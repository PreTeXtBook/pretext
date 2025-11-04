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
<!-- We choose to not include a default namespace       -->
<!-- (in particular  http://www.w3.org/1999/xhtml),     -->
<!-- even if this complicates adding namespaces onto    -->
<!-- derivatives, such as HTML destined for EPUB output -->
<!-- xmlns="http://www.w3.org/1999/xhtml"               -->
<!--                                                    -->
<!-- NB:                                                -->
<!--   "xsl" is necessary to identify XSL functionality -->
<!--   "xml" is automatic, hence redundant              -->
<!--   "svg" is necessary to for Asymptote 3D images    -->
<!--   "pi" is meant to mark private PreTeXt markup     -->
<!--   "exsl" namespaces enable extension functions     -->
<!--                                                    -->
<!-- Excluding result prefixes keeps them from bleeding -->
<!-- into output unnecessarily -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:pf="https://prefigure.org"
    exclude-result-prefixes="svg xlink pi fn pf"
    extension-element-prefixes="exsl date str"
>

<!-- Allow writing of JSON from structured HTML -->
<xsl:import href="./xml-to-json.xsl"/>

<!-- Standard conversion groundwork -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>

<!-- Modularize lots of Runestone-specific code    -->
<!-- Likely need not be an "import" (v. "include") -->
<xsl:import href="./pretext-runestone.xsl"/>
<xsl:import href="./pretext-runestone-fitb.xsl"/>

<!-- Routines to provide "View Source" annotations on HTML output   -->
<!-- as a service on the PreTeXt website. NB: we use an "include"   -->
<!-- to provide this set of templates.  The included stylesheet has -->
<!-- radically different "strip-space" and "preserve-space"         -->
<!-- declarations, which seem to *not* provide overrrides, and are  -->
<!-- simply "local" to that stylesheet.                             -->
<xsl:import href="./pretext-view-source.xsl"/>

<!-- We create HTML5 output.  The @doctype-system attribute will    -->
<!-- create a header in the old style that browsers will recognize  -->
<!-- as signaling HTML5.  However  xsltproc  does one better and    -->
<!-- writes the super-simple <!DOCTYPE html> header.  See all of    -->
<!-- https://stackoverflow.com/questions/3387127/                   -->
<!-- (set-html5-doctype-with-xslt)                                  -->
<!--                                                                -->
<!-- Indentation is weak, it is just strategic newlines.  This is   -->
<!-- explained late in the thread by Daniel Veillard:               -->
<!-- http://docbook-apps.oasis-open.narkive.com/tDqyEc91/           -->
<!-- (two-issues-with-xslt-processors-xsltproc-and-xalan)           -->
<!--                                                                -->
<!-- Since we write output into multiple files, likely this         -->
<!-- declaration is never active, but it serves as a model here for -->
<!-- subsequent exsl:document elements.                             -->

<xsl:output method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat" />

<!-- ################################################ -->
<!-- Following is slated to migrate above, 2019-07-10 -->
<!-- ################################################ -->

<!-- Parameters -->
<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!-- See more generally applicable parameters in pretext-common.xsl file     -->

<!-- CSS and Javascript Directories -->
<!-- These are convenience variables to specify file prefixes  -->
<!-- consistently.  If you know what you are doing you could   -->
<!-- likely point them elsewhere, even to other servers.       -->
<!-- So the name says "dir", but effectively it is "location". -->
<!-- But this is not the intent, nor supported, and thus can   -->
<!-- change without warning.                                   -->
<xsl:variable name="html.css.dir" select="concat($cdn-prefix, '_static/pretext/css')"/>
<xsl:variable name="html.js.dir" select="concat($cdn-prefix, '_static/pretext/js')"/>
<xsl:variable name="html.jslib.dir" select="concat($cdn-prefix, '_static/pretext/js/lib')"/>

<!-- Add a prefix for the cdn url, which is empty unless the portable html variable is true -->
<!-- We use version "latest" unless the CLI provides a version -->
<xsl:param name="cli.version" select="'latest'"/>
<xsl:variable name="cdn-prefix">
    <xsl:if test="$b-portable-html">
        <xsl:text>https://cdn.jsdelivr.net/gh/PreTeXtBook/html-static@</xsl:text>
        <xsl:value-of select="$cli.version"/>
        <xsl:text>/dist/</xsl:text>
    </xsl:if>
</xsl:variable>

<!-- The css file name is usually "theme.css", but if portable html is selected, -->
<!-- then we use a minified version and need to give the full theme name.        -->
<xsl:variable name="html-css-theme-file">
    <xsl:choose>
        <xsl:when test="$b-portable-html">
            <xsl:text>theme-</xsl:text>
            <xsl:value-of select="$html-theme-name"/>
            <xsl:text>.min.css</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>theme.css</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Annotation -->
<xsl:param name="html.annotation" select="''" />
<xsl:variable name="b-activate-hypothesis" select="boolean($html.annotation='hypothesis')" />

<!-- Should we build the SCORM manifest file? -->
<xsl:param name="html.scorm" select="'no'" />
<xsl:variable name="b-build-scorm-manifest" select="$html.scorm = 'yes'" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->
<!-- Variables that affect HTML creation -->
<!-- More in the common file             -->

<!-- The  pretext-assembly.xsl  stylesheet is parameterized to create  -->
<!-- representations of interactive exercises in final "static"        -->
<!-- versions or precursor "dynamic" versions.  The conversion to HTML -->
<!-- is the motivation for this parameterization.  See the definition  -->
<!-- of this variable in  pretext-assembly.xsl  for more detail.       -->
<!--                                                                   -->
<!-- Conversions that build on HTML, but produce formats unwilling     -->
<!-- (EPUB, Jupyter) to employ Javascript, or similar, need to         -->
<!-- override this variable back to "static".                          -->
<xsl:variable name="exercise-style" select="'dynamic'"/>

<!-- Search for the "math.punctuation.include" -->
<!-- global variable, which is discussed in    -->
<!-- closer proximity to its application.      -->

<!-- This is cribbed from the CSS "max-width"-->
<!-- Design width, measured in pixels        -->
<!-- NB: the exact same value, for similar,  -->
<!-- but not identical, reasons is used in   -->
<!-- the formation of WeBWorK problems       -->
<xsl:variable name="design-width" select="'600'" />

<!-- We generally want to chunk longer HTML output -->
<xsl:variable name="chunk-level">
    <xsl:choose>
        <!-- portable html always gets chunk level 0, even something else is entered -->
        <xsl:when test="$b-portable-html">0</xsl:when>
        <xsl:when test="$chunk-level-entered != ''">
            <xsl:value-of select="$chunk-level-entered" />
        </xsl:when>
        <xsl:when test="$root/book/part">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
        <xsl:when test="$root/article/section">1</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/slideshow">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: HTML chunk level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- HTML files as output -->
<xsl:variable name="file-extension" select="'.html'" />

<!-- "presentation" mode is experimental, target        -->
<!-- is in-class presentation of a textbook             -->
<!--   (1) clickable mathematics (MathJax) at 300% zoom -->
<!-- boolean variable $b-html-presentation              -->
<xsl:param name="html.presentation" select="'no'" />
<xsl:variable name="b-html-presentation" select="$html.presentation = 'yes'" />

<!-- ############### -->
<!-- Source Analysis -->
<!-- ############### -->

<!-- We check certain aspects of the source and record the results   -->
<!-- in boolean ($b-has-*) variables or as particular nodes high up  -->
<!-- in the structure ($document-root).  Scans here in -html should  -->
<!-- help streamline the construction of the HTML page "head" by     -->
<!-- computing properties that will be used in the "head" of every   -->
<!-- page of every chunk. checked more than once. While technically  -->
<!-- generally part of constructing the head, there is no real harm  -->
<!-- in making these global variables.  Short, simple, and universal -->
<!-- properties are determined in -common. These may duplicate       -->
<!-- variables in disjoint conversions.                              -->

<xsl:variable name="b-has-icon"         select="boolean($document-root//icon)"/>
<xsl:variable name="b-has-webwork-reps" select="boolean($document-root//webwork-reps)"/>
<xsl:variable name="b-has-myopenmath"   select="boolean($document-root//myopenmath)"/>
<xsl:variable name="b-has-stack"        select="boolean($document-root//exercise/stack)"/>
<xsl:variable name="b-has-program"      select="boolean($document-root//program)"/>
<xsl:variable name="b-has-sage"         select="boolean($document-root//sage)"/>
<!-- 2023-10-18: this is a bit buggy, as it ignores the "men" element.  -->
<!-- And it examines the "md" element which will never be true. It has  -->
<!-- been fine for years, and it hopefully will go away some day, so no -->
<!-- fix right now.                                                     -->
<xsl:variable name="b-has-sfrac"        select="boolean($document-root//m[contains(text(),'sfrac')]|$document-root//md[contains(text(),'sfrac')]|$document-root//me[contains(text(),'sfrac')]|$document-root//mrow[contains(text(),'sfrac')])"/>
<xsl:variable name="b-has-geogebra"     select="boolean($document-root//interactive[@platform='geogebra'])"/>
<xsl:variable name="b-has-mermaid"      select="boolean($document-root//image[mermaid]|/image[mermaid])"/>
<!-- 2018-04-06:  jsxgraph deprecated -->
<xsl:variable name="b-has-jsxgraph"     select="boolean($document-root//jsxgraph)"/>
<!-- Plural "annotations" is a child of "diagram" -->
<xsl:variable name="b-has-prefigure-annotations" select="boolean($document-root//pf:prefigure/pf:diagram/pf:annotations)"/>
<xsl:variable name="b-dynamics-static-seed" select="false()"/>
<!-- Every page has an index button, with a link to the index -->
<!-- Here we assume there is at most one                      -->
<xsl:variable name="the-index"          select="($document-root//index)[1]"/>

<!-- ol markers                                                        -->
<!-- Make a master list of all unique author-supplied ol marker styles -->
<xsl:key name="marker-key" match="ol|ol-marker" use="@marker"/> <!-- never used on node sets that contain mix of ol and ol-marker -->
<xsl:variable name="ol-markers">
    <ol-markers>
        <xsl:apply-templates select="$document-root//ol[@marker and count(. | key('marker-key', @marker)[1]) = 1]" mode="ol-markers"/>
    </ol-markers>
</xsl:variable>
<!-- Following should be more efficient than 'select="boolean($document-root//ol[@marker])"' -->
<xsl:variable name="b-needs-custom-marker-css" select="boolean(exsl:node-set($ol-markers)/ol-markers/ol-marker)"/>


<!-- ######## -->
<!-- WeBWorK  -->
<!-- ######## -->

<!-- We mine some values from the first "WW representation" to have been -->
<!-- inserted into the source by the pre-processor ("assembly") when     -->
<!-- making dynamic exercises.                                           -->

<xsl:variable name="webwork-major-version" select="$document-root//webwork-reps[1]/@webwork2_major_version"/>
<xsl:variable name="webwork-minor-version" select="$document-root//webwork-reps[1]/@webwork2_minor_version"/>

<!-- #### EXPERIMENTAL #### -->
<!-- We allow for the HTML conversion to chunk output, starting  -->
<!-- from an arbitrary node.  $subtree-node needs context.       -->
<xsl:param name="subtree" select="''"/>
<xsl:variable name="b-subsetting" select="not($subtree = '')"/>
<!-- #### EXPERIMENTAL #### -->


<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the pretext element,  -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<!-- TODO: consider moving  manifests, etc to  the "pretext" template,      -->
<!-- leaving this entry template for derived stylesheets to (a) test        -->
<!-- source, and (b) set the root                                           -->
<xsl:template match="/">
    <!-- temporary - while Hypothesis annotation is beta -->
    <xsl:if test="$b-activate-hypothesis">
        <xsl:call-template name="banner-warning">
            <xsl:with-param name="warning">Hypothes.is annotation is experimental</xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <xsl:apply-templates select="$original" mode="generic-warnings"/>
    <xsl:apply-templates select="$original" mode="element-deprecation-warnings"/>
    <xsl:apply-templates select="$original" mode="parameter-deprecation-warnings"/>
    <!-- Usually no manifest is created -->
    <xsl:call-template name="runestone-manifest"/>
    <!-- A structured Table of Contents for a React app approach -->
    <xsl:call-template name="doc-manifest"/>
    <!-- build a search page (in development) -->
    <xsl:if test="$has-native-search and not($b-portable-html)">
        <xsl:call-template name="search-page-construction"/>
    </xsl:if>
    <!-- Optionally, build a SCORM manifest -->
    <xsl:if test="$b-build-scorm-manifest">
        <xsl:call-template name="scorm-manifest"/>
    </xsl:if>
    <!-- The main event                          -->
    <!-- We process the enhanced source pointed  -->
    <!-- to by $root at  /mathbook  or  /pretext -->
    <xsl:apply-templates select="$root"/>
</xsl:template>


<!-- We process structural nodes via chunking routine in xsl/pretext-common.xsl    -->
<!-- This in turn calls specific modal templates defined elsewhere in this file     -->
<!-- The xref-knowl templates run independently on content node of document tree    -->
<xsl:template match="/mathbook|/pretext">

    <xsl:choose>
        <!-- usually not working on a subset -->
        <xsl:when test="not($b-subsetting)">
            <!-- Build the index-redirect-page, but not if doing a portable build -->
            <xsl:if test="not($b-portable-html)">
                <xsl:call-template name="index-redirect-page"/>
            </xsl:if>
            <xsl:apply-templates mode="chunking" />
        </xsl:when>
        <!-- if subsetting, begin chunking at specified node -->
        <!-- and do not build an "index.html" page           -->
        <xsl:otherwise>
            <!-- we compute the subset node while the context is the -->
            <!-- tree produced by the -assembly stylesheet, and only -->
            <!-- if actually requested                               -->
            <xsl:variable name="subtree-node" select="id($subtree)"/>
            <!-- this error-checking should be parked somewhere else -->
            <!-- and maybe there is a fallback to full processing?   -->
            <xsl:choose>
                <xsl:when test="not($subtree-node)">
                    <xsl:message terminate="yes">PTX:FATAL:  the @xml:id given as a subtree root ("<xsl:value-of select="$subtree"/>") does not specify any element.  (Check spelling?)  Quitting...</xsl:message>
                </xsl:when>
                <xsl:when test="not($subtree-node[&STRUCTURAL-FILTER;])">
                    <xsl:message terminate="yes">PTX:FATAL:  the element with the @xml:id given as a subtree root ("<xsl:value-of select="$subtree"/>") is not division that can be chunked into HTML page(s).  Quitting...</xsl:message>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="current-level">
                        <!-- this should be successful having passed previous filter -->
                        <xsl:apply-templates select="$subtree-node" mode="level"/>
                    </xsl:variable>
                    <!-- too deep to chunk into a page (or pages) -->
                    <xsl:if test="$current-level > $chunk-level">
                        <xsl:message terminate="yes">PTX:FATAL:  the element with @xml:id given as a subtree root ("<xsl:value-of select="$subtree"/>") is only a partial HTML page at the current chunking level.  Quitting...</xsl:message>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
            <!-- seems to now be a good place to start chunking -->
            <xsl:apply-templates select="$subtree-node" mode="chunking" />
        </xsl:otherwise>
    </xsl:choose>
    <!-- knowl-production -->
    <!-- subsetting? don't bother (for now) -->
    <!-- portable html does not get xref knowls either. -->
    <xsl:if test="not($b-subsetting) and not($b-portable-html)">
        <xsl:apply-templates select="." mode="make-xref-knowls"/>
    </xsl:if>
    <!-- custom ol marker css production -->
    <xsl:if test="not($b-subsetting) and not($b-portable-html)">
        <xsl:call-template name="ol-marker-styles"/>
    </xsl:if>
</xsl:template>

<!-- However, some PTX document types do not have    -->
<!-- universal conversion, so these default warnings -->
<!-- should be overridden by supported conversions   -->
<xsl:template match="letter" mode="chunking">
    <xsl:message terminate="yes">
        <xsl:text>PTX:FATAL:  HTML conversion does not support the "letter" document type.  Quitting...</xsl:text>
    </xsl:message>
</xsl:template>

<xsl:template match="memo" mode="chunking">
    <xsl:message terminate="yes">
        <xsl:text>PTX:FATAL:  HTML conversion does not support the "memo" document type.  Quitting...</xsl:text>
    </xsl:message>
</xsl:template>

<!-- We build a simple, instantaneous, redirection page based on the    -->
<!-- publisher html/index-page/@ref option.  We write it first, so if   -->
<!-- the deprecated scheme is in place then it will overwrite this one. -->
<!-- See https://css-tricks.com/redirect-web-page/ for alternatives     -->
<!-- NB: the use of the "containing-filename" template will require a   -->
<!-- chunking level or else the template may go into infinite           -->
<!-- recursion.  So we also protect against the chunking-level not      -->
<!-- being set properly.                                                -->
<xsl:template name="index-redirect-page">
    <!-- $html-index-page-entered-ref comes from the publisher variables -->
    <!-- stylesheet.  It may be empty, signifying no election beyond     -->
    <!-- the defaults, or it is a reference to some actual node with a   -->
    <!-- matching @xml:id value.  We now need to see if it is a node     -->
    <!-- that is a complete webpage at the current chunking level.       -->
    <!--                                                                 -->
    <!-- But first, we see if there is a coding error, due to            -->
    <!-- the critical chunk level variable being overridden              -->
    <xsl:if test="$chunk-level = ''">
        <xsl:message>PTX:BUG     the $chunk-level variable has been left undefined&#xa;due to a change in a stylesheet that imports the HTML conversion&#xa;and the computation of an index page may fail spectacularly (infinite recursion?)"</xsl:message>
    </xsl:if>
    <xsl:variable name="sanitized-ref">
        <xsl:choose>
            <!-- no publisher file entry implies empty entered ref -->
            <xsl:when test="$html-index-page-entered-ref = ''"/>
            <!-- now we have a node, is it the top of a page? -->
            <xsl:otherwise>
                <!-- true/false values if node creates a web page -->
                <xsl:variable name="is-intermediate">
                    <xsl:apply-templates select="id($html-index-page-entered-ref)" mode="is-intermediate"/>
                </xsl:variable>
                <xsl:variable name="is-chunk">
                    <xsl:apply-templates select="id($html-index-page-entered-ref)" mode="is-chunk"/>
                </xsl:variable>
                <xsl:choose>
                    <!-- really is a web-page -->
                    <xsl:when test="($is-intermediate = 'true') or ($is-chunk = 'true')">
                        <xsl:value-of select="$html-index-page-entered-ref"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>PTX:WARNING:   the requested HTML index page cannot be constructed since "<xsl:value-of select="$html-index-page-entered-ref"/>" is not a complete web page at the current chunking level (level <xsl:value-of select="$chunk-level"/>).  Defaults will be used instead</xsl:message>
                        <xsl:text/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Now have a good @xml:id for an extant webpage, or an empty -->
    <!-- string signals we need to choose a sensible default. The   -->
    <!-- default is the "frontmatter" page, if possible, otherwise  -->
    <!-- the root page. The variable $html-index-page will be the   -->
    <!-- full name (*.html) of a page guaranteed to be built by     -->
    <!-- the chunking routines.                                     -->
    <xsl:variable name="html-index-page">
        <xsl:choose>
            <!-- publisher's choice survives -->
            <xsl:when test="not($sanitized-ref = '')">
                <xsl:apply-templates select="id($sanitized-ref)" mode="containing-filename"/>
            </xsl:when>
            <!-- now need to create defaults                        -->
            <!-- the level of the frontmatter is a bit conflicted   -->
            <!-- but it is a chunk iff there is any chunking at all -->
            <xsl:when test="$document-root/frontmatter and ($chunk-level &gt; 0)">
                <xsl:apply-templates select="$document-root/frontmatter" mode="containing-filename"/>
            </xsl:when>
            <!-- absolute last option is $document-root, *always* a webpage -->
            <xsl:otherwise>
                <xsl:apply-templates select="$document-root" mode="containing-filename"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- build a very simple  index.html  page pointing at  $html-index-page -->
    <!-- This is the one place we insert a (timestamped) blurb, since the    -->
    <!-- file is already exceptional and one-off                             -->
    <exsl:document href="index.html" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
        <html>
            <xsl:text>&#xa;</xsl:text>
            <xsl:call-template name="converter-blurb-html"/>
            <!-- Open Graph Protocol only in "meta" elements, within "head" -->
            <head xmlns:og="http://ogp.me/ns#" xmlns:book="https://ogp.me/ns/book#">
                <meta http-equiv="refresh" content="0; URL='{$html-index-page}'" />
                <!-- Add a canonical link here, in generic build case? -->
                <!-- more "meta" elements for discovery -->
                <xsl:call-template name="open-graph-info"/>
            </head>
            <!-- body is non-existent, i.e. empty -->
            <body/>
        </html>
    </exsl:document>
</xsl:template>

<!-- ################ -->
<!-- Structural Nodes -->
<!-- ################ -->

<!-- Read the code and documentation for "chunking" in      -->
<!-- xsl/pretext-common.xsl  This will help explain         -->
<!-- document structure (not XML structure).                -->
<!--                                                        -->
<!-- With an implementation of a file-wrapping routine,     -->
<!-- a typical use is to                                    -->
<!--                                                        -->
<!--   (a) apply a default template to the structural       -->
<!--       node for a complete (chunk'ed) node              -->
<!--                                                        -->
<!--   (b) apply a modal template to the structural         -->
<!--       node for a summary (intermediate) node           -->
<!--                                                        -->
<!-- The "file-wrap" routine should accept a $content       -->
<!-- parameter holding the contents of the body of the page -->

<!-- A complete page for a structural division -->
<!-- Unlike the base implemenation in -common we pass a        -->
<!-- "heading-level", which begins at 2 to account for an "h1" -->
<!-- being used in the masthead of the page infrastructure.    -->
<xsl:template match="&STRUCTURAL;" mode="chunk">
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="content">
            <xsl:apply-templates select=".">
                 <xsl:with-param name="heading-level" select="2"/>
            </xsl:apply-templates>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- A summary page for a structural division -->
<!-- Processing of a structural node realized as an           -->
<!-- intermediate/summary node.                               -->
<!-- We pass in a "heading-level", which begins at 2 to       -->
<!-- account for an "h1" being used in the masthead of the    -->
<!-- page infrastructure.                                     -->
<xsl:template match="&STRUCTURAL;" mode="intermediate">
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="content">
            <!-- location info for debugging efforts -->
            <xsl:apply-templates select="." mode="debug-location" />
            <!-- Heading, div for this structural subdivision -->
            <section class="{local-name(.)}">
                <xsl:apply-templates select="." mode="html-id-attribute"/>
                <xsl:apply-templates select="." mode="section-heading">
                    <xsl:with-param name="heading-level" select="2"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="." mode="author-byline"/>
                <!-- Special case when building page for frontmatter without a titlepage -->
                <xsl:if test="self::frontmatter[not(titlepage)]">
                    <xsl:call-template name="frontmatter-title" />
                </xsl:if>
                <xsl:apply-templates select="objectives|introduction|titlepage|abstract" />
                <!-- Links to subsidiary divisions, as a group of button/hyperlinks -->
                <nav class="summary-links">
                    <ul>
                        <xsl:apply-templates select="*" mode="summary-nav" />
                    </ul>
                </nav>
                <xsl:apply-templates select="conclusion|outcomes"/>
                <!-- Insert permalink -->
                <xsl:apply-templates select="." mode="permalink"/>
            </section>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- Navigation -->
<!-- Structural nodes on a summary page  -->
<!-- become attractive button/hyperlinks -->
<xsl:template match="&STRUCTURAL;" mode="summary-nav">
    <xsl:variable name="num">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:variable name="url">
        <xsl:apply-templates select="." mode="url" />
    </xsl:variable>
    <li>
        <a href="{$url}" class="internal">
            <!-- do not include an empty codenumber span -->
            <xsl:if test="not($num = '')">
                <span class="codenumber">
                    <xsl:value-of select="$num" />
                </span>
                <xsl:text> </xsl:text>
            </xsl:if>
            <!-- title is required on structural elements -->
            <span class="title">
                <xsl:apply-templates select="." mode="title-short" />
            </span>
        </a>
    </li>
</xsl:template>

<!-- introduction (etc.) and conclusion get dropped -->
<xsl:template match="*" mode="summary-nav" />

<!-- Default template for content of a structural  -->
<!-- division, which could be an entire page's     -->
<!-- worth, or just a subdivision within a page    -->
<!-- Increment $heading-level via this template    -->
<!-- We use a modal template, so it can be called  -->
<!-- one more time for a printout to make          -->
<!-- printable standalone versions.                -->
<xsl:template match="&STRUCTURAL;">
    <xsl:param name="heading-level"/>

    <xsl:apply-templates select="." mode="structural-division-content">
        <xsl:with-param name="heading-level" select="$heading-level"/>
    </xsl:apply-templates>

    <!-- For a printout (worksheet or handout), we do it again,   -->
    <!-- to generate a standalone printable and editable version. -->
    <!-- NB we don't produce these for portable html.             -->
    <xsl:if test="(self::worksheet or self::handout) and not($b-portable-html)">
        <xsl:apply-templates select="." mode="standalone-printout">
            <xsl:with-param name="heading-level" select="$heading-level"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- This is where a division becomes an HTML "section".  It may -->
<!-- be the content wrapped as an entire HTML page, or it may be -->
<!-- a subdivision that is just part of a page.                  -->
<xsl:template match="&STRUCTURAL;" mode="structural-division-content">
    <xsl:param name="heading-level"/>

    <!-- Specialized divisions "exercises" and "worksheet" can be used   -->
    <!-- as vehicles for collections of "exercise" as group work modules -->
    <!-- NB: this assumes that the "exercises" is an entire page, so     -->
    <!-- checks if it is a subdivision of a "chapter" (or "appendix").   -->
    <!-- In other words, these divisions must be Runestone "subchapter". -->

    <xsl:variable name="b-is-groupwork"
                  select="$b-host-runestone and (@groupwork = 'yes') and (self::worksheet or self::exercises) and (parent::chapter or parent::appendix)"/>

    <!-- location info for debugging efforts -->
    <xsl:apply-templates select="." mode="debug-location" />
    <!-- Heading, div for this structural subdivision -->
    <section>
        <xsl:attribute name="class">
            <xsl:value-of select="local-name(.)"/>
            <!-- mark "section" for potential styling, etc -->
            <xsl:if test="$b-is-groupwork">
                <xsl:text> groupwork</xsl:text>
            </xsl:if>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <!-- page-margins-attribute will be empty unless in a printout's standalone page -->
        <xsl:apply-templates select="." mode="page-margins-attribute"/>
        <xsl:apply-templates select="." mode="section-heading">
            <xsl:with-param name="heading-level" select="$heading-level"/>
        </xsl:apply-templates>
        <!-- Special case when building page for frontmatter without a titlepage -->
        <xsl:if test="self::frontmatter[not(titlepage)]">
            <xsl:call-template name="frontmatter-title"/>
        </xsl:if>
        <xsl:apply-templates select="." mode="author-byline"/>
        <!-- If there is watermark text, we print it here in an assistive p -->
        <!-- so that it is the first thing read by a screen-reader user.    -->
        <xsl:if test="$b-watermark and $heading-level = 2">
            <p class="watermark">
                <xsl:text>Watermark text: </xsl:text>
                <xsl:value-of select="$watermark-text"/>
                <xsl:text></xsl:text>
            </p>
        </xsl:if>
        <!-- After the heading, and before the actual guts, we      -->
        <!-- sometimes annotate with the source                     -->
        <!-- of the current element.  This calls a stub, unless     -->
        <!-- a separate stylesheet is used to define the template,  -->
        <!-- and the method is defined there.                       -->
        <xsl:apply-templates select="." mode="view-source-widget"/>

        <!-- This is usually recurrence, so increment heading-level,  -->
        <!-- but "book" and "article" have an h1  masthead, so if     -->
        <!-- this is the context, we just pass along the level of     -->
        <!-- "2" which is supplied by the chunking templates          -->
        <!-- N.B. the modal "solutions" templates increment           -->
        <!--      $heading-level as "exercise" are produced, so       -->
        <!--      we by-pass the increment here.                      -->
        <xsl:variable name="next-level">
            <xsl:choose>
                <xsl:when test="self::book or self::article or self::solutions">
                    <xsl:value-of select="$heading-level"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$heading-level + 1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Most divisions are a simple list of elements to be       -->
        <!-- processed in document order, once we handle metadata     -->
        <!-- properly, and also kill it so it is not caught up here.  -->
        <!-- So the "inner-content" template just processes children  -->
        <!-- in document order.  Exceptions are:                      -->
        <!--   "solutions": no children, so built via a constructive  -->
        <!--                modal template                            -->
        <!--   "glossary": is presumed to have a very specific        -->
        <!--               structure which requires elements          -->
        <!--               at the division level                      -->

        <xsl:apply-templates select="." mode="structural-division-inner-content">
            <xsl:with-param name="heading-level" select="$next-level"/>
        </xsl:apply-templates>

        <!-- Sometimes conclude with groupwork submission items -->
        <xsl:if test="$b-is-groupwork">
            <xsl:apply-templates select="." mode="runestone-groupwork"/>
        </xsl:if>

        <!-- Include permalink for the section as last child -->
        <xsl:apply-templates select="." mode="permalink"/>
    </section>
</xsl:template>

<!-- A glossary has a headnote, followed by a sequence  -->
<!-- of glossary items ('gi").  This could be the place -->
<!-- to get fancy and segment the entries with spacing  -->
<!-- by letter, or similar. Terminal (as a specialized  -->
<!-- division) and the  $heading-level  affects nothing -->
<xsl:template match="glossary" mode="structural-division-inner-content">
    <xsl:param name="heading-level"/>

    <xsl:apply-templates select="headnote"/>
    <dl class="glossary">
        <xsl:apply-templates select="gi"/>
    </dl>
</xsl:template>

<!-- A "solutions" specialized division does not have any children -->
<!-- at all, it gets built by mining content from other places     -->
<xsl:template match="solutions" mode="structural-division-inner-content">
    <xsl:param name="heading-level"/>

    <xsl:apply-templates select="." mode="solutions">
        <xsl:with-param name="heading-level" select="$heading-level"/>
    </xsl:apply-templates>
</xsl:template>

<!-- This is identical to the default "structural-division-inner-content" -->
<!-- template just below, excepting there are modifications for Runestone -->
<!-- to accomodate timed exams and group work.                            -->
<xsl:template match="exercises" mode="structural-division-inner-content">
    <xsl:param name="heading-level"/>

    <!-- Similar to variable above, except we know this is an "exercises" -->
    <xsl:variable name="b-is-groupwork"
              select="$b-host-runestone and (@groupwork = 'yes') and (parent::chapter or parent::appendix)"/>

    <xsl:variable name="the-exercises">
        <xsl:apply-templates select="*">
            <xsl:with-param name="heading-level" select="$heading-level"/>
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:choose>
        <xsl:when test="@time-limit and $b-is-groupwork">
            <xsl:message>PTX:ERROR:   an &quot;exercises&quot; division cannot simultaneously be a timed exam AND group work</xsl:message>
            <xsl:apply-templates select="." mode="location-report"/>
        </xsl:when>
        <xsl:when test="$b-is-groupwork">
            <!-- the actual list of exercises -->
            <xsl:copy-of select="$the-exercises"/>
            <!-- Infrastructure for groupwork is provided by -->
            <!--   "structural-division-content"             -->
            <!-- template (early and late in "section")      -->
            <!-- No progress indicator in this case -->
        </xsl:when>
        <!-- some extra wrapping for timed exercises      -->
        <!-- so we pass the $the-exercises as a parameter -->
        <!-- presence of @time-limit is the signal        -->
        <xsl:when test="@time-limit">
            <xsl:apply-templates select="." mode="runestone-timed-exam">
                <xsl:with-param name="the-exercises" select="$the-exercises"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <!-- the actual list of exercises -->
            <xsl:copy-of select="$the-exercises"/>
            <!-- only at "section" level. only when building for a Runestone server -->
            <xsl:apply-templates select="." mode="runestone-progress-indicator"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Only &STRUCTURAL; elements will pass through here, but we -->
<!-- can't limit the match (without explicit exclusions), this -->
<!-- is the default.  Which is to just apply templates to      -->
<!-- elements within the division. Optional: add RS progress.  -->
<xsl:template match="*" mode="structural-division-inner-content">
    <xsl:param name="heading-level"/>

    <xsl:apply-templates select="*">
        <xsl:with-param name="heading-level" select="$heading-level"/>
    </xsl:apply-templates>
    <!-- only at "section" level. only when building for a Runestone server -->
    <xsl:apply-templates select="." mode="runestone-progress-indicator"/>
</xsl:template>

<!-- Worksheets generate one additional version     -->
<!-- designed for printing, on Letter or A4 paper.  -->
<xsl:template match="worksheet|handout" mode="standalone-printout">
    <xsl:param name="heading-level"/>

    <xsl:variable name="base-filename">
        <xsl:apply-templates select="." mode="visible-id"/>
    </xsl:variable>
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="filename">
            <xsl:apply-templates select="." mode="standalone-printout-filename"/>
        </xsl:with-param>
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="structural-division-content">
                <xsl:with-param name="heading-level" select="$heading-level"/>
            </xsl:apply-templates>
        </xsl:with-param>
        <xsl:with-param name="b-printable" select="true()"/>
    </xsl:apply-templates>
</xsl:template>

<!-- ############### -->
<!-- Bits and Pieces -->
<!-- ############### -->

<!-- Heading for Document Nodes -->
<!-- Every document node goes the same way, a    -->
<!-- heading followed by its subsidiary elements -->
<!-- hit with templates.  This is the heading.   -->
<!-- Only "chapter" ever gets shown generically  -->
<!-- Subdivisions have titles, or default titles -->
<xsl:template match="*" mode="section-heading">
    <xsl:param name="heading-level"/>

    <xsl:variable name="html-heading">
        <xsl:apply-templates select="." mode="html-heading">
            <xsl:with-param name="heading-level" select="$heading-level"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:element name="{$html-heading}">
        <xsl:attribute name="class">
            <xsl:choose>
                <xsl:when test="(self::chapter or self::appendix or self::solutions/parent::backmatter) and ($numbering-maxlevel > 0)">
                    <xsl:text>heading</xsl:text>
                </xsl:when>
                <!-- hide "Chapter" when numbers are killed -->
                <xsl:otherwise>
                    <xsl:text>heading hide-type</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="heading-content" />
    </xsl:element>
</xsl:template>

<!-- Add an author's names, if present   -->
<!-- TODO: make match more restrictive?  -->
<xsl:template match="&STRUCTURAL;" mode="author-byline">
    <xsl:if test="author">
        <p class="byline">
            <xsl:apply-templates select="author" mode="name-list"/>
        </p>
    </xsl:if>
</xsl:template>

<!-- The front and back matter have their own style -->
<xsl:template match="frontmatter|backmatter" mode="section-heading" />

<!-- A book or article is the top level, so the   -->
<!-- masthead might suffice, else an author can   -->
<!-- provide a frontmatter/titlepage to provide   -->
<!-- more specific information.  In either event, -->
<!-- a typical section heading is out of place.   -->
<xsl:template match="book|article" mode="section-heading" />

<!-- An abstract needs structure, and an ID for a -->
<!-- link out of the ToC sidebar for an article   -->
<xsl:template match="abstract">
    <div class="abstract">
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <!-- title or heading?  We go with a default title, which will -->
        <!-- be localized.  Then ban an author-provided title in the   -->
        <!-- schema.  This allows for reasonable behavior in a ToC     -->
        <!-- sidebar.  (This is a non-issue for LaTeX, where a good    -->
        <!-- "abstract" environment exists.)                           -->
        <span class="title">
            <xsl:apply-templates select="." mode="title-full"/>
        </span>
        <xsl:apply-templates select="*"/>
        <!-- Display keywords.  Note: the placement of this here works for  -->
        <!-- articles that have an abstract.  Books (no abstract) will put  -->
        <!-- their keywords in the colophon.                                -->
        <xsl:apply-templates select="$bibinfo/keywords" />
        <!-- Display general support (funding) statement -->
        <xsl:apply-templates select="$bibinfo/support" />
    </div>
</xsl:template>

<!-- ######## -->
<!-- Headings -->
<!-- ######## -->

<!-- Both environments and sections have a "type,"         -->
<!-- a "codenumber," and a "title."  We format these       -->
<!-- consistently here with a modal template.  We can hide -->
<!-- components with classes on the enclosing "heading"    -->
<xsl:template match="*" mode="heading-content">
    <span class="type">
        <xsl:apply-templates select="." mode="type-name" />
    </span>
    <xsl:call-template name="space-styled"/>
    <span class="codenumber">
        <xsl:apply-templates select="." mode="number" />
    </span>
    <xsl:call-template name="space-styled"/>
    <span class="title">
        <xsl:apply-templates select="." mode="title-full" />
    </span>
</xsl:template>

<!-- Specialized Divisions -->
<!-- A specialized division may inherit a number from its parent  -->
<!-- ("exercises"), or it may not ever even get a number          -->
<!-- (backmatter/references is a singleton).  Whether or not to   -->
<!-- *display* a number at birth is therefore more complicated    -->
<!-- than *having* a number or not.                               -->
<!-- NB: We sneak in links for standalone versions of printouts.  -->
<xsl:template match="exercises|solutions|glossary|references|worksheet|handout|reading-questions" mode="heading-content">
    <span class="type">
        <xsl:apply-templates select="." mode="type-name"/>
    </span>
    <xsl:call-template name="space-styled"/>
    <!-- be selective about displaying numbers at birth-->
    <xsl:variable name="is-numbered">
        <xsl:apply-templates select="." mode="is-specialized-own-number"/>
    </xsl:variable>
    <span class="codenumber">
        <xsl:if test="($is-numbered = 'true')">
            <xsl:apply-templates select="." mode="number"/>
        </xsl:if>
    </span>
    <xsl:call-template name="space-styled"/>
    <span class="title">
        <xsl:apply-templates select="." mode="title-full" />
    </span>
    <!-- Links to the "printable" version(s), meant only for "viewable" -->
    <!-- printout, so CSS can kill on the "printable" versions          -->
    <!-- $paper is LOWER CASE "a4" and "letter"                         -->
    <!-- NB until printout printing can be done without extra files,    -->
    <!-- we omit this for portable html.                                -->
    <xsl:if test="(self::worksheet or self::handout) and not($b-portable-html)">
        <xsl:apply-templates select="." mode="standalone-printout-links"/>
    </xsl:if>
</xsl:template>

<!-- Links to the "printable" version(s), meant only for "viewable" -->
<!-- printout, so CSS can kill on the "printable" versions          -->
<!-- As of 2025-05-31, this is changing to a single print button    -->
<!-- and will later change to have the button to popout printable   -->
<!-- printout instead of linking to separate file.                  -->
<!-- We isolate link creation, so we can kill it simply in          -->
<!-- derivative  conversions                                        -->
<xsl:template match="worksheet|handout" mode="standalone-printout-links">
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="standalone-printout-filename"/>
    </xsl:variable>
    <xsl:variable name="print-preview-text">
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'print-preview'"/>
        </xsl:apply-templates>
    </xsl:variable>
    <div class="print-links">
        <a href="{$filename}" class="print-link" title="{$print-preview-text}">
            <xsl:call-template name="insert-symbol">
                <xsl:with-param name="name" select="'print'"/>
            </xsl:call-template>
        </a>
    </div>
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
<!-- A frontmatter has no title, so we reproduce the       -->
<!-- title of the work (book or article) here              -->
<!-- NB: this could done with a "section-heading" template?-->
<!-- Other divisions (eg, colophon, preface) will follow   -->
<!-- This is all within a .frontmatter class for CSS       -->
<xsl:template match="titlepage">
    <!-- Use a context-free template to generate -->
    <!-- an "h2" title/subtitle heading          -->
    <xsl:call-template name="frontmatter-title"/>
    <!-- text generator for title page items from "bibinfo" -->
    <xsl:apply-templates select="$document-root/frontmatter/titlepage/titlepage-items" />
</xsl:template>

<xsl:template match="titlepage-items">
    <!-- Put authors and editors first, in document order -->
    <xsl:apply-templates select="$bibinfo/author|$bibinfo/editor" mode="full-info"/>
    <!-- Followed by "contributors" authored as credit (which have titles) -->
    <xsl:apply-templates select="$bibinfo/credit[title]" />
    <!-- and finally date -->
    <xsl:apply-templates select="$bibinfo/date" />
</xsl:template>

<!-- Title to put on frontmatter page.  This is a context-free named template      -->
<!-- since an author's source may not have a frontmatter/titlepage element,        -->
<!-- yet we still want to grap the title (and subtitle) for use on pages           -->
<!-- generated by a "frontmatter" element (including, e.g., an intermediate page). -->
<xsl:template name="frontmatter-title">
    <xsl:variable name="b-has-subtitle" select="$document-root/subtitle"/>
    <h2 class="heading">
        <span class="title">
            <xsl:apply-templates select="$document-root" mode="title-full" />
        </span>
        <xsl:if test="$b-has-subtitle">
            <span class="subtitle">
                <xsl:apply-templates select="$document-root" mode="subtitle" />
            </span>
        </xsl:if>
    </h2>
</xsl:template>

<!-- A "credit" required "title" followed by an author (or several)    -->
<!-- CSS should give lesser prominence to these (versus "full" author) -->
<xsl:template match="bibinfo/credit[title]">
    <div class="credit">
        <div class="title">
            <xsl:apply-templates select="." mode="title-full"/>
        </div>
        <xsl:apply-templates select="author" mode="full-info" />
    </div>
</xsl:template>

<!-- The time element has content that is "human readable" time -->
<xsl:template match="bibinfo/date">
    <div class="date">
        <xsl:apply-templates/>
    </div>
</xsl:template>

<!-- Authors, Editors, Creditors -->

<!-- Authors and editors with affiliations (eg, on title page) -->
<!-- CSS does not distinguish authors from editors             -->
<xsl:template match="author|editor" mode="full-info">
    <div class="author">
        <div class="author-name">
            <xsl:apply-templates select="personname" />
            <xsl:if test="self::editor">
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="." mode="type-name" />
            </xsl:if>
        </div>
        <div class="author-info">
            <xsl:if test="affiliation">
                <xsl:apply-templates select="affiliation"/>
                <xsl:if test="affiliation/following-sibling::*">
                    <br />
                </xsl:if>
            </xsl:if>
            <xsl:if test="email">
                <xsl:apply-templates select="email" />
                <xsl:if test="email/following-sibling::*">
                    <br />
                </xsl:if>
            </xsl:if>
            <xsl:if test="support">
                <xsl:apply-templates select="support" />
                <xsl:if test="support/following-sibling::*">
                    <br />
                </xsl:if>
            </xsl:if>
        </div>
    </div>
</xsl:template>

<xsl:template match="affiliation">
    <xsl:if test="department">
        <xsl:apply-templates select="department" />
        <xsl:if test="department/following-sibling::*">
            <br />
        </xsl:if>
    </xsl:if>
    <xsl:if test="institution">
        <xsl:apply-templates select="institution" />
        <xsl:if test="institution/following-sibling::*">
            <br />
        </xsl:if>
    </xsl:if>
    <xsl:if test="location">
        <xsl:apply-templates select="location" />
        <xsl:if test="location/following-sibling::*">
            <br />
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- Departments and Institutions are free-form, or sequences of lines -->
<xsl:template match="department|institution|location">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="department[line]|institution[line]|location[line]">
    <xsl:apply-templates select="line" />
</xsl:template>

<!-- Keywords -->
<xsl:template match="bibinfo/keywords">
    <div class="keywords">
        <span class="title">
            <xsl:apply-templates select="." mode="title-full"/>
        </span>
        <xsl:apply-templates select="*" />
        <xsl:text>.</xsl:text>
    </div>
</xsl:template>

<!-- General support (not for a particular author) -->
<xsl:template match="bibinfo/support">
    <div class="support">
        <xsl:apply-templates select="*"/>
    </div>
</xsl:template>


<!-- Front Colophon -->
<!-- Licenses, ISBN, Cover Designer, etc -->
<!-- We process pieces, in document order -->
<!-- TODO: edition, publisher, production notes, cover design, etc -->
<!-- TODO: revision control commit hash -->
<xsl:template match="frontmatter/colophon" mode="structural-division-inner-content">
    <xsl:param name="heading-level"/>
    <!-- Include publication data from titlepage appropriate for colophon -->
    <xsl:apply-templates select="colophon-items"/>
</xsl:template>

<xsl:template match="colophon-items">
     <xsl:apply-templates select="$bibinfo/credit[role]" />
     <xsl:apply-templates select="$bibinfo/edition" />
     <xsl:apply-templates select="$bibinfo/website" />
     <xsl:apply-templates select="$bibinfo/copyright" />
     <!-- NB: keywords are included in a colophon for a book, but under the abstract of an article -->
     <xsl:apply-templates select="$bibinfo/keywords" />
     <xsl:apply-templates select="$bibinfo/support" />
</xsl:template>

<xsl:template match="bibinfo/credit[role]">
    <div class="credit">
        <b class="title">
            <xsl:apply-templates select="role" />
        </b>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="entity"/>
    </div>
</xsl:template>

<xsl:template match="bibinfo/edition">
    <div class="credit">
        <b class="title">
            <xsl:apply-templates select="." mode="type-name" />
        </b>
        <xsl:text> </xsl:text>
        <xsl:apply-templates/>
    </div>
</xsl:template>

<!-- website for the book -->
<xsl:template match="bibinfo/website">
    <div class="credit">
        <b class="title">
            <xsl:apply-templates select="." mode="type-name" />
        </b>
        <xsl:text> </xsl:text>
        <!-- URL for canonical project website                -->
        <!-- NB: interior of "website" is a "url" in author's -->
        <!-- source, but the pre-processor adds a footnote    -->
        <!-- Only one presumed, and thus enforced here        -->
        <xsl:apply-templates select="url[1]|fn[1]" />
    </div>
</xsl:template>

<xsl:template match="bibinfo/copyright">
    <div class="para copyright">
        <xsl:call-template name="copyright-character"/>
        <xsl:apply-templates select="year" />
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="holder" />
    </div>
    <xsl:if test="shortlicense">
        <div class="para license">
            <xsl:apply-templates select="shortlicense" />
        </div>
    </xsl:if>
</xsl:template>

<!-- Introductions and Conclusions -->
<!-- Simple containers, allowed before and after           -->
<!-- explicit subdivisions, to introduce or summarize      -->
<!-- Title optional, typically just a few paragraphs       -->
<!-- Also occur in "smaller" units (elsewhere), so the     -->
<!-- HTML element varies from a "section" to an "article"  -->

<!-- Not knowlable as a component of bigger things, a      -->
<!-- pure container.  This is the component of a division. -->
<!-- Tunnel the duplication flag, drop id if duplicate     -->
<xsl:template match="introduction[parent::*[&STRUCTURAL-FILTER;]]|conclusion[parent::*[&STRUCTURAL-FILTER;]]">
    <xsl:param name="b-original" select="true()" />
    <section>
        <!-- cheap, but it works -->
        <xsl:attribute name="class">
            <xsl:value-of select="local-name(.)" />
        </xsl:attribute>
        <xsl:if test="$b-original">
            <xsl:apply-templates select="." mode="html-id-attribute"/>
        </xsl:if>
        <xsl:if test="title">
            <xsl:variable name="hN">
                <xsl:apply-templates select="." mode="hN"/>
            </xsl:variable>
            <xsl:element name="{$hN}">
                <xsl:attribute name="class">
                    <xsl:text>heading</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="." mode="title-full" />
                <span> </span>
            </xsl:element>
        </xsl:if>
        <xsl:apply-templates select="*">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </section>
</xsl:template>

<!-- ####################### -->
<!-- Back Matter Components -->
<!-- ####################### -->

<!-- Back Colophon -->
<!-- Nothing special, so just process similarly to front -->

<!--               -->
<!-- Notation List -->
<!--               -->

<!-- Implementation of abstract templates.       -->
<!-- See more complete code comments in -common. -->

<xsl:template name="present-notation-list">
    <xsl:param name="content"/>

    <table class="notation-list">
        <tr>
            <th>
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'symbol'"/>
                </xsl:apply-templates>
            </th>
            <th>
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'description'"/>
                </xsl:apply-templates>
            </th>
            <th>
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'location'"/>
                </xsl:apply-templates>
            </th>
        </tr>
        <xsl:copy-of select="$content"/>
    </table>
</xsl:template>

<!-- Process *exactly* one "m" element             -->
<!-- Duplicate the provided description            -->
<!-- Create a cross-reference to enclosing content -->
<xsl:template match="notation" mode="present-notation-item">
    <tr>
        <td>
            <xsl:apply-templates select="usage/m[1]"/>
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
<!-- NB: presumes this only gets used for   -->
<!-- knowls that end up in a "notation"     -->
<!-- list (can't adjust @match since it     -->
<!-- claws up the tree)                     -->
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
        <!-- TODO: xref-link's select is a fiction, maybe lead to bugs? -->
        <xsl:when test="$structural='true' or $block='true'">
            <xsl:apply-templates select="." mode="xref-link">
                <xsl:with-param name="target" select="." />
                <xsl:with-param name="origin" select="'notation'"/>
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
            <!-- As we make knowl content selectively, we need -->
            <!-- nto produce the content for the notation link -->
            <xsl:variable name="is-knowl">
                <xsl:apply-templates select="." mode="xref-as-knowl"/>
            </xsl:variable>
            <xsl:if test="$is-knowl = 'true'">
                <xsl:apply-templates select="." mode="manufacture-knowl">
                    <xsl:with-param name="origin" select="'notation'"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:when>
        <!-- nothing interesting here, so step up a level -->
        <!-- Eventually we find the top-level structure   -->
        <!-- eg article, book, etc                        -->
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="enclosure-xref" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ####################################### -->
<!-- Solutions Divisions, Content Generation -->
<!-- ####################################### -->

<!-- The "division-in-solutions" modal template from -common -->
<!-- calls the "duplicate-heading" modal template.           -->

<xsl:template match="*" mode="duplicate-heading">
    <xsl:param name="heading-level"/>
    <xsl:param name="heading-stack" select="."/>
    <xsl:variable name="hN">
        <xsl:text>h</xsl:text>
        <xsl:choose>
            <xsl:when test="$heading-level > 6">
                <xsl:text>6</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$heading-level"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$hN}">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
            <xsl:if test="not(self::chapter) or ($numbering-maxlevel = 0)">
                <xsl:text> hide-type</xsl:text>
            </xsl:if>
        </xsl:attribute>
        <xsl:attribute name="title">
            <xsl:apply-templates select="." mode="tooltip-text" />
        </xsl:attribute>
        <xsl:apply-templates select="$heading-stack" mode="duplicate-heading-content"/>
    </xsl:element>
</xsl:template>

<xsl:template match="*" mode="duplicate-heading-content">
    <xsl:variable name="is-specialized-division">
        <xsl:choose>
            <xsl:when test="self::task">
                <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="is-specialized-division"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="is-child-of-structured">
        <xsl:choose>
            <xsl:when test="parent::*[&TRADITIONAL-DIVISION-FILTER;]">
                <xsl:apply-templates select="parent::*[&TRADITIONAL-DIVISION-FILTER;]" mode="is-structured-division"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="title">
        <xsl:apply-templates select="." mode="title-full" />
    </xsl:variable>
    <!-- Since headings stack, we use a "p" to aid screen readers in pausing between headings -->
    <xsl:if test="$is-specialized-division = 'false' or $is-child-of-structured = 'true'">
        <span class="codenumber">
            <xsl:apply-templates select="." mode="number" />
        </span>
        <xsl:if test="$title != ''">
            <xsl:call-template name="space-styled"/>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$title != ''">
        <span class="title">
            <xsl:apply-templates select="." mode="title-full" />
        </span>
    </xsl:if>
    <xsl:if test="position() != last()">
        <br/>
    </xsl:if>
</xsl:template>


<!-- ############### -->
<!-- Arbitrary Lists -->
<!-- ############### -->

<!-- See general routine in  xsl/pretext-common.xsl -->
<!-- which expects the two named templates and the  -->
<!-- two division'al and element'al templates below,  -->
<!-- it contains the logic of constructing such a list -->

<!-- List-of entry/exit hooks -->
<!-- No ops for HTML          -->
<xsl:template name="list-of-begin" />
<xsl:template name="list-of-end" />

<!-- Subdivision headings in list-of's -->
<xsl:template match="*" mode="list-of-heading">
    <xsl:param name="heading-level"/>
    <xsl:apply-templates select="." mode="duplicate-heading">
        <xsl:with-param name="heading-level" select="$heading-level"/>
    </xsl:apply-templates>
</xsl:template>

<!-- Entries in list-of's -->
<!-- Partly borrowed from common routines -->
<!-- TODO: CSS styling of the div forcing the knowl to open in the right place -->
<!-- And spacing should be done with .type, .codenumber, .title                -->
<xsl:template match="*" mode="list-of-element">
    <!-- Name and number as a knowl/link, div to open against -->
    <!-- TODO: xref-link's select is a fiction, maybe lead to bugs? -->
    <div>
        <xsl:apply-templates select="." mode="xref-link">
            <xsl:with-param name="target" select="." />
            <xsl:with-param name="origin" select="'list-of'"/>
            <xsl:with-param name="content">
                <xsl:apply-templates select="." mode="type-name" />
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="." mode="number" />
            </xsl:with-param>
        </xsl:apply-templates>
        <!-- title plain, separated             -->
        <!-- xref version, no additional period -->
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-xref"/>
    </div>
    <!-- As we make knowl content selectively, we need -->
    <!-- nto produce the content for a "list-of" link  -->
    <xsl:variable name="is-knowl">
        <xsl:apply-templates select="." mode="xref-as-knowl"/>
    </xsl:variable>
    <xsl:if test="$is-knowl = 'true'">
        <xsl:apply-templates select="." mode="manufacture-knowl">
            <xsl:with-param name="origin" select="'list-of'"/>
        </xsl:apply-templates>
    </xsl:if>
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

<!-- Implementation of abstract index template -->
<!-- No wrapper in HTML output                 -->
<xsl:template name="present-index">
    <xsl:param name="content"/>

    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- Implementation of abstract letter group template        -->
<!-- wrap the group in a div, which will be used for styling -->
<xsl:template name="present-letter-group">
    <xsl:param name="the-index-list"/>
    <xsl:param name="letter-group"/>
    <xsl:param name="current-letter"/>
    <xsl:param name="content"/>

    <div class="indexletter" id="indexletter-{$current-letter}">
        <xsl:copy-of select="$content"/>
    </div>
</xsl:template>

<!-- Implementation of presentation of index item, sub index item,      -->
<!-- sub sub index item, in other words, headings at depth 1, 2, and 3. -->
<!--   $heading-level: is 1, 2 or 3, to be translated to indicators     -->
<!--                   for styling (such as indentation, newlines, etc) -->
<!--   $content:       the actual text of the heading                   -->

<xsl:template name="present-index-heading">
    <xsl:param name="the-index-list"/>
    <xsl:param name="heading-group"/>
    <xsl:param name="b-write-locators"/>
    <xsl:param name="heading-level"/>
    <xsl:param name="content"/>

    <div class="indexitem">
        <!-- translate heading-level to a CSS class name -->
        <xsl:attribute name="class">
            <xsl:choose>
                <xsl:when test="$heading-level = 1">
                    <xsl:text>indexitem</xsl:text>
                </xsl:when>
                <xsl:when test="$heading-level = 2">
                    <xsl:text>subindexitem</xsl:text>
                </xsl:when>
                <xsl:when test="$heading-level = 3">
                    <xsl:text>subsubindexitem</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:attribute>
        <!-- the actual heading content -->
        <xsl:copy-of select="$content"/>
        <!-- perhaps time to write locators -->
        <xsl:if test="$b-write-locators">
            <xsl:call-template name="locator-list">
                <xsl:with-param name="the-index-list" select="$the-index-list"/>
                <xsl:with-param name="heading-group" select="$heading-group" />
                <!-- use space to separate knowls -->
                <xsl:with-param name="cross-reference-separator" select="' '" />
            </xsl:call-template>
        </xsl:if>
    </div>
</xsl:template>

<!-- Implementation of abstract templates for presentation of locators -->

<xsl:template name="present-index-locator">
    <xsl:param name="content"/>

    <span class="indexknowl">
        <xsl:copy-of select="$content"/>
    </span>
</xsl:template>

<xsl:template name="present-index-see">
    <xsl:param name="content"/>

    <span class="see">
        <xsl:copy-of select="$content"/>
    </span>
</xsl:template>

<xsl:template name="present-index-see-also">
    <xsl:param name="content"/>

    <span class="seealso">
        <xsl:copy-of select="$content"/>
    </span>
</xsl:template>

<xsl:template name="present-index-italics">
    <xsl:param name="content"/>

    <em>
        <xsl:copy-of select="$content"/>
    </em>
</xsl:template>


<!-- Climb the tree looking for an enclosing structure of        -->
<!-- interest.  Create cross-reference.                          -->
<!-- One notable case: paragraph must be "top-level", just below -->
<!-- a structural document node                                  -->
<!-- Recursion always halts, since "pretext" is structural       -->
<!-- TODO: save knowl or section link                            -->
<!-- We create content of "xref-knowl" if it is a block.         -->
<!-- TODO: identify index targets consistently in "make-xref-knowls" -->
<!-- template, presumably parents of "idx" that are knowlable.       -->
<xsl:template match="index-list" mode="index-enclosure">
    <xsl:param name="enclosure"/>

    <xsl:variable name="structural">
        <xsl:apply-templates select="$enclosure" mode="is-structural"/>
    </xsl:variable>
    <xsl:variable name="block">
        <xsl:apply-templates select="$enclosure" mode="is-block"/>
    </xsl:variable>
    <xsl:choose>
        <!-- found a structural parent first           -->
        <!-- collect a url for a traditional hyperlink -->
        <xsl:when test="($structural = 'true') or ($block = 'true')">
            <xsl:apply-templates select="." mode="xref-link">
                <xsl:with-param name="target" select="$enclosure"/>
                <xsl:with-param name="origin" select="'index'"/>
                <xsl:with-param name="content">
                    <xsl:apply-templates select="$enclosure" mode="type-name"/>
                </xsl:with-param>
            </xsl:apply-templates>
            <xsl:variable name="need-knowl">
                <xsl:apply-templates select="$enclosure" mode="xref-as-knowl"/>
            </xsl:variable>
            <xsl:if test="$block = 'true' and $need-knowl = 'true'">
                <xsl:apply-templates select="$enclosure" mode="manufacture-knowl">
                    <xsl:with-param name="origin" select="'index'"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <!-- Recurse.  The "index-list" gets passed along unchanged,     -->
            <!-- as the context for location of the eventual cross-reference -->
            <xsl:apply-templates select="." mode="index-enclosure">
                <xsl:with-param name="enclosure" select="$enclosure/parent::*"/>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################################### -->
<!-- Cross-Reference Knowls (xref-knowl) -->
<!-- ################################### -->

<!-- Many elements are candidates for cross-references     -->
<!-- and many of those are nicely implemented as knowls.   -->

<!-- Cross-references as knowls                               -->
<!-- Override to turn off cross-references as knowls          -->
<!-- NB: this device makes it easy to turn off knowlification -->
<!-- entirely, since some renders cannot use knowl JavaScript -->
<xsl:template match="*" mode="xref-as-knowl">
    <xsl:value-of select="false()" />
</xsl:template>
<!-- TEMPORARY: var/li is a WeBWorK popup or radio button, -->
<!-- which is not a cross-reference target (it originates  -->
<!-- in PG-code), and an error results when the heading in -->
<!-- the knowl content tries to compute a number           -->
<xsl:template match="fn|p|blockquote|biblio|biblio/note|interactive/instructions|gi|&DEFINITION-LIKE;|&OPENPROBLEM-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|task|&FIGURE-LIKE;|&THEOREM-LIKE;|&PROOF-LIKE;|case|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&ASIDE-LIKE;|poem|assemblage|paragraphs|&GOAL-LIKE;|exercise|&SOLUTION-LIKE;|&DISCUSSION-LIKE;|exercisegroup|men|mdn[not(mrow)]|mrow|md[not(mrow) and (@numbered = 'yes')]|li[not(parent::var)]|contributor|fragment" mode="xref-as-knowl">
    <xsl:param name="link" select="/.." />
    <xsl:choose>
        <xsl:when test="$b-skip-knowls or $html-xref-knowled = 'never' or $b-portable-html">
            <xsl:value-of select="false()"/>
        </xsl:when>
        <xsl:when test="$html-xref-knowled = 'maximum'">
            <xsl:value-of select="true()"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- Case $html-xref-knowled = 'cross-page'                                    -->
            <!-- Find the nearest common ancestor of the link and target                   -->
            <!-- https://stackoverflow.com/questions/538293/find-common-parent-using-xpath -->
            <xsl:variable name="nearest-common-ancestor"
                          select="./ancestor::*[count(. | $link/ancestor::*) = count($link/ancestor::*)] [1]"/>
            <xsl:variable name="nearest-ancestor-level">
                <xsl:apply-templates select="$nearest-common-ancestor" mode="enclosing-level"/>
            </xsl:variable>
            <!-- remove not(), replace operator with <, then radically different behavior -->
            <xsl:value-of select="not($nearest-ancestor-level >= $chunk-level)"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- This template makes the knowl content for cross-references    -->
<!-- (and not index entries, notation list entries, etc.)  It      -->
<!-- accumulates and de-duplicagtes all the @ref/@xml:id strings   -->
<!-- and then makes the files of content for the target *once*.    -->
<!-- Initiation is one-time, late in the entry template.           -->
<!--                                                               -->
<!-- A "fragref" for literate programming has specialized behavior -->
<!-- when reconstructing program code.  But as a knowl in HTML it  -->
<!-- is isomorphic to "xref", so we lump them into this template.  -->
<!-- Also, because we collect unique id's it will no longer be     -->
<!-- possible to use the "origin" parameter to distinguish the     -->
<!-- reference provoking the knowl (an "xref" and a "fragref"      -->
<!-- could point to the same target).  There is little downside in -->
<!-- this, and some upside in not putting identical content into   -->
<!-- multiple locations.                                           -->
<xsl:template match="*" mode="make-xref-knowls">
    <xsl:variable name="xref-ids">
        <!-- Round up all "xref" elements -->
        <xsl:variable name="all-xref" select="$document-root//xref"/>
        <!-- Rund up all "fragref" elements, which are very similar -->
        <xsl:variable name="all-fragref" select="$document-root//fragref"/>
        <!-- A "proof" (or similar) with a @ref attribute doubles as  -->
        <!-- an "xref" to the theorem it proves.  This should only be -->
        <!-- a "detached" proof, not living inside a THEOREM-LIKE,    -->
        <!-- nor inside a SOLUTION-LIKE. An author's attempt to put a -->
        <!-- @ref on a non-detached proof will not create a knowl     -->
        <!-- clickable and so will be unavailable. We make the knowl  -->
        <!-- content here anyway, which does no real harm and should  -->
        <!-- stop once the author mends their ways.                   -->
        <!-- NB: there is an implicit PROOF-LIKE here.                -->
        <xsl:variable name="all-proofref" select="$document-root//proof[@ref]|$document-root//argument[@ref]|$document-root//justification[@ref]|$document-root//reasoning[@ref]|$document-root//explanation[@ref]"/>
        <!-- Consider all "xref-like" together as a group -->
        <xsl:for-each select="$all-xref|$all-fragref|$all-proofref">
            <xsl:choose>
                <!-- ignore, no-op -->
                <xsl:when test="@provisional"/>
                <!-- just use @first, clean-up spaces -->
                <xsl:when test="@first and @last">
                    <xid>
                        <xsl:value-of select="normalize-space(@first)"/>
                    </xid>
                </xsl:when>
                <!-- a space-separated or comma-separated list -->
                <!-- to bust up and wrap many times in "xid"   -->
                <xsl:when test="@ref and (contains(normalize-space(@ref), ' ') or contains(@ref, ','))">
                    <xsl:variable name="clean-list" select="concat(normalize-space(translate(@ref, ',', ' ')), ' ')"/>
                    <xsl:call-template name="split-ref-list">
                        <xsl:with-param name="list" select="$clean-list"/>
                    </xsl:call-template>
                </xsl:when>
                <!-- clean-up reference as a courtesy -->
                <xsl:when test="@ref">
                    <xid>
                        <xsl:value-of select="normalize-space(@ref)"/>
                    </xid>
                </xsl:when>
                <!-- could error-check here -->
                <xsl:otherwise/>
            </xsl:choose>
            <!-- TODO: cruise "idx" to get references to parents -->
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="id-nodes" select="exsl:node-set($xref-ids)"/>

    <!-- might work better if sorted first -->
    <xsl:variable name="unique-ids-rtf">
        <xsl:for-each select="$id-nodes/xid[not(. = preceding::*/.)]">
            <xsl:copy-of select="."/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="unique-ids" select="exsl:node-set($unique-ids-rtf)"/>

    <xsl:for-each select="$unique-ids/xid">
        <!-- context change coming, so save off the actual id string -->
        <xsl:variable name="the-id" select="."/>
        <!-- for-each only loops over one item, but changes context, -->
        <!-- so the id() function is checking against the right document -->
        <xsl:for-each select="$document-root">
            <xsl:variable name="target" select="id($the-id)"/>
            <xsl:variable name="is-knowl">
                <xsl:apply-templates select="$target" mode="xref-as-knowl"/>
            </xsl:variable>
            <xsl:if test="$is-knowl = 'true'">
                <xsl:apply-templates select="$target" mode="manufacture-knowl">
                    <xsl:with-param name="origin" select="'xref'" />
                </xsl:apply-templates>
            </xsl:if>
        </xsl:for-each>
    </xsl:for-each>
</xsl:template>

<!-- Decompose a string of references into elements for id  -->
<!-- rtf above.  Note: each token has a space following it  -->
<xsl:template name="split-ref-list">
    <xsl:param name="list"/>

    <xsl:choose>
        <!-- final space causes recursion with -->
        <!-- totally empty list, so halt       -->
        <xsl:when test="$list = ''"/>
        <xsl:otherwise>
            <xid>
                <xsl:value-of select="substring-before($list, ' ')"/>
            </xid>
            <xsl:call-template name="split-ref-list">
                <xsl:with-param name="list" select="substring-after($list, ' ')"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Build file for xref-knowl content                            -->
<!-- Context is an object that is the target of a cross-reference -->
<!-- ("xref") and is known/checked to be implemented as a knowl.  -->
<xsl:template match="*" mode="manufacture-knowl">
    <xsl:param name="origin" select="''"/>

    <xsl:variable name="knowl-file">
        <xsl:apply-templates select="." mode="knowl-filename">
            <xsl:with-param name="origin" select="$origin"/>
        </xsl:apply-templates>
    </xsl:variable>
    <!-- N.B. can't form @href with xsl:attribute -->
    <exsl:document href="{$knowl-file}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
        <html>
            <xsl:call-template name="language-attributes"/>
            <xsl:call-template name="pretext-advertisement-and-style"/>
            <!-- header since separate file -->
            <xsl:text>&#xa;</xsl:text>
            <xsl:call-template name="converter-blurb-html-no-date"/>
            <head>
                <!-- dissuade indexing duplicated content -->
                <meta name="robots" content="noindex, nofollow" />
                <!-- we need Sage cell configuration functions     -->
                <!-- in the knowl file itself, the main Javascript -->
                <!-- is being placed on *every* page, if present   -->
                <!-- anywhere in the document, and that is         -->
                <!-- sufficient for the external knowl             -->
                <xsl:apply-templates select="." mode="sagecell" />
            </head>
            <!-- ignore MathJax signals everywhere, then enable selectively -->
            <body class="ignore-math">
                <!-- content, in xref style or hidden style     -->
                <!-- initiate tunneling duplication flag here   -->
                <!-- We send a flag to the "body" template      -->
                <!-- indicating the call is at the outermost    -->
                <!-- level of the knowl being constructed,      -->
                <!-- rather than to manufacture a child element -->
                <!-- Usually this parameter is ignored          -->
                <!-- An xref to an mrow results in a knowl      -->
                <!-- whose content is more than just the xref,  -->
                <!-- it is the entire containing md or mdn      -->

                <!-- NB: the Javascript controlling the animation of the   -->
                <!-- open/close of a knowl, presumes it begins with an     -->
                <!-- element enclosing the content.  This is guaranteed by -->
                <!-- the "body" template via the "body-element" template.  -->
                <xsl:choose>
                    <xsl:when test="self::mrow">
                        <xsl:apply-templates select="parent::*" mode="body">
                            <xsl:with-param name="block-type" select="'xref'" />
                            <xsl:with-param name="b-original" select="false()" />
                            <xsl:with-param name="b-top-level" select="true()" />
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="." mode="body">
                            <xsl:with-param name="block-type" select="'xref'" />
                            <xsl:with-param name="b-original" select="false()" />
                            <xsl:with-param name="b-top-level" select="true()" />
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- in-context link for xref-knowl content -->
                <span class="incontext">
                    <a class="internal">
                        <xsl:attribute name="href">
                            <xsl:apply-templates select="." mode="url"/>
                        </xsl:attribute>
                        <xsl:apply-templates select="." mode="type-name">
                            <xsl:with-param name="string-id" select="'incontext'"/>
                        </xsl:apply-templates>
                    </a>
                </span>
            </body>
        </html>
    </exsl:document>
</xsl:template>

<!-- The directories of knowls that are targets of references.  Most,   -->
<!-- but not all, filenames are based on the "visible-id" template,     -->
<!-- but this is organized so alternate naming conventions can be used. -->
<!-- The file extension is *.html so recognized as OK by Moodle, etc    -->
<xsl:template match="*" mode="knowl-filename">
    <xsl:param name="origin" select="''"/>

    <xsl:text>./knowl/</xsl:text>
    <xsl:choose>
        <xsl:when test="$origin = 'xref'">
            <xsl:text>xref/</xsl:text>
            <!-- Target of an "xref" must always have an author-supplied -->
            <!-- @xml:id value and this is backward-compatible with the  -->
            <!-- situation before @label became prominent.               -->
            <xsl:value-of select="@xml:id"/>
        </xsl:when>
        <xsl:when test="$origin = 'index'">
            <xsl:text>index/</xsl:text>
            <xsl:apply-templates select="." mode="visible-id" />
        </xsl:when>
        <xsl:when test="$origin = 'list-of'">
            <xsl:text>list-of/</xsl:text>
            <xsl:apply-templates select="." mode="visible-id" />
        </xsl:when>
        <xsl:when test="$origin = 'notation'">
            <xsl:text>notation/</xsl:text>
            <xsl:apply-templates select="." mode="visible-id" />
        </xsl:when>
        <!-- put a "location-report" template here to debug a bad knowl file -->
        <!-- (the file, or a reference to it) that lacks a subdirectory      -->
        <xsl:otherwise/>
    </xsl:choose>
    <xsl:text>.html</xsl:text>
</xsl:template>

<!-- ######## -->
<!-- Headings -->
<!-- ######## -->

<!-- Pretty much everything for actually manipluating titles -->
<!-- happens in the -common template. But when structured by -->
<!-- "line" we need to implement an abstract variable with a -->
<!-- separator string.  Since HTML (and EPUB, etc) are       -->
<!-- zoomable and reflowable, we just insert spaces and      -->
<!-- leave actual line-breaking to the laTeX conversion.     -->
<xsl:variable name="title-separator" select="' '"/>

<!-- This template manufactures HTML "headings", the "hN" elements.   -->
<!-- We do not style based on these elements, but a screen-reader     -->
<!-- or offline (no CSS) environment will use these profitably.       -->
<!-- So it is important for the elements to be in a logical           -->
<!-- progression corresponding to "section" and "article" nodes       -->
<!-- of the HTML tree.                                                -->
<!--                                                                  -->
<!-- We set the "heading-level" to "2" when chunking is initiated,    -->
<!-- since we expect the masthead/banner to contain an "h1".          -->
<!-- Whenever a template processes its children, we increment the     -->
<!-- variable as we pass it down, so a template receives the correct  -->
<!-- level (and before it ever gets here, since we have consciously   -->
<!-- chosen *not* to increment here).                                 -->
<!--                                                                  -->
<!-- There is no h7, so we need to just settle for h6, I guess.       -->
<!-- TODO: address h7 when "article" get careful headings             -->
<xsl:template match="*" mode="html-heading">
    <xsl:param name="heading-level"/>

    <!-- Debugging code, preserve temporarily, just for divisions now -->
    <!-- Turn on "CHUNK: and "INTER:" debugging in -common templates  -->
    <!-- <xsl:message> -->
        <!-- <xsl:text>  </xsl:text><xsl:value-of select="$heading-level"/> -->
        <!-- <xsl:text> : </xsl:text><xsl:value-of select="local-name(.)"/><xsl:text> : </xsl:text><xsl:apply-templates select="." mode="long-name"/> -->
    <!-- </xsl:message> -->

    <!-- simple -->
    <xsl:text>h</xsl:text>
    <xsl:choose>
        <xsl:when test="$heading-level &lt; 7">
            <xsl:value-of select="$heading-level"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- TODO: Report excessive heading here, as informational item           -->
            <!-- Perhaps include advice: chunk more, author with shallower divisions, -->
            <!-- use less comprehensive solutions nested at depth                     -->
            <xsl:text>6</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- These are convenience methods for frequently-used headings -->

<!-- heading level for when something needs an hN                       -->
<!-- count structural ancestors, which all have an hN                   -->
<!-- subtract the chunk level for those ancestors not on the page       -->
<!-- subtract 1 more if chunk level is 0, since we quash overall title  -->
<!-- subtract the backmatter and frontmatter                            -->
<!-- add block ancestors that definitely have an hN                     -->
<!-- but subtract 1 for a hint|answer|solution because the statement is -->
<!--   not an HTML heading ancestor                                     -->
<!-- also subtract 1 for a PROOF-LIKE inside a THEOREM-LIKE             -->
<!-- add block ancestors that have an hN if they had a @title           -->
<!-- add 1 for the overall h1                                           -->
<!-- add 1 for the section itself                                       -->
<xsl:template match="*" mode="hN">
    <xsl:variable name="chunk-level-zero-adjustment">
        <xsl:choose>
            <xsl:when test="$chunk-level = 0">1</xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="heading-level">
        <xsl:value-of select="
            count(ancestor::*[&STRUCTURAL-FILTER;])
             - $chunk-level
             - $chunk-level-zero-adjustment
             - count(ancestor::*[self::backmatter or self::frontmatter])
             + count(ancestor::*[&DEFINITION-FILTER; or &THEOREM-FILTER; or &AXIOM-FILTER; or &REMARK-FILTER; or &COMPUTATION-FILTER; or &OPENPROBLEM-FILTER; or &EXAMPLE-FILTER; or &PROJECT-FILTER; or &GOAL-FILTER; or self:: subexercises or self::exercise or self::task or self::exercisegroup])
             - count(self::answer|self::hint|self::solution)
             - count(self::*[&INNER-PROOF-FILTER;])
             + count(ancestor::*[&ASIDE-FILTER; or self::introduction or self::conclusion or self::paragraphs or self::li][title])
             + 2
        "/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$heading-level > 6">
            <xsl:text>h6</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="concat('h',$heading-level)"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- REMARK-LIKE, COMPUTATION-LIKE, DEFINITION-LIKE, SOLUTION-LIKE, objectives (xref-content), outcomes (xref-content), EXAMPLE-LIKE, PROJECT-LIKE, OPENPROBLEM-LIKE, exercise (inline), task (xref-content), fn (xref-content), biblio/note (xref-content)-->
<!-- E.g. Corollary 4.1 (Leibniz, Newton).  The fundamental theorem of calculus. -->
<xsl:template match="*" mode="heading-full">
    <xsl:param name="heading-level"/>
    <xsl:variable name="hN">
        <xsl:choose>
            <xsl:when test="$heading-level > 6">
                <xsl:text>h6</xsl:text>
            </xsl:when>
            <xsl:when test="$heading-level">
                <xsl:value-of select="concat('h',$heading-level)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="hN"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$hN}">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
        </xsl:attribute>
        <span class="type">
            <xsl:apply-templates select="." mode="type-name"/>
        </span>
        <!--  -->
        <xsl:variable name="the-number">
            <xsl:apply-templates select="." mode="number" />
        </xsl:variable>
        <xsl:if test="not($the-number='')">
            <xsl:call-template name="space-styled"/>
            <span class="codenumber">
                <xsl:value-of select="$the-number"/>
            </span>
        </xsl:if>
        <!--  -->
        <xsl:if test="creator and (&THEOREM-FILTER; or &AXIOM-FILTER;)">
            <xsl:call-template name="space-styled"/>
            <span class="creator">
                <xsl:text>(</xsl:text>
                <xsl:apply-templates select="." mode="creator-full"/>
                <xsl:text>)</xsl:text>
            </span>
        </xsl:if>
        <!-- A period now, no matter which of 4 combinations we have above-->
        <xsl:call-template name="period-styled"/>
        <!-- A title carries its own punctuation -->
        <xsl:if test="title">
            <xsl:call-template name="space-styled"/>
            <span class="title">
                <xsl:apply-templates select="." mode="title-full"/>
            </span>
        </xsl:if>
    </xsl:element>
</xsl:template>

<xsl:template match="figure|listing|table|list" mode="figure-caption">
    <xsl:param name="b-original"/>

    <!-- Subnumbered panels of a "sidebyside" get a simpler caption/title -->
    <xsl:variable name="fig-placement">
        <xsl:apply-templates select="." mode="figure-placement"/>
    </xsl:variable>
    <xsl:variable name="b-subnumbered" select="$fig-placement = 'subnumber'"/>
    <figcaption>
        <!-- A normal caption/title, or a subnumbered caption/title -->
        <xsl:choose>
            <xsl:when test="$b-subnumbered">
                <span class="codenumber">
                    <xsl:apply-templates select="." mode="serial-number"/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <span class="type">
                    <xsl:apply-templates select="." mode="type-name"/>
                </span>
                <xsl:call-template name="space-styled"/>
                <span class="codenumber">
                    <xsl:apply-templates select="." mode="number"/>
                    <xsl:call-template name="period-styled"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="space-styled"/>
        <xsl:choose>
            <!-- a caption can have a footnote, hence a -->
            <!-- knowl, hence original or duplicate     -->
            <xsl:when test="self::figure">
                <xsl:apply-templates select="." mode="caption-full">
                    <xsl:with-param name="b-original" select="$b-original"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="self::table or self::list or self::listing">
                <xsl:apply-templates select="." mode="title-full"/>
            </xsl:when>
        </xsl:choose>
        <!-- Insert permalink directly below the title or caption -->
        <xsl:apply-templates select="." mode="permalink"/>
    </figcaption>
</xsl:template>


<!-- hN, no type name, full number, title (if exists)   -->
<!-- divisional exercise, principally for solution list -->
<xsl:template match="*" mode="heading-divisional-exercise">
    <xsl:param name="heading-level"/>
    <xsl:variable name="hN">
        <xsl:choose>
            <xsl:when test="$heading-level > 6">
                <xsl:text>h6</xsl:text>
            </xsl:when>
            <xsl:when test="$heading-level">
                <xsl:value-of select="concat('h',$heading-level)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="hN"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$hN}">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
        </xsl:attribute>
        <span class="codenumber">
            <xsl:apply-templates select="." mode="number" />
            <xsl:call-template name="period-styled"/>
        </span>
        <xsl:if test="title">
            <xsl:call-template name="space-styled"/>
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:if>
    </xsl:element>
</xsl:template>

<!-- hN, no type name, serial number, title (if exists) -->
<!-- divisional exercise, principally when born         -->
<xsl:template match="*" mode="heading-divisional-exercise-serial">
    <xsl:variable name="hN">
        <xsl:apply-templates select="." mode="hN"/>
    </xsl:variable>
    <xsl:element name="{$hN}">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
        </xsl:attribute>
        <span class="codenumber">
            <xsl:apply-templates select="." mode="serial-number" />
            <xsl:call-template name="period-styled"/>
        </span>
        <xsl:if test="title">
            <xsl:call-template name="space-styled"/>
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:if>
    </xsl:element>
</xsl:template>

<!-- hN, type name, serial number, title (if exists) -->
<!-- exercise (divisional, xref-content)      -->
<xsl:template match="*" mode="heading-divisional-exercise-typed">
    <xsl:variable name="hN">
        <xsl:apply-templates select="." mode="hN"/>
    </xsl:variable>
    <xsl:element name="{$hN}">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
        </xsl:attribute>
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
        </span>
        <xsl:call-template name="space-styled"/>
        <span class="codenumber">
            <xsl:apply-templates select="." mode="serial-number" />
            <xsl:call-template name="period-styled"/>
        </span>
        <xsl:if test="title">
            <xsl:call-template name="space-styled"/>
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:if>
    </xsl:element>
</xsl:template>

<!-- hN, no type name, just simple list number, no title -->
<!-- task (when born) -->
<xsl:template match="*" mode="heading-list-number">
    <xsl:variable name="hN">
        <xsl:apply-templates select="." mode="hN"/>
    </xsl:variable>
    <xsl:element name="{$hN}">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
        </xsl:attribute>
        <span class="codenumber">
            <xsl:text>(</xsl:text>
            <xsl:apply-templates select="." mode="list-number" />
            <xsl:text>)</xsl:text>
        </span>
        <xsl:if test="title">
            <xsl:call-template name="space-styled"/>
            <span class="title">
                <xsl:apply-templates select="." mode="title-full"/>
            </span>
        </xsl:if>
    </xsl:element>
</xsl:template>

<!-- hN, type name, no number (even if exists), title (if exists)              -->
<!-- eg, objectives is one-per-subdivison, max, so no need to display at birth -->
<!-- NB: rather specific to "objectives" and "outcomes", careful               -->
<!-- objectives and outcomes (when born) -->
<xsl:template match="*" mode="heading-full-implicit-number">
    <xsl:variable name="hN">
        <xsl:apply-templates select="." mode="hN"/>
    </xsl:variable>
    <xsl:element name="{$hN}">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
        </xsl:attribute>
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
            <xsl:if test="title">
                <xsl:call-template name="dividing-string-styled">
                    <xsl:with-param name="divider" select="':'"/>
                    <xsl:with-param name="name" select="'colon'"/>
                </xsl:call-template>
            </xsl:if>
        </span>
        <!-- codenumber is implicit via placement -->
        <xsl:if test="title">
            <xsl:call-template name="space-styled"/>
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:if>
    </xsl:element>
</xsl:template>

<!-- Not normally titled, but knowl content gives some indication -->
<!-- NB: no punctuation, intended only for xref knowl content     -->
<!-- blockquote, exercisegroup, defined term -->
<xsl:template match="*" mode="heading-type">
    <xsl:variable name="hN">
        <xsl:apply-templates select="." mode="hN"/>
    </xsl:variable>
    <xsl:element name="{$hN}">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
        </xsl:attribute>
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
        </span>
    </xsl:element>
</xsl:template>

<!-- A title or the type, with a period   -->
<!-- PROOF-LIKE. interactive/instructions -->
<xsl:template match="&PROOF-LIKE;|interactive/instructions" mode="heading-no-number">
    <xsl:variable name="hN">
        <xsl:apply-templates select="." mode="hN"/>
    </xsl:variable>
    <xsl:element name="{$hN}">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
        </xsl:attribute>
        <xsl:choose>
            <xsl:when test="title">
                <!-- comes with punctuation -->
                <span class="title">
                    <xsl:apply-templates select="." mode="title-full"/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <!-- supply a period -->
                <span class="type">
                    <xsl:apply-templates select="." mode="type-name" />
                    <xsl:call-template name="period-styled"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="@ref">
            <xsl:text>&#xa0;(</xsl:text>
            <xsl:apply-templates select="." mode="proof-xref-theorem"/>
            <xsl:text>)</xsl:text>
        </xsl:if>
    </xsl:element>
</xsl:template>

<!-- Title only -->
<!-- exercisegroup, dl/li             -->
<!-- PROOF-LIKE, when titled          -->
<!-- Subsidiary to paragraphs,        -->
<!-- and divisions of "exercises"     -->
<!-- No title, then nothing happens   -->
<xsl:template match="*" mode="heading-title">
    <xsl:param name="heading-level"/>
    <xsl:variable name="has-default-title">
        <xsl:apply-templates select="." mode="has-default-title"/>
    </xsl:variable>
    <xsl:if test="title/*|title/text() or $has-default-title = 'true'">
        <xsl:variable name="hN">
            <xsl:choose>
                <xsl:when test="$heading-level > 6">
                    <xsl:text>h6</xsl:text>
                </xsl:when>
                <xsl:when test="$heading-level">
                    <xsl:value-of select="concat('h',$heading-level)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="hN"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$hN}">
            <xsl:attribute name="class">
                <xsl:text>heading</xsl:text>
            </xsl:attribute>
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:element>
    </xsl:if>
</xsl:template>

<!-- Title only, paragraphs         -->
<!-- No title, then nothing happens -->
<!-- TODO: titles will be mandatory sometime -->
<xsl:template match="*" mode="heading-title-paragraphs">
    <xsl:if test="title/*|title/text()">
        <xsl:variable name="hN">
            <xsl:apply-templates select="." mode="hN"/>
        </xsl:variable>
        <xsl:element name="{$hN}">
            <xsl:attribute name="class">
                <xsl:text>heading</xsl:text>
            </xsl:attribute>
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:element>
    </xsl:if>
</xsl:template>

<!-- A type, with maybe a serial number to disambiguate -->
<!-- No hN, optional title                              -->
<!-- SOLUTION-LIKE (xref-text), biblio/note (xref-text),-->
<!-- interactive/instructions (xref-text)               -->
<xsl:template match="*" mode="heading-simple">
    <!-- the name of the object, its "type" -->
    <!-- The <xsl:text> </xsl:text> to produce a space is -->
    <!-- essential for EPUB. Calling space-styled creates -->
    <!-- a line break in EPUB/Kindle.                     -->
    <span class="type">
        <xsl:apply-templates select="." mode="type-name" />
    </span>
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="non-singleton-number" />
    </xsl:variable>
    <!-- An empty value means element is a singleton -->
    <!-- else the serial number comes through        -->
    <xsl:if test="not($the-number = '')">
        <xsl:call-template name="space-styled"/>
        <span class="codenumber">
            <xsl:apply-templates select="." mode="serial-number" />
        </span>
    </xsl:if>
    <!-- Always end, e.g. "Hint" or "Hint 4", with a period -->
    <xsl:call-template name="period-styled"/>
    <xsl:if test="title">
        <xsl:call-template name="space-styled"/>
        <span class="title">
            <xsl:apply-templates select="." mode="title-full" />
        </span>
    </xsl:if>
</xsl:template>

<!-- The next template, "heading-non-singleton-number", is basically    -->
<!-- "heading-no-number" with an (optional) non-singleton number,       -->
<!-- much like in "heading-simple".  If/Once PROOF-LIKE gets a          -->
<!-- non-singleton number then maybe "heading-no-number" can come here. -->

<!-- A title or the type, with a period, and an optional number -->
<!-- &SOLUTION-LIKE;, when unknowled, is the only known case    -->
<xsl:template match="*" mode="heading-non-singleton-number">
    <xsl:variable name="hN">
        <xsl:apply-templates select="." mode="hN"/>
    </xsl:variable>
    <xsl:element name="{$hN}">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
        </xsl:attribute>
        <xsl:choose>
            <xsl:when test="title">
                <!-- comes with punctuation -->
                <span class="title">
                    <xsl:apply-templates select="." mode="title-full"/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <span class="type">
                    <xsl:apply-templates select="." mode="type-name" />
                </span>
                <xsl:variable name="the-number">
                    <xsl:apply-templates select="." mode="non-singleton-number" />
                </xsl:variable>
                <!-- An empty value means element is a singleton -->
                <!-- else the serial number comes through        -->
                <xsl:if test="not($the-number = '')">
                    <xsl:call-template name="space-styled"/>
                    <span class="codenumber">
                        <xsl:apply-templates select="." mode="serial-number" />
                    </span>
                </xsl:if>
                <!-- supply a period -->
                <xsl:call-template name="period-styled"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:element>
</xsl:template>

<!-- A case in a PROOF-LIKE, eg "(=>) Necessity." -->

<!-- First we need to set up arrow symbols for this output target. -->
<xsl:template name="double-right-arrow-symbol">
    <!-- 'RIGHTWARDS DOUBLE ARROW' (U+21D2) -->
    <xsl:comment>Style arrows in CSS?</xsl:comment>
    <xsl:text>&#x21d2;</xsl:text>
</xsl:template>
<xsl:template name="double-left-arrow-symbol">
    <!-- 'LEFTWARDS DOUBLE ARROW' (U+21D0) -->
    <xsl:comment>Style arrows in CSS?</xsl:comment>
    <xsl:text>&#x21d0;</xsl:text>
</xsl:template>
<!-- Also need a "delimiter space" for when "direction" is "cycle". -->
<xsl:template name="case-cycle-delimiter-space">
    <!-- 'HAIR SPACE'  (U+200A)                -->
    <!-- 'WORD JOINER' (U+2060)                -->
    <!-- Prevents line break after whitespace. -->
    <!-- May not work in Firefox.              -->
    <xsl:text>&#x200a;&#x2060;</xsl:text>
</xsl:template>

<!-- case -->
<xsl:template match="*" mode="heading-case">
    <xsl:variable name="hN">
        <xsl:apply-templates select="." mode="hN"/>
    </xsl:variable>
    <xsl:element name="{$hN}">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
        </xsl:attribute>
        <!-- optional direction, given by attribute -->
        <xsl:apply-templates select="." mode="case-direction" />
        <!-- If there is a title, the following will produce it. If -->
        <!-- no title, and we don't have a direction already, the   -->
        <!-- following will produce a default title, eg "Case."     -->
        <xsl:if test="boolean(title) or not(@direction)">
            <xsl:apply-templates select="." mode="title-full" />
        </xsl:if>
    </xsl:element>
</xsl:template>

<!-- Heading Utilities -->

<!-- These named templates create a dividing character  -->
<!-- with enough HTML markup to allow for hiding        -->
<!-- them if some other part of a heading is hidden.    -->
<!-- space/period versions are convience wrappers for   -->
<!-- commonly used characters.                          -->

<xsl:template name="space-styled">
    <xsl:call-template name="dividing-string-styled"/>
</xsl:template>

<xsl:template name="period-styled">
    <xsl:call-template name="dividing-string-styled">
        <xsl:with-param name="divider" select="'.'"/>
        <xsl:with-param name="name" select="'period'"/>
    </xsl:call-template>
</xsl:template>

<xsl:template name="dividing-string-styled">
    <xsl:param name="divider" select="' '"/>
    <xsl:param name="name" select="'space'"/>
    <span class="{$name} heading-divison-mark heading-divison-mark__{$name}">
        <xsl:value-of select="$divider"/>
    </span>
</xsl:template>


<!-- ######################## -->
<!-- Block Production, Knowls -->
<!-- ######################## -->

<!-- 2023-09-23: content "born hidden" may be due to an election by a publisher ("theorem") or automatic as part of this conversion ("hint").  We once thought of these as "embedded" knowls since their content lived on the page, and in contrast to cross-reference knowls ("xref") whose content lives in an (external) file.  With recent changes we have migrated even further away from "embed" to "hidden" in nomenclature for these.  The comments below may not always reflect this. -->

<!-- Generically, a "block" is a child of a "division."  See the schema for more precision.  Blocks also have significant components.  An "example" is a block, and its "solution" is a significant component.  A "p" might be a block, but it could also be a significant component of an "example." -->

<!-- Some blocks and components can be realized in a hidden fashion, as knowls whose content is embedded within the page.  This may be automatic ("hint" is always born hidden), elective ("theorem" is a good example), or banned (a "blockquote" is never hidden). -->

<!-- All blocks, and many of their significant components, are available as targets of cross-references, implemented as knowls, but now the content resides in external files.  These files contain duplicates of blocks and their components (rather than originals), so need to be free of the unique identifiers that are used in the original versions. -->

<!-- This suggests three modes for the initial production of a block or component, though some blocks may only be produced in two of the three modes: visible and original, hidden and original, a cross-reference knowl. -->
<!-- (a) Visible and original (on a main page) -->
<!-- (b) Hidden and original (embedded knowl on a page) -->
<!-- (c) Visible and duplicate (in, or as, a cross-reference knowl) -->

<!-- The generic (not modal) template matches any element that is a block or a significant component of some other element that is a block or a component. -->

<!-- Every such element is only output in one of two forms, and as few times as possible.  One form is the "original" and includes full identifying information, such as an HTML id attribute or a LaTeX label for rows of display mathematics.  The other form is a "duplicate", as an external file, for use by the knowl code to open and display.  As a duplicate of the orginal, it should be free of all identifying information and should recycle other duplicates as much as possible. -->

<!-- An element arrives here in one of three situations, two as originals and one as a duplicate.  We describe those situations and what should happen. -->

<!-- Original, born visible.  The obvious situation, we render the element as part of the page, adding identifying information.  The template sets the "b-original" flag to true by default, for this reason.  Children of the element are incorporated (through the modal body templates) as originals (visible and/or hidden) by passing along the "b-original" flag. -->

<!-- Original, born hidden.  The element knows if it should be hidden on the page in an embedded knowl via the modal "is-hidden" template.  So a link is written on the page, and the main content is written onto the page as a hidden, embedded knowl.  The "b-original" flag (set to true) is passed through to templates for the children. -->

<!-- Duplicates.  Duplicated versions, sans identification, are created by an extra, specialized, traversal of the entire document tree with the "make-efficient-knowl" templates  When an element is first considered as a cross-reference target the infrastructure for an external file is constructed and the modal "body" template of the element is called with the "b-original" flag set to false.  The content of the knowl should have an overall heading, explaining what it is, since it is a target of the cross-reference.  Now the body template will pass along the "b-original" flag set to false, indicating the production mode should be duplication.  -->

<!-- Child elements born visible will be written into knowl files without identification.  -->

<!-- The upshot is that the main pages have visible content and hidden, embedded content (knowls) with full identification as original canonical versions.  Cross-references open external file knowls.  None of the knowl files contain any identification, so these identifiers remain unique in their appearances as part of the main pages. -->

<!-- This process is controlled by the boolean "b-original" parameter, which needs to be laboriously passed down and through templates, including containers like "sidebyside."  The XSLT 2.0 tunnel parameter would be a huge advantage here.  The parameter "block-type" can take on the values: 'visible', 'hidden', 'xref'.  The three situations above can be identified with these parameters.  The block-type parameter is also used to aid in placement of identification.  For example, an element born visible will have an HTML id on its outermost element, such as an "article".  But as a born-hidden knowl, we put the id onto the visible link text instead, even if the same outermost element is employed for the hidden content.  Also, the block-type parameter is tunneled down to the Sage cells so they can be constructed properly when inside of knowls. -->

<!-- The relevant templates controlling production of a block, and their use, are: -->

<!-- (1) "is-hidden":  mandatory, value is 'true' or 'false' (could move to a boolean), controls visible or hidden property, so usd in a variety of situations to control flow.  Often fixed, but also responds to options. (As boolean: do conditionals in global text variable, then check value in "select" of new global boolean variable.) -->

<!-- (2) "body-element", "body-css-class": useful for general production, but sometimes its employment leads to requiring exceptional templates (eg display math).  The outermost HTML element of a block.  Sometimes it gets an ID, sometimes not, which is its main purpose.  Employed in "body" templates (see below).  The "body-element" should always be a block element, since it will be the outer-level element for knowl content, which will (always) have blocks as content. -->

<!-- (3) "heading-birth": produces HTML immediately interior to the "body-element", for visible blocks, in both the original and duplication processes.  Similarly, it is the link-text of a knowl for a block that is hidden (again in original or duplication modes).  Employed in "body" templates. -->

<!-- (4) "heading-xref-knowl": when a knowl is a target of a cross-reference, sometimes a better heading is necessary to help identify it.  For example, a cross-refernce to a list item can be improved by providing the number of the item in a heading. -->

<!-- (5) "body": main template to produce the HTML "body" portion of a knowl, or the content displayed on a page.  Reacts to four modes: 'visible' (original or duplicate), 'hidden', or 'xref'. -->

<!-- (6) TODO: "wrapped-content" called by "body" to separate code. -->

<xsl:template match="&REMARK-LIKE;|&COMPUTATION-LIKE;|&DEFINITION-LIKE;|&ASIDE-LIKE;|poem|&FIGURE-LIKE;|assemblage|blockquote|paragraphs|&GOAL-LIKE;|&OPENPROBLEM-LIKE;|&EXAMPLE-LIKE;|subexercises|exercisegroup|exercise|&PROJECT-LIKE;|task|&SOLUTION-LIKE;|&DISCUSSION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&PROOF-LIKE;|case|contributor|biblio|biblio/note|interactive/instructions|gi|p|li|me|men|md[not(mrow)]|mdn[not(mrow)]|md[mrow]|mdn[mrow]|fragment">
    <xsl:param name="b-original" select="true()" />
    <xsl:variable name="hidden">
        <xsl:apply-templates select="." mode="is-hidden" />
    </xsl:variable>
    <xsl:choose>
        <!-- born-hidden case -->
        <xsl:when test="$hidden = 'true'">
            <xsl:apply-templates select="." mode="born-hidden">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- born-visible case -->
        <xsl:otherwise>
            <!-- pass-thru of b-original mandatory -->
            <xsl:apply-templates select="." mode="born-visible">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="born-visible">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="." mode="body">
        <xsl:with-param name="block-type" select="'visible'" />
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="*" mode="born-hidden">
    <xsl:param name="b-original" select="true()" />

    <details>
        <!-- put an HTML id as a target of cross-references, etc, -->
        <!-- but only when this is original content.  In other    -->
        <!-- words, not when a consituent of an xref knowl        -->
        <xsl:if test="$b-original">
            <xsl:apply-templates select="." mode="html-id-attribute"/>
        </xsl:if>
        <!-- put relevant class names on "details" to help with styling -->
        <xsl:attribute name="class">
            <xsl:apply-templates select="." mode="body-css-class"/>
            <xsl:text> born-hidden-knowl</xsl:text>
        </xsl:attribute>
        <!-- the clickable that is visible on the page -->
        <summary class="knowl__link">
           <xsl:apply-templates select="." mode="heading-birth" />
        </summary>
        <!-- the content of the knowl, to be revealed later        -->
        <!-- NB: the Javascript controlling the animation of the   -->
        <!-- open/close of a knowl, presumes it begins with an     -->
        <!-- element enclosing the content.  This is guaranteed by -->
        <!-- the "body" template via the "body-element" template.  -->
        <xsl:apply-templates select="." mode="body">
            <xsl:with-param name="block-type" select="'hidden'" />
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </details>
</xsl:template>

<!-- ######### -->
<!-- Footnotes -->
<!-- ######### -->

<!-- Currently implemented as a details html element with no guardrails   -->
<!-- on nested content. Other footnotes, block content, etc... will all   -->
<!-- be rendered, but perhaps not well. Caveat emptor.                    -->
<xsl:template match="fn">
    <details class="ptx-footnote" aria-live="polite">
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <!-- A superscript number, as the clickable content -->
        <summary class="ptx-footnote__number">
            <xsl:attribute name="title">
                <xsl:apply-templates select="." mode="tooltip-text" />
            </xsl:attribute>
            <xsl:apply-templates select="." mode="heading-birth"/>
        </summary>
        <!-- the content of the knowl, to be revealed later        -->
        <!-- NB: the Javascript controlling the animation of the   -->
        <!-- open/close of a knowl, presumes it begins with an     -->
        <!-- element enclosing the content.  This is guaranteed by -->
        <!-- the "body" template via the "body-element" template.  -->
        <xsl:apply-templates select="." mode="body"/>
    </details>
    <!-- xref-knowl content is manufactured elsewhere in a brute-force   -->
    <!-- fashion.  This would be a better place to ensure that every     -->
    <!--  "fn" had its content produced in the right way no matter what. -->
</xsl:template>

<!-- ##################### -->
<!-- Block Implementations -->
<!-- ##################### -->

<!-- We devise the more straightforward blocks first, -->
<!-- saving the exceptions for subsequent exposition  -->

<!-- REMARK-LIKE -->
<!-- A simple block with full titles and generic contents -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&REMARK-LIKE;" mode="is-hidden">
    <xsl:value-of select="$knowl-remark = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&REMARK-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&REMARK-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> remark-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&REMARK-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&REMARK-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement     -->
<!-- with Sage, so pass block type               -->
<!-- Simply process contents, could restict here -->
<xsl:template match="&REMARK-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:apply-templates select="*">
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>


<!-- COMPUTATION-LIKE -->
<!-- A simple block with full titles, but more substantial contents -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&COMPUTATION-LIKE;" mode="is-hidden">
    <xsl:value-of select="$knowl-remark = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&COMPUTATION-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&COMPUTATION-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> computation-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&COMPUTATION-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&COMPUTATION-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement     -->
<!-- with Sage, so pass block type               -->
<!-- Simply process contents, could restict here -->
<xsl:template match="&COMPUTATION-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:apply-templates select="*">
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>


<!-- OPENPROBLEM-LIKE -->
<!-- A simple block with full titles, but more substantial contents -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&OPENPROBLEM-LIKE;" mode="is-hidden">
    <xsl:value-of select="false()"/>
    <!-- <xsl:value-of select="$knowl-remark = 'yes'" /> -->
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&OPENPROBLEM-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&OPENPROBLEM-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> openproblem-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&OPENPROBLEM-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&OPENPROBLEM-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement     -->
<!-- with Sage, so pass block type               -->
<!-- Simply process contents, could restict here -->

<!-- NB: we explicitly ignore "prelude" and      -->
<!-- "postlude" by being very careful about what -->
<!-- we process.  A more general template will   -->
<!-- pick them up *only* when it is original     -->
<!-- content, and place outside the block.       -->

<xsl:template match="&OPENPROBLEM-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:choose>
        <!-- structured by "task" so let templates for tasks work -->
        <!-- down to terminal task with SOLUTION-LIKE appendages  -->
        <xsl:when test="task">
            <xsl:apply-templates select="introduction|task|conclusion">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- structured with "statement" and DISCUSSION-LIKE  -->
        <!-- (We don't entertain bare content for a statement -->
        <xsl:otherwise>
            <xsl:apply-templates select="statement|&DISCUSSION-LIKE;">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- DEFINITION-LIKE -->
<!-- A simple block with full titles and generic contents -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&DEFINITION-LIKE;" mode="is-hidden">
    <xsl:value-of select="$knowl-definition = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&DEFINITION-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&DEFINITION-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> definition-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&DEFINITION-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&DEFINITION-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement     -->
<!-- with Sage, so pass block type               -->
<!-- Simply process contents, could restict here -->
<xsl:template match="&DEFINITION-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:apply-templates select="*">
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>


<!-- ASIDE-LIKE -->
<!-- A simple block with a title (no number) and generic contents -->

<!-- Rendered as a born hidden knowl -->
<xsl:template match="&ASIDE-LIKE;" mode="is-hidden">
    <xsl:text>true</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&ASIDE-LIKE;" mode="body-element">
    <xsl:text>aside</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&ASIDE-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> aside-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&ASIDE-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full-implicit-number" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&ASIDE-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full-implicit-number" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Potentially knowled, may have statement      -->
<!-- with Sage, so pass block type                -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="&ASIDE-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <!-- Coordinate with schema, since we enforce it here -->
    <xsl:apply-templates select="p|blockquote|pre|image|video|program|console|tabular">
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>


<!-- Poem -->
<!-- Titled, not numbered, but with an author's name. -->
<!-- Knowled as a cross-reference target, but never born  -->
<!-- hidden (for now particular reason).  A complicated  -->
<!-- implementation, which should rely more on CSS. -->

<!-- Never born-hidden, other devices partially hide -->
<xsl:template match="poem" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="poem" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="poem" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="poem" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="poem" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="poem" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="stanza" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
    <!-- author comes early in schema, but is rendered below -->
    <xsl:apply-templates select="author" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<!-- ################### -->
<!-- Structured by Lines -->
<!-- ################### -->

<!-- The HTML-specific line separator for use by   -->
<!-- the abstract template for a "line" elent used -->
<!-- to (optionally) structure certain elements.   -->

<xsl:template name="line-separator">
    <br/>
</xsl:template>

<!-- ###### -->
<!-- Poetry -->
<!-- ###### -->

<!-- TODO: Address GitHub issues regarding poetry output:   -->
<!-- https://github.com/BooksHTML/mathbook-assets/issues/65 -->

<xsl:template match="poem/author">
    <div>
        <xsl:attribute name="class">
            <xsl:text>author</xsl:text>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="poem-halign"/>
        </xsl:attribute>
        <xsl:apply-templates/>
    </div>
</xsl:template>

<xsl:template match="stanza">
    <div class="stanza">
        <xsl:apply-templates select="." mode="heading-title"/>
        <xsl:apply-templates select="line"/>
    </div>
</xsl:template>

<xsl:template match="stanza/line">
    <xsl:variable name="alignment">
        <xsl:apply-templates select="." mode="poem-halign"/>
    </xsl:variable>
    <xsl:variable name="indentation">
        <xsl:apply-templates select="." mode="poem-indent"/>
    </xsl:variable>
    <div>
        <xsl:attribute name="class">
            <xsl:text>line</xsl:text>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="poem-halign"/>
        </xsl:attribute>
        <!-- Left Alignment: Indent from Left -->
        <xsl:if test="$alignment='left'">
            <xsl:call-template name="poem-line-indenting">
                <xsl:with-param name="count" select="$indentation"/>
            </xsl:call-template>
        </xsl:if>
        <!-- Center Alignment: Ignore Indentation -->
        <xsl:apply-templates/>
        <!-- Right Alignment: Indent from Right -->
        <xsl:if test="$alignment='right'">
            <xsl:call-template name="poem-line-indenting">
                <xsl:with-param name="count" select="$indentation"/>
            </xsl:call-template>
        </xsl:if>
    </div>
</xsl:template>

<xsl:template name="poem-line-indenting">
    <xsl:param name="count"/>
    <xsl:choose>
        <xsl:when test="(0 >= $count)"/>
        <xsl:otherwise>
            <span class="tab"/>
            <xsl:call-template name="poem-line-indenting">
                <xsl:with-param name="count" select="$count - 1"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- FIGURE-LIKE -->
<!-- Captioned, titled (heading) -->

<!-- Born-hidden behavior is configurable -->
<!-- On a per-element basis               -->
<xsl:template match="figure" mode="is-hidden">
    <xsl:value-of select="$knowl-figure = 'yes'" />
</xsl:template>

<xsl:template match="table" mode="is-hidden">
    <xsl:value-of select="$knowl-table = 'yes'" />
</xsl:template>

<xsl:template match="listing" mode="is-hidden">
    <xsl:value-of select="$knowl-listing = 'yes'" />
</xsl:template>

<xsl:template match="list" mode="is-hidden">
    <xsl:value-of select="$knowl-list = 'yes'" />
</xsl:template>

<!-- The optionally born-hidden items can be panels of -->
<!-- a sidebyside, where we should not be hiding them. -->
<!-- A figure wrapping the sidebyside could be knowled -->
<!-- if they need to be hidden.                        -->
<xsl:template match="sidebyside/figure|sidebyside/table|sidebyside/listing|sidebyside/list" mode="is-hidden">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="&FIGURE-LIKE;" mode="body-element">
    <xsl:text>figure</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="figure|listing" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> figure-like</xsl:text>
</xsl:template>
<!-- a table of data will use this class when -->
<!-- the title is placed above the tabular    -->
<xsl:template match="table|list" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> table-like</xsl:text>
</xsl:template>

<!-- TODO - sort out title/caption -->
<!-- Use title for xref-link text  -->

<!-- When born use this heading -->
<!-- no heading, since captioned -->
<xsl:template match="&FIGURE-LIKE;" mode="heading-birth" />

<!-- Heading for interior of xref-knowl content -->
<!-- no heading, since captioned -->
<xsl:template match="&FIGURE-LIKE;" mode="heading-xref-knowl" />

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Handle "caption" exceptionally               -->
<xsl:template match="&FIGURE-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />

    <!-- Subnumbered caption/title go below, to help with alignment -->
    <xsl:variable name="fig-placement">
        <xsl:apply-templates select="." mode="figure-placement"/>
    </xsl:variable>
    <xsl:variable name="b-place-title-below" select="($fig-placement = 'subnumber') or ($fig-placement = 'panel')"/>
    <xsl:choose>
        <!-- caption at the bottom, always -->
        <xsl:when test="self::figure">
            <xsl:apply-templates select="*">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
            <xsl:apply-templates select="." mode="figure-caption">
                <xsl:with-param name="b-original" select="$b-original"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- caption at the top as per CMoS if not subnumbered -->
        <xsl:when test="self::listing">
            <xsl:if test="not($b-place-title-below)">
                <xsl:apply-templates select="." mode="figure-caption">
                    <xsl:with-param name="b-original" select="$b-original"/>
                </xsl:apply-templates>
            </xsl:if>
            <div class="listing__contents">
                <xsl:apply-templates select="program|console">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </div>
            <xsl:if test="$b-place-title-below">
                <xsl:apply-templates select="." mode="figure-caption">
                    <xsl:with-param name="b-original" select="$b-original"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:when>
        <!-- table only contains a tabular; if not subnumbered  -->
        <!-- then title is displayed before data/tabular        -->
        <xsl:when test="self::table">
            <xsl:if test="not($b-place-title-below)">
                <xsl:apply-templates select="." mode="figure-caption">
                    <xsl:with-param name="b-original" select="$b-original"/>
                </xsl:apply-templates>
            </xsl:if>
            <xsl:apply-templates select="tabular">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
            <xsl:if test="$b-place-title-below">
                <xsl:apply-templates select="." mode="figure-caption">
                    <xsl:with-param name="b-original" select="$b-original"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:when>
        <!-- "title" at the top, subnumber at the bottom -->
        <xsl:when test="self::list">
            <xsl:if test="not($b-place-title-below)">
                <xsl:apply-templates select="." mode="figure-caption">
                    <xsl:with-param name="b-original" select="$b-original"/>
                </xsl:apply-templates>
            </xsl:if>
            <div class="named-list-content">
                <xsl:apply-templates select="introduction|ol|ul|dl|conclusion">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </div>
            <xsl:if test="$b-place-title-below">
                <xsl:apply-templates select="." mode="figure-caption">
                    <xsl:with-param name="b-original" select="$b-original"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- Assemblage -->
<!-- A simple block with an optional title and limited contents -->

<!-- Never born-hidden, simply by design -->
<xsl:template match="assemblage" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="assemblage" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="assemblage" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> assemblage-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="assemblage" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="assemblage" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Primary content of generic "body" template    -->
<!-- Pass along b-original flag                    -->
<!-- Simply process contents, restrictions match   -->
<!-- schema, except schema says no captioned items -->
<!-- in the side-by-side                           -->
<xsl:template match="assemblage" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <!-- Coordinate with schema, since we enforce it here -->
    <xsl:apply-templates select="p|blockquote|pre|image|video|program|console|tabular|sidebyside|sbsgroup" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Block Quote -->
<!-- A very simple block with just an enclosing div -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="blockquote" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element     -->
<!-- Natural HTML element, usually -->
<xsl:template match="blockquote" mode="body-element">
    <xsl:text>blockquote</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="blockquote" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- When born use this heading         -->
<!-- Never hidden, never gets a heading -->
<xsl:template match="blockquote" mode="heading-birth" />

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="blockquote" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-type" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="blockquote" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Paragraphs -->
<!-- Technically a division, but small enough to xref knowl -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="paragraphs" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="paragraphs" mode="body-element">
    <xsl:text>section</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="paragraphs" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="paragraphs" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title-paragraphs" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="paragraphs" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-title-paragraphs" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="paragraphs" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- GOAL-LIKE -->
<!-- Special, and restricted, blocks -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="objectives" mode="is-hidden">
    <xsl:value-of select="$knowl-objectives = 'yes'" />
</xsl:template>
<xsl:template match="outcomes" mode="is-hidden">
    <xsl:value-of select="$knowl-outcomes = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&GOAL-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&GOAL-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> goal-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&GOAL-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full-implicit-number" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&GOAL-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template        -->
<!-- Pass along b-original flag                        -->
<!-- Simply process contents, with partial restriction -->
<xsl:template match="&GOAL-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="introduction|ol|ul|dl|conclusion" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- The next few implementations have hints, answers, -->
<!-- or solutions hanging off the ends.  Examples may  -->
<!-- elect to have these.  Exercises may have them and -->
<!-- they are more configurable.  Projects may have    -->
<!-- them prima facie, or associated with tasks.  In   -->
<!-- all cases the hints, answers, and solutions are   -->
<!-- presented as knowls.                              -->

<!-- EXAMPLE-LIKE -->
<!-- A simple block, but with possible appendages -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&EXAMPLE-LIKE;" mode="is-hidden">
    <xsl:value-of select="$knowl-example = 'yes'" />
    <!-- Preserving a way to not knowl anything in a worksheet -->
    <!--
    <xsl:choose>
        <xsl:when test="ancestor::worksheet">
            <xsl:value-of select="false()"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$knowl-example = 'yes'" />
        </xsl:otherwise>
    </xsl:choose>
    -->
 </xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&EXAMPLE-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&EXAMPLE-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> example-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&EXAMPLE-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&EXAMPLE-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement     -->
<!-- with Sage, so pass block type               -->
<!-- Process according to structure              -->
<xsl:template match="&EXAMPLE-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:choose>
        <!-- structured by "task" so let templates for tasks work -->
        <!-- down to terminal task with SOLUTION-LIKE appendages  -->
        <xsl:when test="task">
            <xsl:apply-templates select="introduction|task|conclusion">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- structured with "statement" and SOLUTION-LIKE, -->
        <!-- or just bare content for a statement           -->
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="exercise-components">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
                <xsl:with-param name="b-has-statement" select="true()"/>
                <xsl:with-param name="b-has-hint"      select="true()"/>
                <xsl:with-param name="b-has-answer"    select="true()"/>
                <xsl:with-param name="b-has-solution"  select="true()"/>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Subexercises -->
<!-- A pseudo-division, implemented more like an "exercisegroup" -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="subexercises" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="subexercises" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="subexercises" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- When born use this heading         -->
<!-- Never hidden, never gets a heading -->
<xsl:template match="subexercises" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title"/>
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<!-- Not knowlizable, more like a division      -->
<xsl:template match="subexercises" mode="heading-xref-knowl"/>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<!-- Mirror changes here into "solutions" below   -->
<xsl:template match="subexercises" mode="wrapped-content">
    <xsl:param name="b-original" select="true()"/>
    <xsl:apply-templates select="introduction">
        <xsl:with-param name="b-original" select="$b-original"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="exercise|exercisegroup">
        <xsl:with-param name="b-original" select="$b-original"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="conclusion">
        <xsl:with-param name="b-original" select="$b-original"/>
    </xsl:apply-templates>
</xsl:template>

<!-- For solutions divisions, we mimic and reuse some of the above -->
<xsl:template match="subexercises" mode="solutions">
    <xsl:param name="admit"/>
    <xsl:param name="heading-level"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <!-- we check for content, subject to selection of switches          -->
    <!-- if there is no content, then we will not output anything at all -->
     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
        <article class="subexercises">
            <xsl:apply-templates select="." mode="heading-title">
                <xsl:with-param name="heading-level" select="$heading-level"/>
            </xsl:apply-templates>
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="introduction">
                    <xsl:with-param name="b-original" select="false()" />
                </xsl:apply-templates>
            </xsl:if>
            <xsl:apply-templates select="exercise|exercisegroup" mode="solutions">
                <xsl:with-param name="admit"           select="$admit"/>
                <xsl:with-param name="heading-level"   select="$heading-level + 1"/>
                <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
            </xsl:apply-templates>
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="conclusion">
                    <xsl:with-param name="b-original" select="false()" />
                </xsl:apply-templates>
            </xsl:if>
        </article>
    </xsl:if>
</xsl:template>

<!-- Exercise Group -->
<!-- A very simple block with just an enclosing div -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="exercisegroup" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="exercisegroup" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="exercisegroup" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- When born use this heading         -->
<!-- Never hidden, never gets a heading -->
<xsl:template match="exercisegroup" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="exercisegroup" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<!-- Mirror changes here into "solutions" below   -->
<xsl:template match="exercisegroup" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="introduction">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
    <div>
        <xsl:attribute name="class">
            <xsl:text>exercisegroup-exercises</xsl:text>
            <xsl:variable name="cols-class-name">
                <!-- HTML-specific, but in pretext-common.xsl -->
                <xsl:apply-templates select="." mode="number-cols-CSS-class"/>
            </xsl:variable>
            <xsl:if test="not($cols-class-name = '')">
                <xsl:text> </xsl:text>
                <xsl:value-of select="$cols-class-name"/>
            </xsl:if>
        </xsl:attribute>
        <xsl:apply-templates select="exercise">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </div>
    <xsl:apply-templates select="conclusion">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<!-- For solutions divisions, we mimic and reuse some of the above -->
<xsl:template match="exercisegroup" mode="solutions">
    <xsl:param name="admit"/>
    <xsl:param name="heading-level"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <!-- we check for content, subject to selection of switches          -->
    <!-- if there is no content, then we will not output anything at all -->
     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
        <div class="exercisegroup">
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="introduction">
                    <xsl:with-param name="b-original" select="false()" />
                </xsl:apply-templates>
            </xsl:if>
            <div>
                <xsl:attribute name="class">
                    <xsl:text>exercisegroup-exercises</xsl:text>
                    <xsl:variable name="cols-class-name">
                        <!-- HTML-specific, but in pretext-common.xsl -->
                        <xsl:apply-templates select="." mode="number-cols-CSS-class"/>
                    </xsl:variable>
                    <xsl:if test="not($cols-class-name = '')">
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$cols-class-name"/>
                    </xsl:if>
                </xsl:attribute>
                <xsl:apply-templates select="exercise" mode="solutions">
                    <xsl:with-param name="admit"           select="$admit"/>
                    <xsl:with-param name="heading-level"   select="$heading-level"/>
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                    <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                </xsl:apply-templates>
            </div>
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="conclusion">
                    <xsl:with-param name="b-original" select="false()" />
                </xsl:apply-templates>
            </xsl:if>
        </div>
    </xsl:if>
</xsl:template>

<!-- Exercise -->
<!-- Inline and divisional, with appendages -->

<!-- Born-hidden behavior is configurable   -->
<!-- Note match first on inline first, override if divisional -->
<xsl:template match="exercise" mode="is-hidden">
    <xsl:value-of select="$knowl-exercise-inline = 'yes'"/>
</xsl:template>
<xsl:template match="exercises//exercise" mode="is-hidden">
    <xsl:value-of select="$knowl-exercise-divisional = 'yes'"/>
</xsl:template>
<xsl:template match="worksheet//exercise" mode="is-hidden">
    <xsl:value-of select="$knowl-exercise-worksheet = 'yes'"/>
</xsl:template>
<xsl:template match="reading-questions//exercise" mode="is-hidden">
    <xsl:value-of select="$knowl-exercise-readingquestion = 'yes'"/>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="exercise" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="exercise" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> exercise-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<!-- Note match first on inline, then divisional -->
<xsl:template match="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" mode="heading-birth">
    <xsl:param name="heading-level"/>
    <xsl:apply-templates select="." mode="heading-full">
        <xsl:with-param name="heading-level" select="$heading-level"/>
    </xsl:apply-templates>
</xsl:template>
<xsl:template match="exercises//exercise|worksheet//exercise|reading-questions//exercise" mode="heading-birth">
    <xsl:param name="heading-level"/>
    <xsl:apply-templates select="." mode="heading-divisional-exercise-serial">
        <xsl:with-param name="heading-level" select="$heading-level"/>
    </xsl:apply-templates>
</xsl:template>

<!-- Heading for interior of xref-knowl content  -->
<!-- Note match first on inline, then divisional -->
<xsl:template match="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>
<xsl:template match="exercises//exercise|worksheet//exercise|reading-questions//exercise" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-divisional-exercise-typed" />
</xsl:template>

<!-- An "exercise" or PROJECT-LIKE authored with a "webwork" element -->
<!-- is always interactive, but for straight HTML output, it has one -->
<!-- look and for hosting on Runestone it has a slightly different   -->
<!-- look.  This template isolates this distinction for the core, or -->
<!-- interior, of such an exercise.                                  -->
<xsl:template match="exercise|&PROJECT-LIKE;" mode="webwork-core">
    <xsl:param name="b-original"/>

    <xsl:choose>
        <xsl:when test="$b-host-runestone">
            <div class="ptx-runestone-container">
                <div class="runestone" data-component="webwork">
                    <!-- Note that this id gets a suffix on div.exercise-wrapper, -->
                    <!-- so Runestone can coordinate the outer exercise and the   -->
                    <!-- inner webwork                                            -->
                    <xsl:attribute name="id">
                        <xsl:apply-templates select="." mode="runestone-id"/>
                    </xsl:attribute>
                    <xsl:apply-templates select="introduction|webwork-reps|conclusion">
                        <xsl:with-param name="b-original" select="$b-original" />
                    </xsl:apply-templates>
                </div>
            </div>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="introduction|webwork-reps|conclusion">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement     -->
<!-- with Sage, so pass block type               -->
<!-- Process according to structure              -->
<!-- Mirror changes here into "solutions" below  -->
<xsl:template match="exercise" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:choose>
        <!-- webwork case -->
        <xsl:when test="webwork-reps">
            <xsl:apply-templates select="." mode="webwork-core">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- MyOpenMath case -->
        <xsl:when test="myopenmath">
            <xsl:apply-templates select="introduction|myopenmath|conclusion">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- STACK case -->
        <xsl:when test="stack">
            <xsl:apply-templates select="introduction|stack|conclusion">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- structured by "task" so let templates for tasks work -->
        <!-- down to terminal task with SOLUTION-LIKE appendages  -->
        <xsl:when test="task">
            <!-- An "exercise" structured by task may electively be presented  -->
            <!-- by a "tabbed" interface from Runestone components.            -->
            <!-- *  Never for a "worksheet" - too messy for printing           -->
            <!-- *  Not hitting PROJECT-LIKE here, see elsewhere               -->
            <xsl:variable name="b-tabbed-tasks" select="
                (@exercise-customization = 'divisional' and $b-html-tabbed-tasks-divisional) or
                (@exercise-customization = 'inline' and $b-html-tabbed-tasks-inline) or
                (@exercise-customization = 'reading' and $b-html-tabbed-tasks-reading)"/>
            <xsl:choose>
                <xsl:when test="$b-tabbed-tasks">
                    <!-- Use tabbed viewer from Runestone Components -->
                    <xsl:apply-templates select="."  mode="tabbed-tasks"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="introduction|task|conclusion">
                        <xsl:with-param name="b-original" select="$b-original"/>
                        <xsl:with-param name="block-type" select="$block-type"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!--  -->
        <!-- structured with "statement" and SOLUTION-LIKE, -->
        <!-- or just bare content for a statement           -->
        <!--  -->
        <!-- inline                                        -->
        <!-- only possibility to be knowled, so only time  -->
        <!-- we pass block-type for Sage cells to react to -->
        <xsl:when test="boolean(&INLINE-EXERCISE-FILTER;)">
            <xsl:apply-templates select="."  mode="exercise-components">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-inline-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-inline-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-inline-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- divisional -->
        <xsl:when test="ancestor::exercises">
            <xsl:apply-templates select="."  mode="exercise-components">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-divisional-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-divisional-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-divisional-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- worksheet -->
        <xsl:when test="ancestor::worksheet">
            <xsl:apply-templates select="."  mode="exercise-components">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-worksheet-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-worksheet-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-worksheet-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- reading -->
        <xsl:when test="ancestor::reading-questions">
            <xsl:apply-templates select="."  mode="exercise-components">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-reading-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-reading-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-reading-solution" />
            </xsl:apply-templates>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Project-LIKE -->
<!-- A complex block, possibly structured with task -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&PROJECT-LIKE;" mode="is-hidden">
    <xsl:value-of select="$knowl-project = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&PROJECT-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&PROJECT-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> project-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&PROJECT-LIKE;" mode="heading-birth">
    <xsl:param name="heading-level"/>
    <xsl:apply-templates select="." mode="heading-full">
        <xsl:with-param name="heading-level" select="$heading-level"/>
    </xsl:apply-templates>
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&PROJECT-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement    -->
<!-- with Sage, so pass block type              -->
<!-- Process according to structure              -->
<!-- Mirror changes here into "solutions" below  -->
<!-- NB: we explicitly ignore "prelude" and      -->
<!-- "postlude" by being very careful about what -->
<!-- we process.  A more general template will   -->
<!-- pick them up *only* when it is original     -->
<!-- content, and place outside the block.       -->
<xsl:template match="&PROJECT-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:choose>
        <!-- webwork case -->
        <xsl:when test="webwork-reps">
            <xsl:apply-templates select="." mode="webwork-core">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="task">
            <!-- An "PROJECT-LIKE" structured by task may electively  -->
            <!-- be presented by a "tabbed" interface from Runestone  -->
            <!-- components. Note: this test is simpler than for  -->
            <!-- "exercise" since we know we have a PROJECT-LIKE and  -->
            <!-- do not need to consult @exercise-customization. -->
            <xsl:choose>
                <xsl:when test="$b-html-tabbed-tasks-project">
                    <!-- Use tabbed viewer from Runestone Components -->
                    <xsl:apply-templates select="."  mode="tabbed-tasks"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="introduction|task|conclusion">
                        <xsl:with-param name="b-original" select="$b-original"/>
                        <xsl:with-param name="block-type" select="$block-type"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="."  mode="exercise-components">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-project-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-project-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-project-solution" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- For solutions divisions, we mimic and reuse some of the above -->
<xsl:template match="exercise|&PROJECT-LIKE;" mode="solutions">
    <xsl:param name="admit"/>
    <xsl:param name="heading-level" />
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <!-- we check for content, subject to selection of switches          -->
    <!-- if there is no content, then we will not output anything at all -->
     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
        <!-- incongruities here are historical, -->
        <!-- keeping the diff low-impact        -->
        <xsl:element name="article">
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="self::exercise">
                        <xsl:text>exercise-like</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>project-like</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <!-- A variety of headings -->
            <xsl:choose>
                <!-- inline can go with generic, which is switched on inline/divisional -->
                <xsl:when test="boolean(&INLINE-EXERCISE-FILTER;)">
                    <xsl:apply-templates select="." mode="heading-birth">
                        <xsl:with-param name="heading-level" select="$heading-level"/>
                    </xsl:apply-templates>
                </xsl:when>
                <!-- with full number just for solution list -->
                <!-- "exercise" must be divisional now -->
                <xsl:when test="self::exercise">
                    <xsl:apply-templates select="." mode="heading-divisional-exercise">
                        <xsl:with-param name="heading-level" select="$heading-level"/>
                    </xsl:apply-templates>
                </xsl:when>
                <!-- now PROJECT-LIKE -->
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="heading-birth">
                        <xsl:with-param name="heading-level" select="$heading-level"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <!-- structured version -->
                <xsl:when test="task">
                    <xsl:if test="$b-has-statement">
                        <xsl:apply-templates select="introduction">
                            <xsl:with-param name="b-original" select="false()" />
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:apply-templates select="task" mode="solutions">
                        <xsl:with-param name="b-original" select="false()" />
                        <xsl:with-param name="heading-level"   select="$heading-level + 1"/>
                        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                    </xsl:apply-templates>
                    <xsl:if test="$b-has-statement">
                        <xsl:apply-templates select="conclusion">
                            <xsl:with-param name="b-original" select="false()" />
                        </xsl:apply-templates>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="webwork-reps/static/task">
                    <xsl:if test="$b-has-statement">
                        <xsl:apply-templates select="webwork-reps/static/introduction">
                            <xsl:with-param name="b-original" select="false()" />
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:apply-templates select="webwork-reps/static/task" mode="solutions">
                        <xsl:with-param name="b-original" select="false()" />
                        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                    </xsl:apply-templates>
                    <xsl:if test="$b-has-statement">
                        <xsl:apply-templates select="webwork-reps/static/conclusion">
                            <xsl:with-param name="b-original" select="false()" />
                        </xsl:apply-templates>
                    </xsl:if>
                </xsl:when>
                <!-- webwork with stages -->
                <xsl:when test="webwork-reps/static/stage">
                    <xsl:apply-templates select="webwork-reps/static/stage" mode="exercise-components">
                        <xsl:with-param name="b-original" select="false()" />
                        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                    </xsl:apply-templates>
                </xsl:when>
                <!-- webwork without tasks or stages -->
                <xsl:when test="webwork-reps/static">
                    <xsl:apply-templates select="webwork-reps/static" mode="exercise-components">
                        <xsl:with-param name="b-original" select="false()" />
                        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="."  mode="exercise-components">
                        <xsl:with-param name="b-original" select="false()" />
                        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:if>
</xsl:template>

<!-- Task -->
<!-- A division of a PROJECT-LIKE, with appendages -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="task" mode="is-hidden">
    <xsl:value-of select="$knowl-task = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="task" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="task" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> exercise-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="task" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-list-number" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="task" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Potentially knowled, may have statement      -->
<!-- with Sage, so pass block type                -->
<!-- Process according to structure               -->
<!-- Mirror changes here into "solutions" below  -->
<xsl:template match="task" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <!-- There are two types of "task".  Those in "exercise", PROJECT-LIKE, -->
    <!-- or EXAMPLE-LIKE, have appendages that are SOLUTION-LIKE, with      -->
    <!-- variable behavior.  Those in OPENPROBLEM-LIKE have appendages that -->
    <!-- are DISCUSSION-LIKE with very predictable behavior.  Easier to     -->
    <!-- switch on being inside OPENPROBLEM-LIKE.                           -->
    <xsl:variable name="openproblem-container" select="ancestor::*[&OPENPROBLEM-FILTER;]"/>

    <xsl:choose>
        <!-- structured by "task" so let templates for tasks work down to   -->
        <!-- terminal task with SOLUTION-LIKE or DISCUSSION-LIKE appendages -->
        <xsl:when test="task">
            <xsl:apply-templates select="introduction|task|conclusion">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- then terminal task, may have DISCUSSION-LIKE to display -->
        <!-- we do not entertain bare content as a "statement" here  -->
        <xsl:when test="$openproblem-container">
            <xsl:apply-templates select="statement|&DISCUSSION-LIKE;">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- then terminal task, may have solutions to optionally display -->
        <!--                                                              -->
        <!-- NB: a "task" rediscovers its context in order to decide      -->
        <!-- if SOLUTION-LIKE appendages are displayed at birth or not.   -->
        <!-- A refactor could examine attributes placed by the            -->
        <!-- pre-processor/assembly pass.                                 -->
        <!--                                                              -->
        <!-- It is tempting to think the context could be passed down     -->
        <!-- through parameters, but each level of "task" goes through a  -->
        <!-- default template, a "body" template, and a "wrapped-content" -->
        <!-- template, which would require cluttering those with four     -->
        <!-- *-has-* parameters, which are not relevant most of the time. -->
        <xsl:otherwise>
            <!-- We identify the container, in order to classify the    -->
            <!-- group of switches that will control visibility of      -->
            <!-- solutions.  Exactly one of these three is a singleton, -->
            <!-- the other two are empty.                               -->
            <xsl:variable name="exercise-container" select="ancestor::exercise"/>
            <xsl:variable name="project-container" select="ancestor::*[&PROJECT-FILTER;]"/>
            <xsl:variable name="example-container" select="ancestor::*[&EXAMPLE-FILTER;]"/>
            <!-- Now booleans for exercises or projects, exercises below -->
            <xsl:variable name="project" select="boolean($project-container)"/>
            <xsl:variable name="example" select="boolean($example-container)"/>
            <!-- We classify the four types of exercises further based -->
            <!-- on location.  Inline is "everything else".            -->
            <xsl:variable name="divisional" select="$exercise-container and $exercise-container/ancestor::exercises"/>
            <xsl:variable name="worksheet" select="$exercise-container and $exercise-container/ancestor::worksheet"/>
            <xsl:variable name="reading" select="$exercise-container and $exercise-container/ancestor::reading-questions"/>
            <xsl:variable name="inline" select="$exercise-container and not($divisional or $worksheet or $reading)"/>
            <!-- We have six booleans, exactly one is true, thus  -->
            <!-- classifying a "task" by its employment/location. -->
            <!-- We now form a set of three booleans, appropriate -->
            <!-- for setting the task finds itself in.  There are -->
            <!-- five author-supplied switches and an "example"   -->
            <!-- *always* shows its solutions (not an "exercise). -->
            <xsl:variable name="b-has-hint"
                select="($inline and $b-has-inline-hint)  or
                        ($project and $b-has-project-hint)  or
                        ($divisional and $b-has-divisional-hint) or
                        ($worksheet and $b-has-worksheet-hint)  or
                        ($reading and $b-has-reading-hint)  or
                         $example"/>
            <xsl:variable name="b-has-answer"
                select="($inline and $b-has-inline-answer)  or
                        ($project and $b-has-project-answer)  or
                        ($divisional and $b-has-divisional-answer) or
                        ($worksheet and $b-has-worksheet-answer)  or
                        ($reading and $b-has-reading-answer)  or
                         $example"/>
            <xsl:variable name="b-has-solution"
                select="($inline and $b-has-inline-solution)  or
                        ($project and $b-has-project-solution)  or
                        ($divisional and $b-has-divisional-solution) or
                        ($worksheet and $b-has-worksheet-solution)  or
                        ($reading and $b-has-reading-solution)  or
                         $example"/>
            <xsl:apply-templates select="."  mode="exercise-components">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
            </xsl:apply-templates>
        </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<!-- For solutions divisions, we mimic and reuse some of the above -->
<xsl:template match="task" mode="solutions">
    <xsl:param name="heading-level"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <!-- we check for content, subject to selection of switches          -->
    <!-- if there is no content, then we will not output anything at all -->
     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
        <article class="exercise-like">
            <xsl:apply-templates select="." mode="duplicate-heading">
                <xsl:with-param name="heading-level" select="$heading-level"/>
            </xsl:apply-templates>

            <xsl:choose>
                <!-- introduction?, task+, conclusion? -->
                <xsl:when test="task">
                    <xsl:if test="$b-has-statement">
                        <xsl:apply-templates select="introduction">
                            <xsl:with-param name="b-original" select="false()" />
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:apply-templates select="task" mode="solutions">
                        <xsl:with-param name="heading-level"   select="$heading-level + 1" />
                        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                    </xsl:apply-templates>
                    <xsl:if test="$b-has-statement">
                        <xsl:apply-templates select="conclusion">
                            <xsl:with-param name="b-original" select="false()" />
                        </xsl:apply-templates>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="."  mode="exercise-components">
                        <xsl:with-param name="b-original" select="false()" />
                        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </article>
    </xsl:if>
</xsl:template>


<!-- SOLUTION-LIKE -->
<!-- A simple item hanging off others -->

<!-- Always born-hidden, by design -->
<xsl:template match="&SOLUTION-LIKE;" mode="is-hidden">
    <xsl:choose>
        <xsl:when test="($knowl-example-solution = 'no') and ancestor::*[&EXAMPLE-FILTER;]">
            <xsl:text>false</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>true</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&SOLUTION-LIKE;" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&SOLUTION-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> solution-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&SOLUTION-LIKE;" mode="heading-birth">
    <xsl:choose>
        <xsl:when test="($knowl-example-solution = 'no') and ancestor::*[&EXAMPLE-FILTER;]">
            <xsl:apply-templates select="." mode="heading-non-singleton-number"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="heading-simple"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&SOLUTION-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Potentially knowled, may have statement      -->
<!-- with Sage, so pass block type                -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="&SOLUTION-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:apply-templates select="*">
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>


<!-- DISCUSSION-LIKE -->
<!-- A simple item hanging off others -->

<!-- Always born-hidden, by design -->
<xsl:template match="&DISCUSSION-LIKE;" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&DISCUSSION-LIKE;" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&DISCUSSION-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> discussion-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&DISCUSSION-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full"/>
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&DISCUSSION-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Potentially knowled, may have statement      -->
<!-- with Sage, so pass block type                -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="&DISCUSSION-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:apply-templates select="*">
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="exercise|&PROJECT-LIKE;|task|&EXAMPLE-LIKE;|webwork-reps/static|webwork-reps/static/task|webwork-reps/static/stage" mode="exercise-components">
    <xsl:param name="b-original"/>
    <xsl:param name="block-type"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:choose>
        <!-- signal on intentional, temporary, hack      -->
        <!-- simply duplicated in assembly, no solutions -->
        <xsl:when test="@exercise-interactive = 'htmlhack'">
            <xsl:apply-templates select="." mode="runestone-to-interactive"/>
        </xsl:when>
        <!-- Select -->
        <!-- Largely a Runestone/database operation referencing -->
        <!-- existing questions supplied by the manifest,       -->
        <!-- so we go straight to an HTML version               -->
        <xsl:when test="@exercise-interactive = 'select'">
            <xsl:apply-templates select="." mode="runestone-to-interactive"/>
        </xsl:when>
        <!-- True/False        -->
        <!-- Multiple Choice   -->
        <!-- Parson problems   -->
        <!-- Matching problems -->
        <!-- Clickable Area    -->
        <!-- Fill-In (Basic)   -->
        <!-- Coding Exercise   -->
        <!-- Short Answer      -->
        <!-- The "runestone-to-interactive" templates will combine a   -->
        <!-- "regular" PreTeXt statement together with some additional -->
        <!-- interactive material to make a hybrid "statement"         -->
        <xsl:when test="(@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'cardsort') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')"
                               >
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="." mode="runestone-to-interactive"/>
            </xsl:if>
            <xsl:apply-templates select="." mode="solutions-div">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
                <xsl:with-param name="b-has-hint"  select="$b-has-hint"/>
                <xsl:with-param name="b-has-answer"  select="$b-has-answer"/>
                <xsl:with-param name="b-has-solution"  select="$b-has-solution"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- Dynamic fillin is broken out separately because the test for -->
        <!-- correctness as well as feedback is dynamically chosen.       -->
        <xsl:when test="@exercise-interactive = 'fillin'">
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="." mode="runestone-to-interactive"/>
            </xsl:if>
            <!-- Include hints. Solution/answer get special handling       -->
            <xsl:apply-templates select="." mode="solutions-div">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
                <xsl:with-param name="b-has-hint"  select="$b-has-hint"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- Finally nothing too exceptional, do the usual drill. Consider -->
        <!-- structured versus unstructured, non-interactive.              -->
        <xsl:when test="statement">
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="statement">
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="block-type" select="$block-type"/>
                </xsl:apply-templates>
            </xsl:if>
            <xsl:apply-templates select="." mode="solutions-div">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
                <xsl:with-param name="b-has-hint"  select="$b-has-hint"/>
                <xsl:with-param name="b-has-answer"  select="$b-has-answer"/>
                <xsl:with-param name="b-has-solution"  select="$b-has-solution"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- TODO: contained "if" should just be a new "when"? (look around for similar)" -->
        <xsl:otherwise>
            <!-- no explicit "statement", so all content is the statement -->
            <!-- the "dry-run" templates should prevent an empty shell  -->
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="*">
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="block-type" select="$block-type"/>
                </xsl:apply-templates>
                <!-- no separator, since no trailing components -->
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- "exercise", EXAMPLE-LIKE, PROJECT-LIKE, "task", and more have a  -->
<!-- div.solutions full of SOLUTION-LIKE hanging off them.  But we    -->
<!-- don't want the div if there is nothing to go into it, and        -->
<!-- EXAMPLE-LIKE is presentational, so we don't have knowls to       -->
<!-- package, we just lay them out right after the example.           -->
<!-- N.B. match could be improved, just being more lazy than careful  -->
<xsl:template match="*" mode="solutions-div">
    <xsl:param name="b-original"/>
    <xsl:param name="block-type"/>
    <!-- no "statement" here -->
    <xsl:param name="b-has-hint"/>
    <xsl:param name="b-has-answer"/>
    <xsl:param name="b-has-solution"/>

    <!-- nothing to do if there is nothing so show -->
    <xsl:if test="(hint and $b-has-hint) or (answer and $b-has-answer) or (solution and $b-has-solution)">
        <!-- collect all the hint, answer, solution in a variable -->
        <xsl:variable name="all-solutions">
            <xsl:if test="$b-has-hint">
                <xsl:apply-templates select="hint">
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="block-type" select="$block-type"/>
                </xsl:apply-templates>
            </xsl:if>
            <xsl:if test="$b-has-answer">
                <xsl:apply-templates select="answer">
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="block-type" select="$block-type"/>
                </xsl:apply-templates>
            </xsl:if>
            <xsl:if test="$b-has-solution">
                <xsl:apply-templates select="solution">
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="block-type" select="$block-type"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:variable>
        <!-- If this is an EXAMPLE-LIKE and we are unknowling its solutions,   -->
        <!-- then just show them.  Otherwise, we use a div to layout knowls    -->
        <!-- like a sentence: horiziontal flow, with wrapping.                 -->
        <!-- NB: context here could be an EXAMPLE-LIKE or it might be a "task" -->
        <!-- with an EXAMPLE-LIKE ancestor, thus the ancestor-or-self:: axis   -->
        <xsl:choose>
            <xsl:when test="($knowl-example-solution = 'no') and ancestor-or-self::*[&EXAMPLE-FILTER;]">
                <xsl:copy-of select="$all-solutions"/>
            </xsl:when>
            <xsl:otherwise>
                <div class="solutions">
                    <xsl:copy-of select="$all-solutions"/>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- All of the items matching the template two above (except perhaps  -->
<!-- the WW exercises) can appear in a printout with some room to      -->
<!-- work a problem given by a @workspace attribute.  (But we are not  -->
<!-- careful with the match, given the limited reach here.)  The "div" -->
<!-- we drop here is controlled by the Javascript - on a "normal" page -->
<!-- displaying a printout it is ineffective, and on a printable,      -->
<!-- standalone page it produces space that is visually apparent, but  -->
<!-- prints invisible.  No @workspace attribute, nothing is added.     -->
<!-- We rely on a template in -common to error-check the value of      -->
<!-- the attribute.                                                    -->
<xsl:template match="*" mode="workspace">
    <xsl:variable name="vertical-space">
        <xsl:apply-templates select="." mode="sanitize-workspace"/>
    </xsl:variable>
    <xsl:if test="not($vertical-space = '')">
        <div class="workspace" data-space="{$vertical-space}"/>
    </xsl:if>
</xsl:template>

<!-- The next few implementions support theorems,       -->
<!-- which may have knowls containing PROOF-LIKE        -->
<!-- hanging  off them.  A PROOF-LIKE can be a block in -->
<!-- its own right (a "detached" PROOF-LIKE).           -->


<!-- THEOREM-LIKE, AXIOM-LIKE -->
<!-- Similar blocks, former may have a PROOF-LIKE appendage -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="is-hidden">
    <xsl:value-of select="$knowl-theorem = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> theorem-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement     -->
<!-- with Sage, so pass block type              -->
<!-- Simply process contents, could restict here -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <!-- Alternative: Locate first "PROOF-LIKE", select only preceding:: ? -->
    <xsl:apply-templates select="*[not(&PROOF-FILTER;)]" >
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>


<!-- PROOF-LIKE -->
<!-- A fairly simple block, though configurable -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&PROOF-LIKE;" mode="is-hidden">
    <xsl:value-of select="$knowl-proof = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&PROOF-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<!-- Only subsidiary item that is configurable -->
<!-- as visible or hidden in a knowl           -->
<xsl:template match="&PROOF-LIKE;" mode="body-css-class">
    <xsl:choose>
        <xsl:when test="$knowl-proof = 'yes'">
            <xsl:text>hiddenproof</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>proof</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- When born use this heading -->
<!-- Optionally titled          -->
<xsl:template match="&PROOF-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-no-number"/>
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<!-- Optionally titled                          -->
<xsl:template match="&PROOF-LIKE;" mode="heading-xref-knowl">
    <xsl:choose>
        <xsl:when test="title">
            <xsl:apply-templates select="." mode="heading-title" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="heading-type" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement    -->
<!-- with Sage, so pass block type              -->
<!-- Simply process contents, could restict here -->
<xsl:template match="&PROOF-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:apply-templates select="*">
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>


<!-- Case (of a PROOF-LIKE) -->
<!-- A simple block with an inline heading -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="case" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="case" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="case" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- When born use this specialized heading -->
<xsl:template match="case" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-case" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="case" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-case" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="case" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="*">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Next few implementations fit into general -->
<!-- framework, but have some one-off flavor   -->


<!-- Footnotes -->
<!-- A bit unusual, as inline with minimal appearance -->

<!-- Always born-hidden, by design -->
<xsl:template match="fn" mode="is-hidden">
    <xsl:text>true</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="fn" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="fn" mode="body-css-class">
    <xsl:text>ptx-footnote__contents</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<!-- This could move to headings, but is one-off -->
<xsl:template match="fn" mode="heading-birth">
    <xsl:element name="sup">
        <xsl:text>&#x2009;</xsl:text>
        <xsl:apply-templates select="." mode="serial-number" />
        <xsl:text>&#x2009;</xsl:text>
    </xsl:element>
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="fn" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<!-- Schema is TextLong, so need to process mixed -->
<xsl:template match="fn" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Contributor -->
<!-- A block with no subsidiary elements, no duplication -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="contributor" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="contributor" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="contributor" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- Heading is not needed -->
<xsl:template match="contributor" mode="heading-birth" />

<!-- xref-knowl content makes it obvious-->
<xsl:template match="contributor" mode="heading-xref-knowl" />

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="contributor" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <!-- not interpreting duplication flag here -->
    <div class="contributor-name">
        <xsl:apply-templates select="personname" />
    </div>
    <div class="contributor-info">
        <xsl:if test="affiliation">
            <xsl:apply-templates select="affiliation"/>
            <xsl:if test="affiliation/following-sibling::*">
                <br/>
            </xsl:if>
        </xsl:if>
        <xsl:if test="email">
            <xsl:apply-templates select="email" />
            <xsl:if test="email/following-sibling::*">
                <br />
            </xsl:if>
        </xsl:if>
    </div>
</xsl:template>


<!-- Defined Terms (of a Glossary) -->

<!-- Never born-hidden, always in "glossary" -->
<xsl:template match="gi" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="gi" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="gi" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="gi" mode="heading-birth" />

<!-- Heading for interior of xref-knowl content -->
<!-- Not necessary, obvious by appearance       -->
<xsl:template match="gi" mode="heading-xref-knowl" />

<!-- Glossary defined terms have more structure -->
<!-- The id is placed on the title as a target  -->
<xsl:template match="gi" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:choose>
        <xsl:when test="$block-type = 'xref'">
            <article class="li">
                <!-- "title" of item is replicated in heading -->
                <xsl:apply-templates select="." mode="heading-xref-knowl" />
                <!-- a run of paragraphs, conceivably, title is killed -->
                <xsl:apply-templates select="*">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
                <!-- Insert permalink -->
                <xsl:apply-templates select="." mode="permalink"/>
            </article>
        </xsl:when>
        <xsl:otherwise>
            <dt>
                <!-- label original -->
                <xsl:if test="$b-original">
                    <xsl:apply-templates select="." mode="html-id-attribute"/>
                </xsl:if>
                <xsl:apply-templates select="." mode="title-full" />
                <!-- Insert permalink -->
                <xsl:apply-templates select="." mode="permalink"/>
            </dt>
            <dd>
                <xsl:apply-templates select="*">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </dd>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Bibliographic Entries -->
<!-- An obvious use for knowls, but occur inline -->

<!-- Never born-hidden, always in references -->
<xsl:template match="biblio" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="biblio" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="biblio" mode="body-css-class">
    <xsl:text>bib</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="biblio" mode="heading-birth" />

<!-- Heading for interior of xref-knowl content -->
<!-- Not necessary, obvious by appearance       -->
<xsl:template match="biblio" mode="heading-xref-knowl" />

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<!-- Schema is TextLong, so need to process mixed -->
<xsl:template match="biblio" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <!-- ignoring original flag at first, -->
    <!-- nothing interior gets duplicated -->
    <div class="bibitem">
        <xsl:choose>
            <!-- CSL not active, PreTeXt numbers and brackets -->
            <xsl:when test="not(@numeric)">
                <xsl:text>[</xsl:text>
                <xsl:apply-templates select="." mode="serial-number" />
                <xsl:text>]</xsl:text>
            </xsl:when>
            <!-- CSL provided, with formatting -->
            <xsl:otherwise>
                <xsl:value-of select="@numeric"/>
            </xsl:otherwise>
        </xsl:choose>
    </div>
    <div class="bibentry">
        <xsl:choose>
            <xsl:when test="@type = 'raw'">
                <!-- mixed content, include text nodes -->
                <xsl:apply-templates select="text()|*[not(self::note)]">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="@type = 'bibtex'">
                <!-- structured, document order -->
                <xsl:apply-templates select="*[not(self::note)]">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="not(@type = 'raw') and not(@type = 'bibtex')">
                <!-- structured, document order -->
                <xsl:apply-templates select="*[not(self::note)]">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </xsl:when>
        </xsl:choose>
        <xsl:if test="note">
            <xsl:apply-templates select="note">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:if>
    </div>
</xsl:template>

<!-- Bibliographic Note -->
<!-- A simple item hanging off others -->

<!-- Always born-hidden, by design -->
<xsl:template match="biblio/note|interactive/instructions" mode="is-hidden">
    <xsl:text>true</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="biblio/note|interactive/instructions" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<!-- This is a temporary hack, which should go away -->
<xsl:template match="biblio/note|interactive/instructions" mode="body-css-class">
    <xsl:text>solution-like</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="biblio/note" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-simple" />
</xsl:template>
<xsl:template match="interactive/instructions" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-no-number" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="biblio/note" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>
<xsl:template match="interactive/instructions" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-no-number" />
</xsl:template>


<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<!-- Schema says just paragraphs, "p"             -->
<xsl:template match="biblio/note|interactive/instructions" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="p" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<!-- Fragment (literate programming) -->
<!-- A simple item hanging off others -->

<!-- Always born-hidden, by design -->
<xsl:template match="fragment" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="fragment" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<!-- This is a temporary hack, which should go away -->
<xsl:template match="fragment" mode="body-css-class">
    <xsl:text>fragment</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="fragment" mode="heading-birth">
    <xsl:variable name="hN">
        <xsl:apply-templates select="." mode="hN"/>
    </xsl:variable>
    <xsl:element name="{$hN}">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
        </xsl:attribute>
        <xsl:call-template name="langle-character"/>
        <xsl:apply-templates select="." mode="number"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:call-template name="rangle-character"/>
        <!--  U+2261 ≡ IDENTICAL TO -->
        <xsl:text> &#x2261;</xsl:text>
    </xsl:element>
    <xsl:if test="@filename">
        <xsl:text>Root of file: </xsl:text>
        <xsl:value-of select="@filename"/>
        <br/>
    </xsl:if>
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="fragment" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template -->
<!-- Pass along b-original flag                 -->
<xsl:template match="fragment" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <pre>
        <xsl:apply-templates select="code|fragref"/>
    </pre>
</xsl:template>

<!-- All of the implementations above use the same   -->
<!-- template for their body, it relies on various   -->
<!-- templates but most of the work comes via the    -->
<!-- "wrapped-content" template.  Here is that       -->
<!-- "body" template.  The items in the "match"      -->
<!-- are in the order presented above: simple first, -->
<!-- and top-down when components are also knowled.  -->


<xsl:template match="&REMARK-LIKE;|&COMPUTATION-LIKE;|&DEFINITION-LIKE;|&ASIDE-LIKE;|poem|&FIGURE-LIKE;|assemblage|blockquote|paragraphs|&GOAL-LIKE;|&OPENPROBLEM-LIKE;|&EXAMPLE-LIKE;|subexercises|exercisegroup|exercise|&PROJECT-LIKE;|task|&SOLUTION-LIKE;|&DISCUSSION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&PROOF-LIKE;|case|fn|contributor|biblio|biblio/note|interactive/instructions|fragment" mode="body">
    <xsl:param name="b-original" select="true()"/>
    <xsl:param name="block-type"/>

    <!-- prelude beforehand, when original -->
    <xsl:if test="$b-original">
        <xsl:apply-templates select="prelude">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:if>
    <xsl:variable name="body-elt">
        <xsl:apply-templates select="." mode="body-element" />
    </xsl:variable>
    <xsl:element name="{$body-elt}">
        <xsl:attribute name="class">
            <xsl:apply-templates select="." mode="body-css-class" />
            <xsl:if test="$block-type = 'hidden'">
                <xsl:text> knowl__content</xsl:text>
            </xsl:if>
        </xsl:attribute>
        <!-- Label original, but not if embedded            -->
        <!-- Then id goes onto the knowl text, so locatable -->
        <xsl:if test="$b-original and not($block-type = 'hidden')">
            <xsl:apply-templates select="." mode="html-id-attribute"/>
        </xsl:if>
        <!-- If visible, heading interior to article -->
        <xsl:if test="$block-type = 'visible'">
            <xsl:apply-templates select="." mode="heading-birth" />
        </xsl:if>
        <!-- If xref-knowl, heading interior to article -->
        <xsl:if test="$block-type = 'xref'">
            <xsl:apply-templates select="." mode="heading-xref-knowl" />
        </xsl:if>
        <!-- After the heading, and before the actual guts, we      -->
        <!-- sometimes annotate with the source                     -->
        <!-- of the current element.  This calls a stub, unless     -->
        <!-- a separate stylesheet is used to define the template,  -->
        <!-- and the method is defined there.  An "fn" necessarily  -->
        <!-- comes through here, but it is a silly thing to         -->
        <!-- annotate.  We skip it promptly on the receiving end,   -->
        <!-- instead of adding clutter here.                        -->
        <xsl:apply-templates select="." mode="view-source-widget"/>
        <!-- Then actual content, respecting b-original flag  -->
        <!-- Pass $block-type for Sage cells to know environs -->
        <xsl:apply-templates select="." mode="wrapped-content">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="block-type" select="$block-type" />
        </xsl:apply-templates>
        <!-- Apply workspace div (but not in project, exercises or tasks, -->
        <!-- since they get them applied in their exercise-content        -->
        <!-- template). Unless the element is in a worksheet or handout,  -->
        <!-- this div will be killed by the sanatize-workspace template.  -->
        <!--<xsl:if test="not(&PROJECT-FILTER; or self::exercise or self::task)">-->
            <xsl:apply-templates select="." mode="workspace"/>
        <!--</xsl:if>-->
        <!-- Insert a permalink as the last child of the block, but only   -->
        <!-- if not FIGURE-LIKE (these get their permalink on the caption) -->
        <xsl:if test="not(&FIGURE-FILTER;)">
            <xsl:apply-templates select="." mode="permalink"/>
        </xsl:if>
    </xsl:element>
    <!-- Extraordinary: PROOF-LIKE are not displayed within their-->
    <!-- parent theorem, but as a sibling, following.  It might  -->
    <!-- be a hidden knowl, it might just be the PROOF-LIKE      -->
    <!-- visible. The conditional simply prevents abuse.         -->
    <xsl:if test="(&THEOREM-FILTER;)">
        <xsl:apply-templates select="&PROOF-LIKE;">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:if>
    <!-- postlude afterward, when original -->
    <xsl:if test="$b-original">
        <xsl:apply-templates select="postlude">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- The following feed into the same framework,   -->
<!-- but have their own specific "body" templates  -->
<!-- due to their unique characteristics.  We have -->
<!-- paragraphs ("p"), list items ("li"), webwork  -->
<!-- exercises ("webwork-reps"), and numbered      -->
<!-- mathematics ("men", "md", "mdn")              -->


<!-- Paragraph -->
<!-- These are never born hidden.  They are     -->
<!-- often xref targets (such as in the index). -->
<!-- Because we bust up some paragraphs into    -->
<!-- smaller ones, interleaved with displays    -->
<!-- (lists, math, code display), and because   -->
<!-- they do not have titles or heading,        -->
<!-- we process everything in the body.         -->

<xsl:template match="p" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<xsl:template match="p" mode="body-element" />

<xsl:template match="p" mode="body-css-class" />

<xsl:template match="p" mode="heading-birth" />

<xsl:template match="p" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-type" />
</xsl:template>

<!-- Paragraphs, without lists within   -->
<xsl:template match="p" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:if test="$block-type = 'xref'">
        <xsl:apply-templates select="." mode="heading-xref-knowl" />
    </xsl:if>
    <div>
        <xsl:attribute name="class">
            <xsl:text>para</xsl:text>
            <!-- acknowledge prelude/interlude/postlude parents -->
            <xsl:apply-templates select="." mode="add-lude-parent-class"/>
        </xsl:attribute>
        <!-- label original -->
        <xsl:if test="$b-original">
            <xsl:apply-templates select="." mode="html-id-attribute"/>
        </xsl:if>
        <xsl:apply-templates>
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <!-- Insert workspace (will only apply to p inside worksheet or handout) -->
        <xsl:apply-templates select="." mode="workspace"/>
        <!-- Insert permalink -->
        <xsl:apply-templates select="." mode="permalink"/>
    </div>
</xsl:template>

<!-- Paragraphs, with displays within                    -->
<!-- Later, so a higher priority match                   -->
<!-- Lists and display math are HTML blocks              -->
<!-- and so should not be within an HTML paragraph.      -->
<!-- We bust them out, and put the id for the paragraph  -->
<!-- on the first one, even if empty.                    -->
<xsl:template match="p[ol|ul|dl|me|men|md[not(mrow)]|mdn[not(mrow)]|md[mrow]|mdn[mrow]|cd]" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:if test="$block-type = 'xref'">
        <xsl:apply-templates select="." mode="heading-xref-knowl" />
    </xsl:if>
    <!-- will later loop over displays within paragraph -->
    <xsl:variable name="displays" select="ul|ol|dl|me|men|md[not(mrow)]|mdn[not(mrow)]|md[mrow]|mdn[mrow]|cd" />
    <!-- content prior to first display is exceptional, but if empty,   -->
    <!-- as indicated by $initial, we do not produce an empty paragraph -->
    <!--                                                                -->
    <!-- all interesting nodes of paragraph, before first display       -->
    <xsl:variable name="initial" select="$displays[1]/preceding-sibling::*|$displays[1]/preceding-sibling::text()" />
    <xsl:variable name="initial-content">
        <xsl:apply-templates select="$initial">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:variable>
    <div class="para logical">
        <xsl:if test="$b-original">
            <xsl:apply-templates select="." mode="html-id-attribute"/>
        </xsl:if>
        <!-- INDENT FOLLOWING ON A WHITESPACE COMMIT -->
    <!-- XSLT 1.0: RTF is just a string if not converted to node set -->
    <!-- This comparison might improve with a normalize-space()      -->
    <xsl:if test="not($initial-content='')">
        <div>
            <xsl:attribute name="class">
                <xsl:text>para</xsl:text>
            </xsl:attribute>
            <xsl:copy-of select="$initial-content" />
        </div>
    </xsl:if>
    <!-- for each display, output the display, plus trailing content -->
    <xsl:for-each select="$displays">
        <!-- do the display proper -->
        <xsl:apply-templates select=".">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <!-- look through remainder, all element and text nodes, and the next display -->
        <xsl:variable name="rightward" select="following-sibling::*|following-sibling::text()" />
        <xsl:variable name="next-display" select="following-sibling::*[self::ul or self::ol or self::dl or self::me or self::men or self::md[not(mrow)] or self::mdn[not(mrow)] or self::md[mrow] or self::mdn[mrow] or self::cd][1]" />
        <xsl:choose>
            <xsl:when test="$next-display">
                <xsl:variable name="leftward" select="$next-display/preceding-sibling::*|$next-display/preceding-sibling::text()" />
                <!-- device below forms set intersection -->
                <xsl:variable name="common" select="$rightward[count(. | $leftward) = count($leftward)]" />
                <!-- No id on these, as the first "p" got that    -->
                <!-- Careful, punctuation after display math      -->
                <!-- gets absorbed into display and so is a node  -->
                <!-- that produces no content (cannot just count) -->
                <xsl:variable name="common-content">
                    <xsl:apply-templates select="$common">
                        <xsl:with-param name="b-original" select="$b-original" />
                    </xsl:apply-templates>
                </xsl:variable>
                <!-- XSLT 1.0: RTF is just a string if not converted to node set -->
                <!-- This comparison might improve with a normalize-space()      -->
                <xsl:if test="not($common-content = '')">
                    <div class="para">
                        <xsl:copy-of select="$common-content" />
                    </div>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <!-- finish the trailing content, if nonempty -->
                <xsl:variable name="common-content">
                    <xsl:apply-templates select="$rightward">
                        <xsl:with-param name="b-original" select="$b-original" />
                    </xsl:apply-templates>
                </xsl:variable>
                <!-- XSLT 1.0: RTF is just a string if not converted to node set -->
                <!-- This comparison might improve with a normalize-space()      -->
                <xsl:if test="not($common-content = '')">
                    <div class="para">
                        <xsl:copy-of select="$common-content" />
                    </div>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
        <!-- INDENT ABOVE ON A WHITESPACE COMMIT -->
    <!-- Insert workspace (will only apply to p inside worksheet or handout) -->
    <xsl:apply-templates select="." mode="workspace"/>
    <!-- Insert permalink -->
    <xsl:apply-templates select="." mode="permalink"/>
    </div>
</xsl:template>


<!-- List Items -->
<!-- A list item can be the target of a        -->
<!-- cross-reference, so we need to make       -->
<!-- a xref-knowl for that scenario.  Also,    -->
<!-- we produce the original versions here     -->
<!-- too.  The "ol, "ul", "dl" are pure        -->
<!-- containers and are implemented elsewhere. -->

<!-- Not applicable -->
<xsl:template match="li" mode="is-hidden" />

<xsl:template match="li" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- not yet supported, change this? -->
<xsl:template match="li" mode="body-css-class">
    <xsl:text>li</xsl:text>
</xsl:template>

<!-- Not applicable -->
<xsl:template match="li" mode="heading-birth" />

<xsl:template match="li" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- For a description list, the title alone is enough -->
<xsl:template match="dl/li" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Pass-through regular list items    -->
<!-- Allow paragraphs in larger items,  -->
<!-- or just snippets for smaller items -->
<!-- radically diffferent looks if part -->
<!-- of overall list versus being a     -->
<!-- standalone display of one item     -->
<!-- var may be a multiple choice list  -->
<!-- container from a webwork-reps      -->
<xsl:template match="ol/li|ul/li|var/li" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:choose>
        <xsl:when test="$block-type = 'xref'">
            <article class="li">
                <xsl:apply-templates select="." mode="heading-xref-knowl" />
                <xsl:apply-templates>
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </article>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="li">
                <!-- label original -->
                <xsl:if test="$b-original">
                    <xsl:apply-templates select="." mode="html-id-attribute"/>
                </xsl:if>
                <!-- "title" only possible for structured version of a list item -->
                <xsl:if test="title">
                    <span class="heading li--heading">
                        <span class="title li--heading-title">
                            <xsl:apply-templates select="." mode="title-full"/>
                        </span>
                    </span>
                </xsl:if>
                <!-- Unstructured list items will be output as an HTML "p"     -->
                <!-- within the "li", much like a structured list item could   -->
                <!-- have a single "p" as its structured content.  This is     -->
                <!-- meant to help with authoring tools based on HTML content  -->
                <!-- and for CSS withing Kindle versions.  A "dl/li" is always -->
                <!-- structured, so we can do this here.                       -->
                <xsl:choose>
                    <!-- Any of these children is an indicator of a structured  -->
                    <!-- list item, according to the schema, as of 2021-07-03   -->
                    <xsl:when test="p|blockquote|pre|image|video|program|console|tabular|&FIGURE-LIKE;|&ASIDE-LIKE;|sidebyside|sbsgroup|sage">
                        <xsl:apply-templates>
                            <xsl:with-param name="b-original" select="$b-original" />
                        </xsl:apply-templates>
                    </xsl:when>
                    <!-- No good test for unstructured? -->
                    <xsl:otherwise>
                        <div class="para">
                            <!-- Create a derived id, if original.  Somewhat  -->
                            <!-- contrived so it doesn't collide with another. -->
                            <xsl:if test="$b-original">
                                <xsl:attribute name="id">
                                    <xsl:text>p-derived-</xsl:text>
                                    <xsl:apply-templates select="." mode="html-id" />
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:apply-templates>
                                <xsl:with-param name="b-original" select="$b-original" />
                            </xsl:apply-templates>
                        </div>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- Insert workspace (will only apply if in worksheet or handout) -->
                <xsl:apply-templates select="." mode="workspace"/>
                <!-- Insert permalink -->
                <xsl:apply-templates select="." mode="permalink"/>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Description list items have more structure -->
<!-- The id is placed on the title as a target  -->
<xsl:template match="dl/li" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:choose>
        <xsl:when test="$block-type = 'xref'">
            <article class="li">
                <!-- "title" of item is replicated in heading -->
                <xsl:apply-templates select="." mode="heading-xref-knowl" />
                <!-- a run of paragraphs, conceivably, title is killed -->
                <xsl:apply-templates>
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </article>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="dt">
                <!-- label original -->
                <xsl:if test="$b-original">
                    <xsl:apply-templates select="." mode="html-id-attribute"/>
                </xsl:if>
                <xsl:apply-templates select="." mode="title-full" />
                <!-- Insert permalink -->
                <xsl:apply-templates select="." mode="permalink"/>
            </xsl:element>
            <xsl:element name="dd">
                <xsl:apply-templates>
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
                <!-- Insert workspace -->
                <xsl:apply-templates select="." mode="workspace"/>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ########### -->
<!-- Mathematics -->
<!-- ########### -->

<!-- Mathematics authored in LaTeX syntax should be       -->
<!-- independent of output format.  Despite MathJax's     -->
<!-- broad array of capabilities, there are still some    -->
<!-- differences which we need to accomodate via abstract -->
<!-- templates.                                           -->

<!-- See the -common stylesheet for manipulations of math elements      -->
<!-- and subsequent text nodes that lead with punctuation.  Basically,  -->
<!-- punctuation can migrate from the start of the text node and into   -->
<!-- the math, wrapped in a \text{}.  We do this to display math as a   -->
<!-- service to authors.  But for HTML/MathJax we avoid bad line-breaks -->
<!-- if we do this routinely for inline math also.  If MathJax ever     -->
<!-- gets better at this, then we can set this switch to 'display',     -->
<!-- as for LaTeX.                                                      -->
<xsl:variable name="math.punctuation.include" select="'all'"/>

<!-- Inline Mathematics ("m") -->

<!-- Never labeled, so not ever knowled,        -->
<!-- and so no need for a duplicate template    -->
<!-- Asymmetric LaTeX delimiters \( and \) need -->
<!-- to be part of MathJax configuration, but   -->
<!-- also free up the dollar sign               -->


<!-- This template wraps inline math in delimiters -->
<xsl:template name="inline-math-wrapper">
    <xsl:param name="math"/>
    <span class="process-math">
        <xsl:text>\(</xsl:text>
        <xsl:value-of select="$math"/>
        <xsl:text>\)</xsl:text>
    </span>
</xsl:template>

<!-- Displayed Single-Line Math ("me", "men") -->

<!-- All displayed mathematics is wrapped by a div,    -->
<!-- motivated in part by the need to sometimes put an -->
<!-- HTML id on the first item of an exploded logical  -->
<!-- paragraph into several HTML block level items     -->
<!-- NB: displaymath might have an intertext           -->
<!-- becoming "p", thus the necessity of "copy-of"     -->
<xsl:template match="me|men|md[not(mrow)]|mdn[not(mrow)]|md[mrow]|mdn[mrow]" mode="display-math-wrapper">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="content" />
    <div class="displaymath process-math">
        <xsl:apply-templates select="." mode="knowl-urls"/>
        <xsl:if test="$b-original and not(self::me|self::md[not(mrow) and (@numbered = 'no')])">
            <xsl:apply-templates select="." mode="html-id-attribute"/>
        </xsl:if>
        <xsl:copy-of select="$content" />
    </div>
</xsl:template>

<xsl:template match="me|men|md[not(mrow)]|mdn[not(mrow)]|md[mrow]|mdn[mrow]" mode="knowl-urls">
    <xsl:variable name="display-math-cross-references" select="..//xref"/>
    <!-- don't add such an attribute if there is nothing happening -->
    <xsl:if test="$display-math-cross-references">
        <xsl:attribute name="data-contains-math-knowls">
            <xsl:for-each select="$display-math-cross-references">
                <!-- space before all, except first -->
                <xsl:if test="position() != 1">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:apply-templates select="id(@ref)" mode="knowl-filename">
                    <xsl:with-param name="origin" select="'xref'"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </xsl:attribute>
    </xsl:if>
</xsl:template>

<!-- "men" needs to be handled in the knowl production          -->
<!-- scheme (but just barely), since it can be duplicated,      -->
<!-- and there are minor details with trailing punctuation.     -->
<!-- Then we just add "me" in as well, since it is so similar.  -->
<!-- The necessary modal "body" template is in -common, and     -->
<!-- is called by other conversions with the default variables. -->

<!-- We need a few templates for knowl production, -->
<!-- but generally they do nothing                 -->

<!-- always visible -->
<xsl:template match="me|men|md[not(mrow)]|mdn[not(mrow)]" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<xsl:template match="me|men|md[not(mrow)]|mdn[not(mrow)]" mode="body-element" />
<xsl:template match="me|men|md[not(mrow)]|mdn[not(mrow)]" mode="body-css-class" />

<!-- No title; type and number obvious from content -->
<xsl:template match="me|men|md[not(mrow)]|mdn[not(mrow)]" mode="heading-xref-knowl" />

<!-- We need this so a % is used only on the LaTeX side -->
<xsl:template name="display-math-visual-blank-line">
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Manual Number Tagging -->
<!-- We do "tag" numbered equations in MathJax output, -->
<!-- because we want to control and duplicate the way  -->
<!-- numbers are generated and assigned by LaTeX       -->
<!-- "me" is never numbered/tagged, "men" always is    -->
<!-- This is the MathJax hard-coded technique          -->
<!-- Local tag preempts a hard-coded number, and we    -->
<!-- need to also take care with the numbering. \tag{} -->
<!-- is what a reader sees, usually the number         -->
<!-- computed in -common, but sometimes symbols        -->
<!-- generated by mrow/@tag. These are purely visual.  -->
<!-- Identification and cross-references are managed   -->
<!-- by HTML id on enclosing HTML elements.            -->

<xsl:template match="md[not(mrow)]" mode="tag">
    <xsl:if test="@numbered = 'yes'">
        <xsl:text>\tag{</xsl:text>
        <xsl:apply-templates select="." mode="number" />
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="men|mdn[not(mrow)]|mrow" mode="tag">
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="mrow[@tag]" mode="tag">
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="@tag" mode="tag-symbol" />
    <xsl:text>}</xsl:text>
</xsl:template>


<!-- Displayed Multi-Line Math ("md", "mdn") -->

<!-- The default template for the "md" and "mdn" containers   -->
<!-- just calls the modal "body" template needed for the HTML -->
<!-- knowl production scheme.                                 -->

<!-- We need a few templates for knowl production, -->
<!-- but generally they do nothing                 -->

<!-- always visible -->
<xsl:template match="md[mrow]|mdn[mrow]" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<xsl:template match="md[mrow]|mdn[mrow]" mode="body-element" />
<xsl:template match="md[mrow]|mdn[mrow]" mode="body-css-class" />

<!-- No title; type and number obvious from content -->
<xsl:template match="md[mrow]|mdn[mrow]" mode="heading-xref-knowl" />

<!-- Rows of Displayed Multi-Line Math ("mrow") -->
<!-- Template in -common is sufficient with base templates     -->
<!--                                                           -->
<!-- (1) "display-page-break" (LaTeX only)                     -->

<!-- Intertext -->
<!-- A LaTeX construct really, we just jump out/in of    -->
<!-- the align/gather environment and process the text.  -->
<!-- "md" and "mdn" can only occur in a "p" and          -->
<!-- we break a logical PreTeXt "p" into multiple HTML   -->
<!-- "p" at places where displays occur, such as math    -->
<!-- and lists.  So we can wrap the "intertext" in a     -->
<!-- p.intertext, giving xref knowls a place to open.    -->
<!-- This breaks the alignment, but MathJax has no good  -->
<!-- solution for this.                                  -->
<!-- NB: "displaymath-alignment" needs to be just right  -->
<!-- NB: we check the *parent* for alignment information -->
<!-- NB: the out-of-order LaTeX begin/end pairs mean     -->
<!-- the "p" for intertext are contained in the overall  -->
<!-- "display-math-wrapper".  It might be advisable      -->
<!-- to unpack the whole md/mdn into math bits and       -->
<!-- intertext bits, similar to how paragraphs are       -->
<!-- exploded.  This will make it harder to locate       -->
<!-- the id of an enclosing paragraph onto the first     -->
<!-- component (first in exploded paragraph, first in    -->
<!-- exploded md/intertext).                             -->
<!-- An abstact "intertext-wrapper" would allow all      -->
<!-- this to live in -common.                            -->
<!-- TODO: pass duplication flag, reaction unnecessary?  -->
<xsl:template match="intertext">
    <xsl:param name="b-nonumbers" select="false()" />
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="parent::*" mode="displaymath-alignment">
        <xsl:with-param name="b-nonumbers" select="$b-nonumbers" />
    </xsl:apply-templates>
    <xsl:text>}&#xa;</xsl:text>
    <div class="para intertext">
        <xsl:apply-templates/>
    </div>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="parent::*" mode="displaymath-alignment">
        <xsl:with-param name="b-nonumbers" select="$b-nonumbers" />
    </xsl:apply-templates>
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="parent::*" mode="alignat-columns" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Once upon a time, we broke up markup meant for MathJax that occured   -->
<!-- outside of what we know is a mathematical context ("accidental        -->
<!-- mathematics").   We did this by breaking up strings with a zero-width -->
<!-- space (U+200B), but a better device is wrapping a delimiter in a span -->
<!-- (see this technique in the "text-processing" template in the Jupyter  -->
<!-- conversion).  However, MathJax 3 lets us target/ignore specific       -->
<!-- locations for its translation.  So the "text-processing" template     -->
<!-- that was once here is now gone.  But now it is back, to upgrade a     -->
<!-- keyboard "plain" apostrophe to a Unicode "curly" apostrophe.          -->

<xsl:template name="text-processing">
    <xsl:param name="text"/>

    <!-- 'RIGHT SINGLE QUOTATION MARK' (U+2019) -->
    <xsl:variable name="apostophe-fixed" select="str:replace($text, $apos, '&#x2019;')"/>

    <xsl:value-of select="$apostophe-fixed"/>
</xsl:template>

<!-- We cruise knowled content for necessity of hidden knowls -->
<xsl:template match="*" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- ############################# -->
<!-- End: Block Production, Knowls -->
<!-- ############################# -->


<!-- #################### -->
<!-- Components of Blocks -->
<!-- #################### -->

<!-- Introductions and Conclusions -->
<!-- As components of blocks.      -->
<xsl:template match="introduction[not(parent::*[&STRUCTURAL-FILTER;])]|conclusion[not(parent::*[&STRUCTURAL-FILTER;])]">
    <xsl:param name="b-original" select="true()" />
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:value-of select="local-name(.)" />
        </xsl:attribute>
        <xsl:if test="$b-original">
            <xsl:apply-templates select="." mode="html-id-attribute"/>
        </xsl:if>
        <xsl:if test="title">
            <xsl:variable name="hN">
                <xsl:apply-templates select="." mode="hN"/>
            </xsl:variable>
            <xsl:element name="{$hN}">
                <xsl:attribute name="class">
                    <xsl:text>heading</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="." mode="title-full" />
                <span> </span>
            </xsl:element>
        </xsl:if>
        <xsl:apply-templates select="*">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

<!-- A "headnote" prefaces the content of a "glossary".  Below -->
<!-- is modeled on block introductions (just above), but with  -->
<!-- no "title" and with a provisional recycled CSS class.     -->
<xsl:template match="glossary/headnote">
    <xsl:param name="b-original" select="true()" />
    <section class="headnote">
        <xsl:if test="$b-original">
            <xsl:apply-templates select="." mode="html-id-attribute"/>
        </xsl:if>
        <xsl:apply-templates select="*">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </section>
</xsl:template>

<!-- Prelude, Interlude, Postlude -->
<!-- Very simple containiers, to help with movement, use -->
<xsl:template match="prelude|interlude|postlude">
    <xsl:param name="b-original" select="true()" />
    <!-- assume these containers are structured -->
    <xsl:apply-templates select="*">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<!-- Indicate if a routine element/object is from a LUDE-LIKE, -->
<!-- by looking to the parent.  This is meant for use where an -->
<!-- HTML element is already placing a @class attribute, so a  -->
<!-- space is included to separate it away.                    -->
<!-- NB: look to schema for all allowed elements within a "prelude", -->
<!-- etc. and extend implementation beyond just "p" if desired.      -->
<xsl:template match="p" mode="add-lude-parent-class">
    <xsl:if test="parent::prelude|parent::interlude|parent::postlude">
        <!-- space off from existing class name(s) -->
        <xsl:text> </xsl:text>
        <!-- class name is parent PTX name -->
        <xsl:value-of select="local-name(parent::*)"/>
    </xsl:if>
</xsl:template>


<!-- ########### -->
<!-- HTML Markup -->
<!-- ########### -->

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Utility templates to translate PTX              -->
<!-- enumeration style to HTML list-style-type       -->
<xsl:template match="ol|ol-marker" mode="html-list-class">
    <xsl:variable name="mbx-format-code" select="./@format-code" />
    <xsl:choose>
        <xsl:when test="$mbx-format-code = '0'">decimal</xsl:when>
        <xsl:when test="$mbx-format-code = '1'">decimal</xsl:when>
        <xsl:when test="$mbx-format-code = 'a'">lower-alpha</xsl:when>
        <xsl:when test="$mbx-format-code = 'A'">upper-alpha</xsl:when>
        <xsl:when test="$mbx-format-code = 'i'">lower-roman</xsl:when>
        <xsl:when test="$mbx-format-code = 'I'">upper-roman</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:BUG: bad ordered list label format code in HTML conversion</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="ul" mode="html-list-class">
    <xsl:variable name="mbx-format-code">
        <xsl:apply-templates select="." mode="format-code" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$mbx-format-code = 'disc'">disc</xsl:when>
        <xsl:when test="$mbx-format-code = 'circle'">circle</xsl:when>
        <xsl:when test="$mbx-format-code = 'square'">square</xsl:when>
        <xsl:when test="$mbx-format-code = 'none'">no-marker</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:BUG: bad unordered list label format code in HTML conversion</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Lists themselves -->
<!-- Hard-code the list style, trading -->
<!-- on match in label templates.      -->
<!-- Tunnel duplication flag to list items -->
<xsl:template match="ol|ul">
    <xsl:param name="b-original" select="true()" />
    <!-- need to switch on 0-1 for ol Arabic -->
    <!-- no harm if called on "ul"           -->
    <xsl:variable name="mbx-format-code">
        <xsl:choose>
            <xsl:when test="self::ol">
                <xsl:value-of select="./@format-code" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="format-code" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:element name="{local-name(.)}">
        <xsl:attribute name="class">
            <xsl:apply-templates select="." mode="html-list-class" />
            <xsl:variable name="ol-marker-class">
                <xsl:apply-templates select="." mode="ol-marker-class" />
            </xsl:variable>
            <xsl:if test="not($ol-marker-class = '')">
                <xsl:text> </xsl:text>
                <xsl:value-of select="$ol-marker-class"/>
            </xsl:if>
            <xsl:variable name="cols-class-name">
                <!-- HTML-specific, but in pretext-common.xsl -->
                <xsl:apply-templates select="." mode="number-cols-CSS-class"/>
            </xsl:variable>
            <xsl:if test="not($cols-class-name = '')">
                <xsl:text> </xsl:text>
                <xsl:value-of select="$cols-class-name"/>
            </xsl:if>
        </xsl:attribute>
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="html-id" />
        </xsl:attribute>
        <xsl:if test="$mbx-format-code = '0'">
            <xsl:attribute name="start">
                <xsl:text>0</xsl:text>
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="li">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

<xsl:template match="ol[@marker]" mode="ol-marker-class">
    <xsl:variable name="marker-value" select="./@marker" />
    <xsl:for-each select="exsl:node-set($ol-markers)">
        <!-- Should be only one match since ol marker -->
        <!-- index node set contains no duplicates    -->
        <xsl:value-of select="key('marker-key', $marker-value)[1]/@classname"/>
    </xsl:for-each >
</xsl:template>

<xsl:template match="ol[not(@marker) and @format-code = 'a' and @ordered-list-level = '1']" mode="ol-marker-class">
    <xsl:text>lower-alpha-level-1</xsl:text>
</xsl:template>

<xsl:template match="ol|ul" mode="ol-marker-class"/>

<xsl:template match="ol[@marker]" mode="ol-markers">
    <xsl:element name="ol-marker">
        <xsl:copy-of select="@format-code"/>
        <xsl:copy-of select="@marker"/>
        <xsl:copy-of select="@marker-prefix"/>
        <xsl:copy-of select="@marker-suffix"/>
        <xsl:attribute name="classname">
            <xsl:text>ol-marker-</xsl:text>
            <xsl:value-of select="position()" />
        </xsl:attribute>
    </xsl:element>
</xsl:template>

<!-- Creates custom formatting for each unique ol/@marker -->
<xsl:template match="ol-marker" mode="ol-marker-style">
    <!-- format child li elements according to marker prefix/code/suffix -->
    <xsl:text>ol.</xsl:text>
    <xsl:value-of select="./@classname"/>
    <xsl:text> &gt; li::marker { content: &quot;</xsl:text>
    <xsl:value-of select="./@marker-prefix" />
    <xsl:text>&quot;counter(list-item,</xsl:text>
    <xsl:apply-templates select="." mode="html-list-class" />
    <xsl:text>)&quot;</xsl:text>
    <xsl:value-of select="./@marker-suffix" />
    <xsl:text> &quot;; }&#xa;</xsl:text>
</xsl:template>

<!-- CSS file for custom ol markers -->
<xsl:template name="ol-marker-styles">
    <!-- We don't produce a file if it will be empty. This would  -->
    <!-- "naturally" be the case, but we have a boolean anyway.   -->
    <xsl:if test="$b-needs-custom-marker-css">
        <xsl:variable name="ol-marker-nodes" select="exsl:node-set($ol-markers)" />
        <exsl:document href="{$html.css.dir}/ol-markers.css" method="text">
            <xsl:apply-templates select="$ol-marker-nodes//ol-marker" mode="ol-marker-style" />
        </exsl:document>
    </xsl:if>
</xsl:template>

<!-- We let CSS react to narrow titles for dl -->
<!-- But no support for multiple columns      -->
<!-- tunnel duplication flag to list items -->
<xsl:template match="dl">
    <xsl:param name="b-original" select="true()" />
    <dl>
        <xsl:attribute name="class">
            <xsl:choose>
                <xsl:when test="@width = 'narrow'">
                    <xsl:text>description-list narrow</xsl:text>
                </xsl:when>
                <xsl:when test="@width = 'wide'">
                    <xsl:text>description-list wide</xsl:text>
                </xsl:when>
                <!-- 'medium' and any typo (let DTD check) -->
                <xsl:otherwise>
                    <xsl:text>description-list</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates select="li">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </dl>
</xsl:template>

<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- A bare image, or an image in a PTX "figure" that is not part  -->
<!-- of a panel of a "sidebyside", can be given horizontal layout  -->
<!-- control.  This is placed on a constraining "div.image-box"    -->
<!-- via the "@style" attribute.  The image simply "grows" to      -->
<!-- fill this box horizontally, with necessary vertical dimension -->
<!-- to preserve the aspect ratio.  This div is also used to       -->
<!-- provide vertical spacing from its surroundings.               -->
<xsl:template match="image[not(ancestor::sidebyside)]">
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters" />
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
    <!-- div is constraint/positioning for contained image -->
    <div class="image-box">
        <xsl:attribute name="style">
            <xsl:text>width: </xsl:text>
            <xsl:value-of select="$layout/width"/>
            <xsl:text>%;</xsl:text>
            <xsl:text> margin-left: </xsl:text>
            <xsl:value-of select="$layout/left-margin"/>
            <xsl:text>%;</xsl:text>
            <xsl:text> margin-right: </xsl:text>
            <xsl:value-of select="$layout/right-margin"/>
            <xsl:text>%;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="image-inclusion"/>
    </div>
</xsl:template>

<xsl:template match="mermaid[ancestor::image]" mode="image-inclusion">
    <pre class="mermaid">
        <xsl:value-of select="." />
    </pre>
</xsl:template>

<!-- The div for a panel of a sidebyside will provide  -->
<!-- the constraint/positioning of the contained image -->
<!-- If the panel is a PTX "figure" then there will be -->
<!-- an intermediate HTML "figure" which will not      -->
<!-- interfere with the panel's constraints            -->
<xsl:template match="image[ancestor::sidebyside]">
    <xsl:apply-templates select="." mode="image-inclusion" />
</xsl:template>

<!-- With a @source attribute, without an extension, -->
<!--   we presume an SVG has been manufactured       -->
<!-- With a @source attribute, with an extension,    -->
<!--   we write an HTML "img" tag with attributes    -->
<xsl:template match="image[@source|@pi:generated]" mode="image-inclusion">
    <!-- condition on file extension -->
    <!-- no period, lowercase'ed     -->
    <xsl:variable name="extension">
        <xsl:call-template name="file-extension">
            <xsl:with-param name="filename">
                <xsl:choose>
                    <xsl:when test="@pi:generated">
                        <xsl:value-of select="@pi:generated"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@source"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <!-- location of image, based on configured directory in publisher file -->
    <xsl:variable name="location">
        <xsl:choose>
            <xsl:when test="@pi:generated">
                <xsl:value-of select="$generated-directory"/>
                <xsl:value-of select="@pi:generated"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- empty when not using managed directories -->
                <xsl:value-of select="$external-directory"/>
                <xsl:value-of select="@source"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <!-- no extension, presume SVG provided as external image -->
        <xsl:when test="$extension=''">
            <xsl:apply-templates select="." mode="svg-png-wrapper">
                <xsl:with-param name="image-filename">
                    <xsl:value-of select="$location"/>
                    <xsl:text>.svg</xsl:text>
                </xsl:with-param>
            </xsl:apply-templates>
            <!-- possibly annotate with archive links -->
            <xsl:apply-templates select="." mode="archive">
                <xsl:with-param name="base-pathname" select="$location"/>
            </xsl:apply-templates>
            <!-- possibly give a long description -->
            <xsl:apply-templates select="." mode="description"/>
        </xsl:when>
        <!-- with extension, just include it -->
        <xsl:otherwise>
            <img>
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                </xsl:attribute>
                <xsl:attribute name="class">
                    <xsl:text>contained</xsl:text>
                </xsl:attribute>
                <!-- alt attribute for accessibility -->
                <xsl:choose>
                    <xsl:when test="@decorative = 'yes'">
                        <xsl:attribute name="alt"/>
                    </xsl:when>
                    <xsl:when test="not(string(shortdescription) = '')">
                        <xsl:attribute name="alt">
                            <xsl:apply-templates select="shortdescription" />
                        </xsl:attribute>
                    </xsl:when>
                    <xsl:when test="description">
                        <xsl:attribute name="alt">
                            <xsl:text>described in detail following the image</xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="aria-describedby">
                            <xsl:apply-templates select="." mode="describedby-id"/>
                        </xsl:attribute>
                    </xsl:when>
                </xsl:choose>
                <xsl:if test="@rotate">
                    <xsl:attribute name="style">
                        <xsl:text>transform: rotate(</xsl:text>
                        <xsl:value-of select="@rotate"/>
                        <xsl:text>deg)</xsl:text>
                    </xsl:attribute>
                </xsl:if>
            </img>
            <!-- possibly annotate with archive links -->
            <xsl:apply-templates select="." mode="archive">
                <xsl:with-param name="base-pathname">
                    <!-- empty when not using managed directories -->
                    <xsl:value-of select="$external-directory"/>
                    <xsl:call-template name="substring-before-last">
                        <xsl:with-param name="input" select="$location" />
                        <xsl:with-param name="substr" select="'.'" />
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:apply-templates>
            <!-- possibly give a long description -->
            <xsl:apply-templates select="." mode="description"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- SVG's produced by pretext/pretext script -->
<!-- Minor variations to be dual-purpose      -->
<!--   LaTeX source code images               -->
<!--   PreFigure source code images           -->
<xsl:template match="image[latex-image]|image[pf:prefigure]" mode="image-inclusion">
    <!-- $base-pathname needed later for archive links -->
    <xsl:variable name="base-pathname">
        <xsl:value-of select="$generated-directory"/>
        <xsl:if test="$b-managed-directories">
            <xsl:choose>
                <xsl:when test="latex-image">
                    <xsl:text>latex-image/</xsl:text>
                </xsl:when>
                <xsl:when test="pf:prefigure">
                    <xsl:text>prefigure/</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
        <!-- NB: node-set in @select will have exactly -->
        <!-- one (child) node, given @match above      -->
        <xsl:apply-templates select="latex-image|pf:prefigure" mode="image-source-basename"/>
    </xsl:variable>
    <!-- Normally the "svg-png-wrapper" will create a "standard" HTML      -->
    <!-- object to hold the image.  For an annotated PreFigure diagram     -->
    <!-- we need a custom embedding for the diagcess JS to act on.  The    -->
    <!-- two files (SVG image, XML annotations) are products of PreFigure. -->

    <xsl:choose>
        <xsl:when test="$b-portable-html and (latex-image|pf:prefigure[not(pf:diagram/pf:annotations)])">
            <xsl:apply-templates select="." mode="svg-embedded"/>
        </xsl:when>
        <xsl:when test="latex-image|pf:prefigure[not(pf:diagram/pf:annotations)]">
            <xsl:apply-templates select="." mode="svg-png-wrapper">
                <xsl:with-param name="image-filename" select="concat($base-pathname, '.svg')" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="pf:prefigure[pf:diagram/pf:annotations]">
            <div class="ChemAccess-element">
                <xsl:attribute name="data-src">
                    <xsl:value-of select="$base-pathname"/>
                    <xsl:text>.svg</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="data-cml">
                    <xsl:value-of select="$base-pathname"/>
                    <xsl:text>-annotations.xml</xsl:text>
                </xsl:attribute>
            </div>
            <!-- a named template provides keyboard shortcuts for  -->
            <!-- the library powering exploration of the PreFigure -->
            <!-- diagram authored with annotations                 -->
            <!-- We defer if we are inside a setting where we      -->
            <!-- might get multiple instances of instructions      -->
            <!-- right next to each other.  This test will include -->
            <!-- being inside a "subsgroup" as well.               -->
            <xsl:if test="not(ancestor::sidebyside)">
                <xsl:call-template name="diagacess-instructions"/>
            </xsl:if>
        </xsl:when>
        <!-- cases should be exhaustive, given match and tests-->
        <xsl:otherwise/>
    </xsl:choose>
    <!-- possibly annotate with archive links -->
    <xsl:apply-templates select="." mode="archive">
        <xsl:with-param name="base-pathname" select="$base-pathname" />
    </xsl:apply-templates>
    <!-- possibly give a long description -->
    <xsl:apply-templates select="." mode="description"/>
</xsl:template>

<xsl:template match="image[sageplot]" mode="image-inclusion">
    <!-- $base-pathname needed later for archive links -->
    <xsl:variable name="base-pathname">
        <xsl:value-of select="$generated-directory"/>
        <xsl:if test="$b-managed-directories">
            <xsl:text>sageplot/</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="sageplot" mode="image-source-basename"/>
    </xsl:variable>
    <!-- 2d are SVG, 3d are HTML -->
    <xsl:choose>
        <xsl:when test="not(sageplot/@variant) or (sageplot/@variant = '2d')">
            <!-- construct the "img" element -->
            <xsl:apply-templates select="." mode="svg-png-wrapper">
                <xsl:with-param name="image-filename" select="concat($base-pathname, '.svg')" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="sageplot/@variant = '3d'">
            <iframe>
                <xsl:apply-templates select="." mode="size-pixels-attributes" />
                <xsl:attribute name="src">
                    <xsl:value-of select="$base-pathname"/>
                    <xsl:text>.html</xsl:text>
                </xsl:attribute>
            </iframe>
        </xsl:when>
        <!-- attribute errors found out in generation? -->
        <xsl:otherwise/>
    </xsl:choose>
    <!-- possibly annotate with archive links -->
    <xsl:apply-templates select="." mode="archive">
        <xsl:with-param name="base-pathname" select="$base-pathname" />
    </xsl:apply-templates>
    <!-- possibly give a long description -->
    <xsl:apply-templates select="." mode="description"/>
</xsl:template>

<!-- Asymptote graphics language -->
<xsl:template match="image[asymptote]" mode="image-inclusion">
    <!-- base-pathname needed later for archive link production. This   -->
    <!-- is the location for eventual output, in contrast to juat below -->
    <!-- for source analysis.                                           -->
    <xsl:variable name="base-pathname">
        <xsl:value-of select="$generated-directory"/>
        <xsl:if test="$b-managed-directories">
            <xsl:text>asymptote/</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="asymptote" mode="image-source-basename"/>
    </xsl:variable>
    <xsl:variable name="html-filename" select="concat($base-pathname, '.html')" />
    <!-- We also need a path to the *source* file, for examination -->
    <!-- to determine the aspect ratio of the diagram, in order to -->
    <!-- insert correctly as a scaled instance                     -->
    <xsl:variable name="html-source-filename">
        <xsl:value-of select="$generated-directory-source"/>
        <xsl:if test="$b-managed-directories">
            <xsl:text>asymptote/</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="asymptote" mode="image-source-basename"/>
        <xsl:text>.html</xsl:text>
    </xsl:variable>
    <!-- Assumes filename is relative to primary source file, -->
    <!-- which must be specified with the original version,   -->
    <!-- not the pre-processed, "assembled" version           -->
    <xsl:variable name="image-xml" select="document($html-source-filename, $original)"/>

    <!-- width first -->
    <xsl:variable name="width">
        <xsl:choose>
            <!-- 2-D diagram -->
            <!-- note necessity of namespace for "svg" element -->
            <xsl:when test="$image-xml/html/body/svg:svg">
                <xsl:variable name="wpt" select="$image-xml/html/body/svg:svg/@width"/>
                <!-- Strip "pt" suffix -->
                <xsl:value-of select="substring($wpt, 1, string-length($wpt) - 2)"/>
            </xsl:when>
            <!-- 3-D diagram -->
            <xsl:when test="$image-xml/html/body/canvas">
                <xsl:value-of select="$image-xml/html/body/canvas/@width"/>
            </xsl:when>
            <!-- failure -->
            <xsl:otherwise>
                <xsl:message>PTX:ERROR:   the Asymptote diagram produced in "<xsl:value-of select="$image-xml"/>" needs to be available relative to the primary source file, or if available it is perhaps ill-formed and its width cannot be determined (which you might report as a bug).  We might be able to proceed as if the diagram is square, but results can be unpredictable.</xsl:message>
                <!-- reasonable guess at points/pixels -->
                <xsl:text>400</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- now height, similarly -->
    <xsl:variable name="height">
        <xsl:choose>
            <!-- 2-D diagram -->
            <!-- note necessity of namespace for "svg" element -->
            <xsl:when test="$image-xml/html/body/svg:svg">
                <xsl:variable name="hpt" select="$image-xml/html/body/svg:svg/@height"/>
                <!-- Strip "pt" suffix -->
                <xsl:value-of select="substring($hpt, 1, string-length($hpt) - 2)"/>
            </xsl:when>
            <!-- 3-D diagram -->
            <xsl:when test="$image-xml/html/body/canvas">
                <xsl:value-of select="$image-xml/html/body/canvas/@height"/>
            </xsl:when>
            <!-- failure -->
            <xsl:otherwise>
                <xsl:message>PTX:ERROR:   the Asymptote diagram produced in "<xsl:value-of select="$image-xml"/>" needs to be available relative to the primary source file, or if available it is perhaps ill-formed and its height cannot be determined (which you might report as a bug).  We might be able to proceed as if the diagram is square, but results can be unpredictable.</xsl:message>
                <!-- reasonable guess at points/pixels -->
                <xsl:text>400</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- All that was to get an aspect-ratio for a responsive iframe embedding -->
    <xsl:variable name="aspect-percent" select="($height div $width) * 100"/>

    <!-- Surrounding/constraining "image", or "sidebyside" panel, or ...    -->
    <!-- will provide an overall width.  The "padding-top" property is what -->
    <!-- makes the right shape.  CSS provides some constant properties.     -->
    <div class="asymptote-box" style="padding-top: {$aspect-percent}%">
        <iframe src="{$html-filename}" class="asymptote"/>
    </div>
    <!-- possibly annotate with archive links -->
    <xsl:apply-templates select="." mode="archive">
        <xsl:with-param name="base-pathname" select="$base-pathname" />
    </xsl:apply-templates>
    <!-- possibly provide link to full size image -->
    <!-- need to set html/asymptote@links="yes" in publisher file to enable -->
    <xsl:if test="$b-asymptote-html-links">
      <xsl:variable name="image-html-url">
          <xsl:value-of select="$baseurl"/>
          <xsl:value-of select="$html-filename"/>
      </xsl:variable>
      <div style="text-align: center;">
        <a href="{$image-html-url}">Link to full-sized image</a>
      </div>
    </xsl:if>
</xsl:template>

<!-- The infrastructure for an SVG or PNG image      -->
<!-- Parameters                                      -->
<!--   image-filename: required, full relative path  -->
<!-- NB: (2020-01-18) Prior, this was SVG specific,  -->
<!-- and then PNG functionality was folded in (when  -->
<!-- fallback for "sageplot" was no longer necessary -->
<xsl:template match="image" mode="svg-png-wrapper">
    <xsl:param name="image-filename" />
    <img>
        <!-- source file attribute for img element, the SVG image -->
        <xsl:attribute name="src">
            <xsl:value-of select="$image-filename" />
        </xsl:attribute>
        <!-- For accessibility use an ARIA role, e.g so screen  -->
        <!-- readers do not try to read the elements of the SVG -->
        <!-- NB: if we write SVG into the page, put this        -->
        <!-- attribute onto the "svg" element                   -->
        <xsl:attribute name="role">
            <xsl:text>img</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="class">
            <xsl:text>contained</xsl:text>
        </xsl:attribute>
        <!-- alt attribute for accessibility -->
        <xsl:choose>
            <xsl:when test="@decorative = 'yes'">
                <xsl:attribute name="alt"/>
            </xsl:when>
            <xsl:when test="shortdescription">
                <xsl:attribute name="alt">
                    <xsl:apply-templates select="shortdescription"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:when test="description">
                <xsl:attribute name="alt">
                    <xsl:text>described in detail following the image</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="aria-describedby">
                    <xsl:apply-templates select="." mode="describedby-id"/>
                </xsl:attribute>
            </xsl:when>
        </xsl:choose>
    </img>
</xsl:template>

<!-- Instead of linking to an svg file as in the modal svg-png-wrapper above  -->
<!-- we can include the svg directly in the html document, which is what      -->
<!-- this does.  Used with b-portable-html is true, at least now (2025-03-04) -->
<xsl:template match="image" mode="svg-embedded">
    <!-- Get the filename of the generated svg file -->
    <xsl:variable name="svg-source-filename">
        <xsl:value-of select="$generated-directory-source" />
        <xsl:if test="$b-managed-directories">
            <xsl:choose>
                <xsl:when test="latex-image">
                    <xsl:text>latex-image/</xsl:text>
                </xsl:when>
                <xsl:when test="pf:prefigure">
                    <xsl:text>prefigure/</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
        <xsl:apply-templates select="latex-image|pf:prefigure" mode="image-source-basename"/>
        <xsl:text>.svg</xsl:text>
    </xsl:variable>
    <!-- Get the SVG file as an XML document -->
    <xsl:variable name="image-svg-xml" select="document($svg-source-filename, $original)" />
    <!-- Create an SVG element with the contents of the SVG file -->
    <svg xmlns="http://www.w3.org/2000/svg">
        <xsl:copy-of select="$image-svg-xml/svg:svg/namespace::*"/>
        <xsl:copy-of select="$image-svg-xml/svg:svg/@version"/>
        <!-- Keep the viewbox, or create one based on the height and width -->
        <xsl:choose>
            <xsl:when test="$image-svg-xml/svg:svg/@viewBox">
                <xsl:attribute name="viewBox">
                    <xsl:value-of select="$image-svg-xml/svg:svg/@viewBox"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="viewBox">
                    <xsl:text>0 0 </xsl:text>
                    <xsl:value-of select="$image-svg-xml/svg:svg/@width"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$image-svg-xml/svg:svg/@height"/>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:copy-of select="$image-svg-xml/svg:svg/@viewBox"/>
        <xsl:attribute name="role">
            <xsl:text>img</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="class">
            <xsl:text>contained</xsl:text>
        </xsl:attribute>
        <xsl:choose>
            <xsl:when test="@decorative = 'yes'">
                <xsl:attribute name="aria-hidden">
                    <xsl:text>true</xsl:text>
                </xsl:attribute>
            </xsl:when>
            <xsl:when test="shortdescription">
                <xsl:attribute name="aria-label">
                    <xsl:apply-templates select="shortdescription"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:when test="description">
                <xsl:attribute name="aria-describedby">
                    <xsl:apply-templates select="." mode="describedby-id"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
        <xsl:if test="shortdescription">
            <title>
                <xsl:apply-templates select="shortdescription"/>
            </title>
        </xsl:if>
        <xsl:if test="description">
            <desc>
                <xsl:apply-templates select="description"/>
            </desc>
        </xsl:if>
        <xsl:apply-templates select="$image-svg-xml/svg:svg/*" mode="svg-unique-ids">
            <xsl:with-param name="svg-unique-id">
                <xsl:value-of select="@unique-id"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </svg>
</xsl:template>

<!-- When embedding multiple svgs in a single page, the ids used     -->
<!-- to refer to svg elements can collide.  This recursively adds    -->
<!-- a unique id (per svg) suffix to all id and xlink:href elements. -->

<xsl:template match="node()|@*" mode="svg-unique-ids">
    <xsl:param name="svg-unique-id"/>
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="svg-unique-ids">
            <xsl:with-param name="svg-unique-id" select="$svg-unique-id"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<xsl:template match="@id|@xlink:href" mode="svg-unique-ids">
    <xsl:param name="svg-unique-id"/>
    <xsl:attribute name="{local-name()}">
        <xsl:value-of select="."/>
        <xsl:text>_</xsl:text>
        <xsl:value-of select="$svg-unique-id"/>
    </xsl:attribute>
</xsl:template>


<xsl:template match="image" mode="description">
    <xsl:if test="description">
        <!-- @aria-live means screenreaders will make announcements -->
        <details class="image-description" aria-live="polite">
            <summary title="details">
                <xsl:call-template name="insert-symbol">
                    <xsl:with-param name="name" select="'info'"/>
                </xsl:call-template>
            </summary>
            <div>
                <xsl:attribute name="id">
                    <xsl:apply-templates select="." mode="describedby-id"/>
                </xsl:attribute>
                <xsl:apply-templates select="description"/>
            </div>
        </details>
    </xsl:if>
</xsl:template>

<!-- Utility template so "aria-describedby" values are consistent -->
<xsl:template match="image" mode="describedby-id">
    <xsl:apply-templates select="." mode="visible-id"/>
    <xsl:text>-description</xsl:text>
</xsl:template>

<!-- Diagacess Instructions -->

<xsl:template name="diagacess-instructions">
    <details>
        <summary>Diagram Exploration Keyboard Controls</summary>
        <div class="diagcess-navigation-controls">
            <table>
            <thead>
            <tr>
            <th>Key</th>
            <th>Action</th>
            </tr>
            </thead>
            <tbody>
            <tr>
            <td>Enter, A</td>
            <td>Activate keyboard driven exploration</td>
            </tr>
            <tr>
            <td>B</td>
            <td>Activate menu driven exploration</td>
            </tr>
            <tr>
            <td>Escape</td>
            <td>Leave exploration mode</td>
            </tr>
            <tr>
            <td>Cursor down</td>
            <td>Explore next lower level</td>
            </tr>
            <tr>
            <td>Cursor up</td>
            <td>Explore next upper level</td>
            </tr>
            <tr>
            <td>Cursor right</td>
            <td>Explore next element on level</td>
            </tr>
            <tr>
            <td>Cursor left</td>
            <td>Explore previous element on level</td>
            </tr>
            <tr>
            <td>X</td>
            <td>Toggle expert mode</td>
            </tr>
            <tr>
            <td>W</td>
            <td>Extra details if available</td>
            </tr>
            <tr>
            <td>Space</td>
            <td>Repeat speech</td>
            </tr>
            <tr>
            <td>M</td>
            <td>Activate step magnification</td>
            </tr>
            <tr>
            <td>Comma</td>
            <td>Activate direct magnification</td>
            </tr>
            <tr>
            <td>N</td>
            <td>Deactivate magnification</td>
            </tr>
            <tr>
            <td>Z</td>
            <td>Toggle subtitles</td>
            </tr>
            <tr>
            <td>C</td>
            <td>Cycle contrast settings</td>
            </tr>
            <tr>
            <td>T</td>
            <td>Monochrome colours</td>
            </tr>
            <tr>
            <td>L</td>
            <td>Toggle language (if available)</td>
            </tr>
            <tr>
            <td>K</td>
            <td>Kill current sound</td>
            </tr>
            <tr>
            <td>Y</td>
            <td>Stop sound output</td>
            </tr>
            <tr>
            <td>O</td>
            <td>Start and stop sonification</td>
            </tr>
            <tr>
            <td>P</td>
            <td>Repeat sonification output</td>
            </tr>
            </tbody>
            </table>
        </div>
    </details>
</xsl:template>


<!-- Image Archives -->
<!-- Under an image provide a set of (download) links              -->
<!-- for archival versions of the image in different formats       -->
<!--                                                               -->
<!-- 1.  @archive is a space-delimited list of file suffixes       -->
<!-- 2.  Author must ensure the versions are next to file employed -->
<!-- 3.  Formatting and case of suffixes is author's choice        -->
<!-- 4.  Order in suffix list is respected in output               -->
<!-- 5.  Per-image, with global spec in "docinfo/images/archive"   -->
<!--                                                               -->
<!-- The originating image template knows/computes the filename,   -->
<!-- so this template accepts the filename, sans period and        -->
<!-- extension, to transmit to the actual link production where    -->
<!-- different extensions are added                                -->
<!--                                                               -->
<xsl:template match="image" mode="archive">
    <xsl:param name="base-pathname" />
    <!-- Determine requested archive links            -->
    <!-- Local request on image overrides global      -->
    <!-- If $formats ends empty, then nothing happens -->
    <xsl:variable name="formats">
        <xsl:choose>
            <!-- local, given on image, including suppression -->
            <xsl:when test="@archive">
                <xsl:value-of select="normalize-space(@archive)" />
            </xsl:when>
            <!-- semi-local, semi-global via subtree specification     -->
            <!-- last in list that contains the image wins             -->
            <!-- Documented heavily as first "mid-range" specification -->
            <!-- A single @from puts us in mid-range mode              -->
            <xsl:when test="$docinfo/images/archive[@from]">
                <!-- context of next "select" filters is "archive" -->
                <!-- so save off the present context, the "image"  -->
                <xsl:variable name="the-image" select="." />
                <!-- Filter all of the "archive" in docinfo with @from      -->
                <!-- Subset occurs in document order                        -->
                <!-- Form two subtrees of all desendant nodes, rooted at    -->
                <!--   (1) the image node                                   -->
                <!--   (2) the node pointed to by @from                     -->
                <!-- The pipe forms a union of the nodes in the subtrees    -->
                <!-- "image" is on the subtree @from iff union is no larger -->
                <xsl:variable name="containing-archives"
                    select="$docinfo/images/archive[@from][count($the-image/descendant-or-self::node()|id(@from)/descendant-or-self::node())=count(id(@from)/descendant-or-self::node())]" />
                <!-- We mimic XSL and the last applicable "archive" is effective -->
                <!-- This way, big subtrees go first, included subtrees refine   -->
                <!-- @from can be an empty string and turn off the behavior      -->
                <!-- We grab the content of the last "archive" to be the formats -->
                <xsl:value-of select="$containing-archives[last()]/." />
            </xsl:when>
            <!-- global, presumes one only, ignores subtree versions -->
            <xsl:when test="$docinfo/images/archive[not(@from)]">
                <xsl:value-of select="normalize-space($docinfo/images/archive)" />
            </xsl:when>
            <!-- nothing begets nothing -->
            <xsl:otherwise />
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="not($formats = '')">
        <!-- Build the links with recursion through formats    -->
        <!-- First wrap resulting links in overall styling div -->
        <xsl:element name="div">
            <xsl:attribute name="class">
                <xsl:text>image-archive</xsl:text>
            </xsl:attribute>
            <!-- Add trailing space as marker for recursion finale -->
            <xsl:call-template name="archive-links">
                <xsl:with-param name="base-pathname" select="$base-pathname" />
                <xsl:with-param name="formats" select="concat($formats, ' ')" />
            </xsl:call-template>
        </xsl:element>
    </xsl:if>
</xsl:template>

<!-- $base-pathname has no concluding -->
<!-- period, so we add it here        -->
<xsl:template name="archive-links">
    <xsl:param name="base-pathname" />
    <xsl:param name="formats" />
    <!-- stop recursion if empty (note extra space added in initial call) -->
    <xsl:if test="not($formats = '')">
        <xsl:variable name="next-format" select="substring-before($formats, ' ')" />
        <xsl:variable name="remaining-formats" select="substring-after($formats, ' ')" />
        <!-- link to the file, author's responsibility  -->
        <!-- add period, and the suffix to rest of path -->
        <!-- text of link is the format suffix verbatim -->
        <xsl:element name="a">
            <xsl:attribute name="href">
                <xsl:value-of select="$base-pathname" />
                <xsl:text>.</xsl:text>
                <xsl:value-of select="$next-format" />
            </xsl:attribute>
            <xsl:value-of select="$next-format" />
        </xsl:element>
        <!-- recurse through remaining formats -->
        <xsl:call-template name="archive-links">
            <xsl:with-param name="base-pathname" select="$base-pathname" />
            <xsl:with-param name="formats" select="$remaining-formats" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>


<!-- ################## -->
<!-- SideBySide Layouts -->
<!-- ################## -->

<!-- See xsl/pretext-common.xsl for descriptions of the  -->
<!-- four modal templates which must be implemented here  -->
<!-- The main templates for "sidebyside" and "sbsgroup"   -->
<!-- are in xsl/pretext-common.xsl, as befits containers -->


<xsl:template name="sbsgroup-wrapper">
    <xsl:param name="sbsgroup-content"/>
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>sbsgroup</xsl:text>
        </xsl:attribute>
        <xsl:copy-of select="$sbsgroup-content"/>
    </xsl:element>
</xsl:template>

<!-- When we use CSS margins (or padding), then percentage        -->
<!-- widths are relative to the remaining space.  This utility    -->
<!-- takes in a width relative to full-text-width and the margins -->
<!-- (both with "%" attached) and returns the larger percentage   -->
<!-- of the remaining space.                                      -->
<xsl:template name="relative-width">
    <xsl:param name="width" />
    <xsl:param name="left-margin" />
    <xsl:param name="right-margin" />
    <xsl:value-of select="(100 * substring-before($width, '%')) div (100 - substring-before($left-margin, '%') - substring-before($right-margin, '%'))" />
    <xsl:text>%</xsl:text>
</xsl:template>

<!-- generic "panel-panel" template            -->
<!-- makes a "sbspanel" div of specified width -->
<!-- calls modal "panel-html-box" for contents -->
<!-- fixed-width class is additional           -->
<xsl:template match="*" mode="panel-panel">
    <xsl:param name="b-original" select="true()" />

    <xsl:param name="width" />
    <xsl:param name="left-margin" />
    <xsl:param name="right-margin" />
    <xsl:param name="valign" />
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>sbspanel</xsl:text>
            <xsl:if test="self::table or self::tabular">
                <xsl:text> fixed-width</xsl:text>
            </xsl:if>
            <!-- assumes "sbspanel" class set vertical direction -->
            <!-- the CSS class equals the source attribute, but that may change -->
            <xsl:choose>
                <xsl:when test="$valign = 'top'">
                    <xsl:text> sbspanel--top top</xsl:text>
                </xsl:when>
                <xsl:when test="$valign = 'middle'">
                    <xsl:text> sbspanel--middle middle</xsl:text>
                </xsl:when>
                <xsl:when test="$valign = 'bottom'">
                    <xsl:text> sbspanel--bottom bottom</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:attribute>
        <xsl:attribute name="style">
            <xsl:if test="$sbsdebug">
                <xsl:text>box-sizing: border-box;</xsl:text>
                <xsl:text>-moz-box-sizing: border-box;</xsl:text>
                <xsl:text>-webkit-box-sizing: border-box;</xsl:text>
                <xsl:text>border: 2px solid black;</xsl:text>
            </xsl:if>
        </xsl:attribute>
        <!-- Realize each panel's object -->
        <xsl:apply-templates select=".">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="width" select="$width" />
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

<!-- We take in all three rows and package       -->
<!-- them up inside an overriding "sidebyside"   -->
<!-- div containing three "sbsrow" divs.  Purely -->
<!--  a container, never a target, so no xml:id  -->
<!-- in source, so no HTML id on div.sidebyside  -->
<xsl:template match="sidebyside" mode="compose-panels">
    <xsl:param name="layout" />
    <xsl:param name="panels" />

    <xsl:variable name="left-margin"  select="$layout/left-margin" />
    <xsl:variable name="right-margin" select="$layout/right-margin" />

    <xsl:variable name="column-widths">
        <xsl:for-each select="$layout/width">
            <xsl:call-template name="relative-width">
                <xsl:with-param name="width" select="." />
                <xsl:with-param name="left-margin"  select="$left-margin" />
                <xsl:with-param name="right-margin" select="$right-margin" />
            </xsl:call-template>
            <xsl:if test="following-sibling::width">
                <xsl:text> </xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>

    <!-- A "sidebyside" div, to contain headers, -->
    <!-- panels, captions rows as "sbsrow" divs  -->
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>sidebyside</xsl:text>
        </xsl:attribute>
        <xsl:if test="$sbsdebug">
            <xsl:attribute name="style">
                <xsl:text>box-sizing: border-box;</xsl:text>
                <xsl:text>-moz-box-sizing: border-box;</xsl:text>
                <xsl:text>-webkit-box-sizing: border-box;</xsl:text>
                <xsl:text>border: 2px solid purple;</xsl:text>
            </xsl:attribute>
        </xsl:if>

        <!-- Panels in an "sbsrow" div, always -->
        <xsl:element name="div">
            <xsl:attribute name="class">
                <xsl:text>sbsrow</xsl:text>
            </xsl:attribute>
            <!-- margins are custom from source -->
            <xsl:attribute name="style">
                <xsl:text>margin-left:</xsl:text>
                <xsl:value-of select="$left-margin" />
                <xsl:text>;</xsl:text>
                <xsl:text>margin-right:</xsl:text>
                <xsl:value-of select="$right-margin" />
                <xsl:text>;</xsl:text>
                <xsl:text>grid-template-columns:</xsl:text>
                <xsl:value-of select="$column-widths" />
                <xsl:text>;</xsl:text>
                <xsl:text>column-gap:</xsl:text>
                <xsl:value-of select="$layout/space-width" />
                <xsl:text>;</xsl:text>
                <xsl:if test="$sbsdebug">
                    <xsl:text>box-sizing: border-box;</xsl:text>
                    <xsl:text>-moz-box-sizing: border-box;</xsl:text>
                    <xsl:text>-webkit-box-sizing: border-box;</xsl:text>
                    <xsl:text>border: 2px solid green;</xsl:text>
                    <xsl:text>background: LightGray;</xsl:text>
                    <xsl:text>background-clip: content-box;</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <xsl:copy-of select="$panels" />
        </xsl:element>

    </xsl:element>
</xsl:template>

<!-- We do not want a proliferation of instructions for keyboard        -->
<!-- shortciuts for exploring PreFigure diagrams with the diagacess     -->
<!-- library.  See hooks for "sidebyside" and "sbsgroup" explained      -->
<!-- in pretext-common.xsl.  Logic here is to follow a "sidebyside"     -->
<!-- with any one panel holding an explorable diagram, unless it is     -->
<!-- a constituent of a "sbsgroup".  Once at the conclusion of a        -->
<!-- "sbsgroup" it is time to present instructions.  Note that these    -->
<!-- instructions are routinely held up right after a diagram in        -->
<!-- these scenarios.                                                   -->
<!-- NB: we tried to add these instructions after an "apply-imports"    -->
<!-- in new templates overriding those in -common, but it appears we    -->
<!-- cannot pass parameters in, so duplicate content inside             -->
<!-- "sidebyside" (such as formulated for xref knowls) ended up getting -->
<!-- duplicate HTML id.  So we had to resort to specialty hooks.        -->

<xsl:template match="sidebyside" mode="post-sidebyside">
    <xsl:if test=".//pf:annotations and not(parent::sbsgroup)">
        <xsl:call-template name="diagacess-instructions"/>
    </xsl:if>
</xsl:template>

<xsl:template match="sbsgroup" mode="post-sbsgroup">
    <xsl:if test=".//pf:annotations">
        <xsl:call-template name="diagacess-instructions"/>
    </xsl:if>
</xsl:template>


<!-- ############# -->
<!-- Audio & Video -->
<!-- ############# -->

<!-- Audio and video are similar enough that we share    -->
<!-- some routines under the general heading of "media", -->
<!-- or else we present them here alongside, due to the  -->
<!-- similarities.                                       -->

<xsl:template match="video">
    <!-- This is an RTF of the object, it is important that it returns -->
    <!-- 100% width as default, so when the object is in an enclosing  -->
    <!-- "sidebyside" only the @aspect is on the object and hence a    -->
    <!-- $layout/height is computed properly.                          -->
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters">
            <xsl:with-param name="default-aspect" select="'16:9'"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
    <!-- div is constraint/positioning for contained video   -->
    <!-- Use of "padding-top" for responsive iframes is from -->
    <!-- https://davidwalsh.name/responsive-iframes          -->
    <div class="video-box">
        <xsl:attribute name="style">
            <xsl:text>width: </xsl:text>
            <xsl:value-of select="$layout/width"/>
            <xsl:text>%;</xsl:text>
            <!-- surrogate for height, except on Runestone -->
            <xsl:if test="not($b-host-runestone and @youtube)">
                <xsl:text>padding-top: </xsl:text>
                <xsl:value-of select="$layout/height"/>
                <xsl:text>%;</xsl:text>
            </xsl:if>
            <xsl:text> margin-left: </xsl:text>
            <xsl:value-of select="$layout/left-margin"/>
            <xsl:text>%;</xsl:text>
            <xsl:text> margin-right: </xsl:text>
            <xsl:value-of select="$layout/right-margin"/>
            <xsl:text>%;</xsl:text>
        </xsl:attribute>
        <xsl:choose>
            <xsl:when test="$b-host-runestone and @youtube">
                <!-- we compute pixels in the parameter value, which become   -->
                <!-- YT-specific attributes, so we can't use general template -->
                <!-- providing standard attributes                            -->
                <xsl:apply-templates select="." mode="runestone-youtube-embed">
                    <xsl:with-param name="width" select="($layout/width * $design-width) div 100"/>
                    <xsl:with-param name="height" select="($layout/height * $design-width) div 100"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="media-embed"/>
            </xsl:otherwise>
        </xsl:choose>
    </div>
    <!-- Always build a standalone page, PDF links to these -->
    <!-- The only exception is when building portable html  -->
    <xsl:if test="not($b-portable-html)">
        <xsl:apply-templates select="." mode="media-standalone-page" />
    </xsl:if>
</xsl:template>

<xsl:template match="audio">
    <!-- This is an RTF of the object, it is important that it returns -->
    <!-- 100% width as default, so when the object is in an enclosing  -->
    <!-- "sidebyside" it fills the panel.                              -->
    <!-- Note: we may want to support images as posters, so we may  -->
    <!-- want to support an aspect-ratio, or perhaps the image will -->
    <!-- define the size?                                           -->
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters"/>
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
    <!-- div is constraint/positioning for contained audio -->
    <div class="audio-box">
        <xsl:attribute name="style">
            <xsl:text>width: </xsl:text>
            <xsl:value-of select="$layout/width"/>
            <xsl:text>%;</xsl:text>
            <xsl:text> margin-left: </xsl:text>
            <xsl:value-of select="$layout/left-margin"/>
            <xsl:text>%;</xsl:text>
            <xsl:text> margin-right: </xsl:text>
            <xsl:value-of select="$layout/right-margin"/>
            <xsl:text>%;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="media-embed"/>
    </div>
    <!-- Always build a standalone page, PDF links to these -->
    <!-- (except when building portable html)               -->
    <xsl:if test="not($b-portable-html)">
        <xsl:apply-templates select="." mode="media-standalone-page" />
    </xsl:if>
</xsl:template>

<!-- Formerly a "pop-out" page, now a "standalone" page     -->
<!-- Has autoplay on since a reader has elected to go there -->
<!-- TODO: override preview, since it just plays, pass 'default -->
<xsl:template match="audio|video" mode="media-standalone-page">
    <xsl:apply-templates select="." mode="standalone-page">
        <xsl:with-param name="content">
            <!-- display preview, and enable autoplay  -->
            <!-- since reader has elected this page    -->
            <div style="text-align: center;">Reloading this page will reset a start location</div>
            <div>
                <xsl:attribute name="class">
                    <xsl:choose>
                        <xsl:when test="self::audio">
                            <xsl:text>audio-box</xsl:text>
                        </xsl:when>
                        <xsl:when test="self::video">
                            <xsl:text>video-box</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:attribute name="style">
                    <xsl:text>width: </xsl:text>
                    <xsl:text>100%;</xsl:text>
                    <xsl:if test="self::video">
                        <xsl:variable name="rtf-layout">
                            <xsl:apply-templates select="." mode="layout-parameters">
                                <xsl:with-param name="default-aspect" select="'16:9'"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
                        <!-- get back the aspect ratio via height and width of layout, -->
                        <!-- which are both defined for a video (but not an audio)     -->
                        <!-- Pairs with 100% width above                               -->
                        <xsl:variable name="height-percent" select="100 * ($layout/height div $layout/width)"/>
                        <xsl:text>padding-top: </xsl:text>
                        <xsl:value-of select="$height-percent"/>
                        <xsl:text>%;</xsl:text>
                    </xsl:if>
                </xsl:attribute>
                <xsl:apply-templates select="." mode="media-embed">
                    <xsl:with-param name="preview" select="'false'" />
                    <xsl:with-param name="autoplay" select="'true'" />
                </xsl:apply-templates>
            </div>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- A "Standalone" Page -->
<!-- Formerly a "pop-out" page, now a "standalone" page    -->
<!-- (A bit rough - this could be improved, consolidated)  -->
<!-- no extra libraries, no sidebar                        -->
<!-- 840px available (~900 - 2*30)                         -->
<!-- Page's  filename comes from modal template on context -->
<!-- TODO:  one page template, super-parameterized      -->
<!-- TODO:  trash navigation further in masthead        -->
<!-- TODO:  replace libraries by hooks to add some back -->
<xsl:template match="*" mode="standalone-page">
    <xsl:param name="content" select="''" />
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="standalone-filename" />
    </xsl:variable>
    <exsl:document href="{$filename}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
        <xsl:call-template name="converter-blurb-html-no-date"/>
        <html>
            <xsl:call-template name="language-attributes"/>
            <xsl:call-template name="pretext-advertisement-and-style"/>
            <!-- Open Graph Protocol only in "meta" elements, within "head" -->
            <head xmlns:og="http://ogp.me/ns#" xmlns:book="https://ogp.me/ns/book#">
                <title>
                    <!-- Leading with initials is useful for small tabs -->
                    <xsl:if test="$docinfo/initialism">
                        <xsl:apply-templates select="$docinfo/initialism" />
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="title-plain" />
                </title>
                <!-- canonical link for better SEO -->
                <xsl:call-template name="canonical-link">
                    <xsl:with-param name="filename" select="$filename"/>
                </xsl:call-template>
                <!-- grab the contents every page gets -->
                <xsl:copy-of select="$file-wrap-basic-head-cache"/>
                <!-- now do anything that is or could be page-specific and comes after cache -->
                <xsl:apply-templates select="." mode="knowl" />
            </head>
            <body>
                <!-- potential document-id per-page -->
                <xsl:call-template name="document-id"/>
                <!-- React flag -->
                <xsl:call-template name="react-in-use-flag"/>
                <!-- the first class controls the default icon -->
                <xsl:attribute name="class">
                    <xsl:choose>
                        <xsl:when test="$root/book">pretext book</xsl:when>
                        <xsl:when test="$root/article">pretext article</xsl:when>
                    </xsl:choose>
                    <!-- ignore MathJax signals everywhere, then enable selectively -->
                    <xsl:text> ignore-math</xsl:text>
                </xsl:attribute>
                <!-- assistive "Skip to main content" link    -->
                <!-- this *must* be first for maximum utility -->
                <xsl:call-template name="skip-to-content-link" />
                <xsl:apply-templates select="." mode="primary-navigation"/>
                <xsl:call-template name="latex-macros" />
                <xsl:call-template name="enable-editing" />
                 <header id="ptx-masthead" class="ptx-masthead">
                    <div class="ptx-banner">
                        <xsl:call-template name="brand-logo" />
                        <div class="title-container">
                            <h1 class="heading">
                                <xsl:variable name="root-filename">
                                    <xsl:apply-templates select="$document-root" mode="containing-filename" />
                                </xsl:variable>
                                <a href="{$root-filename}">
                                    <xsl:variable name="b-has-subtitle" select="boolean($document-root/subtitle)"/>
                                    <span class="title">
                                        <!-- Do not use shorttitle in masthead,  -->
                                        <!-- which is much like cover of a book  -->
                                        <xsl:apply-templates select="$document-root" mode="title-simple" />
                                    </span>
                                    <xsl:if test="$b-has-subtitle">
                                        <xsl:text> </xsl:text>
                                        <span class="subtitle">
                                            <xsl:apply-templates select="$document-root" mode="subtitle" />
                                        </span>
                                    </xsl:if>
                                </a>
                            </h1>
                            <!-- Serial list of authors/editors -->
                            <p class="byline">
                                <xsl:apply-templates select="$bibinfo/author" mode="name-list"/>
                                <xsl:apply-templates select="$bibinfo/editor" mode="name-list"/>
                            </p>
                        </div>  <!-- title-container -->
                    </div> <!-- banner -->
                    <!-- This seemed to not be enough, until Google Search went away  -->
                    <!-- <xsl:apply-templates select="." mode="primary-navigation" /> -->
                </header> <!-- masthead -->
                <div class="ptx-page">
                    <!-- With sidebars killed, this stuff is extraneous     -->
                    <!-- <xsl:apply-templates select="." mode="sidebars" /> -->
                    <main class="ptx-main">
                        <!-- relax the 600px width restriction, so with    -->
                        <!-- responsive videos they grow to be much bigger -->
                        <div id="ptx-content" class="ptx-content" style="max-width: 1600px">
                            <!-- This is content passed in as a parameter -->
                            <xsl:copy-of select="$content" />
                          </div>
                    </main>
                </div>
                <xsl:copy-of select="$file-wrap-basic-endbody-cache"/>
            </body>
        </html>
    </exsl:document>
</xsl:template>

<xsl:template name="generic-preview-svg">
    <!-- viewbox was square (0,0), 96x96, now clipped 14 above and below                   -->
    <!-- preserveAspectRatio="none" makes it amenable to matching video it hides           -->
    <!-- SVG scaling, comprehensive: https://css-tricks.com/scale-svg/                     -->
    <!-- Accessed: 2017-08-08                                                              -->
    <!-- Page: https://commons.wikimedia.org/wiki/File:YouTube_Play_Button.svg             -->
    <!-- File: https://upload.wikimedia.org/wikipedia/commons/d/d1/YouTube_Play_Button.svg -->
    <!-- License text:  This image only consists of simple geometric shapes or text.       -->
    <!-- It does not meet the threshold of originality needed for copyright protection,    -->
    <!-- and is therefore in the public domain.                                            -->
    <!-- See  xsl/support/play-button/README.md  for a description of the static version   -->
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 14 96 68" style="cursor:pointer; position: absolute; top: 0; left: 0; width: 100%; height: 100%;" preserveAspectRatio="none">
        <path fill="#e62117" d="M94.98,28.84c0,0-0.94-6.6-3.81-9.5c-3.64-3.81-7.72-3.83-9.59-4.05c-13.4-0.97-33.52-0.85-33.52-0.85s-20.12-0.12-33.52,0.85c-1.87,0.22-5.95,0.24-9.59,4.05c-2.87,2.9-3.81,9.5-3.81,9.5S0.18,36.58,0,44.33v7.26c0.18,7.75,1.14,15.49,1.14,15.49s0.93,6.6,3.81,9.5c3.64,3.81,8.43,3.69,10.56,4.09c7.53,0.72,31.7,0.89,32.54,0.9c0.01,0,20.14,0.03,33.54-0.94c1.87-0.22,5.95-0.24,9.59-4.05c2.87-2.9,3.81-9.5,3.81-9.5s0.96-7.75,1.02-15.49v-7.26C95.94,36.58,94.98,28.84,94.98,28.84z M38.28,61.41v-27l25.74,13.5L38.28,61.41z"/>
    </svg>
</xsl:template>

<!-- Take <svg> element above, remove width and height attributes  -->
<!-- (not ever needed???), compact to one long string.             -->
<!-- URL encode via: https://meyerweb.com/eric/tools/dencoder/     -->
<!-- Then add a bit of voodoo, and this may be used as the value   -->
<!-- of the HTML5 video/@poster attribute (and other places?)      -->
<xsl:variable name="generic-preview-svg-data-uri">
    <xsl:text>data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%2014%2096%2068%22%20style%3D%22cursor%3Apointer%3B%22%20preserveAspectRatio%3D%22none%22%3E%3Cpath%20fill%3D%22%23e62117%22%20d%3D%22M94.98%2C28.84c0%2C0-0.94-6.6-3.81-9.5c-3.64-3.81-7.72-3.83-9.59-4.05c-13.4-0.97-33.52-0.85-33.52-0.85s-20.12-0.12-33.52%2C0.85c-1.87%2C0.22-5.95%2C0.24-9.59%2C4.05c-2.87%2C2.9-3.81%2C9.5-3.81%2C9.5S0.18%2C36.58%2C0%2C44.33v7.26c0.18%2C7.75%2C1.14%2C15.49%2C1.14%2C15.49s0.93%2C6.6%2C3.81%2C9.5c3.64%2C3.81%2C8.43%2C3.69%2C10.56%2C4.09c7.53%2C0.72%2C31.7%2C0.89%2C32.54%2C0.9c0.01%2C0%2C20.14%2C0.03%2C33.54-0.94c1.87-0.22%2C5.95-0.24%2C9.59-4.05c2.87-2.9%2C3.81-9.5%2C3.81-9.5s0.96-7.75%2C1.02-15.49v-7.26C95.94%2C36.58%2C94.98%2C28.84%2C94.98%2C28.84z%20M38.28%2C61.41v-27l25.74%2C13.5L38.28%2C61.41z%22%2F%3E%3C%2Fsvg%3E</xsl:text>
</xsl:variable>

<!-- LaTeX watermark uses default 5cm font which is then scaled by watermark.scale -->
<!-- We copy that here. We also copy the 45 degree angle.                          -->
<!-- Color rgb(204,204,204) matches LaTeX 80% grayscale.                           -->
<xsl:variable name="watermark-svg">
    <svg xmlns="http://www.w3.org/2000/svg" version="1.1" height="600" width="600">
        <text x="50%" y="50%" text-anchor="middle" transform="rotate(-45,300,300)" fill="rgb(204,204,204)" style="font-family:sans-serif; font-size:{5*$watermark-scale}cm;">
            <xsl:value-of select="$watermark-text"/>
        </text>
    </svg>
</xsl:variable>

<xsl:variable name="watermark-css">
    <xsl:text>background-image:url('data:image/svg+xml;charset=utf-8,</xsl:text>
    <xsl:apply-templates select="exsl:node-set($watermark-svg)" mode="xml-to-string">
        <!-- as-authored-source to preserve namespace on svg -->
        <xsl:with-param name="as-authored-source" select="true()"/>
    </xsl:apply-templates>
    <xsl:text>');</xsl:text>
    <xsl:text>background-position:center top;background-repeat:repeat-y;</xsl:text>
</xsl:variable>

<!-- NB: here, and elesewhere, references -->
<!-- to "video" should become "media"     -->
<xsl:template match="audio[@source|@href]" mode="media-embed">
    <xsl:param name="preview" select="'false'" />
    <xsl:param name="autoplay" select="'false'" />

    <xsl:variable name="location">
        <xsl:choose>
            <xsl:when test="@href">
                <xsl:value-of select="@href"/>
            </xsl:when>
            <!-- Now, must have a @source. For backwards -->
            <!-- compatibility, consider a @source that  -->
            <!-- really appears to be a @href. Might be  -->
            <!-- http or https.                          -->
            <xsl:when test="substring(@source,1,4) = 'http'">
                <xsl:value-of select="@source"/>
            </xsl:when>
            <!-- else a local filename in @source -->
            <xsl:otherwise>
                <!-- empty when not using managed directories -->
                <xsl:value-of select="$external-directory"/>
                <xsl:value-of select="@source"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:element name="audio">
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <xsl:attribute name="class">
            <xsl:text>audio</xsl:text>
        </xsl:attribute>
        <!-- empty forms work as boolean switches -->
        <xsl:attribute name="controls"/>
        <xsl:if test="$autoplay = 'true'">
            <xsl:attribute name="autoplay" />
        </xsl:if>
        <!-- @poster, or equivalent does not seem trivial -->
        <!-- Construct the HTML5 source URL(s)                  -->
        <!-- If this gets refactored, it could be best to form  -->
        <!-- base, extension, query, fragment strings/variables -->
        <!-- First, grab extension of source URL in PTX @source -->
        <xsl:variable name="extension">
            <xsl:call-template name="file-extension">
                <xsl:with-param name="filename" select="$location" />
            </xsl:call-template>
        </xsl:variable>
        <!-- "source" elements, children of HTML5 audio -->
        <!-- no extension suggests hosting has multiple -->
        <!-- versions for browser to sort through       -->
        <!-- More open formats first!  ;-)              -->
        <xsl:if test="$extension = '' or $extension = 'ogg'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.ogg</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="temporal-fragment"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>audio/ogg</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <xsl:if test="$extension = '' or $extension = 'mp3'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.mp3</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="temporal-fragment"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>audio/mp3</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <xsl:if test="$extension = '' or $extension = 'wav'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.wav</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="temporal-fragment"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>audio/wav</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <!-- failure to perform -->
        <xsl:text>Your browser does not support the &lt;audio&gt; tag.</xsl:text>
    </xsl:element>
</xsl:template>

<!-- create a "video" element for author-hosted   -->
<!-- dimensions and autoplay as parameters        -->
<!-- Normally $preview is true, and not passed in -->
<!-- 'false' is an override for standalone pages  -->
<xsl:template match="video[@source|@href]" mode="media-embed">
    <xsl:param name="preview" select="'true'" />
    <xsl:param name="autoplay" select="'false'" />

    <xsl:variable name="location">
        <xsl:choose>
            <xsl:when test="@href">
                <xsl:value-of select="@href"/>
            </xsl:when>
            <!-- Now, must have a @source. For backwards -->
            <!-- compatibility, consider a @source that  -->
            <!-- really appears to be a @href. Might be  -->
            <!-- http or https.                          -->
            <xsl:when test="substring(@source,1,4) = 'http'">
                <xsl:value-of select="@source"/>
            </xsl:when>
            <!-- else a local filename in @source -->
            <xsl:otherwise>
                <!-- empty when not using managed directories -->
                <xsl:value-of select="$external-directory"/>
                <xsl:value-of select="@source"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>


    <!-- we need to build the element, since @autoplay is optional -->
    <xsl:element name="video">
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <xsl:attribute name="class">
            <xsl:text>video</xsl:text>
        </xsl:attribute>
        <!-- empty forms work as boolean switches -->
        <xsl:attribute name="controls" />
        <xsl:if test="$autoplay = 'true'">
            <xsl:attribute name="autoplay" />
        </xsl:if>
        <!-- Optionally cover up with HTML5 @poster via PTX @preview -->
        <xsl:if test="($preview = 'true') and @preview and not(@preview = 'default')">
            <xsl:attribute name="poster">
                <xsl:choose>
                    <xsl:when test="@preview = 'generic'">
                        <xsl:value-of select="$generic-preview-svg-data-uri" />
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- empty when not using managed directories -->
                        <xsl:value-of select="$external-directory"/>
                        <xsl:value-of select="@preview" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </xsl:if>
        <!-- Construct the HTML5 source URL(s)                  -->
        <!-- If this gets refactored, it could be best to form  -->
        <!-- base, extension, query, fragment strings/variables -->
        <!-- First, grab extension of source URL in PTX @source -->
        <xsl:variable name="extension">
            <xsl:call-template name="file-extension">
                <xsl:with-param name="filename" select="$location" />
            </xsl:call-template>
        </xsl:variable>
        <!-- "source" elements, children of HTML5 video -->
        <!-- no extension suggests hosting has multiple -->
        <!-- versions for browser to sort through       -->
        <!-- More open formats first!  ;-)              -->
        <xsl:if test="$extension = '' or $extension = 'ogv'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.ogv</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="temporal-fragment"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>video/ogg</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <xsl:if test="$extension = '' or $extension = 'webm'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.webm</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="temporal-fragment"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>video/webm</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <xsl:if test="$extension = '' or $extension = 'mp4'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.mp4</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="temporal-fragment"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>video/mp4</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <!-- 2007: *.oog officially replaced by *.ogv    -->
        <!-- 2018-04-01: we supported *.oog for video at -->
        <!--    91028991e081d2c933d46d3ce5d4d1cb6759c0bf -->
        <!-- 2020-07-05: demoted, but continue support   -->
        <xsl:if test="$extension = '' or $extension = 'oog'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.ogg</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="temporal-fragment"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>video/ogg</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <!-- failure to perform -->
        <xsl:text>Your browser does not support the &lt;video&gt; tag.</xsl:text>
        <xsl:apply-templates select="track"/>
    </xsl:element>
</xsl:template>


<!-- This an optional component of an author-hosted video, -->
<!-- and the markup closely tracks the generated HTML.     -->
<!-- The exception being our @listing; @label is taken.    -->
<!-- The HTML @default attribute functions simply by being -->
<!-- present, so we do not provide a value.                -->
<xsl:template match="track">
    <xsl:variable name="location">
        <!-- empty when not using managed directories -->
        <xsl:value-of select="$external-directory"/>
        <xsl:value-of select="@source"/>
    </xsl:variable>

    <track>
        <xsl:if test="@default='yes'">
            <xsl:attribute name="default"/>
        </xsl:if>
        <xsl:attribute name="label">
            <xsl:value-of select="@listing"/>
        </xsl:attribute>
        <xsl:attribute name="kind">
            <xsl:value-of select="@kind"/>
        </xsl:attribute>
        <xsl:attribute name="srclang">
            <xsl:value-of select="@xml:lang"/>
        </xsl:attribute>
        <xsl:attribute name="src">
            <xsl:value-of select="$location"/>
        </xsl:attribute>
    </track>
</xsl:template>

<!-- HTML5 Media Fragment URI (shared for audio, video)       -->
<!-- start/end times (read both, see 4.1, 4.2.1 at w3.org)    -->
<!-- Media Fragment URI: https://www.w3.org/TR/media-frags/   -->
<!-- Javascript: https://stackoverflow.com/questions/11212715 -->
<!-- return is possibly empty, so no harm using that later    -->
<!-- This portion of URL should follow any query string       -->
<xsl:template match="audio|video" mode="temporal-fragment">
    <xsl:if test="@start or @end">
        <xsl:text>#t=</xsl:text>
    </xsl:if>
    <xsl:if test="@start">
        <xsl:value-of select="@start" />
    </xsl:if>
    <!-- can lead with comma, implies 0,xx -->
    <xsl:if test="@end">
        <xsl:text>,</xsl:text>
        <xsl:value-of select="@end" />
    </xsl:if>
</xsl:template>

<!-- You Tube, Vimeo -->
<!-- Better sizing would require CSS classes (16:9, 4:3?)                      -->
<!-- https://css-tricks.com/NetMag/FluidWidthVideo/Article-FluidWidthVideo.php -->

<!-- Configurable options, we are considering academic uses                       -->
<!-- https://developers.google.com/youtube/player_parameters#Manual_IFrame_Embeds -->
<!-- hl parameter for language seems superfluous, user settings override          -->
<!-- something to do with cross-domain scripting security?                        -->
<!-- <xsl:text>&amp;origin=http://example.com</xsl:text>                          -->
<!-- start/end time parameters                                                    -->

<!-- create iframe embedded video                     -->
<!-- dimensions and autoplay as parameters            -->
<!-- Normally $preview is true, and not passed in     -->
<!-- 'false' is an override for standalone pages      -->
<!-- Templates, on a per-service basis, supply a URL, -->
<!-- and any attributes on the "iframe" element which -->
<!-- are not shared                                   -->
<xsl:template match="video[@youtube|@youtubeplaylist|@vimeo]" mode="media-embed">
    <xsl:param name="preview" select="'true'" />
    <xsl:param name="autoplay" select="'false'" />

    <xsl:variable name="source-url">
        <xsl:apply-templates select="." mode="video-embed-url">
            <xsl:with-param name="autoplay" select="$autoplay" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="source-url-autoplay-on">
        <xsl:apply-templates select="." mode="video-embed-url">
            <xsl:with-param name="autoplay">
                <xsl:choose>
                    <!-- the YouTube autoplay won't wait for the poster -->
                    <!-- to be withdrawn, so two clicks are needed,     -->
                    <!-- perhaps this is true of *all* services?        -->
                    <xsl:when test="@youtube|@youtubeplaylist">
                        <xsl:text>false</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>true</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:variable>
    <!-- allowfullscreen is an iframe parameter,   -->
    <!-- not a video-embedding parameter, but it's -->
    <!-- use enables the "full screen" button      -->
    <!-- http://w3c.github.io/test-results/html51/implementation-report.html -->
    <xsl:choose>
        <xsl:when test="($preview = 'true') and @preview and not(@preview = 'default')">
            <!-- hide behind a preview image, code from post at -->
            <!-- https://stackoverflow.com/questions/7199624    -->
            <div onclick="this.nextElementSibling.style.display='block'; this.style.display='none'">
                <xsl:choose>
                    <xsl:when test="@preview = 'generic'">
                        <xsl:call-template name="generic-preview-svg"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <img class="video-poster" alt="Video cover image">
                            <xsl:attribute name="src">
                                <!-- empty when not using managed directories -->
                                <xsl:value-of select="$external-directory"/>
                                <xsl:value-of select="@preview"/>
                            </xsl:attribute>
                        </img>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
            <div class="hidden-content">
                <!-- Hidden content in here                   -->
                <!-- Turn autoplay on, else two clicks needed -->
                <iframe class="video" allowfullscreen="" src="{$source-url-autoplay-on}">
                    <xsl:apply-templates select="." mode="html-id-attribute"/>
                    <xsl:apply-templates select="." mode="video-iframe-attributes">
                        <xsl:with-param name="autoplay" select="'true'"/>
                    </xsl:apply-templates>
                </iframe>
            </div>
        </xsl:when>
        <xsl:otherwise>
            <iframe class="video" allowfullscreen="" src="{$source-url}">
                <xsl:apply-templates select="." mode="html-id-attribute"/>
                <xsl:apply-templates select="." mode="video-iframe-attributes">
                    <xsl:with-param name="autoplay" select="$autoplay"/>
                </xsl:apply-templates>
            </iframe>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Creates a YouTube URL for embedding for use in an iframe -->
<!-- Autoplay option is conveyed in the URL query options     -->
<!-- Autoplay is for popout, otherwise not                    -->
<xsl:template match="video[@youtube|@youtubeplaylist]" mode="video-embed-url">
    <xsl:param name="autoplay" select="'false'" />
    <xsl:variable name="youtube">
        <xsl:choose>
            <!-- forgive an author's leading or trailing space -->
            <xsl:when test="@youtubeplaylist">
                <xsl:value-of select="normalize-space(@youtubeplaylist)" />
            </xsl:when>
            <!-- replace commas with spaces then normalize space    -->
            <!-- result is a trim space-separated list of video IDs -->
            <xsl:otherwise>
                <xsl:value-of select="normalize-space(str:replace(@youtube, ',', ' '))" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$b-video-privacy">
            <xsl:text>https://www.youtube-nocookie.com/embed</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>https://www.youtube.com/embed</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
        <!-- playlist with a YouTube ID -->
        <xsl:when test="@youtubeplaylist">
            <xsl:text>?listType=playlist&amp;list=</xsl:text>
            <xsl:value-of select="$youtube" />
        </xsl:when>
        <!-- if we get this far there must be a @youtube -->
        <!-- and $youtube is one or more video IDs       -->
        <xsl:when test="contains($youtube, ' ')">
            <xsl:text>?playlist=</xsl:text>
            <xsl:value-of select="str:replace($youtube, ' ', ',')" />
        </xsl:when>
        <!-- a single video ID -->
        <xsl:otherwise>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="$youtube" />
            <xsl:text>?</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- use &amp; separator for remaining options -->
    <xsl:text>&amp;modestbranding=1</xsl:text>
    <!-- kill related videos at end -->
    <xsl:text>&amp;rel=0</xsl:text>
    <!-- start and end times; for a playlist these are applied to first video -->
    <xsl:if test="@start">
        <xsl:text>&amp;start=</xsl:text>
        <xsl:value-of select="@start" />
    </xsl:if>
    <xsl:if test="@end">
        <xsl:text>&amp;end=</xsl:text>
        <xsl:value-of select="@end" />
    </xsl:if>
    <!-- default autoplay is 0, don't -->
    <xsl:if test="$autoplay = 'true'">
        <xsl:text>&amp;autoplay=1</xsl:text>
    </xsl:if>
</xsl:template>

<!-- For a YouTube video, no YT-specific options come in the attributes -->
<xsl:template match="video[@youtube|@youtubeplaylist]" mode="video-iframe-attributes"/>

<!-- Creates a Vimeo URL for embedding, typically in an iframe  -->
<xsl:template match="video[@vimeo]" mode="video-embed-url">
    <xsl:param name="autoplay" select="'false'" />
    <xsl:text>https://player.vimeo.com/video/</xsl:text>
    <xsl:value-of select="@vimeo"/>
    <xsl:text>?color=ffffff</xsl:text>
    <!-- use &amp; separator for remaining options -->
    <!-- default autoplay is 0, don't -->
    <xsl:if test="$autoplay = 'true'">
        <xsl:text>&amp;autoplay=1</xsl:text>
    </xsl:if>
</xsl:template>

<!-- These are additional attributes on the "iframe" which seem specific to Vimeo -->
<!-- N.B. the autoplay seems ineffective                                          -->
<xsl:template match="video[@vimeo]" mode="video-iframe-attributes">
    <xsl:param name="autoplay" select="'false'" />

    <xsl:attribute name="frameborder">
        <xsl:text>0</xsl:text>
    </xsl:attribute>
    <xsl:attribute name="allow">
        <xsl:if test="$autoplay = 'true'">
            <xsl:text>autoplay; </xsl:text>
        </xsl:if>
        <xsl:text>fullscreen</xsl:text>
    </xsl:attribute>
</xsl:template>

<!-- ############ -->
<!-- Music Scores -->
<!-- ############ -->

<!-- Embed an interactive score from MuseScore                          -->
<!-- Flag: score element has two MuseScore-specific attributes          -->
<!-- https://musescore.org/user/{usernumber}/scores/{scorenumber}/embed -->
<!-- into an iframe with width and height (todo)                        -->
<xsl:template match="score[@musescoreuser and @musescore]">
    <xsl:element name="iframe">
        <xsl:attribute name="width">
            <xsl:text>100%</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="height">
            <xsl:text>500</xsl:text>
        </xsl:attribute>
        <!-- empty attribute, just switch -->
        <xsl:attribute name="allowfullscreen">
            <xsl:text></xsl:text>
        </xsl:attribute>
        <xsl:attribute name="src">
            <xsl:text>https://musescore.com/user/</xsl:text>
            <xsl:value-of select="@musescoreuser" />
            <xsl:text>/scores/</xsl:text>
            <xsl:value-of select="@musescore" />
            <xsl:text>/embed</xsl:text>
        </xsl:attribute>
    </xsl:element>
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

<xsl:template match="tabular[not(ancestor::sidebyside)]">
    <xsl:param name="b-original" select="true()" />
    <!-- naked tabular carries its own width -->

    <xsl:choose>
        <xsl:when test="not(@margins) and (not(@width) or (@width = 'auto'))">
            <!-- the "natural width" case                       -->
            <!-- 100% width allows paragraph cells to be widest -->
            <div class="tabular-box natural-width">
                <xsl:apply-templates select="." mode="tabular-inclusion">
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="width" select="'100%'" />
                </xsl:apply-templates>
            </div>
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="rtf-layout">
                <xsl:apply-templates select="." mode="layout-parameters"/>
            </xsl:variable>
            <xsl:variable name="layout" select="exsl:node-set($rtf-layout)"/>
            <div class="tabular-box">
                <xsl:attribute name="style">
                    <xsl:text>width: </xsl:text>
                    <xsl:value-of select="$layout/width"/>
                    <xsl:text>%;</xsl:text>
                    <xsl:text> margin-left: </xsl:text>
                    <xsl:value-of select="$layout/left-margin"/>
                    <xsl:text>%;</xsl:text>
                    <xsl:text> margin-right: </xsl:text>
                    <xsl:value-of select="$layout/right-margin"/>
                    <xsl:text>%;</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="." mode="tabular-inclusion">
                    <xsl:with-param name="b-original" select="$b-original"/>
                    <xsl:with-param name="width" select="concat($layout/width, '%')"/>
                </xsl:apply-templates>
            </div>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="tabular[ancestor::sidebyside]">
    <xsl:param name="b-original" select="true()" />
    <!-- sidebyside should always provide width, -->
    <!-- so no default value provided here       -->
    <xsl:param name="width"/>

    <xsl:apply-templates select="." mode="tabular-inclusion">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="width" select="$width" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="tabular" mode="tabular-inclusion">
    <xsl:param name="b-original" select="$b-original"/>
    <xsl:param name="width"  select="$width"/>

    <!-- Abort if tabular's cols have widths summing to over 100% -->
    <xsl:call-template name="cap-width-at-one-hundred-percent">
        <xsl:with-param name="nodeset" select="col/@width" />
    </xsl:call-template>

    <table class="tabular">
        <!-- We *actively* enforce header rows being (a) initial, and      -->
        <!-- (b) contiguous.  So following two-part match will do no harm  -->
        <!-- to correct source, but will definitely harm incorrect source. -->
        <xsl:apply-templates select="row[@header]">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="ambient-relative-width" select="$width" />
        </xsl:apply-templates>
        <xsl:apply-templates select="row[not(@header)]">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="ambient-relative-width" select="$width" />
        </xsl:apply-templates>
    </table>
</xsl:template>

<!-- A row of table -->
<xsl:template match="row">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="ambient-relative-width" />

    <!-- Determine if the row is a header row -->
    <!-- and construct class names as needed  -->
    <xsl:variable name="header-row">
        <xsl:choose>
            <xsl:when test="@header = 'yes'">
                <xsl:text>header-horizontal</xsl:text>
            </xsl:when>
            <xsl:when test="@header = 'vertical'">
                <xsl:text>header-vertical</xsl:text>
            </xsl:when>
            <!-- "no" is other choice, or no attribute at all -->
            <!-- controlled by schema, so no error-check here -->
            <!-- empty implies no class attribute at all      -->
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:variable>

    <!-- Form the HTML table row -->
    <xsl:element name="tr">
        <!-- and a class attribute for horizontal or vertical headers -->
        <xsl:if test="not($header-row = '')">
            <xsl:attribute name="class">
                <xsl:value-of select="$header-row"/>
            </xsl:attribute>
        </xsl:if>
        <!-- Walk the cells of the row -->
        <xsl:call-template name="row-cells">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="ambient-relative-width">
                <xsl:value-of select="$ambient-relative-width" />
            </xsl:with-param>
            <xsl:with-param name="the-cell" select="cell[1]" />
            <xsl:with-param name="left-col" select="ancestor::tabular/col[1]" />  <!-- possibly empty -->
        </xsl:call-template>
    </xsl:element>
</xsl:template>

<xsl:template name="row-cells">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="ambient-relative-width" />
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
    <!-- position()  added in 026d6d6d9f69f4de17a012aa32c4e8dee77519fb,      -->
    <!-- unclear if it can be removed/replaced                               -->
    <xsl:variable name="right-col" select="($left-col/self::*|$left-col/following-sibling::col)[position()=$column-span]" />
    <!-- Look ahead one column, anticipating recursion   -->
    <!-- but also probing for end of row (no more cells) -->
    <xsl:variable name="next-cell" select="$the-cell/following-sibling::cell[1]" />
    <xsl:variable name="next-col"  select="$right-col/following-sibling::col[1]" /> <!-- possibly empty -->

    <!-- Check if row-headers are requested -->
    <xsl:variable name="b-row-headers" select="boolean($the-cell/parent::row/parent::tabular[@row-headers = 'yes'])"/>
    <!-- And if we are at the first cell -->
    <xsl:variable name="b-row-header" select="$b-row-headers and not($the-cell/preceding-sibling::cell)"/>

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
        <!-- vertical alignment -->
        <xsl:variable name="valignment">
            <xsl:choose>
                <!-- parent row attribute first -->
                <xsl:when test="$the-cell/ancestor::row/@valign">
                    <xsl:value-of select="$the-cell/ancestor::row/@valign" />
                </xsl:when>
                <!-- table attribute last -->
                <xsl:when test="$the-cell/ancestor::tabular/@valign">
                    <xsl:value-of select="$the-cell/ancestor::tabular/@valign" />
                </xsl:when>
                <!-- HTML default is "baseline", not supported by PTX           -->
                <!-- Instead we default to "middle" to be consistent with LaTeX -->
                <xsl:otherwise>
                    <xsl:text>middle</xsl:text>
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

        <!-- a cell of a header row needs to be "th" -->
        <!-- else the HTML mark up is "td"           -->
        <!-- NB: Named templates means context is a  -->
        <!-- row, which is really wrong.  Tests      -->
        <!-- should be on  parent::row/@header       -->
        <xsl:variable name="header-row-elt">
            <xsl:choose>
                <xsl:when test="@header = 'yes'">
                    <xsl:text>th</xsl:text>
                </xsl:when>
                <xsl:when test="@header = 'vertical'">
                    <xsl:text>th</xsl:text>
                </xsl:when>
                <xsl:when test="$b-row-header">
                    <xsl:text>th</xsl:text>
                </xsl:when>
                <!-- "no" is other choice, or no attribute at all -->
                <!-- controlled by schema, so no error-check here -->
                <xsl:otherwise>
                    <xsl:text>td</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- the HTML element for the cell -->
        <xsl:element name="{$header-row-elt}">
            <!-- Scope attribute helps with accessibility: what          -->
            <!-- is the table element/cell describing?                   -->
            <!-- if this is a row of column headers, declare scope="col" -->
            <!-- if this is a column of row headers, declare scope="row" -->
            <xsl:if test="$header-row-elt = 'th'">
                <xsl:attribute name="scope">
                    <!-- If in upper-left corner, let column headings dominate -->
                    <xsl:choose>
                        <xsl:when test="(@header = 'yes') or (@header = 'vertical')">
                            <xsl:text>col</xsl:text>
                        </xsl:when>
                        <xsl:when test="$b-row-header">
                            <xsl:text>row</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:if>
            <!-- and the class attribute -->
            <xsl:attribute name="class">
                <!-- always write alignment, so *precede* all subsequent with a space -->
                <xsl:choose>
                    <xsl:when test="$the-cell/p and $alignment='justify'">
                        <xsl:text>j</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="halign-specification">
                            <xsl:with-param name="align" select="$alignment" />
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- vertical alignment -->
                <xsl:text> </xsl:text>
                <xsl:call-template name="valign-specification">
                    <xsl:with-param name="align" select="$valignment" />
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
                <!-- no wrapping unless paragraph cell -->
                <xsl:if test="not($the-cell/p)">
                    <xsl:text> lines</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <xsl:if test="not($column-span = 1)">
                <xsl:attribute name="colspan">
                    <xsl:value-of select="$column-span" />
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="$the-cell/p">
                <xsl:attribute name="style">
                    <xsl:text>max-width:</xsl:text>
                    <xsl:choose>
                        <xsl:when test="$left-col/@width">
                            <xsl:variable name="width">
                                <xsl:call-template name="normalize-percentage">
                                    <xsl:with-param name="percentage" select="$left-col/@width" />
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:value-of select="$design-width * substring-before($width, '%') div 100 * substring-before($ambient-relative-width, '%') div 100" />
                            <xsl:text>px;</xsl:text>
                        </xsl:when>
                        <!-- If there is no $left-col/@width, silently use 20% as default -->
                        <!-- We get some ill-formed WW exercises here, so a less-precise  -->
                        <!-- warning is given on the author's source.                     -->
                        <xsl:otherwise>
                            <xsl:value-of select="$design-width * 0.2 * substring-before($ambient-relative-width, '%') div 100" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:if>
            <!-- process the actual contents           -->
            <!-- condition on indicators of structure  -->
            <!-- All "line", all "p", or mixed content -->
            <!-- TODO: is it important to pass $b-original -->
            <!-- flag into template for "line" elements?   -->
            <xsl:choose>
                <xsl:when test="$the-cell/line">
                    <xsl:apply-templates select="$the-cell/line"/>
                </xsl:when>
                <xsl:when test="$the-cell/p">
                    <xsl:apply-templates select="$the-cell/p">
                        <xsl:with-param name="b-original" select="$b-original"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$the-cell">
                        <xsl:with-param name="b-original" select="$b-original"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
        <!-- recurse forward, perhaps to an empty cell -->
        <xsl:call-template name="row-cells">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="ambient-relative-width" select="$ambient-relative-width" />
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

<!-- Utilities are defined in xsl/pretext-common.xsl -->

<!-- "thickness-specification" : param "width"    -->
<!--     none, minor, medium, major -> 0, 1, 2, 3 -->

<!-- "halign-specification" : param "align"       -->
<!--     left, right, center -> l, c, r           -->

<!-- "valign-specification" : param "align"       -->
<!--     top, middle, bottom -> t, m, b           -->


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

<!-- This is the implementation of an abstract template, -->
<!-- to accomodate hard-coded HTML numbers and for       -->
<!-- LaTeX the \ref and \label mechanism                 -->
<xsl:template match="*" mode="xref-number">
    <xsl:param name="xref" select="/.." />
    <xsl:variable name="needs-part-prefix">
        <xsl:apply-templates select="." mode="crosses-part-boundary">
            <xsl:with-param name="xref" select="$xref" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$needs-part-prefix = 'true'">
        <xsl:apply-templates select="ancestor::part" mode="serial-number" />
        <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<!-- One exception is a local tag on an mrow -->
<xsl:template match="mrow[@tag]" mode="xref-number">
    <xsl:apply-templates select="@tag" mode="tag-symbol" />
</xsl:template>

<!-- The second abstract template, we condition   -->
<!-- on if the link is rendered as a knowl or not -->
<!-- and then condition on the location of the    -->
<!-- actual link, which is sensitive to display   -->
<!-- math in particular                           -->
<!-- See xsl/pretext-common.xsl for more info     -->
<!-- NB: for HTML output, the $content variable   -->
<!-- may have HTML elements in it (e.g. link is a  -->
<!-- title with emphasis, or a MathJax processing  -->
<!-- span) so we want a "copy-of" here, not a      -->
<!-- "value-of".                                   -->
<!-- TODO: could match on "xref" once link routines  -->
<!-- are broken into two and other uses are rearranged -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="target" select="/.." />
    <xsl:param name="origin" select="''" />
    <xsl:param name="content" select="'MISSING LINK CONTENT'"/>
    <xsl:variable name="knowl">
        <xsl:apply-templates select="$target" mode="xref-as-knowl">
            <xsl:with-param name="link" select="."/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
        <!-- 1st exceptional case, xref in a webwork, or in    -->
        <!-- some sort of title.  Then just parrot the content -->
        <xsl:when test="ancestor::webwork-reps|ancestor::title|ancestor::shorttitle|ancestor::subtitle">
            <xsl:copy-of select="$content"/>
        </xsl:when>
        <!-- 2nd exceptional case, xref in mrow of display math  -->
        <!--   with Javascript (pure HTML) we can make knowls    -->
        <!--   without Javascript (EPUB) we use plain text       -->
        <xsl:when test="parent::mrow or parent::me or parent::men or parent::md[not(mrow)] or parent::mdn[not(mrow)]">
            <xsl:apply-templates select="." mode="xref-link-display-math">
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="origin" select="'xref'"/>
                <xsl:with-param name="content" select="$content"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- usual case, always an "a" element (anchor) -->
        <xsl:otherwise>
            <xsl:element name="a">
                <!-- knowl/hyperlink variability here -->
                <xsl:choose>
                    <!-- build a modern knowl -->
                    <xsl:when test="$knowl='true'">
                        <!-- provide href for a fallback behavior if knowl is -->
                        <!-- disabled intentionally or not                    -->
                        <xsl:attribute name="href">
                            <xsl:apply-templates select="$target" mode="url" />
                        </xsl:attribute>
                        <!-- mark as duplicated content via an xref -->
                        <xsl:attribute name="class">
                            <xsl:text>xref</xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="data-knowl">
                            <xsl:apply-templates select="$target" mode="knowl-filename">
                                <xsl:with-param name="origin" select="$origin"/>
                            </xsl:apply-templates>
                        </xsl:attribute>
                        <!-- text to use for tooltip/aria  -->
                        <xsl:attribute name="data-reveal-label">
                            <xsl:apply-templates select="." mode="type-name">
                                <xsl:with-param name="string-id" select="'reveal'"/>
                            </xsl:apply-templates>
                        </xsl:attribute>
                        <xsl:attribute name="data-close-label">
                            <xsl:apply-templates select="." mode="type-name">
                                <xsl:with-param name="string-id" select="'close'"/>
                            </xsl:apply-templates>
                        </xsl:attribute>
                    </xsl:when>
                    <!-- build traditional hyperlink -->
                    <xsl:otherwise>
                        <xsl:attribute name="href">
                            <xsl:apply-templates select="$target" mode="url" />
                        </xsl:attribute>
                        <!-- use a class to identify an internal link -->
                        <xsl:attribute name="class">
                            <xsl:text>internal</xsl:text>
                        </xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- add HTML title attribute to the link -->
                <xsl:attribute name="title">
                    <xsl:apply-templates select="$target" mode="tooltip-text" />
                </xsl:attribute>
                <!-- link content from common template -->
                <xsl:copy-of select="$content"/>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- For pure HTML we can make a true knowl or traditional link -->
<!-- when an "xref" is authored inside of a display math "mrow" -->
<!-- Requires js/lib/mathjaxknowl3.js                           -->
<!-- loaded as a MathJax extension for knowls to render.        -->
<!-- See discussion in "xref-link" about "copy-of" necessity.   -->
<xsl:template match="*" mode="xref-link-display-math">
    <xsl:param name="target"/>
    <xsl:param name="origin"/>
    <xsl:param name="content"/>

    <!-- this could be passed as a parameter, but -->
    <!-- we have $target anyway, so can recompute -->
    <xsl:variable name="knowl">
        <xsl:apply-templates select="$target" mode="xref-as-knowl">
            <xsl:with-param name="link" select="."/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$knowl='true'">
            <xsl:text>\knowl{</xsl:text>
            <xsl:apply-templates select="$target" mode="knowl-filename">
                <xsl:with-param name="origin" select="'xref'"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\href{</xsl:text>
            <xsl:apply-templates select="$target" mode="url"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}{</xsl:text>
    <xsl:copy-of select="$content"/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- A URL is needed various places, such as                     -->
<!--   1. xref to material larger than a knowl, e.g. a "chapter" -->
<!--   2. "in-context" link in xref-knowls                       -->
<!--   3. summary-page links                                     -->
<!--   4. many navigation devices, e.g. ToC, prev/next buttons   -->
<!-- This is strictly an HTML construction.                      -->
<!-- A containing filename, plus possibly a fragment identifier. -->
<!-- NB: a "p" whose initial content is display math results in  -->
<!-- a contest for the HTML id that goes on the                  -->
<!-- div.displaymath.  The "p" is only a target of a hyperlink   -->
<!-- when it is the "in-context" link of a knowl for the "p",    -->
<!-- which only happens in the index, so the "p" must also have  -->
<!-- an "idx" element.  So we are labeling the div for what it   -->
<!-- is, display math, so links to numbered equations will work. -->
<!-- So we have:                                                 -->
<!-- BUG: a "p" that leads with display math and has an "idx"    -->
<!-- creates a knowl in the index whose "in-context" link is     -->
<!-- incorrect.                                                  -->
<xsl:template match="*" mode="url">
    <xsl:choose>
        <xsl:when test="$chunk-level = 0">
            <!-- When building a single page, we just want the     -->
            <!-- fragment identifier since links should just jump  -->
            <!-- around the page. Not including the filename makes -->
            <!-- it easy for for a user to rename the file later.  -->
            <xsl:apply-templates select="." mode="url-fragment"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- In other other cases, we want a filename plus a fragment -->
            <!-- identifier if the link is to the interior of a page.     -->
            <xsl:apply-templates select="." mode="containing-filename" />
            <xsl:variable name="intermediate">
                <xsl:apply-templates select="." mode="is-intermediate" />
            </xsl:variable>
            <xsl:variable name="chunk">
                <xsl:apply-templates select="." mode="is-chunk" />
            </xsl:variable>
            <xsl:if test="$intermediate='false' and $chunk='false'">
                <!-- interior to a page, needs fragment identifier -->
                <xsl:apply-templates select="." mode="url-fragment"/>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="url-fragment">
    <xsl:text>#</xsl:text>
    <!-- All display math is in a  div.displaymath  with  -->
    <!-- an HTML id.  An "mrow" can have an @xml:id, and  -->
    <!-- we direct a URL (typically the "in-context" link -->
    <!-- of a knowl) to the enclosing "md" or "mdn" (we   -->
    <!-- can't know which in advance)                     -->
    <xsl:choose>
        <xsl:when test="self::mrow">
            <xsl:apply-templates select="parent::*" mode="html-id"/>
        </xsl:when>
        <!-- an "men" is fine here, we do not need a parent -->
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="html-id"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- The @id attribute of an HTML element is critical.      -->
<!-- We supply the "visible-id".                            -->
<xsl:template match="*" mode="html-id">
    <xsl:apply-templates select="." mode="visible-id"/>
</xsl:template>

<!-- And a convenience template to make an id attribute.  -->
<!-- Note: the purpose of an id is to later reference it, -->
<!-- so we still need the "html-id" template in order to  -->
<!-- make those references, but these two templates       -->
<!-- together ensure that they are consistent.  And there -->
<!-- are limited cases where we need ids derived from     -->
<!-- these baseline versions.                             -->
<xsl:template match="*" mode="html-id-attribute">
    <xsl:attribute name="id">
        <xsl:apply-templates select="." mode="html-id"/>
    </xsl:attribute>
</xsl:template>

<!-- We manufacture Javascript variables sometimes using            -->
<!-- this id to keep them unique, but a dash (encouraged in PTX)    -->
<!-- is banned in Javascript, so we make a "no-dash" version,       -->
<!-- by replacing a hyphen by a double-underscore.                  -->
<!-- NB: This runs some non-zero probability of breaking uniqueness -->
<xsl:template match="*" mode="visible-id-no-dash">
    <xsl:variable name="the-id">
        <xsl:apply-templates select="." mode="visible-id" />
    </xsl:variable>
    <xsl:value-of select="str:replace($the-id, '-', '__')" />
</xsl:template>


<!-- ######## -->
<!-- SI Units -->
<!-- ######## -->

<xsl:template match="quantity">
    <!-- Unicode FRACTION SLASH -->
    <xsl:variable name="fraction-slash" select="'&#x2044;'"/>

    <!-- span to prevent line breaks within the quantity -->
    <span class="quantity">
        <xsl:apply-templates select="mag"/>
        <!-- if not solo, add separation -->
        <xsl:if test="mag and (unit or per)">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="per">
               <sup>
                    <xsl:if test="not(unit)">
                        <xsl:text>1</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="unit" />
                </sup>
                <xsl:value-of select="$fraction-slash"/>
                <sub>
                    <xsl:apply-templates select="per" />
                </sub>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="unit"/>
            </xsl:otherwise>
        </xsl:choose>
    </span>
    <!-- NB: no mag, no per, no unit implies no output -->
    <!-- (really should be caught in schema), but      -->
    <!-- no real harm in just doing nothing            -->
</xsl:template>

<!-- "mag" is pretty much verbatim, but we allow LaTeX syntax  -->
<!-- for \pi and we need to make them amenable to MathJax.     -->
<!-- TODO:                                                     -->
<!--   - implement <pi/> strictly inside "mag" (LaTeX too)     -->
<!--   - move the recursive template to the "repair"           -->
<!--     pass of the pre-processor                             -->
<xsl:template match="mag">
    <xsl:call-template name="wrap-units-pi">
        <xsl:with-param name="text">
            <xsl:value-of select="."/>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- We recursively isolate instances of \pi and replace them  -->
<!-- with wrapped versions so MathJax will process them.  A    -->
<!-- simple string replacement will not work since the         -->
<!-- replacement is a span.process-math (an HTML element).     -->
<!-- NB: this will not generalize easily to additional symbols -->
<xsl:template name="wrap-units-pi">
    <xsl:param name="text"/>

    <xsl:variable name="pi" select="'\pi'"/>
    <xsl:choose>
        <xsl:when test="not(contains($text, $pi))">
            <!-- nothing left to do, output as-is, and finish -->
            <xsl:value-of select="$text"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- must have a \pi, output prior text -->
            <xsl:value-of select="substring-before($text, $pi)"/>
            <!-- output \pi, appropriately bundled -->
            <xsl:call-template name="inline-math-wrapper">
                <xsl:with-param name="math" select="$pi"/>
            </xsl:call-template>
            <!-- recurse on remainder -->
            <xsl:call-template name="wrap-units-pi">
                <xsl:with-param name="text" select="substring-after($text, $pi)"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- unit and per children of a quantity element    -->
<!-- have a mandatory base attribute                -->
<!-- may have prefix and exp attributes             -->
<!-- base and prefix are not abbreviations          -->

<xsl:key name="prefix-key" match="prefix" use="concat(../@name, @full)"/>
<xsl:key name="base-key" match="base" use="concat(../@name, @full)"/>

<xsl:template match="unit|per">
    <!-- Unicode MIDDLE-DOT -->
    <xsl:variable name="inter-unit-product" select="'&#x00B7;'"/>

    <!-- add non-breaking hyphen within a numerator or denominator of units -->
    <xsl:if test="(self::unit and preceding-sibling::unit) or (self::per and preceding-sibling::per)">
        <xsl:value-of select="$inter-unit-product"/>
    </xsl:if>
    <!-- prefix is optional -->
    <xsl:if test="@prefix">
        <xsl:variable name="prefix">
            <xsl:value-of select="@prefix" />
        </xsl:variable>
        <xsl:variable name="short">
            <xsl:for-each select="document('pretext-units.xsl')">
                <xsl:value-of select="key('prefix-key',concat('prefixes',$prefix))/@short"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="$short" />
    </xsl:if>
    <!-- base unit is required -->
    <xsl:variable name="base">
        <xsl:value-of select="@base" />
    </xsl:variable>
    <xsl:variable name="short">
        <xsl:for-each select="document('pretext-units.xsl')">
            <xsl:value-of select="key('base-key',concat('bases',$base))/@short"/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="$short" />
     <!-- exponent is optional -->
    <xsl:if test="@exp">
        <sup>
            <xsl:value-of select="@exp"/>
        </sup>
    </xsl:if>
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
<!-- Or structured by "line" elements    -->
<!-- Quotation dash if within blockquote -->
<!-- Unicode Character 'HORIZONTAL BAR' aka 'QUOTATION DASH' -->
<xsl:template match="attribution">
    <cite class="attribution">
        <xsl:if test="parent::blockquote">
            <xsl:text>&#x2015;</xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="line">
                <xsl:apply-templates select="line" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </cite>
</xsl:template>

<!-- Defined terms (bold, typically) -->
<xsl:template match="term">
    <dfn class="terminology">
        <xsl:apply-templates/>
    </dfn>
</xsl:template>

<!-- Acronyms, Initialisms, Abbreviations -->
<!-- abbreviation: contracted form                                  -->
<!-- acronym: initials, pronounced as a word (eg SCUBA, RADAR)      -->
<!-- initialism: one letter at a time, (eg CIA, FBI)                -->
<!-- All are marked as the HTML "abbr" tag, but classes distinguish -->
<!-- Would a screen reader know the difference?                     -->
<xsl:template match="abbr">
    <abbr class="abbreviation">
        <xsl:apply-templates/>
    </abbr>
</xsl:template>

<xsl:template match="acro">
    <abbr class="acronym">
        <xsl:apply-templates/>
    </abbr>
</xsl:template>

<xsl:template match="init">
    <abbr class="initialism">
        <xsl:apply-templates/>
    </abbr>
</xsl:template>

<!-- Emphasis -->
<xsl:template match="em">
    <em class="emphasis">
        <xsl:apply-templates/>
    </em>
</xsl:template>

<!-- Alert -->
<xsl:template match="alert">
    <em class="alert">
        <xsl:apply-templates/>
    </em>
</xsl:template>

<!-- CSS for ins, del, s -->
<!-- http://html5doctor.com/ins-del-s/           -->
<!-- http://stackoverflow.com/questions/2539207/ -->

<!-- Insert (an edit) -->
<xsl:template match="insert">
    <ins class="insert">
        <xsl:apply-templates/>
    </ins>
</xsl:template>

<!-- Delete (an edit) -->
<xsl:template match="delete">
    <del class="delete">
        <xsl:apply-templates/>
    </del>
</xsl:template>

<!-- Stale (no longer relevant) -->
<xsl:template match="stale">
    <s class="stale">
        <xsl:apply-templates/>
    </s>
</xsl:template>

<!-- Copyright symbol -->
<xsl:template name="copyright-character">
    <xsl:text>&#xa9;</xsl:text>
</xsl:template>

<!-- Phonomark symbol -->
<xsl:template name="phonomark-character">
    <xsl:text>&#x2117;</xsl:text>
</xsl:template>

<!-- Copyleft symbol -->
<!-- May not be universally available in fonts                 -->
<!-- Open C (U+254) plus Combining Circle (U+20dd) can imitate -->
<xsl:template name="copyleft-character">
    <xsl:text>&#x1f12f;</xsl:text>
</xsl:template>

<!-- Registered symbol -->
<!-- Bringhurst: should be superscript                    -->
<!-- We consider it a font mistake if not superscripted,  -->
<!-- since if we use a "sup" tag then a correct font will -->
<!-- get way too small                                    -->
<xsl:template name="registered-character">
    <xsl:text>&#xae;</xsl:text>
</xsl:template>

<!-- Trademark symbol -->
<xsl:template name="trademark-character">
    <xsl:text>&#x2122;</xsl:text>
</xsl:template>

<!-- Servicemark symbol -->
<xsl:template name="servicemark-character">
    <xsl:text>&#x2120;</xsl:text>
</xsl:template>

<!-- Degree -->
<xsl:template name="degree-character">
    <xsl:text>&#xb0;</xsl:text>
</xsl:template>

<!-- Prime -->
<xsl:template name="prime-character">
    <xsl:text>&#x2032;</xsl:text>
</xsl:template>

<xsl:template name="dblprime-character">
    <xsl:text>&#x2033;</xsl:text>
</xsl:template>

<!-- Characters for Tagging Equations -->

<!-- 'SIX POINTED BLACK STAR' (U+2736) -->
<xsl:template name="tag-star">
    <xsl:text>&#x2736;</xsl:text>
</xsl:template>

<!-- 'DAGGER' (U+2020) -->
<xsl:template name="tag-dagger">
    <xsl:text>&#x2020;</xsl:text>
</xsl:template>

<!-- 'DOUBLE DAGGER' (U+2021) -->
<xsl:template name="tag-daggerdbl">
    <xsl:text>&#x2021;</xsl:text>
</xsl:template>

<!-- 'NUMBER SIGN' (U+0023) -->
<xsl:template name="tag-hash">
    <xsl:text>&#x0023;</xsl:text>
</xsl:template>

<!-- 'MALTESE CROSS' (U+2720) -->
<xsl:template name="tag-maltese">
    <xsl:text>&#x2720;</xsl:text>
</xsl:template>

<!-- Fill-in blank -->
<!-- Bringhurst suggests 5/11 em per character                            -->
<!-- A 'span' normally, but a MathJax non-standard \Rule for math         -->
<!-- "\Rule is a MathJax-specific extension with parameters being width,  -->
<!-- height and depth of the rule"                                        -->
<!-- Davide Cervone                                                       -->
<!-- https://groups.google.com/forum/#!topic/mathjax-users/IEivs1D7ntM    -->
<xsl:template match="fillin[not(parent::m or parent::me or parent::men or parent::md[not(mrow)] or parent::mdn[not(mrow)] or parent::mrow)]">
    <xsl:choose>
        <xsl:when test="ancestor::statement/../@exercise-interactive='fillin'">
            <xsl:apply-imports />
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="characters">
                <xsl:choose>
                    <xsl:when test="@characters">
                        <xsl:value-of select="@characters" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>10</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <span class="fillin {$fillin-text-style}" role="img">
                <xsl:attribute name="aria-label">
                    <xsl:value-of select="$characters" />
                    <xsl:text>-character blank</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="style">
                    <xsl:text>width: </xsl:text>
                    <xsl:value-of select="5 * $characters div 11" />
                    <xsl:text>em;</xsl:text>
                </xsl:attribute>
            </span>
            <xsl:if test="@rows or @cols">
                <xsl:apply-templates select="." mode="fillin-array"/>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Implication Symbols -->
<!-- TODO: better names! -->
<xsl:template match="imply">
    <xsl:text>&#x21D2;</xsl:text>
</xsl:template>
<xsl:template match="implyreverse">
    <xsl:text>&#x21D0;</xsl:text>
</xsl:template>

<!-- TeX, LaTeX w/ CSS -->
<!-- Corresponding CSS from William Hammond   -->
<!-- attributed to David Carlisle             -->
<!-- "mathjax-users" Google Group, 2015-12-27 -->
<!-- PreTeXt, XeLaTeX, XeTeX are in -common   -->

<xsl:template match="latex">
    <span class="latex-logo">L<span class="A">a</span>T<span class="E">e</span>X</span>
</xsl:template>
<xsl:template match="tex">
    <span class="latex-logo">T<span class="E">e</span>X</span>
</xsl:template>

<!-- External URLs, Email        -->
<!-- Open in new window/tab as external reference                        -->
<!-- If "no-content", prefer @visual to @href, and then automatically    -->
<!-- format like code (verbatim)                                         -->
<!-- Within titles, we just produce (formatted) text, but nothing active -->
<!-- N.B.  In "content" case, we get a special footnote from the         -->
<!-- assembly phase, so look elsewhere for that handling.                -->
<!-- N.B. compare with LaTeX version, could move much to -common         -->
<xsl:template match="url|dataurl">
    <!-- link/reference/location may be external -->
    <!-- (@href) or internal (dataurl[@source])  -->
    <xsl:variable name="uri">
        <xsl:choose>
            <!-- "url" and "dataurl" both support external @href -->
            <xsl:when test="@href">
                <xsl:value-of select="@href"/>
            </xsl:when>
            <!-- a "dataurl" might be local, @source is      -->
            <!-- indication, so prefix with a local path/URI -->
            <xsl:when test="self::dataurl and @source">
                <!-- empty when not using managed directories -->
                <xsl:value-of select="$external-directory"/>
                <xsl:value-of select="@source"/>
            </xsl:when>
            <!-- empty will be non-functional -->
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:variable>
    <!-- visible portion of HTML is the URL itself,   -->
    <!-- formatted as code, or content of PTX element -->
    <xsl:variable name="visible-text">
        <xsl:choose>
            <xsl:when test="node()">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <code class="code-inline tex2jax_ignore">
                    <xsl:choose>
                        <xsl:when test="@visual">
                            <xsl:value-of select="@visual"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$uri"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </code>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Normally in an active link, except inactive in titles -->
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::shorttitle|ancestor::subtitle">
            <xsl:copy-of select="$visible-text" />
        </xsl:when>
        <xsl:otherwise>
            <!-- class name identifies an external link -->
            <a class="external" href="{$uri}" target="_blank">
                <xsl:copy-of select="$visible-text" />
            </a>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="email">
    <xsl:element name="a">
        <xsl:attribute name="href">
            <xsl:text>mailto:</xsl:text>
            <xsl:value-of select="." />
        </xsl:attribute>
        <xsl:value-of select="." />
    </xsl:element>
</xsl:template>


<!-- ############# -->
<!-- Verbatim Text -->
<!-- ############# -->

<!-- Code, inline -->
<!-- HTML "code" element, with classes -->
<xsl:template name="code-wrapper">
    <xsl:param name="content"/>

    <code class="code-inline tex2jax_ignore">
        <xsl:value-of select="$content"/>
    </code>
</xsl:template>

<xsl:template name="insert-clipboardable-class">
    <xsl:text> clipboardable</xsl:text>
</xsl:template>

<!-- 100% analogue of LaTeX's verbatim            -->
<!-- environment or HTML's <pre> element          -->
<!-- TODO: center on page?                        -->

<!-- When visual spaces are requested, we mimic the               -->
<!-- long-established pattern in LaTeX and use a (short) open     -->
<!-- box character, which is also suggested as a "graphic for     -->
<!-- space" as part of the Unicode standard.                      -->
<!-- Unicode Character 'OPEN BOX' (U+2423)                        -->
<!-- https://www.fileformat.info/info/unicode/char/2423/index.htm -->

<!-- cd is for use in paragraphs, inline -->
<!-- Unstructured is pure text           -->
<xsl:template match="cd">
    <xsl:param name="b-original" select="true()" />
    <xsl:element name="pre">
        <xsl:attribute name="class">
            <xsl:text>code-display tex2jax_ignore</xsl:text>
            <xsl:call-template name="insert-clipboardable-class" />
        </xsl:attribute>
        <xsl:choose>
            <xsl:when test="not(@showspaces) or (@showspaces = 'none')">
                <xsl:value-of select="." />
            </xsl:when>
            <xsl:when test="@showspaces = 'all'">
                <xsl:value-of select="str:replace(., '&#x20;', '&#x2423;')" />
            </xsl:when>
        </xsl:choose>
    </xsl:element>
</xsl:template>

<!-- cline template is in xsl/pretext-common.xsl -->
<xsl:template match="cd[cline]">
    <xsl:param name="b-original" select="true()" />
    <xsl:element name="pre">
        <xsl:attribute name="class">
            <xsl:text>code-display tex2jax_ignore</xsl:text>
            <xsl:call-template name="insert-clipboardable-class" />
        </xsl:attribute>
        <xsl:apply-templates select="cline" />
    </xsl:element>
</xsl:template>

<!-- Override from -common to insert visual spaces -->
<xsl:template match="cline[parent::cd/@showspaces = 'all']">
    <xsl:value-of select="str:replace(., '&#x20;', '&#x2423;')" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- "pre" is analogous to the HTML tag of the same name -->
<!-- The "interior" templates decide between two styles  -->
<!--   (a) clean up raw text, just like for Sage code    -->
<!--   (b) interpret cline as line-by-line structure     -->
<!-- (See templates in xsl/pretext-common.xsl file)     -->
<!-- Then wrap in a pre element that MathJax ignores     -->
<xsl:template match="pre">
    <pre>
        <xsl:attribute name="class">
            <xsl:text>code-block tex2jax_ignore</xsl:text>
            <xsl:call-template name="insert-clipboardable-class" />
        </xsl:attribute>
        <xsl:apply-templates select="." mode="interior"/>
    </pre>
</xsl:template>

<!-- ################## -->
<!-- Special Characters -->
<!-- ################## -->

<!-- Left Single Quote -->
<xsl:template name="lsq-character">
    <xsl:text>&#x2018;</xsl:text>
</xsl:template>

<!-- Right Single Quote -->
<xsl:template name="rsq-character">
    <xsl:text>&#x2019;</xsl:text>
</xsl:template>

<!-- Left (Double) Quote -->
<xsl:template name="lq-character">
    <xsl:text>&#x201c;</xsl:text>
</xsl:template>

<!-- Right (Double) Quote -->
<xsl:template name="rq-character">
    <xsl:text>&#x201d;</xsl:text>
</xsl:template>

<!-- Left Double Bracket -->
<!-- MATHEMATICAL LEFT WHITE SQUARE BRACKET -->
<xsl:template name="ldblbracket-character">
    <xsl:text>&#x27e6;</xsl:text>
</xsl:template>

<!-- Right Double Bracket -->
<!-- MATHEMATICAL RIGHT WHITE SQUARE BRACKET -->
<xsl:template name="rdblbracket-character">
    <xsl:text>&#x27e7;</xsl:text>
</xsl:template>

<!-- Left Angle Bracket -->
<!-- LEFT ANGLE BRACKET -->
<!-- U+2329 was once used and caused a validator warning      -->
<!-- "Text run is not in Unicode Normalization Form C" (NFC)  -->
<xsl:template name="langle-character">
    <xsl:text>&#x3008;</xsl:text>
</xsl:template>

<!-- Right Angle Bracket -->
<!-- RIGHT ANGLE BRACKET -->
<!-- U+232A was once used and caused a validator warning      -->
<!-- "Text run is not in Unicode Normalization Form C" (NFC)  -->
<xsl:template name="rangle-character">
    <xsl:text>&#x3009;</xsl:text>
</xsl:template>


<!-- Other Miscellaneous Symbols, Constructions -->

<!-- Ellipsis (dots), for text, not math -->
<xsl:template name="ellipsis-character">
    <xsl:text>&#x2026;</xsl:text>
</xsl:template>

<!-- Midpoint -->
<!-- A centered dot used sometimes like a decorative dash -->
<!-- Bringhurst: Not Unicode +387, "GREEK ANO TELEIA"     -->
<xsl:template name="midpoint-character">
    <xsl:text>&#xb7;</xsl:text>
</xsl:template>

<!-- Swung Dash -->
<!-- A decorative dash, like a tilde, but bigger, and centered -->
<xsl:template name="swungdash-character">
    <xsl:text>&#x2053;</xsl:text>
</xsl:template>

<!-- Per Mille -->
<!-- Or, per thousand, like a percent sign -->
<xsl:template name="permille-character">
    <xsl:text>&#x2030;</xsl:text>
</xsl:template>

<!-- Pilcrow -->
<!-- Often used to mark the start of a paragraph -->
<xsl:template name="pilcrow-character">
    <xsl:text>&#xb6;</xsl:text>
</xsl:template>

<!-- Section Mark -->
<!-- The stylized double-S to indicate section numbers -->
<xsl:template name="section-mark-character">
    <xsl:text>&#xa7;</xsl:text>
</xsl:template>

<!-- Minus -->
<!-- A hyphen/dash for use in text as subtraction or negation-->
<xsl:template name="minus-character">
    <xsl:text>&#x2212;</xsl:text>
</xsl:template>

<!-- Times -->
<!-- A "multiplication sign" symbol for use in text   -->
<!-- Styled to enhance, consensus at Google Group was -->
<!-- font-size: larger; vertical-align: -.2ex;        -->
<xsl:template name="times-character">
    <xsl:element name="span">
        <xsl:attribute name="class">
            <xsl:text>times-sign</xsl:text>
        </xsl:attribute>
        <xsl:text>&#xd7;</xsl:text>
    </xsl:element>
</xsl:template>

<!-- Solidus -->
<!-- Fraction bar, not as steep as a forward slash -->
<xsl:template name="solidus-character">
    <xsl:text>&#x2044;</xsl:text>
</xsl:template>

<!-- Obelus -->
<!-- A "division" symbol for use in text -->
<xsl:template name="obelus-character">
    <xsl:text>&#xf7;</xsl:text>
</xsl:template>

<!-- Plus/Minus -->
<!-- The combined symbol -->
<xsl:template name="plusminus-character">
    <xsl:text>&#xb1;</xsl:text>
</xsl:template>

<!-- Foreign words/idioms -->
<!-- Rutter, Web Typography, p.50 advocates a "span" with      -->
<!-- a "lang" attribute for foreign words so screen readers    -->
<!-- and hyphenation react properly.  Elsewhere, italics is    -->
<!-- suggested only for transliterated wods, to avoid          -->
<!-- confusion. However, for now, we are using "i" by default, -->
<!-- with a class that can be used in CSS for distinctions.    -->
<!-- But see also (2018-03-23):                                -->
<!-- https://www.w3.org/TR/html5/text-level-semantics.html#the-i-element -->
<xsl:template match="foreign">
    <i class="foreign">
        <xsl:if test="@xml:lang">
            <xsl:attribute name="lang">
                <xsl:value-of select="@xml:lang" />
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates/>
    </i>
</xsl:template>

<!-- Symbols -->
<!-- Symbols are for internal use within theme designs.            -->
<!-- Compare to "icons" which are designed for author use.         -->
<!-- Presumes material symbols font was loaded in "fonts" template -->
<xsl:include href="./html-symbols.xsl"/>
<xsl:key name="symbol-key" match="symbolinfo" use="@name"/>
<xsl:variable name="symbol-table" select="exsl:node-set($available-symbols-list)"/>

<xsl:template name="insert-symbol">
    <xsl:param name = "name" />
    <!-- List of available html symbols for symbol    -->

    <!-- lookup entity code as sanity check -->
    <xsl:variable name="entity-name">
        <xsl:for-each select="$symbol-table">
            <xsl:value-of select="key('symbol-key', $name)/@entity"/>
        </xsl:for-each>
    </xsl:variable>

    <xsl:if test="$entity-name=''">
        <xsl:message>PTX:ERROR: the symbol name <xsl:value-of select="$name"/> is not a known symbol. It will not render correctly.</xsl:message>
    </xsl:if>

    <!-- Could also just use $name here if assume browser supports ligatures. (Just about all do)  -->
    <span class="icon material-symbols-outlined" aria-hidden="true">
        <xsl:text disable-output-escaping="yes">&amp;#x</xsl:text><xsl:value-of select="$entity-name"/><xsl:text>;</xsl:text>
    </span>
</xsl:template>

<!-- ##### -->
<!-- Icons -->
<!-- ##### -->

<!-- Presumes CSS headers have been loaded -->
<xsl:template match="icon">
    <!-- the name attribute of the "icon" in text as a string -->
    <xsl:variable name="icon-name">
        <xsl:value-of select="@name"/>
    </xsl:variable>

    <!-- for-each is just one node, but sets context for key() -->
    <xsl:variable name="fa-family">
        <xsl:for-each select="$icon-table">
            <xsl:value-of select="key('icon-key', $icon-name)/@font-awesome-family"/>
        </xsl:for-each>
    </xsl:variable>

    <!-- for-each is just one node, but sets context for key() -->
    <xsl:variable name="fa-name">
        <xsl:for-each select="$icon-table">
            <xsl:value-of select="key('icon-key', $icon-name)/@font-awesome"/>
        </xsl:for-each>
    </xsl:variable>

    <!-- Element could be "i", but seems non-semantic for screenreaders -->
    <xsl:element name="span">
        <xsl:attribute name="class">
            <xsl:choose>
                <xsl:when test="$fa-family = 'classic'">
                    <!-- "solid", may become "fa-solid" in v6" -->
                    <xsl:text>fas</xsl:text>
                </xsl:when>
                <xsl:when test="$fa-family = 'brands'">
                    <!-- "brands", may become "fa-brand" in v6" -->
                    <xsl:text>fab</xsl:text>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
            <xsl:text> </xsl:text>
            <xsl:text>fa-</xsl:text>
            <xsl:value-of select="$fa-name"/>
        </xsl:attribute>
    </xsl:element>
</xsl:template>


<!-- ############# -->
<!-- Keyboard Keys -->
<!-- ############# -->

<xsl:template match="kbd[not(@name)]">
    <kbd class="kbdkey">
        <xsl:value-of select="."/>
    </kbd>
</xsl:template>

<xsl:template match="kbd[@name]">
    <!-- the name attribute of the "kbd" in text as a string -->
    <xsl:variable name="kbdkey-name">
        <xsl:value-of select="@name"/>
    </xsl:variable>
    <!-- Entirely similar HTML/CSS, but will hold a Unicode character -->
    <kbd class="kbdkey">
        <!-- for-each is just one node, but sets context for key() -->
        <xsl:for-each select="$kbdkey-table">
            <xsl:value-of select="key('kbdkey-key', $kbdkey-name)/@unicode" />
        </xsl:for-each>
    </kbd>
</xsl:template>


<!-- ################ -->
<!-- Biological Names -->
<!-- ################ -->

<!-- typically in an italic font -->

<xsl:template match="taxon">
    <span class="taxon">
        <xsl:choose>
            <!-- both substructures -->
            <xsl:when test="genus and species">
                <xsl:apply-templates select="genus"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="species"/>
            </xsl:when>
            <!-- just one -->
            <xsl:when test="genus">
                <xsl:apply-templates select="genus"/>
            </xsl:when>
            <!-- just the other one -->
            <xsl:when test="species">
                <xsl:apply-templates select="species"/>
            </xsl:when>
            <!-- not structured, use content -->
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </span>
</xsl:template>

<xsl:template match="genus">
    <span class="genus">
        <xsl:apply-templates select="text()"/>
    </span>
</xsl:template>

<xsl:template match="species">
    <span class="species">
        <xsl:apply-templates select="text()"/>
    </span>
</xsl:template>

<!-- Titles of Publications -->
<!-- 2018-02-05: Deprecate "booktitle" in favor of       -->
<!-- "pubtitle".  Will still maintain all for a while.   -->
<!-- CMOS:  When quoted in text or listed in a           -->
<!-- bibliography, titles of books, journals, plays,     -->
<!-- and other freestanding works are italicized; titles -->
<!-- of articles, chapters, and other shorter works      -->
<!-- are set in roman and enclosed in quotation marks.   -->
<xsl:template match="pubtitle|booktitle">
    <span class="booktitle">
        <xsl:apply-templates/>
    </span>
</xsl:template>

<!-- We provide the quotation marks explicitly, along       -->
<!-- with a span for any additional styling.  The quotation -->
<!-- marks are necessary for accessibility.                 -->
<xsl:template match="articletitle">
    <span class="articletitle">
        <xsl:call-template name="lq-character"/>
        <xsl:apply-templates/>
        <xsl:call-template name="rq-character"/>
    </span>
</xsl:template>


<!-- ################## -->
<!-- Special Characters -->
<!-- ################## -->

<!-- These are specific instances of abstract templates        -->
<!-- See the similar section of  pretext-common.xsl  for more -->

<!-- Non-breaking space, which "joins" two words as a unit            -->
<!-- Using &nbsp; does not travel well into node-set() in common file -->
<!-- http://stackoverflow.com/questions/31870                         -->
<!-- /using-a-html-entity-in-xslt-e-g-nbsp                            -->
<!-- Should create UTF-8 anyway:                                      -->
<!-- https://html.spec.whatwg.org/multipage/semantics.html#charset    -->

<xsl:template name="nbsp-character">
    <xsl:text>&#xa0;</xsl:text>
</xsl:template>

<xsl:template name="ndash-character">
    <xsl:text>&#8211;</xsl:text>
</xsl:template>

<xsl:template name="mdash-character">
    <xsl:text>&#8212;</xsl:text>
</xsl:template>

<!-- The abstract template for "mdash" consults a publisher option -->
<!-- for thin space, or no space, surrounding an em-dash.  So the  -->
<!-- "thin-space-character" is needed for that purpose, and does   -->
<!-- not have an associated empty PTX element.                     -->

<xsl:template name="thin-space-character">
    <xsl:text>&#8201;</xsl:text>
</xsl:template>

<!--       -->
<!-- Music -->
<!--       -->

<!--                 -->
<!-- Musical Symbols -->
<!--                 -->

<!-- Accidentals -->

<!-- TODO: If requested, add semi- and sesqui- versions of sharp and flat -->

<!-- Double Sharp -->
<!-- Unicode Character 'MUSICAL SYMBOL DOUBLE SHARP' (U+1D12A)    -->
<!-- http://www.fileformat.info/info/unicode/char/1d12a/index.htm -->
<xsl:template name="doublesharp">
    <xsl:text>&#x1D12A;</xsl:text>
</xsl:template>

<!-- Sharp -->
<!-- Unicode Character 'MUSIC SHARP SIGN' (U+266F)               -->
<!-- http://www.fileformat.info/info/unicode/char/266f/index.htm -->
<xsl:template name="sharp">
    <xsl:text>&#x266F;</xsl:text>
</xsl:template>

<!-- Natural -->
<!-- Unicode Character 'MUSIC NATURAL SIGN' (U+266E)             -->
<!-- http://www.fileformat.info/info/unicode/char/266e/index.htm -->
<xsl:template name="natural">
    <xsl:text>&#x266E;</xsl:text>
</xsl:template>

<!-- Flat -->
<!-- Unicode Character 'MUSIC FLAT SIGN' (U+266D)                -->
<!-- http://www.fileformat.info/info/unicode/char/266d/index.htm -->
<xsl:template name="flat">
    <xsl:text>&#x266D;</xsl:text>
</xsl:template>

<!-- Double Flat -->
<!-- Unicode Character 'MUSICAL SYMBOL DOUBLE FLAT' (U+1D12B)     -->
<!-- http://www.fileformat.info/info/unicode/char/1d12b/index.htm -->
<xsl:template name="doubleflat">
    <xsl:text>&#x1D12B;</xsl:text>
</xsl:template>

<!-- Half Diminished -->
<!-- (MathJax does not support "\o") -->
<!-- Unicode Character 'LATIN SMALL LETTER O WITH STROKE' (U+00F8) -->
<!-- http://www.fileformat.info/info/unicode/char/00F8/index.htm -->
<xsl:template name="halfdiminishedchordsymbol">
    <xsl:text>&#x00F8;</xsl:text>
</xsl:template>

<!-- Implement abstract templates to support      -->
<!-- formatting of bibliographic entries in HTML. -->

<xsl:template match="*" mode="italic">
    <i>
        <xsl:apply-templates/>
    </i>
</xsl:template>

<xsl:template match="*" mode="bold">
    <b>
        <xsl:apply-templates/>
    </b>
</xsl:template>

<!-- This should likely become an "a" for URLS -->
<xsl:template match="*" mode="monospace">
    <tt>
        <xsl:apply-templates/>
    </tt>
</xsl:template>

<xsl:template name="biblio-period">
    <xsl:text>.</xsl:text>
</xsl:template>

<!-- Index Entries -->
<!-- Kill on sight, collect later to build index  -->
<xsl:template match="index[not(index-list)]" />
<xsl:template match="idx" />


<!-- ############################ -->
<!-- Literate Programming Support -->
<!-- ############################ -->

<!-- The "fragment" element is used various other places, so that it   -->
<!-- slots into the knowl-creation system.  The pointer to a fragment, -->
<!-- "fragref", is different, and this makes a visual representation   -->
<!-- of a pointer to the target, as a knowl.  The next two templates   -->
<!-- support the "wrapped-content" template for "fragment".            -->

<!-- @ref is simply a pointer to a fragment, so -->
<!-- convert title into a knowl for the target  -->
<xsl:template match="fragref">
    <xsl:variable name="target" select="id(@ref)"/>
    <span>
        <xsl:call-template name="langle-character"/>
        <xsl:apply-templates select="." mode="xref-link">
            <xsl:with-param name="target" select="$target" />
            <!-- "fragref" is isomorpic to "xref" as a link -->
            <xsl:with-param name="origin" select="'xref'" />
            <xsl:with-param name="content">
                <xsl:apply-templates select="$target" mode="title-full"/>
            </xsl:with-param>
        </xsl:apply-templates>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="$target" mode="number"/>
        <xsl:call-template name="rangle-character"/>
    </span>
    <br/>
</xsl:template>

<!-- wrap code in a "pre" environment, after pulling left -->
<!-- Drop whitespace only text() nodes                    -->
<xsl:template match="fragment/code">
    <xsl:variable name="normalized-frag" select="normalize-space(.)"/>
    <xsl:if test="not($normalized-frag = '')">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
    </xsl:if>
</xsl:template>


<!-- Sage Cells -->
<!-- TODO: make hidden autoeval cells link against sage-compute cells -->

<!-- The block-type parameter is only received from, and sent to, the -->
<!-- templates in the HTML conversion.  The purpose is to inform that -->
<!-- conversion that the Sage cell is inside a born-hidden knowl      -->
<!-- ($block-type = 'hidden') and adjust the class name accordingly.  -->

<!-- Never an @id , so just repeat -->
<xsl:template match="sage" mode="duplicate">
    <xsl:apply-templates select="." />
</xsl:template>

<!-- An abstract named template accepts input text and   -->
<!-- output text, then wraps it for the Sage Cell Server -->
<!-- TODO: consider showing output in green span (?),    -->
<!-- presently output is dropped as computable           -->
<!-- NB: button text is also set as part of knowls code  -->
<xsl:template match="sage" mode="sage-active-markup">
    <xsl:param name="language-attribute" />
    <xsl:param name="b-autoeval" select="false()"/>
    <xsl:param name="in" />
    <xsl:param name="out" />
    <xsl:param name="b-original"/>

    <xsl:element name="div">
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <xsl:attribute name="class">
            <!-- ".ptx-sagecell" for CSS (and not simply .sagecell). -->
            <!-- See https://github.com/sagemath/sagecell/issues/542 -->
            <xsl:text>ptx-sagecell </xsl:text>
            <xsl:call-template name="sagecell-class-name">
                <xsl:with-param name="language-attribute" select="$language-attribute"/>
                <xsl:with-param name="b-autoeval" select="$b-autoeval"/>
            </xsl:call-template>
        </xsl:attribute>

        <xsl:element name="script">
            <xsl:attribute name="type">
                <xsl:text>text/x-sage</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="$in" />
        </xsl:element>
    </xsl:element>
</xsl:template>

<!-- An abstract named template accepts input text   -->
<!-- and provides the display class, so untouchable  -->
<xsl:template name="sage-display-markup">
    <xsl:param name="in" />

    <pre>
        <xsl:attribute name="class">
            <!-- ".ptx-sagecell" for CSS (and not simply .sagecell). -->
            <!-- See https://github.com/sagemath/sagecell/issues/542 -->
            <xsl:text>ptx-sagecell sage-display</xsl:text>
        </xsl:attribute>
        <script type="text/x-sage">
            <xsl:value-of select="$in" />
        </script>
    </pre>
</xsl:template>

<!-- Program Listings -->
<!-- Research:  http://softwaremaniacs.org/blog/2011/05/22/highlighters-comparison/  -->
<!-- See common file for more on language handlers, and "language-prism" template    -->
<!-- TODO: maybe ship sanitized "input" to each modal template? -->
<xsl:template match="program[not(ancestor::sidebyside)]|console[not(ancestor::sidebyside)]">
    <!-- Possibly annotate with the source                     -->
    <xsl:apply-templates select="." mode="view-source-widget"/>
    <xsl:choose>
        <!-- if  a program is elected as interactive, then     -->
        <!-- let Runestone do the best it can via the template -->
        <xsl:when test="self::program and (@interactive='activecode')">
            <xsl:apply-templates select="." mode="runestone-activecode"/>
        </xsl:when>
        <!-- if  a program is elected as interactive, then     -->
        <!-- let Runestone do the best it can via the template -->
        <xsl:when test="self::program and (@interactive='codelens')">
            <xsl:apply-templates select="." mode="runestone-codelens"/>
        </xsl:when>
        <!-- fallback is a less-capable static version, which -->
        <!-- might actually be desired for many formats       -->
        <xsl:otherwise>
            <xsl:variable name="rtf-layout">
                <xsl:apply-templates select="." mode="layout-parameters" />
            </xsl:variable>
            <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
            <!-- div is constraint/positioning for contained program/console -->
            <div class="code-box">
                <!-- only produce inline styles if width has been changed -->
                <xsl:if test="$layout/width != 100">
                    <xsl:attribute name="style">
                        <xsl:text>width: </xsl:text>
                        <xsl:value-of select="$layout/width"/>
                        <xsl:text>%;</xsl:text>
                        <xsl:text> margin-left: </xsl:text>
                        <xsl:value-of select="$layout/left-margin"/>
                        <xsl:text>%;</xsl:text>
                        <xsl:text> margin-right: </xsl:text>
                        <xsl:value-of select="$layout/right-margin"/>
                        <xsl:text>%;</xsl:text>
                    </xsl:attribute>
                </xsl:if>
                <xsl:apply-templates select="." mode="code-inclusion"/>
            </div>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="program[ancestor::sidebyside]|console[ancestor::sidebyside]">
    <!-- Possibly annotate with the source                     -->
    <xsl:apply-templates select="." mode="view-source-widget"/>
    <xsl:choose>
        <!-- if  a program is elected as interactive, then     -->
        <!-- let Runestone do the best it can via the template -->
        <xsl:when test="self::program and (@interactive='activecode')">
            <xsl:apply-templates select="." mode="runestone-activecode"/>
        </xsl:when>
        <!-- if  a program is elected as interactive, then     -->
        <!-- let Runestone do the best it can via the template -->
        <xsl:when test="self::program and (@interactive='codelens')">
            <xsl:apply-templates select="." mode="runestone-codelens"/>
        </xsl:when>
        <!-- fallback is a less-capable static version, which -->
        <!-- might actually be desired for many formats       -->
        <!-- constrained by side-by-side boxes                -->
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="code-inclusion"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- An inline program fragment with potential -->
<!-- syntax highlighting from Prism            -->
<!-- Whitespace is left as authored            -->
<xsl:template match="pf">
    <xsl:variable name="prism-language">
        <xsl:apply-templates select="." mode="prism-language"/>
    </xsl:variable>
    <code>
        <xsl:attribute name="class">
            <xsl:text>code-inline tex2jax_ignore</xsl:text>
            <xsl:choose>
                <xsl:when test="not($prism-language = '')">
                    <xsl:text> language-</xsl:text>
                    <xsl:value-of select="$prism-language" />
                </xsl:when>
                <!-- else, explicitly use what code gives -->
                <xsl:otherwise>
                    <xsl:text> language-none</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:value-of select="." />
    </code>
</xsl:template>

<!-- A non-interactive version with potential -->
<!-- syntax highlighting from Prism           -->
<xsl:template match="program" mode="code-inclusion">
    <xsl:variable name="prism-language">
        <xsl:apply-templates select="." mode="prism-language"/>
    </xsl:variable>
    <!-- a "program" element may be empty in a coding       -->
    <!-- exercise, and just used to indicate an interactive -->
    <!-- area supporting some language                      -->
    <xsl:variable name="b-has-code" select="not(normalize-space(code) = '') or preamble[@visible = 'yes'] or postamble[@visible = 'yes']"/>
    <xsl:if test="$b-has-code">
        <pre>
            <!-- always identify as coming from "program" -->
            <xsl:attribute name="class">
                <xsl:text>program</xsl:text>
                <xsl:call-template name="insert-clipboardable-class" />
                <!-- conditionally request line numbers -->
                <xsl:if test="@line-numbers = 'yes'">
                    <xsl:text> line-numbers</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <!-- Setup line highlighting and numbering -->
            <xsl:if test="@highlight-lines != ''">
                <xsl:attribute name="data-line">
                    <!-- force comma-, or space-separated, list to commas -->
                    <xsl:value-of select="translate(normalize-space(translate(@highlight-lines, ',', ' ')), ' ', ',')"/>
                </xsl:attribute>
            </xsl:if>
            <code>
                <!-- Runestone may have a use for ids and filenames, even on non-interactive -->
                <!-- programs (e.g. inclusion elsewhere).                                    -->
                <xsl:apply-templates select="." mode="runestone-id-attribute"/>
                <xsl:if test="@filename">
                    <xsl:attribute name="data-filename">
                        <xsl:value-of select="@filename"/>
                    </xsl:attribute>
                </xsl:if>
                <!-- Prism only needs a single class name, per language  -->
                <!-- placed on "code" but will migrate to the "pre" also -->
                <xsl:attribute name="class">
                    <xsl:choose>
                        <xsl:when test="not($prism-language = '')">
                            <xsl:text>language-</xsl:text>
                            <xsl:value-of select="$prism-language" />
                        </xsl:when>
                        <!-- else, explicitly use what code gives -->
                        <xsl:otherwise>
                            <xsl:text>language-none</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <!-- build up full program text so we can apply sanitize-text to entire blob -->
                <!-- and thus allow relative indentation for preamble/code/postamble         -->
                <xsl:variable name="program-text">
                    <xsl:if test="preamble[not(@visible = 'no')]">
                        <xsl:apply-templates select="preamble" mode="program-part-processing"/>
                    </xsl:if>
                    <xsl:apply-templates select="code" mode="program-part-processing"/>
                    <xsl:if test="postamble[not(@visible = 'no')]">
                        <xsl:apply-templates select="postamble" mode="program-part-processing"/>
                    </xsl:if>
                </xsl:variable>
                <!-- now sanitize the whole blob -->
                <xsl:call-template name="sanitize-text">
                    <xsl:with-param name="text" select="$program-text" />
                </xsl:call-template>
            </code>
        </pre>
    </xsl:if>
</xsl:template>

<!-- Data Files -->

<xsl:template match="datafile">
    <xsl:apply-templates select="." mode="runestone-to-interactive"/>
</xsl:template>

<!-- Queries -->

<xsl:template match="query">
    <xsl:apply-templates select="." mode="runestone-to-interactive"/>
</xsl:template>

<!-- Console/input helper -->
<!-- A single line of input, possibly with "prefix" (prompt or continuation) -->
<!-- prefix gets wrapped in span if not empty -->
<xsl:template name="input-line-with-prompt">
    <xsl:param name="text" />
    <xsl:param name="prefix" />
    <xsl:if test="not($prefix = '')">
        <span class="prompt unselectable">
            <xsl:value-of select="$prefix"/>
        </span>
    </xsl:if>
    <b>
        <xsl:value-of select="$text" />
    </b>
</xsl:template>

<!-- Console Session -->
<!-- An interactive command-line session with a prompt, input and output -->
<xsl:template match="console" mode="code-inclusion">
    <!-- ignore prompt, and pick it up in trailing input -->
    <pre>
        <xsl:attribute name="class">
            <xsl:text>console</xsl:text>
            <xsl:call-template name="insert-clipboardable-class" />
        </xsl:attribute>
        <xsl:apply-templates select="input|output"/>
    </pre>
</xsl:template>

<xsl:template match="console/input">
    <xsl:variable name="prompt">
        <xsl:apply-templates select="." mode="determine-console-prompt"/>
    </xsl:variable>
    <xsl:variable name="continuation">
        <xsl:apply-templates select="." mode="determine-console-continuation"/>
    </xsl:variable>
    <xsl:variable name="sanitized-text">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$continuation = ''">
            <xsl:call-template name="input-line-with-prompt">
                <xsl:with-param name="text" select="$sanitized-text" />
                <xsl:with-param name="prefix" select="$prompt" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:for-each select="str:tokenize($sanitized-text, '&#xa;')">
                <xsl:choose>
                    <xsl:when test="preceding-sibling::token">
                        <xsl:call-template name="input-line-with-prompt">
                            <xsl:with-param name="text" select="." />
                            <xsl:with-param name="prefix" select="$continuation" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="input-line-with-prompt">
                            <xsl:with-param name="text" select="." />
                            <xsl:with-param name="prefix" select="$prompt" />
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text>&#xa;</xsl:text>
            </xsl:for-each>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="console/output">
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="." />
    </xsl:call-template>
</xsl:template>


<!-- ############ -->
<!-- Interactives -->
<!-- ############ -->

<!-- Every interactive is an "iframe" - this allows us to confine      -->
<!-- libraries, variables, and scripts to just where they are needed.  -->
<!-- And we can "sandbox" an iframe.  Some simple interactives, coming -->
<!-- from servers, are built to be iframes.  In other cases, we build  -->
<!-- a super-minimal page to serve as the @src of an iframe.  For each -->
<!-- "interactive", we also build a stand-alone page to serve as the   -->
<!-- target of a live link in a static format (such as a QR code in a  -->
<!-- LaTeX/PDF document).                                              -->
<!--                                                                   -->
<!-- PTX source may include a "static" element - we routinely ignore   -->
<!-- for HTML output, as it is only employed in static output formats  -->
<!-- https://www.html5rocks.com/en/tutorials/security/sandboxed-iframes/ -->

<!-- Three actions, all based on "interactive-core" template -->
<xsl:template match="interactive">
    <!-- (1) Build, display full content on the page, where born -->
    <xsl:apply-templates select="." mode="interactive-core" />
    <!-- (2) Identical content, but now isolated on a reader-friendly page -->
    <!-- (we skip this for portable html)                                  -->
    <xsl:if test="not($b-portable-html)">
        <xsl:apply-templates select="." mode="standalone-page" >
            <xsl:with-param name="content">
                <xsl:apply-templates select="." mode="interactive-core" />
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- (3) A simple page that can be used in an iframe construction -->
    <!-- (portable html still needs these, since they contain the     -->
    <!-- the content for the interactive                              -->
    <xsl:apply-templates select="." mode="create-iframe-page" />
</xsl:template>

<!-- Following will generate:              -->
<!--   1.  Instructions (paragraphs, etc)  -->
<!--   2.  An iframe, via modal-template   -->
<xsl:template match="interactive" mode="interactive-core">
    <!-- An iframe first -->
    <xsl:choose>
        <!-- A DoenetML interactive lives two lives.  Plain 'ol PreTeXt,  -->
        <!-- supported by a Doenet CDN for its interactivity.  But when   -->
        <!-- hosted on Runestone it can communicate its results.  So it   -->
        <!-- needs surrounding infrastructure, in part to hold an id.     -->
        <xsl:when test="(@platform = 'doenetml') and $b-host-runestone">
            <div class="ptx-runestone-container">
                <div data-component="doenet">
                    <xsl:attribute name="id">
                        <xsl:apply-templates select="." mode="runestone-id"/>
                    </xsl:attribute>
                    <xsl:apply-templates select="." mode="iframe-interactive"/>
                </div>
            </div>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="iframe-interactive"/>
        </xsl:otherwise>
    </xsl:choose>
    <!-- "instructions" next, *always* as a knowl -->
    <!-- "title" is handled in knowl creation     -->
    <!-- div.solutions is good, but replacable?   -->
    <xsl:if test="instructions">
        <div class="instructions">
            <xsl:apply-templates select="instructions" />
        </div>
    </xsl:if>
</xsl:template>

<!-- ################### -->
<!-- iframe Interactives -->
<!-- ################### -->

<!-- Given by a small piece of information used -->
<!-- to form the @src attribute of an "iframe"  -->
<!-- An iframe has @width, @height attributes,  -->
<!-- specified in pixels                        -->

<!-- Check if author wants to dark mode to propagate into iframe   -->
<!-- Propogation will only work for iframes on same server as page -->
<xsl:template match="*" mode="iframe-dark-mode-attribute">
    <xsl:if test="$b-theme-has-darkmode and @dark-mode-enabled">
        <xsl:attribute name="data-dark-mode-enabled">true</xsl:attribute>
    </xsl:if>
</xsl:template>

<!-- Desmos -->
<!-- The simplest possible example of this type -->
<xsl:template match="interactive[@desmos]" mode="iframe-interactive">
    <iframe src="https://www.desmos.com/calculator/{@desmos}">
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <xsl:apply-templates select="." mode="size-pixels-attributes" />
        <xsl:apply-templates select="." mode="iframe-dark-mode-attribute" />
    </iframe>
</xsl:template>

<!-- Geogebra -->
<!-- Similar again, but with options fixed -->
<xsl:template match="interactive[@geogebra]" mode="iframe-interactive">
    <xsl:param name="default-aspect" select="'1:1'" />
    <xsl:variable name="ggbToolBar">
        <xsl:choose>
            <xsl:when test="@toolbar='yes'">
                <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>false</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="ggbAlgebraInput">
        <xsl:choose>
            <xsl:when test="@algebra-input='yes'">
                <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>false</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="ggbResetIcon">
        <xsl:choose>
            <xsl:when test="@reset-icon='yes'">
                <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>false</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="ggbShiftDragZoom">
        <xsl:choose>
            <xsl:when test="@shift-drag-zoom='yes'">
                <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>false</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="ggbMaterialWidth">
        <xsl:choose>
            <xsl:when test="@material-width">
                <xsl:value-of select="@material-width"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>800</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="aspect-ratio">
        <xsl:apply-templates select="." mode="get-aspect-ratio">
            <xsl:with-param name="default-aspect" select="$default-aspect" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="ggbMaterialHeight">
        <xsl:choose>
            <xsl:when test="@material-height">
                <xsl:value-of select="@material-height"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="round($ggbMaterialWidth div $aspect-ratio)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- iframe options not implemented: -->
    <!-- smb = show menu bar                   -->
    <!-- asb = allow style bar                 -->
    <!-- rc = enable right click options       -->
    <!-- ld = enable label drag                -->
    <!-- ctl = click to launch                 -->
    <iframe src="https://www.geogebra.org/material/iframe/id/{@geogebra}/width/{$ggbMaterialWidth}/height/{$ggbMaterialHeight}/border/888888/smb/false/stb/{$ggbToolBar}/stbh/{$ggbToolBar}/ai/{$ggbAlgebraInput}/asb/false/sri/{$ggbResetIcon}/rc/false/ld/false/sdz/{$ggbShiftDragZoom}/ctl/false">
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <xsl:apply-templates select="." mode="size-pixels-attributes" />
        <xsl:apply-templates select="." mode="iframe-dark-mode-attribute" />
    </iframe>
</xsl:template>

<!-- CalcPlot3D -->
<!-- A bit more complicated, as the configuration   -->
<!-- is a query string of a URL, and we can specify -->
<!-- the style of the interface through @variant    -->
<xsl:template match="interactive[@calcplot3d]" mode="iframe-interactive">
    <!-- Use @variant to pick an endpoint/view/infrastructure -->
    <xsl:variable name="cp3d-endpoint">
        <xsl:choose>
            <xsl:when test="@variant='application'">
                <xsl:text>https://c3d.libretexts.org/CalcPlot3D/index.html</xsl:text>
            </xsl:when>
            <xsl:when test="@variant='controls'">
                <xsl:text>https://c3d.libretexts.org/CalcPlot3D/dynamicFigureWCP/index.html</xsl:text>
            </xsl:when>
            <xsl:when test="@variant='minimal'">
                <xsl:text>https://c3d.libretexts.org/CalcPlot3D/dynamicFigure/index.html</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!-- just a silly domain so something none-too-crazy happens -->
                <xsl:text>http://www.example.com/</xsl:text>
                <xsl:message>PTX:ERROR:  @variant="<xsl:value-of select="@variant" />" is not recognized for a CalcPlot3D &lt;interactive&gt;</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- load 'em up and go -->
    <!-- TODO: box-sizing, etc does not seem to help with vertical scroll bars -->
    <xsl:variable name="full-url" select="concat($cp3d-endpoint, '?', @calcplot3d)" />
    <iframe src="{$full-url}">
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <xsl:apply-templates select="." mode="size-pixels-attributes" />
        <xsl:apply-templates select="." mode="iframe-dark-mode-attribute" />
    </iframe>
</xsl:template>

<!-- CircuitJS: https://www.falstad.com -->
<!-- www.bait-consulting.com/publications/circuit_simulator_manual.pdf -->
<xsl:template match="interactive[@circuitjs]" mode="iframe-interactive">
    <!-- CircuitJS native language, as a URL-safe string -->
    <xsl:variable name="url-string">
        <xsl:choose>
            <!-- a prepared string is in the signaling attribute -->
            <xsl:when test="normalize-space(@circuitjs)">
                <xsl:value-of select="@circuitjs"/>
            </xsl:when>
            <!-- Else, a more-friendly version is in a "source" element -->
            <!-- Note that when a "source" element is used, and then    -->
            <!-- provided in iframe/@src, the XSL processing itself     -->
            <!-- will do the necessary escaping to join lines, etc      -->
            <!-- (such as newlines to "%0A" and spaces to "%20")        -->
            <!-- So we just strip leading whitespace primarily          -->
            <xsl:when test="source">
                <xsl:call-template name="sanitize-text">
                    <xsl:with-param  name="text">
                        <xsl:value-of select="source"/>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <!-- no code, empty string, still makes a nice widget -->
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:variable>
    <iframe src="https://www.falstad.com/circuit/circuitjs.html?cct='{$url-string}'">
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <xsl:apply-templates select="." mode="size-pixels-attributes"/>
        <xsl:apply-templates select="." mode="iframe-dark-mode-attribute" />
    </iframe>
</xsl:template>

<!-- Arbitrary IFrame -->
<!-- Almost too easy and trivial, so last, not first -->
<!-- Assumes a local, "external", HTML file to house -->
<xsl:template match="interactive[@iframe]" mode="iframe-interactive">
    <!-- Distinguish netowk location versus (external) file -->
    <xsl:variable name="b-network-location" select="(substring(@iframe, 1, 7) = 'http://') or
                                                    (substring(@iframe, 1, 8) = 'https://')"/>

    <xsl:variable name="location">
        <!-- prefix with directory information if not obviously a network location -->
        <xsl:if test="not($b-network-location)">
            <!-- empty when not using managed directories -->
            <xsl:value-of select="$external-directory"/>
        </xsl:if>
        <xsl:value-of select="@iframe"/>
    </xsl:variable>
    <iframe src="{$location}">
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <xsl:apply-templates select="." mode="size-pixels-attributes"/>
        <xsl:apply-templates select="." mode="iframe-dark-mode-attribute" />
    </iframe>
</xsl:template>

<!-- For more complicated interactives, we just point to the page we generate -->
<xsl:template match="interactive[@platform]" mode="iframe-interactive">
    <iframe>
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <xsl:apply-templates select="." mode="size-pixels-attributes" />
        <xsl:attribute name="src">
            <xsl:apply-templates select="." mode="iframe-filename" />
        </xsl:attribute>
        <xsl:apply-templates select="." mode="iframe-dark-mode-attribute" />
    </iframe>
</xsl:template>

<!-- ######################### -->
<!-- Source File Interactives  -->
<!-- ######################### -->

<!-- Build a minimal page for iframe contents -->
<!-- This version for @platform variant       -->
<!--   MathJax for PTX delimiters             -->
<!--   Platform specific libraries into head  -->
<!--   Author-libraries after slate exist     -->
<xsl:template match="interactive[@platform]" mode="create-iframe-page">
    <xsl:variable name="if-filename">
        <xsl:apply-templates select="." mode="iframe-filename" />
    </xsl:variable>
    <exsl:document href="{$if-filename}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
        <xsl:call-template name="converter-blurb-html-no-date"/>
        <html>
            <xsl:call-template name="language-attributes"/>
            <head>
                <!-- grab the contents every iframe gets -->
                <xsl:copy-of select="$file-wrap-iframe-head-cache"/>
                <!-- now do anything that is or could be page-specific and comes after cache -->
                <!-- and CSS for the entire interactive, into the head -->
                <xsl:apply-templates select="@css" />
                <!-- load header libraries (for all "slate") -->
                <xsl:apply-templates select="." mode="header-libraries" />
            </head>
                <!-- ignore MathJax signals everywhere, then enable selectively -->
                <body class="ptx-content ignore-math">
                <!-- potential document-id per-page -->
                <xsl:call-template name="document-id"/>
                <!-- React flag -->
                <xsl:call-template name="react-in-use-flag"/>
                <!-- Some interactives use slates that are PreTeXt  -->
                <!-- elements, hence could have math, hence need to -->
                <!-- know globally available macros from the author -->
                <xsl:call-template name="latex-macros"/>
                <div>
                    <!-- the actual interactive bit          -->
                    <xsl:apply-templates select="." mode="size-pixels-style-attribute" />
                    <!-- stack, else use a layout -->
                    <xsl:apply-templates select="slate|sidebyside|sbsgroup" />
                    <!-- accumulate script tags *after* HTML elements -->
                    <xsl:apply-templates select="@source" />
                    <!-- accumulate script elements *after* @source scripts -->
                    <xsl:apply-templates select="script"/>
                </div>
            </body>
        </html>
    </exsl:document>
</xsl:template>

<!-- These forms *are* iframes, so we don't need to build their content -->
<!-- NB: coordinate with "embed-iframe-url" in -common                  -->
<xsl:template match="interactive[@desmos|@geogebra|@calcplot3d|@circuitjs|@iframe]" mode="create-iframe-page" />


<!-- ################ -->
<!-- Header Libraries -->
<!-- ################ -->

<!-- Specified by libraries through @platform attribute  -->
<!-- or explicitly with @library, and with per-slate     -->
<!-- @source files stored locally, these draw on "slate" -->
<!-- elements having different @surface characteristics  -->

<!-- Geogebra header libraries -->
<xsl:template match="interactive[@platform = 'geogebra']" mode="header-libraries">
    <script type="text/javascript" src="https://cdn.geogebra.org/apps/deployggb.js"></script>
</xsl:template>

<!-- Sage Interact header libraries -->
<!-- ".sage-interact" must match use in "slate" -->
<xsl:template match="interactive[@platform = 'sage']" mode="header-libraries">
    <script src="https://sagecell.sagemath.org/static/embedded_sagecell.js"></script>
    <script>
        <xsl:text>sagecell.makeSagecell(</xsl:text>
        <xsl:call-template name="json">
            <xsl:with-param name="content">
                <map xmlns="http://www.w3.org/2005/xpath-functions">
                    <string key="inputLocation">.sage-interact</string>
                    <boolean key="autoeval">true</boolean>
                    <array key="hide">
                        <string>editor</string>
                        <string>evalButton</string>
                        <string>permalink</string>
                    </array>
                </map>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:text>);&#xa;</xsl:text>
    </script>
    <link rel="stylesheet" type="text/css" href="https://sagecell.sagemath.org/static/sagecell_embed.css" />
</xsl:template>

<!-- JSXGraph header libraries -->
<xsl:template match="interactive[@platform = 'jsxgraph']" mode="header-libraries">
    <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/jsxgraph/1.8.0/jsxgraph.css" />
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jsxgraph/1.8.0/jsxgraphcore.js"></script>
</xsl:template>

<!-- D3.js header libraries -->
<xsl:template match="interactive[@platform = 'd3']" mode="header-libraries">
    <xsl:variable name="d3-library-url">
        <xsl:text>https://d3js.org/d3.v</xsl:text>
        <!-- versions could be 3, 4, 5 -->
        <xsl:choose>
            <xsl:when test="@version">
                <xsl:value-of select="@version" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>5</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>.min.js</xsl:text>
    </xsl:variable>
    <script src="{$d3-library-url}"></script>
</xsl:template>

<!-- DoenetML header libraries -->
<xsl:template match="interactive[@platform = 'doenetml']" mode="header-libraries">
    <xsl:variable name="doenet-version">
        <xsl:choose>
            <xsl:when test="@version">
                <xsl:value-of select="@version"/>
            </xsl:when>
            <xsl:when test="$docinfo/doenetml/@version">
                <xsl:value-of select="$docinfo/doenetml/@version"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>latest</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="doenet-css-url">
        <xsl:text>https://cdn.jsdelivr.net/npm/@doenet/standalone@</xsl:text>
        <xsl:value-of select="$doenet-version"/>
        <xsl:text>/style.css</xsl:text>
    </xsl:variable>
    <xsl:variable name="doenet-js-url">
        <xsl:text>https://cdn.jsdelivr.net/npm/@doenet/standalone@</xsl:text>
        <xsl:value-of select="$doenet-version"/>
        <xsl:text>/doenet-standalone.js</xsl:text>
    </xsl:variable>
    <link rel="stylesheet" type="text/css" href="{$doenet-css-url}" />
    <script onload="onLoad()" type="module" src="{$doenet-js-url}"></script>
    <script>
        <xsl:text>function onLoad() {window.renderDoenetViewerToContainer(document.querySelector(".doenetml-applet"))}</xsl:text>
    </script>
</xsl:template>

<xsl:template match="image/mermaid" mode="header-libraries">
    <xsl:call-template name="mermaid-header"/>
</xsl:template>

<!-- Javascript header libraries (none) -->
<xsl:template match="interactive[@platform = 'javascript']" mode="header-libraries" />

<!-- ########################### -->
<!-- Slates (objects to draw on) -->
<!-- ########################### -->

<!-- Slates are where we draw, with different surfaces -->

<xsl:template match="slate[@surface='div']">
    <div>
        <xsl:attribute name="id">
            <xsl:value-of select="@xml:id" />
        </xsl:attribute>
        <xsl:apply-templates select="." mode="size-pixels-style-attribute" />
    </div>
</xsl:template>

<xsl:template match="slate[@surface = 'pretext']">
    <div class="slate-ptx">
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <!-- Perhaps more children make sense?  A 1-panel "sidebyside" -->
        <!-- does allow for a wider range of children.                 -->
        <xsl:apply-templates select="p|tabular|sidebyside|sbsgroup"/>
    </div>
</xsl:template>

<xsl:template match="slate[@surface='svg']">
    <svg>
        <xsl:attribute name="id">
            <xsl:value-of select="@xml:id" />
        </xsl:attribute>
        <!-- <xsl:apply-templates select="." mode="size-pixels-style-attribute" /> -->
    </svg>
</xsl:template>

<xsl:template match="slate[@surface = 'canvas']">
    <!-- display:block allows precise sizes, without   -->
    <!-- having inline content with extra line height, -->
    <!-- or whatever, inducing scroll bars             -->
    <canvas style="display:block">
        <xsl:attribute name="id">
            <xsl:value-of select="@xml:id" />
        </xsl:attribute>
        <xsl:apply-templates select="." mode="size-pixels-attributes" />
    </canvas>
</xsl:template>

<!-- HTML Code -->
<!-- Simply create deep-copy of HTML elements -->
<!-- TODO: should this be a div, with width and height? -->
<xsl:template match="slate[@surface = 'html']">
    <xsl:copy-of select="*" />
</xsl:template>

<!-- Similar to the "div" surface, but with class information -->
<xsl:template match="slate[@surface = 'jsxboard']">
    <div>
        <xsl:attribute name="id">
            <xsl:value-of select="@xml:id" />
        </xsl:attribute>
        <xsl:attribute name="class">
            <xsl:text>jxgbox</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="size-pixels-style-attribute" />
    </div>
</xsl:template>

<!-- Sage Cell Server will execute an interact, when     -->
<!-- properly bundled up with the right HTML markup      -->
<!-- ".sage-interact" must match use in "header-library" -->
<xsl:template match="slate[@surface = 'sage']">
    <!-- ".ptx-sagecell" for CSS (and not simply .sagecell). -->
    <!-- See https://github.com/sagemath/sagecell/issues/542 -->
    <pre class="ptx-sagecell sage-interact">
      <script type="text/x-sage">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
      </script>
    </pre>
</xsl:template>

<xsl:template match="slate[@surface='geogebra']">
    <!-- size of the window, to be passed as a parameter -->
    <xsl:variable name="width">
        <xsl:apply-templates select="." mode="get-width-pixels" />
    </xsl:variable>
    <xsl:variable name="height">
        <xsl:apply-templates select="." mode="get-height-pixels" />
    </xsl:variable>
    <xsl:variable name="material-width">
        <xsl:choose>
            <xsl:when test="@material-width">
                <xsl:value-of select="@material-width"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$width"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="material-height">
        <xsl:choose>
            <xsl:when test="@material-height">
                <xsl:value-of select="@material-height"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$height"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- We need a Javascript identifier to name the applet.      -->
    <!-- Other variables will use this as their root.  Need to    -->
    <!-- ensure identifier does not lead with a digit, so "ggb_". -->
    <xsl:variable name="applet-name">
        <xsl:text>ggb_</xsl:text>
        <xsl:apply-templates select="." mode="visible-id-no-dash" />
    </xsl:variable>
    <!-- And a Javascript identifier for the parameters -->
    <xsl:variable name="applet-parameters">
        <xsl:value-of select="$applet-name"/>
        <xsl:text>_params</xsl:text>
    </xsl:variable>
    <!-- And a Javascript identifier for the onload function -->
    <xsl:variable name="applet-onload">
        <xsl:value-of select="$applet-name"/>
        <xsl:text>_onload</xsl:text>
    </xsl:variable>
    <!-- And a Javascript identifier for the onload function argument -->
    <!-- not strictly necessary, but clarifies HTML                   -->
    <xsl:variable name="applet-onload-argument">
        <xsl:value-of select="$applet-name"/>
        <xsl:text>_applet</xsl:text>
    </xsl:variable>
    <!-- And an HTML unique identifier -->
    <xsl:variable name="applet-container">
        <xsl:apply-templates select="." mode="visible-id" />
        <xsl:text>-container</xsl:text>
    </xsl:variable>
    <!-- Javascript API for loading GeoGebra                               -->
    <script>
        <!-- API commands, as text() nodes in the slate. Manual at:   -->
        <!-- https://wiki.geogebra.org/en/Reference:GeoGebra_Apps_API -->
        <!-- In PTX source, use the commands one per line, as in:     -->
        <!-- setCoordSystem(0, 20, 0, 10);                            -->
        <!-- enableShiftDragZoom(false);                              -->
        <xsl:if test="normalize-space(text())">
            <xsl:text>var </xsl:text>
            <xsl:value-of select="$applet-onload" />
            <xsl:text> = function(</xsl:text>
            <xsl:value-of select="$applet-onload-argument" />
            <xsl:text>) {&#xa;</xsl:text>
            <xsl:call-template name="prepend-string">
                <xsl:with-param name="text">
                    <xsl:call-template name="sanitize-text">
                        <xsl:with-param name="text" select="." />
                    </xsl:call-template>
                </xsl:with-param>
                <!-- period below is Javascript syntax for methods -->
                <xsl:with-param name="pad" select="concat($applet-onload-argument,'.')" />
            </xsl:call-template>
            <!-- call a function named 'listeners()' in attached .js file to communicate with other divs -->
            <xsl:text>listeners(</xsl:text><xsl:value-of select='$applet-onload-argument'/><xsl:text>)</xsl:text>
            <xsl:text>};&#xa;</xsl:text>
        </xsl:if>
        <!-- Parameter reference:                                              -->
        <!-- https://wiki.geogebra.org/en/Reference:GeoGebra_App_Parameters    -->
        <!-- We leave most parameters as their default value. In most cases,   -->
        <!-- an author could use API commands to alter these settings.         -->
        <xsl:text>var </xsl:text>
        <xsl:value-of select="$applet-parameters" />
        <xsl:text> = {&#xa;</xsl:text>
        <!-- Prioritize local over remote -->
        <xsl:choose>
            <xsl:when test="@base64">
                <xsl:text>ggbBase64:"</xsl:text>
                <xsl:value-of select="@base64" />
                <xsl:text>",&#xa;</xsl:text>
            </xsl:when>
            <xsl:when test="@source">
                <xsl:text>filename:"</xsl:text>
                <!-- empty when not using managed directories -->
                <xsl:value-of select="$external-directory"/>
                <xsl:value-of select="@source" />
                <xsl:text>",&#xa;</xsl:text>
            </xsl:when>
            <xsl:when test="@material">
                <xsl:text>material_id:"</xsl:text>
                <xsl:value-of select="@material" />
                <xsl:text>",&#xa;</xsl:text>
            </xsl:when>
            <xsl:when test="@geogebra">
                <xsl:message>PTX Warning:  "geogebra" attribute on "slate" element is deprecated; use "material" attribute</xsl:message>
                <xsl:text>material_id:"</xsl:text>
                <xsl:value-of select="@geogebra" />
                <xsl:text>",&#xa;</xsl:text>
            </xsl:when>
            <!-- Now must be authored in source, so we can check for   -->
            <!-- setting perspective via an attribute.  This bypasses  -->
            <!-- a bug where using "setPerspective()" in source caused -->
            <!-- the focus to be grabbed here.                         -->
            <xsl:otherwise>
                <xsl:if test="@perspective">
                    <xsl:text>perspective:"</xsl:text>
                    <xsl:value-of select="@perspective"/>
                    <xsl:text>",&#xa;</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>width:</xsl:text><xsl:value-of select="$material-width" />
        <xsl:text>,&#xa;</xsl:text>
        <xsl:text>height:</xsl:text><xsl:value-of select="$material-height" />
        <xsl:text>,&#xa;</xsl:text>
        <xsl:if test="normalize-space(text())">
            <xsl:text>appletOnLoad:</xsl:text>
            <xsl:value-of select="$applet-onload" />
        </xsl:if>
        <xsl:text>};&#xa;</xsl:text>

        <xsl:text>new Promise((resolve, reject) => {&#xa;</xsl:text>
        <xsl:text>var </xsl:text>
            <xsl:value-of select="$applet-name" />
        <xsl:text> = new GGBApplet(</xsl:text>
            <xsl:value-of select="$applet-parameters" />
        <xsl:text>, true);&#xa;</xsl:text>

      <xsl:text>resolve(</xsl:text><xsl:value-of select="$applet-name" /><xsl:text>);})&#xa;</xsl:text>
      <xsl:text>.then((</xsl:text><xsl:value-of select="$applet-name" /><xsl:text>) => {&#xa;</xsl:text>
        <!-- inject the applet into the div below -->
        <xsl:text>window.onload = function() { </xsl:text>
        <xsl:value-of select="$applet-name" />
        <xsl:text>.inject('</xsl:text>
        <xsl:value-of select="$applet-container" />
        <xsl:text>'); }&#xa;</xsl:text>
        <xsl:text>},&#xa;</xsl:text>
        <xsl:text>(error) => {console.log('GGB applet load failure.', error)});&#xa;</xsl:text>
    </script>
    <!-- build a container div with the right shape -->
    <div class="geogebra-applet" id="{$applet-container}">
        <xsl:apply-templates select="." mode="size-pixels-style-attribute" />
    </div>
</xsl:template>

<xsl:template match="slate[@surface = 'jessiecode']">
  <!-- size of the window, to be passed as a parameter -->
  <xsl:variable name="width">
      <xsl:apply-templates select="." mode="get-width-pixels" />
  </xsl:variable>
  <xsl:variable name="height">
      <xsl:apply-templates select="." mode="get-height-pixels" />
  </xsl:variable>
  <!-- the div that jsxgraph will take over -->
  <xsl:element name="div">
      <xsl:attribute name="id">
          <xsl:apply-templates select="." mode="visible-id" />
      </xsl:attribute>
      <xsl:attribute name="class">
          <xsl:text>jxgbox</xsl:text>
      </xsl:attribute>
      <xsl:apply-templates select="." mode="size-pixels-style-attribute" />
  </xsl:element>
  <!-- Add a script wrapper to parse using JSXGraph -->
  <xsl:choose>
      <xsl:when test="text()">
          <xsl:element name="script">
              <xsl:attribute name="type">
                  <xsl:text>text/jessiecode</xsl:text>
              </xsl:attribute>
              <!-- Put the board in the appropriate container. -->
              <xsl:attribute name="container">
                  <xsl:apply-templates select="." mode="visible-id" />
              </xsl:attribute>
              <xsl:if test="@boundingbox">
                  <xsl:attribute name="boundingbox">
                      <xsl:value-of select="@boundingbox" />
                  </xsl:attribute>
              </xsl:if>
              <xsl:if test="@axis">
                  <xsl:attribute name="axis">
                      <xsl:value-of select="@axis" />
                  </xsl:attribute>
              </xsl:if>
              <xsl:if test="@grid">
                  <xsl:attribute name="grid">
                      <xsl:value-of select="@grid" />
                  </xsl:attribute>
              </xsl:if>
              <!-- Add the script -->
              <xsl:call-template name="sanitize-text">
                  <xsl:with-param name="text" select="." />
              </xsl:call-template>
          </xsl:element>
      </xsl:when>
      <xsl:when test="@source">
          <xsl:element name="script">
              <xsl:attribute name="type">
                  <xsl:text>text/javascript</xsl:text>
              </xsl:attribute>
              <xsl:text>function parseJessie(code) {&#xa;</xsl:text>
              <xsl:text>  let board = JXG.JSXGraph.initBoard('</xsl:text>
              <xsl:apply-templates select="." mode="visible-id" />
              <xsl:text>', {</xsl:text>
              <xsl:if test="@boundingbox">
                  <xsl:text>boundingbox:[</xsl:text>
                  <xsl:value-of select="@boundingbox" />
                  <xsl:text>], </xsl:text>
              </xsl:if>
              <xsl:if test="@axis">
                  <xsl:text>axis:</xsl:text>
                  <xsl:value-of select="@axis" />
                  <xsl:text>, </xsl:text>
              </xsl:if>
              <xsl:if test="@grid">
                  <xsl:text>grid:</xsl:text>
                  <xsl:value-of select="@grid" />
                  <xsl:text>, </xsl:text>
              </xsl:if>
              <xsl:text>keepaspectratio:true});&#xa;</xsl:text>
              <xsl:text>  board.jc = new JXG.JessieCode();&#xa;</xsl:text>
              <xsl:text>  board.jc.use(board);&#xa;</xsl:text>
              <xsl:text>  board.suspendUpdate();&#xa;</xsl:text>
              <xsl:text>  board.jc.parse(code);&#xa;</xsl:text>
              <xsl:text>  board.unsuspendUpdate();&#xa;</xsl:text>
              <xsl:text>}&#xa;</xsl:text>
              <xsl:text>fetch('</xsl:text>
              <!-- empty when not using managed directories -->
              <xsl:value-of select="$external-directory"/>
              <xsl:value-of select="@source" />
              <xsl:text>').then(function(response) { response.text().then( function(text) { parseJessie(text); }); });&#xa;</xsl:text>
          </xsl:element>
      </xsl:when>
  </xsl:choose>
</xsl:template>

<xsl:template match="slate[@surface = 'doenetml']">
    <div class="doenetml-applet" data-doenet-add-virtual-keyboard="false" data-doenet-send-resize-events="true">
        <div class="doenetml-loading" style="text-align:center">
            <p><img src="https://www.doenet.org/Doenet_Logo_Frontpage.png"/></p>
            <p><xsl:text>Waiting on the page to load...</xsl:text></p>
        </div>
        <script type="text/doenetml">
            <xsl:value-of select="text()"/>
        </script>
    </div>
</xsl:template>

<!-- Utilities -->

<!-- These can be vastly improved with a call to "tokenize()"   -->
<!-- and then a "for-each" can effectively loop over the pieces -->

<!-- @source attribute to multiple script tags -->
<xsl:template match="interactive[@platform]/@source">
    <xsl:variable name="scripts" select="str:tokenize(., ', ')"/>
    <!-- $scripts is a collection of "token" and does not have -->
    <!-- a root, which implies the form of the "for-each"      -->
    <xsl:for-each select="$scripts">
        <!-- create a script tag for each JS file -->
        <script>
            <!-- this is a hack to allow for local files and network resources,   -->
            <!-- with or without managed directories.  There should be a separate -->
            <!-- attribute like an @href used for audio and video, and then any   -->
            <!-- "http"-leading string should be flagged as a deprecation         -->
            <xsl:variable name="location">
                <xsl:variable name="raw-location">
                    <xsl:value-of select="."/>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="substring($raw-location,1,4) = 'http'">
                        <xsl:value-of select="$raw-location"/>
                    </xsl:when>
                    <xsl:when test="not($b-managed-directories)">
                        <xsl:value-of select="$raw-location"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- empty when not using managed directories -->
                        <xsl:value-of select="$external-directory"/>
                        <xsl:value-of select="$raw-location"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:attribute name="src">
                <xsl:value-of select="$location" />
            </xsl:attribute>
        </script>
    </xsl:for-each>
</xsl:template>

<!-- @css attribute to multiple "link" element -->
<xsl:template match="interactive[@platform]/@css">
    <xsl:variable name="csses" select="str:tokenize(., ', ')"/>
    <!-- $scripts is a collection of "token" and does not have -->
    <!-- a root, which implies the form of the "for-each"      -->
    <xsl:for-each select="$csses">
        <link rel="stylesheet" type="text/css">
            <!-- This is a hack to allow for local files and network -->
            <!-- resources, with or without managed directories.     -->
            <xsl:variable name="location">
                <xsl:variable name="raw-location">
                    <xsl:value-of select="."/>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="substring($raw-location,1,4) = 'http'">
                        <xsl:value-of select="$raw-location"/>
                    </xsl:when>
                    <xsl:when test="not($b-managed-directories)">
                        <xsl:value-of select="$raw-location"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- empty when not using managed directories -->
                        <xsl:value-of select="$external-directory"/>
                        <xsl:value-of select="$raw-location"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:attribute name="href">
                <xsl:value-of select="$location" />
            </xsl:attribute>
        </link>
    </xsl:for-each>
</xsl:template>

<!-- Next two utilities write attributes, so cannot go in -common -->

<!-- iframes, etc, need size as a pair of attributes in pixels -->
<xsl:template match="*" mode="size-pixels-attributes">
    <xsl:attribute name="width">
        <xsl:apply-templates select="." mode="get-width-pixels" />
    </xsl:attribute>
    <xsl:attribute name="height">
        <xsl:apply-templates select="." mode="get-height-pixels" />
    </xsl:attribute>
</xsl:template>

<!-- div's need size in a style attribute -->
<xsl:template match="*" mode="size-pixels-style-attribute">
    <xsl:variable name="width">
        <xsl:apply-templates select="." mode="get-width-pixels" />
    </xsl:variable>
    <xsl:variable name="height">
        <xsl:apply-templates select="." mode="get-height-pixels" />
    </xsl:variable>
    <xsl:attribute name="style">
        <xsl:text>width:</xsl:text>
        <xsl:value-of select="$width" />
        <xsl:text>px; </xsl:text>
        <xsl:text>height:</xsl:text>
        <xsl:value-of select="$height" />
        <xsl:text>px; </xsl:text>
        <xsl:text>display: block; </xsl:text>
        <xsl:text>box-sizing: border-box; -moz-box-sizing: border-box; -webkit-box-sizing: border-box;</xsl:text>
    </xsl:attribute>
</xsl:template>

<!-- Add js from script elemenets inside interactives     -->
<!-- Scripts are added in order, after all other elements -->
<!-- in the interactive, include scripts created from     -->
<!-- @source directives in the interactive element        -->
<xsl:template match="interactive[@platform = 'javascript']/script">
    <script>
        <xsl:value-of select="."/>
    </script>
</xsl:template>

<!-- JSXGraph -->
<!-- DEPRECATED (2018-04-06)                             -->
<!-- Restrict edits to cosmetic, no functional change    -->
<!-- Remove when continued maintenance becomes untenable -->
<xsl:template match="jsxgraph">
    <!-- interpret @width percentage and @aspect ratio -->
    <xsl:variable name="width-percent">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:variable name="width-fraction">
        <xsl:value-of select="substring-before($width-percent,'%') div 100" />
    </xsl:variable>
    <xsl:variable name="aspect-ratio">
        <xsl:apply-templates select="." mode="get-aspect-ratio">
            <xsl:with-param name="default-aspect" select="'1:1'" />
        </xsl:apply-templates>
    </xsl:variable>
    <!-- these are now standardized templates -->
    <xsl:variable name="width"  select="$design-width * $width-fraction" />
    <xsl:variable name="height" select="$design-width * $width-fraction div $aspect-ratio" />
    <!-- the div to hold the JSX output -->
    <xsl:element name="div">
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="visible-id" />
        </xsl:attribute>
        <xsl:attribute name="class">
            <xsl:text>jxgbox</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="style">
            <xsl:text>width:</xsl:text>
            <xsl:value-of select="$width" />
            <xsl:text>px; height:</xsl:text>
            <xsl:value-of select="$height" />
            <xsl:text>px;</xsl:text>
        </xsl:attribute>
    </xsl:element>
    <!-- the script to hold the code                       -->
    <!-- JSXGraph code must reference the id on the div,   -->
    <!-- so ideally an xml:id specifies this in the source -->
    <xsl:element name="script">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="input" />
        </xsl:call-template>
    </xsl:element>
    <xsl:copy-of select="controls" />
</xsl:template>

<!-- ########################## -->
<!-- WeBWorK Embedded Exercises -->
<!-- ########################## -->

<!-- WeBWorK Javascript header -->
<xsl:template name="webwork-js">
    <xsl:if test="$b-has-webwork-reps">
        <script src="{$html.js.dir}/pretext-webwork/2.{$webwork-minor-version}/pretext-webwork.js"></script>
        <script src="{$webwork-server}/webwork2_files/node_modules/iframe-resizer/js/iframeResizer.min.js"></script>
    </xsl:if>
</xsl:template>

<!-- lti-iframe-resizer -->
<xsl:template name="lti-iframe-resizer">
    <script src="{$html.js.dir}/lti_iframe_resizer.js"></script>
</xsl:template>


<!-- Fail if WeBWorK extraction and merging has not been done -->
<xsl:template match="webwork[*]">
    <xsl:message>PTX:ERROR: A document that uses WeBWorK nees to incorporate a file</xsl:message>
    <xsl:message>of representations of WW problems.  These can be created with the</xsl:message>
    <xsl:message>"pretext" Python script and specified in a publisher file.</xsl:message>
    <xsl:message>See the documentation for details.</xsl:message>
</xsl:template>

<!-- The guts of a WeBWorK problem realized in HTML -->
<!-- This is heart of an external knowl version, or -->
<!-- what is born visible under control of a switch -->
<xsl:template match="webwork-reps">
    <xsl:param name="b-original" select="true()"/>
    <!-- TODO: simplify these variables, much like for LaTeX -->
    <xsl:variable name="b-has-hint" select="(ancestor::*[&PROJECT-FILTER;] and $b-has-project-hint) or
                                            (ancestor::exercises and $b-has-divisional-hint) or
                                            (ancestor::reading-questions and $b-has-reading-hint) or
                                            (ancestor::worksheet and $b-has-worksheet-hint) or
                                            (not(ancestor::*[&PROJECT-FILTER;] or ancestor::exercises or ancestor::reading-questions or ancestor::worksheet) and $b-has-inline-hint)" />
    <xsl:variable name="b-has-answer" select="(ancestor::*[&PROJECT-FILTER;] and $b-has-project-answer) or
                                              (ancestor::exercises and $b-has-divisional-answer) or
                                              (ancestor::reading-questions and $b-has-reading-answer) or
                                              (ancestor::worksheet and $b-has-worksheet-answer) or
                                              (not(ancestor::*[&PROJECT-FILTER;] or ancestor::exercises or ancestor::reading-questions or ancestor::worksheet) and $b-has-inline-answer)" />
    <xsl:variable name="b-has-solution" select="(ancestor::*[&PROJECT-FILTER;] and $b-has-project-solution) or
                                                (ancestor::exercises and $b-has-divisional-solution) or
                                                (ancestor::reading-questions and $b-has-reading-solution) or
                                                (ancestor::worksheet and $b-has-worksheet-solution) or
                                                (not(ancestor::*[&PROJECT-FILTER;] or ancestor::exercises or ancestor::reading-questions or ancestor::worksheet) and $b-has-inline-solution)"/>
    <xsl:variable name="b-static" select="(ancestor::*[&PROJECT-FILTER;] and $b-webwork-project-static) or
                                          (ancestor::exercises and $b-webwork-divisional-static) or
                                          (ancestor::reading-questions and $b-webwork-reading-static) or
                                          (ancestor::worksheet and $b-webwork-worksheet-static) or
                                          (not(ancestor::*[&PROJECT-FILTER;] or ancestor::exercises or ancestor::reading-questions or ancestor::worksheet) and $b-webwork-inline-static)"/>
    <xsl:choose>
        <!-- We print the static version when that is explicitly directed. -->
        <xsl:when test="$b-static">
            <xsl:apply-templates select="static" mode="exercise-components">
                <xsl:with-param name="b-original"      select="$b-original"/>
                <xsl:with-param name="b-has-statement" select="true()"/>
                <xsl:with-param name="b-has-hint"      select="$b-has-hint"/>
                <xsl:with-param name="b-has-answer"    select="$b-has-answer"/>
                <xsl:with-param name="b-has-solution"  select="$b-has-solution"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="webwork-interactive-div">
                <xsl:with-param name="b-original"     select="$b-original"/>
                <xsl:with-param name="b-has-hint"     select="$b-has-hint"/>
                <xsl:with-param name="b-has-answer"   select="$b-has-answer"/>
                <xsl:with-param name="b-has-solution" select="$b-has-solution"/>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Make a div with a button, where pretext-webwork.js can   -->
<!-- replace the div content with a live, interactive problem -->
<xsl:template match="webwork-reps" mode="webwork-interactive-div">
    <xsl:param name="b-original"/>
    <xsl:param name="b-has-hint"/>
    <xsl:param name="b-has-answer"/>
    <xsl:param name="b-has-solution"/>

    <!-- For Runestone, the WW problem is handled in isolation, -->
    <!-- yet capturing and storing student work/results needs   -->
    <!-- to be associated with the parent/enclosing "exercise"  -->
    <!-- (or PROJECT-LIKE).  So in this case (only) we place    -->
    <!-- an id value on the  div.exercise-wrapper that is       -->
    <!-- derived from the parent.  Otherwise, we use the id     -->
    <!-- placed on the "webwork-reps" in @ww-id.                -->
    <xsl:variable name="inner-id">
        <xsl:choose>
            <xsl:when test="$b-host-runestone">
                <xsl:apply-templates select="parent::*" mode="runestone-id"/>
                <xsl:text>-ww-rs</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@ww-id"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <div id="{$inner-id}" class="exercise-wrapper">
        <xsl:attribute name="data-domain">
            <xsl:value-of select="$webwork-server"/>
        </xsl:attribute>
        <xsl:attribute name="data-seed" >
            <xsl:value-of select="static/@seed"/>
        </xsl:attribute>
        <xsl:attribute name="data-localize-correct">
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'correct'"/>
            </xsl:apply-templates>
        </xsl:attribute>
        <xsl:attribute name="data-localize-incorrect">
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'incorrect'"/>
            </xsl:apply-templates>
        </xsl:attribute>
        <xsl:attribute name="data-localize-blank">
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'blank'"/>
            </xsl:apply-templates>
        </xsl:attribute>
        <xsl:attribute name="data-localize-submit">
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'submit'"/>
            </xsl:apply-templates>
        </xsl:attribute>
        <xsl:attribute name="data-localize-check-responses">
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'check-responses'"/>
            </xsl:apply-templates>
        </xsl:attribute>
        <xsl:attribute name="data-localize-reveal">
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'reveal'"/>
            </xsl:apply-templates>
        </xsl:attribute>
        <xsl:attribute name="data-localize-randomize">
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'randomize'"/>
            </xsl:apply-templates>
        </xsl:attribute>
        <xsl:attribute name="data-localize-reset">
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'reset'"/>
            </xsl:apply-templates>
        </xsl:attribute>
        <xsl:attribute name="data-localize-hint">
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'hint'"/>
            </xsl:apply-templates>
        </xsl:attribute>
        <xsl:attribute name="data-localize-solution">
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'solution'"/>
            </xsl:apply-templates>
        </xsl:attribute>
        <xsl:attribute name="data-origin">
            <xsl:value-of select="rendering-data/@origin"/>
        </xsl:attribute>
        <xsl:choose>
            <xsl:when test="rendering-data/@problemSource">
                <xsl:attribute name="data-problemSource">
                    <xsl:value-of select="rendering-data/@problemSource"/>
                </xsl:attribute>
                <!-- When rendering a problem with problemSource, we want to know the base course id -->
                <xsl:attribute name="data-documentID">
                    <xsl:value-of select="$document-id"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:when test="rendering-data/@sourceFilePath">
                <xsl:attribute name="data-sourceFilePath">
                    <xsl:value-of select="rendering-data/@sourceFilePath"/>
                </xsl:attribute>
            </xsl:when>
        </xsl:choose>
        <xsl:attribute name="data-courseID">
            <xsl:value-of select="rendering-data/@course-id"/>
        </xsl:attribute>
        <xsl:attribute name="data-userID">
            <xsl:value-of select="rendering-data/@user-id"/>
        </xsl:attribute>
        <xsl:attribute name="data-coursePassword">
            <xsl:choose>
                <xsl:when test="rendering-data/@passwd">
                    <xsl:value-of select="rendering-data/@passwd"/>
                </xsl:when>
                <!-- Old representations files will have one of the following @password -->
                <xsl:when test="rendering-data/@password">
                    <xsl:value-of select="rendering-data/@password"/>
                </xsl:when>
                <!-- Old representations files will have @course-password instead of @password -->
                <xsl:otherwise>
                    <xsl:value-of select="rendering-data/@course-password"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:attribute name="aria-live">
            <xsl:value-of select="'polite'"/>
        </xsl:attribute>
        <div class="problem-buttons">
            <button class="webwork-button" onclick="handleWW('{$inner-id}')">
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'activate'"/>
                </xsl:apply-templates>
            </button>
        </div>
        <div class="problem-contents">
            <xsl:apply-templates select="static" mode="exercise-components">
                <xsl:with-param name="b-original"      select="$b-original"/>
                <xsl:with-param name="b-has-statement" select="true()"/>
                <xsl:with-param name="b-has-hint"      select="$b-has-hint"/>
                <xsl:with-param name="b-has-answer"    select="$b-has-answer"/>
                <xsl:with-param name="b-has-solution"  select="$b-has-solution"/>
            </xsl:apply-templates>
        </div>
    </div>
</xsl:template>

<!-- Select the correct URL from four pre-generated choices -->
<!-- and package up as an iframe for interactive version    -->
<!-- Used with 2.15- WW servers (webwork-reps version 1)    -->
<xsl:template match="webwork-reps" mode="webwork-iframe">
    <xsl:param name="b-has-hint"/>
    <xsl:param name="b-has-solution"/>
    <xsl:variable name="the-url">
        <xsl:choose>
            <xsl:when test="$b-has-hint and $b-has-solution">
                <xsl:apply-templates select="server-url[@hint='yes' and @solution='yes']"/>
            </xsl:when>
            <xsl:when test="$b-has-hint and not($b-has-solution)">
                <xsl:apply-templates select="server-url[@hint='yes' and @solution='no']"/>
            </xsl:when>
            <xsl:when test="not($b-has-hint) and $b-has-solution">
                <xsl:apply-templates select="server-url[@hint='no'  and @solution='yes']"/>
            </xsl:when>
            <xsl:when test="not($b-has-hint) and not($b-has-solution)">
                <xsl:apply-templates select="server-url[@hint='no'  and @solution='no']"/>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <!-- build the iframe -->
    <!-- mimicking Mike Gage's blog post -->
    <iframe name="{@ww-id}" width="{$design-width}" src="{$the-url}" data-seed="{static/@seed}"/>
    <script>
        <xsl:text>iFrameResize({log:true,inPageLinks:true,resizeFrom:'child',checkOrigin:["</xsl:text>
        <xsl:value-of select="$webwork-server" />
        <xsl:text>"]})</xsl:text>
    </script>
</xsl:template>

<!-- ############################# -->
<!-- STACK Embedded Exercises -->
<!-- ############################# -->

<!-- STACK Javascript header -->
<xsl:template name="stack-js">

    <xsl:if test="$b-has-stack">
        <!-- Note: MathJax2 is required for HTML STACK problems to render.  -->
        <!-- But loading this conflicts with v3 (and presumably v4 in major -->
        <!-- ways.  The offending command has been commented out, so        -->
        <!-- testing might proceed on certain aspects.                      -->
        <!-- <script src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.7/MathJax.js?config=TeX-MML-AM_CHTML" type="text/javascript"></script> -->
        <script src="{$html.js.dir}/pretext-stack/stackjsvle.js" type="text/javascript"></script>
        <script src="{$html.js.dir}/pretext-stack/stackapicalls.js" type="text/javascript"></script>
        <script type="text/javascript">
            const stack_api_url = "<xsl:value-of select="$stack-server"/>";
        </script>
        <script type="text/javascript">
            function docHasLoaded() {
                stackSetup();
            }
        </script>
    </xsl:if>
</xsl:template>

<!-- Not to be confused with  sidebyside/stack  panel -->
<xsl:template match="exercise/stack">

    <!-- The location in HTML output where files of STACK -->
    <!-- questions live, ready to be fed into Javascript  -->
    <!-- and servers. Analagous to where xref knowl files -->
    <!-- live, a production as part of an HTML build.     -->
    <xsl:variable name="stack-dir">
        <xsl:text>stack/</xsl:text>
    </xsl:variable>

    <!-- the file we build and the file we serve up -->
    <xsl:variable name="the-filename">
        <xsl:value-of select="$stack-dir"/>
        <xsl:value-of select="@label"/>
        <xsl:text>.xml</xsl:text>
    </xsl:variable>

    <!-- Write out the STACK (XML) source as a file in the HTML output -->
    <!-- TODO: make this a general purpose templare (in -common)  -->
    <!-- TODO: use an "edit" template to scrub junk from assembly -->
    <!--       Note: @xml:base might be worth keeping/adjusting   -->
    <exsl:document href="{$the-filename}" method="xml" indent="yes" encoding="UTF-8">
        <!-- don't copy the "stack" element, just children -->
        <xsl:copy-of select="node()"/>
    </exsl:document>

    <!-- Replace the source by a bit of HTML -->
    <!-- for Javascript to find and act on   -->
    <div class="container-fluid que stack">
        <xsl:attribute name="data-qfile">
            <xsl:value-of select="$the-filename"/>
        </xsl:attribute>
        <xsl:if test="@qname != ''">
            <xsl:attribute name="data-qname">
                <xsl:value-of select="@qname" />
            </xsl:attribute>
        </xsl:if>
    </div>
</xsl:template>

<!-- ############################# -->
<!-- MyOpenMath Embedded Exercises -->
<!-- ############################# -->

<xsl:template match="myopenmath">
    <!-- A container controls the width. At 100% this is the     -->
    <!-- full page width and when revealed in a knowl it shrinks -->
    <!-- to fill available width.  In another application, the   -->
    <!-- width might come from an author's source.               -->
    <xsl:variable name="an-id">
        <xsl:apply-templates select="." mode="html-id"/>
    </xsl:variable>
    <div id="mom{$an-id}wrap" style="width:100%;overflow:visible;position:relative">
        <!-- This preserves the aspect-ratio, and there is no       -->
        <!-- clipping.  Basically this says scale the iframe to     -->
        <!-- fill whatever width is available in the containing div -->
        <iframe id="mom{$an-id}" style="position:absolute;z-index:1;object-fit: contain; width: 100%"
            frameborder="0" data-knowl-callback="sendResizeRequest">
            <xsl:attribute name="src">
                <xsl:text>https://www.myopenmath.com/embedq2.php?id=</xsl:text>
                <xsl:value-of select="@problem" />
                <!-- can't disable escaping text of an attribute -->
                <xsl:text>&amp;frame_id=mom</xsl:text>
                <xsl:value-of select="$an-id" />
                <xsl:if test="@params != ''">
                    <xsl:text>&amp;</xsl:text>
                    <xsl:value-of select="str:replace(@params, ',', '&amp;')" />
                </xsl:if>
            </xsl:attribute>
        </iframe>
    </div>
</xsl:template>

<!--                         -->
<!-- Web Page Infrastructure -->
<!--                         -->

<!-- Start by building a series of "cache" variables that hold common head/foot -->
<!-- page elements. Ideally, all pages types can be kept in a strict ordering   -->
<!-- of complexity so each cahce is a superset of the previous ones.            -->

<!-- Start with what is required by iframes -->
<xsl:variable name="file-wrap-iframe-head-cache">
    <xsl:call-template name="fonts"/>
    <xsl:call-template name="font-awesome"/>
    <xsl:call-template name="css"/>
    <xsl:call-template name="mathjax"/>
</xsl:variable>

<!-- Build a cache of the head elements that are constant across ALL standalone -->
<!-- pages in the document. Main targets are "standalone" pages for meadia and  -->
<!-- interactive extraction.                                                    -->
<xsl:variable name="file-wrap-basic-head-cache">
    <xsl:copy-of select="$file-wrap-iframe-head-cache"/>
    <!-- Add keywords, including those in bibinfo -->
    <xsl:call-template name="keywords-meta-element"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <!-- more "meta" elements for discovery -->
    <xsl:call-template name="open-graph-info"/>
    <xsl:call-template name="pretext-js"/>
    <xsl:call-template name="runestone-header"/>
    <xsl:call-template name="diagcess-header"/>
</xsl:variable>

<!-- Content used by simple-file-wrap -->
<xsl:variable name="file-wrap-simple-head-cache">
    <xsl:copy-of select="$file-wrap-basic-head-cache"/>
    <xsl:call-template name="sagecell-code" />
    <xsl:call-template name="favicon"/>
    <xsl:call-template name="webwork-js"/>
    <xsl:call-template name="stack-js"/>
    <xsl:call-template name="lti-iframe-resizer"/>
    <xsl:call-template name="syntax-highlight"/>
    <xsl:call-template name="hypothesis-annotation" />
    <xsl:call-template name="geogebra" />
    <xsl:call-template name="jsxgraph" />
    <xsl:call-template name="mermaid-header" />
</xsl:variable>

<!-- Content used by main file-wrap template -->
<xsl:variable name="file-wrap-full-head-cache">
    <xsl:copy-of select="$file-wrap-simple-head-cache"/>
    <xsl:call-template name="google-search-box-js" />
    <xsl:call-template name="native-search-box-js" />
</xsl:variable>

<!-- Generate a version of file-wrap-full-head-cache customized for use in -->
<!-- printable worksheets and handouts. There does not seem to be a better -->
<!-- (and straightforward) method other than duplicating above work.       -->
<xsl:variable name="file-wrap-full-head-cache-printable">
    <!-- file-wrap-iframe-head-cache -->
    <xsl:call-template name="fonts"/>
    <xsl:call-template name="font-awesome"/>
    <xsl:call-template name="css-printable"/>
    <xsl:call-template name="mathjax"/>
    <!-- file-wrap-basic-head-cache -->
    <xsl:call-template name="keywords-meta-element"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <xsl:call-template name="open-graph-info"/>
    <xsl:call-template name="pretext-js"/>
    <xsl:call-template name="runestone-header"/>
    <xsl:call-template name="diagcess-header"/>
    <!-- file-wrap-simple-head-cache -->
    <xsl:call-template name="sagecell-code" />
    <xsl:call-template name="favicon"/>
    <xsl:call-template name="webwork-js"/>
    <xsl:call-template name="stack-js"/>
    <xsl:call-template name="lti-iframe-resizer"/>
    <xsl:call-template name="syntax-highlight"/>
    <xsl:call-template name="hypothesis-annotation" />
    <xsl:call-template name="geogebra" />
    <xsl:call-template name="jsxgraph" />
    <xsl:call-template name="mermaid-header" />
    <!-- file-wrap-full-head-cache -->
    <xsl:call-template name="google-search-box-js" />
    <xsl:call-template name="native-search-box-js" />
</xsl:variable>

<!-- Now build end of body caches in the same manner          -->
<!-- Again, start with univeral content and build from there  -->

<!-- basic content is in any standalone page-->
<xsl:variable name="file-wrap-basic-endbody-cache">
    <xsl:call-template name="statcounter"/>
    <xsl:call-template name="google-classic"/>
    <xsl:call-template name="google-universal"/>
    <xsl:call-template name="google-gst"/>
    <xsl:call-template name="diagcess-footer"/>
    <xsl:call-template name="extra-js-footer"/>
</xsl:variable>

<!-- extra contents for main file-wrap template -->
<xsl:variable name="file-wrap-full-endbody-cache">
    <xsl:copy-of select="$file-wrap-basic-endbody-cache"/>
    <xsl:call-template name="runestone-ethical-ads"/>
</xsl:variable>

<xsl:template name="pretext-advertisement-and-style">
    <!-- 40 characters within comment for each line -->
    <xsl:variable name="fixed-width-theme"
        select="concat(substring(concat($html-theme-name,   '                               '), 1, 31), '*')"/>
    <xsl:variable name="fixed-width-palette"
        select="concat(substring(concat($html-palette-name, '                               '), 1, 29), '*')"/>
    <xsl:comment>******************************************</xsl:comment><xsl:text>&#xa;</xsl:text>
    <xsl:comment>*  Authored with PreTeXt                 *</xsl:comment><xsl:text>&#xa;</xsl:text>
    <xsl:comment>*  pretextbook.org                       *</xsl:comment><xsl:text>&#xa;</xsl:text>
    <xsl:comment>*  Theme: <xsl:value-of select="$fixed-width-theme"/></xsl:comment><xsl:text>&#xa;</xsl:text>
    <xsl:comment>*  Palette: <xsl:value-of select="$fixed-width-palette"/></xsl:comment><xsl:text>&#xa;</xsl:text>
    <xsl:comment>******************************************</xsl:comment><xsl:text>&#xa;</xsl:text>
</xsl:template>



<!-- An individual page:                                   -->
<!-- Inputs:                                               -->
<!-- * page content (exclusive of banners, navigation etc) -->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />
    <xsl:param name="filename" select="''"/>
    <xsl:param name="b-printable" select="false()"/>

    <xsl:variable name="the-filename">
        <xsl:choose>
            <xsl:when test="not($filename = '')">
                <xsl:value-of select="$filename"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="containing-filename" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Experimental - companion, chunked HTML -->
    <xsl:if test="$debug.editable = 'yes'">
        <xsl:variable name="the-source-filename">
            <xsl:value-of select="str:replace($the-filename, '.html', '.ptx')"/>
        </xsl:variable>
        <exsl:document href="{$the-source-filename}" method="xml" omit-xml-declaration="no" indent="yes" encoding="UTF-8">
            <xsl:copy-of select="."/>
        </exsl:document>
    </xsl:if>

    <exsl:document href="{$the-filename}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
    <xsl:call-template name="converter-blurb-html-no-date"/>
    <html>
        <xsl:call-template name="language-attributes"/>
        <xsl:call-template name="html-theme-attributes"/>
        <xsl:call-template name="pretext-advertisement-and-style"/>
        <!-- Open Graph Protocol only in "meta" elements, within "head" -->
        <head xmlns:og="http://ogp.me/ns#" xmlns:book="https://ogp.me/ns/book#">
            <title>
                <!-- Leading with initials is useful for small tabs -->
                <xsl:if test="$docinfo/initialism">
                    <xsl:apply-templates select="$docinfo/initialism" />
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:apply-templates select="." mode="title-plain" />
            </title>
            <!-- canonical link for better SEO -->
            <xsl:call-template name="canonical-link">
                <xsl:with-param name="filename" select="$the-filename"/>
            </xsl:call-template>
            <!-- grab the contents every page gets -->
            <xsl:choose>
                <xsl:when test="$b-printable">
                    <xsl:copy-of select="$file-wrap-full-head-cache-printable"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$file-wrap-full-head-cache"/>
                </xsl:otherwise>
            </xsl:choose>
            <!-- now do anything that is or could be page-specific and comes after cache -->
            <xsl:apply-templates select="." mode="knowl" />
            <!-- webwork's iframeResizer needs to come before sagecell template -->
            <xsl:apply-templates select="." mode="sagecell" />
        </head>
        <body>
            <xsl:if test="$b-has-stack">
                <xsl:attribute name="onload">
                    <xsl:text>docHasLoaded()</xsl:text>
                </xsl:attribute>
            </xsl:if>

            <!-- potential document-id per-page -->
            <xsl:call-template name="document-id"/>
            <!-- React flag -->
            <xsl:call-template name="react-in-use-flag"/>
            <!-- the first class controls the default icon -->
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="$root/book">pretext book</xsl:when>
                    <xsl:when test="$root/article">pretext article</xsl:when>
                </xsl:choose>
                <!-- ignore MathJax signals everywhere, then enable selectively -->
                <xsl:text> ignore-math</xsl:text>
            </xsl:attribute>
            <!-- assistive "Skip to main content" link    -->
            <!-- this *must* be first for maximum utility -->
            <xsl:call-template name="skip-to-content-link" />
            <!-- HTML5 body/header will be a "banner" landmark automatically -->
            <header id="ptx-masthead" class="ptx-masthead">
                <div class="ptx-banner">
                    <xsl:call-template name="brand-logo" />
                    <div class="title-container">
                        <h1 class="heading">
                            <xsl:variable name="root-filename">
                                <xsl:apply-templates select="$document-root" mode="containing-filename" />
                            </xsl:variable>
                            <a href="{$root-filename}">
                                <xsl:variable name="b-has-subtitle" select="boolean($document-root/subtitle)"/>
                                <span class="title">
                                    <!-- Do not use shorttitle in masthead,  -->
                                    <!-- which is much like cover of a book  -->
                                    <xsl:apply-templates select="$document-root" mode="title-simple" />
                                </span>
                                <xsl:if test="$b-has-subtitle">
                                    <xsl:text> </xsl:text>
                                    <span class="subtitle">
                                        <xsl:apply-templates select="$document-root" mode="subtitle" />
                                    </span>
                                </xsl:if>
                            </a>
                        </h1>
                        <!-- Serial list of authors/editors -->
                        <p class="byline">
                            <xsl:apply-templates select="$bibinfo/author" mode="name-list"/>
                            <xsl:apply-templates select="$bibinfo/editor" mode="name-list"/>
                        </p>
                    </div>  <!-- title-container -->
                </div>  <!-- banner -->
            </header>  <!-- masthead -->
            <xsl:apply-templates select="." mode="primary-navigation"/>
            <xsl:call-template name="latex-macros"/>
            <xsl:call-template name="enable-editing"/>
            <div class="ptx-page">
                <xsl:apply-templates select="." mode="sidebars" />
                <!-- HTML5 main will be a "main" landmark automatically -->
                <main class="ptx-main">
                    <xsl:if test="$b-watermark">
                        <xsl:attribute name="style">
                            <xsl:value-of select="$watermark-css"/>
                        </xsl:attribute>
                    </xsl:if>
                    <div id="ptx-content" class="ptx-content">
                        <xsl:if test="$b-printable">
                            <div class="print-preview-header">
                                <xsl:apply-templates select="." mode="print-preview-header"/>
                                <div class="print-controls">
                                    <div class="print-controls-toggles">
                                        <xsl:apply-templates select="." mode="papersize-toggle"/>
                                        <xsl:apply-templates select="." mode="highlight-workspace-toggle"/>
                                    </div>
                                    <xsl:apply-templates select="." mode="print-button"/>
                                </div>
                            </div>
                        </xsl:if>
                        <!-- Alternative to "copy-of": convert $content to a  -->
                        <!-- node-set, and then hit with an identity template -->
                        <!-- to duplicate.  Experiment indicates no change in -->
                        <!-- output. (2023-01-11)                             -->
                        <xsl:copy-of select="$content" />
                    </div>
                    <div id="ptx-content-footer" class="ptx-content-footer">
                        <xsl:apply-templates select="." mode="previous-button"/>
                        <a class="top-button button" href="#" title="Top">
                            <xsl:call-template name="insert-symbol">
                                <xsl:with-param name="name" select="'expand_less'"/>
                            </xsl:call-template>
                            <span class="name">Top</span>
                        </a>
                        <xsl:apply-templates select="." mode="next-button"/>
                    </div>
                </main>
            </div>
            <!-- formerly "extra" -->
            <div id="ptx-page-footer" class="ptx-page-footer">
                <xsl:apply-templates select="." mode="feedback-button"/>
                <xsl:call-template name="pretext-link" />
                <xsl:call-template name="runestone-link"/>
                <xsl:call-template name="mathjax-link" />
            </div>
            <xsl:copy-of select="$file-wrap-full-endbody-cache"/>
            <!-- For portable builds we stash the lunr search here -->
            <xsl:if test="$b-portable-html and $has-native-search">
                <xsl:call-template name="embedded-search-construction"/>
            </xsl:if>
        </body>
    </html>
    </exsl:document>
</xsl:template>

<!-- A minimal individual page:                              -->
<!-- Inputs:                                                 -->
<!-- * page content (exclusive of banners, navigation etc)   -->
<xsl:template match="*" mode="simple-file-wrap">
    <xsl:param name="content" />
    <xsl:variable name="filename">
        <!-- do not use "containing-filename" may be different -->
        <xsl:apply-templates select="." mode="visible-id" />
        <text>.html</text>
    </xsl:variable>
    <exsl:document href="{$filename}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
    <xsl:call-template name="converter-blurb-html-no-date"/>
    <html>
        <xsl:call-template name="language-attributes"/>
        <xsl:call-template name="pretext-advertisement-and-style"/>
        <!-- Open Graph Protocol only in "meta" elements, within "head" -->
        <head xmlns:og="http://ogp.me/ns#" xmlns:book="https://ogp.me/ns/book#">
            <title>
                <xsl:apply-templates select="." mode="title-plain" />
            </title>
            <!-- canonical link for better SEO -->
            <xsl:call-template name="canonical-link">
                <xsl:with-param name="filename" select="$filename"/>
            </xsl:call-template>
            <!-- grab the contents every page gets -->
            <xsl:copy-of select="$file-wrap-simple-head-cache"/>
            <!-- now do anything that is or could be page-specific and comes after cache -->
            <xsl:apply-templates select="." mode="knowl" />
            <xsl:apply-templates select="." mode="sagecell" />
        </head>
        <!-- TODO: needs some padding etc -->
        <!-- ignore MathJax signals everywhere, then enable selectively -->
        <body class="ignore-math">
            <!-- potential document-id per-page -->
            <xsl:call-template name="document-id"/>
            <!-- React flag -->
            <xsl:call-template name="react-in-use-flag"/>
            <xsl:copy-of select="$content" />
            <xsl:copy-of select="$file-wrap-basic-endbody-cache"/>
        </body>
    </html>
    </exsl:document>
</xsl:template>

<!-- The body element of every page will (optionally) carry  -->
<!-- an id that identifies which document the HTML page is a -->
<!-- portion of.  This requires the author to specify the    -->
<!-- string in the docinfo/document-id element, which comes  -->
<!-- here via the $document-id variable.                     -->
<xsl:template name="document-id">
    <xsl:if test="not($document-id = '')">
        <xsl:attribute name="id">
            <xsl:value-of select="$document-id"/>
        </xsl:attribute>
    </xsl:if>
</xsl:template>

<xsl:template name="react-in-use-flag">
    <xsl:if test="$b-debug-react">
        <xsl:attribute name="data-react-in-use">
            <xsl:value-of select="'yes'"/>
        </xsl:attribute>
    </xsl:if>
</xsl:template>

<!-- ############# -->
<!-- Meta keywords -->
<!-- ############# -->

<xsl:template name="keywords-meta-element" >
    <meta name="Keywords">
        <xsl:attribute name="content">
            <xsl:if test="$bibinfo/keywords[not(@authority='msc')]">
                <xsl:apply-templates select="$bibinfo/keywords[not(@authority='msc')]/keyword" />
                <xsl:text>, </xsl:text>
            </xsl:if>
            <xsl:text>Authored in PreTeXt</xsl:text>
        </xsl:attribute>
    </meta>
</xsl:template>

<!-- ################### -->
<!-- Page Identification -->
<!-- ################### -->

<!-- Canonical Link -->
<!-- TODO: condition for generic builds at $site-root, need base-url, etc -->
<xsl:template name="canonical-link">
    <xsl:param name="filename"/>

    <!-- book-wide site URL -->
    <xsl:variable name="site-root">
        <xsl:value-of select="concat('https://runestone.academy/ns/books/published/', $document-id, '/')"/>
    </xsl:variable>
    <!-- just for Runestone builds -->
    <xsl:if test="$b-host-runestone">
        <xsl:variable name="full-url" select="concat($site-root, $filename)"/>
        <link rel="canonical" href="{$full-url}"/>
    </xsl:if>
</xsl:template>


<!-- Open Graph Protocol, advertise to Facebook, others       -->
<!-- https://ogp.me/                                          -->
<!-- https://developers.facebook.com/docs/sharing/webmasters/ -->
<!-- https://webcode.tools/generators/open-graph/book         -->
<!-- Sanity-check live instance: https://opengraphcheck.com/  -->
<!-- NB not used for EPUB nor Jupyter (could be in RevealJS?) -->

<xsl:template name="open-graph-info">
    <!-- og:type - book, article, or missing -->
    <xsl:if test="$b-is-article or $b-is-book">
        <xsl:call-template name="open-graph-meta-element">
            <xsl:with-param name="namespace" select="'og'"/>
            <xsl:with-param name="property" select="'type'"/>
            <xsl:with-param name="content">
                <xsl:choose>
                    <xsl:when test="$b-is-book">
                        <xsl:text>book</xsl:text>
                    </xsl:when>
                    <xsl:when test="$b-is-article">
                        <xsl:text>article</xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <!-- og:image - if it's URL can be constructed -->
    <xsl:if test="$b-has-baseurl and $docinfo/brandlogo">
        <xsl:call-template name="open-graph-meta-element">
            <xsl:with-param name="namespace" select="'og'"/>
            <xsl:with-param name="property" select="'image'"/>
            <!-- URL = baseurl + external + @source -->
            <xsl:with-param name="content">
                <!-- empty when not using managed directories -->
                <xsl:value-of select="$baseurl"/>
                <xsl:value-of select="$external-directory"/>
                <xsl:value-of select="$docinfo/brandlogo/@source"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <!-- book:title (always exactly one)-->
    <xsl:if test="$b-is-book">
        <xsl:call-template name="open-graph-meta-element">
            <xsl:with-param name="namespace" select="'book'"/>
            <xsl:with-param name="property" select="'title'"/>
            <xsl:with-param name="content">
                <xsl:apply-templates select="$document-root" mode="title-plain"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <!-- book:author (allow for multiple) -->
    <xsl:if test="$b-is-book">
        <xsl:for-each select="$bibinfo/author">
            <xsl:call-template name="open-graph-meta-element">
                <xsl:with-param name="namespace" select="'book'"/>
                <xsl:with-param name="property" select="'author'"/>
                <xsl:with-param name="content">
                    <xsl:value-of select="personname"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:if>
    <!--  -->
</xsl:template>

<xsl:template name="open-graph-meta-element">
    <xsl:param name="namespace"/>
    <xsl:param name="property"/>
    <xsl:param name="content"/>
    <meta>
        <xsl:attribute name="property">
            <xsl:value-of select="$namespace"/>
            <xsl:text>:</xsl:text>
            <xsl:value-of select="$property"/>
        </xsl:attribute>
        <xsl:attribute name="content">
            <xsl:value-of select="$content"/>
        </xsl:attribute>
    </meta>
</xsl:template>


<!-- ################# -->
<!-- Navigational Aids -->
<!-- ################# -->

<!-- Skip to Main Content link -->
<!-- For accessibilty, a link (hidden off-screen)  -->
<!-- which allows a quick by-pass of all the other -->
<!-- navigational elements, direct to content      -->
<xsl:template name="skip-to-content-link">
    <xsl:element name="a">
        <xsl:attribute name="class">
            <xsl:text>assistive</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="href">
            <xsl:text>#ptx-content</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'skip-to-content'"/>
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

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
<!-- structural check fails at <pretext>           -->
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
    <!-- will be empty precisely at children of <pretext> -->
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
            <xsl:variable name="first-structural-child" select="*[&STRUCTURAL-FILTER;][1]" />
            <xsl:apply-templates select="$first-structural-child" mode="url" />
            <!-- remainder is a basic check, could be removed -->
            <xsl:variable name="structural">
                <xsl:apply-templates select="$first-structural-child" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='false'">
                <xsl:message>PTX:ERROR: descending into first node of an intermediate page (<xsl:value-of select="local-name($first-structural-child)" />) that is non-structural; maybe your source has incorrect structure</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <!-- try going sideways, which climbs up the tree recursively -->
            <xsl:apply-templates select="." mode="next-sideways-url" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Recursively look sideways to the right, else up    -->
<!-- <pretext> is not structural, so halt looking there -->
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
        <!-- Try going up and then sideways                          -->
        <!-- parent always exists, since <pretext> is non-structural -->
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
<!-- <pretext> is not structural, so halt if we go up to there  -->
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
            <!-- Go up to parent and get the URL there (not recursive)   -->
            <!-- parent always exists, since <pretext> is non-structural -->
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
            <xsl:variable name="last-structural-child" select="*[&STRUCTURAL-FILTER;][last()]" />
            <xsl:apply-templates select="$last-structural-child" mode="previous-descent-url" />
            <!-- remainder is a basic check, could be removed -->
            <xsl:variable name="structural">
                <xsl:apply-templates select="$last-structural-child" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='false'">
                <xsl:message>PTX:ERROR: descending into last node of an intermediate page (<xsl:value-of select="local-name($last-structural-child)" />) that is non-structural</xsl:message>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ########## -->
<!-- Permalinks -->
<!-- ########## -->

<xsl:template match="*" mode="permalink">
    <xsl:variable name="permalink-description">
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'permalink-tooltip'"/>
        </xsl:apply-templates>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="tooltip-text"/>
    </xsl:variable>
    <div class="autopermalink">
        <xsl:attribute name="data-description">
            <xsl:apply-templates select="." mode="tooltip-text"/>
        </xsl:attribute>
        <a>
            <xsl:attribute name="href">
                <xsl:text>#</xsl:text>
                <xsl:apply-templates select="." mode="unique-id"/>
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:value-of select="$permalink-description"/>
            </xsl:attribute>
            <xsl:attribute name="aria-label">
                <xsl:value-of select="$permalink-description"/>
            </xsl:attribute>
            <xsl:text>🔗</xsl:text>
        </a>
    </div>
</xsl:template>

<!-- Asides and footnotes don't get permalinks -->
<xsl:template match="fn|&ASIDE-LIKE;" mode="permalink"/>

<!-- 2025-05-29: "p" inside a "feedback" of a dynamic FITB exercise -->
<!-- are losing their context, can't look up the tree, don't know   -->
<!-- their language, and can't make a tooltip.  This match is more  -->
<!-- aggressive than necessary, but should suffice while we wait    -->
<!-- for the underlying problem to be addressed.  Details may       -->
<!-- appear at  https://github.com/PreTeXtBook/pretext/pull/2534    -->
<xsl:template match="feedback/p" mode="permalink"/>

<!-- 2025-10-19: "p" in the label for a multiple choice option overlaps -->
<!-- the label itself, obscuring the content.  This will suppress most  -->
<!-- of the "choice", but not everything.                               -->
<xsl:template match="exercise/choices/choice/statement/p" mode="permalink"/>

<!-- 2025-11-1: "p" inside Parsons problem should not get permalinks -->
<xsl:template match="exercise/blocks//p" mode="permalink"/>

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
                <xsl:attribute name="class">previous-button button</xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:value-of select="$previous-url" />
                </xsl:attribute>
                <xsl:attribute name="title">
                    <xsl:apply-templates select="." mode="type-name">
                        <xsl:with-param name="string-id" select="'previous'"/>
                    </xsl:apply-templates>
                </xsl:attribute>
                <xsl:call-template name="insert-symbol">
                    <xsl:with-param name="name" select="'chevron_left'"/>
                </xsl:call-template>
                <span class="name">
                    <xsl:apply-templates select="." mode="type-name">
                        <xsl:with-param name="string-id" select="'previous-short'"/>
                    </xsl:apply-templates>
                </span>
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="span">
                <xsl:attribute name="class">previous-button button disabled</xsl:attribute>
                <xsl:call-template name="insert-symbol">
                    <xsl:with-param name="name" select="'chevron_left'"/>
                </xsl:call-template>
                <span class="name">
                    <xsl:apply-templates select="." mode="type-name">
                        <xsl:with-param name="string-id" select="'previous-short'"/>
                    </xsl:apply-templates>
                </span>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="index-button">
    <xsl:if test="$the-index">
        <xsl:variable name="url">
            <xsl:apply-templates select="$the-index" mode="url" />
        </xsl:variable>
        <xsl:element name="a">
            <xsl:attribute name="class">
                <xsl:text>index-button button</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="href">
                <xsl:value-of select="$url" />
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'index'"/>
                </xsl:apply-templates>
            </xsl:attribute>
            <xsl:call-template name="insert-symbol">
                <xsl:with-param name="name" select="'info'"/>
            </xsl:call-template>
            <span class="name">
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'index'"/>
                </xsl:apply-templates>
            </span>
        </xsl:element>
    </xsl:if>
</xsl:template>

<!-- The "jump to" navigation on a page with the index -->
<xsl:template match="*" mode="index-jump-nav">
    <div class="indexnav">
        <span class="mininav">
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'jump-to'"/>
            </xsl:apply-templates>
        </span>
        <span class="indexjump">
            <a href="#indexletter-a">A </a>
            <a href="#indexletter-b">B </a>
            <a href="#indexletter-c">C </a>
            <a href="#indexletter-d">D </a>
            <a href="#indexletter-e">E </a>
            <a href="#indexletter-f">F </a>
            <a href="#indexletter-g">G </a>
            <a href="#indexletter-h">H </a>
            <a href="#indexletter-i">I </a>
            <a href="#indexletter-j">J </a>
            <a href="#indexletter-k">K </a>
            <a href="#indexletter-l">L </a>
            <a href="#indexletter-m">M </a>
            <br />
            <a href="#indexletter-n">N </a>
            <a href="#indexletter-o">O </a>
            <a href="#indexletter-p">P </a>
            <a href="#indexletter-q">Q </a>
            <a href="#indexletter-r">R </a>
            <a href="#indexletter-s">S </a>
            <a href="#indexletter-t">T </a>
            <a href="#indexletter-u">U </a>
            <a href="#indexletter-v">V </a>
            <a href="#indexletter-w">W </a>
            <a href="#indexletter-x">X </a>
            <a href="#indexletter-y">Y </a>
            <a href="#indexletter-z">Z </a>
        </span>
    </div>
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
                <xsl:attribute name="class">next-button button</xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:value-of select="$next-url" />
                </xsl:attribute>
                <xsl:attribute name="title">
                    <xsl:apply-templates select="." mode="type-name">
                        <xsl:with-param name="string-id" select="'next'"/>
                    </xsl:apply-templates>
                </xsl:attribute>
                <span class="name">
                    <xsl:apply-templates select="." mode="type-name">
                        <xsl:with-param name="string-id" select="'next-short'"/>
                    </xsl:apply-templates>
                </span>
                <xsl:call-template name="insert-symbol">
                    <xsl:with-param name="name" select="'chevron_right'"/>
                </xsl:call-template>
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="span">
                <xsl:attribute name="class">next-button button disabled</xsl:attribute>
                <span class="name">
                    <xsl:apply-templates select="." mode="type-name">
                        <xsl:with-param name="string-id" select="'next-short'"/>
                    </xsl:apply-templates>
                </span>
                <xsl:call-template name="insert-symbol">
                    <xsl:with-param name="name" select="'chevron_right'"/>
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
                <xsl:attribute name="class">up-button button</xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:value-of select="$up-url" />
                </xsl:attribute>
                <xsl:attribute name="title">
                    <xsl:apply-templates select="." mode="type-name">
                        <xsl:with-param name="string-id" select="'up'"/>
                    </xsl:apply-templates>
                </xsl:attribute>
                <xsl:call-template name="insert-symbol">
                    <xsl:with-param name="name" select="'expand_less'"/>
                </xsl:call-template>
                <span class="name">
                    <xsl:apply-templates select="." mode="type-name">
                        <xsl:with-param name="string-id" select="'up-short'"/>
                    </xsl:apply-templates>
                </span>
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="span">
                <xsl:attribute name="class">up-button button disabled</xsl:attribute>
                <xsl:call-template name="insert-symbol">
                    <xsl:with-param name="name" select="'expand_less'"/>
                </xsl:call-template>
                <span class="name">
                    <xsl:apply-templates select="." mode="type-name">
                        <xsl:with-param name="string-id" select="'up-short'"/>
                    </xsl:apply-templates>
                </span>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="calculator-toggle">
    <button id="calculator-toggle" class="calculator-toggle button" title="Show calculator" aria-expanded="false" aria-controls="calculator-container">
        <xsl:call-template name="insert-symbol">
            <xsl:with-param name="name" select="'calculate'"/>
        </xsl:call-template>
        <span class="name">Calc</span>
    </button>
</xsl:template>

<xsl:template name="light-dark-button">
    <button id="light-dark-button" class="light-dark-button button" title="Dark Mode">
        <xsl:call-template name="insert-symbol">
            <xsl:with-param name="name" select="'dark_mode'"/>
        </xsl:call-template>
        <span class="name">Dark Mode</span>
    </button>
</xsl:template>

<xsl:template name="embed-button">
    <button id="embed-button" class="embed-button button" title="Embed this page">
        <xsl:call-template name="insert-symbol">
            <xsl:with-param name="name" select="'code'"/>
        </xsl:call-template>
        <span class="name">Embed</span>

    </button>
    <div class="embed-popup hidden" id="embed-popup">
        <p>Copy the code below to embed this page in your own website or LMS page.</p>
        <div class="embed-code-container">
            <textarea class="embed-code-textbox" id="embed-code-textbox" readonly="true" aria-label="textbox">
                <iframe src="https://example.com/embed" width="100%" height="1000"></iframe>
            </textarea>
            <button class="copy-embed-button button" id="copy-embed-button" title="Copy embed code">
                <xsl:call-template name="insert-symbol">
                    <xsl:with-param name="name" select="'content_copy'"/>
                </xsl:call-template>
                <span class="name">Copy</span>
            </button>
        </div>
    </div>
</xsl:template>

<xsl:template match="*" mode="print-button"/>

<xsl:template match="worksheet|handout" mode="print-button">
    <xsl:variable name="print-text">
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'print'"/>
        </xsl:apply-templates>
    </xsl:variable>
    <button class="print-button" title="{$print-text}" onClick="window.print()">
        <xsl:call-template name="insert-symbol">
            <xsl:with-param name="name" select="'print'"/>
        </xsl:call-template>
        <span class="name">
            <xsl:value-of select="$print-text"/>
        </span>
    </button>
</xsl:template>

<xsl:template match="*" mode="print-preview-header"/>

<xsl:template match="worksheet|handout" mode="print-preview-header">
    <h2 class="print-preview">
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'print-preview'"/>
        </xsl:apply-templates>
    </h2>
</xsl:template>

<xsl:template match="*" mode="papersize-toggle"/>

<xsl:template match="worksheet|handout" mode="papersize-toggle">
    <xsl:variable name="papersize">
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'papersize'"/>
        </xsl:apply-templates>
    </xsl:variable>
    <form class="papersize-select" id="papersize-select">
        <span class="name"><xsl:value-of select="$papersize"/></span>
        <label>
            <input type="radio" name="papersize" value="a4"/>A4
        </label>
        <label>
            <input type="radio" name="papersize" value="letter"/>Letter
        </label>
    </form>
</xsl:template>

<xsl:template match="*" mode="highlight-workspace-toggle"/>

<xsl:template match="worksheet|handout" mode="highlight-workspace-toggle">
    <label for="highlight-workspace-checkbox">
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'highlight-workspace'"/>
        </xsl:apply-templates>
    </label>
    <input type="checkbox" id="highlight-workspace-checkbox"/>
</xsl:template>

<!-- Primary Navigation Panels -->
<!-- ToC, Prev/Up/Next/Annotation buttons  -->
<!-- Also organized for small screen modes -->
<xsl:template match="*" mode="primary-navigation">

    <nav id="ptx-navbar">
        <xsl:attribute name="class">
            <xsl:text>ptx-navbar navbar</xsl:text>
        </xsl:attribute>

        <div class="ptx-navbar-contents">
            <!-- Pick an ordering for the nav components based on layout needs -->
            <xsl:apply-templates select="." mode="primary-navigation-toc" />
            <xsl:apply-templates select="." mode="primary-navigation-index" />
            <xsl:apply-templates select="." mode="primary-navigation-search" />
            <xsl:apply-templates select="." mode="primary-navigation-other-controls" />
            <xsl:apply-templates select="." mode="primary-navigation-treebuttons" />
            <xsl:apply-templates select="." mode="primary-navigation-runestone" />

            <!-- Annotations button was once here, see GitHub issue -->
            <!-- https://github.com/rbeezer/mathbook/issues/1010    -->
        </div>
    </nav>
</xsl:template>

<xsl:template match="*" mode="primary-navigation-search">
    <xsl:call-template name="google-search-box" />
    <xsl:call-template name="native-search-box" />
</xsl:template>

<xsl:template match="*" mode="primary-navigation-treebuttons">
    <!-- Span to encase Prev/Up/Next buttons and float right    -->
    <!-- Each button gets an id for keypress recognition/action -->
    <span class="treebuttons">
        <xsl:apply-templates select="." mode="previous-button"/>
        <xsl:if test="$nav-upbutton='yes'">
            <xsl:apply-templates select="." mode="up-button"/>
        </xsl:if>
        <xsl:apply-templates select="." mode="next-button"/>
    </span>
</xsl:template>

<xsl:template match="*" mode="primary-navigation-runestone">
    <!-- Runestone user menu -->
    <xsl:if test="not($b-debug-react) and ($b-host-runestone or $b-has-scratch-activecode)">
        <span class="nav-runestone-controls">
            <!-- A scratch ActiveCode via a pencil icon, always -->
            <xsl:call-template name="runestone-scratch-activecode"/>
            <!-- Conditional on a build for Runestone hosting -->
            <xsl:call-template name="runestone-bust-menu"/>
        </span>
    </xsl:if>
</xsl:template>

<xsl:template match="*" mode="primary-navigation-other-controls">
    <span class="nav-other-controls">
        <!-- Button to show/hide the calculator -->
        <xsl:if test="$b-has-calculator">
            <xsl:call-template name="calculator-toggle" />
            <xsl:call-template name="calculator" />
        </xsl:if>
        <!-- Button to show code for embedding in an LMS or webpage  -->
         <xsl:if test="$b-has-embed-button">
             <xsl:call-template name="embed-button" />
        </xsl:if>
        <xsl:if test="$b-theme-has-darkmode">
            <xsl:call-template name="light-dark-button" />
        </xsl:if>
    </span>
</xsl:template>

<xsl:template match="*" mode="primary-navigation-index">
    <!-- A page either has an/the index as    -->
    <!-- a child, and gets the "jump to" bar, -->
    <!-- or it deserves an index button       -->
    <xsl:choose>
        <xsl:when test="index-list">
            <xsl:apply-templates select="." mode="index-jump-nav" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="index-button" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="primary-navigation-toc">
    <button>
        <xsl:attribute name="class">
            <xsl:text>toc-toggle button</xsl:text>
            <xsl:if test="$toc-level = 0">
                <xsl:text> hidden</xsl:text>
            </xsl:if>
        </xsl:attribute>
        <xsl:attribute name="title">
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'toc'"/>
            </xsl:apply-templates>
        </xsl:attribute>
        <xsl:call-template name="insert-symbol">
            <xsl:with-param name="name" select="'menu'"/>
        </xsl:call-template>
        <span class="name">
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'toc'"/>
            </xsl:apply-templates>
        </span>
    </button>
</xsl:template>

<!-- ToC sidebar                                                -->
<xsl:template match="*" mode="sidebars">
    <div id="ptx-sidebar">
        <xsl:attribute name="class">
            <xsl:text>ptx-sidebar</xsl:text>
            <xsl:if test="$toc-level = 0">
                <xsl:text> hidden</xsl:text>
            </xsl:if>
        </xsl:attribute>
        <nav id="ptx-toc">
            <xsl:attribute name="class">
                <xsl:text>ptx-toc</xsl:text>
                <!-- A class indicates how much of the ToC we want   -->
                <!-- to see, as set in the publication file. Always. -->
                <xsl:text> depth</xsl:text>
                <xsl:value-of select="$toc-level"/>
                <!-- Optionally place a class name to allow for numbering  -->
                <!-- parts and chapters, when parts are present (w/ space) -->
                <xsl:if test="$b-has-parts">
                    <xsl:text> parts</xsl:text>
                </xsl:if>
                <xsl:if test="$b-html-toc-focused">
                    <xsl:text> focused</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <!-- if focused, add info for js to pick up about levels -->
            <xsl:if test="$b-html-toc-focused">
                <xsl:attribute name="data-preexpanded-levels">
                    <xsl:value-of select="$html-toc-preexpanded-levels"/>
                </xsl:attribute>
                <xsl:attribute name="data-max-levels">
                    <xsl:value-of select="$toc-level"/>
                </xsl:attribute>
            </xsl:if>
            <!-- now, all the actual ToC entries -->
            <xsl:apply-templates select="." mode="customized-toc-items"/>
        </nav>
    </div>
 </xsl:template>

<xsl:template name="calculator">
    <xsl:if test="contains($html-calculator,'geogebra')">
        <div id="calculator-container" class="calculator-container" style="display: none; z-index:100;">
            <div id="geogebra-calculator"></div>
        </div>
        <script>
            <xsl:text>&#xa;</xsl:text>
            <!-- Here is where we could initialize some things to customize the display.                    -->
            <!-- But the customization should be different depending on classic, graphing, geometry, or 3d. -->
            <!-- For instance geometry probably does not benefit from showing the grid.                     -->
            <!-- If this is not in use, no need to set "appletOnLoad" further below.                        -->
            <!-- var onLoad = function(applet) {
                applet.setAxisLabels(1,'x','y','z');
                applet.setGridVisible(1,true);
                applet.showFullscreenButton(true);
            }; -->
            <xsl:text>var ggbApp = new GGBApplet({"appName": "</xsl:text>
            <xsl:value-of select="substring-after($html-calculator,'-')"/>
            <xsl:text>",&#xa;</xsl:text>
            <!-- width and height are required parameters                   -->
            <!-- All the rest is customizing some things away from defaults -->
            <!-- (or maybe in some cases explicitly using the defaults)     -->
            <!-- The last parameters have to do with scaling. This combination allows the 330x600 applet -->
            <!-- to scale up or down to the width of the contining div with class calculator-container.  -->
            <!-- The applet's height will scale proportionately.                                         -->
            <xsl:text>    "width": 330,&#xa;</xsl:text>
            <xsl:text>    "height": 600,&#xa;</xsl:text>
            <xsl:text>    "showToolBar": true,&#xa;</xsl:text>
            <xsl:text>    "showAlgebraInput": true,&#xa;</xsl:text>
            <xsl:text>    "perspective": "G/A",&#xa;</xsl:text>
            <xsl:text>    "algebraInputPosition": "bottom",&#xa;</xsl:text>
            <!--          "appletOnLoad": onLoad, -->
            <xsl:text>    "scaleContainerClass": "calculator-container",&#xa;</xsl:text>
            <xsl:text>    "allowUpscale": true,&#xa;</xsl:text>
            <xsl:text>    "autoHeight": true,&#xa;</xsl:text>
            <xsl:text>    "disableAutoScale": false},&#xa;</xsl:text>
            <xsl:text>true);&#xa;</xsl:text>
            <!--   The calculator is created by                    -->
            <!--   ggbApp.inject('geogebra-calculator');           -->
            <!--   which is inserted by code in pretext_add_on.js  -->
        </script>
    </xsl:if>
</xsl:template>


<!-- Table of Contents Contents (Items)                            -->
<!-- This is the pre-computed TOC that is on every page. It will   -->
<!-- be customized later as it is rendered to each page.           -->
<xsl:variable name="toc-cache-rtf">
    <xsl:apply-templates select="/" mode="toc-items"/>
</xsl:variable>

<xsl:template match="*" mode="toc-items">
    <!-- start recursion at the top, since the  -->
    <!-- ToC is global for the whole document   -->
    <ul class="structural toc-item-list">
        <xsl:apply-templates select="$document-root" mode="toc-item"/>
    </ul>
</xsl:template>

<!-- NB no "book", "article" -->
<xsl:template match="frontmatter|abstract|frontmatter/colophon|biography|dedication|acknowledgement|preface|contributors|part|chapter|section|subsection|subsubsection|exercises|solutions|reading-questions|references|glossary|worksheet|handout|backmatter|appendix|index|backmatter/colophon" mode="toc-item">
    <li>
        <xsl:apply-templates select="." mode="toc-item-properties"/>
        <!-- Recurse into children divisions (if any)-->
        <xsl:variable name="child-list" select="frontmatter|abstract|frontmatter/colophon|biography|dedication|acknowledgement|preface|contributors|part|chapter|section|subsection|subsubsection|exercises|solutions|reading-questions|references|glossary|worksheet|handout|backmatter|appendix|index|backmatter/colophon"/>
        <xsl:if test="$child-list">
            <ul>
                <!-- copy id of this ui for use in customization pass, will remove there -->
                <xsl:attribute name="uid">
                    <xsl:value-of select="@unique-id"/>
                </xsl:attribute>
                <xsl:attribute name="class">
                    <xsl:text>structural toc-item-list</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="*" mode="toc-item"/>
            </ul>
        </xsl:if>
    </li>
</xsl:template>

<!-- Recurse through un-interesting elements -->
<!-- NB: pass along current page -->
<!-- Will pickup blocks, etc on unstructured divisions while picking up specialized divisions -->
<xsl:template match="*" mode="toc-item">
    <xsl:apply-templates select="*" mode="toc-item"/>
</xsl:template>

<!-- The contents of a division's "li" -->
<xsl:template match="*" mode="toc-item-properties">
    <xsl:variable name="the-url">
        <xsl:apply-templates select="." mode="url"/>
    </xsl:variable>
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:attribute name="class">
        <xsl:text>toc-item</xsl:text>
        <xsl:text> toc-</xsl:text><xsl:value-of select="translate(local-name(), '/', '-')"/>
    </xsl:attribute>
    <!-- copy id of this li for use in customization pass, will remove there -->
    <xsl:attribute name="uid">
        <xsl:value-of select="@unique-id"/>
    </xsl:attribute>
    <div class="toc-title-box">
        <a href="{$the-url}" class="internal">
            <xsl:if test="not($the-number = '')">
                <span class="codenumber">
                    <xsl:value-of select="$the-number" />
                </span>
                <!-- separating space, only if needed -->
                <xsl:text> </xsl:text>
            </xsl:if>
            <!-- *always* a title for divisions -->
            <span class="title">
                <xsl:apply-templates select="." mode="title-short" />
            </span>
        </a>
    </div>
</xsl:template>

<!-- Table of Contents per-page customization      -->
<xsl:template match="*" mode="customized-toc-items">
    <!-- get a copy of the toc-cach that we will decorate -->
    <xsl:variable name="toc-contents-rtf">
        <xsl:copy-of select="$toc-cache-rtf"/>
    </xsl:variable>
    <xsl:variable name="toc-contents" select="exsl:node-set($toc-contents-rtf)"/>

    <!-- get the unique id of the current page -->
    <xsl:variable name="uid" select="@unique-id"/>
    <!-- use that to find the ToC node for that page -->
    <xsl:variable name="this-page-node" select="$toc-contents//*[@uid = $uid]"/>
    <!-- ancestor list will allow us to identify when we are in the path to the page -->
    <xsl:variable name="this-page-ancestors" select="$this-page-node/ancestor::*" />

    <!-- begin copying ToC at root element -->
    <xsl:apply-templates select="$toc-contents" mode="customized-toc-item">
        <xsl:with-param name="this-page" select="$this-page-node"/>
        <xsl:with-param name="this-page-ancestors" select="$this-page-ancestors"/>
    </xsl:apply-templates>
</xsl:template>

<!-- boring element (span, etc...) -->
<xsl:template match="@*|*" mode="customized-toc-item">
    <xsl:param name="this-page"/>
    <xsl:param name="this-page-ancestors"/>
    <xsl:copy>
        <!-- process all other attributes, nodes, and text-->
        <xsl:apply-templates select="@*|*|text()" mode="customized-toc-item">
            <xsl:with-param name="this-page" select="$this-page"/>
            <xsl:with-param name="this-page-ancestors" select="$this-page-ancestors"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<!-- items that may need to be customized-->
<xsl:template match="ul|li" mode="customized-toc-item">
    <xsl:param name="this-page"/>
    <xsl:param name="this-page-ancestors"/>

    <!-- root ul in toc should always be considered "is-ancestor"     -->
    <!-- even if there is no active page (e.g. index.html)            -->
    <xsl:variable name="is-ancestor" select="not(ancestor::ul) or count($this-page-ancestors|.) = count($this-page-ancestors)"/>
    <xsl:variable name="is-page" select="count($this-page|.) = count($this-page)"/>
    <xsl:choose>
        <!-- ToC item contains or is active page -->
        <xsl:when test="$is-ancestor or $is-page">
            <!-- need to copy with modified class list -->
            <xsl:copy>
                <!-- reconstruct class attr -->
                <xsl:variable name="old-class" select="@class"/>
                <xsl:attribute name="class">
                    <xsl:value-of select="$old-class"/>
                    <xsl:choose>
                        <xsl:when test="$is-ancestor">
                            <xsl:text> contains-active</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text> active</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <!-- filter the uids and class, process all other attributes, nodes, and text-->
                <xsl:apply-templates select="@*[name() != 'uid' and name() != 'class']|*|text()" mode="customized-toc-item">
                    <xsl:with-param name="this-page" select="$this-page"/>
                    <xsl:with-param name="this-page-ancestors" select="$this-page-ancestors"/>
                </xsl:apply-templates>
            </xsl:copy>
        </xsl:when>
        <!-- ToC item is not on path to active page, simple copy minus uid-->
        <xsl:otherwise>
            <xsl:copy>
                <xsl:apply-templates select="@*[name() != 'uid']|*|text()" mode="customized-toc-item">
                    <xsl:with-param name="this-page" select="$this-page"/>
                    <xsl:with-param name="this-page-ancestors" select="$this-page-ancestors"/>
                </xsl:apply-templates>
            </xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A standalone XML file with ToC necessities  -->
<!-- Infrastructure for file, initiate recursion -->
<xsl:template name="doc-manifest">
    <xsl:if test="$b-debug-react">
        <exsl:document href="doc-manifest.xml" method="xml" indent="yes" encoding="UTF-8">
            <toc>
                <xsl:apply-templates select="$document-root" mode="toc-item-list"/>
            </toc>
        </exsl:document>
    </xsl:if>
</xsl:template>

<!-- The top-level organization is of two flavors:                  -->
<!--                                                                -->
<!-- (1a) For a book with no parts                                  -->
<!--                                                                -->
<!-- frontmatter                                                    -->
<!-- mainmatter                                                     -->
<!--   chapter                                                      -->
<!--   chapter                                                      -->
<!-- backmatter                                                     -->
<!--                                                                -->
<!-- (1b) For an article                                            -->
<!--                                                                -->
<!-- frontmatter                                                    -->
<!-- mainmatter                                                     -->
<!--   section                                                      -->
<!--   section                                                      -->
<!-- backmatter                                                     -->
<!--                                                                -->
<!-- (2) For a book with parts                                      -->
<!--                                                                -->
<!--   frontmatter                                                  -->
<!--   part                                                         -->
<!--   part                                                         -->
<!--   backmatter                                                   -->
<!--                                                                -->
<!-- So there are four top-level divisions for the ToC:             -->
<!--                                                                -->
<!--   frontmatter, mainmatter, backmatter, part                    -->
<!--                                                                -->
<!-- which are always peers.  Then, for example, a book chapter     -->
<!-- and a book appendix are always at the same depth, parts or     -->
<!-- not.  The "mainmatter" division is a fiction, so not rendered. -->

<xsl:template match="article|book" mode="toc-item-list">
    <division>
        <xsl:apply-templates select="." mode="doc-manifest-division-attributes"/>
        <xsl:choose>
            <xsl:when test="$b-has-parts">
                <!-- identical to general recursion below, see comments -->
                <xsl:apply-templates select="*" mode="toc-item-list"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="frontmatter" mode="toc-item-list"/>
                <!-- insert a faux "mainmatter" division to coordinate the levels -->
                <!-- of similar divisions, such a chapter and appendix in a book  -->
                <!-- attributes are sensible defaults                             -->
                <division type="mainmatter" number="" id="mainmatter">
                    <!-- form URL of "mainmatter" to be the document root -->
                    <xsl:variable name="the-url">
                        <xsl:apply-templates select="." mode="url"/>
                    </xsl:variable>
                    <xsl:attribute name="url">
                        <xsl:value-of select="$the-url"/>
                        <!-- add the HTML id as a fragment identifier when absent, -->
                        <!-- which is the case where the division is a chunk/page  -->
                        <xsl:if test="not(contains($the-url, '#'))">
                            <xsl:text>#</xsl:text>
                            <xsl:apply-templates select="." mode="html-id"/>
                        </xsl:if>
                    </xsl:attribute>
                    <!-- title not localized, not expected to be displayed -->
                    <title>Main Matter</title>
                    <xsl:apply-templates select="*[not(self::frontmatter or self::backmatter)]" mode="toc-item-list"/>
                </division>
                <xsl:apply-templates select="backmatter" mode="toc-item-list"/>
            </xsl:otherwise>
        </xsl:choose>
    </division>
</xsl:template>

<!-- Every item that could be a TOC entry, mined from the schema. -->
<xsl:template match="frontmatter|frontmatter/colophon|biography|dedication|acknowledgement|preface|contributors|part|chapter|section|subsection|subsubsection|exercises|solutions|reading-questions|references|glossary|worksheet|handout|backmatter|appendix|index|backmatter/colophon" mode="toc-item-list">
    <division>
        <xsl:apply-templates select="." mode="doc-manifest-division-attributes"/>
        <!-- Recurse into children divisions (if any)                 -->
        <!-- NB: the select here could match the one above and this   -->
        <!-- would be much more efficient.  But we may include blocks -->
        <!-- in the future, which could complicate how this is done   -->
        <!-- (perhaps a "block-item" call right here which recurses   -->
        <!-- through an entire division? -->
        <xsl:apply-templates select="*" mode="toc-item-list"/>
    </division>
</xsl:template>

<!-- Recurse through un-interesting elements                -->
<!-- NB: this could be unnecessary in context of note above -->
<xsl:template match="*" mode="toc-item-list">
    <xsl:apply-templates select="*" mode="toc-item-list"/>
</xsl:template>

<!-- Coordinate changes here with faux division, "mainmatter", above -->
<xsl:template match="*" mode="doc-manifest-division-attributes">
        <xsl:attribute name="type">
            <xsl:value-of select="local-name(.)"/>
        </xsl:attribute>
        <xsl:attribute name="number">
            <xsl:apply-templates select="." mode="number"/>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <xsl:variable name="the-url">
            <xsl:apply-templates select="." mode="url"/>
        </xsl:variable>
        <xsl:attribute name="url">
            <xsl:value-of select="$the-url"/>
            <!-- add the HTML id as a fragment identifier when absent, -->
            <!-- which is the case where the division is a chunk/page  -->
            <xsl:if test="not(contains($the-url, '#'))">
                <xsl:text>#</xsl:text>
                <xsl:apply-templates select="." mode="html-id"/>
            </xsl:if>
        </xsl:attribute>
        <title>
            <xsl:apply-templates select="." mode="title-short"/>
        </title>
</xsl:template>

<!-- ###### -->
<!-- Search -->
<!-- ###### -->

<!-- We build a collection of what Lunr calls "search documents" -->
<!-- as a Javascript object stored in a file.  For Runestone, it -->
<!-- needs to go in a different directory than the HTML files.   -->
<xsl:variable name="lunr-search-file">
    <xsl:if test="$b-host-runestone">
        <xsl:text>_static/</xsl:text>
    </xsl:if>
    <xsl:text>lunr-pretext-search-index.js</xsl:text>
</xsl:variable>

<xsl:template name="search-page-construction">
    <!-- The a Javascript file with the Lunr search index (non-portable builds).  -->
    <exsl:document href="{$lunr-search-file}" method="text" encoding="UTF-8">
        <xsl:call-template name="search-script-contents"/>
    </exsl:document>
</xsl:template>

<xsl:template name="embedded-search-construction">
    <!-- For portable html builds, we include the contents of what    -->
    <!-- what would otherwise go in the lunr-search-file inside the   -->
    <!-- HTML file itself, inside script tags (to be placed as the    -->
    <!-- last script tag in the body).                                -->
    <script>
        <xsl:call-template name="search-script-contents"/>
    </script>
</xsl:template>

<xsl:template name="search-script-contents">
    <!-- The contents of either the lunr-search-page or the script  -->
    <!-- embedded in HTML. This defines  the raw "documents"        -->
    <!-- of the eventual index, and then converted by Lunr into     -->
    <!-- a Javascript variable , ptx_lunr_idx.  This index variable -->
    <!-- is included later in the search page via a script element, -->
    <!-- for use/consumption by the Lunr search() method.           -->
    <xsl:text>var ptx_lunr_search_style = "</xsl:text>
    <xsl:value-of select="$native-search-variant"/>
    <xsl:text>";&#xa;</xsl:text>
    <!-- the actual search documents in one HUGE variable, then a list -->
    <xsl:variable name="json-docs">
        <xsl:apply-templates select="$document-root" mode="search-page-docs"/>
    </xsl:variable>
    <xsl:text>var ptx_lunr_docs = [&#xa;</xsl:text>
    <!-- Strip a trailing comma, and a newline, to be proper JSON -->
    <xsl:value-of select="substring($json-docs, 1, string-length($json-docs) - 2)"/>
    <!-- restore newline just stripped -->
    <xsl:text>&#xa;]&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <!-- the Javascript function to make the index -->
    <xsl:text>var ptx_lunr_idx = lunr(function () {&#xa;</xsl:text>
    <xsl:text>  this.ref('id')&#xa;</xsl:text>
    <xsl:text>  this.field('title')&#xa;</xsl:text>
    <xsl:text>  this.field('body')&#xa;</xsl:text>
    <xsl:text>  this.metadataWhitelist = ['position']&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>  ptx_lunr_docs.forEach(function (doc) {&#xa;</xsl:text>
    <xsl:text>    this.add(doc)&#xa;</xsl:text>
    <xsl:text>  }, this)&#xa;</xsl:text>
    <xsl:text>})&#xa;</xsl:text>
</xsl:template>


<!-- The modal template "search-page-docs" traverses the structural   -->
<!-- elements (divisions), stopping when a division is a chunk of the -->
<!-- HTML ouput (as configured by the publisher).  A search document  -->
<!-- is created for the content of such HTML output page.  This is    -->
<!-- one collection of possible search results, in correspondence     -->
<!-- with the actual pages of the output, and displayed at level 1    -->
<!-- (no indentation).  Each such page then gives rise to more        -->
<!-- detailed results, which are primarily "blocks" of the page.      -->

<xsl:template match="&STRUCTURAL;" mode="search-page-docs">
    <xsl:variable name="chunk">
        <xsl:apply-templates select="." mode="is-chunk"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$chunk = 'true'">
            <!-- stop and build a search document for the page,    -->
            <!-- as a first-level indentation in the outline-style -->
            <!-- of the search results                             -->
            <xsl:apply-templates select="." mode="search-document">
                <xsl:with-param name="level" select="'1'"/>
            </xsl:apply-templates>
            <!-- recursively cruise the *children* of the page for   -->
            <!-- blocks that will be second-level indentation in the -->
            <!-- outline-style of the search results                 -->
            <!-- This is where we adjust our priorities on what      -->
            <!-- becomes a search document, see descriptions of      -->
            <!-- the modal templates for those priorities.           -->
            <xsl:choose>
                <xsl:when test="$native-search-variant = 'textbook'">
                    <xsl:apply-templates select="*" mode="search-block-docs-textbook"/>
                </xsl:when>
                <xsl:when test="$native-search-variant = 'reference'">
                    <xsl:apply-templates select="*" mode="search-block-docs-reference"/>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="&STRUCTURAL;" mode="search-page-docs"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Textbook search -->
<!-- The modal "search-block-docs-textbook" traverses all the elements      -->
<!-- (of a page), starting with the children of the page's division,        -->
<!-- stopping to create a search document for selected blocks. Generally    -->
<!-- these are elements that admit/display titles. These are assigned       -->
<!-- level 2, so they can be displayed with an indentation.  We do not      -->
<!-- recurse into blocks.  So only "first-class" paragraphs are considered, -->
<!-- and only if they have a definition ("term" element) within.            -->

<xsl:template match="*" mode="search-block-docs-textbook">
    <xsl:apply-templates select="*" mode="search-block-docs-textbook"/>
</xsl:template>

<!-- Note: could add &STRUCTURAL; here in order to make a    -->
<!-- search-document for each SUBDIVISION on the page/chunk. -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&PROOF-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&OPENPROBLEM-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&GOAL-LIKE;|&FIGURE-LIKE;|exercise|p[descendant::term]" mode="search-block-docs-textbook">
    <!-- build a search document and dead-end -->
    <xsl:apply-templates select="." mode="search-document">
        <xsl:with-param name="level" select="'2'"/>
    </xsl:apply-templates>
</xsl:template>

<!-- Reference search -->
<!-- The modal "search-block-docs-textbook" traverses all the elements -->
<!-- (of a page), starting with the children of the page's division,   -->
<!-- stopping to create a search document for subdivisions, blocks,    -->
<!-- and first-class paragraphs (plus block quotes and pre-formatted   -->
<!-- paragraphs.  This relies more on division structure, and *all*    -->
<!-- of the content.                                                   -->

<xsl:template match="*" mode="search-block-docs-reference">
    <xsl:apply-templates select="*" mode="search-block-docs-reference"/>
</xsl:template>

<xsl:template match="&STRUCTURAL;|&DEFINITION-LIKE;|&THEOREM-LIKE;|&PROOF-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&OPENPROBLEM-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&GOAL-LIKE;|&FIGURE-LIKE;|exercise|p|blockquote|pre" mode="search-block-docs-reference">
    <!-- build a search document and dead-end -->
    <xsl:apply-templates select="." mode="search-document">
        <xsl:with-param name="level" select="'2'"/>
    </xsl:apply-templates>
</xsl:template>

<!-- For any node, be it a page or a block, a "search document"  -->
<!-- data structure is created, the actual content is realized   -->
<!-- by the "search-node-text" template, which is designed to be -->
<!-- overridden in some situations.  The level comes in as a     -->
<!-- parameter and is recorded in the data structure.            -->

<xsl:template match="*" mode="search-document">
    <xsl:param name="level"/>

    <!-- With "textbook" search, paragraphs using a "term" -->
    <!-- to make a definition have some exceptions below.  -->
    <xsl:variable name="b-is-definition-paragraph"
                  select="($native-search-variant = 'textbook') and self::p and descendant::term"/>

    <xsl:text>{&#xa;</xsl:text>
    <!-- string to identify results with original docs -->
    <xsl:text>  "id": "</xsl:text>
    <xsl:call-template name="escape-json-string">
        <xsl:with-param name="text">
            <xsl:apply-templates select="." mode="html-id"/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>",&#xa;</xsl:text>
    <!-- level 2 indicates need for indentation -->
    <xsl:text>  "level": "</xsl:text>
    <xsl:value-of select="$level"/>
    <xsl:text>",&#xa;</xsl:text>
    <!-- filename relative to search page -->
    <xsl:text>  "url": "</xsl:text>
    <xsl:call-template name="escape-json-string">
        <xsl:with-param name="text">
            <xsl:apply-templates select="." mode="url"/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>",&#xa;</xsl:text>
    <!-- the type of the division -->
    <xsl:text>  "type": "</xsl:text>
    <xsl:call-template name="escape-json-string">
        <xsl:with-param name="text">
            <xsl:apply-templates select="." mode="type-name"/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:if test="$b-is-definition-paragraph">
        <xsl:text> (with a defined term)</xsl:text>
    </xsl:if>
    <xsl:text>",&#xa;</xsl:text>
    <!-- the number of the division -->
    <xsl:text>  "number": "</xsl:text>
    <xsl:call-template name="escape-json-string">
        <xsl:with-param name="text">
            <xsl:apply-templates select="." mode="number"/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>",&#xa;</xsl:text>
    <!-- title of division that is a page -->
    <xsl:text>  "title": "</xsl:text>
    <!-- title might have HTML markup          -->
    <!-- e.g. emphasis, span.process-math      -->
    <!-- RTF -> node-set ->  serialized string -->
    <xsl:variable name="title-html">
        <xsl:apply-templates select="." mode="title-full"/>
    </xsl:variable>
    <xsl:call-template name="escape-json-string">
        <xsl:with-param name="text">
            <xsl:apply-templates select="exsl:node-set($title-html)" mode="xml-to-string"/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>",&#xa;</xsl:text>
    <!-- all text on the page, more or less, duplicates title -->
    <xsl:text>  "body": "</xsl:text>
    <!-- Some elements need special treatment, for specific forms of   -->
    <!-- search, when they *are* the search document, rather than when -->
    <!-- they are *a part of* some other larger search document.  We   -->
    <!-- intercept them here, most-specific first.                     -->
    <xsl:choose>
        <!-- "textbook" search treats first-class -->
        <!-- paragraphs with a term specially     -->
        <xsl:when test="$b-is-definition-paragraph">
            <xsl:apply-templates select="." mode="search-term-paragraph-text"/>
        </xsl:when>
        <!-- for most elements, just extract text -->
        <!-- nodes with various adjustments       -->
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="search-node-text"/>
        </xsl:otherwise>
    </xsl:choose>
    <!-- text here, sanitized -->
    <xsl:text>"&#xa;</xsl:text>
    <!-- NB: final comma AND newline are stripped above -->
    <xsl:text>},&#xa;</xsl:text>
</xsl:template>

<!-- The "search-node-text" templates basically recurses into elements -->
<!-- with no effect and duplicate the text() nodes, properly escaped   -->
<!-- for use in a big old JSON data structure.  This is the place to   -->
<!-- make adjustments by ignoring or modifying certain aspects of the  -->
<!-- content of an element.                                            -->

<xsl:template match="*" mode="search-node-text">
    <xsl:apply-templates select="node()" mode="search-node-text"/>
</xsl:template>

<!-- "Generators" need content, LaTeX and TeX avoid goofy CSS -->
<xsl:template match="pretext|webwork[not(node())]" mode="search-node-text">
    <xsl:apply-templates select="."/>
    <xsl:text> </xsl:text>
</xsl:template>
<xsl:template match="latex" mode="search-node-text">
    <xsl:text>latex </xsl:text>
</xsl:template>
<xsl:template match="tex" mode="search-node-text">
    <xsl:text>tex </xsl:text>
</xsl:template>
<xsl:template match="copyright" mode="search-node-text">
    <xsl:text>copyright </xsl:text>
</xsl:template>
<xsl:template match="copyleft" mode="search-node-text">
    <xsl:text>copyleft </xsl:text>
</xsl:template>

<!-- tags need angle brackets -->
<!-- Empty tag version needs JSON escaping, otherwise -->
<!-- this shouldn't be necessary - but for tag abuse. -->
<xsl:template match="tag|tage" mode="search-node-text">
    <xsl:call-template name="escape-json-string">
        <xsl:with-param name="text">
            <xsl:text>&lt;</xsl:text>
            <xsl:value-of select="text()"/>
            <xsl:if test="self::tage">
                <xsl:text>/</xsl:text>
            </xsl:if>
            <xsl:text>&gt; </xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- First-class paragraphs (children of divisions or "paragraphs",    -->
<!-- and not in blocks) containing "term" are considered differently   -->
<!-- in a textbook search.  Without a "term" they are ignored, while   -->
<!-- with "term" the search document is just the content of the terms. -->
<xsl:template match="p[descendant::term]" mode="search-term-paragraph-text">
    <xsl:apply-templates select=".//term" mode="search-node-text"/>
</xsl:template>

<!-- Lots of stuff can make very misleading search documents. -->
<!-- Examples have included: "\subset" in math and "limits"   -->
<!-- in a WW problem to specify a domain.  So we kill stuff.  -->

<xsl:template match="m|me|men|md[not(mrow)]|mdn[not(mrow)]|md[mrow]|mdn[mrow]" mode="search-node-text"/>
<xsl:template match="latex-image|asymptote|sageplot" mode="search-node-text"/>
<xsl:template match="sage" mode="search-node-text"/>
<!-- "slate" in an "interactive" can have JS code, GeoGebra too, etc -->
<xsl:template match="interactive" mode="search-node-text"/>

<!-- WeBWorK exercises, as output of the pre-processor, include    -->
<!-- a "webwork-reps" element with three elements:                 -->
<!--                                                               -->
<!--   "static": meant for LaTeX, but we *will* index this version -->
<!--   "server-data": base64 versions, empty element with just     -->
<!--                  attributes, so harmless for search           -->
<!--   "pg": native WW version (for problem archives), which will  -->
<!--         be misleading                                         -->
<!--                                                               -->
<!-- NB: ideally the "pg" version will not make it here after some -->
<!-- pre-processor work.  Parsing "static" in the pre-processor    -->
<!-- and labeling the result with a "pi:" prefix would make sense. -->
<xsl:template match="pg" mode="search-node-text"/>

<!--
TODO:
  hints, answers, solutions (only if elected by publisher in text)
-->

<xsl:template match="text()" mode="search-node-text">
    <xsl:choose>
        <!-- collapse authored whitespace, and structural whitespace -->
        <!-- that is being preserved with whitespace declarations    -->
        <!-- Replaced by universal addition at end of the template.  -->
        <!-- Reduces file size by 40%. (sample article)              -->
        <xsl:when test="normalize-space() = ''"/>
        <xsl:otherwise>
            <xsl:call-template name="escape-json-string">
                <!-- normalize-space adds another 2% reduction -->
                <xsl:with-param name="text" select="normalize-space(.)"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
    <!-- a space seems necessary to separate some text() nodes, -->
    <!-- like consecutive (simple) list items.  Presumably it   -->
    <!-- can't hurt to have too many?                           -->
    <xsl:text> </xsl:text>
</xsl:template>


<!-- Feedback Button goes in page-footer                -->
<!-- Values of variables set in publisher-variables.xsl -->
<!-- Context influences default button text language    -->
<xsl:template match="*" mode="feedback-button">
    <xsl:if test="$b-has-feedback-button">
        <a class="feedback-link" href="{$feedback-button-href}" target="_blank">
            <xsl:choose>
                <xsl:when test="not($feedback-button-text = '')">
                    <xsl:value-of select="$feedback-button-text" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="type-name">
                        <xsl:with-param name="string-id" select="'feedback'"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </a>
    </xsl:if>
</xsl:template>

<!-- Branding in page-footer, mostly hard-coded     -->
<!-- HTTPS for authors delivering from secure sites -->
<xsl:template name="pretext-link">
    <a class="pretext-link" href="https://pretextbook.org" title="PreTeXt">
        <div class="logo">
            <!-- explicitly only have a height here to prevent rendering issue in Safari -->
            <svg xmlns="http://www.w3.org/2000/svg" height="100%" viewBox="338 3000 8772 6866" role="img">
            <!-- Use @role="img" and <title> elements for accessibility -->
                <title>PreTeXt logo</title>
                <g style="stroke-width:.025in; stroke:currentColor; fill:none">
                    <polyline points="472,3590 472,9732 " style="stroke-width:174; stroke-linejoin:miter; stroke-linecap:round; "/>
                    <path style="stroke-width:126;stroke-linecap:butt;"  d="M 4724,9448 A 4660 4660  0  0  1  8598  9259"/>
                    <path style="stroke-width:174;stroke-linecap:butt;"  d="M 4488,9685 A 4228 4228  0  0  0   472  9732"/>
                    <path style="stroke-width:126;stroke-linecap:butt;"  d="M 4724,3590 A 4241 4241  0  0  1  8598  3496"/>
                    <path style="stroke-width:126;stroke-linecap:round;" d="M 850,3496  A 4241 4241  0  0  1  4724  3590"/>
                    <path style="stroke-width:126;stroke-linecap:round;" d="M 850,9259  A 4507 4507  0  0  1  4724  9448"/>
                    <polyline points="5385,4299 4062,8125"           style="stroke-width:300; stroke-linejoin:miter; stroke-linecap:round;"/>
                    <polyline points="8598,3496 8598,9259"           style="stroke-width:126; stroke-linejoin:miter; stroke-linecap:round;"/>
                    <polyline points="850,3496 850,9259"             style="stroke-width:126; stroke-linejoin:miter; stroke-linecap:round;"/>
                    <polyline points="4960,9685 4488,9685"           style="stroke-width:174; stroke-linejoin:miter; stroke-linecap:round;"/>
                    <polyline points="3070,4582 1889,6141 3070,7700" style="stroke-width:300; stroke-linejoin:miter; stroke-linecap:round;"/>
                    <polyline points="6418,4582 7600,6141 6418,7700" style="stroke-width:300; stroke-linejoin:miter; stroke-linecap:round;"/>
                    <polyline points="8976,3590 8976,9732"           style="stroke-width:174; stroke-linejoin:miter; stroke-linecap:round;"/>
                    <path style="stroke-width:174;stroke-linecap:butt;" d="M 4960,9685 A 4228 4228  0  0  1  8976  9732"/>
                </g>
            </svg>
        </div>
    </a>
</xsl:template>

<xsl:template name="runestone-link">
    <a class="runestone-link" href="https://runestone.academy" title="Runestone Academy">
        <img class="logo" src="https://runestone.academy/runestone/static/images/RAIcon_cropped.png" alt="Runstone Academy logo"/>
    </a>
</xsl:template>

<xsl:template name="mathjax-link">
    <a class="mathjax-link" href="https://www.mathjax.org" title="MathJax">
        <img class="logo" src="https://www.mathjax.org/badge/badge-square-2.png" alt="MathJax logo"/>
    </a>
</xsl:template>

<!-- Runestone build only, revenue generator -->
<xsl:template name="runestone-ethical-ads">
    <xsl:if test="$b-host-runestone">
        <xsl:text>{% if show_ethical_ad %}</xsl:text>
        <div style="width: 100%">
            <div data-ea-publisher="runestoneacademy" data-ea-type="image" style="display: flex; justify-content: center"/>
        </div>
        <xsl:text>{% endif %}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Tooltip Text -->
<!-- Text for an HTML "title" attribute      -->
<!-- Always leverage the PreTeXt title, e.g. -->
<!-- don't use "caption", it could be BIG    -->
<xsl:template match="*" mode="tooltip-text">
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:variable name="num">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:if test="not($num = '')">
        <xsl:text> </xsl:text>
        <xsl:value-of select="$num" />
    </xsl:if>
    <xsl:if test="title">
        <xsl:text>: </xsl:text>
        <xsl:apply-templates select="." mode="title-plain" />
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
    <!-- mathjax configuration -->
    <xsl:element name="script">
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>var runestoneMathReady = new Promise((resolve) => window.rsMathReady = resolve);&#xa;</xsl:text>
        <xsl:text>window.MathJax = </xsl:text>
        <xsl:call-template name="json">
            <xsl:with-param name="content">
                <map xmlns="http://www.w3.org/2005/xpath-functions">
                    <map key="tex">
                        <array key="inlineMath">
                            <array>
                                <string>\(</string>
                                <string>\)</string>
                            </array>
                        </array>
                        <string key="tags">none</string>
                        <string key="tagSide">right</string>
                        <string key="tagIndent">.8em</string>
                        <map key="packages">
                            <array key="[+]">
                                <string>base</string>
                                <!-- 2023-10-19: this provides backward-compatible behavior -->
                                <!-- and could be removed at the first sign of trouble      -->
                                <xsl:if test="not(contains($latex-packages-mathjax, '\require{extpfeil}'))">
                                    <string>extpfeil</string>
                                </xsl:if>
                                <string>ams</string>
                                <string>amscd</string>
                                <string>color</string>
                                <string>newcommand</string>
                                <string>knowl</string>
                            </array>
                        </map>
                    </map>
                    <map key="options">
                        <string key="ignoreHtmlClass">tex2jax_ignore|ignore-math</string>
                        <string key="processHtmlClass">process-math</string>
                        <xsl:if test="$b-has-webwork-reps or $b-has-sage">
                            <map key="renderActions">
                                <array key="findScript">
                                    <number>10</number>
                                    <raw>
                                        <xsl:text>function (doc) {&#xa;</xsl:text>
                                        <xsl:text>            document.querySelectorAll('script[type^="math/tex"]').forEach(function(node) {&#xa;</xsl:text>
                                        <xsl:text>                var display = !!node.type.match(/; *mode=display/);&#xa;</xsl:text>
                                        <xsl:text>                var math = new doc.options.MathItem(node.textContent, doc.inputJax[0], display);&#xa;</xsl:text>
                                        <xsl:text>                var text = document.createTextNode('');&#xa;</xsl:text>
                                        <xsl:text>                node.parentNode.replaceChild(text, node);&#xa;</xsl:text>
                                        <xsl:text>                math.start = {node: text, delim: '', n: 0};&#xa;</xsl:text>
                                        <xsl:text>                math.end = {node: text, delim: '', n: 0};&#xa;</xsl:text>
                                        <xsl:text>                doc.math.push(math);&#xa;</xsl:text>
                                        <xsl:text>            });&#xa;</xsl:text>
                                        <xsl:text>        }</xsl:text>
                                    </raw>
                                    <string></string>
                                </array>
                            </map>
                        </xsl:if>
                    </map>
                    <map key="chtml">
                        <number key="scale">0.98</number>
                        <boolean key="mtextInheritFont">true</boolean>
                    </map>
                    <map key="loader">
                        <array key="load">
                            <string>input/asciimath</string>
                            <string>[tex]/extpfeil</string>
                            <string>[tex]/amscd</string>
                            <string>[tex]/color</string>
                            <string>[tex]/newcommand</string>
                            <string>[pretext]/mathjaxknowl3.js</string>
                        </array>
                        <map key="paths">
                            <string key="pretext">
                                <xsl:value-of select="$html.jslib.dir"/>
                            </string>
                        </map>
                    </map>
                    <map key="startup">
                        <xsl:choose>
                            <xsl:when test="$b-debug-react">
                                <boolean key="typeset">false</boolean>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- tell Runestone components that MathJax is all loaded -->
                                <raw>
                                    <xsl:text>pageReady() {&#xa;</xsl:text>
                                    <xsl:text>      return MathJax.startup.defaultPageReady().then(function () {&#xa;</xsl:text>
                                    <xsl:text>      console.log("in ready function");&#xa;</xsl:text>
                                    <xsl:text>      rsMathReady();&#xa;</xsl:text>
                                    <xsl:text>      }&#xa;</xsl:text>
                                    <xsl:text>    )}</xsl:text>
                                </raw>
                            </xsl:otherwise>
                        </xsl:choose>
                    </map>
                    <!-- optional presentation mode gets clickable, large math -->
                    <xsl:if test="$b-html-presentation">
                        <map key="options">
                            <map key="menuOptions">
                                <map key="settings">
                                    <string key="zoom">Click</string>
                                    <string key="zscale">300%</string>
                                </map>
                            </map>
                        </map>
                    </xsl:if>
                </map>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:text>;</xsl:text>
        <xsl:text>&#xa;</xsl:text>
    </xsl:element>
    <!-- mathjax javascript -->
    <xsl:element name="script">
        <!-- probably should be universal, but only adding for MJ 4    -->
        <!-- TODO: make a literal "script" element with this attribute -->
        <xsl:if test="$mathjax4-testing">
            <xsl:attribute name="type">
                <xsl:text>text/javascript</xsl:text>
            </xsl:attribute>
        </xsl:if>
        <xsl:attribute name="src">
            <xsl:choose>
                <xsl:when test="$mathjax4-testing">
                    <xsl:text>https://cdn.jsdelivr.net/npm/mathjax@4/</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>https://cdn.jsdelivr.net/npm/mathjax@3/es5/</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <!-- CHTML is the default, SVG is for debugging -->
            <xsl:choose>
                <!-- SVG filename identical for v3, v4 -->
                <!-- NB: is tex-mml-svg.js new for v4? -->
                <xsl:when test="$debug.mathjax.svg = 'yes'">
                    <xsl:text>tex-svg.js</xsl:text>
                </xsl:when>
                <!-- new filename (default) for v4 -->
                <xsl:when test="$mathjax4-testing">
                    <xsl:text>tex-mml-chtml.js</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>tex-chtml.js</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:element>
</xsl:template>

<!-- SageCell Javascript-->
<!-- We never know if a Sage cell might be inside a knowl, -->
<!-- so we load the relevant JavaScript onto every page if -->
<!-- a cell occurs *anywhere* in the entire document       -->
<xsl:template name="sagecell-code">
    <xsl:if test="$b-has-sage">
        <script src="https://sagecell.sagemath.org/static/embedded_sagecell.js"></script>
    </xsl:if>
</xsl:template>

<!-- Sage Cell Setup -->
<!-- TODO: internationalize button labels, strings below -->
<!-- TODO: make an initialization cell which links with the sage-compute cells -->

<!-- A template for a generic makeSageCell script element -->
<!-- Parameters: language, evaluate-button text -->
<xsl:template name="makesagecell">
    <xsl:param name="language-attribute" />
    <xsl:param name="b-autoeval" select="false()"/>
    <xsl:param name="language-text" />

    <xsl:element name="script">
        <xsl:text>// Make *any* div with class '</xsl:text>
        <xsl:call-template name="sagecell-class-name">
            <xsl:with-param name="language-attribute" select="$language-attribute"/>
            <xsl:with-param name="b-autoeval" select="$b-autoeval"/>
        </xsl:call-template>
        <xsl:text>' an executable Sage cell&#xa;</xsl:text>
        <xsl:text>// Their results will be linked, only within language type&#xa;</xsl:text>
        <xsl:text>sagecell.makeSagecell(</xsl:text>
        <xsl:call-template name="json">
            <xsl:with-param name="content">
                <map xmlns="http://www.w3.org/2005/xpath-functions">
                    <string key="inputLocation">
                        <xsl:text>div.</xsl:text>
                        <xsl:call-template name="sagecell-class-name">
                            <xsl:with-param name="language-attribute" select="$language-attribute"/>
                            <xsl:with-param name="b-autoeval" select="$b-autoeval"/>
                        </xsl:call-template>
                    </string>
                    <boolean key="linked">true</boolean>
                    <string key="linkKey">
                        <xsl:text>linked-</xsl:text>
                        <xsl:value-of select="$language-attribute" />
                    </string>
                    <boolean key="autoeval">
                        <xsl:value-of select="$b-autoeval"/>
                    </boolean>
                    <array key="languages">
                        <string>
                            <xsl:value-of select="$language-attribute" />
                        </string>
                    </array>
                    <string key="evalButtonText">
                        <xsl:apply-templates select="." mode="type-name">
                            <xsl:with-param name="string-id" select="'evaluate'"/>
                        </xsl:apply-templates>
                        <xsl:text> (</xsl:text>
                        <xsl:value-of select="$language-text" />
                        <xsl:text>)</xsl:text>
                    </string>
                    <xsl:if test="$b-autoeval">
                        <array key="hide">
                            <string>evalButton</string>
                        </array>
                    </xsl:if>
                </map>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:text>);&#xa;</xsl:text>
    </xsl:element>
</xsl:template>

<!-- template for a "display only" version -->
<xsl:template name="sagecell-display">
    <xsl:element name="script">
        <xsl:text>// Make *any* div with class 'sage-display' a visible, uneditable Sage cell&#xa;</xsl:text>
        <xsl:text>sagecell.makeSagecell(</xsl:text>
        <xsl:call-template name="json">
            <xsl:with-param name="content">
                <map xmlns="http://www.w3.org/2005/xpath-functions">
                    <string key="inputLocation">div.sage-display</string>
                    <string key="editor">codemirror-readonly</string>
                    <array key="hide">
                        <string>evalButton</string>
                        <string>editorToggle</string>
                        <string>language</string>
                    </array>
                </map>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:text>);&#xa;</xsl:text>
    </xsl:element>
</xsl:template>

<!-- All languages, linked only to similar   -->
<!-- Generic button, drop-down for languages -->
<xsl:template name="sagecell-practice">
    <xsl:element name="script">
        <xsl:text>// Make *any* div with class 'sagecell-practice' an executable Sage cell&#xa;</xsl:text>
        <xsl:text>// Their results will be linked, only within language type&#xa;</xsl:text>
        <xsl:text>sagecell.makeSagecell(</xsl:text>
        <xsl:call-template name="json">
            <xsl:with-param name="content">
                <map xmlns="http://www.w3.org/2005/xpath-functions">
                    <string key="inputLocation">div.sagecell-practice</string>
                    <boolean key="linked">true</boolean>
                    <string key="evalButtonText">
                        <xsl:apply-templates select="." mode="type-name">
                            <xsl:with-param name="string-id" select="'evaluate'"/>
                        </xsl:apply-templates>
                    </string>
                    <!-- drop-down allows practice with all possible languages -->
                    <raw key="languages">sagecell.allLanguages</raw>
                </map>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:text>);&#xa;</xsl:text>
    </xsl:element>
</xsl:template>


<!-- Make Sage Cell Server headers on a per-language basis -->
<!-- Examine the subtree of the page, which can still be   -->
<!-- excessive for summary pages, so room for improvement  -->
<!-- Note: this template employs the context given in a    -->
<!-- "select" attribute so that only the Javascript        -->
<!-- necessary for a page is invoked.  Further,            -->
<!-- cross-reference knowls also have these bits of set-up -->
<!-- javascript, but only for what the knowl content needs.-->
<xsl:template match="*" mode="sagecell">
    <!-- only check for all the special types if there is actually a sage element -->
    <xsl:if test="$b-has-sage">
        <!-- special types -->
        <xsl:if test=".//sage[@type='display']">
            <xsl:call-template name="sagecell-display" />
        </xsl:if>

        <xsl:if test=".//sage[@type='practice']">
            <xsl:call-template name="sagecell-practice" />
        </xsl:if>

        <!-- 2016-06-13: sage, gap, gp, html, maxima, octave, python, r, and singular -->
        <!-- 2024-02-07: add macaulay2                                                -->

        <xsl:if test=".//sage[not(@type) and (not(@language) or @language='sage') and not(@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>sage</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="false()"/>
                <xsl:with-param name="language-text">Sage</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[not(@type) and (not(@language) or @language='sage') and (@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>sage</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="true()"/>
                <xsl:with-param name="language-text">Sage</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='gap' and not(@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>gap</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="false()"/>
                <xsl:with-param name="language-text">GAP</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='gap' and (@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>gap</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="true()"/>
                <xsl:with-param name="language-text">GAP</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='gp' and not(@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>gp</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="false()"/>
                <xsl:with-param name="language-text">GP</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='gp' and (@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>gp</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="true()"/>
                <xsl:with-param name="language-text">GP</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='html' and not(@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>html</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="false()"/>
                <xsl:with-param name="language-text">HTML</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='html' and (@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>html</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="true()"/>
                <xsl:with-param name="language-text">HTML</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='macaulay2' and not(@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>macaulay2</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="false()"/>
                <xsl:with-param name="language-text">Macaulay2</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='macaulay2' and (@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>macaulay2</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="true()"/>
                <xsl:with-param name="language-text">Macaulay2</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='maxima' and not(@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>maxima</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="false()"/>
                <xsl:with-param name="language-text">Maxima</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='maxima' and (@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>maxima</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="true()"/>
                <xsl:with-param name="language-text">Maxima</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='octave' and not(@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>octave</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="false()"/>
                <xsl:with-param name="language-text">Octave</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='octave' and (@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>octave</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="true()"/>
                <xsl:with-param name="language-text">Octave</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='python' and not(@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>python</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="false()"/>
                <xsl:with-param name="language-text">Python</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='python' and (@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>python</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="true()"/>
                <xsl:with-param name="language-text">Python</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='r' and not(@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>r</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="false()"/>
                <xsl:with-param name="language-text">R</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='r' and (@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>r</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="true()"/>
                <xsl:with-param name="language-text">R</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='singular' and not(@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>singular</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="false()"/>
                <xsl:with-param name="language-text">Singular</xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:if test=".//sage[@language='singular' and (@auto-evaluate = 'yes')]">
            <xsl:call-template name="makesagecell">
                <xsl:with-param name="language-attribute">
                    <xsl:text>singular</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="b-autoeval" select="true()"/>
                <xsl:with-param name="language-text">Singular</xsl:with-param>
            </xsl:call-template>
        </xsl:if>
    </xsl:if>
</xsl:template>


<!-- Program Listings highlighted by Prism -->
<xsl:template name="syntax-highlight">
    <xsl:if test="$b-has-program and not($b-debug-react)">
        <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/components/prism-core.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/plugins/autoloader/prism-autoloader.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/plugins/line-numbers/prism-line-numbers.min.js" integrity="sha512-dubtf8xMHSQlExGRQ5R7toxHLgSDZ0K7AunqPWHXmJQ8XyVIG19S1T95gBxlAeGOK02P4Da2RTnQz0Za0H0ebQ==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/plugins/line-highlight/prism-line-highlight.min.js" integrity="sha512-93uCmm0q+qO5Lb1huDqr7tywS8A2TFA+1/WHvyiWaK6/pvsFl6USnILagntBx8JnVbQH5s3n0vQZY6xNthNfKA==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
        <xsl:if test="$b-html-theme-legacy">
            <!-- Legacy themes rely on external css for prism, but newer ones have it built in -->
            <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/themes/prism.css" rel="stylesheet"/>
            <!-- We could conditionally load the following based on line number -->
            <!-- requests, but have chosen not to enact that efficiency         -->
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/plugins/line-numbers/prism-line-numbers.min.css" integrity="sha512-cbQXwDFK7lj2Fqfkuxbo5iD1dSbLlJGXGpfTDqbggqjHJeyzx88I3rfwjS38WJag/ihH7lzuGlGHpDBymLirZQ==" crossorigin="anonymous" referrerpolicy="no-referrer" />
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/plugins/line-highlight/prism-line-highlight.min.css" integrity="sha512-nXlJLUeqPMp1Q3+Bd8Qds8tXeRVQscMscwysJm821C++9w6WtsFbJjPenZ8cQVMXyqSAismveQJc0C1splFDCA==" crossorigin="anonymous" referrerpolicy="no-referrer" />
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- JS setup for a Google Custom Search Engine box -->
<!-- Empty if not enabled via presence of cx number -->
<xsl:template name="google-search-box-js">
    <xsl:if test="$b-google-cse and not($b-debug-react)">
        <script async="">
            <xsl:attribute name="src">
                <xsl:text>https://cse.google.com/cse.js?cx=</xsl:text>
                <xsl:value-of select="$google-search-cx"/>
            </xsl:attribute>
        </script>
    </xsl:if>
</xsl:template>

<!-- Div for Google Search -->
<!-- https://developers.google.com/custom-search/docs/element -->
<!-- Empty if not enabled via presence of cx number           -->
<xsl:template name="google-search-box">
    <xsl:if test="$b-google-cse">
        <!-- ARIA: "search" role for Google Search div/wrapper -->
        <div class="searchwrapper" role="search">
            <div class="gcse-search" />
        </div>
    </xsl:if>
</xsl:template>

<!-- JS for native search -->
<!-- The async attribute may help with slow downloads,  -->
<!-- especially the project-specific search-file which  -->
<!-- can be as large as several megabytes.              -->
<!-- NB: async attribute also on Lunr and PTX-JS        -->
<!-- resulted in console errors (2022-02-08)            -->
<xsl:template name="native-search-box-js">
    <xsl:if test="$has-native-search and not($b-debug-react)">
        <script src="https://cdnjs.cloudflare.com/ajax/libs/lunr.js/2.3.9/lunr.min.js" integrity="sha512-4xUl/d6D6THrAnXAwGajXkoWaeMNwEKK4iNfq5DotEbLPAfk6FSxSP3ydNxqDgCw1c/0Z1Jg6L8h2j+++9BZmg==" crossorigin="anonymous" referrerpolicy="no-referrer"/>
        <!-- document-specific variables with search documents -->
        <script src="{$lunr-search-file}" async=""/>
        <!-- PreTeXt Javascript and CSS to form and render results of a search -->
        <script src="{$html.js.dir}/pretext_search.js"/>
        <!-- CSS for search is bundled into theme.css -->
    </xsl:if>
</xsl:template>


<!-- Div for native search -->
<xsl:template name="native-search-box">
    <xsl:if test="$has-native-search">
        <div class="searchbox">
            <div class="searchwidget">
                <button id="searchbutton" class="searchbutton button" type="button" title="Search book">
                    <xsl:call-template name="insert-symbol">
                        <xsl:with-param name="name" select="'search'"/>
                    </xsl:call-template>
                    <span class="name">Search Book</span>
                </button>
            </div>
            <xsl:call-template name="native-search-results"/>
        </div>
    </xsl:if>
</xsl:template>

<!-- Div for native search results -->
<xsl:template name="native-search-results">
    <xsl:if test="$has-native-search">
        <div id="searchresultsplaceholder" class="searchresultsplaceholder" style="display: none">
            <div class="search-results-controls">
                <input aria-label="Search term" id="ptxsearch" class="ptxsearch" type="text" name="terms" placeholder="Search term"/>
                <button title="Close search" id="closesearchresults" class="closesearchresults"><span class="material-symbols-outlined">close</span></button>
            </div>
            <h2 class="search-results-heading">
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'search-results-heading'"/>
                </xsl:apply-templates>
                <xsl:text>: </xsl:text>
            </h2>
            <!-- div#searchempty is not visible when there are results -->
            <div id="searchempty" class="searchempty">
                <span>
                    <xsl:apply-templates select="." mode="type-name">
                        <xsl:with-param name="string-id" select="'no-search-results'"/>
                    </xsl:apply-templates>
                    <xsl:text>.</xsl:text>
                </span>
            </div>
            <ol id="searchresults" class="searchresults">
            </ol>
        </div>
    </xsl:if>
</xsl:template>

<!-- Knowl header -->
<xsl:template match="*" mode="knowl">
    <xsl:if test="not($b-debug-react)">
        <script src="{$html.jslib.dir}/knowl.js"></script>
        <!-- Variables are defined to defaults in knowl.js and  -->
        <!-- we can override them with new values here          -->
        <xsl:comment>knowl.js code controls Sage Cells within knowls</xsl:comment>
        <script>
            <!-- button text, internationalized -->
            <xsl:text>sagecellEvalName='</xsl:text>
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'evaluate'"/>
            </xsl:apply-templates>
            <xsl:text> (</xsl:text>
            <!-- $language-text hard-coded since language  -->
            <!-- support within knowls is not yet settled -->
            <xsl:text>Sage</xsl:text>
            <xsl:text>)</xsl:text>
            <xsl:text>';&#xa;</xsl:text>
        </script>
    </xsl:if>
</xsl:template>

<!-- Header information for favicon -->
<!-- Presently: needs two image files placeed in  HTML output     -->
<!-- Publisher file could be extended to allow for other schemes. -->
<!--      See: https://realfavicongenerator.net/faq               -->
<!-- for one such option and ideas for others.                    -->
<xsl:template name="favicon">
    <!-- $docinfo/html/favicon indicator is legacy code.  We do -->
    <!-- not rewrite the publisher file as part of the assembly -->
    <!-- (pre-processor) phase, so we leave this in.  Removal   -->
    <!-- will require a sterner deprecation message that the    -->
    <!-- current, gentle, reminder.                             -->
    <xsl:if test="($favicon-scheme = 'simple') or $docinfo/html/favicon">
        <!-- Expects publisher to provide both -->
        <!--     favicon/favicon-32x32.png     -->
        <!--     favicon/favicon-16x16.png     -->
        <!-- in the external images directory  -->
        <xsl:variable name="res32">
            <!-- empty when not using managed directories -->
            <xsl:value-of select="$external-directory"/>
            <xsl:text>favicon/favicon-32x32.png</xsl:text>
        </xsl:variable>
        <xsl:variable name="res16">
            <!-- empty when not using managed directories -->
            <xsl:value-of select="$external-directory"/>
            <xsl:text>favicon/favicon-16x16.png</xsl:text>
        </xsl:variable>
        <link rel="icon" type="image/png" sizes="32x32" href="{$res32}"/>
        <link rel="icon" type="image/png" sizes="16x16" href="{$res16}"/>
    </xsl:if>
</xsl:template>

<!-- PreTeXt Javascript header -->
<xsl:template name="pretext-js">
    <xsl:choose>
        <xsl:when test="not($b-debug-react)">
            <!-- condition first on toc present? -->
            <script src="{$html.jslib.dir}/jquery.min.js"></script>
            <script src="{$html.jslib.dir}/jquery.sticky.js" ></script>
            <script src="{$html.jslib.dir}/jquery.espy.min.js"></script>
            <script src="{$html.js.dir}/pretext.js"></script>
            <script src="{$html.js.dir}/pretext_add_on.js?x=1"></script>
            <script src="{$html.js.dir}/user_preferences.js"></script>
        </xsl:when>
        <xsl:when test="$b-debug-react-local">
            <script type="module" defer="" src="./static/js/main.js"></script>
            <link href="./static/css/main.css" rel="stylesheet"/>
        </xsl:when>
        <!-- provisional implementation -->
        <xsl:when test="$b-debug-react-global">
            <xsl:variable name="prefix" select="'https://siefkenj.github.io/pretext-react'"/>
            <script type="module" defer="" src="{$prefix}/static/js/main.js"></script>
            <link href="{$prefix}/static/css/main.css" rel="stylesheet"/>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Font header -->
<!-- Google Fonts -->
<!-- Text: Open Sans by default (was: Istok Web font, regular and italic (400), bold (700)) -->
<!-- Code: Inconsolata, regular (400), bold (700) (was: Source Code Pro regular (400))      -->
<!-- (SourceCodePro being removed) -->
<xsl:template name="fonts">
    <link rel="preconnect" href="https://fonts.googleapis.com"/>
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin=""/>
    <!-- Material Symbols font used for symbols -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0" />
    <!-- Legacy themes need these fonts, modern ones load them on their own -->
    <xsl:if test="$b-html-theme-legacy">
            <!-- DejaVu Serif from an alternate CDN -->
            <link href="https://fonts.cdnfonts.com/css/dejavu-serif" rel="stylesheet"/>
            <!-- A variable font from Google, with serifs -->
            <link href="https://fonts.googleapis.com/css2?family=PT+Serif:ital,wght@0,400;0,700;1,400;1,700&amp;display=swap" rel="stylesheet"></link>
            <!-- A variable font from Google, sans serif -->
            <link href="https://fonts.googleapis.com/css2?family=Open+Sans:wdth,wght@75..100,300..800&amp;display=swap" rel="stylesheet"/>
            <!-- NB: not loading (binary) italic axis for variable fonts, tests seem to indicate this is OK -->
            <link href="https://fonts.googleapis.com/css2?family=Inconsolata:wght@400;700&amp;" rel="stylesheet"/>
    </xsl:if>
</xsl:template>

<!-- Hypothes.is Annotations -->
<!-- Configurations are the defaults as of 2016-11-04   -->
<!-- async="" is a guessed-hack, docs have no attribute -->
<xsl:template name="hypothesis-annotation">
    <xsl:if test="$b-activate-hypothesis">
        <script type="application/json" class="js-hypothesis-config">
        <xsl:text>{&#xa;</xsl:text>
        <xsl:text>    "openSidebar": false,</xsl:text>
        <xsl:text>    "showHighlights": true,</xsl:text>
        <xsl:text>}</xsl:text>
        </script>
        <script src="https://hypothes.is/embed.js" async=""></script>
    </xsl:if>
</xsl:template>

<!-- GeoGebra -->
<!-- The JS necessary to load the "App" for a generic calculator -->
<xsl:template name="geogebra">
    <xsl:if test="$b-has-calculator and contains($html-calculator,'geogebra')">
        <script src="https://cdn.geogebra.org/apps/deployggb.js"></script>
    </xsl:if>
</xsl:template>

<!-- JSXGraph -->
<xsl:template name="jsxgraph">
    <xsl:if test="$b-has-jsxgraph">
        <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/jsxgraph/0.99.6/jsxgraph.css" />
        <script src="https://cdnjs.cloudflare.com/ajax/libs/jsxgraph/0.99.6/jsxgraphcore.js"></script>
    </xsl:if>
</xsl:template>

<!-- Mermaid header libraries -->
<xsl:template name="mermaid-header">
    <xsl:if test="$b-has-mermaid">
        <script type="module">
            import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
            let theme = '<xsl:value-of select="$mermaid-theme"/>';
            if (isDarkMode())
                theme = 'dark';
            mermaid.initialize({
                securityLevel: 'loose',
                theme: theme,
            });
        </script>
    </xsl:if>
</xsl:template>

<!-- Diagcess header library -->
<xsl:template name="diagcess-header">
    <xsl:if test="$b-has-prefigure-annotations">
        <script src="{$html.js.dir}/diagcess/diagcess.js"></script>
    </xsl:if>
</xsl:template>

<!-- Diagcess footer initialization -->
<xsl:template name="diagcess-footer">
    <xsl:if test="$b-has-prefigure-annotations">
        <script>diagcess.Base.init()</script>
    </xsl:if>
</xsl:template>

<!-- CSS header -->
<xsl:template name="css-common">
    <!-- Temporary until css handling overhaul by ascholer complete -->
    <xsl:if test="$b-needs-custom-marker-css">
        <link href="{$html.css.dir}/ol-markers.css" rel="stylesheet" type="text/css"/>
    </xsl:if>
    <!-- If extra CSS is specified, then unpack multiple CSS files -->
    <xsl:if test="not($html.css.extra = '')">
        <xsl:variable name="csses" select="str:tokenize($html.css.extra, ', ')"/>
        <!-- $scripts is a collection of "token" and does not have -->
        <!-- a root, which implies the form of the "for-each"      -->
        <xsl:for-each select="$csses">
            <link rel="stylesheet" type="text/css">
                <xsl:attribute name="href">
                    <xsl:value-of select="." />
                </xsl:attribute>
            </link>
        </xsl:for-each>
    </xsl:if>
    <!-- For testing purposes a developer can set the stringparam -->
    <!-- "debug.developer.css" to the value "yes" and provide a   -->
    <!-- CSS file to be loaded last.                              -->
    <xsl:if test="$debug.developer.css = 'yes'">
        <xsl:comment> This HTML version has been built with elective CSS strictly </xsl:comment>
        <xsl:comment> for testing purposes, and the developer who chose to use it </xsl:comment>
        <xsl:comment> must supply it.                                             </xsl:comment>
        <link href="developer.css" rel="stylesheet" type="text/css" />
    </xsl:if>
</xsl:template>

<!-- The printout previews get their own css target that controls both screen and print styles -->
<xsl:template name="css-printable">
    <xsl:if test="not($b-debug-react)">
        <link href="{$html.css.dir}/print-worksheet.css" rel="stylesheet" type="text/css"/>
    </xsl:if>
    <xsl:call-template name="css-common"/>
</xsl:template>

<xsl:template name="css">
    <xsl:if test="not($b-debug-react)">
        <link href="{$html.css.dir}/{$html-css-theme-file}" rel="stylesheet" type="text/css"/>
    </xsl:if>
    <xsl:call-template name="css-common"/>
</xsl:template>

<!-- Inject classes into the root div of a book. Only for used for   -->
<!-- legacy styles - handles old css@colors and dark-mode disabling  -->
<xsl:template name="html-theme-attributes">
    <!-- check for use of old css color sheets -->
    <xsl:if test="$b-html-theme-legacy">
        <xsl:attribute name="data-legacy-colorscheme">
            <xsl:choose>
                <xsl:when test="not($debug.colors = '')">
                    <xsl:value-of select="$debug.colors"/>
                </xsl:when>
                <xsl:when test="not($html.css.colors = '')">
                    <xsl:value-of select="$html.css.colors"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>default</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:if>
    <xsl:if test="not($b-theme-has-darkmode)">
        <xsl:attribute name="data-darkmode">
            <xsl:text>disabled</xsl:text>
        </xsl:attribute>
    </xsl:if>
</xsl:template>

<!-- Treated as characters, these could show up often, -->
<!-- so load into every possible HTML page instance    -->
<xsl:template name="font-awesome">
    <xsl:if test="$b-has-icon">
        <!-- CDNJS is an alternative for obtaining this CSS -->
        <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.15.4/css/all.css" crossorigin="anonymous"/>
    </xsl:if>
</xsl:template>

<!-- A place to put *one* Javascript file at the *end* of an  -->
<!-- HTML page/file.  Not present in *every* page implemented -->
<!-- in this file, such as knowls.                            -->
<xsl:template name="extra-js-footer">
    <xsl:if test="not($html.js.extra = '')">
        <script src="{$html.js.extra}"></script>
    </xsl:if>
</xsl:template>

<!-- ################## -->
<!-- Language Direction -->
<!-- ################## -->

<!-- Note: perhaps this should begin in a localization file, -->
<!-- and come through as a key; but perhaps this template    -->
<!-- can stay as is.                                         -->
<xsl:template name="language-attributes">
    <xsl:attribute name="lang">
        <xsl:value-of select="$document-language"/>
    </xsl:attribute>
    <xsl:attribute name="dir">
        <xsl:value-of select="$document-language-direction"/>
    </xsl:attribute>
</xsl:template>


<!-- ############## -->
<!-- LaTeX Preamble -->
<!-- ############## -->

<!-- First a variable to massage the author-supplied -->
<!-- package list to the form MathJax expects        -->
<xsl:variable name="latex-packages-mathjax">
    <xsl:for-each select="$docinfo/math-package">
        <!-- must be specified, but can be empty/null -->
        <xsl:if test="not(normalize-space(@mathjax-name)) = ''">
            <xsl:text>\require{</xsl:text>
            <xsl:value-of select="@mathjax-name"/>
            <xsl:apply-templates/>
            <xsl:text>}</xsl:text>
            <!-- all on one line, not very readable, but historical -->
        </xsl:if>
    </xsl:for-each>
</xsl:variable>

<!-- MathJax expects math wrapping, and we place in   -->
<!-- a hidden div so not visible and take up no space -->
<!-- Inline CSS added because a "flash" was visible   -->
<!-- between HTML loading and CSS taking effect.      -->
<!-- We could rename this properly, since we are      -->
<!-- sneaking in packages, which load first, in       -->
<!-- case authors want to build on these macros       -->
<xsl:template name="latex-macros">
    <div id="latex-macros" class="hidden-content process-math" style="display:none">
        <xsl:call-template name="inline-math-wrapper">
            <xsl:with-param name="math">
                <xsl:value-of select="$latex-packages-mathjax"/>
                <xsl:value-of select="$latex-macros"/>
                <xsl:call-template name="fillin-math"/>
                <!-- legacy built-in support for "slanted|beveled|nice" fractions -->
                <xsl:if test="$b-has-sfrac">
                    <xsl:text>\newcommand{\sfrac}[2]{{#1}/{#2}}&#xa;</xsl:text>
                </xsl:if>
            </xsl:with-param>
        </xsl:call-template>
    </div>
</xsl:template>

<!-- If editing is enabled, the .ptx source file of each -->
<!-- HTML page will be created.  We still need to set a  -->
<!-- JavaScript variable to signal that the .ptx file    -->
<!-- should be fetched.                                  -->
<xsl:template name="enable-editing">
    <xsl:if test="$debug.editable = 'yes'">
        <script>sourceeditable = true</script>
    </xsl:if>
</xsl:template>


<!-- Brand Logo -->
<!-- Place image in masthead -->
<!-- We either create a link with an image, or just an image. -->
<!-- NB: This template does nothing unless $docinfo/brandlogo -->
<!-- exists, in which case we assume @source exists, as       -->
<!-- required by the schema.                                  -->
<xsl:template name="brand-logo">
    <xsl:if test="$docinfo/brandlogo">
        <xsl:variable name="location">
            <!-- empty when not using managed directories -->
            <xsl:value-of select="$external-directory"/>
            <xsl:value-of select="$docinfo/brandlogo/@source"/>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$docinfo/brandlogo/@url">
                <a id="logo-link" class="logo-link" target="_blank" >
                    <xsl:attribute name="href">
                        <xsl:value-of select="$docinfo/brandlogo/@url"/>
                    </xsl:attribute>
                    <img src="{$location}" alt="Logo image"/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                    <img src="{$location}" alt="Logo image"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- Analytics Footers -->

<!-- Google Analytics                     -->
<!-- "Classic", not compared to Universal -->
<xsl:template name="google-classic">
    <xsl:if test="$b-google-classic">
        <xsl:comment>Start: Google Classic code</xsl:comment>
        <xsl:comment>*** DO NOT COPY ANOTHER PROJECT'S MAGIC NUMBERS/ID ***</xsl:comment>
        <xsl:comment>***           GET YOUR OWN FROM GOOGLE             ***</xsl:comment>
        <xsl:text>&#xa;</xsl:text>
        <script>
            <xsl:text>&#xa;</xsl:text>
            <xsl:text>var _gaq = _gaq || [];&#xa;</xsl:text>
            <xsl:text>_gaq.push(['_setAccount', '</xsl:text>
            <xsl:value-of select="$google-classic-tracking" />
            <xsl:text>']);&#xa;</xsl:text>
            <xsl:text>_gaq.push(['_trackPageview']);&#xa;</xsl:text>
            <xsl:text>(function() {&#xa;</xsl:text>
            <xsl:text>var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;&#xa;</xsl:text>
            <xsl:text>ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'https://www') + '.google-analytics.com/ga.js';&#xa;</xsl:text>
            <xsl:text>var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);&#xa;</xsl:text>
            <xsl:text>})();&#xa;</xsl:text>
        </script>
        <xsl:text>&#xa;</xsl:text>
        <xsl:comment>End: Google Classic code</xsl:comment>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template name="google-universal">
    <xsl:if test="$b-google-universal">
        <xsl:comment>Start: Google Universal code</xsl:comment>
        <xsl:comment>*** DO NOT COPY ANOTHER PROJECT'S MAGIC NUMBERS/ID ***</xsl:comment>
        <xsl:comment>***           GET YOUR OWN FROM GOOGLE             ***</xsl:comment>
        <xsl:text>&#xa;</xsl:text>
        <script>
            <xsl:text>(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){&#xa;</xsl:text>
            <xsl:text>(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),&#xa;</xsl:text>
            <xsl:text>m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)&#xa;</xsl:text>
            <xsl:text>})(window,document,'script','https://www.google-analytics.com/analytics.js','ga');&#xa;</xsl:text>
            <xsl:text>ga('create', '</xsl:text>
            <xsl:value-of select="$google-universal-tracking" />
            <xsl:text>', 'auto');&#xa;</xsl:text>
            <xsl:text>ga('send', 'pageview');&#xa;</xsl:text>
        </script>
        <xsl:text>&#xa;</xsl:text>
        <xsl:comment>End: Google Universal code</xsl:comment>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Google says use first in <head>, seems fine in foot -->
<xsl:template name="google-gst">
    <xsl:if test="$b-google-gst">
        <xsl:variable name="gst-url">
            <xsl:text>https://www.googletagmanager.com/gtag/js?id=</xsl:text>
            <xsl:value-of select="$google-gst-tracking"/>
        </xsl:variable>
        <xsl:comment>Start: Google Global Site Tag code</xsl:comment>
        <xsl:comment>*** DO NOT COPY ANOTHER PROJECT'S MAGIC NUMBERS/ID ***</xsl:comment>
        <xsl:comment>***           GET YOUR OWN FROM GOOGLE             ***</xsl:comment>
        <xsl:text>&#xa;</xsl:text>
        <script async="" src="{$gst-url}"></script>
        <script>
            <xsl:text>  window.dataLayer = window.dataLayer || [];&#xa;</xsl:text>
            <xsl:text>  function gtag(){dataLayer.push(arguments);}&#xa;</xsl:text>
            <xsl:text>  gtag('js', new Date());&#xa;</xsl:text>
            <xsl:text>  gtag('config', '</xsl:text>
            <xsl:value-of select="$google-gst-tracking"/>
            <xsl:text>');&#xa;</xsl:text>
        </script>
        <xsl:comment>End: Google Global Site Tag code</xsl:comment>
    </xsl:if>
</xsl:template>

<!-- StatCounter                                -->
<!-- Set sc_invisible to 1                      -->
<!-- In noscript URL, final 1 is an edit from 0 -->
<xsl:template name="statcounter">
    <xsl:if test="$b-statcounter">
        <xsl:variable name="noscript_url">
            <xsl:text>https://c.statcounter.com/</xsl:text>
            <xsl:value-of select="$statcounter-project" />
            <xsl:text>/0/</xsl:text>
            <xsl:value-of select="$statcounter-security" />
            <xsl:text>/1/</xsl:text>
        </xsl:variable>
        <xsl:comment>Start: StatCounter code</xsl:comment>
        <xsl:comment>*** DO NOT COPY ANOTHER PROJECT'S MAGIC NUMBERS/ID ***</xsl:comment>
        <xsl:comment>***        GET YOUR OWN FROM STATCOUNTER           ***</xsl:comment>
        <script>
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>var sc_project=</xsl:text>
        <xsl:value-of select="$statcounter-project" />
        <xsl:text>;&#xa;</xsl:text>
        <xsl:text>var sc_invisible=1;&#xa;</xsl:text>
        <xsl:text>var sc_security="</xsl:text>
        <xsl:value-of select="$statcounter-security" />
        <xsl:text>";&#xa;</xsl:text>
        <xsl:text>var scJsHost = (("https:" == document.location.protocol) ? "https://secure." : "https://www.");&#xa;</xsl:text>
        <xsl:text>document.write("&lt;sc"+"ript src='" + scJsHost+ "statcounter.com/counter/counter.js'&gt;&lt;/"+"script&gt;");&#xa;</xsl:text>
        </script>
        <noscript>
        <div class="statcounter">
        <a title="web analytics" href="https://statcounter.com/" target="_blank">
        <img class="statcounter" src="{$noscript_url}" alt="web analytics" /></a>
        </div>
        </noscript>
        <xsl:comment>End: StatCounter code</xsl:comment>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- ########################### -->
<!-- Worksheet Margins and Pages -->
<!-- ########################### -->

<!-- We put page-margins-attributes only on printout sections -->
<xsl:template match="*" mode="page-margins-attribute"/>

<xsl:template match="worksheet|handout" mode="page-margins-attribute">
    <xsl:attribute name="data-margins">
        <!-- A space-separated list for top, right, bottom, and left margins -->
        <xsl:apply-templates select="." mode="printout-margin">
            <xsl:with-param name="author-side" select="@top"/>
            <xsl:with-param name="publisher-side" select="$ws-margin-top"/>
        </xsl:apply-templates>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="printout-margin">
            <xsl:with-param name="author-side" select="@right"/>
            <xsl:with-param name="publisher-side" select="$ws-margin-right"/>
        </xsl:apply-templates>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="printout-margin">
            <xsl:with-param name="author-side" select="@bottom"/>
            <xsl:with-param name="publisher-side" select="$ws-margin-bottom"/>
        </xsl:apply-templates>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="printout-margin">
            <xsl:with-param name="author-side" select="@left"/>
            <xsl:with-param name="publisher-side" select="$ws-margin-left"/>
        </xsl:apply-templates>
    </xsl:attribute>
</xsl:template>

<!-- A printout is (mostly) structured by "page", which translates    -->
<!-- into an HTML section.onepage.  Note that an "introduction" and    -->
<!-- "objectives" can precede the first "page" as HTML output, and the -->
<!-- final "page" may be followed by a "conclusion" and "outcomes"     -->
<xsl:template match="worksheet/page|handout/page">
    <section class="onepage">
        <xsl:apply-templates select="." mode="html-id-attribute"/>
        <xsl:apply-templates select="*"/>
    </section>
</xsl:template>

<!-- A template ensures standalone page creation, -->
<!-- and links to same, are consistent            -->
<xsl:template match="worksheet|handout" mode="standalone-printout-filename">
    <xsl:apply-templates select="." mode="visible-id"/>
    <xsl:text>-printable</xsl:text>
    <xsl:text>.html</xsl:text>
</xsl:template>

<!-- 2020-03-17: Empty element, since originally a       -->
<!-- "page" element interrupted numbering of contents.   -->
<!-- Now deprecated in favor of a proper "page" element. -->
<xsl:template match="worksheet/pagebreak">
    <hr class="pagebreak"/>
</xsl:template>

<!-- Miscellaneous -->

<!-- Inline warnings go into text, no matter what -->
<!-- They are colored for an author's report -->
<xsl:template name="inline-warning">
    <xsl:param name="warning" />
    <xsl:element name="span">
        <!-- Color for author tools version -->
        <xsl:if test="$author-tools-new = 'yes'" >
            <xsl:attribute name="style">color:red</xsl:attribute>
        </xsl:if>
        <xsl:text>(((</xsl:text>
        <xsl:value-of select="$warning" />
        <xsl:text>)))</xsl:text>
    </xsl:element>
</xsl:template>

<!-- Marginal notes are only for author's report                     -->
<!-- and are always colored red.  Marginpar's from                   -->
<!-- http://www.sitepoint.com/web-foundations/floating-clearing-css/ -->
<xsl:template name="margin-warning">
    <xsl:param name="warning" />
    <xsl:if test="$author-tools-new = 'yes'" >
        <xsl:element name="span">
            <xsl:attribute name="style">color:red;float:right;width:20em;margin-right:-25em;</xsl:attribute>
            <xsl:value-of select="$warning" />
        </xsl:element>
    </xsl:if>
</xsl:template>


<!-- SCORM manifest -->
<!-- Generate a simple xml file describing a minimal SCORM "course". -->
<!-- Besides some boiler plate, we include the title of the course   -->
<!-- (under the main organization), a single item (since the entire  -->
<!-- document is a single iframe), and the entry point for that item -->
<!-- (the resource with its file).  It appears that while other files-->
<!-- can be listed as files for that resource, this is not required. -->

<!-- The only customization we do here is setting the main title to  -->
<!-- the title of the document.  We could easily expand this.        -->
<xsl:template name="scorm-manifest">
    <xsl:variable name="root-filename">
        <xsl:apply-templates select="$document-root" mode="containing-filename" />
    </xsl:variable>
    <exsl:document href="imsmanifest.xml" method="xml" omit-xml-declaration="no" indent="yes">
        <manifest identifier="ptx-scorm-test" version="1" xmlns="http://www.imsglobal.org/xsd/imscp_v1p1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:adlcp="http://www.adlnet.org/xsd/adlcp_v1p3" xmlns:adlseq="http://www.adlnet.org/xsd/adlseq_v1p3" xmlns:adlnav="http://www.adlnet.org/xsd/adlnav_v1p3" xmlns:imsss="http://www.imsglobal.org/xsd/imsss" xsi:schemaLocation="http://www.imsglobal.org/xsd/imscp_v1p1 imscp_v1p1.xsd http://www.adlnet.org/xsd/adlcp_v1p3 adlcp_v1p3.xsd http://www.adlnet.org/xsd/adlseq_v1p3 adlseq_v1p3.xsd http://www.adlnet.org/xsd/adlnav_v1p3 adlnav_v1p3.xsd http://www.imsglobal.org/xsd/imsss imsss_v1p0.xsd">
            <!--The metadata node simply declares which SCORM version this course operates under.-->
            <metadata>
                <schema>ADL SCORM</schema>
                <schemaversion>2004 3rd Edition</schemaversion>
            </metadata>
            <!-- There is just one organization. The organization contains just one item.-->
            <organizations default="main">
                <organization identifier="main">
                    <title>
                        <xsl:apply-templates select="$document-root" mode="title-full"/>
                    </title>
                    <item identifier="item_1" identifierref="main-resource">
                        <!-- "Main" here is a generic name.  Only visible when importing a into LMS -->
                        <!-- (at least in Canvas), sort of a sole entry in the table of contents.   -->
                        <title>Main</title>
                    </item>
                </organization>
            </organizations>
            <!-- There is just one resource that represents the single SCO that comprises the entirety of this course. The href attribute points to the launch URL for the course and all of the files required by the course are listed. -->
            <resources>
                <!-- We use the index.html file pretext produces, as this always points to the right place.  -->
                <!-- NB we could point to any entry filename, as long as it is in the resulting zip          -->
                <resource identifier="main-resource" type="webcontent" adlcp:scormType="sco" href="index.html">
                <file href="index.html"/>
                </resource>
            </resources>
        </manifest>
    </exsl:document>
</xsl:template>

</xsl:stylesheet>
