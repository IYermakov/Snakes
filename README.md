# Snakes web application
Snakes is Java-based web application hosted on Tomcat server.
The main goal is not to create complex functionality, but configure optimal CI/CD, git, tag flow and other DevOps related processes.

 
## Application requirements
Install the Java 8 JDK. The java compiler is required to run the build script. 
For Ubuntu or Debian would run:

    $ sudo apt update 
    $ sudo apt install openjdk-8-jdk
    $ java -version

Install Tomcat 8+ to run compiled WAR file.

For Ubuntu or Debian would run:

    $ sudo groupadd tomcat
    $ sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
    $ wget http://apache.ip-connect.vn.ua/tomcat/tomcat-9/v9.0.29/bin/apache-tomcat-9.0.29.tar.gz
    $ tar xzf apache-tomcat-9.0.29.tar.gz
    $ sudo mkdir /opt/tomcat
    $ mv apache-tomcat-9.0.29/ /opt/tomcat/
    $ sudo chown -R tomcat: /opt/tomcat
    $ sudo sh -c 'chmod +x /opt/tomcat/bin/*.sh'
    $ /opt/tomcat/bin/catalina.sh run
    
and you should see Tomcat default page    

    # curl http://localhost:8080/

## Manual application deployment
To download, build and deploy the project:
- Clone the project 

        $ git clone https://github.com/IYermakov/Snakes.git
    
- Run build.sh to compile the web app and create a WAR file
        
        $ cd Snakes/
        $ sudo sh -c 'chmod +x eb-tomcat-snakes/build.sh'
        $ eb-tomcat-snakes/build.sh

**IMPORTANT**
Always run build.sh from the root of the project directory.
The script compiles the project's classes, packs the necessary files into a web archive

- Paste WAR file to Tomcat server.

        $ sudo rm -rf /opt/tomcat/webapps/ROOT/
        $ cd eb-tomcat-snakes && cp ROOT.war /opt/tomcat/webapps/

Open [localhost:8080](http://localhost:8080/) in a web browser to check the running application.

## Сontainerized deployment
We can use containerized tool - Docker to run the application.
Repository already have Dockerfile which contain strict commands for container building.

### Build docker image with application:
Navigate to folder that contain Dockerfile and build:

    $ docker build -t snakes-web-application .

Run docker container from previously builded image:

    $ docker run -d -p 8080:8080 --name snakes snakes-web-application

Check the result

    $ docker ps
    $ curl http://localhost:8080/

## Automatic deployment with Jenkins
Repository consist two Jenkins pipeline scripts for deployment management.
Deployment works with Docker image and use AWS ECS/ECR services.

##### Jenkinsfile 
Is Managing deployment of new AWS CFN Stack. Using "Build with parameters" we can manipulate with new AWS CloudFormation stack parameters.

##### Jenkinsfile2 
Is Managing Application Load Balancer parameters and can destroy AWS CFN stack with outdated version of application. 

Link to Jenkins:
https://ci.devopsa3.me.uk/

Link to application:
https://www.devopsa3.me.uk/
