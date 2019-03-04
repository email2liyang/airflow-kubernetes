version = 1.10.2
build:
	docker build -t email2liyang/docker-airflow:$(version) .
push:
	docker push email2liyang/docker-airflow:$(version)
