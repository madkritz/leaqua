#!/usr/bin/python
# -*- coding: utf-8 -*-
# touchv6
# LeAqua v2.03c
# install first "sudo apt-get install python-psutil"

import pygame, sys, os
import pygame.image
import serial
import time
import MySQLdb
import threading
import psutil
from subprocess import PIPE, Popen
from pygame.locals import *
from time import localtime, strftime
from xml.etree.ElementTree import parse

# Init framebuffer/touchscreen environment variables
from evdev import InputDevice, list_devices
devices = map(InputDevice, list_devices())
eventX=""
for dev in devices:
    if dev.name == "ADS7846 Touchscreen":
        eventX = dev.fn
print eventX

os.environ["SDL_FBDEV"] = "/dev/fb1"
os.environ["SDL_MOUSEDRV"] = "TSLIB"
os.environ["SDL_MOUSEDEV"] = eventX

# Init pygame and screen
print "Initting..."
pygame.init()
pygame.mouse.set_visible(False)

# set up the window
print "Setting fullscreen..."
# 320x240 화면을 설정..
screen = pygame.display.set_mode((320, 240), 0, 32)
pygame.display.set_caption('LeAqua V2.03')


# CPU 시리얼 번호를 가져옴
cpuserial = "0000000000000000"
try:
    f = open('/proc/cpuinfo','r')
    for line in f:
        if line[0:6]=='Serial':
            cpuserial = line[10:26]
    f.close()
except:
    cpuserial = "ERROR000000000"

# set up the colors
BLACK = (  0,   0,   0)
WHITE = (255, 255, 255)
RED   = (255,   0,   0)
GREEN = (  0, 255,   0)
BLUE  = (  0,   0, 255)
CYAN  = (  0, 255, 255)
MAGENTA=(255,   0, 255)
YELLOW =(255, 255,   0)

# Atmega에서 넘어온 상태 저장 변수
at_temp=""
at_ph=""
at_orp=""
at_rel1=""
at_rel2=""
at_rel3=""
at_rel4=""
at_rel5=""
at_rel6=""
at_rel7=""
at_rel8=""

# 컨트롤러 설정용 변수
set_temp_cali="0"
set_switch_light="0"
set_max_temp="28"
set_min_temp="25"
set_min_ph="5.00"
set_light_start="0800"
set_light_end="1600"
set_co2_start="0700"
set_co2_end="1530"

		
# Fill background
# 화면과 똑같은 크기의 "표면(surface)"을 만들어라...
background = pygame.Surface(screen.get_size())
background = background.convert()
background.fill(WHITE)

# 스프라이트를 적재하라:
# 다음으로부터 이미지를 가져오라: ./images/sprite1.gif
sprite_file = os.path.join('/home/pi/leaqua/python/', 'leaqua_base.png')
sprite = pygame.image.load(sprite_file).convert()
config_icon = pygame.image.load(os.path.join('/home/pi/leaqua/python/icons/', 'config_icon.png'))
cloud_on_icon = pygame.image.load(os.path.join('/home/pi/leaqua/python/icons/', 'cloudyes_icon.png'))
cloud_off_icon = pygame.image.load(os.path.join('/home/pi/leaqua/python/icons/', 'cloudno_icon.png'))
cooler_icon = pygame.image.load(os.path.join('/home/pi/leaqua/python/icons/', 'cooler_icon.png'))
heater_icon = pygame.image.load(os.path.join('/home/pi/leaqua/python/icons/', 'heater_icon.png'))
co2_icon = pygame.image.load(os.path.join('/home/pi/leaqua/python/icons/', 'gas_icon.png'))
light_icon = pygame.image.load(os.path.join('/home/pi/leaqua/python/icons/', 'light_icon.png'))
cooler_off_icon = pygame.image.load(os.path.join('/home/pi/leaqua/python/icons/', 'cooler_off_icon.png'))
heater_off_icon = pygame.image.load(os.path.join('/home/pi/leaqua/python/icons/', 'heater_off_icon.png'))
co2_off_icon = pygame.image.load(os.path.join('/home/pi/leaqua/python/icons/', 'gas_off_icon.png'))
light_off_icon = pygame.image.load(os.path.join('/home/pi/leaqua/python/icons/', 'light_off_icon.png'))
info_icon = pygame.image.load(os.path.join('/home/pi/leaqua/python/icons/', 'info_icon.png'))
accept_icon = pygame.image.load(os.path.join('/home/pi/leaqua/python/icons/', 'accept_icon.png'))
cancel_icon = pygame.image.load(os.path.join('/home/pi/leaqua/python/icons/', 'cancel_icon.png'))


# 스프라이트의 초기 위치를 획득하라, 
sprite_position = sprite.get_rect()
config_icon_position = config_icon.get_rect()
cloud_on_icon_position = cloud_on_icon.get_rect()
cloud_off_icon_position = cloud_off_icon.get_rect()
cooler_icon_position = cooler_icon.get_rect()
heater_icon_position = heater_icon.get_rect()
co2_icon_position = co2_icon.get_rect()
light_icon_position = light_icon.get_rect()
info_icon_position = info_icon.get_rect()
accept_icon_position = accept_icon.get_rect()
cancel_icon_position = cancel_icon.get_rect()


# 아이콘들의 위치 
sprite_position.top = 0
sprite_position.left = 0
config_icon_position.top = 187
config_icon_position.left = 140
info_icon_position.top = 189
info_icon_position.left = 248
accept_icon_position.top = 189
accept_icon_position.left = 248
cancel_icon_position.top = 189
cancel_icon_position.left =143
cloud_on_icon_position.top = 192
cloud_on_icon_position.left =37
cloud_off_icon_position = cloud_on_icon_position
cooler_icon_position.top = 104
cooler_icon_position.left = 270
heater_icon_position.top = 100
heater_icon_position.left = 227
co2_icon_position.top = 50
co2_icon_position.left = 271
light_icon_position.top = 50
light_icon_position.left = 227

# 폰트 설정 
#nanum = r'/home/pi/leaqua/Nanum.ttf'
digital = r'/home/pi/leaqua/python/digital-7.ttf'
#font = pygame.font.Font(nanum, 14)
font1 = pygame.font.Font(digital, 16)
font2 = pygame.font.Font(digital, 24)
font3 = pygame.font.Font(digital, 34)

font1.set_italic(0)
font2.set_italic(0)
font3.set_italic(0)

#text = font.render(u"여기를 터치하면 종료합니다.", 1, (WHITE))
text_temp = font2.render("TEMP : 26.5'", 1, (WHITE))
text_ph = font2.render("PH   : 08.3", 1, (WHITE))
text_orp = font2.render("ORP  : -0320mv", 1, (WHITE))
text_ser = font2.render(" ", 1, (WHITE)) 

timeStamp = time.strftime("%Y-%m-%d %H:%M:%S")
text_clock = font3.render(timeStamp, 1, (WHITE))

text_infotitle = font1.render("SYSTEM INFORMATION", 1, (WHITE))
text_cpu = font1.render("CPU USE : ", 1, (WHITE))
text_ramtotal = font1.render("RAM TOTAL : ", 1, (WHITE))
text_ramuse = font1.render("RAM USE : ", 1, (WHITE))
text_disktotal = font1.render("DISK TOTAL : ", 1, (WHITE))
text_diskfree =  font1.render("DISK free : ", 1, (WHITE))
text_cpuserial = font1.render("S/N : ", 1, (WHITE))

text_clock_pos = (10 , 10) 
text_temp_pos = (10 , 50)
text_ph_pos = (10 , 80)
text_orp_pos = (10 , 110)
text_ser_pos = (10 , 140)

text_infotitle_pos = (10, 10)
text_cpu_pos = (10 , 35)
text_ramtotal_pos = (10 , 60)
text_ramuse_pos = (10 , 85)
text_disktotal_pos = (10 , 110)
text_diskfree_pos = (10 , 135)
text_cpuserial_pos = (10 , 160)

#text = pygame.transform.rotate(text,270)
#textpos = text.get_rect(centerx=background.get_width()/2,centery=background.get_height()/2)

screen.blit(background, (0, 0))
screen.blit(sprite, sprite_position)

#UART 통신 설정
ser = serial.Serial("/dev/ttyAMA0",9600)
sertext = ""

#무슨 문제인지 한방에 연결안됨 -_-;;
ser.writelines("connect\n")
ser.close()
time.sleep(1)
ser = serial.Serial("/dev/ttyAMA0",9600)


#mySql 오픈
db = MySQLdb.connect("localhost", "leaqua", "__DB_PASSWORD__", "leaqua")
dbcurs=db.cursor()
#5분마다 저장 300 
db_SaveDelay = 300
#현재시간 저장 
db_SaveTime = int(time.time())


cloud_accept = False
heater_sw = False
cooler_sw = False
light_stat = False
co2_stat = False

LIGHT_SWITCH = 0  #이더넷으로 조명 on/off 명령을 받아서 처리 하는 변수  2=이더넷 명령이 없음, 0=off, 1=on
TIME_CHANGE = 0     #현재시간이 설정시간으로 변경이 되거나 설정시간이외로 변경이 되는 순간에 데이터가 변경이 된다. 현재시간이 설정시간이나 설정시간 이외로 변경이 되는 순간 ethernet 명령에 대한 모든 행동은 무효
IN_TIME = False

#디스플레이 화면 설정  0: 메인 , 1: 시스템정보 , 3: 설정
display_mode = 0


#######################################################
#   센서값 가져와서 처리 
########################################################
def getsensor():
    global sertext, text_ser, at_temp, at_ph, at_orp, at_rel1, at_rel2, at_rel3, at_rel4, at_rel5, at_rel6, at_rel7, at_rel8, cooler_sw, light_stat, co2_stat, heater_sw

    ser.writelines("201|221| \n")
    #print "Start Uart"
    time.sleep(0.2)
    #시리얼포트에서 한줄 읽어옴
    sertext = ser.readline()
    #print "Read Line:"+sertext
    sertext = sertext.replace("\n","")
    text_parts = sertext.split("|")
    #print "Read Pars:"+text_parts[1]
    if text_parts[0] == "101":
        at_temp=text_parts[1]
        at_ph=text_parts[2]
        at_orp=text_parts[3]
        at_rel1=text_parts[4]
        at_rel2=text_parts[5]
        at_rel3=text_parts[6]
        at_rel4=text_parts[7]
        at_rel5=text_parts[8]
        at_rel6=text_parts[9]
        at_rel7=text_parts[10]
        at_rel8=text_parts[11]
    if len(at_temp) == 0:
        at_temp = "0"
    if len(at_ph) == 0:
        at_ph = "0"
    if len(at_orp) == 0:
        at_orp = "0"

    set_switch_light = at_rel1
    if at_rel1 == "1":
        light_stat = True
    else:
    	  light_stat = False
    if at_rel2 == "1":
        co2_stat = True
    else:
    	  co2_stat = False
    if at_rel3 == "1":
        cooler_sw = True
    else:
    	  cooler_sw = False 
    if at_rel4 == "1":
        heater_sw = True
    else:
    	  heater_sw = False

    
    #파일에 기록
    try:
        f = open("/var/ramdisk/state.xml", 'w')
        data = "<?xml version='1.0'?>\n"
        data += "<note>\n"
        data += "    <temp>%s</temp>\n" % at_temp
        data += "    <ph>%s</ph>\n" % at_ph
        data += "    <orp>%s</orp>\n" % at_orp
        data += "    <rel1>%s</rel1>\n" % at_rel1
        data += "    <rel2>%s</rel2>\n" % at_rel2
        data += "    <rel3>%s</rel3>\n" % at_rel3
        data += "    <rel4>%s</rel4>\n" % at_rel4
        data += "    <rel5>%s</rel5>\n" % at_rel5
        data += "    <rel6>%s</rel6>\n" % at_rel6
        data += "    <rel7>%s</rel7>\n" % at_rel7
        data += "    <rel8>%s</rel8>\n" % at_rel8
        data += "    <time>%s</time>\n" % time.strftime("%Y-%m-%d_%H:%M:%S")
        data += "</note>"
        f.write(data) 
        f.close()
        os.chmod("/var/ramdisk/state.xml", 0777)
    except:
        print "file write error"

    ser.writelines("201|255| \n")
    #print "Start Uart"
    time.sleep(0.2)
    #시리얼포트에서 한줄 읽어옴
    sertext = ser.readline()
    #print "Read Line:"+sertext
    sertext = sertext.replace("\n","")
    text_parts = sertext.split("|")
    #print "Read Pars:"+text_parts[1]
    if text_parts[0] == "155":
        _volt=text_parts[1]
        _adc=text_parts[2]
        _temp=text_parts[3]
    try:
        f = open("/var/ramdisk/debug.xml", 'w')
        data = "<?xml version='1.0'?>\n"
        data += "<note>\n"
        data += "    <volt>%s</volt>\n" % _volt
        data += "    <temp_adc>%s</temp_adc>\n" % _adc
        data += "    <temp>%s</temp>\n" % _temp
        data += "</note>"
        f.write(data) 
        f.close()
        os.chmod("/var/ramdisk/debug.xml", 0777)
    except:
        print "file write error"
        
#atmega328 에 온도보정,최고온도,최저온도,최저PH값 저장 
#타이머를 제외한 값을 저장하는 이유는 raspberry pi 가 다운되어도 온도관련된 작동은 atmega에서 알아서 처리하게끔 하기 위함이다
def setAvr():
    global set_temp_cali, set_max_temp, set_min_temp, set_min_ph
    ser.writelines("201|222|"+set_temp_cali+"|"+set_max_temp+"|"+set_min_temp+"|"+set_min_ph+"|999| \n")
    time.sleep(0.2)
    #print "setAvr 201|222|"+set_temp_cali+"|"+set_max_temp+"|"+set_min_temp+"|"+set_min_ph+"|999|"
    
#atmega328 에서 온도보정,최고온도,최저온도,최저PH값 가져옴 
def getAvr():
    global set_temp_cali, set_max_temp, set_min_temp, set_min_ph
    ser.writelines("201|223| \n")
    time.sleep(0.2)
    sertext = ser.readline()
    sertext = sertext.replace("\n","")
    text_parts = sertext.split("|")
    if text_parts[0] == "102":
        set_temp_cali=text_parts[1]
        set_max_temp=text_parts[2]
        set_min_temp=text_parts[3]
        set_min_ph=text_parts[4]
    #print "getAvr 102|"+set_temp_cali+"|"+set_max_temp+"|"+set_min_temp+"|"+set_min_ph+"|"
    
#조명과 CO2 릴레이 작동시킴
def setRelay():
    global light_stat, co2_stat
    _light_stat = ""
    _co2_stat = ""
    if light_stat == True:
        _light_stat = "1"
    else:
    	  _light_stat = "0"
    if co2_stat == True:
        _co2_stat = "1"
    else:
    	  _co2_stat = "0"    
    ser.writelines("201|224|"+_light_stat+"|"+_co2_stat+"|999| \n")
    time.sleep(0.2)

#초기 시동시 조명상태 읽어옴
getsensor()
getAvr()


#초기 시동시 마지막 설정값 읽어옴
if os.path.isfile("/home/pi/leaqua/python/get_"+cpuserial+".xml"):
    #SET 파일에서 읽어옴
    stree = parse("/home/pi/leaqua/python/get_"+cpuserial+".xml")
    snote = stree.getroot()

    #set_temp_cali = snote.find("temp_calibration").text
    #set_max_temp = snote.find("temp_max").text
    #set_min_temp = snote.find("temp_min").text
    #set_min_ph = snote.find("ph_min").text
    set_light_start = snote.find("light_starttime").text
    set_light_end = snote.find("light_endtime").text
    set_co2_start = snote.find("co2_starttime").text
    set_co2_end = snote.find("co2_endtime").text
    
    if light_stat == True:
        set_switch_light = "1"
        
    #GET 파일에 기록
    try:
        f = open("/var/ramdisk/get_"+cpuserial+".xml", 'w')
        data = "<?xml version='1.0'?>\n"
        data += "<note>\n"
        data += "    <light>%s</light>\n" % set_switch_light
        data += "    <temp_calibration>%s</temp_calibration>\n" % set_temp_cali
        data += "    <temp_max>%s</temp_max>\n" % set_max_temp
        data += "    <temp_min>%s</temp_min>\n" % set_min_temp
        data += "    <ph_min>%s</ph_min>\n" % set_min_ph
        data += "    <light_starttime>%s</light_starttime>\n" % set_light_start
        data += "    <light_endtime>%s</light_endtime>\n" % set_light_end
        data += "    <co2_starttime>%s</co2_starttime>\n" % set_co2_start
        data += "    <co2_endtime>%s</co2_endtime>\n" % set_co2_end
        data += "    <time>%s</time>\n" % time.strftime("%Y-%m-%d_%H:%M:%S")
        data += "</note>"
        f.write(data)
        f.close()
        os.chmod("/var/ramdisk/get_"+cpuserial+".xml", 0777)
                
    except:
        print "get_"+cpuserial+".xml : file write error"
            

def get_cpu_usage():
    return psutil.cpu_percent()



def get_cpu_temperature():
    process = Popen(['vcgencmd', 'measure_temp'], stdout=PIPE)
    output, _error = process.communicate()
    return float(output[output.index('=') + 1:output.rindex("'")])

# RAM 의 kb 정보를 배열로 가져옴 
# Index 0: total RAM
# Index 1: used RAM
# Index 2: free RAM
def getRAMinfo():
    p = os.popen('free')
    i = 0
    while 1:
        i = i + 1
        line = p.readline()
        if i==2:
            return(line.split()[1:4])

# 디스크 공간값이 들어있는 배열을 가져옴
# Index 0: total disk space                                                         
# Index 1: used disk space                                                          
# Index 2: remaining disk space                                                     
# Index 3: percentage of disk used                                                  
def getDiskSpace():
    p = os.popen("df -h /")
    i = 0
    while 1:
        i = i +1
        line = p.readline()
        if i==2:
            return(line.split()[1:5])

      
def draw_screen():
    global display_mode

    #clear screen		
    screen.blit(sprite, sprite_position)

    if display_mode == 0:
        clock_position = text_clock.get_rect()
        temp_position = text_temp.get_rect()
        screen.blit(text_clock, text_clock_pos)
        screen.blit(text_temp, text_temp_pos)
        screen.blit(text_ph, text_ph_pos)
        screen.blit(text_orp, text_orp_pos)
        screen.blit(text_ser, text_ser_pos)
        screen.blit(config_icon, config_icon_position)
        screen.blit(info_icon, info_icon_position)
                                                
        if cloud_accept == False:
            screen.blit(cloud_off_icon,cloud_off_icon_position)
        elif cloud_accept == True:
            screen.blit(cloud_on_icon,cloud_on_icon_position)
        if cooler_sw == True:
            screen.blit(cooler_icon,cooler_icon_position)
        else:
            screen.blit(cooler_off_icon,cooler_icon_position)
        if heater_sw == True:
            screen.blit(heater_icon,heater_icon_position)
        else:
            screen.blit(heater_off_icon,heater_icon_position)
        if co2_stat == True:
            screen.blit(co2_icon,co2_icon_position)
        else:
            screen.blit(co2_off_icon,co2_icon_position)
        if light_stat == True:
            screen.blit(light_icon,light_icon_position)
        else:
            screen.blit(light_off_icon,light_icon_position)

    if display_mode == 1:
        screen.blit(text_infotitle, text_infotitle_pos)
        screen.blit(text_cpu, text_cpu_pos)
        screen.blit(text_ramtotal, text_ramtotal_pos)
        screen.blit(text_ramuse, text_ramuse_pos)
        screen.blit(text_disktotal, text_disktotal_pos)
        screen.blit(text_diskfree, text_diskfree_pos)
        screen.blit(text_cpuserial, text_cpuserial_pos)
        screen.blit(accept_icon, accept_icon_position)

    pygame.display.update()

		
#타이머 
class ExTimer(threading.Thread):
 
    def __init__(self): 
        threading.Thread.__init__(self) 
        # default delay set.. 
        self.delay = 1
        self.state = True
        self.handler = None

    def setDelay(self, delay): 
        self.delay = delay

    def run(self): 
        while self.state: 
            time.sleep( self.delay ) 
            if self.handler != None: 
                self.handler()
 
    def end(self): 
        self.state = False                
 
    def setHandler(self, handler): 
        self.handler = handler


def relayTimer():
    global set_light_start, set_light_end, set_co2_start, set_co2_end, LIGHT_SWITCH, TIME_CHANGE, IN_TIME, light_stat, co2_stat

    _set_light_start = int(set_light_start)
    _set_light_end = int(set_light_end)
    _set_co2_start = int(set_co2_start)
    _set_co2_end = int(set_co2_end)
    _hour = time.strftime("%H")
    _minute = time.strftime("%M")
    _timeNow = (int(_hour) * 100) + int(_minute)
    
    #현재시간과 비교해서 조명 켜기
    if (_set_light_start > 0) and (_set_light_end > 0 ):
        #일반적인 타이머 시작시간이 종료시간 보다 작은 경우 (주간 작동)
        if _set_light_start < _set_light_end:
            if (_set_light_start <= _timeNow) and (_set_light_end > _timeNow):  
                IN_TIME = True
            else:
                IN_TIME = False

        #24시를 넘어가는 타이머 종료시간이 시작시간 보다 작은 경우 (야간작동)
        if _set_light_start > _set_light_end:
            if (_set_light_start <= _timeNow) or (set_light_end > _timeNow): 
                IN_TIME = True
            else:
                IN_TIME = False
        
        if IN_TIME:  #설정시간 이내이면 켜짐
            if TIME_CHANGE != 1:
                TIME_CHANGE = 1
                LIGHT_SWITCH = 2
            
            if (LIGHT_SWITCH == 2) or (LIGHT_SWITCH == 1):  #ethernet으로 on 이거나 설정 시간 이내면 on
                light_stat = True
            elif LIGHT_SWITCH == 0: # ethernet으로 off
                light_stat = False
        
        else:  # 설정 시간 이외면 off
            if TIME_CHANGE != 2:
                TIME_CHANGE = 2
                LIGHT_SWITCH = 2
            if LIGHT_SWITCH == 1:  #ethernet으로 on
                light_stat = True
            elif (LIGHT_SWITCH == 2) or (LIGHT_SWITCH == 0): #ethernet으로 off 이거나 설정식간 이외면 off
                light_stat = False
   
    #현재시간과 비교해서 CO2 켜기
    if (_set_co2_start > 0) and (_set_co2_end > 0 ):
        #24시를 넘어가는 타임인지 확인
        if _set_co2_start < _set_co2_end:
            if (_set_co2_start <= _timeNow) and (_timeNow < _set_co2_end):
              co2_stat = True
            else:
              co2_stat = False
        else:
            if (_set_co2_start <= _timeNow) or (_timeNow < _set_co2_end):
              co2_stat = True
            else:
              co2_stat = False
    else:
         co2_stat = False

    setRelay()

def valueSet():
    global cpuserial, set_temp_cali, LIGHT_SWITCH, light_stat, set_max_temp, set_min_temp, set_min_ph, set_light_start, set_light_end, set_co2_start, set_co2_end

    if light_stat == True:
        _light_switch = "1"
    else:
    	_light_switch = "0"
    
    changeVal = False
        	      
    if os.path.isfile("/var/ramdisk/set_"+cpuserial+".xml"):
        #SET 파일에서 읽어옴
        tree = parse("/var/ramdisk/set_"+cpuserial+".xml")
        note = tree.getroot()

        set_mode = note.find("mode").text
        
        if set_mode == "set_light":
            _light_switch = note.find("light").text
            if _light_switch == "1":
                LIGHT_SWITCH = True
            else:
            	  LIGHT_SWITCH = False
               
        if set_mode == "save_value":
            set_temp_cali = note.find("temp_calibration").text
            set_max_temp = note.find("temp_max").text
            set_min_temp = note.find("temp_min").text
            set_min_ph = note.find("ph_min").text
            set_light_start = note.find("light_starttime").text
            set_light_end = note.find("light_endtime").text
            set_co2_start = note.find("co2_starttime").text
            set_co2_end = note.find("co2_endtime").text

            setAvr()
            getAvr()
        #작업후 파일 삭제    
        os.unlink("/var/ramdisk/set_"+cpuserial+".xml")
        #설정값이 변했다
        changeVal = True

    #GET 파일에 기록
    data = "<?xml version='1.0'?>\n"
    data += "<note>\n"
    data += "    <light>%s</light>\n" % _light_switch
    data += "    <temp_calibration>%s</temp_calibration>\n" % set_temp_cali
    data += "    <temp_max>%s</temp_max>\n" % set_max_temp
    data += "    <temp_min>%s</temp_min>\n" % set_min_temp
    data += "    <ph_min>%s</ph_min>\n" % set_min_ph
    data += "    <light_starttime>%s</light_starttime>\n" % set_light_start
    data += "    <light_endtime>%s</light_endtime>\n" % set_light_end
    data += "    <co2_starttime>%s</co2_starttime>\n" % set_co2_start
    data += "    <co2_endtime>%s</co2_endtime>\n" % set_co2_end
    data += "    <time>%s</time>\n" % time.strftime("%Y-%m-%d_%H:%M:%S")
    data += "</note>"
    try:
    	  #현재상태 램디스크에 기록
        f = open("/var/ramdisk/get_"+cpuserial+".xml", 'w')
        f.write(data) 
        f.close()
        os.chmod("/var/ramdisk/get_"+cpuserial+".xml", 0777)
        #설정값이 변했다면 프로그램 경로에도 기록해놓은다
        if changeVal == True:
            f = open("/home/pi/leaqua/python/get_"+cpuserial+".xml", 'w')
            f.write(data) 
            f.close()
            os.chmod("/home/pi/leaqua/python/get_"+cpuserial+".xml", 0777)
    except:
        print "file write error"
            
def timerHandler():
    global timeStamp, text_clock, text_temp, text_ph, text_orp, text_infotitle, text_cpu, text_ramtotal, text_ramuse, text_disktotal, text_diskfree, text_cpuserial, sertext, text_ser, at_temp, at_ph, at_orp, at_rel1, at_rel2, at_rel3, at_rel4, at_rel5, at_rel6, at_rel7, at_rel8 , db_SaveDelay, db_SaveTime

    CurrentTime = int(time.time())

    if (db_SaveDelay < (CurrentTime - db_SaveTime)):
        db_SaveTime = int(time.time())
        try:
            sql = "INSERT INTO leaqua (temp,date,ph,orp,rel1,rel2,rel3,rel4,rel5,rel6,rel7,rel8) values(" +"'"+ at_temp +"', NOW(), '"+ at_ph +"', '"+ at_orp + "', "+ at_rel1 + ", " + at_rel2 + ", " + at_rel3 + ", " + at_rel4 + ", " + at_rel5 + ", " + at_rel6 + ", " + at_rel7 + ", " + at_rel8 +")"
            dbcurs.execute(sql)
            sql2 = "INSERT INTO leaqua_maxmin (temp,ph,orp) values(" +"'"+ at_temp +"', '"+ at_ph +"', '"+ at_orp +"')"
            dbcurs.execute(sql2)
            db.commit()
            
            ##leaqua_maxmin 테이블에서 최근 24시간내의 데이터만 남기고 삭제 (전체 테이블에서 오늘날짜의 최고/최저 수질값을 뽑으려면 시간이 너무 많이 걸림
            dbcurs.execute("SELECT id FROM leaqua_maxmin ORDER BY id DESC LIMIT 1")
            lastid = dbcurs.fetchone()
            deleteid = lastid[0] - 288 #5분 단위 저장이므로 24시간은 288번 기록
            delsql = "DELETE from leaqua_maxmin WHERE id <= %d" % deleteid 
            dbcurs.execute(delsql)
            db.commit()
            #print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!! DB Execute"
        except:
            #print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!! DB Error Rollback"
            db.rollback()

    valueSet()
    getsensor()
    relayTimer()

    #화면 출력값 설정
    if display_mode == 0:
        timeStamp = time.strftime("%Y-%m-%d %H:%M:%S")
        text_clock = font3.render(timeStamp, 1, (WHITE))
        tempPrint = "Temp : "+str(at_temp)
        text_temp = font2.render(tempPrint, 1, (WHITE))
        phPrint = "PH   : "+str(at_ph)
        text_ph = font2.render(phPrint, 1, (WHITE))
        orpPrint = "ORP  : "+str(at_orp)+"mv"
        text_orp = font2.render(orpPrint, 1, (WHITE))
        #sertext 는 디버깅을 위해서 atmega328 과 통신된 값을 출력하게 된다 
        #text_ser = font2.render(sertext, 1, (WHITE))
    elif display_mode == 1:
        CPU_temp = str(get_cpu_temperature())
        CPU_usage = str(get_cpu_usage())
        CPU_serial = cpuserial
        RAM_stats = getRAMinfo()
        RAM_total = str(round(int(RAM_stats[0]) / 1000,1))
        RAM_used = str(round(int(RAM_stats[1]) / 1000,1))
        #RAM_free = round(int(RAM_stats[2]) / 1000,1)
        DISK_stats = getDiskSpace()
        DISK_total = DISK_stats[0]
        DISK_free = DISK_stats[1]
        DISK_perc = DISK_stats[3]
        text_infotitle = font1.render("SYSTEM INFORMATION", 1, (WHITE))
        text_cpu = font1.render("CPU Info : "+CPU_usage+"%  "+CPU_temp+"'C", 1, (WHITE))
        text_ramtotal = font1.render("RAM TOTAL : "+RAM_total+"Mb", 1, (WHITE))
        text_ramuse = font1.render("RAM USE : "+RAM_used+"Mb", 1, (WHITE))
        text_disktotal = font1.render("DISK TOTAL : "+DISK_total, 1, (WHITE))
        text_diskfree =  font1.render("DISK free : "+DISK_free, 1, (WHITE))
        text_cpuserial = font1.render("S/N : "+CPU_serial, 1, (WHITE)) 
    elif display_mode == 2:
        CPU_temp = str(get_cpu_temperature())

    draw_screen()

	
running = True

th = ExTimer()
th.setHandler(timerHandler)
th.setDelay(0.3)
th.start()

print "Start Main Loop..."

event = pygame.event.poll()

while running:
    #for event in pygame.event.get():

    event = pygame.event.wait()
    if event.type == QUIT:
        th.end()
        pygame.quit()
        db.close()
        ser.close()
        sys.exit()
        running = False
    elif event.type == pygame.MOUSEBUTTONDOWN:
       	#print("Pos: %sx%s\n" % pygame.mouse.get_pos())
       	#if textpos.collidepoint(pygame.mouse.get_pos()):
       	if display_mode == 0:
            if config_icon_position.collidepoint(pygame.mouse.get_pos()):
                th.end()
                pygame.quit()
                db.close()
                ser.close()
                sys.exit()
                running = False
            elif cloud_on_icon_position.collidepoint(pygame.mouse.get_pos()):
                if cloud_accept == True:
                    cloud_accept = False
                else:
                    cloud_accept = True
                draw_screen()
            elif info_icon_position.collidepoint(pygame.mouse.get_pos()):
                display_mode = 1
                draw_screen()
            elif event.type == KEYDOWN and event.key == K_ESCAPE:
                th.end()
                pygame.quit()
                db.close()
                ser.close()
                sys.exit()
                running = False

        elif display_mode == 1:
            if accept_icon_position.collidepoint(pygame.mouse.get_pos()):
                display_mode = 0
                draw_screen()

        elif display_mode == 2:
            if accept_icon_position.collidepoint(pygame.mouse.get_pos()):
                display_mode = 0
                draw_screen()

    pygame.display.update()
    #time.sleep(0.1)
