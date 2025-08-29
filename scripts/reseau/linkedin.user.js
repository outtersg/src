// ==UserScript==
// @name      Embellificateur de LinkedIn
// @namespace http://outters.eu/
// @include   https://www.linkedin.com/jobs/*
// @grant     none
// ==/UserScript==

(
	function()
	{
		document.head.insertAdjacentHTML('beforeend', '<style type="text/css">[etat="Consulté"] { background: #dfdfff; } [etat="Enregistré"] { background: #dfffdf; } [etat] .job-card-list__insight { display: none; }</style>');
		
		var marquer = function()
		{
			var trouve = 0;
			document.querySelectorAll('.scaffold-layout__list-item:not([etat]):has(.job-card-container__footer-job-state)').forEach
			(
				function(x)
				{
					trouve = 1;
					x.setAttribute('etat', x.querySelector('.job-card-container__footer-job-state').innerText)
				}
			);
			return trouve;
		};
		var attente;
		attente = window.setInterval
		(
			function()
			{
				if(marquer())
				{
					window.clearInterval(attente);
					window.setInterval(marquer, 10000);
				}
			}
			, 500
		);
	}
)();
