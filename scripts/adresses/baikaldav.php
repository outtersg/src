<?php

class BaïkalDav
{
	public function __construct($url, $qui, $mdp)
	{
		$this->url = $url;
		$this->qui = $qui;
		$this->mdp = $mdp;
	}
	
	public function fiche($uri)
	{
		$enTêtes = array
		(
			'User-Agent: Mimine 1.0',
		);
		
		$c = curl_init($this->url.(substr($this->url, -1) == '/' ? '' : '/').urlencode($this->qui).'/default/'.$uri.'.vcf');
		curl_setopt($c, CURLOPT_RETURNTRANSFER, 1);
		curl_setopt($c, CURLOPT_HEADER, 1);
		curl_setopt($c, CURLOPT_CUSTOMREQUEST, "GET");
		curl_setopt($c, CURLOPT_HTTPHEADER, $enTêtes);
		curl_setopt($c, CURLOPT_USERPWD, $this->qui.':'.$this->mdp);
		curl_setopt($c, CURLOPT_HTTPAUTH, CURLAUTH_DIGEST);
		$r = curl_exec($c);
		curl_close($c);
		
		if($r === false)
		{
			fprintf(STDERR, '#'.curl_error($c)."\n");
			return null;
		}
		
		return $r;
	}
}

?>
