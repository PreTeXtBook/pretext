<?xml version='1.0'?>

<!--********************************************************************
Copyright 2026 Robert A. Beezer

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

<!-- This stylesheet locates gdscript/@pck elements and -->
<!-- prepares a file necessary to zip a -->
<!-- pck for each activcode with gdscript   -->

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

<!-- PreTeXt override: Force dynamic exercise processing so that the   -->
<!-- "visible-id" templates calculate IDs matching the interactive web -->
<!-- target rather than a static print target.                        -->
<xsl:variable name="exercise-style" select="'dynamic'"/>


<!-- The default godot version is 4.6.3, this parameter allows         -->
<!-- publishers to use a different version as newer versions become    -->
<!-- available.                                                        -->
<xsl:param name="godot.version" select="'4.6.3'"/>


<!-- Visible id, pck, scene name, and version as a comma-separated quadruple per line -->
<xsl:template match="program[@pck and @interactive='activecode']" mode="extraction">
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>,</xsl:text>
    <xsl:value-of select="@pck" />
    <xsl:text>,</xsl:text>
    <xsl:value-of select="@scene" />
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$godot.version" />
    <xsl:text>&#xa;</xsl:text> <!-- newline -->
</xsl:template>
</xsl:stylesheet>
