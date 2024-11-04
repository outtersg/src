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
	menudroite: function()
	{
		if(!gira.menudroite.n) gira.menudroite.n = 1;
		else if(++gira.menudroite.n >= 100) { window.clearInterval(gira.menudroite.re); return; }
		
		var gp = document.querySelector('.issue-body-content, [data-testid="issue.views.issue-details.issue-layout.container-left"]'); // Grand-père.
		var pepere = document.querySelector('[data-testid="issue.views.issue-details.issue-layout.container-right"]');
		if(pepere) pepere.id = 'viewissuesidebar';
		else pepere = document.getElementById('viewissuesidebar');
		var menu = document.getElementById('menuZorro');
		var i;
		
		var agrandissement = document.querySelector('[data-component-selector="jira-issue-view-common-component-resize-handle"]');
		if(agrandissement)
			for(i = agrandissement.classList.length; --i >= 0;)
				if(document.querySelectorAll('.'+agrandissement.classList[i]).length == 1)
					gira.style.innerHTML += '.'+agrandissement.classList[i]+'[role="separator"] { display: none; }\n';
		
		if(!menu)
		{
			menu = document.createElement('DIV');
			menu.id = 'menuZorro';
			
			var zorro = document.createElement('DIV');
		menu.setAttribute('class', 'pouet');
		zorro.setAttribute('class', 'zorro');
		pepere.setAttribute('style', 'width: 400px; padding: 0;');
		menu.appendChild(zorro);
		menu.appendChild(pepere);
		gp.insertBefore(menu, gp.childNodes[0]);
		
			var urlIcone = document.querySelector('#assignee-val img, [data-testid="issue.views.field.user.assignee"] :is(img, svg)');
			if(urlIcone) urlIcone = urlIcone.src;
		gira.style.innerHTML +=
			'.pouet { display: inline-block; position: absolute; right: 0; z-index: 256; width: auto; padding: 5px; border: 1px solid #DFDFDF; background: white; }\n'+
			'.pouet #viewissuesidebar { display: none; max-height: 400px; }\n'+
			'.pouet:hover #viewissuesidebar { display: block; }\n'+
				'.pouet .zorro { position: relative; display: inline-block; width: 32px; height: 32px; right: 0; background: url('+urlIcone+') no-repeat center center; background-size: contain; }\n'+
				'.pouet:hover .zorro { position: absolute; top: 5px; right: 5px; }\n'; // top et right pour remplacer le padding du .pouet.
		}
		
		// Heu tout de même l'état du JIRA c'est important…
		
		if(gira.etatVisibleAvecOutils) gira.etatVisible = window.setInterval(gira.etatVisible, 1000);
		else gira.etatVisible();
		
		pepere.fait = 1;
	},
	etatVisible: function()
    {
		//var bde = document.querySelector('[data-testid="issue.views.issue-base.context.status-and-approvals-wrapper.status-and-approval"]'); // Barre d'état. Bon en fait on laisse tomber car elle contient aussi les Actions (à quoi ça sert?) et quelques marges disgracieuses.
		var bdt = document.querySelector // Barre de tâches.
		(
			gira.etatVisibleAvecOutils
			? '[data-testid="issue.issue-view.views.issue-base.foundation.quick-add.quick-add-item.link-issue"],[data-testid="issue-view-foundation.quick-add.quick-add-items-compact.add-button-dropdown--trigger"]'
			: '[data-testid="issue-view-layout-templates-default.ui.foundation-content.foundation-content-wrapper"]'
		);
		if(!bdt) return;
		if(typeof gira.etatVisible == 'number') window.clearInterval(gira.etatVisible);
		
		if(gira.etatVisibleAvecOutils)
		{
			while(bdt.parentElement && bdt.parentElement.getAttribute('data-component-selector') != "jira.issue-view.issue-details.full-size-mode-column")
				bdt = bdt.parentElement;
			if(!bdt.parentElement) return;
		}
		document.querySelectorAll('[data-testid="issue.views.issue-base.foundation.status.resolution"],[data-testid="issue.views.issue-base.foundation.status.status-field-wrapper"]')
		.forEach(function(bde)
		{
			if(gira.etatVisibleAvecOutils)
				bdt.insertBefore(bde, bdt.childNodes[0]);
			else
				bdt.appendChild(bde);
		});
	},
	densifier: function()
	{
		// Densité de texte.
		
		// Recherche de la classe CSS en tête de tout le contenu.
		var unTitre = document.querySelector('[class^="css-"] h2[data-testid="issue.views.issue-base.common.description.label"]');
		var unTexte = document.querySelector('.is-comment [class^="css-"]');
		if(unTexte)
		{
			while(unTitre && !(unTitre.className && unTitre.className.match(/^css-/))) unTitre = unTitre.parentNode;
			if(unTexte) // Marcherait aussi avec unTitre finalement.
				gira.style.innerHTML +=
					'.'+unTexte.classList[0]+' p { line-height: 1.1 !important; letter-spacing: 0 !important; }\n'+
					'.'+unTexte.classList[0]+' { font-size: 9pt; }\n';
		}
		document.body.style.setProperty('--ds-font-body', '9pt sans-serif'); // Celui-là est paramétrable par une simple pseudo-prop du corps, ouf!, qui passe avant tout le fatras qu'ils ont définir par défaut.
		gira.style.innerHTML += '.code-block code[class*="language-"] { font-size: 9pt; line-height: 1; }\n';
		gira.style.innerText += 'img.emoji { max-height: 1em; max-width: 1em; font-size: 100%; }\n';
		
		// Les émoticônes c'est un plus mais pas au point de devoir bouffer une ligne de texte.
		
		// On chope la classe "privée" du conteneur.
		var uneReac = document.querySelector('[data-testid="issue-comment-base.ui.comment.reactions-container"]');
		if(uneReac)
		{
			uneReac = uneReac.parentNode;
			gira.style.innerHTML +=
				'.'+uneReac.classList[0]+' { position: absolute; bottom: 0; left: 0; opacity: 0.33; }\n'+
				'.'+uneReac.classList[0]+':hover { z-index: 2; opacity: 1; background: var(--ds-surface, white); }\n'+
				'.'+uneReac.previousSibling.classList[0]+' { z-index: 1; }'+
				'.'+uneReac.previousSibling.querySelector('h3').classList[0]+' { font-size: 80%; }';
		}
	},
	coupDeBarres: function()
	{
		// Tout ce qui traîne en permanence.
		
		gira.style.innerText +=
			'header[class^="css-"] { height: var(--topNavigationHeight); }\n'+
			'body { --topNavigationHeight: 3em; }\n'+
			'#jira-issue-header > div { min-height: unset; }\n';
		
		// Souci avec les --ds-space-100, -150, -200: ces abrutis le rendent configurable,
		// sauf qu'il est utilisé à la fois en marge verticale autour des différents champs de détail du Jira (on n'en veut pas),
		// et comme marge verticale entre titre et paragraphe, ou horizontale entre onglets (on veut en conserver un minimum).
		// Donc au lieu de les mettre à 0, on va les réduire (ça aide le texte), mais pour les menus à réduire encore plus on devra charcuter chirurgicalement.
		document.body.style.setProperty('--ds-space-300', '0.8em');
		document.body.style.setProperty('--ds-space-200', '0.6em');
		document.body.style.setProperty('--ds-space-150', '0.4em');
		document.body.style.setProperty('--ds-space-100', '0.2em');
		
		// Entre un bloc (Description) et son paragraphe, il utilise --ds-space-100 qui est vraiment trop court.
		// Là c'est l'élément qu'on corrige.
		var db = document.querySelector('form[role="presentation"] > div').classList[0]; // Début de bloc.
		gira.style.innerText +=
			'.'+db+' { margin-block-start: 1em; }\n'+
			'details .'+db+' { margin-block-start: 0; }\n';
		gira.style.innerText += '[role="tab"] { padding-left: 0.5em !important; padding-right: 0.5em !important; }\n';
	},
	/* Qu'est-ce que c'est que cette incitation à commenter sans même avoir lu les commentaires de nos prédecesseurs? */
	tourner7fois: function()
	{
		var commentaireFlottant = document.querySelector('[data-testid="issue.activity.comment"]');
		if(commentaireFlottant)
			commentaireFlottant.parentNode.parentNode.style.setProperty('position', 'static'); // Au lieu de sticky.
	},
	/* Les listes déroulantes ont un [max-]width: 100% qui prend trop de place une fois qu'on supprime le menu droite;
	 * donc visuellement déjà ça fait moche, mais pire: les suggestions du menu s'affichant à droite du menu lui-même, tombent hors page lorsque le menu prend toute la largeur! */
	deroulantes: function(css)
	{
		css.appendChild(document.createTextNode('.full-width { max-width: 512px; }'));
	},
	/* Le liant, c'est bien, mais le principe de l'hyperlien ça n'est pas d'être hyper alourdi par l'intégralité des infos de la page cible sur le lien */
	allegeEnLipides: function()
	{
		if(!gira.allegeEnLipides.classesEtatConnues) gira.allegeEnLipides.classesEtatConnues = {};
		
		// On repère les libellés qu'on saurait représenter par un simple code couleur.
		document.querySelectorAll('.smart-link-title-wrapper').forEach(function(titre)
		{
			if(!titre.innerText.includes(':')) return; // Déjà traité.
			
			titre.innerText = titre.innerText.replace(/:.*/, '');
			var classeEtat = titre.closest('a').lastChild.classList[0]; // Le cartouche d'état est le dernier bloc contenu dans le lien.
			if(!gira.allegeEnLipides.classesEtatConnues[classeEtat])
			{
				gira.allegeEnLipides.classesEtatConnues[classeEtat] = 1;
				gira.style.innerText += '.'+classeEtat+' > span > span { font-size: 70%; line-height: 1.5em; }\n';
			}
			
			/* À FAIRE?: transformer les Terminé par un trait rayant vert, Abandonné par un orange? */
			/* À FAIRE?: transformer les anos en un lien rouge, les évols en un lien vert, les besoins en un lien bleu? */
		});
	},
	/* Et pourquoi notre société considérerait-elle que les vieux sont sans intérêt et doivent être masqués?
	 * (bon d'accord ce ne sont que de vieux *commentaires*) */
	beguinage: function()
	{
		var plus = document.querySelector('[data-testid="issue.activity.common.component.load-more-button.loading-button"]');
		if(plus) plus.click();
	}
};

{
	var ints;
	var inst = function()
	{
		var tete = document.getElementsByTagName('head')[0];
		var gp = document.querySelector('.issue-body-content, [data-testid="issue.views.issue-details.issue-layout.container-left"]');
		if(gp) window.clearInterval(ints); else return;
		
		tete.insertAdjacentHTML('beforeend', '<style type="text/css">\n</style>');
		gira.style = tete.lastChild;
		
		/* Présentation */
		
		gira.densifier();
		// Eh merde, menudroite aussi doit être intervallé, car rechargé par Jira quand ça lui chante, dont une fois juste après le chargement de la page alors qu'on venait de le coller en menu à survol!
		gira.menudroite.re = window.setInterval(function() { gira.menudroite(); }, 200);
		gira.menudroite();
		gira.deroulantes(gira.style);
		gira.coupDeBarres();
		gira.tourner7fois();
		// Récurrent nécessaire, car d'une les liens sont enrichis et stylés en asynchrone, de deux ils peuvent apparaître après "Voir les commentaires + anciens".
		window.setInterval(gira.allegeEnLipides, 2000);
		
		/* Fonctionnalités */
		
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
		
		gira.beguinage();
	};
	
	ints = window.setInterval(inst, 1000);
	inst();
}
