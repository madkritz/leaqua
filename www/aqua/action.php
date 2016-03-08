<?php
//$loggedIn = (isset($_COOKIE['loggedins']) && $_COOKIE['loggedins'] == 'true')?true:false;

@extract($HTTP_GET_VARS);
@extract($HTTP_POST_VARS);
@extract($HTTP_SERVER_VARS);
@extract($HTTP_ENV_VARS);
@extract($_POST);
@extract($_GET);

require_once 'access.class.php';
$user = new flexibleAccess();

$loggedIn = ($user->is_loaded())?true:false;

if (!$loggedIn) { exit; }

/*
$lights = $_POST['light'];
$mode = $_POST['mode'];
$setval =$_POST['setval'];
$switch_light_act = $_POST['switch_light_act'];
$set_temp_call_act = $_POST['set_temp_call_act'];
*/
//echo "<script> alert('$lights'); </script>";


// CPU ���� ID�� ������
$handle = fopen("/proc/cpuinfo", "r");
$contents = fread($handle, 1024);
fclose($handle);
$cpuSN = substr($contents,strpos($contents,"Serial"),100);
$cpuSN = trim(substr($cpuSN,strpos($cpuSN,":")+2,20));

if (($mode == "save_value") or ($mode == "set_light")) {
		$switch_light_vlaue = $switch_light;
		$set_temp_call_vlaue = $set_temp_call;
		$set_max_temp_value = $set_max_temp;
		$set_min_temp_value = $set_min_temp;
		$set_min_ph_value = $set_min_ph;
		$set_light_start_value = $set_light_startv;
		$set_light_end_value = $set_light_endv;
		$set_co2_start_value = $set_co2_startv;
		$set_co2_end_value = $set_co2_endv;
		
    if($switch_light == "") { $switch_light = "0";}

		$fn = "/var/ramdisk/set_".$cpuSN.".xml";
	
		if(is_file($fn)) {
			@unlink($fn);
		}
		if($file=fopen($fn,"w+")){ 

		fputs($file,"<?xml version=\"1.0\"?>\r\n"); 
		fputs($file,"<note>\r\n");
		fputs($file,"    <light>$switch_light</light>\r\n");	//���� on/off	
		fputs($file,"    <temp_calibration>$set_temp_call</temp_calibration>\r\n"); //�µ�����
		fputs($file,"    <temp_max>$set_max_temp</temp_max>\r\n"); //�ִ�µ�
		fputs($file,"    <temp_min>$set_min_temp</temp_min>\r\n"); //�����µ�	
		fputs($file,"    <ph_min>$set_min_ph</ph_min>\r\n"); //����PH
		fputs($file,"    <light_starttime>$set_light_startv</light_starttime>\r\n"); //������۽ð�
		fputs($file,"    <light_endtime>$set_light_endv</light_endtime>\r\n"); //��������ð�
		fputs($file,"    <co2_starttime>$set_co2_startv</co2_starttime>\r\n"); //co2���۽ð�	
		fputs($file,"    <co2_endtime>$set_co2_endv</co2_endtime>\r\n"); //co2����ð�
		fputs($file,"    <time>$datetime</time>\r\n");
		fputs($file,"    <mode>$mode</mode>\r\n");		
		fputs($file,"</note>\r\n");
		
		fclose($file); 
		chmod($fn,0777);
    echo "ok";
	}
			
}
else if ($mode == "get_value") {

}

//���� on/off		�µ�����		�ִ�µ�		�����µ�		����PH		������۽ð�		��������ð�		co2���۽ð�		co2����ð�		������ȣ��
//

echo "ok";

?>
