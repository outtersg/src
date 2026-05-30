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
	
	// Un petit cartouche pour indiquer la bonne prise en compte.
	resume = resume.replace("\n", '<br/>'); // À FAIRE: < & >
	document.body.insertAdjacentHTML('beforeend', '<div id="copie" style="position: absolute; top: 5px; right: 5px; border: 1px solid #003f00; padding: 10px; background: #bfffbf;"><div>'+resume+'</div><div>(copié)</div></div>');
	var copie = document.getElementById('copie');
	window.setTimeout(function() { copie.remove(); }, 5000);
};

(
	function()
	{
		copierHelloWork();
	}
)();
