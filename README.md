# Snakes web application
Snakes is Java-based web application hosted on Tomcat server.
The main goal is not to create complex functionality, but configure optimal CI/CD, git, tag flow and other DevOps related processes.

 
## Application requirements
Install the Java 8 JDK. The java compiler is required to run the build script. 
Install Tomcat 8+ to run compiled WAR file.

## Manual deployment
To download, build and deploy the project:
- Clone the project 
- Run build.sh to compile the web app and create a WAR file

**IMPORTANT**
Always run build.sh from the root of the project directory.
The script compiles the project's classes, packs the necessary files into a web archive

- Paste WAR file to Tomcat server.
Open [localhost:8080](http://localhost:8080/) in a web browser to check the running application.

## Automatic deployment with Jenkins
Repository consist two Jenkins pipeline scripts for deployment management.
Deployment works with Docker image and use AWS ECS/ECR services.

##### Jenkinsfile 
Is Managing deployment of new AWS CFN Stack. Using "Build with parameters" we can manipulate with new AWS CloudFormation stack parameters.

##### Jenkinsfile2 
Is Managing Application Load Balancer parameters and can destroy AWS CFN stack with outdated version of application. 

Link to Jenkins:
https://ci.devopsa3.me.uk/

Link to origin application:
https://github.com/aws-samples/eb-tomcat-snakes
