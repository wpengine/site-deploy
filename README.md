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
WPE_ENV=yourinstall # The target WP Engine install name.
REMOTE_PATH=
SRC_PATH=.
PHP_LINT=TRUE
CACHE_CLEAR=TRUE
SCRIPT=
```

3. Set an environment variable with your private SSH key, replacing the key file name with your own.

```sh
export WPE_SSHG_KEY_PRIVATE=`cat ~/.ssh/my_sshg_key_rsa`
```
4. Run the deploy!

```sh
 docker run --rm \
    -e "WPE_SSHG_KEY_PRIVATE" \
    --env-file ./.env \
    -v $(pwd):/site \
    --workdir=/site \
    wpengine/site-deploy:latest
```
