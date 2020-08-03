#!/bin/sh

host_ip=$(route -n | grep "^0\.0\.0\.0" | awk '{ print $2 }') &&
export DOGSTATSD_HOST=${DOGSTATSD_HOST:-"$host_ip"} &&

exec "$@"
