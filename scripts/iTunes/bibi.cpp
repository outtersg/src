/*
 * testSAX.c : a small tester program for parsing using the SAX API.
 *
 * See Copyright for the status of this software.
 *
 * daniel@veillard.com
 */

#include <libxml/SAX.h>

#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#ifdef HAVE_SYS_TIMEB_H
#include <sys/timeb.h>
#endif
#ifdef HAVE_TIME_H
#include <time.h>
#endif

#ifdef LIBXML_SAX1_ENABLED
#include <string.h>
#include <stdarg.h>

#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#ifdef HAVE_STRING_H
#include <string.h>
#endif

#include <vector>
#include <string>
#include <map>

#include <libxml/globals.h>
#include <libxml/xmlerror.h>
#include <libxml/parser.h>
#include <libxml/parserInternals.h> /* only for xmlNewInputFromFile() */
#include <libxml/tree.h>
#include <libxml/debugXML.h>
#include <libxml/xmlmemory.h>

/*- Compo --------------------------------------------------------------------*/

class Compo
{
	public:
		virtual void entrer();
		virtual void * entrerDans(void * depuis, const xmlChar * nom, const xmlChar ** attributs);
		virtual void contenuPour(void * objet, const xmlChar * contenu, int taille);
		virtual void sortirDe(void * object);
		virtual void sortir();
};

void Compo::entrer() {}
void * Compo::entrerDans(void * depuis, const xmlChar * nom, const xmlChar ** attributs) { return NULL; }
void Compo::contenuPour(void * objet, const xmlChar * contenu, int taille) {}
void Compo::sortirDe(void * object) {}
void Compo::sortir() {}

/*- Chargeur -----------------------------------------------------------------*/

class Chargeur
{
	public:
		Compo * courant();
		void charger(char * chemin, const xmlChar * nomRacine, Compo * traiteurRacine);
		void entrer(void * ctx ATTRIBUTE_UNUSED, const xmlChar * nom, const xmlChar * prefixe, const xmlChar * uri, int nEnsembles, const xmlChar ** ensembles, int nAttributs, int nAttrParDefaut, const xmlChar ** attributs);
		void contenu(void * ctx ATTRIBUTE_UNUSED, const xmlChar * chaine, int taille);
		void sortir(void * ctx ATTRIBUTE_UNUSED, const xmlChar * nom, const xmlChar * prefixe, const xmlChar * uri);
		inline void prochainRetour() { _prochainRetour = 1; }
	protected:
		std::vector<void *> _pile;
		std::vector<int> _pileCompo;
		int _prochainRetour;
};

Chargeur g_chargeur;

/*- Lien Compo - Chargeur - --------------------------------------------------*/

std::vector<Chargeur *> g_pileChargeurs;

/* Doit être appelée en retour d'entrerDans() par un Compo s'il veut passer la
 * main à un sous-compo. */
void * RC(Compo * c) { g_pileChargeurs.back()->prochainRetour(); return c; }

/*- Lien Chargeur - libxml ---------------------------------------------------*/

void charger(char * chemin, const xmlChar * nomRacine, Compo * traiteurRacine) { g_chargeur.charger(chemin, nomRacine, traiteurRacine); }
void entrer(void * ctx ATTRIBUTE_UNUSED, const xmlChar * nom, const xmlChar * prefixe, const xmlChar * uri, int nEnsembles, const xmlChar ** ensembles, int nAttributs, int nAttrParDefaut, const xmlChar ** attributs) { g_chargeur.entrer(ctx, nom, prefixe, uri, nEnsembles, ensembles, nAttributs, nAttrParDefaut, attributs); }
void contenu(void * ctx ATTRIBUTE_UNUSED, const xmlChar * chaine, int taille) { g_chargeur.contenu(ctx, chaine, taille); }
void sortir(void * ctx ATTRIBUTE_UNUSED, const xmlChar * nom, const xmlChar * prefixe, const xmlChar * uri) { g_chargeur.sortir(ctx, nom, prefixe, uri); }
static xmlSAXHandler g_fonctionsChargeur =
{
	NULL, //internalSubsetDebug,
	NULL, //isStandaloneDebug,
	NULL, //hasInternalSubsetDebug,
	NULL, //hasExternalSubsetDebug,
	NULL, //resolveEntityDebug,
	NULL, //getEntityDebug,
	NULL, //entityDeclDebug,
	NULL, //notationDeclDebug,
	NULL, //attributeDeclDebug,
	NULL, //elementDeclDebug,
	NULL, //unparsedEntityDeclDebug,
	NULL, //setDocumentLocatorDebug,
	NULL, //startDocumentDebug,
	NULL, //endDocumentDebug,
	NULL,
	NULL,
	NULL, //referenceDebug,
	contenu,
	NULL, //ignorableWhitespaceDebug,
	NULL, //processingInstructionDebug,
	NULL, //commentDebug,
	NULL, //warningDebug,
	NULL, //errorDebug,
	NULL, //fatalErrorDebug,
	NULL, //getParameterEntityDebug,
	NULL, //cdataBlockDebug,
	NULL, //externalSubsetDebug,
	XML_SAX2_MAGIC,
	NULL,
	entrer,
	sortir,
	NULL
};

/*- GobeurRacine -------------------------------------------------------------*/

class GobeurRacine : public Compo
{
	public:
		GobeurRacine(const xmlChar * racine, Compo * traiteur);
		virtual void * entrerDans(void * depuis, const xmlChar * nom, const xmlChar ** attributs);
	protected:
		Compo * _racineCompo;
		const xmlChar * _nomRacine;
};

GobeurRacine::GobeurRacine(const xmlChar * racine, Compo * traiteur) : _nomRacine(racine), _racineCompo(traiteur) {}
void * GobeurRacine::entrerDans(void * depuis, const xmlChar * nom, const xmlChar ** attributs) { return strcmp((const char *)nom, (const char *)_nomRacine) == 0 ? RC(_racineCompo) : NULL; }

/*- Chargeur -----------------------------------------------------------------*/

Compo * Chargeur::courant()
{
	int k;
	
	for(k = _pileCompo.size(); --k >= 0;)
		if(_pileCompo[k])
			return (Compo *)_pile[k];
	
	return NULL;
}

void Chargeur::charger(char * chemin, const xmlChar * nomRacine, Compo * traiteurRacine)
{
	_pile.push_back(nomRacine ? new GobeurRacine(nomRacine, traiteurRacine) : traiteurRacine);
	_pileCompo.push_back(1);
	
	if(chemin)
	{
		xmlSAXUserParseFile(&g_fonctionsChargeur, NULL, chemin);
		xmlCleanupParser();
		xmlMemoryDump();
	}
}

void Chargeur::entrer(void * ctx ATTRIBUTE_UNUSED, const xmlChar * nom, const xmlChar * prefixe, const xmlChar * uri, int nEnsembles, const xmlChar ** ensembles, int nAttributs, int nAttrParDefaut, const xmlChar ** attributs)
{
	Compo * cou = courant();
	g_pileChargeurs.push_back(this);
	void * resultat = cou->entrerDans(_pile.back(), nom, attributs);
	_pile.push_back(resultat);
	_pileCompo.push_back(_prochainRetour);
	if(_prochainRetour) { _prochainRetour = 0; ((Compo *)resultat)->entrer(); }
	g_pileChargeurs.pop_back();
}

void Chargeur::contenu(void * ctx ATTRIBUTE_UNUSED, const xmlChar * chaine, int taille)
{
	courant()->contenuPour(_pile.back(), chaine, taille);
}

void Chargeur::sortir(void * ctx ATTRIBUTE_UNUSED, const xmlChar * nom, const xmlChar * prefixe, const xmlChar * uri)
{
	Compo * compo;
	void * dernier;
	if(_pileCompo.back())
		((Compo *)_pile.back())->sortir();
	_pile.pop_back();
	_pileCompo.pop_back();
	courant()->sortirDe(dernier);
}

class PlistInterieure : public Compo
{
	public:
		PlistInterieure(Compo * traiteurRacine);
		virtual void entrer();
		virtual void * entrerDans(void * depuis, const xmlChar * nom, const xmlChar ** attributs);
		virtual void contenuPour(void * objet, const xmlChar * contenu, int taille);
		virtual void sortirDe(void * object);
		virtual void sortir();
	protected:
		Chargeur _suite;
		int _enCle;
		std::string _cle;
};

PlistInterieure::PlistInterieure(Compo * traiteurRacine) : _enCle(0)
{
	_suite.charger(NULL, NULL, traiteurRacine);
}
void PlistInterieure::entrer() { _enCle = 0; /*_suite.pile.front().entrer();*/ }

void * PlistInterieure::entrerDans(void * depuis, const xmlChar * nom, const xmlChar ** attributs)
{
	if(strcmp((const char *)nom, "key") == 0)
		_enCle = 1;
	else
		_suite.entrer(NULL, (const xmlChar *)_cle.c_str(), NULL, NULL, 0, NULL, 0, 0, NULL);
	_cle.clear();
}

void PlistInterieure::contenuPour(void * objet, const xmlChar * contenu, int taille)
{
	if(_enCle)
		_cle.append((const char *)contenu, taille);
	else
		_suite.contenu(NULL, contenu, taille);
}

void PlistInterieure::sortirDe(void * object)
{
	if(!_enCle)
		_suite.sortir(NULL, NULL, NULL, NULL);
	else
		_enCle = 0;
}

void PlistInterieure::sortir() { /*_suite.pile.front().sortir();*/ }

class Plist : public Compo
{
	public:
		Plist(Compo * traiteurRacine);
		virtual void * entrerDans(void * depuis, const xmlChar * nom, const xmlChar ** attributs);
	protected:
		PlistInterieure _interieur;
};

Plist::Plist(Compo * traiteurRacine) : _interieur(traiteurRacine) {}
void * Plist::entrerDans(void * depuis, const xmlChar * nom, const xmlChar ** attributs) { return RC(&_interieur); }

/*- Bordel -------------------------------------------------------------------*/

static int debug = 0;
static int copy = 0;
static int recovery = 0;
static int push = 0;
static int speed = 0;
static int noent = 0;
static int quiet = 0;
static int nonull = 0;
static int sax2 = 0;
static int repeat = 0;
static int callbacks = 0;
static int timing = 0;

/*
 * Timing routines.
 */
/*
 * Internal timing routines to remove the necessity to have unix-specific
 * function calls
 */

#ifndef HAVE_GETTIMEOFDAY 
#ifdef HAVE_SYS_TIMEB_H
#ifdef HAVE_SYS_TIME_H
#ifdef HAVE_FTIME

static int
my_gettimeofday(struct timeval *tvp, void *tzp)
{
	struct timeb timebuffer;

	ftime(&timebuffer);
	if (tvp) {
		tvp->tv_sec = timebuffer.time;
		tvp->tv_usec = timebuffer.millitm * 1000L;
	}
	return (0);
}
#define HAVE_GETTIMEOFDAY 1
#define gettimeofday my_gettimeofday

#endif /* HAVE_FTIME */
#endif /* HAVE_SYS_TIME_H */
#endif /* HAVE_SYS_TIMEB_H */
#endif /* !HAVE_GETTIMEOFDAY */

#if defined(HAVE_GETTIMEOFDAY)
static struct timeval begin, end;

/*
 * startTimer: call where you want to start timing
 */
static void
startTimer(void)
{
    gettimeofday(&begin, NULL);
}

/*
 * endTimer: call where you want to stop timing and to print out a
 *           message about the timing performed; format is a printf
 *           type argument
 */
static void XMLCDECL
endTimer(const char *fmt, ...)
{
    long msec;
    va_list ap;

    gettimeofday(&end, NULL);
    msec = end.tv_sec - begin.tv_sec;
    msec *= 1000;
    msec += (end.tv_usec - begin.tv_usec) / 1000;

#ifndef HAVE_STDARG_H
#error "endTimer required stdarg functions"
#endif
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);

    fprintf(stderr, " took %ld ms\n", msec);
}
#elif defined(HAVE_TIME_H)
/*
 * No gettimeofday function, so we have to make do with calling clock.
 * This is obviously less accurate, but there's little we can do about
 * that.
 */
#ifndef CLOCKS_PER_SEC
#define CLOCKS_PER_SEC 100
#endif

static clock_t begin, end;
static void
startTimer(void)
{
    begin = clock();
}
static void XMLCDECL
endTimer(const char *fmt, ...)
{
    long msec;
    va_list ap;

    end = clock();
    msec = ((end - begin) * 1000) / CLOCKS_PER_SEC;

#ifndef HAVE_STDARG_H
#error "endTimer required stdarg functions"
#endif
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fprintf(stderr, " took %ld ms\n", msec);
}
#else

/*
 * We don't have a gettimeofday or time.h, so we just don't do timing
 */
static void
startTimer(void)
{
    /*
     * Do nothing
     */
}
static void XMLCDECL
endTimer(char *format, ...)
{
    /*
     * We cannot do anything because we don't have a timing function
     */
#ifdef HAVE_STDARG_H
    va_start(ap, format);
    vfprintf(stderr, format, ap);
    va_end(ap);
    fprintf(stderr, " was not timed\n", msec);
#else
    /* We don't have gettimeofday, time or stdarg.h, what crazy world is
     * this ?!
     */
#endif
}
#endif

/*
 * empty SAX block
 */
static xmlSAXHandler emptySAXHandlerStruct = {
    NULL, /* internalSubset */
    NULL, /* isStandalone */
    NULL, /* hasInternalSubset */
    NULL, /* hasExternalSubset */
    NULL, /* resolveEntity */
    NULL, /* getEntity */
    NULL, /* entityDecl */
    NULL, /* notationDecl */
    NULL, /* attributeDecl */
    NULL, /* elementDecl */
    NULL, /* unparsedEntityDecl */
    NULL, /* setDocumentLocator */
    NULL, /* startDocument */
    NULL, /* endDocument */
    NULL, /* startElement */
    NULL, /* endElement */
    NULL, /* reference */
    NULL, /* characters */
    NULL, /* ignorableWhitespace */
    NULL, /* processingInstruction */
    NULL, /* comment */
    NULL, /* xmlParserWarning */
    NULL, /* xmlParserError */
    NULL, /* xmlParserError */
    NULL, /* getParameterEntity */
    NULL, /* cdataBlock; */
    NULL, /* externalSubset; */
    1,
    NULL,
    NULL, /* startElementNs */
    NULL, /* endElementNs */
    NULL  /* xmlStructuredErrorFunc */
};

static xmlSAXHandlerPtr emptySAXHandler = &emptySAXHandlerStruct;
extern xmlSAXHandlerPtr debugSAXHandler;

/************************************************************************
 *									*
 *				Debug Handlers				*
 *									*
 ************************************************************************/

/**
 * isStandaloneDebug:
 * @ctxt:  An XML parser context
 *
 * Is this document tagged standalone ?
 *
 * Returns 1 if true
 */
static int
isStandaloneDebug(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    if (quiet)
	return(0);
    fprintf(stdout, "SAX.isStandalone()\n");
    return(0);
}

/**
 * hasInternalSubsetDebug:
 * @ctxt:  An XML parser context
 *
 * Does this document has an internal subset
 *
 * Returns 1 if true
 */
static int
hasInternalSubsetDebug(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    if (quiet)
	return(0);
    fprintf(stdout, "SAX.hasInternalSubset()\n");
    return(0);
}

/**
 * hasExternalSubsetDebug:
 * @ctxt:  An XML parser context
 *
 * Does this document has an external subset
 *
 * Returns 1 if true
 */
static int
hasExternalSubsetDebug(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    if (quiet)
	return(0);
    fprintf(stdout, "SAX.hasExternalSubset()\n");
    return(0);
}

/**
 * internalSubsetDebug:
 * @ctxt:  An XML parser context
 *
 * Does this document has an internal subset
 */
static void
internalSubsetDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name,
	       const xmlChar *ExternalID, const xmlChar *SystemID)
{
    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.internalSubset(%s,", name);
    if (ExternalID == NULL)
	fprintf(stdout, " ,");
    else
	fprintf(stdout, " %s,", ExternalID);
    if (SystemID == NULL)
	fprintf(stdout, " )\n");
    else
	fprintf(stdout, " %s)\n", SystemID);
}

/**
 * externalSubsetDebug:
 * @ctxt:  An XML parser context
 *
 * Does this document has an external subset
 */
static void
externalSubsetDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name,
	       const xmlChar *ExternalID, const xmlChar *SystemID)
{
    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.externalSubset(%s,", name);
    if (ExternalID == NULL)
	fprintf(stdout, " ,");
    else
	fprintf(stdout, " %s,", ExternalID);
    if (SystemID == NULL)
	fprintf(stdout, " )\n");
    else
	fprintf(stdout, " %s)\n", SystemID);
}

/**
 * resolveEntityDebug:
 * @ctxt:  An XML parser context
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 *
 * Special entity resolver, better left to the parser, it has
 * more context than the application layer.
 * The default behaviour is to NOT resolve the entities, in that case
 * the ENTITY_REF nodes are built in the structure (and the parameter
 * values).
 *
 * Returns the xmlParserInputPtr if inlined or NULL for DOM behaviour.
 */
static xmlParserInputPtr
resolveEntityDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *publicId, const xmlChar *systemId)
{
    callbacks++;
    if (quiet)
	return(NULL);
    /* xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx; */

    
    fprintf(stdout, "SAX.resolveEntity(");
    if (publicId != NULL)
	fprintf(stdout, "%s", (char *)publicId);
    else
	fprintf(stdout, " ");
    if (systemId != NULL)
	fprintf(stdout, ", %s)\n", (char *)systemId);
    else
	fprintf(stdout, ", )\n");
/*********
    if (systemId != NULL) {
        return(xmlNewInputFromFile(ctxt, (char *) systemId));
    }
 *********/
    return(NULL);
}

/**
 * getEntityDebug:
 * @ctxt:  An XML parser context
 * @name: The entity name
 *
 * Get an entity by name
 *
 * Returns the xmlParserInputPtr if inlined or NULL for DOM behaviour.
 */
static xmlEntityPtr
getEntityDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name)
{
    callbacks++;
    if (quiet)
	return(NULL);
    fprintf(stdout, "SAX.getEntity(%s)\n", name);
    return(NULL);
}

/**
 * getParameterEntityDebug:
 * @ctxt:  An XML parser context
 * @name: The entity name
 *
 * Get a parameter entity by name
 *
 * Returns the xmlParserInputPtr
 */
static xmlEntityPtr
getParameterEntityDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name)
{
    callbacks++;
    if (quiet)
	return(NULL);
    fprintf(stdout, "SAX.getParameterEntity(%s)\n", name);
    return(NULL);
}


/**
 * entityDeclDebug:
 * @ctxt:  An XML parser context
 * @name:  the entity name 
 * @type:  the entity type 
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 * @content: the entity value (without processing).
 *
 * An entity definition has been parsed
 */
static void
entityDeclDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name, int type,
          const xmlChar *publicId, const xmlChar *systemId, xmlChar *content)
{
const xmlChar *nullstr = BAD_CAST "(null)";
    /* not all libraries handle printing null pointers nicely */
    if (publicId == NULL)
        publicId = nullstr;
    if (systemId == NULL)
        systemId = nullstr;
    if (content == NULL)
        content = (xmlChar *)nullstr;
    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.entityDecl(%s, %d, %s, %s, %s)\n",
            name, type, publicId, systemId, content);
}

/**
 * attributeDeclDebug:
 * @ctxt:  An XML parser context
 * @name:  the attribute name 
 * @type:  the attribute type 
 *
 * An attribute definition has been parsed
 */
static void
attributeDeclDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar * elem,
                   const xmlChar * name, int type, int def,
                   const xmlChar * defaultValue, xmlEnumerationPtr tree)
{
    callbacks++;
    if (quiet)
        return;
    if (defaultValue == NULL)
        fprintf(stdout, "SAX.attributeDecl(%s, %s, %d, %d, NULL, ...)\n",
                elem, name, type, def);
    else
        fprintf(stdout, "SAX.attributeDecl(%s, %s, %d, %d, %s, ...)\n",
                elem, name, type, def, defaultValue);
    xmlFreeEnumeration(tree);
}

/**
 * elementDeclDebug:
 * @ctxt:  An XML parser context
 * @name:  the element name 
 * @type:  the element type 
 * @content: the element value (without processing).
 *
 * An element definition has been parsed
 */
static void
elementDeclDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name, int type,
	    xmlElementContentPtr content ATTRIBUTE_UNUSED)
{
    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.elementDecl(%s, %d, ...)\n",
            name, type);
}

/**
 * notationDeclDebug:
 * @ctxt:  An XML parser context
 * @name: The name of the notation
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 *
 * What to do when a notation declaration has been parsed.
 */
static void
notationDeclDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name,
	     const xmlChar *publicId, const xmlChar *systemId)
{
    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.notationDecl(%s, %s, %s)\n",
            (char *) name, (char *) publicId, (char *) systemId);
}

/**
 * unparsedEntityDeclDebug:
 * @ctxt:  An XML parser context
 * @name: The name of the entity
 * @publicId: The public ID of the entity
 * @systemId: The system ID of the entity
 * @notationName: the name of the notation
 *
 * What to do when an unparsed entity declaration is parsed
 */
static void
unparsedEntityDeclDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name,
		   const xmlChar *publicId, const xmlChar *systemId,
		   const xmlChar *notationName)
{
const xmlChar *nullstr = BAD_CAST "(null)";

    if (publicId == NULL)
        publicId = nullstr;
    if (systemId == NULL)
        systemId = nullstr;
    if (notationName == NULL)
        notationName = nullstr;
    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.unparsedEntityDecl(%s, %s, %s, %s)\n",
            (char *) name, (char *) publicId, (char *) systemId,
	    (char *) notationName);
}

/**
 * setDocumentLocatorDebug:
 * @ctxt:  An XML parser context
 * @loc: A SAX Locator
 *
 * Receive the document locator at startup, actually xmlDefaultSAXLocator
 * Everything is available on the context, so this is useless in our case.
 */
static void
setDocumentLocatorDebug(void *ctx ATTRIBUTE_UNUSED, xmlSAXLocatorPtr loc ATTRIBUTE_UNUSED)
{
    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.setDocumentLocator()\n");
}

/**
 * startDocumentDebug:
 * @ctxt:  An XML parser context
 *
 * called when the document start being processed.
 */
static void
startDocumentDebug(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.startDocument()\n");
}

/**
 * endDocumentDebug:
 * @ctxt:  An XML parser context
 *
 * called when the document end has been detected.
 */
static void
endDocumentDebug(void *ctx ATTRIBUTE_UNUSED)
{
    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.endDocument()\n");
}

/**
 * startElementDebug:
 * @ctxt:  An XML parser context
 * @name:  The element name
 *
 * called when an opening tag has been processed.
 */
static void
startElementDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name, const xmlChar **atts)
{
    int i;

    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.startElement(%s", (char *) name);
    if (atts != NULL) {
        for (i = 0;(atts[i] != NULL);i++) {
	    fprintf(stdout, ", %s='", atts[i++]);
	    if (atts[i] != NULL)
	        fprintf(stdout, "%s'", atts[i]);
	}
    }
    fprintf(stdout, ")\n");
}

/**
 * endElementDebug:
 * @ctxt:  An XML parser context
 * @name:  The element name
 *
 * called when the end of an element has been detected.
 */
static void
endElementDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name)
{
    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.endElement(%s)\n", (char *) name);
}

/**
 * charactersDebug:
 * @ctxt:  An XML parser context
 * @ch:  a xmlChar string
 * @len: the number of xmlChar
 *
 * receiving some chars from the parser.
 * Question: how much at a time ???
 */
static void
charactersDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *ch, int len)
{
    char output[40];
    int i;

    callbacks++;
    if (quiet)
	return;
    for (i = 0;(i<len) && (i < 30);i++)
	output[i] = ch[i];
    output[i] = 0;

    fprintf(stdout, "SAX.characters(%s, %d)\n", output, len);
}

/**
 * referenceDebug:
 * @ctxt:  An XML parser context
 * @name:  The entity name
 *
 * called when an entity reference is detected. 
 */
static void
referenceDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *name)
{
    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.reference(%s)\n", name);
}

/**
 * ignorableWhitespaceDebug:
 * @ctxt:  An XML parser context
 * @ch:  a xmlChar string
 * @start: the first char in the string
 * @len: the number of xmlChar
 *
 * receiving some ignorable whitespaces from the parser.
 * Question: how much at a time ???
 */
static void
ignorableWhitespaceDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *ch, int len)
{
    char output[40];
    int i;

    callbacks++;
    if (quiet)
	return;
    for (i = 0;(i<len) && (i < 30);i++)
	output[i] = ch[i];
    output[i] = 0;
    fprintf(stdout, "SAX.ignorableWhitespace(%s, %d)\n", output, len);
}

/**
 * processingInstructionDebug:
 * @ctxt:  An XML parser context
 * @target:  the target name
 * @data: the PI data's
 * @len: the number of xmlChar
 *
 * A processing instruction has been parsed.
 */
static void
processingInstructionDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *target,
                      const xmlChar *data)
{
    callbacks++;
    if (quiet)
	return;
    if (data != NULL)
	fprintf(stdout, "SAX.processingInstruction(%s, %s)\n",
		(char *) target, (char *) data);
    else
	fprintf(stdout, "SAX.processingInstruction(%s, NULL)\n",
		(char *) target);
}

/**
 * cdataBlockDebug:
 * @ctx: the user data (XML parser context)
 * @value:  The pcdata content
 * @len:  the block length
 *
 * called when a pcdata block has been parsed
 */
static void
cdataBlockDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *value, int len)
{
    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.pcdata(%.20s, %d)\n",
	    (char *) value, len);
}

/**
 * commentDebug:
 * @ctxt:  An XML parser context
 * @value:  the comment content
 *
 * A comment has been parsed.
 */
static void
commentDebug(void *ctx ATTRIBUTE_UNUSED, const xmlChar *value)
{
    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.comment(%s)\n", value);
}

/**
 * warningDebug:
 * @ctxt:  An XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 *
 * Display and format a warning messages, gives file, line, position and
 * extra parameters.
 */
static void XMLCDECL
warningDebug(void *ctx ATTRIBUTE_UNUSED, const char *msg, ...)
{
    va_list args;

    callbacks++;
    if (quiet)
	return;
    va_start(args, msg);
    fprintf(stdout, "SAX.warning: ");
    vfprintf(stdout, msg, args);
    va_end(args);
}

/**
 * errorDebug:
 * @ctxt:  An XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 *
 * Display and format a error messages, gives file, line, position and
 * extra parameters.
 */
static void XMLCDECL
errorDebug(void *ctx ATTRIBUTE_UNUSED, const char *msg, ...)
{
    va_list args;

    callbacks++;
    if (quiet)
	return;
    va_start(args, msg);
    fprintf(stdout, "SAX.error: ");
    vfprintf(stdout, msg, args);
    va_end(args);
}

/**
 * fatalErrorDebug:
 * @ctxt:  An XML parser context
 * @msg:  the message to display/transmit
 * @...:  extra parameters for the message display
 *
 * Display and format a fatalError messages, gives file, line, position and
 * extra parameters.
 */
static void XMLCDECL
fatalErrorDebug(void *ctx ATTRIBUTE_UNUSED, const char *msg, ...)
{
    va_list args;

    callbacks++;
    if (quiet)
	return;
    va_start(args, msg);
    fprintf(stdout, "SAX.fatalError: ");
    vfprintf(stdout, msg, args);
    va_end(args);
}

static xmlSAXHandler debugSAXHandlerStruct = {
    internalSubsetDebug,
    isStandaloneDebug,
    hasInternalSubsetDebug,
    hasExternalSubsetDebug,
    resolveEntityDebug,
    getEntityDebug,
    entityDeclDebug,
    notationDeclDebug,
    attributeDeclDebug,
    elementDeclDebug,
    unparsedEntityDeclDebug,
    setDocumentLocatorDebug,
    startDocumentDebug,
    endDocumentDebug,
    startElementDebug,
    endElementDebug,
    referenceDebug,
    charactersDebug,
    ignorableWhitespaceDebug,
    processingInstructionDebug,
    commentDebug,
    warningDebug,
    errorDebug,
    fatalErrorDebug,
    getParameterEntityDebug,
    cdataBlockDebug,
    externalSubsetDebug,
    1,
    NULL,
    NULL,
    NULL,
    NULL
};

xmlSAXHandlerPtr debugSAXHandler = &debugSAXHandlerStruct;

/*
 * SAX2 specific callbacks
 */
/**
 * startElementNsDebug:
 * @ctxt:  An XML parser context
 * @name:  The element name
 *
 * called when an opening tag has been processed.
 */
static void
startElementNsDebug(void *ctx ATTRIBUTE_UNUSED,
                    const xmlChar *localname,
                    const xmlChar *prefix,
                    const xmlChar *URI,
		    int nb_namespaces,
		    const xmlChar **namespaces,
		    int nb_attributes,
		    int nb_defaulted,
		    const xmlChar **attributes)
{
    int i;

    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.startElementNs(%s", (char *) localname);
    if (prefix == NULL)
	fprintf(stdout, ", NULL");
    else
	fprintf(stdout, ", %s", (char *) prefix);
    if (URI == NULL)
	fprintf(stdout, ", NULL");
    else
	fprintf(stdout, ", '%s'", (char *) URI);
    fprintf(stdout, ", %d", nb_namespaces);
    
    if (namespaces != NULL) {
        for (i = 0;i < nb_namespaces * 2;i++) {
	    fprintf(stdout, ", xmlns");
	    if (namespaces[i] != NULL)
	        fprintf(stdout, ":%s", namespaces[i]);
	    i++;
	    fprintf(stdout, "='%s'", namespaces[i]);
	}
    }
    fprintf(stdout, ", %d, %d", nb_attributes, nb_defaulted);
    if (attributes != NULL) {
        for (i = 0;i < nb_attributes * 5;i += 5) {
	    if (attributes[i + 1] != NULL)
		fprintf(stdout, ", %s:%s='", attributes[i + 1], attributes[i]);
	    else
		fprintf(stdout, ", %s='", attributes[i]);
	    fprintf(stdout, "%.4s...', %d", attributes[i + 3],
		    (int)(attributes[i + 4] - attributes[i + 3]));
	}
    }
    fprintf(stdout, ")\n");
}

/**
 * endElementDebug:
 * @ctxt:  An XML parser context
 * @name:  The element name
 *
 * called when the end of an element has been detected.
 */
static void
endElementNsDebug(void *ctx ATTRIBUTE_UNUSED,
                  const xmlChar *localname,
                  const xmlChar *prefix,
                  const xmlChar *URI)
{
    callbacks++;
    if (quiet)
	return;
    fprintf(stdout, "SAX.endElementNs(%s", (char *) localname);
    if (prefix == NULL)
	fprintf(stdout, ", NULL");
    else
	fprintf(stdout, ", %s", (char *) prefix);
    if (URI == NULL)
	fprintf(stdout, ", NULL)\n");
    else
	fprintf(stdout, ", '%s')\n", (char *) URI);
}

static xmlSAXHandler debugSAX2HandlerStruct = {
    internalSubsetDebug,
    isStandaloneDebug,
    hasInternalSubsetDebug,
    hasExternalSubsetDebug,
    resolveEntityDebug,
    getEntityDebug,
    entityDeclDebug,
    notationDeclDebug,
    attributeDeclDebug,
    elementDeclDebug,
    unparsedEntityDeclDebug,
    setDocumentLocatorDebug,
    startDocumentDebug,
    endDocumentDebug,
    NULL,
    NULL,
    referenceDebug,
    charactersDebug,
    ignorableWhitespaceDebug,
    processingInstructionDebug,
    commentDebug,
    warningDebug,
    errorDebug,
    fatalErrorDebug,
    getParameterEntityDebug,
    cdataBlockDebug,
    externalSubsetDebug,
    XML_SAX2_MAGIC,
    NULL,
    startElementNsDebug,
    endElementNsDebug,
    NULL
};

static xmlSAXHandlerPtr debugSAX2Handler = &debugSAX2HandlerStruct;

/************************************************************************
 *									*
 *				Debug					*
 *									*
 ************************************************************************/

static void
parseAndPrintFile(char *filename) {
    int res;

#ifdef LIBXML_PUSH_ENABLED
    if (push) {
	FILE *f;

        if ((!quiet) && (!nonull)) {
	    /*
	     * Empty callbacks for checking
	     */
#if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)
	    f = fopen(filename, "rb");
#else
	    f = fopen(filename, "r");
#endif
	    if (f != NULL) {
		int ret;
		char chars[10];
		xmlParserCtxtPtr ctxt;

		ret = fread(chars, 1, 4, f);
		if (ret > 0) {
		    ctxt = xmlCreatePushParserCtxt(emptySAXHandler, NULL,
				chars, ret, filename);
		    while ((ret = fread(chars, 1, 3, f)) > 0) {
			xmlParseChunk(ctxt, chars, ret, 0);
		    }
		    xmlParseChunk(ctxt, chars, 0, 1);
		    xmlFreeParserCtxt(ctxt);
		}
		fclose(f);
	    } else {
		xmlGenericError(xmlGenericErrorContext,
			"Cannot read file %s\n", filename);
	    }
	}
	/*
	 * Debug callback
	 */
#if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)
	f = fopen(filename, "rb");
#else
	f = fopen(filename, "r");
#endif
	if (f != NULL) {
	    int ret;
	    char chars[10];
	    xmlParserCtxtPtr ctxt;

	    ret = fread(chars, 1, 4, f);
	    if (ret > 0) {
	        if (sax2)
		    ctxt = xmlCreatePushParserCtxt(debugSAX2Handler, NULL,
				chars, ret, filename);
		else
		    ctxt = xmlCreatePushParserCtxt(debugSAXHandler, NULL,
				chars, ret, filename);
		while ((ret = fread(chars, 1, 3, f)) > 0) {
		    xmlParseChunk(ctxt, chars, ret, 0);
		}
		ret = xmlParseChunk(ctxt, chars, 0, 1);
		xmlFreeParserCtxt(ctxt);
		if (ret != 0) {
		    fprintf(stdout,
		            "xmlSAXUserParseFile returned error %d\n", ret);
		}
	    }
	    fclose(f);
	}
    } else {
#endif /* LIBXML_PUSH_ENABLED */
	if (!speed) {
	    /*
	     * Empty callbacks for checking
	     */
	    if ((!quiet) && (!nonull)) {
		res = xmlSAXUserParseFile(emptySAXHandler, NULL, filename);
		if (res != 0) {
		    fprintf(stdout, "xmlSAXUserParseFile returned error %d\n", res);
		}
	    }

	    /*
	     * Debug callback
	     */
	    callbacks = 0;
	    if (repeat) {
	        int i;
		for (i = 0;i < 99;i++) {
		    if (sax2)
			res = xmlSAXUserParseFile(debugSAX2Handler, NULL,
			                          filename);
		    else
			res = xmlSAXUserParseFile(debugSAXHandler, NULL,
			                          filename);
		}
	    }
	    if (sax2)
	        res = xmlSAXUserParseFile(debugSAX2Handler, NULL, filename);
	    else
		res = xmlSAXUserParseFile(debugSAXHandler, NULL, filename);
	    if (res != 0) {
		fprintf(stdout, "xmlSAXUserParseFile returned error %d\n", res);
	    }
	    if (quiet)
		fprintf(stdout, "%d callbacks generated\n", callbacks);
	} else {
	    /*
	     * test 100x the SAX parse
	     */
	    int i;

	    for (i = 0; i<100;i++)
		res = xmlSAXUserParseFile(emptySAXHandler, NULL, filename);
	    if (res != 0) {
		fprintf(stdout, "xmlSAXUserParseFile returned error %d\n", res);
	    }
	}
#ifdef LIBXML_PUSH_ENABLED
    }
#endif
}


#if 0
int main(int argc, char **argv) {
    int i;
    int files = 0;

    LIBXML_TEST_VERSION	/* be safe, plus calls xmlInitParser */
    
    for (i = 1; i < argc ; i++) {
	if ((!strcmp(argv[i], "-debug")) || (!strcmp(argv[i], "--debug")))
	    debug++;
	else if ((!strcmp(argv[i], "-copy")) || (!strcmp(argv[i], "--copy")))
	    copy++;
	else if ((!strcmp(argv[i], "-recover")) ||
	         (!strcmp(argv[i], "--recover")))
	    recovery++;
	else if ((!strcmp(argv[i], "-push")) ||
	         (!strcmp(argv[i], "--push")))
#ifdef LIBXML_PUSH_ENABLED
	    push++;
#else
	    fprintf(stderr,"'push' not enabled in library - ignoring\n");
#endif /* LIBXML_PUSH_ENABLED */
	else if ((!strcmp(argv[i], "-speed")) ||
	         (!strcmp(argv[i], "--speed")))
	    speed++;
	else if ((!strcmp(argv[i], "-timing")) ||
	         (!strcmp(argv[i], "--timing"))) {
	    nonull++;
	    timing++;
	    quiet++;
	} else if ((!strcmp(argv[i], "-repeat")) ||
	         (!strcmp(argv[i], "--repeat"))) {
	    repeat++;
	    quiet++;
	} else if ((!strcmp(argv[i], "-noent")) ||
	         (!strcmp(argv[i], "--noent")))
	    noent++;
	else if ((!strcmp(argv[i], "-quiet")) ||
	         (!strcmp(argv[i], "--quiet")))
	    quiet++;
	else if ((!strcmp(argv[i], "-sax2")) ||
	         (!strcmp(argv[i], "--sax2")))
	    sax2++;
	else if ((!strcmp(argv[i], "-nonull")) ||
	         (!strcmp(argv[i], "--nonull")))
	    nonull++;
    }
    if (noent != 0) xmlSubstituteEntitiesDefault(1);
    for (i = 1; i < argc ; i++) {
	if (argv[i][0] != '-') {
	    if (timing) {
		startTimer();
	    }
	    parseAndPrintFile(argv[i]);
	    if (timing) {
		endTimer("Parsing");
	    }
	    files ++;
	}
    }
    xmlCleanupParser();
    xmlMemoryDump();

    return(0);
}
#endif

#else
int main(int argc ATTRIBUTE_UNUSED, char **argv ATTRIBUTE_UNUSED) {
    printf("%s : SAX1 parsing support not compiled in\n", argv[0]);
    return(0);
}
#endif /* LIBXML_SAX1_ENABLED */

/*- Sorties ------------------------------------------------------------------*/

class Sortie
{
	public:
		virtual void traiterMorceau(std::string * champs);
		virtual void traiterListe(std::string & nom);
		virtual void traiterMorceauListe(int numero);
};

class SortieListeListes : public Sortie
{
	public:
		virtual void traiterMorceau(std::string * champs);
		virtual void traiterListe(std::string & nom);
		virtual void traiterMorceauListe(int numero);
	protected:
		std::map<int, std::string> _morceaux;
};

/*- Lecteurs de sous-liste ---------------------------------------------------*/

class Morceaux : public Compo
{
	public:
		Morceaux(Sortie * sortie) : _sortie(sortie) {}
		virtual void entrer();
		virtual void * entrerDans(void * depuis, const xmlChar * nom, const xmlChar ** attributs);
		virtual void contenuPour(void * objet, const xmlChar * contenu, int taille);
		virtual void sortirDe(void * object);
	protected:
		int _niveau;
		std::string _champs[5];
		int _modif;
		Sortie * _sortie;
};

class Listes : public Compo
{
	public:
		Listes(Sortie * sortie) : _sortie(sortie) {}
		virtual void entrer();
		virtual void * entrerDans(void * depuis, const xmlChar * nom, const xmlChar ** attributs);
		virtual void contenuPour(void * objet, const xmlChar * contenu, int taille);
		virtual void sortirDe(void * object);
	protected:
		int _niveau;
		Sortie * _sortie;
		int _faitCourant;
		std::string _courant;
};

class Itml : public Compo
{
	public:
		Itml(Sortie * sortieMorceaux, Sortie * sortieListes);
		virtual void entrer();
		virtual void * entrerDans(void * depuis, const xmlChar * nom, const xmlChar ** attributs);
		virtual void sortirDe(void * object);
	protected:
		int _niveau;
		Morceaux * _morceaux;
		Listes * _listes;
		std::string _champs[5];
		int _modif;
		Sortie * _sortie;
};

/*- Lecteurs de sous-liste ---------------------------------------------------*/

Itml::Itml(Sortie * sortieMorceaux, Sortie * sortieListes)
{
	if(sortieMorceaux) _morceaux = new Morceaux(sortieMorceaux);
	if(sortieListes) _listes = new Listes(sortieListes);
}

void Itml::entrer()
{
	_niveau = 0;
}

void * Itml::entrerDans(void * depuis, const xmlChar * nom, const xmlChar ** attributs)
{
	switch(++_niveau)
	{
		case 1:
			if(strcmp((char *)nom, "Tracks") == 0)
				return RC(_morceaux);
			else if(strcmp((char *)nom, "Playlists") == 0)
				return RC(_listes);
			break;
	}
	
	return NULL;
}

void Itml::sortirDe(void * depuis)
{
	--_niveau;
}

void Morceaux::entrer()
{
	_niveau = 0;
}

void * Morceaux::entrerDans(void * depuis, const xmlChar * nom, const xmlChar ** attributs)
{
	switch(++_niveau)
	{
		case 2:
			if(strcmp((char *)nom, "Location") == 0)
				_modif = 0;
			else if(strcmp((char *)nom, "Rating") == 0)
				_modif = 1;
			else if(strcmp((char *)nom, "Artist") == 0)
				_modif = 2;
			else if(strcmp((char *)nom, "Name") == 0)
				_modif = 3;
			else if(strcmp((char *)nom, "Track ID") == 0)
				_modif = 4;
			break;
		case 1:
			for(int i = 5; --i >= 0;)
				_champs[i].clear();
			break;
	}
	return NULL;
}

void Morceaux::contenuPour(void * objet, const xmlChar * contenu, int taille)
{
	if(_modif >= 0)
		_champs[_modif].append((char *)contenu, taille);
}

void Morceaux::sortirDe(void * object)
{
	switch(--_niveau)
	{
		case 1:
			_modif = -1;
			break;
		case 0:
			_sortie->traiterMorceau(_champs);
			break;
	}
}

void Listes::entrer()
{
	_niveau = 0;
}

void * Listes::entrerDans(void * depuis, const xmlChar * nom, const xmlChar ** attributs)
{
	switch(++_niveau)
	{
		case 1:
			_faitCourant = 0;
			break;
		case 2:
			if(strcmp((char *)nom, "Name") == 0)
			{
				_faitCourant = 1;
				_courant.clear();
			}
			break;
		case 4:
			if(strcmp((char *)nom, "Track ID") == 0)
			{
				_faitCourant = 1;
				_courant.clear();
			}
			break;
	}
	return NULL;
}

void Listes::contenuPour(void * objet, const xmlChar * contenu, int taille)
{
	if(_faitCourant)
		_courant.append((char *)contenu, taille);
}

void Listes::sortirDe(void * object)
{
	switch(--_niveau)
	{
		case 3:
			if(_faitCourant)
				_sortie->traiterMorceauListe(atol(_courant.c_str())); /* À FAIRE: ne pas le faire si le nom de la liste n'est pas encore apparu (détecter quand on entre dans une liste, quand on en récupère le nom, et retenir les numéros tant qu'on n'a pas le second dans le premier). */
			_faitCourant = 0;
			break;
		case 1:
			if(_faitCourant)
				_sortie->traiterListe(_courant);
			_faitCourant = 0;
			break;
	}
}

/*- Sorties ------------------------------------------------------------------*/

void Sortie::traiterMorceau(std::string * champs) {}
void Sortie::traiterListe(std::string & nom) {}
void Sortie::traiterMorceauListe(int numero) {}

void SortieListeListes::traiterMorceau(std::string * champs)
{
	if(champs[4].length())
		_morceaux[atol(champs[4].c_str())] = champs[2]+" - "+champs[3];
}

void SortieListeListes::traiterListe(std::string & nom)
{
	printf("*** %s\n", nom.c_str());
}

void SortieListeListes::traiterMorceauListe(int numero)
{
	printf("%s\n", _morceaux[numero].c_str());
}

/*- Principal ----------------------------------------------------------------*/

int main(int argc, char ** argv)
{
	Sortie * morceaux = NULL;
	Sortie * listes = NULL;
	
	morceaux = listes = new SortieListeListes();
	charger(argv[1], (const xmlChar *)"plist", new Plist(new Itml(morceaux, listes)));
	return 0;
}
