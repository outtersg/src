<?php

require_once dirname(__FILE__).'/baikaldav.php';

function analyserParametres($argv)
{
	$r = array
	(
		'serveur' => null,
		'compte' => null,
		'mot de passe' => null,
	);
	for($i = 0; ++$i < count($argv);)
		switch($argv[$i])
		{
			default:
				foreach($r as & $ptrParam)
					if(!isset($ptrParam))
					{
						$ptrParam = $argv[$i];
						break 2;
					}
				$r['fiches'][] = preg_replace('#\.vcf$#', '', $argv[$i]);
				break;
		}
	foreach($r as $clé => $param)
		if(!isset($param))
			auSecours($clé);
	if(empty($r['fiches']))
		auSecours('fiche');
	
	return $r;
}

$params = analyserParametres($argv);

$serveur = new BaïkalDav($params['serveur'], $params['compte'], $params['mot de passe']);

$fiches = array();
$chemins = array();
foreach($params['fiches'] as $id)
{
	$cheminPonte = '/tmp/'.$id.'.vcf';
	$f = $serveur->fiche($id);
	$fiches[] = $f;
	$chemins[] = $cheminPonte;
	file_put_contents($cheminPonte, $f);
}

passthru((getenv('EDITOR') ? getenv('EDITOR') : 'vi').' '.implode(' ', $chemins).' < /dev/tty > /dev/tty 2> /dev/tty');

foreach($fiches as $num => $f)
	if(($contenu = file_get_contents($chemins[$num])) && $contenu != $f->contenu)
	{
		$f->contenu = $contenu;
		$serveur->fiche($f->uri, 'PUT', $f);
	}

// php /tmp/tmp/src/scripts/adresses/modifiche.php https://sync.gclo.fr:443/card.php/addressbooks/ clo@gclo.fr "$mdp" <xxxxx>.vcf

?>
