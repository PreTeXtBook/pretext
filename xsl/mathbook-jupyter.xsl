<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2015 Robert A. Beezer

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

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
    >

<xsl:import href="./mathbook-common.xsl" />
<xsl:import href="./mathbook-html.xsl" />

<!-- Output is JSON, enriched with serialized HTML -->
<xsl:output method="text" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<!-- iPython files as output -->
<xsl:variable name="file-extension" select="'.ipynb'" />

<!-- Examples and proofs are knowled by default      -->
<!-- in HTML conversion.  While a THEOREM-LIKE is    -->
<!-- one big unit, so proofs are not even considered -->
<!-- as knowls, EXAMPLE-LIKE do need protection.     -->

<xsl:param name="html.knowl.proof" select="'no'" />
<xsl:param name="html.knowl.example" select="'no'" />

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:apply-templates />
</xsl:template>

<!-- We process structural nodes via chunking routine in  xsl/mathbook-common.html -->
<!-- This in turn calls specific modal templates defined elsewhere in this file    -->
<xsl:template match="mathbook">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Jupyter notebook conversion is experimental and incomplete&#xa;Requests to fix/implement specific constructions welcome</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="mathbook" mode="deprecation-warnings" />
    <xsl:apply-templates mode="chunking" />
</xsl:template>

<!-- ################ -->
<!-- Structural Nodes -->
<!-- ################ -->

<!-- Read the code and documentation for "chunking" in xsl/mathbook-common.html -->
<!-- This will explain document structure (not XML structure) and has the       -->
<!-- routines which call the necessary realizations of two abstract templates.  -->

<!-- Divisions, and pseudo-divisions -->
<!-- A heading cell, then apply templates here to children -->
<xsl:template match="&STRUCTURAL;|paragraphs|introduction[parent::*[&STRUCTURAL-FILTER;]]|conclusion[parent::*[&STRUCTURAL-FILTER;]]">
    <!-- <xsl:message>S:<xsl:value-of select="local-name(.)" />:S</xsl:message> -->
    <xsl:apply-templates select="." mode="pretext-heading" />
    <xsl:apply-templates />
</xsl:template>

<!-- Some structural nodes do not need their title,                -->
<!-- (or subtitle) so we don't put a section heading there         -->
<!-- Title(s) for an article are forced by a frontmatter/titlepage -->
<xsl:template match="article|frontmatter">
    <xsl:apply-templates />
</xsl:template>

<!-- We have entire cells for division headings. -->
<xsl:template match="&STRUCTURAL;" mode="pretext-heading">
    <xsl:variable name="html-rtf">
        <xsl:apply-templates select="." mode="section-header" />
    </xsl:variable>
    <xsl:variable name="html-node-set" select="exsl:node-set($html-rtf)" />
    <xsl:call-template name="pretext-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
                <xsl:apply-templates select="$html-node-set" mode="serialize" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="paragraphs|introduction|conclusion" mode="pretext-heading">
    <xsl:variable name="html-rtf">
        <xsl:apply-templates select="." mode="heading-title" />
    </xsl:variable>
    <xsl:variable name="html-node-set" select="exsl:node-set($html-rtf)" />
    <xsl:call-template name="pretext-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
                <xsl:apply-templates select="$html-node-set" mode="serialize" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="*" mode="pretext-heading">
    <xsl:message>pretext-heading unmatched <xsl:value-of select="local-name(.)" /></xsl:message>
</xsl:template>

<!-- Three modal templates accomodate all document structure nodes -->
<!-- and all possibilities for chunking.  Read the description     -->
<!-- in  xsl/mathbook-common.xsl to understand these.              -->
<!-- The  "file-wrap"  template is defined elsewhre in this file.  -->

<!-- Content of a summary page is usual content,  -->
<!-- or link to subsidiary content, all from HTML -->
<!-- template with same mode, as one big cell     -->
<xsl:template match="&STRUCTURAL;" mode="summary">
    <xsl:variable name="html-rtf">
        <xsl:apply-imports />
    </xsl:variable>
    <xsl:variable name="html-node-set" select="exsl:node-set($html-rtf)" />
    <xsl:call-template name="pretext-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
                <xsl:apply-templates select="$html-node-set" mode="serialize" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- File Structure -->
<!-- Gross structure of a Jupyter notebook -->
<!-- TODO: need to make a "simple file wrap" template?  Or just call this?-->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />
    <!--  -->
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="containing-filename" />
    </xsl:variable>
    <xsl:variable name="cell-list">
        <!-- a code cell for reader to load CSS -->
        <!-- First, so already with focus       -->
        <xsl:call-template name="load-css" />
        <!-- load LaTeX macros for MathJax   -->
        <!-- Empty, also provides separation -->
        <xsl:call-template name="latex-macros" />
        <!-- the real content of the page -->
        <xsl:copy-of select="$content" />
    </xsl:variable>
    <exsl:document href="{$filename}" method="text">
        <!-- <xsl:call-template name="converter-blurb-html" /> -->
        <!-- begin outermost group -->
        <xsl:text>{&#xa;</xsl:text>
        <!-- cell list first, majority of notebook, metadata to finish -->
        <xsl:text>"cells": [&#xa;</xsl:text>
        <!-- <xsl:message>CL:<xsl:value-of select="$cell-list" /></xsl:message> -->
        <!-- Escape backslashes -->
        <xsl:variable name="escape-backslash" select="str:replace($cell-list, '\','\\')" />
        <!-- Escape quote marks -->
        <xsl:variable name="escape-quote" select="str:replace($escape-backslash, '&quot;','\&quot;')" />
        <!-- Replace newline markers -->
        <xsl:variable name="replace-newline" select="str:replace($escape-quote, $NL,'\n')" />
        <!-- Massage string delimiters, separators -->
        <xsl:variable name="split-strings" select="str:replace($replace-newline, $ESBS, '&quot;,&#xa;&quot;')" />
        <xsl:variable name="finalize-strings" select="str:replace(str:replace($split-strings, $ES, '&quot;'), $BS, '&quot;')" />
        <!-- Massage cell delimiters, separators -->
        <!-- Split cell separators -->
        <xsl:variable name="split-cells" select="str:replace($finalize-strings, $RBLB, $RBLB-comma)" />
        <!-- now replace cell markers with actual wrappers -->
        <xsl:variable name="markdown-cells" select="str:replace(str:replace($split-cells, $BM, $begin-markdown-wrap), $EM, $end-markdown-wrap)" />
        <xsl:variable name="code-cells" select="str:replace(str:replace($markdown-cells, $BC, $begin-code-wrap), $EC, $end-code-wrap)" />
        <!-- remove next line by making previous a value-of, once stable -->
        <xsl:value-of select="$code-cells" />
        <!-- end cell list -->
        <xsl:text>],&#xa;</xsl:text>
        <!-- version identifiers -->
        <xsl:text>"nbformat": 4,&#xa;</xsl:text>
        <xsl:text>"nbformat_minor": 0,&#xa;</xsl:text>
        <!-- metadata copied from blank SMC notebook -->
        <xsl:text>"metadata": {&#xa;</xsl:text>
        <xsl:text>  "kernelspec": {&#xa;</xsl:text>
        <!-- TODO: configure kernel in "docinfo" -->
        <!-- "display_name" seems ineffective, but is required -->
        <xsl:text>    "display_name": "",&#xa;</xsl:text>
        <!-- TODO: language not needed? -->
        <!-- <xsl:text>    "language": "python",&#xa;</xsl:text> -->
        <!-- "sagemath" as  "name" will be latest kernel on CoCalc -->
        <xsl:text>    "name": "python2"&#xa;</xsl:text>
        <!-- TODO: how much of the following is necessary before loading? -->
        <xsl:text>  },&#xa;</xsl:text>
        <xsl:text>  "language_info": {&#xa;</xsl:text>
        <xsl:text>    "codemirror_mode": {&#xa;</xsl:text>
        <xsl:text>      "name": "ipython",&#xa;</xsl:text>
        <xsl:text>      "version": 2&#xa;</xsl:text>
        <xsl:text>    },&#xa;</xsl:text>
        <xsl:text>    "file_extension": ".py",&#xa;</xsl:text>
        <xsl:text>    "mimetype": "text/x-python",&#xa;</xsl:text>
        <xsl:text>    "name": "python",&#xa;</xsl:text>
        <xsl:text>    "nbconvert_exporter": "python",&#xa;</xsl:text>
        <xsl:text>    "pygments_lexer": "ipython2",&#xa;</xsl:text>
        <xsl:text>    "version": "2.7.8"&#xa;</xsl:text>
        <xsl:text>  },&#xa;</xsl:text>
        <xsl:text>  "name": "</xsl:text>
        <xsl:value-of select="$filename" />
        <xsl:text>"&#xa;</xsl:text>
        <xsl:text>  }&#xa;</xsl:text>
        <!-- end outermost group -->
        <xsl:text>}&#xa;</xsl:text>
    </exsl:document>
</xsl:template>

<!-- a code cell with HTML magic         -->
<!-- allows reader to activate styling   -->
<!-- Code first, so it begins with focus -->
<xsl:template name="load-css">
    <!-- HTML as one-off code cell   -->
    <!-- Serialize HTML by hand here -->
    <xsl:call-template name="code-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>%%html</xsl:text>
            <xsl:call-template name="newline" />
            <xsl:call-template name="end-string" />
            <xsl:call-template name="begin-string" />
            <!-- TEMPORARY TEMPORARY for AIR TRAVEL testing -->
            <!-- <xsl:text>&lt;link href="./mathbook-content.css" rel="stylesheet" type="text/css" /&gt;</xsl:text> -->
            <xsl:text>&lt;link href="http://mathbook.pugetsound.edu/beta/mathbook-content.css" rel="stylesheet" type="text/css" /&gt;</xsl:text>
            <xsl:call-template name="newline" />
            <xsl:text>&lt;link href="https://aimath.org/mathbook/mathbook-add-on.css" rel="stylesheet" type="text/css" /&gt;</xsl:text>
            <xsl:call-template name="newline" />
            <xsl:text>&lt;link href="https://fonts.googleapis.com/css?family=Open+Sans:400,400italic,600,600italic" rel="stylesheet" type="text/css" /&gt;</xsl:text>
            <xsl:call-template name="newline" />
            <xsl:text>&lt;link href="https://fonts.googleapis.com/css?family=Inconsolata:400,700&amp;subset=latin,latin-ext" rel="stylesheet" type="text/css" /&gt;</xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
    <!-- instructions as Markdown cell        -->
    <!-- Use markdown, since no CSS yet (duh) -->
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>**Important:** to view this notebook properly you will need to execute the cell above, which assumes you have an Internet connection.  It should already be selected, or place your cursor anywhere above to select.  Then press the "Run" button in the menu bar above (the right-pointing arrowhead), or press Shift-Enter on your keyboard.</xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- This will override the HTML version, but is patterned       -->
<!-- after same.  Adjustments are: different overall delimiters, -->
<!-- translation of newlines, and no enclosing div to hide       -->
<!-- content (thereby avoiding the need for serialization).      -->
<xsl:template name="latex-macros">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:call-template name="begin-inline-math" />
            <xsl:value-of select="str:replace($latex-packages-mathjax, '&#xa;', $NL)" />
            <xsl:value-of select="str:replace($latex-macros,           '&#xa;', $NL)" />
            <xsl:call-template name="end-inline-math" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>


<!-- ################# -->
<!-- Block Level Items -->
<!-- ################# -->

<!-- These are "top-level" items, children of divisions    -->
<!-- and pseudo-divisions.  Normally they would get a high -->
<!-- priority, but we want them to have the same low       -->
<!-- priority as a generic (default) wilcard match         -->
<xsl:template match="*[parent::*[&STRUCTURAL-FILTER; or self::paragraphs or self::introduction[parent::*[&STRUCTURAL-FILTER;]] or self::conclusion[parent::*[&STRUCTURAL-FILTER;]]]]" priority="-0.5">
    <!-- <xsl:message>G:<xsl:value-of select="local-name(.)" />:G</xsl:message> -->
    <xsl:variable name="html-rtf">
        <xsl:apply-imports />
    </xsl:variable>
    <xsl:variable name="html-node-set" select="exsl:node-set($html-rtf)" />
    <xsl:call-template name="pretext-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
                <xsl:apply-templates select="$html-node-set" mode="serialize" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Kill some templates temporarily -->
<xsl:template name="inline-warning" />
<xsl:template name="margin-warning" />

<!-- Kill some metadata -->
<xsl:template match="title|idx|notation" />


<!-- Sage code -->
<!-- Should evolve to accomodate general template -->
<xsl:template match="sage">
    <!-- formulate lines of code -->
    <xsl:variable name="loc">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text">
                <xsl:value-of select="input" />
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <!-- we trim a final trailing newline -->
    <xsl:variable name="loc-trim" select="substring($loc, 1, string-length($loc)-1)" />
    <!-- the code, content with string markers -->
    <xsl:variable name="the-code">
        <xsl:call-template name="begin-string" /> <!-- start first string -->
        <xsl:value-of select="str:replace($loc-trim, '&#xa;', concat($NL, $ESBS))" />
        <xsl:call-template name="end-string" /> <!-- end last string -->
    </xsl:variable>
    <xsl:call-template name="code-cell">
        <xsl:with-param name="content">
            <xsl:value-of select="$the-code" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- #### -->
<!-- Math -->
<!-- #### -->

<!-- These two templates provide the delimiters for inline math. -->
<!-- The Jupyter notebook appears to support AMS-style inline.   -->
<xsl:template name="begin-inline-math">
    <xsl:text>\\(</xsl:text>
</xsl:template>

<xsl:template name="end-inline-math">
    <xsl:text>\\)</xsl:text>
</xsl:template>

<!-- Dollar sign -->
<!-- The Jupyter notebook allows markdown cells to      -->
<!-- use dollar signs to delimit LaTeX, if you have     -->
<!-- two used for financial reasons, they will be       -->
<!-- interpreted incorrectly.  But they can be escaped. -->
<!-- So authors should use the "dollar" element.        -->
<xsl:template match="dollar">
    <xsl:text>\$</xsl:text>
</xsl:template>

<!-- Displayed Equations -->
<!-- Break out of enclosing paragraph, new -->
<!-- JSON string, combine lines as one big -->
<!-- string with newline separators        -->
<xsl:template match="me|men|md|mdn">
    <xsl:variable name="line-broken-math">
        <xsl:apply-imports />
    </xsl:variable>
    <!-- check to see if first element in paragraph? -->
    <xsl:call-template name="end-string" />
    <xsl:call-template name="begin-string" />
    <xsl:value-of select="str:replace($line-broken-math, '&#xa;', $NL)" />
    <xsl:call-template name="end-string" />
    <!-- check to see if last element in paragraph? -->
    <xsl:call-template name="begin-string" />
</xsl:template>

<!-- Images -->

<!-- Jupyter seems to not allow an "object" tag.        -->
<!-- So we override the HTML wrapper with a simpler     -->
<!-- version.  Interface info copied from HTML version. -->

<!-- A named template creates the infrastructure for an SVG image -->
<!-- Parameters                                 -->
<!-- svg-filename: required, full relative path -->
<!-- png-fallback-filename: optional            -->
<!-- image-width: required                      -->
<!-- image-description: optional                -->
<xsl:template name="svg-wrapper">
    <xsl:param name="svg-filename" />
    <xsl:param name="png-fallback-filename" select="''" />
    <xsl:param name="image-width" />
    <xsl:param name="image-description" select="''" />
    <xsl:element name="img">
        <xsl:attribute name="src">
            <xsl:value-of select="$svg-filename" />
        </xsl:attribute>
        <xsl:attribute name="width">
            <xsl:value-of select="$image-width" />
        </xsl:attribute>
        <!-- alt attribute for accessibility -->
        <xsl:attribute name="alt">
            <xsl:value-of select="$image-description" />
        </xsl:attribute>
    </xsl:element>
</xsl:template>

<!--
TODO:

1.  Interfere with left-angle bracket to make elements not evaporate in serialization.
2.  DONE: Escape $ so that pairs do not go MathJax on us.
3.  Do we need to protect a hash?  So not interpreted as a title?  Underscores, too.
4.  Update CSS, use add-on, make an output version to parse as text.
5.  Markup enclosed Sage cells (non-top-level) to allow dropout, dropin.
6.  Remove empty strings, empty anything, with search/replace step on null constructions.
7.  Maybe replace tabs (good for Sage code and/or JSON fidelity)?
-->

<!-- ########################## -->
<!-- Intermediate Pseudo-Markup -->
<!-- ########################## -->

<!-- A Jupyter notebook is a flat sequence of cells, of type either     -->
<!-- "markdown" or "code."  The content is primarily a list of strings. -->
<!-- This presents two fundamental problems:                            -->
<!--                                                                    -->
<!--   1.  Lists of cells, or lists of strings, with  n  items          -->
<!--       need exactly  n-1  commas.  It is hard to predict/find       -->
<!--       the first or last element of a list.                         -->
<!--                                                                    -->
<!--   2.  Cells cannot be nested and content should not lie            -->
<!--       outside of cells.                                            -->
<!--                                                                    -->
<!-- We use a sort of pseudo-markup.  Adjacency of items lets           -->
<!-- us solve the comma problem.  We are also able to effectively       -->
<!-- merge content into a cell, without knowing anything about          -->
<!-- the following cell.                                                -->
<!--                                                                    -->
<!-- We pipeline a pseudo-markup as an intermediate text format.        -->
<!--                                                                    -->
<!-- Pseudo-markup language:                                            -->
<!--                                                                    -->
<!-- LB, RB: left and right brackets - should be UUIDs eventually       -->
<!--                                                                    -->
<!-- BS, ES: begin and end string                                       -->
<!--                                                                    -->
<!-- BM, EM, BC, EC: begin and end, markdown and code, cells            -->
<!--                                                                    -->
<!-- NL: newline                                                        -->


<!-- ####### -->
<!-- Markers -->
<!-- ####### -->

<!-- This is pseudo-markup, starting with delimiters       -->
<!-- analagous to < and > of XML.   Make these delimiters  -->
<!-- exceedingly unique.  Comment out salt while debugging -->
<!-- if it helps to see intermediate structure. Or leave   -->
<!-- salt in, and grep final output for this "bad" string  -->
<!-- that should not survive.                              -->

<!-- Random-ish output from  mkpasswd  utility, -->
<!-- 2017-10-24 at AMS airport, Starbucks by gate D1 -->
<xsl:variable name="salt" select="'x9rNtyUydoz3o'" />

<xsl:variable name="LB" select="'[[['" />

<xsl:variable name="RB">
    <!-- <xsl:value-of select="$salt" /> -->
    <xsl:text>]]]</xsl:text>
</xsl:variable>

<!-- These are analagous to XML opening           -->
<!-- ("begin", B) and closing ("end", E) elements -->

<!-- Destined to be string -->
<xsl:variable name="BS">
    <xsl:value-of select="$LB" />
    <xsl:text>BS</xsl:text>
    <xsl:value-of select="$RB" />
</xsl:variable>
<xsl:variable name="ES">
    <xsl:value-of select="$LB" />
    <xsl:text>ES</xsl:text>
    <xsl:value-of select="$RB" />
</xsl:variable>

<!-- Destined to be a Jupyter markdown cell in JSON output-->
<xsl:variable name="BM">
    <xsl:value-of select="$LB" />
    <xsl:text>BM</xsl:text>
    <xsl:value-of select="$RB" />
</xsl:variable>

<xsl:variable name="EM">
    <xsl:value-of select="$LB" />
    <xsl:text>EM</xsl:text>
    <xsl:value-of select="$RB" />
</xsl:variable>

<!-- Destined to be a Jupyter code cell in JSON output-->
<xsl:variable name="BC">
    <xsl:value-of select="$LB" />
    <xsl:text>BC</xsl:text>
    <xsl:value-of select="$RB" />
</xsl:variable>

<xsl:variable name="EC">
    <xsl:value-of select="$LB" />
    <xsl:text>EC</xsl:text>
    <xsl:value-of select="$RB" />
</xsl:variable>

<!-- Destined to be a newline in JSON output        -->
<!-- We often need to be very careful with newlines -->
<!-- This is like an empty, or self-closing tag     -->
<xsl:variable name="NL">
    <xsl:value-of select="$LB" />
    <xsl:text>NL</xsl:text>
    <xsl:value-of select="$RB" />
</xsl:variable>

<!-- Combinations -->

<!-- These variables describe adjacent pseudo-markup   -->
<!-- that will be converted to JSON equivalents,       -->
<!-- or in the last case, an intermediate combination. -->

<xsl:variable name="ESBS">
    <xsl:value-of select="$ES" />
    <xsl:value-of select="$BS" />
</xsl:variable>

<xsl:variable name="RBLB">
    <xsl:value-of select="$RB" />
    <xsl:value-of select="$LB" />
</xsl:variable>

<xsl:variable name="RBLB-comma">
    <xsl:value-of select="$RB" />
    <xsl:text>,&#xa;</xsl:text>
    <xsl:value-of select="$LB" />
</xsl:variable>

<!-- Convenience templates -->
<!-- These are primary interface to our creation           -->
<!-- of pseudo-markup above, but are not the whole         -->
<!-- story since we convert markup based oon the variables -->

<!-- TODO: global search/replace to make more unique names -->

<xsl:template name="begin-string">
    <xsl:value-of select="$BS" />
</xsl:template>

<xsl:template name="end-string">
    <xsl:value-of select="$ES" />
</xsl:template>

<!-- Will be a start of a markdown cell eventually -->
<xsl:template name="begin-inline">
    <xsl:value-of select="$BM" />
</xsl:template>

<xsl:template name="end-inline">
    <xsl:value-of select="$EI" />
</xsl:template>

<xsl:template name="begin-markdown-cell">
    <xsl:value-of select="$BM" />
</xsl:template>

<xsl:template name="end-markdown-cell">
    <xsl:value-of select="$EM" />
</xsl:template>

<xsl:template name="begin-code-cell">
    <xsl:value-of select="$BC" />
</xsl:template>

<xsl:template name="end-code-cell">
    <xsl:value-of select="$EC" />
</xsl:template>

<xsl:template name="newline">
    <xsl:value-of select="$NL" />
</xsl:template>


<!-- ################# -->
<!-- Cell Construction -->
<!-- ################# -->

<xsl:variable name="begin-markdown-wrap">
    <xsl:text>{"cell_type": "markdown", "metadata": {}, "source": [&#xa;</xsl:text>
</xsl:variable>

<xsl:variable name="end-markdown-wrap">
    <xsl:text>]}</xsl:text>
</xsl:variable>

<xsl:variable name="begin-code-wrap">
    <xsl:text>{"cell_type" : "code", "execution_count" : null, "metadata" : {}, "source": [&#xa;</xsl:text>
</xsl:variable>

<xsl:variable name="end-code-wrap">
    <xsl:text>],"outputs" : []}</xsl:text>
</xsl:variable>

<!-- A Jupyter markdown cell intended  -->
<!-- to hold markdown or unstyled HTML -->
<xsl:template name="markdown-cell">
    <xsl:param name="content" />
    <xsl:call-template name="begin-markdown-cell" />
    <xsl:value-of select="$content" />
    <xsl:call-template name="end-markdown-cell" />
</xsl:template>

<!-- A Jupyter markdown cell intended -->
<!-- to hold PreTeXt styled HTML      -->
<!-- Serialization here is "by hand"  -->
<xsl:template name="pretext-cell">
    <xsl:param name="content" />
    <xsl:call-template name="begin-markdown-cell" />
    <xsl:call-template name="begin-string" />
    <xsl:text>&lt;div class="mathbook-content"&gt;</xsl:text>
    <xsl:call-template name="end-string" />
    <xsl:value-of select="$content" />
    <xsl:call-template name="begin-string" />
    <xsl:text>&lt;/div&gt;</xsl:text>
    <xsl:call-template name="end-string" />
    <xsl:call-template name="end-markdown-cell" />
</xsl:template>

<!-- A Jupyter code cell intended -->
<!-- to hold raw text/code        -->
<xsl:template name="code-cell">
    <xsl:param name="content" />
    <xsl:call-template name="begin-code-cell" />
    <xsl:value-of select="$content" />
    <xsl:call-template name="end-code-cell" />
</xsl:template>

</xsl:stylesheet>
