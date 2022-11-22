# wpengine/site-deploy
Base image to build VCS integrations enabling customers to deploy their site to WP Engine

## How to Build

You can build and version this image using make targets.

```sh
make build       # Builds the image locally
make version     # Builds the image and creates version tags
make list-images # Shows all tagged versions of the image
make clean       # Deletes all tagged versions of the image
```

## How to Run

You can use this image to deploy a site from your local machine.

1. Build the `wpengine/site-deploy:latest` image with `make build`.
2. Change directories into the root of the local site you'd like to deploy.
3. Create a `.env` file with the following variables, changing their values as needed.

```sh
INPUT_WPE_ENV=yourinstall # The target WP Engine install name.
GITHUB_REF=main           # Inconsequential, but must be defined for now.
INPUT_REMOTE_PATH=
INPUT_SRC_PATH=.
INPUT_PHP_LINT=TRUE
INPUT_CACHE_CLEAR=TRUE
```

3. Set an environment variable with your private SSH key, replacing the key file name with your own.

```sh
export INPUT_WPE_SSHG_KEY_PRIVATE=`cat ~/.ssh/my_sshg_key_rsa`
```
4. Replace `/path/to/your/install` with the absolute path to your local site and run the deploy!

```sh
 docker run \
    -e "INPUT_WPE_SSHG_KEY_PRIVATE" \
    -e "INPUT_FLAGS=-azvr --inplace --exclude=\".*\"" \
    --env-file ./.env \
    -v /path/to/your/install:/site \
    --workdir=/site \
    wpengine/site-deploy:latest
```
