<?xml version='1.0'?>

<!--********************************************************************
Copyright 2018 Robert A. Beezer

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

<!-- Conveniences for classes of similar elements -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "../entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<!-- Override specific tenplates of the standard conversion -->
<xsl:import href="../mathbook-latex.xsl" />

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="text" />

<!-- "commentary" -->
<!-- No options, so whatever is default tcolorbox -->
<xsl:template match="commentary" mode="tcb-style">
    <xsl:text/>
</xsl:template>

<!-- "objectives", "outcomes" -->
<!-- Green and ugly, plus identical, via the dual match -->
<xsl:template match="objectives|outcomes" mode="tcb-style">
    <xsl:text>size=minimal, attach title to upper, after title={\space}, fonttitle=\bfseries, coltitle=black, colback=green</xsl:text>
</xsl:template>

<!-- DEFINITION-LIKE: "definition"   -->
<!-- Various extreme choices from the tcolorbox documentation -->
<!-- Note: a trailing comma is OK, and maybe a good idea      -->
<!-- Note: the style definition may split across several line -->
<!-- of the LaTeX source using the hex A (dec 10) character   -->
<!-- Note: "enhanced" is necessary for boxed titles           -->
<xsl:template match="&DEFINITION-LIKE;" mode="tcb-style">
    <xsl:text>enhanced, arc=4mm,outer arc=1mm,colback=pink,&#xa;</xsl:text>
    <xsl:text>attach boxed title to top center={yshift=-\tcboxedtitleheight/2},&#xa;</xsl:text>
    <xsl:text>boxed title style={size=small,colback=blue},&#xa;</xsl:text>
</xsl:template>

<!-- REMARK-LIKE: "remark", "convention", "note",   -->
<!--            "observation", "warning", "insight" -->
<!-- COMPUTATION-LIKE: "computation", "technology"  -->
 <!--White title text, but title backgounds vary    -->
 <!--by category, and remarks have sharp corners    -->
<xsl:template match="&REMARK-LIKE;" mode="tcb-style">
    <xsl:text>colbacktitle=red, sharp corners</xsl:text>
</xsl:template>
<xsl:template match="&COMPUTATION-LIKE;" mode="tcb-style">
    <xsl:text>colbacktitle=blue</xsl:text>
</xsl:template>

<!-- EXAMPLE-LIKE: "example", "question", "problem" -->
<!-- Default tcolorbox, but with tricolor titles    -->
<!-- Each just slightly different                   -->
<xsl:template match="example" mode="tcb-style">
    <xsl:text>coltitle=red</xsl:text>
</xsl:template>
<xsl:template match="question" mode="tcb-style">
    <xsl:text>coltitle=blue</xsl:text>
</xsl:template>
<xsl:template match="problem" mode="tcb-style">
    <xsl:text>coltitle=yellow</xsl:text>
</xsl:template>


</xsl:stylesheet>

