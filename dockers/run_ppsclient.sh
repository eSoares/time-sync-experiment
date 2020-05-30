#!/usr/bin/env bash

build() {
  docker build --tag kernelbuilder -f ppsclient.0 .
  cbuild=$(docker run --privileged --network=host -it -d -v /lib/modules:/lib/modules -v /run:/run -v /boot:/boot -v /proc:/proc -v /usr/share/doc/raspberrypi-bootloader/:/usr/share/doc/raspberrypi-bootloader/ kernelbuilder sh)
  echo "$cbuild"
  docker exec -it "$cbuild" /usr/bin/rpi-source -q --tag-update
  docker exec -it "$cbuild" /usr/bin/rpi-source -d ./ --nomake --delete
  docker exec -it "$cbuild" bash -c "cd /linux; KERNEL=kernel7; make bcm2709_defconfig"
  docker exec -it "$cbuild" bash -c "cd /linux; make -j4 zImage"
  # todo check if container built with sucess
  
  docker exec -it "$cbuild" bash -c "cd /; git clone https://github.com/rascol/Raspberry-Pi-PPS-Client.git"
  docker exec -it "$cbuild" bash -c "cd /Raspberry-Pi-PPS-Client;\
      git checkout c388d2e03f25cf5955ead97e7c8bb87472be80db && \
      sed -i 's/__time_t/time_t/g' client/pps-client.h;"

  docker exec -it "$cbuild" bash -c "cd /Raspberry-Pi-PPS-Client; \
      sed -i 's/#serial=enable/serial=enable/g' client/pps-client.conf &&\
      sed -i 's/4/18/g' client/pps-client.conf &&\
      sed -i 's/17/23/g' client/pps-client.conf &&\
      sed -i 's/22/24/g' client/pps-client.conf &&\
      sed -i 's/serial0/ttyS0/g' client/pps-client.conf"

  docker exec -it "$cbuild" bash -c "cd /Raspberry-Pi-PPS-Client; make KERNELDIR=/linux KERNELVERS=`uname -r`"
  docker exec -it "$cbuild" bash -c "cd /Raspberry-Pi-PPS-Client; ./\$(ls | grep pps-client-)"
  docker exec -it "$cbuild" bash -c "rm -rf /linux*"
  echo "commiting pps-client"
  image=$(docker commit "$cbuild")
  docker tag "$image" ppsclient.compiled
  docker stop "$cbuild"
  docker container rm "$cbuild"
  docker build --tag ppsclient -f ppsclient.1 .
  docker image rm "ppsclient.compiled"

  echo "ready to run"
}

run() {
  docker run --privileged -it -d -v /lib/modules:/lib/modules -v /run:/run ppsclient
}

case "$1" in
build)
  build
  ;;
run)
  run
  ;;
*)
  echo "please use build or run with the script"
  ;;
esac

exit 0
