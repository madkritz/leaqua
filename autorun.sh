#!/bin/bash

echo -e "\033[33m## Leaqua를 자동실행 하도록 설정합니다 \033[0m"
grep "python /home/pi/leaqua/python/leaqua.py" /etc/rc.local > /dev/null 2>&1
if [ "$?" -eq 0 ]; then
    echo " 이미 자동실행이 설정이 되어 있습니다"
else
    echo " 부팅시 자동실행을 하도록 설정합니다"
    sudo sed -i "/^fi/ a\ \n# Enable autorun leaqua\nsudo python /home/pi/leaqua/python/leaqua.py\n" /etc/rc.local
fi
