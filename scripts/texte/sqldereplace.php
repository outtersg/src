<?php
/* Vire les replace() dans les versions modernes de sqlite3 .dump. */

$c1 = stream_get_contents(STDIN);
$c0 = '';

$expr = "/replace\('([^']*(?:''[^']*)*)', *'([^']*)', *(?:'([^']*(?:''[^']*)*)'|char\(([0-9]+)\))\)/s";
function fRempl($args)
{
	list($tout, $chaîne, $de, $versChaîne, $versCar) = $args;
	$chaînes = array(& $chaîne, & $versChaîne);
	foreach($chaînes as & $ptrTruc)
		$ptrTruc = strtr($ptrTruc, array("''" => "'"));
	$vers = !empty($versCar) ? chr(0 + $versCar) : $versChaîne;
	return "'".strtr(strtr($chaîne, array($de => $vers)), array("'" => "''"))."'";
}

while(($c0 = $c1) && strlen($c0) > strlen($c1 = preg_replace_callback($expr, 'fRempl', $c0))) {}

echo $c0;

?>
