<?xml version='1.0'?> <!-- As XML file -->
<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exsl="http://exslt.org/common"
                extension-element-prefixes="exsl"
>

<xsl:import href="./mathbook-html.xsl" />

<!-- TODO: protect math sections from Sage cell marker of triple-braces -->
<!-- TODO: better header for page-wrap -->
<!-- TODO: free chunking level, fix toc -->
<!-- TODO: liberate book -->
<!-- TODO: liberate GeoGebra -->

<!-- Intend output for rendering by browsers-->
<xsl:output method="html" indent="yes"/>

<!-- Single worksheets are <article>s, -->
<!-- so do not chunk into sections     -->
<!-- And no table of contents, either  -->
<!-- (even though it is header-info)   -->
<xsl:param name="html.chunk.level" select="1" />
<xsl:param name="toc.level" select="2" />
<xsl:param name="purpose" />

<xsl:template match="/">
    <!-- <link rel="stylesheet" type="text/css" href="mathbook.css" /> -->
    <!-- Book length inactive -->
<!--     <xsl:if test="mathbook/book">
        <xsl:message terminate="yes">Book length documents do not yet convert to Sage Notebook worksheets.  Quitting...</xsl:message>
    </xsl:if>
 -->    <xsl:if test="$purpose='files'">
        <xsl:apply-templates select="mathbook"/>
    </xsl:if>
    <!-- Determine filenames of chunks,             -->
    <!-- their titles and their assets within       -->
    <!-- Creates a Python assignment, to be exec'ed -->
    <xsl:if test="$purpose='info'">
        <xsl:if test="not(/mathbook/docinfo/initialization)">
            <xsl:message>MBX:WARNING: providing an &lt;inititalization&gt; in the &lt;docinfo&gt; can make the Sage Notebook worksheet list more usable</xsl:message>
        </xsl:if>
        <xsl:text>manifest = [</xsl:text>
        <xsl:apply-templates select="mathbook" mode="filenames"/>
        <xsl:text>]</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Overall Structure -->
<!-- Everything you might see in a <body>, -->
<!-- but not enclosed in <body>            -->
<!-- Don't match bibliography articles     -->
<xsl:template match="mathbook">
<!--     <xsl:apply-templates select="." mode="page-wrap">
        <xsl:with-param name="content">
            <xsl:apply-templates select="*[not(self::title)]"/>
        </xsl:with-param>
    </xsl:apply-templates>
 -->
    <xsl:apply-templates />


 <!-- 

        <xsl:text>{</xsl:text>
        <xsl:text>'title': "</xsl:text>
        <xsl:apply-templates select="title" />
        <xsl:text>"</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:call-template name="styling" />
        <xsl:call-template name="insert-macros" />
        <div class="headerblock">
            <div class="title"><xsl:apply-templates select="title" /></div>
            <div class="event"><xsl:apply-templates select="/mathbook/docinfo/event" /></div>
            <div class="authorgroup"><xsl:apply-templates select="/mathbook/docinfo/author" /></div>
            <div class="date"><xsl:apply-templates select="/mathbook/docinfo/date" /></div>
        </div>
        <xsl:apply-templates select="*[not(self::title)]" />
 -->
</xsl:template>

<xsl:template match="sage">
    <xsl:text>&#xa;{{{&#xa;</xsl:text>
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="input" />
    </xsl:call-template>
    <xsl:text>///&#xa;</xsl:text>
    <xsl:text>}}}&#xa;</xsl:text>
</xsl:template>
<!-- Bare sage element means an empty cell to scribble in -->
<xsl:template match="sage[not(input) and not(output)]">
    <xsl:text>&#xa;{{{&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>///&#xa;</xsl:text>
    <xsl:text>}}}&#xa;</xsl:text>
</xsl:template>

<!-- ############## -->
<!-- URL Banishment -->
<!-- ############## -->

<!-- Cross-worksheet links in the Sage Notebook are untenable -->
<!-- Strategy now is to 100% ban them, we could do relative   -->
<!-- links on a page with some work                           -->

<!-- A cross-reference has a visual component,             -->
<!-- formed elsewhere, and a realization as a hyperlink    -->
<!-- We override this for the Sage notebook, since         -->
<!-- we cannot determine cross-worksheet links in advance. -->
<!-- So just the content appears and no hyperlink          -->
<!-- TODO: generally improve xref links (urls) to be relative -->
 <!-- when possible, then recognize them here for use. -->
<xsl:template match="*" mode="xref-hyperlink">
    <xsl:param name="content" />
    <xsl:value-of  disable-output-escaping="yes" select="$content" />
</xsl:template>

<!-- Document node summaries are normally links to the page    -->
<!-- Override for Sage Notebook production, no anchor/href     -->
<!-- We format these as smaller headings                       -->
<xsl:template match="book|article|chapter|appendix|section|subsection|subsubsection" mode="summary-entry">
    <h5 class="heading">
        <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
        <xsl:text> </xsl:text>
        <span class="title"><xsl:apply-templates select="title" /></span>
    </h5>
</xsl:template>

<!-- Some document nodes will not normally have titles and we need default titles -->
<!-- Especially if one-off (eg Preface), or generic (Exercises)                   -->
<!-- Override for Sage Notebook production, no anchor/href                        -->
<!-- We format these as smaller headings                                          -->
<xsl:template match="exercises|references|frontmatter|preface|acknowledgement|authorbiography|foreword|dedication|colophon" mode="summary-entry">
    <h5 class="heading">
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
    </h5>
 </xsl:template>

<!-- Adjustments to the Sage Notebook size parameters     -->
<!-- #user-worksheet-page includes all UI elements        -->
<!-- We scrunch so that button lists do not reflow        -->
<!-- #worksheet is the "page", so we mimic the parameters -->
<!-- of the standard HTML view                            -->
<!-- NB: Annotations may require adjusting these          -->
<xsl:template name="styling" >
    <style>
        <xsl:text>#user-worksheet-page {max-width:1080px;}</xsl:text>
        <xsl:text>#worksheet {max-width:600px; padding-left:48px; padding-right:48px;}</xsl:text>
    </style>
</xsl:template>

<!-- Kill GeoGebra applets -->

<xsl:template match="geogebra-applet[ggbBase64]|geogebra-applet[not(ggbBase64)]">
    <xsl:call-template name="inline-warning">
        <xsl:with-param name="warning">GeoGebra applets disabled in Sage worksheets temporarily</xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="margin-warning">
        <xsl:with-param name="warning">GeoGebra disabled</xsl:with-param>
    </xsl:call-template>

    <p></p>
</xsl:template>

<!-- An individual page:                                     -->
<!-- Inputs:                                                 -->
<!--     * strings for page title, subtitle, authors/editors -->
<!--     * content (exclusive of banners, etc)               -->
<xsl:template match="*" mode="page-wrap">
    <xsl:param name="title" />
    <xsl:param name="subtitle" />
    <xsl:param name="credits" />
    <xsl:param name="content" />
    <xsl:variable name="file"><xsl:apply-templates select="." mode="filename" /></xsl:variable>
    <exsl:document href="{$file}" method="html">
        <xsl:call-template name="converter-blurb" />
        <xsl:call-template name="fonts" />
        <xsl:call-template name="css" />
        <xsl:call-template name="styling" />            
<!--         
        <xsl:if test="/mathbook//program">
            <xsl:call-template name="goggle-code-prettifier" />
        </xsl:if>
        <xsl:if test="//video">
            <xsl:call-template name="video" />
        </xsl:if>
 -->        
        <xsl:call-template name="latex-macros" />
        <h1 id="title">
            <span class="title"><xsl:value-of select="$title" /></span>
            <p id="byline"><span class="byline"><xsl:value-of select="$credits" /></span></p>
        </h1>
        <div id="content" class="mathbook-content">
            <xsl:copy-of select="$content" />
        </div>
        <!-- <xsl:apply-templates select="/mathbook/docinfo/analytics" /> -->
    </exsl:document>
</xsl:template>

<!-- CSS header -->
<!-- No interface work, just content styling -->
<!-- The Sage Notebook provides the interface -->
<xsl:template name="css">
    <!-- #1 to #5 for different color schemes -->
    <link href="http://mathbook.staging.michaeldubois.me/develop/stylesheets/mathbook-content.css" rel="stylesheet" type="text/css" />
    <!-- <link href="http://mathbook.staging.michaeldubois.me/develop/stylesheets/icons.css" rel="stylesheet" type="text/css" /> -->
    <link href="http://aimath.org/mathbook/add-on.css" rel="stylesheet" type="text/css" />
</xsl:template>

<!-- Filename Determination -->
<!-- Traverse the tree, writing filename and title of every webpage created           -->
<!-- Prepend titles (no footnotes) to make manageable in Sage Notebook Worksheet list -->
<!-- For an entire webpage, cruise children for assets                                -->
<!-- For a summary webpage, cruise non-summary items for assets                       -->
<xsl:template match="@*|node()" mode="filenames">
    <xsl:variable name="webpage"><xsl:apply-templates select="." mode="is-webpage" /></xsl:variable>
    <xsl:variable name="summary"><xsl:apply-templates select="." mode="is-summary" /></xsl:variable>
    <xsl:if test="$webpage='true' or $summary='true'">
        <xsl:text>[</xsl:text>
        <!-- HTML filename, no path -->
        <xsl:text>'</xsl:text>
        <xsl:apply-templates select="." mode="filename" />
        <xsl:text>'</xsl:text>
        <xsl:text>, </xsl:text>
        <!-- Title, prepended for Sage NB ToC sorting-->
        <!-- Triply-quoted for apostrophe, quote protection -->
        <xsl:text>"""</xsl:text>
        <!-- NB: coordinate with inititlization warning in 'info' template -->
        <xsl:if test="/mathbook/docinfo/initialization">
            <xsl:value-of select="/mathbook/docinfo/initialization" />
            <xsl:text>-</xsl:text>
        </xsl:if>
        <!-- Protect against double-dash for un-numbered divisions -->
        <xsl:variable name="num"><xsl:apply-templates select="." mode="number" /></xsl:variable>
        <xsl:if test="$num!=''">
            <xsl:value-of select="$num" />
            <xsl:text>-</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="title/node()[not(self::fn)]" />
        <xsl:text>"""</xsl:text>
        <xsl:text>, </xsl:text>
        <!-- Any included files, necessary for inclusions -->
        <xsl:if test="$webpage='true'">
            <xsl:text>[</xsl:text>
            <xsl:apply-templates mode="assets" />
            <xsl:text>]</xsl:text>
        </xsl:if>
        <xsl:if test="$summary='true'">
            <xsl:text>[</xsl:text>
            <xsl:apply-templates select="introduction|conclusion" mode="assets" />
            <xsl:text>]</xsl:text>
        </xsl:if>
        <xsl:text>], </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="@*|node()" mode="filenames" />
</xsl:template>

<!-- Asset Determination -->
<!-- We need to locate all the files which are "included" -->
<!-- more easily in the HTML version, both for packaging  -->
<!-- into the *.sws file, and for their appearance in     -->
<!-- the worsheet itself                                  -->

<!-- Traverse subtree, looking for datafiles to include  -->
<xsl:template match="@*|node()" mode="assets">
<!--     <xsl:variable name="leaf"><xsl:apply-templates select="." mode="is-leaf" /></xsl:variable>
    <xsl:if test="$leaf='true'">
 -->
    <xsl:apply-templates select="@*|node()" mode="assets" />
</xsl:template>

<!-- Paths will be normalized by receiving Python script -->
<xsl:template match="tikz|asymptote|sageplot" mode="assets" >
    <xsl:text>'</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>.svg</xsl:text>
    <xsl:text>', </xsl:text>
</xsl:template>

<xsl:template match="image" mode="assets" >
    <xsl:text>'</xsl:text>
    <xsl:value-of select="@source" />
    <xsl:text>', </xsl:text>
</xsl:template>


</xsl:stylesheet>