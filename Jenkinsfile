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
    OPSRepoBranch = 'ecs-spot'
    Tag = "1.0.0"
    Email = 'vecinomio@gmail.com'
    DelUnusedImage = 'docker image prune -af --filter="label=maintainer=devopsa3"'
  }
  stages {
    stage("Condition") {
      steps {
        script {
          if (env.BRANCH_NAME == 'master') {
            Tag = "release-${Tag}"
          } else {
            Tag = "${BRANCH_NAME}-${Tag}"
          }
        }
      }
    }
    stage("Build app") {
      steps {
        script {
          // if (env.TAG_NAME) {
          //   Tag = env.TAG_NAME
          // } else {
          //   Tag = env.BUILD_NUMBER
          // }
          try {
            sh 'cd eb-tomcat-snakes && ./build.sh'
            currentBuild.result = 'SUCCESS'
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
    stage("Push artifact to ECR") {
      steps {
        script {
          try {
            sh '$(aws ecr get-login --no-include-email --region us-east-1)'
            docker.withRegistry("https://${ECRURI}") {
              dockerImage.push()
            }
            currentBuild.result = 'SUCCESS'
            emailext body: 'Docker Image was successfully delivered to ECR.', subject: "JOB with identifier ${Tag} SUCCESS", to: "${Email}"
          }
          catch (err) {
            sh "${DelUnusedImage}"
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. Delivery to ECR Failed, check logs.", subject: "JOB with identifier ${Tag} FAILED", to: "${Email}"
            throw (err)
          }
          echo "result is: ${currentBuild.currentResult}"
        }
      }
    }
    stage("Tagging") {
      steps {
        sh "git tag -a ${Tag} -m 'Added tag ${Tag}'"
        sh "git push origin ${Tag}"
      }
    }
    stage("CleanUp") {
      steps {
        echo "====================== Removing images ====================="
        sh "${DelUnusedImage}"
        sh 'docker images'
      }
    }
    stage("Create stack") {
      when { buildingTag() }
      steps {
        script {
          try {
            git(url: "${OPSRepoURL}", branch: "${OPSRepoBranch}")
            sh "aws cloudformation deploy --stack-name ECS-task --template-file ops/cloudformation/ecs-task.yml --parameter-overrides ImageUrl=${ECRURI}/${AppRepoName}:${Tag} --region us-east-1"
            currentBuild.result = 'SUCCESS'
            emailext body: 'Application was successfully deployed to ECS.', subject: "JOB with identifier ${Tag} SUCCESS", to: "${Email}"
          }
          catch (err) {
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. ECS Stack Creation Failed, check logs.", subject: "JOB with identifier ${Tag} FAILED", to: "${Email}"
            throw (err)
          }
          echo "result is: ${currentBuild.currentResult}"
        }
      }
    }
  }
}
