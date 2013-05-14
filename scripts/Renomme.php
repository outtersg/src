<?php

array_shift($argv);
foreach($argv as $arg)
{
	if($arg == '-n')
		$nePasFaire = true;
	else
		$source = $arg;
}

$liste = file($source);
$liste = array_map('rtrim', $liste);

$nouveau = array_shift($liste);
$nouveau = strtr($nouveau, '/', ':');

$insert = ' xxx';
$regexInsert = strtr($insert, array('xxx' => '(?P<numero>[0-9]+)'));

$regexSuffixe = '(?P<suffixe>([.][a-zA-Z0-9]+)*)';

$dossiers = array();
foreach($liste as $fichier)
	$dossiers[dirname($fichier)] = true;

// Utilitaires de transfo des regex.

function encfs($chaine)
{
	return PHP_OS == 'Darwin' ? iconv('UTF-8', 'UTF-8-MAC', $chaine) : $chaine;
}

function globule($chaine)
{
	return strtr($chaine, array('*' => '\\*'));
}

function globubulle($regex)
{
	$glob = preg_replace
	(
		array
		(
			'#\((([^()]*\((?1)\))*[^()]*)\)\*#',
			'#\[[^]]*\]\*#',
			'#\((\?P<[^>]+>)?(([^()]*\((?1)\))*[^()]*)\)#',
			'#[()]#',
			'#\+#',
		),
		array
		(
			'*',
			'*',
			'\\2',
			'',
			'*',
		),
		$regex
	);
	return preg_replace('#\*+#', '*', $glob);
}

//echo globubulle('expr(ession)(répétition de (ça) puis (ça aussi)*)* avec [0-9]+ chiffres et optionnellement [a-z]*(suffixe)')."\n";
//exit;

function regexChaine($chaine)
{
	return preg_replace('#[][().]#', '\\\\\0', $chaine);
}

// Recherche des fichiers déjà existants avec ce nom dans les dossiers destination: on partira de là.

$globuleFichier = globule($nouveau).globubulle($regexInsert.$regexSuffixe);
$regexFichier = encfs(regexChaine($nouveau).$regexInsert.$regexSuffixe);
//echo $globuleFichier."\n";
//echo $regexFichier."\n";exit;
$max = 0;
foreach($dossiers as $dossier => $rien)
{
	foreach(glob(encfs($dossier.'/'.$globuleFichier)) as $existant)
		if(preg_match('#^'.$regexFichier.'$#', basename($existant), $corr))
			if($corr['numero'] > $max)
				$max = $corr['numero'];
}

// Renommage.

foreach($liste as $fichier)
{
	preg_match('#'.$regexSuffixe.'$#', $fichier, $corr);
	$dest = $nouveau.strtr($insert, array('xxx' => ++$max)).$corr['suffixe'];
	$dest = dirname($fichier).'/'.$dest;
	echo "mv $fichier $dest\n";
	if(!isset($nePasFaire))
		rename($fichier, $dest);
}

?>
