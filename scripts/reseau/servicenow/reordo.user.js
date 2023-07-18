// ==UserScript==
// @name         ServiceNow en ordre
// @namespace    http://outters.eu/
// @description  Force l'ordre des barres d'un diagramme ServiceNow, ainsi que ses couleurs.
// @include      https://….service-now.com/*
// @require      https://git.io/waitForKeyElements.js
// @grant        none
// ==/UserScript==

(function(){

/* ICI PARAMÉTREZ VOS ÉTATS ET COULEURS */
var treo = [ /Transmis/, /En traitement/, /En attente/, /Résolu/ ];
var creo = [ [ 255, 127, 0 ], [ 255, 152, 25 ], [ 223, 223, 0 ], [ 143, 175, 0 ] ];

// treo = Tableau de Remise En Ordre; creo = Couleurs; freo = Fonction; lreo = Légende.
var exyt = /^translate\(([^,]*),([^,]*)\)$/;
var lreo;
var freo = function(bloc)
{
	// On réordonne les graphes selon treo.
	
	var rects = bloc.querySelectorAll('.highcharts-column-series .highcharts-point');
	var cols = {};
	var i, j, l, x, y, r, col, miny;
	for(i = rects.length; --i >= 0;)
	{
		r = rects[i];
		x = r.x.baseVal.valueAsString;
		if(typeof cols[x] == 'undefined')
			cols[x] = [];
		l = r.getAttribute('aria-label');
		for(j = -1; ++j < treo.length && !treo[j].test(l);) {}
		r.poids = j;
		r.setAttribute('fill', 'rgb('+creo[j].join(',')+')');
		cols[x].push(r);
	}
	for(col in cols)
	{
		col = cols[col];
		if(col.length < 1) continue;
		col.sort(function(a, b) { return b.poids - a.poids; }); // Ordre inverse, les y les plus faibles étant l'état le plus final.
		miny = col[0].y.baseVal.value;
		for(i = 0; ++i < col.length;)
			if((y = col[0].y.baseVal.value) < miny)
				miny = y;
		for(y = miny, i = -1; ++i < col.length;)
		{
			col[i].setAttribute('y', y);
			y += col[i].height.baseVal.value;
		}
	}
	
	// Idem pour la légende.
	
	lreo(bloc.parentElement.querySelector('.highcharts-legend'));
};
lreo = function(bloc)
{
	var rects = bloc.querySelectorAll('.highcharts-column-series');
	var fs = []; // Flottants. Trucs à déplacer.
	var ps = []; // Positions. Position de chaque bloc, glanées puis reréparties.
	var i, l, r, trans;
	for(i = rects.length; --i >= 0;)
	{
		r = rects[i];
		l = r.querySelector('tspan').innerHTML;
		for(j = -1; ++j < treo.length && !treo[j].test(l);) {}
		r.poids = j;
		fs.push(r);
		trans = r.getAttribute('transform');
		trans = { t: trans, x: parseFloat(trans.replace(exyt, '$1')), y: parseFloat(trans.replace(exyt, '$2')) };
		ps.push(trans);
		
		r = r.querySelector('rect');
		r.setAttribute('fill', 'rgb('+creo[j].join(',')+')');
	}
	ps.sort(function(a, b) { return a.y == b.y ? a.x - b.x : a.y - b.y; });
	fs.sort(function(a, b) { return a.poids - b.poids; });
	for(i = -1; ++i < fs.length;)
		fs[i].setAttribute('transform', ps[i].t);
	// À FAIRE: en fait on ne peut reprendre telle quelle l'abcisse: il faut recalculer ces dernières en fonction de la largeur des éléments qu'on a placés devant.
	// Là où ça se complique, c'est sur du multi-colonnes (ex.: 5 libellés de tailles diverses, répartis sur 2 colonnes):
	// il faut alors déterminer la largeur max de chaque colonne (/!\ pas séquentiel, la colonne 0 comporte les 0 - 2 - 4 tandis que la 1 contient les 1 - 3).
	// De plus attention à ce que ça tienne encore dans le contenant (si SNow avait réparti Riquiqui, Petit, Long, Gigantesque en 2 lignes R - L et G - P, le R et le G étaient sur la même large colonne (mettons 150px), et le L et le P sur une autre (mettons 100px), pour un total de 250px. Si maintenant R et G sont chacun sur une colonne, les *deux* colonnes devront faire 150px, pour un total de 300px: rentré-ce encore?).
};

var traiter = function()
{
	var appliquer = function(document)
	{
		var t = document.querySelectorAll('.highcharts-series-group');
		var i;
		// À FAIRE: les camemberts.
		// À FAIRE: quand on passe la souris ça remet la couleur d'origine.
		for(i = -1; ++i < t.length;)
			if(typeof(t[i].fait) == 'undefined' && t[i].querySelectorAll('.highcharts-column-series').length)
			{
				t[i].fait = true;
				freo(t[i]);
			}
	};
	var attente = setInterval(function()
	{
		appliquer(document);
		// https://stackoverflow.com/a/55837286/1346819
		var i;
		for(i = -1; ++i < frames.length;)
			appliquer(frames[i].document);
	}, 100);
	setTimeout(function() { clearInterval(attente); }, 5000);
};

traiter();

/*- Page ticket individuel -*/

var bloquer = function()
{
// Zone de description trop courte.
var descr = document.getElementById('sys_readonly.incident.description');
if(descr) descr.style.height = '256px';

// Les "titres" de section sont noyés parmi leurs sous-éléments (au même niveau, à l'intérieur d'un row; et parfois on a <row><titre1><élém1.1><élém1.2><titre2></row><row><élém2.1></row>)
// On réorganise donc tout ce bazar.
	var css = document.createElement('style');
	css.setAttribute('type', 'text/css');
	document.getElementsByTagName('head')[0].appendChild(css);
	css.appendChild
	(
		document.createTextNode
		(
			'.titre-bloc { cursor: pointer; position: relative; }'+
			'.titre-bloc .annotation-wrapper { margin: 0!important; font-size: 12px!important; line-height: 1!important; }'+
			'.fleche-bloc { position: absolute; top: 0; }'+
			'.fleche-bloc:after { content: " ▼"; }'+
			'.sous-bloc { display: none; }'
		)
	);
	
	var titre;
	var blocs = document.querySelectorAll('.form-group');
	var bloc, i, classes, fleche;
	for(i = -1; ++i < blocs.length;)
	{
		bloc = blocs[i];
		if(bloc.getAttribute('sn-atf-whitelist'))
		{
			titre = bloc.querySelector('.annotation-wrapper').innerText;
			if(titre == 'Descriptif')
				break;
			bloc.setAttribute('onclick', 'var b = document.body.toggleClassName("sous-blocs-'+titre+'-affiches");');
			bloc.setAttribute('class', ((classes = bloc.getAttribute('class')) ? classes+' ' : '')+'titre-bloc titre-bloc-'+titre);
			bloc.appendChild(fleche = document.createElement('div'));
			fleche.setAttribute('class', 'fleche-bloc fleche-bloc-'+titre);
			css.appendChild(document.createTextNode('.sous-blocs-'+titre+'-affiches .sous-bloc-'+titre+' { display: block; }'));
			css.appendChild(document.createTextNode('.sous-blocs-'+titre+'-affiches .fleche-bloc-'+titre+':after { content: "▲"; }'));
		}
		else if(titre)
		{
			if(!(classes = bloc.getAttribute('class')))
				classes = '';
			classes = classes+' sous-bloc sous-bloc-'+titre;
			bloc.setAttribute('class', classes);
		}
	}
};

bloquer();

// ServiceNow a tendance à ne pas charger dans ses iframes directement la page voulue,
// mais un simple JS de remplissage du <body> par invocation de la vraie URL sous-jacente.
// On doit donc attendre la survenue de cet appel avant d'appliquer.
var attendreEtRetaper = function(retape, params)
{
  	if(retape.apply(null, params)) return;
	var attente, fini;
	fini = function() { clearInterval(attente); }
	attente = setInterval(function() { if(retape.apply(null, params)) fini(); }, 100);
	setTimeout(fini, 5000);
};

// Sous GreaseMonkey 4, notre JS n'est pas automatiquement invoqué sur les iframes (même si l'URL respecte l'@include), à nous de nous appliquer aussi bien sur eux que sur le document principal.
// https://stackoverflow.com/questions/37616818 dit que les iframe ne reçoivent pas les événements.
// https://bleepingcoder.com/greasemonkey/259598810/execute-in-frames
// https://github.com/greasemonkey/greasemonkey/issues/2574
var attendreEtRetaperDocEtCadres = function(retape)
{
	attendreEtRetaper(retape, [ document ]);
	waitForKeyElements("iframe, frame", function(frame)
	{
		frame.addEventListener('load', function(e) { attendreEtRetaper(retape, [ e.target.contentDocument ]); });
	});
};

})();
