#!/bin/bash -e
# This script is used to tag the OpenShift Docker images.
#
# Resulting image will be tagged: 'name:version' and 'name:latest'. Name and version
#                                  are values of labels from resulted image
#
# TEST_MODE - If set, the script will look for *-candidate images to tag
# VERSIONS - Must be set to a list with possible versions (subdirectories)
# CLEAN_AFTER - If set the script will clean built up leftover images and
#               containers created during the run of the test suite.
#               If set to the string "all" it will additionally remove
#               the original (unsquashed) image.

for dir in ${VERSIONS}; do
  [ ! -e "${dir}/.image-id" ] && echo "-> Image for version $dir not built, skipping tag." && continue
  pushd ${dir} > /dev/null
  IMAGE_ID=$(cat .image-id)
  # name=$(docker inspect -f "{{.Config.Labels.name}}" $IMAGE_ID)
  name="rhmap/mongodb-32-centos7"
  # version=$(docker inspect -f "{{.Config.Labels.version}}" $IMAGE_ID)
  version="3.2"
  IMAGE_NAME=$name
  if [ -n "${TEST_MODE}" ]; then
    IMAGE_NAME+="-candidate"
  fi

  if [ -n "$CLEAN_AFTER" ]; then
    echo "-> Removing built images and leftover containers"
    # Remove all remaining containers
    docker rm $(docker ps -q -a -f "ancestor=$IMAGE_ID") 2>/dev/null || :
    # Remove the built image
    docker rmi $IMAGE_ID --force 2>/dev/null || :
    # Remove the unsquashed image
    [ "$CLEAN_AFTER" == "all" ] && docker rmi "${IMAGE_NAME}-unsquashed" 2>/dev/null || :
 else
    echo "-> Tagging image '$IMAGE_NAME' as '$name:$version' and '$name:latest'"
    docker tag $IMAGE_NAME "$name:$version"
    docker tag $IMAGE_NAME "$name:latest"
 fi

  rm .image-id
  popd > /dev/null
done
