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

<!-- This stylesheet locates <asymptote> elements          -->
<!-- and wraps them for processing by the "asy" exectuable -->
<!-- This includes the LaTeX macros present in docinfo     -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace" 
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
>

<!-- Get internal ID's for filenames, etc -->
<xsl:import href="./mathbook-common.xsl" />

<!-- Get "scratch" directory        -->
<!-- and a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<!-- Output Asymptote code as text -->
<xsl:output method="text" />

<!-- Asymptote graphics to standalone file           -->
<!-- Prepend document's macros, otherwise no changes -->
<xsl:template match="image/asymptote">
    <xsl:variable name="filebase">
        <xsl:apply-templates select=".." mode="internal-id" />
    </xsl:variable>
    <exsl:document href="{$scratch}/{$filebase}.asy" method="text">
        <xsl:text>texpreamble("&#xa;</xsl:text>
        <xsl:value-of select="$latex-macros" />
        <xsl:text>");&#xa;&#xa;</xsl:text>
        <xsl:value-of select="."/>
    </exsl:document>
 </xsl:template>

<!-- ################################## -->
<!-- Deprecated Graphics Code Templates -->
<!-- ################################## -->
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="asymptote">
    <xsl:variable name="filebase">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <exsl:document href="{$scratch}/{$filebase}.asy" method="text">
        <xsl:text>texpreamble("&#xa;</xsl:text>
        <xsl:value-of select="$latex-macros" />
        <xsl:text>");&#xa;&#xa;</xsl:text>
        <xsl:value-of select="."/>
    </exsl:document>
 </xsl:template>
<!-- ################################## -->
<!-- Deprecated Graphics Code Templates -->
<!-- ################################## -->

</xsl:stylesheet>
