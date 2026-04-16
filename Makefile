REGISTRY ?= lcr.loongnix.cn
ORGANIZATION ?= kekingcn
REPOSITORY ?= kkfileview
TAG ?= 4.4.0
LATEST ?= false

TARGET_PLATFORM ?= linux/loong64
BASE_IMAGE ?= cr.loongnix.cn/library/openjdk:8-buster
OFFICE_PACKAGES ?=

SOURCE_URL ?= https://github.com/kekingcn/kkFileView.git
SOURCE_REF ?= v$(TAG)
PATCH ?= switch_office_preview_type.patch

BUILD_DIR ?= .build
SRC_DIR ?= $(BUILD_DIR)/kkFileView-$(TAG)
LOCAL_IMAGE ?= $(REPOSITORY):loong64-$(TAG)
IMAGE ?= $(REGISTRY)/$(ORGANIZATION)/$(REPOSITORY):$(TAG)
LATEST_IMAGE ?= $(REGISTRY)/$(ORGANIZATION)/$(REPOSITORY):latest
TAR_NAME ?= $(REPOSITORY)-loong64-$(TAG).tar

default: image

.PHONY: default help print-config src image smoke export push clean

help:
	@printf '%s\n' \
	  'make src      Clone kkFileView source and apply local patch' \
	  'make image    Build the loong64 image via Docker buildx' \
	  'make smoke    Run a basic runtime smoke test' \
	  'make export   Build, smoke test, and export a docker save tar' \
	  'make push     Push the built image to the configured registry' \
	  'make clean    Remove cloned source and exported tar'

print-config:
	@printf 'SOURCE_REF=%s\nLOCAL_IMAGE=%s\nIMAGE=%s\nTAR_NAME=%s\nTARGET_PLATFORM=%s\n' \
	  "$(SOURCE_REF)" "$(LOCAL_IMAGE)" "$(IMAGE)" "$(TAR_NAME)" "$(TARGET_PLATFORM)"

src:
	rm -rf "$(SRC_DIR)"
	mkdir -p "$(BUILD_DIR)"
	git clone --quiet --depth 1 --branch "$(SOURCE_REF)" "$(SOURCE_URL)" "$(SRC_DIR)"
ifneq ($(strip $(PATCH)),)
	cd "$(SRC_DIR)" && git apply "$(CURDIR)/$(PATCH)"
endif

image: src
	docker buildx build \
	  --platform "$(TARGET_PLATFORM)" \
	  --build-arg BASE_IMAGE="$(BASE_IMAGE)" \
	  --build-arg KKFILEVIEW_VERSION="$(TAG)" \
	  --build-arg OFFICE_PACKAGES="$(OFFICE_PACKAGES)" \
	  -t "$(LOCAL_IMAGE)" \
	  -f "$(CURDIR)/Dockerfile.loong64" \
	  --load \
	  "$(SRC_DIR)"

smoke: image
	docker run --rm --platform "$(TARGET_PLATFORM)" --entrypoint sh "$(LOCAL_IMAGE)" -lc '\
	  test -d "$${KKFILEVIEW_HOME:-/opt/kkFileView-$(TAG)}"; \
	  set -- "$${KKFILEVIEW_HOME:-/opt/kkFileView-$(TAG)}"/bin/kkFileView-*.jar; \
	  test -f "$$1"; \
	  test -d "$${OFFICE_HOME:-/opt/libreoffice}/program"; \
	  printf "jar=%s\noffice.home=%s\n" "$$1" "$${OFFICE_HOME:-/opt/libreoffice}" \
	'

export: smoke
	docker save -o "$(TAR_NAME)" "$(LOCAL_IMAGE)"

push: smoke
	docker tag "$(LOCAL_IMAGE)" "$(IMAGE)"
	docker push "$(IMAGE)"
	@if [ "$(LATEST)" = "true" ]; then \
	  docker tag "$(LOCAL_IMAGE)" "$(LATEST_IMAGE)"; \
	  docker push "$(LATEST_IMAGE)"; \
	fi

clean:
	rm -rf "$(BUILD_DIR)" "$(TAR_NAME)"
