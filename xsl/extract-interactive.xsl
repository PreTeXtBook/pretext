<?xml version='1.0'?>

<!--********************************************************************
Copyright 2014-2016 Robert A. Beezer

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

<!-- This stylesheet locates video/@youtube elements and -->
<!-- prepares a Python dictionary necessary to extract a -->
<!-- thumbnail for each video from the YouTube servers   -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl"
>

<!-- Get internal ID's for filenames, etc -->
<!-- Standard conversion groundwork       -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>
<xsl:import href="./pretext-html.xsl"/>

<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<xsl:output method="text" encoding="UTF-8"/>

<!-- @preview indicates custom image is present    -->
<!-- Stylesheet output is text, with "visible-id"  -->
<!-- of each interactive, one per line, to be      -->
<!-- captured in a text file to guide snapshotting -->
<!-- Make the iframe and standalone page for each  -->
<!-- interactive, these are two of the three steps -->
<!-- in the non-modal template for "interactive"   -->
<!-- in pretext-html.xsl.  Results are HTML files  -->
<!-- (despite this stylesheet having text output). -->
<xsl:template match="interactive[not(@preview)]" mode="extraction">
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>&#xa;</xsl:text>
    <!-- (2) Identical content, but now isolated on a reader-friendly page -->
    <xsl:apply-templates select="." mode="standalone-page" >
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="interactive-core" />
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- (3) A simple page that can be used in an iframe construction -->
    <xsl:apply-templates select="." mode="create-iframe-page" />
</xsl:template>

</xsl:stylesheet>
