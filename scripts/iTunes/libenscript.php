<?php

require_once('xml/chargeur.php');
require_once('chemin.inc');

class PlistInterieure extends Compo
{
	var $suite;
	var $enCle;
	var $cle;
	
	function PlistInterieure(&$traiteurRacine)
	{
		$this->suite = new Chargeur();
		$this->suite->pile[] = &$traiteurRacine;
	}
	
	function entrer()
	{
		$this->enCle = 0;
		$this->suite->pile[0]->entrer();
	}
	
	function &entrerDans($depuis, $nom, $attributs)
	{
		if($nom == 'key')
		{
			$this->enCle = 1;
			$this->cle = null;
		}
		else
		{
			$this->suite->entrer(NULL, $this->cle, null);
			$this->cle = null;
		}
	}
	
	function contenuPour(&$objet, $contenu)
	{
		if($this->enCle)
			$this->cle = $this->cle === null ? $contenu : $this->cle.$contenu;
		else
			$this->suite->contenu(NULL, $contenu);
	}
	
	function sortirDe(&$objet)
	{
		if(!$this->enCle)
			$this->suite->sortir(null, null);
		$this->enCle = 0;
	}
	
	function sortir()
	{
		$this->suite->pile[0]->sortir();
	}
}

class Plist extends Compo
{
	var $interieur;
	
	function Plist(&$traiteurRacine)
	{
		$this->interieur = new PlistInterieure(&$traiteurRacine);
 	}
	
	function &entrerDans($depuis, $nom, $attributs)
	{
		/* À la racine on doit avoir un dict; c'est celui-ci que l'on passe
		 * comme véritable racine de la liste. */
		return $this->interieur;
	}
}

class Morceaux extends Compo
{
	var $niveau;
	var $champs; // 0: chemin; 1: note; 2: artiste; 3: titre
	var $modif;
	protected $sortie;
	
	function Morceaux($sortie)
	{
		$this->sortie = $sortie;
	}
	
	function entrer()
	{
		$this->niveau = 0;
		$this->champs = Array(null, null);
	}
	
	function &entrerDans($depuis, $nom, $attributs)
	{
		if(++$this->niveau == 2)
		{
			if($nom == 'Rating')
				$this->modif = 1;
			else if($nom == 'Location')
				$this->modif = 0;
			else if($nom == 'Name')
				$this->modif = 3;
			else if($nom == 'Artist')
				$this->modif = 2;
			else if($nom == 'Track ID')
				$this->modif = 4;
		}
		else if($this->niveau == 1)
		{
			for($i = 4; --$i >= 0;)
				$this->champs[$i] = null;
		}
	}
	
	function contenuPour(&$objet, $contenu)
	{
		if($this->modif >= 0)
			$this->champs[$this->modif] = $this->champs[$this->modif] === null ? $contenu : $this->champs[$this->modif].$contenu;
	}
	
	function sortirDe(&$objet)
	{
		if(--$this->niveau == 1)
			$this->modif = -1;
		else if($this->niveau == 0)
			$this->sortie->traiterMorceau($this->champs);
	}
}

class Listes extends Compo
{
	var $niveau;
	protected $sortie;
	protected $courant;
	
	function Listes($sortie)
	{
		$this->sortie = $sortie;
	}
	
	function entrer()
	{
		$this->niveau = 0;
		$this->courant = null;
	}
	
	function &entrerDans($depuis, $nom, $attributs)
	{
		switch(++$this->niveau)
		{
			case 1:
				$this->courant = null;
				break;
			case 4:
				if($nom == 'Track ID')
					$this->courant = '';
				break;
		}
	}
	
	function contenuPour(&$objet, $contenu)
	{
		if($this->courant !== null)
			$this->courant .= $contenu;
	}
	
	function sortirDe(&$objet)
	{
		if(--$this->niveau == 3)
		{
			$this->sortie->traiterMorceauListe($this->courant);
			$this->courant = null;
		}
	}
}

function chemin($champs, $pourScript = false)
{
	$chemin = preg_replace('=^file://localhost=', '', rawurldecode($champs[0]));
	return $chemin;
}

class SortieListeListe
{
	public $morceaux;
	
	function SortieListeListe()
	{
		$this->morceaux = Array();
	}
	
	function traiterMorceau($champs)
	{
		if($champs[4] !== null)
			$this->morceaux[$champs[4]] = Array($champs[2], $champs[3]);
echo chemin($champs)."\n";
	}
	
	function traiterMorceauListe($numero)
	{
		printf("%s - %s\n", $numero, "");
	}
}

class SortieNotation
{
	protected $prefixes = Array('o', 'oo', 'ooo', 'oooo', 'ooooo');
	
	function traiterMorceau($champs)
	{
		$note = floor($champs[1] / 20);
		$chemin = chemin($champs);
		$suffixe = ($pos = strrpos($chemin, '.')) === FALSE ? '' : substr($chemin, $pos);
		if($note > 5)
			$note = 5;
		if($note > 0)
			printf("%s\0%s\0", $chemin, $this->prefixes[$note - 1].'/'.str_replace('/', ':', $champs[2].' - '.$champs[3]).$suffixe);
	}
}

class Itml extends Compo
{
	var $niveau;
	var $morceaux;
	protected $listes;
	protected $sorties;
	
	function Itml($sortieMorceaux, $sortieListes)
	{
		$this->sorties = Array($sortieMorceaux, $sortieListes);
	}
	
	function entrer()
	{
		$this->niveau = 0;
		if($this->sorties[0] !== null) $this->morceaux = new Morceaux($this->sorties[0]);
		if($this->sorties[1] !== null) $this->listes = new Listes($this->sorties[1]);
	}
	
	function &entrerDans($depuis, $nom, $attributs)
	{
		if(++$this->niveau == 1 && $nom == "Tracks")
			return $this->morceaux;
		else if($this->niveau == 1 && $nom == "Playlists")
			return $this->listes;
	}
	
	function sortirDe(&$objet)
	{
		--$this->niveau;
	}
}

$mode = 0;
$fichier = null;
for($i = 1; $i < count($argv); ++$i)
	switch($argv[$i])
	{
		case '-l': $mode = 1; break;
		default: $fichier = $argv[$i]; break;
	}

$chargeur = new Chargeur();
$sortieMorceaux = $sortieListes = null;
switch($mode)
{
	case 0: $sortieMorceaux = new SortieNotation(); break;
	case 1: $sortieMorceaux = $sortieListes = new SortieListeListe(); break;
}
$plist = new Plist(new Itml($sortieMorceaux, $sortieListes));
$chargeur->charger(new Chemin($fichier), 'plist', &$plist, true);
print_r($sortieMorceaux->listes);
exit(0);

?>
