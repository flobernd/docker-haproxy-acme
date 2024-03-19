#!/bin/bash
set -e

if [ $ACME_CRON -ne 1 ]; then
    # Cronjob is disabled in configuration
    exit 0
fi

trap "exit 0" SIGTERM

args=(
    "--cron"
)

if [ $ACME_DEBUG -eq 1 ]; then
    args+=("--debug")
fi

interval=86400 # 1 day
while :
do
    now=$(date +%s) # timestamp in seconds
    sleep $((interval - now % interval)) & wait $!

    acme.sh "${args[@]}"
done
