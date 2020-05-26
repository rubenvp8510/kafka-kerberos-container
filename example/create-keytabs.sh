rm client.keytab
REALM="EXAMPLE.COM"
KADMIN_PRINCIPAL="admin/admin"
KADMIN_PRINCIPAL_FULL=$KADMIN_PRINCIPAL@$REALM
KADMIN_PASSWORD="qwerty"

echo "REALM: $REALM"
echo "KADMIN_PRINCIPAL_FULL: $KADMIN_PRINCIPAL_FULL"
echo "KADMIN_PASSWORD: $KADMIN_PASSWORD"
echo ""

function kadminCommand {
    kadmin -p $KADMIN_PRINCIPAL_FULL -w $KADMIN_PASSWORD -q "$1"
}

echo "Add kafka user"
kadminCommand "addprinc -pw secret client/localhost@EXAMPLE.COM"
echo "Create kafka keytab"
kadminCommand "xst -k ./client.keytab client/localhost"
kinit client/kafka@EXAMPLE.COM -k -t client.keytab
