<?php

require_once dirname(__FILE__).'/baikalbase.php';
require_once dirname(__FILE__).'/baikaldav.php';

class Fiche
{
	public function __construct($entrée)
	{
		$this->contenu = $entrée['carddata'];
		$this->uri = $entrée['uri'];
	}
	
	public function uid()
	{
		return trim(preg_replace('/\.vcf$/', '', $this->uri));
	}
	
	public function nom()
	{
		if(preg_match('/^FN:(.*)$/m', $this->contenu, $r))
		{
			return trim($r[1]);
		}
	}
}

class Personne extends Fiche
{
	public function __construct($entrée)
	{
		parent::__construct($entrée);
		$this->groupes = array();
	}
	
	public function _notifGroupe($groupe)
	{
		$this->groupes[$groupe->uid()] = $groupe;
	}
}

class Groupe extends Fiche
{
	public function __construct($entrée)
	{
		parent::__construct($entrée);
	}
	
	public function ajouter(Personne $p)
	{
if(!isset($this->gens[$p->uid()]))
echo "+++ ".$p->nom().' -> '.$this->nom()."\n";
		$this->gens[$p->uid()] = $p;
		$p->_notifGroupe($this);
	}
	
	public function pousser()
	{
		$contenu2 = $this->contenu;
		preg_match_all('#\n(X-ADDRESSBOOKSERVER-KIND:|X-ADDRESSBOOKSERVER-MEMBER:).*\n#', $this->contenu, $r, PREG_OFFSET_CAPTURE);
		foreach ($r[0] as $bout) {}
		$posMembre = $bout[1] + strlen($bout[0]);
		foreach ($this->gens as $gen)
			if(strpos($this->contenu, "\nX-ADDRESSBOOKSERVER-MEMBER:urn:uuid:".$gen->uid()) !== false)
				continue;
			else
				$this->_ins($contenu2, $posMembre, 'X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:'.$gen->uid()."\r\n");
		
		if(0 != strcmp($contenu2, $this->contenu))
		{
			echo "POUSSAGE DE ".$this->nom()."\n";
			echo $this->contenu."\n";
			echo $contenu2."\n";
			exit;
			}
		// $this->contenu = $contenu2;
		print_r(array($this->contenu."\n".$contenu2));exit;
	}
	
	protected function _ins(& $ptrChaîne, & $ptrPos, $insert)
	{
		$ptrChaîne = substr($ptrChaîne, 0, $ptrPos).$insert.substr($ptrChaîne, $ptrPos);
		$ptrPos += strlen($insert);
	}
}

$g_regrouper = true;

$p = new BaïkalBase($argv[1], $argv[2]);

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
			'/\n(CATEGORIES|PRODID|REV|UID):.*/',
			'/[ \t\r\n]+\n/',
		),
		array
		(
			'',
			"\n",
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
					$groupes[$cléGroupe]->ajouter($fiche);
		}
	}
	if(!$diffèrent)
		echo 'Contenus identiques.'."\n";
}

// Poussage des regroupements.

foreach($groupes as $groupe)
{
	echo "------------- ".$groupe->nom()."\n";
	$groupe->pousser();
}

?>
