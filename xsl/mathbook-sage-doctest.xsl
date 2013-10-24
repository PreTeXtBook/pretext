<?xml version='1.0'?> <!-- As XML file -->
<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<xsl:import href="./mathbook-common.xsl" />

<!-- Intend output for Python docstring -->
<xsl:output method="text" />

<!-- Whitespace control in text output mode-->
<!-- Forcing newlines with &#xa; : http://stackoverflow.com/questions/723226/producing-a-new-line-in-xslt -->
<!-- Avoiding extra whitespace: http://stackoverflow.com/questions/1468984/xslt-remove-whitespace-from-template -->

<!-- Make a single docstring for Sage doctest framework -->
<!-- TODO: Investigate just when random-number seed is reinitialized, -->
<!-- per docstring or per verbatim marker -->
<xsl:template match="/mathbook" >
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
<!-- TODO: planning one level deeper as "paragraph", but perhaps at any level -->
<xsl:template match="subsubsection" >
    <xsl:text># Begin Subsubsection: </xsl:text><xsl:value-of select="title" /><xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="sage" />
    <xsl:text># End Subsubsection: </xsl:text><xsl:value-of select="title" /><xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Form doctring/ReST verbatim block -->
<!-- for one input/output pair         -->
<xsl:template match="sage">
<xsl:text>~~~~~~~~~~~~~~~~~~~~~~ ::&#xA;&#xA;</xsl:text>
<xsl:apply-templates select="input" />
<xsl:apply-templates select="output" />
<xsl:text>&#xA;</xsl:text>
</xsl:template>

<!-- Sanitize intput block      -->
<!-- Add in 4-space indentation -->
<!-- and Sage prompts           -->
<xsl:template match="input">
    <xsl:call-template name="prepend-prompt">
        <xsl:with-param name="text">
            <xsl:call-template name="sanitize-sage" >
                <xsl:with-param name="raw-sage-code" select="." />
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Sanitize output block      -->
<!-- Add in 4-space indentation -->
<xsl:template match="output">
    <xsl:call-template name="add-indentation">
        <xsl:with-param name="text">
            <xsl:call-template name="sanitize-sage" >
                <xsl:with-param name="raw-sage-code" select="." />
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="indent" select="'    '" />
    </xsl:call-template>
</xsl:template>

<!-- Doctest specific template, others are in common XSL file -->

<xsl:template name="prepend-prompt">
    <xsl:param name="text" />
    <!-- Just quit when string becomes empty -->
    <xsl:if test="string-length($text)">
        <xsl:variable name="first-line" select="substring-before($text, '&#xA;')" />
        <xsl:choose>
            <!-- blank lines are treated as continuation -->
            <!-- could be important content of triply-quoted strings? -->
            <!-- no harm if really just spacing at totally out-dented level? -->
            <xsl:when test="not(string-length($first-line))">
                <xsl:text>    ...   </xsl:text>
            </xsl:when>
            <!-- leading blank indicates continuation -->
            <xsl:when test="substring($first-line,1,1)=' '">
                <xsl:text>    ...   </xsl:text>
            </xsl:when>
            <!-- otherwise, totally outdented, needs sage prompt -->
            <xsl:otherwise>
                <xsl:text>    sage: </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="$first-line"/>
        <xsl:text>&#xA;</xsl:text>
        <!-- recursive call on remainder of string -->
        <xsl:call-template name="prepend-prompt">
            <xsl:with-param name="text" select="substring-after($text, '&#xA;')"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>


</xsl:stylesheet>