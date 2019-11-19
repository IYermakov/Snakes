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
  environment {
    ECRURI = '054017840000.dkr.ecr.us-east-1.amazonaws.com'
    AppRepoName = 'snakes'
    OPSRepoURL = 'https://github.com/IYermakov/DevOpsA3Training.git'
    OPSRepoBranch = 'ecs-snakes'
    ImageTag = ""

  }
  stages {
    stage("Build app") {
      steps {
        script {
          try {
            sh 'cd eb-tomcat-snakes && ./build.sh'
            currentBuild.result = 'SUCCESS'
          }
          catch (err) {
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. Build Application Failed, check logs.", subject: 'JOB FAILED', to: 'vecinomio@gmail.com'
          }
          echo "result is: ${currentBuild.currentResult}"
        }
      }
    }
    stage("Build Docker Image") {
      steps {
        script {
          if (env.TAG_NAME) {
            ImageTag = env.TAG_NAME
          } else {
            ImageTag = env.BUILD_NUMBER
          }
          try {
            dockerImage = docker.build("${ECRURI}/${AppRepoName}:${ImageTag}")
            currentBuild.result = 'SUCCESS'
          }
          catch (err) {
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. Build Docker Image Failed, check logs.", subject: 'JOB FAILED', to: 'vecinomio@gmail.com'
          }
          echo "result is: ${currentBuild.currentResult}"
        }
      }
    }
    stage("Create Test Env") {
      steps {
        script {
            echo "======== Start Docker Container ========"
            testContainer = dockerImage.run('-p 8090:8080 --name test')
        }
      }
    }
    stage("Test") {
      steps {
        script {
          try {
            echo "======== Check Access ========="
            sh 'sleep 30'
            sh 'curl -sS http://localhost:8090 | grep "Does it have snakes?"'
            }
          }
          catch (err) {
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. Curl Test Failed, check logs.", subject: 'JOB FAILED', to: 'vecinomio@gmail.com'
          }
          echo "result is: ${currentBuild.currentResult}"
        }
      }
    }
    stage("Remove Test Env") {
      steps {
        script {
          echo "======== Disable and Remove Container ========="
          testContainer.stop()
        }
      }
    }
    stage("Push artifact to ECR") {
      steps {
        script {
          try {
            sh '$(aws ecr get-login --no-include-email --region us-east-1)'
            docker.withRegistry("https://${ECRURI}") {
              dockerImage.push()
            currentBuild.result = 'SUCCESS'
            }
          }
          catch (err) {
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. Delivery to ECR Failed, check logs.", subject: 'JOB FAILED', to: 'vecinomio@gmail.com'
          }
          echo "result is: ${currentBuild.currentResult}"
        }
      }
    }
    stage("CleanUp") {
      steps {
        echo "====================== Removing images ====================="
        sh 'docker image prune -af --filter="label=maintainer=devopsa3"'
        sh 'docker images'
      }
    }
    stage("Create stack") {
      when { buildingTag() }
      steps {
        script {
          try {
            git(url: "${OPSRepoURL}", branch: "${OPSRepoBranch}")
            sh "aws cloudformation deploy --stack-name ECS-task --template-file ops/cloudformation/ecs-task.yml --parameter-overrides ImageUrl=${ECRURI}/${AppRepoName}:${ImageTag} --region us-east-1"
            currentBuild.result = 'SUCCESS'
            emailext body: 'Application was successfully deployed to ECS.', subject: 'CD finished', to: 'vecinomio@gmail.com'
          }
          catch (err) {
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. ECS Stack Creation Failed, check logs.", subject: 'JOB FAILED', to: 'vecinomio@gmail.com'
          }
          echo "result is: ${currentBuild.currentResult}"
        }
      }
    }
  }
}
