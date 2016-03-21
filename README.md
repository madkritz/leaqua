Leaqua 
--------------------------------------------
Leaqua 설치 프로그램입니다


1 Raspbian Jessie Lite 이미지를 받아서 SD카드에 설치

2 sudo raspi-config 실행하여 기본 설정

    타임존설정
    5 Internationalisation Options 
    2 Change Timezone 
    Asia 선택 엔터-> Seoul 선택 엔터

    메모리 분할
    9 Advanced Options 
    A3 Memory Split 
    32 입력 엔터

    SSH 사용
    9 Advanced Options 
    A4 SSH 
    <Enable>  선택 엔터

    SPI 사용
    9 Advanced Options 
    A5 SPI 
    <Yes>  선택 엔터

    파일시스템 확장
    1 Expand Filesystem  
    raspi-config 종료하면 리부팅하면서 파일시스템확장됨
    
    <Finish> 선택해서 재시동

3 wget https://raw.githubusercontent.com/madkritz/leaqua/master/leaqua.sh

4 chmod +x leaqua.sh

5 sudo ./leaqua.sh





