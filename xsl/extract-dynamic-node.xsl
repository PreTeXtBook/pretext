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
<xsl:import href="./pretext-runestone-fitb.xsl"/>

<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

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
<xsl:template match="*" mode="extraction-wrapper">
    <xsl:text>[ { "exercise_id": null }</xsl:text>
    <xsl:apply-templates select="." mode="extraction"/>
    <xsl:text>]</xsl:text>
</xsl:template>

<xsl:template match="exercise[@exercise-interactive='fillin' and setup]
                    | project[@exercise-interactive='fillin' and setup]
                    | activity[@exercise-interactive='fillin' and setup]
                    | exploration[@exercise-interactive='fillin' and setup]
                    | investigation[@exercise-interactive='fillin' and setup]
                    | exercise//task[@exercise-interactive='fillin' and setup]
                    | project//task[@exercise-interactive='fillin' and setup]
                    | activity//task[@exercise-interactive='fillin' and setup]
                    | exploration//task[@exercise-interactive='fillin' and setup]
                    | investigation//task[@exercise-interactive='fillin' and setup]"
                    mode="extraction">
    <xsl:text>,&#xa;</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:text>  "exercise_id": "</xsl:text>
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>",&#xa;</xsl:text>
    <xsl:text>  "exercise_setup": </xsl:text>
    <xsl:call-template name="dynamic-setup" />
    <xsl:text>,&#xa;</xsl:text>
    <xsl:text>  "exercise_seed": "</xsl:text>
    <xsl:choose>
        <xsl:when test="setup[@seed]">
            <xsl:value-of select="setup/@seed"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>1234</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>",&#xa;</xsl:text>
    <xsl:text>  "exercise_evals": [</xsl:text>
    <xsl:for-each select="(statement|solution)//eval[@obj]|evaluation//feedback//eval[@obj]|statement//fillin[@ansobj]">
        <xsl:if test="position() > 1">
            <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="@obj">
                <xsl:text>"</xsl:text>
                <xsl:value-of select="@obj"/>
                <xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:when test="@ansobj">
                <xsl:text>"</xsl:text>
                <xsl:value-of select="@ansobj"/>
                <xsl:text>"</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:for-each>
    <xsl:text>]</xsl:text>
    <xsl:text>}</xsl:text>
</xsl:template>

</xsl:stylesheet>
