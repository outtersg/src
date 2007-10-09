<?php

if(($s = socket_create(AF_INET, SOCK_STREAM, SOL_TCP)))
	echo serialize(socket_connect($s, "www.apple.com", 80))."\n";
else
	echo "Non ".socket_last_error()."\n";

if(($s = socket_create(AF_INET, SOCK_DGRAM, SOL_UDP)))
{
	$paquet = join('', array_map(create_function('$x', 'return chr(hexdec($x));'), explode(':', '00:11:24:38:b3:86')));
	for($i = 4; --$i >= 0;)
		$paquet .= $paquet;
	echo serialize(socket_sendto($s, $paquet, strlen($paquet), 0, "82.240.30.31", 9))."\n";
}
else
	echo "Non ".socket_last_error()."\n";
socket_close($s);

?>
