#!/bin/sh

set -e

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage $0 connector-name [version=v1|v2]"
    exit 1
fi

name=$1
version=${2:-v2}

# First stop the current version (may be not needed in the future)
kubectl scale klb $name --replicas 0

# Hand off the integration to the new operator and platform
kubectl annotate klb $name camel.apache.org/platform.id=camel-k-$version camel.apache.org/operator.id=$version --overwrite

# Clear the previous status to let the new operator rebuild the integration
kamel rebuild $name

# Start the connector again
kubectl scale klb $name --replicas 1
