#!groovy
//Only one build can run
properties([disableConcurrentBuilds()])

def RemoveUnusedImages() {
  sh 'docker image prune -af --filter="label=maintainer=devopsa3"'
}
def LastTag() {
  return "git describe --tags `git rev-list --tags --max-count=1`"
}
pipeline {
  agent {
    label 'master'
  }
  options {
    buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '5'))
    timestamps()
  }
  parameters {
    string(name: 'AWSRegion', defaultValue: 'us-east-1', description: 'Enter the desired AWS region')
    string(name: 'ECRURI', defaultValue: '054017840000.dkr.ecr.us-east-1.amazonaws.com', description: 'Enter the URI of the Container Registry')
    string(name: 'Email', defaultValue: 'vecinomio@gmail.com', description: 'Enter the desired Email for the Job notifications')
    string(name: 'SetNewTag', defaultValue: LastTag(), description: 'New tag will be')
    booleanParam(name: 'Build', defaultValue: true, description: 'Includes Build app and Tests')
    booleanParam(name: 'Release', defaultValue: false, description: 'Includes Tagging and Delivery')
    booleanParam(name: 'Deployment', defaultValue: false, description: 'Deploy a new version of App')
    // booleanParam(name: 'SetNewTag', defaultValue: false, description: 'Auto-increasing version')
    choice(name: 'AppVersion', choices: ['Minor', 'Middle', 'Major'], description: 'Pick Version Tag')
    choice(name: 'NewVersionTrafficWeight', choices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], description: 'Amount of traffic to the new vesion of the App')
  }
  environment {
    ECRURI = "${params.ECRURI}"
    AWSRegion = "${params.AWSRegion}"
    AppRepoName = 'snakes'
    OPSRepoURL = 'git@github.com:IYermakov/DevOpsA3Training.git'
    OPSRepoBranch = 'weighted-tgs'
    BuildAndTest = "${params.Build}"
    Release = "${params.Release}"
    Deployment = "${params.Deployment}"
    StartVersionFrom = '1.0.0'
    ChoiceResult = "${params.Version}"
    CurrentVersionTrafficWeight = (10 - "${params.NewVersionTrafficWeight}".toInteger()).toString()
    Email = "${params.Email}"
    FailureEmailSubject = "JOB with identifier ${Tag} FAILED"
    SuccessEmailSubject = "JOB with identifier ${Tag} SUCCESS"
  }

  stages {
    stage("Versioning"){
      when { environment name: 'SetNewTag', value: 'true' }
      steps {
        script {
            sh """
            version=\$(git describe --tags `git rev-list --tags --max-count=1` || echo ${StartVersionFrom})
            FirstSet=\$(echo \$version | cut -d '.' -f 1)
            if [ \${#FirstSet} -ge 2 ];
                then
                    Prefix=\$(echo \$FirstSet | cut -d '-' -f 1)-
                    A=\$(echo \$FirstSet | cut -d '-' -f 2)
                else
                    Prefix=""
                    A=\$FirstSet
            fi
            B=\$(echo \$version | cut -d '.' -f 2)
            C=\$(echo \$version | cut -d '.' -f 3)
            echo " *** ORIGIN VERSION A=\$A, B=\$B, C=\$C *** "
            if [ ${ChoiceResult} == "Major" ]
                then
                    A=\$((A+1))
                    B=0
                    C=0
                    echo "Executing Major"
            fi
            if [ ${ChoiceResult} == "Middle" ]
                then
                    B=\$((B+1))
                    C=0
                    echo "Executing Middle"
                else
                    C=\$((C+1))
                    echo "Executing Minor"
            fi
            echo "[\$Prefix\$A.\$B.\$C]" > outFile
            echo Increased: A=\$A, B=\$B, C=\$C
            """
            nextVersion = readFile 'outFile'
            Tag = nextVersion.substring(nextVersion.indexOf("[")+1,nextVersion.indexOf("]"));
        }
      }
    }
    stage("Condition") {
      steps {
        script {
          if (Release == 'false') {
            Tag = "${BUILD_NUMBER}"
          }
        }
      }
    }
    stage("Build") {
      when { environment name: 'BuildAndTest', value: 'true' }
      steps {
        script {
          try {
            sh 'cd eb-tomcat-snakes && ./build.sh'
            currentBuild.result = 'SUCCESS'
          }
          catch (err) {
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. Build Application Failed, check logs.", subject: "${FailureEmailSubject}", to: "${Email}"
            throw (err)
          }
          echo "result is: ${currentBuild.currentResult}"
        }
      }
    }
    stage("Build Docker Image") {
      when { environment name: 'BuildAndTest', value: 'true' }
      steps {
        script {
          try {
            dockerImage = docker.build("${ECRURI}/${AppRepoName}:${Tag}")
            currentBuild.result = 'SUCCESS'
          }
          catch (err) {
            RemoveUnusedImages()
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. Build Docker Image Failed, check logs.", subject: "${FailureEmailSubject}", to: "${Email}"
            throw (err)
          }
          echo "result is: ${currentBuild.currentResult}"
        }
      }
    }
    stage("Test") {
      when { environment name: 'BuildAndTest', value: 'true' }
      steps {
        script {
          try {
            testContainer = dockerImage.run('-p 8090:8080 --name test')
            sh 'sleep 10'
            sh 'curl -sS http://localhost:8090 | grep "Does it have snakes?"'
            testContainer.stop()
            currentBuild.result = 'SUCCESS'
          }
          catch (err) {
            testContainer.stop()
            RemoveUnusedImages()
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. Test Failed, check logs.", subject: "${FailureEmailSubject}", to: "${Email}"
            throw (err)
          }
        }
      }
    }
    stage("Delivery") {
      when { environment name: 'Release', value: 'true' }
      steps {
        script {
          try {
            sh '$(aws ecr get-login --no-include-email --region ${AWSRegion})'
            docker.withRegistry("https://${ECRURI}") {
              dockerImage.push()
            }
            currentBuild.result = 'SUCCESS'
          }
          catch (err) {
            RemoveUnusedImages()
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. Delivery to ECR Failed, check logs.", subject: "${FailureEmailSubject}", to: "${Email}"
            throw (err)
          }
          echo "result is: ${currentBuild.currentResult}"
        }
      }
    }
    stage("Tagging") {
      when { environment name: 'Release', value: 'true' }
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
            RemoveUnusedImages()
            sh "rm -rf ${OPSRepoBranch}"
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. Tagging Stage Failed, check logs.", subject: "${FailureEmailSubject}", to: "${Email}"
            throw (err)
          }
          echo "result is: ${currentBuild.currentResult}"
        }
      }
    }
    stage("CleanUp") {
      steps {
        RemoveUnusedImages()
      }
    }
    stage("Deployment") {
      when { environment name: 'Deployment', value: 'true' }
      steps {
        script {
          try {
            dir("${OPSRepoBranch}") {
              UnicId = "${Tag}".replaceAll("\\.", "-")
              sh """
                 CurrentStack=\$(aws cloudformation describe-stacks --output text --query "Stacks[?contains(StackName,'ECS-task')].[StackName]" --region ${AWSRegion} | tail -1)
                 CurrentDeploymentColor=\$(aws cloudformation describe-stacks --stack-name \$CurrentStack --query "Stacks[].Parameters[?ParameterKey=='DeploymentColor'].ParameterValue" --output text --region ${AWSRegion} | tail -1)
                 NewDeploymentColor="Green"
                 if [ \$CurrentDeploymentColor == "Green" ]
                     then
                         NewDeploymentColor="Blue"
                 fi
                 aws cloudformation deploy --stack-name ECS-task-${UnicId} --template-file ops/cloudformation/ECS/ecs-task.yml --parameter-overrides ImageUrl=${ECRURI}/${AppRepoName}:${Tag} ServiceName=snakes-${UnicId} DeploymentColor=\$NewDeploymentColor --capabilities CAPABILITY_IAM --region ${AWSRegion}
                 aws cloudformation deploy --stack-name alb --template-file ops/cloudformation/alb.yml --parameter-overrides VPCStackName=DevVPC \${CurrentDeploymentColor}Weight=${CurrentVersionTrafficWeight} \${NewDeploymentColor}Weight=${NewVersionTrafficWeight} --capabilities CAPABILITY_IAM --region ${AWSRegion}
                 """
            }
            currentBuild.result = 'SUCCESS'
            emailext body: 'New release was successfully deployed to ECS.', subject: "${SuccessEmailSubject}", to: "${Email}"
          }
          catch (err) {
            currentBuild.result = 'FAILURE'
            emailext body: "${err}. ECS Stack Creation Failed, check logs.", subject: "${FailureEmailSubject}", to: "${Email}"
            throw (err)
          }
          echo "result is: ${currentBuild.currentResult}"
        }
      }
    }
  }
}
