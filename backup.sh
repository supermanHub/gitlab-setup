#!/usr/bin/env bash
echo ""
echo " +---------------------------------------------------+"
echo " |     Backup Gitlab Server Config/App/SSH Data      |"
echo " |                                                   |"
echo " | This script is used to backup docker-installed    |"
echo " | gitlab server's configuration data & application  |"
echo " | data & ssh data. Please do not use this script to |"
echo " | backup gitlab server that installed other than    |"
echo " | docker!!                                          |"
echo " |                                                   |"
echo " | This script will back up config data from /etc    |"
echo " | /gitlab to /secret/gitlab/config-backups/ (in     |"
echo " | container)                                        |"
echo " |                                                   |"
echo " | This script will backup ssh data from /etc/ssh to |"
echo " | /secret/gitlab/ssh-backups/ (in container)        |"
echo " |                                                   |"
echo " | This script will backup application data from     |"
echo " | /var/opt/gitlab to /var/opt/gitlab/backups (in    |"
echo " | container).                                       |"
echo " |                                                   |"
echo " | If you gitlab server config data and application  |"
echo " | data are not location in upon folders in container|"
echo " | , then please do not backup your data by this     |"
echo " | script!!!                                         |"
echo " |                                                   |"
echo " | If you want to save the backup data to host, you  |"
echo " | have to mount the backup location(in container) to|"
echo " | your host directory correctlly!                   |"
echo " |                                                   |"
echo " | If you install the gitlab server by setup.sh, then|"
echo " | the backup directory in host are:                 |"
echo " | 1. config data, /srv/gitlab/config-backups/       |"
echo " | 2. ssh data, /srv/gitlab/ssh-backups/             |"
echo " | 3. application data, /srv/gitlab/data/backups     |"
echo " |                                                   |"
echo " | REMEMBER!!! Backups only readable by root user    |"
echo " |                                                   |"
echo " | Contact to author: Wenbo Wang<jackie-1685@163.com>|"
echo " |---------------------------------------------------|"
echo " | A. Pre requirement:                               |"
echo " |    1. docker is installed                         |"
echo " |    2. gitlab container is running                 |"
echo " |    3. user `whoami` is in group 'docker'          |"
echo " |    4. user `whoami` has root permission           |"
echo " |                                                   |"
echo " | B. OS support                                     |"
echo " |    1. Linux yes                                   |"
echo " |    2. Selinux no                                  |"
echo " |    3. Windows no                                  |"
echo " |    4. Mac no                                      |"
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

if ! command -v docker > /dev/null 2>&1 ; then
  echo "ERROR!!! No docker detected. Please make sure the docker is installed on your host."
  exit 1
fi

if [ "`docker ps -aq -f ancestor=gitlab/gitlab-ce:latest -f health=healthy`" == "" ] ; then
  echo "ERROR!!! Gitlab server is not runing or its status is not 'healthy', please start it or wait for healthy and then retry."
  exit 1
fi

if ! id -nG "$USER" | grep -qw "docker"; then 
  echo "ERROR!!! $USER does not belong to docker group."
  exit 1
fi

echo "WARNING: Pre requirements check successfully, the script will start to backup your gitlab server config data and application data."
echo ""
echo -n "Do you wish to proceed? [y]: "
read decision

if [ "$decision" != "y" ]; then
  echo "Exiting. Backup progress is cancelled by user."
  exit 1
fi

echo "Start to backup gitlab server configuration data && application data, please wait..."
#
# Backup config data
#
CONTAINER=`docker ps -aq -f ancestor=gitlab/gitlab-ce:latest`

# Step 1: Create configuration backup folder if necessary
docker exec -t $CONTAINER /bin/sh -c 'ls /secret/gitlab/config-backups' > /dev/null 2>&1
if [ $? -ne 0 ] ; then
  echo "INFO!!! Backup folder '/secret/gitlab/config-backups'(in container) doest not exist. create it!"
  docker exec -t $CONTAINER /bin/sh -c 'mkdir -p /secret/gitlab/config-backups' > /dev/null 2>&1
fi

# Step 2: Backup configuration data
docker exec -t $CONTAINER /bin/sh -c 'umask 0077; tar cfz /secret/gitlab/config-backups/$(date "+etc-gitlab-%s.tgz") -C / etc/gitlab'
if [ $? -ne 0 ] ; then
  echo "ERROR!!! Backup configuration data failed, please check it or try again later."
  exit 1
fi

# Step 3: Create ssh backup folder if necessary
docker exec -t $CONTAINER /bin/sh -c 'ls /secret/gitlab/ssh-backups' > /dev/null 2>&1
if [ $? -ne 0 ] ; then
  echo "INFO!!! Backup folder '/secret/gitlab/ssh-backups'(in container) doest not exist. create it!"
  docker exec -t $CONTAINER /bin/sh -c 'mkdir -p /secret/gitlab/ssh-backups' > /dev/null 2>&1
fi

# Step 4: Backup ssh data
docker exec -t $CONTAINER /bin/sh -c 'umask 0077; tar cfz /secret/gitlab/ssh-backups/$(date "+etc-ssh-%s.tgz") -C / etc/ssh'
if [ $? -ne 0 ] ; then
  echo "ERROR!!! Backup ssh data failed, please check it or try again later."
  exit 1
fi

# Step 5: Backup application data
docker exec -t $CONTAINER gitlab-rake gitlab:backup:create
if [ $? -ne 0 ] ; then
  echo "ERROR!!! Backup application data failed, please check it or try again later."
  exit 1
fi

echo "INFO!!! Backup gitlab server's configuration data && application data successfully."
echo "INFO!!! Please read post steps from below and make some operations if necessary."

echo ""
echo " +---------------------------------------------------+"
echo " |                     Post Steps                    |"
echo " |                                                   |"
echo " | A. If you dont mount the backups to host yet, then|"
echo " |    mount backups to your host directories.        | "
echo " | B. Keep your backups into a safe place!           |"
echo " | C. Remember to backup your data in period(crontab)| "
echo " |                                                   |"
echo " | Contact to author: Wenbo Wang<jackie-1685@163.com>|"
echo " +---------------------------------------------------+"
echo ""

exit 0








