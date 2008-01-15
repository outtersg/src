# -*- coding: utf-8 -*-
import sys
import email
from email import Header
import locale
import os

def decoder(enTete):
	bouts = []
	for texte,encodage in email.Header.decode_header(enTete):
		bouts.append(texte.decode(encodage or 'latin1'))
	return ' '.join(bouts)

sys.stdout.write(decoder(sys.argv[1]).encode('utf-8')+"\n")
