<?xml version='1.0'?>

<!--********************************************************************
Copyright 2014-2016 Robert A. Beezer

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

<!-- This stylesheet locates <latex-image> elements    -->
<!-- and wraps them for LaTeX processing               -->
<!-- This includes the LaTeX macros present in docinfo -->
<!-- and the document's docinfo/latex-image-preamble   -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
>

<!-- Get internal ID's for filenames, etc -->
<xsl:import href="./mathbook-common.xsl" />

<!-- Get "scratch" directory        -->
<!-- and a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<!-- Output LaTeX as text -->
<xsl:output method="text" />

<!-- NB: Code between lines of hashes is cut/paste    -->
<!-- from the LaTeX conversion.  Until we do a better -->
<!-- job of ensuring they remain in-sync, please      -->
<!-- coordinate the two sets of templates by hand     -->

<!-- ######################################### -->
<!-- Standard fontsizes: 10pt, 11pt, or 12pt       -->
<!-- extsizes package: 8pt, 9pt, 14pt, 17pt, 20pt  -->
<xsl:param name="latex.font.size" select="'12pt'" />
<!--  -->
<!-- Geometry: page shape, margins, etc            -->
<!-- Pass a string with any of geometry's options  -->
<!-- Default is empty and thus ineffective         -->
<!-- Otherwise, happens early in preamble template -->
<xsl:param name="latex.geometry" select="''"/>

<!-- font-size also dictates document class for -->
<!-- those provided by extsizes, but we can get -->
<!-- these by just inserting the "ext" prefix   -->
<!-- We don't load the package, the classes     -->
<!-- are incorporated in the documentclass[]{}  -->
<!-- and only if we need the extreme values     -->

<!-- Default is 10pt above, this stupid template     -->
<!-- provides an error message and also sets a value -->
<!-- we can condition on for the extsizes package.   -->
<!-- In predicted order, sort of, so fall out early  -->
<xsl:variable name="font-size">
    <xsl:choose>
        <xsl:when test="$latex.font.size='10pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='12pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='11pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='8pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='9pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='14pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='17pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='20pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="yes">MBX:ERROR   the latex.font.size parameter must be 8pt, 9pt, 10pt, 11pt, 12pt, 14pt, 17pt, or 20pt, not "<xsl:value-of select="$latex.font.size" />"</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- A convenient shortcut/hack that might need expansion later   -->
<!-- insert "ext" or nothing in front of "regular" document class -->
<xsl:variable name="document-class-prefix">
    <xsl:choose>
        <xsl:when test="$font-size='10pt'"></xsl:when>
        <xsl:when test="$font-size='12pt'"></xsl:when>
        <xsl:when test="$font-size='11pt'"></xsl:when>
        <xsl:otherwise>
            <xsl:text>ext</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- ######################################### -->


<!-- latex graphics to standalone file        -->
<xsl:template match="image/latex-image-code|image/latex-image">
    <xsl:variable name="filebase">
        <xsl:apply-templates select=".." mode="internal-id" />
    </xsl:variable>
    <exsl:document href="{$scratch}/{$filebase}.tex" method="text">
        <xsl:text>\documentclass[</xsl:text>
        <xsl:value-of select="$font-size" />
        <xsl:text>]{</xsl:text>
        <xsl:value-of select="$document-class-prefix" />
        <xsl:text>article}&#xa;</xsl:text>
        <xsl:text>\usepackage{geometry}&#xa;</xsl:text>
        <!-- ######################################### -->
        <!-- Determine height of text block, assumes US letterpaper (11in height) -->
        <!-- Could react to document type, paper, margin specs                    -->
        <xsl:variable name="text-height">
            <xsl:text>9.0in</xsl:text>
        </xsl:variable>
        <!-- Bringhurst: 30x => 66 chars, so 34x => 75 chars -->
        <xsl:variable name="text-width">
            <xsl:value-of select="34 * substring-before($font-size, 'pt')" />
            <xsl:text>pt</xsl:text>
        </xsl:variable>
        <!-- (These are actual TeX comments in the main document's LaTeX output) -->
        <!-- Text height identically 9 inches, text width varies on point size   -->
        <!-- See Bringhurst 2.1.1 on measure for recommendations                 -->
        <!-- 75 characters per line (count spaces, punctuation) is target        -->
        <!-- which is the upper limit of Bringhurst's recommendations            -->
        <xsl:text>\geometry{letterpaper,total={</xsl:text>
        <xsl:value-of select="$text-width" />
        <xsl:text>,</xsl:text>
        <xsl:value-of select="$text-height" />
        <xsl:text>}}&#xa;</xsl:text>
        <xsl:text>%% Custom Page Layout Adjustments (use latex.geometry)&#xa;</xsl:text>
        <xsl:if test="$latex.geometry != ''">
            <xsl:text>\geometry{</xsl:text>
            <xsl:value-of select="$latex.geometry" />
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <!-- ######################################### -->
        <xsl:text>\usepackage{amsmath,amssymb}&#xa;</xsl:text>
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text">
                <xsl:value-of select="$docinfo/latex-image-preamble"/>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:text>\ifdefined\tikzset&#xa;</xsl:text>
        <xsl:text>\tikzset{ampersand replacement = \amp}&#xa;</xsl:text>
        <xsl:text>\fi&#xa;</xsl:text>
        <xsl:value-of select="$latex-macros" />
        <xsl:text>\begin{document}&#xa;</xsl:text>
        <xsl:text>\pagestyle{empty}&#xa;</xsl:text>
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
        <xsl:text>\end{document}&#xa;</xsl:text>
    </exsl:document>
  </xsl:template>

</xsl:stylesheet>
