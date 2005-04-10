# Compose un CN de certificat serveur multi-fqdn façon Netscape. Ex.:
# smtp.domaine.net,imap.domaine.net devient (smtp|imap).domaine.net
cnCertifNetscape()
{
	echo "$1" | awk '{if((numNom=split($0,noms,/,/))<=1)print $0;else{numCommuns=split(noms[1],blocs,/\./);for(i=-1;++i<numCommuns;)communs[i+1]=blocs[numCommuns-i];restes[1]="";while(numNom>1){n=split(noms[numNom],blocs,/\./);synchro=1;for(i=0;++i<=numCommuns;--n)if(n<1||communs[i]!=blocs[n]){for(c=i;c<=numCommuns;++c){r2=communs[c]"."r2;delete communs[c];}numCommuns=i-1;for(ancien in restes)restes[ancien]=r2""restes[ancien];break}while(n>=1){reste=blocs[n]"."reste;--n}restes[numNom--]=reste}for(i in restes)if(length(restes[i]))oui=1;else vraiment=1;if(oui&&vraiment){for(i in restes)restes[i]=restes[i]communs[numCommuns];delete communs[numCommuns];--numCommuns}else for(i in restes)sub(/\.$/,"",restes[i]);if(oui){c=").";for(i in restes){r=restes[i]""c""r;c="|"}r="("r};r2=communs[1];delete communs[1];for(i in communs)r2=communs[i]"."r2;print r""r2}}'
}

# Génère un certificat, en recréant si nécessaire toutes les étapes
# intermédiaires (clé, requête, certificat, PKCS#12).
nouveauCertif()
{
	DONNEES=
	DATES=
	while [ $# -gt 0 ] ; do
		case "$1" in
			*)
				for i in DONNEES DATES ; do
					if eval test -z \$$i ; then
						eval $i=\""$1"\"
						break
					fi
				done
				;;
		esac
		shift
	done
}
