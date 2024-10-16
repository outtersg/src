// ==UserScript==
// @name         JIRA spacieux
// @namespace    http://outters.eu/
// @description  Masque le gros pâté à droite qui bouffe un tiers de la largeur de l'écran pour pas grand-chose.
// @include      https://jira.…/*
// @include      https://*.atlassian.net/browse/*
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
		var num;
		if((num = document.head.querySelector('meta[name="ajs-issue-key"]')))
			num = num.attributes.content.value;
		else if((num = document.querySelector('[data-testid="issue.views.issue-base.foundation.breadcrumbs.current-issue.item"]')))
			num = num.textContent;
		var refs = document.querySelector(giraIncsChamp); // À FAIRE sous JiraNuage.
		if(refs && refs.innerHTML) refs = refs.innerHTML.replace('&nbsp;', '').trim();
		var req = new XMLHttpRequest();
		req.addEventListener('load', function()
		{
			var infos = document.querySelector('#details-module .mod-content'); // À FAIRE sous JiraNuage.
			infos.insertAdjacentHTML('beforeend', '<ul class="property-list"><li class="item"><div class="wrap"><strong class="name">Incidents:</strong><div class="value type-readonlyfield" style="border: 1px solid black; background: #FFFFDF">'+req.responseText+'</div></div></li></ul>');
		});
		req.open('GET', giraIncsUrl.replace(/@NUM/, num).replace(/@REFS/, refs));
		req.send();
	},
	/* Les listes déroulantes ont un [max-]width: 100% qui prend trop de place une fois qu'on supprime le menu droite;
	 * donc visuellement déjà ça fait moche, mais pire: les suggestions du menu s'affichant à droite du menu lui-même, tombent hors page lorsque le menu prend toute la largeur! */
	deroulantes: function(css)
	{
		css.appendChild(document.createTextNode('.full-width { max-width: 512px; }'));
	}
};

{
	var ints;
	var inst = function()
	{
		var style = '';
		var tete = document.getElementsByTagName('head')[0];
		var gp = document.querySelector('.issue-body-content, [data-testid="issue.views.issue-details.issue-layout.container-left"]');
		if(gp) window.clearInterval(ints); else return;
		document.querySelector('[data-testid="issue.views.issue-details.issue-layout.container-right"]').id = 'viewissuesidebar';
		var pepere = document.getElementById('viewissuesidebar');
		var menu = document.createElement('DIV');
		var zorro = document.createElement('DIV');
		var i;
		
		var commentaireFlottant = document.querySelector('[data-testid="issue.activity.comment"]');
		if(commentaireFlottant)
			commentaireFlottant.parentNode.parentNode.style.setProperty('position', 'static'); // Au lieu de sticky.
		
		var agrandissement = document.querySelector('[data-component-selector="jira-issue-view-common-component-resize-handle"]');
		if(agrandissement)
			for(i = agrandissement.classList.length; --i >= 0;)
				if(document.querySelectorAll('.'+agrandissement.classList[i]).length == 1)
					style += '.'+agrandissement.classList[i]+'[role="separator"] { display: none; }\n';
		menu.setAttribute('class', 'pouet');
		zorro.setAttribute('class', 'zorro');
		zorro.setAttribute('style', 'display: inline-block; width: 32px; height: 32px; right: 0; background: url('+document.querySelectorAll('#assignee-val img, [data-testid="issue.views.field.user.assignee"] img')[0].src+') no-repeat center center; background-size: contain;');
		pepere.setAttribute('style', 'width: 400px; padding: 0;');
		menu.appendChild(zorro);
		menu.appendChild(pepere);
		gp.insertBefore(menu, gp.childNodes[0]);
		
		style +=
			'.pouet { display: inline-block; position: absolute; right: 0; z-index: 256; width: auto; padding: 5px; border: 1px solid #DFDFDF; background: white; }\n'+
			'.pouet #viewissuesidebar { display: none; max-height: 400px; }\n'+
			'.pouet:hover #viewissuesidebar { display: block; }\n'+
			'.pouet .zorro { position: relative; }\n'+
			'.pouet:hover .zorro { position: absolute; }\n';
		
		// Recherche de la classe CSS en tête de tout le contenu.
		var unTitre = document.querySelector('[class^="css-"] h2[data-testid="issue.views.issue-base.common.description.label"]');
		var unTexte = document.querySelector('.is-comment [class^="css-"]');
		if(unTexte)
		{
			while(unTitre && !(unTitre.className && unTitre.className.match(/^css-/))) unTitre = unTitre.parentNode;
			if(unTexte) // Marcherait aussi avec unTitre finalement.
				style +=
					'.'+unTexte.classList[0]+' p { line-height: 1.1 !important; letter-spacing: 0 !important; }\n'+
					'.'+unTexte.classList[0]+' { font-size: 9pt; }\n';
		}
		document.body.style.setProperty('--ds-font-body', '9pt sans-serif'); // Celui-là est paramétrable par une simple pseudo-prop du corps, ouf!, qui passe avant tout le fatras qu'ils ont définir par défaut.
		style += '.code-block code[class*="language-"] { font-size: 9pt; line-height: 1; }\n';
		
		// Les réactions: on va choper la classe "privée" du conteneur.
		var uneReac = document.querySelector('[data-testid="issue-comment-base.ui.comment.reactions-container"]');
		if(uneReac)
		{
			uneReac = uneReac.parentNode;
			style +=
				'.'+uneReac.classList[0]+' { position: absolute; bottom: 0; left: 0; opacity: 0.33; }\n'+
				'.'+uneReac.classList[0]+':hover { z-index: 2; opacity: 1; background: var(--ds-surface, white); }\n'+
				'.'+uneReac.previousSibling.classList[0]+' { z-index: 1; }'+
				'.'+uneReac.previousSibling.querySelector('h3').classList[0]+' { font-size: 80%; }';
		}
		
		tete.insertAdjacentHTML('beforeend', '<style type="text/css">\n'+style+'</style>');
		var st = tete.lastChild;
		
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
		
		gira.deroulantes(st);
		gira.incs();
		
		// Et pourquoi notre société considérerait-elle que les vieux sont sans intérêt et doivent être masqués?
		// (bon d'accord ce ne sont que de vieux *commentaires*)
		var plus = document.querySelector('[data-testid="issue.activity.common.component.load-more-button.loading-button"]');
		if(plus) plus.click();
	};
	
	ints = window.setInterval(inst, 1000);
	inst();
}
