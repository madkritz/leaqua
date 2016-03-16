#!/bin/bash

DIRECTORY=/home/pi/leaqua

echo -e "\033[33m## APM 확인\033[0m"
dpkg-query -W apache2 > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " 먼저 apache2 패키지를 설치해 주세요"
    exit 1
fi
dpkg-query -W php5 php5-fpm > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " 먼저 php5 php5-fpm 패키지를 설치해 주세요"
    exit 1
fi
dpkg-query -W mysql-server mysql-client > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo " 먼저 mysql-server mysql-client 패키지를 설치해 주세요"
    exit 1
fi




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
    sudo sed -i '$a\0 0 * * *  ntpdate -u 3.kr.pool.ntp.org' /var/spool/cron/crontabs/root
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

if [ ! -h "/var/www/http/tmp" ]; then
    sudo ln -s /var/ramdisk /var/www/http/tmp
    sudo chmod 777 /var/www/http/tmp
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
    sudo sed -i '$a\##############################################################' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.name=Raspberrypi with ATmega328p GPIO' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.upload.using=gpio' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.upload.protocol=gpio' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.upload.maximum_size=30720' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.upload.speed=57600' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.upload.disable_flushing=true' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.bootloader.low_fuses=0xFF' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.bootloader.high_fuses=0xDA' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.bootloader.extended_fuses=0x05' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.bootloader.path=optiboot' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.bootloader.file=optiboot_atmega328.hex' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.bootloader.unlock_bits=0x3F' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.bootloader.lock_bits=0x0F' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.build.mcu=atmega328p' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.build.f_cpu=16000000L' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.build.core=arduino' /usr/share/arduino/hardware/arduino/boards.txt
    sudo sed -i '$a\leaqua.build.variant=standard' /usr/share/arduino/hardware/arduino/boards.txt
fi

sudo sed -i '/"gpio"/,/mosi/s/reset = 8/reset = 4/g' /etc/avrdude.conf

sudo rm setup.sh
read -n 1 -p "아무키나 누르세요...."




echo -e "\033[33m## atmega328p에 부트로더 설치\033[0m"
read -n 1 -p "부트로더를 설치할까요? (y/N)"
if [[ $REPLY == [yY] ]]; then
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
    cd /home/pi/
    mkdir sketch
    cd sketch
    git clone https://code.google.com/r/kylecgordon-arscons/
    cd /home/pi/    
fi
read -n 1 -p "아무키나 누르세요...."

#echo -e "\033[33m## APM 설치\033[0m"
#dpkg-query -W apache2 > /dev/null 2>&1
#if [ "$?" -eq 0 ]; then
#    echo ""
#else
#    echo " apache2 패키지를 설치합니다"
#    sudo apt-get -y install apache2
#    sudo a2enmod rewrite
#    
#fi




## 사용자 이름을 받아들이고 인사를 출력한다
#echo -n "Enter your name: "
# read user_name
## 사용자가 아무 것도 입력하지 않으면:
#if [ -z "$user_name" ]; then
#    echo "You did not tell me your name!"
#    exit
#fi
echo "설치가 완료되었습니다!" 


