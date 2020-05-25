#!/bin/bash

KADMIN_PRINCIPAL="admin/admin"
KADMIN_PRINCIPAL_FULL="${KADMIN_PRINCIPAL}@${REALM}"

echo "REALM: $REALM"
echo "KADMIN_PRINCIPAL_FULL: $KADMIN_PRINCIPAL_FULL"
echo "KADMIN_PASSWORD: $KADMIN_PASSWORD"
echo ""

function kadminCommand {
    kadmin -p $KADMIN_PRINCIPAL_FULL -w $KADMIN_PASSWORD -q "$1"
}

until kadminCommand "list_principals $KADMIN_PRINCIPAL_FULL"; do
  >&2 echo "KDC is unavailable - sleeping 1 sec"
  sleep 1
done
echo "KDC and Kadmin are operational"
echo ""

echo "Add zookeeper user"
kadminCommand "addprinc -pw zookeeper zookeeper/localhost@${REALM}"
echo "Create zookeeper keytab"
kadminCommand "xst -k /zookeeper.keytab zookeeper/localhost"
echo "Add kafka user"
kadminCommand "addprinc -pw kafka kafka/localhost@${REALM}"
echo "Create kafka keytab"
kadminCommand "xst -k /kafka.keytab kafka/localhost"
echo ""
exit 0
