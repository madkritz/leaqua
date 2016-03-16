<?php

$mode = $_POST['mode'];

include '../wp-load.php';

$wp_cookie = $_COOKIE['wordpress_logged_in_'.md5(get_site_option('siteurl'))];
$wp_user = $_POST['log'];
$wp_pass = $_POST['pwd'];

if($wp_user&&$wp_pass)    {
	if(user_pass_ok($wp_user, $wp_pass)){
		$user = get_user_by('login', $wp_user);
		wp_set_auth_cookie($user->ID);
	}
}else{
	if($wp_cookie)
	{
		wp_set_current_user(wp_validate_auth_cookie($wp_cookie, 'logged_in'));
		$user = wp_get_current_user();
	}
}

if($user->display_name) {
	$loginid = $user->display_name;
}


if($loginid) {
	setcookie('loggedins', 'true', time()+31536000, '/');
	header('Location: index.html');
} else {
		echo '<script type="text/javascript" charset="utf-8">';
		echo '	alert("로그인에 실패했습니다");';
		echo '  window.history.back();'; 
		echo ' </script>';
}


?>