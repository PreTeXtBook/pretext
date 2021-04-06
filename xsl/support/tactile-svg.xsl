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

<!-- This stylesheet begins with a specially constructed SVG image, -->
<!-- authored in TikZ with minimal PreTeXt elements, that is ready  -->
<!-- to accept BRF content for the labels.                          -->

<!-- SVG "text" element is in the same namespace as the rest of the -->
<!-- graphic, so we set the SVG namespace as the default.  We only  -->
<!-- need the "PreTeXt internal" namespace for reading the label    -->
<!-- file, so we exclude that namespace from the result tree.       -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns="http://www.w3.org/2000/svg"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    exclude-result-prefixes="pi"
>

<!-- Required: necessary to get braille'd labels, Grade 1 + Nemeth -->
<xsl:param name="labelfile" select="''"/>
<xsl:variable name="braille-labels"  select="document($labelfile)/pi:braille-labels"/>

<!-- Optional: defaults to no rectangle, must be precise election -->
<xsl:param name="rectangles" select="''"/>
<xsl:variable name="b-debugging-rectangle" select="$rectangles = 'yes'"/>

<!-- Enter "add-braille" modal template - which might be overkill, -->
<!-- but avoids any accidental processing should a PreTeXt         -->
<!-- stylesheet be imported for some future reason.                -->
<xsl:template match="/">
    <xsl:apply-templates mode="add-braille"/>
</xsl:template>

<xsl:template match="node()|@*" mode="add-braille">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="add-braille"/>
    </xsl:copy>
</xsl:template>

<!-- Add style element early so labels rendered as SVG "text" elements   -->
<!-- with BRF content get rendered with the Braille29 font.  The         -->
<!-- dvisvgm  processing on a LaTeX dvi sets a typographic "point" as    -->
<!-- an SVG "pixel", though there seems to be some scaling to accomodate -->
<!-- a TeX/Knuth point at 72.27 points to the inch, rather than the more -->
<!-- modern 72 points to the inch.                                       -->
<xsl:template match="svg:svg" mode="add-braille">
    <xsl:copy>
        <xsl:apply-templates select="@*" mode="add-braille"/>
        <style>text.braille-label {font-family: Braille29; font-size: 29px}</style>
        <xsl:apply-templates select="node()" mode="add-braille"/>
    </xsl:copy>
</xsl:template>

<!-- Discard the SVG group ("g") marking the rectangle needing  -->
<!-- braille content, and explicitly only process its content.  -->
<xsl:template match="svg:g[@class='PTX-rectangle']" mode="add-braille">
    <!-- only "svg:rect" -->
    <xsl:apply-templates select="svg:rect" mode="add-braille"/>
</xsl:template>

<!-- The main business.  Optionally draw a debugging remnant of the  -->
<!-- SVG rectangle.  Then construct an SVG "text" element.  The      -->
<!-- top-left corner of the rectangle becomes the lower-left corner  -->
<!-- of the text (down is increasing x) by adding the height.  Match -->
<!-- the @id of the rectangle to access the Grade 1 + Nemeth as BRF  -->
<!-- in the precursor $braille-labels.                               -->
<!-- NB: "xsl:element" is necessary (rather than a literal element)  -->
<!-- so the SVG default namespace is recognized and the processor    -->
<!-- knows the containing element is alrready in that namespace.     -->
<!-- If a namespace bleeds through to the  svg:text  element a web   -->
<!-- browser will be confused.                                       -->
<xsl:template match="svg:g[@class='PTX-rectangle']/svg:rect" mode="add-braille">
    <xsl:element name="text">
        <xsl:attribute name="id">
            <xsl:value-of select="parent::*/@id"/>
        </xsl:attribute>
        <xsl:attribute name="class">
            <xsl:text>braille-label</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="x">
            <xsl:value-of select="@x"/>
        </xsl:attribute>
        <xsl:attribute name="y">
            <xsl:value-of select="@y + @height"/>
        </xsl:attribute>
        <xsl:variable name="id" select="../@id"/>
        <xsl:value-of select="$braille-labels/pi:braille-label[@id=$id]"/>
    </xsl:element>
    <xsl:if test="$b-debugging-rectangle">
        <!-- maintain pretty-printing from divsvgm -->
        <xsl:text>&#xa;</xsl:text>
        <!-- A red rectangle that outlines braille cells -->
        <xsl:copy>
            <!-- Just the necessary attributes to draw a rectangle -->
            <xsl:apply-templates select="@x|@y|@height|@width" mode="add-braille"/>
            <!-- Add a very thin red border (not clear if it is inside, outside, etc.) -->
            <xsl:attribute name="style">
                <xsl:text>stroke: red; fill: none; stroke-width: 0.1px;</xsl:text>
            </xsl:attribute>
        </xsl:copy>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>
