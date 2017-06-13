# Variables are documented in hack/build.sh.
BASE_IMAGE_NAME = mongodb
VERSIONS = 2.6 3.0-upg 3.2 3.4-tar
OPENSHIFT_NAMESPACES = 2.4

# HACK:  Ensure that 'git pull' for old clones doesn't cause confusion.
# New clones should use '--recursive'.
.PHONY: $(shell test -f common/common.mk || echo >&2 'Please do "git submodule update --init" first.')

include common/common.mk
