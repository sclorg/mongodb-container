# Variables are documented in hack/build.sh.
BASE_IMAGE_NAME = mongodb
VERSIONS = 2.4 2.6 3.2

# RHMAP adding all versions here to avoid images getting tagged with anything
# other than rhmap/ in hack/build.sh
OPENSHIFT_NAMESPACES = 2.4 2.6 3.2

# Include common Makefile code.
include hack/common.mk
