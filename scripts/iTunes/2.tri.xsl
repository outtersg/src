<?xml version='1.0'?>

<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
<xsl:output method="xml" indent="yes" doctype-public="-//W3C//DTD XHTML 1.1//EN" doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"/>

<xsl:template match="/contenu">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="fr">

<head>
        <title>Classement</title>
        <meta name="Description" content="Pas grand chose"/>
        <meta name="Author" content="Guillaume Outters"/>
</head>

<body>
	<xsl:apply-templates/>
</body>
</html>
</xsl:template>

<xsl:template match="_Tracks">
	<table>
	<xsl:call-template name="TotoBoulouboulou">
		<xsl:with-param name="note">100</xsl:with-param>
		<xsl:with-param name="intitulé">Sublime</xsl:with-param>
	</xsl:call-template>
	<xsl:call-template name="TotoBoulouboulou">
		<xsl:with-param name="note">80</xsl:with-param>
		<xsl:with-param name="intitulé">Superbe</xsl:with-param>
	</xsl:call-template>
	<xsl:call-template name="TotoBoulouboulou">
		<xsl:with-param name="note">60</xsl:with-param>
		<xsl:with-param name="intitulé">Ça se laisse bien écouter</xsl:with-param>
	</xsl:call-template>
	<xsl:call-template name="TotoBoulouboulou">
		<xsl:with-param name="note">40</xsl:with-param>
		<xsl:with-param name="intitulé">Il y avait de l'idée</xsl:with-param>
	</xsl:call-template>
	<xsl:call-template name="TotoBoulouboulou">
		<xsl:with-param name="note">20</xsl:with-param>
		<xsl:with-param name="intitulé">La prochaine fois que je tombe dessus de mauvaise humeur, direct à la poubelle</xsl:with-param>
	</xsl:call-template>
	</table>
</xsl:template>

<xsl:template name="TotoBoulouboulou">
	<xsl:param name="note"/>
	<xsl:param name="intitulé"/>
	<tr style="background-color: yellow;"><td colspan="2"><xsl:value-of select="$intitulé"/></td></tr>
	<xsl:apply-templates select="*[_Rating=$note]" mode="groumf">
		<xsl:sort select="_Artist"/>
		<xsl:sort select="_Composer"/>
		<xsl:sort select="_Name"/>
		<xsl:with-param name="intitulé" select="$intitulé"/>
	</xsl:apply-templates>
</xsl:template>	

<xsl:template match="*" mode="groumf">
	<tr>
		<td><a href="{substring-after(_Location,'file://localhost$BIBLIO/')}"><xsl:value-of select="_Name"/></a></td>
		<td><xsl:choose><xsl:when test="_Artist"><xsl:value-of select="_Artist"/></xsl:when><xsl:otherwise><xsl:value-of select="_Composer"/></xsl:otherwise></xsl:choose></td>
	</tr>
</xsl:template>

<xsl:template match="*"/>
<xsl:template match="text()"/>
<xsl:template match="text()" mode="bruti"/>

</xsl:stylesheet>
