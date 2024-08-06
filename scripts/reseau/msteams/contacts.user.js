// ==UserScript==
// @name         Pseudo Teams
// @namespace    http://outters.eu/
// @description  Purée permettez-moi de renommer mes contacts, surtout quand ils s'appellent tous "CAPGEMINI TECHNOLOGY SE…"!
// @grant        none
// @include      https://teams.microsoft.com/*
// ==/UserScript==

// Souci: https://feedbackportal.microsoft.com/feedback/idea/dccf7cc9-272e-ec11-b6e6-00224827bbc2

// Remplacements définis hors de la fonction, pour pouvoir être surchargés en temps réel et pris en compte par la prochaine passe de retaper().
unsafeWindow.retape =
{
	// Remplir ici les transformations à appliquer, sur le modèle de la suivante:
	"OUTTERS, GUILLAUME (Vous)": "Moi!",
	"OUTTERS, GUILLAUME": "Moi!"
};

var retapages =
[
	'.cle-title.truncate-name > .single-line-truncation', // Nom de conversation.
	'.app-participant-unit.single-line-truncation', // Interloc unique en tête d'une conversation passée en premier plan.
	'.app-participant-unit > span[pl-name]', // Interloc multiple en tête d'une conversation passée en premier plan.
	'.ui-chat__message__author > .ui-text', // Dans une conversation, auteur d'un message en particulier.
	'.ms-Persona > .ms-Persona-primaryText > .ms-TooltipHost', // Détail d'un nom de conversation "MACHIN +2"
	// v2
	'[data-tid="chat-list-item-title"]', // Nom de conversation
	'[id^="chat-topic-person"]', // Interloc en tête d'une conversation passée en premier plan.
	'[data-tid="message-author-name"]' // Dans une conversation, auteur d'un message en particulier.
	/* À FAIRE: dans le fil de conversation, sous son titre apparaît le dernier message qui commence par un "NOM, Prénom: Bla bla": on pourrait remplacer aussi ce NOM, Prénom. */
	// À FAIRE: pour les "a ajouté Untel à la conversation", j'ai un .bko, mais n'est-ce pas un nom de classe regénéré à chaque fois?
	// À FAIRE: pour les interpellations d'une personne dans une conversation, Teams découpe son nom en autant de liens que de mots :-( donc il faudrait repérer les blocs successifs et les remplacer.
];
retapages = retapages.join(', ');

var retaperUn = function(document)
{
	document.querySelectorAll(retapages).forEach(function(i)
	{
		if(i.dejaFait == i.innerHTML) return;
		i.dejaFait = i.innerHTML;
		
		var composite, r, icone;
		
		// Pour les conversations, le "NOM, Prénom, +2" n'est pas satisfaisant.
		// On va chercher la liste des participants dans l'icône "+ d'infos sur la conversation".
		if((icone = i.parentElement.parentElement.parentElement.querySelector('img[role="presentation"]')))
			if((icone = new URL(icone.src).searchParams.get('usersInfo')))
				if((icone = JSON.parse(icone)))
				{
					composite = [];
					for(var j = -1; ++j < icone.length;)
						composite.push(unsafeWindow.retape[r = icone[j].displayName] || r);
					// Condition: que le titre de conversation n'ait pas été personnalisé,
					// autrement dit qu'il commence par le premier participant.
					var prems = icone[0].displayName;
					if(i.innerHTML.substr(0, prems.length) != prems) return;
					r = composite.join(' / ');
				}
		
		if(!r) r = unsafeWindow.retape[i.innerHTML];
		if(!r && (composite = i.innerHTML.match(/,( \+[0-9]+)$/)) && (r = unsafeWindow.retape[i.innerHTML.replace(composite[0], '')]))
			r += composite[1];

		if(r) i.innerHTML = r;
	});
};

var retaper = function()
{
	retaperUn(document);
	// Sous GreaseMonkey 4, notre JS n'est pas automatiquement invoqué sur les iframes (même si l'URL respecte l'@include), à nous de nous appliquer aussi bien sur eux que sur le document principal.
	// https://stackoverflow.com/questions/37616818 dit que les iframe ne reçoivent pas les événements.
	// https://bleepingcoder.com/greasemonkey/259598810/execute-in-frames
	document.querySelectorAll('iframe').forEach(function(sousDoc) { retaperUn(sousDoc.contentDocument); });
};

(

	function()
	{
		// À FAIRE: détecter les changements pour mettre à jour plus rapidement.
		window.setInterval(retaper, 5000);
	}
)
();
