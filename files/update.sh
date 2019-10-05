#!/bin/bash
# MANAGED BY MES AIDES OPS

set -e

cd `dirname $0`

echo "Your SSH connection ($1) triggered a shell script ($0)."
case "$1" in
    deploy)
        fab refresh --host localhost
        ;;
    *)
        echo $"Usage: deploy"
        exit 1
esac
