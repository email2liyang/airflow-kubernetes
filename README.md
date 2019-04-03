# airflow-kubernetes

deploy airflow into kubernetes env with both LocalExecutor and CeleryExecutor Support, the orignal docker build file is from [https://github.com/puckel/docker-airflow](https://github.com/puckel/docker-airflow). but with some modification to make it work in kubernetes.

## information

please checkout [https://github.com/puckel/docker-airflow](https://github.com/puckel/docker-airflow) for how to use the docker image

* we use mysql as backend rather than postgresql
* we've implemnet a SystemV style of init script, is user copy anything in /usr/local/airflow/config/init/ of docker contianer , it will be executed before webserver started, this is a perfect place to init airflow variables and connections etc

## kubernetes

* [install with minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/#install-minikube)
* install airflow with LocalExecutor
 
```
kubectl apply -f kubernetes-LocalExecutor.yaml
``` 

 * install airflow with CeleryExecutor

```
kubectl apply -f kubernetes-CeleryExecutor.yaml
``` 