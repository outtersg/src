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

$imagettes = 1;

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
		echo '<a href="'.rawurlencode($f).'">'.($mini ? '<img src="'.rawurlencode($mini).'"/>' : '').htmlspecialchars($f).'</a><br/>'."\n";
	}

?>
	</body>
</html>
