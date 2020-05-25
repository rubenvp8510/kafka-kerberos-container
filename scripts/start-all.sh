#!/bin/bash

# The full path of the lock file to use.
LOCKFILE="/tmp/startscript-lock"
export JAVA_HOME=$(readlink -f $(which java) | sed -e 's/\/bin\/java//g')

start(){
  # Assert that there is no other Lambda instance, created with this script, running.
  [ -f $LOCKFILE ] && return 0
  # Create a lock file to prevent multiple instantiations.
  touch $LOCKFILE
  
  KADMIN_PRINCIPAL="admin/admin"
  KADMIN_PRINCIPAL_FULL="${KADMIN_PRINCIPAL}@${REALM}"
  # All kerberos stuff
  KADMIN_PRINCIPAL_FULL=$KADMIN_PRINCIPAL@$REALM
  echo "=========== Kerberos Parameters ==========="
  echo "REALM: $REALM"
  echo "KADMIN_PRINCIPAL_FULL: $KADMIN_PRINCIPAL_FULL"
  echo "KADMIN_PASSWORD: $KADMIN_PASSWORD"
  echo "==========================================="
  echo ""
  echo "Configuring kerberos server"
  /usr/bin/configure-kerberos-server.sh
  returnedValue=$?
  if [ $returnedValue -eq 0 ]
  then
    echo "Krb5 server configuration has been started!"
  else
    echo "Krb5 server configuration has failed to start with code $returnedValue."
    return $returnedValue
  fi
  echo ""
  echo "Starting kdc"
  supervisorctl start krb5kdc
  supervisorctl start kaasdmind
  echo ""
  echo "Configuring kerberos kafka and zookeeper client"
  /usr/bin/configure-kerberos-client.sh
  returnedValue=$?
  if [ $returnedValue -eq 0 ]
  then
    echo "Krb5 client configuration has been started!"
  else
    echo "Krb5 client configuration has failed to start with code $returnedValue."
    return $returnedValue
  fi
  returnedValue=$?

  # Start Zookeeper.
  echo "Starting Zookeeper..."
  supervisorctl start zookeeper
# Wait for Zookeeper to start.
  while [ "$(supervisorctl status zookeeper | tr -s ' ' | cut -f2 -d' ')" == "STARTING" ] 
  do
    sleep 10
  done
  zookeeper_status=$(supervisorctl status zookeeper | tr -s ' ' | cut -f2 -d' ')
  if [ "$zookeeper_status" != "RUNNING" ]
  then
    echo "Zookeeper has failed to start with code $zookeeper_status."
  else
    echo "Zookeeper has been started!"
  fi

  # Start Kafka on master node.
  echo "Starting kafka..."
  supervisorctl start kafka
# Wait for Kafka to start.
  while [ "$(supervisorctl status kafka | tr -s ' ' | cut -f2 -d' ')" == "STARTING" ] 
  do
    sleep 10
  done
  kafka_status=$(supervisorctl status kafka | tr -s ' ' | cut -f2 -d' ')
  if [ "$kafka_status" != "RUNNING" ]
  then
    echo "Kafka has failed to start with code $kafka_status."
  else
    echo "Kafka has been started!"
  fi

  # Don;t exit as long as kafka is running
  while [ "$(supervisorctl status kafka | tr -s ' ' | cut -f2 -d' ')" == "RUNNING" ] 
  do
    sleep 300
  done

  return 0
}

stop(){
  # Stop Kafka.
  supervisorctl stop kafka
  kafka_status=$(supervisorctl status kafka | tr -s ' ' | cut -f2 -d' ')
  if [ "$kafka_status" == "STOPPED" ]
  then
    echo "Kafka has been stopped!"
  else
    echo "Kafka has failed to stop with returned code $kafka_status"
  fi

  # Stop Zookeeper.
  supervisorctl stop zookeeper
  zookeeper_status=$(supervisorctl status zookeeper | tr -s ' ' | cut -f2 -d' ')
  if [ "$zookeeper_status" == "STOPPED" ]
  then
    echo "Zookeeper has been stopped!"
  else
    echo "Zookeeper has failed to stop with returned code $zookeeper_status"
  fi

  # Remove lock file.
  #rm -f $LOCKFILE

  return 0
}

restart(){
  stop
  start
}

RETVAL=0

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart|reload|force-reload)
    restart
    ;;
  condrestart)
    [ -f $LOCKFILE ] && restart || :
    ;;
  status)
    # If the lock file exists, then the Lambda instance is running.
    [ -f $LOCKFILE ] && echo "Kafka startup instance is running." || echo "Kafka startup instance is not running."
    RETVAL=$?
    ;;
  *)
    echo "Usage: $0 {start|stop|status|restart|reload|force-reload|condrestart}"
    RETVAL=1
esac

exit $RETVAL


