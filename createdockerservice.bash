#!/bin/bash

NOMBRE=$1
IMAGEN=$2
REPLICAS=1


# Memory en Bytes
# ----------------

docker service create \
  --name $NOMBRE \
  --hostname $NOMBRE \
  --replicas  $REPLICAS \
  --host logstash.art.com:172.29.170.205 \
  --host logstash:172.29.170.205 \
  --publish 20172:8080 \
  --publish 21172:8081 \
  --workdir /data \
  --reserve-memory 104857698 \
  --limit-memory 629145600 \
  --detach=false \
  $IMAGEN

