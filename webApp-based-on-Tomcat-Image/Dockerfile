FROM tomcat:8

LABEL maintainer="devopsa3" \
      description="tomcat-8 image with application about snakes"

WORKDIR /home/project

COPY . .

RUN mv /usr/local/tomcat/webapps/ROOT/ /usr/local/tomcat/webapps/default-ROOT

RUN cd eb-tomcat-snakes && cp ROOT.war /usr/local/tomcat/webapps/

HEALTHCHECK --interval=5s --timeout=10s --retries=5 CMD curl -sS http://127.0.0.1:8080 || exit 1

EXPOSE 8080
