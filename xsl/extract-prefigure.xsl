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

<!-- PreFigure graphics to standalone file           -->
<xsl:template match="prefigure" mode="extraction">
    <xsl:variable name="filebase">
        <xsl:apply-templates select="." mode="image-source-basename"/>
    </xsl:variable>
    <!-- Do not use directories here, as Windows paths will get mangled -->
    <!-- Instead, set working directory before applying stylesheet      -->
    <exsl:document href="{$filebase}.xml" method="xml">
        <!-- Adjust how root "prefigure" element is handled if we        -->
        <!-- want to insert some preamble material or some LaTeX macros. -->
        <!-- <xsl:value-of select="$latex-macros" />                     -->
        <!-- NB: maybe we want to xerox contents from "assembly" and trash supefluous id's? -->
        <xsl:copy-of select="."/>
    </exsl:document>
 </xsl:template>

</xsl:stylesheet>
