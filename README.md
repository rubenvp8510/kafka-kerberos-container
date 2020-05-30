docker run -d --name kafka -e REALM=EXAMPLE.COM -e KADMIN_PASSWORD=qwerty -p 88:88/udp -p 9092:9092 -p 464:464 -p 749:749  rubensvp/kafka-kerberos:latest

