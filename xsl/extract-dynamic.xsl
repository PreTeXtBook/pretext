<?xml version='1.0'?>

<!--********************************************************************
Copyright (C) 2014-2026  Robert A. Beezer

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
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    exclude-result-prefixes="pi"
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
<!-- Stylesheet output is text, with "unique-id"    -->
<!-- of each exercise, one per line, to be captured -->
<!-- captured in a text file to guide snapshotting  -->
<!-- Make the standalone page for each exercise     -->
<!-- with an indication that the exercise uses the  -->
<!-- static seed.  Results are HTML files           -->
<!-- (despite this stylesheet having text output).  -->
<xsl:template match="*" mode="extraction-wrapper">
    <xsl:text>{&#xa;</xsl:text>
    <!-- Remote libraries the publisher has approved for execution   -->
    <!-- during a static build.  See "remote-library-allowlist" in   -->
    <!-- publisher-variables.xsl for why this gate exists.  An empty -->
    <!-- list means no exercise may import a library by @url.        -->
    <xsl:text>"allowed_remote": [</xsl:text>
    <xsl:for-each select="$remote-library-allowlist">
        <xsl:if test="position() > 1">
            <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:call-template name="escape-quote-string">
            <xsl:with-param name="text" select="@url"/>
        </xsl:call-template>
    </xsl:for-each>
    <xsl:text>],&#xa;</xsl:text>
    <xsl:text>"exercises": [ { "exercise_id": null }</xsl:text>
    <xsl:apply-templates select="." mode="extraction"/>
    <xsl:text>]&#xa;}</xsl:text>
</xsl:template>

<xsl:template match="exercise[@pi:exercise-interactive='fillin' and setup]
                    | project[@pi:exercise-interactive='fillin' and setup]
                    | activity[@pi:exercise-interactive='fillin' and setup]
                    | exploration[@pi:exercise-interactive='fillin' and setup]
                    | investigation[@pi:exercise-interactive='fillin' and setup]
                    | exercise//task[@pi:exercise-interactive='fillin' and setup]
                    | project//task[@pi:exercise-interactive='fillin' and setup]
                    | activity//task[@pi:exercise-interactive='fillin' and setup]
                    | exploration//task[@pi:exercise-interactive='fillin' and setup]
                    | investigation//task[@pi:exercise-interactive='fillin' and setup]"
                    mode="extraction">
    <xsl:text>,&#xa;</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:text>  "exercise_id": "</xsl:text>
    <!-- Key the round trip on @pi:assembly-id, the early identifier the-->
    <!-- substitution pass reads back.  @label only exists for labeled  -->
    <!-- exercises, so it would miss unlabeled exercises and tasks.      -->
    <xsl:apply-templates select="." mode="assembly-id" />
    <xsl:text>",&#xa;</xsl:text>
    <!-- The @assembly-id above is what the substitution pass reads   -->
    <!-- back, but it means nothing to an author.  Carry the          -->
    <!-- @unique-id alongside it purely so that a failure during      -->
    <!-- evaluation can name the exercise the way the author sees it. -->
    <xsl:text>  "exercise_unique_id": "</xsl:text>
    <xsl:apply-templates select="." mode="unique-id" />
    <xsl:text>",&#xa;</xsl:text>
    <!-- Packages and libraries this exercise's setup depends on.     -->
    <!-- This mirrors the "dyn_imports" array of the HTML version,    -->
    <!-- including its leading "BTM", which the substitution script   -->
    <!-- matches as a literal and resolves to the npm package, just   -->
    <!-- as the Runestone component does.  Keeping the two arrays     -->
    <!-- identical means an exercise that loads in a browser loads    -->
    <!-- the same way under Node.                                     -->
    <xsl:text>  "exercise_imports": [</xsl:text>
    <xsl:text>"BTM"</xsl:text>
    <xsl:for-each select="setup/jsimports/jslibrary">
        <xsl:variable name="import-path">
            <xsl:apply-templates select="." mode="js-import-path"/>
        </xsl:variable>
        <xsl:if test="string-length($import-path) > 0">
            <xsl:text>, </xsl:text>
            <xsl:call-template name="escape-quote-string">
                <xsl:with-param name="text" select="$import-path"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:for-each>
    <xsl:text>],&#xa;</xsl:text>
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
    <!-- Everything the static version needs a value for.  Each entry -->
    <!-- is the @obj (or @ansobj) verbatim, which is a Javascript     -->
    <!-- *expression*, not merely a variable name: the HTML version   -->
    <!-- drops the same string into a template as  [%= ... %] , so    -->
    <!-- "_config.date" and the like have to evaluate, not be looked  -->
    <!-- up.  The substitution script evaluates each one in the scope -->
    <!-- left behind by the setup.  Duplicates are harmless; they     -->
    <!-- collapse to one entry there.                                 -->
    <xsl:text>  "exercise_evals": [</xsl:text>
    <xsl:for-each select="(statement|solution)//eval[@obj]|evaluation//test[@correct='yes']/feedback//eval[@obj]|statement//fillin[@ansobj]">
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
