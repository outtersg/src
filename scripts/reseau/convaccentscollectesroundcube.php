<?php
/* Les collected_contacts de Roundcube, pour certains, sont stockés en UTF-8 (alors qu'on doit avoir du CP1252). On convertit ceux que l'on arrive à convertir. */

error_reporting(-1);
ini_set('display_errors', 1);

mysql_connect('localhost', 'rc_gclo_fr', 'XXXXXXXXXXXXXXXXXXXXXXXXXX');
mysql_select_db('rc_gclo_fr');

$r = mysql_query('select * from collected_contacts');
while(($l = mysql_fetch_assoc($r)))
{
	$n2 = @iconv('UTF-8', 'cp1252', $l['name']);
	$n3 = @iconv('cp1252', 'UTF-8', $n2);
	if($n3 === $l['name'] && $n2 != $n3)
	{
		echo $l['name'];
		$n2 = mysql_escape_string($n2);
		$v2 = mysql_escape_string(iconv('UTF-8', 'cp1252', $l['vcard']));
		$w2 = mysql_escape_string(iconv('UTF-8', 'cp1252', $l['words']));
		// Euh, il me fait des erreurs de conversion sur les words.
		mysql_query("update collected_contacts set name = '$n2', vcard = '$v2', words = '$w2' where contact_id = ".$l['contact_id']);
	}
}

?>
