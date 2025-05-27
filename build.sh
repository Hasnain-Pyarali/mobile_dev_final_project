#!/bin/bash -e

IMG=git.gmoker.com/icing/flutter:sdk36

docker volume create --ignore flutter_cache
set -x
#docker run --entrypoint bash --rm -v "flutter_cache:/root/" -v "/dev/bus/usb/:/dev/bus/usb/" -v "$PWD:/app/" "$IMG" -c 'sleep 1 && flutter --no-version-check run -v'
docker run --rm \
    -v "flutter_cache:/root/" \
    -v "$PWD:/app/" \
    "$IMG"
