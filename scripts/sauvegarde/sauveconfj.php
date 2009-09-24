<?php

require_once '/Users/gui/src/util/php//navigateur.inc';

$n = new Navigateur;

$n->auth = 'confj:xxx';
$page = $n->aller('http://sql.free.fr/phpMyAdmin/');
if(!preg_match('/token=([a-z0-9]*)[\'"]/', $page, $r) || !($token = $r[1])) die("Impossible de trouver le token dans la page.");

$page = $n->aller('db_export.php?db=confj');
if(!preg_match('#<select name="table_select\[\]".*</select>#sU', $page, $r)) die("Impossible de trouver la liste des tables dans la page.");
preg_match_all('/option value="([^"]*)"/', $r[0], $r);
$tables = array();
$tables['table_select'] = $r[1];

$page = $n->aller('export.php', array
(
	'token' => $token,
	'db' => 'confj',
	'export_type' => 'database',
	'what' => 'sql',
	'sql_structure' => 'something',
	'sql_drop_table' => 'something',
	'sql_if_not_exists' => 'something',
	'sql_auto_increment' => 'something',
	'sql_backquotes' => 'something',
	'sql_data' => 'something',
	'sql_columns' => 'something',
	'sql_extended' => 'something',
	'sql_max_query_size' => '50000',
	'sql_hex_for_blob' => 'something',
	'sql_type' => '0',
	'asfile' => 'sendit',
	'filename_template' => '__DB__',
	'charset_of_file' => 'utf-8',
	'compression' => 'bzip',
) + $tables);

echo $page;

?>
