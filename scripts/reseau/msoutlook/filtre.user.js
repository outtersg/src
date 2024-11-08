// ==UserScript==
// @name         Filtrage JS
// @namespace    http://outters.eu/
// @description  Ces gros débiles de MS virent le support VBA, ne proposent pas de remplacement JS, mais n'ont même pas songé à offrir un filtre "l'objet est exactement blabla".
// @grant        none
// @include      https://outlook.office.com/*
// ==/UserScript==

/* À FAIRE: défiler tout seul pour aller chercher les vieux messages */
/* À FAIRE: parfois il bute aussi le message suivant: emmêlage si une tâche n'avait pas fini? */

var Dests =
{
	p: 'Éléments supprimés',
	…
};

var Règles = function(objet, émetteur)
{
	switch(objet)
	{
		case …: return Dests.p;
	}
};

(
function()
{
	/*- Utilitaires génériques -----------------------------------------------*/
	
	/**
	 * Renvoie un objet attendeur, dont la fonction attendre() scrutera selon un test, et appellera en cas de succès une fonction adjointe a posteriori à l'objet.
	 * Ex.:
	 *   var attente = attendre(function() { return document.querySelector('.toto'); }, 5000);
	 *   attente.f = function(trouvaille) { console.log('trouvé '+trouvaille.innerText); };
	 *   attente.attendre();
	 */
	var attendre = function(test, maxims)
	{
		if(!maxims) maxims = 5000;
		var freq = 50;
		var attente =
		{
			reste: maxims / freq,
			tentation: test,
			attendre: function()
			{
				attente.attente = window.setInterval(attente.tenter, freq);
			},
			tenter: function()
			{
				var r = attente.tentation();
				if(!r && --attente.reste > 0) return;
				window.clearInterval(attente.attente);
				if(r && attente.f)
					attente.f(r);
				else if(attente.ferr)
					attente.ferr();
				else
					console.log(r ? '# attendre(): pas de fonction à appeler' : '# attendre(): attente expirée');
				return r;
			}
		};
		
		return attente;
	};
	
	var puis = function(cond, f, ferr, interne)
	{
		var promesse =
		{
			puis: function(cond, f)
			{
				var suite = puis(cond, f, ferr, true);
				promesse.suite = suite.déclencher;
				return suite;
			}
		};
		var fe = function(x) // Fonction Encapsulée.
		{
			f(x);
			if(promesse.suite)
				promesse.suite();
		};
		promesse.déclencher = function()
		{
			if(typeof cond === 'number')
				window.setTimeout(fe, cond);
			else if(typeof cond == 'object' && cond.attendre)
			{
				cond.f = fe;
				if(ferr)
					cond.ferr = ferr;
				cond.attendre();
			}
		};
		if(!interne)
			promesse.déclencher();
		return promesse;
	};
	
	/*- Initialisation -------------------------------------------------------*/
	
	// Ensemble de classes CSS porté par les <span> où figure l'objet du mél.
	var classeObjet = '';
	var classesExpéditeur = [];
	var sélecteurObjet;
	var sélecteurExpéditeur;
	
	var info = function(m)
	{
		console.log('Filtrage JS: '+m);
	};
	
	// Détermination de l'association de classes désignant l'objet.
	// On sait qu'objet et émetteur ont tous deux un title, toujours vide pour l'objet, et comportant l'adrél pour l'émetteur, mais uniquement lorsque l'adrél a pu être interprétée et validée par Outlook.
	var détection = function()
	{
		var classes = {};
		var nobles = document.querySelectorAll('div[class] > span[title]');
		nobles.forEach(function(noble)
		{
			var noblesse = noble.getAttribute('title');
			var typos, typo;
			if(noblesse === '')
				typos = { 'adrél': 1, 'objet': 1 }; // En fait "soit une adrél, soit un objet".
			else if(/@/.test(noblesse))
				typos = { 'adrél': 1 };
			if(undefined === typos) return;
			
			var classe = noble.parentNode.getAttribute('class');
			if(undefined === classes[classe]) classes[classe] = {};
			for(typo in typos)
				classes[classe][typo] = (undefined === classes[classe][typo] ? 0 : classes[classe][typo]) + typos[typo];
		});
		var classe, nObjets = 0, nAdrels = 0;
		// Les objets ont toujours la même classe, tandis que les adréls changent selon que le mél est lu ou non.
		// En outre les assimilés objet peuvent être des adréls vides.
		// On repère donc tout d'abord le groupe de classes le plus donné, qui devrait désigner les objets.
		for(classe in classes)
			if(classes[classe].objet == classes[classe].adrél && classes[classe].objet > nObjets)
				nObjets = classes[classe].objet;
		if(!nObjets) return info('Impossible de repérer les objets de mél');
		for(classe in classes)
			if(classes[classe].objet == classes[classe].adrél && classes[classe].objet == nObjets)
			{
				if(classeObjet) return info('Ouille, plusieurs libellés pourraient porter les objets de mél');
				classeObjet = classe;
			}
			else
			{
				nAdrels += classes[classe].adrél;
				classesExpéditeur.push(classe);
			}
		if(nAdrels != nObjets) return info('Je ne trouve '+nObjets+' objets de mél pour '+nAdrels+' expéditeurs');
		
		info('Éléments des méls repérés');
		
		return classeObjet;
	}
	
	var destinations = function()
	{
		var d, é;
		for(d in Dests)
		{
			if(typeof(Dests[d]) == 'string')
			//querySelectorAll('[draggable]')
			// https://stackoverflow.com/a/37098628
			if(!(é = document.evaluate('//span[text()="'+Dests[d]+'"]', document, null, XPathResult.ANY_TYPE, null).iterateNext())) return info('Boîte "'+d+'" introuvable');
			// Le remplacement suivant était destiné au glisser-déposer. Mais comme on ne sait pas le faire marcher, le fonctionnement par menu contextuel nous fait garder le simple libellé.
			//Dests[d] = é;
		}
		
		info('Destinations repérées');
		return true;
	};
	
	var menu = function(nom)
	{
		var r;
		// Le menu premier niveau est en itemText; le second niveau est un gros foutoir de div et span (pour avoir des jolies icônes?).
		document.querySelectorAll('.ms-ContextualMenu-itemText, .ms-ContextualMenu-item div span').forEach(function(x) { if(x.innerText == nom && !r) r = x; });
		return r;
	};
	
	var souris = function(cible, quoi)
	{
		var ops =
		{
			click:
			[
				{ op: 'mouseover' },
				{ op: 'mousedown' },
				{ op: 'mouseup' },
				{ op: 'click' }
			],
			contextmenu:
			[
				{ op: 'mouseover', opts: { button: 2 } },
				{ op: 'mousedown', opts: { button: 2 } },
				{ op: 'mouseup', opts: { button: 2 } },
				{ op: 'contextmenu', opts: { button: 2 } }
			],
			mouseover:
			[
				{ op: 'mouseover' }
			]
		};
		
		var op = ops[quoi];
		if(!op) op = [ { op: op } ];
		
		for(var i = -1; ++i < op.length;)
		{
			var opts = { view: window, bubbles: true, cancelable: true };
			if(op[i].opts)
				for(var opt in op[i].opts)
					opts[opt] = op[i].opts[opt];
			var ev = new MouseEvent(op[i].op, opts);
			cible.dispatchEvent(ev);
		}
	};
	
	var àFaire = [], faire1;
	
	/* À FAIRE: vérifier qu'on est toujours sur la bonne BàL, aussi bien dans tourner qu'à chaque étape de faire1. */
	
	var tourner = function()
	{
		// On ne fait rien si on tourne encore sur la détection précédente.
		if(àFaire.length) return;
		
		var bal;
		document.querySelectorAll('span.screenReaderOnly').forEach(function(x)
		{
			if(x.innerText == 'sélectionné')
				bal = x.parentNode.querySelector('div > span').innerText;
		});
		
		document.querySelectorAll('[title="Marquer comme lu"]').forEach(function(x)
		{
			// On remonte à l'élément englobant le message.
			// data-animatable est trop haut, car dans le cas du premier message d'un bloc "Reçus le mois dernier", il se trouve non sur le message mais sur un <div> regroupant le titre "Le mois dernier" et le premier message lui-même :-(
			// draggable est un coup trop bas (c'est peut-être lui qu'il faudrait cibler pour déplacer par glisser-déposer?)
			// aria-selected est pile au bon niveau (celui qui possède tous les attributs dont pour aria-label une grosse concaténation des champs indexés affichés: état, expéditeur, objet, début du message).
			while((x = x.parentNode) && x.getAttribute && !x.getAttribute('aria-selected')); if(!x) return;
			// Une évolution d'Outlook ajoute un second bouton "Marquer comme lu" (la barre bleue à gauche n'étant pas évidente).
			// On s'assure donc de ne pas ajouter deux fois le même bloc.
			if(àFaire.length > 0 && àFaire[àFaire.length - 1].bloc == x) return;
			var objet = x.querySelector(sélecteurObjet).innerText;
			var expé = x.querySelector(sélecteurExpéditeur);
			var dest = Règles(objet, expé);
			if(dest && dest != bal)
			{
				x.children[0].children[0].style = 'background: #ffffbf;';
				var de = x.querySelectorAll('span[title]')[1]; // Le [0] est l'expéditeur, le [1] le titre.
				àFaire.push({ de: de, vers: dest, objet: objet, bloc: x });
			}
		});
		
		faire1();
	};
	
	var attendreMenu = function(libelléMenu, maxims)
	{
		return attendre(function() { return menu(libelléMenu); }, maxims);
	};
	
	var attenteLuOuNon = function(bloc)
	{
		return attendre(function() { return bloc.querySelector('[title="Marquer comme non lu"], [title="Marquer comme lu"]'); });
	};
	
	var tantPis = function() { àFaire = []; info('# Impossible d\'aller au bout, on retentera plus tard.'); };
	
	faire1 = function()
	{
		if(!àFaire.length) return;
		
		var e = àFaire.pop(); // On part de la fin, ne sachant pas si retirer les premiers ne va pas tout décaler et faire sauter nos suivants.
		var de = e.de, dest = e.vers, objet = e.objet;
		
		/* NOTE: marquage non lu
		 * Le dépliement du menu déroulant est considéré comme un clic: au bout de quelques secondes, Outlook considérera le message comme lu.
		 * Or notre filtre travaille uniquement sur les non lus: si la suite des opérations foire, le message, lu, ne sera pas retenté.
		 * On force donc son passage à lu puis re à non lu, pour en garantir l'état.
		 */
		/* Bon finalement le menu déroulant marche tout aussi bien sans clic préalable; de plus il évite de s'embarrasser de déselection en cas de souci. */
		/*
		souris(de, 'clic');
		puis(attenteLuOuNon(e.bloc), function(lecteur)
		{
			souris(lecteur, 'click');
		}, tantPis)
		.puis(attenteLuOuNon(e.bloc), function(lecteur)
		{
			if(lecteur.getAttribute('title') == 'Marquer comme non lu')
				souris(lecteur, 'click');
		}, tantPis)
		.puis(attendre(function() { return true; }), function()
		{
				souris(de, 'contextmenu');
		}, tantPis)
		.puis(attendreMenu('Déplacer', 1000), function(menu)
		*/
		souris(de, 'contextmenu');
		var attente =
		puis(attendreMenu('Déplacer', 1000), function(menu)
		{
				souris(menu, 'mouseover');
		}, tantPis)
		.puis(attendreMenu('Déplacer vers un autre dossier...', 1000), function(menu)
		{
				souris(menu, 'click');
		}, tantPis)
		.puis(attendreMenu(dest, 1000), function(menu)
		{
				souris(menu, 'click');
				info(objet+' → '+dest);
		}, tantPis)
		.puis(0, function()
		{
			var sel = document.querySelector('[aria-selected=true] [title="Marquer comme lu"]');
			if(sel)
				attente = attente.puis(10, function()
				{
					var coche = document.querySelector('[aria-selected=true] :is([aria-label="Sélectionner une conversation"],[aria-label="Sélectionner un message"])');
					souris(coche, 'click');
					souris(coche, 'click');
				});
			attente
		.puis(200, faire1);
		});
	};
	
	var installer = function()
	{
		if(!classeObjet && !détection()) return;
		if(!destinations()) return;
		// La barre d'outils à laquelle se greffer.
		// On ne peut directement taper headerButtonsRegionId ni même un de ses fils (ex.: owaSettingsBtn_container),
		// car ils apparaissent brièvement puis sont supprimés pour être regénérés, cette fois avec tous les outils standard.
		// Si on s'est greffé à la première instance on perd notre bouton.
		// On s'insère donc de façon violente sous une icône plus générale mais stable.
		var barre = document.getElementById('O365_MainLink_Me');
		if(!barre || !(barre = barre.parentElement)) return;
		
		window.clearInterval(scrutateur);
		
		sélecteurObjet = '.'+classeObjet.replaceAll(/ +/g, '.')+' [title]';
		sélecteurExpéditeur = classesExpéditeur.map(x => '.'+x.replaceAll(/ +/g, '.')+' [title]').join(', ');
		
		var lf = document.createElement('span'); // Lanceur Filtrage.
		lf.className = barre.children[0].className+' monBouton';
		lf.innerText = 'Filtrage auto';
		lf.onclick = lancer;
		barre.appendChild(lf);
		
		var st = document.createElement('style');
		st.setAttribute('type', 'text/css');
		st.innerText = '.monBouton { color: white; cursor: pointer; padding: 0 1em 0 1em; } .monBouton:hover { background: #bfbf9f; color: #df7f00; } #CenterRegion { width: auto !important; }';
		document.head.appendChild(st);
	};
	
	var lancer = function()
	{
		var masque = document.createElement('div');
		masque.style = 'position: absolute; width: 100%; height: 100%; left: 0; top: 0; background: white; opacity: 50%;';
		document.body.appendChild(masque);
		var rien = function(e) { e.stopPropagation(); e.preventDefault(); };
		[ 'contextmenu','mousemove','mouseover','mouseout','mouseenter','mouseleave','mousedown','mouseup','click','visibilitychange' ].forEach
		(
			function(quoi) { masque.addEventListener(quoi, rien); }
		);
		
		tourner();
		window.setInterval(tourner, 5000);
	};
	var scrutateur = window.setInterval(installer, 1000);
}
)
();
