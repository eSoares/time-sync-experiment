#!/usr/bin/env sh

iface="wlan1"
if [ ! -z "$1" ]
then
    iface="$1"
fi

#docker build --tag audio_traffic -f audio_traffic .
echo $iface
sudo ip route add 240.0.0.0/4 dev $iface
docker run --network=host -it -d audio_traffic