// ==UserScript==
// @name         Filtrage JS
// @namespace    http://outters.eu/
// @description  Ces gros débiles de MS virent le support VBA, ne proposent pas de remplacement JS, mais n'ont même pas songé à offrir un filtre "l'objet est exactement blabla".
// @grant        none
// @include      https://outlook.office365.com/*
// ==/UserScript==

/* À FAIRE: un cadre translucide pour empêcher les interférences de la vraie souris */
/* À FAIRE: défiler tout seul pour aller chercher les vieux messages */
/* À FAIRE: sur demande (consacrer un onglet à ce tri mais permettre de naviguer ailleurs sans interférence) */
/* À FAIRE: parfois il bute aussi le message suivant: emmêlage si une tâche n'avait pas fini? */
/* À FAIRE: ne pas marquer lu */

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
		if(bal != 'Boîte de réception') return;
		
		document.querySelectorAll('[title="Marquer comme lu"]').forEach(function(x)
		{
			while((x = x.parentNode) && x.getAttribute && !x.getAttribute('data-animatable')); if(!x) return;
			var objet = x.querySelector(sélecteurObjet).innerText;
			var expé = x.querySelector(sélecteurExpéditeur);
			var dest = Règles(objet, expé);
			if(dest)
			{
				x.children[0].children[0].children[0].style = 'background: #ffffbf;';
				var de = x.querySelectorAll('[title]')[2]; // Surtout pas le [0], qui est le marqueur "lu / non lu"; le 1 est l'expéditeur, le 2 le titre.
				àFaire.push({ de: de, vers: dest, objet: objet });
			}
		});
		
		faire1();
	};
	
	var attendreMenu = function(libelléMenu, maxims)
	{
		return attendre(function() { return menu(libelléMenu); }, maxims);
	};
	
	var tantPis = function() { àFaire = []; info('# Impossible d\'aller au bout, on retentera plus tard.'); };
	
	faire1 = function()
	{
		if(!àFaire.length) return;
		
		var e = àFaire.pop(); // On part de la fin, ne sachant pas si retirer les premiers ne va pas tout décaler et faire sauter nos suivants.
		var de = e.de, dest = e.vers, objet = e.objet;
		
				souris(de, 'contextmenu');
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
				info(objet+' → '+dest.innerText);
		}, tantPis)
		.puis(500, faire1);
	};
	
	var installer = function()
	{
		if(!classeObjet && !détection()) return;
		if(!destinations()) return;
		
		window.clearInterval(scrutateur);
		
		sélecteurObjet = '.'+classeObjet.replaceAll(/ +/g, '.')+' [title]';
		sélecteurExpéditeur = classesExpéditeur.map(x => '.'+x.replaceAll(/ +/g, '.')+' [title]').join(', ');
		
		tourner();
		window.setInterval(tourner, 10000);
	};
	var scrutateur = window.setInterval(installer, 1000);
}
)
();
