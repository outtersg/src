<?xml version='1.0'?>

<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
<xsl:output method="text"/>

<xsl:template match="/contenu">
#!/bin/sh
<xsl:apply-templates/>
</xsl:template>

<xsl:template match="_Tracks">
	<xsl:call-template name="TotoBoulouboulou">
		<xsl:with-param name="note">100</xsl:with-param>
		<xsl:with-param name="intitulé">ooooo</xsl:with-param>
	</xsl:call-template>
	<xsl:call-template name="TotoBoulouboulou">
		<xsl:with-param name="note">80</xsl:with-param>
		<xsl:with-param name="intitulé">oooo</xsl:with-param>
	</xsl:call-template>
	<xsl:call-template name="TotoBoulouboulou">
		<xsl:with-param name="note">60</xsl:with-param>
		<xsl:with-param name="intitulé">ooo</xsl:with-param>
	</xsl:call-template>
	<xsl:call-template name="TotoBoulouboulou">
		<xsl:with-param name="note">40</xsl:with-param>
		<xsl:with-param name="intitulé">oo</xsl:with-param>
	</xsl:call-template>
	<xsl:call-template name="TotoBoulouboulou">
		<xsl:with-param name="note">20</xsl:with-param>
		<xsl:with-param name="intitulé">o</xsl:with-param>
	</xsl:call-template>
</xsl:template>

<xsl:template name="TotoBoulouboulou">
	<xsl:param name="note"/>
	<xsl:param name="intitulé"/>
	<xsl:apply-templates select="*[_Rating=$note]" mode="groumf">
		<xsl:sort select="_Artist"/>
		<xsl:sort select="_Composer"/>
		<xsl:sort select="_Name"/>
		<xsl:with-param name="dossier" select="$intitulé"/>
	</xsl:apply-templates>
</xsl:template>	

<xsl:template match="*" mode="groumf">
	<xsl:param name="dossier"/>
	<xsl:call-template name="gloups"><xsl:with-param name="dossier" select="$dossier"/><xsl:with-param name="intitulé" select="_Location"/></xsl:call-template>
</xsl:template>

<xsl:template name="gloups">
	<xsl:param name="dossier"/>
	<xsl:param name="intitulé"/>
	<xsl:variable name="réduit" select="substring-after($intitulé,'.')"/>
	<xsl:choose>
		<xsl:when test="contains($réduit,'.')">
			<xsl:call-template name="gloups"><xsl:with-param name="dossier" select="$dossier"/><xsl:with-param name="intitulé" select="$réduit"/></xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			ln -s "../../<xsl:value-of select="substring-after(_Location,'file://localhost$BIBLIO/')"/><xsl:text>" "</xsl:text><xsl:value-of select="$dossier"/>/<xsl:value-of select="_Artist"/> - <xsl:value-of select="_Name"/>.<xsl:value-of select="$réduit"/>"
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*"/>
<xsl:template match="text()"/>
<xsl:template match="text()" mode="bruti"/>

</xsl:stylesheet>
