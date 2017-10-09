#!groovy

// https://github.com/feedhenry/fh-pipeline-library
@Library('fh-pipeline-library') _

fhBuildNode(['label': 'openshift']) {

    final String COMPONENT = 'mongodb'
    final String VERSION = '3.2'
    final String BUILD = env.BUILD_NUMBER
    final String DOCKER_HUB_ORG = "rhmap"
    final String DOCKER_HUB_REPO = COMPONENT
    final String CHANGE_URL = env.CHANGE_URL

    stage('Platform Update') {
        final Map updateParams = [
                componentName: COMPONENT,
                componentVersion: "centos-${VERSION}",
                componentBuild: BUILD,
                changeUrl: CHANGE_URL
        ]
        fhOpenshiftTemplatesComponentUpdate(updateParams)
        fhCoreOpenshiftTemplatesComponentUpdate(updateParams)
    }

    stage('Build Image') {
        final Map params = [
                fromDir: "./${VERSION}",
                buildConfigName: COMPONENT,
                imageRepoSecret: "dockerhub",
                outputImage: "docker.io/${DOCKER_HUB_ORG}/${DOCKER_HUB_REPO}:centos-${VERSION}-${BUILD}"
        ]
        buildWithDockerStrategy params
        archiveArtifacts writeBuildInfo('mongodb', "centos-${VERSION}-${BUILD}", false)
    }

}
