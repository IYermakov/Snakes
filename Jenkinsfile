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
    booleanParam(name: 'TAG', defaultValue: false, description: 'TAG git commit and docker image')
    booleanParam(name: 'Push to ECR', defaultValue: false, description: 'Push docker image to ECR')
    booleanParam(name: 'Deploy ECS stack', defaultValue: false, description: 'Deploy ECS stack')
    choice(name: 'Tagging', choices: ['Save OLD version', 'Increase Minor  version', 'Increase Middle version', 'Increase Major  version'], description: 'Pick Version Tag')
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
  }

  stages{
    stage("preparation"){
      steps {
         sh 'echo Build Preparation'
         checkout scm
      }
    }

    stage("Parsing of version A.B.C"){
      steps {
        script {
            sh ''' echo "Executing Tagging"
            version=\$(git describe --tags `git rev-list --tags --max-count=1`)
            # Version to get the latest tag
            A=\$(echo \$version | cut -d '.' -f 1)
            B=\$(echo \$version | cut -d '.' -f 2)
            C=\$(echo \$version | cut -d '.' -f 3)
            echo A= \$A, B=\$B, C=\$C

            if [ \$C -gt 8 ]
                then
                    if [ \$B -gt 8 ]
                        then
                            A=\$((A+1))
                            B=0 C=0
                    else
                        B=\$((B+1))
                        C=0
                    fi
            else
                C=\$((C+1))
            fi
            echo "[\$A.\$B.\$C]" > outFile
            echo Try to read outFile
            cat outFile
            let A++
            let B++
            let C++
            echo "[\$A]" > outFileA
            echo "[\$B]" > outFileB
            echo "[\$C]" > outFileC
            echo Increased: A= \$A, B=\$B, C=\$C
            '''
            nextVersion = readFile 'outFile'
            nextVersionA = readFile 'outFileA'
            nextVersionB = readFile 'outFileB'
            nextVersionC = readFile 'outFileC'
            echo "Current version is A='${nextVersionA}'  B='${nextVersionB}'  C='${nextVersionC}'  "
            echo "we will tag '${nextVersion}'"
            result = nextVersion.substring(nextVersion.indexOf("[")+1,nextVersion.indexOf("]"));
            echo "we will tag '${result}'"
            echo "Choice: ${params.Tagging}"
        }
      }
    }

    stage("Choice --SaveOldVersion"){
      when {
        equals expected: "Save OLD version", actual: params.Tagging
      }
      steps {
        echo 'Deploying --SaveOldVersion'
        echo "we will not tag '${nextVersionA}'.'${nextVersionB}'.'${nextVersionC}'"
        echo "Current version is A='${nextVersionA}'  B='${nextVersionB}'  C='${nextVersionC}'  "
      }
    }

    stage("Choice --IncreaseMinorVersion"){
      when {
        equals expected: "Increase Minor  version", actual: params.Tagging
      }
      steps {
        echo 'Deploying --IncreaseMinorVersion'

        echo "Current version is A='${nextVersionA}'  B='${nextVersionB}'  C='${nextVersionC}'  "
      }
    }

    stage("Choice --IncreaseMiddleVersion"){
      when {
        equals expected: "Increase Middle version", actual: params.Tagging
      }
      steps {
        echo 'Deploying --IncreaseMiddleVersion'

        echo "Current version is A='${nextVersionA}'  B='${nextVersionB}'  C='${nextVersionC}'  "
      }
    }

    stage("Choice --IncreaseMajorVersion"){
      when {
        equals expected: "Increase Major  version", actual: params.Tagging
      }
      steps {
        echo 'Deploying --IncreaseMajorVersion'

        echo "Current version is A='${nextVersionA}'  B='${nextVersionB}'  C='${nextVersionC}'  "
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
    stage("MyStep") {
      when { environment name: 'RELEASE_VERSION', value: '1.0.0' }
      steps {
        script {
          sh 'echo ${RELEASE_VERSION} ${TAG}'
          sh 'export LAST_GIT_TAG="$(git tag | sort -V | tail -1)"'
          sh 'echo Find env variable'
          sh 'echo LAST_GIT_TAG = "$LAST_GIT_TAG"'
          sh ('printenv | sort')
        }
      }
    }
  }
}
