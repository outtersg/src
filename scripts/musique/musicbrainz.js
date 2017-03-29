/*
 * Copyright (c) 2017 Guillaume Outters
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/**
 * Date toutes les relations ayant participé à l'enregistrement.
 *
 * @param string d Date de début, au format ISO 1979-10-10.
 * @param void|string f Date de fin; si non définie, d est reprise.
 */
var g_daterCochees = function(d, f)
{
	if(typeof f == 'undefined')
		f = d;
	d = d.split('-');
	f = f.split('-');
	
	$('.recording input:checked').each(function(i, x)
	{
		g_daterPistes(d, f, $(x).parents('tr'));
	});
};

/*- Interne ------------------------------------------------------------------*/

var g_relationsDatees =
[
	'enregistré à',
	
	'chef d’orchestre',
	'enregistrement de',
	'orchestre',
	
	'hautbois',
	'piano',
	'violon',
	
	'-'
];

var g_remplirDate = function(ligne, date)
{
	ligne = $(ligne).find('input');
	var i, x;
	// On ne remplit rien si un élément de la date est déjà renseigné.
	for(i = 2; --i >= 0;)
		if(ligne[i].value)
			return;
	console.log(ligne);
	ligne.each(function(i, x) { $(x).val(date[i]).keydown(); });
};

var g_datagesLien = [];
var g_datageLienEnCours = false;

var g_daterLien = function(d, f, lien)
{
	$(lien).click();
	var lignesDate = $('.partial-date');
	g_remplirDate(lignesDate[0], d);
	g_remplirDate(lignesDate[1], f);
	console.log($('.rel-editor-dialog .buttons-right button').length);
	window.setTimeout(function()
	{
		$('.rel-editor-dialog .buttons-right button').click();
		var datage = g_datagesLien.pop();
		if(datage)
			datage();
		else
			g_datageLienEnCours = false;
	}, 0);
};

var g_datageLien = function(d, f, lien)
{
	var datage = function() { g_daterLien(d, f, lien); };
	if(!g_datageLienEnCours)
	{
		g_datageLienEnCours = true;
		datage();
	}
	else
		g_datagesLien.push(datage);
		
};

var g_daterPistes = function(d, f, piste)
{
	piste.find('.recording .link-phrase, .works > .ar > .link-phrase').filter(function(i, x) { return g_relationsDatees.indexOf($(x).text()) >= 0; }).each(function(i, x) { g_datageLien(d, f, x); });
};
