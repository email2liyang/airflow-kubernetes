#!/usr/bin/env bash

TRY_LOOP="20"

: "${AIRFLOW_MYSQL_DB_HOST:="airflow_mysql"}"
: "${AIRFLOW_MYSQL_DB_PORT:="3306"}"
: "${AIRFLOW_MYSQL_DB_USER:="airflow"}"
: "${AIRFLOW_MYSQL_DB_PASSWORD:="airflow"}"
: "${AIRFLOW_MYSQL_DB_NAME:="airflow"}"

# Defaults and back-compat
: "${AIRFLOW__CORE__FERNET_KEY:=${FERNET_KEY:=$(python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)")}}"
: "${AIRFLOW__CORE__EXECUTOR:=${EXECUTOR:-Sequential}Executor}"

export \
  AIRFLOW__CELERY__BROKER_URL \
  AIRFLOW__CELERY__RESULT_BACKEND \
  AIRFLOW__CORE__EXECUTOR \
  AIRFLOW__CORE__FERNET_KEY \
  AIRFLOW__CORE__LOAD_EXAMPLES \
  AIRFLOW__CORE__SQL_ALCHEMY_CONN \


# Load DAGs exemples (default: Yes)
if [[ -z "$AIRFLOW__CORE__LOAD_EXAMPLES" && "${LOAD_EX:=n}" == n ]]
then
  AIRFLOW__CORE__LOAD_EXAMPLES=False
fi

# Install custom python package if requirements.txt is present
if [ -e "/requirements.txt" ]; then
    $(which pip) install --user -r /requirements.txt
fi

wait_for_port() {
  local name="$1" host="$2" port="$3"
  echo "testing $name from $host on port $port"
  local j=0
  while ! nc -z "$host" "$port" >/dev/null 2>&1 < /dev/null; do
    j=$((j+1))
    if [ $j -ge $TRY_LOOP ]; then
      echo >&2 "$(date) - $host:$port still not reachable, giving up"
      exit 1
    fi
    echo "$(date) - waiting for $name... $j/$TRY_LOOP"
    sleep 5
  done
}

# super init airflow env when user provide airflow init script in fodler 
airflow_super_init_env() {
  AIRFLOW_SUPER_INIT_DIR=/usr/local/airflow/config/super_init/
  if [ ! -d ${AIRFLOW_SUPER_INIT_DIR} ]; then
      echo "no super init script found , do nothing"
  else 
    airflow_super_init_scripts=$(ls ${AIRFLOW_SUPER_INIT_DIR} | grep 'sh')

    for super_init_script in ${airflow_super_init_scripts}; do
      echo "executing super init script - ${super_init_script}"
      sudo bash ${AIRFLOW_SUPER_INIT_DIR}/${super_init_script}
    done
  fi
}
# init airflow env when user provide airflow init script in fodler 
airflow_init_env() {
  AIRFLOW_INIT_DIR=/usr/local/airflow/config/init/
  if [ ! -d ${AIRFLOW_INIT_DIR} ]; then
      echo "no init script found , do nothing"
  else 
    airflow_init_scripts=$(ls ${AIRFLOW_INIT_DIR} | grep 'sh')

    for init_script in ${airflow_init_scripts}; do
      echo "executing init script - ${init_script}"
      bash ${AIRFLOW_INIT_DIR}/${init_script}
    done
  fi
}

if [ "$AIRFLOW__CORE__EXECUTOR" != "SequentialExecutor" ]; then
  AIRFLOW__CORE__SQL_ALCHEMY_CONN="mysql://$AIRFLOW_MYSQL_DB_USER:$AIRFLOW_MYSQL_DB_PASSWORD@$AIRFLOW_MYSQL_DB_HOST:$AIRFLOW_MYSQL_DB_PORT/$AIRFLOW_MYSQL_DB_NAME"
  AIRFLOW__CELERY__RESULT_BACKEND="db+mysql://$AIRFLOW_MYSQL_DB_USER:$AIRFLOW_MYSQL_DB_PASSWORD@$AIRFLOW_MYSQL_DB_HOST:$AIRFLOW_MYSQL_DB_PORT/$AIRFLOW_MYSQL_DB_NAME"
  wait_for_port "MySQL" "$AIRFLOW_MYSQL_DB_HOST" "$AIRFLOW_MYSQL_DB_PORT"
fi

if [[ -z "$AIRFLOW__CELERY__RESULT_BACKEND" && "$AIRFLOW__CORE__EXECUTOR" = "CeleryExecutor" ]]; then
  AIRFLOW__CELERY__BROKER_URL="sqla+mysql://$AIRFLOW_MYSQL_DB_USER:$AIRFLOW_MYSQL_DB_PASSWORD@$AIRFLOW_MYSQL_DB_HOST:$AIRFLOW_MYSQL_DB_PORT/$AIRFLOW_MYSQL_DB_NAME"
fi

case "$1" in
  webserver)
    airflow initdb
    airflow_super_init_env
    airflow_init_env
    if [ "$AIRFLOW__CORE__EXECUTOR" = "LocalExecutor" ]; then
      # With the "Local" executor it should all run in one container.
      airflow scheduler &
    fi
    echo $AIRFLOW__CELERY__RESULT_BACKEND
    exec airflow webserver
    ;;
  worker|scheduler)
    # To give the webserver time to run initdb.
    sleep 10
    exec airflow "$@"
    ;;
  flower)
    sleep 10
    echo $AIRFLOW__CELERY__RESULT_BACKEND
    exec airflow "$@"
    ;;
  version)
    exec airflow "$@"
    ;;
  *)
    # The command is something like bash, not an airflow subcommand. Just run it in the right environment.
    exec "$@"
    ;;
esac
