import re
import sys
import unicodedata

despec = re.compile('&#x....;')
sorteur = re.compile('output="([^"]*)"')

while 1:
	ligne = sys.stdin.readline()
	if not ligne:
		break
	contenu = sorteur.search(ligne)
	if contenu:
		chaine = contenu.group(1)
		res = despec.search(chaine)
		if res:
			compo = unicode('')
			pos = 0
			while res:
				compo = compo+ligne[pos:res.start()]+unichr(int(res.group(0)[3:7], 16))
				pos = res.end()
				res = despec.search(chaine, pos)
			compo = unicodedata.normalize(sys.argv[1], compo+chaine[pos:])
			res = ''
			for car in compo:
				res = res+'&#x%4.4x;'%ord(car)
			sys.stdout.write(ligne[0:contenu.start(1)]+res+ligne[contenu.end(1):])
		else:
			sys.stdout.write(ligne)
	else:
		sys.stdout.write(ligne)
