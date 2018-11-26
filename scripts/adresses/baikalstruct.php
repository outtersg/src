<?php

class Fiche
{
	public function __construct($entrée)
	{
		$this->id = $entrée['id'];
		$this->contenu = $entrée['carddata'];
		$this->uri = $entrée['uri'];
	}
	
	public function __toString()
	{
		return $this->contenu;
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
	
	/**
	 * Renvoie true si l'ajout est effectif, false si finalement la fiche y figurait déjà.
	 */
	public function ajouter(Personne $p)
	{
		if(!isset($this->gens[$p->uid()]))
		{
		$this->gens[$p->uid()] = $p;
		$p->_notifGroupe($this);
			return true;
		}
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

?>
