<?xml version='1.0'?>

<!--********************************************************************
Copyright 2018 Robert A. Beezer

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
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<!-- We choose to not include a default namespace       -->
<!-- (in particular  http://www.w3.org/1999/xhtml),     -->
<!-- even if this complicates adding namespaces onto    -->
<!-- derivatives, such as HTML destined for EPUB output -->
<!-- xmlns="http://www.w3.org/1999/xhtml"               -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:b64="https://github.com/ilyakharlamov/xslt_base64"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    exclude-result-prefixes="b64"
    extension-element-prefixes="exsl date str"
>

<xsl:import href="./pretext-common.xsl" />

<!-- This is a conversion to "plain" text.  Upon initiation it is mainly -->
<!-- meant as a foundation for various simple conversions to things like -->
<!-- doctests or JSON table-of-contents.  But it is designed as a "real" -->
<!-- conversion.  But obviously, there are many PreTeXt constructions    -->
<!-- which cannot be realized in text.                                   -->
<!--                                                                     -->
<!-- Goal is to make it so *no* conversion imports "pretext-common.xsl" -->
<!-- since some foundational conversion (such as this one) can be the    -->
<!-- basis of the conversion and will import the foundationa one instead.-->
<!--                                                                     -->
<!-- Initial work might be to implement certain characters as 7-bit      -->
<!-- ASCII and as Unicode, under the control of a switch.  For example,  -->
<!-- the "q" element could have dumb generic quotes or smart left and    -->
<!-- right quotes.                                                       -->

<xsl:output method="text"/>

<!-- if chunking, this is the extension of the files produced -->
<xsl:variable name="file-extension" select="'.txt'"/>


<!-- Entry Template -->
<!-- Kickstart the process, ignore "docinfo"  -->
<xsl:template match="/">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Conversion to simple text is incomplete&#xa;But importing this stylesheet could be helpful for certain purposes&#xa;Override the entry template to make this warning go away</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="$document-root"/>
</xsl:template>

<!-- TEMPORARY: defined to stop errors, need stubs in -common -->
<xsl:template name="inline-warning"/>
<xsl:template name="margin-warning"/>
<xsl:template match="sage" mode="sage-active-markup"/>
<xsl:template name="sage-display-markup"/>

<!-- ######### -->
<!-- Divisions -->
<!-- ######### -->

<xsl:template match="part|chapter|section|subsection|subsubsection|exercises|reading-questions|worksheet|glossary|references|solutions">
    <!-- empty line prior -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number"/>
    <!-- Title is required (or default is supplied) -->
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- metadata-ish, eg "title", should be killed by default -->
    <xsl:apply-templates/>
</xsl:template>

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- Nothing fancy (like in LaTeX conversion) for  -->
<!-- the number of the target of a cross-reference -->
<xsl:template match="*" mode="xref-number">
    <xsl:apply-templates select="." mode="number"/>
</xsl:template>

<!-- No good way to link/direct to target, so we just   -->
<!-- parrot the text produced typically for a clickable -->
<xsl:template match="xref" mode="xref-link">
    <xsl:param name="target"/>
    <xsl:param name="content"/>

    <xsl:value-of select="$content"/>
</xsl:template>

<!-- Characters -->

<!-- Idea: variables from "choose" on $text.encoding variable      -->
<!-- to use cheap ASCII versions (or stand-ins, like [PER-MILLE]), -->
<!-- versus more realistic Unicode versions                        -->

<!-- ASCII we just use a regular space -->
<xsl:template name="nbsp-character">
    <xsl:text> </xsl:text>
</xsl:template>

<xsl:template name="ndash-character">
    <xsl:text>-</xsl:text>
</xsl:template>

<xsl:template name="mdash-character">
    <xsl:text>-</xsl:text>
</xsl:template>

<!-- The abstract template for "mdash" consults a publisher option -->
<!-- for thin space, or no space, surrounding an em-dash.  So the  -->
<!-- "thin-space-character" is needed for that purpose, and does   -->
<!-- not have an associated empty PTX element.                     -->

<!-- ASCII we just use a full space -->
<xsl:template name="thin-space-character">
    <xsl:text> </xsl:text>
</xsl:template>

<xsl:template name="lsq-character">
    <xsl:text>'</xsl:text>
</xsl:template>

<xsl:template name="rsq-character">
    <xsl:text>'</xsl:text>
</xsl:template>

<xsl:template name="lq-character">
    <xsl:text>"</xsl:text>
</xsl:template>

<xsl:template name="rq-character">
    <xsl:text>"</xsl:text>
</xsl:template>

<xsl:template name="ellipsis-character">
    <xsl:text>...</xsl:text>
</xsl:template>

<!-- Math -->
<!-- Until we think of something better, we just -->
<!-- bracket raw LaTeX that appears inline       -->
<!-- This can be overridden, if necessary        -->
<xsl:template name="begin-inline-math">
    <xsl:text>[</xsl:text>
</xsl:template>

<xsl:template name="end-inline-math">
    <xsl:text>]</xsl:text>
</xsl:template>

<xsl:template match="p">
    <!-- space with a blank line if not -->
    <!-- first in a structured element  -->
    <!-- barring metadata-ish           -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <!-- mixed-content -->
    <xsl:apply-templates/>
    <!-- end onto a newline -->
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ############ -->
<!-- Environments -->
<!-- ############ -->

<xsl:template match="&REMARK-LIKE;">
    <!-- space with a blank line if not -->
    <!-- first in a structured element  -->
    <!-- barring metadata-ish           -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number"/>
    <xsl:if test="title">
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <!-- structured -->
    <xsl:apply-templates select="*"/>
</xsl:template>

<xsl:template match="&EXAMPLE-LIKE;">
    <!-- space with a blank line if not -->
    <!-- first in a structured element  -->
    <!-- barring metadata-ish           -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number"/>
    <xsl:if test="title">
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="statement">
            <xsl:apply-templates select="statement"/>
            <xsl:apply-templates select="hint|answer|solution"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="*[self::hint|self::answer|self::solution]"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="&THEOREM-LIKE;">
    <!-- space with a blank line if not -->
    <!-- first in a structured element  -->
    <!-- barring metadata-ish           -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number"/>
    <xsl:if test="title">
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="statement">
            <xsl:apply-templates select="statement"/>
            <xsl:apply-templates select="proof"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="*[self::proof]"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- General-purpose container, we  -->
<!-- do not enforce possibilities -->
<xsl:template match="statement">
    <!-- structured -->
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- THEOREM-LIKE only -->
<xsl:template match="proof">
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>.&#xa;</xsl:text>
    <!-- structured -->
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- ######### -->
<!-- Exercises -->
<!-- ######### -->

<xsl:template match="exercise">
    <!-- space with a blank line if not -->
    <!-- first in a structured element  -->
    <!-- barring metadata-ish           -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="serial-number"/>
    <xsl:text>.</xsl:text>
    <xsl:if test="title">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:text> </xsl:text>
    <xsl:choose>
        <xsl:when test="statement">
            <xsl:apply-templates select="statement"/>
            <xsl:apply-templates select="hint|answer|solution"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="*[self::hint|self::answer|self::solution]"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="hint|answer|solution">
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="non-singleton-number" />
    </xsl:variable>
    <!-- An empty value means element is a singleton -->
    <!-- else the serial number comes through        -->
    <xsl:if test="not($the-number = '')">
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="serial-number" />
    </xsl:if>
    <xsl:text>. </xsl:text>
    <xsl:apply-templates/>
    <!-- not needed if structured -->
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ############### -->
<!-- Captioned Items -->
<!-- ############### -->

<xsl:template match="figure">
    <!-- space with a blank line if not -->
    <!-- first in a structured element  -->
    <!-- barring metadata-ish           -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number"/>
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="caption"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="caption">
    <!-- mixed-content -->
    <xsl:apply-templates/>
</xsl:template>

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<xsl:template match="ul|ol|dl">
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="li"/>
</xsl:template>

<xsl:template match="ol/li">
    <xsl:apply-templates select="." mode="serial-number"/>
    <xsl:text>. </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="ul/li">
    <xsl:text>* </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="dl/li">
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
