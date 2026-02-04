<?php

/* Prend une description de cases type Excel "G26:CA32;CD27:ACO32;G7:ACO25;G33:ACO42;G44:ACO4122;G43:LS43;LU43:ACO43;CD26:JO26;JQ26:ACO26" et détermine quelles cases il couvre en réalité.
 * Utile par exemple lorsque des ajouts de cases au beau milieu d'une zone en formatage conditionnel ont éclaté les intervalles en plein de petits morceaux.
 */

// Constantes pile dans l'ordre de notre preg_match_all.
define('G', 1);
define('H', 2);
define('D', 3);
define('B', 4);

/**
 * Renvoie le numéro de colonne correspondant à un nom de colonne (ex.: AA → 27).
 */
function colEnAbcisse($col)
{
	for($r = 0, $i = -1; ++$i < strlen($col);)
		$r = $r * 26 + (1 + ord($col[$i]) - ord('A'));
	return $r;
}

function abcisseEnCol($x)
{
	for($r = ''; $x > 0; $x = floor($x / 26)) // intdiv en PHP 7
		$r = chr(ord('A') + ($x % 26) - 1).$r;
	return $r;
}

function plagesEnRects($plages)
{
	preg_match_all('/([A-Z]+)([0-9]+):([A-Z]+)([0-9]+)/', $plages, $r, PREG_SET_ORDER);
	foreach($r as & $ptrRect)
		foreach([ G, D ] as $coord)
			$ptrRect[$coord] = colEnAbcisse($ptrRect[$coord]);
	return $r;
}

function rectEnPlage($rect)
{
	return abcisseEnCol($rect[G]).$rect[H].':'.abcisseEnCol($rect[D]).$rect[B];
}

$àFaire = [];

array_shift($GLOBALS['argv']);
foreach($GLOBALS['argv'] as $param)
{
	$àFaire = plagesEnRects($param);
	$zone = $àFaire[0];
	foreach($àFaire as $rect)
	{
		if($rect[G] < $zone[G]) $zone[G] = $rect[G];
		if($rect[D] > $zone[D]) $zone[D] = $rect[D];
		if($rect[H] < $zone[H]) $zone[H] = $rect[H];
		if($rect[B] > $zone[B]) $zone[B] = $rect[B];
	}
	
	echo "Zone: ".rectEnPlage($zone)."\n";
	
	$trous = [ $zone ];
	
	foreach($àFaire as $rect)
	{
		echo '  rectangle '.rectEnPlage($rect)."\n";
		$éclats = []; // Si le rectangle courant intersecte un des trous, il en comble un bout; les éclats (restes du trous non comblés) vont là-dedans.
		foreach($trous as $numTrou => $trou)
			if($rect[G] <= $trou[D] && $rect[D] >= $trou[G] && $rect[H] <= $trou[B] && $rect[B] >= $trou[H])
			{
				echo '    intersection '.rectEnPlage($rect).' '.rectEnPlage($trou)."\n";
				unset($trous[$numTrou]);
				if($rect[H] > $trou[H]) $éclats[] = [ G => $trou[G], H => $trou[H], D => $trou[D], B => $rect[H] - 1 ];
				if($rect[G] > $trou[G]) $éclats[] = [ G => $trou[G], H => max($rect[H], $trou[H]), D => $rect[G] - 1, B => min($rect[B], $trou[B]) ];
				if($rect[D] < $trou[D]) $éclats[] = [ G => $rect[D] + 1, H => max($rect[H], $trou[H]), D => $trou[D], B => min($rect[B], $trou[B]) ];
				if($rect[B] < $trou[B]) $éclats[] = [ G => $trou[G], H => $rect[B] + 1, D => $trou[D], B => $trou[B] ];
				echo '    → '.count($éclats).' rectangles restants'."\n";
			}
		$trous = array_merge($trous, $éclats);
		echo '  → '.implode(';', array_map('rectEnPlage', $trous))."\n";
	}
	
	/* À FAIRE: recoudre les trous qui se touchent? */
	
	echo 'Trous restants: '.implode(';', array_map('rectEnPlage', $trous))."\n";
}

?>
