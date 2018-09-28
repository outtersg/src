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
			'Expect:',
		);
		if($contenu)
		{
			$enTêtes[] = 'Content-Type: text/vcard';
			if(isset($contenu->etag))
				$enTêtes[] = 'If-Match: '.$contenu->etag;
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
		if(isset($enTêtesRetour['ETag']))
			$f->etag = strtr($enTêtesRetour['ETag'][0], array("\n" => '', "\r" => ''));
		
		return $f;
	}
	
	public function grouper($p, $g)
	{
		$fiche = $this->fiche($g->uid());
		$uidp = $p->uid();
		$fiche->contenu = preg_replace("#([\r\n]+)(END:VCARD)#", "\\1X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:$uidp\\1\\2", $fiche);
		$this->fiche($g->uid(), 'PUT', $fiche, null);
	}
}

?>
