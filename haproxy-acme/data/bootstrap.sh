#!/bin/bash
set -e

. /usr/local/bin/acmeinit.early.sh

exec supervisord -c /etc/supervisord.conf -n
