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

<!-- Content as Knowls -->
<!-- These parameters control if content is -->
<!-- hidden in a knowl on first appearance -->
<!-- The happens automatically sometimes, -->
<!-- eg a footnote should always be hidden -->
<!-- Some things never are hidden, -->
<!-- eg an entire section (too big) -->
<xsl:param name="html.knowl.theorem" select="'no'" />
<xsl:param name="html.knowl.proof" select="'yes'" />
<xsl:param name="html.knowl.definition" select="'no'" />
<xsl:param name="html.knowl.example" select="'no'" />
<xsl:param name="html.knowl.remark" select="'no'" />
<xsl:param name="html.knowl.figure" select="'no'" />
<xsl:param name="html.knowl.table" select="'no'" />
<xsl:param name="html.knowl.exercise" select="'no'" />

<!-- CSS and Javascript Servers -->
<!-- We allow processing paramteers to specify new servers   -->
<!-- or to specify the particular CSS file, which may have   -->
<!-- different color schemes.  The defaults should work      -->
<!-- fine and will not need changes on initial or casual use -->
<!-- #0 to #5 on mathbook-modern for different color schemes -->
<!-- We just like #3 as the default                          -->
<!-- N.B.:  This scheme is transitional and may change             -->
<!-- N.B.:  without warning and without any deprecation indicators -->
<xsl:param name="html.js.server"  select="'http://aimath.org'" />
<xsl:param name="html.css.server" select="'http://aimath.org'" />
<xsl:param name="html.css.file"   select="'mathbook-3.css'" />

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
    <xsl:if test="//frontmatter/titlepage/author" >
        <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="personname" />
    <xsl:text> (</xsl:text>
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text>)</xsl:text>
</xsl:template>
<xsl:template match="editor" mode="name-list" >
    <xsl:text>, </xsl:text>
    <xsl:apply-templates select="personname" />
    <xsl:text> (</xsl:text>
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- Authors and editors with affiliations (eg, on title page) -->
<xsl:template match="author|editor" mode="full-info">
    <p>
        <xsl:apply-templates select="personname" />
        <xsl:if test="self::editor">
            <xsl:text>, </xsl:text>
            <xsl:apply-templates select="." mode="type-name" />
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


<!-- ############################# -->
<!-- Document Structure, version 2 -->
<!-- ############################# -->

<!-- Some XML nodes reflect the overall structure                 -->
<!-- of the document, such as chapter, section, backmatter.       -->
<!-- A routine in the common file describes precisely which ones. -->
<!--                                                             -->
<!-- Sometimes these nodes are a leaf of the structure tree,      -->
<!-- with no children that are structural.  A routine in          -->
<!-- the common file will identify this situation.                -->
<!--                                                             -->
<!-- Also in the common file, the "chunking" level is used to     -->
<!-- decide which of these nodes is a summary of its children,    -->
<!-- and which should comprise an entire HTML page (where the     -->
<!-- structure is just evidenced typographically).                -->
<!--                                                              -->
<!-- The "dispatch" template decides which of these two cases     -->
<!-- to handle.                                                   -->


<!-- Entry Point -->
<!-- This is the entry point for this stylesheet          -->
<!-- The root <mathbook> element has two children         -->
<!-- typically.  We kill <docinfo> for use in an ad-hoc   -->
<!-- fashion, and dispatch the other (book, article, etc) -->
<xsl:template match="/mathbook">
    <xsl:apply-templates mode="dispatch" />
</xsl:template>

<xsl:template match="docinfo" mode="dispatch" />

<!-- Dispatch -->
<!-- This routine should only ever receive a         -->
<!-- structual document node.  Anything at           -->
<!-- chunking level, or leaves at lesser levels,     -->
<!-- becomes a web page of its own.                  -->
<!--                                                 -->
<!-- Otherwise a node has structural children, so we -->
<!-- create a page that is a summary of the node.    -->
<!-- See below about page decorations.               -->
<xsl:template match="*" mode="dispatch">
    <xsl:variable name="structural"><xsl:apply-templates select="." mode="is-structural" /></xsl:variable>
    <xsl:if test="$structural='false'">
        <xsl:message>MBX:BUG: Dispatching a node (<xsl:apply-templates  select="." mode="long-name"/>) that is not structural.</xsl:message>
    </xsl:if>
    <xsl:variable name="summary"><xsl:apply-templates select="." mode="is-summary" /></xsl:variable>
    <xsl:variable name="webpage"><xsl:apply-templates select="." mode="is-webpage" /></xsl:variable>
    <!-- <xsl:message>INFO: <xsl:value-of select="local-name(.)"/> Summary: <xsl:value-of select="$summary"/> Webpage: <xsl:value-of select="$webpage"/> Name: <xsl:apply-templates  select="." mode="long-name"/></xsl:message> -->
    <xsl:choose>
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

<!-- Web Page -->
<!-- When a structural node is the parent of an   -->
<!-- entire web page, we build it here as content -->
<!-- sent to the web page wrapping template       -->
<xsl:template match="*" mode="webpage">
    <xsl:apply-templates select="." mode="page-wrap">
        <xsl:with-param name="title">
            <xsl:apply-templates select="/mathbook/book/title|/mathbook/article/title" />
        </xsl:with-param>
        <xsl:with-param name="subtitle">
            <xsl:apply-templates select="/mathbook/book/subtitle|/mathbook/article/subtitle" />
        </xsl:with-param>
        <!-- Serial list of authors, then editors, as names only -->
         <xsl:with-param name="credits">
            <xsl:apply-templates select="//frontmatter/titlepage/author" mode="name-list"/>
            <xsl:apply-templates select="//frontmatter/titlepage/editor" mode="name-list"/>
        </xsl:with-param>
        <xsl:with-param name="content">
            <!-- Heading, div for subdivision that is this page -->
            <!-- frontmatter/titlepage is exceptional           -->
            <xsl:variable name="ident"><xsl:apply-templates select="." mode="internal-id" /></xsl:variable>
            <section class="{local-name(.)}" id="{$ident}">
                <xsl:apply-templates select="." mode="section-header" />
                <!-- Recurse through contents inside enclosing section, ignore title, author -->
                <xsl:apply-templates select="./*[not(self::title or self::subtitle or self::author)]" />
            </section>
         </xsl:with-param>
     </xsl:apply-templates>
</xsl:template>

<!-- Page Decorations -->
<!-- Even if we summarize a node, it has some    -->
<!-- decorations we would like to ignore.  So    -->
<!-- we do not dispatch these and just slide by. -->
<xsl:template match="title|subtitle|author|introduction|todo|abstract|titlepage|conclusion" mode="dispatch" />

<!-- Summary Page -->
<!-- A summary page has some initial decorations,       -->
<!-- such as title, author and introduction.  Then      -->
<!-- the structural subnodes become links in a          -->
<!-- navigation section, followed by some final         -->
<!-- decorations like conclusions.                      -->
<!--                                                    -->
<!-- The webpage parameters below should be clear, while -->
<!-- the content is a heading, followed by mostly a list -->
<!-- of hyperlinks to the subsidiary document nodes.  So -->
<!-- we can isolate the links, we hit everything on the  -->
<!-- page three times, mostly doing nothing.             -->
<!--                                                     -->
<!-- Once concluded, we dispatch all the elements,       -->
<!-- knowing some will get killed immediately.           -->
<xsl:template match="*" mode="summary">
    <xsl:apply-templates select="." mode="page-wrap">
        <xsl:with-param name="title">
            <xsl:apply-templates select="/mathbook/*" mode="title-simple" />
        </xsl:with-param>
        <xsl:with-param name="subtitle">
            <xsl:apply-templates select="/mathbook/*/subtitle"/>
        </xsl:with-param>
        <!-- Serial list of authors, then editors, as names only -->
         <xsl:with-param name="credits">
            <xsl:apply-templates select="//frontmatter/titlepage/author" mode="name-list"/>
            <xsl:apply-templates select="//frontmatter/titlepage/editor" mode="name-list"/>
        </xsl:with-param>
        <xsl:with-param name="content">
            <!-- Heading, div for subdivision that is this page -->
            <xsl:variable name="ident"><xsl:apply-templates select="." mode="internal-id" /></xsl:variable>
            <section class="{local-name(.)}" id="{$ident}">
                <xsl:apply-templates select="." mode="section-header" />
                <!-- Summarize elements of the node (which could be verbatim) -->
                <xsl:apply-templates select="*" mode="summary-prenav" />
                <nav class="summary-links">
                    <xsl:apply-templates select="*" mode="summary-nav" />
                </nav>
                <xsl:apply-templates select="*" mode="summary-postnav"/>
            </section>
         </xsl:with-param>
     </xsl:apply-templates>
     <!-- Summary-mode templates do not recurse,  -->
     <!-- need to restart outside web page        -->
     <!-- wrapper and dispatch everything         -->
    <xsl:apply-templates mode="dispatch" />
</xsl:template>

<!-- Some elements inside a document node being summarized    -->
<!-- appear as content on the summary page, or are otherwise  -->
<!-- handled in an ad-hoc fashion (titles).  These can appear -->
<!-- before, or after, a navigation section, which holds      -->
<!-- links to the elements that are again structural.         -->

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
        <xsl:variable name="num"><xsl:apply-templates select="." mode="number" /></xsl:variable>
        <xsl:variable name="url"><xsl:apply-templates select="." mode="url" /></xsl:variable>
        <a href="{$url}">
            <!-- important not include codenumber span -->
            <xsl:if test="$num!=''">
                <span class="codenumber"><xsl:value-of select="$num" /></span>
            </xsl:if>
            <span class="title">
                <xsl:apply-templates select="." mode="title-simple" />
            </span>
        </a>
    </xsl:if>
</xsl:template>

<!-- Document Nodes -->
<!-- A structural node may be one of many on a web page -->
<!-- We make an HTML section, then a header, then       -->
<!-- recurse into remaining content                     -->
<xsl:template match="book|article|frontmatter|chapter|appendix|preface|acknowledgement|biography|foreword|dedication|colophon|section|subsection|subsubsection|exercises|references|backmatter">
    <xsl:variable name="ident"><xsl:apply-templates select="." mode="internal-id" /></xsl:variable>
    <section class="{local-name(.)}" id="{$ident}">
        <xsl:apply-templates select="." mode="section-header" />
        <!-- Now recurse through contents, ignoring title and author -->
        <!-- Just applying templates right and left -->
        <xsl:apply-templates  select="./*[not(self::title or self::subtitle or self::author)]"/>
    </section>
</xsl:template>

<!-- Header for Document Nodes -->
<!-- Every document node goes the same way, a    -->
<!-- heading followed by its subsidiary elements -->
<!-- hit with templates.  This is the header.    -->
<xsl:template match="*" mode="section-header">
    <header>
        <h1 class="heading">
            <xsl:apply-templates select="." mode="header-content" />
        </h1>
        <xsl:if test="author">
            <p class="byline"><xsl:apply-templates select="author" mode="name-list"/></p>
        </xsl:if>
    </header>
</xsl:template>

<!-- The "type" is redundant at the top-level, -->
<!-- so we hide it with a class specification  -->
<xsl:template match="book|article" mode="section-header">
    <header>
        <h1 class="heading hide-type">
            <xsl:apply-templates select="." mode="header-content" />
        </h1>
        <xsl:if test="author">
            <p class="byline"><xsl:apply-templates select="author" mode="name-list"/></p>
        </xsl:if>
    </header>
</xsl:template>

<!-- Sections which are "auto-titled" do not need to           -->
<!-- display their type since that is the default title        -->
<!-- The references and exercises are exceptions, see Headings -->
<xsl:template match="frontmatter|colophon|preface|foreword|acknowledgement|dedication|backmatter" mode="section-header">
    <header>
        <h1 class="heading hide-type">
            <xsl:apply-templates select="." mode="header-content" />
        </h1>
        <xsl:if test="author">
            <p class="byline"><xsl:apply-templates select="author" mode="name-list"/></p>
        </xsl:if>
    </header>
</xsl:template>

<!-- The "frontmatter" node will always lead with -->
<!-- a pseudo-introduction that is the titlepage. -->
<!-- The section-header is then redundant.        -->
<xsl:template match="frontmatter" mode="section-header" />

<!-- ###### -->
<!-- Titles -->
<!-- ###### -->

<!-- Almost everything can have a title, and they       -->
<!-- are important for navigation, so get recycled      -->
<!-- in various uses.  Some are nearly-mandatory,       -->
<!-- others are optional, and some nodes can get titled -->
<!-- automatically.  So mostly we handle them with      -->
<!-- modal templates and kill the generic occurence.    -->

<!-- Simple titles are lacking footnotes, and perhaps more. -->
<!-- Full titles have everything present.  We pass the      -->
<!-- complexity as a parameter until we get to actually     -->
<!-- processing the title itself.  But the interface to all -->
<!-- this is based on two modal templates of the enclosing  -->
<!-- structure that has a title, since we handle some       -->
<!-- structures differently.                                -->

<!-- Interface to Titles -->
<!-- Two levels of complexity                    -->
<!-- full:   lives on a page, go for it          -->
<!-- simple: used someplace else, be careful     -->
<!-- Pass the distinction through as a parameter -->
<xsl:template match="*" mode="title-full">
    <xsl:apply-templates select="." mode="title">
        <xsl:with-param name="complexity">full</xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="*" mode="title-simple">
    <xsl:apply-templates select="." mode="title">
        <xsl:with-param name="complexity">simple</xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- Chapters, Sections, etc may be untitled, so may be empty, though unusual -->
<!-- Environments could be untitled much of the time                          -->
<xsl:template match="book|article|chapter|appendix|section|subsection|subsubsection|exercise|example|remark|definition|axiom|conjecture|principle|theorem|corollary|lemma|proposition|claim|fact|proof|demonstration" mode="title">
    <xsl:param name="complexity" />
    <xsl:apply-templates select="title" mode="title">
        <xsl:with-param name="complexity"><xsl:value-of select="$complexity" /></xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- Other subdivisions can be auto-titled with their type-name -->
<!-- Synchronize with the header-content template above         -->
<xsl:template match="frontmatter|colophon|preface|foreword|acknowledgement|dedication|references|exercises|backmatter" mode="title">
    <xsl:param name="complexity" />
    <!-- Check if these subdivisions have been given a title -->
    <xsl:variable name="title">
        <xsl:apply-templates select="title" mode="title">
            <xsl:with-param name="complexity"><xsl:value-of select="$complexity" /></xsl:with-param>
        </xsl:apply-templates>
    </xsl:variable>
    <!-- Provide the title itself, or use the type-name as a default -->
    <xsl:choose>
        <xsl:when test="$title=''">
            <xsl:apply-templates select="." mode="type-name" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$title" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- <docinfo> is a sibling of book, article, etc              -->
<!-- So sometimes we ask for its title, which it does not have -->
<xsl:template match="docinfo" mode="title" />

<!-- Once actually at a title element, we    -->
<!-- process it or process without footnotes -->
<xsl:template match="title|subtitle" mode="title" >
    <xsl:param name="complexity" />
    <xsl:choose>
        <xsl:when test="$complexity='full'">
            <xsl:apply-templates />
        </xsl:when>
        <xsl:when test="$complexity='simple'">
            <xsl:apply-templates  select="./node()[not(self::fn)]" />
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Unhandled title requests,           -->
<!-- likely subdivisions or environments -->
<xsl:template match="*" mode="title">
    <xsl:message>MBX:BUG: asking for title of unhandled <xsl:value-of select="local-name(.)" /></xsl:message>
</xsl:template>

<!-- Kill titles, once all are handled, then strip avoidances elsewhere -->
<!-- <xsl:template match="*" select="title|subtitle" /> -->

<!-- ######## -->
<!-- Headings -->
<!-- ######## -->

<!-- Both environments and sections have a "type,"         -->
<!-- a "codenumber," and a "title."  We format these       -->
<!-- consistently here with a modal template.  We can hide -->
<!-- components with classes on the enclosing "heading"    -->
<xsl:template match="*" mode="header-content">
    <span class="type">
        <xsl:apply-templates select="." mode="type-name" />
    </span>
    <span class="codenumber">
        <xsl:apply-templates select="." mode="number" />
    </span>
    <span class="title">
        <xsl:apply-templates select="." mode="title-full" />
    </span>
</xsl:template>

<!-- References and Exercises are universal subdivisions       -->
<!-- We give them a localized "type" computed from their level -->
<xsl:template match="exercises|references" mode="header-content">
    <span class="type">
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id">
                <xsl:apply-templates select="." mode="subdivision-name" />
            </xsl:with-param>
        </xsl:call-template>
    </span>
    <span class="codenumber">
        <xsl:apply-templates select="." mode="number" />
    </span>
    <span class="title">
        <xsl:apply-templates select="." mode="title-full" />
    </span>
</xsl:template>


<!-- ####################### -->
<!-- Front Matter Components -->
<!-- ####################### -->

<!-- Title Page -->
<!-- A frontmatter has no title, so we reproduce the            -->
<!-- title of the work (book or article) here                   -->
<!-- We add other material prior to links to major subdivisions -->
<xsl:template match="titlepage">
    <h1 class="heading">
        <span class="title"><xsl:apply-templates select="/mathbook/*/title" /></span>
        <xsl:if test="/mathbook/*/subtitle">
            <span class="subtitle"><xsl:apply-templates select="/mathbook/*/subtitle" /></span>
        </xsl:if>
    </h1>
    <address class="contributors">
        <xsl:apply-templates select="author|editor" mode="full-info"/>
    </address>
    <xsl:if test="date">
        <p style="text-align:center"><xsl:apply-templates select="date" /></p>
    </xsl:if>
</xsl:template>

<!-- Colophon -->
<!-- Licenses, ISBN, Cover Designer, etc -->
<!-- We process pieces, in document order -->
<!-- TODO: edition, publisher, production notes, cover design, etc -->
<!-- TODO: revision control commit hash -->
<xsl:template match="colophon/copyright">
    <p>
        <xsl:text>&#xa9;</xsl:text>
        <xsl:apply-templates select="year" />
        <xsl:text>&#xa0;&#xa0;</xsl:text>
        <xsl:apply-templates select="holder" />
    </p>
    <xsl:if test="shortlicense">
        <p>
            <xsl:apply-templates select="shortlicense" />
        </p>
    </xsl:if>
</xsl:template>

<!-- Introductions and Conclusions -->
<!-- Simple containers, allowed before and after       -->
<!-- explicit subdivisions, to introduce or summarize  -->
<!-- No title allowed, typically just a few paragraphs -->
<xsl:template match="introduction|conclusion">
    <xsl:variable name="ident"><xsl:apply-templates select="." mode="internal-id" /></xsl:variable>
    <article class="{local-name(.)}" id="{$ident}">
        <xsl:apply-templates />
    </article>
</xsl:template>

<!-- ####################### -->
<!-- Back Matter Components -->
<!-- ####################### -->

<xsl:template match="solution-list">
    <xsl:apply-templates select="//exercises" mode="backmatter" />
</xsl:template>

<xsl:template match="exercises" mode="backmatter">
    <xsl:variable name="nonempty" select="(.//hint and $exercise.backmatter.hint='yes') or
                                          (.//answer and $exercise.backmatter.answer='yes') or
                                          (.//solution and $exercise.backmatter.solution='yes')" />

    <xsl:if test="$nonempty='true'">
        <section class="exercises" id="">
            <h1 class="heading">
                <span class="type">Exercises</span>
                <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
                <span class="title"><xsl:apply-templates select="title-full" /></span>
            </h1>
            <xsl:apply-templates select="*[not(self::title)]" mode="backmatter" />
        </section>
    </xsl:if>
</xsl:template>

<!-- We kill the introduction and conclusion for -->
<!-- the exercises and for the exercisegroups    -->
<xsl:template match="exercises//introduction|exercises//conclusion" mode="backmatter" />

<!-- Print exercises with some solution component -->
<!-- Respect switches about visibility ("knowl" is assumed to be 'no') -->
<xsl:template match="exercise" mode="backmatter">
    <xsl:if test="hint or answer or solution">
        <!-- Lead with the problem number and some space -->
        <xsl:variable name="xref">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:variable>
        <article class="exercise-like" id="{$xref}">
            <h5 class="heading hidden-type">
            <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
            <span class="codenumber"><xsl:apply-templates select="." mode="origin-id" /></span>
            <xsl:if test="title">
                <span class="title"><xsl:apply-templates select="title" /></span>
            </xsl:if>
            </h5>
            <xsl:if test="$exercise.backmatter.statement='yes'">
                <!-- TODO: not a "backmatter" template - make one possibly? Or not necessary -->
                <xsl:apply-templates select="statement" />
            </xsl:if>
            <xsl:if test="hint and $exercise.backmatter.hint='yes'">
                <xsl:apply-templates select="hint" mode="backmatter" />
            </xsl:if>
            <xsl:if test="answer and $exercise.backmatter.answer='yes'">
                <xsl:apply-templates select="answer" mode="backmatter" />
            </xsl:if>
            <xsl:if test="solution and $exercise.backmatter.solution='yes'">
                <xsl:apply-templates select="solution" mode="backmatter" />
            </xsl:if>
        </article>
    </xsl:if>
</xsl:template>


<xsl:template match="hint|answer|solution" mode="backmatter">
    <article class="example-like">
        <h5 class="heading">
            <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
            <!-- Careful: number comes from enclosing exercise -->
            <span class="codenumber"><xsl:apply-templates select=".." mode="number" /></span>
            <span class="title"><xsl:apply-templates select="title-full" /></span>
        </h5>
        <xsl:apply-templates />
    </article>
</xsl:template>

<!-- At location, we just drop a marker -->
<xsl:template match="notation">
    <xsl:element name="span">
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:attribute>
    </xsl:element>
</xsl:template>

<!-- Notation list -->
<!-- TODO: Localize/Internationalize header row -->
<xsl:template match="notation-list">
    <table>
        <tr>
            <th style="text-align:left">Symbol</th>
            <th style="text-align:left">Description</th>
        </tr>
        <xsl:apply-templates select="//notation" mode="backmatter" />
    </table>
</xsl:template>

<xsl:template match="notation" mode="backmatter">
    <tr>
        <td>
            <xsl:text>\(</xsl:text>
            <xsl:value-of select="usage" />
            <xsl:text>\)</xsl:text>
        </td>
        <td>
            <xsl:apply-templates select="description" />
            <xsl:text> </xsl:text>
            <xsl:element name="a">
                <xsl:attribute name="href">
                    <xsl:apply-templates select="." mode="url" />
                </xsl:attribute>
                <xsl:text>[*]</xsl:text>
            </xsl:element>
        </td>
    </tr>
</xsl:template>


<!-- ####################### -->
<!-- Environments and Knowls -->
<!-- ####################### -->

<!--
Environments are small amounts of information,
often the right size to be a knowl.  They usually
contain information that allows them to be targets of
a cross-reference.  A classic example is an Example.
Footnotes are at one end of the spectrum, while a
Theorem or Exercise is at the other end.

When placed in knowls they can be the target of
a cross-reference (a bibliographic reference), or
they can be information-hiding (solution to an
exercise).  These are not "environments" in the
same sense as LaTeX uses the word, in particular
they are not structural subdivisions.

An environment can be hidden at its first
presentation to a reader.  A footnote is
always hidden, that is its main feature.
An equation is never hidden, that would be odd.
Usually we hide something like an example,
presenting the reader just a header-like
clickable to bring up a knowl.

The opposite of "hidden" is "visible", which
is just flat out on the page, as if printed there.
-->

<!-- Hidden and Visible Environments -->
<!-- The "is-hidden" template returns 'yes'/'no' -->
<!-- for each environment. Some choices are      -->
<!-- customizable, and some are fixed.           -->
<!-- Default just issues an error warning.       -->
<xsl:template match="*" mode="is-hidden">
    <xsl:message>MBX:ERROR: inquired inappropriately if an environment is hidden or not</xsl:message>
</xsl:template>

<!-- Environment Element Names -->
<!-- Environments get wrapped in HTML elements.        -->
<!-- They have an id where they are born, and          -->
<!-- not when they are the content of a xref knowl.    -->
<!-- ID's are needed so context links to have targets. -->
<!-- TODO: Kludge, convert to error-->
<xsl:template match="*" mode="environment-element">
    <!-- <xsl:text>article</xsl:text> -->
    <xsl:message>MBX:ERROR: an environment  (<xsl:value-of select="local-name(.)" />) does not know its HTML element</xsl:message>
</xsl:template>

<!-- Environment Class Names -->
<!-- An environment, visible or hidden has a      -->
<!-- class name for CSS to recognize it.  Some    -->
<!-- are grouped in broad classes.  This template -->
<!-- returns the relevant class name.             -->
<xsl:template match="*" mode="environment-class">
    <xsl:message>MBX:ERROR: an environment  (<xsl:value-of select="local-name(.)" />) does not know its CSS class</xsl:message>
</xsl:template>

<!-- Head, Body, Posterior -->
<!-- An environment had a head (for knowl clickables),     -->
<!-- a body (the actual content after the head), and a     -->
<!-- posterior (to follow outside the structure, eg proof) -->
<xsl:template match="*" mode="head">
    <xsl:message>MBX:ERROR: an environment  (<xsl:value-of select="local-name(.)" />) does not know its header</xsl:message>
</xsl:template>
<xsl:template match="*" mode="body">
    <xsl:message>MBX:ERROR: an environment  (<xsl:value-of select="local-name(.)" />) does not know its body</xsl:message>
</xsl:template>
<xsl:template match="*" mode="posterior">
    <xsl:message>MBX:ERROR: an environment  (<xsl:value-of select="local-name(.)" />) does not know its posterior</xsl:message>
</xsl:template>


<!-- Entry Point to Process Environments -->
<!-- This is the entry point for *all* environments       -->
<!-- We always build a knowl to be target of a xref       -->
<!-- We build a hidden knowl and place a link on the page -->
<!-- Or, we show the full content of the item on the page -->
<xsl:template match="fn|biblio|example|remark|definition|axiom|conjecture|principle|theorem|corollary|lemma|proposition|claim|fact|proof|hint|answer|solution|note">
    <!-- Always build a knowl we can point to it with a cross-reference -->
    <xsl:apply-templates select="." mode="xref-knowl-factory" />
    <!-- Born hidden or not (visible) -->
    <xsl:variable name="hidden">
        <xsl:apply-templates select="." mode="is-hidden" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$hidden='yes'">
            <xsl:apply-templates select="." mode="environment-hidden" />
            <!-- embedded, so place on page right below -->
            <xsl:apply-templates select="." mode="hidden-knowl-factory" />
        </xsl:when>
        <xsl:when test="$hidden='no'">
            <xsl:apply-templates select="." mode="environment-visible" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: an environment does not know if it is hidden or not</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Environments Rendered Hidden -->
<!-- Similar content as the visible case, but now -->
<!-- a knowl to actual content (in the body) that -->
<!-- has the head as the clickable                -->
<!-- Wrapped in an element with an id and a class -->
<xsl:template match="*" mode="environment-hidden">
    <xsl:variable name="element">
        <xsl:apply-templates select="." mode="environment-element" />
    </xsl:variable>
    <xsl:element name="{$element}">
        <xsl:attribute name="class">
           <xsl:apply-templates select="." mode="environment-class" />
        </xsl:attribute>
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:attribute>
        <xsl:element name="a">
            <!-- Point to the file version, may have silly in-context link -->
            <xsl:attribute name="knowl">
                <xsl:apply-templates select="." mode="xref-knowl-filename" />
            </xsl:attribute>
            <!-- Following creates an embedded knowl, careully uncomment -->
            <!-- empty, indicates content *not* in a file -->
            <!-- <xsl:attribute name="knowl"></xsl:attribute> -->
            <!-- class indicates content is in div referenced by id -->
            <!-- <xsl:attribute name="class"> -->
                <!-- <xsl:text>id-ref</xsl:text> -->
            <!-- </xsl:attribute> -->
            <!-- and the id via a template for consistency -->
            <!-- <xsl:attribute name="refid"> -->
                <!-- <xsl:apply-templates select="." mode="hidden-knowl-id" /> -->
            <!-- </xsl:attribute> -->
            <xsl:apply-templates select="." mode="head" />
        </xsl:element>
    </xsl:element>
</xsl:template>

<!-- Environments Rendered Visible -->
<!-- This would be a "normal" display of an environment -->
<!-- Wrapped in some type of element, with a class name -->
<!-- and an id, for HTML rendering                      -->
<xsl:template match="*" mode="environment-visible">
    <xsl:variable name="element">
        <xsl:apply-templates select="." mode="environment-element" />
    </xsl:variable>
    <xsl:element name="{$element}">
        <xsl:attribute name="class">
           <xsl:apply-templates select="." mode="environment-class" />
        </xsl:attribute>
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:attribute>
        <xsl:apply-templates select="." mode="head" />
        <xsl:apply-templates select="." mode="body" />
    </xsl:element>
    <xsl:apply-templates select="." mode="posterior" />
</xsl:template>

<!-- Footnotes -->
<!-- Always born hidden -->
<xsl:template match="fn" mode="is-hidden">
    <xsl:text>yes</xsl:text>
</xsl:template>
<!-- Head is the "mark", a number with two thin spaces -->
<xsl:template match="fn" mode="head">
    <xsl:text>&#x2009;</xsl:text>
    <xsl:apply-templates select="." mode="origin-id" />
    <xsl:text>&#x2009;</xsl:text>
</xsl:template>
<!-- Body is just all content, but joined to the head -->
<xsl:template match="fn" mode="body">
    <xsl:text>) </xsl:text>
    <xsl:apply-templates />
</xsl:template>
<!-- No posterior  -->
<xsl:template match="fn" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="fn" mode="environment-element">
    <xsl:text>sup</xsl:text>
</xsl:template>
<xsl:template match="fn" mode="environment-class">
    <xsl:text>footnote</xsl:text>
</xsl:template>


<!-- References, Citations (biblio) -->
<!-- Never born hidden -->
<xsl:template match="biblio" mode="is-hidden">
    <xsl:text>no</xsl:text>
</xsl:template>
<!-- There is no head, all body -->
<xsl:template match="biblio" mode="head" />
<!-- Body is all the content -->
<xsl:template match="biblio" mode="body">
    <div class="bibitem">
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="." mode="origin-id" />
        <xsl:text>]</xsl:text>
    </div>
    <xsl:text disable-output-escaping="yes">&amp;nbsp;&amp;nbsp;</xsl:text>
    <div class="bibentry">
        <xsl:apply-templates select="text()|*[not(self::note)]" />
    </div>
    <xsl:apply-templates select="note" />
</xsl:template>
<!-- No posterior  -->
<xsl:template match="biblio" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="biblio" mode="environment-element">
    <xsl:text>div</xsl:text>
</xsl:template>
<xsl:template match="biblio" mode="environment-class">
    <xsl:text>bib</xsl:text>
</xsl:template>


<!-- Examples, Remarks -->
<!-- Individually customizable -->
<!-- Similar, as just runs of paragraphs -->
<xsl:template match="example" mode="is-hidden">
    <xsl:value-of select="$html.knowl.example" />
</xsl:template>
<xsl:template match="remark" mode="is-hidden">
    <xsl:value-of select="$html.knowl.remark" />
</xsl:template>
<!-- Head is type, number, title -->  <!-- GENERALIZE -->
<xsl:template match="example|remark" mode="head">
    <h5 class="heading">
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
        <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
        <xsl:if test="title">
            <span class="title"><xsl:apply-templates select="title" /></span>
        </xsl:if>
    </h5>
</xsl:template>
<!-- Body is just all content, but no title -->
<xsl:template match="example|remark" mode="body">
    <xsl:apply-templates select="*[not(self::title)]"/>
</xsl:template>
<!-- No posterior  -->
<xsl:template match="example|remark" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="example|remark" mode="environment-element">
    <xsl:text>article</xsl:text>
</xsl:template>
<xsl:template match="example|remark" mode="environment-class">
    <xsl:text>example-like</xsl:text>
</xsl:template>

<!-- Definitions, etc. -->
<!-- Customizable as hidden    -->
<!-- A statement without proof -->
<xsl:template match="definition|axiom|conjecture|principle" mode="is-hidden">
    <xsl:value-of select="$html.knowl.definition" />
</xsl:template>
<!-- Head is type, number, title -->  <!-- GENERALIZE -->
<xsl:template match="definition|axiom|conjecture|principle" mode="head">
    <h5 class="heading">
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
        <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
        <xsl:if test="title">
            <span class="title"><xsl:apply-templates select="title" /></span>
        </xsl:if>
    </h5>
</xsl:template>
<!-- Body is just the statement -->
<!-- For definitions, we also process any notation                -->
<!-- The other environments should not use the notation construct -->
<xsl:template match="definition|axiom|conjecture|principle" mode="body">
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="notation" />
</xsl:template>
<!-- No posterior  -->
<xsl:template match="definition|axiom|conjecture|principle" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="definition|axiom|conjecture|principle" mode="environment-element">
    <xsl:text>article</xsl:text>
</xsl:template>
<xsl:template match="definition|axiom|conjecture|principle" mode="environment-class">
    <xsl:text>definition-like</xsl:text>
</xsl:template>


<!-- Theorems, etc. -->
<!-- Customizable as hidden    -->
<!-- A statement with proof -->
<xsl:template match="theorem|corollary|lemma|proposition|claim|fact" mode="is-hidden">
    <xsl:value-of select="$html.knowl.theorem" />
</xsl:template>
<!-- Head is type, number, title -->  <!-- GENERALIZE -->
<xsl:template match="theorem|corollary|lemma|proposition|claim|fact" mode="head">
    <h5 class="heading">
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
        <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
        <xsl:if test="title">
            <span class="title"><xsl:apply-templates select="title" /></span>
        </xsl:if>
    </h5>
</xsl:template>
<!-- Body is just the statement -->
<xsl:template match="theorem|corollary|lemma|proposition|claim|fact" mode="body">
    <xsl:apply-templates select="statement" />
</xsl:template>
<!-- Posterior is just the proof -->
<xsl:template match="theorem|corollary|lemma|proposition|claim|fact" mode="posterior">
    <xsl:apply-templates select="proof" />
</xsl:template>
<!-- HTML, CSS -->
<xsl:template match="theorem|corollary|lemma|proposition|claim|fact" mode="environment-element">
    <xsl:text>article</xsl:text>
</xsl:template>
<xsl:template match="theorem|corollary|lemma|proposition|claim|fact" mode="environment-class">
    <xsl:text>theorem-like</xsl:text>
</xsl:template>

<!-- Proofs, etc -->
<!-- Hints, Answers, Solutions (on exercises)  -->
<!-- Proofs customizable as hidden             -->
<!-- Help with exercises are always are hidden -->
<!-- Notes on references always are hidden     -->
<!-- All subsidiary to some other environment  -->
<!-- TODO: need to split out solutions, etc -->
<xsl:template match="proof" mode="is-hidden">
    <xsl:value-of select="$html.knowl.proof" />
</xsl:template>
<xsl:template match="hint|answer|solution|note" mode="is-hidden">
    <xsl:text>yes</xsl:text>
</xsl:template>
<!-- Head is just the type               -->
<!-- We do not ask for a number or title -->
<!-- TODO: Maybe this should change      -->
<xsl:template match="proof|hint|answer|solution|note" mode="head">
    <h5 class="heading">
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
    </h5>
</xsl:template>
<!-- Body is everything (no title?) -->
<xsl:template match="proof|hint|answer|solution|note" mode="body">
    <xsl:apply-templates />
</xsl:template>
<!-- No posterior  -->
<xsl:template match="proof|hint|answer|solution|note" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="proof|hint|answer|solution|note" mode="environment-element">
    <xsl:text>article</xsl:text>
</xsl:template>
<xsl:template match="proof|hint|answer|solution|note" mode="environment-class">
    <xsl:choose>
        <xsl:when test="$html.knowl.proof='yes'">
            <xsl:text>hiddenproof</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>proof</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- BELOW NOT ADAPTED TO ENVIRONMENTS/KNOWLS -->

<!-- Exercise Group -->
<!-- We interrupt a list of exercises with short commentary, -->
<!-- typically instructions for a list of similar exercises  -->
<!-- Commentary goes in an introduction and/or conclusion    -->
<xsl:template match="exercisegroup">
    <div class="exercisegroup">
        <xsl:apply-templates />
    </div>
</xsl:template>

<!-- Exercise, inline or in exercises section -->
<xsl:template match="exercise">
    <xsl:variable name="xref">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <xsl:variable name="statement-visible">
        <xsl:value-of select="$exercise.text.statement='yes'" />
    </xsl:variable>
    <xsl:variable name="hint-visible">
        <xsl:value-of select="$exercise.text.hint='yes'" />
    </xsl:variable>
    <xsl:variable name="answer-visible">
        <xsl:value-of select="$exercise.text.answer='yes'" />
    </xsl:variable>
    <xsl:variable name="solution-visible">
        <xsl:value-of select="$exercise.text.solution='yes'" />
    </xsl:variable>
    <article class="exercise-like" id="{$xref}">
        <h5 class="heading">
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
        <xsl:text> </xsl:text>
        <span class="codenumber"><xsl:apply-templates select="." mode="origin-id" /></span>
        <xsl:if test="title">
            <xsl:text> </xsl:text>
            <span class="title"><xsl:apply-templates select="title" /></span>
        </xsl:if>
        </h5>
        <!-- Order enforced: statement, hint, answer, solution -->
        <xsl:if test="$statement-visible='true'">
            <xsl:apply-templates select="statement"/>
        </xsl:if>
        <xsl:if test="$hint-visible='true'">
            <xsl:apply-templates select="hint"/>
        </xsl:if>
        <xsl:if test="$answer-visible='true'">
            <xsl:apply-templates select="answer"/>
        </xsl:if>
        <xsl:if test="$solution-visible='true'">
            <xsl:apply-templates select="solution"/>
        </xsl:if>
    </article>
</xsl:template>

<xsl:template match="exercise/hint|exercise/answer|exercise/solution">
    <b><xsl:comment>Style me</xsl:comment><xsl:apply-templates select="." mode="type-name" /></b>
    <xsl:text>. </xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- ################# -->
<!-- Knowl Manufacture -->
<!-- ################# -->

<!-- Two types of knowls:                                          -->
<!-- "xref": the content that is shown to a reader via a click     -->
<!--    typically with header info, since clickable may be opaque  -->
<!--    This content is the same as the "visible" content, but     -->
<!--    without any kind of identification (ie an "id" attribute)  -->
<!--    eg, no title information in clickable                      -->
<!-- "hidden": content that is born in a knowl, hidden at creation -->
<!--    typically without header, since clickable will have more   -->
<!--    eg, a hidden Example will have title visible               -->

<!-- The directory of knowls that are cross-references -->
<!-- is hard-coded here for consistency.  The filetype -->
<!-- *.html so recognized as OK by web servers         -->
<xsl:template match="*" mode="xref-knowl-filename">
    <xsl:text>./knowl/</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>.html</xsl:text>
</xsl:template>

<!-- Hidden knowls are embedded on the page in a   -->
<!-- div that MathJax is told to ignore.  That div -->
<!-- needs and id for the knowl to locate it       -->
<xsl:template match="*" mode="hidden-knowl-id">
    <xsl:text>hk-</xsl:text>  <!-- "hidden-knowl" -->
    <xsl:apply-templates select="." mode="internal-id" />
</xsl:template>


<!-- Knowls for cross-reference targets -->
<!-- (1) have a context link   -->
<!-- (2) live in a file        -->
<!-- (3) have no id info       -->
<!-- (4) Just the body, since  -->
<!-- head is part of clickable -->
<xsl:template match="*" mode="xref-knowl-factory">
    <xsl:variable name="knowl-file">
        <xsl:apply-templates select="." mode="xref-knowl-filename" />
    </xsl:variable>
    <exsl:document href="{$knowl-file}" method="html">
        <xsl:call-template name="converter-blurb" />
        <xsl:variable name="element">
            <xsl:apply-templates select="." mode="environment-element" />
        </xsl:variable>
        <xsl:element name="{$element}">
            <xsl:attribute name="class">
               <xsl:apply-templates select="." mode="environment-class" />
            </xsl:attribute>
            <xsl:apply-templates select="." mode="head" />
            <xsl:apply-templates select="." mode="body" />
        </xsl:element>
        <xsl:apply-templates select="." mode="posterior" />
        <div class="context-link" style="text-align:right;">
            <xsl:element name="a">
                <xsl:attribute name="href">
                    <xsl:apply-templates select="." mode="url" />
                </xsl:attribute>
                <xsl:text>(in-context)</xsl:text>
            </xsl:element>
        </div>
    </exsl:document>
</xsl:template>

<!-- Knowls for born-hidden content -->
<!-- (1) context link is useless    -->
<!-- (2) live in a div              -->
<!-- (3) have no id info in content -->
<!-- (4) only have a body           -->
<xsl:template match="*" mode="hidden-knowl-factory">
    <xsl:element name="div">
        <!-- different id, for use by the knowl mechanism -->
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="hidden-knowl-id" />
        </xsl:attribute>
        <!-- not "visibility,"" display:none takes no space -->
        <xsl:attribute name="style">
            <xsl:text>display: none;</xsl:text>
        </xsl:attribute>
        <!-- Do not process the contents on page load, wait until it is exposed -->
        <xsl:attribute name="class">
            <xsl:text>tex2jax_ignore</xsl:text>
        </xsl:attribute>
        <xsl:variable name="element">
            <xsl:apply-templates select="." mode="environment-element" />
        </xsl:variable>
        <xsl:element name="{$element}">
            <xsl:attribute name="class">
               <xsl:apply-templates select="." mode="environment-class" />
            </xsl:attribute>
            <xsl:apply-templates select="." mode="body" />
        </xsl:element>
    </xsl:element>
  </xsl:template>




<!-- ########### -->
<!-- HTML Markup -->
<!-- ########### -->

<!-- Wrap generic paragraphs in p tag -->
<xsl:template match="p">
<p><xsl:apply-templates /></p>
</xsl:template>

<!-- Lists -->

<!-- Utility templates to translate MBX              -->
<!-- enumeration style to HTML list-style-type       -->
<!-- NB: this is currently inferior to latex version -->
<!-- NB: all pre-, post-formatting is lost           -->
<xsl:template match="*" mode="html-ordered-list-label">
   <xsl:choose>
        <xsl:when test="contains(@label,'1')">decimal</xsl:when>
        <xsl:when test="contains(@label,'a')">lower-alpha</xsl:when>
        <xsl:when test="contains(@label,'A')">upper-alpha</xsl:when>
        <xsl:when test="contains(@label,'i')">lower-roman</xsl:when>
        <xsl:when test="contains(@label,'I')">upper-roman</xsl:when>
        <xsl:when test="@label=''">none</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: ordered list label not found or not recognized</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="html-unordered-list-label">
   <xsl:choose>
        <xsl:when test="@label='disc'">disc</xsl:when>
        <xsl:when test="@label='circle'">circle</xsl:when>
        <xsl:when test="@label='square'">square</xsl:when>
        <xsl:when test="@label=''">none</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: unordered list label not found or not recognized</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Utility template to translate ordered list    -->
<!-- level to HTML list-style-type                 -->
<!-- This mimics LaTeX's choice and order:         -->
<!-- arabic, lower alpha, lower roman, upper alpha -->
<xsl:template match="*" mode="html-ordered-list-label-default">
    <xsl:variable name="level">
        <xsl:apply-templates select="." mode="ordered-list-level" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$level='0'">decimal</xsl:when>
        <xsl:when test="$level='1'">lower-alpha</xsl:when>
        <xsl:when test="$level='2'">lower-roman</xsl:when>
        <xsl:when test="$level='3'">upper-alpha</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: ordered list is more than 4 levels deep (<xsl:value-of select="$level" /> levels)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Utility template to translate unordered    -->
<!-- list level to HTML list-style-type         -->
<!-- This is similar to Firefox default choices -->
<!-- but different in the fourth slot           -->
<!-- disc, circle, square, disc                 -->
<xsl:template match="*" mode="html-unordered-list-label-default">
    <xsl:variable name="level">
        <xsl:apply-templates select="." mode="unordered-list-level" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$level='0'">disc</xsl:when>
        <xsl:when test="$level='1'">circle</xsl:when>
        <xsl:when test="$level='2'">square</xsl:when>
        <xsl:when test="$level='3'">disc</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: unordered list is more than 4 levels deep</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<xsl:template match="ol">
    <xsl:element name="ol">
        <xsl:attribute name="style">
            <xsl:text>list-style-type: </xsl:text>
            <xsl:choose>
                <xsl:when test="@label">
                    <xsl:apply-templates select="." mode="html-ordered-list-label" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="html-ordered-list-label-default" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates />
    </xsl:element>
</xsl:template>

<xsl:template match="ul">
    <xsl:element name="ul">
        <xsl:attribute name="style">
            <xsl:text>list-style-type: </xsl:text>
            <xsl:choose>
                <xsl:when test="@label">
                    <xsl:apply-templates select="." mode="html-unordered-list-label" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="html-unordered-list-label-default" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates />
    </xsl:element>
</xsl:template>

<!-- Pass-through list items            -->
<!-- Allow paragraphs in larger items,  -->
<!-- or just snippets for smaller items -->
<xsl:template match="li">
    <li>
        <xsl:apply-templates />
    </li>
</xsl:template>

<!-- ##################### -->
<!-- Multiple-column lists -->
<!-- ##################### -->

<!-- TODO: Accept top-level list label formatting in here -->
<!-- TODO: Protect for top-level use only -->

<!-- Note: ul, ol combined with "<xsl:copy>" led to namespace trouble -->

<!-- With cols specified, we form the list items with variable -->
<!-- widths then clear the floating property to resume         -->
<xsl:template match="ol[@cols]">
    <xsl:if test="@label">
        <xsl:message>MBX:WARNING: Custom labeling of multi-column lists not implemented</xsl:message>
    </xsl:if>
    <xsl:element name="ol">
        <xsl:apply-templates select="li" mode="variable-width">
            <xsl:with-param name="percent-width" select="98 div @cols" />
        </xsl:apply-templates>
    </xsl:element>
    <div style="clear:both;"></div>
</xsl:template>

<xsl:template match="ul[@cols]">
    <xsl:if test="@label">
        <xsl:message>MBX:WARNING: Custom labeling of multi-column lists not implemented</xsl:message>
    </xsl:if>
    <xsl:element name="ul">
        <xsl:apply-templates select="li" mode="variable-width">
            <xsl:with-param name="percent-width" select="98 div @cols" />
        </xsl:apply-templates>
    </xsl:element>
    <div style="clear:both;"></div>
</xsl:template>

<!-- Each list item needs styling independent of CSS -->
<xsl:template match="li" mode="variable-width">
    <xsl:param name="percent-width" />
    <xsl:element name="li">
        <xsl:attribute name="style">
            <xsl:text>width:</xsl:text><xsl:value-of select="$percent-width" /><xsl:text>%; float:left;</xsl:text>
        </xsl:attribute>
       <xsl:apply-templates />
    </xsl:element>
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
        <xsl:if test="$table.caption.position='above'">
            <xsl:apply-templates select="caption" />
        </xsl:if>
        <table class="center">
            <xsl:apply-templates select="*[not(self::caption)]" />
        </table>
        <xsl:if test="$table.caption.position='below'">
            <xsl:apply-templates select="caption" />
        </xsl:if>
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
</xsl:template>
<xsl:template match="tbody/row">
    <tr><xsl:apply-templates /></tr>
</xsl:template>
<!-- With a parent axis, get overrides easily? -->
<xsl:template match="thead/row/entry[descendant::tgroup]"><td align="{../../../@align}"><xsl:apply-templates /></td></xsl:template>
<xsl:template match="thead/row/entry" mode="hline"><td class="hline"><hr /></td></xsl:template>
<xsl:template match="tbody/row/entry[descendant::tgroup]"><td align="{../../../@align}"><xsl:apply-templates /></td></xsl:template>

<!-- td match in thead when tgroup tag is *not* used -->
<xsl:template match="thead/row/entry[not(descendant::tgroup)]">
  <!-- get the column *position* of the current entry, e.g 1st, 2nd, 3rd -->
  <xsl:variable name="columnPos">
    <xsl:value-of select="position()" />
  </xsl:variable>
  <!-- get the column *type* of the current entry, e.g left, center, right, decimal -->
  <xsl:variable name="columnType">
    <xsl:value-of select="(../../../coltypes/col[@align])[position()=$columnPos]/@align" />
  </xsl:variable>
  <!-- set up <td>...</td> -->
  <xsl:element name="td">
    <xsl:choose>
      <!-- when columnType is decimal we have to use
           <td style="center">CONTENTS</td>
                -->
        <xsl:when test="$columnType='decimal'">
            <xsl:attribute name="style">text-align:center</xsl:attribute>
            <xsl:apply-templates />
        </xsl:when>
        <!-- when columnType is *not* decimal <td text-align="$columnType"> -->
        <xsl:otherwise>
            <xsl:attribute name="style">text-align:<xsl:value-of select="$columnType"/></xsl:attribute>
            <!-- insert contents of <entry> -->
            <xsl:apply-templates />
        </xsl:otherwise>
    </xsl:choose>
  </xsl:element>
</xsl:template>

<!-- td match in tbody when tgroup tag is *not* used -->
<xsl:template match="tbody/row/entry[not(descendant::tgroup)]">
  <!-- get the column *position* of the current entry, e.g 1st, 2nd, 3rd -->
  <xsl:variable name="columnPos">
    <xsl:value-of select="position()" />
  </xsl:variable>
  <!-- get the column *type* of the current entry, e.g left, center, right, decimal -->
  <xsl:variable name="columnType">
    <xsl:value-of select="(../../../coltypes/col[@align])[position()=$columnPos]/@align" />
  </xsl:variable>
  <!-- set up <td>...</td> -->
  <xsl:element name="td">
    <xsl:choose>
      <!-- when columnType is decimal we have to use
           <td style="width:TOTALwidthEM">
                <span class="left" style="width:LENGTHofCELL+em">xxx</span>
           </td>
                -->
        <xsl:when test="$columnType='decimal'">
          <!-- store the cell value into the variable $cell -->
          <xsl:variable name="cell">
            <xsl:value-of select="."/>
          </xsl:variable>
          <!-- grab the format, e.g 2.4 or 3.5, etc-->
          <xsl:variable name="format">
            <xsl:value-of select="(../../../coltypes/col[@align])[position()=$columnPos]/@format"/>
          </xsl:variable>
          <!-- the format attribute will be format="2.4", for example,
               so we need to grab the 2 and the 4 -->
          <xsl:variable name="integerPart">
            <xsl:value-of select="substring-before($format,'.')"/>
          </xsl:variable>
          <xsl:variable name="fractionalPart">
            <xsl:value-of select="substring-after($format,'.')"/>
          </xsl:variable>
          <!-- we need the length of the string *after* the decimal place 
               a bit of adjustment when the cell has *no* decimal -->
          <xsl:variable name="fractionalPartLength">
            <xsl:choose>
              <xsl:when test="contains($cell,'.')">
                  <xsl:value-of select="string-length(substring-after($cell,'.'))"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>-.5</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <!-- form <td style="width:TOTALwidthEM"> -->
          <xsl:attribute name="style">width:<xsl:value-of select="$integerPart+$fractionalPart+.5" />ex</xsl:attribute>
          <!-- form <span class="left" style="width:LENGTHofCELLem">XXX</span> -->
          <xsl:element name="span">
            <xsl:attribute name="class">left</xsl:attribute>
            <xsl:attribute name="style">width:<xsl:value-of select="$integerPart+.5+$fractionalPartLength"/>ex</xsl:attribute>
            <xsl:text>\(</xsl:text><xsl:value-of select="$cell"/><xsl:text>\)</xsl:text>
          </xsl:element>
        </xsl:when>
        <!-- when columnType is *not* decimal <td text-align="$columnType"> -->
        <xsl:otherwise>
            <xsl:attribute name="style">text-align:<xsl:value-of select="$columnType"/></xsl:attribute>
            <!-- insert contents of <entry> -->
            <xsl:apply-templates />
        </xsl:otherwise>
    </xsl:choose>
  </xsl:element>
</xsl:template>

<!-- Caption of a figure or table                  -->
<!-- All the relevant information is in the parent -->
<xsl:template match="caption">
    <figcaption>
        <span class="heading">
            <xsl:apply-templates select=".." mode="type-name"/>
        </span>
        <span class="codenumber">
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

<!-- TODO: trash escaping by building content with hex nbsp -->

<!-- A cross-reference has a visual component,      -->
<!-- formed above, and a realization as a hyperlink -->
<!-- or as a knowl.  Default is a link              -->
<xsl:template match="*" mode="xref-hyperlink">
    <xsl:param name="content" />
    <xsl:element name="a">
        <xsl:attribute name="href">
            <xsl:apply-templates select="." mode="url" />
        </xsl:attribute>
        <xsl:value-of  disable-output-escaping="yes" select="$content" />
    </xsl:element>
</xsl:template>
<!-- Now, those items that are knowls -->
<!-- TODO: proof|figure|table|exercise|me|men|mrow (hint|answer|solution|note) -->
<xsl:template match="fn|biblio|example|remark|theorem|corollary|lemma|proposition|claim|fact|definition|axiom|conjecture|principle" mode="xref-hyperlink">
    <xsl:param name="content" />
    <xsl:element name="a">
        <xsl:attribute name="knowl">
            <xsl:apply-templates select="." mode="xref-knowl-filename" />
        </xsl:attribute>
        <!-- TODO: check if this "knowl-id" is needed, knowl.js implies it is -->
        <xsl:attribute name="knowl-id">
            <xsl:text>xref-</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:attribute>
        <xsl:attribute name="title">
            <xsl:apply-templates select="title" />
        </xsl:attribute>
        <xsl:value-of  disable-output-escaping="yes" select="$content" />
    </xsl:element>
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

<!-- Acronyms (no-op) -->
<xsl:template match="acro">
    <abbr class="acronym"><xsl:comment>Style me</xsl:comment><xsl:apply-templates /></abbr>
</xsl:template>

<!-- Emphasis -->
<xsl:template match="em">
    <em><xsl:apply-templates /></em>
</xsl:template>

<!-- Copyright symbol -->
<xsl:template match="copyright">
    <xsl:text>&#169;</xsl:text>
</xsl:template>

<!-- exempli gratia, for example -->
<xsl:template match="eg">
    <xsl:text>e.g.</xsl:text>
</xsl:template>

<!-- id est, in other words -->
<xsl:template match="ie">
    <xsl:text>i.e.</xsl:text>
</xsl:template>

<!-- et cetera -->
<xsl:template match="etc">
    <xsl:text>etc.</xsl:text>
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
<!-- NB: "code-block" class otherwise -->
<xsl:template match="c">
    <tt class="code-inline"><xsl:apply-templates /></tt>
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

<!-- Chunks of Pre-Formatted Text                -->
<!-- 100% analogue of LaTeX's verbatim           -->
<!-- environment or HTML's <pre> element         -->
<!-- Text is massaged just like Sage input code  -->
<xsl:template match="pre">
    <xsl:element name="pre">
        <xsl:call-template name="sanitize-sage">
            <xsl:with-param name="raw-sage-code" select="." />
        </xsl:call-template>
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
<!-- We need * (no numbers, md), and plain (numbers, mdn) variants            -->
<xsl:template match="md/intertext">
    <xsl:text>\end{align*}&#xa;</xsl:text>
    <p>
    <xsl:apply-templates />
    </p>
    <xsl:text>\begin{align*}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="mdn/intertext">
    <xsl:text>\end{align}&#xa;</xsl:text>
    <p>
    <xsl:apply-templates />
    </p>
    <xsl:text>\begin{align}&#xa;</xsl:text>
</xsl:template>

<!-- Demonstrations -->
<!-- A simple page with no constraints -->
<xsl:template match="demonstration">
    <xsl:variable name="url"><xsl:apply-templates select="." mode="internal-id" />.html</xsl:variable>
    <a href="{$url}" target="_blank" class="link">
        <xsl:apply-templates select="." mode="title-full" />
    </a>
    <xsl:apply-templates select="." mode="simple-page-wrap" >
        <xsl:with-param name="content">
            <xsl:apply-templates />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- Sage Cells -->
<!-- TODO: make hidden autoeval cells link against sage-compute cells -->

<!-- An abstract named template accepts input text and   -->
<!-- output text, then wraps it for the Sage Cell Server -->
<!-- TODO: consider showing output in green span (?),    -->
<!-- presently output is dropped as computable           -->
<xsl:template name="sage-active-markup">
    <xsl:param name="in" />
    <xsl:param name="out" />
    <div class="sage-compute">
    <script type="text/x-sage">
        <xsl:value-of select="$in" />
    </script>
    </div>
</xsl:template>

<!-- An abstract named template accepts input text   -->
<!-- and provides the display class, so untouchable  -->
<xsl:template name="sage-display-markup">
    <xsl:param name="in" />
    <div class="sage-display">
    <script type="text/x-sage">
        <xsl:value-of select="$in" />
    </script>
    </div>
</xsl:template>

<!-- Program Listings -->
<!-- Research:  http://softwaremaniacs.org/blog/2011/05/22/highlighters-comparison/           -->
<!-- From Google: downloadable, auto-detects languages, has hint-handlers                     -->
<!-- http://code.google.com/p/google-code-prettify/                                           -->
<!-- http://code.google.com/p/google-code-prettify/wiki/GettingStarted                        -->
<!-- See common file for more on language handlers, and "language-prettify" template          -->
<!-- Coordinate with disabling in Sage Notebook production                                    -->
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
        <xsl:call-template name="converter-blurb" />
        <head>
            <title>
                <!-- Leading with initials is useful for small tabs -->
                <xsl:if test="//docinfo/initialism">
                    <xsl:apply-templates select="//docinfo/initialism" />
                    <xsl:text> </xsl:text>
                </xsl:if>
            <xsl:apply-templates select="." mode="title-simple" />
            </title>
            <meta name="Keywords" content="Authored in MathBook XML" />
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
            <!-- the first class controls the default icon -->
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="/mathbook/book">mathbook-book</xsl:when>
                    <xsl:when test="/mathbook/article">mathbook-article</xsl:when>
                </xsl:choose>
                <xsl:if test="$toc-level > 0">
                    <xsl:text> has-toc has-sidebar-left</xsl:text> <!-- note space, later add right -->
                </xsl:if>
            </xsl:attribute>
            <xsl:call-template name="latex-macros" />
             <header id="masthead">
                <div class="banner">
                        <div class="container">
                            <xsl:call-template name="brand-logo" />
                            <div class="title-container">
                                <h1 class="heading">
                                    <span class="title">
                                        <xsl:value-of select="$title" />
                                    </span>
                                    <xsl:if test="normalize-space($subtitle)">
                                        <span class="subtitle">
                                            <xsl:value-of select="$subtitle" />
                                        </span>
                                    </xsl:if>
                                </h1>
                                <p class="byline"><xsl:value-of select="$credits" /></p>
                            </div>
                        </div>
                </div>
            <xsl:apply-templates select="." mode="primary-navigation" />
            </header>
            <div class="page">
                <xsl:apply-templates select="." mode="sidebars" />
                <main class="main">
                    <div id="content" class="mathbook-content">
                        <xsl:copy-of select="$content" />
                    </div>
                </main>
            </div>
        <xsl:apply-templates select="/mathbook/docinfo/analytics" />
        </xsl:element>
    </html>
    </exsl:document>
</xsl:template>

<!-- A minimal individual page:                              -->
<!-- Inputs:                                                 -->
<!--     * content (exclusive of banners, etc)               -->
<!-- Maybe a page title -->
<xsl:template match="*" mode="simple-page-wrap">
    <xsl:param name="content" />
    <xsl:variable name="url"><xsl:apply-templates select="." mode="internal-id" />.html</xsl:variable>
    <xsl:message>URL: <xsl:value-of select="$url" /></xsl:message>
    <exsl:document href="{$url}" method="html">
    <!-- Need to be careful for format of this initial string     -->
    <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html>&#xa;</xsl:text>
    <html> <!-- lang="", and/or dir="rtl" here -->
        <xsl:call-template name="converter-blurb" />
        <head>
            <meta name="Keywords" content="Authored in MathBook XML" />
            <meta name="viewport" content="width=device-width,  initial-scale=1.0, user-scalable=0, minimum-scale=1.0, maximum-scale=1.0" />
            <xsl:call-template name="mathjax" />
            <xsl:call-template name="sagecell" />
            <xsl:call-template name="knowl" />
            <xsl:call-template name="fonts" />
            <xsl:call-template name="css" />
        </head>
        <!-- TODO: needs some padding etc -->
        <body>
            <xsl:copy-of select="$content" />
            <xsl:apply-templates select="/mathbook/docinfo/analytics" />
        </body>
    </html>
    </exsl:document>
</xsl:template>

<!-- ################# -->
<!-- Navigational Aids -->
<!-- ################# -->

<!-- Prev/Up/Next URL's -->
<!-- The "tree" versions are simpler, though less natural for a reader -->
<!-- They often return empty and require the use of the Up button      -->
<!-- The "linear" versions are breadth-first search, and so mimic      -->
<!-- the way a reader would encounter the sections in a (linear) book  -->

<!-- TODO: perhaps isolate logic to return nodes and put into "common" -->

<!-- Check if the XML tree has a preceding/following/parent node -->
<!-- Then check if it is a document node (structural)            -->
<!-- If so, compute the URL for the node                         -->
<!-- NB: tree urls maybe enabled as a processing option          -->
<xsl:template match="*" mode="previous-tree-url">
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

<xsl:template match="*" mode="next-tree-url">
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

<!-- Create the URL of the parent document node    -->
<!-- Parent always exists, since the               -->
<!-- structural check fails at <mathbook>          -->
<!-- Identical in tree/linear schemes, up is up    -->
<xsl:template match="*" mode="up-url">
    <xsl:if test="parent::*">
        <xsl:variable name="parent" select="parent::*[1]" />
        <xsl:variable name="structural">
            <xsl:apply-templates select="$parent" mode="is-structural" />
        </xsl:variable>
        <xsl:if test="$structural='true'">
            <xsl:apply-templates select="$parent" mode="url" />
        </xsl:if>
    </xsl:if>
    <!-- will be empty precisely at children of <mathbook> -->
</xsl:template>

<!-- Next Linear URL -->
<!-- Breadth-first search, try to descend into first summary link -->
<!-- Else, look sideways for next structural sibling              -->
<!-- Else, go up to parent and look sideways                      -->
<!-- Else done and return empty url                               -->
<xsl:template match="*" mode="next-linear-url">
    <xsl:variable name="summary">
        <xsl:apply-templates select="." mode="is-summary" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$summary='true'">
            <!-- Descend once, will always have a child that is structural -->
            <xsl:variable name="first-structural-child" select="*[not(self::title or self::subtitle or self::todo or self::introduction or self::conclusion or self::titlepage or self::author)][1]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$first-structural-child" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='false'">
                <xsl:message>MBX:ERROR: descending into first node of a summary page (<xsl:value-of select="local-name($first-structural-child)" />) that is non-structural</xsl:message>
            </xsl:if>
            <xsl:apply-templates select="$first-structural-child" mode="url" />
        </xsl:when>
        <xsl:otherwise>
            <!-- try going sideways, which climbs up the tree recursively -->
            <xsl:apply-templates select="." mode="next-sideways-url" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Recursively look sideways to the right, else up     -->
<!-- <mathbook> is not structural, so halt looking there -->
<xsl:template match="*" mode="next-sideways-url">
    <xsl:variable name="url">
        <xsl:if test="following-sibling::*">
            <xsl:variable name="following" select="following-sibling::*[1]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$following" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='true'">
                <!-- A normal sibling following -->
                <xsl:apply-templates select="$following" mode="url" />
            </xsl:if>
        </xsl:if>
        <!-- could be empty here-->
    </xsl:variable>
    <xsl:value-of select="$url" /> <!-- no harm if empty -->
    <xsl:if test="$url=''">
        <!-- Try going up and then sideways                           -->
        <!-- parent always exists, since <mathbook> is non-structural -->
        <xsl:variable name="parent" select="parent::*[1]" />
        <xsl:variable name="structural">
            <xsl:apply-templates select="$parent" mode="is-structural" />
        </xsl:variable>
        <xsl:if test="$structural='true'">
            <!-- Up a level, so try looking sideways again -->
            <xsl:apply-templates select="$parent" mode="next-sideways-url" />
        </xsl:if>
        <!-- otherwise we are off the top and quit with an empty url -->
    </xsl:if>
</xsl:template>

<!-- Look sideways to the left                                  -->
<!-- If present, move there and descend right branches          -->
<!-- If nothing there, move up once                             -->
<!-- <mathbook> is not structural, so halt if we go up to there -->
<xsl:template match="*" mode="previous-linear-url">
    <xsl:variable name="url">
        <xsl:if test="preceding-sibling::*">
            <xsl:variable name="preceding" select="preceding-sibling::*[1]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$preceding" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='true'">
                <!-- A normal sibling precedin, result is just a sentinel-->
                <xsl:apply-templates select="$preceding" mode="url" />
            </xsl:if>
        </xsl:if>
        <!-- could be empty here -->
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$url=''">
            <!-- Go up to parent and get the URL there (not recursive)    -->
            <!-- parent always exists, since <mathbook> is non-structural -->
            <xsl:variable name="parent" select="parent::*[1]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$parent" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='true'">
                <xsl:apply-templates select="$parent" mode="url" />
            </xsl:if>
            <!-- otherwise we are off the top and quit with an empty url -->
        </xsl:when>
        <xsl:otherwise>
            <!-- found a preceding sibling, so descend right branches to a leaf -->
            <xsl:apply-templates select="preceding-sibling::*[1]" mode="previous-descent-url"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Descend recursively through summary pages -->
<!-- to a leaf (content) and get URL           -->
<xsl:template match="*" mode="previous-descent-url" >
    <xsl:variable name="summary">
        <xsl:apply-templates select="." mode="is-summary" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$summary='false'">
            <xsl:apply-templates select="." mode="url" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="last-structural-child" select="*[not(self::title or self::subtitle or self::todo or self::introduction or self::conclusion)][last()]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$last-structural-child" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='false'">
                <xsl:message>MBX:ERROR: descending into last node of a summary page (<xsl:value-of select="local-name($last-structural-child)" />) that is non-structural</xsl:message>
            </xsl:if>
            <xsl:apply-templates select="$last-structural-child" mode="previous-descent-url" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!--                     -->
<!-- Navigation Sections -->
<!--                     -->

<!-- Button code, <a href=""> when active -->
<!-- <span> with "disabled" class otherwise -->
<xsl:template match="*" mode="previous-button">
    <xsl:variable name="previous-url">
        <xsl:apply-templates select="." mode="previous-linear-url" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$previous-url!=''">
            <xsl:element name="a">
                <xsl:attribute name="class">previous-button toolbar-item button</xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:value-of select="$previous-url" />
                </xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'previous'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="span">
                <xsl:attribute name="class">previous-button button toolbar-item disabled</xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'previous'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="next-button">
    <xsl:variable name="next-url">
        <xsl:apply-templates select="." mode="next-linear-url" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$next-url!=''">
            <xsl:element name="a">
                <xsl:attribute name="class">next-button button toolbar-item</xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:value-of select="$next-url" />
                </xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'next'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="span">
                <xsl:attribute name="class">next-button button toolbar-item disabled</xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'next'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="up-button">
    <xsl:variable name="up-url">
        <xsl:apply-templates select="." mode="up-url" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$up-url!=''">
            <xsl:element name="a">
                <xsl:attribute name="class">up-button button toolbar-item</xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:value-of select="$up-url" />
                </xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'up'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="span">
                <xsl:attribute name="class">up-button button disabled toolbar-item</xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'up'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Primary Navigation Panel         -->
<!-- For smaller modes, like phones   -->
<!-- Includes ToC, Annotation buttons -->
<xsl:template match="*" mode="primary-navigation">
    <nav id="primary-navbar">
        <div class="container">
            <!--  -->
            <div class="navbar-top-buttons">
                <button class="sidebar-left-toggle-button button active">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'toc'" />
                    </xsl:call-template>
                </button>
                <div class="tree-nav toolbar toolbar-divisor-3">
                    <xsl:apply-templates select="." mode="previous-button" />
                    <xsl:apply-templates select="." mode="up-button" />
                    <xsl:apply-templates select="." mode="next-button" />
                </div>
                <button class="sidebar-right-toggle-button button active">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'annotations'" />
                    </xsl:call-template>
                </button>
            </div>
            <!--  -->
            <div class="navbar-bottom-buttons toolbar toolbar-divisor-4">
                <button class="sidebar-left-toggle-button button toolbar-item active">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'toc'" />
                    </xsl:call-template>
                </button>
                <xsl:apply-templates select="." mode="previous-button" />
                <xsl:apply-templates select="." mode="up-button" />
                <xsl:apply-templates select="." mode="next-button" />
                <!-- unused, increment to  toolbar-divisor-5  above
                <button class="sidebar-right-toggle-button button toolbar-item active">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'annotations'" />
                    </xsl:call-template>
                </button> -->
            </div>
            <!--  -->
        </div>
    </nav>
</xsl:template>


<!-- Sidebars -->
<!-- Two HTML aside's for ToC (left), Annotations (right)       -->
<!-- Need to pass node down into "toc-items", which is per-page -->
<xsl:template match="*" mode="sidebars">
    <aside id="sidebar-left" class="sidebar">
        <div class="sidebar-content">
            <nav id="toc">
                 <xsl:apply-templates select="." mode="toc-items" />
            </nav>
            <div class="extras">
                <nav>
                    <xsl:if test="/mathbook/docinfo/feedback">
                        <xsl:call-template name="feedback-link" />
                    </xsl:if>
                    <xsl:call-template name="mathbook-link" />
                </nav>
            </div>
        </div>
    </aside>
    <!-- Content here appears in odd places if turned sidebar is turned off
        <aside id="sidebar-right" class="sidebar">
            <div class="sidebar-content">Mock right sidebar content</div>
        </aside> -->
</xsl:template>

<!-- Table of Contents Contents (Items) -->
<!-- Includes "active" class for enclosing outer node              -->
<!-- Node set equality and subset based on unions of subtrees, see -->
<!-- http://www.xml.com/cookbooks/xsltckbk/solution.csp?day=5      -->
<!-- Displayed text is simple titles                               -->
<!-- TODO: split out inner link formation, outer link formation? -->
<xsl:template match="*" mode="toc-items">
    <xsl:if test="$toc-level > 0">
        <!-- Subtree for page this sidebar will adorn -->
        <xsl:variable name="this-page-node" select="descendant-or-self::*" />
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
                <xsl:variable name="outer-internal">
                    <xsl:apply-templates select="." mode="internal-id" />
                </xsl:variable>
                <!-- The link itself -->
                <h2 class="{$class}">
                    <xsl:element name="a">
                        <xsl:attribute name="href">
                            <xsl:value-of select="$outer-url" />
                        </xsl:attribute>
                        <xsl:if test="1 > html.chunk.level">
                            <xsl:attribute name="data-scroll">
                                <xsl:value-of select="$outer-internal" />
                            </xsl:attribute>
                        </xsl:if>
                        <xsl:variable name="num"><xsl:apply-templates select="." mode="number" /></xsl:variable>
                        <xsl:if test="$num!=''">
                            <span class="codenumber"><xsl:value-of select="$num" /></span>
                        </xsl:if>
                        <span class="title">
                            <xsl:apply-templates select="." mode="title-simple" />
                        </span>
                    </xsl:element>
                </h2>
                <xsl:if test="$toc-level > 1">
                    <ul>
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
                            <xsl:variable name="inner-internal">
                                <xsl:apply-templates select="." mode="internal-id" />
                            </xsl:variable>
                            <li>
                                <xsl:element name="a">
                                    <xsl:attribute name="href">
                                        <xsl:value-of select="$inner-url" />
                                    </xsl:attribute>
                                    <xsl:if test="2 > html.chunk.level">
                                        <xsl:attribute name="data-scroll">
                                            <xsl:value-of select="$outer-internal" />
                                        </xsl:attribute>
                                    </xsl:if>
                                    <!-- Add if an "active" class if this is where we are -->
                                    <xsl:if test="count($this-page-node|$inner-node) = count($inner-node)">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <xsl:apply-templates select="." mode="title-simple" />
                                </xsl:element>
                            </li>
                        </xsl:if>
                    </xsl:for-each>
                    </ul>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:if>
</xsl:template>

<!-- Feedback Button goes at the bottom (in "extras") -->
<!-- Text from docinfo, or localized string           -->
<!-- Target URL from docinfo                          -->
<xsl:template name="feedback-link">
    <xsl:variable name="feedback-text">
        <xsl:choose>
            <xsl:when test="/mathbook/docinfo/feedback/text">
                <xsl:apply-templates select="/mathbook/docinfo/feedback/text" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'feedback'" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Possibly an empty URL -->
    <xsl:variable name="feedback-url">
        <xsl:apply-templates select="/mathbook/docinfo/feedback/url" />
    </xsl:variable>
    <a class="feedback-link" href="{$feedback-url}">
        <xsl:value-of select="$feedback-text" />
    </a>
</xsl:template>

<!-- Branding in "extras", mostly hard-coded -->
<xsl:template name="mathbook-link">
    <a class="mathbook-link" href="http://mathbook.pugetsound.edu">
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'authored'" />
        </xsl:call-template>
        <xsl:text> MathBook&#xa0;XML</xsl:text>
    </a>
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
<!-- extpfeil.js provides extensible arrows: \xmapsto, \xtofrom -->
<!--   \xtwoheadrightarrow, \xtwoheadleftarrow, \xlongequal     -->
<!--   equivalent to the LaTeX package of the same name         -->
<!-- Autobold extension is critical for captions (bold'ed) that -->
<!-- have mathematics in them (suggested by P. Krautzberger)    -->
<xsl:template name="mathjax">
<script type="text/x-mathjax-config">
MathJax.Hub.Config({
    tex2jax: {
        inlineMath: [['\\(','\\)']]
    },
    TeX: {
        extensions: ["AMSmath.js", "AMSsymbols.js", "extpfeil.js", "autobold.js"],
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
    <xsl:if test="//m[contains(text(),'sfrac')] or //md[contains(text(),'sfrac')] or //me[contains(text(),'sfrac')] or //mrow[contains(text(),'sfrac')]">
    /* support for the sfrac command in MathJax (Beveled fraction)
        see: https://github.com/mathjax/MathJax-docs/wiki/Beveled-fraction-like-sfrac,-nicefrac-bfrac */
MathJax.Hub.Register.StartupHook("TeX Jax Ready",function () {
  var MML = MathJax.ElementJax.mml,
      TEX = MathJax.InputJax.TeX;

  TEX.Definitions.macros.sfrac = "myBevelFraction";

  TEX.Parse.Augment({
    myBevelFraction: function (name) {
      var num = this.ParseArg(name),
          den = this.ParseArg(name);
      this.Push(MML.mfrac(num,den).With({bevelled: true}));
    }
  });
});
    </xsl:if>
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
    <!-- condition first on toc present? -->
    <script src="{$html.js.server}/mathbook/js/lib/jquery.sticky.js" ></script>
    <script src="{$html.js.server}/mathbook/js/lib/jquery.espy.min.js"></script>
    <script src="{$html.js.server}/mathbook/js/Mathbook.js"></script>
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
    <link href="{$html.css.server}/mathbook/stylesheets/{$html.css.file}" rel="stylesheet" type="text/css" />
    <link href="http://aimath.org/mathbook/mathbook-add-on.css" rel="stylesheet" type="text/css" />
    <style>/*for decimal alignment */
      span.left { float: left; text-align: right; }
/* table styles */
table thead { border-top: 2px solid #000; }
table tbody { border-top: 1px solid #000; 
border-bottom: 2px solid #000; 
</style>
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
<!-- TODO: separate url and image, now need both or neither -->
<!-- should allow specifying just URL and get default image -->
<xsl:template name="brand-logo">
    <xsl:choose>
        <xsl:when test="/mathbook/docinfo/brandlogo">
            <a id="logo-link" href="{/mathbook/docinfo/brandlogo/@url}" target="_blank" >
                <img src="{/mathbook/docinfo/brandlogo/@source}" />
            </a>
        </xsl:when>
        <xsl:otherwise>
            <a id="logo-link" href="" />
        </xsl:otherwise>
    </xsl:choose>
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
<!-- 2014/08/14: remove knowl-link-factory at the same time -->
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

<!-- Only used by <cite> above, so can be removed at same time -->
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

</xsl:stylesheet>
