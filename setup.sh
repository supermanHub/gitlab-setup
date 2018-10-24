#!/usr/bin/env bash

echo ""
echo " +---------------------------------------------------+"
echo " |           Setup gitlab server for Linux           |"
echo " |---------------------------------------------------|"
echo " | A. Pre requirement:                               |"
echo " |    1. GDOMAIN env is set.                         |"
echo " |    2. docker is installed                         |"
echo " |    3. docker-compose is installed                 |"
echo " |    4. port 22, 80, 443 are not in use             |"
echo " |    4. user `whoami` is in group 'docker'         |"
echo " |                                                   |"
echo " | B. OS support                                     |"
echo " |    1. Linux yes                                   |"
echo " |    2. Selinux no                                  |"
echo " |    3. Windows no                                  |"
echo " |    4. Mac no                                      |"
echo " |                                                   |"
echo " | C. Author                                         |"
echo " |    1. Wenbo Wang<jackie-1685@163.com>             |"
echo " +---------------------------------------------------+"
echo ""

OS=`uname -s`

if [ $OS != "Linux" ]; then
  echo "ERROR!!! This script is Linux-only. Please do not run it on any other than Linudx."
  exit 1
fi

if [[ $EUID -eq 0 ]]; then
  echo "ERROR!!! This script must NOT be run with sudo/root. Please re-run without sudo." 1>&2
  exit 1
fi

if [ -z $GDOMAIN ]; then
  echo "ERROR!!! GDOMAIN environment is not set, please set it. e.g, 'export GDOMAIN=idianyou.com'";
  exit 1
fi

if ! id -nG "$USER" | grep -qw "docker"; then 
  echo "ERROR!!! $USER does not belong to docker group."
  exit 1
fi

if ! command -v docker > /dev/null 2>&1 ; then
  echo "ERROR!!! No docker detected. Please make sure the docker is installed on your host."
  exit 1
fi

if ! command -v docker-compose > /dev/null 2>&1 ; then
  echo "ERROR!!! No docker compose detected. Please make sure the docker compose is installed on your host."
  exit 1
fi

if ! docker ps > /dev/null 2>&1 ; then
  echo "ERROR!!! Docker is not start. Please start the docker to continue. e.g, 'systemctl start docker'"
  exit 1
fi

echo "WARNING: This script will set path /srv/gitlab as gitlab server work folder and /srv/mattermost as mattermost work folder, please backup your data if the fold is already exists."
echo ""
echo -n "Do you wish to proceed? [y]: "
read decision

if [ "$decision" != "y" ]; then
  echo "Exiting. Installing progress is cancelled by user."
  exit 1
fi

echo "INFO!!! Pre requirements checking is finished. Everything looks good, start to setup gitlab server..."

if [ ! -d "/srv" ]; then
 echo "INFO!!! Directory '/srv' is not exist, create it and change owner to `whoami`:docker (maybe require root permission)!"
 sudo mkdir -p /srv
 sudo chown -R `whoami`:docker /srv
fi

if [ ! -w "/srv" ]; then 
  echo "INFO!!! Directory '/srv' is exist, but permission is not correct. change it to `whoami`:docker (maybe require root permission)!"
  sudo chown -R `whoami`:docker /srv
fi

echo "INFO!!! Gitlab server workspace setup successfully, startup gitlab server"
docker-compose up -d 
sleep 5

CONTAINER=`docker ps -aq -f ancestor=gitlab/gitlab-ce:latest`
echo "INFO!!! Detect gitlab server container id '${CONTAINER}', waiting for start, this will cost more than 5 minutes..."
sleep 1


while [ "`docker ps -aq -f ancestor=gitlab/gitlab-ce:latest -f health=healthy`" == "" ] ; do 
  echo "Starting, please wait..."
  sleep 10
  docker logs ${CONTAINER}
done

echo "INFO!!! Gitlab server startup successfully, please waiting for anther 2 - 10 minutes to components communication setup"
echo "        then you can access it from https://gitlab.$GDOMAIN}.com or https://localhost"
echo "+-----------------------------------------+"
echo "|             Post Steps                  |"
echo "| 1. Setup domain in /etc/hosts           |"
echo "| 2. Change passord(username: root)       |"

exit 0