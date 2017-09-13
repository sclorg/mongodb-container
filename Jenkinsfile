#!groovy

// https://github.com/feedhenry/fh-pipeline-library
@Library('fh-pipeline-library') _

final String COMPONENT = 'mongodb'
final String VERSION = '3.2'
final String DOCKER_HUB_ORG = "rhmap"
final String DOCKER_HUB_REPO = COMPONENT

fhBuildNode(['label': 'openshift']) {

    stage('Build Image') {
        dockerBinaryBuild(COMPONENT, "centos-${VERSION}", DOCKER_HUB_ORG, DOCKER_HUB_REPO, 'dockerhubjenkins', "./${VERSION}")
    }

}
