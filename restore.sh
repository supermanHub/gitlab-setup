#!/usr/bin/env bash

echo ""
echo " +---------------------------------------------------+"
echo " |         Restore gitlab server from backup         |"
echo " |                                                   |"
echo " |  This script only restore from application backup!|"
echo " |                                                   |"
echo " |  For config backup, because of all configurations |"
echo " | are also available in docker-compose.yaml, so if  |"
echo " | migrate by the same docker-compose.yaml, then you |"
echo " | can skip to restore the gitlab config.            |"
echo " |                                                   |"
echo " | For ssh backup, the script will not restore it. so|"
echo " | after restoring, customers have to remove old     |"
echo " | gitlab host from know_hosts file to make the ssh  |"
echo " | work. In common, the know_hosts should be exist at|"
echo " | ~/.ssh/known_hosts in customers host.             |"
echo " |---------------------------------------------------|"
echo " | A. Pre requirement:                               |"
echo " |    1. BACKUP env is set.                          |"
echo " |    2. Gitlab server container is running          |"
echo " |    3. Gitlab version matchs backup's version      |"
echo " |    4. Backup file has a correct ownership         |"
echo " |    5. user `whoami` is in group 'docker'          |"
echo " |    6. user `whoami` has root permission           |"
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

if [ -z $BACKUP ]; then
  echo "ERROR!!! BACKUP environment is not set, please set it. e.g, 'export BACKUP=1539845102_2018_10_18_11.3.5'";
  echo "If you backup gitlab server by backup.sh, you can find out the BACKUP file from /srv/gitlab/data/backups"
  exit 1
fi

if sudo [ ! -f "/srv/gitlab/data/backups/${BACKUP}_gitlab_backup.tar" ] ; then
  echo "ERROR!!! Backup file doest not exist in /srv/gitlab/data/backups/${BACKUP}_gitlab_backup.tar"
  exit 1
fi

echo "WARNING: The script will start to restore your gitlab server from backup file ${BACKUP}_gitlab_backup.tar."
echo "WARNING: Please make sure the backuped gitlab version is match the runging gitlab server!!!!!!!!!!!! Otherwise you may hit unexpected error!!!!"
echo ""
echo -n "Do you wish to proceed? [y]: "
read decision

if [ "$decision" != "y" ]; then
  echo "Exiting. Restore progress is cancelled by user."
  exit 1
fi

echo "Start to restore gitlab server from backup /srv/gitlab/data/backups/${BACKUP}_gitlab_backup.tar please wait..."

CONTAINER=`docker ps -aq -f ancestor=gitlab/gitlab-ce:latest`

# BACKUP
docker exec -e BACKUP=$BACKUP -it $CONTAINER gitlab-rake gitlab:backup:restore 
if [ $? -ne 0 ] ; then
  echo "ERROR!!! Restore gitlab from backup failed, please check it or try again later."
  exit 1
fi

# Done
echo "INFO!!! Restore gitlab server successfully."
echo ""
echo " +---------------------------------------------------+"
echo " |                     Post Steps                    |"
echo " |                                                   |"
echo " | A. Access the gitlab server to make sure the      |"
echo " |    restore is successfully                        |"
echo " |                                                   |"
echo " | Contact to author: Wenbo Wang<jackie-1685@163.com>|"
echo " +---------------------------------------------------+"
echo ""

exit 0;
