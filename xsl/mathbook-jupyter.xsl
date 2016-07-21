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

<!-- iPython files as output -->
<xsl:variable name="file-extension" select="'.ipynb'" />


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
<xsl:template match="mathbook">
    <xsl:apply-templates mode="chunking" />
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

<!-- Markup common to every structural node.                    -->
<!-- Both as outer-level of a page and as subsidiary to a page. -->
<xsl:template match="&STRUCTURAL;">
    <!-- Top-level is 0, so add one at use-->
    <xsl:variable name="level">
        <xsl:apply-templates select="." mode="level" />
    </xsl:variable>
    <!-- wrap a single header string as cell -->
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:call-template name="heading-format">
                <xsl:with-param name="count" select="$level + 1" />
            </xsl:call-template>
            <xsl:apply-templates select="." mode="number" />
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="title-full" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates />
</xsl:template>

<!-- Some structural nodes do not need their title,                -->
<!-- (or subtitle) so we don't put a section heading there         -->
<!-- Title(s) for an article are forced by a frontmatter/titlepage -->
<xsl:template match="article|frontmatter">
    <xsl:apply-templates />
</xsl:template>

<!-- Content of a summary page is usual content, -->
<!-- or link to subsidiary content               -->
<xsl:template match="&STRUCTURAL;" mode="summary">
    <!-- Top-level is 0, so add one at use-->
    <xsl:variable name="level">
        <xsl:apply-templates select="." mode="level" />
    </xsl:variable>
    <!-- wrap a single header string as cell -->
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:call-template name="heading-format">
                <xsl:with-param name="count" select="$level + 1" />
            </xsl:call-template>
            <xsl:apply-templates select="." mode="number" />
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="title-full" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:for-each select="*">
        <xsl:choose>
            <xsl:when test="&STRUCTURAL-FILTER;">
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
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
</xsl:template>


<!-- Mark unimplemented parts with [NI-elementname] -->
<!-- cell level first -->
<xsl:template match="tabular">
    <xsl:call-template name="begin-markdown-cell" />
    <xsl:call-template name="begin-string" />
    <xsl:variable name="element-name" select="local-name(.)" />
    <xsl:text>[NI-</xsl:text>
    <xsl:value-of select="$element-name" />
    <xsl:text>]</xsl:text>
    <!-- <xsl:value-of select="." /> -->
    <xsl:text>[NI-</xsl:text>
    <xsl:value-of select="$element-name" />
    <xsl:text>]</xsl:text>
    <xsl:call-template name="end-string" />
    <xsl:call-template name="end-markdown-cell" />
</xsl:template>

<!-- sentence level next -->
<xsl:template match="fn">
    <xsl:variable name="element-name" select="local-name(.)" />
    <xsl:text>[NI-</xsl:text>
    <xsl:value-of select="$element-name" />
    <xsl:text>]</xsl:text>
    <!-- <xsl:value-of select="." /> -->
    <xsl:text>[NI-</xsl:text>
    <xsl:value-of select="$element-name" />
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- Kill various parts temporarily -->
<xsl:template match="frontmatter" />
<xsl:template match="notation" />

<!-- Kill some templates temporarily -->
<xsl:template name="inline-warning" />
<xsl:template name="margin-warning" />
<xsl:template match="index" />

<!-- File Structure -->
<!-- Gross structure of a Jupyter notebook -->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />
    <!--  -->
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="containing-filename" />
    </xsl:variable>
    <xsl:variable name="cell-list">
        <!-- load LaTeX macros for MathJax -->
        <xsl:call-template name="load-macros" />
        <xsl:copy-of select="$content" />
    </xsl:variable>
    <exsl:document href="{$filename}" method="text">
        <!-- <xsl:call-template name="converter-blurb-html" /> -->
        <!-- begin outermost group -->
        <xsl:text>{&#xa;</xsl:text>
        <!-- cell list first, majority of notebook, metadata to finish -->
        <xsl:text>"cells": [&#xa;</xsl:text>
        <!-- Massage string delimiters, separators -->
        <xsl:variable name="split-strings" select="str:replace($cell-list, $ESBS, '&quot;,&#xa;&quot;')" />
        <xsl:variable name="finalize-strings" select="str:replace(str:replace($split-strings, $ES, '&quot;'), $BS, '&quot;')" />
        <!-- Massage cell delimiters, separators -->
        <!-- first, square inline headings to cell separators -->
        <xsl:variable name="inline-headings" select="str:replace($finalize-strings, $EIBM, ',&#xa;')" />
        <!-- now split cell separators -->
        <xsl:variable name="split-cells" select="str:replace($inline-headings, $RBLB, $RBLB-comma)" />
        <!-- now replace cell markers with actual wrappers -->
        <xsl:variable name="markdown-cells" select="str:replace(str:replace($split-cells, $BM, $begin-markdown-wrap), $EM, $end-markdown-wrap)" />
        <xsl:variable name="code-cells" select="str:replace(str:replace($markdown-cells, $BC, $begin-code-wrap), $EC, $end-code-wrap)" />
        <!-- remove nect line by making previous a value-of, once stable -->
        <xsl:value-of select="$code-cells" />
        <!-- end cell list -->
        <xsl:text>],&#xa;</xsl:text>
        <!-- version identifiers -->
        <xsl:text>"nbformat": 4,&#xa;</xsl:text>
        <xsl:text>"nbformat_minor": 0,&#xa;</xsl:text>
        <!-- metadata copied from blank SMC notebook -->
        <xsl:text>"metadata": {&#xa;</xsl:text>
        <xsl:text>  "kernelspec": {&#xa;</xsl:text>
        <!-- Display name seems totally irrelevant, it gets replaced by actual kernel -->
        <xsl:text>    "display_name": "SageMath",&#xa;</xsl:text>
        <xsl:text>    "language": "",&#xa;</xsl:text>
        <xsl:text>    "name": "sagemath"&#xa;</xsl:text>
        <!-- Eventually make this  jupyter.kernel, perhaps defaulting on "sage" elements -->
        <!-- <xsl:text>   "display_name": "Python 2",&#xa;</xsl:text> -->
        <!-- <xsl:text>   "language": "python",&#xa;</xsl:text> -->
        <!-- <xsl:text>   "name": "python2"&#xa;</xsl:text> -->
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

<!-- Macros, escape backslashes, join lines, -->
<!-- wrap in string, dollars, wrap as a cell -->
<xsl:template name="load-macros">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>$</xsl:text>
            <xsl:value-of select="str:replace(str:replace($latex-macros, '\', '\\'), '&#xa;', '')" />
            <xsl:text>$</xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Make an initial header for an article -->
<xsl:template match="article/frontmatter/titlepage">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <!-- cannot get -> <- to center   -->
            <xsl:call-template name="begin-string" />
                <xsl:text># </xsl:text>
                <xsl:value-of select="/mathbook/article/title" />
            <xsl:call-template name="end-string" />
            <!-- Remainder in order, as simple strings via template below -->
            <!-- Note, if these are not present, no harm                  -->
            <xsl:apply-templates select="author/personname" />
            <xsl:apply-templates select="author/institution" />
            <xsl:apply-templates select="event" />
            <xsl:apply-templates select="date" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Add blank line prior to each to effect a newline visually-->
<xsl:template match="titlepage/author/personname|titlepage/author/institution|titlepage/event|titlepage/date">
    <xsl:call-template name="begin-string" />
        <xsl:text>\n\n</xsl:text>
        <xsl:apply-templates />
    <xsl:call-template name="end-string" />
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
            <xsl:apply-templates select="." mode="type-name" />
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="number" />
            <!-- if title? -->
            <xsl:text>** </xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="statement" />
</xsl:template>

<!-- Drop a title in a cell and process remainder -->
<xsl:template match="&THEOREM-LIKE;|&EXAMPLE-LIKE;|remark|exercise">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>**</xsl:text>
            <xsl:apply-templates select="." mode="type-name" />
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="number" />
            <xsl:if test="title">
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="." mode="title-full" />
            </xsl:if>
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
<!--     <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
 -->
            <xsl:call-template name="begin-inline" />
            <xsl:call-template name="begin-string" />
            <xsl:text>**</xsl:text>
            <xsl:apply-templates select="." mode="type-name" />
            <xsl:text>** </xsl:text>
            <xsl:call-template name="end-string" />
            <xsl:call-template name="end-inline" />
<!--         </xsl:with-param>
    </xsl:call-template>
 -->
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
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="hint|answer|solution">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>**</xsl:text>
            <xsl:apply-templates select="." mode="type-name" />
            <xsl:text>**</xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates />
</xsl:template>

<!-- Lists -->

<!-- Note: maybe this goes into the markdown file, with adjustments? -->

<!-- A top-level list goes into its own markdown cell -->
<xsl:template match="ol[not(ancestor::ol or ancestor::ul or ancestor::dl)]|ul[not(ancestor::ol or ancestor::ul or ancestor::dl)]|dl[not(ancestor::ol or ancestor::ul or ancestor::dl)]">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:apply-templates select="li" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Nested lists get no infrastructure, -->
<!-- we just process their items         -->
<xsl:template match="ol|ul|dl">
    <xsl:apply-templates select="li" />
</xsl:template>

<!-- Items of ordered lists, indented properly -->
<xsl:template match="ol/li">
    <xsl:call-template name="begin-string" />
    <!-- indent 4 spaces per level, starting at zero -->
    <xsl:variable name="level">
        <xsl:apply-templates select="." mode="list-level" />
    </xsl:variable>
    <xsl:call-template name="duplicate-string">
        <xsl:with-param name="text" select="'    '" />
        <xsl:with-param name="count" select="$level - 1" />
    </xsl:call-template>
    <xsl:text>1.  </xsl:text>
    <xsl:call-template name="end-string" />
    <xsl:apply-templates />
</xsl:template>

<!-- Items of unordered lists, indented properly -->
<xsl:template match="ul/li">
    <xsl:call-template name="begin-string" />
    <!-- indent 4 spaces per level -->
    <xsl:variable name="level">
        <xsl:apply-templates select="." mode="list-level" />
    </xsl:variable>
    <xsl:call-template name="duplicate-string">
        <xsl:with-param name="text" select="'    '" />
        <xsl:with-param name="count" select="$level - 1" />
    </xsl:call-template>
    <xsl:text>*   </xsl:text>
    <xsl:call-template name="end-string" />
    <xsl:apply-templates />
</xsl:template>

<!-- We write description lists items like unordered -->
<!-- list items, but include the title in bold       -->
<xsl:template match="dl/li">
    <xsl:call-template name="begin-string" />
    <!-- indent 4 spaces per level -->
    <xsl:variable name="level">
        <xsl:apply-templates select="." mode="list-level" />
    </xsl:variable>
    <xsl:call-template name="duplicate-string">
        <xsl:with-param name="text" select="'    '" />
        <xsl:with-param name="count" select="$level - 1" />
    </xsl:call-template>
    <xsl:text>*   </xsl:text>
    <!-- bold, with trailing space -->
    <xsl:text>**</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>** </xsl:text>
    <xsl:call-template name="end-string" />
    <xsl:apply-templates select="*[not(self::title)]" />
</xsl:template>

<!-- If list items only contain paragraphs and other lists, -->
<!-- then every list will end with a paragraph (or the end  -->
<!-- of a list, which is a paragraph).  The double newline  -->
<!-- will interject a blank line between every list item    -->
<!-- and between every paragraph, even if there are several -->
<!-- in a list item.  We get one extra blank line at the    -->
<!-- end of the cell, but that is no real problem.          -->
<xsl:template match="li/p">
    <xsl:call-template name="begin-string" />
        <xsl:apply-templates />
        <xsl:text>\n\n</xsl:text>
    <xsl:call-template name="end-string" />
</xsl:template>

<!-- ############### -->
<!-- Arbitrary Lists -->
<!-- ############### -->

<!-- See general routine in  xsl/mathbook-common.xsl -->
<!-- which expects the two named templates and the  -->
<!-- two division'al and element'al templates below,  -->
<!-- it contains the logic of constructing such a list -->

<!-- List-of entry/exit hooks -->
<!-- No ops for HTML (maybe blocking) -->
<xsl:template name="list-of-begin" />
<xsl:template name="list-of-end" />

<!-- Sage code -->
<!-- Should evolve to accomodate gebneral template -->
<xsl:template match="sage">
    <!-- formulate lines of code -->
    <xsl:variable name="loc">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="raw-text">
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
    <xsl:call-template name="code-cell">
        <xsl:with-param name="content">
            <xsl:variable name="split" select="str:replace($the-code, $ESBS, '&quot;,&#xa;&quot;')" />
            <xsl:value-of select="str:replace(str:replace($split, $ES, '&quot;'), $BS, '&quot;')" />
        </xsl:with-param>
    </xsl:call-template>
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

<!-- Straight copies, from mathbook-common, just double-slash-->
<!-- LaTeX labels get used on MathJax content in HTML, so we -->
<!-- put this template in the common file for universal use  -->
<!-- Insert an identifier as a LaTeX label on anything       -->
<!-- Calls to this template need come from where LaTeX likes -->
<!-- a \label, generally someplace that can be numbered      -->
<xsl:template match="*" mode="label">
    <xsl:text>\\label{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="men|mrow" mode="tag">
    <xsl:text>\\tag{</xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
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


<!-- ################## -->
<!-- Figures and Tables-->
<!-- ################## -->

<xsl:template match="caption">
    <xsl:call-template name="begin-string" />
    <xsl:apply-templates select="parent::*" mode="type-name"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="parent::*" mode="number"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates />
    <xsl:call-template name="end-string" />
</xsl:template>

<xsl:template match="figure|table">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:apply-templates select="*[not(self::caption)]" />
            <xsl:apply-templates select="caption" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

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
    <xsl:text>\\begin{</xsl:text>
    <xsl:apply-templates select="." mode="displaymath-alignment" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="alignat-columns" />
    <xsl:apply-templates />
    <xsl:text>\\end{</xsl:text>
    <xsl:apply-templates select="." mode="displaymath-alignment" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Now numbered   -->
<xsl:template match="men">
    <xsl:text>\\begin{</xsl:text>
    <xsl:apply-templates select="." mode="displaymath-alignment" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="alignat-columns" />
    <xsl:apply-templates />
    <xsl:apply-templates select="." mode="label" />
    <xsl:apply-templates select="." mode="tag"/>
    <xsl:text>\\end{</xsl:text>
    <xsl:apply-templates select="." mode="displaymath-alignment" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- TODO: Straight out of LaTeX, but sanitized some -->

<!-- Multi-Line Math -->
<!-- Multi-line displayed equations container, globally unnumbered or numbered   -->
<!-- mrow logic controls numbering, based on variant here, and per-row overrides -->
<!-- align environment if ampersands are present, gather environment otherwise   -->
<!-- Output follows source line breaks                                           -->
<xsl:template match="md|mdn">
    <xsl:text>\\begin{</xsl:text>
    <xsl:apply-templates select="." mode="displaymath-alignment" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="alignat-columns" />
    <xsl:text>\n</xsl:text>
    <xsl:apply-templates select="mrow|intertext" />
    <xsl:text>\\end{</xsl:text>
    <xsl:apply-templates select="." mode="displaymath-alignment" />
    <xsl:text>}</xsl:text>
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
    <xsl:if test="following-sibling::mrow">
       <xsl:text>\\\\\n</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="mdn/mrow">
    <xsl:apply-templates />
    <xsl:choose>
        <xsl:when test="@number='no'">
            <xsl:text>\\notag</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="label" />
            <xsl:apply-templates select="." mode="tag"/>
        </xsl:otherwise>
    </xsl:choose>
    <!-- write newline for markdown source formatting -->
    <xsl:if test="following-sibling::mrow">
       <xsl:text>\\\\\n</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Intertext -->
<!-- An <mrow> will provide trailing newline, so do the same here -->
<!-- Added double slash for jupyter                               -->
<xsl:template match="md/intertext|mdn/intertext">
    <xsl:text>\\intertext{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\n</xsl:text>
</xsl:template>

<xsl:template match="latex">
    <xsl:text>$\\mathrm{LaTeX}$</xsl:text>
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

<!-- ################### -->
<!-- Reserved Characters -->
<!-- ################### -->

<!-- Across all possibilities                 -->
<!-- See mathbook-common.xsl for discussion   -->
<!-- We just override/extend Markdown to JSON -->

<!-- Number Sign, Hash, Octothorpe -->
<xsl:template match="hash">
    <xsl:text>\\#</xsl:text>
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
<xsl:template match="text()">
    <!-- long-term: remove variable for clean sources -->
    <xsl:variable name="escaped-string">
        <xsl:value-of select="str:replace(str:replace(., '\', '\\'), '&quot;', '\&quot;')" />
    </xsl:variable>
    <!-- newlines to spaces  -->
    <!-- tabs to empty string-->
    <xsl:variable name="CR-sub" select="' '" />  <!-- use [CR] to make a point -->
    <xsl:value-of select="str:replace(str:replace($escaped-string, '&#xa;', $CR-sub), '&#x9;', '')" />
</xsl:template>

<!-- A Jupyter notebook is a flat sequence of cells, either             -->
<!-- "markdown" or "code."  The content is primarily a list of strings. -->
<!-- This presents two fundamental problems:                            -->
<!--                                                                    -->
<!--   1.  Lists of cells, or lists of strings, with  n  items          -->
<!--       need exactly  n-1  commas.  It is hard to predict/find       -->
<!--       the first or last element of a list.                         -->
<!--                                                                    -->
<!--   2.  Cells cannot be nested and content should not lie            -->
<!--       outside of cells                                             -->
<!--                                                                    -->
<!-- We use a sort of pseudo-markup.  Adjacency of items lets           -->
<!-- us solve the comma problem.  We are also able to effectively       -->
<!-- merge content into a cell, without knowing anything about          -->
<!-- the following cell.                                                -->
<!--                                                                    -->
<!-- Marker language:                                                   -->
<!--                                                                    -->
<!-- LB, RB: left and right brackets - should be UUIDs eventually       -->
<!--                                                                    -->
<!-- BS, ES: begin and end string                                       -->
<!--                                                                    -->
<!-- BI, EI: begin and end inline heading                               -->
<!--                                                                    -->
<!-- BM, EM, BC, EC: begin and end, markdown and code, cells            -->


<!-- ####### -->
<!-- Markers -->
<!-- ####### -->

<!-- make these exceddingly unique -->
<xsl:variable name="LB" select="'[[['" />
<xsl:variable name="RB" select="']]]'" />

<!-- upgrade with brackets -->
<xsl:variable name="BS">
    <xsl:text>[BS]</xsl:text>
</xsl:variable>
<xsl:variable name="ES">
    <xsl:text>[ES]</xsl:text>
</xsl:variable>

<xsl:variable name="BI">
    <xsl:text>[BI]</xsl:text>
</xsl:variable>
<xsl:variable name="EI">
    <xsl:text>[EI]</xsl:text>
</xsl:variable>

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

<!-- Combinations (to recognize) -->


<xsl:variable name="ESBS">
    <xsl:value-of select="$ES" />
    <xsl:value-of select="$BS" />
</xsl:variable>

<xsl:variable name="RBLB">
    <xsl:value-of select="$RB" />
    <xsl:value-of select="$LB" />
</xsl:variable>

<xsl:variable name="EMBM">
    <xsl:value-of select="$EM" />
    <xsl:value-of select="$BM" />
</xsl:variable>

<xsl:variable name="ECBC">
    <xsl:value-of select="$EC" />
    <xsl:value-of select="$BC" />
</xsl:variable>

<xsl:variable name="ECBM">
    <xsl:value-of select="$EC" />
    <xsl:value-of select="$BM" />
</xsl:variable>

<xsl:variable name="EMBC">
    <xsl:value-of select="$EM" />
    <xsl:value-of select="$BC" />
</xsl:variable>

<!-- Fix up end of inline against a beginnning of either type of cell -->
<xsl:variable name="EIBM">
    <xsl:value-of select="$EI" />
    <xsl:value-of select="$BM" />
</xsl:variable>

<xsl:variable name="EIBC">
    <xsl:value-of select="$EI" />
    <xsl:value-of select="$BC" />
</xsl:variable>

<!-- Substitutions -->

<xsl:variable name="RBLB-comma">
    <xsl:value-of select="$RB" />
    <xsl:text>,&#xa;</xsl:text>
    <xsl:value-of select="$LB" />
</xsl:variable>

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


<!-- Convenience templates -->

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


<!-- ################# -->
<!-- Cell Construction -->
<!-- ################# -->

<!-- These should be phased out in lieu of their two respective convenience templates -->

<xsl:template name="markdown-cell">
    <xsl:param name="content" />
    <!--  -->
    <xsl:call-template name="begin-markdown-cell" />
    <xsl:value-of select="$content" />
    <xsl:call-template name="end-markdown-cell" />
</xsl:template>

<xsl:template name="code-cell">
    <xsl:param name="content" />
    <!--  -->
    <xsl:call-template name="begin-code-cell" />
    <xsl:value-of select="$content" />
    <xsl:call-template name="end-code-cell" />
</xsl:template>

</xsl:stylesheet>
