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
		
		// Accès à AJS pour lui injecter de nouveaux raccourcis clavier.
		// Pas besoin de ruser façon http://5.9.10.113/58877097/add-a-custom-key-shortcut-within-javascript-in-confluence (car on est déjà chargés une fois la page bien installée).
		// Par contre pour taper la variable globale AJS, il faut ruser un peu.
		// La sécurité GreaseMonkey empêche d'accéder à window; on peut appeler une fonction d'unsafeWindow, mais pas lui passer de paramètres, car ceux-ci sont instanciés dans la zone GreaseMonkey et donc inaccessibles de la fenêtre.
		// Le @grant none de https://wiki.greasespot.net/Content_Script_Injection ne fonctionne pas.
		// Donc: https://sourceforge.net/p/greasemonkey/wiki/unsafeWindow/
		var s = document.createElement('script');
		s.type = 'application/javascript';
		s.textContent = "(" + function()
		{
			// Comme on est chargés en premier, on se permet de piquer le raccourci 'l'. Si ce n'était le cas il nous faudrait au préalable virer celui par défaut.
			AJS.KeyboardShortcut.fromJSON([ { moduleKey: "lien", context: "issueaction", op: "click", param: "#link-issue", keys: [ [ "l" ] ] } ]);
		} + ")();";
		document.body.appendChild(s);
	}
)
();
