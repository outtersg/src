// ==UserScript==
// @name         Stack Overflow en pleine largeur
// @namespace    http://outters.eu/
// @description  Mais pourquoi ces limites riquiqui?
// @include      https://stackoverflow.com/*
// @grant        none
// ==/UserScript==

document.head.insertAdjacentHTML('beforeend', '<style type="text/css">body > .container, #content { max-width: none!important; }</style>');
