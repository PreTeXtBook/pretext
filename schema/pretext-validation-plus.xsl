<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2020 Robert A. Beezer

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

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!-- NB: directories affect location -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "../xsl/entities.ent">
    %entities;
]>
<!-- Identify as a stylesheet -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace">

<!-- Report on console, or redirect/option to a file -->
<xsl:output method="text"/>

<!-- Walk the tree, so messages appear in document order, not topically.  -->
<!-- Be sure to recurse into larger elements after interrupting to        -->
<!-- process certain situations.  This is not necessary for templates     -->
<!-- matching attributes or elements guarnteed to be empty and without    -->
<!-- any attributes, ever.                                                -->
<!--                                                                      -->
<!-- Sections:                                                            -->
<!--   * Deprecations:                                                    -->
<!--       moved here once old, to minimize usual start-up times,         -->
<!--       includes explanations of necessity and alternatives,           -->
<!--   * Real-Time Checks:                                                -->
<!--       items the usual schema checking cannot compute                 -->
<!--   * WeBWorK:                                                         -->
<!--       WW-specific items that the schema suggests are OK, but are not -->

<!-- ############ -->
<!-- Deprecations -->
<!-- ############ -->

<!-- Comments are copied from original warnings in -common templates -->

<!-- 2014-05-04  @filebase has been replaced in function by @xml:id -->
<!-- 2018-07-21  remove all relevant code                           -->
<xsl:template match="@filebase">
    <xsl:apply-templates select="parent::*" mode="messaging">
        <xsl:with-param name="severity" select="'error'"/>
        <xsl:with-param name="message">
            <xsl:text>The @filebase attribute is deprecated (2014-05-04) and no code&#xa;</xsl:text>
            <xsl:text>remains (2018-07-21), convert to using @xml:id for this purpose</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- 2014-06-25  xref once had cite as a variant -->
<!-- 2018-07-21  remove all relevant code        -->
<xsl:template match="cite">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'error'"/>
        <xsl:with-param name="message">
            <xsl:text>The &lt;cite&gt; element is deprecated (2014-06-25) and no&#xa;</xsl:text>
            <xsl:text>code remains (2018-07-21), convert to an &lt;xref&gt;</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<!-- 2015-01-28  once both circum and circumflex existed, circumflex won -->
<!-- 2018-07-21  remove all relevant code                                -->
<xsl:template match="circum">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'error'"/>
        <xsl:with-param name="message">
            <xsl:text>The &lt;circum&gt; element is deprecated (2015-01-28) and no&#xa;</xsl:text>
            <xsl:text>code remains (2018-07-22), convert to a &lt;circumflex&gt;</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- 2017-12-21 remove sage/@copy               -->
<!-- 2021-02-25 remove all code due to id() use -->
<xsl:template match="sage[@copy]">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'error'"/>
        <xsl:with-param name="message">
            <xsl:text>@copy on a &quot;sage&quot; element was deprecated (2017-12-21)</xsl:text>
            <xsl:text>Use the xinclude mechanism with common code in an external file</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- 2017-12-21 remove image/@copy              -->
<!-- 2021-02-25 remove all code due to id() use -->
<xsl:template match="image[@copy]">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'error'"/>
        <xsl:with-param name="message">
            <xsl:text>@copy on an &quot;image&quot; element was deprecated (2017-12-21)</xsl:text>
            <xsl:text>Perhaps use the xinclude mechanism with common code in an external file</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>


<!-- ################ -->
<!-- Real-Time Checks -->
<!-- ################ -->

<!-- Checks that the schema cannot perform since some -->
<!-- sort of look-up or source analysis is necessary  -->

<!-- More information about an "author" is achieved   -->
<!-- with a cross-reference to a "contributor". Only. -->
<xsl:template match="author/xref">
    <xsl:if test="not(id(@ref)/self::contributor)">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>An &lt;xref&gt; within an &lt;author&gt; is meant to point&#xa;</xsl:text>
                <xsl:text>to a &lt;contributor&gt;, not to a &lt;</xsl:text>
                <xsl:value-of select="local-name(id(@ref))"/>
                <xsl:text>&gt;</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<!-- Docinfo should have at most one latex-image-preamble -->
<!-- of each value for @syntax (including no @syntax)     -->
<xsl:template match="latex-image-preamble[not(@syntax)][1]">
    <xsl:if test="count(parent::docinfo/latex-image-preamble[not(@syntax)]) > 1">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>There should be at most one &lt;latex-image-preamble&gt; without a&#xa;</xsl:text>
                <xsl:text>@syntax within the &lt;docinfo&gt; element. There are more than one,&#xa;</xsl:text>
                <xsl:text>and they should be consolidated.</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="latex-image-preamble[@syntax = 'PGtikz'][1]">
    <xsl:if test="count(parent::docinfo/latex-image-preamble[@syntax = 'PGtikz']) > 1">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>There should be at most one &lt;latex-image-preamble&gt; with @syntax&#xa;</xsl:text>
                <xsl:text>having value 'PGtikz' within the &lt;docinfo&gt; element. There are&#xa;</xsl:text>
                <xsl:text>more than one, and they should be consolidated.</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<!-- ########## -->
<!-- Advisories -->
<!-- ########## -->

<xsl:template match="sidebyside[not(parent::interactive)]">
    <xsl:if test="count(*[not(&METADATA-FILTER;)]) = 1">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>A &lt;sidebyside&gt; normally does not have a single panel.&#xa;</xsl:text>
                <xsl:text>If this construct is only for layout control, try moving&#xa;</xsl:text>
                <xsl:text>layout onto the element used as panel ("</xsl:text>
                <xsl:value-of select="local-name(*[not(&METADATA-FILTER;)])"/>
                <xsl:text>") and remove the &lt;sidebyside&gt;&#xa;</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="title[m]">
    <xsl:if test="parent::chapter|appendix|preface|acknowledgement|biography|foreword|dedication|colophon|section|subsection|subsubsection|slide|exercises|worksheet|reading-questions|solutions|references|glossary|backmatter and not(following-sibling::shorttitle)">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>You have a title containing m but no shorttitle.&#xa;</xsl:text>
                <xsl:text>Because this title will be used many places, errors may result.&#xa;</xsl:text>
                <xsl:text>Please add a shorttitle.</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<!-- ####### -->
<!-- WeBWorK -->
<!-- ####### -->

<!-- Certain constructions are only meant for use in WW problems, -->
<!-- but we allow them (apparently) everywhere when writing the   -->
<!-- official schema.  We indicate these situations here.         -->

<!-- "var" is specific to WW -->
<xsl:template match="var[not(ancestor::webwork)]">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'error'"/>
        <xsl:with-param name="message">
            <xsl:text>The &lt;var&gt; element is exclusive to a WeBWorK problem,&#xa;</xsl:text>
            <xsl:text>and so must only appear within a &lt;webwork&gt; element,&#xa;</xsl:text>
            <xsl:text>not here.  It will be ignored.</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<!-- WW tables can't express the range of borders/rules that PreTeXt can -->

<xsl:template match="webwork//tabular/col/@top">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'warn'"/>
        <xsl:with-param name="message">
            <xsl:text>Column-specific top border attributes are not implemented for the&#xa;</xsl:text>
            <xsl:text>output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="webwork//tabular/cell/@bottom">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'warn'"/>
        <xsl:with-param name="message">
            <xsl:text>Cell-specific bottom border border attributes are not implemented for the&#xa;</xsl:text>
            <xsl:text>output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="webwork//tabular/*[@top='medium' or @bottom='medium' or @left='medium' or @right='medium' or @top='major' or @bottom='major' or @left='major' or @right='major']">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'warn'"/>
        <xsl:with-param name="message">
            <xsl:text>'medium' or 'major' table rule attributes will be handled as 'minor' in the&#xa;</xsl:text>
            <xsl:text>output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>


<!-- ############## -->
<!-- Infrastructure -->
<!-- ############## -->

<!-- Entry template -->
<xsl:template match="/">
    <xsl:apply-templates/>
</xsl:template>

<!-- Traverse the tree, looking for trouble -->
<xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
</xsl:template>

<!-- ######### -->
<!-- Messaging -->
<!-- ######### -->

<xsl:template match="*" mode="messaging">
    <xsl:param name="severity"/>
    <xsl:param name="message"/>

    <xsl:text>################################################################&#xa;</xsl:text>
    <xsl:text>PTX:</xsl:text>
    <xsl:choose>
        <xsl:when test="$severity = 'error'">
            <xsl:text>ERROR</xsl:text>
        </xsl:when>
        <xsl:when test="$severity = 'warn'">
            <xsl:text>WARNING</xsl:text>
        </xsl:when>
        <xsl:when test="$severity = 'advice'">
            <xsl:text>ADVICE</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>################################################################</xsl:message>
            <xsl:message>Validation+ stylesheet is passing incorrect severity ("<xsl:value-of select="$severity"/>")</xsl:message>
            <xsl:message>################################################################</xsl:message>
            <xsl:message terminate='yes'/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="." mode="numbered-path"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="$message"/>
    <!-- supply final newline -->
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="*" mode="numbered-path">
    <xsl:variable name="ancestors" select="ancestor-or-self::*"/>
    <xsl:for-each select="$ancestors">
        <xsl:text>/</xsl:text>
        <xsl:value-of select="local-name(.)"/>
        <xsl:text>[</xsl:text>
        <xsl:number/>
        <xsl:text>]</xsl:text>
    </xsl:for-each>
</xsl:template>

</xsl:stylesheet>


