// ==UserScript==
// @name      Embellificateur HelloWork
// @namespace http://outters.eu/
// @include   https://www.hellowork.com/fr-fr/emplois/*
// @grant     none
// ==/UserScript==

var copierHelloWork = function()
{
	var d = new Date().toISOString().substr(0, 10);
	var titre = document.querySelector('h1');
	var poste = titre.querySelector('[data-cy="jobTitle"]').innerText;
	var boite = titre.querySelector('a[href*="/entreprises/"]').innerText;
	var ville = document.querySelector('ul.flex-wrap li').innerText; // La ville est le premier cartouche d'infos.
	var salaire = document.querySelector('[data-input-checker-input-value="#salaryModalInformation"] > span').innerText;
	poste = poste.replaceAll(/[\s-(]*(?:[HMFX](?:[-\/.][HMFX]){1,2})\)?/g, '');
	var resume =
		'- ['+boite+'] '+poste+' '+document.URL+' {'+d+'}'+"\n"
		+ville+"\n"
		+salaire
	;
	navigator.clipboard.writeText(resume);
};

(
	function()
	{
		copierHelloWork();
	}
)();
