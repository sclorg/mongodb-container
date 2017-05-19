#!/bin/bash -e
# This script is used to build the OpenShift Docker images.
#
# OS - Specifies distribution - "rhel7", "centos7" or "fedora"
# VERSION - Specifies the image version - (must match with subdirectory in repo)
# TEST_MODE - If set, build a candidate image and test it
# TAG_ON_SUCCESS - If set, tested image will be re-tagged as a non-candidate
#       image, if the tests pass.
# VERSIONS - Must be set to a list with possible versions (subdirectories)

OS=${1-$OS}
VERSION=${2-$VERSION}

DOCKERFILE_PATH=""

# Perform docker build but append the LABEL with GIT commit id at the end
function docker_build_with_version {
  local dockerfile="$1"
  [ ! -e "$dockerfile" ] && echo "-> $dockerfile for version $dir does not exist, skipping build." && return
  echo "-> Version ${dir}: building image from '${dockerfile}' ..."

  git_version=$(git rev-parse --short HEAD)
  BUILD_OPTIONS+=" --label io.openshift.builder-version=\"${git_version}\""
  if [[ "${UPDATE_BASE}" == "1" ]]; then
    BUILD_OPTIONS+=" --pull=true"
  fi

  local docker_cmd=(docker build ${BUILD_OPTIONS} -f "${dockerfile}" .)
  { IMAGE_ID=$("${docker_cmd[@]}" | tee /dev/fd/$fd | awk '/Successfully built/{print $NF}'); } {fd}>&1

  name=$(docker inspect -f "{{.Config.Labels.name}}" $IMAGE_ID)

  # IMAGE_NAME=$name
  IMAGE_NAME="rhmap/mongodb-32-centos7"
  # if [ -n "${TEST_MODE}" ]; then
  #   IMAGE_NAME+="-candidate"
  # fi
  echo "-> Image ${IMAGE_ID} tagged as ${IMAGE_NAME}"
  docker tag $IMAGE_ID $IMAGE_NAME

  if [[ "${SKIP_SQUASH}" != "1" ]]; then
    docker tag $IMAGE_ID "${IMAGE_NAME}"
    #squash "${dockerfile}"
  fi
  # Narrow by repo:tag first and then grep out the exact match
  docker images "${IMAGE_NAME}:latest" --format="{{.Repository}} {{.ID}}" | grep "^${IMAGE_NAME}" | awk '{print $2}' >.image-id
}

# Install the docker squashing tool[1] and squash the result image
# [1] https://github.com/goldmann/docker-squash
function squash {
  # FIXME: We have to use the exact versions here to avoid Docker client
  #        compatibility issues
  easy_install -q --user docker_py==1.10.6 docker-squash==1.0.5
  base=$(awk '/^FROM/{print $2}' $1)
  ${HOME}/.local/bin/docker-squash -f $base ${IMAGE_NAME} -t ${IMAGE_NAME}
}

# Versions are stored in subdirectories. You can specify VERSION variable
# to build just one single version. By default we build all versions
dirs=${VERSION:-$VERSIONS}

for dir in ${dirs}; do
  pushd ${dir} > /dev/null
  if [ "$OS" == "rhel7" -o "$OS" == "rhel7-candidate" ]; then
    docker_build_with_version Dockerfile.rhel7
  elif [ "$OS" == "fedora" -o "$OS" == "fedora-candidate" ]; then
    docker_build_with_version Dockerfile.fedora
  else
    docker_build_with_version Dockerfile
  fi

  popd > /dev/null
done
