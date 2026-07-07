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
  /* Chope le cartouche porteur de l'état d'une offre (Consulté, Enregistré, etc.) */
	etatiste: function(el)
	{
		let classe;
		switch(1)
		{
			case 1:
			if((classe = AttentisteUrl.classeEtat)) break;
			if(el.querySelector(classe = '.job-card-container__footer-job-state')) break; // Avant mai 2026, tout était simple.
			/* Après mai 2026, ça devient compliqué.
			 * On peut se raccrocher au fait que l'état est le premier de plusieurs cartouches: Consulté - il y a x jours - Candidature simplifiée
			 * Le "il y a est (quasi?) toujours présent. De plus, pour l'accessibilité (pour expliciter ce qu'il s'est passé il y a x jours), il est décliné en deux versions: <span aria-hidden="true">il y a x jours</span><span>Publié il y a x jours</span>
			 */
			let cartouchier, etatiste;
			el.querySelectorAll('span[aria-hidden="true"]').forEach(function(x) { if(x.innerText.match(/^il y a/)) cartouchier = x.closest('div'); });
			if(cartouchier && (etatiste = cartouchier.querySelector('p')) && etatiste.innerText.match(/^(Consulté|Enregistré)/))
				classe = '.'+etatiste.getAttribute('class').replaceAll(' ', '.'); // Foutoir à la je ne sais quelle biblio de ponte utilise LinkedIn; on prend tout, a priori ça sera toujours les mêmes, pas la peine de chercher "la classe CSS qui distingue des autres cartouches".
		}
		if(classe) AttentisteUrl.classeEtat = classe;
		if(AttentisteUrl.classeEtat) return el.querySelector(AttentisteUrl.classeEtat);
	},
	/* Renvoie l'identifiant d'annonce LinkedIn. */
	id: function(el)
	{
		let id, id2;
		if(el.dataset.jobId) return el.dataset.jobId;
		if((id = el.getAttribute('componentkey')) && (id2 = id.replace(/^job-card-component-ref-/, '')) != id) return id2;
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
			boutonsRonds.forEach(function(x) { x = x.innerText.trim(); if(x.match(/[1-9][0-9].*€/)) salaire = "\n"+x; }); // "Essayer Premium pour 0 €" n'est pas un salaire.
			let boite;
			bloc.querySelectorAll('.job-details-jobs-unified-top-card__company-name, a[href*="/company/"]').forEach(function(x) { if(x.innerText && !boite) boite = x.innerText; }); // Parfois le premier bloc "boîte" n'est que l'icône SVG, sans contenu textuel; il faut attendre le second pour tomber sur la boîte (et ne pas aller plus loin, sinon on récupère "Voir plus" comme nom de boîte).
			navigator.clipboard.writeText
			(
				'- '+boite
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
			// document.querySelectorAll('[componentkey="SearchResultsMainContent"] > [data-display-contents="true"]')
			document.querySelectorAll('[data-job-id]:not([etat]), [componentkey^="job-card-component-ref-"][role="button"]:not([etat])').forEach
			(
				function(x)
				{
					trouve = 1;
					let etatAff = AttentisteUrl.etatiste(x);
					let consult = localStorage.getItem('vu/'+AttentisteUrl.id(x));
					if(etatAff) etatAff = etatAff.innerText;
					else if(consult) etatAff = 'Consulté';
					if(etatAff)
					{
						console.log('Embellificateur: '+AttentisteUrl.id(x)+' '+etatAff);
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
