# gitlab-setup

Gitlab server one-step scripts, support setup/backup/restore features

## Features

1. **Setup** a clean gitlab server, running in docker container
2. **Backup** gitlab server's configuration data, application data, ssh data.
3. **Restore** gitlab server from backup files. Makes team to migrate the gitlab server easily

## Setup

Setup a clean gitlab server container using `sh setup.sh` command

#### Pre requirements

1. `GDOMAIN` environment must be set before running the `setup.sh` scripts
2. `docker` and `docker-compose` must be installed on the host, and docker daemon must be running
3. `$USER` must belongs to `docker` group
4. Ports `22`, `80`, `443` must not in use.

#### How to install

1. Execute command `export GDOMAIN=YOUR_DOMAIN`
2. Run script `sh setup.sh`

#### How to access

1. Access from [https://gitlab.${YOUR_DOMAIN}.com](https://gitlab.${YOUR_DOMAIN}.com)


## Backup

Backup a gitlab server's configuration data, application data, ssh data using `sh backup.sh` scripts

#### Pre requirements

1. gitlab container is running
2. `$USER` must belongs to `docker` group

#### How to backup

1. Run script `sh backup.sh` to backup your data

#### Backup files location

1. config data: `/secret/gitlab/config-backups/` in container, `/srv/gitlab/config-backups/` on host
2. application data: `/var/opt/gitlab/backups` in container, `/srv/gitlab/data/backups` on host
3. ssh data: `/secret/gitlab/ssh-backups/` in container, `/srv/gitlab/ssh-backups/` on host

> NOTE: The script does not support customize backup location in container! If you want, you can customize the mounted backup location on host. To achieve this, please change the `volumes` part of `docker-compose.yaml`

## Restore

Restore a gitlab server from backup file using script `sh restore.sh`

#### Pre requirements

1. `BACKUP` environment is set, (backup file name)
2. Backup file must be location at `/srv/gitlab/data/backups/` and file name must be `${BACKUP}_gitlab_backup.tar`
3. Backup file must has a correct ownership(Just copy it and do not change its ownership)
4. Gitlab container must be running
5. `$USER` must belongs to `docker` group
6. The most important is, the `backup version` must match the `running gitlab container version`


#### How to restore

1. Execute command `export BACKUP=YOUR_BACKUP_FILE_NAME` to export your backup file name
2. Move backup file to `/srv/gitlab/data/backups` by `sudo mv YOU_BACKUP_FILE_LOCATION /srv/gitlab/data/backups` if necessary
3. Run script `sh restore.sh` to restore your gitlab server

> NOTE: For the environment `BACKUP`, please do not export full name of backup file. For example, if backup file name is `1539853307_2018_10_18_11.3.5_gitlab_backup.tar`, then you have to export the `BACKUP` environment in this way `export BACKUP=1539853307_2018_10_18_11.3.5_gitlab`. Do remember to ignore `_gitlab_backup.tar` when export the environment!


## Contact to author

Wenbo Wang <jackie-1685@163.com>

