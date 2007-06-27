<?php

$ID = 'fxlemenestrel@yahoo.fr';
$MDP = '';
$DEST='/tmp';
$SORTIE='/tmp/sortie.html';
$UTIL = '../../util/php';
$RECHERCHE = $argv[1];

require_once "$UTIL/navigateur.inc";

/*--- Chargement par titre dans notre cache ---*/

if($RECHERCHE == '-')
{

	$stdin = fopen("php://stdin", "r");
	
	while(($titre = fgets($stdin)) !== FALSE)
		$rs[0][] = '<a href="">Suite</a><span class=.titreDossiers.>'.trim(utf8_decode($titre)).'</span>';
	
	fclose($stdin);

}
else
{

/*--- Obtention dela page de résultats de recherche ---*/

$url = "http://www.edifa.com/sitemagazine/index.php?query_string=$RECHERCHE&blType_1=AND&query_string_2=&blType_2=AND&query_string_3=&rubrique=18&sous_rubrique=&strAuteur=&numero_fc=&blForm=1&isAvance=1&doSearch=1&idrub=23&idmeta=52&idlang=1&idsite=1&date_debut=jj%2Fmm%2Faaaa&date_fin=jj%2Fmm%2Faaaa&aff_par_page=16384&strValid=Rechercher";

$n = new Navigateur();
$page = $n->aller($url);

/*--- Récupération des résultats dans la page ---*/
/* Chaque résultat apparaît deux fois, une nous suffira. On délimite sur
 * l'identifiant de cette fois. */

preg_match_all('#<div class="pageDossiersProduitDetail.*</div>#sU', $page, $rs); // Ce faisant, du <div class="…">…<div>…</div>…</div>, on ne récupère que jusqu'au premier </div>, mais ça n'est pas grave, car tout ce qu'on veut y est.

}

/*--- Préparation du global ---*/

$sortie = fopen($SORTIE, 'w');
fwrite($sortie, <<<TERMINE
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>Edifa</title>
<meta http-equiv="Content-Type" content="text/html; charset=fr-iso-8859-1">
<link href="http://www.edifa.com/sitemagazine/public/spec/systeme_1/styles/edifa.css" rel="stylesheet" type="text/css">
<link href="http://www.edifa.com/sitemagazine/public/spec/systeme_1/styles/edifa_page.css" rel="stylesheet" type="text/css">
TERMINE
);

/*--- Et pour chaque lien ---*/

$premiereFois = true;
foreach($rs[0] as $r)
	if(preg_match('#<a href="([^"]*)">Suite</a>#', $r, $rlien)) // Seuls les machins avec Suite peuvent être lus (les autres sont les récents).
	{
		/*- Analyse -*/
		
		preg_match('#<span class=.titreDossiers.[^>]*>([^<]*)</span>#', $r, $rtitre);
		$titre = utf8_encode($rtitre[1]); // Et dire qu'il y a encore des gens qui fonctionnent en ISO-8859-1…
		printf('%s: ', $titre);
		$chemin = $DEST.'/'.strtr($titre, array('/' => '-')).'.html';
		if(file_exists($chemin))
		{
			printf("(déjà ici)\n");
			$page = file_get_contents($chemin);
		}
		else
		{
			/*- Accès -*/
			
			$n2 = $n->cloner();
			$page = $n2->aller($rlien[1]);
			if($premiereFois) // Pour la première page, on doit s'authentifier.
			{
				$racces = array();
				preg_match('#<form[^>]*form_authentification[^>]*action="([^"]*)"(.*)</form>#sU', $page, $racces);
				$rplanques = array();
				preg_match_all('#<input type="hidden" name="([^"]*)"[^>]*value="([^"]*)"#', $racces[2], $rplanques);
				
				$champs = array();
				/* On recompose notre tableau de hidden. */
				foreach($rplanques[1] as $i => $cle)
					$champs[$cle] = $rplanques[2][$i];
				/* Puis les champs saisis à la main */
				$champs['login'] = $ID;
				$champs['password'] = $MDP;
				$champs['btSubmit'] = "S'authentifier";
				
				$page = $n2->aller($racces[1], $champs);
				
				$premiereFois = false;
			}
			
			/*- Ménage -*/
			/* On vire les en-têtes et tout */
			
			/* En fait on recherche un div qui contient tout */
			
			$rpos = array();
			if(preg_match('#<div id="pageArchive">#', $page, $rpos, PREG_OFFSET_CAPTURE))
			{
				$pos = $rpos[0][1] + 4;
				for($nDiv = 1; $nDiv > 0;)
				{
					$prochainO = strpos($page, '<div', $pos);
					$prochainF = strpos($page, '</div', $pos);
					if($prochainO === false && $prochainF === false)
						break;
					if($prochainO !== false && $prochainO < $prochainF)
					{
						++$nDiv;
						$pos = $prochainO;
					}
					else
					{
						--$nDiv;
						$pos = $prochainF;
					}
					++$pos;
				}
				
				if($nDiv <= 0)
				{
					//$depart = $rpos[0][1] + strlen($rpos[0][0]);
					//$taille = $pos - 1 - $depart;
					$depart = $rpos[0][1];
					$taille = $pos + 5 - $depart;
					$page = substr($page, $depart, $taille);
				}
			}
			
			/*- Enregistrement -*/
			
			$f = fopen($chemin, 'w');
			fwrite($f, $page);
			fclose($f);
			
			printf("%d octets\n", strlen($page));
		}
		
		/*- Et dans le fichier global -*/
		
		unset($coupe1);
		unset($coupe2);
		if(preg_match('#<span class="pageArchiveTitre">(<span.*</span>|[^<]*)*</span>#sU', $page, $r, PREG_OFFSET_CAPTURE))
		{
			$coupe1 = strrpos($r[0][0], '>', -4) + $r[0][1] + 1;
			$coupe2 = strrpos($r[0][0], '<') + $r[0][1];
		}
		fwrite($sortie, isset($coupe1) && isset($coupe2) ? substr($page, 0, $coupe1).'</span><h2>'.substr($page, $coupe1, $coupe2 - $coupe1).'</h2>' : $page);
	}

fwrite($sortie, <<<TERMINE
</body>
</html>
TERMINE
);
fclose($sortie);

?>
