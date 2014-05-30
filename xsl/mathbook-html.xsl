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
            <xsl:message>ERROR: Chunk level not determined</xsl:message>
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
            <xsl:message>WARNING: Document node is considered both summary and webpage at <xsl:apply-templates  select="." mode="long-name"/>.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Document nodes subsidiary to a web page                -->
<!-- Make heading and enclosing div, no page infrastructure -->
<xsl:template match="*" mode="content">
    <xsl:variable name="url"><xsl:apply-templates select="." mode="internal-id" /></xsl:variable>
    <section class="{local-name(.)}" id="{$url}">
        <h1 class="heading">
            <xsl:if test="not(self::book or self::article)">
                <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
                <xsl:text> </xsl:text>
                <span class="counter"><xsl:apply-templates select="." mode="number" /></span>
                <xsl:text> </xsl:text>
            </xsl:if>
            <span class="title"><xsl:apply-templates select="title" /></span>
        </h1>
        <!-- Need some CSS for authors at subsidiary level in collected works -->
        <xsl:if test="author">
            <p id="byline"><span class="byline"><xsl:apply-templates select="author" mode="name-list"/></span></p>
        </xsl:if>
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
             <section class="{local-name(.)}">
                <h1 class="heading">
                    <xsl:if test="not(self::book or self::article or self::frontmatter)">
                        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
                        <xsl:text> </xsl:text>
                        <span class="counter"><xsl:apply-templates select="." mode="number" /></span>
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:if test="not(self::frontmatter)">
                        <span class="title"><xsl:apply-templates select="title" /></span>
                    </xsl:if>
                </h1>
                <!-- Need some CSS for authors at subsidiary level in collected works -->
                <xsl:if test="author">
                    <p id="byline"><span class="byline"><xsl:apply-templates select="author" mode="name-list"/></span></p>
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
                <h1 class="heading">
                    <xsl:if test="not(self::book or self::article or self::frontmatter)">
                        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
                        <xsl:text> </xsl:text>
                        <span class="counter"><xsl:apply-templates select="." mode="number" /></span>
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:if test="not(self::frontmatter)">
                        <span class="title"><xsl:apply-templates select="title" /></span>
                    </xsl:if>
                </h1>
                <!-- Need some CSS for authors at subsidiary level in collected works -->
                <xsl:if test="author">
                    <p id="byline"><span class="byline"><xsl:apply-templates select="author" mode="name-list"/></span></p>
                </xsl:if>
                <!-- Create summaries of each child node (which will be a document node) -->
                 <xsl:apply-templates select="*[not(self::title or self::author)]" mode="summary-entry" />
            </section>
         </xsl:with-param>
     </xsl:apply-templates>
     <!-- Summary-entries do not recurse, need to restart outside web page wrapper -->
    <xsl:apply-templates select="book|article|frontmatter|chapter|appendix|preface|acknowledgement|authorbiography|foreword|dedication|colophon|section|subsection|subsubsection|exercises|references" />
</xsl:template>

<!-- Document summaries -->
<!-- On a summary page, some items get summarized (eg subdivisions become links) -->
<!-- some do not (eg introductions)                                              -->

<!-- Document node summaries are just links to the page -->
<xsl:template match="book|article|chapter|appendix|section|subsection|subsubsection" mode="summary-entry">
    <xsl:variable name="url"><xsl:apply-templates select="." mode="url" /></xsl:variable>
    <h2 class="link"><a href="{$url}">
        <span class="counter"><xsl:apply-templates select="." mode="number" /></span>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="title" /></a>
    </h2>
</xsl:template>

<!-- Some items in summary pages are of interest and are not document nodes -->
<xsl:template match="titlepage|introduction" mode="summary-entry">
    <xsl:apply-templates />
</xsl:template>

<!-- TODO's can be anywhere and we do not want to see them -->
<xsl:template match="todo" mode="summary-entry" />

<!-- Page Navigation Bar -->
<!-- OBSOLETE: but useful example (filebase, title/node are no longer used)  -->
<!-- TODO: Rework as a floating navigation bar with arrows at bottom of page -->
<!-- http://stackoverflow.com/questions/12347412/concept-xml-xlst-preceding-sibling-and-ancestor -->
<!-- http://stackoverflow.com/questions/10367387/are-there-css-alternatives-to-the-deprecated-html-attributes-align-and-valign -->
<xsl:template name="page-navigation-bar">
    <table class="page-nav-bar">
        <tr>
        <td class="previous">
        <a href="{preceding-sibling::*[1]/@filebase}.html">
            <xsl:apply-templates select="preceding-sibling::*[1]/title/node()" />
        </a>
        </td>
        <td class="up">
        <a href="{parent::*/@filebase}.html">
            <xsl:apply-templates select="parent::*/title/node()" />
        </a>
        </td>
        <td class="next">
        <a href="{following-sibling::*[1]/@filebase}.html">
            <xsl:apply-templates select="following-sibling::*[1]/title/node()" />
        </a>
        </td>
        </tr>
    </table>
</xsl:template>

<!-- Theorem-Like, plus associated Proofs                                   -->
<!-- <statement>s and <proof>s are sequences of paragraphs and other blocks -->
<xsl:template match="theorem|corollary|lemma|proposition|claim|fact|conjecture|definition">
    <xsl:variable name="xref">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <article class="theorem-like" id="{$xref}">
        <h5>
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
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
<!-- Statement, just like a proof, to separate from notation perhaps -->
<xsl:template match="definition|axiom">
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

<!-- Solutions are include by default switch, could be knowls -->
<xsl:template match="exercise">
    <xsl:variable name="xref">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <article class="exercise-like" id="{$xref}">
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
    <xsl:apply-templates select="solution" />
</xsl:template>

<xsl:template match="exercise/solution">
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

<!-- Figures and their captions -->
<xsl:template match="figure">
    <div class="figure">
        <xsl:apply-templates select="*[not(self::caption)]"/>
        <xsl:apply-templates select="caption"/>
    </div>
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

<!-- Asymptote graphics language -->
<!-- unimplemented               -->
<xsl:template match="asymptote">
    <p style="margin:auto">&lt;Asymptote graphics migration to HTML not implemented, but is planned&gt;</p>
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
    <table class="plain-table">
        <xsl:apply-templates select="*[not(self::caption)]" />
        <xsl:apply-templates select="caption" />
    </table>
</xsl:template>

<xsl:template match="tgroup"><xsl:apply-templates /></xsl:template>
<xsl:template match="thead"><thead><xsl:apply-templates /></thead></xsl:template>
<xsl:template match="tbody"><tbody><xsl:apply-templates /></tbody></xsl:template>
<xsl:template match="row"><tr><xsl:apply-templates /></tr></xsl:template>
<!-- With a parent axis, get overrides easily? -->
<xsl:template match="thead/row/entry"><th align="{../../../@align}"><xsl:apply-templates /></th></xsl:template>
<xsl:template match="tbody/row/entry"><td align="{../../../@align}"><xsl:apply-templates /></td></xsl:template>

<!-- Caption of a figure or table                  -->
<!-- All the relevant information is in the parent -->
<xsl:template match="caption">
    <caption>
        <xsl:apply-templates select=".." mode="type-name"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select=".." mode="number"/>
        <xsl:text>: </xsl:text>
        <xsl:apply-templates />
        <xsl:apply-templates select=".." mode="label" />
    </caption>
</xsl:template>



<!-- Citations, Cross-References -->
<!-- Each a bit different in style of link (eg knowl), or content of link (eg "here") -->
<!-- Warnings at command-line for mess-ups are in common file -->

<!-- Bring up bibliographic entries as knowls with cite -->
<!-- Style the bare number with CSS, eg [6]             -->
<!-- A citation can be "provisional"   -->
<!-- as a tool for drafts, otherwise "ref" to -->
<!-- an xml:id in bibliography                     -->
<!-- TODO: tokenize a list of labels? -->

<!-- Point to any numbered item with link, content is number only -->
<!-- Displayed equations have targets manufactured by MathJax,    -->
<!-- which we ensure are consistent with our scheme here          -->
<!-- A cross-reference can be "provisional"   -->
<!-- as a tool for drafts, otherwise "ref" to -->
<!-- an xml:id elsewhere                      -->
<!-- TODO: need to take into account chunking for href manufacture -->
<!-- need to use basename for targetnode's file        -->
<!-- or knowl these references, with "in context link" -->
<xsl:template match="cite[@ref]">
    <xsl:call-template name="knowl-link-factory">
        <xsl:with-param name="css-class">cite</xsl:with-param>
        <xsl:with-param name="identifier">
            <xsl:apply-templates select="id(@ref)" mode="xref-identifier" />
        </xsl:with-param>
        <xsl:with-param name="content">
            <xsl:text>[</xsl:text>
            <xsl:apply-templates select="id(@ref)" mode="number" />
            <xsl:text>]</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="xref[@ref]">
    <!-- Save what the reference points to -->
    <xsl:variable name="target" select="id(@ref)" />
    <!-- Create what the reader sees, equation references get parentheses -->
    <xsl:variable name="visual">
        <xsl:choose>
            <xsl:when test="$target/self::mrow or $target/self::me or $target/self::men">
                <xsl:text>(</xsl:text>
                <xsl:apply-templates select="$target" mode="number" />
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$target" mode="number" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Build the anchor -->
    <xsl:element name ="a">
        <!-- http://stackoverflow.com/questions/585261/is-there-an-xslt-name-of-element -->
        <!-- Sans namespace (would be name(.)) -->
        <xsl:attribute name="class">
            <xsl:value-of select="local-name($target)" />
        </xsl:attribute>
        <xsl:attribute name="href">
            <xsl:apply-templates select="$target" mode="url" />
        </xsl:attribute>
    <xsl:value-of select="$visual" />
    </xsl:element>
</xsl:template>

<xsl:template match="cite[@provisional]|xref[@provisional]">
    <xsl:element name="span">
        <xsl:if test="$author-tools='yes'" >
            <xsl:attribute name="style">color:red</xsl:attribute>
        </xsl:if>
        <xsl:text>&lt;&lt;</xsl:text>
        <xsl:value-of select="@provisional" />
        <xsl:text>&gt;&gt;</xsl:text>
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

<!-- Point to a "random" mark, with generic "this point" link -->
<xsl:template match="pageref">
    <xsl:variable name="target-node" select="id(@label)" />
    <xsl:element name ="a">
        <xsl:attribute name="class">
            <xsl:value-of select="'pageref'" />
        </xsl:attribute>
        <xsl:attribute name="href">
            <xsl:text>#</xsl:text><xsl:value-of select="@label" />
        </xsl:attribute>
    <xsl:text>this point</xsl:text>
    </xsl:element>
</xsl:template>




<!-- TODO: condition on id present!!!!!-->
<!-- TODO: perhaps back up a level on xml:id and regroup elsewhere, see latex version -->
<xsl:template match="*" mode="label">
    <xsl:element name="a">
        <xsl:attribute name="class">
            <xsl:value-of select="'label'" />
        </xsl:attribute>
        <xsl:attribute name="name">
            <xsl:value-of select="@xml:id" />
        </xsl:attribute>
    </xsl:element>
</xsl:template>


<!-- Miscellaneous -->

<!-- A marker we can point to -->
<xsl:template match="mark">
   <xsl:apply-templates select="." mode="label" />
</xsl:template>


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
            <xsl:value-of select="." />
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
    <xsl:apply-templates />>
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

<!-- Entry as a list item    -->
<!-- And manufacture a knowl -->
<xsl:template match="biblio[@type='raw']">
    <li><xsl:apply-templates /></li>
    <xsl:call-template name="knowl-factory">
        <xsl:with-param name="identifier">
            <xsl:apply-templates select="." mode="xref-identifier" />
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


<!-- Math  -->
<!-- Inline snippets -->
<!-- Any numbered equation needs a TeX \label set                    -->
<!-- with the xml:id of the equation, so equation references workout -->
<!-- Note: we could set \label with something different              -->
<xsl:template match= "m">
    <xsl:text>\(</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\)</xsl:text>
</xsl:template>

<!-- Unnumbered, single displayed equation -->
<!-- Output follows source line breaks     -->
<xsl:template match="me">
    <xsl:text>\[</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\]</xsl:text>
</xsl:template>

<!-- Numbered, single displayed equation -->
<!-- Output follows source line breaks   -->
<xsl:template match="men">
    <xsl:text>\[</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
    <xsl:if test="@xml:id">
        <xsl:text>\label{</xsl:text>
        <xsl:value-of select="@xml:id" />
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>\]</xsl:text>
</xsl:template>

<!-- md, mdn containers are generic gather/align environments, so in common xsl -->

<!-- Rows of a multi-line math display                 -->
<!-- (1) MathJax config turns off all numbering        -->
<!-- (1) Numbering controlled here with \tag{}, \notag -->
<!-- (2) Labels are TeX-style, created by MathJax      -->
<!-- (2) MathJax config makes span id's predictable    -->
<!-- (3) Last row special, has no line-break marker    -->
<xsl:template match="mrow">
    <xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="." />
    <xsl:choose>
        <xsl:when test="(local-name(parent::*)='mdn') and (@number='no')">
            <xsl:text>\notag</xsl:text>
        </xsl:when>
        <xsl:when test="(local-name(parent::*)='md') and not(@number='yes')">
            <xsl:text>\notag</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\tag{</xsl:text>
            <xsl:apply-templates select="." mode="number" />
            <xsl:text>}</xsl:text>
            <xsl:if test="@xml:id">
                <xsl:text>\label{</xsl:text>
                <xsl:value-of select="@xml:id" />
                <xsl:text>}</xsl:text>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
        <xsl:when test="position()=last()">
            <xsl:text>&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\\</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Intertext -->
<!-- A LaTeX construct really, we just jump in/out of the align environment   -->
<!-- And package the text in an HTML paragraph, assuming it is just a snippet -->
<xsl:template match="md/intertext|mdn/intertext">
    <xsl:text>\end{align}&#xa;</xsl:text>
    <p>
    <xsl:apply-templates />
    </p>
    <xsl:text>\begin{align}&#xa;</xsl:text>
</xsl:template>


<!--Manual numbering example
<xsl:template match="mrow">
    <xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\tag{</xsl:text>
        <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
    <xsl:text>\\</xsl:text>
</xsl:template>-->

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
                <xsl:attribute name="class">has-toc</xsl:attribute>
            </xsl:if>
            <xsl:call-template name="latex-macros" />
             <header id="masthead">
                <div class="banner">
                        <div class="container">
                            <xsl:call-template name="brand-logo" />
                            <div class="title-container">
                                <h1 id="title">
                                    <span class="title"><xsl:value-of select="$title" /></span>
                                    <xsl:if test="normalize-space($subtitle)">
                                        <p id="subtitle">
                                            <span class="subtitle">
                                                <xsl:value-of select="$subtitle" />
                                            </span>
                                        </p>
                                    </xsl:if>
                                </h1>
                                <p id="byline"><span class="byline"><xsl:value-of select="$credits" /></span></p>
                            </div>
                        </div>
                </div>
            <xsl:apply-templates select="." mode="navigation" />
            </header>
            <div class="page">
                <main class="main">
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

<!-- ################# -->
<!-- Navigational Aids -->
<!-- ################# -->

<!-- Navigation Section -->
<!-- Using mode since navigation arrows are relative to node -->
<xsl:template match="*" mode="navigation">
    <div id="navbar">
        <div class="container">
            <xsl:call-template name="toc-items" />
            <xsl:apply-templates select="." mode="nav-arrows" />
        </div>
    </div>
</xsl:template>

<!-- Table of Contents SideBar -->
<!-- Identical on each page    -->
<xsl:template name="toc-items">
    <xsl:if test="$toc-level > 0">
        <div id="toc-navbar-item" class="navbar-item">
            <h2 class="navbar-item-text icon-navicon-round ">Table of Contents</h2>
            <nav id="toc">
            <xsl:for-each select="/mathbook/book/*|/mathbook/article/*">
                <xsl:variable name="structural">
                    <xsl:apply-templates select="." mode="is-structural" />
                </xsl:variable>
                <xsl:if test="$structural='true'">
                    <xsl:variable name="outer-url">
                        <xsl:apply-templates select="." mode="url"/>
                   </xsl:variable>
                    <h2 class="link"><a href="{$outer-url}">
                    <xsl:apply-templates select="." mode="number" />
                    <xsl:text> </xsl:text>
                    <xsl:apply-templates select="title" /></a></h2>
                    <ul> <!-- CSS expects a sublist, even if it is empty -->
                    <xsl:if test="$toc-level > 1">
                        <xsl:for-each select="./*">
                            <xsl:variable name="inner-structural">
                                <xsl:apply-templates select="." mode="is-structural" />
                            </xsl:variable>
                            <xsl:if test="$inner-structural='true'">
                                <xsl:variable name="inner-url">
                                    <xsl:apply-templates select="." mode="url" />
                                </xsl:variable>
                                <xsl:variable name="internal">
                                    <xsl:apply-templates select="." mode="internal-id" />
                                </xsl:variable>
                                <li><a href="{$inner-url}" data-scroll="{$internal}">
                                <xsl:apply-templates select="title" /></a></li>
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

<!-- Navigational Arrows -->
<!-- Page-specific       -->
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
        <xsl:otherwise>
            <xsl:value-of select="$structural" />
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
        <xsl:otherwise>
            <xsl:value-of select="$structural" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Files -->
<!-- Every web page has a file name,                       -->
<!-- and every node is subsidiary to some web page.        -->
<!-- With a web page objects will be referenced by anchors -->
<!-- formed from their internal identifier to make a URL   -->
<xsl:template name="filename">
    <xsl:param name="a-node" />
    <xsl:variable name="summary"><xsl:apply-templates select="$a-node" mode="is-summary" /></xsl:variable>
    <xsl:variable name="webpage"><xsl:apply-templates select="$a-node" mode="is-webpage" /></xsl:variable>
    <xsl:choose>
        <xsl:when test="$summary='true' or $webpage='true'">
            <xsl:apply-templates select="$a-node" mode="internal-id" />
            <xsl:text>.html</xsl:text>
            <!-- DEPRECATION: May 2015, replace with terminate=yes if present without an xml:id -->
            <xsl:if test="$a-node/@filebase">
                <xsl:message>WARNING: filebase attribute (value=<xsl:value-of select="$a-node/@filebase" />) is deprecated, use xml:id attribute instead (by 1 May 2015)</xsl:message>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="filename">
                <xsl:with-param name="a-node" select="$a-node/.." />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match ="*" mode="url">
    <xsl:variable name="summary"><xsl:apply-templates select="." mode="is-summary" /></xsl:variable>
    <xsl:variable name="webpage"><xsl:apply-templates select="." mode="is-webpage" /></xsl:variable>
    <xsl:call-template name="filename">
        <xsl:with-param name="a-node" select="." />
    </xsl:call-template>
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

<!-- Knowl header -->
<xsl:template name="knowl">
<script type="text/javascript" src="http://code.jquery.com/jquery-latest.min.js"></script> 
<link href="http://aimath.org/knowlstyle.css" rel="stylesheet" type="text/css" /> 
<script type="text/javascript" src="http://aimath.org/knowl.js"></script>

</xsl:template>

<!-- Mathbook Javasript header -->
<xsl:template name="mathbook-js">
    <script src="http://aimath.org/mathbook/ScrollingNav.js"></script>
    <script src="http://aimath.org/mathbook/Mathbook.js"></script>
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
    <link href="http://aimath.org/mathbook/mathbook-modern-3.css" rel="stylesheet" type="text/css" />
    <link href="http://aimath.org/mathbook/icons.css" rel="stylesheet" type="text/css" />
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


<!-- Miscellaneous -->


<!-- ToDo's are silent unless asked for -->
<!-- Can also grep across the source    -->
<xsl:template match="todo">
    <xsl:if test="$author-tools='yes'" >
        <xsl:element name="p">
            <xsl:attribute name="style">color:red</xsl:attribute>
            <xsl:apply-templates select="." mode="type-name" />
            <xsl:text>: </xsl:text>
            <xsl:apply-templates />
        </xsl:element>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>