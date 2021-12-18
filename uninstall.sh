#!/bin/bash
#================================================#
## Environmental inspection ##
# Version Number:1.00
# Type:app
# Language:bash shell
#================================================#

pkill -9 -u istorm
userdel -r istorm
groupdel istorm
find / -name mysql | xargs rm -rf
rm -rf /etc/my.cnf
rm -rf .repeat.ini
rm -rf /usr/local/redis
rm -rf /usr/local/nginx
rm -rf /usr/local/jdk1.8
rm -rf /usr/local/src/nginx-1.*
rm -rf /usr/local/src/pcre-8.*
rm -rf /usr/local/src/redis-3.*
rm -rf /usr/local/src/zlib-1.*
