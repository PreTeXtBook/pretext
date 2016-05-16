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

<!-- This should eventually be obsolete. The tikz element has been superceded with latex-image-code.  -->
<!-- New authors shouldn't be using "tikz" tags. But this can stay a while for backwards compat.      -->
<!-- Once this is ready for removal, the body of the mbx script should be simplified too.             -->

<!-- This stylesheet locates <tikz> elements           -->
<!-- and wraps them for LaTeX processing               -->
<!-- This includes the LaTeX macros present in docinfo -->
<!-- TODO: integrate a tikz.preamble into this and main LaTeX processing (in common file) -->

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

<!-- Output tikz/LaTeX as text -->
<xsl:output method="text" />

<!-- tikz graphics to standalone file        -->
<!-- Default border of 0.5bp seems too small -->
<!-- http://tex.stackexchange.com/questions/51757/how-can-i-use-tikz-to-make-standalone-graphics -->
<xsl:template match="image/tikz">
    <xsl:variable name="filebase">
        <xsl:apply-templates select=".." mode="internal-id" />
    </xsl:variable>
    <exsl:document href="{$scratch}/{$filebase}.tex" method="text">
        <xsl:text>\documentclass[12pt,border=2pt]{standalone}&#xa;</xsl:text>
        <xsl:text>\usepackage{amsmath,amssymb}&#xa;</xsl:text>
        <xsl:value-of select="$latex-macros" />
        <xsl:text>\usepackage{tikz}&#xa;</xsl:text>
        <xsl:text>\usetikzlibrary{backgrounds}&#xa;</xsl:text>
        <xsl:text>\usetikzlibrary{arrows,matrix}&#xa;</xsl:text>
        <xsl:text>\begin{document}&#xa;</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>\end{document}&#xa;</xsl:text>
    </exsl:document>
  </xsl:template>

<!-- ################################## -->
<!-- Deprecated Graphics Code Templates -->
<!-- ################################## -->
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="tikz">
    <xsl:variable name="filebase">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <exsl:document href="{$scratch}/{$filebase}.tex" method="text">
        <xsl:text>\documentclass[12pt,border=2pt]{standalone}&#xa;</xsl:text>
        <xsl:text>\usepackage{amsmath,amssymb}&#xa;</xsl:text>
        <xsl:value-of select="$latex-macros" />
        <xsl:text>\usetikzlibrary{backgrounds}&#xa;</xsl:text>
        <xsl:text>\usetikzlibrary{arrows,matrix}&#xa;</xsl:text>
        <xsl:text>\begin{document}&#xa;</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>\end{document}&#xa;</xsl:text>
    </exsl:document>
  </xsl:template>
<!-- ################################## -->
<!-- Deprecated Graphics Code Templates -->
<!-- ################################## -->

</xsl:stylesheet>
