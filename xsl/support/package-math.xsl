<?xml version='1.0'?>

<!--********************************************************************
Copyright 2020 Robert A. Beezer

This file is part of PreTeXt.

PreTeXt is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

PreTeXt is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<!-- This stylesheet expects the XHTML built by the  extract-math.xsl -->
<!-- stylesheet, which looks like a standard web page (and may be     -->
<!-- viewable as such).  It gets repackaged with PreTeXt internal     -->
<!-- elements (in a different namespace) that looks like              -->
<!--                                                                  -->
<!-- pi:math-representations                                          -->
<!--   pi:math                                                        -->
<!--   ...                                                            -->
<!--   pi:math                                                        -->
<!--   svg/defs                                                       -->
<!--                                                                  -->
<!-- The multiple  pi:math  elements have                             -->
<!--   @id: matches the id of its progenitor in the source            -->
<!--   @context: element of progenitor (m|me|men|md|mdn)              -->
<!--   content: an SVG version                                        -->
<!--                                                                  -->
<!-- The final element is a font cache, which                         -->
<!-- has the @id attribute value "font-data"                          -->

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:svg="http://www.w3.org/2000/svg"
    exclude-result-prefixes="svg"
>

<!-- Entry template -->
<xsl:template match="/">
    <xsl:apply-templates select="node()|@*"/>
</xsl:template>

<!-- Elements to unwap/discard    -->
<!-- Don't select its attributes! -->
<xsl:template match="html|head|style|div[span]|span[svg:svg]">
    <xsl:apply-templates select="node()"/>
</xsl:template>

<!-- Elements to remove, *including* interior content -->
<xsl:template match="style|div[@id = 'latex-macros']"/>

<!-- Attributes to remove -->
<!-- epubcheck 4.0.2 complains about these for EPUB 3.0.1 -->
<!-- Each match appears to be once per math-SVG           -->
<!-- TODO: switch this packaging stylesheet on output target -->
<!-- OR: move to the EPUB packaging stylesheet               -->
<xsl:template match="svg:svg/@focusable|svg:svg/@role|svg:svg/@aria-labelledby"/>
<!-- Per-image, when fonts are included -->
<xsl:template match="svg:svg/svg:defs/@aria-hidden"/>
<!-- Per-font-cache, when fonts are consolidated -->
<xsl:template match="svg:svg/svg:g/@aria-hidden"/>

<!-- Body has what we want/need -->
<xsl:template match="body">
    <pi:math-representations>
        <xsl:apply-templates select="node()|@*"/>
    </pi:math-representations>
</xsl:template>

<!-- Unwind MathJax SVG wrapped in an extra div -->
<!-- The div carries @id and @context           -->
<xsl:template match="div/span/svg:svg">
    <pi:math>
        <xsl:copy-of select="../../@*"/>
        <xsl:copy>
            <!-- allowing surgery on the SVG -->
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </pi:math>
</xsl:template>

<!-- SVG font (glyphs) cache -->
<!-- Following depends on font caching behavior      -->
<!-- as passed to  mathjax-node-page routine         -->
<!--   global cache:  a pile of defs in a single SVG -->
<!--   no caching:  defs are per-SVG                 -->
<!-- NB: need to have this prefixed with "body" to   -->
<!-- identify it as top-level, global situation      -->
<xsl:template match="body/svg:svg[svg:defs]">
    <xsl:copy>
        <xsl:attribute name="id">
            <xsl:text>font-data</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
</xsl:template>

<!-- Identity -->
<xsl:template match="node()|@*">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
</xsl:template>

</xsl:stylesheet>