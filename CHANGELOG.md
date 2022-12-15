# @wpengine/site-deploy

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
