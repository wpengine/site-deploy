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

test-unit:
	./tests/test_functions.sh
	./tests/test_generate_path_excludes.sh
