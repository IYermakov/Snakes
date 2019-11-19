FROM alpine

LABEL maintainer="devopsa3"

RUN apk add openjdk8 curl

RUN cd /usr/local/ \
  && wget http://apache.volia.net/tomcat/tomcat-8/v8.5.47/bin/apache-tomcat-8.5.47.tar.gz \
  && tar xzf apache-tomcat-8.5.47.tar.gz \
  && mv apache-tomcat-8.5.47/ tomcat/ \
  && rm apache-tomcat-8.5.47.tar.gz

RUN rm -rf /usr/local/tomcat/webapps/ROOT/

COPY ROOT.war /usr/local/tomcat/webapps/
 
CMD [ "/usr/local/tomcat/bin/catalina.sh", "run"]

HEALTHCHECK --interval=5s --timeout=10s --retries=5 CMD curl -sS http://127.0.0.1:8080 || exit 1

EXPOSE :8080
