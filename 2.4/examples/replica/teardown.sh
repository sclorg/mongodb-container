#!/bin/bash

osc delete services/mongodb
osc update rc mongodb --patch='{ "apiVersion": "v1beta1", "desiredState": { "replicas": 0 }}'
osc delete rc mongodb
osc delete pods/mongodb-node
