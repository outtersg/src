// ==UserScript==
// @name      DrawIo
// @namespace http://outters.eu/
// @match    https://app.diagrams.net/*
// @grant    none
// ==/UserScript==

var DrawIo =
{
	brancher: function()
	{
		// Les éléments de menu sont construits dynamiquement. On les chope donc à la première ouverture.
		let attraper = function()
		{
			document.querySelectorAll('.mxPopupMenuItem').forEach(function(x)
			{
				if(/Périph/.test(x.innerText))
				{
					document.querySelector('.geMenubar').appendChild(x);
					window.clearInterval(DrawIo.brancher);
				}
			});
		};
		DrawIo.brancher = window.setInterval(attraper, 1000);
	}
};

(function() { DrawIo.brancher(); })();
