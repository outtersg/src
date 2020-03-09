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
$spéciaux = array('.', 'index.php');
foreach($fs as $f)
	if(!in_array($f, $spéciaux))
		echo '<a href="'.rawurlencode($f).'">'.htmlspecialchars($f).'</a><br/>'."\n";

?>
	</body>
</html>
