<?xml version='1.0'?>

<!--********************************************************************
Copyright 2019 Robert A. Beezer

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

<!-- A conversion to "stock" PreTeXt HTML, but optimized as an     -->
<!-- eventual input for teh liblouis system to produce Grade 2     -->
<!-- and Nemeth Braille into BRF format with ASCII Braille         -->
<!-- (encoding the 6-dot-patterns of cells with 64 well-behaved    -->
<!-- ASCII characters).  By itself theis conversion is not useful. -->
<!-- The math bits (as LaTeX) need to be converted to Braille by   -->
<!-- MathJax and Speech Rules Engine, and then fed to              -->
<!-- liblouisutdml's  file2brl  program.                           -->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
    >

<!-- desire HTML output, but primarily content -->
<xsl:import href="mathbook-html.xsl" />

<xsl:output method="xml" indent="yes" encoding="UTF-8"/>

<!-- Only need one monolithic file, how to chunk -->
<!-- is not obvious, so we set this here         -->
<xsl:param name="chunk.level" select="0"/>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- These two templates are similar to those of  mathbook-html.xsl. -->
<!-- Primarily the production of cross-reference ("xref") knowls     -->
<!-- has been removed.                                               -->

<xsl:template match="/">
    <xsl:apply-templates/>
</xsl:template>

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<!-- We process structural nodes via chunking routine in xsl/mathbook-common.xsl    -->
<!-- This in turn calls specific modal templates defined elsewhere in this file     -->
<xsl:template match="/mathbook|/pretext">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">This template is under development.&#xa;It will not produce Braille directly, just a precursor.</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="$root" mode="generic-warnings" />
    <xsl:apply-templates select="$root" mode="deprecation-warnings" />
    <xsl:apply-templates mode="chunking" />
</xsl:template>

<!-- ################# -->
<!-- Page Construction -->
<!-- ################# -->

<!-- A greatly simplified file-wrap template      -->
<!-- Drop file output, so we can script on stdout -->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />

    <html>
        <head>
        <!-- some MathJax config? -->
        </head>
        <body>
            <xsl:call-template name="latex-macros" />
            <xsl:copy-of select="$content" />
        </body>
    </html>
</xsl:template>

<!-- ################### -->
<!-- Display Mathematics -->
<!-- ################### -->


<!-- Less is more -->
<xsl:template match="me|men|md|mdn" mode="display-math-wrapper">
    <xsl:param name="content" />
    <xsl:copy-of select="$content" />
</xsl:template>

<xsl:template name="display-math-visual-blank-line"/>

<!-- We do not look forward for clause-ending         -->
<!-- punctuation, since we do not want punctuation    -->
<!-- to be part of the translation to Nemeth Braille. -->
<xsl:template match="*" mode="get-clause-punctuation"/>

<!-- Then we xerox $text, effectively *not* removing  -->
<!-- any punctuation.                                 -->
<xsl:template name="drop-clause-punctuation">
    <xsl:param name="text" />
    <xsl:value-of select="$text" />
</xsl:template>

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- This is just a device for LaTeX conversion -->
<xsl:template match="*" mode="xref-number">
    <xsl:apply-templates select="." mode="number"/>
</xsl:template>

<!-- Nothing much to be done, we just -->
<!-- xerox the text representation    -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="target" />
    <xsl:param name="content" />

    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- ########## -->
<!-- Quotations -->
<!-- ########## -->

<!-- liblouis recognizes the single/double, left/right -->
<!-- smart quotes so we just let wander in from the    -->
<!-- standard HTML conversion, covering the elements:  -->
<!--                                                   -->
<!--   Characters: "lq", "rq", "lsq", "rsq"            -->
<!--   Grouping: "q", "sq"                             -->

</xsl:stylesheet>