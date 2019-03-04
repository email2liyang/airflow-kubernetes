# airflow-kubernetes

deploy airflow into kubernetes env with both LocalExecutor and CeleryExecutor Support, the orignal docker build file is from [https://github.com/puckel/docker-airflow](https://github.com/puckel/docker-airflow). but with some modification to make it work in kubernetes.

## information

please checkout [https://github.com/puckel/docker-airflow](https://github.com/puckel/docker-airflow) for how to use the docker image

## kubernetes

* [install with minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/#install-minikube)
* install airflow with LocalExecutor
 
 ```
 kubectl apply -f kubernetes-LocalExecutor.yml
 ``` 

 * install airflow with CeleryExecutor

```
 kubectl apply -f kubernetes-CeleryExecutor.yml
 ``` 