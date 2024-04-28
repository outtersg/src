// ==UserScript==
// @name         Gitlab: Robot d'Enrichissement des Collages
// @namespace    http://outters.eu/
// @description  Enrichissement des copier-coller dans Gitlab
// @include      https://gitlab.…/*
// @grant        none
// ==/UserScript==

(function(){

var rempls =
{
	'\\*([0-9]+)': '[*$1](https://bugzilla.…/show_bug.cgi?id=$1)'
};

var remplacer = function(e, t0, t1)
{
	var v = e.value, pos = e.selectionStart;
	if(pos >= t0.length)
	{
		if(v.substr(pos - t0.length, t0.length) == t0)
			e.value = v.substr(0, pos - t0.length)+t1+v.substr(pos);
			// Et va comprendre pourquoi, Firefox arrive à repositionner le curseur tout bien comme il faut après la partie rallongée!
	}
};

var coller = function(e)
{
	var t, t0;
	if((t = t0 = e.clipboardData.getData('text/plain')))
	{
		for(expr in rempls)
			if(t.match(expr))
				t = t.replace(new RegExp(expr), rempls[expr]);
		if(t != t0)
			window.setTimeout(function() { remplacer(descr, t0, t); }, 0);
	}
};

var descr = document.getElementById('merge_request_description');
if(descr)
{
	descr.addEventListener('paste', coller, true);
}

})();
