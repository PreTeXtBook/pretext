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

<!-- This stylesheet locates exercise elements that have  -->
<!-- dynamic content. Create a standalone page for each.  -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl"
>

<!-- Get internal ID's for filenames, etc -->
<!-- Standard conversion groundwork       -->
<xsl:import href="./pretext-html.xsl"/>

<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<!-- We need to alert the pretext-assembly.xsl stylesheet     -->
<!-- that it is being used in the very specific instance      -->
<!-- of extracting these objects for processing externally,   -->
<!-- with results collected in additional files, for          -->
<!-- consultation/collection in a more general use of this    -->
<!-- stylesheet for the purpose of actually building a useful -->
<!-- output format.  This variable declaration here overrides -->
<!-- the default setting of "false" in pretext-assembly.xsl.  -->
<!-- Look there for a more comprehensive discussion of the    -->
<!-- necessity of this scheme.                                -->
<xsl:variable name="b-extracting-fitb" select="true()"/>

<xsl:variable name="b-dynamics-static-seed" select="true()"/>

<xsl:output method="text" encoding="UTF-8"/>

<!-- The  pretext-assembly.xsl  stylesheet is parameterized to create  -->
<!-- representations of interactive exercises in final "static"        -->
<!-- versions or precursor "dynamic" versions.  The conversion to HTML -->
<!-- is the motivation for this parameterization.  See the definition  -->
<!-- of this variable in  pretext-assembly.xsl  for more detail.       -->
<!--                                                                   -->
<!-- Conversions that build on HTML, but produce formats incapable     -->
<!-- (braille) or unwilling (EPUB, Jupyter) to employ Javascript, or   -->
<!-- similar, need to override this variable back to "static".         -->
<xsl:variable name="exercise-style" select="'dynamic'"/>

<!-- exercise/setup indicates the exercise will     -->
<!-- require Runestone and javascript to generate   -->
<!-- the content.                                   -->
<!-- Stylesheet output is text, with "visible-id"   -->
<!-- of each exercise, one per line, to be captured -->
<!-- captured in a text file to guide snapshotting  -->
<!-- Make the standalone page for each exercise     -->
<!-- with an indication that the exercise uses the  -->
<!-- static seed.  Results are HTML files           -->
<!-- (despite this stylesheet having text output).  -->
<xsl:template match="exercise[@exercise-interactive='fillin' and ./setup]
                    | project[@exercise-interactive='fillin' and ./setup]
                    | activity[@exercise-interactive='fillin' and ./setup]
                    | exploration[@exercise-interactive='fillin' and ./setup]
                    | investigation[@exercise-interactive='fillin' and ./setup]"
                    mode="extraction">
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>&#x9;</xsl:text>
    <xsl:choose>
        <xsl:when test="@label">
            <xsl:value-of select="@label"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR:    Dynamic content missing label "<xsl:value-of select="@visible-id"/>"</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <!-- <xsl:value-of select="@label"/> -->
    <xsl:text>&#xa;</xsl:text>
    <!-- (2) Identical content, but now isolated on a reader-friendly page -->
    <xsl:apply-templates select="." mode="standalone-page" >
        <xsl:with-param name="content">
            <xsl:apply-templates select="." />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="exercise[.//task and .//task/@exercise-interactive='fillin' and .//task/setup]
                    | project[.//task and .//task/@exercise-interactive='fillin' and .//task/setup]
                    | activity[.//task and .//task/@exercise-interactive='fillin' and .//task/setup]
                    | exploration[.//task and .//task/@exercise-interactive='fillin' and .//task/setup]
                    | investigation[.//task and .//task/@exercise-interactive='fillin' and .//task/setup]"
                    mode="extraction">
    <!-- filename \t label-identifier -->
    <xsl:variable name="container" select="."/>
    <xsl:for-each select="//task[@exercise-interactive='fillin' and setup]">
        <xsl:apply-templates select="$container" mode="visible-id" />
        <xsl:text>&#x9;</xsl:text>
        <xsl:apply-templates select="." mode="visible-id" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>
    <!-- (2) Identical content, but now isolated on a reader-friendly page -->
    <xsl:apply-templates select="." mode="standalone-page" >
        <xsl:with-param name="content">
            <xsl:apply-templates select="." />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

</xsl:stylesheet>
