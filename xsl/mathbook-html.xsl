<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2013 Robert A. Beezer

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

<!-- Identify as a stylesheet -->
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
>

<xsl:import href="./mathbook-common.xsl" />

<!-- Intend output for rendering by a web browser -->
<xsl:output method="html" encoding="utf-8"/>

<!-- Parameters -->
<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!-- See others in mathbook-common.xsl file                                   -->
<!--  -->
<!-- Depth to which web pages are "chunked" -->
<!-- Sentinel indicates no choice made      -->
<xsl:param name="html.chunk.level" select="''" />

<!-- Variables  -->
<xsl:variable name="chunk-level">
    <xsl:choose>
        <xsl:when test="$html.chunk.level != ''">
            <xsl:value-of select="$html.chunk.level" />
        </xsl:when>
        <xsl:when test="/mathbook/book">2</xsl:when>
        <xsl:when test="/mathbook/article and /mathbook/article/section">1</xsl:when>
        <xsl:when test="/mathbook/article">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Chunk level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Entry template is in mathbook-common file -->

<!-- Authors, editors in serial lists for headers           -->
<!-- Presumes authors get selected first, so editors follow -->
<!-- TODO: Move to common -->
<xsl:template match="author[1]" mode="name-list" >
    <xsl:apply-templates select="personname" />
</xsl:template>
<xsl:template match="author" mode="name-list" >
    <xsl:text>, </xsl:text>
    <xsl:apply-templates select="personname" />
</xsl:template>
<xsl:template match="editor[1]" mode="name-list" >
    <xsl:if test="/mathbook/docinfo/author" >
        <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="personname" />
    <xsl:text> (</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="generic" select="'editor'" />
    </xsl:call-template>
    <xsl:text>)</xsl:text>
</xsl:template>
<xsl:template match="editor" mode="name-list" >
    <xsl:text>, </xsl:text>
    <xsl:apply-templates select="personname" />
    <xsl:text> (</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="generic" select="'editor'" />
    </xsl:call-template>
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- Authors and editors with affiliations (eg, on title page) -->
<xsl:template match="author|editor" mode="full-info">
    <p>
        <xsl:apply-templates select="personname" />
        <xsl:if test="self::editor">
            <xsl:text>, </xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="generic" select="'editor'" />
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="department|institution|email">
            <xsl:if test="department">
                <br /><xsl:apply-templates select="department" />
            </xsl:if>
            <xsl:if test="institution">
                <br /><xsl:apply-templates select="institution" />
            </xsl:if>
            <xsl:if test="email">
                <br /><xsl:apply-templates select="email" />
            </xsl:if>
        </xsl:if>
    </p>
</xsl:template>


<!-- ################## -->
<!-- Document Structure -->
<!-- ################## -->

<!-- Document Nodes -->
<!-- The document tree is all the structural components of the book                     -->
<!-- Here we decide if they are web pages, or just visual components of a web page      -->
<!-- Each such document node is                                                         -->
<!--   (a) A web page full of content (at chunking level, or below and a document leaf) -->
<!--   (b) A summary web page (level less than chunking-level, not a document leaf)     -->
<!--   (c) A visual component of some enclosing web page                                -->
<!-- They are dispatched here, and recurse back to handle children, typically           -->
<xsl:template match="book|article|frontmatter|chapter|appendix|preface|acknowledgement|authorbiography|foreword|dedication|colophon|section|subsection|subsubsection|exercises|references">
    <xsl:variable name="summary"><xsl:apply-templates select="." mode="is-summary" /></xsl:variable>
    <xsl:variable name="webpage"><xsl:apply-templates select="." mode="is-webpage" /></xsl:variable>
    <xsl:choose>
        <xsl:when test="$summary='false' and $webpage='false'">
            <xsl:apply-templates select="." mode="content" />
        </xsl:when>
        <xsl:when test="$webpage='true'">
            <xsl:apply-templates select="." mode="webpage" />
        </xsl:when>
        <xsl:when test="$summary='true'">
            <xsl:apply-templates select="." mode="summary" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: Document node is considered both summary and webpage at <xsl:apply-templates  select="." mode="long-name"/>.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Document nodes subsidiary to a web page                -->
<!-- Make heading and enclosing div, no page infrastructure -->
<xsl:template match="*" mode="content">
    <xsl:variable name="url"><xsl:apply-templates select="." mode="internal-id" /></xsl:variable>
    <section class="{local-name(.)}" id="{$url}">
        <header>
            <h1 class="heading">
                <xsl:if test="not(self::book or self::article)">
                    <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
                    <xsl:text> </xsl:text>
                    <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
                    <xsl:text> </xsl:text>
                </xsl:if>
                <span class="title"><xsl:apply-templates select="title" /></span>
            </h1>
            <xsl:if test="author">
                <p class="byline"><xsl:apply-templates select="author" mode="name-list"/></p>
            </xsl:if>
        </header>
        <!-- Now recurse through contents, ignoring title and author -->
        <xsl:apply-templates  select="./*[not(self::title or self::author)]"/>
    </section>
</xsl:template>

<!-- Document nodes that are an entire webpage               -->
<!-- A node at the top-level of a page, build infrastructure -->
<xsl:template match="*" mode="webpage">
    <xsl:apply-templates select="." mode="page-wrap">
        <xsl:with-param name="title">
            <xsl:apply-templates select="/mathbook/book/title|/mathbook/article/title" />
        </xsl:with-param>
        <xsl:with-param name="subtitle"></xsl:with-param> -->
        <!-- Serial list of authors, then editors, as names only -->
         <xsl:with-param name="credits">
            <xsl:apply-templates select="/mathbook/docinfo/author" mode="name-list"/>
            <xsl:apply-templates select="/mathbook/docinfo/editor" mode="name-list"/>
        </xsl:with-param>
        <xsl:with-param name="content">
            <!-- Heading, div for subdivision that is this page -->
            <!-- frontmatter/titlepage is exceptional           -->
             <section class="{local-name(.)}">
                <xsl:if test="not(self::frontmatter)">
                    <header>
                        <h1 class="heading">
                            <!-- Book 1 or Article 1 is silly -->
                            <xsl:if test="not(self::book or self::article )">
                                <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
                                <xsl:text> </xsl:text>
                                <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
                                <xsl:text> </xsl:text>
                            </xsl:if>
                            <span class="title"><xsl:apply-templates select="title" /></span>
                        </h1>
                        <!-- Subdivisions may have individual authors -->
                        <xsl:if test="author">
                            <p class="byline"><xsl:apply-templates select="author" mode="name-list"/></p>
                        </xsl:if>
                    </header>
                </xsl:if>
                <!-- Recurse through contents inside enclosing section, ignore title, author -->
                <xsl:apply-templates select="*[not(self::title or self::author)]" />
            </section>
         </xsl:with-param>
     </xsl:apply-templates>
</xsl:template>

<!-- Document node that is a summary of children                  -->
<!-- Build a page and create summaries of children                -->
<!-- Some summaries are actual content (introductions, typically) -->
<xsl:template match="*" mode="summary">
    <xsl:apply-templates select="." mode="page-wrap">
        <xsl:with-param name="title">
            <xsl:apply-templates select="/mathbook/book/title|/mathbook/article/title" />
        </xsl:with-param>
        <xsl:with-param name="subtitle"></xsl:with-param> -->
        <!-- Serial list of authors, then editors, as names only -->
         <xsl:with-param name="credits">
            <xsl:apply-templates select="/mathbook/docinfo/author" mode="name-list"/>
            <xsl:apply-templates select="/mathbook/docinfo/editor" mode="name-list"/>
        </xsl:with-param>
        <xsl:with-param name="content">
            <!-- Heading, div for subdivision that is this page -->
             <section class="{local-name(.)}">
                <header>
                    <h1 class="heading">
                        <xsl:if test="not(self::book or self::article or self::frontmatter)">
                            <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
                            <xsl:text> </xsl:text>
                            <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
                            <xsl:text> </xsl:text>
                        </xsl:if>
                        <xsl:if test="not(self::frontmatter)">
                            <span class="title"><xsl:apply-templates select="title" /></span>
                        </xsl:if>
                    </h1>
                    <xsl:if test="author">
                        <p class="byline"><xsl:apply-templates select="author" mode="name-list"/></p>
                    </xsl:if>
                </header>
                <!-- Create summaries of each child node (which will be a document node) -->
                <!-- NB: be more careful about just wrapping links -->
                <xsl:apply-templates select="titlepage|introduction" mode="summary-entry"/>
                <nav class="chapter-toc">
                    <xsl:apply-templates select="*[not(self::title or self::author or self::titlepage or self::introduction or self::conclusion)]" mode="summary-entry" />
                </nav>
                <xsl:apply-templates select="conclusion" mode="summary-entry"/>
            </section>
         </xsl:with-param>
     </xsl:apply-templates>
     <!-- Summary-entries do not recurse, need to restart outside web page wrapper -->
    <xsl:apply-templates select="book|article|frontmatter|chapter|appendix|preface|acknowledgement|authorbiography|foreword|dedication|colophon|section|subsection|subsubsection|exercises|references" />
</xsl:template>

<!-- Document summaries -->
<!-- On a summary page, some items get summarized (eg subdivisions become links)          -->
<!-- some do not.  For eample and introduction just gets reproduced verbatim              -->
<!-- NB: listed here roughly in "order of appearance", note <nav> section of summary page -->

<!-- A titlepage is a front-matter introduction      -->
<!-- We always handle these the same, summary or not -->
<!-- So this just calls the default template         -->
<xsl:template match="titlepage|introduction|conclusion" mode="summary-entry">
    <xsl:apply-templates select="."/>
</xsl:template>

<!-- Document node summaries are just links to the page -->
<xsl:template match="book|article|chapter|appendix|section|subsection|subsubsection" mode="summary-entry">
    <xsl:variable name="url"><xsl:apply-templates select="." mode="url" /></xsl:variable>
    <a href="{$url}">
        <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
        <xsl:text> </xsl:text>
        <span class="title"><xsl:apply-templates select="title" /></span>
    </a>
</xsl:template>

<!-- Some document nodes will not normally have titles and we need default titles -->
<!-- Especially if one-off (eg Preface), or generic (Exercises)                   -->
<xsl:template match="exercises|references|frontmatter|preface|acknowledgement|authorbiography|foreword|dedication|colophon" mode="summary-entry">
    <xsl:variable name="url"><xsl:apply-templates select="." mode="url" /></xsl:variable>
    <a href="{$url}">
        <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
        <xsl:text> </xsl:text>
        <span class="title">
            <xsl:choose>
                <xsl:when test="title">
                    <xsl:apply-templates select="title" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="type-name" />
                </xsl:otherwise>
            </xsl:choose>
        </span>
    </a>
 </xsl:template>

<!-- TODO's can be anywhere and we do not want to see them -->
<xsl:template match="todo" mode="summary-entry" />

<!-- Title Page -->
<!-- A frontmatter has no title, so we reproduce the            -->
<!-- title of the work (book or article) here                   -->
<!-- We add other material prior to links to major subdivisions -->
<xsl:template match="titlepage">
    <h1 class="heading">
        <span class="title"><xsl:apply-templates select="/mathbook/book/title|/mathbook/article/title" /></span>
    </h1>
    <address class="contributors">
        <xsl:apply-templates select="/mathbook/docinfo/author|/mathbook/docinfo/editor" mode="full-info"/>
    </address>
</xsl:template>

<!-- Introductions and Conclusions -->
<!-- Simple containers, allowed before and after       -->
<!-- explicit subdivisions, to introduce or summarize  -->
<!-- No title allowed, typically just a few paragraphs -->
<xsl:template match="introduction|conclusion">
    <section class="{local-name(.)}">
        <xsl:apply-templates />
    </section>
</xsl:template>

<!-- Theorem-Like, plus associated Proofs                                   -->
<!-- <statement>s and <proof>s are sequences of paragraphs and other blocks -->
<xsl:template match="theorem|corollary|lemma|proposition|claim|fact">
    <xsl:variable name="xref">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <article class="theorem-like" id="{$xref}">
        <h5>
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
        <xsl:text> </xsl:text>
        <span class="counter"><xsl:apply-templates select="." mode="number" /></span>
        <xsl:if test="title">
            <xsl:text> (</xsl:text>
            <span class="title"><xsl:apply-templates select="title" /></span>
            <xsl:text>)</xsl:text>
        </xsl:if>
        </h5>
        <xsl:apply-templates select="statement" />
    </article>
    <xsl:apply-templates select="proof" />
</xsl:template>

<!-- TODO: Does a proof have a title ever? -->
<xsl:template match="proof">
    <article class="proof">
        <h5><xsl:apply-templates select="." mode="type-name" /></h5>
        <xsl:apply-templates />
    </article>
</xsl:template>

<!-- Definitions, Axioms -->
<!-- Statement, just like a theorem, but no proof -->
<xsl:template match="definition|axiom|conjecture|principle">
    <xsl:variable name="xref">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <article class="theorem-like" id="{$xref}">
        <h5>
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
        <xsl:text> </xsl:text>
        <span class="counter"><xsl:apply-templates select="." mode="number" /></span>
        <xsl:if test="title">
            <xsl:text> </xsl:text>
            <span class="title"><xsl:apply-templates select="title" /></span>
        </xsl:if>
        </h5>
        <xsl:apply-templates select="statement" />
    </article>
</xsl:template>

<!-- Examples, Remarks -->
<!-- Just a sequence of paragraphs, etc -->
<xsl:template match="example|remark">
    <xsl:variable name="xref">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <article class="example-like" id="{$xref}">
        <xsl:element name="h5">
            <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
            <xsl:text> </xsl:text>
            <span class="counter"><xsl:apply-templates select="." mode="number" /></span>
            <xsl:if test="title">
                <xsl:text> </xsl:text>
                <span class="title"><xsl:apply-templates select="title" /></span>
            </xsl:if>
        </xsl:element>
        <xsl:apply-templates select="*[not(self::title)]"/>
    </article>
</xsl:template>

<!-- Exercise Group -->
<!-- We interrupt a list of exercises with short commentary, -->
<!-- typically instructions for a list of similar exercises  -->
<!-- Commentary goes in an introduction and/or conclusion    -->
<xsl:template match="exercisegroup">
    <div class="exercisegroup">
        <xsl:apply-templates />
    </div>
</xsl:template>

<!-- Solutions are included by default switch, could be knowls -->
<xsl:template match="exercise">
    <xsl:variable name="xref">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <article class="exercise-like" id="{$xref}">
        <h5>
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
        <xsl:text> </xsl:text>
        <span class="counter"><xsl:apply-templates select="." mode="origin-id" /></span>
        <xsl:if test="title">
            <xsl:text> </xsl:text>
            <span class="title"><xsl:apply-templates select="title" /></span>
        </xsl:if>
        </h5>
        <xsl:apply-templates select="statement" />
        <xsl:apply-templates select="hint" />
        <xsl:apply-templates select="solution" />
    </article>
</xsl:template>

<xsl:template match="exercise/hint|exercise/solution">
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text>. </xsl:text>
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="notation">
<p>Sample notation (in a master list eventually): \(<xsl:value-of select="." />\)</p>
</xsl:template>

<!-- Wrap generic paragraphs in p tag -->
<xsl:template match="p">
<p><xsl:apply-templates /></p>
</xsl:template>

<!-- Pass-through stock HTML for lists-->
<xsl:template match="ol|ul|li">
    <xsl:copy>
        <xsl:apply-templates />
    </xsl:copy>
</xsl:template>

<!-- With cols specified, we form the list items with variable -->
<!-- widths then clear the floating property to resume -->
<xsl:template match="ol[@cols]|ul[@cols]">
    <xsl:copy>
        <xsl:apply-templates select="li" mode="variable-width">
            <xsl:with-param name="percent-width" select="98 div @cols" />
        </xsl:apply-templates>
    </xsl:copy>
    <div style="clear:both;"></div>
</xsl:template>

<xsl:template match="li" mode="variable-width">
    <xsl:param name="percent-width" />
    <xsl:copy>
        <xsl:attribute name="style">
            <xsl:text>width:</xsl:text><xsl:value-of select="$percent-width" /><xsl:text>%; float:left;</xsl:text>
        </xsl:attribute>
       <xsl:apply-templates />
    </xsl:copy>
</xsl:template>

<!-- Figures and their captions -->
<!-- TODO: class="wrap" is possible -->
<xsl:template match="figure">
    <figure>
        <xsl:apply-templates select="*[not(self::caption)]"/>
        <xsl:apply-templates select="caption"/>
    </figure>
</xsl:template>

<!-- Images -->
<xsl:template match="image" >
<xsl:element name="img">
    <xsl:if test="@width">
        <xsl:attribute name="width"><xsl:value-of select="@width" /></xsl:attribute>
    </xsl:if>
    <xsl:if test="@height">
        <xsl:attribute name="height"><xsl:value-of select="@height" /></xsl:attribute>
    </xsl:if>
    <xsl:attribute name="src"><xsl:value-of select="@source" /></xsl:attribute>
</xsl:element>
</xsl:template>

<!-- tikz graphics language       -->
<!-- SVG's produced by mbx script -->
<xsl:template match="tikz">
    <xsl:element name="object">
        <xsl:attribute name="type">image/svg+xml</xsl:attribute>
        <xsl:attribute name="style">width:90%; margin:auto;</xsl:attribute>
        <xsl:attribute name="data">
            <xsl:value-of select="$directory.images" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>.svg</xsl:text>
        </xsl:attribute>
        <p style="margin:auto">&lt;&lt;Your browser is unable to render this SVG image&gt;&gt;</p>
    </xsl:element>
</xsl:template>


<!-- Asymptote graphics language  -->
<!-- SVG's produced by mbx script -->
<xsl:template match="asymptote">
    <xsl:element name="object">
        <xsl:attribute name="type">image/svg+xml</xsl:attribute>
        <xsl:attribute name="style">width:90%; margin:auto;</xsl:attribute>
        <xsl:attribute name="data">
            <xsl:value-of select="$directory.images" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>.svg</xsl:text>
        </xsl:attribute>
        <p style="margin:auto">&lt;&lt;Your browser is unable to render this SVG image&gt;&gt;</p>
    </xsl:element>
</xsl:template>

<!-- Sage graphics plots          -->
<!-- SVG's produced by mbx script -->
<!-- PNGs are fall back for 3D    -->
<xsl:template match="sageplot">
    <xsl:element name="object">
        <xsl:attribute name="type">image/svg+xml</xsl:attribute>
        <xsl:attribute name="style">width:90%; margin:auto;</xsl:attribute>
        <xsl:attribute name="data">
            <xsl:value-of select="$directory.images" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>.svg</xsl:text>
        </xsl:attribute>
        <xsl:element name="img">
            <xsl:attribute name="src">
                <xsl:value-of select="$directory.images" />
                <xsl:text>/</xsl:text>
                <xsl:apply-templates select="." mode="internal-id" />
                <xsl:text>.png</xsl:text>
            </xsl:attribute>
        </xsl:element>
    </xsl:element>
</xsl:template>

<!-- Video -->
<!-- Embed FlowPlayer to play mp4 format                                    -->
<!-- 2014/03/07:  http://flowplayer.org/docs/setup.html                     -->
<!-- TODO: use for-each and extension matching to preferentially use WebM format -->
<!-- <source type="video/mp4" src="http://mydomain.com/path/to/intro.webm">     -->
<xsl:template match="video">
    <div class="flowplayer" style="width:200px">
        <xsl:text disable-output-escaping='yes'>&lt;video controls>&#xa;</xsl:text>
        <source type="video/webm" src="{@source}" />
        <xsl:text disable-output-escaping='yes'>&lt;/video>&#xa;</xsl:text>
    </div>
</xsl:template>

<!-- Tables -->
<!-- Follow "XML Exchange Table Model"           -->
<!-- A subset of the (failed) "CALS Table Model" -->
<!-- Should be able to replace this by extant XSLT for this conversion -->
<xsl:template match="table">
    <figure>
        <table class="center">
            <xsl:apply-templates select="*[not(self::caption)]" />
        </table>
        <xsl:apply-templates select="caption" />
    </figure>
</xsl:template>

<xsl:template match="tgroup"><xsl:apply-templates /></xsl:template>
<xsl:template match="thead">
    <thead><xsl:apply-templates /></thead>
</xsl:template>
<xsl:template match="tbody">
    <tbody><xsl:apply-templates /></tbody>
</xsl:template>
<xsl:template match="thead/row">
    <tr><xsl:apply-templates /></tr>
    <tr><xsl:apply-templates mode="hline" /></tr>
</xsl:template>
<xsl:template match="tbody/row">
    <tr><xsl:apply-templates /></tr>
</xsl:template>
<!-- With a parent axis, get overrides easily? -->
<xsl:template match="thead/row/entry"><td align="{../../../@align}"><xsl:apply-templates /></td></xsl:template>
<xsl:template match="thead/row/entry" mode="hline"><td class="hline"><hr /></td></xsl:template>
<xsl:template match="tbody/row/entry"><td align="{../../../@align}"><xsl:apply-templates /></td></xsl:template>

<!-- Caption of a figure or table                  -->
<!-- All the relevant information is in the parent -->
<xsl:template match="caption">
    <figcaption>
        <span class="heading">
            <xsl:apply-templates select=".." mode="type-name"/>
        </span>
        <span class="counter">
            <xsl:apply-templates select=".." mode="number"/>
        </span>
        <xsl:apply-templates />
    </figcaption>
</xsl:template>

<!-- Visual Identifiers for Cross-References -->
<!-- Format of visual identifiers, peculiar to HTML       -->
<!-- This is complete HTML  code to make visual reference -->
<!-- LaTeX does much of this semi-automatically           -->
<!-- Many components are built from common routines       -->

<!-- Most cross-references have targets that know -->
<!-- their names, so we default to trying that,   -->
<!-- subject to various customizations            -->
<xsl:template match="*" mode="ref-id">
    <!-- Parameter is the local @autoname of the calling xref -->
    <xsl:param name="autoname" />
    <xsl:variable name="prefix">
        <xsl:apply-templates select="." mode="ref-prefix">
            <xsl:with-param name="local" select="$autoname" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="content">
        <!-- Autonaming prefix: add non-breaking space -->
        <xsl:value-of select="$prefix" />
        <xsl:if test="$prefix!=''">
            <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:apply-templates select="." mode="xref-hyperlink">
        <xsl:with-param name="content" select="$content" />
    </xsl:apply-templates>
</xsl:template>

<!-- Citations get marked off in a pair of brackets              -->
<!-- A cross-reference to a biblio may have "detail",            -->
<!-- extra information about the location in the referenced work -->
<xsl:template match="biblio" mode="ref-id">
    <xsl:param name="detail" />
    <xsl:variable name="content">
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="." mode="number" />
        <xsl:if test="$detail != ''">
            <xsl:text>, </xsl:text>
            <xsl:apply-templates select="$detail" />
       </xsl:if>
        <xsl:text>]</xsl:text>
    </xsl:variable>
    <xsl:apply-templates select="." mode="xref-hyperlink">
        <xsl:with-param name="content" select="$content" />
    </xsl:apply-templates>
</xsl:template>

<!-- Displayed equations have targets manufactured by MathJax,                   -->
<!-- Elsewhere we number these just as MathJax/AMSMath would                     -->
<!-- For HTML we need to provide the parentheses, which LaTeX does automatically -->
<!-- TODO: will we allow me's to be numbered, or not? -->
<xsl:template match="me|men|mrow" mode="ref-id">
    <xsl:variable name="content">
        <xsl:text>(</xsl:text>
        <xsl:apply-templates select="." mode="number" />
        <xsl:text>)</xsl:text>
    </xsl:variable>
    <xsl:apply-templates select="." mode="xref-hyperlink">
        <xsl:with-param name="content" select="$content" />
    </xsl:apply-templates>
</xsl:template>


<!-- A cross-reference has a visual component,      -->
<!-- formed above, and a realization as a hyperlink -->
<!-- We build the latter here                       -->
<!-- TODO: maybe create knowls via the "url" mode template? -->
<xsl:template match="*" mode="xref-hyperlink">
    <xsl:param name="content" />
    <xsl:element name ="a">
        <!-- http://stackoverflow.com/questions/585261/is-there-an-xslt-name-of-element -->
        <!-- Sans namespace (would be name(.)) -->
        <xsl:attribute name="class">
            <xsl:value-of select="local-name(.)" />
        </xsl:attribute>
        <xsl:attribute name="href">
            <xsl:apply-templates select="." mode="url" />
        </xsl:attribute>
    <xsl:value-of  disable-output-escaping="yes" select="$content" />
    </xsl:element>
</xsl:template>

<!-- Footnotes                                             -->
<!-- Mimicking basic LaTeX, but as knowls                  -->
<!-- Put content into knowl, then make a knowl link for it -->
<!-- The knowl link gets placed into a superscript         -->
<xsl:template match="fn">
    <xsl:variable name="ident">
        <xsl:text>footnote-</xsl:text>
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <!-- -->
    <xsl:call-template name="knowl-factory">
        <xsl:with-param name="identifier" select="$ident" />
        <xsl:with-param name="content">
            <xsl:apply-templates />
        </xsl:with-param>
    </xsl:call-template>
    <!-- -->
    <sup>
    <xsl:call-template name="knowl-link-factory">
        <xsl:with-param name="css-class">footnote</xsl:with-param>
        <xsl:with-param name="identifier" select="$ident" />
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="number" />
        </xsl:with-param>
    </xsl:call-template>
    </sup>
</xsl:template>


<!-- Miscellaneous -->

<!-- Markup, typically within paragraphs            -->
<!-- Quotes, double or single, see quotations below -->
<!-- HTML5 wants actual characters here -->
<xsl:template match="q">
    <xsl:text>&#x201c;</xsl:text><xsl:apply-templates /><xsl:text>&#x201d;</xsl:text>
</xsl:template>

<xsl:template match="sq">
    <xsl:text>&#x2018;</xsl:text><xsl:apply-templates /><xsl:text>&#x2019;</xsl:text>
</xsl:template>

<!-- Actual Quotations                -->
<!-- TODO: <quote> element for inline to be <q> in HTML-->
<xsl:template match="blockquote">
    <blockquote><xsl:apply-templates /></blockquote>
</xsl:template>

<!-- Use at the end of a blockquote -->
<xsl:template match="blockquote/attribution">
    <br /><span class="attribution"><xsl:apply-templates /></span>
</xsl:template>

<!-- Defined terms (bold) -->
<xsl:template match="term">
    <em class="terminology"><xsl:apply-templates /></em>
</xsl:template>

<!-- Emphasis -->
<xsl:template match="em">
    <em><xsl:apply-templates /></em>
</xsl:template>

<!-- Copyright symbol -->
<xsl:template match="copyright">
    <xsl:text>&#169;</xsl:text>
</xsl:template>

<!-- for example -->
<xsl:template match="eg">
    <xsl:text>e.g.</xsl:text>
</xsl:template>

<!-- in other words -->
<xsl:template match="ie">
    <xsl:text>i.e.</xsl:text>
</xsl:template>

<!-- Implication Symbols -->
<!-- TODO: better names! -->
<xsl:template match="imply">
    <xsl:text>&#x21D2;</xsl:text>
</xsl:template>
<xsl:template match="implyreverse">
    <xsl:text>&#x21D0;</xsl:text>
</xsl:template>

<!-- TeX, LaTeX -->
<xsl:template match="latex">
    <xsl:text>\(\LaTeX\)</xsl:text>
</xsl:template>
<xsl:template match="tex">
    <xsl:text>\(\TeX\)</xsl:text>
</xsl:template>

<!-- Line Breaks -->
<!-- use sparingly, e.g. for poetry, not in math environments-->
<xsl:template match="br">
    <br />
</xsl:template>

<!-- Code, inline -->
<xsl:template match="c">
    <tt class="code"><xsl:apply-templates /></tt>
</xsl:template>

<!-- External URLs, Email        -->
<!-- Open in new windows         -->
<!-- URL itself, if content-less -->
<!-- http://stackoverflow.com/questions/9782021/check-for-empty-xml-element-using-xslt -->
<xsl:template match="url">
    <a class="external-url" href="{@href}" target="_blank">
    <xsl:choose>
        <xsl:when test="not(*) and not(normalize-space())">
            <xsl:value-of select="@href" />
        </xsl:when>
        <xsl:otherwise>         
            <xsl:apply-templates />
        </xsl:otherwise>
    </xsl:choose>
    </a>
</xsl:template>

<xsl:template match="email">
    <xsl:element name="a">
        <xsl:attribute name="href">
            mailto:<xsl:value-of select="." />
        </xsl:attribute>
        <xsl:value-of select="." />
    </xsl:element>
</xsl:template>

<!-- Special Characters from TeX -->
<!--    # $ % ^ & _ { } ~ \      -->
<!-- These need special treatment, elements     -->
<!-- here are for text mode, and are not for    -->
<!-- use inside mathematics elements, e.g. <m>. -->

<!-- Number Sign, Hash, Octothorpe -->
<!-- Also &#x23;                   -->
<xsl:template match="hash">
    <xsl:text>#</xsl:text>
</xsl:template>

<!-- Dollar sign -->
<xsl:template match="dollar">
    <xsl:text>$</xsl:text>
</xsl:template>

<!-- Percent sign -->
<xsl:template match="percent">
    <xsl:text>%</xsl:text>
</xsl:template>

<!-- Circumflex (caret) -->
<!-- Also &#x5e;        -->
<xsl:template match="circumflex">
    <xsl:text>^</xsl:text>
</xsl:template>

<!-- Ampersand -->
<!-- Not for controlling mathematics -->
<!-- or table formatting             -->
<xsl:template match="ampersand">
    <xsl:text>&amp;</xsl:text>
</xsl:template>

<!-- Text underscore -->
<xsl:template match="underscore">
    <xsl:text>_</xsl:text>
</xsl:template>

<!-- Braces -->
<!-- Individually, or matched -->
<xsl:template match="lbrace">
    <xsl:text>{</xsl:text>
</xsl:template>
<xsl:template match="rbrace">
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="braces">
    <xsl:text>{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Tilde -->
<xsl:template match="tilde">
    <xsl:text>~</xsl:text>
</xsl:template>

<!-- Backslash -->
<!-- See url element for comprehensive approach -->
<xsl:template match="backslash">
    <xsl:text>\</xsl:text>
</xsl:template>

<!-- Other Miscellaneous Symbols, Constructions -->

<!-- Ellipsis (dots), for text, not math -->
<xsl:template match="ellipsis">
    <xsl:text>&#x2026;</xsl:text>
</xsl:template>

<!-- Foreign words/idioms        -->
<!-- Matches HTML5 specification -->
<xsl:template match="foreign">
    <i class="foreign"><xsl:apply-templates /></i>
</xsl:template>

<!-- Non-breaking space, which "joins" two words as a unit -->
<!-- http://stackoverflow.com/questions/31870/using-a-html-entity-in-xslt-e-g-nbsp -->
<xsl:template match="nbsp">
    <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
</xsl:template>

<!-- Dashes, Hyphen -->
<!-- http://www.cs.tut.fi/~jkorpela/dashes.html -->
<!-- HTML Tidy does not like these characters, but they seem to be OK -->
<!-- Could do this in CSS, perhaps? -->
<xsl:template match="mdash">
    <xsl:text>&#8212;</xsl:text>
</xsl:template>
<xsl:template match="ndash">
    <xsl:text>&#8211;</xsl:text>
</xsl:template>
<!-- Unambiguous hyphen -->
<xsl:template match="hyphen">
    <xsl:text>&#8208;</xsl:text>
</xsl:template>

<!-- Titles of Books and Articles -->
<xsl:template match="booktitle">
    <span class="booktitle"><xsl:apply-templates /></span>
</xsl:template>
<xsl:template match="articletitle">
    <span class="articletitle"><xsl:apply-templates /></span>
</xsl:template>


<!-- Raw Bibliographic Entry Formatting              -->
<!-- Markup really, not full-blown data preservation -->

<!-- Entry could be a list item                      -->
<!-- if we wrote enclosing HTML and overrode display -->
<!-- Also manufacture a knowl,as a matter of course  -->
<xsl:template match="biblio[@type='raw']">
    <xsl:element name="div">
        <xsl:attribute name="class">biblio</xsl:attribute>
        <xsl:attribute name="id"><xsl:apply-templates select="." mode="internal-id" /></xsl:attribute>
        <xsl:comment>Style me, please. (Maybe as a list item with hard-coded numbers/labels, not automatic, or just a span)</xsl:comment>
        <p>
            <xsl:text>[</xsl:text>
                <xsl:apply-templates select="." mode="origin-id" />
            <xsl:text>]</xsl:text>
            <xsl:text disable-output-escaping="yes">&amp;nbsp;&amp;nbsp;</xsl:text>
            <xsl:apply-templates select="text()|*[not(self::note)]" />
        </p>
        <xsl:apply-templates select="note" />
    </xsl:element>
    <xsl:call-template name="knowl-factory">
        <xsl:with-param name="identifier">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:with-param>
        <xsl:with-param name="content">
            <span class="article">
            <xsl:apply-templates />
            </span>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Bibliographic items can have annotations            -->
<!-- Presumably just paragraphs, nothing too complicated -->
<xsl:template match="biblio/note">
    <xsl:apply-templates />
</xsl:template>

<!-- Title in italics -->
<xsl:template match="biblio[@type='raw']/title">
    <i><xsl:apply-templates /></i>
</xsl:template>

<!-- No treatment for journal -->
<xsl:template match="biblio[@type='raw']/journal">
    <xsl:apply-templates />
</xsl:template>

<!-- Volume in bold -->
<xsl:template match="biblio[@type='raw']/volume">
    <b><xsl:apply-templates /></b>
</xsl:template>

<!-- Number -->
<xsl:template match="biblio[@type='raw']/number">
    <xsl:text>no. </xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Index -->
<!-- Only implemented for LaTeX, where it -->
<!-- makes sense, otherwise just kill it  -->
<xsl:template match="index" />

<!-- #### -->
<!-- Math -->
<!-- #### -->

<!-- We do "tag" numbered equations in MathJax output, -->
<!-- because we want to control and duplicate the way  -->
<!-- numbers are generated and assigned by LaTeX       -->
<xsl:template match="men|mrow" mode="tag">
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Intertext -->
<!-- A LaTeX construct really, we just jump in/out of the align environment   -->
<!-- And package the text in an HTML paragraph, assuming it is just a snippet -->
<!-- This breaks the alignment, but MathJax has no good solution for this     -->
<xsl:template match="md/intertext|mdn/intertext">
    <xsl:text>\end{align}&#xa;</xsl:text>
    <p>
    <xsl:apply-templates />
    </p>
    <xsl:text>\begin{align}&#xa;</xsl:text>
</xsl:template>

<!-- Manufacturing Knowls              -->
<!-- "knowl" subdirectory is hardcoded -->
<!-- Name knowls as *.html so a known filetype for servers -->
<!-- First, make actual content in predictable location    -->
<xsl:template name="knowl-factory">
    <xsl:param name="identifier"/>
    <xsl:param name="content"/>
    <exsl:document href="./knowl/{$identifier}.html" method="html">
        <xsl:call-template name="converter-blurb" />
        <xsl:copy-of select="$content" />
    </exsl:document>
</xsl:template>
<!-- Second, make a clickable knowl link -->
<xsl:template name="knowl-link-factory">
    <xsl:param name="css-class"/>
    <xsl:param name="identifier"/>
    <xsl:param name="content"/>
    <xsl:element name ="a">
        <xsl:attribute name="class">
            <xsl:value-of select="$css-class" />
        </xsl:attribute>
        <xsl:attribute name="knowl">
            <xsl:text>./knowl/</xsl:text>
            <xsl:value-of select="$identifier" />
            <xsl:text>.html</xsl:text>
        </xsl:attribute>
        <xsl:value-of select="$content" />
    </xsl:element>
</xsl:template>

<!-- Sage Cells -->
<!-- Various customizations, with more typical at end -->
<!-- TODO: make hidden autoeval cells link against sage-compute cells -->

<!-- Type: "invisible"; to doctest, but never show to a reader -->
<xsl:template match="sage[@type='invisible']" />

<!-- Type: "display"; input portion as uneditable, unevaluatable -->
<xsl:template match="sage[@type='display']">
    <div class="sage-display">
    <script type="text/x-sage">
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="input" />
    </xsl:call-template>
    </script>
    </div>
</xsl:template>

<!-- Type: "practice"; empty, but with practice string from config -->
<xsl:template match="sage[@type='practice']">
    <div class="sage-compute">
    <script type="text/x-sage">
    <xsl:text># Sage practice area&#xa;</xsl:text>
    </script>
    </div>
</xsl:template>

<!-- Copy previous cell and "replay" it-->
<xsl:template match="sage[@copy]">
    <div class="sage-compute">
    <script type="text/x-sage">
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="id(@copy)/input" />
    </xsl:call-template>
    </script>
    </div>
</xsl:template>

<!-- Totally empty element: an empty cell to scribble in -->
<xsl:template match="sage[not(input) and not(output) and not(@type) and not(@copy)]">
    <div class="sage-compute"><script type="text/x-sage">
    <xsl:text>&#xa;</xsl:text>
    </script></div>
</xsl:template>

<!-- Type: "full" or no attributes; input portion to an evaluatable cell -->
<xsl:template match="sage[(not(@copy) and not(@type)) or (@type='full')]">
    <div class="sage-compute">
    <script type="text/x-sage">
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="input" />
    </xsl:call-template>
    </script>
    </div>
</xsl:template>

<!-- Program Listings -->
<!-- Research:  http://softwaremaniacs.org/blog/2011/05/22/highlighters-comparison/           -->
<!-- From Google: downloadable, auto-detects languages, has hint-handlers                     -->
<!-- http://code.google.com/p/google-code-prettify/                                           -->
<!-- http://code.google.com/p/google-code-prettify/wiki/GettingStarted                        -->
<!-- See common file for more on language handlers, and "language-prettify" template          -->
<xsl:template match="program">
    <xsl:variable name="classes">
        <xsl:text>prettyprint</xsl:text>
        <xsl:if test="@language">
            <xsl:text> lang-</xsl:text>
            <xsl:value-of select="@language" />
        </xsl:if>
    </xsl:variable>
    <pre class="{$classes}" style="font-size:80%">
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="input" />
    </xsl:call-template>
    </pre>
</xsl:template>

<!-- Geogebra                               -->
<!-- Empty cell for scribbling if empty tag -->
<!-- From Bruce Cohen's Sage iFrame demo    -->
<xsl:template match="geogebra-applet[not(ggbBase64)]">
<table border="0" width="750">
<tr><td>
<applet name="ggbApplet" code="geogebra.GeoGebraApplet" archive="geogebra.jar"
        codebase="http://www.geogebra.org/webstart/3.2/"
        width="750" height="550" mayscript="true">
        <param name="ggbBase64" value="UEsDBBQACAAIAMeAzj4AAAAAAAAAAAAAAAAMAAAAZ2VvZ2VicmEueG1srVQ9b9swEJ2bX0Fwb6yPuEgAyUGbLgGCdnCboRslnaWrKVIgKcfKr++RlGzHcyfq3j3evfugisdjL9kBjEWtSp7eJpyBqnWDqi356Haf7/nj5qZoQbdQGcF22vTClTy/zbjHR9zcfCpsp9+YkIHyivBW8p2QFjizgwHR2A7AfcDFeESJwkw/q79QO3t2xCDPahgpizMjYXXfvKBdzFVIOEh03/GADRgmdV3yL2uSTl+vYBzWQpb8LolIVvLsyklQ7r2dNviulfP0c3ApKpDUgK2bJDB28N48unZEZsziO1CzMo8Vq9CDAsZaYoNC+TqDRCIx9oaN60r+ELIBth2Vsb5LY7Raa9NsJ+ugZ8c/YDSJTnM/gyla2X2YiCXJlHCdBNelFcLAYQvOkWDLxBHOvWwNNh+MZ/tNyzM0aFTuSQxuNGHc+QyFuktOuYwX/FW1EmYspWl0UO8rfdzGJuQx9K9pCFeCoKp90lIbZnzn10SYzyqegeOVnlhJ4CSBMcfwQU/+9CELjHBW8YyjQhWlzZWnS9VpsqRByzzg20hbeio+DLnknI0K3cti0Hbsz6X6Cz/GvqLncbkfp5jp/4pZrK7Wp9iDUSDjkiia7ahHGzcx5gpCGqixJzM65pYIP67fJCCiDbQGFuHxccWGBW9yuYhXcLFaRHgNlrTWjv4SVI/ztUA/uIktPwb/pB09p5JXWHPWCEcU/4dYXd4Nz2W+sfkHUEsHCLTMTSIiAgAAfAQAAFBLAQIUABQACAAIAMeAzj60zE0iIgIAAHwEAAAMAAAAAAAAAAAAAAAAAAAAAABnZW9nZWJyYS54bWxQSwUGAAAAAAEAAQA6AAAAXAIAAAAA"/>
        <param name="image" value="http://www.geogebra.org/webstart/loading.gif"  />
        <param name="boxborder" value="false"  />
        <param name="centerimage" value="true"  />
        <param name="java_arguments" value="-Xmx512m -Djnlp.packEnabled=true" />
        <param name="cache_archive" value="geogebra.jar, geogebra_main.jar, geogebra_gui.jar, geogebra_cas.jar, geogebra_export.jar, geogebra_properties.jar" />
        <param name="cache_version" value="3.2.47.0, 3.2.47.0, 3.2.47.0, 3.2.47.0, 3.2.47.0, 3.2.47.0" />
        <param name="framePossible" value="true" />
        <param name="showResetIcon" value="true" />
        <param name="showAnimationButton" value="true" />
        <param name="enableRightClick" value="true" />
        <param name="errorDialogsActive" value="true" />
        <param name="enableLabelDrags" value="true" />
        <param name="showMenuBar" value="true" />
        <param name="showToolBar" value="true" />
        <param name="showToolBarHelp" value="true" />
        <param name="showAlgebraInput" value="true" />
        <param name="allowRescaling" value="true" />
This is a Java Applet created using GeoGebra from www.geogebra.org - it looks like you don't have Java installed, please go to www.java.com
</applet>
</td></tr></table>
</xsl:template>

<!-- Pre-built Geogebra demonstrations based on ggbBase64 strings -->
<xsl:template match="geogebra-applet[ggbBase64]">
<xsl:variable name="ggbBase64"><xsl:value-of select="ggbBase64" /></xsl:variable>
<table border="0" width="750">
<tr><td>
<applet name="ggbApplet" code="geogebra.GeoGebraApplet" archive="geogebra.jar"
        codebase="http://www.geogebra.org/webstart/3.2/unsigned/"
        width="750" height="441" mayscript="true">
        <param name="ggbBase64" value="{$ggbBase64}"/>
        <param name="image" value="http://www.geogebra.org/webstart/loading.gif"  />
        <param name="boxborder" value="false"  />
        <param name="centerimage" value="true"  />
        <param name="java_arguments" value="-Xmx512m -Djnlp.packEnabled=true" />
        <param name="cache_archive" value="geogebra.jar, geogebra_main.jar, geogebra_gui.jar, geogebra_cas.jar, geogebra_export.jar, geogebra_properties.jar" />
        <param name="cache_version" value="3.2.47.0, 3.2.47.0, 3.2.47.0, 3.2.47.0, 3.2.47.0, 3.2.47.0" />
        <param name="framePossible" value="false" />
        <param name="showResetIcon" value="false" />
        <param name="showAnimationButton" value="true" />
        <param name="enableRightClick" value="false" />
        <param name="errorDialogsActive" value="true" />
        <param name="enableLabelDrags" value="false" />
        <param name="showMenuBar" value="false" />
        <param name="showToolBar" value="false" />
        <param name="showToolBarHelp" value="false" />
        <param name="showAlgebraInput" value="false" />
        <param name="allowRescaling" value="true" />
This is a Java Applet created using GeoGebra from www.geogebra.org - it looks like you don't have Java installed, please go to www.java.com
</applet>
</td></tr></table>
</xsl:template>



<!--                         -->
<!-- Web Page Infrastructure -->
<!--                         -->

<!-- An individual page:                                     -->
<!-- Inputs:                                                 -->
<!--     * strings for page title, subtitle, authors/editors -->
<!--     * content (exclusive of banners, etc)               -->
<xsl:template match="*" mode="page-wrap">
    <xsl:param name="title" />
    <xsl:param name="subtitle" />
    <xsl:param name="credits" />
    <xsl:param name="content" />
    <xsl:variable name="url"><xsl:apply-templates select="." mode="url" /></xsl:variable>
    <exsl:document href="{$url}" method="html">
    <!-- Need to be careful for format of this initial string     -->
    <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html>&#xa;</xsl:text>
    <html> <!-- lang="", and/or dir="rtl" here -->
        <head>
            <xsl:call-template name="converter-blurb" />
            <!-- http://webdesignerwall.com/tutorials/responsive-design-in-3-steps -->
            <meta name="viewport" content="width=device-width,  initial-scale=1.0, user-scalable=0, minimum-scale=1.0, maximum-scale=1.0" />
            <xsl:call-template name="mathjax" />
            <xsl:call-template name="sagecell" />
            <xsl:if test="/mathbook//program">
                <xsl:call-template name="goggle-code-prettifier" />
            </xsl:if>
            <xsl:call-template name="knowl" />
            <xsl:call-template name="mathbook-js" />
            <xsl:call-template name="fonts" />
            <xsl:call-template name="css" />
            <xsl:if test="//video">
                <xsl:call-template name="video" />
            </xsl:if>
        </head>
        <xsl:element name="body">
            <xsl:if test="$toc-level > 0">
                <xsl:attribute name="class">has-toc has-sidebar-left</xsl:attribute> <!-- later add right -->
            </xsl:if>
            <xsl:call-template name="latex-macros" />
             <header id="masthead">
                <div class="banner">
                        <div class="container">
                            <xsl:call-template name="brand-logo" />
                            <div class="title-container">
                                <h1 class="title">
                                    <xsl:value-of select="$title" />
                                    <xsl:if test="normalize-space($subtitle)">
                                        <p class="subtitle">
                                            <xsl:value-of select="$subtitle" />
                                        </p>
                                    </xsl:if>
                                </h1>
                                <p class="byline"><xsl:value-of select="$credits" /></p>
                            </div>
                        </div>
                </div>
            <xsl:apply-templates select="." mode="primary-navigation" />
            </header>
            <div class="page container">
                <xsl:apply-templates select="." mode="sidebars" />
                <main class="main">
                    <xsl:apply-templates select="." mode="secondary-navigation" />
                    <div id="content">
                        <xsl:copy-of select="$content" />
                    </div>
                </main>
            </div>
        <xsl:apply-templates select="/mathbook/docinfo/analytics" />
        </xsl:element>
    </html>
    </exsl:document>
</xsl:template>

<!-- ################# -->
<!-- Navigational Aids -->
<!-- ################# -->

<!-- Prev/Next URL's -->
<!-- Check if the XML tree has a preceding/following node -->
<!-- Then check if it is a document node (structural)     -->
<!-- If so, compute the URL for the node                  -->
<!-- TODO: make the up/back version, then drop obsolete SVG arrows -->
<xsl:template match="*" mode="previous-url">
    <xsl:if test="preceding-sibling::*">
        <xsl:variable name="preceding" select="preceding-sibling::*[1]" />
        <xsl:variable name="structural">
            <xsl:apply-templates select="$preceding" mode="is-structural" />
        </xsl:variable>
        <xsl:if test="$structural='true'">
            <xsl:apply-templates select="$preceding" mode="url" />
        </xsl:if>
    </xsl:if>
    <!-- could be empty -->
</xsl:template>

<xsl:template match="*" mode="next-url">
    <xsl:if test="following-sibling::*">
        <xsl:variable name="following" select="following-sibling::*[1]" />
        <xsl:variable name="structural">
            <xsl:apply-templates select="$following" mode="is-structural" />
        </xsl:variable>
        <xsl:if test="$structural='true'">
            <xsl:apply-templates select="$following" mode="url" />
        </xsl:if>
    </xsl:if>
    <!-- could be empty -->
</xsl:template>


<!-- Navigation Sections, Primary and Secondary -->
<!-- TODO: consolidate duplicated button generation, once it is clear how to handle empty buttons -->
<!-- Primary - complete for mobile target -->
<xsl:template match="*" mode="primary-navigation">
    <nav id="primary-navbar" class="navbar">
        <div class="container">
            <!-- place buttons in order for mobile -->
            <!-- begin Previous -->
            <xsl:element name="a">
                <xsl:attribute name="class">previous-button button</xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:apply-templates select="." mode="previous-url" />
                </xsl:attribute>
                <xsl:text>Previous</xsl:text>  <!-- internationalize -->
            </xsl:element>
            <!-- end Previous -->
            <button id="sidebar-left-toggle-button" class="button">Table of Contents</button> <!-- internationalize -->
            <button id="sidebar-right-toggle-button" class="button">Annotations</button> <!-- internationalize -->
            <!-- begin Next -->
            <xsl:element name="a">
                <xsl:attribute name="class">next-button button</xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:apply-templates select="." mode="next-url" />
                </xsl:attribute>
                <xsl:text>Next</xsl:text>  <!-- internationalize -->
            </xsl:element>
            <!-- end Next -->
        </div>
    </nav>
</xsl:template>

<!-- Secondary - desktop has ToC, Annotation buttons on top -->
<xsl:template match="*" mode="secondary-navigation">
    <nav id="secondary-navbar" class="navbar">
        <!-- begin Previous -->
        <xsl:element name="a">
            <xsl:attribute name="class">previous-button button</xsl:attribute>
            <xsl:attribute name="href">
                <xsl:apply-templates select="." mode="previous-url" />
            </xsl:attribute>
            <xsl:text>Previous</xsl:text>  <!-- internationalize -->
        </xsl:element>
        <!-- end Previous -->
        <!-- Put Up/Back here -->
        <!-- begin Next -->
        <xsl:element name="a">
            <xsl:attribute name="class">next-button button</xsl:attribute>
            <xsl:attribute name="href">
                <xsl:apply-templates select="." mode="next-url" />
            </xsl:attribute>
            <xsl:text>Next</xsl:text>  <!-- internationalize -->
        </xsl:element>
        <!-- end Next -->
    </nav>
</xsl:template>


<!-- Sidebars -->
<!-- Two HTML aside's for ToC (left), Annotations (right)       -->
<!-- Need to pass node down into "toc-items", which is per-page -->
<xsl:template match="*" mode="sidebars">
    <aside id="sidebar-left" class="sidebar">
        <div class="sidebar-content">
            <nav id="toc" style="height: 394px;">
                 <xsl:apply-templates select="." mode="toc-items" />
            </nav>
            <div class="extras">
                <nav>
                    <a class="feedback-link" href="">Feedback</a>
                    <a class="mathbook-link" href="http://mathbook.pugetsound.edu">Authored in MathBook XML</a>
                </nav>
            </div>
        </div>
    </aside>
    <aside id="sidebar-right" class="sidebar">
        <div class="sidebar-content">Mock right sidebar content</div>
    </aside>
</xsl:template>


<!-- Table of Contents Contents (Items) -->
<!-- Includes "active" class for enclosing outer node              -->
<!-- Node set equality and subset based on unions of subtrees, see -->
<!-- http://www.xml.com/cookbooks/xsltckbk/solution.csp?day=5      -->
<xsl:template match="*" mode="toc-items">
    <!-- Subtree for page this sidebar will adorn -->
    <xsl:variable name="this-page-node" select="descendant-or-self::*" />
    <xsl:if test="$toc-level > 0">
        <div id="toc-navbar-item" class="navbar-item">
            <h2 class="navbar-item-text icon-navicon-round ">Table of Contents</h2>
            <nav id="toc">
            <xsl:for-each select="/mathbook/book/*|/mathbook/article/*">
                <xsl:variable name="structural">
                    <xsl:apply-templates select="." mode="is-structural" />
                </xsl:variable>
                <xsl:if test="$structural='true'">
                    <!-- Subtree represented by this ToC item -->
                    <xsl:variable name="outer-node" select="descendant-or-self::*" />
                    <xsl:variable name="outer-url">
                        <xsl:apply-templates select="." mode="url"/>
                   </xsl:variable>
                   <!-- text of anchor's class, active if a match, otherwise plain -->
                   <!-- Based on node-set union size                               -->
                   <xsl:variable name="class">
                        <xsl:choose>
                            <xsl:when test="count($this-page-node|$outer-node) = count($outer-node)" >
                                <xsl:text>link active</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>link</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <!-- The link itself -->
                    <h2 class="{$class}"><a href="{$outer-url}">
                    <xsl:apply-templates select="." mode="number" />
                    <xsl:text> </xsl:text>
                    <xsl:apply-templates select="." mode="toc-entry" /></a></h2>
                    <ul> <!-- CSS expects a sublist, even if it is empty -->
                    <xsl:if test="$toc-level > 1">
                        <xsl:for-each select="./*">
                            <xsl:variable name="inner-structural">
                                <xsl:apply-templates select="." mode="is-structural" />
                            </xsl:variable>
                            <xsl:if test="$inner-structural='true'">
                                <!-- Subtree represented by this ToC item -->
                                <xsl:variable name="inner-node" select="descendant-or-self::*" />
                                <xsl:variable name="inner-url">
                                    <xsl:apply-templates select="." mode="url" />
                                </xsl:variable>
                                <xsl:variable name="internal">
                                    <xsl:apply-templates select="." mode="internal-id" />
                                </xsl:variable>
                                <li><a href="{$inner-url}" data-scroll="{$internal}">
                                <!-- Add if an "active" class if this is where we are -->
                                <xsl:if test="count($this-page-node|$inner-node) = count($inner-node)">
                                    <xsl:attribute name="class">active</xsl:attribute>
                                </xsl:if>
                                <xsl:apply-templates select="." mode="toc-entry" /></a></li>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:if>
                    </ul>
                </xsl:if>
            </xsl:for-each>
            </nav>
        </div>
    </xsl:if>
</xsl:template>

<!-- Some entries of table of contents are based on a title   -->
<!-- Others are just one-off and have language-specific names -->
<!-- Footnotes wreck havoc with table-of-contents text        -->
<xsl:template match="*" mode="toc-entry">
    <xsl:choose>
        <xsl:when test="title">
            <xsl:apply-templates select="title/node()[not(self::fn)]" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="type-name" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Now OBSOLETE, save for Up/Back code integrated elsewhere -->
<!-- Navigational Arrows -->
<!-- Page-specific       -->
<!-- TODO: Also make a floating navigation bar with arrows at bottom of page? -->
<xsl:template match="*" mode="nav-arrows">
    <nav id="prevnext">
        <!-- Previous -->
        <xsl:if test="preceding-sibling::*">
            <xsl:variable name="preceding" select="preceding-sibling::*[1]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$preceding" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='true'">
                <xsl:variable name="url">
                    <xsl:apply-templates select="$preceding" mode="url" />
                </xsl:variable>
                <a href="{$url}">
                    <svg height="50" width="60" viewBox="-10 50 110 100" xmlns="http://www.w3.org/2000/svg">
                        <polygon points="-10,100 25,75 100,75 100,125 25,125"
                        style="fill:darkred;stroke:maroon;stroke-width:1" />
                        <text x="28" y="108" fill="blanchedalmond" font-size="32">Prev</text>
                    </svg>
                </a>
            </xsl:if>
        </xsl:if>
        <!-- End Previous -->
        <!-- TODO: be more careful about adding space -->
        <!-- Maybe compute preceding, up, following at outer level of template -->
        <xsl:text> </xsl:text>
        <!-- Above -->
        <xsl:if test="parent::*">
            <xsl:variable name="parent" select="parent::*[1]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$parent" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='true'">
                <xsl:variable name="url">
                    <xsl:apply-templates select="$parent" mode="url" />
                </xsl:variable>
                <a href="{$url}">
                    <svg height="50" width="60" viewBox="0 50 80 100" xmlns="http://www.w3.org/2000/svg">
                        <polygon points="75,75 37,65 0,75 0,125 75,125"
                        style="fill:darkred;stroke:maroon;stroke-width:1"/>
                        <text x="13" y="108" fill="blanchedalmond" font-size="32">Up</text>
                    </svg>
                </a>
            </xsl:if>
        </xsl:if>
        <!-- End: Above -->
        <xsl:text> </xsl:text>
        <!-- Next -->
        <xsl:if test="following-sibling::*">
            <xsl:variable name="following" select="following-sibling::*[1]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$following" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='true'">
                <xsl:variable name="url">
                    <xsl:apply-templates select="$following" mode="url" />
                </xsl:variable>
                <a href="{$url}">
                    <svg height="50" width="60" viewBox="0 50 110 100" xmlns="http://www.w3.org/2000/svg">
                        <polygon points="110,100 75,75 0,75 0,125 75,125"
                        style="fill:darkred;stroke:maroon;stroke-width:1"/>
                        <text x="13" y="108" fill="blanchedalmond" font-size="32">Next</text>
                    </svg>
                </a>
            </xsl:if>
        </xsl:if>
        <!-- End: Next -->
    </nav>
</xsl:template>

<!-- ######## -->
<!-- Chunking -->
<!-- ######## -->

<!-- Web Page Determination -->
<!-- Three types of document nodes:                                                -->
<!-- Summary: structural node, not a document leaf, smaller level than chunk level -->
<!-- Webpage: structural node, at chunk-level or a document leaf at smaller level  -->
<!-- Neither: Subsidiary to some Webpage node                                      -->
<!-- See definition of document structure nodes in mathbook-common file            -->
<xsl:template match="*" mode="is-summary">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$structural='true'">
            <xsl:variable name="current-level">
                <xsl:apply-templates select="." mode="level" />
            </xsl:variable>
            <xsl:variable name="leaf">
                <xsl:apply-templates select="." mode="is-leaf" />
            </xsl:variable>
            <xsl:value-of select="($leaf='false') and ($chunk-level > $current-level)" />
        </xsl:when>
        <xsl:when test="$structural='false'">
            <xsl:value-of select="$structural" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: Structural determination (<xsl:value-of select="$structural" />) failed for is-summary at <xsl:apply-templates select="." mode="long-name"/></xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="is-webpage">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$structural='true'">
            <xsl:variable name="current-level">
                <xsl:apply-templates select="." mode="level" />
            </xsl:variable>
            <xsl:variable name="leaf">
                <xsl:apply-templates select="." mode="is-leaf" />
            </xsl:variable>
            <xsl:value-of select="($chunk-level = $current-level) or ( ($leaf='true') and ($chunk-level > $current-level) )" />
        </xsl:when>
        <xsl:when test="$structural='false'">
            <xsl:value-of select="$structural" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: Structural determination (<xsl:value-of select="$structural" />) failed for is-webpage at <xsl:apply-templates select="." mode="long-name"/></xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Filenames -->
<!-- Every web page has a file name,                           -->
<!-- and every node is subsidiary to some web page.            -->
<!-- This template give the filename of the webpage enclosing  -->
<!-- any node (or the webpage representing that node)          -->
<!-- This allows cross-references to point to the right page   -->
<!-- when chunking the content into many subdivisions          -->
<xsl:template match="*" mode="filename">
    <xsl:variable name="summary"><xsl:apply-templates select="." mode="is-summary" /></xsl:variable>
    <xsl:variable name="webpage"><xsl:apply-templates select="." mode="is-webpage" /></xsl:variable>
    <xsl:choose>
        <xsl:when test="$summary='true' or $webpage='true'">
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>.html</xsl:text>
            <!-- DEPRECATION: May 2015, replace with terminate=yes if present without an xml:id -->
            <xsl:if test="@filebase">
                <xsl:message>WARNING: filebase attribute (value=<xsl:value-of select="$a-node/@filebase" />) is deprecated, use xml:id attribute instead (by 1 May 2015)</xsl:message>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select=".." mode="filename" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- URL's -->
<!-- Every node has a URL associated with it -->
<!-- A filename, plus an optional anchor/id  -->
<xsl:template match ="*" mode="url">
    <xsl:variable name="summary"><xsl:apply-templates select="." mode="is-summary" /></xsl:variable>
    <xsl:variable name="webpage"><xsl:apply-templates select="." mode="is-webpage" /></xsl:variable>
    <xsl:apply-templates select="." mode="filename" />
    <xsl:if test="$summary='false' and $webpage='false'">
        <xsl:text>#</xsl:text>
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:if>
</xsl:template>

<!-- MathJax header                                             -->
<!-- XML manages equation numbers                               -->
<!-- Config MathJax to make anchor names on equations           -->
<!--   these are just the contents of the \label on an equation -->
<!--   which we provide as the xml:id of the equation           -->
<!-- Note: we could set \label with something different         -->
<xsl:template name="mathjax">
<script type="text/x-mathjax-config">
MathJax.Hub.Config({
    tex2jax: {
        inlineMath: [['\\(','\\)']]
    },
    TeX: {
        extensions: ["AMSmath.js", "AMSsymbols.js"],
        equationNumbers: { autoNumber: "none",
                           useLabelIds: true,
                           formatID: function (n) {return String(n).replace(/[:'"&lt;&gt;&amp;]/g,"")},
                         },
        TagSide: "right",
        TagIndent: ".8em",
    },
    "HTML-CSS": {
        scale: 88,
    },
});
</script>
<script type="text/javascript" src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML-full" />
</xsl:template>

<!-- Sage Cell header -->
<!-- TODO: internationalize button labels, strings below -->
<!-- TODO: make an initialization cell which links with the sage-compute cells -->
<xsl:template name="sagecell">
    <script src="http://sagecell.sagemath.org/static/jquery.min.js"></script>
    <script src="http://sagecell.sagemath.org/embedded_sagecell.js"></script>
    <script>
$(function () {
    // Make *any* div with class 'sage-compute' an executable Sage cell
    sagecell.makeSagecell({inputLocation: 'div.sage-compute',
                           linked: true,
                           evalButtonText: 'Evaluate'});
});
$(function () {
    // Make *any* div with class 'sage-display' a visible, uneditable Sage cell
    sagecell.makeSagecell({inputLocation: 'div.sage-display',
                           editor: 'codemirror-readonly',
                           hide: ['evalButton', 'editorToggle', 'language']});
});
    </script>
</xsl:template>

<!-- Program Listings from Google -->
<!--   ?skin=sunburst  on end of src URL gives black terminal look -->
<xsl:template name="goggle-code-prettifier">
    <script src="https://google-code-prettify.googlecode.com/svn/loader/run_prettify.js"></script>
</xsl:template>

<!-- Knowl header -->
<xsl:template name="knowl">
<script type="text/javascript" src="http://code.jquery.com/jquery-latest.min.js"></script> 
<link href="http://aimath.org/knowlstyle.css" rel="stylesheet" type="text/css" /> 
<script type="text/javascript" src="http://aimath.org/knowl.js"></script>

</xsl:template>

<!-- Mathbook Javascript header -->
<xsl:template name="mathbook-js">
    <!-- GSAP Animation Platform for granular animation control -->
    <script src="http://cdnjs.cloudflare.com/ajax/libs/gsap/1.12.1/TweenLite.min.js"></script>
    <script src="http://cdnjs.cloudflare.com/ajax/libs/gsap/1.12.1/TimelineLite.min.js"></script>
    <script src="http://cdnjs.cloudflare.com/ajax/libs/gsap/1.12.1/plugins/CSSPlugin.min.js"></script>

    <script src="http://mathbook.staging.michaeldubois.me/develop/js/lib/jquery.sticky.js"></script>
    <script src="http://mathbook.staging.michaeldubois.me/develop/js/lib/jquery.intersections.js"></script>
    <script src="http://mathbook.staging.michaeldubois.me/develop/js/SidebarView.js"></script>
    <script src="http://mathbook.staging.michaeldubois.me/develop/js/TouchController.js"></script>
    <script src="http://mathbook.staging.michaeldubois.me/develop/js/Mathbook.js"></script>
</xsl:template>

<!-- Font header -->
<!-- Google Fonts -->
<!-- Text: Open Sans by default (was: Istok Web font, regular and italic (400), bold (700)) -->
<!-- Code: Source Code Pro, regular (400) -->
<xsl:template name="fonts">
    <link href='http://fonts.googleapis.com/css?family=Open+Sans:400,400italic,600,600italic|Source+Code+Pro:400' rel='stylesheet' type='text/css' />
</xsl:template>

<!-- CSS header -->
<xsl:template name="css">
    <!-- #1 to #5 for different color schemes -->
    <link href="http://mathbook.staging.michaeldubois.me/develop/stylesheets/mathbook-modern-3.css" rel="stylesheet" type="text/css" />
    <link href="http://mathbook.staging.michaeldubois.me/develop/stylesheets/icons.css" rel="stylesheet" type="text/css" />
    <link href="http://aimath.org/mathbook/add-on.css" rel="stylesheet" type="text/css" />
</xsl:template>


<!-- Video header                    -->
<!-- Flowplayer setup                -->
<!-- assumes JQuery loaded elsewhere -->
<!-- 2014/03/07: http://flowplayer.org/docs/setup.html#global-configuration -->
<xsl:template name="video">
    <link rel="stylesheet" href="//releases.flowplayer.org/5.4.6/skin/minimalist.css" />
    <script src="//releases.flowplayer.org/5.4.6/flowplayer.min.js"></script>
    <script>flowplayer.conf = {
    };</script>

</xsl:template>

<!-- LaTeX Macros -->
<!-- In a hidden div, for near the top of the page -->
<xsl:template name="latex-macros">
    <xsl:if test="/mathbook/docinfo/macros">
        <div style="display:none;">
        <xsl:text>\(</xsl:text>
        <xsl:value-of select="/mathbook/docinfo/macros" />
        <xsl:text>\)</xsl:text>
        </div>
    </xsl:if>
</xsl:template>

<!-- Brand Logo -->
<!-- Place image in masthead -->
<xsl:template name="brand-logo">
    <xsl:if test="/mathbook/docinfo/brandlogo">
        <a id="logo-link" href="{/mathbook/docinfo/brandlogo/@url}" target="_blank" >
            <img src="{/mathbook/docinfo/brandlogo/@source}" />
        </a>
    </xsl:if>
</xsl:template>

<!-- Analytics Footers -->

<!-- Google Analytics                     -->
<!-- "Classic", not compared to Universal -->
<xsl:template match="google">
<xsl:comment>Start: Google code</xsl:comment>
<script type="text/javascript">
var _gaq = _gaq || [];
_gaq.push(['_setAccount', '<xsl:value-of select="./tracking" />']);
_gaq.push(['_trackPageview']);

(function() {
var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
})();
</script>
<xsl:comment>End: Google code</xsl:comment>
</xsl:template>

<!-- StatCounter                                -->
<!-- Set sc_invisible to 1                      -->
<!-- In noscript URL, final 1 is an edit from 0 -->
<xsl:template match="statcounter">
<xsl:comment>Start: StatCounter code</xsl:comment>
<script type="text/javascript">
var sc_project=<xsl:value-of select="./project" />;
var sc_invisible=1;
var sc_security="<xsl:value-of select="./security" />";
var scJsHost = (("https:" == document.location.protocol) ? "https://secure." : "http://www.");
<![CDATA[document.write("<sc"+"ript type='text/javascript' src='" + scJsHost+ "statcounter.com/counter/counter.js'></"+"script>");]]>
</script>
<xsl:variable name="noscript_url">
    <xsl:text>http://c.statcounter.com/</xsl:text>
    <xsl:value-of select="./project" />
    <xsl:text>/0/</xsl:text>
    <xsl:value-of select="./security" />
    <xsl:text>/1/</xsl:text>
</xsl:variable>
<noscript>
<div class="statcounter">
<a title="web analytics" href="http://statcounter.com/" target="_blank">
<img class="statcounter" src="{$noscript_url}" alt="web analytics" /></a>
</div>
</noscript>
<xsl:comment>End: StatCounter code</xsl:comment>
</xsl:template>

<!-- Converter information for header -->
<!-- TODO: add date, URL -->
<xsl:template name="converter-blurb">
    <xsl:comment>*                                    *</xsl:comment><xsl:text>&#xa;</xsl:text>
    <xsl:comment>* Generated from MathBook XML source *</xsl:comment><xsl:text>&#xa;</xsl:text>
    <xsl:comment>
        <xsl:text>*    on </xsl:text>
        <xsl:value-of select="date:date-time()" />
        <xsl:text>    *</xsl:text>
    </xsl:comment><xsl:text>&#xa;</xsl:text>
    <xsl:comment>*                                    *</xsl:comment><xsl:text>&#xa;</xsl:text>
    <xsl:comment>*   http://mathbook.pugetsound.edu   *</xsl:comment><xsl:text>&#xa;</xsl:text>
    <xsl:comment>*                                    *</xsl:comment><xsl:text>&#xa;</xsl:text>
</xsl:template>


<!-- Miscellaneous -->

<!-- Inline warnings go into text, no matter what -->
<!-- They are colored for an author's report -->
<xsl:template name="inline-warning">
    <xsl:param name="warning" />
    <xsl:element name="span">
        <!-- Color for author tools version -->
        <xsl:if test="$author-tools='yes'" >
            <xsl:attribute name="style">color:red</xsl:attribute>
        </xsl:if>
        <xsl:text>&lt;&lt;</xsl:text>
        <xsl:value-of select="$warning" />
        <xsl:text>&gt;&gt;</xsl:text>
    </xsl:element>
</xsl:template>

<!-- Marginal notes are only for author's report                     -->
<!-- and are always colored red.  Marginpar's from                   -->
<!-- http://www.sitepoint.com/web-foundations/floating-clearing-css/ -->
<xsl:template name="margin-warning">
    <xsl:param name="warning" />
    <xsl:if test="$author-tools='yes'" >
        <xsl:element name="span">
            <xsl:attribute name="style">color:red;float:right;width:20em;margin-right:-25em;</xsl:attribute>
            <xsl:value-of select="$warning" />
        </xsl:element>
    </xsl:if>
</xsl:template>


<!-- Uninteresting Code, aka the Bad Bank                    -->
<!-- Deprecated, unmaintained, etc, parked here out of sight -->

<!-- Legacy code: not maintained                  -->
<!-- Banish to common file when removed, as error -->
<!-- 2014/06/25: implemented with xref as link, need to duplicate knowl functionality -->
<xsl:template match="cite[@ref]">
    <xsl:message>MBX:WARNING: &lt;cite ref="<xsl:value-of select="@ref" />&gt; is deprecated, convert to &lt;xref ref="<xsl:value-of select="@ref" />"&gt;</xsl:message>
    <xsl:call-template name="knowl-link-factory">
        <xsl:with-param name="css-class">cite</xsl:with-param>
        <xsl:with-param name="identifier">
            <xsl:apply-templates select="id(@ref)" mode="internal-id" />
        </xsl:with-param>
        <xsl:with-param name="content">
            <xsl:text>[</xsl:text>
            <xsl:apply-templates select="id(@ref)" mode="number" />
            <xsl:if test="@detail">
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="@detail" />
            </xsl:if>
            <xsl:text>]</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

</xsl:stylesheet>