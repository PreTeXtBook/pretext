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

<!-- The "frontmatter" and "backmatter" of the HTML version are possibly -->
<!-- summary pages and need to step the heading level (h1-h6) for screen -->
<!-- readers and accessibility.  But here we want to style items at      -->
<!-- similar levels to be at the same HTML level so we can use liblouis' -->
<!-- device for this.  So, for example, we want  book/preface/chapter    -->
<!-- to be h2, not h3.  Solution: we don't need the frontmatter and      -->
<!-- backmatter distinctions in Braille, so we simply recurse with a     -->
<!-- pass-through of the heading level.  This is a very tiny subset of   -->
<!-- the HTML template matching &STRUCTURAL;.                            -->
<xsl:template match="frontmatter|backmatter">
    <xsl:param name="heading-level"/>

    <xsl:apply-templates>
        <xsl:with-param name="heading-level" select="$heading-level"/>
    </xsl:apply-templates>
</xsl:template>


<!-- ########## -->
<!-- Title Page -->
<!-- ########## -->

<!-- This has the same @match as in the HTML conversion,        -->
<!-- so keep them in-sync.  Here we make adjustments:           -->
<!--   * One big h1 for liblouis styling (centered, etc)        -->
<!--   * No extra HTML, just line breaks                        -->
<!--   * exchange the subtitle semicolon/space for a line break -->
<!--   * dropped credit, and included edition                   -->
<!-- See [BANA-2016, 1.8.1]                                     -->
<xsl:template match="titlepage">
    <xsl:variable name="b-has-subtitle" select="parent::frontmatter/parent::*/subtitle"/>
    <h1 class="heading">
        <xsl:apply-templates select="parent::frontmatter/parent::*" mode="title-full" />
        <br/>
        <xsl:if test="$b-has-subtitle">
            <xsl:apply-templates select="parent::frontmatter/parent::*" mode="subtitle" />
            <br/>
        </xsl:if>
        <!-- We list authors and editors in document order -->
        <xsl:apply-templates select="author|editor" mode="full-info"/>
        <!-- A credit is subsidiary, so follows -->
        <!-- <xsl:apply-templates select="credit" /> -->
        <xsl:if test="colophon/edition or date">
            <br/> <!-- a small gap -->
            <xsl:if test="colophon/edition">
                <xsl:apply-templates select="colophon/edition"/>
                <br/>
            </xsl:if>
            <xsl:if test="date">
                <xsl:apply-templates select="date"/>
                <br/>
            </xsl:if>
        </xsl:if>
    </h1>
</xsl:template>

<xsl:template match="titlepage/author|titlepage/editor" mode="full-info">
    <xsl:apply-templates select="personname"/>
    <xsl:if test="self::editor">
        <xsl:text> (Editor)</xsl:text>
    </xsl:if>
    <br/>
    <xsl:if test="department">
        <xsl:apply-templates select="department"/>
        <br/>
    </xsl:if>
    <xsl:if test="institution">
        <xsl:apply-templates select="institution"/>
        <br/>
    </xsl:if>
</xsl:template>


<!-- ######### -->
<!-- Divisions -->
<!-- ######### -->

<!-- We override the content of titles of divisions that are -->
<!-- peers of chapters in books (only).  A line break after  -->
<!-- the number will result in a centered number over a  -->
<!-- centered title via a liblouis style on HTML "h2" elements. -->

<!-- Numbered, chapter-level headings, two lines to HTML -->
<xsl:template match="chapter|appendix" mode="header-content">
    <span class="type">
        <xsl:apply-templates select="." mode="type-name" />
    </span>
    <xsl:text> </xsl:text>
    <span class="codenumber">
        <xsl:apply-templates select="." mode="number" />
    </span>
    <br/>
    <span class="title">
        <xsl:apply-templates select="." mode="title-full" />
    </span>
</xsl:template>

<!-- Unnumbered, chapter-level headings, just title text -->
<xsl:template match="preface|acknowledgement|biography|foreword|dedication|solutions[parent::backmatter]|references[parent::backmatter]|index|colophon" mode="header-content">
    <span class="title">
        <xsl:apply-templates select="." mode="title-full" />
    </span>
</xsl:template>

<!-- A "paragraphs" element is a lightweignt division, which we  -->
<!-- usually realize with a run-in title.  We need to force this -->
<!-- for the HTML output, rather than letting CSS accomplish it. -->

<!-- First, kill the independent heading/title element. -->
<xsl:template match="paragraphs" mode="heading-title-paragraphs"/>

<!-- Slide in the title, which includes punctuation -->
<xsl:template match="paragraphs/p[1]" mode="body">
    <p>
        <xsl:apply-templates select="parent::paragraphs" mode="title-full"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates/>
    </p>
</xsl:template>


<!-- Environments-->

<!-- Born-hidden behavior is generally configurable, -->
<!-- but we do not want any automatic or configured, -->
<!-- knowlization to take place.  Ever.              -->
<!-- Checklist:  implemented environments            -->
<!-- Definitions                                     -->
<!-- Examples                                        -->
<xsl:template match="&DEFINITION-LIKE;|&EXAMPLE-LIKE;" mode="is-hidden">
    <xsl:text>no</xsl:text>
</xsl:template>

<!-- ################ -->
<!-- Subsidiary Items -->
<!-- ################ -->

<!-- These tend to "hang" off other structures and/or are routinely -->
<!-- rendered as knowls.  So we turn off automatic knowlization     -->
<xsl:template match="&SOLUTION-LIKE;" mode="is-hidden">
    <xsl:text>no</xsl:text>
</xsl:template>

<!-- ###################### -->
<!-- Paragraph-Level Markup -->
<!-- ###################### -->

<!-- Certain PreTeXt elements create characters beyond the -->
<!-- "usual" Unicode range of U+0000-U+00FF.  We defer the -->
<!-- translation to the "pretext-symbol.dis" file which    -->
<!-- liblouis  will consult for characters/code-points it  -->
<!-- does not recognize.  We make notes here, but the file -->
<!-- should be consulted for accurate information.         -->

<!-- PTX: ldblbracket, rdblbracket, dblbrackets     -->
<!-- Unicode:                                       -->
<!-- MATHEMATICAL LEFT WHITE SQUARE BRACKET, x27e6  -->
<!-- MATHEMATICAL RIGHT WHITE SQUARE BRACKET, x27e7 -->
<!-- Translation:  [[, ]]                           -->


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
    <!-- we look for very simple math (one-letter variable names) -->
    <!-- so we process the content (which can have "xref", etc)   -->
    <xsl:variable name="content">
        <xsl:apply-templates select="*|text()"/>
    </xsl:variable>
    <xsl:choose>
        <!-- one Latin letter -->
        <xsl:when test="(string-length($content) = 1) and
                        contains('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', $content)">
            <i class="one-letter">
                <xsl:value-of select="."/>
            </i>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="open-nemeth"/>
            <xsl:apply-imports/>
            <xsl:call-template name="close-nemeth"/>
        </xsl:otherwise>
    </xsl:choose>
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

<!-- We do not worry about lists, display math, or code  -->
<!-- displays which PreTeXt requires inside paragraphs.  -->
<!-- Especially since the pipeline corrects this anyway. -->
<!-- NB: see p[1] modified in "paragraphs" elsewhere     -->

<!-- ########## -->
<!-- Quotations -->
<!-- ########## -->

<!-- liblouis recognizes the single/double, left/right -->
<!-- smart quotes so we just let wander in from the    -->
<!-- standard HTML conversion, covering the elements:  -->
<!--                                                   -->
<!--   Characters: "lq", "rq", "lsq", "rsq"            -->
<!--   Grouping: "q", "sq"                             -->

<!-- http://www.dotlessbraille.org/aposquote.htm -->

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Preliminary: be sure to notate HTML with regard to override -->
<!-- here.  Template will help locate for subsequent work.       -->
<!-- <xsl:template match="ol/li|ul/li|var/li" mode="body">       -->

<xsl:template match="ol|ul|dl">
    <xsl:copy>
        <xsl:attribute name="class">
            <xsl:text>outerlist</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="li"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="ol/li" mode="body">
    <li>
        <xsl:apply-templates select="." mode="item-number"/>
        <xsl:text>. </xsl:text>
        <xsl:apply-templates/>
    </li>
</xsl:template>

<xsl:template match="ul/li" mode="body">
    <xsl:variable name="format-code">
        <xsl:apply-templates select="parent::ul" mode="format-code"/>
    </xsl:variable>
    <li>
        <!-- the list label.  Unicode values are not critical, they are  -->
        <!-- just signals for the liblouis translation into dot-patterns -->
        <xsl:choose>
            <!-- Unicode Character 'BULLET' (U+2022) -->
            <xsl:when test="$format-code = 'disc'">
                <xsl:text>&#x2022; </xsl:text>
            </xsl:when>
            <!-- Unicode Character 'WHITE CIRCLE' (U+25CB) -->
            <xsl:when test="$format-code = 'circle'">
                <xsl:text>&#x25cb; </xsl:text>
            </xsl:when>
            <!-- Unicode Character 'BLACK SQUARE' (U+25A0) -->
            <xsl:when test="$format-code = 'square'">
                <xsl:text>&#x25a0; </xsl:text>
            </xsl:when>
            <!-- a bad idea for Braille -->
            <xsl:when test="$format-code = 'none'">
                <xsl:text/>
            </xsl:when>
        </xsl:choose>
        <!-- and the contents -->
        <xsl:apply-templates/>
    </li>
</xsl:template>

<xsl:template match="dl">
    <dl class="outerlist">
        <xsl:apply-templates select="li"/>
    </dl>
</xsl:template>

<xsl:template match="dl/li">
    <li>
        <xsl:apply-templates select="." mode="title-full"/>
        <ul>
            <li>
                <xsl:apply-templates/>
            </li>
        </ul>
    </li>
</xsl:template>


<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- We leave a placeholder for images, temporarily -->
<xsl:template match="image">
    <xsl:text>[image]</xsl:text>
</xsl:template>


<!-- #### -->
<!-- Sage -->
<!-- #### -->

<!-- We leave a placeholder for Sage cells, temporarily -->
<xsl:template match="sage">
    <xsl:text>[sage cell]</xsl:text>
    <br/>
</xsl:template>

</xsl:stylesheet>