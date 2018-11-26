<?php

require_once dirname(__FILE__).'/baikalstruct.php';

class BaïkalBase
{
	public function __construct($cheminBdd, $qui)
	{
		$this->bdd = new PDO('sqlite://'.realpath($cheminBdd));
		$this->bdd->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
		$ids = $this->bdd->query("select id from addressbooks where principaluri = 'principals/$qui'")->fetchAll();
		if(count($ids) != 1)
			throw new Exception(count($ids)." résultat(s) pour l'agenda de $qui");
		$this->idCarnet = $ids[0]['id'];
		$this->avecCatégories = false;
	}
	
	public function err($truc)
	{
		fprintf(STDERR, "# \033[31m".$truc."\033[0m\n");
	}
	
	protected function _brancherGensAuxGroupes()
	{
		// On a besoin des gens et des groupes pour tirer le lien. Même pour les catégories, qui en théorie sont calculables à partir des seuls gens, mais qui, peuplant $this->groupes de groupes virtuels, pourraient laisser penser que $this->groupe est complet alors qu'on n'a pas récupéré les "vrais" groupes.
		if(!isset($this->groupes) || !isset($this->gens))
			return;
		
		foreach($this->groupes as $groupe)
		{
			preg_match_all('#\nX-ADDRESSBOOKSERVER-MEMBER:urn:uuid:([-a-zA-Z0-9]*)#', $groupe->contenu, $r);
			foreach($r[1] as $idp)
				if(isset($this->gens[$idp]))
					$groupe->ajouter($this->gens[$idp]);
				else
					$this->err('Le groupe '.$groupe->nom().' fait référence à la fiche inexistance '.$idp);
		}
		
		foreach($this->gens as $gen)
			if(preg_match('#\nCATEGORIES(?:;[^:]*)?:(.*(?:\r?\n .*)*)#', $gen->contenu, $r))
			{
				$catégories = explode(',', preg_replace('#\r?\n #', '', trim($r[1])));
				foreach($catégories as $catégorie)
				{
					isset($this->groupes['$'.$catégorie]) || $this->groupes['$'.$catégorie] = new Catégorie($catégorie);
					$this->groupes['$'.$catégorie]->ajouter($gen);
				}
			}
	}
	
	public function groupes()
	{
		if(isset($this->groupes)) return $this->groupes;
		
		$groupes = $this->bdd->query("select * from cards where addressbookid = ".$this->idCarnet." and carddata like '%X-ADDRESSBOOKSERVER-KIND:group%'")->fetchAll();
		$this->groupes = array();
		foreach($groupes as $groupe)
		{
			$g = new Groupe($groupe);
			$gid = $g->uid();
			if(isset($this->groupes[$gid]))
			{
				$this->err('Plusieurs entrées avec l\'uid '.$gid);
				continue;
			}
			$this->groupes[$gid] = $g;
		}
		
			$this->_brancherGensAuxGroupes();
		
		return $this->groupes;
	}
	
	public function gens($avecGroupes = false)
	{
		if(isset($this->gens)) return $this->gens;
		
		$gens = $this->bdd->query("select * from cards where addressbookid = ".$this->idCarnet." and carddata not like '%X-ADDRESSBOOKSERVER-KIND:group%'")->fetchAll();
		$this->gens = array();
		foreach($gens as $gen)
		{
			$p = new Personne($gen);
			$uid = $p->uid();
			if(isset($this->gens[$uid]))
			{
				$this->err('Plusieurs entrées avec l\'uid '.$uid);
				continue;
			}
			$this->gens[$uid] = $p;
		}
		
			$this->_brancherGensAuxGroupes();
		
		return $this->gens;
	}
}

?>
