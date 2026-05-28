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

$fs = glob('*');
sort($fs);
$spéciaux = array('.', '..', 'index.php');
foreach($fs as $f)
	if(!in_array($f, $spéciaux) && !preg_match('/.mini.jpg$/', $f))
	{
		if(($mini = preg_replace('/\.(jpg)$/', '.mini.jpg', $f)) == $f)
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
