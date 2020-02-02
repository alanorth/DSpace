<?xml version="1.0" encoding="UTF-8"?>


<xsl:stylesheet
        xmlns="http://di.tamu.edu/DRI/1.0/"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
        xmlns:i18n="http://apache.org/cocoon/i18n/2.1"
        xmlns:mets="http://www.loc.gov/METS/"
        xmlns:dim="http://www.dspace.org/xmlns/dspace/dim"

        exclude-result-prefixes="xsl i18n mets dim">

    <xsl:output indent="yes"/>
    <xsl:template match="mets:METS" mode="community-browser">
        <xsl:variable name="dim" select="mets:dmdSec/mets:mdWrap/mets:xmlData/dim:dim"/>
        <xref target="{@OBJID}" n="community-browser-link">
            <xsl:value-of select="$dim/dim:field[@element='title']"/>
        </xref>
        <!--Display community strengths (item counts) if they exist-->
        <xsl:if test="string-length($dim/dim:field[@element='format'][@qualifier='extent'][1]) &gt; 0">
            <span>
                <xsl:text> [</xsl:text>
                <xsl:value-of
                        select="$dim/dim:field[@element='format'][@qualifier='extent'][1]"/>
                <xsl:text>]</xsl:text>
            </span>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
