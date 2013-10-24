<?xml version='1.0'?> <!-- As XML file -->
<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<xsl:import href="./mathbook-common.xsl" />

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="text" />

<!-- Whitespace control in text output mode-->
<!-- Forcing newlines with &#xa; : http://stackoverflow.com/questions/723226/producing-a-new-line-in-xslt -->
<!-- Avoiding extra whitespace: http://stackoverflow.com/questions/1468984/xslt-remove-whitespace-from-template -->

<xsl:template match="/" >
    <xsl:text>r"""&#xa;</xsl:text>
    <xsl:apply-templates select="article|worksheet|book" />
    <xsl:text>"""&#xa;</xsl:text>
</xsl:template>

<xsl:template match="article|worksheet" >
    <xsl:apply-templates select="section" />
</xsl:template>

<xsl:template match="book" >
    <xsl:apply-templates select="chapter|sage" />
</xsl:template>

<xsl:template match="chapter" >
    <xsl:text># Begin Chapter: </xsl:text><xsl:value-of select="title" /><xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="section|sage" />
    <xsl:text># End Chapter: </xsl:text><xsl:value-of select="title" /><xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="section" >
    <xsl:text># Begin Section: </xsl:text><xsl:value-of select="title" /><xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="subsection|sage" />
    <xsl:text># End Section: </xsl:text><xsl:value-of select="title" /><xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="subsection" >
    <xsl:text># Begin Subsection: </xsl:text><xsl:value-of select="title" /><xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="subsubsection|sage" />
    <xsl:text># End Subsection: </xsl:text><xsl:value-of select="title" /><xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- TODO: will subsubsections have titles? -->
<xsl:template match="subsubsection" >
    <xsl:text># Begin Subsubsection: </xsl:text><xsl:value-of select="title" /><xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="sage" />
    <xsl:text># End Subsubsection: </xsl:text><xsl:value-of select="title" /><xsl:text>&#xa;</xsl:text>
</xsl:template>


<xsl:template match="sage">
<xsl:text>~~~~~~~~~~~~~~~~~~~~~~ ::&#xA;&#xA;</xsl:text>
<xsl:apply-templates select="input" />
<xsl:apply-templates select="output" />
<xsl:text>&#xA;</xsl:text>
</xsl:template>

<xsl:template match="input">
    <xsl:call-template name="prependPrompt">
        <xsl:with-param name="pText">
            <xsl:call-template name="trim-sage" >
                <xsl:with-param name="sagecode" select="." />
            </xsl:call-template>
            <xsl:text>&#xA;</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="output">
    <xsl:call-template name="prependTab" />
</xsl:template>

<xsl:template name="prependPrompt">
    <xsl:param name="pText" select="."/>
    <!-- Bail if the string becomes empty -->
    <xsl:if test="string-length($pText)">
        <xsl:choose>
            <!-- prepend if first char is blank or not, indentation is continuation -->
            <xsl:when test="substring($pText,1,1)=' '">
                <xsl:text>    ...   </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>    sage: </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <!-- output up to carriage return, and dup the return -->
        <!-- but do not output a blank line                   -->
        <xsl:if test="string-length(substring-before($pText, '&#xA;'))">
            <xsl:value-of select="substring-before($pText, '&#xA;')"/>
            <xsl:text>&#xA;</xsl:text>
        </xsl:if>
        <!-- recursive call on remainder of string -->
        <xsl:call-template name="prependPrompt">
            <xsl:with-param name="pText" select="substring-after($pText, '&#xA;')"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<xsl:template name="prependTab">
  <xsl:param name="pText" select="."/>

  <xsl:if test="string-length($pText)">
   <xsl:text>    </xsl:text>
   <xsl:value-of select="substring-before($pText, '&#xA;')"/>
   <xsl:text>&#xA;</xsl:text>

   <xsl:call-template name="prependTab">
    <xsl:with-param name="pText"
      select="substring-after($pText, '&#xA;')"/>
   </xsl:call-template>
  </xsl:if>
</xsl:template>




</xsl:stylesheet>