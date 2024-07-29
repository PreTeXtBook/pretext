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
<!-- and the $latex-image-preamble from common.        -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="pi exsl"
>

<!-- Get internal ID's for filenames, etc -->
<!-- Standard conversion groundwork -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>

<!-- We use some common code to make the actual LaTeX code used      -->
<!-- for the image.  The extract-identity stylesheet will override   -->
<!-- the entry template, so we just access some templates as needed. -->
<xsl:import href="./pretext-latex.xsl"/>

<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<!-- Output LaTeX as text -->
<xsl:output method="text" encoding="UTF-8"/>

<!-- LaTeX graphics to a standalone file for subsequent processing.     -->
<!-- Intercept "extraction" process in extract-identity.xsl stylesheet. -->
<xsl:template match="image[latex-image]" mode="extraction">
    <xsl:variable name="filebase">
        <xsl:apply-templates select="latex-image" mode="image-source-basename"/>
    </xsl:variable>
    <!-- Do not use directories here, as Windows paths will get mangled -->
    <!-- Instead, set working directory before applying stylesheet      -->
    <exsl:document href="{$filebase}.tex" method="text">
        <xsl:text>\documentclass[</xsl:text>
        <xsl:value-of select="$font-size" />
        <xsl:text>]{</xsl:text>
        <xsl:value-of select="$document-class-prefix" />
        <xsl:text>article}&#xa;</xsl:text>
        <xsl:text>\usepackage{geometry}&#xa;</xsl:text>
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
        <xsl:text>%% Custom Page Layout Adjustments (use publisher page-geometry)&#xa;</xsl:text>
        <xsl:if test="$latex-page-geometry != ''">
            <xsl:text>\geometry{</xsl:text>
            <xsl:value-of select="$latex-page-geometry" />
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:text>\usepackage{amsmath,amssymb}&#xa;</xsl:text>
        <xsl:value-of select="$latex-image-preamble"/>
        <xsl:text>\ifdefined\tikzset&#xa;</xsl:text>
        <xsl:text>\tikzset{ampersand replacement = \amp}&#xa;</xsl:text>
        <xsl:text>\fi&#xa;</xsl:text>
        <xsl:value-of select="$latex-macros" />
        <xsl:text>\begin{document}&#xa;</xsl:text>
        <xsl:text>\pagestyle{empty}&#xa;</xsl:text>
        <!-- The "latex-image" template is in  pretext-latex.xsl      -->
        <xsl:variable name="the-latex-image">
            <xsl:apply-templates select="latex-image"/>
        </xsl:variable>
        <!-- NB: this spurious box is designed to make           -->
        <!-- processing here match more closely what happens in  -->
        <!-- a PDF build, where an image is scrunched into a     -->
        <!-- functional resizing box of given width and          -->
        <!-- preserved aspect-ratio.                             -->
        <xsl:text>\resizebox{\width}{\height}{&#xa;</xsl:text>
        <xsl:value-of select="$the-latex-image"/>
        <xsl:text>}&#xa;</xsl:text>
         <xsl:text>\end{document}&#xa;</xsl:text>
    </exsl:document>
</xsl:template>

</xsl:stylesheet>
