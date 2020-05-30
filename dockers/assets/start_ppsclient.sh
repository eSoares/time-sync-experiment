#!/usr/bin/env sh
cp /Raspberry-Pi-PPS-Client/driver/gps-pps-io.ko /lib/modules/`uname -r`/kernel/drivers/misc
while true; do
	pps-client
	while [ ! -z `pidof pps-client` ];
	do
		sleep 5;
	done
done
