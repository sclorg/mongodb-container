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
  local import_image=$3
  local service_name=${import_image##*/}
  ct_os_template_exists mongodb-ephemeral && t=mongodb-ephemeral || t=mongodb-persistent
  ct_os_test_template_app_func "${image_name}" \
                               "${t}" \
                               "${service_name}" \
                               "ct_os_check_cmd_internal '${import_image}' '${service_name}' \"mongo <IP>/testdb -u testu -ptestp --eval 'quit()'\" '.*' 120" \
                               "-p MONGODB_VERSION=${VERSION} \
                                -p DATABASE_SERVICE_NAME="${service_name}-testing" \
                                -p MONGODB_USER=testu \
                                -p MONGODB_PASSWORD=testp \
                                -p MONGODB_DATABASE=testdb" "" "${import_image}"
}

# vim: set tabstop=2:shiftwidth=2:expandtab:
