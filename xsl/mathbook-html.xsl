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

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
    <!-- xmlns="http://www.w3.org/1999/xhtml" -->
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

<xsl:import href="./mathbook-common.xsl" />

<!-- Base 64 Library, MIT License -->
<!-- Used to encode WeBWork problems           -->
<!-- Will also read  base64_binarydatamap.xml  -->
<xsl:include href="./xslt_base64/base64.xsl"/>

<!-- Routines specific to converting a "webwork"  -->
<!-- element into a problem in the PGML language -->
<xsl:include href="./mathbook-webwork-pg.xsl" />

<!-- Intend output for rendering by a web browser -->
<xsl:output method="xml" encoding="utf-8"/>

<!-- Parameters -->
<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!-- See more generally applicable parameters in mathbook-common.xsl file     -->

<!-- Content as Knowls -->
<!-- These parameters control if content is      -->
<!-- hidden in a knowl on first appearance       -->
<!-- The happens automatically sometimes,        -->
<!-- eg content of a footnote is always hidden   -->
<!-- Some things never are hidden,               -->
<!-- eg an entire section (too big),             -->
<!-- or a bibliographic item (pointless)         -->
<!-- These switches often control a whole group  -->
<!-- of similar items, for example the "theorem" -->
<!-- switch will similarly affect corrolaries,   -->
<!-- lemmas, etc - anything that can be proved   -->
<!-- NB: figures and tables inside of            -->
<!-- side-by-side panels are never born hidden,  -->
<!-- no matter how the switches below are set.   -->
<!-- You may elect to have entire side-by-side   -->
<!-- panels born as knowls, using the switch.    -->
<xsl:param name="html.knowl.theorem" select="'no'" />
<xsl:param name="html.knowl.proof" select="'yes'" />
<xsl:param name="html.knowl.definition" select="'no'" />
<xsl:param name="html.knowl.example" select="'yes'" />
<xsl:param name="html.knowl.list" select="'no'" />
<xsl:param name="html.knowl.remark" select="'no'" />
<xsl:param name="html.knowl.figure" select="'no'" />
<xsl:param name="html.knowl.table" select="'no'" />
<xsl:param name="html.knowl.listing" select="'no'" />
<xsl:param name="html.knowl.sidebyside" select="'no'" />
<xsl:param name="html.knowl.exercise.inline" select="'yes'" />
<xsl:param name="html.knowl.exercise.sectional" select="'no'" />
<!-- html.knowl.example.solution: always "yes", could be implemented -->

<!-- CSS and Javascript Servers -->
<!-- We allow processing paramteers to specify new servers   -->
<!-- or to specify the particular CSS file, which may have   -->
<!-- different color schemes.  The defaults should work      -->
<!-- fine and will not need changes on initial or casual use -->
<!-- #0 to #5 on mathbook-modern for different color schemes -->
<!-- We just like #3 as the default                          -->
<!-- N.B.:  This scheme is transitional and may change             -->
<!-- N.B.:  without warning and without any deprecation indicators -->
<xsl:param name="html.js.server"  select="'https://aimath.org'" />
<xsl:param name="html.css.server" select="'https://aimath.org'" />
<xsl:param name="html.css.file"   select="'mathbook-3.css'" />
<!-- A space-separated list of CSS URLs (points to servers or local files) -->
<xsl:param name="html.css.extra"  select="''" />

<!-- Navigation -->
<!-- Navigation may follow two different logical models:                     -->
<!--   (a) Linear, Prev/Next - depth-first search, linear layout like a book -->
<!--       Previous and Next take you to the adjacent "page"                 -->
<!--   (b) Tree, Prev/Up/Next - explicitly traverse the document tree        -->
<!--       Prev and Next remain at same depth/level in tree                  -->
<!--       Must follow a summary link to descend to finer subdivisions       -->
<!--   'linear' is the default, 'tree' is an option                          -->
<xsl:param name="html.navigation.logic"  select="'linear'" />
<!-- The "up" button is optional given the contents sidebar, default is to have it -->
<!-- An up button is very desirable if you use the tree-like logic                 -->
<xsl:param name="html.navigation.upbutton"  select="'yes'" />
<!-- There are also "compact" versions of the navigation buttons in the top right -->
<xsl:param name="html.navigation.style"  select="'full'" />

<!-- WeBWorK -->
<!-- There is no default server provided         -->
<!-- Interactions are with an "anonymous" course -->
<xsl:param name="webwork.server" select="''"/>
<xsl:param name="webwork.course" select="'anonymous'" />
<xsl:param name="webwork.userID" select="'anonymous'" />
<xsl:param name="webwork.password" select="'anonymous'" />

<!-- Permalinks -->
<!-- Next to subdivision headings a "paragraph" symbol     -->
<!-- (a pilcrow) along with internationalized text         -->
<!-- ("permalink") indicates a link to that section.       -->
<!-- It is useful if you want to right-click on it to      -->
<!-- capture a link for use somewhere else.  (Similar      -->
<!-- behavior for theorems, examples, etc is planned.)     -->
<!--                                                       -->
<!-- "Permalink" is a bit of an exaggeration.  Site        -->
<!-- domain name is relative to wherever content is        -->
<!-- hosted.  We say a link is "stable" if there is        -->
<!-- an  xml:id  on the enclosing page AND an  xml:id      -->
<!-- on the subdivision (which could be the same).         -->
<!-- If you change the chunking level, then the enclosing  -->
<!-- page could change and these links will be affected.   -->
<!--                                                       -->
<!-- 'none' - no permalinks anywhere                       -->
<!-- 'stable' - only stable links (see paragraph above)    -->
<!-- 'all' - every section heading, even if links are poor -->
<xsl:param name="html.permalink"  select="'stable'" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->
<!-- Variables that affect HTML creation -->
<!-- More in the common file             -->

<!-- We generally want to chunk longer HTML output -->
<xsl:variable name="chunk-level">
    <xsl:choose>
        <xsl:when test="$chunk.level != ''">
            <xsl:value-of select="$chunk.level" />
        </xsl:when>
        <!-- HTML-specific deprecated 2015/06      -->
        <!-- But still effective if not superseded -->
        <xsl:when test="$html.chunk.level != ''">
            <xsl:value-of select="$html.chunk.level" />
        </xsl:when>
        <xsl:when test="/mathbook/book">2</xsl:when>
        <xsl:when test="/mathbook/article/section">1</xsl:when>
        <xsl:when test="/mathbook/article">0</xsl:when>
        <xsl:when test="/mathbook/letter">0</xsl:when>
        <xsl:when test="/mathbook/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: HTML chunk level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Local versions of navigation options -->
<!-- Fatal errors if not recognized       -->
<xsl:variable name="nav-logic">
    <xsl:choose>
        <xsl:when test="$html.navigation.logic='linear'">
            <xsl:text>linear</xsl:text>
        </xsl:when>
        <xsl:when test="$html.navigation.logic='tree'">
            <xsl:text>tree</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate='yes'>MBX:ERROR: 'html.navigation.logic' must be 'linear' or 'tree', not '<xsl:value-of select="$html.navigation.logic" />.'  Quitting...</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="nav-upbutton">
    <xsl:choose>
        <xsl:when test="$html.navigation.upbutton='yes'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:when test="$html.navigation.upbutton='no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate='yes'>MBX:ERROR: 'html.navigation.upbutton' must be 'yes' or 'no', not '<xsl:value-of select="$html.navigation.upbutton" />.'  Quitting...</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="nav-style">
    <xsl:choose>
        <xsl:when test="$html.navigation.style='full'">
            <xsl:text>full</xsl:text>
        </xsl:when>
        <xsl:when test="$html.navigation.style='compact'">
            <xsl:text>compact</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate='yes'>MBX:ERROR: 'html.navigation.style' must be 'full' or 'compact', not '<xsl:value-of select="$html.navigation.style" />.'  Quitting...</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- WW problem presentation needs the assistance of a server -->
<xsl:variable name="webwork-server">
    <xsl:if test="//webwork[@*|node()] and $webwork.server=''">
        <xsl:message>
            <xsl:text>MBX:WARNING: WeBWorK problems will not render with out the use of a properly configured server.  Provide a webwork server with --stringparam webwork.server as something like  https://webwork.bigstateu.edu</xsl:text>
        </xsl:message>
    </xsl:if>
    <xsl:value-of select="$webwork.server" />
</xsl:variable>

<!-- Permalink display options -->
<xsl:variable name="permalink">
    <xsl:choose>
        <xsl:when test="$html.permalink='none'">
            <xsl:text>none</xsl:text>
        </xsl:when>
        <xsl:when test="$html.permalink='all'">
            <xsl:text>all</xsl:text>
        </xsl:when>
        <xsl:when test="$html.permalink='stable'">
            <xsl:text>stable</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate='yes'>MBX:ERROR: 'html.permalink' must be 'none', 'stable' or 'all', not '<xsl:value-of select="$html.permalink" />.'  Quitting...</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- HTML files as output -->
<xsl:variable name="file-extension" select="'.html'" />

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:apply-templates select="mathbook" mode="generic-warnings" />
    <xsl:apply-templates select="mathbook" mode="deprecation-warnings" />
    <xsl:apply-templates />
</xsl:template>

<!-- We process structural nodes via chunking routine in   xsl/mathbook-common.html -->
<!-- This in turn calls specific modal templates defined elsewhere in this file     -->
<!-- The xref-knowl templates run independently on the entire document tree         -->
<xsl:template match="/mathbook">
    <xsl:apply-templates mode="chunk" />
    <xsl:apply-templates mode="xref-knowl" />
</xsl:template>

<!-- However, some MBX document types do not have    -->
<!-- universal conversion, so these default warnings -->
<!-- should be overridden by supported conversions   -->
<xsl:template match="letter" mode="chunk">
    <xsl:message terminate="yes">
        <xsl:text>MBX:ERROR:  HTML conversion does not support the "letter" document type.  Quitting...</xsl:text>
    </xsl:message>
</xsl:template>

<xsl:template match="memo" mode="chunk">
    <xsl:message terminate="yes">
        <xsl:text>MBX:ERROR:  HTML conversion does not support the "memo" document type.  Quitting...</xsl:text>
    </xsl:message>
</xsl:template>




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
                <br />
                <xsl:apply-templates select="department" />
            </xsl:if>
            <xsl:if test="institution">
                <br />
                <xsl:apply-templates select="institution" />
            </xsl:if>
            <xsl:if test="email">
                <br />
                <xsl:apply-templates select="email" />
            </xsl:if>
        </xsl:if>
    </p>
</xsl:template>

<!-- Departments and Institutions are free-form, or sequences of lines -->
<xsl:template match="department|institution">
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="department[line]|institution[line]">
    <xsl:apply-templates select="line" />
</xsl:template>

<!-- Sneak in dedication line element here as well -->
<xsl:template match="department/line|institution/line|dedication/p/line">
    <xsl:apply-templates />
    <!-- is there a next line to separate? -->
    <xsl:if test="following-sibling::*">
        <br />
    </xsl:if>
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
    <!-- Heading, div for subdivision that is this page -->
    <xsl:variable name="ident"><xsl:apply-templates select="." mode="internal-id" /></xsl:variable>
    <section class="{local-name(.)}" id="{$ident}">
        <xsl:apply-templates select="." mode="section-header" />
        <xsl:copy-of select="$content" />
    </section>
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


<!-- Bits and Pieces -->

<!-- Paragraphs -->
<!-- Never structural, never named, somewhat distinct  -->
<!-- Extra CSS to position within a side-by-side panel -->
<xsl:template match="paragraphs|paragraph">
    <xsl:if test="local-name(.)='paragraph'">
        <xsl:message>MBX:WARNING: the "paragraph" element is deprecated (2015/03/13), use "paragraphs" instead</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <xsl:variable name="ident"><xsl:apply-templates select="." mode="internal-id" /></xsl:variable>
    <article class="paragraphs" id="{$ident}">
        <!-- within a side-by-side can carry positioning attributes -->
        <xsl:if test="parent::sidebyside">
            <xsl:call-template name="sidebysideCSS" select="."/>
        </xsl:if>
        <h5 class="heading">
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </h5>
        <xsl:apply-templates  select="*"/>
    </article>
</xsl:template>

<!-- Header for Document Nodes -->
<!-- Every document node goes the same way, a    -->
<!-- heading followed by its subsidiary elements -->
<!-- hit with templates.  This is the header.    -->
<xsl:template match="*" mode="section-header">
    <header>
        <!-- TODO: replicate tooltip on header (only) -->
        <xsl:element name="h1">
            <xsl:attribute name="class">
                <xsl:text>heading</xsl:text>
            </xsl:attribute>
             <xsl:attribute name="alt">
                <xsl:apply-templates select="." mode="tooltip-text" />
            </xsl:attribute>
             <xsl:attribute name="title">
                <xsl:apply-templates select="." mode="tooltip-text" />
            </xsl:attribute>
            <xsl:apply-templates select="." mode="header-content" />
        </xsl:element>
        <xsl:if test="author">
            <p class="byline"><xsl:apply-templates select="author" mode="name-list"/></p>
        </xsl:if>
    </header>
</xsl:template>

<!-- The "type" is redundant at the top-level, -->
<!-- so we hide it with a class specification  -->
<!-- We also hide it at lower levels, parallel -->
<!-- to default LaTeX style behavior           -->
<xsl:template match="book|article|subsection|subsubsection|exercises[ancestor::section]|references[ancestor::section]" mode="section-header">
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
<xsl:template match="frontmatter|colophon|preface|foreword|acknowledgement|dedication|biography|backmatter" mode="section-header">
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
    <xsl:apply-templates select="." mode="permalink" />
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
    <xsl:apply-templates select="." mode="permalink" />
</xsl:template>

<!-- Permalinks on section headings are configurable              -->
<!-- "stable" implies there is an xml:id on the element. However, -->
<!-- the filename will change with different chunking levels      -->
<xsl:template match="*" mode="permalink">
    <xsl:variable name="has-permalink">
        <xsl:choose>
            <xsl:when test="$permalink='none'">
                <xsl:value-of select="false()" />
            </xsl:when>
            <xsl:when test="$permalink='all'">
                <xsl:value-of select="true()" />
            </xsl:when>
            <!-- now in case of $permalink='stable' due to input sanitation -->
            <xsl:when test="not(@xml:id)">
                <xsl:value-of select="false()" />
            </xsl:when>
            <!-- now just need xml:id for the page URL, or not      -->
            <!-- NOTE: the element and the enclosure might be equal -->
            <!--       but double 'true' is not a problem           -->
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="has-id-on-enclosure" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="$has-permalink='true'">
        <xsl:variable name="url">
            <xsl:apply-templates select="." mode="url" />
        </xsl:variable>
        <!-- pilchrow plus internationalized string  -->
        <a href="{$url}" class="permalink">
            <xsl:text>&#xb6; </xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'permalink'" />
            </xsl:call-template>
        </a>
    </xsl:if>
</xsl:template>

<!-- Recursively finds enclosing structural node -->
<!-- and reports if it has an xml:id on it       -->
<!-- Note: from mode="containing-filename", can we return a node-set? -->
<xsl:template match="*" mode="has-id-on-enclosure">
    <xsl:variable name="intermediate"><xsl:apply-templates select="." mode="is-intermediate" /></xsl:variable>
    <xsl:variable name="chunk"><xsl:apply-templates select="." mode="is-chunk" /></xsl:variable>
    <xsl:choose>
        <xsl:when test="$intermediate='true' or $chunk='true'">
            <!-- found it, is there an xml:id? -->
            <xsl:choose>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="true()" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="false()" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select=".." mode="has-id-on-enclosure" />
        </xsl:otherwise>
    </xsl:choose>
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
        <span class="title">
            <xsl:apply-templates select="/mathbook/*" mode="title-full" />
        </span>
        <xsl:if test="/mathbook/*/subtitle">
            <span class="subtitle">
                <xsl:apply-templates select="/mathbook/*" mode="subtitle" />
            </span>
        </xsl:if>
    </h1>
    <!-- We list full info for each author and editor in document order -->
    <!-- Minor players (credits) come next                              -->
    <address class="contributors">
        <xsl:apply-templates select="author|editor" mode="full-info" />
        <xsl:apply-templates select="credit" />
    </address>
    <xsl:apply-templates select="date" />
</xsl:template>

<!-- A "credit" can have a "title" followed by an author (or several)  -->
<!-- Better CSS would have the title in the same size as author info   -->
<!-- then name, etc in slightly smaller font (generally de-emphasised) -->
<xsl:template match="titlepage/credit">
    <xsl:if test="title">
        <p>
        <xsl:apply-templates select="." mode="title-full"/>
        </p>
    </xsl:if>
    <xsl:apply-templates select="author" mode="full-info" />
</xsl:template>

<!-- A template manages the date      -->
<!-- Until we have better CSS for it  -->
<xsl:template match="titlepage/date">
    <!-- <p style="text-align:center"> -->
    <address class="contributors">
        <xsl:apply-templates />
    </address>
    <p></p>
</xsl:template>

<!-- Front Colophon -->
<!-- Licenses, ISBN, Cover Designer, etc -->
<!-- We process pieces, in document order -->
<!-- TODO: edition, publisher, production notes, cover design, etc -->
<!-- TODO: revision control commit hash -->
<xsl:template match="frontmatter/colophon/copyright">
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

<!-- website for the book -->
<xsl:template match="frontmatter/colophon/website">
    <p>
        <xsl:text>Website: </xsl:text>
        <xsl:element name="a">
            <xsl:attribute name="href">
                <xsl:apply-templates select="address" />
            </xsl:attribute>
            <xsl:apply-templates select="name" />
        </xsl:element>
    </p>
</xsl:template>

<!-- Introductions and Conclusions -->
<!-- Simple containers, allowed before and after      -->
<!-- explicit subdivisions, to introduce or summarize -->
<!-- Title optional (and discouraged),                -->
<!-- typically just a few paragraphs                  -->
<xsl:template match="introduction|conclusion">
    <xsl:variable name="ident"><xsl:apply-templates select="." mode="internal-id" /></xsl:variable>
    <article class="{local-name(.)}" id="{$ident}">
        <h5 class="heading">
            <xsl:apply-templates select="." mode="title-full" />
            <span> </span>
        </h5>
        <xsl:apply-templates  select="*"/>
    </article>
</xsl:template>

<!-- ####################### -->
<!-- Back Matter Components -->
<!-- ####################### -->

<!-- Back Colophon -->
<!-- Nothing special, so just process similarly to front -->


<xsl:template match="index-list">
    <xsl:call-template name="print-index" />
</xsl:template>



<!-- Solutions List -->
<!-- We construct one huge list of solutions, organized      -->
<!-- as divisions, one per "exercises" section.  Seperate    -->
<!-- parameters control visibility. We eventually appeal     -->
<!-- to the environment/knowl code to realize each hint, etc -->
<!-- as a knowl for decent page-loading time.                -->

<!-- This is a hack that should go away when backmatter exercises are rethought -->
<xsl:template match="title" mode="backmatter" />

<xsl:template match="solution-list">
    <xsl:apply-templates select="//exercises" mode="backmatter" />
</xsl:template>

<xsl:template match="exercises" mode="backmatter">
    <!-- see if an "exercises" section has any solutions -->
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
            <!-- ignore introduction, conclusion, exercise groups -->
            <xsl:apply-templates select=".//exercise" mode="backmatter" />
        </section>
    </xsl:if>
</xsl:template>

<!-- Print exercises with some solution component -->
<!-- Respect switches about visibility            -->
<xsl:template match="exercise" mode="backmatter">
    <xsl:if test="hint or answer or solution">
        <!-- Lead with the problem number and some space -->
        <xsl:variable name="xref">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:variable>
        <article class="exercise-like" id="{$xref}">
            <h5 class="heading hidden-type">
            <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
            <span class="codenumber"><xsl:apply-templates select="." mode="serial-number" /></span>
            <xsl:if test="title">
                <span class="title"><xsl:apply-templates select="." mode="title-full" /></span>
            </xsl:if>
            </h5>
            <xsl:if test="$exercise.backmatter.statement='yes'">
                <xsl:apply-templates select="statement" />
            </xsl:if>
            <!-- default templates will produce inline knowls -->
            <span class="hidden-knowl-wrapper">
                <xsl:if test="hint and $exercise.backmatter.hint='yes'">
                    <xsl:apply-templates select="hint" />
                </xsl:if>
                <xsl:if test="answer and $exercise.backmatter.answer='yes'">
                    <xsl:apply-templates select="answer" />
                </xsl:if>
                <xsl:if test="solution and $exercise.backmatter.solution='yes'">
                    <xsl:apply-templates select="solution" />
                </xsl:if>
            </span>
        </article>
    </xsl:if>
</xsl:template>

<!--               -->
<!-- Notation List -->
<!--               -->

<!-- At actual location, we do nothing -->
<xsl:template match="notation" />

<!-- Build the table infrastructure, then    -->
<!-- populate with all the notation entries, -->
<!-- in order of appearance                  -->
<xsl:template match="notation-list">
    <table>
        <tr>
            <th style="text-align:left">
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'symbol'" />
                </xsl:call-template>
            </th>
            <th style="text-align:left">
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'description'" />
                </xsl:call-template>
            </th>
            <th style="text-align:left">
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'location'" />
                </xsl:call-template>
            </th>
        </tr>
        <xsl:apply-templates select="//notation" mode="backmatter" />
    </table>
</xsl:template>

<!-- We wrap the sample usage as mathematics       -->
<!-- Duplicate the provided description            -->
<!-- Create a cross-reference to enclosing content -->
<xsl:template match="notation" mode="backmatter">
    <tr>
        <td>
            <xsl:text>\(</xsl:text>
            <xsl:value-of select="usage" />
            <xsl:text>\)</xsl:text>
        </td>
        <td>
            <xsl:apply-templates select="description" />
        </td>
        <td>
            <xsl:apply-templates select="." mode="enclosure-xref" />
        </td>
    </tr>
</xsl:template>

<!-- Experimental: maybe belongs in -common -->
<!-- Not -md, know where the link lives     -->
<xsl:template match="*" mode="enclosure-xref">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:variable name="block">
        <xsl:apply-templates select="." mode="is-block" />
    </xsl:variable>
    <xsl:choose>
        <!-- found a structural or block parent -->
        <!-- we fashion a cross-reference link  -->
        <xsl:when test="$structural='true' or $block='true'">
            <xsl:apply-templates select="." mode="xref-link">
                <xsl:with-param name="content">
                    <xsl:apply-templates select="." mode="type-name" />
                    <xsl:variable name="enclosure-number">
                        <xsl:apply-templates select="." mode="number" />
                    </xsl:variable>
                    <xsl:if test="not($enclosure-number = '')">
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$enclosure-number" />
                    </xsl:if>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <!-- nothing interesting here, so step up a level -->
        <!-- Eventually we find the top-level structure   -->
        <!-- eg article, book, etc                        -->
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="enclosure-xref" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############### -->
<!-- Arbitrary Lists -->
<!-- ############### -->

<!-- See general routine in  xsl/mathbook-common.xsl -->
<!-- which expects the two named templates and the  -->
<!-- two division'al and element'al templates below,  -->
<!-- it contains the logic of constructing such a list -->

<!-- List-of entry/exit hooks -->
<!-- No ops for HTML          -->
<xsl:template name="list-of-begin" />
<xsl:template name="list-of-end" />

<!-- Subdivision headings in list-of's -->
<!-- Amalgamation of "section-header" and "header-content" -->
<!--   (1) No author credit                                -->
<!--   (2) No permalink                                    -->
<xsl:template match="*" mode="list-of-header">
    <header>
        <xsl:element name="h1">
            <xsl:attribute name="class">
                <xsl:text>heading</xsl:text>
            </xsl:attribute>
             <xsl:attribute name="alt">
                <xsl:apply-templates select="." mode="tooltip-text" />
            </xsl:attribute>
             <xsl:attribute name="title">
                <xsl:apply-templates select="." mode="tooltip-text" />
            </xsl:attribute>
            <span class="type">
                <xsl:apply-templates select="." mode="type-name" />
            </span>
            <span class="codenumber">
                <xsl:apply-templates select="." mode="number" />
            </span>
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:element>
    </header>
</xsl:template>

<!-- Entries in list-of's -->
<!-- Partly borrowed from common routines -->
<!-- TODO: CSS styling of the div forcing the knowl to open in the right place -->
<!-- And spacing should be done with .type, .codenumber, .title                -->
<xsl:template match="*" mode="list-of-element">
    <!-- Name and number as a knowl/link, div to open against -->
    <div>
        <xsl:apply-templates select="." mode="xref-link">
            <xsl:with-param name="content">
                <xsl:apply-templates select="." mode="type-name" />
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="." mode="number" />
            </xsl:with-param>
        </xsl:apply-templates>
        <!-- title plain, separated -->
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
    </div>
</xsl:template>

<!-- ################ -->
<!-- Contributor List -->
<!-- ################ -->

<!-- Not much happening here, will drop -->
<!-- into environment manufacture       -->
<xsl:template match="contributors">
    <xsl:apply-templates select="contributor" />
</xsl:template>

<!-- ############## -->
<!-- Index Creation -->
<!-- ############## -->

<xsl:template name="print-index">
    <!-- <index> and identified <term> with simple content index entry             -->
    <!-- start attribute is actual end of a "page range", goodies are at other end -->
    <xsl:variable name="unstructured-index">
        <xsl:for-each select="//index[not(child::*) and not(@start)]|//term[@index='yes']">
            <xsl:variable name="content">
                <xsl:apply-templates select="*|text()" />
            </xsl:variable>
            <index>
                <xsl:apply-templates select="." mode="index-enclosure" />
                <text>
                    <xsl:value-of select="$content" />
                </text>
                <key>
                    <xsl:value-of select="translate($content, &UPPERCASE;, &LOWERCASE;)" />
                </key>
            </index>
        </xsl:for-each>
    </xsl:variable>
    <!-- index entries with structure, cant't be end of a "page range" -->
    <xsl:variable name="structured-index">
        <xsl:for-each select="//index[child::*]">
            <index>
                <!-- write/preserve info about the location's surroundings -->
                <!-- as "knowl" and "typename" temporary elements          -->
                <xsl:apply-templates select="." mode="index-enclosure" />
                 <xsl:for-each select="main|sub">
                    <xsl:variable name="content">
                        <xsl:apply-templates select="*|text()" />
                    </xsl:variable>
                    <text>
                        <xsl:value-of select="$content" />
                    </text>
                    <key>
                        <xsl:value-of select="translate($content, &UPPERCASE;, &LOWERCASE;)" />
                    </key>
                </xsl:for-each>
            </index>
        </xsl:for-each>
    </xsl:variable>
    <!-- sort now that info from document tree ordering is recorded -->
    <xsl:variable name="sorted-index">
        <xsl:for-each select="exsl:node-set($unstructured-index)/*|exsl:node-set($structured-index)/*">
            <xsl:sort select="./key[1]" />
            <xsl:sort select="./key[2]" />
            <xsl:sort select="./key[3]" />
            <xsl:copy-of select="." />
        </xsl:for-each>
    </xsl:variable>
    <!-- work out if each new entry needs some material in      -->
    <!-- the index prior to simply making a knowl for the entry -->
    <xsl:for-each select="exsl:node-set($sorted-index)/*">
        <!-- strings for comparisons, this item first -->
        <xsl:variable name="key1"><xsl:value-of select="key[1]" /></xsl:variable>
        <xsl:variable name="key2"><xsl:value-of select="key[2]" /></xsl:variable>
        <xsl:variable name="key3"><xsl:value-of select="key[3]" /></xsl:variable>
        <!-- strings for second item -->
        <xsl:variable name="previous" select="preceding-sibling::*[1]" />
        <xsl:variable name="prev1"><xsl:value-of select="$previous/key[1]" /></xsl:variable>
        <xsl:variable name="prev2"><xsl:value-of select="$previous/key[2]" /></xsl:variable>
        <xsl:variable name="prev3"><xsl:value-of select="$previous/key[3]" /></xsl:variable>
        <!-- flatten the sorted structure, with breaks -->
        <xsl:choose>
            <!-- new key1, so finish knowl list and start new level one list -->
            <!-- (if not dimply starting out)                                -->
            <!-- Extraordinary: perhaps time for a new prominent letter      -->
            <xsl:when test="not($key1 = $prev1)">
                <xsl:if test="not($prev1='')">
                    <xsl:call-template name="end-index-knowl-list" />
                </xsl:if>
                <!-- Compare lower-cased leading letters, break if changed -->
                <xsl:if test="not(substring($prev1, 1,1) = substring($key1, 1,1))">
                    <div class="indexletter">
                        <xsl:value-of select="translate(substring($key1, 1, 1), &UPPERCASE;, &LOWERCASE;)" />
                    </div>
                </xsl:if>
                <!--  -->
                <xsl:text disable-output-escaping="yes">&lt;div class="indexitem"></xsl:text>
                <!-- <xsl:value-of select="$key1" /> -->
                <xsl:value-of select="text[1]" />
                <xsl:choose>
                    <xsl:when test="not($key2='')">
                        <!-- no links yet, so close index item w/o links (?), open subitem -->
                        <xsl:text disable-output-escaping="yes">&lt;/div></xsl:text>
                        <xsl:text disable-output-escaping="yes">&lt;div class="subindexitem"></xsl:text>
                        <xsl:value-of select="text[2]" />
                        <xsl:choose>
                            <xsl:when test="not($key3='')">
                                <!-- no links yet, so close subindex item w/o links, open subsubitem -->
                                <xsl:text disable-output-escaping="yes">&lt;/div></xsl:text>
                                <xsl:text disable-output-escaping="yes">&lt;div class="subsubindexitem"></xsl:text>
                                <xsl:value-of select="'*'" />
                                <xsl:value-of select="text[3]" />
                                <!-- terminal so start knowl list -->
                                <xsl:call-template name="begin-index-knowl-list" />
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- no subsubitems, so start knowl span -->
                                <xsl:call-template name="begin-index-knowl-list" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- no subitems, so start knowl span -->
                        <xsl:call-template name="begin-index-knowl-list" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- key1 unchanged, but new key2 -->
            <!-- so finish knowl list and start new level two list -->
            <xsl:when test="not($key2 = $prev2)">
                <xsl:call-template name="end-index-knowl-list" />
                <xsl:text disable-output-escaping="yes">&lt;div class="subindexitem"></xsl:text>
                <xsl:value-of select="text[2]" />
                <xsl:choose>
                    <xsl:when test="not($key3='')">
                        <!-- no links yet, so close subindex item w/o links, open subsubitem -->
                        <xsl:text disable-output-escaping="yes">&lt;/div></xsl:text>
                        <xsl:text disable-output-escaping="yes">&lt;div class="subsubindexitem"></xsl:text>
                        <xsl:value-of select="'*'" />
                        <xsl:value-of select="text[3]" />
                        <!-- terminal so start knowl list -->
                        <xsl:call-template name="begin-index-knowl-list" />
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- no subsubitems, so start knowl span -->
                        <xsl:call-template name="begin-index-knowl-list" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- key1 and key 2 unchanged, but new key3              -->
            <!-- so finish knowl list and start new level three list -->
            <xsl:when test="not($key3 = $prev3)">
                <xsl:call-template name="end-index-knowl-list" />
                <xsl:text disable-output-escaping="yes">&lt;div class="subsubindexitem"></xsl:text>
                <xsl:value-of select="'*'" />
                <xsl:value-of select="text[3]" />
                <xsl:call-template name="begin-index-knowl-list" />
            </xsl:when>
            <!-- if here then key1, key2, key3 all unchanged, so just drop a link -->
        </xsl:choose>
        <!-- every item has a link, above we just place breaks into the list -->
        <xsl:text> </xsl:text>
        <xsl:element name="a">
            <!-- knowl or traditional hyperlink     -->
            <!-- mutually exclusive by construction -->
            <xsl:if test="knowl">
                <xsl:attribute name="knowl">
                    <xsl:value-of select="knowl" />
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="hyperlink">
                <xsl:attribute name="href">
                    <xsl:value-of select="hyperlink" />
                </xsl:attribute>
            </xsl:if>
            <!-- content: replace with localized short-names -->
            <xsl:value-of select="typename" />
        </xsl:element>
    </xsl:for-each>
    <!-- we fall out with one unbalanced item -->
    <xsl:call-template name="end-index-knowl-list" />
</xsl:template>

<!-- Climb the tree looking for an enclosing structure of        -->
<!-- interest and preserve the knowl-url, plus clickable text    -->
<!-- One notable case: paragraph must be "top-level", just below -->
<!-- a structural document node                                  -->
<!-- Recursion always halts, since "mathbook" is structural      -->
<!-- TODO: save knowl or section link                            -->
<xsl:template match="*" mode="index-enclosure">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:variable name="block">
        <xsl:apply-templates select="." mode="is-block" />
    </xsl:variable>
    <xsl:choose>
        <!-- found a structural parent first           -->
        <!-- collect a url for a traditional hyperlink -->
        <xsl:when test="$structural='true'">
            <hyperlink>
                <xsl:apply-templates select="." mode="url" />
            </hyperlink>
            <typename>
                <xsl:apply-templates select="." mode="type-name" />
            </typename>
        </xsl:when>
        <!-- found a block parent     -->
        <!-- collect a knowl filename -->
        <xsl:when test="$block='true'">
            <knowl>
                <xsl:apply-templates select="." mode="xref-knowl-filename" />
            </knowl>
            <typename>
                <xsl:apply-templates select="." mode="type-name" />
            </typename>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="index-enclosure" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Start markup for a list of knowls representing entries -->
<xsl:template name="begin-index-knowl-list">
    <xsl:text disable-output-escaping="yes">&lt;span class="indexknowl"></xsl:text>
</xsl:template>

<!-- End markup for a list of knowls representing entries -->
<!-- End markup for the actual index entry text           -->
<xsl:template name="end-index-knowl-list">
    <xsl:text disable-output-escaping="yes">&lt;/span></xsl:text>
    <xsl:text disable-output-escaping="yes">&lt;/div></xsl:text>
</xsl:template>

<!-- ###################### -->
<!-- Cross-Reference Knowls -->
<!-- ###################### -->

<!-- Many elements are candidates for cross-references       -->
<!-- and many of those are nicely implemented as knowls.     -->
<!-- We traverse the entire document tree with modal         -->
<!-- "xref-knowl" templates.  When they encounter an element -->
<!-- that needs a cross-reference target as a knowl file,    -->
<!-- that file is built and the tree traversal continues.    -->

<!-- See initiation in the entry template. We default -->
<!-- to just recursing through children elements      -->
<!-- Otherwise, see knowl creation in next section    -->
<xsl:template match="*" mode="xref-knowl">
    <xsl:apply-templates select="*" mode="xref-knowl" />
</xsl:template>

<!-- ####################### -->
<!-- Environments and Knowls -->
<!-- ####################### -->

<!-- The term "environment" is used here in a way dissimilar   -->
<!-- to the way LaTeX uses the term.  We mean any collection   -->
<!-- of text that is not structural and which could reasonably -->
<!-- be accomodated in a knowl.  So a <subsection> is not an   -->
<!-- environment, but examples include: theorems, exercises,   -->
<!-- citations, footnotes and displayed mathematics.  It       -->
<!-- is part of the "flow," and frequently called a "block" in -->
<!-- the DTD.  Primarily, they are perfect for knowls, either  -->
<!-- by default/fiat, or by an author's choice.                -->

<!-- We have three options on encountering an environment: -->
<!--                                                       -->
<!-- (a) place the content in a file for use as a knowl,   -->
<!-- as a target of cross-reference (xref)                 -->
<!--                                                       -->
<!-- (b) write the content directly into the HTML page,    -->
<!-- which we will refer to as "visible" environment       -->
<!--                                                       -->
<!-- (c) embed the content on the page, in a form to       -->
<!-- be revealed by a knowl.  We will refer to this as     -->
<!-- "hidden" environment                                  -->
<!--                                                       -->
<!-- Options (b) and (c) are mutually exclusive.           -->
<!-- Primarily, this choice is configurable, however       -->
<!-- some (eg footnotes) are always born hidden and        -->
<!-- then some are never born hidden (eg citations).       -->
<!-- Option (b) needs a header, while for (c) we           -->
<!-- will put the header in the knowl link and the         -->
<!-- content will always appear immediately below.         -->

<!-- Entry Point to Process Environments -->
<!-- This is the entry point for *all* environments, in default mode -->
<!-- We *always* build a knowl to be target of a xref (a), but       -->
<!-- this happens independently via the "xref-knowl" templates       -->
<!-- We show the full content of the item on the page (b)            -->
<!-- Or, we build a hidden knowl and place a link on the page (c)    -->
<!-- NB: this template employs several modal templates, defined just below -->
<xsl:template match="fn|biblio|example|list|remark|definition|axiom|conjecture|principle|theorem|corollary|lemma|algorithm|proposition|claim|fact|proof|exercise|hint|answer|solution|exercisegroup|note|figure|table|listing|sidebyside|sidebyside/figure|sidebyside/table|me|men|md|mdn|contributor">
    <xsl:variable name="hidden">
        <xsl:apply-templates select="." mode="is-hidden" />
    </xsl:variable>
    <!-- Born visible or born hidden behind a knowl -->
    <xsl:choose>
        <xsl:when test="$hidden='false'">
            <xsl:apply-templates select="." mode="environment-visible-factory" />
        </xsl:when>
        <xsl:when test="$hidden='true'">
            <xsl:apply-templates select="." mode="environment-hidden-factory" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: an environment (<xsl:value-of select="local-name(.)" />) does not know if it is hidden or not</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Environments as knowls for targets of cross-references  -->
<!-- Option (a): "xref-knowl-factory"                        -->
<!-- The environment                                         -->
<!-- (1) lives in a file                                     -->
<!-- (2) has a header (since it may open some distance away) -->
<!-- (3) no id attribute (can't point to it)                 -->
<!-- (4) a body                                              -->
<!-- (5) posterior, outside structure                        -->
<!-- (6) concluding "in-context" link always                 -->
<!-- NB: this depends on multiple modal templates (below)    -->
<!-- NB: this list should contain the list at         -->
<!--     the "xref-as-knowl" modal template           -->
<!-- TODO: we need to process children in a way that no \label{}, nor ID's, are produced   -->
<!--       This would perhaps obsolete the "env-type" device, and reorder explnation below -->
<xsl:template match="fn|biblio|example|list|remark|definition|axiom|conjecture|principle|theorem|corollary|lemma|algorithm|proposition|claim|fact|proof|exercise|hint|answer|solution|exercisegroup|note|figure|table|listing|sidebyside|sidebyside/figure|sidebyside/table|me|men|md|mdn|li|p|contributor" mode="xref-knowl">
    <xsl:variable name="knowl-file">
        <xsl:apply-templates select="." mode="xref-knowl-filename" />
    </xsl:variable>
    <exsl:document href="{$knowl-file}" method="html">
        <xsl:call-template name="converter-blurb-html" />
        <xsl:variable name="element">
            <xsl:apply-templates select="." mode="environment-element" />
        </xsl:variable>
        <xsl:element name="{$element}">
            <xsl:attribute name="class">
               <xsl:apply-templates select="." mode="environment-class" />
            </xsl:attribute>
            <xsl:apply-templates select="." mode="head">
                <xsl:with-param name="env-type" select="'xref'" />
            </xsl:apply-templates>
            <xsl:apply-templates select="." mode="body">
                <xsl:with-param name="env-type" select="'xref'" />
            </xsl:apply-templates>
        </xsl:element>
        <xsl:apply-templates select="." mode="posterior" />
        <xsl:element name="span">
            <xsl:attribute name="class">
                <xsl:text>incontext</xsl:text>
            </xsl:attribute>
            <xsl:element name="a">
                <xsl:attribute name="href">
                    <xsl:apply-templates select="." mode="url" />
                </xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'incontext'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:element>
    </exsl:document>
    <!-- recurse the tree outside of the file-writing -->
    <xsl:apply-templates select="*" mode="xref-knowl" />
</xsl:template>

<!-- WeBWorK exercises live inside generic exercises which would    -->
<!-- typically be knowlized.  They have components (solution, hint) -->
<!-- which are knowlized as part of generic exercises.  So we need  -->
<!-- to dead-end the  xref-knowl  templates here and not blindly    -->
<!-- descend into a  webwork  element                               -->
<xsl:template match="webwork" mode="xref-knowl" />

<!-- Environments born visible -->
<!-- Option (b): "environment-visible-factory"   -->
<!-- The environment                             -->
<!-- (1) lives openly on the page                -->
<!-- (2) has a header                            -->
<!-- (3) has id attribute, so we can point to it -->
<!-- (4) a body                                  -->
<!-- (5) posterior, outside structure            -->
<!-- (6) no concluding "in-context" link         -->
<!-- NB: this depends on multiple modal templates, defined below -->
<xsl:template match="*" mode="environment-visible-factory">
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
        <xsl:apply-templates select="." mode="head">
            <xsl:with-param name="env-type" select="'visible'" />
        </xsl:apply-templates>
        <xsl:apply-templates select="." mode="body">
            <xsl:with-param name="env-type" select="'visible'" />
        </xsl:apply-templates>
    </xsl:element>
    <xsl:apply-templates select="." mode="posterior" />
</xsl:template>

<!-- Environments born hidden -->
<!-- Option (c): "environment-hidden-factory" -->
<!-- The environment                          -->
<!-- (1) is just a knowl on the page          -->
<!-- (2) the knowl link has specialized text  -->
<!-- (3) has id attribute on the knowl link   -->
<!-- (4) a body                               -->
<!-- (5) posterior, outside structure         -->
<!-- (6) no concluding "in-context" link      -->
<!-- NB: this depends on multiple modal templates, defined below -->
<xsl:template match="*" mode="environment-hidden-factory">
    <!-- the HTML element for the environment -->
    <xsl:variable name="env-element">
        <xsl:apply-templates select="." mode="environment-element" />
    </xsl:variable>
    <xsl:variable name="block">
        <xsl:apply-templates select="." mode="is-block-env" />
    </xsl:variable>
    <!-- an element to wrap the knowl link ("kw" = "knowl wrap") -->
    <!-- provides structure for knowl open location              -->
    <!-- also wraps the embedded content immediately adjacent    -->
    <!-- block wrapped in a div, inline wrapped in a span        -->
    <xsl:variable name="kw-element">
        <xsl:choose>
            <xsl:when test="$block='true'">
                <xsl:text>div</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>span</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$kw-element}">
        <xsl:attribute name="class">
            <xsl:text>hidden-knowl-wrapper</xsl:text>
        </xsl:attribute>
        <xsl:element name="a">
            <!-- Point to the file version, may have silly in-context link -->
            <xsl:attribute name="knowl">
                <xsl:apply-templates select="." mode="xref-knowl-filename" />
            </xsl:attribute>
            <!-- empty, indicates content *not* in a file -->
            <xsl:attribute name="knowl"></xsl:attribute>
            <!-- class indicates content is in div referenced by id -->
            <xsl:attribute name="class">
                <xsl:text>id-ref</xsl:text>
            </xsl:attribute>
            <!-- and the id via a template for consistency -->
            <xsl:attribute name="refid">
                <xsl:apply-templates select="." mode="hidden-knowl-id" />
            </xsl:attribute>
            <!-- make the anchor a target, eg of an in-context link -->
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="internal-id" />
            </xsl:attribute>
            <!-- marked-up knowl text link *inside* of knowl anchor to be effective -->
            <xsl:apply-templates select="." mode="hidden-knowl-text" />
        </xsl:element>
    </xsl:element>
    <!-- now embed the content properly within the page itself    -->
    <!-- We build a hidden span or div, according to block/inline -->
    <xsl:element name="{$kw-element}">
        <!-- different id, for use by the knowl mechanism -->
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="hidden-knowl-id" />
        </xsl:attribute>
        <!-- not "visibility,"" display:none takes no space -->
        <xsl:attribute name="style">
            <xsl:text>display: none;</xsl:text>
        </xsl:attribute>
        <!-- Do not process the contents on page load, wait until it is opened -->
        <xsl:attribute name="class">
            <xsl:text>tex2jax_ignore</xsl:text>
        </xsl:attribute>
        <xsl:element name="{$env-element}">
            <xsl:attribute name="class">
               <xsl:apply-templates select="." mode="environment-class" />
            </xsl:attribute>
            <xsl:apply-templates select="." mode="body">
                <xsl:with-param name="env-type" select="'hidden'" />
            </xsl:apply-templates>
        </xsl:element>
        <xsl:apply-templates select="." mode="posterior" />
    </xsl:element>
</xsl:template>

<!-- Knowl manufacturing utilities -->
<!-- For consistency in use, we make identifiers via templates -->

<!-- The directory of knowls that are targets of cross-references    -->
<!-- The file extension is *.html so recognized as OK by Moodle, etc -->
<xsl:template match="*" mode="xref-knowl-filename">
    <xsl:text>./knowl/</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>.html</xsl:text>
</xsl:template>
<!-- Small trick, a cross-reference to an <mrow> of -->
<!-- a multi-line display of mathematics will point -->
<!-- to the file for the entire display.            -->
<xsl:template match="mrow" mode="xref-knowl-filename">
    <xsl:text>./knowl/</xsl:text>
    <xsl:apply-templates select="parent::*" mode="internal-id" />
    <xsl:text>.html</xsl:text>
</xsl:template>

<!-- Hidden knowls are embedded in a div that MathJax ignores.   -->
<!-- That div needs an id for the knowl to be able to locate it  -->
<xsl:template match="*" mode="hidden-knowl-id">
    <xsl:text>hk-</xsl:text>  <!-- "hidden-knowl" -->
    <xsl:apply-templates select="." mode="internal-id" />
</xsl:template>

<!-- Modal Templates of Environments -->
<!-- The above three primary templates repeatedly inspect properties of environments -->
<!-- We provide documantation and default templates now, real implementations follow -->

<!-- Hidden and Visible Environments -->
<!-- The "is-hidden" template returns true/false -->
<xsl:template match="*" mode="is-hidden">
    <xsl:message>MBX:ERROR: inquired inappropriately if an environment (<xsl:value-of select="local-name(.)" />)is hidden or not</xsl:message>
</xsl:template>

<!-- Block or Inline Environment -->
<!-- An environment born hidden generates a knowl link.     -->
<!-- We need to place it on the page as a block element     -->
<!-- or as an inline element, so the knowl opens in the     -->
<!-- right place (adjacent, or nearby). A link to a theorem -->
<!-- knowl needs a div, while a footnote needs a span.      -->
<xsl:template match="*" mode="is-block-env">
    <xsl:message>MBX:ERROR: an environment  (<xsl:value-of select="local-name(.)" />) does not know if it is a block or inline element</xsl:message>
</xsl:template>

<!-- Environment HTML Element and CSS Names -->
<!-- Environments get wrapped in HTML elements, with CSS class names. -->
<xsl:template match="*" mode="environment-element">
    <xsl:message>MBX:ERROR: an environment  (<xsl:value-of select="local-name(.)" />) does not know its HTML element</xsl:message>
</xsl:template>
<xsl:template match="*" mode="environment-class">
    <xsl:message>MBX:ERROR: an environment  (<xsl:value-of select="local-name(.)" />) does not know its CSS class</xsl:message>
</xsl:template>

<!-- Head, Body, Posterior -->
<!-- An environment had a head (header), a body (the actual content after   -->
<!-- the head), and a posterior (to follow outside the structure, eg proof) -->
<!-- The "head" and "body" templates may *choose* to respect a parameter,   -->
<!-- named "env-type" which takes the values: 'xref', 'visible' or 'hidden' -->
<!-- (hidden knowl content has ho head, so one case of six never occurs).   -->
<!-- This device was initiated to allow CSS to position tables and figures  -->
<!-- inside of side-by-side, while allowing knowlized versions              -->
<!-- to fill the knowl properly, and to avoid "\label{}" in xref knowls.    -->
<xsl:template match="*" mode="head">
    <xsl:message>MBX:ERROR: an environment  (<xsl:value-of select="local-name(.)" />) does not know its header</xsl:message>
</xsl:template>
<xsl:template match="*" mode="body">
    <xsl:message>MBX:ERROR: an environment  (<xsl:value-of select="local-name(.)" />) does not know its body</xsl:message>
</xsl:template>
<xsl:template match="*" mode="posterior">
    <xsl:message>MBX:ERROR: an environment  (<xsl:value-of select="local-name(.)" />) does not know its posterior</xsl:message>
</xsl:template>

<!-- ########################### -->
<!-- Environment Implementations -->
<!-- ########################### -->

<!-- Footnotes -->
<!-- Always born hidden -->
<xsl:template match="fn" mode="is-hidden">
    <xsl:value-of select="true()" />
</xsl:template>
<!-- Occur in paragraphs and titles, hence inline -->
<xsl:template match="fn" mode="is-block-env">
    <xsl:value-of select="false()" />
</xsl:template>
<!-- Knowl text is the "mark", a number with two thin spaces -->
<xsl:template match="fn" mode="hidden-knowl-text">
    <sup>
    <xsl:text>&#x2009;</xsl:text>
    <xsl:apply-templates select="." mode="serial-number" />
    <xsl:text>&#x2009;</xsl:text>
    </sup>
</xsl:template>
<!-- Head is the named number -->
<xsl:template match="fn" mode="head">
    <span class="heading">
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
        <xsl:text> </xsl:text>
        <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
    </span>
</xsl:template>
<!-- Body is just all content -->
<xsl:template match="fn" mode="body">
    <xsl:apply-templates />
</xsl:template>
<!-- No posterior  -->
<xsl:template match="fn" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="fn" mode="environment-element">
    <xsl:text>span</xsl:text>
</xsl:template>
<xsl:template match="fn" mode="environment-class">
    <xsl:text>footnote</xsl:text>
</xsl:template>


<!-- References, Citations (biblio) -->
<!-- Never born hidden -->
<xsl:template match="biblio" mode="is-hidden">
    <xsl:value-of select="false()" />
</xsl:template>
<!-- Always in a list item -->
<xsl:template match="biblio" mode="is-block-env">
    <xsl:value-of select="false()" />
</xsl:template>
<!-- Never hidden so calling hidden-knowl-text raises error -->
<!-- There is no head -->
<xsl:template match="biblio" mode="head" />
<!-- Body is all the content -->
<xsl:template match="biblio" mode="body">
    <div class="bibitem">
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="." mode="serial-number" />
        <xsl:text>]</xsl:text>
    </div>
    <xsl:text>&#xa0;&#xa0;</xsl:text>
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


<!-- Examples, Remarks, List Wrappers -->
<!-- Individually customizable -->
<!-- Similar, as just runs of paragraphs -->
<xsl:template match="example" mode="is-hidden">
    <xsl:value-of select="$html.knowl.example = 'yes'" />
</xsl:template>
<xsl:template match="list" mode="is-hidden">
    <xsl:value-of select="$html.knowl.list = 'yes'" />
</xsl:template>
<xsl:template match="remark" mode="is-hidden">
    <xsl:value-of select="$html.knowl.remark = 'yes'" />
</xsl:template>
<xsl:template match="example|list|remark" mode="is-block-env">
    <xsl:value-of select="true()" />
</xsl:template>
<!-- Knowl-text is an article with heading -->
<xsl:template match="example|list|remark" mode="hidden-knowl-text">
    <article class="example-like">
        <h5 class="heading">
            <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
            <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
            <xsl:if test="title">
                <span class="title"><xsl:apply-templates select="." mode="title-full" /></span>
            </xsl:if>
        </h5>
    </article>
</xsl:template>
<!-- Head is type, number, title -->  <!-- GENERALIZE -->
<xsl:template match="example|list|remark" mode="head">
    <h5 class="heading">
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
        <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
        <xsl:if test="title">
            <span class="title"><xsl:apply-templates select="." mode="title-full" /></span>
        </xsl:if>
    </h5>
</xsl:template>
<!-- Body is just all content, but no title -->
<xsl:template match="example|list|remark" mode="body">
    <xsl:apply-templates select="*"/>
</xsl:template>
<!-- No posterior  -->
<xsl:template match="example|list|remark" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="example|list|remark" mode="environment-element">
    <xsl:text>article</xsl:text>
</xsl:template>
<xsl:template match="example|list|remark" mode="environment-class">
    <xsl:text>example-like</xsl:text>
</xsl:template>

<!-- Definitions, etc. -->
<!-- Customizable as hidden    -->
<!-- A statement without proof -->
<xsl:template match="definition|axiom|conjecture|principle" mode="is-hidden">
    <xsl:value-of select="$html.knowl.definition = 'yes'" />
</xsl:template>
<xsl:template match="definition|axiom|conjecture|principle" mode="is-block-env">
    <xsl:value-of select="true()" />
</xsl:template>
<!-- Knowl-text is an article with heading -->
<xsl:template match="definition|axiom|conjecture|principle" mode="hidden-knowl-text">
    <article class="definition-like">
        <h5 class="heading">
            <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
            <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
            <xsl:if test="title">
                <span class="title"><xsl:apply-templates select="." mode="title-full" /></span>
            </xsl:if>
        </h5>
    </article>
</xsl:template>
<!-- Head is type, number, title -->  <!-- GENERALIZE -->
<xsl:template match="definition|axiom|conjecture|principle" mode="head">
    <h5 class="heading">
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
        <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
        <xsl:if test="title">
            <span class="title"><xsl:apply-templates select="." mode="title-full" /></span>
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
<xsl:template match="theorem|corollary|lemma|algorithm|proposition|claim|fact" mode="is-hidden">
    <xsl:value-of select="$html.knowl.theorem = 'yes'" />
</xsl:template>
<xsl:template match="theorem|corollary|lemma|algorithm|proposition|claim|fact" mode="is-block-env">
    <xsl:value-of select="true()" />
</xsl:template>
<!-- Knowl-text is an article with heading -->
<xsl:template match="theorem|corollary|lemma|algorithm|proposition|claim|fact" mode="hidden-knowl-text">
    <article class="theorem-like">
        <h5 class="heading">
            <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
            <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
            <xsl:if test="title">
                <span class="title"><xsl:apply-templates select="." mode="title-full" /></span>
            </xsl:if>
        </h5>
    </article>
</xsl:template>
<!-- Head is type, number, title -->  <!-- GENERALIZE -->
<xsl:template match="theorem|corollary|lemma|algorithm|proposition|claim|fact" mode="head">
    <h5 class="heading">
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
        <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
        <xsl:if test="title">
            <span class="title"><xsl:apply-templates select="." mode="title-full" /></span>
        </xsl:if>
    </h5>
</xsl:template>
<!-- Body is just the statement -->
<xsl:template match="theorem|corollary|lemma|algorithm|proposition|claim|fact" mode="body">
    <xsl:apply-templates select="statement" />
</xsl:template>
<!-- Posterior is just the proof -->
<xsl:template match="theorem|corollary|lemma|algorithm|proposition|claim|fact" mode="posterior">
    <xsl:apply-templates select="proof" />
</xsl:template>
<!-- HTML, CSS -->
<xsl:template match="theorem|corollary|lemma|algorithm|proposition|claim|fact" mode="environment-element">
    <xsl:text>article</xsl:text>
</xsl:template>
<xsl:template match="theorem|corollary|lemma|algorithm|proposition|claim|fact" mode="environment-class">
    <xsl:text>theorem-like</xsl:text>
</xsl:template>

<!-- Proof -->
<!-- Customizable as hidden -->
<xsl:template match="proof" mode="is-hidden">
    <xsl:value-of select="$html.knowl.proof = 'yes'" />
</xsl:template>
<xsl:template match="proof" mode="is-block-env">
    <xsl:value-of select="true()" />
</xsl:template>
<!-- Knowl-text is an article with simple heading and hidden class -->
<xsl:template match="proof" mode="hidden-knowl-text">
    <article class="hiddenproof">
        <h5 class="heading">
            <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
        </h5>
    </article>
</xsl:template>
<!-- Head is just the type                       -->
<!-- We do not ask for a number or title         -->
<!-- TODO: Maybe "Proof of" when not in theorem? -->
<xsl:template match="proof" mode="head">
    <h5 class="heading">
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
    </h5>
</xsl:template>
<!-- Body is everything (no title?) -->
<xsl:template match="proof" mode="body">
    <xsl:apply-templates />
</xsl:template>
<!-- No posterior  -->
<xsl:template match="proof" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="proof" mode="environment-element">
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


<!-- Figures, Tables, entire Side-By-Side Panels     -->
<!-- Figures, Tables from within Side-By-Side Panels -->
<!-- Individually customizable, but otherwise very similar                 -->
<!-- This includes figures and tables contained within side-by-side panels -->
<!-- They are never born as knowls, but their content can be displayed     -->
<!-- as a knowl when the target of a cross-reference                       -->
<xsl:template match="figure" mode="is-hidden">
    <xsl:value-of select="$html.knowl.figure = 'yes'" />
</xsl:template>
<xsl:template match="table" mode="is-hidden">
    <xsl:value-of select="$html.knowl.table = 'yes'" />
</xsl:template>
<xsl:template match="listing" mode="is-hidden">
    <xsl:value-of select="$html.knowl.table = 'yes'" />
</xsl:template>
<xsl:template match="sidebyside" mode="is-hidden">
    <xsl:value-of select="$html.knowl.sidebyside = 'yes'" />
</xsl:template>
<xsl:template match="sidebyside/figure|sidebyside/table" mode="is-hidden">
    <xsl:value-of select="false()" />
</xsl:template>
<xsl:template match="figure|table|listing|sidebyside" mode="is-block-env">
    <xsl:value-of select="true()" />
</xsl:template>
<!-- Knowl-text is like a theorem, employs a title -->
<xsl:template match="figure|table|listing|sidebyside" mode="hidden-knowl-text">
    <article class="theorem-like">
        <h5 class="heading">
            <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
            <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
            <xsl:if test="title">
                <span class="title"><xsl:apply-templates select="." mode="title-full" /></span>
            </xsl:if>
        </h5>
    </article>
</xsl:template>
<!-- There is no head, a caption always appears in the body -->
<xsl:template match="figure|table|listing|sidebyside" mode="head" />
<!-- For tables or figures within a side-by-side:              -->
<!-- Born visible (ie within a side-by-side), we need some     -->
<!-- extra positioning CSS. In a knowl content file, we don't  -->
<!-- want the CSS in the way.  This is the motivating reason   -->
<!-- for parameterizing the "head" template.  Conveniently the -->
<!-- CSS lands just below the outer-most enclosing element.    -->
<xsl:template match="sidebyside/figure|sidebyside/table" mode="head">
    <xsl:param name="env-type" />
    <xsl:if test="$env-type='visible'">
        <xsl:call-template name="sidebysideCSS" select="."/>
    </xsl:if>
</xsl:template>
<!-- Body is just all content, followed by caption -->
<!-- Figure: just contents, caption -->
<!-- Table: wrapped in figure, tabular provides <table> -->
<xsl:template match="figure|table|listing|sidebyside" mode="body">
    <xsl:apply-templates select="*[not(self::caption)]"/>
    <xsl:apply-templates select="caption"/>
</xsl:template>
<!-- No posterior  -->
<xsl:template match="figure|table|listing|sidebyside" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="figure|table|listing" mode="environment-element">
    <xsl:text>figure</xsl:text>
</xsl:template>
<xsl:template match="sidebyside" mode="environment-element">
    <xsl:text>div</xsl:text>
</xsl:template>
<xsl:template match="figure|table|listing" mode="environment-class">
    <xsl:text>figure-like</xsl:text>
</xsl:template>
<xsl:template match="sidebyside" mode="environment-class">
    <xsl:text>sidebyside</xsl:text>
</xsl:template>

<!-- Display Mathematics -->
<!-- We make knowls of all four types of display mathematics        -->
<!-- We likely will never reference an <me> (no xml:id, or number), -->
<!-- but an <men> is perfectly natural.   For <md>, <mdn> the       -->
<!-- <mrow> carry the xml:id and possible numbers, but we show      -->
<!-- the whole display. NB: the trick is in the filename of an      -->
<!-- mrow, it points to the enclosing display filename              -->
<!-- NB: we could put an xml:id on a display, but it has no         -->
<!-- title or number, so there is no way to reference it,           -->
<!-- nor can LaTeX accomplish this (right?)                         -->
<xsl:template match="me|men|md|mdn" mode="is-hidden">
    <xsl:value-of select="false()" />
</xsl:template>
<xsl:template match="me|men|md|mdn" mode="is-block-env">
    <xsl:value-of select="false()" />
</xsl:template>
<!-- Never hidden so calling hidden-knowl-text raises error -->
<!-- There is no head ever -->
<xsl:template match="me|men|md|mdn" mode="head" />
<!-- Bodies of display mathematics         -->
<!--   More complicated, so isolated below -->
<!-- There is no posterior -->
<xsl:template match="me|men|md|mdn" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="me|men|md|mdn" mode="environment-element">
    <xsl:text>div</xsl:text>
</xsl:template>
<xsl:template match="me|men|md|mdn" mode="environment-class">
    <xsl:text>displaymath</xsl:text>
</xsl:template>

<!-- Simple environments -->
<!-- All subsidiary to some other environment  -->
<!-- Exercises: Hints, Answers, Solutions      -->
<!-- Bibliographic notes                       -->
<!-- Help with exercises are always hidden     -->
<!-- Notes on biblio are always hidden         -->
<xsl:template match="hint|answer|solution|note" mode="is-hidden">
    <xsl:value-of select="true()" />
</xsl:template>
<xsl:template match="hint|answer|solution|note" mode="is-block-env">
    <xsl:value-of select="false()" />
</xsl:template>
<!-- Knowl text is simply the type             -->
<xsl:template match="hint|answer|solution|note" mode="hidden-knowl-text">
    <span class="heading">
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
    </span>
</xsl:template>
<!-- Head is just the type                     -->
<!-- We do not ask for a number or title       -->
<!-- We do not use "h5" as we want low-profile -->
<xsl:template match="hint|answer|solution|note" mode="head">
    <span class="heading">
        <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
        <xsl:text> </xsl:text>
        <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
    </span>
</xsl:template>
<!-- Body is everything (no title?) -->
<xsl:template match="hint|answer|solution|note" mode="body">
    <xsl:apply-templates />
</xsl:template>
<!-- No posterior  -->
<xsl:template match="hint|answer|solution|note" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="hint|answer|solution|note" mode="environment-element">
    <xsl:text>span</xsl:text>
</xsl:template>
<xsl:template match="hint|answer|solution|note" mode="environment-class">
    <xsl:text>solution</xsl:text>
</xsl:template>

<!-- Exercise Group -->
<!-- We interrupt a list of exercises with short commentary, -->
<!-- typically instructions for a list of similar exercises  -->
<!-- Commentary goes in an introduction and/or conclusion    -->
<!-- Available as a xref knowl, but never born hidden        -->
<xsl:template match="exercisegroup" mode="is-hidden">
    <xsl:value-of select="false()" />
</xsl:template>
<xsl:template match="exercisegroup" mode="is-block-env">
    <xsl:value-of select="true()" />
</xsl:template>
<!-- Never hidden so calling hidden-knowl-text raises error -->
<!-- There is no head ever -->
<xsl:template match="exercisegroup" mode="head" />
<!-- Body is just all content             -->
<!-- introducttion, exercises, conclusion -->
<xsl:template match="exercisegroup" mode="body">
    <xsl:apply-templates />
</xsl:template>
<!-- No posterior  -->
<xsl:template match="exercisegroup" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="exercisegroup" mode="environment-element">
    <xsl:text>div</xsl:text>
</xsl:template>
<xsl:template match="exercisegroup" mode="environment-class">
    <xsl:text>exercisegroup</xsl:text>
</xsl:template>

<!-- Exercises -->
<!-- TODO: switches for inline versus sectional -->
<xsl:template match="exercise" mode="is-hidden">
    <xsl:value-of select="$html.knowl.exercise.inline = 'yes'" />
</xsl:template>
<xsl:template match="exercises//exercise" mode="is-hidden">
    <xsl:value-of select="$html.knowl.exercise.sectional = 'yes'" />
</xsl:template>
<!-- does block form work in "exercises" section -->
<xsl:template match="exercise" mode="is-block-env">
    <xsl:value-of select="true()" />
</xsl:template>
<!-- Knowl text has simpler number at appearance in division -->
<xsl:template match="exercises//exercise" mode="hidden-knowl-text">
    <h5 class="heading">
    <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
    <xsl:text> </xsl:text>
    <span class="codenumber"><xsl:apply-templates select="." mode="serial-number" /></span>
    <xsl:if test="title">
        <xsl:text> </xsl:text>
        <span class="title"><xsl:apply-templates select="." mode="title-full" /></span>
    </xsl:if>
    </h5>
</xsl:template>
<xsl:template match="exercise" mode="hidden-knowl-text">
    <h5 class="heading">
    <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
    <xsl:text> </xsl:text>
    <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
    <xsl:if test="title">
        <xsl:text> </xsl:text>
        <span class="title"><xsl:apply-templates select="." mode="title-full" /></span>
    </xsl:if>
    </h5>
</xsl:template>
<!-- Simpler head for sectional exercise -->
<xsl:template match="exercises//exercise" mode="head">
    <h5 class="heading">
    <span class="codenumber"><xsl:apply-templates select="." mode="serial-number" /></span>
    <xsl:if test="title">
        <xsl:text> </xsl:text>
        <span class="title"><xsl:apply-templates select="." mode="title-full" /></span>
    </xsl:if>
    </h5>
</xsl:template>
<xsl:template match="exercise" mode="head">
    <h5 class="heading">
    <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
    <xsl:text> </xsl:text>
    <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
    <xsl:if test="title">
        <xsl:text> </xsl:text>
        <span class="title"><xsl:apply-templates select="." mode="title-full" /></span>
    </xsl:if>
    </h5>
</xsl:template>
<!-- Body is statement normally, but for WeBWorK -->
<!-- body is introduction, webwork, conclusion   -->
<!-- (ignoring .text switches for WW!)           -->
<xsl:template match="exercise[child::statement]" mode="body">
    <xsl:apply-templates select="statement"/>
</xsl:template>
<xsl:template match="exercise[child::webwork]" mode="body">
    <xsl:apply-templates select="statement"/>
    <xsl:apply-templates select="introduction"/>
    <xsl:apply-templates select="webwork" mode="knowlized" />
    <xsl:apply-templates select="conclusion"/>
</xsl:template>
<!-- Posterior: links to information  -->
<xsl:template match="exercise" mode="posterior">
    <xsl:variable name="hint-visible">
        <xsl:value-of select="$exercise.text.hint='yes'" />
    </xsl:variable>
    <xsl:variable name="answer-visible">
        <xsl:value-of select="$exercise.text.answer='yes'" />
    </xsl:variable>
    <xsl:variable name="solution-visible">
        <xsl:value-of select="$exercise.text.solution='yes'" />
    </xsl:variable>
    <!-- Order enforced: hint, answer, solution                   -->
    <!-- wrapped in a div to get these to open in proper location -->
    <div class="hidden-knowl-wrapper">
        <xsl:if test="$hint-visible='true'">
            <xsl:apply-templates select="hint"/>
        </xsl:if>
        <xsl:if test="$answer-visible='true'">
            <xsl:apply-templates select="answer"/>
        </xsl:if>
        <xsl:if test="$solution-visible='true'">
            <xsl:apply-templates select="solution"/>
        </xsl:if>
    </div>
</xsl:template>
<!-- HTML, CSS -->
<xsl:template match="exercise" mode="environment-element">
    <xsl:text>article</xsl:text>
</xsl:template>
<xsl:template match="exercise" mode="environment-class">
    <xsl:text>exercise-like</xsl:text>
</xsl:template>

<!-- List Items -->
<!-- Never born hidden -->
<xsl:template match="li" mode="is-hidden">
    <xsl:value-of select="false()" />
</xsl:template>
<xsl:template match="li" mode="is-block-env">
    <xsl:value-of select="true()" />
</xsl:template>
<!-- List items are never born hidden -->
<xsl:template match="li" mode="hidden-knowl-text" />
<!-- ??????? -->
<xsl:template match="li" mode="head">
    <h5 class="heading">
    <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
    <xsl:text> </xsl:text>
    <span class="codenumber"><xsl:apply-templates select="." mode="serial-number" /></span>
    <xsl:if test="title">
        <xsl:text> </xsl:text>
        <span class="title"><xsl:apply-templates select="." mode="title-full" /></span>
    </xsl:if>
    </h5>
</xsl:template>
<!-- Body is everything, including nested lists -->
<!-- TODO: maybe something is missing here, style of label, etc -->
<xsl:template match="li" mode="body">
    <!-- TODO: this needs formatting, insertion into first paragraph -->
    <xsl:if test="parent::dl">
        <xsl:apply-templates select="." mode="title-full" />
    </xsl:if>
    <xsl:apply-templates />
</xsl:template>
<!-- No posterior  -->
<xsl:template match="li" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="li" mode="environment-element">
    <xsl:text>article</xsl:text>
</xsl:template>
<xsl:template match="li" mode="environment-class">
    <xsl:text>list</xsl:text>
</xsl:template>

<!-- Contributors -->
<!-- Never born hidden -->
<xsl:template match="contributor" mode="is-hidden">
    <xsl:value-of select="false()" />
</xsl:template>
<!-- Always in a list -->
<xsl:template match="contributor" mode="is-block-env">
    <xsl:value-of select="false()" />
</xsl:template>
<!-- Never hidden so calling hidden-knowl-text raises error -->
<!-- Side-By-Side divs -->
<!-- http://stackoverflow.com/questions/17217766/two-divs-side-by-side-fluid-display -->
<!-- There head is the person's name -->
<xsl:template match="contributor" mode="head">
    <xsl:comment>Style Me (contributor-name)</xsl:comment>
    <div style="width:40%;float:left;">
        <xsl:value-of select="personname" />
    </div>
</xsl:template>
<!-- Body is the identifying info for the contributor -->
<xsl:template match="contributor" mode="body">
    <xsl:comment>Style Me (contributor-info)</xsl:comment>
    <div style="margin-left:40%;">
        <xsl:apply-templates select="department" />
        <br />
        <xsl:apply-templates select="institution" />
    </div>
</xsl:template>
<!-- No posterior  -->
<xsl:template match="contributor" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="contributor" mode="environment-element">
    <xsl:text>div</xsl:text>
</xsl:template>
<xsl:template match="contributor" mode="environment-class">
    <xsl:text>contributor</xsl:text>
</xsl:template>

<!-- Paragraphs -->
<!-- Never born hidden                         -->
<!-- Necessary as targets of index entries     -->
<!-- and stealth knowls for defined terms      -->
<!-- Following is just used for knowl creation -->
<xsl:template match="p" mode="is-hidden">
    <xsl:value-of select="false()" />
</xsl:template>
<xsl:template match="p" mode="is-block-env">
    <xsl:value-of select="true()" />
</xsl:template>
<!-- Paragraphs are never born hidden -->
<xsl:template match="p" mode="hidden-knowl-text" />
<!-- ??????? -->
<xsl:template match="p" mode="head">
    <h5 class="heading">
    <span class="type"><xsl:apply-templates select="." mode="type-name" /></span>
    </h5>
</xsl:template>
<!-- Body is everything -->
<xsl:template match="p" mode="body">
    <xsl:apply-templates />
</xsl:template>
<!-- No posterior  -->
<xsl:template match="p" mode="posterior" />
<!-- HTML, CSS -->
<xsl:template match="p" mode="environment-element">
    <xsl:text>article</xsl:text>
</xsl:template>
<xsl:template match="p" mode="environment-class">
    <xsl:text>paragraph</xsl:text>
</xsl:template>

<!-- ########################## -->
<!-- Mathematics (HTML/MathJax) -->
<!-- ########################## -->

<!-- Since MathJax interprets a large subset of LaTeX,   -->
<!-- there are only subtle differences between LaTeX     -->
<!-- and HTML output.  See LaTeX- and HTML-specific       -->
<!-- templates for intertext elements and the numbering   -->
<!-- of equations (automatic for LaTeX, managed for HTML) -->

<!-- Numbering -->
<!-- We manually "tag" numbered equations in HTML output,       -->
<!-- with the exact same numbers that LaTeX would provide       -->
<!-- automatically.  We also "\label{}" the equations where     -->
<!-- they are born, and then the MathJax configuration          -->
<!-- provides a predictable HTML anchor so our cross-reference  -->
<!-- scheme can point to the right place.  The implies that we  -->
<!-- do not need/want to "\label{}" equations in knowl files    -->
<!-- serving as cross-references.  And indeed, including        -->
<!-- labels in cross-reference knowls led to a serious bug.     -->
<!-- https://github.com/rbeezer/mathbook/issues/143             -->

<!-- NOTE -->
<!-- The remainder should look very similar to that   -->
<!-- of the LaTeX/MathJax version in terms of result. -->
<!-- Notably, "intertext" elements are implemented    -->
<!-- differently, and we need to be careful not to    -->
<!-- place LaTeX "\label{}" in know'ed content.       -->

<!-- Inline Math -->
<!-- See the common file for the universal "m" template -->

<!-- Bodies of Displayed Math -->
<!-- These modal templates are called by -->
<!-- the environment/knowl scheme above  -->

<!-- Single displayed equation, unnumbered -->
<!-- Output follows source line breaks     -->
<!-- MathJax: out-of-the-box support       -->
<xsl:template match="me" mode="body">
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="." mode="displaymath-alignment" />
    <xsl:text>}</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="." mode="displaymath-alignment" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Single displayed equation, numbered -->
<!-- MathJax: out-of-the-box support     -->
<!-- Requires a manual tag for number    -->
<xsl:template match="men" mode="body">
    <xsl:param name="env-type" />
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="." mode="displaymath-alignment" />
    <xsl:text>}</xsl:text>
    <xsl:value-of select="." />
    <!-- Needs label{} at birth, NOT in xref knowl -->
    <xsl:if test="$env-type='visible' or $env-type='hidden'">
        <xsl:apply-templates select="." mode="label" />
    </xsl:if>
    <xsl:apply-templates select="." mode="tag" />
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="." mode="displaymath-alignment" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Multi-Line Math -->
<!-- Multi-line displayed equations container, globally unnumbered or numbered   -->
<!-- mrow logic controls numbering, based on variant here, and per-row overrides -->
<!-- align environment if ampersands are present, gather environment otherwise   -->
<!-- NB: *identical* to LaTeX version, but for mode and knowl-type parameter     -->
<xsl:template match="md|mdn" mode="body">
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="." mode="displaymath-alignment" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="mrow|intertext" />
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="." mode="displaymath-alignment" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Rows of a multi-line math display                 -->
<!-- (1) MathJax config above turns off all numbering  -->
<!-- (2) Numbering supplied by \tag{}                  -->
<!-- (3) MathJax config makes span id's predictable    -->
<!-- (4) Last row special, has no line-break marker    -->
<xsl:template match="md/mrow">
    <xsl:param name="env-type" />
    <xsl:apply-templates select="text()|xref|var" />
    <xsl:if test="@number='yes'">
        <!-- Needs label{} at birth, NOT in xref knowl -->
        <xsl:if test="$env-type='visible' or $env-type='hidden'">
            <xsl:apply-templates select="." mode="label" />
        </xsl:if>
        <xsl:apply-templates select="." mode="tag"/>
    </xsl:if>
    <xsl:if test="following-sibling::mrow">
       <xsl:text>\\</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="mdn/mrow">
    <xsl:param name="env-type" />
    <xsl:apply-templates select="text()|xref|var" />
    <xsl:choose>
        <xsl:when test="@number='no'">
            <xsl:text>\notag</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <!-- Needs label{} at birth, NOT in xref knowl -->
            <xsl:if test="$env-type='visible' or $env-type='hidden'">
                <xsl:apply-templates select="." mode="label" />
            </xsl:if>
            <xsl:apply-templates select="." mode="tag"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="following-sibling::mrow">
       <xsl:text>\\</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Math Utilities -->

<!-- Manual Number Tagging -->
<!-- We do "tag" numbered equations in MathJax output, -->
<!-- because we want to control and duplicate the way  -->
<!-- numbers are generated and assigned by LaTeX       -->
<xsl:template match="men|mrow" mode="tag">
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Intertext -->
<!-- A LaTeX construct really, we just jump out/in of             -->
<!-- the align/gather environment and package the text            -->
<!-- in an HTML paragraph, assuming it is just a snippet.         -->
<!-- This breaks the alignment, but MathJax has no good           -->
<!-- solution for this.                                           -->
<!-- We need * (md=no numbers), and plain (mdn=numbers) variants, -->
<!-- together with aligned (& present) or gather (no & present).  -->
<!-- NB: we check the *parent* for alignment                      -->
<xsl:template match="md/intertext|mdn/intertext">
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select=".." mode="displaymath-alignment" />
    <xsl:text>}&#xa;</xsl:text>
    <p>
        <xsl:apply-templates />
    </p>
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select=".." mode="displaymath-alignment" />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>


<!-- ########### -->
<!-- HTML Markup -->
<!-- ########### -->

<!-- Paragraph -->
<!-- An id is needed as target of in-context links  -->
<!-- that arise from knowling paragraphs routinely  -->
<!-- for notation, term index cross-references      -->
<!-- A single paragraph within a side-by-side       -->
<!-- panel will carry positioning CSS               -->
<xsl:template match="p">
    <xsl:element name="p">
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:attribute>
        <xsl:if test="parent::sidebyside">
            <xsl:call-template name="sidebysideCSS" select="."/>
        </xsl:if>
        <xsl:apply-templates />
    </xsl:element>
</xsl:template>

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Utility templates to translate MBX              -->
<!-- enumeration style to HTML list-style-type       -->
<!-- NB: this is currently inferior to latex version -->
<!-- NB: all pre-, post-formatting is lost           -->
<xsl:template match="ol" mode="html-list-label">
    <xsl:variable name="mbx-format-code">
        <xsl:apply-templates select="." mode="format-code" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$mbx-format-code = '1'">decimal</xsl:when>
        <xsl:when test="$mbx-format-code = 'a'">lower-alpha</xsl:when>
        <xsl:when test="$mbx-format-code = 'A'">upper-alpha</xsl:when>
        <xsl:when test="$mbx-format-code = 'i'">lower-roman</xsl:when>
        <xsl:when test="$mbx-format-code = 'I'">upper-roman</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: bad MBX ordered list label format code in HTML conversion</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="ul" mode="html-list-label">
    <xsl:variable name="mbx-format-code">
        <xsl:apply-templates select="." mode="format-code" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$mbx-format-code = 'disc'">disc</xsl:when>
        <xsl:when test="$mbx-format-code = 'circle'">circle</xsl:when>
        <xsl:when test="$mbx-format-code = 'square'">square</xsl:when>
        <xsl:when test="$mbx-format-code = 'none'">none</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: bad MBX unordered list label format code in HTML conversion</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Lists themselves -->
<!-- Hard-code the list style, trading on match  -->
<!-- in label templates. When columns are        -->
<!-- specified, float items and clear afterwards -->
<!-- NB: an  xsl:copy  makes namespace confusion -->
<xsl:template match="ol">
    <ol>
        <xsl:attribute name="style">
            <xsl:text>list-style-type: </xsl:text>
                <xsl:apply-templates select="." mode="html-list-label" />
            <xsl:text>;</xsl:text>
        </xsl:attribute>
        <xsl:choose>
            <xsl:when test="@cols">
                <xsl:apply-templates select="li" mode="variable-width">
                    <xsl:with-param name="percent-width" select="98 div @cols" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="li" />
            </xsl:otherwise>
        </xsl:choose>
    </ol>
    <xsl:if test="@cols">
        <div style="clear:both;"></div>
    </xsl:if>
</xsl:template>

<xsl:template match="ul">
    <ul>
        <xsl:attribute name="style">
            <xsl:text>list-style-type: </xsl:text>
                <xsl:apply-templates select="." mode="html-list-label" />
            <xsl:text>;</xsl:text>
        </xsl:attribute>
        <xsl:choose>
            <xsl:when test="@cols">
                <xsl:apply-templates select="li" mode="variable-width">
                    <xsl:with-param name="percent-width" select="98 div @cols" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="li" />
            </xsl:otherwise>
        </xsl:choose>
    </ul>
    <xsl:if test="@cols">
        <div style="clear:both;"></div>
    </xsl:if>
</xsl:template>

<!-- Pass-through regular list items    -->
<!-- Allow paragraphs in larger items,  -->
<!-- or just snippets for smaller items -->
<!-- List items should migrate to knowlization framework -->
<xsl:template match="li">
    <xsl:element name="li">
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:attribute>
        <!-- TODO: this needs formatting, insertion into first paragraph -->
        <xsl:if test="parent::dl">
            <xsl:apply-templates select="." mode="title-full" />
        </xsl:if>
        <xsl:apply-templates />
    </xsl:element>
</xsl:template>

<!-- List items in HTML need to float with fractional widths -->
<xsl:template match="li" mode="variable-width">
    <xsl:param name="percent-width" />
    <xsl:element name="li">
        <xsl:attribute name="style">
            <xsl:text>width:</xsl:text><xsl:value-of select="$percent-width" /><xsl:text>%; float:left;</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:attribute>
        <!-- TODO: this needs formatting, insertion into first paragraph -->
        <xsl:if test="parent::dl">
            <xsl:apply-templates select="." mode="title-full" />
        </xsl:if>
       <xsl:apply-templates />
    </xsl:element>
</xsl:template>

<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- With a @source attribute, without an extension, -->
<!--   we presume an SVG has been manufactured       -->
<!-- With a @source attribute, with an extension,    -->
<!--   we write an HTML "img" tag with attributes    -->
<xsl:template match="image[@source]" >
    <!-- condition on file extension -->
    <xsl:variable name="extension">
        <xsl:call-template name="file-extension">
            <xsl:with-param name="filename" select="@source" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
        <!-- no extension, presume SVG manufactured -->
        <!-- TODO: pass along side-by-side CSS somehow -->
        <xsl:when test="$extension=''">
            <xsl:call-template name="svg-wrapper">
                <xsl:with-param name="svg-filename">
                    <xsl:value-of select="@source" />
                    <xsl:text>.svg</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="png-fallback-filename" />
                <xsl:with-param name="image-width">
                    <xsl:choose>
                        <xsl:when test="@width">
                            <xsl:value-of select="@width" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>90%</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
                <xsl:with-param name="image-description">
                    <xsl:apply-templates select="description" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:when>
        <!-- with extension, just include it -->
        <xsl:otherwise>
            <xsl:element name="img">
                <!-- side-by-side extras with width, or plain width attribute-->
                <xsl:choose>
                    <!-- put CSS on bare image as a side-by-side panel -->
                    <!-- a width CSS rule that comes from this always  -->
                    <xsl:when test="ancestor::sidebyside and not(ancestor::figure)">
                        <xsl:call-template name="sidebysideCSS" select="."/>
                    </xsl:when>
                    <xsl:when test="@width">
                        <xsl:attribute name="width">
                            <xsl:value-of select="@width" />
                        </xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="width">
                            <xsl:text>90%</xsl:text>
                        </xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- TODO: abandon, deprecate height specification (along with LaTeX code) -->
                <xsl:if test="@height">
                    <xsl:attribute name="height"><xsl:value-of select="@height" /></xsl:attribute>
                </xsl:if>
                <xsl:attribute name="src">
                    <xsl:value-of select="@source" />
                </xsl:attribute>
                <!-- alt attribute for accessibility -->
                <xsl:attribute name="alt">
                    <xsl:apply-templates select="description" />
                </xsl:attribute>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A plain image is just a light wrapper and content -->
<!-- describes the image type and dictates result      -->
<xsl:template match="image">
    <xsl:apply-templates select="asymptote|sageplot|latex-image-code" />
</xsl:template>

<!-- SVG's produced by mbx script                  -->
<!--   Asymptote graphics language                 -->
<!--   LaTeX source code images                    -->
<!--   Sage graphics plots, w/ PNG fallback for 3D -->
<xsl:template match="image/asymptote|image/latex-image-code|image/sageplot">
    <xsl:call-template name="svg-wrapper">
        <xsl:with-param name="svg-filename">
            <xsl:value-of select="$directory.images" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select=".." mode="internal-id" />
            <xsl:text>.svg</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="png-fallback-filename">
            <xsl:if test="self::sageplot">
                <xsl:value-of select="$directory.images" />
                <xsl:text>/</xsl:text>
                <xsl:apply-templates select=".." mode="internal-id" />
                <xsl:text>.png</xsl:text>
            </xsl:if>
        </xsl:with-param>
        <xsl:with-param name="image-width">
            <xsl:choose>
                <xsl:when test="../@width">
                    <xsl:value-of select="../@width" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>90%</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="image-description">
            <xsl:apply-templates select="../description" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- A named template creates the infrastructure for an SVG image -->
<!-- Parameters -->
<!-- svg-filename: required, full relative path -->
<!-- png-fallback-filename: optional -->
<!-- image-width: required -->
<!-- image-description: optional -->
<xsl:template name="svg-wrapper">
    <xsl:param name="svg-filename" />
    <xsl:param name="png-fallback-filename" select="''" />
    <xsl:param name="image-width" />
    <xsl:param name="image-description" select="''" />
    <xsl:element name="object">
        <!-- type attribute for object element -->
        <xsl:attribute name="type">image/svg+xml</xsl:attribute>
        <!-- style attribute, should be class + CSS -->
        <xsl:attribute name="style">
            <xsl:text>width:</xsl:text>
            <xsl:value-of select="$image-width" />
            <xsl:text>; </xsl:text>
            <xsl:text>margin:auto; display:block;</xsl:text>
        </xsl:attribute>
        <!-- data attribute for object element, the SVG image -->
        <xsl:attribute name="data">
            <xsl:value-of select="$svg-filename" />
        </xsl:attribute>
        <!-- alt attribute for accessibility -->
        <xsl:attribute name="alt">
            <xsl:value-of select="$image-description" />
        </xsl:attribute>
        <!-- content is PNG fallback, if available, else message -->
        <xsl:choose>
            <xsl:when test="$png-fallback-filename = ''">
                <p style="margin:auto">&lt;&lt;SVG image is unavailable, or your browser cannot render it&gt;&gt;</p>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="img">
                    <xsl:attribute name="src">
                        <xsl:value-of select="$png-fallback-filename" />
                   </xsl:attribute>
                    <xsl:attribute name="width">
                        <xsl:value-of select="$image-width" />
                    </xsl:attribute>
                    <!-- alt attribute for accessibility -->
                    <xsl:attribute name="alt">
                        <xsl:value-of select="$image-description" />
                    </xsl:attribute>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:element>
</xsl:template>

<!-- LaTeX standalone image              -->
<!-- Deprecated when not inside an image -->
<!-- But it gets processed anyway        -->
<xsl:template match="latex-image-code">
    <xsl:message>MBX WARNING: latex-image-code element should be enclosed by an image element</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
</xsl:template>

<!-- ################### -->
<!-- Side-By-Side Panels -->
<!-- ################### -->

<!-- A side-by-side panel has objects aligned across a page. -->
<!-- There are six elements which may be included within:    -->
<!--                                                         -->
<!-- (a) figures and tables: with/without captions, possibly -->
<!--     targets of cross-references (carrying an xml:id),   -->
<!--     and so are knowlized for cross-references, but      -->
<!--     will never appear as knowls within a side-by-side   -->
<!--     listings are not implemented, but could be          -->
<!-- (b) paragraphs: exceptional, no caption, not knowlized  -->
<!-- (c) image, tabular, p: more fundamental, no captions,   -->
<!--     no numbers, etc., and so not knowlized              -->
<!--                                                         -->
<!-- The entire panel may be born as a knowl, and is         -->
<!-- knowlized as a potential target of a cross-reference.   -->

<!-- To position an item within a panel, the element may       -->
<!-- have additional atributes.  This template *must* follow   -->
<!-- an <xsl:element name="XYX"> statement for the outer-most  -->
<!-- enclosing HTML of the panel's content.  You will see this -->
<!-- template employed conditionally in a variety of places.   -->
<!-- Adding:                                                   -->
<!--   class="left|middle|right"                               -->
<!--   style="width=@width;                                    -->
<!--          vertical-align=@valign;                          -->
<!--          ext-align=@halign"                               -->

<!-- TODO: study "image" template and consolidate -->
<!-- TODO: convert to a match="" template and break up conditionals -->
<xsl:template name="sidebysideCSS">
  <!-- paragraphs have their own class -->
  <xsl:if test="not(self::paragraphs)">
    <xsl:choose>
        <!-- first child is class="left" -->
        <xsl:when test="not(preceding-sibling::figure or preceding-sibling::image or preceding-sibling::paragraphs or preceding-sibling::p or preceding-sibling::table or preceding-sibling::tabular)">
          <xsl:attribute name="class">left</xsl:attribute>
        </xsl:when>
        <!-- last child is class="right" -->
        <xsl:when test="not(following-sibling::figure or following-sibling::image or following-sibling::paragraphs or following-sibling::p or following-sibling::table or following-sibling::tabular)">
          <xsl:attribute name="class">right</xsl:attribute>
        </xsl:when>
        <!-- middle children are class="middle" -->
        <xsl:otherwise>
          <xsl:attribute name="class">middle</xsl:attribute>
        </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
  <xsl:attribute name="style">
  <xsl:text>width:</xsl:text>
  <!-- if width is defined, then use it -->
  <xsl:variable name="width">
    <xsl:choose>
      <xsl:when test="@width">
          <xsl:value-of select="substring-before(@width,'%')"/>
      </xsl:when>
      <xsl:otherwise>
          <!-- calculate widths that have been specified 
             and auto-print a remaining width -->
               <xsl:call-template name="printWidth" select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <!-- the width needs to be cut a small amount to allow a space between objects -->
  <xsl:value-of select="floor(($width)*.97)"/>
  <xsl:text>%</xsl:text>
  <xsl:text>;</xsl:text>
  <!-- vertical alignment option -->
  <xsl:text>vertical-align:</xsl:text>
  <xsl:choose>
    <xsl:when test="@valign">
      <xsl:value-of select="@valign"/>
    </xsl:when>
    <!-- default -->
    <xsl:otherwise>
      <xsl:text>bottom</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:text>;</xsl:text>
  <!-- horizontal alignment option -->
  <xsl:text>text-align:</xsl:text>
  <xsl:choose>
    <xsl:when test="@halign">
      <xsl:value-of select="@halign"/>
    </xsl:when>
    <!-- default -->
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="not(self::paragraphs or self::p)">
            <xsl:text>center</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>left</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:text>;</xsl:text>
  </xsl:attribute>
</xsl:template>


<!-- ################################## -->
<!-- Deprecated Graphics Code Templates -->
<!-- ################################## -->
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="tikz">
    <xsl:message>MBX:WARNING: tikz element superceded by latex-image-code element</xsl:message>
    <xsl:message>MBX:WARNING: tikz package and necessary libraries should be included in docinfo/latex-image-preamble</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
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
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="asymptote">
    <xsl:message>MBX:WARNING: asymptote element must be enclosed by an image element - deprecation (2015/02/08)</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
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
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="sageplot">
    <xsl:message>MBX:WARNING: sageplot element must be enclosed by an image element - deprecation (2015/02/08)</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
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
<!-- ################################## -->
<!-- Deprecated Graphics Code Templates -->
<!-- ################################## -->


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

<!-- ####### -->
<!-- Tabular -->
<!-- ####### -->

<!-- Top-down organization -->

<!-- A tabular layout, a naked table -->
<!-- Allowed to be placed various locations, but gets no              -->
<!-- vertical space etc, that is the container's responsibiility      -->
<!-- A sequence of rows, we ignore column group in applying templates -->
<!-- Realized as an HTML table                                        -->
<xsl:template match="tabular">
    <xsl:element name="table">
        <xsl:apply-templates select="row" />
    </xsl:element>
</xsl:template>

<!-- Slightly different handling within a side-by-side -->
<!-- TODO: experiment with:                 -->
<!-- (a) dropping figure element            -->
<!-- (b) place CSS onto the table element -->
<!-- (c) dropping the center class          -->
<xsl:template match="sidebyside/tabular">
    <xsl:element name="figure">
        <xsl:call-template name="sidebysideCSS" select="."/>
        <xsl:element name="table">
            <xsl:attribute name="class">center</xsl:attribute>
            <xsl:apply-templates select="row"/>
        </xsl:element>
    </xsl:element>
</xsl:template>

<!-- A row of table -->
<xsl:template match="row">
    <!-- Form the HTML table row -->
    <xsl:element name="tr">
        <!-- Walk the cells of the row -->
        <xsl:call-template name="row-cells">
            <xsl:with-param name="the-cell" select="cell[1]" />
            <xsl:with-param name="left-col" select="ancestor::tabular/col[1]" />  <!-- possibly empty -->
        </xsl:call-template>
    </xsl:element>
</xsl:template>

<xsl:template name="row-cells">
    <xsl:param name="the-cell" />
    <xsl:param name="left-col" />
    <!-- A cell may span several columns, or default to just 1              -->
    <!-- When colspan is not trivial, we identify the col elements          -->
    <!-- for the left and right ends of the span                            -->
    <!-- When colspan is trivial, the left and right versions are identical -->
    <!-- Left is used for left border and for horizontal alignment          -->
    <!-- Right is used for right border                                     -->
    <xsl:variable name="column-span">
        <xsl:choose>
            <xsl:when test="$the-cell/@colspan">
                <xsl:value-of select="$the-cell/@colspan" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- For a "normal" 1-column cell this variable effectively makes a copy -->
    <xsl:variable name="right-col" select="($left-col/self::*|$left-col/following-sibling::col)[position()=$column-span]" />
    <!-- Look ahead one column, anticipating recursion   -->
    <!-- but also probing for end of row (no more cells) -->
    <xsl:variable name="next-cell" select="$the-cell/following-sibling::cell[1]" />
    <xsl:variable name="next-col"  select="$right-col/following-sibling::col[1]" /> <!-- possibly empty -->
    <xsl:if test="$the-cell">
        <!-- build an HTML data cell, with CSS decorations              -->
        <!-- we set properties in various variables,                    -->
        <!-- then write them in a class attribute                       -->
        <!-- we look outward and upward for characteristics of the cell -->
        <!--                                                            -->
        <!-- horizontal alignment -->
        <xsl:variable name="alignment">
            <xsl:choose>
                <!-- cell attribute first -->
                <xsl:when test="$the-cell/@halign">
                    <xsl:value-of select="$the-cell/@halign" />
                </xsl:when>
                <!-- parent row attribute next -->
                <xsl:when test="$the-cell/ancestor::row/@halign">
                    <xsl:value-of select="$the-cell/ancestor::row/@halign" />
                </xsl:when>
                <!-- col attribute next -->
                <xsl:when test="$left-col/@halign">
                    <xsl:value-of select="$left-col/@halign" />
                </xsl:when>
                <!-- table attribute last -->
                <xsl:when test="$the-cell/ancestor::tabular/@halign">
                    <xsl:value-of select="$the-cell/ancestor::tabular/@halign" />
                </xsl:when>
                <!-- HTML default is left, we write it for consistency -->
                <xsl:otherwise>
                    <xsl:text>left</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- bottom borders -->
        <xsl:variable name="bottom">
            <xsl:choose>
                <!-- cell attribute first -->
                <xsl:when test="$the-cell/@bottom">
                    <xsl:value-of select="$the-cell/@bottom" />
                </xsl:when>
                <!-- parent row attribute next -->
                <xsl:when test="$the-cell/ancestor::row/@bottom">
                    <xsl:value-of select="$the-cell/ancestor::row/@bottom" />
                </xsl:when>
                <!-- not available on columns, table attribute last -->
                <xsl:when test="$the-cell/ancestor::tabular/@bottom">
                    <xsl:value-of select="$the-cell/ancestor::tabular/@bottom" />
                </xsl:when>
                <!-- default is none -->
                <xsl:otherwise>
                    <xsl:text>none</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- right borders -->
        <xsl:variable name="right">
            <xsl:choose>
                <!-- cell attribute first -->
                <xsl:when test="$the-cell/@right">
                    <xsl:value-of select="$the-cell/@right" />
                </xsl:when>
                <!-- not available on rows, col attribute next -->
                <xsl:when test="$right-col/@right">
                    <xsl:value-of select="$right-col/@right" />
                </xsl:when>
                <!-- table attribute last -->
                <xsl:when test="$the-cell/ancestor::tabular/@right">
                    <xsl:value-of select="$the-cell/ancestor::tabular/@right" />
                </xsl:when>
                <!-- default is none -->
                <xsl:otherwise>
                    <xsl:text>none</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- left borders -->
        <xsl:variable name="left">
            <xsl:choose>
                <!-- the first cell of the row, so may have left border -->
                <xsl:when test="not($the-cell/preceding-sibling::cell)">
                    <xsl:choose>
                        <!-- row attribute first -->
                        <xsl:when test="$the-cell/ancestor::row/@left">
                            <xsl:value-of select="$the-cell/ancestor::row/@left" />
                        </xsl:when>
                        <!-- table attribute last -->
                        <xsl:when test="$the-cell/ancestor::tabular/@left">
                            <xsl:value-of select="$the-cell/ancestor::tabular/@left" />
                        </xsl:when>
                        <!-- default is none -->
                        <xsl:otherwise>
                            <xsl:text>none</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- not the first cell of the row, so no left border -->
                <xsl:otherwise>
                    <xsl:text>none</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- top borders -->
        <xsl:variable name="top">
            <xsl:choose>
                <!-- the first row of the table, so may have top border -->
                <!-- http://ajaxandxml.blogspot.com/2006/11/xsl-detect-first-of-type-element-in.html -->
                <xsl:when test="not($the-cell/ancestor::row/preceding-sibling::row)">
                    <xsl:choose>
                        <!-- col attribute first -->
                        <xsl:when test="$left-col/@top">
                            <xsl:value-of select="$left-col/@top" />
                        </xsl:when>
                        <!-- table attribute last -->
                        <xsl:when test="$the-cell/ancestor::tabular/@top">
                            <xsl:value-of select="$the-cell/ancestor::tabular/@top" />
                        </xsl:when>
                        <!-- default is none -->
                        <xsl:otherwise>
                            <xsl:text>none</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- not the first cell of the row, so no left border -->
                <xsl:otherwise>
                    <xsl:text>none</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- the HTML element for the cell -->
        <xsl:element name="td">
            <!-- and the class attribute -->
            <xsl:attribute name="class">
                <!-- always write alignmant, so *precede* all subsequent with a space -->
                <xsl:call-template name="halign-specification">
                    <xsl:with-param name="align" select="$alignment" />
                </xsl:call-template>
                <!-- bottom border -->
                <xsl:text> b</xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="$bottom" />
                </xsl:call-template>
                <!-- right border -->
                <xsl:text> r</xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="$right" />
                </xsl:call-template>
                <!-- left border -->
                <xsl:text> l</xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="$left" />
                </xsl:call-template>
                <!-- top border -->
                <xsl:text> t</xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="$top" />
                </xsl:call-template>
            </xsl:attribute>
            <xsl:if test="not($column-span = 1)">
                <xsl:attribute name="colspan">
                    <xsl:value-of select="$column-span" />
                </xsl:attribute>
            </xsl:if>
            <!-- process the actual contents -->
            <xsl:apply-templates select="$the-cell" />
        </xsl:element>
        <!-- recurse forward, perhaps to an empty cell -->
        <xsl:call-template name="row-cells">
            <xsl:with-param name="the-cell" select="$next-cell" />
            <xsl:with-param name="left-col" select="$next-col" />
        </xsl:call-template>
    </xsl:if>
    <!-- Arrive here only when we have no cell so      -->
    <!-- we bail out of recursion with no action taken -->
</xsl:template>


<!-- ############################ -->
<!-- Table construction utilities -->
<!-- ############################ -->

<!-- Utilities are defined in xsl/mathbook-common.xsl -->

<!-- "thickness-specification" : param "width"    -->
<!--     none, minor, medium, major -> 0, 1, 2, 3 -->

<!-- "halign-specification" : param "width"       -->
<!--     left, right, center -> l, c, r           -->

<!-- ######## -->
<!-- Captions -->
<!-- ######## -->

<!-- Caption of a numbered figure, table or listing -->
<!-- All the relevant information is in the parent  -->
<xsl:template match="caption">
    <figcaption>
        <span class="heading">
            <xsl:apply-templates select="parent::*" mode="type-name"/>
        </span>
        <span class="codenumber">
            <xsl:apply-templates select="parent::*" mode="number"/>
        </span>
        <xsl:apply-templates />
    </figcaption>
</xsl:template>

<!-- Caption'ed sidebyside indicate subfigures and subtables are subsidiary -->
<!-- so we number with just their serial number, a formatted (a), (b), (c), -->
<xsl:template match="sidebyside[caption]/figure/caption|sidebyside[caption]/table/caption">
    <figcaption>
        <span class="codenumber">
            <xsl:apply-templates select="parent::*" mode="serial-number"/>
        </span>
        <xsl:apply-templates />
    </figcaption>
</xsl:template>


<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- Much of the cross-reference mechanism is -->
<!-- implemented in the common routines,      -->
<!-- here we implement two abstract templates -->
<!-- which are called from those routines     -->

<!-- The "text" of a cross-reference typically   -->
<!-- includes a number and our numbering code is -->
<!-- designed to sync with LaTeX's schemes       -->

<!-- The xref-link template provides one of two types of links      -->
<!--                                                                -->
<!-- (a) a traditional HTML hyperlink, a jump to a new location     -->
<!-- (b) a knowl, aka a transclusion, which appears within the text -->
<!--                                                                -->
<!-- A hyperlink is the default. For conversions to different       -->
<!-- HTML outputs, the choice of targets appearing as knowls        -->
<!-- can be adjusted by overriding the next template                -->

<!-- NB: these items must have their knowl content produced -->
<!-- NB: this is just the behavior of cross-references      -->

<!-- Cross-references as knowls                               -->
<!-- Override to turn off cross-references as knowls          -->
<!-- We explicitly include figures and tables from within     -->
<!-- a sidebyside even though this is not necessary           -->
<!-- NB: this device makes it easy to turn off knowlification -->
<!-- entirely, since some renders cannot use knowl JavaScript -->
<xsl:template match="fn|p|biblio|note|example|list|remark|theorem|corollary|lemma|algorithm|proposition|claim|fact|proof|definition|axiom|conjecture|principle|exercise|hint|answer|solution|exercisegroup|figure|table|listing|sidebyside|sidebyside/figure|sidebyside/table|men|mrow|li|contributor" mode="xref-as-knowl">
    <xsl:value-of select="true()" />
</xsl:template>
<xsl:template match="*" mode="xref-as-knowl">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- This is the implementation of an abstract template, -->
<!-- to accomodate hard-coded HTML numbers and for       -->
<!-- LaTeX the \ref and \label mechanism                 -->
<!-- NB: we do exactly the same thing in the mathbook-webwork-pg.xsl -->
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
    <xsl:variable name="knowl">
        <xsl:apply-templates select="." mode="xref-as-knowl" />
    </xsl:variable>
    <xsl:element name="a">
        <xsl:choose>
            <xsl:when test="$knowl='true'">
                <!-- build a modern knowl -->
                <xsl:attribute name="knowl">
                    <xsl:apply-templates select="." mode="xref-knowl-filename" />
                </xsl:attribute>
                <!-- TODO: check if this "knowl-id" is needed, knowl.js implies it is -->
                <xsl:attribute name="knowl-id">
                    <xsl:text>xref-</xsl:text>
                    <xsl:apply-templates select="." mode="internal-id" />
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <!-- build traditional hyperlink -->
                <xsl:attribute name="href">
                    <xsl:apply-templates select="." mode="url" />
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
        <!-- add HTML title and alt attributes to the link -->
        <xsl:attribute name="alt">
            <xsl:apply-templates select="." mode="tooltip-text" />
        </xsl:attribute>
        <xsl:attribute name="title">
            <xsl:apply-templates select="." mode="tooltip-text" />
        </xsl:attribute>
        <!-- link content from common template -->
        <!-- For a contributor we bypass autonaming, etc -->
        <xsl:choose>
            <xsl:when test="self::contributor">
                <xsl:apply-templates select="personname" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$content" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:element>
</xsl:template>

<!-- This is a third abstract template, which creates a    -->
<!-- hyperlink or knowl (as possible) that can be realized -->
<!-- as MathJax processes display math. It requires        -->
<!-- http://aimath.org/mathbook/mathjaxknowl.js be loaded  -->
<!-- as a MathJax extension for knowls to render           -->
<xsl:template match="*" mode="xref-link-md">
    <xsl:param name="content" />
    <xsl:variable name="knowl">
        <xsl:apply-templates select="." mode="xref-as-knowl" />
    </xsl:variable>
    <!-- MathJax expects similar constructions, variation is here -->
    <xsl:choose>
        <xsl:when test="$knowl='true'">
            <xsl:text>\knowl{</xsl:text>
            <xsl:apply-templates select="." mode="xref-knowl-filename" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\href{</xsl:text>
            <xsl:apply-templates select="." mode="url" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}{\text{</xsl:text>
    <xsl:value-of select="$content" />
    <xsl:text>}}</xsl:text>
</xsl:template>


<!-- Numbers, units, quantities                     -->
<!-- quantity                                       -->
<xsl:template match="quantity">
    <!-- warning if there is no content -->
    <xsl:if test="not(descendant::unit) and not(descendant::per) and not(descendant::mag)">
        <xsl:message terminate="no">
        <xsl:text>MBX:WARNING: magnitude or units needed</xsl:text>
        </xsl:message>
    </xsl:if>
    <!-- print magnitude if there is one -->
    <xsl:if test="descendant::mag">
        <xsl:apply-templates select="mag"/>
        <!-- if the units that follow are fractional, thin space -->
        <xsl:if test="descendant::per">
            <xsl:text>&#8239;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- if there are non-fracitonal units, print them -->
    <xsl:if test="descendant::unit and not(descendant::per)">
        <xsl:apply-templates select="unit" />
    </xsl:if>
    <!-- if there are fracitonal units with a numerator part, print them -->
    <xsl:if test="descendant::unit and descendant::per">
        <sup> <xsl:apply-templates select="unit" /> </sup>
        <xsl:text>&#8260;</xsl:text>
        <sub> <xsl:apply-templates select="per" /> </sub>
    </xsl:if>
    <!-- if there are fracitonal units without a numerator part, print them -->
    <xsl:if test="not(descendant::unit) and descendant::per">
        <sup> <xsl:text>1</xsl:text></sup>
        <xsl:text>&#8260;</xsl:text>
        <sub> <xsl:apply-templates select="per" /> </sub>
    </xsl:if>
</xsl:template>

<!-- Magnitude                                      -->
<xsl:template match="mag">
    <xsl:variable name="mag">
        <xsl:apply-templates />
    </xsl:variable>
    <xsl:value-of select="str:replace($mag,'\pi','\(\pi\)')"/>
</xsl:template>

<!-- unit and per children of a quantity element    -->
<!-- have a mandatory base attribute                -->
<!-- may have prefix and exp attributes             -->
<!-- base and prefix are not abbreviations          -->

<xsl:key name="prefix-key" match="prefix" use="concat(../@name, @full)"/>
<xsl:key name="base-key" match="base" use="concat(../@name, @full)"/>

<xsl:template match="unit|per">
    <xsl:if test="not(parent::quantity)">
        <xsl:message>MBX:WARNING: unit or per element should have parent quantity element</xsl:message>
    </xsl:if>
    <!-- if the unit is 1st and no mag, no need for thinspace. Otherwise, give thinspace -->
    <xsl:if test="position() != 1 or (local-name(.)='unit' and (preceding-sibling::mag or following-sibling::mag) and not(preceding-sibling::per or following-sibling::per))">
        <xsl:text>&#8239;</xsl:text>
    </xsl:if>
    <!-- prefix is optional -->
    <xsl:if test="@prefix">
        <xsl:variable name="prefix">
            <xsl:value-of select="@prefix" />
        </xsl:variable>
        <xsl:variable name="short">
            <xsl:for-each select="document('mathbook-units.xsl')">
                <xsl:value-of select="key('prefix-key',concat('prefixes',$prefix))/@short"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="$short" />
    </xsl:if>
    <!-- base unit is *mandatory* so check to see if it has been provided -->
    <xsl:choose>
        <xsl:when test="@base">
            <xsl:variable name="base">
                <xsl:value-of select="@base" />
            </xsl:variable>
            <xsl:variable name="short">
                <xsl:for-each select="document('mathbook-units.xsl')">
                    <xsl:value-of select="key('base-key',concat('bases',$base))/@short"/>
                </xsl:for-each>
            </xsl:variable>
            <xsl:value-of select="$short" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="no">
                <xsl:text>MBX:WARNING: base unit needed</xsl:text>
            </xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <!-- exponent is optional -->
    <xsl:if test="@exp">
        <sup><xsl:value-of select="@exp"/></sup>
    </xsl:if>
</xsl:template>


<!-- Actual Quotations                -->
<!-- TODO: <quote> element for inline to be <q> in HTML-->
<xsl:template match="blockquote">
    <blockquote>
        <xsl:apply-templates />
    </blockquote>
</xsl:template>

<!-- ############ -->
<!-- Attributions -->
<!-- ############ -->

<!-- At end of: blockquote, preface, foreword       -->
<!-- free-form for one line, or structured as lines -->
<!-- TODO: add CSS for attribution, div flush right         -->
<!-- And go slanted ("oblique"?)                            -->
<!-- Maybe use CSS to right align as a block                -->
<!-- https://github.com/BooksHTML/mathbook-assets/issues/64 -->

<!-- Single line, mixed-content          -->
<!-- Quotation dash if within blockquote -->
<!-- Unicode Character 'HORIZONTAL BAR' aka 'QUOTATION DASH' -->
<xsl:template match="attribution">
    <cite class="attribution">
        <xsl:if test="parent::blockquote">
            <xsl:text>&#x2015;</xsl:text>
        </xsl:if>
        <xsl:apply-templates />
    </cite>
</xsl:template>

<!-- Multiple lines, structured by lines -->
<xsl:template match="attribution[line]">
    <cite class="attribution">
        <xsl:apply-templates select="line" />
    </cite>
</xsl:template>

<!-- General line of an attribution -->
<xsl:template match="attribution/line">
    <xsl:if test="parent::attribution/parent::blockquote and not(preceding-sibling::*)">
        <xsl:text>&#x2015;</xsl:text>
    </xsl:if>
    <xsl:apply-templates />
    <!-- is there a next line to separate? -->
    <xsl:if test="following-sibling::*">
        <br />
    </xsl:if>
</xsl:template>


<!-- Defined terms (bold) -->
<xsl:template match="term">
    <em class="terminology"><xsl:apply-templates /></em>
</xsl:template>

<!-- Acronyms, Initialisms, Abbreviations -->
<!-- abbreviation: contracted form                                  -->
<!-- acronym: initials, pronounced as a word (eg SCUBA, RADAR)      -->
<!-- initialism: one letter at a time, (eg CIA, FBI)                -->
<!-- All are marked as the HTML "abbr" tag, but classes distinguish -->
<!-- Would a screen reader know the difference?                     -->
<xsl:template match="abbr">
    <abbr class="abbreviation">
        <xsl:comment>Style me</xsl:comment>
        <xsl:apply-templates />
    </abbr>
</xsl:template>

<xsl:template match="acro">
    <abbr class="acronym">
        <xsl:comment>Style me</xsl:comment>
        <xsl:apply-templates />
    </abbr>
</xsl:template>

<xsl:template match="init">
    <abbr class="initialism">
        <xsl:comment>Style me</xsl:comment>
        <xsl:apply-templates />
    </abbr>
</xsl:template>

<!-- Emphasis -->
<xsl:template match="em">
    <xsl:comment>Style me with CSS</xsl:comment>
    <em><xsl:apply-templates /></em>
</xsl:template>

<!-- Alert -->
<xsl:template match="alert">
    <b><i><xsl:apply-templates /></i></b>
</xsl:template>

<!-- Copyright symbol -->
<xsl:template match="copyright">
    <xsl:text>&#169;</xsl:text>
</xsl:template>

<!-- Registered symbol    -->
<!-- "sup" tag will raise -->
<xsl:template match="registered">
    <xsl:text>&#174;</xsl:text>
</xsl:template>

<!-- Trademark symbol -->
<xsl:template match="trademark">
    <xsl:text>&#x2122;</xsl:text>
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

<!-- circa -->
<xsl:template match="circa">
    <xsl:text>c.</xsl:text>
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
    <xsl:text>\(\mathrm{\LaTeX}\)</xsl:text>
</xsl:template>
<xsl:template match="tex">
    <xsl:text>\(\mathrm{\TeX}\)</xsl:text>
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

<!-- Chunks of Pre-Formatted Text                 -->
<!-- 100% analogue of LaTeX's verbatim            -->
<!-- environment or HTML's <pre> element          -->
<!-- Text is massaged just like Sage output code, -->
<!-- examining *all* lines to find left margin    -->
<xsl:template match="pre">
    <xsl:element name="pre">
        <xsl:call-template name="sanitize-text-output">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
    </xsl:element>
</xsl:template>


<!-- ################### -->
<!-- Reserved Characters -->
<!-- ################### -->

<!-- Across all possibilities                     -->
<!-- See mathbook-common.xsl for discussion       -->

<!--           -->
<!-- XML, HTML -->
<!--           -->

<!-- & < > -->

<!-- Ampersand -->
<xsl:template match="ampersand">
    <xsl:text>&amp;</xsl:text>
</xsl:template>

<!-- Less Than -->
<xsl:template match="less">
    <xsl:text>&lt;</xsl:text>
</xsl:template>

<!-- Greater Than -->
<xsl:template match="greater">
    <xsl:text>&gt;</xsl:text>
</xsl:template>

<!--       -->
<!-- LaTeX -->
<!--       -->

<!-- # $ % ^ & _ { } ~ \ -->

<!-- Number Sign, Hash, Octothorpe -->
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

<!-- Circumflex  -->
<xsl:template match="circumflex">
    <xsl:text>^</xsl:text>
</xsl:template>

<!-- Ampersand -->
<!-- Handled above -->

<!-- Underscore -->
<xsl:template match="underscore">
    <xsl:text>_</xsl:text>
</xsl:template>

<!-- Left Brace -->
<xsl:template match="lbrace">
    <xsl:text>{</xsl:text>
</xsl:template>

<!-- Right  Brace -->
<xsl:template match="rbrace">
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Tilde -->
<xsl:template match="tilde">
    <xsl:text>~</xsl:text>
</xsl:template>

<!-- Backslash -->
<xsl:template match="backslash">
    <xsl:text>\</xsl:text>
</xsl:template>

<!-- Asterisk -->
<!-- Centered as a character, not an exponent                    -->
<!-- Unicode Character 'ASTERISK OPERATOR' (U+2217)              -->
<!-- See raised asterisk for other options:                      -->
<!-- http://www.fileformat.info/info/unicode/char/002a/index.htm -->
<xsl:template match="asterisk">
    <xsl:text>&#x2217;</xsl:text>
</xsl:template>

<!-- Left Single Quote -->
<xsl:template match="lsq">
    <xsl:text>&#x2018;</xsl:text>
</xsl:template>

<!-- Right Single Quote -->
<xsl:template match="rsq">
    <xsl:text>&#x2019;</xsl:text>
</xsl:template>

<!-- Left (Double) Quote -->
<xsl:template match="lq">
    <xsl:text>&#x201c;</xsl:text>
</xsl:template>

<!-- Right (Double) Quote -->
<xsl:template match="rq">
    <xsl:text>&#x201d;</xsl:text>
</xsl:template>

<!-- Left Bracket -->
<xsl:template match="lbracket">
    <xsl:text>[</xsl:text>
</xsl:template>

<!-- Right Bracket -->
<xsl:template match="rbracket">
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- Left Double Bracket -->
<!-- MATHEMATICAL LEFT WHITE SQUARE BRACKET -->
<xsl:template match="ldblbracket">
    <xsl:text>&#x27e6;</xsl:text>
</xsl:template>

<!-- Right Double Bracket -->
<!-- MATHEMATICAL RIGHT WHITE SQUARE BRACKET -->
<xsl:template match="rdblbracket">
    <xsl:text>&#x27e7;</xsl:text>
</xsl:template>

<!-- Left Angle Bracket -->
<xsl:template match="langle">
    <xsl:text>&#x2329;</xsl:text>
</xsl:template>

<!-- Right Angle Bracket -->
<xsl:template match="rangle">
    <xsl:text>&#x232a;</xsl:text>
</xsl:template>


<!-- Other Miscellaneous Symbols, Constructions -->

<!-- Ellipsis (dots), for text, not math -->
<xsl:template match="ellipsis">
    <xsl:text>&#x2026;</xsl:text>
</xsl:template>

<!-- Midpoint -->
<!-- A centered dot used sometimes like a decorative dash -->
<xsl:template match="midpoint">
    <xsl:text>&#xb7;</xsl:text>
</xsl:template>

<!-- Swung Dash -->
<!-- A decorative dash, like a tilde, but bigger, and centered -->
<xsl:template match="swungdash">
    <xsl:text>&#x2053;</xsl:text>
</xsl:template>

<!-- Per Mille -->
<!-- Or, per thousand, like a percent sign -->
<xsl:template match="permille">
    <xsl:text>&#x2030;</xsl:text>
</xsl:template>

<!-- Pilcrow -->
<!-- Often used to mark the start of a paragraph -->
<xsl:template match="pilcrow">
    <xsl:text>&#xb6;</xsl:text>
</xsl:template>

<!-- Section Mark -->
<!-- The stylized double-S to indicate section numbers -->
<xsl:template match="section-mark">
    <xsl:text>&#xa7;</xsl:text>
</xsl:template>

<!-- Dimension -->
<!-- A "times" symbol for dimensions of physical objects -->
<xsl:template match="dimension">
    <xsl:text>&#xd7;</xsl:text>
</xsl:template>

<!-- Slash -->
<!-- Forward slash, or virgule (see solidus) -->
<xsl:template match="slash">
    <xsl:text>&#x2f;</xsl:text>
</xsl:template>

<!-- Solidus -->
<!-- Fraction bar, not as steep as a forward slash -->
<xsl:template match="solidus">
    <xsl:text>&#x2044;</xsl:text>
</xsl:template>





<!-- Foreign words/idioms        -->
<!-- Matches HTML5 specification -->
<xsl:template match="foreign">
    <i class="foreign"><xsl:apply-templates /></i>
</xsl:template>

<!-- Non-breaking space, which "joins" two words as a unit            -->
<!-- Using &nbsp; does not travel well into node-set() in common file -->
<!-- http://stackoverflow.com/questions/31870/using-a-html-entity-in-xslt-e-g-nbsp -->
<xsl:template match="nbsp">
    <xsl:text>&#xa0;</xsl:text>
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


<!-- ################## -->
<!-- Special Characters -->
<!-- ################## -->

<!-- These are specific instances of abstract templates        -->
<!-- See the similar section of  mathbook-common.xsl  for more -->

<xsl:template match="*" mode="nbsp">
    <xsl:text>&#xa0;</xsl:text>
</xsl:template>

<xsl:template match="*" mode="ndash">
    <xsl:text>&#8211;</xsl:text>
</xsl:template>

<xsl:template match="*" mode="mdash">
    <xsl:text>&#8212;</xsl:text>
</xsl:template>

<!--        -->
<!-- Poetry -->
<!--        -->
<!-- https://github.com/BooksHTML/mathbook-assets/issues/65 -->

<!-- "poem" element loads verse package         -->
<!-- width attribute is for print, ignored here -->
<xsl:template match="poem">
    <div class="poem" style="margin: auto;">
        <div class="poemtitle" style="padding-bottom: 20px; font-weight: bold; font-size: 121%">
            <xsl:apply-templates select="." mode="title-full"/>
        </div>
        <xsl:apply-templates select="stanza"/>
        <xsl:apply-templates select="author" />
    </div>
</xsl:template>


<!-- Stanzas are sequences of lines -->
<xsl:template match="stanza">
    <div class="stanza" style="padding-bottom: 20px;">
    <xsl:apply-templates select="line" />
    </div>
</xsl:template>

<!-- The last line of a stanza gets no break -->
<!-- Other lines are more normal             -->
<xsl:template match="poem/line|stanza/line">
    <xsl:apply-templates />
    <br />
</xsl:template>

<xsl:template match="poem/line[not(following-sibling::*)]|stanza/line[not(following-sibling::*)]">
    <xsl:apply-templates />
</xsl:template>

<!-- attribution style for author at end -->
<xsl:template match="poem/author">
    <cite class="attribution" style="padding-bottom: 20px;">
        <xsl:apply-templates />
    </cite>
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

<!-- Year in parentheses -->
<xsl:template match="biblio[@type='raw']/year">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates />
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- Number -->
<xsl:template match="biblio[@type='raw']/number">
    <xsl:text>no. </xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Ibid, nee ibidem, handle TeX period idosyncracy, empty element -->
<!-- A 3em dash is used for identical authors                       -->
<xsl:template match="biblio[@type='raw']/ibid">
    <xsl:text>Ibid.</xsl:text>
</xsl:template>
<!-- Index -->
<!-- Only implemented for LaTeX, where it -->
<!-- makes sense, otherwise just kill it  -->
<xsl:template match="index" />


<!-- Demonstrations -->
<!-- A simple page with no constraints -->
<xsl:template match="demonstration">
    <xsl:variable name="url"><xsl:apply-templates select="." mode="internal-id" />.html</xsl:variable>
    <a href="{$url}" target="_blank" class="link">
        <xsl:apply-templates select="." mode="title-full" />
    </a>
    <xsl:apply-templates select="." mode="simple-file-wrap" >
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
    <xsl:call-template name="sanitize-code">
        <xsl:with-param name="raw-code" select="input" />
    </xsl:call-template>
    </pre>
</xsl:template>


<!-- Console Session -->
<!-- An interactive command-line session with a prompt, input and output -->
<xsl:template match="console">
    <!-- ignore prompt, and pick it up in trailing input -->
    <xsl:element name="pre">
        <xsl:attribute name="class">console</xsl:attribute>
        <xsl:apply-templates select="input|output" />
    </xsl:element>
</xsl:template>

<xsl:template match="console/prompt">
    <xsl:element name="span">
        <xsl:attribute name="class">prompt unselectable</xsl:attribute>
        <xsl:apply-templates />
    </xsl:element>
</xsl:template>

<!-- match immediately preceding, only if a prompt:                   -->
<!-- https://www.oxygenxml.com/archives/xsl-list/199910/msg00541.html -->
<xsl:template match="console/input">
    <xsl:apply-templates select="preceding-sibling::*[1][self::prompt]" />
    <xsl:element name="b">
        <xsl:call-template name="sanitize-code">
            <xsl:with-param name="raw-code" select="." />
        </xsl:call-template>
    </xsl:element>
</xsl:template>

<xsl:template match="console/output">
    <xsl:call-template name="sanitize-code">
        <xsl:with-param name="raw-code" select="." />
    </xsl:call-template>
</xsl:template>


<!-- Geogebra                               -->
<!-- Empty cell for scribbling if empty tag -->
<!-- From Bruce Cohen's Sage iFrame demo    -->
<xsl:template match="geogebra-applet[not(ggbBase64)]">
<table border="0" width="750">
<tr><td>
<applet name="ggbApplet" code="geogebra.GeoGebraApplet" archive="geogebra.jar"
        codebase="https://www.geogebra.org/webstart/3.2/"
        width="750" height="550" mayscript="true">
        <param name="ggbBase64" value="UEsDBBQACAAIAMeAzj4AAAAAAAAAAAAAAAAMAAAAZ2VvZ2VicmEueG1srVQ9b9swEJ2bX0Fwb6yPuEgAyUGbLgGCdnCboRslnaWrKVIgKcfKr++RlGzHcyfq3j3evfugisdjL9kBjEWtSp7eJpyBqnWDqi356Haf7/nj5qZoQbdQGcF22vTClTy/zbjHR9zcfCpsp9+YkIHyivBW8p2QFjizgwHR2A7AfcDFeESJwkw/q79QO3t2xCDPahgpizMjYXXfvKBdzFVIOEh03/GADRgmdV3yL2uSTl+vYBzWQpb8LolIVvLsyklQ7r2dNviulfP0c3ApKpDUgK2bJDB28N48unZEZsziO1CzMo8Vq9CDAsZaYoNC+TqDRCIx9oaN60r+ELIBth2Vsb5LY7Raa9NsJ+ugZ8c/YDSJTnM/gyla2X2YiCXJlHCdBNelFcLAYQvOkWDLxBHOvWwNNh+MZ/tNyzM0aFTuSQxuNGHc+QyFuktOuYwX/FW1EmYspWl0UO8rfdzGJuQx9K9pCFeCoKp90lIbZnzn10SYzyqegeOVnlhJ4CSBMcfwQU/+9CELjHBW8YyjQhWlzZWnS9VpsqRByzzg20hbeio+DLnknI0K3cti0Hbsz6X6Cz/GvqLncbkfp5jp/4pZrK7Wp9iDUSDjkiia7ahHGzcx5gpCGqixJzM65pYIP67fJCCiDbQGFuHxccWGBW9yuYhXcLFaRHgNlrTWjv4SVI/ztUA/uIktPwb/pB09p5JXWHPWCEcU/4dYXd4Nz2W+sfkHUEsHCLTMTSIiAgAAfAQAAFBLAQIUABQACAAIAMeAzj60zE0iIgIAAHwEAAAMAAAAAAAAAAAAAAAAAAAAAABnZW9nZWJyYS54bWxQSwUGAAAAAAEAAQA6AAAAXAIAAAAA"/>
        <param name="image" value="https://www.geogebra.org/webstart/loading.gif"  />
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
        codebase="https://www.geogebra.org/webstart/3.2/unsigned/"
        width="750" height="441" mayscript="true">
        <param name="ggbBase64" value="{$ggbBase64}"/>
        <param name="image" value="https://www.geogebra.org/webstart/loading.gif"  />
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

<!-- ########################## -->
<!-- WeBWorK Embedded Exercises -->
<!-- ########################## -->

<!-- Base64 resources for debugging encoding and transmission problems  -->
<!-- ASCII Table: http://www.rapidtables.com/code/text/ascii-table.htm  -->
<!-- Online Converter: http://www.freeformatter.com/base64-encoder.html -->

<!-- WeBWorK HTML CSS header -->
<!-- MathView likely necessary for WW widgets          -->
<!-- Incorporated only if "webwork" element is present -->
<xsl:template name="webwork">
    <link href="{$webwork-server}/webwork2_files/js/apps/MathView/mathview.css" rel="stylesheet" />
</xsl:template>

<!-- The request for a "knowlized" webwork problem comes       -->
<!-- from deep within the environment/knowl scheme             -->
<!-- Package as a knowl with a source URL or base64 version    -->
<xsl:template match="webwork" mode="knowlized">
    <script type="text/javascript" src="{$webwork-server}/webwork2_files/js/vendor/iframe-resizer/js/iframeResizer.min.js"></script>
    <!-- Clickable, cribbed from "environment-hidden-factory" template -->
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>hidden-knowl-wrapper</xsl:text>
        </xsl:attribute>
        <xsl:element name="a">
           <!-- borrowing xref style for experiment -->
            <xsl:attribute name="knowl">
                <xsl:apply-templates select="." mode="xref-knowl-filename" />
            </xsl:attribute>
            <!-- make the anchor a target, eg of an in-context link -->
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="internal-id" />
            </xsl:attribute>
            <!-- generally the "hidden-knowl-text", but generic here -->
            <xsl:text>WeBWorK Exercise</xsl:text>
        </xsl:element>
    </xsl:element> <!-- end knowl clickable -->
    <!-- now a file containing WW problem -->
    <xsl:variable name="knowl-file">
        <xsl:apply-templates select="." mode="xref-knowl-filename" />
    </xsl:variable>
    <exsl:document href="{$knowl-file}" method="html">
        <xsl:call-template name="converter-blurb-html" />
        <!-- Actual content of knowl -->
        <xsl:comment>use 'format=debug' on 'webwork' tag to debug problem</xsl:comment>
        <xsl:element name="iframe">
            <xsl:attribute name="width">100%</xsl:attribute> <!-- MBX specific -->
            <xsl:attribute name="src">
                <xsl:value-of select="concat($webwork-server,'/webwork2/html2xml?')"/>
                <xsl:text>&amp;answersSubmitted=0</xsl:text>
                <xsl:choose>
                    <xsl:when test="@source">
                        <xsl:text>&amp;sourceFilePath=</xsl:text>
                        <xsl:value-of select="@source" />
                    </xsl:when>
                    <xsl:when test="not(. = '')">
                        <xsl:text>&amp;problemSource=</xsl:text>
                        <!-- formulate PG version with included routine -->
                        <!-- form base64 version for URL transmission -->
                        <xsl:variable name="pg-ascii">
                            <xsl:apply-templates select="." mode="pg" />
                        </xsl:variable>
                        <!-- A useful debugging message if WW problems misbehave            -->
                        <!-- Redirect output with 2> if there is too much at the console    -->
                        <!-- <xsl:message><xsl:value-of select="$pg-ascii" /></xsl:message> -->
                        <xsl:call-template name="b64:encode">
                            <xsl:with-param name="urlsafe" select="true()" />
                            <xsl:with-param name="asciiString">
                                <xsl:value-of select="$pg-ascii" />
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- problem not authored, nor pointed at -->
                    <xsl:otherwise>
                        <xsl:message>
                            <xsl:text>MBX:WARNING: A webwork problem requires a source URL or original content</xsl:text>
                            <xsl:apply-templates select="." mode="location-report" />
                        </xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text>&amp;problemSeed=</xsl:text>
                <xsl:choose>
                    <xsl:when test="@seed">
                        <xsl:value-of select="@seed"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>123567890</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text>&amp;displayMode=MathJax</xsl:text>
                <xsl:text>&amp;courseID=</xsl:text>
                <xsl:value-of select="$webwork.course"/>
                <xsl:text>&amp;userID=</xsl:text>
                <xsl:value-of select="$webwork.userID"/>
                <xsl:text>&amp;password=</xsl:text>
                <xsl:value-of select="$webwork.password"/>
                <xsl:text>&amp;outputformat=</xsl:text>
                <xsl:choose>
                    <xsl:when test="@format"><xsl:value-of select="@format" /></xsl:when>
                    <xsl:otherwise><xsl:text>simple</xsl:text></xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <!-- unclear what this does, mimicing Mike's blog post -->
            <xsl:if test="not(. = '')">
                <xsl:attribute name="base64"><xsl:text>1</xsl:text></xsl:attribute>
                <xsl:attribute name="uri"><xsl:text>1</xsl:text></xsl:attribute>
            </xsl:if>
        </xsl:element> <!-- end iframe -->
        <script type="text/javascript">iFrameResize({log:true,inPageLinks:true,resizeFrom:'child'})</script>
    </exsl:document>
</xsl:template>

<!--                         -->
<!-- Web Page Infrastructure -->
<!--                         -->

<!-- An individual page:                                   -->
<!-- Inputs:                                               -->
<!-- * page content (exclusive of banners, navigation etc) -->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="containing-filename" />
    </xsl:variable>
    <exsl:document href="{$filename}" method="html">
    <!-- Need to be careful for format of this initial string     -->
    <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html>&#xa;</xsl:text>
    <xsl:call-template name="converter-blurb-html" />
    <html> <!-- lang="", and/or dir="rtl" here -->
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
            <xsl:if test="//webwork">
                <xsl:call-template name="webwork" />
            </xsl:if>
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
                                    <xsl:apply-templates select="/mathbook/book|/mathbook/article" mode="title-simple" />
                                </span>
                                <xsl:if test="normalize-space(/mathbook/book/subtitle|/mathbook/article/subtitle)">
                                    <span class="subtitle">
                                        <xsl:apply-templates select="/mathbook/book|/mathbook/article" mode="subtitle" />
                                    </span>
                                </xsl:if>
                            </h1>
                            <!-- Serial list of authors/editors -->
                            <p class="byline">
                                <xsl:apply-templates select="//frontmatter/titlepage/author" mode="name-list"/>
                                <xsl:apply-templates select="//frontmatter/titlepage/editor" mode="name-list"/>
                            </p>
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
<!-- * page content (exclusive of banners, navigation etc)   -->
<!-- Maybe a page title -->
<xsl:template match="*" mode="simple-file-wrap">
    <xsl:param name="content" />
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="internal-id" />
        <text>.html</text>
    </xsl:variable>
    <exsl:document href="{$filename}" method="html">
    <!-- Need to be careful for format of this initial string     -->
    <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html>&#xa;</xsl:text>
    <xsl:call-template name="converter-blurb-html" />
    <html> <!-- lang="", and/or dir="rtl" here -->
        <head>
            <meta name="Keywords" content="Authored in MathBook XML" />
            <meta name="viewport" content="width=device-width,  initial-scale=1.0, user-scalable=0, minimum-scale=1.0, maximum-scale=1.0" />
            <xsl:call-template name="mathjax" />
            <xsl:call-template name="sagecell" />
            <xsl:if test="//webwork">
                <xsl:call-template name="webwork" />
            </xsl:if>
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
    <xsl:variable name="intermediate">
        <xsl:apply-templates select="." mode="is-intermediate" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$intermediate='true'">
            <!-- Descend once, will always have a child that is structural -->
            <xsl:variable name="first-structural-child" select="*[not(self::title or self::subtitle or self::todo or self::introduction or self::conclusion or self::titlepage or self::author)][1]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$first-structural-child" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='false'">
                <xsl:message>MBX:ERROR: descending into first node of an intermediate page (<xsl:value-of select="local-name($first-structural-child)" />) that is non-structural; maybe your source has incorrect structure</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
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
    <xsl:variable name="intermediate">
        <xsl:apply-templates select="." mode="is-intermediate" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$intermediate='false'">
            <xsl:apply-templates select="." mode="url" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="last-structural-child" select="*[not(self::title or self::subtitle or self::todo or self::introduction or self::conclusion)][last()]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$last-structural-child" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='false'">
                <xsl:message>MBX:ERROR: descending into last node of an intermediate page (<xsl:value-of select="local-name($last-structural-child)" />) that is non-structural</xsl:message>
            </xsl:if>
            <xsl:apply-templates select="$last-structural-child" mode="previous-descent-url" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!--                     -->
<!-- Navigation Sections -->
<!--                     -->

<!-- Button code, <a href=""> when active   -->
<!-- <span> with "disabled" class otherwise -->
<xsl:template match="*" mode="previous-button">
    <xsl:variable name="previous-url">
        <xsl:choose>
            <xsl:when test="$nav-logic='linear'">
                <xsl:apply-templates select="." mode="previous-linear-url" />
            </xsl:when>
            <xsl:when test="$nav-logic='tree'">
                <xsl:apply-templates select="." mode="previous-tree-url" />
            </xsl:when>
        </xsl:choose>
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
        <xsl:choose>
            <xsl:when test="$nav-logic='linear'">
                <xsl:apply-templates select="." mode="next-linear-url" />
            </xsl:when>
            <xsl:when test="$nav-logic='tree'">
                <xsl:apply-templates select="." mode="next-tree-url" />
            </xsl:when>
        </xsl:choose>
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
    <!-- up URL is identical for linear, tree logic -->
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

<!-- Compact Buttons -->
<!-- These get smashed consecutively into a single "tool-bar" -->
<xsl:template match="*" mode="compact-buttons">
    <!-- URL formation, maybe this could be consolidated with above versions -->
    <xsl:variable name="previous-url">
        <xsl:choose>
            <xsl:when test="$nav-logic='linear'">
                <xsl:apply-templates select="." mode="previous-linear-url" />
            </xsl:when>
            <xsl:when test="$nav-logic='tree'">
                <xsl:apply-templates select="." mode="previous-tree-url" />
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="up-url">
        <xsl:apply-templates select="." mode="up-url" />
    </xsl:variable>
    <xsl:variable name="next-url">
        <xsl:choose>
            <xsl:when test="$nav-logic='linear'">
                <xsl:apply-templates select="." mode="next-linear-url" />
            </xsl:when>
            <xsl:when test="$nav-logic='tree'">
                <xsl:apply-templates select="." mode="next-tree-url" />
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <!-- toolbar-item when aligned right, get placed right: first in, first right -->
    <!-- so they apparently seem in the reversed order here and in HTML output    -->
    <!-- Empty URL, then no button                                                -->
    <xsl:if test="not($next-url = '')">
        <div class="toolbar-item">
            <a href="{$next-url}">
                <svg height="50" width="60" viewBox="0 50 110 100" xmlns="https://www.w3.org/2000/svg" >
                    <polygon points="110,100 75,75 0,75 0,125 75,125 " style="fill:darkred;stroke:maroon;stroke-width:1" />
                    <text x="13" y="108" fill="blanchedalmond" font-size="32">next</text>
                </svg>
            </a>
        </div>
    </xsl:if>
    <xsl:if test="not($up-url = '')">
        <div class="toolbar-item">
            <a href="{$up-url}">
                <svg height="50" width="60" viewBox="0 50 80 100" xmlns="https://www.w3.org/2000/svg" >
                    <polygon points="75,75 37,65 0,75 0,125 75,125 " style="fill:blanchedalmond;stroke:burlywood;stroke-width:1" />
                    <text x="13" y="108" fill="maroon" font-size="32">up</text>
                </svg>
            </a>
        </div>
    </xsl:if>
    <xsl:if test="not($previous-url = '')">
        <div class="toolbar-item">
            <a href="{$previous-url}">
                <svg height="50" width="60" viewBox="-10 50 110 100" xmlns="https://www.w3.org/2000/svg" >
                    <polygon points="-10,100 25,75 100,75 100,125 25,125 " style="fill:blanchedalmond;stroke:burlywood;stroke-width:1" />
                    <text x="28" y="108" fill="maroon" font-size="32">prev</text>
                </svg>
            </a>
        </div>
    </xsl:if>
</xsl:template>

<!-- Primary Navigation Panels -->
<!-- ToC, Prev/Up/Next/Annotation buttons  -->
<!-- Also organized for small screen modes -->
<xsl:template match="*" mode="primary-navigation">
    <nav id="primary-navbar">
        <div class="container">
            <!-- Several buttons across the top -->
            <div class="navbar-top-buttons">
                <!-- "contents" button is uniform across logic, style -->
                <button class="sidebar-left-toggle-button button active">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'toc'" />
                    </xsl:call-template>
                </button>
                <!-- Prev/Up/Next buttons on top, according to options -->
                <xsl:choose>
                    <xsl:when test="$nav-style = 'full'">
                        <xsl:element name="div">
                            <xsl:attribute name="class">
                                <!-- 3 or 4 buttons, depending on Up Button choice -->
                                <xsl:choose>
                                    <xsl:when test="$nav-upbutton='yes'">
                                        <xsl:text>tree-nav toolbar toolbar-divisor-3</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="$nav-upbutton='no'">
                                        <xsl:text>tree-nav toolbar toolbar-divisor-2</xsl:text>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:attribute>
                            <xsl:apply-templates select="." mode="previous-button" />
                            <xsl:if test="$nav-upbutton='yes'">
                                <xsl:apply-templates select="." mode="up-button" />
                            </xsl:if>
                            <xsl:apply-templates select="." mode="next-button" />
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="$nav-style = 'compact'">
                        <div class="toolbar toolbar-align-right">
                            <xsl:apply-templates select="." mode="compact-buttons" />
                        </div>
                    </xsl:when>
                </xsl:choose>
                <!-- right sidebar, not used currently -->
                <button class="sidebar-right-toggle-button button active">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'annotations'" />
                    </xsl:call-template>
                </button>
            </div>
            <!-- Bottom buttons, for mobile UI -->
            <xsl:element name="div">
                <xsl:attribute name="class">
                    <!-- 3 or 4 buttons, depending on Up Button choice -->
                    <xsl:choose>
                        <xsl:when test="$nav-upbutton='yes'">
                            <xsl:text>navbar-bottom-buttons toolbar toolbar-divisor-4</xsl:text>
                        </xsl:when>
                        <xsl:when test="$nav-upbutton='no'">
                            <xsl:text>navbar-bottom-buttons toolbar toolbar-divisor-3</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>
                <!-- "contents" button is uniform across logic -->
                <button class="sidebar-left-toggle-button button toolbar-item active">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'toc'" />
                    </xsl:call-template>
                </button>
                <!-- Prev/Up/Next buttons on top, according to options -->
                <xsl:apply-templates select="." mode="previous-button" />
                <xsl:if test="$nav-upbutton='yes'">
                    <xsl:apply-templates select="." mode="up-button" />
                </xsl:if>
                <xsl:apply-templates select="." mode="next-button" />
                <!-- unused, increment the toolbar-divisor-4/5 above -->
                <!--
                <button class="sidebar-right-toggle-button button toolbar-item active">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'annotations'" />
                    </xsl:call-template>
                </button>
                -->
             </xsl:element>
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
                    <xsl:call-template name="powered-by-mathjax" />
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
                        <xsl:if test="1 > $chunk-level">
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
                                    <xsl:if test="2 > $chunk-level">
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

<!-- Branding in "extras", mostly hard-coded        -->
<!-- HTTPS for authors delivering from secure sites -->
<xsl:template name="mathbook-link">
    <a class="mathbook-link" href="https://mathbook.pugetsound.edu">
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'authored'" />
        </xsl:call-template>
        <xsl:text> MathBook&#xa0;XML</xsl:text>
    </a>
</xsl:template>

<!-- MathJax Logo for bottom of left sidebar -->
<xsl:template name="powered-by-mathjax">
    <a href="https://www.mathjax.org">
        <img title="Powered by MathJax" src="https://cdn.mathjax.org/mathjax/badge/badge.gif" border="0" alt="Powered by MathJax" />
    </a>
</xsl:template>

<!-- Tooltip Text -->
<!-- text for an HTML title attribute -->
<!-- TODO: be more careful about extraneous spaces -->
<!-- TODO: captions from figures, tables, sbs? -->
<xsl:template match="*" mode="tooltip-text">
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="title-simple" />
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
        inlineMath: [['\\(','\\)']],
    },
    TeX: {
        extensions: ["AMSmath.js", "AMSsymbols.js", "extpfeil.js", "autobold.js", "https://aimath.org/mathbook/mathjaxknowl.js", ],
        equationNumbers: { autoNumber: "none",
                           useLabelIds: true,
                           // JS comment, XML CDATA protect XHTML quality of file
                           // if removed in XSL, use entities
                           //&lt;![CDATA[
                           formatID: function (n) {return String(n).replace(/[:'"&lt;&gt;&amp;]/g,"")},
                           //]]&gt;
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
<script type="text/javascript" src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML-full" />
</xsl:template>

<!-- Sage Cell header -->
<!-- TODO: internationalize button labels, strings below -->
<!-- TODO: make an initialization cell which links with the sage-compute cells -->
<xsl:template name="sagecell">
    <script type="text/javascript" src="https://sagecell.sagemath.org/static/jquery.min.js"></script>
    <script type="text/javascript" src="https://sagecell.sagemath.org/embedded_sagecell.js"></script>
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
<script type="text/javascript" src="https://code.jquery.com/jquery-latest.min.js"></script>
<link href="https://aimath.org/knowlstyle.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="https://aimath.org/knowl.js"></script>

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
    <link href='https://fonts.googleapis.com/css?family=Open+Sans:400,400italic,600,600italic|Source+Code+Pro:400' rel='stylesheet' type='text/css' />
</xsl:template>

<!-- CSS header -->
<xsl:template name="css">
    <link href="{$html.css.server}/mathbook/stylesheets/{$html.css.file}" rel="stylesheet" type="text/css" />
    <link href="https://aimath.org/mathbook/mathbook-add-on.css" rel="stylesheet" type="text/css" />
    <xsl:call-template name="external-css">
        <xsl:with-param name="css-list" select="normalize-space($html.css.extra)" />
    </xsl:call-template>
</xsl:template>

<!-- Recursively unpack the list of URLs for extra CSS                       -->
<!-- Presumes normalized, so no leading/trailing space and single separators -->
<!-- If unspecified, default is empty string and nothing at all happens      -->
<xsl:template name="external-css">
    <xsl:param name="css-list" />
    <xsl:variable name="delimiter" select="' '" />
    <xsl:choose>
        <xsl:when test="$css-list = ''">
            <!-- bail out: done, halt recursion, take no action -->
        </xsl:when>
        <!--
        Unnormalized:
        strip leading space, or leftover from multiple spaces, or trailing
        <xsl:when test="substring($css-list, 1, 1) = ' '">
            <xsl:call-template name="external-css">
                <xsl:with-param name="css-list" select="substring($css-list, 2)" />
            </xsl:call-template>
        </xsl:when>
        -->
        <xsl:when test="contains($css-list, $delimiter)">
            <!-- Form the css inclusion element from front, recurse -->
            <!-- Presumes a single space as separator               -->
            <xsl:element name="link">
                <xsl:attribute name="href">
                    <xsl:value-of select="substring-before($css-list, $delimiter)" />
                </xsl:attribute>
                <xsl:attribute name="rel">stylesheet</xsl:attribute>
                <xsl:attribute name="type">text/css</xsl:attribute>
            </xsl:element>
            <xsl:call-template name="external-css">
                <xsl:with-param name="css-list" select="substring-after($css-list, $delimiter)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <!-- form the css inclusion element from last/only URL -->
            <xsl:element name="link">
                <xsl:attribute name="href">
                    <xsl:value-of select="$css-list" />
                </xsl:attribute>
                <xsl:attribute name="rel">stylesheet</xsl:attribute>
                <xsl:attribute name="type">text/css</xsl:attribute>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
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
<!-- In a hidden div, for near the top of the page, as math -->
<xsl:template name="latex-macros">
    <div style="display:none;">
    <xsl:text>\(</xsl:text>
    <xsl:value-of select="$latex-macros" />
    <xsl:text>\)</xsl:text>
    </div>
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
ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'https://www') + '.google-analytics.com/ga.js';
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
var scJsHost = (("https:" == document.location.protocol) ? "https://secure." : "https://www.");
<![CDATA[document.write("<sc"+"ript type='text/javascript' src='" + scJsHost+ "statcounter.com/counter/counter.js'></"+"script>");]]>
</script>
<xsl:variable name="noscript_url">
    <xsl:text>https://c.statcounter.com/</xsl:text>
    <xsl:value-of select="./project" />
    <xsl:text>/0/</xsl:text>
    <xsl:value-of select="./security" />
    <xsl:text>/1/</xsl:text>
</xsl:variable>
<noscript>
<div class="statcounter">
<a title="web analytics" href="https://statcounter.com/" target="_blank">
<img class="statcounter" src="{$noscript_url}" alt="web analytics" /></a>
</div>
</noscript>
<xsl:comment>End: StatCounter code</xsl:comment>
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
    <xsl:apply-templates select="." mode="location-report" />
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
