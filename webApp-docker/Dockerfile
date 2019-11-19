FROM alpine

RUN apk add openjdk8

RUN apk --update add --no-cache openssh bash \
  && sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config \
  && echo "root:root" | chpasswd \
  && rm -rf /var/cache/apk/* \
  && sed -ie 's/#Port 22/Port 22/g' /etc/ssh/sshd_config \
  && sed -ri 's/#HostKey \/etc\/ssh\/ssh_host_key/HostKey \/etc\/ssh\/ssh_host_key/g' /etc/ssh/sshd_config \
  && sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey \/etc\/ssh\/ssh_host_rsa_key/g' /etc/ssh/sshd_config \
  && sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_dsa_key/HostKey \/etc\/ssh\/ssh_host_dsa_key/g' /etc/ssh/sshd_config \
  && sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/g' /etc/ssh/sshd_config \
  && sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_ed25519_key/HostKey \/etc\/ssh\/ssh_host_ed25519_key/g' /etc/ssh/sshd_config \
  && /usr/bin/ssh-keygen -A \
  && ssh-keygen -t rsa -b 4096 -f  /etc/ssh/ssh_host_key

RUN cd /usr/local/ \
  && wget http://apache.volia.net/tomcat/tomcat-8/v8.5.47/bin/apache-tomcat-8.5.47.tar.gz \
  && tar xzf apache-tomcat-8.5.47.tar.gz \
  && mv apache-tomcat-8.5.47/ tomcat/ \
  && rm apache-tomcat-8.5.47.tar.gz

CMD [ "/usr/local/tomcat/bin/catalina.sh", "run"]

HEALTHCHECK --interval=5s --timeout=10s --retries=5 CMD curl -sS 127.0.0.1:8080 || exit 1

EXPOSE :8080
EXPOSE :22
