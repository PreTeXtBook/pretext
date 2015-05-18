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

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
    >

<xsl:import href="./mathbook-common.xsl" />
<xsl:import href="./mathbook-markdown-common.xsl" />

<!-- Output is JSON -->
<xsl:output method="text" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->
<!-- Variables that affect HTML creation -->
<!-- More in the common file             -->

<!-- We generally want to chunk longer Jupyter output -->
<!-- Copied from HTML, less deprecated switch         -->
<xsl:variable name="chunk-level">
    <xsl:choose>
        <xsl:when test="$chunk.level != ''">
            <xsl:value-of select="$chunk.level" />
        </xsl:when>
        <xsl:when test="/mathbook/book">2</xsl:when>
        <xsl:when test="/mathbook/article/section">1</xsl:when>
        <xsl:when test="/mathbook/article">0</xsl:when>
        <xsl:when test="/mathbook/letter">0</xsl:when>
        <xsl:when test="/mathbook/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Jupyter chunk level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Jupyter notebook conversion is experimental and incomplete&#xa;Please report major problems and/or send feature requests</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="mathbook" mode="deprecation-warnings" />
    <xsl:apply-templates />
</xsl:template>

<!-- We process structural nodes via chunking routine in  xsl/mathbook-common.html -->
<!-- This in turn calls specific modal templates defined elsewhere in this file    -->
<xsl:template match="/mathbook">
    <xsl:apply-templates mode="chunk" />
</xsl:template>

<!-- ################ -->
<!-- Structural Nodes -->
<!-- ################ -->

<!-- Read the code and documentation for "chunking" in xsl/mathbook-common.html -->
<!-- This will explain document structure (not XML structure) and has the       -->
<!-- routines which call the necessary realizations of two abstract templates.  -->

<!-- Three modal templates accomodate all document structure nodes -->
<!-- and all possibilities for chunking.  Read the description     -->
<!-- in  xsl/mathbook-common.xsl to understand these.              -->
<!-- The  "file-wrap"  template is defined elsewhre in this file.  -->

<!-- HTML markup common to every structural node. -->
<!-- Both as outer-level of a page and as subsidiary to a page. -->
<xsl:template match="*" mode="content-wrap">
    <xsl:param name="content" />
    <!-- Top-level is 0, so add one at use-->
    <xsl:variable name="level">
        <xsl:apply-templates select="." mode="level" />
    </xsl:variable>
    <!-- wrap a single header string as cell -->
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <!-- <xsl:text>, "</xsl:text> -->
            <xsl:call-template name="heading-format">
                <xsl:with-param name="count" select="$level + 1" />
            </xsl:call-template>
            <xsl:apply-templates select="." mode="title-simple" />
            <xsl:call-template name="end-string" />
            <!-- <xsl:text>"</xsl:text> -->
        </xsl:with-param>
    </xsl:call-template>
    <!-- content of subdivision as multiple cells -->
    <xsl:copy-of select="$content" />
</xsl:template>

<!-- The HTML content of a page representing an intermediate node.                 -->
<!-- Note: the necessity of the <nav> section creates two problems:                -->
<!-- (i)  We implement a 3-pass hack which requires identifing, eg,                -->
<!-- an introduction as preceding a conclusion, and eg, hiding the killing titles. -->
<!-- (ii) We generally could have maybe just requied a modal template              -->
<!-- for a summary of a structural node and moved processing all the page          -->
<!-- elements into the  mathbook-common  routines                                  -->
<xsl:template match="*" mode="structure-node-intermediate">
    <xsl:apply-templates select="*" mode="summary-prenav" />
    <nav class="summary-links">
        <xsl:apply-templates select="*" mode="summary-nav" />
    </nav>
    <xsl:apply-templates select="*" mode="summary-postnav"/>
</xsl:template>


<!-- A 3-pass hack to create presentations and summaries of  -->
<!-- an intermediate node.  It is the <nav> section wrapping -->
<!-- the summaries/links that makes this necessary.          -->
<!-- Note: titles/authors etc are killed here                -->
<!-- TODO: improve this somehow?                             -->

<!-- Pre-Navigation -->
<xsl:template match="introduction|titlepage|abstract" mode="summary-prenav">
    <xsl:apply-templates select="."/>
</xsl:template>
<xsl:template match="*" mode="summary-prenav" />

<!-- Post-Navigation -->
<xsl:template match="conclusion" mode="summary-postnav">
    <xsl:apply-templates select="."/>
</xsl:template>
<xsl:template match="*" mode="summary-postnav" />

<!-- Navigation -->
<!-- Any structural node becomes a hyperlink        -->
<!-- Could recurse into "dispatch" inside the "if", -->
<!-- but might pile too much onto the stack?        -->
<xsl:template match="*" mode="summary-nav">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:if test="$structural='true'">
        <xsl:call-template name="markdown-cell">
            <xsl:with-param name="content">
                <xsl:call-template name="begin-string" />
                <xsl:text>## </xsl:text>
                <xsl:text>[</xsl:text>
                <xsl:apply-templates select="." mode="number" />
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="." mode="title-simple" />
                <xsl:text>]</xsl:text>
                <xsl:text>(</xsl:text>
                <xsl:apply-templates select="." mode="url" />
                <xsl:text>)</xsl:text>
                <xsl:call-template name="end-string" />
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>
</xsl:template>



<!-- Kill various parts temporarily -->
<xsl:template match="title" />
<xsl:template match="subtitle" />
<xsl:template match="frontmatter" />
<xsl:template match="notation" />

<!-- Kill some templates temporarily -->
<xsl:template name="inline-warning" />
<xsl:template name="margin-warning" />
<xsl:template match="index" />

<!-- Book length inactive -->
<xsl:template match="/book">
    <xsl:message terminate="yes">Book length documents do not yet convert to Jupyter notebooks.  Quitting...</xsl:message>
</xsl:template>




<!-- File Structure -->
<!-- Gross structure of a Jupyter notebook -->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />
    <!--  -->
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="filename" />
    </xsl:variable>
    <!-- every cell added leads with comma-space, ends plain -->
    <xsl:variable name="cell-list">
        <!-- load LaTeX macros for MathJax -->
        <xsl:call-template name="load-macros" />
        <xsl:copy-of select="$content" />
    </xsl:variable>
    <exsl:document href="{$filename}" method="text">
        <!-- TODO JSON COMMENT -->
        <!-- <xsl:call-template name="converter-blurb-html" /> -->
        <xsl:text>{&#xa;</xsl:text>
        <!-- version identifiers -->
        <xsl:text>  "nbformat": 4,&#xa;</xsl:text>
        <xsl:text>  "nbformat_minor": 0,&#xa;</xsl:text>
        <!-- metadata copied from blank SMC notebook -->
        <xsl:text>  "metadata": {&#xa;</xsl:text>
        <xsl:text>  "kernelspec": {&#xa;</xsl:text>
        <xsl:text>   "display_name": "Sage 6.9",&#xa;</xsl:text>
        <xsl:text>   "language": "",&#xa;</xsl:text>
        <xsl:text>   "name": "sage-6.9"&#xa;</xsl:text>
        <!-- <xsl:text>   "display_name": "Python 2",&#xa;</xsl:text> -->
        <!-- <xsl:text>   "language": "python",&#xa;</xsl:text> -->
        <!-- <xsl:text>   "name": "python2"&#xa;</xsl:text> -->
        <xsl:text>  },&#xa;</xsl:text>
        <xsl:text>  "language_info": {&#xa;</xsl:text>
        <xsl:text>   "codemirror_mode": {&#xa;</xsl:text>
        <xsl:text>    "name": "ipython",&#xa;</xsl:text>
        <xsl:text>    "version": 2&#xa;</xsl:text>
        <xsl:text>   },&#xa;</xsl:text>
        <xsl:text>   "file_extension": ".py",&#xa;</xsl:text>
        <xsl:text>   "mimetype": "text/x-python",&#xa;</xsl:text>
        <xsl:text>   "name": "python",&#xa;</xsl:text>
        <xsl:text>   "nbconvert_exporter": "python",&#xa;</xsl:text>
        <xsl:text>   "pygments_lexer": "ipython2",&#xa;</xsl:text>
        <xsl:text>   "version": "2.7.8"&#xa;</xsl:text>
        <xsl:text>  },&#xa;</xsl:text>
        <xsl:text>  "name": "</xsl:text>
        <xsl:value-of select="$filename" />
        <xsl:text>"&#xa;</xsl:text>
        <xsl:text> },&#xa;</xsl:text>
        <!-- cell list, majority of notebook -->
        <xsl:text>   "cells": [</xsl:text>

        <!-- A cell with no trailing comma -->
        <!-- TODO maybe lead with macros or whitespace -->
        <!-- <xsl:call-template name="empty-lead-cell" /> -->
        <!-- Conditionally include necessary commands -->
        <!-- <xsl:call-template name="load-sage-library" /> -->
        <!-- The cells of the notebook -->
        <!-- Strip leading ", " of first cell -->
        <xsl:value-of select="substring($cell-list, 3)" />
        <!-- end cell list -->
        <xsl:text>&#xa;]&#xa;</xsl:text>
        <!-- end outermost group -->
        <xsl:text>}&#xa;</xsl:text>
    </exsl:document>
</xsl:template>


<!-- Macros, escape backslashes, join lines, -->
<!-- wrap in string, dollars, wrap as a cell -->
<!-- TODO: sanitize left margin              -->
<xsl:template name="load-macros">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>$</xsl:text>
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text">
                    <xsl:call-template name="string-replace-all">
                        <xsl:with-param name="text">
                            <xsl:value-of select="/mathbook/docinfo/macros" />
                        </xsl:with-param>
                        <xsl:with-param name="replace" select="'\'" />
                        <xsl:with-param name="by" select="'\\'" />
                    </xsl:call-template>
                </xsl:with-param>
                <xsl:with-param name="replace" select="'&#xa;'" />
                <xsl:with-param name="by" select="''" />
            </xsl:call-template>
            <xsl:text>$</xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>



<!-- Make an initial header for an article -->
<xsl:template match="article/frontmatter/titlepage">
    <xsl:text>,&#xa;{"cell_type" : "markdown", "metadata": {}, "source": [&#xa;</xsl:text>
    <!-- commas lead subsequent cells -->
    <!-- cannot get -> <- to center   -->
    <xsl:text>"# </xsl:text>
        <xsl:value-of select="/mathbook/article/title" />
    <xsl:text>\n"</xsl:text>
    <xsl:text>,&#xa;"</xsl:text>
        <xsl:apply-templates select="author/personname" />
    <xsl:text>\n"</xsl:text>
    <xsl:text>,&#xa;"</xsl:text>
        <xsl:apply-templates select="event" />
    <xsl:text>\n"</xsl:text>
    <xsl:text>,&#xa;"</xsl:text>
        <xsl:apply-templates select="date" />
    <xsl:text>"</xsl:text>
    <xsl:text>]&#xa;</xsl:text>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- ################# -->
<!-- Block Level Items -->
<!-- ################# -->

<!-- Block-level paragraphs are cells of their own -->
<xsl:template match="p">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:apply-templates />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- statement only, notation is not shown here -->
<xsl:template match="definition">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>**</xsl:text>
            <xsl:apply-templates select=".." mode="type-name" />
            <xsl:text> </xsl:text>
            <xsl:apply-templates select=".." mode="number" />
            <!-- if title? -->
            <xsl:text>** </xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="statement" />
</xsl:template>

<!-- Drop a title in a cell and process remainder -->
<xsl:template match="theorem|corollary|lemma|proposition|example|remark">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>**</xsl:text>
            <xsl:apply-templates select=".." mode="type-name" />
            <xsl:text> </xsl:text>
            <xsl:apply-templates select=".." mode="number" />
            <!-- if title? -->
            <xsl:text>** </xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates />
</xsl:template>

<!-- meant for theorem-like, and definition -->
<!-- Also for exercises                     -->
<xsl:template match="statement">
    <xsl:apply-templates />
</xsl:template>

<!-- Drop a "proof" header  -->
<xsl:template match="proof">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>**</xsl:text>
            <xsl:apply-templates select="." mode="type-name" />
            <xsl:text>** </xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates />
</xsl:template>

<!-- not structural, no number or name -->
<xsl:template match="paragraphs">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>**</xsl:text>
            <xsl:apply-templates select="." mode="title-full" />
            <xsl:text>** </xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates />
</xsl:template>

<!-- Header inline, then sequence of paragraphs (say) -->
<xsl:template match="exercises/exercise|exercises/exercisegroup/exercise">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>**</xsl:text>
            <xsl:apply-templates select="." mode="type-name" />
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="serial-number" />
            <xsl:text>** </xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="statement" />
</xsl:template>

<!-- Sage code, a bit hackish -->
<xsl:template match="sage">
    <!-- formulate lines of code -->
    <xsl:variable name="loc">
        <xsl:call-template name="sanitize-code">
            <xsl:with-param name="raw-code">
                <!-- use text() macro to fix backslashes, quotes -->
                <xsl:apply-templates select="input" />
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <!-- we trim a final trailing newline -->
    <xsl:variable name="loc-trim" select="substring($loc, 1, string-length($loc)-1)" />
    <!-- the code, content with string markers -->
    <xsl:variable name="the-code">
        <xsl:call-template name="begin-string" /> <!-- start first string -->
        <xsl:value-of select="str:replace($loc-trim, '&#xa;', concat('\n', $ESBS))" />
        <xsl:call-template name="end-string" /> <!-- end last string -->
    </xsl:variable>
    <!-- use codecell template to adjust no matter what? -->
    <xsl:text>,&#xa;</xsl:text> <!-- end previous cell -->
    <xsl:text>{"cell_type" : "code", "execution_count" : null, "metadata" : {}, "source": [&#xa;</xsl:text>
    <xsl:variable name="split" select="str:replace($the-code, $ESBS, '&quot;,&#xa;&quot;')" />
    <xsl:value-of select="str:replace(str:replace($split, $ES, '&quot;'), $BS, '&quot;')" />
    <xsl:text>&#xa;],</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>"outputs" : []</xsl:text>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- This is the implementation of an abstract template -->
<xsl:template match="*" mode="xref-number">
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<!-- In common template, but have to point -->
<!-- to it since it is a modal template    -->
<xsl:template match="exercisegroup" mode="xref-number">
    <xsl:apply-imports />
</xsl:template>

<!-- straight copy - - - except for file ending -->
<!-- Filenames -->
<!-- Every web page has a file name,                           -->
<!-- and every node is subsidiary to some web page.            -->
<!-- This template give the filename of the webpage enclosing  -->
<!-- any node (or the webpage representing that node)          -->
<!-- This allows cross-references to point to the right page   -->
<!-- when chunking the content into many subdivisions          -->
<xsl:template match="*" mode="filename">
    <xsl:variable name="intermediate"><xsl:apply-templates select="." mode="is-intermediate" /></xsl:variable>
    <xsl:variable name="chunk"><xsl:apply-templates select="." mode="is-chunk" /></xsl:variable>
    <xsl:choose>
        <xsl:when test="$intermediate='true' or $chunk='true'">
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>.ipynb</xsl:text>
            <!-- DEPRECATION: May 2015, replace with terminate=yes if present without an xml:id -->
            <xsl:if test="@filebase">
                <xsl:message>MBX:WARNING: filebase attribute (value=<xsl:value-of select="@filebase" />) is deprecated, use xml:id attribute instead</xsl:message>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select=".." mode="filename" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- This is a straight copy from HTML -->
<!-- Maybe it belongs in common, despite being online only -->
<!-- URL's -->
<!-- Every node has a URL associated with it -->
<!-- A filename, plus an optional anchor/id  -->
<xsl:template match="*" mode="url">
    <xsl:variable name="intermediate"><xsl:apply-templates select="." mode="is-intermediate" /></xsl:variable>
    <xsl:variable name="chunk"><xsl:apply-templates select="." mode="is-chunk" /></xsl:variable>
    <xsl:apply-templates select="." mode="filename" />
    <xsl:if test="$intermediate='false' and $chunk='false'">
        <xsl:text>#</xsl:text>
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:if>
</xsl:template>

<!-- The second abstract template, we condition   -->
<!-- on if the link is rendered as a knowl or not -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="content" />
    <!-- text in square brackets -->
    <xsl:text>[</xsl:text>
    <xsl:value-of select="$content" />
    <xsl:text>]</xsl:text>
    <!-- url in parentheses -->
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="." mode="url" />
    <xsl:text>)</xsl:text>
</xsl:template>


<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- Allows for a width, but needs HTML syntax.   -->
<!-- Not employed just yet, see the markdown      -->
<!-- "image-wrap" template in markdown-common.xsl -->
<xsl:template name="image-html-wrap">
    <xsl:param name="filename" />
    <xsl:param name="width" select="''" />
    <xsl:text disable-output-escaping="yes">&lt;img src=\"</xsl:text>
    <xsl:value-of select="$filename" />
    <xsl:text>\"</xsl:text>
    <xsl:if test="not($width='')">
        <xsl:text> width=\"</xsl:text>
        <xsl:apply-templates select="$width" />
        <xsl:text>\"</xsl:text>
    </xsl:if>
    <xsl:text disable-output-escaping="yes"> /&gt;</xsl:text>
</xsl:template>

<!-- Presumes inside some wrapper (figure most likely) -->
<!-- ![ ]( ) syntax does not seem to work              -->
<xsl:template match="image[@source]" >
    <xsl:call-template name="begin-string" />
    <xsl:call-template name="image-wrap">
        <xsl:with-param name="filename" select="@source" />
    </xsl:call-template>
    <xsl:call-template name="end-string" />
</xsl:template>

<xsl:template match="image[child::latex-image-code]">
    <xsl:call-template name="begin-string" />
    <xsl:call-template name="image-wrap">
        <xsl:with-param name="filename">
            <xsl:value-of select="$directory.images" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>.svg</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="alt-description">
            <xsl:apply-templates select="description" />
        </xsl:with-param>
<!--
        Grab a caption: this works but template produces string markers which become quotes
        <xsl:with-param name="tooltip-title">
            <xsl:apply-templates select="parent::*/caption" />
        </xsl:with-param>
-->
    </xsl:call-template>
    <xsl:call-template name="end-string" />
</xsl:template>


<!-- ####### -->
<!-- Figures -->
<!-- ####### -->

<xsl:template match="caption">
    <xsl:call-template name="begin-string" />
    <xsl:apply-templates select="parent::*" mode="type-name"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="parent::*" mode="number"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates />
    <xsl:call-template name="end-string" />
</xsl:template>

<xsl:template match="figure">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:apply-templates select="*[not(self::caption)]" />
            <xsl:apply-templates select="caption" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>




<!-- ########## -->
<!-- Paragraphs -->
<!-- ########## -->

<!-- #### -->
<!-- Math -->
<!-- #### -->

<!-- $ for MathJax            -->
<!-- Sanitize TeX backslashes -->
<xsl:template match="m">
    <xsl:text>$</xsl:text>
    <xsl:apply-templates />
    <xsl:text>$</xsl:text>
</xsl:template>

<!-- Single Displayed Equations      -->
<!-- Write escaped TeX backslashes   -->
<xsl:template match="me">
    <xsl:text>\\begin{equation}</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\\end{equation}</xsl:text>
</xsl:template>

<!-- TODO: Straight out of LaTeX, but sanitized some -->

<!-- Multi-Line Math -->
<!-- Multi-line displayed equations container, globally unnumbered or numbered   -->
<!-- mrow logic controls numbering, based on variant here, and per-row overrides -->
<!-- align environment if ampersands are present, gather environment otherwise   -->
<!-- Output follows source line breaks                                           -->
<xsl:template match="md">
    <xsl:choose>
        <xsl:when test="contains(., '&amp;')">
            <xsl:text>\\begin{align*}\n</xsl:text>
            <xsl:apply-templates select="mrow|intertext" />
            <xsl:text>\\end{align*}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\\begin{gather*}\n</xsl:text>
            <xsl:apply-templates select="mrow|intertext" />
            <xsl:text>\\end{gather*}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="mdn">
    <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text">
            <xsl:choose>
                <xsl:when test="contains(., '&amp;')">
                    <xsl:text>\begin{align}\n</xsl:text>
                    <xsl:apply-templates select="mrow|intertext" />
                    <xsl:text>\end{align}</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\begin{gather}\n</xsl:text>
                    <xsl:apply-templates select="mrow|intertext" />
                    <xsl:text>\end{gather}</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="replace" select="string('\')" />
        <xsl:with-param name="by" select="string('\\')" />
    </xsl:call-template>
</xsl:template>

<!-- Rows of a multi-line math display -->
<!-- Numbering controlled here with \label{}, \notag, or nothing -->
<!-- Last row different, has no line-break marker                -->
<xsl:template match="md/mrow">
    <xsl:apply-templates />
    <xsl:choose>
        <xsl:when test="@number='yes'">
            <xsl:apply-templates select="." mode="label" />
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
    <!-- write newline for markdown source formatting -->
    <xsl:if test="position()!=last()">
       <xsl:text>\\\\\n</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="mdn/mrow">
    <xsl:apply-templates />
    <xsl:choose>
        <xsl:when test="@number='no'">
            <xsl:text>\notag</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="label" />
        </xsl:otherwise>
    </xsl:choose>
    <!-- write newline for markdown source formatting -->
    <xsl:if test="position()!=last()">
       <xsl:text>\\\\\n</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Intertext -->
<!-- An <mrow> will provide trailing newline, so do the same here -->
<xsl:template match="md/intertext|mdn/intertext">
    <xsl:text>\intertext{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\n</xsl:text>
</xsl:template>





<!-- Standard Sage cells -->
<!-- TODO: plug into abstract cell infrastructure -->
<!-- <xsl:template match="sage">
    <xsl:text>,&#xa;{"cell_type": "code", "source": ["</xsl:text>
    <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text">
            <xsl:call-template name="sanitize-code">
                <xsl:with-param name="raw-code" select="input" />
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="replace" select="string('&#xa;')" />
        <xsl:with-param name="by" select="string('\n')" />
    </xsl:call-template>
    <xsl:text>"],&#xa;"metadata": {}, "outputs": [], "execution_count": null}</xsl:text>
</xsl:template>
 -->


<!-- Build markdown, then sanitize -->
<xsl:template match="c">
    <!-- <xsl:message>in c</xsl:message> -->
    <xsl:call-template name="escape-quotes">
        <xsl:with-param name="text">
            <xsl:apply-imports />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>





<!-- " in JSON is touchy -->
<xsl:template match="q">
    <xsl:text>\"</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\"</xsl:text>
</xsl:template>

<!-- Line break in Markdown is a carriage return (hex A) -->
<!-- Strings in JSON like a split better                 -->
<xsl:template match="br">
    <xsl:text>\n", "</xsl:text>
</xsl:template>

<!-- http://stackoverflow.com/questions/3067113/xslt-string-replace -->
<xsl:template name="string-replace-all">
    <xsl:param name="text" />
    <xsl:param name="replace" />
    <xsl:param name="by" />
    <xsl:choose>
        <xsl:when test="contains($text, $replace)">
            <xsl:value-of select="substring-before($text,$replace)" />
            <xsl:value-of select="$by" />
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="substring-after($text,$replace)" />
                <xsl:with-param name="replace" select="$replace" />
                <xsl:with-param name="by" select="$by" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- <xsl:template match="text()">
    <xsl:if test="contains(., '&#xa;')">
        <xsl:message>CR: <xsl:value-of select="." /></xsl:message>
    </xsl:if>
    <xsl:value-of select="str:replace(., '&#xa;', '[CR]')" />
    <xsl:if test="contains(., '&#xa;')">
        <xsl:message>CR: <xsl:value-of select="str:replace(., '&#xa;', '')" /></xsl:message>
    </xsl:if>
</xsl:template>
 -->

<!-- space          &#x20; -->
<!-- tab             &#x9; -->
<!-- carriage return &#xd; -->
<!-- new line        &#xa; -->

<!-- Escape backslash first, then escape any textual quotations -->
<!-- These latex constructions may have matrices, etc           -->
<!-- with newlines and tabs in the margins.  Newlines           -->
<!-- become \n, and tabs become single spaces                  -->
<xsl:template match="m/text()|me/text()|men/text()|mrow/text()">
    <xsl:value-of select="str:replace(str:replace(str:replace(str:replace(., '\', '\\'), '&quot;', '\&quot;'), '&#xa;', '\n'), '&#x9;', '&#x20;')" />
</xsl:template>

<!-- Sanitize Sage code - newlines are addressed elsewhere -->
<xsl:template match="sage/input/text()|sage/output/text()">
    <xsl:value-of select="str:replace(str:replace(., '\', '\\'), '&quot;', '\&quot;')" />
</xsl:template>

<!-- Sanitize inline code - no newlines should be present -->
<xsl:template match="c/text()">
    <xsl:value-of select="str:replace(str:replace(., '\', '\\'), '&quot;', '\&quot;')" />
</xsl:template>

<!-- Sanitize everything else -->
<!-- newlines to warning now, maybe to "\n" eventually -->
<xsl:template match="text()">
    <!-- long-term: remove variable for clean sources -->
    <xsl:variable name="escaped-string">
        <xsl:value-of select="str:replace(str:replace(., '\', '\\'), '&quot;', '\&quot;')" />
    </xsl:variable>
    <!-- newlines, tabs -->
    <xsl:value-of select="str:replace(str:replace($escaped-string, '&#xa;', '[CR]'), '&#x9;', '')" />
</xsl:template>



<!-- MAYBE text() needs backslashes escaped universally, then quotes -->
<!-- and no "value-of" so the template gets applied. -->

<xsl:template name="escape-quotes">
    <xsl:param name="text" />
    <!-- <xsl:message>in eq: <xsl:value-of select="$text" /></xsl:message> -->
    <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text" select="$text" />
        <xsl:with-param name="replace" select="string('&#x22;')" />
        <xsl:with-param name="by" select="string('\&#x22;')" />
    </xsl:call-template>
</xsl:template>

<!-- ################# -->
<!-- String Management -->
<!-- ################# -->

<xsl:variable name="BS">
    <xsl:text>[BS]</xsl:text>
</xsl:variable>
<xsl:variable name="ES">
    <xsl:text>[ES]</xsl:text>
</xsl:variable>
<!-- useful for chunking up verbatim text -->
<xsl:variable name="ESBS">
    <xsl:value-of select="$ES" />
    <xsl:value-of select="$BS" />
</xsl:variable>

<xsl:template name="begin-string">
    <xsl:value-of select="$BS" />
</xsl:template>

<xsl:template name="end-string">
    <xsl:value-of select="$ES" />
</xsl:template>

<!-- ################# -->
<!-- Cell Construction -->
<!-- ################# -->

<!-- Hack to avoid dealing with  n - 1 -->
<!-- commas in a list of length  n     -->
<!-- A cell with no comma to lead,     -->
<!-- all subsequent lead w/ a comma    -->
<!-- A single space squashes prompt to -->
<!-- start typing someting in the cell -->
<!-- <xsl:template name="empty-lead-cell">
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>{"cell_type" : "markdown", "metadata": {}, "source": [&#xa;</xsl:text>
    <xsl:text>" "</xsl:text>
    <xsl:text>&#xa;]}</xsl:text>
</xsl:template>
 -->
<!--
<xsl:template name="markdown-cell">
    <xsl:param name="content" />
    <xsl:text>,&#xa;</xsl:text>
    <xsl:text>{"cell_type" : "markdown", "metadata": {}, "source": [&#xa;</xsl:text>
    <xsl:copy-of select="$content" />
    <xsl:text>&#xa;]}</xsl:text>
</xsl:template>
 -->
<!-- Expects a list of strings, with n-1 commas -->
<xsl:template name="markdown-cell">
    <xsl:param name="content" />
    <!--  -->
    <xsl:text>,&#xa;</xsl:text> <!-- end previous cell -->
    <xsl:text>{"cell_type": "markdown", "metadata": {}, "source": [&#xa;</xsl:text>
    <xsl:variable name="split" select="str:replace($content, $ESBS, '&quot;,&#xa;&quot;')" />
    <xsl:value-of select="str:replace(str:replace($split, $ES, '&quot;'), $BS, '&quot;')" />
    <xsl:text>&#xa;]}</xsl:text>
</xsl:template>

<xsl:template name="code-cell">
    <xsl:param name="content" />
    <!--  -->
    <xsl:text>,&#xa;</xsl:text> <!-- end previous cell -->
    <xsl:text>{"cell_type" : "code", "execution_count" : null, "metadata" : {}, "source": [&#xa;</xsl:text>
    <xsl:variable name="split" select="str:replace($content, $ESBS, '&quot;,&#xa;&quot;')" />
    <xsl:value-of select="str:replace(str:replace($split, $ES, '&quot;'), $BS, '&quot;')" />
    <xsl:text>&#xa;],</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>"outputs" : []</xsl:text>
    <xsl:text>}</xsl:text>
</xsl:template>

</xsl:stylesheet>