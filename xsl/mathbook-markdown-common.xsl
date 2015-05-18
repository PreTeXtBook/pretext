<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2013 Robert A. Beezer

This file is part of MathBook XML.

MathBook XML is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

MathBook XML is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace" 
>


<!-- MathBook XML common templates  -->
<!-- For any conversion to Markdown -->

<!-- So output methods here are just text -->
<xsl:output method="text" />



<!-- backticks for monospace font -->
<xsl:template match="c">
    <xsl:text>`</xsl:text>
    <xsl:apply-templates />
    <xsl:text>`</xsl:text>
</xsl:template>

<!-- italics for emphasis, matches default LaTeX -->
<xsl:template match="em">
    <xsl:text>*</xsl:text>
    <xsl:apply-templates />
    <xsl:text>*</xsl:text>
</xsl:template>

<!-- two spaces, hard return -->
<xsl:template match="br">
    <xsl:text>  #xa;</xsl:text>
</xsl:template>

<!-- nothing special for quotes -->
<xsl:template match="q">
    <xsl:text>"</xsl:text>
    <xsl:apply-templates />
    <xsl:text>"</xsl:text>
</xsl:template>

<!-- URLs, href mandatory, content  -->
<!-- optional, defaults to href     -->
<xsl:template match="url">
    <xsl:text>[</xsl:text>
    <xsl:choose>
        <xsl:when test="not(*) and not(normalize-space())">
            <xsl:value-of select="@href" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>](</xsl:text>
    <xsl:value-of select="@href" />
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- email to a mailto: URL -->
<xsl:template match="email">
    <xsl:text>[</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>](mailto:</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>)</xsl:text>
</xsl:template>    






<!-- Lists -->
<!--<xsl:template match="ul|ol|dl">
    <xsl:variable name="new-indentation" select="concat($indentation, '    ')" />
    <xsl:variable name="indentation" select="$new-indentation" />


<xsl:template>

<xsl:template name="process-list-contents"-->

</xsl:stylesheet>