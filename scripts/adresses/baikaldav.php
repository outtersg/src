<?php

class FicheDav
{
	public function __toString()
	{
		return $this->contenu;
	}
}

class BaïkalDav
{
	public function __construct($url, $qui, $mdp)
	{
		$this->url = $url;
		$this->qui = $qui;
		$this->mdp = $mdp;
	}
	
	public function fiche($uri, $méthode = 'GET', $contenu = null)
	{
		$enTêtes = array
		(
			'User-Agent: Mimine 1.0',
		);
		if($contenu)
		{
			$enTêtes[] = 'Content-Type: text/vcard';
		}
		
		$enTêtesRetour = array();
		
		$c = curl_init($this->url.(substr($this->url, -1) == '/' ? '' : '/').urlencode($this->qui).'/default/'.$uri.'.vcf');
		curl_setopt($c, CURLOPT_RETURNTRANSFER, 1);
		curl_setopt($c, CURLOPT_CUSTOMREQUEST, $méthode);
		curl_setopt($c, CURLOPT_USERPWD, $this->qui.':'.$this->mdp);
		curl_setopt($c, CURLOPT_HTTPHEADER, $enTêtes);
		curl_setopt($c, CURLOPT_HTTPAUTH, CURLAUTH_DIGEST);
		if($contenu)
		{
			curl_setopt($c, CURLOPT_POST, 1);
			curl_setopt($c, CURLOPT_POSTFIELDS, $contenu->__toString());
		}
		$fEnTêtes = function($c, $enTête) use(& $enTêtesRetour)
		{
			$bouts = explode(': ', $enTête, 2);
			if(count($bouts) == 2)
				$enTêtesRetour[$bouts[0]][] = $bouts[1];
			return strlen($enTête);
		};
		curl_setopt($c, CURLOPT_HEADERFUNCTION, $fEnTêtes);
		$r = curl_exec($c);
		
		if($r === false)
		{
			fprintf(STDERR, '#'.curl_error($c)."\n");
			curl_close($c);
			return null;
		}
		
		curl_close($c);
		
		if(!$r)
			return null;
		
		$f = new FicheDav();
		$f->uri = $uri;
		$f->contenu = $r;
		
		return $f;
	}
}

?>
