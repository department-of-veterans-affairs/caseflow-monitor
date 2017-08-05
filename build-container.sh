#!/bin/sh
#
# Build the appeals development image. This should be run at least
# once prior to running docker-compose.
#
docker build \
    --build-arg username=$USER \
    --build-arg usergroup=`id -g -n $USER` \
    -t appeals-caseflow-monitor-img .
