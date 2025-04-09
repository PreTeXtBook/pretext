<?xml version='1.0'?>

<!--********************************************************************
Copyright 2022 Robert A. Beezer

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

<!-- This stylesheet locates "program" elements to render as -->
<!-- CodeLens for interactive execution.  The code itself is -->
<!-- processed into a trace by the  pretext/pretext  script. -->
<!-- It produces text output, with one line per program:     -->
<!--                                                         -->
<!--     visible-id, language, source                        -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="str"
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

<!-- YouTube ID, and internal id as a comma-separated pair per line -->
<xsl:template match="program[@interactive = 'codelens']" mode="extraction">
    <xsl:apply-templates select="." mode="runestone-id"/>
    <xsl:text>,</xsl:text>
    <xsl:apply-templates select="." mode="visible-id"/>
    <xsl:text>,</xsl:text>
    <xsl:apply-templates select="." mode="active-language"/>
    <xsl:text>,</xsl:text>
    <xsl:variable name="code-with-newlines">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="code" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="removed-carriage-returns">
        <xsl:value-of select="str:replace($code-with-newlines, '&#xd;', '')" />
    </xsl:variable>
    <xsl:value-of select="str:replace($removed-carriage-returns, '&#xa;', '\n')"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
