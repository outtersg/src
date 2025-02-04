#!/bin/sh
# Extirpe la liste de prix de https://www.bouyguestelecom.fr/telephones-mobiles

# Finalement on ne fait pas ça, car on a un beau JSON qui traîne.
true ||
sed -E \
	-e 's#<div [^>]*product-card[^>]*>#@@@ Nouvelle entrée @@@#g' \
	-e 's#(<[^>]*>)+#'"`printf '\003'`"'#g' \
| tr \\003 \\012

php -r '
$c = stream_get_contents(STDIN);
// Une seule occurrence de products non vide, on y file:
$c = preg_replace("/.*\\\\\"products\\\\\":\[{/s", "[{", $c);
$c = preg_replace("/}\\],\\\\\"pageSize.*/", "}]", $c);
$c = strtr($c, [ "\\\"" => "\"" ]);
$l = json_decode($c);
usort($l, function($a, $b) { return strcmp($a->id, $b->id); });
$r = [];
foreach($l as $tél)
	$r[$tél->brand.$tél->name] = $tél->details->price->final."\t".($tél->rating->value ?? "");
print_r($l);
print_r($r);
'
