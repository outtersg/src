// ==UserScript==
// @name         JIRA spacieux
// @namespace    http://outters.eu/
// @description  Masque le gros pâté à droite qui bouffe un tiers de la largeur de l'écran pour pas grand-chose.
// @include      http://…/*
// ==/UserScript==


/* ICI PLACEZ L'URL QUI RENVERRA LE HTML POUR LE JIRA DONT LE NUMÉRO LUI EST PASSÉ CONCATÉNÉ
 * L'exemple donné fonctionne sur Riquet (https://github.com/outtersg/riquet si un jour je le publie),
 * extracteur et présentateur de fiches ServiceNow. */
var giraIncsUrl = 'http://riquet.local/liens.php?q=@NUM&num=@REFS';
var giraIncsChamp = '#customfield_123456-val';

var gira =
{
	incs: function()
	{
		var num = document.head.querySelector('meta[name="ajs-issue-key"]').attributes.content.value;
		var refs = document.querySelector(giraIncsChamp);
		if(refs && refs.innerHTML) refs = refs.innerHTML;
		var req = new XMLHttpRequest();
		req.addEventListener('load', function()
		{
			var infos = document.querySelector('#details-module .mod-content');
			infos.insertAdjacentHTML('beforeend', '<ul class="property-list"><li class="item"><div class="wrap"><strong class="name">Incidents:</strong><div class="value type-readonlyfield" style="border: 1px solid black; background: #FFFFDF">'+req.responseText+'</div></div></li></ul>');
		});
		req.open('GET', giraIncsUrl.replace(/@NUM/, num).replace(/@REFS/, refs));
		req.send();
	}
};

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
			//AJS.KeyboardShortcut.fromJSON([ { moduleKey: "lien", context: "issueaction", op: "click", param: "#link-issue", keys: [ [ "l" ] ] } ]);
			// Pour avoir en plus le curseur qui se positionne sur le champ "type", on doit ruser:
			// - execute: pour une instruction complexe
			// - setTimeout: pour passer APRÈS l'autofocus JIRA (https://jira.atlassian.com/browse/JRASERVER-15758; pourrait-on intercepter via https://confluence.atlassian.com/jirakb/focus-is-switched-to-a-different-field-224396165.html)
			// - passivite: le premier chargement est un peu longuet, les suivants moins. On adapte.
			var passivite = 1000;
			var lien = function()
			{
				$('#link-issue').click();
				setTimeout(function() { $('#link-type').focus(); }, passivite);
				passivite = 200;
			};
			AJS.KeyboardShortcut.fromJSON([ { moduleKey: "lien", context: "issueaction", op: "execute", param: lien, keys: [ [ "l" ] ] } ]);
		} + ")();";
		document.body.appendChild(s);
		
		gira.incs();
	}
)
();
