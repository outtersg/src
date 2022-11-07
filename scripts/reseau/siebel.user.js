// ==UserScript==
// @name         Siebel Open UI
// @namespace    http://outters.eu/
// @description  Adapte l'affichage d'un Siebel Open UI.
// @include      https://…/*
// @grant        none
// ==/UserScript==

(function(){

setInterval
(
	function()
	{
		/* Si les listes savent s'adjoindre une barre de défilement horizontale,
		 * les panneaux de détail, eux, sont parfois idiotement tronqués quand trop larges.
		 */
		var l = 0;
		document.querySelectorAll('.AppletBack').forEach(function(x)
		{
			if(l < x.clientWidth)
				l = x.clientWidth;
		});
		document.getElementById('_swecontent').setAttribute('style', 'min-width: '+(l + 24)+'px;');
	}
	, 5000
);

})();
