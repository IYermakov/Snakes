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
    booleanParam(name: 'Build application', defaultValue: true, description: 'Build Java   web application')
    booleanParam(name: 'Build Docker Image', defaultValue: false, description: 'Build Docker Image with Java web application')
    booleanParam(name: 'Test', defaultValue: false, description: 'Test Docker Image with Java web application')
    booleanParam(name: 'Push to ECR', defaultValue: false, description: 'Push docker image to ECR')
    booleanParam(name: 'Deploy ECS stack', defaultValue: false, description: 'Deploy ECS stack')
    booleanParam(name: 'SetNewTag', defaultValue: false, description: 'TAG git commit and docker image')
    choice(name: 'Tagging', choices: ['Minor', 'Middle', 'Major'], description: 'Pick Version Tag')
  }
  environment {
    ECRURI = '054017840000.dkr.ecr.us-east-1.amazonaws.com'
    AppRepoName = 'snakes'
    OPSRepoURL = 'git@github.com:IYermakov/DevOpsA3Training.git'
    OPSRepoBranch = 'ecs-spot'

    Tag = "${params.RELEASE_VERSION}"
    Email = 'vecinomio@gmail.com'
    DelUnusedImage = 'docker image prune -af --filter="label=maintainer=devopsa3"'
    String result='0.0.0';
    ChoiceResult = "${params.Tagging}"
  }

  stages{
    stage("Preparation"){
      steps {
         sh 'echo Build Preparation'
         checkout scm
      }
    }

    stage("Tagging"){
      when { environment name: 'SetNewTag', value: 'true' }
      steps {
        script {
            sh ''' echo "Executing Tagging"
            version=\$(git describe --tags `git rev-list --tags --max-count=1`)
            FirstSet=\$(echo \$version | cut -d '.' -f 1)
            if [ \${#FirstSet} -ge 2 ];
                then
                    Prefix=\$(echo \$FirstSet | cut -d '-' -f 1)
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
            echo "[\$Prefix-\$A.\$B.\$C]" > outFile
            echo Increased: A=\$A, B=\$B, C=\$C
            '''
            nextVersion = readFile 'outFile'
            result = nextVersion.substring(nextVersion.indexOf("[")+1,nextVersion.indexOf("]"));
            echo "We will --tag '${result}'"

            // Set new Tag
            sh "git status"
            sh "git tag -a ${result} -m 'Added tag ${result}'"
            sh "git push origin ${result}"
        }
      }
    }

    stage("Build app") {
      when { environment name: 'Build application', value: 'true' }
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
      when { environment name: 'Build Docker Image', value: 'true' }
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
      when { environment name: 'Test', value: 'true' }
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
