#!/bin/sh

set -e

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage $0 connector-name [version=v1|v2]"
    exit 1
fi

location=$(dirname $0)
$location/upgrade.sh "$1" "v1"
