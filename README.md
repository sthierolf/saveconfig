# Saveconfig

saveconfig are two small Shell and TCL/Expect scripts which create a backup of configuration files of network devices. The typical usage is for Cisco hardware like switches, routers, wireless controllers and wireless access points but the script can be extended to create also backup files for any other device which supports the protocols SSH, SCP, SFTP and so on. 

# Requirements

    aptitude install expect openssh-server atftpd diffutils bsd-mailx

# TL;DR

    root@linux-devel:/srv# /srv/tftp/scripts/saveconfig-backup.sh catalyst

# Code and details

[Saveconfig Backup scripts](https://www.thierolf.org/blog/2018/saveconfig-backup-scripts.html)
