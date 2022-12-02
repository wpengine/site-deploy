---
"@wpengine/site-deploy": major
---

# Refactor the Main Script

Updates the main script to be more generic and allow the script and image to be used around other CI/CD Vendors.

In order to use this script, each CI/CD vendor will need to set the environment variables accordingly:

```sh
REMOTE_PATH # Default is empty
SRC_PATH # Default is the current directory
FLAGS # Default is -azvr --inplace --exclude=".*"
PHP_LINT # Default is "FALSE"
CACHE_CLEAR # Default is "TRUE"
SCRIPT # Default is empty
CICD_VENDOR # Default is "wpe-cicd"
```

Example of how to run this image:

```sh
 docker run \
    -e "WPE_SSHG_KEY_PRIVATE" \
    --env-file ./.env \
    -v <full_path_of_site>:/site \
    --workdir=/site \
    wpengine/site-deploy:latest
```
