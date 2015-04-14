#!/bin/bash

osc delete services/mongodb
osc update rc mongo --patch='{ "apiVersion": "v1beta1", "desiredState": { "replicas": 0 }}'
osc delete rc mongo
osc delete pods mongo-service
osc delete secret mongo-keyfile
