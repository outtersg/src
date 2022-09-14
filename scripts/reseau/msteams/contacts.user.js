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
	'.ms-Persona > .ms-Persona-primaryText > .ms-TooltipHost'
	// À FAIRE: pour les "a ajouté Untel à la conversation", j'ai un .bko, mais n'est-ce pas un nom de classe regénéré à chaque fois?
	// À FAIRE: pour les interpellations d'une personne dans une conversation, Teams découpe son nom en autant de liens que de mots :-( donc il faudrait repérer les blocs successifs et les remplacer.
];
retapages = retapages.join(', ');

var retaperUn = function(document)
{
	document.querySelectorAll(retapages).forEach(function(i)
	{
		// À FAIRE: marquer l'élément comme déjà retapé, histoire d'éviter de repasser dessus.
		if(unsafeWindow.retape[i.innerHTML]) i.innerHTML = unsafeWindow.retape[i.innerHTML];
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
		window.setInterval(retaper, 20000);
	}
)
();
