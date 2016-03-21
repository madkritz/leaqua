#!/bin/bash

DIRECTORY=/home/pi/leaqua

sudo apt-get update 

echo -e "\033[33m## APM 확인\033[0m"
dpkg-query -W apache2 > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " apache2 패키지를 설치하고 설정합니다"
    sudo apt-get -y install apache2
    sudo a2enmod rewrite
    #/etc/apache2/sites-available/000-default.conf  수정
    #sudo sed -i '/DocumentRoot/a\\n        \<Directory \/var\/www\/html\/\>\n            Options Indexes FollowSymLinks MultiViews\n            AllowOverride All\n            Order allow,deny\n            allow from all\n        </Directory>' /etc/apache2/sites-available/000-default.conf
    #sudo sed -i 's/*:[0-9][0-9]/*:88/g' /etc/apache2/sites-available/000-default.conf
    grep "x-httpd-php .html" /etc/apache2/mods-available/mime.conf > /dev/null 2>&1
    if [ "$?" -ne 0 ]; then
        sudo sed -i '/TypesConfig \/etc\/mime.types/a\\n        AddType application\/x-httpd-php .html' /etc/apache2/mods-available/mime.conf
    fi  
    sudo sed -i 's/^Listen [0-9][0-9]/Listen 88/g' /etc/apache2/ports.conf
fi

dpkg-query -W php5-common php5 libapache2-mod-php5 > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " php5 패키지를 설치합니다"
    sudo apt-get -y install php5-common php5 libapache2-mod-php5
fi
dpkg-query -W mysql-server mysql-client php5-mysql > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " mysql 패키지를 설치합니다"
    sudo apt-get -y install mysql-server mysql-client php5-mysql
fi



## 중간에 입력 받아야 하는값들 미리 받아놓기 ...
echo -n "MYSQL 패키지 설치시 설정한 root 암호를 입력하세요: "
stty -echo
read pass
echo ""
echo "" 
stty echo

echo -n "MYSQL에 생성하는 Leaqua DB 암호를 입력하세요: "
stty -echo
read leaquapass
echo ""
echo ""
stty echo

echo -n "MYSQL에 생성하는 Leaqua DB 암호 확인: "
stty -echo
read leaquapassconfirm
echo ""
echo ""
stty echo

if [ "$leaquapass" != "$leaquapassconfirm" ]; then
    echo "Leaqua DB 암호가 일치하지 않습니다."
    echo "설치를 종료합니다. 다시 시도해 주세요. "
    echo ""
    exit 1
fi

echo -n "Leaqua 웹앱 로그인용 아이디를 설정합니다: "
read app_user_id
echo ""

echo -n "Leaqua 웹앱 로그인용 암호를 설정합니다: "
stty -echo
read app_user_password
echo ""
echo ""
stty echo

echo -n "Leaqua 웹앱 로그인용 암호 확인: "
stty -echo
read app_user_password_confirm
echo ""
echo ""
stty echo

if [ "$app_user_password" != "$app_user_password_confirm" ]; then
    echo "Leaqua 웹앱 로그인용 암호가 일치하지 않습니다."
    echo "설치를 종료합니다. 다시 시도해 주세요. "
    echo ""
    exit 1
fi

read -n 1 -p "arduino 부트로더를 설치할까요? 부트로더는 새 atmega328 IC 에 처음 한번만 설치하면 됩니다.  (y/N)"
bootloder_reple=$REPLY






echo -e "\033[33m## git 패키지 설치확인\033[0m"
dpkg-query -W git > /dev/null 2>&1
if [ "$?" -eq 0 ]; then
    echo " 이미 git 패키지가 설치되어 있습니다"
else
    echo " git 패키지를 설치합니다"
    sudo apt-get -y install git git-core
fi
read -n 1 -p "아무키나 누르세요...."


echo -e "\033[33m## LCD 자동끄기 비활성\033[0m"
grep "setterm -blank 0 -powerdown 0 -powersave off" /etc/rc.local > /dev/null 2>&1
if [ "$?" -eq 0 ]; then
    echo " 이미 LCD 자동끄기 설정이 되어 있습니다"
else
    echo " LCD 자동끄기를 비활성화 시킵니다"
    ##부팅시 절전모드 끄기 (LCD 꺼짐방지)
    sudo sed -i "/^fi/ a\# Disable console blanking\nsetterm -blank 0 -powerdown 0 -powersave off\n" /etc/rc.local
    ##sudo python $DIRECTORY/leaqua.py
fi
read -n 1 -p "아무키나 누르세요...."




echo -e "\033[33m## 자동 시간동기화 설치\033[0m"
dpkg-query -W ntpdate > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " ntp 패키지를 설치합니다"
    sudo apt-get -y install ntpdate
fi

sudo grep "ntpdate" /var/spool/cron/crontabs/root > /dev/null 2>&1
if [ "$?" -eq 0 ]; then
    echo " 이미 자동 시간동기화 설정이 되어 있습니다."
else
    echo " 자동 시간동기화 설정"
    sudo touch /var/spool/cron/crontabs/root 
    #sudo sed -i '$a\0 0 * * *  ntpdate -u 3.kr.pool.ntp.org' /var/spool/cron/crontabs/root
    sudo echo "0 0 * * *  sudo ntpdate -u 3.kr.pool.ntp.org" | crontab
fi
read -n 1 -p "아무키나 누르세요...."




echo -e "\033[33m## 램디스크(15Mb) 를 설정합니다\033[0m"
if [ -d "/var/ramdisk" ]; then
    echo ""
else
    sudo mkdir /var/ramdisk
fi
sudo grep "tmpfs     /var/ramdisk" /etc/fstab > /dev/null 2>&1

if [ "$?" -eq 0 ]; then
    echo " 이미 램디스크가  설정이 되어 있습니다."
else
    sudo sed -i '$a\tmpfs     /var/ramdisk     tmpfs     nodev,nosuid,size=15M     0     0' /etc/fstab
    sudo mount -a
fi

read -n 1 -p "아무키나 누르세요...."




echo -e "\033[33m## Webapp 설정\033[0m"
git clone https://github.com/madkritz/leaqua
cd /home/pi/leaqua/www/
git clone https://github.com/amcharts/amcharts3
cd $DIRECTORY
sudo mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bak
sudo cp /home/pi/leaqua/apache-default.conf /etc/apache2/sites-available/000-default.conf

touch /tmp/mysql_dbusersetup_temp 
echo "create database IF NOT EXISTS leaqua;" >> /tmp/mysql_dbusersetup_temp 
echo "GRANT all privileges on leaqua.* TO leaqua@localhost IDENTIFIED BY '$leaquapass';" >> /tmp/mysql_dbusersetup_temp  
mysql -u root -p$pass mysql < /tmp/mysql_dbusersetup_temp 
rm -f /tmp/mysql_dbusersetup_temp
mysql -u leaqua -p$leaquapass leaqua < leaqua.sql
touch /tmp/leaqua_usersetup_temp
echo "insert into leaqua_users values('','$app_user_id',SHA1('$app_user_password'),'',1);" > /tmp/leaqua_usersetup_temp
mysql -uleaqua -p$leaquapass leaqua < /tmp/leaqua_usersetup_temp
rm -f /tmp/leaqua_usersetup_temp

sudo sed -i "s/__DB_PASSWORD__/$leaquapass/g" /home/pi/leaqua/www/access.class.php
sudo sed -i "s/__DB_PASSWORD__/$leaquapass/g" /home/pi/leaqua/www/index.html
sudo sed -i "s/__DB_PASSWORD__/$leaquapass/g" /home/pi/leaqua/www/chart.html
sudo sed -i "s/__DB_PASSWORD__/$leaquapass/g" /home/pi/leaqua/python/leaqua.py
#sudo cp -r /home/pi/leaqua/www/* /var/www/html/

#램디스크 링크 설정
if [ ! -h "/home/pi/leaqua/www/tmp" ]; then
    sudo ln -s /var/ramdisk /home/pi/leaqua/www/tmp
    sudo chmod 777 /home/pi/leaqua/www/tmp
fi    

read -n 1 -p "아무키나 누르세요...."




echo -e "\033[33m## Python 용 라이브러리 설치\033[0m"
dpkg-query -W python-mysqldb > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " python-mysqldb 패키지를 설치합니다"
    sudo apt-get -y install python-mysqldb
fi

dpkg-query -W python-psutil > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " python-psutil 패키지를 설치합니다"
    sudo apt-get -y install python-psutil
fi
read -n 1 -p "아무키나 누르세요...."

dpkg-query -W python-pygame > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " python-pygame 패키지를 설치합니다"
    sudo apt-get -y install python-pygame
fi
read -n 1 -p "아무키나 누르세요...."




echo -e "\033[33m## avrdude 설치\033[0m"
dpkg-query -W avrdude > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " avrdude 패키지를 설치합니다"
    wget http://project-downloads.drogon.net/gertboard/avrdude_5.10-4_armhf.deb 
    sudo dpkg -i avrdude_5.10-4_armhf.deb
    sudo chmod 4755 /usr/bin/avrdude
fi
read -n 1 -p "아무키나 누르세요...."




echo -e "\033[33m## Arduino IDE 설치\033[0m"
dpkg-query -W arduino > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " arduino 패키지를 설치합니다"
    sudo apt-get -y install arduino
fi

dpkg-query -W arduino-mk > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " arduino-mk 패키지를 설치합니다"
    sudo apt-get -y install arduino-mk
fi

read -n 1 -p "아무키나 누르세요...."




echo -e "\033[33m## Arduino IDE 환경설정\033[0m"
wget http://project-downloads.drogon.net/gertboard/setup.sh
sudo chmod +x setup.sh
sudo ./setup.sh

sudo echo 'KERNEL=="ttyAMA0", SYMLINK+="ttyS0",GROUP="dialout",MODE:=0666' >> /etc/udev/rules.d/85-paperduinopi.rules

grep "leaqua.name=" /usr/share/arduino/hardware/arduino/boards.txt > /dev/null 2>&1
if [ "$?" -eq 0 ]; then
    echo " 이미 boards.txt 파일에 Leaqua 보드설정이 되어 있습니다."
else
    echo "  boards.txt 파일에 Leaqua 보드를 등록합니다."
       
    echo " 
##############################################################

leaqua.name=Raspberrypi with ATmega328p GPIO
leaqua.upload.using=gpio
leaqua.upload.protocol=gpio
leaqua.upload.maximum_size=30720
leaqua.upload.speed=57600
leaqua.upload.disable_flushing=true
leaqua.bootloader.low_fuses=0xFF
leaqua.bootloader.high_fuses=0xDA
leaqua.bootloader.extended_fuses=0x05
leaqua.bootloader.path=optiboot
leaqua.bootloader.file=optiboot_atmega328.hex
leaqua.bootloader.unlock_bits=0x3F
leaqua.bootloader.lock_bits=0x0F
leaqua.build.mcu=atmega328p
leaqua.build.f_cpu=16000000L
leaqua.build.core=arduino
leaqua.build.variant=standard" >> /usr/share/arduino/hardware/arduino/boards.txt
fi

sudo sed -i '/"gpio"/,/mosi/s/reset = 8/reset = 4/g' /etc/avrdude.conf

sudo rm setup.sh
read -n 1 -p "아무키나 누르세요...."




# atmega328p에 부트로더 설치
if [[ $bootloder_reple == [yY] ]]; then
    echo -e "\033[33m## atmega328p에 부트로더 설치\033[0m"
    sudo avrdude -c gpio -p m328p -v -e  -U flash:w:/usr/share/arduino/hardware/arduino/bootloaders/optiboot/optiboot_atmega328.hex -U efuse:w:0x05:m -U hfuse:w:0xD6:m -U lfuse:w:0xFF:m
fi




echo -e "\033[33m## scons 설치\033[0m"
dpkg-query -W python-serial > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " python-serial 패키지를 설치합니다"
    sudo apt-get -y install python-serial
fi

dpkg-query -W scons > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " scons 패키지를 설치합니다"
    sudo apt-get -y install scons
fi

if [ -d "sketch" ]; then
    echo "sketch 디렉터리가 이미 존재합니다"
else
    cd /home/pi/leaqua
    mkdir sketch
    cd sketch
    git clone https://code.google.com/r/kylecgordon-arscons/

    sudo cp /home/pi/leaqua/sketch/kylecgordon-arscons/SConstruct /home/pi/leaqua/leaqua_arduino/SConstruct
    sudo cp -r /home/pi/leaqua/leaqua_arduino/libraries/Time /usr/share/arduino/libraries/
    #아래 두줄은 컴파일시 WProgram.h 관련 에러 때문에 제거
    sudo rm -r /usr/share/arduino/libraries/Robot_Control
    sudo rm -r /usr/share/arduino/libraries/Robot_Motor
fi
echo -e "\033[33m## leaqua_arduino를 컴파일 하고 업로드 합니다\033[0m"
cd /home/pi/leaqua/leaqua_arduino
#소스코드 컴파일 해서 펌웨어 업로드
sudo scons ARDUINO_PORT=/dev/ttyS0 ARDUINO_BOARD=leaqua ARDUINO_VER=1.0.1 ARDUINO_HOME=/usr/share/arduino upload
cd /home/pi/leaqua

read -n 1 -p "아무키나 누르세요...."


echo -e "\033[33m## 터치스크린 설치\033[0m"
#/boot/config.txt 에 dtoverlay=hy28b, rotate=90, speed=48000000, fps=20 추가
grep "dtoverlay=hy28b" /boot/config.txt > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo "  hy28b 드라이버를 사용하도록 설정합니다"
    sudo sed -i '$a\dtparam=spi=on' /boot/config.txt 
    sudo sed -i '$a\dtparam=i2c_arm=on' /boot/config.txt 
    sudo sed -i '$a\dtoverlay=hy28b, rotate=90, speed=48000000, fps=20' /boot/config.txt
fi
#/boot/cmdline.txt 는 dwc_otg.lpm_enable=0   root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait fbcon=map:10 fbcon=font:ProFont6x11
grep "fbcon=map:10" /boot/cmdline.txt > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    sudo sed -i "1s/rootwait/rootwait fbcon=map:10 fbcon=font:ProFont6x11/" /boot/cmdline.txt
fi
#/etc/udev/rules.d/95-ads7846.rules 이 파일에 아래 내용 추가
if [ ! -f /etc/udev/rules.d/95-ads7846.rules ]; then
cd /home/pi
touch 95-ads7846.rules 
echo "SUBSYSTEM==\"input\", ATTRS{name}==\"ADS7846 Touchscreen\", ENV{DEVNAME}==\"*event*\", SYMLINK+=\"input/touchscreen\"" >> 95-ads7846.rules
sudo cp 95-ads7846.rules /etc/udev/rules.d/95-ads7846.rules
rm 95-ads7846.rules
cd /home/pi/leaqua
fi



echo -e "\033[33m## 터치스크린 보정 프로그램 설치\033[0m"
sudo apt-get install -y libts-bin evtest xinput python-dev python-pip
pip install evdev


############################################################################################
#ts_calibrate 등에서는 문제가 없으나 pygame 에서 터치포인터가 벽에 붙어 버리는 문제가 있어서 해결
#Thanks to heine in the adafruit forums!
#https://forums.adafruit.com/viewtopic.php?f=47&t=76169&p=439894#p435225
############################################################################################
#enable wheezy package sources
echo "deb http://archive.raspbian.org/raspbian wheezy main" > /etc/apt/sources.list.d/wheezy.list
#set stable as default package source (currently jessie)
echo "APT::Default-release \"stable\";" > /etc/apt/apt.conf.d/10defaultRelease
#set the priority for libsdl from wheezy higher then the jessie package
echo "Package: libsdl1.2debian
Pin: release n=jessie
Pin-Priority: -10
Package: libsdl1.2debian
Pin: release n=wheezy
Pin-Priority: 900
" > /etc/apt/preferences.d/libsdl
#install  아래 libsdl1.2debian 설치 관련내용은 재시동후 설치해야 에러가 없음 
#sudo apt-get update
#sudo apt-get -y --force-yes install libsdl1.2debian/wheezy
#sudo TSLIB_FBDEVICE=/dev/fb1 TSLIB_TSDEVICE=/dev/input/event0 ts_calibrate

echo "
설치가 완료되었습니다!

입력하신 정보는 다음과 같습니다. 

웹앱의 사용자 아이디 :  $app_user_id
웹앱의 사용자 암호 : $app_user_password

재시동 한다음  sudo TSLIB_FBDEVICE=/dev/fb1 TSLIB_TSDEVICE=/dev/input/event0 ts_calibrate 를 실행해 주세요

"
