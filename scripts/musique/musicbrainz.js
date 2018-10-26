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
	'piano solo',
	'violon',
	'violoncelle',
	'violoncelle solo',
	
	'voix de soprano solo',
	'voix de ténor solo',
	
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

// http://stackoverflow.com/a/1997811/1346819
(function() {
if ( typeof Object.id == "undefined" ) {
var id = 0;
Object.id = function(o) {
if ( typeof o.__uniqueid == "undefined" ) {
Object.defineProperty(o, "__uniqueid", {
value: ++id,
enumerable: false,
// This could go either way, depending on your 
// interpretation of what an "id" is
writable: false
});
}
return o.__uniqueid;
};
}
})();

var g =
{
	depilement: [],
	empilements: [], // Les empilements sont des pointeurs sur le membre empilement d'empilables.
	enCours: false,
	tourner: function()
	{
		if(g.enCours) return;
		
		g.enCours = true;
		
		var actuel, papa;
		var onContinue;
		
		while(g.depilement.length)
		{
			// On recalcule l'actuel à chaque tour de boucle, car les fonctions appelées par le précédent tour ont pu modifier les piles.
			for(actuel = g; actuel.depilement && actuel.depilement.length; papa = actuel, actuel = actuel.depilement[0]) {}
			g.empilements.push(actuel);
			onContinue = actuel.apply(this);
			g.empilements.pop();
			if(onContinue !== 'encore')
			{
				// On supprime l'entrée qu'on vient de traiter… en n'oubliant pas de reprendre ses sous-entrées qui auraient été ajoutées entre-temps.
				papa.depilement.splice(0, 1);
				if(actuel.depilement && actuel.depilement.length)
					papa.depilement.unshift.apply(papa.depilement, actuel.depilement);
			}
			if(typeof onContinue == 'number')
			{
				setTimeout(function() { g.enCours = false; g.tourner(); }, onContinue);
				return;
			}
		}
		
		g.enCours = false;
	},
	empiler: function(f)
	{
		if(!g.empilements.length)
			g.empilements = [ g ];
		var empilable = g.empilements[g.empilements.length - 1];
		if(!empilable.depilement)
			empilable.depilement = [];
		empilable.depilement.push(f);
		
		g.tourner();
	},
	puis: function(f)
	{
		// On empile non pas f mais une encapsulation, afin d'être sûrs de ne pas laisser filer le retour de f vers tourner().
		g.empiler(function() { f.apply(this, arguments); });
		return g;
	},
	pause: function(millisecondes)
	{
		g.empiler(function() { return millisecondes; });
		return g;
	},
	attendre: function(fTest)
	{
		var f = function()
		{
			if(!fTest.apply(this))
			{
				g.pause(100); // Ira s'immiscer avant notre prochain test.
				// Et on dit à l'ordonnanceur de ne pas nous retirer, on retentera notre chance la prochaine fois.
				return 'encore';
			}
		};
		g.empiler(f);
		return g;
	},
	// ( cat musicbrainz.js ; echo "g.tester();" ) | node
    tester: function()
	{
		var res = [];
		var n = 3;
		g
			.puis(function() { res.push(0); })
			.pause(0)
			.puis(function() { res.push(1); })
			.puis(function() { g.puis(function() { res.push(2); }); })
			.attendre(function() { res.push(n); return ++n >= 7; })
			.puis(function() { g.puis(function() { res.push(7); }); })
			.puis(function() { res.push(8); })
			.puis(function() { console.log(res); })
		;
	}
};
