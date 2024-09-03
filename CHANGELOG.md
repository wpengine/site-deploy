# @wpengine/site-deploy

## 1.0.4

### Patch Changes

- 30cdd52: Fixes a bug that caused certain flags in the FLAGS option to be incorrectly parsed by rsync
- f8fa689: Adds wp-cache-memcached to default excludes list

## 1.0.3

### Patch Changes

- f1e6867: Bump node version for dev tooling
- 43ebea6: Update base image alpine 3.18 > 3.20 and apply updates
- 504f3db: Update dev tooling npm dependencies

## 1.0.2

### Patch Changes

- d8b8469: Bump @changesets/cli > 2.26.2 (resolves semver vulnerability)
- 4283418: Bump alpine 3.17 > 3.18

## 1.0.1

### Patch Changes

- 20cff22: Update instrumentisto/rsync-ssh base image to alpine3.17

## 1.0.0

### Major Changes

- 58eb612: Updates the main script to be more generic, allowing it to be used around different CI/CD Vendors.

  In order to use this image, each CI/CD vendor implementation will need to set the environment variables accordingly:

  ```sh
  WPE_ENV # The target WP Engine install name
  REMOTE_PATH # Default is empty
  SRC_PATH # Default is the current directory
  FLAGS # Default is -azvr --inplace --exclude=".*"
  PHP_LINT # Default is "FALSE"
  CACHE_CLEAR # Default is "TRUE"
  SCRIPT # Default is empty
  ```

  Example of how to run this image:

  ```sh
   docker run --rm \
      -e "WPE_SSHG_KEY_PRIVATE" \
      --env-file ./.env \
      -v <full_path_of_site>:/site \
      --workdir=/site \
      wpengine/site-deploy:latest
  ```
