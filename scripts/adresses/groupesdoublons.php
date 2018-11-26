<?php

require_once dirname(__FILE__).'/baikalbase.php';
require_once dirname(__FILE__).'/baikaldav.php';

// À FAIRE: faire tampon pour les modifs de groupes. Si on supprime par exemple 7 doublons d'un groupe, autant les supprimer en une fois plutôt qu'en 7 appels.
class Exécutant
{
	protected $serveur;
	protected $lier = true;
	protected $dédoublonner = true;
	
	public function __construct($serveur)
	{
		$this->serveur = $serveur;
	}
	
	public function grouper($p, $g)
	{
		echo "+++ ".$p->nom().' -> '.$g->nom()."\n";
		if($this->lier && $this->serveur)
		{
			$this->serveur->grouper($p, $g);
		}
	}
	
	public function dédoublonner($fiches)
	{
		echo 'Contenus identiques.'."\n";
		if($this->dédoublonner && $this->serveur)
		{
			// On choisit la fiche d'ID minimal (a priori la fiche historique) pour référence, on supprime les autres.
			$minId = null;
			foreach($fiches as $f)
				if(!isset($minId) || $minId > $f->id)
					$minId = $f->id;
			echo "On conserve $minId, on supprime ".(count($fiches) - 1)." fiches.\n";
			foreach($fiches as $f)
				if($f->id != $minId)
				{
					echo "- ".$f->uid()."\n";
					$this->serveur->supprimer($f);
				}
		}
	}
}

function analyserParametres($argv)
{
	$r = array();
	for($i = 0; ++$i < count($argv);)
		switch($argv[$i])
		{
			case '-s': $r['s'] = $argv[++$i]; break;
			case '-b': $r['b'] = $argv[++$i]; break;
			default:
				$r[isset($r['u']) ? 'mdp' : 'u'] = $argv[$i];
				break;
		}
	return $r;
}

$params = analyserParametres($argv);

$g_regrouper = true;

$p = new BaïkalBase($params['b'], $params['u']);
$serveur = null;
if(isset($params['s']) && isset($params['mdp']))
	$serveur = new BaïkalDav($params['s'], $params['u'], $params['mdp']);
$exécutant = new Exécutant($serveur);

$groupes = $p->groupes();

// On groupe par nom.

$groupées = array();
foreach($p->gens(true) as $gen)
	$groupées[$gen->nom()][] = $gen;

// Repérage des doublons.

foreach($groupées as $i => $groupée)
	if(count($groupée) == 1) // Pas un doublon.
		unset($groupées[$i]); // Donc on n'aura pas à le gérer.

// Analyse des différences.
// Deux choses peuvent différer:
// - le contenu
// - l'appartenance aux groupes.

function contenu($contenu)
{
	$contenu = preg_replace
	(
		array
		(
			//'/\n(CATEGORIES|PRODID|REV|UID):.*/', // If faudrait reprendre les CATEGORIES comme des groupes. En attendant de savoir faire, on les considère comme des infos à reprendre impérativement avant de pouvoir fusionner des fiches.
			'/\n(PRODID|REV|UID):.*/',
			'/[ \t\r\n]+\n/',
			'/\nPHOTO(;[^:]*)*:.*(\n .*)*/',
		),
		array
		(
			'',
			"\n",
			'PHOTO:<quelque chose>',
		),
		$contenu
	);
	return $contenu;
}

foreach($groupées as $i => $groupée)
	foreach($groupée as $fiche)
		$fiche->contenuFiltré = contenu($fiche->contenu);

foreach($groupées as $groupée)
{
	$contenus = array();
	$groupesFiche = array();
	foreach($groupée as $fiche)
	{
		$contenus[$fiche->contenuFiltré][] = $fiche->uri;
		$groupesFiche[implode(',', array_keys($fiche->groupes))][] = $fiche->uri;
	}
	echo '=== '.$fiche->nom().' ==='."\n";
	$diffèrent = false;
	if(count($contenus) > 1)
	{
		$diffèrent = true;
		echo 'Les contenus diffèrent:'."\n";
		foreach($contenus as $contenu => $clés)
		{
			echo '----------------'."\n";
			foreach($clés as $clé)
				echo $clé."\n";
			echo '----------------'."\n";
			echo trim($contenu)."\n";
		}
	}
	// À FAIRE: effectuer dans la même passe le lien et la suppression des doublons.
	// À FAIRE alors: ne pas lier aux groupes les fiches que l'on va supprimer. Seule la fiche qui sera conservée est à lier aux groupes des fiches que l'on va supprimer. S'assurer alors que tous les groupes ont été rapatriés avant de supprimer les doublons, car après on n'aura plus l'info des groupes supplémentaires.
	if(count($groupesFiche) > 1)
	{
		$diffèrent = true;
		echo 'Les groupes diffèrent:'."\n";
		foreach($groupesFiche as $groupeDeGroupes => $clés)
		{
			echo '----------------'."\n";
			foreach($clés as $clé)
				echo $clé."\n";
			echo '----------------'."\n";
			echo $groupeDeGroupes ? implode("\n", array_map(function($e) use($groupes) { return $groupes[$e]->nom(); }, explode(',', $groupeDeGroupes)))."\n" : "-\n";
		}
		if($g_regrouper && count($contenus) == 1)
		{
			$tous = array();
			foreach($groupesFiche as $groupeDeGroupes => $clés)
				if(strlen($groupeDeGroupes))
					foreach(explode(',', $groupeDeGroupes) as $idGroupe)
						$tous[$idGroupe] = true;
			echo "-> On ajoute les fiches aux ".count($tous)." groupes.\n";
			foreach($tous as $cléGroupe => $true)
				foreach($groupée as $fiche)
					if($groupes[$cléGroupe]->ajouter($fiche))
						$exécutant->grouper($fiche, $groupes[$cléGroupe]);
		}
	}
	if(!$diffèrent)
		$exécutant->dédoublonner($groupée);
}

// Poussage des regroupements.

foreach($groupes as $groupe)
{
	echo "------------- ".$groupe->nom()."\n";
	$groupe->pousser();
}

?>
