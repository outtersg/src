<?php

require_once('/Users/gui/src/util/php/navigateur.inc');

$nav = new Navigateur();

$page = $nav->aller('http://subscribe.free.fr/login/login.pl', array('login' => $_GET['i'], 'pass' => $_GET['m']));

if('version2')
{
	preg_match('/<a href="([^"]*)"[^>]*title="Gestion de mes services de t[^"]*phonie/', $page, $réponses, 0);
	if(count($réponses[0]) > 0)
		$page = $nav->aller($réponses[1]);
	/* Et ensuite comme en version 1. */
}
preg_match('/<a href="([^"]*)">[^<]*messagerie vocale/', $page, $réponses, 0);
header('Location: '.(count($réponses[0]) > 0 ? $nav->url($réponses[1]) : 'http://subscribe.free.fr/login/login.pl'));

?>
