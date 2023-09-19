// ==UserScript==
// @name         RATP Prochain bus plein écran
// @namespace    http://outters.eu/
// @include      https://www.ratp.fr/horaires-bus*
// @grant        none
// ==/UserScript==

document.querySelectorAll('.page-header, header, .breadcrumbs, .ixxi-horaire-search-form, .ixxi-horaires-first-last, .ixxi-horaires-content h2, .ixxi-horaires-content .copyright, .ixxi-horaires-content .utils')
	.forEach(function(x) { x.setAttribute('style', 'display:none;'); });
document.body.setAttribute('style', 'margin-top: 0;');
var stylo = document.createElement('style');
stylo.textContent = '.ixxi-horaire-result-history { display: none; }';
document.head.appendChild(stylo);
