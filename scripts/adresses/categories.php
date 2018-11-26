<?php

require_once dirname(__FILE__).'/baikalbase.php';

$p = new BaïkalBase($argv[1], $argv[2]);

$gensParNom = array();

$p->gens();
foreach($p->groupes() as $g)
	if($g instanceof Catégorie)
		foreach($g->gens as $gen)
			$gensParNom[$gen->nom()][$g->nom()] = true;

foreach($gensParNom as & $ptrGen)
	ksort($ptrGen);
ksort($gensParNom);

print_r($gensParNom);

?>
