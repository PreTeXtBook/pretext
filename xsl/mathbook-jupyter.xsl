<?xml version='1.0'?> <!-- As XML file -->
<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:import href="./mathbook-common.xsl" />
<xsl:import href="./common-markdown.xsl" />

<!-- Output is JSON -->
<xsl:output method="text" indent="yes"/>

<xsl:strip-space elements="article section sage" />

<!-- Bypass docinfo metadata -->
<xsl:template match="/mathbook">
    <xsl:apply-templates select="article"/>
</xsl:template>

<!-- Book length inactive -->
<xsl:template match="/book">
    <xsl:message terminate="yes">Book length documents do not yet convert to iPython notebooks.  Quitting...</xsl:message>
</xsl:template>

<!-- Kill titles, handle as title/node() as needed -->
<xsl:template match="title"></xsl:template>

<!-- Article Structure -->
<xsl:template match="article">
    <!-- Gross structure for iPython notebook -->
    <xsl:text>{&#xa;</xsl:text>
    <xsl:text>"metadata": {"name": "</xsl:text>
        <xsl:apply-templates select="title/node()" />
    <xsl:text>"},&#xa;</xsl:text>
    <xsl:text>"nbformat": 3, "nbformat_minor": 0,&#xa;</xsl:text>
    <!-- Only one worksheet supported as of 2013/10/12     -->
    <xsl:text>"worksheets": [{"cells": [&#xa;</xsl:text>
    <xsl:text>{"cell_type": "heading", "level": 1, "metadata": {}, "source": ["</xsl:text>
        <xsl:apply-templates select="title/node()" />
    <xsl:text>"]}</xsl:text>
    <!-- no trailing comma, each new cell adds it in front -->
    <!-- Sage library, preparser import -->
    <xsl:text>,&#xa;{"cell_type": "code", "collapsed": false, "input": ["%load_ext sage"], </xsl:text>
    <xsl:text>"language": "python", "metadata": {}, "outputs": [], "prompt_number": 0}</xsl:text>
    <!-- Credits -->
    <xsl:text>,&#xa;{"cell_type": "markdown", "metadata": {}, "source": [&#xa;</xsl:text>
    <xsl:text>"</xsl:text>
<!--        <xsl:text>###</xsl:text>-->
        <xsl:apply-templates select="../docinfo/author/personname" />
    <xsl:text>"</xsl:text>
    <!--      -->
    <xsl:text>,&#xa;"</xsl:text>
    <xsl:apply-templates select="../docinfo/event" />
    <xsl:text>\n"</xsl:text>
    <!--      -->
    <xsl:text>,&#xa;"</xsl:text>
    <xsl:apply-templates select="../docinfo/date" />
    <xsl:text>"</xsl:text>
    <!--      -->
    <xsl:text>&#xa;]}</xsl:text>
    <!-- End Credits -->
    <!-- all structural templates should produce more cells -->
    <xsl:apply-templates />
    <!-- End cell list, worksheet list, JSON object     -->
    <xsl:text>],&#xa;</xsl:text>
    <xsl:text>"metadata": {}&#xa;</xsl:text>
    <xsl:text>}]}&#xa;</xsl:text>
</xsl:template>

<!-- Sections become just cells with font changes -->
<!-- Copied from stock HTML, but with apply-templates outside wrap-html -->
<xsl:template match="section">
    <xsl:text>,&#xa;{"cell_type": "heading", "level": 2, "metadata": {}, "source": ["</xsl:text>
        <xsl:apply-templates select="title/node()" />
    <xsl:text>"]}</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="p">
    <xsl:text>,&#xa;{"cell_type": "markdown", "metadata": {}, "source": [&#xa;</xsl:text>
    <xsl:text>"</xsl:text>
        <xsl:apply-templates />
    <xsl:text>"&#xa;</xsl:text>
    <xsl:text>]}</xsl:text>
</xsl:template>

<!-- $ for MathJax            -->
<!-- Sanitize TeX backslashes -->
<xsl:template match="m">
    <xsl:text>$</xsl:text>
    <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text" select="." />
        <xsl:with-param name="replace" select="string('\')" />
        <xsl:with-param name="by" select="string('\\')" />
    </xsl:call-template>
    <xsl:text>$</xsl:text>
</xsl:template>

<!-- $$ for MathJax           -->
<!-- Sanitize TeX backslashes -->
<xsl:template match="me">
    <xsl:text>\\begin{equation}</xsl:text>
    <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text" select="." />
        <xsl:with-param name="replace" select="string('\')" />
        <xsl:with-param name="by" select="string('\\')" />
    </xsl:call-template>
    <xsl:text>\\end{equation}</xsl:text>
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



<xsl:template match="sage">
    <xsl:text>,&#xa;{"cell_type": "code", "collapsed": false, "input": ["</xsl:text>
    <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text">
            <xsl:call-template name="sanitize-sage">
                <xsl:with-param name="raw-sage-code" select="input" />
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="replace" select="string('&#xa;')" />
        <xsl:with-param name="by" select="string('\n')" />
    </xsl:call-template>
    <xsl:text>"],&#xa;"language": "python", "metadata": {}, "outputs": [], "prompt_number": </xsl:text>
    <xsl:number from="chapter" level="single" count="sage" />
    <xsl:text>}</xsl:text>
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
        <xsl:with-param name="text"
        select="substring-after($text,$replace)" />
        <xsl:with-param name="replace" select="$replace" />
        <xsl:with-param name="by" select="$by" />
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>