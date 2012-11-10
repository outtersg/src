<?php

array_shift($argv);
$dest = array_shift($argv);
if(!is_dir($dest))
	mkdir($dest);
if(!is_dir($dest))
{
	echo '# '.$dest.' n\'est pas un dossier. Il le faut pourtant, pour qu\'il serve de destination aux photos.'."\n";
	exit;
}
$dates = array();
foreach($argv as $num => $arg)
{
	$i = exif_read_data($arg);
	$dates[$num] = $i['DateTime'];
}

asort($dates);

$numTrie = 0;
foreach($dates as $num => $date)
{
	$nom = sprintf('IMG_%04.4d.JPG', ++$numTrie);
	system('ln "'.$argv[$num].'" "'.$dest.'/'.$nom.'"');
}

system('ls -l "'.$dest.'"');
