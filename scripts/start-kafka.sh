#!/bin/sh
# Configure kerberos for kafka
echo "Make sure new config items are put at end of config file even if no newline is present as final character in the config"
echo >> $KAFKA_HOME/config/server.properties    

echo "set SASL mechanism"
if grep -r -q "^#\?sasl.enabled.mechanisms" $KAFKA_HOME/config/server.properties; then
  sed -r -i "s/#?(sasl.enabled.mechanisms)=(.*)/\1=GSSAPI/g" $KAFKA_HOME/config/server.properties
else
  echo "sasl.enabled.mechanisms=GSSAPI" >> $KAFKA_HOME/config/server.properties
fi
  
echo "set Kerberos service name for kafka"
KAFKA_KRB_SERVICE_NAME="kafka"
if grep -r -q "^#\?sasl.kerberos.service.name" $KAFKA_HOME/config/server.properties; then
  sed -r -i "s/#?(sasl.kerberos.service.name)=(.*)/\1=${KAFKA_KRB_SERVICE_NAME}/g" $KAFKA_HOME/config/server.properties
else
  echo "sasl.kerberos.service.name=${KAFKA_KRB_SERVICE_NAME}" >> $KAFKA_HOME/config/server.properties
fi
  
echo "create jaas config based on template"
sed "s/HOSTNAME/$(hostname -f)/g" $KAFKA_HOME/config/kafka.jaas.tmpl > $KAFKA_HOME/config/kafka.jaas  
export KAFKA_OPTS="-Djava.security.auth.login.config=${KAFKA_HOME}/config/kafka.jaas -Djava.security.krb5.conf=/etc/krb5.conf -Dsun.security.krb5.debug=true"

AUTOCREATE_TOPIC="true"
if grep -r -q "^#\?auto.create.topics.enable" $KAFKA_HOME/config/server.properties; then
  sed -r -i "s/#?(auto.create.topics.enable)=(.*)/\1=${AUTOCREATE_TOPIC}/g" $KAFKA_HOME/config/server.properties
else
  echo "auto.create.topics.enable=${AUTOCREATE_TOPIC}" >> $KAFKA_HOME/config/server.properties
fi

ADVERTISED_LISTENERS="LISTENER_DOCKER_INTERNAL://localhost:19092,LISTENER_DOCKER_EXTERNAL://localhost:9092"
if grep -r -q "^#\?advertised.listeners=" $KAFKA_HOME/config/server.properties; then
  sed -r -i "s|^#?(advertised.listeners)=(.*)|\1=${ADVERTISED_LISTENERS}|g" $KAFKA_HOME/config/server.properties
else
  echo "advertised.listeners=${ADVERTISED_LISTENERS}" >> $KAFKA_HOME/config/server.properties
fi

ADVERTISED_HOST="localhost"
if grep -r -q "^#\?advertised.host.name=" $KAFKA_HOME/config/server.properties; then
  sed -r -i "s|^#?(advertised.host.name)=(.*)|\1=${ADVERTISED_HOST}|g" $KAFKA_HOME/config/server.properties
else
  echo "advertised.host.name=${ADVERTISED_HOST}" >> $KAFKA_HOME/config/server.properties
fi

LISTENERS="LISTENER_DOCKER_INTERNAL://0.0.0.0:19092,LISTENER_DOCKER_EXTERNAL://0.0.0.0:9092"
if grep -r -q "^#\?listeners=" $KAFKA_HOME/config/server.properties; then
    # use | as a delimiter to make sure // does not confuse sed
    sed -r -i "s|^#?(listeners)=(.*)|\1=${LISTENERS}|g" $KAFKA_HOME/config/server.properties
else
    echo "listeners=${LISTENERS}" >> $KAFKA_HOME/config/server.properties
fi

SECURITY_PROTOCOL_MAP="LISTENER_DOCKER_INTERNAL:PLAINTEXT,LISTENER_DOCKER_EXTERNAL:SASL_PLAINTEXT"
if grep -r -q "^#\?listener.security.protocol.map=" $KAFKA_HOME/config/server.properties; then
    sed -r -i "s/^#?(listener.security.protocol.map)=(.*)/\1=${SECURITY_PROTOCOL_MAP}/g" $KAFKA_HOME/config/server.properties
else
    echo "listener.security.protocol.map=${SECURITY_PROTOCOL_MAP}" >> $KAFKA_HOME/config/server.properties
fi


if grep -r -q "^#\?inter.broker.listener.name=" $KAFKA_HOME/config/server.properties; then
    sed -r -i "s/^#?(inter.broker.listener.name)=(.*)/\1=LISTENER_DOCKER_INTERNAL/g" $KAFKA_HOME/config/server.properties
else
    echo "inter.broker.listener.name=LISTENER_DOCKER_INTERNAL" >> $KAFKA_HOME/config/server.properties
fi

$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties


