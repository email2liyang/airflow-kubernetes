version = 1.10.3-1
build:
	docker build -t email2liyang/docker-airflow:$(version) .
push:
	docker push email2liyang/docker-airflow:$(version)
