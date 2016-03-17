#!/bin/bash

# Mysql 에 새로운 DB 를 추가합니다. 
echo -n "MYSQL DB Create? - [y/n](default n) : " 
read db 
echo "" 
if [ "$db" = "y" ] || [ "$db" = "Y" ]; then 
    echo -n "MYSQL root password: "
    stty -echo
    read pass
    echo ""
    echo "" 
    stty echo
    
    echo -n "MYSQL Leaqua DB password: "
    stty -echo
    read leaquapass
    echo ""
    echo ""
    stty echo
    
    echo -n "MYSQL Leaqua password Confirm: "
    stty -echo
    read leaquapassconfirm
    echo ""
    echo ""
    stty echo
    
    if [ "$leaquapass" == "$leaquapassconfirm" ]; then
        touch /tmp/mysql_dbusersetup_temp 
        echo "create database IF NOT EXISTS leaqua;" >> /tmp/mysql_dbusersetup_temp 
        echo "GRANT all privileges on leaqua.* TO leaqua@localhost IDENTIFIED BY '$leaquapass';" >> /tmp/mysql_dbusersetup_temp  
        mysql -u root -p$pass mysql < /tmp/mysql_dbusersetup_temp 
        rm -f /tmp/mysql_dbusersetup_temp
        mysql -u leaqua -p$leaquapass leaqua < leaqua.sql
    else
        echo -n "Different password"
        exit
    fi
fi 
