var treo = [ /Transmis/, /En traitement/, /En attente/, /Résolu/ ];
var creo = [ [ 255, 127, 0 ], [ 255, 152, 25 ], [ 223, 223, 0 ], [ 143, 175, 0 ] ];
var freo = function(bloc)
{
	var rects = bloc.querySelectorAll('.highcharts-column-series .highcharts-point');
	var cols = {};
	var i, j, l, x, y, r, col, miny;
	for(i = rects.length; --i >= 0;)
	{
		r = rects[i];
		x = r.x.baseVal.valueAsString;
		if(typeof cols[x] == 'undefined')
			cols[x] = [];
		l = r.getAttribute('aria-label');
		for(j = -1; ++j < treo.length && !treo[j].match(l);) {}
		r.poids = j;
		r.setAttribute('fill', 'rgb('+creo[j].join(',')+')');
		cols[x].push(r);
	}
	for(col in cols)
	{
		col = cols[col];
		if(col.length < 1) continue;
		col.sort(function(a, b) { return b.poids - a.poids; }); // Ordre inverse, les y les plus faibles étant l'état le plus final.
		miny = col[0].y.baseVal.value;
		for(i = 0; ++i < col.length;)
			if((y = col[0].y.baseVal.value) < miny)
				miny = y;
		for(y = miny, i = -1; ++i < col.length;)
		{
			col[i].setAttribute('y', y);
			y += col[i].height.baseVal.value;
		}
	}
};

document.querySelectorAll('.highcharts-series-group').forEach(freo);
