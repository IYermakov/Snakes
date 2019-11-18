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
    RepoName = 'snakes'

  }
  stages {
    stage("Build app") {
      steps {
        sh 'cd eb-tomcat-snakes && ./build.sh'
      }
    }
    stage("Build Docker Image") {
      steps {
        script {
          dockerImage = docker.build("${ECRURI}/${RepoName}:${env.BUILD_ID}")
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
          echo "======== Check Access ========="
          sh 'sleep 30'
          sh 'curl -sS http://localhost:8090 | grep "Does it have snakes?"'
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
          sh '$(aws ecr get-login --no-include-email --region us-east-1)'
          docker.withRegistry("https://${ECRURI}") {
            dockerImage.push()
          }
        }
      }
    }
    stage("CleanUp") {
      steps {
        echo "====================== Removing images ====================="
        sh 'docker image prune -af'
        sh 'docker images'
      }
    }
    stage("Create stack") {
      // when { tag "release-*" }
      steps {
        git(url: 'https://github.com/IYermakov/DevOpsA3Training.git', branch: 'ecs-snakes')
        sh "aws cloudformation deploy --stack-name ECS-task --template-file ops/cloudformation/ecs-task.yml --parameter-overrides ImageUrl=${dockerImage} --region us-east-1"
      }
    }
  }
}
