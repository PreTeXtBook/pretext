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
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
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

<!-- We look for the tokens " import " and " graph3 " on     -->
<!-- the same line of Asymptote source, signifying that      -->
<!-- 3D, WebGL, HTML output is indicated.  We assume         -->
<!-- lines are separated by newlines - this is not           -->
<!-- accurate when control structures are employed           -->
<!-- (e.g. "for" loops).  Furthermore, a module can be       -->
<!-- loaded with "access", and with a "from/access"          -->
<!-- directive.  Futher still, a module can be specified     -->
<!-- by a file path (which this routine does not recognize). -->
<!-- Finally, a comment line is not recognized as such.      -->
<!-- The routine is recursive, and we halt with an empty     -->
<!-- string, so the first call should have a newline as      -->
<!-- the final character. -->
<!-- The template produces string "2D" or "3D".              -->
<xsl:template name="asymptote-3d">
    <xsl:param name="code"/>

    <xsl:variable name="raw-line" select="substring-before($code, '&#xa;')"/>
    <xsl:variable name="spaced-line" select="str:replace(str:replace($raw-line, ';', ' ;'), ',', ' ,')"/>
    <xsl:variable name="line"  select="concat('&#x20;', normalize-space($spaced-line), '&#x20;')"/>
    <!-- <xsl:message>L:<xsl:value-of select="$line"/>:L</xsl:message> -->
    <xsl:choose>
        <!-- terminating newline of input, means final recursion -->
        <!-- is empty, and we never found a 3D indicator         -->
        <xsl:when test="$code = ''">
            <xsl:text>2D</xsl:text>
        </xsl:when>
        <!-- found 3D indicator, report and halt -->
        <xsl:when test="contains($line, ' import ') and contains($line, ' graph3 ')">
            <xsl:text>3D</xsl:text>
        </xsl:when>
        <xsl:when test="contains($line, ' import ') and contains($line, ' three ')">
            <xsl:text>3D</xsl:text>
        </xsl:when>
        <!-- otherwise, recurse to get next line -->
        <xsl:otherwise>
            <xsl:call-template name="asymptote-3d">
                <xsl:with-param name="code" select="substring-after($code, '&#xa;')"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Asymptote graphics to standalone file           -->
<!-- Prepend document's macros, otherwise no changes -->
<xsl:template match="image/asymptote">
    <xsl:variable name="filebase">
        <xsl:apply-templates select=".." mode="visible-id" />
    </xsl:variable>
    <!-- output a Python 2-tuple, with separators, etc -->
    <!--   (filename, '2D'|'3D'),                      -->
    <!-- for use in Python mbx script                  -->
    <!-- will need list structure upon receipt         -->
    <xsl:text>('</xsl:text>
    <xsl:value-of select="$filebase"/>
    <xsl:text>.asy'</xsl:text>
    <xsl:text>, '</xsl:text>
    <!-- construct dimension of diagram for "mbx" script -->
    <xsl:choose>
        <!-- author-provided as authoritative -->
        <xsl:when test="@dimension = 2">
            <xsl:text>2D</xsl:text>
        </xsl:when>
        <xsl:when test="@dimension = 3">
            <xsl:text>3D</xsl:text>
        </xsl:when>
        <!-- otherwise, make an intelligent guess, -->
        <!-- including bad input in attribute      -->
        <xsl:otherwise>
            <xsl:call-template name="asymptote-3d">
                <xsl:with-param name="code" select="concat(., '&#xa;')"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>'), </xsl:text>
    <exsl:document href="{$scratch}/{$filebase}.asy" method="text">
        <xsl:text>usepackage("amsmath");&#xa;</xsl:text>
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
        <xsl:apply-templates select="." mode="visible-id" />
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
