<?php

class Interro
{
	public function demander($discid)
	{
		$listesDePistes = $this->discidEnListesDePistes($discid);
		return $listesDePistes;
	}
	
	public function discidEnListesDePistes($discid)
	{
		$disque = $this->_req('discid', $discid, array('media-format' => 'all', 'inc' => 'recordings artist-credits'));
		
		// Maintenant on recherche dans le résultat de recherche les disques qui pourraient correspondre vraiment à ce qu'on a demandé.
		
		$listesDePistes = array();
		
		if(isset($disque->releases))
		foreach($disque->releases as $sortie)
		{
			$titreRecueil = $sortie->title;
			$dateRecueil = null;
			if(isset($sortie->{'release-event-list'}))
				foreach($sortie->{'release-event-list'} as $événement)
					if(isset($événement->date))
						$dateRecueil = $événement->date;
			foreach($sortie->media as $media)
				foreach($media->discs as $sousDisque)
				{
					$titreAlbum = $media->title;
					if(strlen(trim($titreAlbum)) == 0)
						$titreAlbum = $titreRecueil;
					$numDisque = isset($media->position) ? $media->position : (count($sortie->media) > 1 ? 1 : '');
					$dateAlbum = $dateRecueil; // À FAIRE.
					if(isset($sousDisque->id) && $sousDisque->id == $discid)
					{
						$listesDePiste = $this->pistes($media->tracks);
						foreach($listesDePiste as & $ptrPiste)
						{
							$ptrPiste->album = $titreAlbum;
							$ptrPiste->numDisque = $numDisque;
							if(!isset($ptrPiste->date))
								$ptrPiste->date = $dateAlbum;
						}
						$listesDePistes[] = $listesDePiste;
						break;
					}
				}
		}
		
		return $listesDePistes;
	}
	
	public function nomArtiste($entrée)
	{
		if(!isset($this->_nomsArtiste[$entrée->id]))
		{
			$fiche = $this->_req('artist', $entrée->id, array('inc' => 'aliases'));
			
			$possibilités = array();
			foreach($fiche->aliases as $alias)
			{
				$p = array();
				switch($alias->type)
				{
					case 'Artist name': $p['t'] = 4; break;
					default: $p['t'] = 2; break;
					case 'Search hint': continue 2;
				}
				// À FAIRE: la langue de l'artiste devrait entrer en compte. Problème: on n'a pas l'info. Dans l'artiste, on a bien un country, mais va-t'en savoir que 'AT' a pour langue primaire 'de', et ne parlons pas des pays multilingues ('BE', par exemple). De plus, il nous faudrait lier la locale à son script: si c'est du latin, alors ça passe avant l'anglais, sinon on prendra en priorité l'anglais.
				switch($alias->locale)
				{
					case 'fr': $p['l'] = 4; break;
					case 'en': $p['l'] = 2; break;
					case '': $p['l'] = 0; break;
					default: continue 2;
				}
				$p['n'] = $alias->name;
				$possibilités[] = $p;
			}
			usort($possibilités, array($this, 'sommeTL'));
			$p = array_pop($possibilités);
			
			$this->_nomsArtiste[$entrée->id] = isset($p) ? $p['n'] : $entrée->name;
		}
		
		return $this->_nomsArtiste[$entrée->id];
	}
	
	public function sommeTL($a, $b)
	{
		return ($a['t'] + $a['l']) - ($b['t'] + $b['l']);
	}
	
	public function pistes($pistes)
	{
		$retour = array();
		foreach($pistes as $piste)
		{
			$p = new stdClass;
			$p->titre = $piste->title;
			
			// Les artistes.
			
			$artistes = array('c' => array(), 'i' => array());
			foreach(
				array
				(
					array('t' => $piste->{'artist-credit'}, 'd' => 'c'),
					array('t' => $piste->recording->{'artist-credit'}, 'd' => 'i'),
				)
				as $descrType
			)
			{
				$ajouts = array('i' => array());
			$séparateurs = array();
				foreach($descrType['t'] as $artiste)
			{
				$séparateurs[] = $artiste->joinphrase;
					$ajouts['i'][] = array
					(
						'id' => $artiste->artist->id,
						'nom' => ($nomArtiste = $this->nomArtiste($artiste->artist)) !== null ? $nomArtiste : $artiste->name,
					);
			}
			
			// Nomenclature: compositeur; artiste, artiste, artiste.
			
			foreach($séparateurs as $num => $sép)
				if(trim($sép) == ';')
						$ajouts['c'] = array_splice($ajouts['i'], 0, $num + 1, array());
				
				// Si la nomenclature par point-virgule n'a rien donné, on bascule sur la nomenclature habituelle: compositeur artiste du morceau, interprète artiste de l'enregistrement. La destination pour le type en cours de traitement est dans $descrType['d'].
				if(count($ajouts) == 1)
					$ajouts = array($descrType['d'] => $ajouts['i']);
				
				// On fusionne par id, pour dédoublonner.
				
				foreach($ajouts as $classe => $artistesAjout)
					foreach($artistesAjout as $artiste)
						$artistes[$classe][$artiste['id']] = $artiste['nom'];
			}
			
			// Finalisation.
			
			$p->artistes = $artistes['i'];
			$p->compositeurs = $artistes['c'];
			
			$retour[$piste->number] = $p;
		}
		return $retour;
	}
	
	protected function _req($type, $id, $params = array())
	{
		foreach($params as $clé => $val)
			$params[$clé] = $clé.'='.urlencode($val);
		
		$ws = 'http://musicbrainz.org/ws/2';
		$c = curl_init();
		curl_setopt($c, CURLOPT_URL, $ws.'/'.$type.'/'.$id.'?'.implode('&', $params).'&fmt=json');
		curl_setopt($c, CURLOPT_USERAGENT, 'guillaume-musicbrainz@outters.eu/1.0');
		curl_setopt($c, CURLOPT_RETURNTRANSFER, 1);
		
		$r = curl_exec($c);
		curl_close($c);
		
		return ($r1 = json_decode($r)) !== null ? $r1 : $r;
	}
}

class Poule
{
	public function pondre($listesDePistes)
	{
		foreach($listesDePistes as $listeDePistes)
			foreach($listeDePistes as $num => $piste)
			{
				$l = array
				(
					$piste->titre,
					implode(' / ', $piste->artistes),
					implode(' / ', $piste->compositeurs),
					$piste->album,
					$piste->date,
					$piste->numDisque,
				);
				echo implode("\t", $l)."\n";
			}
	}
}

$i = new Interro();
$p = new Poule();
$listes = $i->demander($argv[1]);
$p->pondre($listes);

?>
