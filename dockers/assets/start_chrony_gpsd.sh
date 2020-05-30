#!/usr/bin/env sh
gpsd -n /dev/ttyS0

chronyd -d -f chrony_gpsd.conf
