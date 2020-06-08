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
    xmlns:math="http://www.w3.org/1998/Math/MathML"
    exclude-result-prefixes="svg"
>

<!-- Our simple webpage is processed by MathJax via the mathjax-node-page -->
<!-- program.  This invocation is parameterized by a choice of SVG output -->
<!-- or MathML output.  Either way, the structure of the page is          -->
<!-- identical, so we seem to handle both simultaneously here.  However,  -->
<!-- only one or the other is present.                                    -->

<!-- This is "pure" MathJax output, we leave adjustments to consumers -->

<!-- Entry template, and cruiser -->
<!-- We start here, and at each node, we simply descend, -->
<!-- *unless* some template below kicks into action      -->
<xsl:template match="/|node()|@*">
    <xsl:apply-templates select="node()|@*"/>
</xsl:template>

<!-- We explicitly kill the LaTeX macro div, lest  -->
<!-- it get picked up as similar to the other math -->
<xsl:template match="div[@id = 'latex-macros']"/>

<!-- Body has what we want/need -->
<xsl:template match="body">
    <pi:math-representations>
        <xsl:apply-templates select="node()|@*"/>
        <xsl:text>&#xa;&#xa;</xsl:text>
    </pi:math-representations>
</xsl:template>

<!-- Copy representation out of an extra div/span -->
<!-- The div carries @id and @context to preserve -->
<xsl:template match="div/span">
    <xsl:text>&#xa;&#xa;</xsl:text>
    <pi:math>
        <xsl:copy-of select="../@*"/>
        <xsl:copy-of select="node()"/>
    </pi:math>
</xsl:template>

<!-- SVG font (glyphs) cache -->
<!-- Following depends on font caching behavior      -->
<!-- as passed to  mathjax-node-page  routine        -->
<!--   global cache:  a pile of defs in a single SVG -->
<!--   no caching:  defs are per-SVG, no match here  -->
<!-- NB: need to have this prefixed with "body" to   -->
<!-- identify it as top-level, global situation,     -->
<!-- rather than local to each individual SVG        -->
<xsl:template match="body/svg:svg[svg:defs]">
    <xsl:copy>
        <xsl:attribute name="id">
            <xsl:text>font-data</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
</xsl:template>

</xsl:stylesheet>