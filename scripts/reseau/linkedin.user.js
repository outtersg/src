// ==UserScript==
// @name      Embellificateur de LinkedIn
// @namespace http://outters.eu/
// @include   https://www.linkedin.com/jobs/*
// @grant     none
// ==/UserScript==

var AttentisteUrl =
{
	attente: function()
	{
		if(AttentisteUrl.url != document.URL)
		{
			AttentisteUrl.url = document.URL;
			if(!AttentisteUrl.attenteH2.repet)
				AttentisteUrl.attenteH2.repet = window.setInterval(AttentisteUrl.attenteH2, 200);
			AttentisteUrl.attenteH2.compteur = 10;
			console.log('Embellificateur: attente ID (nouvelle URL: '+document.URL+')');
		}
	},
	attenteH2: function()
	{
		var urlId, bloc = document.querySelector('[data-view-name="job-detail-page"], .jobs-details');
		if
		(
			bloc
			&& bloc.querySelector('h2')
			&& (urlId = bloc.querySelector('a[href^="/jobs/view/"], a[href*="JobId="]'))
			&& (urlId = urlId.href.match(/(?:\/jobs\/view\/|JobId=)([0-9]{8,})/))
			&& (urlId = urlId[1]) != AttentisteUrl.attenteH2.dernierId
		)
		{
			console.log('Embellificateur: ID '+urlId);
			AttentisteUrl.attenteH2.dernierId = urlId;
			AttentisteUrl.attenteH2.compteur = 0;
			var d = new Date().toISOString().substr(0, 10);
			if(!localStorage.getItem('vu/'+urlId))
				localStorage.setItem('vu/'+urlId, new Date().toISOString().substr(0, 10));
			// On pousse vers le presse-papier une ligne de résumé de l'offre, au format de mes Notes:
			navigator.clipboard.writeText
			(
				'- '+bloc.querySelector('.job-details-jobs-unified-top-card__company-name').innerText
				+' '+bloc.querySelector('h1').innerText.replaceAll(/[\s-(]*(?:[HMF][-\/.][HMF])\)?/g, '')
				+' https://www.linkedin.com/jobs/view/'+urlId
				+' {'+d+'}'
			);
			/* À FAIRE: indicateur montrant que le presse-papier a été modifié */
			/* À FAIRE: utiliser le presse-papier secondaire (Maj-Insert)? */
		}
		if(--AttentisteUrl.attenteH2.compteur < 0)
		{
			window.clearInterval(AttentisteUrl.attenteH2.repet);
			delete AttentisteUrl.attenteH2.repet;
		}
	},
	url: null
};

/* On aurait voulu intercepter les changements d'URL.
* https://stackoverflow.com/a/4585031/1346819
* Cependant nous ne sommes jamais appelés.
* Tant pis, dans un premier temps on continuera à exploiter le setInterval plus bas.
(function(history){
var pushState = history.pushState;
history.pushState = function(state) {
urlChange();
return pushState.apply(history, arguments);
};
var replaceState = history.replaceState;
history.replaceState = function(state) {
urlChange();
return replaceState.apply(history, arguments);
};
})(window.history);
*/

(
	function()
	{
		document.head.insertAdjacentHTML('beforeend', '<style type="text/css">[etat="Consulté"] { background: #dfdfff; } [etat="Enregistré"] { background: #dfffdf; } [etat] .job-card-list__insight { display: none; }</style>');
		
		var marquer = function()
		{
			var trouve = 0;
			document.querySelectorAll('[data-job-id]:not([etat])').forEach
			(
				function(x)
				{
					trouve = 1;
					let etatAff = x.querySelector('.job-card-container__footer-job-state');
					let consult = localStorage.getItem('vu/'+x.dataset.jobId);
					if(etatAff) etatAff = etatAff.innerText;
					else if(consult) etatAff = 'Consulté';
					if(etatAff)
					{
						console.log('Embellificateur: '+x.dataset.jobId+' '+etatAff);
						x.setAttribute('etat', etatAff);
						/* À FAIRE: consult contient la date de première consultation. L'afficher. */
					}
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
					window.setInterval(marquer, 3000);
				}
			}
			, 500
		);
		window.setInterval(AttentisteUrl.attente, 3000);
		AttentisteUrl.attente();
	}
)();
