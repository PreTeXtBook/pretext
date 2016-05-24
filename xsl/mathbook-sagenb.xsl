<?xml version='1.0'?> <!-- As XML file -->
<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exsl="http://exslt.org/common"
                extension-element-prefixes="exsl"
>

<!-- Trade on HTML markup, numbering, chunking, etc. -->
<!-- Override as pecularities of Sage Notebook arise -->
<xsl:import href="./mathbook-html.xsl" />

<!-- TODO: free chunking level -->
<!-- TODO: liberate GeoGebra, videos -->
<!-- TODO: style Sage display-only code in a similar padded box -->

<!-- Intend output for rendering by browsers-->
<xsl:output method="html" indent="yes"/>

<!-- We hard-code the chunking level, need to pass this  -->
<!-- through the mbx script or use a compatibility layer -->
<xsl:param name="html.chunk.level" select="1" />
<!-- We disable the ToC level to avoid any conflicts with chunk level -->
<xsl:param name="toc.level" select="0" />

<!-- HTML files as output -->
<xsl:variable name="file-extension" select="'.html'" />

<!-- Dual-purpose transform -->
<!-- 'files': produces the relevant content                 -->
<!-- 'info:': produces a sting mbx can use to locate assets -->
<xsl:param name="purpose" />

<xsl:template match="/">
    <xsl:if test="$purpose='files'">
        <xsl:apply-templates select="mathbook/*" mode="dispatch" />
    </xsl:if>
    <!-- Determine filenames of chunks,             -->
    <!-- their titles and their assets within       -->
    <!-- Creates a Python list, to be eval'ed -->
    <xsl:if test="$purpose='info'">
        <xsl:if test="not(//docinfo/initialism)">
            <xsl:message>MBX:WARNING: providing an &lt;initialism&gt; in the &lt;docinfo&gt; can make the Sage Notebook worksheet list more usable</xsl:message>
        </xsl:if>
        <xsl:if test="//program">
            <xsl:message>MBX:WARNING: syntax highlighting of program listings is not possible in the Sage Notebook - though you will see a display with a black monospace font</xsl:message>
        </xsl:if>
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="mathbook" mode="filenames"/>
        <xsl:text>]</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Root template, look at everything  -->
<xsl:template match="mathbook">
    <xsl:apply-templates />
</xsl:template>

<!-- ########## -->
<!-- Sage Cells -->
<!-- ########## -->

<!-- The Sage Notebook expects wiki markup for               -->
<!-- Sage input/output pairs.  Perhaps a regrettable         -->
<!-- design decision way back when.  We can at least warn    -->
<!-- about the conceivable event that some math contains the -->
<!-- evil leading triple braces. (It seems trailing braces   -->
<!-- are not a problem, but the test could be adjusted.)     -->
<xsl:template match="m|me|men|mrow">
    <xsl:variable name="tex"><xsl:value-of select="." /></xsl:variable>
    <xsl:if test="contains($tex, '{{{')">
        <xsl:message>MBX:WARNING: your source contains LaTeX syntax with three consecutive braces ("{{{") which confuses the Sage Notebook interface.  Consider adding canceling thin spaces ("\!\,"") to your source to break up the consecutive braces.  (Offending math: <xsl:value-of select="$tex" />)</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <xsl:apply-imports />
</xsl:template>

<!-- An abstract named template accepts input text and output             -->
<!-- text, then wraps it in the Sage Notebook's wiki syntax               -->
<!-- Output is always computable, so we do not show it.                   -->
<!-- Though we once experimented with printing it in green,               -->
<!-- hence readable, but clued in that it was not the "real" blue output  -->
<!-- Sage cell output goes in <script> element, xsltproc leaves "<" alone -->
<!-- Here xsltproc tries to escape them, so we explicitly prevent that    -->
<xsl:template name="sage-active-markup">
    <xsl:param name="in" />
    <xsl:param name="out" />
    <xsl:text>&#xa;{{{&#xa;</xsl:text>
        <xsl:value-of select="$in" disable-output-escaping="yes" />
    <xsl:text>///&#xa;</xsl:text>
    <xsl:text>}}}&#xa;</xsl:text>
</xsl:template>

<!-- An abstract named template accepts input text                        -->
<!-- and employs a <pre> element, so untouchable                          -->
<!-- Sage cell output goes in <script> element, xsltproc leaves "<" alone -->
<!-- Here xsltproc tries to escape them, so we explicitly prevent that    -->
<!-- TODO: learn of a way to prevent notebook evaluation -->
<xsl:template name="sage-display-markup">
    <xsl:param name="in" />
    <pre style="font-size:80%">
        <xsl:value-of select="$in" disable-output-escaping="yes" />
    </pre>
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

<!-- Document node summaries are normally links to the page         -->
<!-- Override for Sage Notebook production, no anchor/href, no type -->
<!-- We format these as smaller headings                            -->
<xsl:template match="book|article|chapter|appendix|section|subsection|subsubsection|exercises|references|frontmatter|preface|acknowledgement|biography|foreword|dedication|colophon" mode="summary-nav">
    <h5 class="heading">
        <span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
        <xsl:text> </xsl:text>
        <span class="title"><xsl:apply-templates select="." mode="title-simple" /></span>
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
        <xsl:text>#worksheet {padding-left:48px; padding-right:48px;}</xsl:text>
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
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="containing-filename" />
    </xsl:variable>
    <exsl:document href="{$filename}" method="html">
        <xsl:call-template name="converter-blurb-html" />
        <xsl:call-template name="fonts" />
        <xsl:call-template name="css" />
        <xsl:call-template name="styling" />            
        <xsl:call-template name="latex-macros" />
        <xsl:if test="not(self::frontmatter)" >
            <header>
                <h1 class="heading">
                    <span class="title"><xsl:value-of select="$title" /></span>
                    <p id="byline"><span class="byline"><xsl:value-of select="$credits" /></span></p>
                </h1>
                <!-- Write a URL into the header of each page, on principle -->
                <xsl:if test="//colophon/website or //colophon/copyright">
                    <h5 class="heading">
                        <xsl:if test="//colophon/copyright">
                            <xsl:apply-templates select="//colophon/copyright" mode="type-name" />
                            <xsl:text> </xsl:text>
                            <xsl:apply-templates select="//colophon/copyright/year" />
                            <xsl:if test="//colophon/copyright/minilicense">
                                <xsl:text> </xsl:text>
                                <xsl:apply-templates select="//colophon/copyright/minilicense" />
                            </xsl:if>
                            <xsl:if test="//colophon/website">
                                <br />
                            </xsl:if>
                        </xsl:if>
                        <xsl:if test="//colophon/website">
                            <xsl:element name="a">
                                <xsl:attribute name="href">
                                    <xsl:apply-templates select="//colophon/website/url" />
                                </xsl:attribute>
                                <xsl:apply-templates select="//colophon/website/title" />
                            </xsl:element>
                        </xsl:if>
                    </h5>
                </xsl:if>
            </header>
        </xsl:if>
        <xsl:copy-of select="$content" />
        <!--
        Script tags seem to confuse the notebook, so this is a broader problem
        <xsl:apply-templates select="/mathbook/docinfo/analytics" />
        -->
    </exsl:document>
</xsl:template>

<!-- CSS Servers -->
<!-- We override processing paramters of the generic    -->
<!-- HTML file to specify new servers, which the        -->
<!-- generic named "css" template will employ.          -->
<!-- We use the "content" version which is lightweight. -->
<!-- Note: we do not employ any javascript, leaving     -->
<!-- that to the Sage Notebook, hence not specified     -->
<xsl:param name="html.css.server" select="'http://aimath.org'" />
<xsl:param name="html.css.file"   select="'mathbook-content-3.css'" />


<!-- ################### -->
<!-- Asset Determination -->
<!-- ################### -->

<!-- We need to locate all the files which are "included" -->
<!-- more easily in the HTML version, both for packaging  -->
<!-- into the *.sws file, and for their appearance in     -->
<!-- the worsheet itself                                  -->

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
        <xsl:apply-templates select="." mode="containing-filename" />
        <xsl:text>'</xsl:text>
        <xsl:text>, </xsl:text>
        <!-- Title, prepended for Sage NB ToC sorting-->
        <!-- Triply-quoted for apostrophe, quote protection -->
        <xsl:text>"""</xsl:text>
        <!-- NB: coordinate with inititalism warning in 'info' template -->
        <xsl:if test="//docinfo/initialism">
            <xsl:value-of select="//docinfo/initialism" />
            <xsl:text>-</xsl:text>
        </xsl:if>
        <!-- Protect against double-dash for un-numbered divisions -->
        <xsl:variable name="num"><xsl:apply-templates select="." mode="number" /></xsl:variable>
        <xsl:if test="$num!=''">
            <xsl:value-of select="$num" />
            <xsl:text>-</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="title-simple" />
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

<!-- Traverse subtree, looking for datafiles to include  -->
<xsl:template match="@*|node()" mode="assets">
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
