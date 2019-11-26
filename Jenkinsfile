#!groovy
//Only one build can run
properties([disableConcurrentBuilds()])

pipeline {
  agent {
    label 'master'
  }
  options {
    buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '5'))
    timestamps()
  }
  parameters {
    string(defaultValue: '1.0.0', description: 'A version of Release', name: 'RELEASE_VERSION')
    string(defaultValue: '1.0.0', description: 'A version of Release', name: 'AV_RELEASE_VERSION')
    booleanParam(name: 'Build application', defaultValue: true, description: 'Build Java web application')
    booleanParam(name: 'Build Docker Image', defaultValue: true, description: 'Build Docker Image with Java web application')
    booleanParam(name: 'Test', defaultValue: true, description: 'Test Docker Image with Java web application')
  }
  environment {
    ECRURI = '054017840000.dkr.ecr.us-east-1.amazonaws.com'
    AppRepoName = 'snakes'
    OPSRepoURL = 'git@github.com:IYermakov/DevOpsA3Training.git'
    OPSRepoBranch = 'ecs-spot'

    Tag = "${params.AV_RELEASE_VERSION}"
    Email = 'vecinomio@gmail.com'
    DelUnusedImage = 'docker image prune -af --filter="label=maintainer=devopsa3"'
  }

  stages{
    stage("Build app") {
      steps {
        script {
          try {
            sh 'cd eb-tomcat-snakes && ./build.sh'
            currentBuild.result = 'SUCCESS'
            sh 'echo ${AV_RELEASE_VERSION}'
          }
          catch (err) {
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. Build Application Failed, check logs.", subject: "JOB with identifier ${Tag} FAILED", to: "${Email}"
            throw (err)
          }
          echo "result is: ${currentBuild.currentResult}"
        }
      }
    }
    stage("Build Docker Image") {
      steps {
        script {
          try {
            dockerImage = docker.build("${ECRURI}/${AppRepoName}:${Tag}")
            currentBuild.result = 'SUCCESS'
          }
          catch (err) {
            sh "${DelUnusedImage}"
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. Build Docker Image Failed, check logs.", subject: "JOB with identifier ${Tag} FAILED", to: "${Email}"
            throw (err)
          }
          echo "result is: ${currentBuild.currentResult}"
          echo "${params.RELEASE_VERSION}"
        }
      }
    }
    stage("Test") {
      steps {
        script {
          try {
            echo "======== Start Docker Container ========"
            testContainer = dockerImage.run('-p 8090:8080 --name test')
            echo "======== Check Access ========="
            sh 'sleep 30'
            sh 'curl -sS http://localhost:8090 | grep "Does it have snakes?"'
            echo "======== Disable and Remove Container ========="
            testContainer.stop()
            currentBuild.result = 'SUCCESS'
          }
          catch (err) {
            testContainer.stop()
            sh "${DelUnusedImage}"
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. Test Failed, check logs.", subject: "JOB with identifier ${Tag} FAILED", to: "${Email}"
            throw (err)
          }
        }
      }
    }

  }
}
