// ==UserScript==
// @name      Mise en page bugs.freebsd.org
// @namespace http://outters.eu/
// @include   https://bugs.freebsd.org/*
// @grant     none
// ==/UserScript==

document.head.insertAdjacentHTML('beforeend', '<style type="text/css">.bz_comment_table .bz_comment_text { width: 100%; }</style>');
