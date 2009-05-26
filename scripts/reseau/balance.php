<?php
/*
 * Copyright (c) 2007-2008 Guillaume Outters
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

require_once 'util/chemin.inc';
require_once 'util/temp.inc';

@include_once 'balance_secu.php';

class Balance
{
	function RecevoirRequete()
	{
		if(class_exists('Secu') && method_exists('Secu', 'verifier'))
			if(!Secu::verifier())
			{
				echo serialize('qued');
				return;
			}
		
		$b = new Balance(new Chemin($_POST['chemin']));
		switch($_POST['mode'])
		{
			case 'infos':
				echo serialize($b->infos());
				break;
			case 'bloc':
				echo serialize($b->recevoir($_FILES['bloc']['tmp_name'], $_POST['position']) ? 'oui' : 'non');
				break;
		}
	}
	
	function Balance($chemin)
	{
		$this->chemin = $chemin;
	}
	
	function infos()
	{
		if(($infos = @stat($this->chemin->cheminComplet())) === false)
			return false;
		$crc = false;
		if(($infos['mode'] & 0170000) == 040000)
			$type = 'd';
		else
		{
			$type = 'f';
			if(($f = fopen($this->chemin->cheminComplet(), 'r')) !== false)
			{
				$crc = array();
				while($b = fread($f, 0x40000))
					$crc[] = sprintf('%u', crc32($b)); // Sans le sprintf, on a des chaînes différentes d'une plate-forme à l'autre.
				$crc = serialize($crc);
				fclose($f);
			}
		}
		return array('type' => $type, 'crc32' => $crc, 'taille' => $infos['size']);
	}
	
	function recevoir($cheminBloc, $position)
	{
		$this->chemin->creerDossier();
		if(($f = fopen($this->chemin->cheminComplet(), 'a')) === false) return false;
		if($position == 0) // Premier bloc de ce fichier (on les suppose envoyés dans l'ordre!), on repart de zéro.
			ftruncate($f, 0); /* À FAIRE: passer par des signaux de début / fin de fichier. Le premier demande de tronquer. Le second pourrait servir, si on fonctionne en « je crée à côté, et finis en rename », au rename. */
		$r = false;
		if(fseek($f, $position) == 0)
			$r = fwrite($f, file_get_contents($cheminBloc)) == filesize($cheminBloc);
		fclose($f);
		return $r;
	}
	
	function requete($facteur, $params, $bloc = false)
	{
		$c = curl_init();
		if(class_exists('Secu') && method_exists('Secu', 'authentifier'))
			Secu::authentifier($c, $params);
		curl_setopt($c, CURLOPT_RETURNTRANSFER, true);
		$url = '';
		/*
		foreach($params as $cle => $p)
			$url .= ($url ? '&' : '?').$cle.'='.urlencode($p);
		*/
		curl_setopt($c, CURLOPT_POST, 1);
		$url = $facteur.$url;
		curl_setopt($c, CURLOPT_URL, $url);
		if($bloc)
			$params = array_merge(array('bloc' => urlencode($bloc)), $params);
		curl_setopt($c, CURLOPT_POSTFIELDS, $params);
		$r = curl_exec($c);
		curl_close($c);
		return unserialize($r);
	}
	
	function rerequete($facteur, $params, $bloc = false)
	{
		for($essai = 3; --$essai >= 0;)
			if(($r = $this->requete($facteur, $params, $bloc)) == 'oui' || is_array($r))
				return $r;
		return $r;
	}
	
	function envoyer($facteur, $infos, $destination)
	{
		$t = time();
		/* À FAIRE: paramétrer cette taille. */
		$taille = 0x500;
		$p = 0;
		
		$chemin = $this->chemin->cheminComplet();
		if($infos['taille'] <= $taille)
			$r = $this->rerequete($facteur, array('mode' => 'bloc', 'chemin' => $destination, 'position' => $p, 'bloc' => '@'.realpath($chemin)));
		else if(($f = fopen($chemin, 'r')))
		{
			$cheminTemp = '/tmp/'.temp_nouveau('/tmp/', '.balance.temp').'.balance.temp';
			$temp = fopen($cheminTemp, 'w');
			while(($b = fread($f, $taille)))
			{
				ftruncate($temp, 0);
				fseek($temp, 0, SEEK_SET);
				fwrite($temp, $b);
				if(($r = $this->rerequete($facteur, array('mode' => 'bloc', 'chemin' => $destination, 'position' => $p, 'bloc' => '@'.realpath($cheminTemp)))) != 'oui')
					break;
				$p += strlen($b);
			}
			fclose($temp);
			unlink($cheminTemp);
			fclose($f);
		}
		echo $chemin.($r == 'oui' ? ((time() - $t) ? ' ('.ceil($infos['taille'] / (time() - $t) / 1000.0).' Ko/s)' : '') : ' ('.$r.')')."\n";
	}
	
	function envoyerSiNecessaire($facteur, $infos, $destination)
	{
		echo $this->chemin->cheminComplet()."?\n";
		$infosAutre = $this->rerequete($facteur, array('mode' => 'infos', 'chemin' => $destination));
		if(!$infosAutre || $infosAutre['crc32'] != $infos['crc32'])
			$this->envoyer($facteur, $infos, $destination);
		else if(!is_array($infosAutre))
			echo $this->chemin->cheminComplet().' ('.$r.')'."\n";
	}
	
	function EnvoyerRecursivement($source, $facteur, $destination, $sauf)
	{
		if(($d = opendir($source->cheminComplet())) !== false)
		{
			$noms = array();
			while(($f = readdir($d)) !== false)
				$noms[] = $f;
			closedir($d);
			foreach($noms as $nom)
				Balance::EnvoyerChose($source, $nom, $facteur, $destination, $sauf);
		}
	}
	
	function EnvoyerChose($source, $nom, $facteur, $destination, $sauf)
	{
				$soussource = $source->et($nom);
			if($nom == '..' || $nom == '.' || in_array($soussource->cheminComplet(), $sauf)) return; /* À FAIRE: blinder avec une table d'inodes déjà parcourus (enfin, pas d'inodes, car un inode peut se retrouver à plusieurs endroits)). */
				$f = new Balance($soussource);
				$i = $f->infos();
				switch($i['type'])
				{
					case 'd':
						$soussource = $source->et($nom.'/');
						Balance::EnvoyerRecursivement($soussource, $facteur, $destination.'/'.$nom, $sauf);
						break;
					case 'f':
						$f->envoyerSiNecessaire($facteur, $i, $destination.'/'.$nom);
						break;
				}
	}
	
	/* Point d'entrée. Bidouille ses paramètres pour qu'ils soient acceptés par
	 * EnvoyerChose(). */
	function Balancer($chemin, $facteur, $destination, $sauf)
	{
		Balance::EnvoyerChose(new Chemin(dirname($chemin).'/'), in_array($nom = basename($chemin), array('.', '..')) ? $nom.'/' : $nom, $facteur, $destination, $sauf);
	}
}

if(isset($argv))
	Balance::Balancer($argv[1], $argv[2], $argv[3].'/', array_key_exists(4, $argv) && $argv[4] == '-' ? array_slice($argv, 5): array());
else if(array_key_exists('envoie', $_GET))
{
	$envoie = new Chemin($_GET['envoie'].'/', new Chemin($_SERVER['SCRIPT_NAME']));
	$par = new Chemin($_GET['par']);
	$vers = new Chemin($_GET['vers'].'/', $par, true);
	Balance::EnvoyerRecursivement($envoie->cheminDepuis($envoie->depuis), $par->cheminComplet(), $vers->cheminDepuis($par)->cheminComplet(), array_key_exists('sauf', $_GET) ? is_array($_GET['sauf']) ? $_GET['sauf'] : array($_GET['sauf']) : array());
}
else
	Balance::RecevoirRequete();

?>
