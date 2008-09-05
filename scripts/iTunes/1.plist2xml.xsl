<?xml version='1.0' encoding='iso-8859-1'?>

<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
<xsl:output indent='yes'/>

<xsl:template match="plist"><contenu><xsl:apply-templates mode="allons"/></contenu></xsl:template>
<xsl:template match="dict" mode="allons"><xsl:apply-templates/></xsl:template>

<xsl:template match="key">
	<xsl:element name="_{translate(.,' ','_')}">
		<xsl:apply-templates select="following-sibling::*[position()=1]" mode="ouais"/>
	</xsl:element>
</xsl:template>

<xsl:template match="dict" mode="ouais"><xsl:apply-templates/></xsl:template>
<xsl:template match="integer|string|float" mode="ouais">
	<xsl:value-of select="."/>
</xsl:template>
<xsl:template match="*"/>
<xsl:template match="text()"/>

</xsl:stylesheet>