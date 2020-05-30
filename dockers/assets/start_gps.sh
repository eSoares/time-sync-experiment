#!/bin/sh

pin="1"

if [ ! -z "$2" ]
then
    pin="$2"
fi

ln /dev/ttyS0 /dev/gps0
ln "/dev/pps$pin" /dev/ppsgps0


driver46(){
	gpsd /dev/gps0 /dev/ppsgps0
	echo "server 127.127.46.0 minpoll 4 maxpoll 4 prefer\n" >> /etc/ntp.conf
	ntpd -d -f /etc/ntp.conf	
}

driver22(){
	gpsd -n /dev/gps0
	cat >> /etc/ntp.conf <<- EOM
			server 127.127.28.0 minpoll 4 maxpoll 4 prefer
			server 127.127.22.1 minpoll 4 maxpoll 4
		EOM
	sleep 1 & ntpd -d -f /etc/ntp.conf
}

driver222(){
	gpsd -n /dev/gps0
	cat >> /etc/ntp.conf <<- EOM
			server 127.127.28.0 minpoll 4 maxpoll 4
      fudge 127.127.28.0 flag1 1 time1 0.5
			server 127.127.22.1 minpoll 4 maxpoll 4 prefer
		EOM
	sleep 1 & ntpd -d -f /etc/ntp.conf
}

driver28(){
	gpsd -n /dev/gps0
	cat >> /etc/ntp.conf <<- EOM
			server 127.127.28.0 minpoll 4 maxpoll 4 prefer
		EOM
	sleep 1 & ntpd -d -f /etc/ntp.conf
}

driver20(){
	stty -F /dev/gps0 9600 cs8 
	cat >> /etc/ntp.conf <<- EOM
			server 127.127.20.0 minpoll 4 maxpoll 4 prefer
			fudge 127.127.20.0 time1 0.5
		EOM
	sleep 1 & ntpd -d -f /etc/ntp.conf
}

driver200(){
	stty -F /dev/gps0 9600 cs8 
	cat >> /etc/ntp.conf <<- EOM
			server 127.127.20.0 minpoll 4 maxpoll 4 prefer
			fudge 127.127.20.0 time1 0.5 flag1 1
		EOM
	sleep 1 & ntpd -d -f /etc/ntp.conf
}

case "$1" in
  driver46)
    driver46
    ;;
  driver22)
    driver22
    ;;
  driver222)
    driver222
    ;;
  driver28)
    driver28
    ;;
  driver20)
  	driver20
  	;;
  driver200)
  	driver200
  	;;
  *)
    driver46
    ;;
esac

exit 0