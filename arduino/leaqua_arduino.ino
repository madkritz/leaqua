#include <Time.h> 
#include <EEPROM.h> 
#include <Wire.h>

/* Pin Mapping
A0 			온도
A1 			ORP
A2 			PH
A3 			확장
A4/SDA	SDA(I2C)
A5/SCL	SCL(I2C)

D0			RX
D1 			TX
D2			확장
D3			확장/PWM
D4			확장
D5			확장/PWM
D6			확장/PWM
D7			확장
D8			확장
D9			확장/PWM
D10			확장/PWM
D11			MOSI(SPI)
D12			MISO(SPI)
D13 		SCL(SPI)
*/

// 아날로그 모듈,센서의 설정
//#define ARDUINO_VOLTAGE 5.00  //조금더 정확한 검출을 위해 아래 값에 아두이노의 정확한 전압을 입력합니다.
#define smoothing 40					//PH , ORP, TEMP 읽어서 평균값을 낼 횟수

// address of PCF8574 IC on TWI bus
#define IO_ADDR 0x39

// PIN Setup
#define TEMP_PIN A0        //A7 핀을 온도 입력핀으로 설정
#define PH_PIN A2          //A6 핀을 PH 입력핀으로 설정
#define ORP_PIN A1         //A5 핀을 ORP 입력핀으로 설정
#define VOLT_PIN A3
//#define REL1 2             //D2 핀을 릴레이1 출력핀으로 설정
//#define FAN_PIN 9          //D9 핀을 FAN 출력핀으로 설정

///////////////////////////////////////////////
// 전역 변수
///////////////////////////////////////////////
float ARDUINO_VOLTAGE = 4.96; 

// 아날로그 센서값 평균용
//const int smoothing = 10;     //읽어서 평균값을 낼 횟수 숫자가 클 수록 갑자기 변하는 폭이 줄어드나 부팅시나,계산하는데 시간이 오래 걸림
int temp_readvals[smoothing] ;    //평균 횟수동안 온도 값이 저장될 변수
int temp_index = 0;               //현재 읽혀진 횟수 /  전체횟수 초과시 다시 0
boolean temp_disp = false;
int ph_readvals[smoothing] ;      //평균 횟수동안 PH 값이 저장될 변수
int ph_index = 0;                 //현재 읽혀진 횟수 /  전체횟수 초과시 다시 0
boolean ph_disp = false;
int orp_readvals[smoothing] ;     //평균 횟수동안 ORP 값이 저장될 변수
int orp_index = 0;                //현재 읽혀진 횟수 /  전체횟수 초과시 다시 0
boolean orp_disp = false;

unsigned long readsensor_lasttime = 0;   
unsigned int readsensor_time = 1; //3초마다 센서 읽어들임


//문자열로 인해서 SRAM 가용 용량이 줄어드는 것을 막기 위해 문자열을 플래시메모리에 올려서 사용하도록 함
char p_buffer[80];
#define P(str) (strcpy_P(p_buffer, PSTR(str)), p_buffer)



//통신용 변수
char cTemp; //한바이트 데이터를 임시 저장
String sCommand = ""; //완성된 명령어
String sTemp = "";
boolean stringComplete = false; 


// 릴레이 1~8 번까지의 출력상태를 결정하는 변수. True 면 켜짐  False 이면 꺼짐
boolean REL1SW = false;  //조명
boolean REL2SW = false; //Co2
boolean REL3SW = false;  //쿨러
boolean REL4SW = false; //히터
boolean REL5SW = false;
boolean REL6SW = false;
boolean REL7SW = false;
boolean REL8SW = false;

/* 히터,쿨러,조명 값 지정 */
int SET_COOLER = 0;   // 쿨러 설정온도 ex:275 일경우 27.5도
int SET_HEATER = 0;   // 히터 설정온도 ex:230 일경우 23.0도  
int SET_PH_STOP = 0;    // CO2 중단 PH  ex:398 일경우 3.98 PH 값 
int SET_TEMP_ADJ = 0;   // 온도 보정온도 ex:32 일경우 3.2도 더함  / 27 일경우 센서온도 + 2.7도 / -25 일경우  센서온도 - 2.5도 로 보정

// 아래의 값들은 모두 2byte 를 사용하는 integer 값들에 대한 주소 값이므로 다른 eeprom 값과 중첩되지 않게 주의 !!
#define SET_COOLER_EEPROM_ADDR 10  // 쿨러설정값  저장되는 EEPROM 주소 ( integer 값이므로 0,1 번지에 저장 )
#define SET_HEATER_EEPROM_ADDR 12  // 히터설정값  저장되는 EEPROM 주소 ( integer 값이므로 2,3 번지에 저장 )
#define SET_PH_STOP_EEPROM_ADDR 14  // CO2공급중단값  저장되는 EEPROM 주소 ( integer 값이므로 4,5 번지에 저장 )
#define SET_TEMP_ADJ_EEPROM_ADDR 16  //온도 보전값 저장되는 EEPROM 주소 ( integer 값이므로 6,7 번지에 저장 )

int ORPOFFSET = 11;						// ORP 보정값 설정 검출값 - 보정값 = 출력값 (예로 검출값이 -211 mv 이고 보전값이 11이면 -222mb 가 됨 

//어항현재 상태 저장용 변수
String temp, ph, orp;

///////////////////////////////////////////////
// 기타 함수들...
///////////////////////////////////////////////

double avergearray(int* arr, int number){
  int i;
  int max,min;
  double avg;
  long amount=0;
  if(number<=0){
    return 0;
  }
  if(number<5){   //5개 미만의 값에 대한 평균 
    for(i=0;i<number;i++){
      amount+=arr[i];
    }
    avg = amount/number;
    return avg;
  }else{
    if(arr[0]<arr[1]){
      min = arr[0];max=arr[1];
    }
    else{
      min=arr[1];max=arr[0];
    }
    for(i=2;i<number;i++){
      if(arr[i]<min){
        amount+=min;        //arr<min
        min=arr[i];
      }else {
        if(arr[i]>max){
          amount+=max;    //arr>max
          max=arr[i];
        }else{
          amount+=arr[i]; //min<=arr<=max
        }
      }//if
    }//for
    avg = (double)amount/(number-2);
  }//if
  return avg;
}


//지정된 주소와 주소 + 1 의  EEPROM에 2 바이트 정수를 기록함
void EEPROMWriteInt(int p_address, int p_value) {
  byte lowByte = ((p_value >> 0) & 0xFF);
  byte highByte = ((p_value >> 8) & 0xFF);

  EEPROM.write(p_address, lowByte);
  EEPROM.write(p_address + 1, highByte);
}

//지정된 주소와 주소 + 1 의  EEPROM에서 2 바이트 정수를 읽어냄
int EEPROMReadInt(int p_address) {
  byte lowByte = EEPROM.read(p_address);
  byte highByte = EEPROM.read(p_address + 1);

  return ((lowByte << 0) & 0xFF) + ((highByte << 8) & 0xFF00);
}

//온도 보정값을 EEPROM으로 저장
void save_temp_calibration(int p_value) {
  EEPROMWriteInt(0, p_value);
}

//Atmega328 리셋 시킴 
void softReset() {
  asm volatile("jmp 0");
}

String getValue(String data, char separator, int index)
{
int found = 0;
  int strIndex[] = { 0, -1 };
  int maxIndex = data.length()-1;
  for(int i=0; i<=maxIndex && found<=index; i++){
  if(data.charAt(i)==separator || i==maxIndex){
  found++;
  strIndex[0] = strIndex[1]+1;
  strIndex[1] = (i == maxIndex) ? i+1 : i;
  }
}
  return found>index ? data.substring(strIndex[0], strIndex[1]) : "";
}

//char * floatToString(char * outstr, float value, int places, int minwidth=, bool rightjustify) {
char * floatToString(char * outstr, float value, int places, int minwidth=0, bool rightjustify=false) {
     // this is used to write a float value to string, outstr.  oustr is also the return value.
     int digit;
     float tens = 0.1;
     int tenscount = 0;
     int i;
     float tempfloat = value;
     int c = 0;
     int charcount = 1;
     int extra = 0;
     // make sure we round properly. this could use pow from <math.h>, but doesn't seem worth the import
     // if this rounding step isn't here, the value  54.321 prints as 54.3209

     // calculate rounding term d:   0.5/pow(10,places)  
     float d = 0.5;
     if (value < 0)
         d *= -1.0;
     // divide by ten for each decimal place
     for (i = 0; i < places; i++)
         d/= 10.0;    
     // this small addition, combined with truncation will round our values properly 
     tempfloat +=  d;

     // first get value tens to be the large power of ten less than value    
     if (value < 0)
         tempfloat *= -1.0;
     while ((tens * 10.0) <= tempfloat) {
         tens *= 10.0;
         tenscount += 1;
     }

     if (tenscount > 0)
         charcount += tenscount;
     else
         charcount += 1;

     if (value < 0)
         charcount += 1;
     charcount += 1 + places;

     minwidth += 1; // both count the null final character
     if (minwidth > charcount){        
         extra = minwidth - charcount;
         charcount = minwidth;
     }

     if (extra > 0 and rightjustify) {
         for (int i = 0; i< extra; i++) {
             outstr[c++] = ' ';
         }
     }

     // write out the negative if needed
     if (value < 0)
         outstr[c++] = '-';

     if (tenscount == 0) 
         outstr[c++] = '0';

     for (i=0; i< tenscount; i++) {
         digit = (int) (tempfloat/tens);
         itoa(digit, &outstr[c++], 10);
         tempfloat = tempfloat - ((float)digit * tens);
         tens /= 10.0;
     }

     // if no places after decimal, stop now and return

     // otherwise, write the point and continue on
     if (places > 0)
     outstr[c++] = '.';


     // now write out each decimal place by shifting digits one by one into the ones place and writing the truncated value
     for (i = 0; i < places; i++) {
         tempfloat *= 10.0; 
         digit = (int) tempfloat;
         itoa(digit, &outstr[c++], 10);
         // once written, subtract off that digit
         tempfloat = tempfloat - (float) digit; 
     }
     if (extra > 0 and not rightjustify) {
         for (int i = 0; i< extra; i++) {
             outstr[c++] = ' ';
         }
     }


     outstr[c++] = '\0';
     return outstr;
}

///////////////////////////////////////////////
// 아날로그 센서의 입력값을 처리하는 함수들
///////////////////////////////////////////////
float getVolt() {
  float volt;
  volt = float((analogRead(VOLT_PIN)*5.0)/1024.0);
  delay(20);
 return volt;
}

// 온도센서의 값을 읽어옴
float getTEMPValue(unsigned int pin) {
  float temp;
  unsigned int i;

  temp_readvals[temp_index++]=analogRead(pin);
	delay(20);
  if (temp_index==smoothing) {
    temp_index=0;
  }   
 
  temp = (avergearray(temp_readvals, smoothing)* 125) / 128;
  temp = temp / 10;
  return temp; 
}

// PH 프로브의 값을 읽어옴
float getPHValue1(unsigned int pin) {
  float ph;
  unsigned int i;	
  
	ph_readvals[ph_index++]=analogRead(pin);
	delay(20);
  if (ph_index==smoothing) {
    ph_index=0;
  }   
	ph = (avergearray(ph_readvals, smoothing)*ARDUINO_VOLTAGE/1024)*3.5;

  return ph;
}

// ORP 프로브의 값을 읽어옴
double getORPValue(unsigned int pin) {
  double millivolts;
  unsigned int i;

	orp_readvals[orp_index++]=analogRead(pin);
	delay(20);
  if (orp_index==smoothing) {
    orp_index=0;
  }   
  millivolts=((30*(double)ARDUINO_VOLTAGE*1000)-(75*avergearray(orp_readvals, smoothing)*ARDUINO_VOLTAGE*1000/1024))/75-ORPOFFSET;   //convert the analog value to orp according the circuit
  
  return millivolts; 
}





///////////////////////////////////
// 센서와 릴레이등의 상태값을 처리 
///////////////////////////////////
 void readsensor() {
	float _ph;
	int _temp;
	double _orp;
	int i;
	unsigned long sum;
  char st[20];

	//온도 검출을처리 
	_temp = getTEMPValue(TEMP_PIN) * 100;
	_temp = _temp + (SET_TEMP_ADJ*10);
  if((_temp/10) > SET_COOLER) { REL3SW = true; }
  if((_temp/10) <= (SET_COOLER-5)) { REL3SW = false; }
  if((_temp/10) < SET_HEATER) { REL4SW = true; }
  if((_temp/10) >= (SET_HEATER+5)) { REL4SW = false; }  
	temp = "";
  temp = String(_temp / 100 , DEC)  + String('.') + String((_temp % 100) / 10 , DEC);
  // EX : temp = "24.3"
  // Serial.println(temp);

  //PH 검출
  _ph = getPHValue1(PH_PIN); 
  ph = "";
  if(((SET_PH_STOP/100) >= _ph ) && ( SET_PH_STOP > 300)) { REL2SW = false; }  
  ph = floatToString(st, _ph, 2, 5) ; //String(_ph);
  // EX : ph = "10.22"
  // Serial.println(ph);

  //ORP 검출
  _orp = getORPValue(ORP_PIN); 
  orp = "";        
  orp = String((int)_orp);
 	// EX : _orp = "1203" or _orp = "-1203"
  // Serial.println((int)_orp);


}  // end of readsensor()

void writeRelay() {
 int relBits = 0;
 if (REL1SW) { 	bitWrite(relBits , 0, HIGH); }
 else { bitWrite(relBits , 0, LOW);}
 if (REL2SW) { 	bitWrite(relBits , 1, HIGH); }
 else { bitWrite(relBits , 1, LOW);}
 if (REL3SW) { 	bitWrite(relBits , 2, HIGH); }
 else { bitWrite(relBits , 2, LOW);}
 if (REL4SW) { 	bitWrite(relBits , 3, HIGH); }
 else { bitWrite(relBits , 3, LOW);}
 if (REL5SW) { 	bitWrite(relBits , 4, HIGH); }
 else { bitWrite(relBits , 4, LOW);}
 if (REL6SW) { 	bitWrite(relBits , 5, HIGH); }
 else { bitWrite(relBits , 5, LOW);}
 if (REL7SW) { 	bitWrite(relBits , 6, HIGH); }
 else { bitWrite(relBits , 6, LOW);}
 if (REL8SW) { 	bitWrite(relBits , 7, HIGH); }
 else { bitWrite(relBits , 7, LOW);} 	 	 	 	 	 	

 Wire.beginTransmission(IO_ADDR);
 Wire.write(relBits);
 Wire.endTransmission();
 delay(100); 
}

///////////////////////////////////////////////
// 컨트롤러 부팅시 초기 작업
///////////////////////////////////////////////


void setup() {
	
  SET_TEMP_ADJ = EEPROMReadInt(SET_TEMP_ADJ_EEPROM_ADDR);  //EEPROM에 저장된 온도 보정 읽어옴
  SET_COOLER = EEPROMReadInt(SET_COOLER_EEPROM_ADDR);    //EEPROM에 저장된  쿨러 설정온도  읽어옴  
  SET_HEATER = EEPROMReadInt(SET_HEATER_EEPROM_ADDR);    //EEPROM에 저장된 히터 설정온도  읽어옴
  SET_PH_STOP = EEPROMReadInt(SET_PH_STOP_EEPROM_ADDR);   //EEPROM에 저장된  CO2 중단 PH 읽어옴

  	
  Serial.begin(9600);
  sCommand.reserve(200);
  Wire.begin();
  delay(70);
  /*
  //FAN Pin Setup
  pinMode(FAN_PIN, OUTPUT);  
  //Relay Module Pin Setup
  pinMode(REL1, OUTPUT);       
  pinMode(REL2, OUTPUT);   
  pinMode(REL3, OUTPUT);   
  pinMode(REL4, OUTPUT);  
  */
}


///////////////////////////////////////////////
// MAIN LOOP
///////////////////////////////////////////////
void loop() {
  
  String cmdMode,cmdSub;
  String RES1,RES2,RES3,RES4,RES5,RES6,RES7,RES8;
  String _text = "";
  String _sw;  
  int valint = 0;
  
  //디버그용 변수
  char st[20];
  String _vol, _temp_adc, _temp;
  int _adc;
  
  readsensor();

  if (stringComplete) {
		cmdMode = getValue(sCommand, '|', 0);
		if (cmdMode == "201") {
			cmdSub =  getValue(sCommand, '|', 1);
		
			//센서및 포트상태 요청
			if (cmdSub == "221") {
				if (REL1SW == true) { RES1 = "1"; } else { RES1 = "0"; }
				if (REL2SW == true) { RES2 = "1"; } else { RES2 = "0"; }
				if (REL3SW == true) { RES3 = "1"; } else { RES3 = "0"; }
				if (REL4SW == true) { RES4 = "1"; } else { RES4 = "0"; }
				if (REL5SW == true) { RES5 = "1"; } else { RES5 = "0"; }
				if (REL6SW == true) { RES6 = "1"; } else { RES6 = "0"; }
				if (REL7SW == true) { RES7 = "1"; } else { RES7 = "0"; }
				if (REL8SW == true) { RES8 = "1"; } else { RES8 = "0"; }
        Serial.print("101|");
        Serial.print(temp);
        Serial.print("|");
        Serial.print(ph);
        Serial.print("|");
        Serial.print(orp);
        Serial.print("|");                                
        Serial.print(RES1);  //조명
        Serial.print("|");
        Serial.print(RES2);  //CO2
        Serial.print("|");
        Serial.print(RES3);  //쿨러
        Serial.print("|");
        Serial.print(RES4);  //히터
        Serial.print("|");
        Serial.print(RES5);
        Serial.print("|");                                
        Serial.print(RES6);
        Serial.print("|");
        Serial.print(RES7);
        Serial.print("|");
        Serial.print(RES8);
        Serial.println("| ");                                
			} // end if (cmdMode = "221")	
			
			//디버깅용 상태값
			else if (cmdSub == "255") {
				_vol = floatToString(st,getVolt(), 2, 4); 
				_adc = analogRead(TEMP_PIN);
				_temp_adc = String(_adc,DEC);
				_temp = String(map(_adc,0,1023,0,1000));
				delay(20);
				Serial.print("155|");
				Serial.print(_vol);
				Serial.print("|");
				Serial.print(_temp_adc);
				Serial.print("|");
        Serial.print(_temp);
        Serial.println("| "); 				
			}
			//온도,PH 설정
			//ser.writelines("201|222|"+set_temp_cali+"|"+set_max_temp+"|"+set_min_temp+"|"+set_min_ph+"|999| \n")
			else if ((cmdSub == "222") && (getValue(sCommand, '|', 6) == "999")) {
				//온도보정값 설정
				_text =  getValue(sCommand, '|', 2);
				valint = _text.toInt();
	      if(valint != SET_TEMP_ADJ) {
	        EEPROMWriteInt(SET_TEMP_ADJ_EEPROM_ADDR,valint);
	        SET_TEMP_ADJ = valint; 
	       }
	      //최대온도 설정 
				_text = getValue(sCommand, '|', 3);
				valint = _text.toInt();
	      if(valint != SET_COOLER) {
	        EEPROMWriteInt(SET_COOLER_EEPROM_ADDR,valint);
	        SET_COOLER = valint;
	      }
	      //최저온도 설정 
	      _text =  getValue(sCommand, '|', 4);
	      valint = _text.toInt();
	      if(valint != SET_HEATER) {
	        EEPROMWriteInt(SET_HEATER_EEPROM_ADDR,valint);
	        SET_HEATER = valint;
	      }
	      //최저PH 설정 
	      _text =  getValue(sCommand, '|', 5);
	      valint = _text.toInt();
	      if(valint != SET_PH_STOP) {
	        EEPROMWriteInt(SET_PH_STOP_EEPROM_ADDR,valint);
	        SET_PH_STOP = valint;
	      }
		  } // end if (cmdMode = "222")
		  
		  //온도 최저 ph 값 보냄	
			else if (cmdSub == "223") {
        Serial.print("102|");
        Serial.print(SET_TEMP_ADJ);
        Serial.print("|");
        Serial.print(SET_COOLER);
        Serial.print("|");
        Serial.print(SET_HEATER);
        Serial.print("|");                                
        Serial.print(SET_PH_STOP);
        Serial.println("| "); 
			}
			
			else if (cmdSub == "224") {
				_sw = getValue(sCommand, '|', 2);
        if ( _sw == "1") {
            REL1SW = true;
      	}
      	else {
            REL1SW = false;
        }
        _sw = getValue(sCommand, '|', 3);
        if (_sw == "1") {
            REL2SW = true;
      	}
      	else {
            REL2SW = false;
        }
			}
		}	// end if (cmdMode = "201")

		sCommand = "";
    stringComplete = false;
  }
  
 	writeRelay();
}


/*
 시리얼 포트로 새로운 데이터가 들올때  실행됨 
 데이터의 다중 바이트 사용할 수 있다.
*/
void serialEvent() {
   while (Serial.available()) {
     // 새로운 Byte 를 읽어옴
     char inChar = (char)Serial.read(); 
     // String 에 추가 
     sCommand += inChar;
     // 줄바꿈이면 문자열 끝 
     if (inChar == '\n') {
       stringComplete = true;
     } 
   }
}


