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
  }
  environment {
    ECRURI = '054017840000.dkr.ecr.us-east-1.amazonaws.com'
    AppRepoName = 'snakes'
    OPSRepoURL = 'git@github.com:IYermakov/DevOpsA3Training.git'
    OPSRepoBranch = 'ecs-spot'

    Tag = "${params.RELEASE_VERSION}"
    Email = 'vecinomio@gmail.com'
    DelUnusedImage = 'docker image prune -af --filter="label=maintainer=devopsa3"'
  }
  stages {
    // stage('checkout') {
    //   steps {
    //     checkout([$class: 'GitSCM', branches: [[name: tagVersion]],
    //               userRemoteConfigs: [[url: 'git@github.com:IYermakov/Snakes.git',
    //                                    credentialsId: 'snakes']]
    //             ])
    //   }
    // }
    stage("Condition") {
      steps {
        script {
          if (env.BRANCH_NAME == 'master-test') {
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
        script {
          try {
            sh "git tag -a ${Tag} -m 'Added tag ${Tag}'"
            sh "git push origin ${Tag}"
            sh "rm -rf ${OPSRepoBranch}"
            sh "mkdir -p ${OPSRepoBranch}"
            dir("${OPSRepoBranch}") {
              git(url: "${OPSRepoURL}", branch: "${OPSRepoBranch}", credentialsId: "devopsa3")
              sshagent (credentials: ['devopsa3']) {
                sh "git tag -a ${Tag} -m 'Added tag ${Tag}'"
                sh "git push origin ${Tag}"
              }
            }
            currentBuild.result = 'SUCCESS'
          }
          catch (err) {
            sh "${DelUnusedImage}"
            sh "pwd && rm -rf ${OPSRepoBranch}"
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. Tagging Stage Failed, check logs.", subject: "JOB with identifier ${Tag} FAILED", to: "${Email}"
            throw (err)
          }
          echo "result is: ${currentBuild.currentResult}"
        }
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
      when { branch 'master-test' }
      steps {
        script {
          try {
            dir("${OPSRepoBranch}") {
              sh "aws cloudformation deploy --stack-name ECS-task --template-file ops/cloudformation/ecs-task.yml --parameter-overrides ImageUrl=${ECRURI}/${AppRepoName}:${Tag} --capabilities CAPABILITY_IAM --region us-east-1"
            }
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
