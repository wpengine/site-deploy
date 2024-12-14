.PHONY: clean list-images build publish

IMAGE_NAME ?= wpengine/site-deploy
MAJOR_VERSION ?= 1
MINOR_VERSION ?= 0
PATCH_VERSION ?= 0
TAG ?= latest
IMAGE := $(IMAGE_NAME):$(TAG)

clean:
	$(eval CURRENT_IMAGES=`docker images $(IMAGE_NAME) -a -q | uniq`)
	docker rmi -f $(CURRENT_IMAGES)

list-images:
	docker images $(IMAGE_NAME) -a

build:
	docker build --no-cache -t $(IMAGE) ./

version: build
	docker image tag $(IMAGE) $(IMAGE_NAME):v$(MAJOR_VERSION) && \
	docker image tag $(IMAGE) $(IMAGE_NAME):v$(MAJOR_VERSION).$(MINOR_VERSION) && \
	docker image tag $(IMAGE) $(IMAGE_NAME):v$(MAJOR_VERSION).$(MINOR_VERSION).$(PATCH_VERSION)

test:
	./tests/test_functions.sh
#	./tests/test_exclude_from.sh
	@make test-excludes

# Test that rsync is properly parsing dynamic file/path exclusions
# Running with an image to emulate the way in which generate_path_excludes.sh will actually be used
test-excludes:
	@echo "🚧 Building container for testing dynamic file/path exclusions with rsync... 🚧"
	@docker build -f tests/docker/Dockerfile_test-path-excludes -t test-path-excludes .
	@echo "🚧 Running tests... 🚧"
	@docker run --rm -e REPO_PATH=$(PWD) -v $(PWD)/tests/fixtures/src:/site --workdir /site test-path-excludes
	@docker run --rm -e REPO_PATH=$(PWD) -v $(PWD)/tests/fixtures/src:/site --workdir /site/wp-content test-path-excludes
	@docker run --rm -e REPO_PATH=$(PWD) -v $(PWD)/tests/fixtures/src:/site --workdir /site/wp-content/plugins test-path-excludes
	@docker run --rm -e REPO_PATH=$(PWD) -v $(PWD)/tests/fixtures/src/wp-content:/site --workdir /site test-path-excludes
	@docker run --rm -e REPO_PATH=$(PWD) -v $(PWD)/tests/fixtures/src/wp-content:/site --workdir /site/plugins test-path-excludes
	@docker run --rm -e REPO_PATH=$(PWD) -v $(PWD)/tests/fixtures/src/wp-content/plugins:/site --workdir /site test-path-excludes
	#@docker run --rm -v $(PWD)/tests/fixtures/src:/site --workdir /site/wp-content/mu-plugins test-path-excludes #MU-PLUGINS
	#@docker run --rm -v $(PWD)/tests/fixtures/src/wp-content:/site --workdir /site/mu-plugins test-path-excludes #MU-PLUGINS
	#@docker run --rm -v $(PWD)/tests/fixtures/src/wp-content/mu-plugins:/site --workdir /site test-path-excludes #MU-PLUGINS
	@echo "🚀 All tests passed for dynamic file/path exclusions with rsync 🚀"
