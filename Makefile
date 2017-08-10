# Variables are documented in hack/build.sh.
BASE_IMAGE_NAME = mongodb
VERSIONS = 3.2

# RHMAP adding all versions here to avoid images getting tagged with anything
# other than rhmap/ in hack/build.sh
OPENSHIFT_NAMESPACES = 3.2

# HACK:  Ensure that 'git pull' for old clones doesn't cause confusion.
# New clones should use '--recursive'.
.PHONY: $(shell test -f common/common.mk || echo >&2 'Please do "git submodule update --init" first.')


# Include common Makefile code.
include common/common.mk
