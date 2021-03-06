FROM centos

ENV SCALA_VERSION 2.12
ENV KAFKA_VERSION 2.3.0
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"

# Install Kafka, Zookeepe, Kerberos Server and other stuff needed.
RUN yum update -y && \
    yum install -y epel-release wget nc net-tools openssl krb5-workstation krb5-libs java which && \
    yum install -y python3-pip && \
    pip3 install supervisor && \
    wget -q \
        http://apache.mirrors.spacedump.net/kafka/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz \
        -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && \
    rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    yum -y install krb5-server krb5-libs krb5-workstation && \
    yum clean all

# Add scripts
ADD scripts/start-all.sh /usr/bin/start-all.sh
ADD scripts/start-kafka.sh /usr/bin/start-kafka.sh
ADD scripts/start-zookeeper.sh /usr/bin/start-zookeeper.sh
ADD scripts/configure-kerberos-server.sh /usr/bin/configure-kerberos-server.sh
ADD scripts/configure-kerberos-client.sh /usr/bin/configure-kerberos-client.sh

# Used for debugging
# ADD config/log4j.properties "$KAFKA_HOME"/config/
ADD config/zookeeper.jaas.tmpl config/kafka.jaas.tmpl "$KAFKA_HOME"/config/

RUN mkdir -p /tmp/zookeeper && \
    mkdir -p /tmp/kafka-logs && \
    mkdir -p /var/log/supervisor && \
    mkdir -p /var/log/zookeeper && \
    mkdir -p /var/lib/krb5kdc/ && \
    mkdir -p /keytabs/ && \
    mkdir "$KAFKA_HOME"/logs && \
    mkdir -p /var/private/ssl/ && \
    chmod -R 777 /var/log/supervisor/ && \
    chmod -R 777 /var/log/zookeeper/ && \
    chmod -R 777 /var/run/ && \
    chmod -R 777 "$KAFKA_HOME"/logs && \
    chmod -R 777 "$KAFKA_HOME"/config && \
    chmod -R 777  /tmp/zookeeper && \
    chmod -R 777  /tmp/kafka-logs && \
    chmod -R 777  /etc/ && \
    chmod -R 777 /var/lib/krb5kdc/ && \
    chmod -R 777 /var/kerberos/krb5kdc/ && \
    chmod -R 777 /var/log/ && \
    chmod -R 777 /keytabs/ && \
    chmod -R 777 /var/private/ssl

# Supervisor config
ADD supervisor/kerberos.ini supervisor/initialize.ini supervisor/kafka.ini supervisor/zookeeper.ini /etc/supervisord.d/
RUN echo_supervisord_conf | sed -e 's:;\[include\]:\[include\]:g' | sed -e 's:;files = relative/directory/\*.ini:files = /etc/supervisord.d/\*.ini:g' > /etc/supervisord.conf

# 2181 is zookeeper, 9092-9099 is kafka (for different listeners like SSL, INTERNAL, PLAINTEXT etc.)
EXPOSE 2181 9092 9093 9094 9095 9096 9097 9098 9099 8888 8464 8749

CMD ["supervisord", "-n"]
