<?xml version='1.0'?> <!-- As XML file -->
<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:import href="./mathbook-html.xsl" />

<!-- Intend output for rendering by browsers-->
<xsl:output method="html" indent="yes"/>

<xsl:strip-space elements="article section sage" />

<!-- Clobber all the head information of the HTML stylesheet -->
<xsl:template match="/mathbook">
    <!-- <link rel="stylesheet" type="text/css" href="mathbook.css" /> -->
    <xsl:apply-templates select="article"/>
</xsl:template>

<!-- Overall Structure -->
<xsl:template match="article">
    <!-- <xsl:call-template name="css-load" /> -->
    <!-- Start in HTML mode -->
    <xsl:call-template name="inputbegin-execute" />
    <xsl:text>%html&#xa;</xsl:text>
    <xsl:text>\(</xsl:text>
    <xsl:value-of select="/mathbook/docinfo/macros" />
    <xsl:text>\)</xsl:text>
    <!-- <xsl:call-template name="styling" /> -->
    <xsl:apply-templates select="*[not(self::title or self::subtitle)]"/>
    <!-- Totally done, wrap it up -->
    <xsl:call-template name="inputoutput" />
    <xsl:call-template name="outputend" />
</xsl:template>

<!-- Book length inactive -->
<xsl:template match="/book">
    <xsl:message terminate="yes">Book length documents do not yet convert to Sage Math Cloud worksheets.  Quitting...</xsl:message>
</xsl:template>

<!-- Divisions become just cells with font changes -->
<!-- Copied from stock HTML, but with apply-templates outside wrap-html -->
<xsl:template match="section">
    <xsl:element name="h4">
        <xsl:apply-templates select="." mode="number" />
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
    </xsl:element>
    <xsl:apply-templates select="*[not(self::title)]"/>
    <!-- Hop out, back in, to HTML mode, to allow new cell creation -->
    <xsl:call-template name="inputoutput" />
    <xsl:call-template name="outputend" />
    <xsl:call-template name="inputbegin-execute" />
    <xsl:text>%html&#xa;</xsl:text>    
</xsl:template>

<!-- Divisions become just cells with font changes -->
<!-- Copied from stock HTML, but with apply-templates outside wrap-html -->
<xsl:template match="subsection">
    <xsl:element name="h3">
        <xsl:apply-templates select="." mode="number" />
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
    </xsl:element>
    <xsl:apply-templates select="*[not(self::title)]"/>
</xsl:template>

<!-- Divisions become just cells with font changes -->
<!-- Copied from stock HTML, but with apply-templates outside wrap-html -->
<xsl:template match="subsubsection">
    <xsl:element name="h2">
        <xsl:apply-templates select="." mode="number" />
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
    </xsl:element>
    <xsl:apply-templates select="*[not(self::title)]"/>
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
    <!-- Drop out of HTML mode -->
    <xsl:call-template name="inputoutput" />
    <xsl:call-template name="outputend" />    
    <!-- Create a complete Sage cell region -->
    <xsl:call-template name="inputbegin" />
        <xsl:value-of select="$in" disable-output-escaping="yes" />
    <xsl:call-template name="inputoutput" />
    <xsl:call-template name="outputend" />
    <!-- Start back in HTML mode -->
    <xsl:call-template name="inputbegin-execute" />
    <xsl:text>%html&#xa;</xsl:text>
</xsl:template>

<!-- TODO: sage-display-markup needed -->

<!-- Sage Math Cloud named templates -->

<!-- An artifact of early efforts -->
<!-- Instructive so still here    -->
<xsl:template name="wrap-html">
    <xsl:param name="raw-html" />
    <xsl:call-template name="inputbegin-execute" />
    <xsl:text>%html&#xa;</xsl:text>
    <xsl:copy-of select="$raw-html" />
    <xsl:call-template name="inputoutput" />
    <xsl:call-template name="outputend" />
</xsl:template>

<!-- Needs work -->
<xsl:template name="css-load">
    <xsl:call-template name="inputbegin-hide" />
    <!-- <xsl:text>%auto&#xa;</xsl:text> Seems to get in the way -->
    <xsl:text>%load mathbook-3.css&#xa;</xsl:text>
    <xsl:call-template name="inputoutput" />
    <xsl:call-template name="outputend" />
</xsl:template>

<!-- UUID string gets replaced via Python script   -->
<!-- Line breaks are placed carefully              -->

<xsl:template name="inputbegin">
    <xsl:text>&#xFE20;UUID&#xFE20;&#xa;</xsl:text>
</xsl:template>

<!-- "x" code after UUID to execute   -->
<xsl:template name="inputbegin-execute">
    <xsl:text>&#xFE20;UUIDx&#xFE20;&#xa;</xsl:text>
</xsl:template>

<!-- "i" code after UUID to hide   -->
<xsl:template name="inputbegin-hide">
    <xsl:text>&#xFE20;UUIDi&#xFE20;&#xa;</xsl:text>
</xsl:template>

<xsl:template name="inputoutput">
    <xsl:text>&#xa;&#xFE21;UUID&#xFE21;</xsl:text>
</xsl:template>

<xsl:template name="outputend">
    <xsl:text>&#xFE21;&#xa;</xsl:text>
</xsl:template>

<!-- "i" code hides the input cell -->
<xsl:template name="hide-input">
    <xsl:text>i</xsl:text>
</xsl:template>

<!-- Currently empty, likely does not need wrapping -->
<xsl:template name="styling" >
    <xsl:call-template name="wrap-html">
        <xsl:with-param name="raw-html">
        <style>
        <!-- experimental SMC adjustments -->
        </style>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

</xsl:stylesheet>