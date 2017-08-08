#!/bin/sh

#
# Test run the appeals container in isolation.
#
docker run \
    --rm \
    -it \
    -v `pwd`:/opt/caseflow-monitor \
    -p 3000:3000 \
    --name caseflow-monitor-container \
    -w /opt/caseflow-monitor \
    appeals-caseflow-monitor-img
