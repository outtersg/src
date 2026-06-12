<?php echo '<'.'?xml version="1.0" encoding="UTF-8"?'.'>'."\n"; ?>
<html>
	<head>
		<title>.</title>
	</head>
	<body>
<?php

ini_set('display_errors', 1);
error_reporting(-1);

if(!chdir(dirname(__FILE__))) throw new Exception('Zut, impossible d\'afficher le contenu du dossier');

$mode = 1; // 0: liste texte; 1: liste HTML.
$imagettes = !$mode;

function trans($ancien, $nouveau)
{
	for($premierDiff = 0; isset($ancien[$premierDiff]) && isset($nouveau[$premierDiff]) && $ancien[$premierDiff] === $nouveau[$premierDiff]; ++$premierDiff) {}
	
	for($pos = count($ancien); --$pos > $premierDiff - ($premierDiff >= count($nouveau) ? 1 : 0);)
		echo '</li>'."\n".'</ul>'."\n";
	if(isset($ancien[$premierDiff]) && isset($nouveau[$premierDiff]))
		echo '</li>'."\n".'<li>';
	while(++$pos < count($nouveau))
		echo "\n".'<ul>'."\n".'<li>';
}

function vercmp($a, $b)
{
	preg_match('/^([0-9]+\.)*/', $a, $a);
	preg_match('/^([0-9]+\.)*/', $b, $b);
	$a = explode('.', $a[0]);
	$b = explode('.', $b[0]);
	foreach($a as $pos => $val)
	{
		if(!isset($b[$pos])) return 1;
		$aval = (int)$val;
		$bval = (int)$b[$pos];
		if($bval != $aval) return $aval - $bval;
	}
	if(isset($b[$pos + 1])) return -1;
	return 0;
}

$fs = glob('*');
usort($fs, 'vercmp');
//$fs = ['4.truc', '4.1.u', '5.k', '5.1.l', '5.2.m' ]; // Pour tester l'arborescence.
$spéciaux = [ '.', '..', 'index.php', 'Makefile' ];
$pinde = []; // Pile des INDEntations.
foreach($fs as $f)
	if(!in_array($f, $spéciaux) && !preg_match('/\.(mini\.jpg|ninja|sh)$/', $f))
	{
		if(!$imagettes || ($mini = preg_replace('/\.(jpg)$/', '.mini.jpg', $f)) == $f)
			$mini = null;
		else
			if(!file_exists($mini))
			{
				// Sinon magick IMG_20260528_090329.jpg -resize 200 IMG_20260528_090329.mini.jpg
				$i = imagecreatefromjpeg($f);
				$h = imagesy($i);
				$l = imagesx($i);
				$i2 = imagecreatetruecolor($nl = (int)($l * 0.1), $nh = (int)($h * 0.1));
				imagecopyresampled($i2, $i, 0, 0, 0, 0, $nl, $nh, $l, $h);
				imagejpeg($i2, $mini);
			}
		if($mode)
		{
			$der = $pinde;
			preg_match('/^([0-9]+\.)*/', $f, $pinde);
			$pinde = explode('.', trim($pinde[0], '.'));
			trans($der, $pinde);
		}
		$prés = stat($f); $prés = !$prés || !$prés['size'];
		$dstyle = $fstyle = '';
		if(preg_match('/\.(?:zip)$/', $f)) { $dstyle = '<strong>'; $fstyle = '</strong>'; }
		if(!$prés) echo '<a href="'.rawurlencode($f).'">';
		if($mini) echo '<img src="'.rawurlencode($mini).'"/>';
		$f = htmlspecialchars($f);
		$f = preg_replace('/^((?:[0-9]+\.)+)/', '<span style="font-size: 80%;">\1 </span>', $f);
		echo $dstyle.$f.$fstyle;
		if(!$prés) echo '</a>';
		if(!$mode)
			echo '<br/>'."\n";
	}
if($mode)
	trans($pinde, []);

?>
	</body>
</html>
