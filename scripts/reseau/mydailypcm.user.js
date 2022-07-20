// ==UserScript==
// @name         My Daily PCM
// @namespace    http://outters.eu/
// @description  Après chaque action, colle les réponses dans le presse-papiers.
// @include      https://my.dailypcm.com/questionnaire/*
// @grant        none
// ==/UserScript==

// Sur clic, sans quoi Firefox braille qu'on tente de copier sans interaction utilisateur préalable.
document.body.addEventListener('click', function(e)
{
	var t = [ document.querySelector('h2').innerText ];
	document.querySelectorAll('.answerGreen label').forEach(function(x, i) { t.push((i + 1)+'. '+x.innerText); });
	document.querySelectorAll('.answersUnselected .answer label').forEach(function(x, i) { t.push('-. '+x.innerText); });
	navigator.clipboard.writeText(t.join("\n")+"\n\n");
});
