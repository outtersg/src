<?php

class Secu
{
	private static $mdp = 'monmdp';
	
	function calculer($quand)
	{
		return md5(gmstrftime('%Y%m%d%H', $quand).Secu::$mdp); // Précision à l'heure, pour limiter la plage de piratage possible… tout en permettant un minimum de désynchro entre client et serveur.
	}
	
	function verifier()
	{
		foreach(array(0, -1, 1) as $decalage) // Tout le monde n'est pas à la seconde près, et une seconde, arrondie à l'heure, ça peut faire beaucoup, voire une heure; alors on cherche si les heures voisines n'ont pas servi.
			if($_POST['mdp'] == Secu::calculer(time() + 3600 * $decalage))
				return true;
		return false;
		
		return in_array($_POST['mdp'], $v);
	}
	
	function authentifier(&$requeteCurl, &$params)
	{
		$params = array_merge(array('mdp' => Secu::calculer(time())), $params);
	}
}

?>
