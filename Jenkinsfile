#!groovy
//Only one build can run
properties([disableConcurrentBuilds()])

def RemoveUnusedImages() {
  sh 'docker image prune -af --filter="label=maintainer=devopsa3"'
}
def GetRegions() {
  return [
    'us-east-1', 'us-east-2', 'us-west-1', 'us-west-2', 'ap-east-1', 'ap-south-1',
    'ap-southeast-1', 'ap-southeast-2', 'ap-northeast-1', 'ap-northeast-2', 'ap-northeast-3',
    'ca-central-1', 'cn-north-1', 'cn-northwest-1', 'eu-central-1', 'eu-west-1', 'eu-west-2',
    'eu-west-3', 'eu-north-1', 'me-south-1', 'sa-east-1'
  ]
}

node {
  StartVersionFrom = '0.0.0'
  LastRelease = sh (script: "git describe --tags `git rev-list --tags --max-count=1` || echo ${StartVersionFrom}", returnStdout: true).trim()
  sh (script:
    """
    FirstSet=\$(echo ${LastRelease} | cut -d '.' -f 1)
    if [ \${#FirstSet} -ge 2 ];
        then
            Prefix=\$(echo \$FirstSet | cut -d '-' -f 1)-
            A=\$(echo \$FirstSet | cut -d '-' -f 2)
        else
            Prefix=""
            A=\$FirstSet
    fi
    B=\$(echo ${LastRelease} | cut -d '.' -f 2)
    C=\$(echo ${LastRelease} | cut -d '.' -f 3)
    echo " *** ORIGIN VERSION A=\$A, B=\$B, C=\$C *** "
    echo "[\$Prefix\$A.\$B.\$((C+1))]" > outFile
    echo Increased: A=\$A, B=\$B, C=\$C
    """
  )
  nextVersion = readFile 'outFile'
  NewRelease = nextVersion.substring(nextVersion.indexOf("[")+1,nextVersion.indexOf("]"));
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
    string(name: "NewRelease", defaultValue: "${NewRelease}", description: "Your Current Release is: ${LastRelease} Change the version of New Release if necessary")
    string(name: 'ECRURI', defaultValue: '054017840000.dkr.ecr.us-east-1.amazonaws.com', description: 'Enter the URI of the Container Registry')
    string(name: 'Email', defaultValue: 'vecinomio@gmail.com', description: 'Enter the desired Email for the Job notifications')
    choice(
      choices: GetRegions(), name: 'AWSRegion', description: 'Choose the desired AWS region'
    )
    booleanParam(name: 'Build', defaultValue: true, description: 'Specify to Build App and do Tests')
    booleanParam(name: 'Release', defaultValue: false, description: 'Specify to deliver an artifact to ECR and tags to Github repos')
    booleanParam(name: 'Deployment', defaultValue: false, description: 'Specify to Deploy a new version of App to ECS')
    choice(name: 'NewVersionTrafficWeight', choices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], description: 'Choose amount of traffic to the new vesion of the App')
  }
  environment {
    ECRURI = "${params.ECRURI}"
    AWSRegion = "${params.AWSRegion}"
    AppRepoName = 'snakes'
    OPSRepoURL = 'git@github.com:IYermakov/DevOpsA3Training.git'
    OPSRepoBranch = 'master'
    BuildAndTest = "${params.Build}"
    Release = "${params.Release}"
    Deployment = "${params.Deployment}"
    Tag = "${params.NewRelease}"
    MaxWeight = 10
    CurrentVersionTrafficWeight = (MaxWeight - "${params.NewVersionTrafficWeight}".toInteger()).toString()
    Email = "${params.Email}"
    FailureEmailSubject = "JOB with identifier ${Tag} FAILED"
    SuccessEmailSubject = "JOB with identifier ${Tag} SUCCESS"
  }

  stages {
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
            retry(10) {
              sh 'sleep 5'
              sh 'curl -sS http://localhost:8090 | grep "Does it have snakes?"'
            }
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
