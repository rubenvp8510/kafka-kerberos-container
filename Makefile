build:
	docker build -t rubensvp/kafka-kerberos:latest .
	
push:
	docker push rubensvp/kafka-kerberos:latest
