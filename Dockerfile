ARG tomcat_version=9.0.29

FROM alpine

ENV tomcat_version=${tomcat_version}

LABEL maintainer="devopsa3"

RUN apk add openjdk8 curl

RUN cd /usr/local/ \
  && tomcat_ver_maj_okt=$(echo ${tomcat_version} | cut -d '.' -f 1) \
  && wget http://apache.ip-connect.vn.ua/tomcat/tomcat-${tomcat_ver_maj_okt}/v${tomcat_version}/bin/apache-tomcat-${tomcat_version}.tar.gz \
  && tar xzf apache-tomcat-${tomcat_version}.tar.gz \
  && mv apache-tomcat-${tomcat_version}/ tomcat/ \
  && rm apache-tomcat-${tomcat_version}.tar.gz

WORKDIR /home/project

COPY . .

RUN mv /usr/local/tomcat/webapps/ROOT/ /usr/local/tomcat/webapps/default-ROOT

RUN cd eb-tomcat-snakes && cp ROOT.war /usr/local/tomcat/webapps/

CMD [ "/usr/local/tomcat/bin/catalina.sh", "run"]

HEALTHCHECK --interval=5s --timeout=10s --retries=5 CMD curl -sS http://127.0.0.1:8080 || exit 1

EXPOSE :8080
