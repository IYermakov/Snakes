ARG app_name=ROOT

FROM tomcat:8
ARG app_name
LABEL maintainer = "imaki" \
      description = "tomcat-8 image with application about snakes"

WORKDIR /home/project
COPY . .
RUN mv /usr/local/tomcat/webapps/ROOT/ /usr/local/tomcat/webapps/default-ROOT
RUN cd eb-tomcat-snakes && cp ${app_name}.war /usr/local/tomcat/webapps/
EXPOSE 8080
#CMD ["catalina.sh", "run"]
