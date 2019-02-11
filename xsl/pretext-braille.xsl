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

<!-- ########### -->
<!-- Mathematics -->
<!-- ########### -->

<!-- Nemeth indicator use described in:            -->
<!-- Braille Authority of North America (BANA),    -->
<!-- "Guidance for Transcription Using the Nemeth  -->
<!-- Code within UEB Contexts Revised", April 2018 -->
<!-- Hereafter "BANA Nemeth Guidance"              -->

<!-- BANA Nemeth Guidance quotes "Rules of Unified English Braille 2013" -->
<!--                                                                     -->
<!-- 14.6 Nemeth Code within UEB text                                    -->
<!--                                                                     -->
<!-- 14.6.1 When technical material is transcribed according to the      -->
<!-- provisions of The Nemeth Braille Code for Mathematics and Science   -->
<!-- Notation within UEB text, the following sections provide for        -->
<!-- switching between UEB and Nemeth Code.                              -->
<!--                                                                     -->
<!-- 14.6.2 Place the opening Nemeth Code indicator followed by a        -->
<!-- space before the sequence to which it applies. Its effect is        -->
<!-- terminated by the Nemeth Code terminator preceded by a space.       -->
<!-- Note: The spaces required with the indicator and the terminator     -->
<!-- do not represent spaces in print.                                   -->
<!--                                                                     -->
<!-- 14.6.3 When the Nemeth Code text is displayed on one or more lines  -->
<!-- separate from the UEB text, the opening Nemeth Code indicator and   -->
<!-- the Nemeth Code terminator may each be placed on a line by itself   -->
<!-- or at the end of the previous line of text.                         -->

<!-- Opening Nemeth Code indicator -->
<!-- _%,  4-5-6 1-4-6,  x5f x25    -->
<!-- always followed by a space    -->
<!-- technically a UEB symbol      -->
<xsl:template name="open-nemeth">
    <!-- <xsl:text>&#x5f;&#x25; </xsl:text> -->
    <xsl:text>&#x2838;&#x2829;&#x20;</xsl:text>
</xsl:template>

<!-- Nemeth Code terminator      -->
<!-- _:,  4-5-6 1-5-6,  x5f x3a  -->
<!-- always preceded by a space  -->
<!-- technically a Nemeth symbol -->
<xsl:template name="close-nemeth">
    <xsl:text>&#x20;&#x2838;&#x2831;</xsl:text>
</xsl:template>

<!-- Single-word switch indicator ,' -->

<!-- ################## -->
<!-- Inline Mathematics -->
<!-- ################## -->

<!-- We place the Nemeth open/close symbols via   -->
<!-- import of the base HTML/LaTeX representation -->
<xsl:template match="m">
    <xsl:call-template name="open-nemeth"/>
    <xsl:apply-imports/>
    <xsl:call-template name="close-nemeth"/>
</xsl:template>

<!-- ################### -->
<!-- Display Mathematics -->
<!-- ################### -->

<!-- We add a space prior to displayed mathematics, -->
<!-- since this will normally be accomplished by    -->
<!-- the vertical space and not present in the      -->
<!-- author's source.  Any arrangement of newlines  -->
<!-- here is immaterial since HTML-processing will  -->
<!-- not care.  If we want the Nemeth indicators to -->
<!-- end, or begin, a line, we should add "br"      -->
<!-- elements here.                                 -->

<xsl:template name="display-math-visual-blank-line"/>

<xsl:template match="me|men|md|mdn" mode="display-math-wrapper">
    <xsl:param name="content" />

    <xsl:text>&#x20;</xsl:text>
    <xsl:call-template name="open-nemeth"/>
    <xsl:copy-of select="$content" />
    <xsl:call-template name="close-nemeth"/>
</xsl:template>

<!-- BANA Nemeth Guidance: "All other text, including -->
<!-- punctuation that is logically associated with    -->
<!-- surrounding sentences, should be done in UEB."   -->
<!-- So we do not move "clause-ending punctuation,"   -->
<!-- and we just put it back in place.  ;-)           -->

<!-- Do not grab/use "clause-ending punctuation" -->
<xsl:template match="*" mode="get-clause-punctuation"/>

<!-- Xerox $text, effectively *not* removing any punctuation. -->
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
<!-- Paragraphs -->
<!-- ########## -->

<!-- We do not worry about lists, display math, or code -->
<!-- displays which PreTeXt requires inside paragraphs. -->
<!-- Following will create non-validating HTML, but     -->
<!-- hopefully our tools will not care.                 -->
<xsl:template match="p" mode="body">
    <p>
        <xsl:apply-templates/>
    </p>
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

<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- We leave a placeholder for images, temporarily -->
<xsl:template match="image">
    <xsl:text>[image]</xsl:text>
</xsl:template>

</xsl:stylesheet>