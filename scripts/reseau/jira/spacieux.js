// ==UserScript==
// @name         JIRA spacieux
// @namespace    http://outters.eu/
// @description  Masque le gros pâté à droite qui bouffe un tiers de la largeur de l'écran pour pas grand-chose.
// @include      http://…/*
// ==/UserScript==

(
	function()
	{
		var tete = document.getElementsByTagName('head')[0];
		var st = document.createElement('style');
		var gp = document.querySelector('.issue-body-content');
		var pepere = document.getElementById('viewissuesidebar');
		var menu = document.createElement('DIV');
		var zorro = document.createElement('DIV');
		
		menu.setAttribute('class', 'pouet');
		menu.setAttribute('style', 'display: inline-block; position: absolute; right: 0; z-index: 1; width: auto; padding: 5px; border: 1px solid #DFDFDF; background: white;');
		zorro.setAttribute('class', 'zorro');
		zorro.setAttribute('style', 'display: inline-block; width: 32px; height: 32px; right: 0; background: url(…) no-repeat center center;');
		pepere.setAttribute('style', 'width: 400px; padding: 0;');
		menu.appendChild(zorro);
		menu.appendChild(pepere);
		gp.insertBefore(menu, gp.childNodes[0]);
		
		st.setAttribute('type', 'text/css');
		st.appendChild(document.createTextNode('.pouet #viewissuesidebar { display: none; } .pouet:hover #viewissuesidebar { display: block; } .pouet .zorro { position: relative; } .pouet:hover .zorro { position: absolute; }'));
		tete.appendChild(st);
	}
)
();
