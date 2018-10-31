#!/bin/bash

#######################################################
# AUTHOR: Dorian Borovina (dorian.borovina@dytech.de) #
#######################################################
#
# DO NOT MODIFY THIS CONFIGURATION FILE IN AN ATTEMPT TO INSTALL ON AN EXISTING SYSTEM.
# INSTALL OPSI ON A FRESH OPERATING SYSTEM ONLY!!!




#Preparations, Samba download, adding sources on the opsi.list
apt-get update
apt-get install wget -y
apt-get install host -y
apt-get install pigz -y
apt-get install samba -y
apt-get install samba-common -y
apt-get install smbclient -y
apt-get install cifs-utils -y
echo "deb http://download.opensuse.org/repositories/home:/uibmz:/opsi:/4.1:/stable/Debian_9.0/ /" > /etc/apt/sources.\list.d/opsi.list

#Repository signature key import and verification, script will about in case the Repository signature key is missing.
wget --no-check-certificate https://download.opensuse.org/repositories/home:uibmz:opsi:4.1:stable/Debian_9.0/Release.key -O Release.key
apt-key add - < Release.key

#OPSI Server installation
apt-get update
apt-get install opsi-tftpd-hpa -y
apt-get install opsi-server -y
apt-get install opsi-configed -y
apt-get install opsi-windows-support -y

#MYSQL Database installation
apt-get install mysql-server -y

#We will now configure the mysql backend. It is assumed that a MySQL server is installed and configured. We require the credentials for an database administrator.
opsi-setup --configure-mysql

#cat << END > /etc/opsi/backends/mysql.conf
# -*- coding: utf-8 -*-
#module = 'MySQL'
#config = {
#"username" : "opsi",
#"connectionPoolMaxOverflow" : 10,
#"database" : "opsi",
#"connectionPoolTimeout" : 30,
#"address" : "localhost",
#"password" : "12345678",
#"databaseCharset" : "utf8",
#"connectionPoolSize" : 20
#}
#END


#Whenever you changed the file dispatch.conf you should execute the following commands. Even if you have not changed the file during the initial setup execute these commands now.
opsi-setup --init-current-config
opsi-setup --set-rights
systemctl restart opsiconfd.service
systemctl restart opsipxeconfd.service

#Opsi requires certain samba shares.
opsi-setup --auto-configure-samba

#A pcpatch user is created on the system.
#This user can install software on a client PC. The pcpatch user allows access to the configuration data on the host shares.
#The user pcpatch needs to get a correct password - once as system user, as samba user and as opsi user.
#In a terminal window the program opsi-admin should be called which will set the pcpatch-password for opsi, unix and samba.
echo -e "Default \e[92mType in the password for PC Patch user."
opsi-admin -d task setPcpatchPassword

#Create the user adminuser, which is a similar procedure to creating an account for yourself.
#Do not use the char ยง as part of the passwords. It becomes impossible to login at the opsi web service!
echo -e "\e[92mType in the UNIX password for OPSI Admin user\e[0m"
useradd -m -s /bin/bash adminuser
passwd adminuser
echo -e "\e[92mType in the SMB password for OPSI Admin user\e[0m"
smbpasswd -a adminuser

#Create and test the group membership for the OPSI Admin user.
usermod -aG opsiadmin adminuser

#Create and test the group membership for the PC Patch user.
usermod -aG pcpatch adminuser

#To make sudo opsi-set-rights available.
opsi-setup --patch-sudoers-file  
  
#Download and install the opsi products.
opsi-package-updater -v install
