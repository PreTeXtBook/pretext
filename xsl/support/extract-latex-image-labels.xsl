<?xml version='1.0'?>

<!--********************************************************************
Copyright 2021-2021 Robert A. Beezer

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


<!-- This stylesheet locates <label> elements in a -->
<!-- <latex-image> and builds an xml document that -->
<!-- records them all. This makes it possible to   -->
<!-- convert labels to Braille to be inserted into -->
<!-- an image file later.                          -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
>

<!-- Get internal ID's for filenames, etc      -->
<!-- This file lives in "support", so look up  -->
<xsl:import href="../pretext-common.xsl" />
<xsl:import href="../pretext-assembly.xsl"/>

<!-- Does not support "subtree" xml:id value   -->

<!-- Output structured XML -->
<xsl:output method="xml" />

<!-- Necessary to get pre-constructed Nemeth braille for math elements. -->
<xsl:param name="mathfile" select="''"/>
<xsl:variable name="math-repr"  select="document($mathfile)/pi:math-representations"/>

<!-- Entry template, and cruiser -->
<!-- We start here, and at each node, we simply descend, -->
<!-- *unless* some template below kicks into action      -->
<xsl:template match="/|node()|@*">
    <xsl:apply-templates select="node()|@*"/>
</xsl:template>

<!-- Create overall shell of structured file of labels -->
<xsl:template match="/pretext">
    <pi:latex-image-labels>
        <xsl:text>&#xa;&#xa;</xsl:text>
        <xsl:apply-templates select="node()|@*"/>
    </pi:latex-image-labels>
</xsl:template>

<!-- Only labels get processed and we copy *only*     -->
<!-- their text nodes and their inline math nodes.    -->
<!-- Record if there is just a single "m" node and    -->
<!-- any stray text nodes are really just whitespace, -->
<!-- we call this "pure math".                        -->
<!-- ids are recorded so that we can place (eventual) -->
<!-- processed labels back into the right place in    -->
<!-- eventual SVG                                     -->
<xsl:template match="latex-image/label">
    <xsl:variable name="pure-math" select="(normalize-space(text()) = '') and (count(m) = 1)"/>
    <pi:latex-image-label>
        <xsl:attribute name="pure-math">
            <xsl:choose>
                <xsl:when test="$pure-math">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>no</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="visible-id"/>
        </xsl:attribute>
        <xsl:apply-templates select="text()|m"/>
    </pi:latex-image-label>
    <xsl:text>&#xa;&#xa;</xsl:text>
</xsl:template>

<!-- xerox each text node -->
<!-- drop any leading or trailing whitespace, which is helpful  -->
<!-- for the case when Nemeth indicators are in use for *some*  -->
<!-- labels that are pure math (perhaps unnecessary)            -->
<xsl:template match="label/text()">
    <xsl:choose>
        <xsl:when test="not(preceding-sibling::node()) and (normalize-space(.) = '')"/>
        <xsl:when test="not(following-sibling::node()) and (normalize-space(.) = '')"/>
        <xsl:otherwise>
            <xsl:value-of select="."/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Preserve inline math nodes, but tag with id in the context of  -->
<!-- entire document, so that we can match with Nemeth braille      -->
<!-- representations from separate math processing run with MathJax -->
<!-- NB: we just drop a marker for math, not including even its     -->
<!-- content, since we are going to fill in with Unicode braille    -->
<!-- from MJ/SRE for eventual use with liblouis.                    -->
<xsl:template match="label/m">
    <xsl:variable name="id">
        <xsl:apply-templates select="." mode="visible-id"/>
    </xsl:variable>
    <xsl:value-of select="$math-repr/pi:math[@id=$id]/div"/>
</xsl:template>

</xsl:stylesheet>
