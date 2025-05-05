// ==UserScript==
// @name      Interface Zyxel
// @namespace http://outters.eu/
// @include   http://192.168.0.1/login
// @grant     none
// ==/UserScript==

// Sur http://192.168.0.1/CellWanStatus, pour voir de loin:
// Array.from(document.querySelectorAll('.title')).filter(x => x.textContent == 'RSRP (dBm)')[0].parentNode.querySelector('.content').style = 'font-size: 3200%; color: black;'; 

(
	function()
	{
		/* Foutue interdiction de laisser Firefox enregistrer le mot de passe! */
		
		var attente;
		attente = window.setInterval
		(
			() =>
			{
				var l = document.querySelectorAll('[autocomplete="off"]');
				if(!l.length) return;
				
				window.clearInterval(attente);
				
				// Un vrai champ MdP pour faire jouer le trousseau Firefox.
				document.getElementById('username').insertAdjacentHTML('afterend', '<input type="password" id="vraimdp" name="userpassword"></input>');
				// Bon et pour recopier apparemment la fonction doit être incluse à la page, non pas définie dans GreaseMonkey.
				var s = document.createElement('script');
				s.type = "text/javascript";
				s.text = `
					function copier()
					{
						var e = new ClipboardEvent('paste', {});
						e.clipboardData.setData('text/plain', document.getElementById('vraimdp').value);
						document.getElementsByClassName('maskPassword')[0].dispatchEvent(e);
					}
					window.setTimeout(copier, 200);
				`;
				document.body.appendChild(s);
			}
			, 500
		);
	}
)();
