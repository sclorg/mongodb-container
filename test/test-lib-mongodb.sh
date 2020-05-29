#!/bin/bash
#
# Functions for tests for the MongoDB image in OpenShift.
#
# IMAGE_NAME specifies a name of the candidate image used for testing.
# The image has to be available before this script is executed.
#

THISDIR=$(dirname ${BASH_SOURCE[0]})

source ${THISDIR}/test-lib.sh
source ${THISDIR}/test-lib-openshift.sh

function test_mongodb_integration() {
  local image_name=$1
  local VERSION=$2
  local service_name=$3
  local image_tagged="${service_name}:${VERSION}"
  ct_os_template_exists mongodb-ephemeral && t=mongodb-ephemeral || t=mongodb-persistent
  ct_os_test_template_app_func "${image_name}" \
                               "${t}" \
                               "${service_name}" \
                               "ct_os_check_cmd_internal '<SAME_IMAGE>' '${service_name}-testing' \"mongo <IP>/testdb -u testu -ptestp --eval 'quit()'\" '.*' 120" \
                               "-p MONGODB_VERSION=${VERSION} \
                                -p DATABASE_SERVICE_NAME="${service_name}-testing" \
                                -p MONGODB_USER=testu \
                                -p MONGODB_PASSWORD=testp \
                                -p MONGODB_DATABASE=testdb"
}

# Check the imagestream
function test_mongodb_imagestream() {
  case ${OS} in
    rhel7|centos7) ;;
    *) echo "Imagestream testing not supported for $OS environment." ; return 0 ;;
  esac

  ct_os_test_image_stream_template "${THISDIR}/../imagestreams/mongodb-${OS}.json" "${THISDIR}/../examples/mongodb-ephemeral-template.json" mongodb "-p MONGODB_VERSION=${VERSION}"
}

# vim: set tabstop=2:shiftwidth=2:expandtab:
