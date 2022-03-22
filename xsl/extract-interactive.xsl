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

<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<xsl:output method="text" encoding="UTF-8"/>

<!-- Sneak in baseurl as first item, with -->
<!-- interactive info on subsequent lines -->
<xsl:template match="/">
    <xsl:value-of select="$baseurl"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-imports />
</xsl:template>

<!-- "visible-id" of each interactive per line -->
<!-- @preview indicates custom image  -->
<xsl:template match="interactive[not(@preview)]" mode="extraction">
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
