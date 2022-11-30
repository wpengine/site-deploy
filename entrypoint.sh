#!/bin/bash -l

set -e

# : "${INPUT_WPE_SSHG_KEY_PRIVATE?Required secret not set.}"

# #Alias logic for ENV names 
# if [[ -n ${INPUT_WPE_ENV} ]]; then
#     WPE_ENV_NAME="${INPUT_WPE_ENV}";
#   elif [[ -n ${INPUT_PRD_ENV} ]]; then
#     WPE_ENV_NAME="${INPUT_PRD_ENV}";
#   elif [[ -n ${INPUT_STG_ENV} ]]; then
#     WPE_ENV_NAME="${INPUT_STG_ENV}";
#   elif [[ -n ${INPUT_DEV_ENV} ]]; then  
#     WPE_ENV_NAME="${INPUT_DEV_ENV}";
#   else echo "Failure: Missing environment variable..."  && exit 1;
# fi

validate() {
  # mandatory params
  : WPE_SSHG_KEY_PRIVATE="${WPE_SSHG_KEY_PRIVATE:?'WPE_SSHG_KEY_PRIVATE variable missing from Repo or Workspace variables.'}"
  # optional params
  : REMOTE_PATH="${REMOTE_PATH:=''}"
  : SRC_PATH="${SRC_PATH:='.'}"
  : FLAGS="${FLAGS:="-azvr --inplace --exclude=".*""}"
  : PHP_LINT="${PHP_LINT:="FALSE"}"
  : CACHE_CLEAR="${CACHE_CLEAR:="TRUE"}"
  : SCRIPT="${SCRIPT:=''}"
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

  echo "Deploying your code to:"
  echo "${WPE_ENV_NAME}"

  WPE_SSH_HOST="${WPE_ENV_NAME}.ssh.wpengine.net"
  DIR_PATH="${REMOTE_PATH}"
  echo "${WPE_ENV_NAME}"

  # Set up WPE user and path
  WPE_SSH_USER="${WPE_ENV_NAME}"@"${WPE_SSH_HOST}"
  WPE_FULL_HOST=wpe_bbp+"$WPE_SSH_USER"
  WPE_DESTINATION=wpe_bbp+"${WPE_SSH_USER}":sites/"${WPE_ENV_NAME}"/"${DIR_PATH}"
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
  umask  077 ; echo "${WPE_SSHG_KEY_PRIVATE}" > "${WPE_SSHG_KEY_PRIVATE_PATH}"
  chmod 600 "${WPE_SSHG_KEY_PRIVATE_PATH}"
  echo "${WPE_SSH_HOST}"
  #establish knownhosts 
  KNOWN_HOSTS_PATH="${SSH_PATH}/known_hosts"
  ssh-keyscan -t rsa "${WPE_SSH_HOST}" >> "${KNOWN_HOSTS_PATH}"
  chmod 644 "${KNOWN_HOSTS_PATH}"

  cat /root/.ssh/wpe_id_rsa

}

check_lint() {
  if [ "${PHP_LINT^^}" == "TRUE" ]; then
    echo "Begin PHP Linting."
    for file in $(find ${SRC_PATH}/ -name "*.php"); do
        php -l "$file"
        status=$?
        if [[ $status -ne 0 ]]; then
            echo "FAILURE: Linting failed - $file :: $status" && exit 1
        fi
    done
      echo "PHP lint successful! No errors detected!"
  else 
      echo "Skipping PHP lint..."
  fi
}

check_cache() {
  if [ "${CACHE_CLEAR^^}" == "TRUE" ]; then
      CACHE_CLEAR="&& wp page-cache flush"
    elif [ "${CACHE_CLEAR^^}" == "FALSE" ]; then
        CACHE_CLEAR=""
    else echo "CACHE_CLEAR value must be set as TRUE or FALSE only... Cache not cleared..."  && exit 1;
  fi
}

fix_file_perms() {
  echo "prepparing file perms..."
  find "$SRC_PATH" -type d -exec chmod -R 775 {} \;
  find "$SRC_PATH" -type f -exec chmod -R 664 {} \;
  echo "file perms set..."
}

sync_files() {
  echo "Deploying ${GIT_REF} branch to ${WPE_ENV_NAME}..."
  
  #create multiplex connection 
  ssh -nNf -v -i "${WPE_SSHG_KEY_PRIVATE_PATH}" -o StrictHostKeyChecking=no -o ControlMaster=yes -o ControlPath="$SSH_PATH/ctl/%C" "$WPE_FULL_HOST"
  echo "!!! MULTIPLEX SSH CONNECTION ESTABLISHED !!!"

  rsync --rsh="ssh -p 22 -i ${WPE_SSHG_KEY_PRIVATE_PATH} -o StrictHostKeyChecking=no" "${FLAGS}" --exclude-from='/exclude.txt' --chmod=D775,F664 ${SRC_PATH} "${WPE_DESTINATION}"

  if [[ -n ${SCRIPT} || -n ${CACHE_CLEAR} ]]; then 
    ssh -v -p 22 -i "${WPE_SSHG_KEY_PRIVATE_PATH}" -o StrictHostKeyChecking=no -o ControlPath="$SSH_PATH/ctl/%C" "$WPE_FULL_HOST" "cd sites/${WPE_ENV_NAME} ${SCRIPT} ${CACHE_CLEAR}"
  fi 
  
  if [[ -n ${SCRIPT} || -n ${CACHE_CLEAR} ]]; then

      if [[ -n ${SCRIPT} ]]; then
        if ! ssh -v -p 22 -i "${WPE_SSHG_KEY_PRIVATE_PATH}" -o StrictHostKeyChecking=no -o ControlPath="$SSH_PATH/ctl/%C" "$WPE_FULL_HOST" "test -s sites/${WPE_ENV_NAME}/${SCRIPT}"; then
          status=1
        fi

        if [[ $status -ne 0 && -f ${SCRIPT} ]]; then
          ssh -v -p 22 -i "${WPE_SSHG_KEY_PRIVATE_PATH}" -o StrictHostKeyChecking=no -o ControlPath="$SSH_PATH/ctl/%C" "$WPE_FULL_HOST" "mkdir -p sites/${WPE_ENV_NAME}/$(dirname "${SCRIPT}")"

          rsync --rsh="ssh -v -p 22 -i ${WPE_SSHG_KEY_PRIVATE_PATH} -o StrictHostKeyChecking=no -o 'ControlPath=$SSH_PATH/ctl/%C'" "${SCRIPT}" "wpe_gha+$WPE_SSH_USER:sites/$WPE_ENV_NAME/$(dirname "${SCRIPT}")"
        fi
      fi

      ssh -v -p 22 -i "${WPE_SSHG_KEY_PRIVATE_PATH}" -o StrictHostKeyChecking=no -o ControlPath="$SSH_PATH/ctl/%C" "$WPE_FULL_HOST" "cd sites/${WPE_ENV_NAME} ${SCRIPT} ${CACHE_CLEAR}"
  fi 

  #close multiplex connection
  ssh -O exit -o ControlPath="$SSH_PATH/ctl/%C" "$WPE_FULL_HOST"
  echo "closing ssh connection..."
}

validate
setup_env
# enable_debug
setup_ssh_dir
fix_file_perms
check_lint
check_cache
sync_files