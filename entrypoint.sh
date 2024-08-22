#!/bin/bash -l

set -e

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the functions.sh file relative to the current script's location
source "${SCRIPT_DIR}/functions.sh"

validate() {
  # mandatory params
  : WPE_SSHG_KEY_PRIVATE="${WPE_SSHG_KEY_PRIVATE:?'WPE_SSHG_KEY_PRIVATE variable missing from Repo or Workspace variables.'}"
  # optional params
  : REMOTE_PATH="${REMOTE_PATH:=""}"
  : SRC_PATH="${SRC_PATH:="."}"
  : FLAGS="${FLAGS:="-azvr --inplace --exclude='.*'"}"
  : PHP_LINT="${PHP_LINT:="FALSE"}"
  : CACHE_CLEAR="${CACHE_CLEAR:="TRUE"}"
  : SCRIPT="${SCRIPT:=""}"
}

setup_env() {
  if [[ -n ${WPE_ENV} ]]; then
      WPE_ENV_NAME="${WPE_ENV}";
    elif [[ -n ${PRD_ENV} ]]; then
      WPE_ENV_NAME="${PRD_ENV}";
    elif [[ -n ${STG_ENV} ]]; then
      WPE_ENV_NAME="${STG_ENV}";
    elif [[ -n ${DEV_ENV} ]]; then  
      WPE_ENV_NAME="${DEV_ENV}";
    else echo "Failure: Missing environment variable..."  && exit 1;
  fi

  if [[ -n ${GITHUB_ACTIONS} ]]; then
      CICD_VENDOR="wpe_gha";
    elif [[ -n ${BITBUCKET_BUILD_NUMBER} ]]; then
      CICD_VENDOR="wpe_bb";
    else CICD_VENDOR="wpe_cicd"
  fi

  parse_flags "$FLAGS"
  print_deployment_info

  WPE_SSH_HOST="${WPE_ENV_NAME}.ssh.wpengine.net"
  DIR_PATH="${REMOTE_PATH}"

  # Set up WPE user and path
  WPE_SSH_USER="${WPE_ENV_NAME}"@"${WPE_SSH_HOST}"
  WPE_FULL_HOST="${CICD_VENDOR}+$WPE_SSH_USER"
  WPE_DESTINATION="${CICD_VENDOR}+${WPE_SSH_USER}:sites/${WPE_ENV_NAME}"/"${DIR_PATH}"
}

setup_ssh_dir() {
  echo "setup ssh path"

  if [ ! -d "${HOME}/.ssh" ]; then 
      mkdir "${HOME}/.ssh" 
      SSH_PATH="${HOME}/.ssh" 
      mkdir "${SSH_PATH}/ctl/"
      # Set Key Perms 
      chmod -R 700 "$SSH_PATH"
    else 
      SSH_PATH="${HOME}/.ssh"
      echo "using established SSH KEY path...";
  fi

  #Copy secret keys to container 
  WPE_SSHG_KEY_PRIVATE_PATH="${SSH_PATH}/wpe_id_rsa"

  if [ "${CICD_VENDOR}" == "wpe_bb" ]; then
    # Only Bitbucket keys require base64 decode
    umask  077 ; echo "${WPE_SSHG_KEY_PRIVATE}" | base64 -d > "${WPE_SSHG_KEY_PRIVATE_PATH}"
    else umask  077 ; echo "${WPE_SSHG_KEY_PRIVATE}" > "${WPE_SSHG_KEY_PRIVATE_PATH}"
  fi

  chmod 600 "${WPE_SSHG_KEY_PRIVATE_PATH}"
  #establish knownhosts 
  KNOWN_HOSTS_PATH="${SSH_PATH}/known_hosts"
  ssh-keyscan -t rsa "${WPE_SSH_HOST}" >> "${KNOWN_HOSTS_PATH}"
  chmod 644 "${KNOWN_HOSTS_PATH}"
}

check_lint() {
  if [ "${PHP_LINT^^}" == "TRUE" ]; then
      echo "Begin PHP Linting."
      find "$SRC_PATH"/ -name "*.php" -type f -print0 | while IFS= read -r -d '' file; do
          php -l "$file"
          status=$?
          if [[ $status -ne 0 ]]; then
              echo "FAILURE: Linting failed - $file :: $status" && exit 1
          fi
      done
      echo "PHP Lint Successful! No errors detected!"
  else 
      echo "Skipping PHP Linting."
  fi
}

check_cache() {
  if [ "${CACHE_CLEAR^^}" == "TRUE" ]; then
      CACHE_CLEAR="&& wp --skip-plugins --skip-themes page-cache flush && wp --skip-plugins --skip-themes cdn-cache flush"
    elif [ "${CACHE_CLEAR^^}" == "FALSE" ]; then
        CACHE_CLEAR=""
    else echo "CACHE_CLEAR value must be set as TRUE or FALSE only... Cache not cleared..."  && exit 1;
  fi
}

sync_files() {
  #create multiplex connection 
  ssh -nNf -v -i "${WPE_SSHG_KEY_PRIVATE_PATH}" -o StrictHostKeyChecking=no -o ControlMaster=yes -o ControlPath="$SSH_PATH/ctl/%C" "$WPE_FULL_HOST"
  echo "!!! MULTIPLEX SSH CONNECTION ESTABLISHED !!!"

  set -x
  rsync --rsh="ssh -v -p 22 -i ${WPE_SSHG_KEY_PRIVATE_PATH} -o StrictHostKeyChecking=no -o 'ControlPath=$SSH_PATH/ctl/%C'" "${FLAGS_ARRAY[@]}" --exclude-from='/exclude.txt' --chmod=D775,F664 "${SRC_PATH}" "${WPE_DESTINATION}"
  set +x
  
  if [[ -n ${SCRIPT} || -n ${CACHE_CLEAR} ]]; then

      if [[ -n ${SCRIPT} ]]; then
        if ! ssh -v -p 22 -i "${WPE_SSHG_KEY_PRIVATE_PATH}" -o StrictHostKeyChecking=no -o ControlPath="$SSH_PATH/ctl/%C" "$WPE_FULL_HOST" "test -s sites/${WPE_ENV_NAME}/${SCRIPT}"; then
          status=1
        fi

        if [[ $status -ne 0 && -f ${SCRIPT} ]]; then
          ssh -v -p 22 -i "${WPE_SSHG_KEY_PRIVATE_PATH}" -o StrictHostKeyChecking=no -o ControlPath="$SSH_PATH/ctl/%C" "$WPE_FULL_HOST" "mkdir -p sites/${WPE_ENV_NAME}/$(dirname "${SCRIPT}")"

          rsync --rsh="ssh -v -p 22 -i ${WPE_SSHG_KEY_PRIVATE_PATH} -o StrictHostKeyChecking=no -o 'ControlPath=$SSH_PATH/ctl/%C'" "${SCRIPT}" "${CICD_VENDOR}+$WPE_SSH_USER:sites/$WPE_ENV_NAME/$(dirname "${SCRIPT}")"
        fi
      fi

      if [[ -n ${SCRIPT} ]]; then
        SCRIPT="&& bash ${SCRIPT}"
      fi

      ssh -v -p 22 -i "${WPE_SSHG_KEY_PRIVATE_PATH}" -o StrictHostKeyChecking=no -o ControlPath="$SSH_PATH/ctl/%C" "$WPE_FULL_HOST" "cd sites/${WPE_ENV_NAME} ${SCRIPT} ${CACHE_CLEAR}"
  fi 

  #close multiplex connection
  ssh -O exit -o ControlPath="$SSH_PATH/ctl/%C" "$WPE_FULL_HOST"
  echo "closing ssh connection..."
}

validate
setup_env
setup_ssh_dir
check_lint
check_cache
sync_files
