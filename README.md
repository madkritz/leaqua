Leaqua 
--------------------------------------------
Leaqua 설치 프로그램입니다

이 문서와 해당 소스코드는 업데이트 작업중이므로 정상적으로 작동하지 않습니다.

1 Raspbian Jessie Lite 이미지를 받아서 SD카드에 설치
2 sudo raspi-config 실행하여 기본 설정

    언어설정
    4 Internationalisation Options 
    1 Change Locale
    [*] ko_KR.UTF-8 UTF-8 스페이스 눌러서 체크 - 엔터
    Default locale for the system environment: 에서 en_GB.UTF-8 선택 엔터

    타임존설정
    4 Internationalisation Options 
    2 Change Timezone 
    Asia 선택 엔터-> Seoul 선택 엔터

    키보드 레이아웃
    4 Internationalisation Options 
    3 Change Keyboard Layout 
    [ ok ] Setting preliminary keymap...done.  자동으로 설정됨

    메모리 분할
    8 Advanced Options 
    A3 Memory Split 
    32 입력 엔터

    SSH 사용
    8 Advanced Options 
    A4 SSH 
    <Enable>  선택 엔터

    SPI 사용
    8 Advanced Options 
    A5 SPI 
    <Yes>  선택 엔터

    파일시스템 확장
    1 Expand Filesystem  
    raspi-config 종료하면 리부팅하면서 파일시스템확장됨

3 apache2 , php , mysql 을 설치
4 wget https://raw.githubusercontent.com/madkritz/leaqua/master/leaqua.sh
5 chmod +x leaqua.sh
6 sudo ./leaqua.sh




