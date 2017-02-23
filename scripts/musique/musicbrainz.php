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
	
	public function pistes($pistes)
	{
		$retour = array();
		foreach($pistes as $piste)
		{
			$p = new stdClass;
			$p->titre = $piste->title;
			
			// Les artistes.
			
			$séparateurs = array();
			$artistes = array();
			$compositeurs = array();
			foreach($piste->recording->{'artist-credit'} as $artiste)
			{
				$séparateurs[] = $artiste->joinphrase;
				$artistes[] = $artiste->name;
			}
			
			// Nomenclature: compositeur; artiste, artiste, artiste.
			
			foreach($séparateurs as $num => $sép)
				if(trim($sép) == ';')
					$compositeurs = array_splice($artistes, 0, $num + 1, array());
			
			// Finalisation.
			
			$p->artistes = $artistes;
			$p->compositeurs = $compositeurs;
			
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
