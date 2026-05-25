// ==UserScript==
// @name      Embellificateur de LinkedIn
// @namespace http://outters.eu/
// @include   https://www.linkedin.com/jobs/*
// @include   https://www.linkedin.com/comm/jobs/*
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
	niemeBlocApres: function(depart, filtre, n)
	{
		var suivant, candidats;
		if(typeof(n) == 'undefined')
			n = 1;
		while(n > 0 && depart)
		{
			if((suivant = depart.nextElementSibling))
			{
				if(suivant.matches(filtre))
					if(!--n)
						return suivant;
				if((candidats = suivant.querySelectorAll(filtre)).length >= n)
					return candidats[n - 1];
				n -= candidats.length;
				depart = suivant;
			}
			else
				depart = depart.parentElement;
		}
	},
	selBoutonsRonds: function(depart)
	{
		/* Peut-être suivre https://stackoverflow.com/questions/2952667/find-all-css-rules-that-apply-to-an-element?
		 * Bon en tout cas cette technique bourrin peut marcher. */
		var liste, i, faits = {}, res = '';
		while(depart && (liste = depart.querySelectorAll('a > span')).length < 5) // On cherche un bloc contenant au moins 5 boutons: inutile de remonter trop haut, mais dès qu'on a un bel échantillon c'est qu'on doit avoir le cartouche résumé de l'offre.
			depart = depart.parentElement;
		for(i = liste.length; --i >= 0;)
			if(!faits[liste[i].getAttribute('class')])
			{
				faits[liste[i].getAttribute('class')] = true;
				if(window.getComputedStyle(liste[i])['border-radius'].match(/[1-9][0-9]*px/))
				{
					if(res) res += ',';
					res += 'a > span[class="'+liste[i].getAttribute('class')+'"]';
				}
			}
		AttentisteUrl.selBoutonsRonds = res;
	},
	attenteH2: function()
	{
		var premier, urlId, bloc = document.querySelector('[data-view-name="job-detail-page"], .jobs-details, [data-sdui-screen="com.linkedin.sdui.flagshipnav.jobs.SemanticJobDetails"]');
		if
		(
			bloc
			//&& bloc.querySelector('h2') // Plus possible depuis la minification CSS du 23 mai 2026.
			&& (premier = bloc.querySelector('a[href*="/jobs/view/"], a[href*="JobId="]'))
			&& (urlId = premier.href.match(/(?:\/jobs\/view\/|JobId=)([0-9]{8,})/))
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
			var salaire = '';
			if(bloc.querySelector('h1')) premier = bloc.querySelector('h1');
			var ville = bloc.querySelector('.job-details-jobs-unified-top-card__primary-description-container .tvm__text');
			if(!ville)
				ville = AttentisteUrl.niemeBlocApres(premier, 'p').querySelector('span');
			var boutonsRonds = document.querySelectorAll('.job-details-fit-level-preferences button');
			if(!boutonsRonds.length)
			{
				if(typeof(AttentisteUrl.selBoutonsRonds) == 'function') AttentisteUrl.selBoutonsRonds(premier);
				boutonsRonds = document.querySelectorAll(AttentisteUrl.selBoutonsRonds);
			}
			boutonsRonds.forEach(function(x) { x = x.innerText.trim(); if(x.match(/€/)) salaire = "\n"+x; });
			navigator.clipboard.writeText
			(
				'- '+bloc.querySelector('.job-details-jobs-unified-top-card__company-name, a[href*="/company/"]').innerText
				+' '+premier.innerText.replaceAll(/[\s-(]*(?:[HMFX](?:[-\/.][HMFX]){1,2})\)?/g, '')
				+' https://www.linkedin.com/jobs/view/'+urlId
				+' {'+d+'}'
				+"\n"+ville.innerText.replace(/,.*/, '') // La ville est dans le premier bloc de blabla.
				+salaire
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
