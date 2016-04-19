# Variables are documented in hack/build.sh.
BASE_IMAGE_NAME = mongodb
VERSIONS = 2.4 2.6
OPENSHIFT_NAMESPACES = 2.4

# Include common Makefile code.
include hack/common.mk
