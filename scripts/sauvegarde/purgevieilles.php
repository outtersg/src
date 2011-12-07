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

$fichiers = "/Users/gui/Downloads/Mail.*.tar.gz";

$faire = true;
array_shift($argv);
while(($arg = array_shift($argv)) !== null)
{
	switch($arg)
	{
		case '-n':
			$faire = false;
			break;
		default:
			$fichiers = $arg;
			break;
	}
}

function extraireDate($fichier)
{
	sscanf(basename($fichier), 'Mail.%d-%d:%d.tar.gz', $j, $h, $m);
	if(($t = mktime($h, $m, 0, date('m'), $j, date('Y'))) >= time())
		$t = mktime($h, $m, 0, date('m') - 1, $j, date('Y'));
	return $t;
}

$t = array();
foreach(glob($fichiers) as $fichier)
	$t[extraireDate($fichier)] = $fichier;
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
	else
		unlink($fichier);
}

?>
