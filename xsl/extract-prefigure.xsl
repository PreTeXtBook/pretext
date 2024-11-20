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

<!-- This stylesheet locates <prefigure> elements and copies them for processing -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:pf="https://prefigure.org"
    extension-element-prefixes="exsl"
>

<!-- Get internal ID's for filenames, etc -->
<!-- Standard conversion groundwork       -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>

<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<!-- Output PreFigure XML -->
<xsl:output method="xml" encoding="UTF-8"/>

<!-- PreFigure graphics to standalone file            -->
<!-- NB: don't match the empty element that is a text -->
<!-- generator.  Once PreFigure has a namespace, then -->
<!-- it should be used here instead.                  -->
<xsl:template match="pf:prefigure[node()]" mode="extraction">
    <xsl:variable name="filebase">
        <xsl:apply-templates select="." mode="image-source-basename"/>
    </xsl:variable>
    <!-- Do not use directories here, as Windows paths will get mangled -->
    <!-- Instead, set working directory before applying stylesheet      -->
    <exsl:document href="{$filebase}.xml" method="xml">
        <!-- xerox the "prefigure" element, but with modifications -->
        <xsl:apply-templates select="." mode="prefigure-edit"/>
    </exsl:document>
 </xsl:template>

<!-- Identity template, with a mode, so we can edit a diagram -->
<!-- NB: it does not seem the "pf:" is necessary here         -->
<xsl:template match="node()|@*" mode="prefigure-edit">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="prefigure-edit"/>
    </xsl:copy>
</xsl:template>

<!-- Raison d'etre for "prefigure-edit": insert a PF "caption" -->
<!-- with a figure number when it is correct to do so          -->
<xsl:template match="pf:diagram" mode="prefigure-edit">
    <xsl:copy>
        <xsl:apply-templates select="@*" mode="prefigure-edit"/>
        <!-- insert a PF "caption", if rational to do so                -->
        <!-- NB: explicit hierarchy is necessary, as "ancestor::figure" -->
        <!-- will be fooled by an anonymous panel/image/diagram inside  -->
        <!-- a "sidebyside" inside a #figure                            -->
        <xsl:variable name="containing-figure" select="parent::pf:prefigure/parent::image/parent::figure"/>
        <xsl:if test="$containing-figure">
            <!-- duplicate indentation of first child of "diagram" -->
            <!-- to make insertion of a new first child look good  -->
            <xsl:value-of select="text()[1]"/>
            <xsl:comment>Reference to containing Figure comes from PreTeXt context</xsl:comment>
            <xsl:value-of select="text()[1]"/>
            <xsl:element name="caption" namespace="https://prefigure.org">
                <xsl:apply-templates select="$containing-figure" mode="type-name" />
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="$containing-figure" mode="number"/>
            </xsl:element>
        </xsl:if>
        <xsl:apply-templates select="node()" mode="prefigure-edit"/>
    </xsl:copy>
</xsl:template>

<!-- PreFigure publication file -->
<!-- We need a one-off generation of a PreFigure publication    -->
<!-- file, dumped in the same directory as the extracted source -->
<!-- diagrams.  So we match the *only* guaranteed node and let  -->
<!-- it do its thing, and then create the necessary file.       -->
 <xsl:template match="/">
    <xsl:apply-imports/>
    <exsl:document href="pf_publication.xml" method="xml">
        <xsl:element name="prefigure" namespace="https://prefigure.org">
            <!-- No "prefigure-preamble" => nothing produced       -->
            <xsl:copy-of select="$docinfo/pf:prefigure-preamble/*"/>
            <!-- $latex-macros is never empty (<, >, &) so always a "macros" -->
            <xsl:element name="macros" namespace="https://prefigure.org">
                <!-- move to a new line for minimal readability -->
                <xsl:text>&#xa;</xsl:text>
                <!-- global variable in -common, includes \lt, \gt, \amp -->
                <xsl:value-of select="$latex-macros"/>
            </xsl:element>
        </xsl:element>
    </exsl:document>
</xsl:template>

</xsl:stylesheet>
