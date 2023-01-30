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

<!-- This stylesheet locates instance of binary files in   -->
<!-- need of base64 (textual) representations, basically   -->
<!-- the first step in a translation from "external" files -->
<!-- to "generated" files                                  -->

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

<!-- The default "exercise-style" is "static". For data files, -->
<!-- we will form a different representation, and pass through -->
<!-- the authored version for a dynamic representation.        -->
<xsl:variable name="exercise-style" select="'dynamic'"/>

<!-- Note: identifiers from @label on enclosing "datafile" -->

<!-- One line per file; an id to coordinate use      -->
<!-- and a path within the "extrnal" directory tree. -->
<!-- First: image files in a "datafile" element      -->
<!-- Second: text files given by external file       -->
<xsl:template match="datafile/image|datafile/pre[@source]" mode="extraction">
    <!-- 1. identifier -->
    <xsl:apply-templates select=".." mode="visible-id" />
    <xsl:text> </xsl:text>
    <!-- 2. Type from element used (image, pre) -->
    <xsl:value-of select="local-name()"/>
    <xsl:text> </xsl:text>
    <!-- 3. path relative to external directory   -->
    <!--    only from files, always has a @source -->
    <xsl:value-of select="@source"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
