<?php

$t = getdate();
$t = array($t['year'], $t['mon'], $t['mday'], $t['hours'], $t['minutes'], $t['seconds']);

// Alternance: jour de commencement, secondes entre deux sauvegardes
$periodes = array
(
	60, 2 * 24 * 3600,
	10, 12 * 3600,
	3, 3600,
	1, 1,
);

$fichiers = "/Users/gui/Downloads/Mail.%d-%d:%d.tar.gz";

$faire = true;
$suffixe = null;
array_shift($argv);
while(($arg = array_shift($argv)) !== null)
{
	switch($arg)
	{
		case '--suffixer':
			$suffixe = array_shift($argv);
			break;
		case '-p':
			$arg = array_shift($argv);
			$arg = strtr($arg, ',;', '::');
			$periodes = explode(':', $arg);
			break;
		case '-n':
			$faire = false;
			break;
		default:
			$fichiers = $arg;
			break;
	}
}

$fichiers = strtr($fichiers, '@', '%');

if(!($GLOBALS['aLaMinute'] = strpos($fichiers, ':') !== false))
	for($i = count($periodes) + 1; ($i -= 2) > 0;)
		$periodes[$i] *= 24 * 3600;

function extraireDate($fichier, $schemaNomFichiers)
{
	if($GLOBALS['aLaMinute'])
	{
		sscanf(basename($fichier), basename($schemaNomFichiers), $j, $h, $m);
		if(($t = mktime($h, $m, 0, date('m'), $j, date('Y'))) >= time())
			$t = mktime($h, $m, 0, date('m') - 1, $j, date('Y'));
	}
	else
	{
		sscanf(basename($fichier), basename($schemaNomFichiers), $a, $m, $j);
		$t = mktime(0, 0, 0, $m, $j, $a);
	}
	return $t;
}

$t = array();
$fichiersGlob = preg_replace('/%[a-z]|\([^)]*\)/', '*', $fichiers);
$expr = '#^'.preg_replace('#%[a-z]#', '[0-9]+', $fichiers).'$#';
foreach(glob($fichiersGlob) as $fichier)
	if(preg_match($expr, $fichier))
	$t[extraireDate($fichier, $fichiers)] = $fichier;
ksort($t);

$frequence = null;
$dGarde = null;
$garde = null;
foreach($t as $d => $fichier)
{
	while(count($periodes) && $d >= time() - $periodes[0] * 24 * 3600) // Changement de zone.
	{
		$frequence = $periodes[1];
		array_shift($periodes);
		array_shift($periodes);
	}
	
	if(isset($frequence))
		if($d >= $dGarde + $frequence) // Si le nouveau est un bon candidat pour remplacer l'ancien.
		{
			$dGarde = $d;
			$garde = $fichier;
			if(!$faire)
				echo '+ '.$fichier."\n";
			continue;
		}
	
	if(!$faire)
		echo '- '.$fichier."\n";
	else if(isset($suffixe))
		rename($fichier, $fichier.'.'.$suffixe);
	else
		unlink($fichier);
}

?>
