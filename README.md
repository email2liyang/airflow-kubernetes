# airflow-kubernetes

deploy airflow into kubernetes env with both LocalExecutor and CeleryExecutor Support, the orignal docker build file is from [https://github.com/puckel/docker-airflow](https://github.com/puckel/docker-airflow). but with some modification to make it work in kubernetes.

## information

please checkout [https://github.com/puckel/docker-airflow](https://github.com/puckel/docker-airflow) for how to use the docker image

* we use mysql as backend rather than postgresql
* we use rabbitmq as broker rather than postgresql
* we've implemnet a SystemV style of init script, is user copy anything in /usr/local/airflow/config/init/ of docker contianer , it will be executed before webserver started, this is a perfect place to init airflow variables and connections etc
* we've implemnet a SystemV style of *super*-init script, is user copy anything in /usr/local/airflow/config/super-init/ of docker contianer , it will be executed before webserver started , *as root*, this is a perfect place to init airflow under root user, e.g: fix the hostname and ip mapping issue in /etc/hosts
* we for CeleryExecutor, we have flower enabled to check the task stats


## kubernetes

* [install with minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/#install-minikube)
* install airflow with LocalExecutor
 
```
kubectl apply -f KubernetesLocalExecutor.yaml
``` 

 * install airflow with CeleryExecutor

```
kubectl apply -f KubernetesCeleryExecutor.yaml
``` 

## FAQ

* how to enalbe live log browsing in kubernetes env?
use super-init system to grab the hostname and ip mapping in kubernetes and put it in /etc/hosts
e.g: have a script named "init_worker_hostnames.sh" and put it under `/usr/local/airflow/config/super-init/` with logic below
```
#!/usr/bin/env bash

kubectl get po -n xx -o wide | grep xx-my-airflow-worker | awk '{printf("%s\t%s\n",$6,$1)}' >> /etc/hosts
```
