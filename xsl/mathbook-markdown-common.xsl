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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>


<!-- MathBook XML common templates  -->
<!-- For any conversion to Markdown -->

<!-- So output methods here are just text -->
<xsl:output method="text" />

<!-- backticks for monospace font          -->
<!-- 4 backticks allows up to three inside -->
<!-- http://meta.stackexchange.com/questions/82718/how-do-i-escape-a-backtick-in-markdown -->
<xsl:template match="c">
    <xsl:variable name="content">
        <xsl:apply-templates />
    </xsl:variable>
    <xsl:if test="contains($content, '````')">
        <xsl:message>MBX:WARNING: 4 consecutive backticks in a "c" element will have unpredictable results</xsl:message>
    </xsl:if>
    <xsl:text>````</xsl:text>
    <xsl:value-of select="$content" />
    <xsl:text>````</xsl:text>
</xsl:template>

<!-- italics for emphasis, matches default LaTeX -->
<xsl:template match="em">
    <xsl:text>*</xsl:text>
    <xsl:apply-templates />
    <xsl:text>*</xsl:text>
</xsl:template>

<!-- Defined terms (bold) -->
<xsl:template match="term">
    <xsl:text>**</xsl:text>
    <xsl:apply-templates />
    <xsl:text>**</xsl:text>
</xsl:template>

<!-- two spaces, hard return -->
<xsl:template match="br">
    <xsl:text>  #xa;</xsl:text>
</xsl:template>

<!-- nothing special for quotes -->
<xsl:template match="q">
    <xsl:text>"</xsl:text>
    <xsl:apply-templates />
    <xsl:text>"</xsl:text>
</xsl:template>

<!-- External URL's -->
<!-- URL in href is mandatory,                 -->
<!-- link text is optional, defaults to href   -->
<xsl:template match="url">
    <xsl:text>[</xsl:text>
    <xsl:choose>
        <xsl:when test="not(*) and not(normalize-space())">
            <xsl:value-of select="@href" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>](</xsl:text>
    <xsl:value-of select="@href" />
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- email to a mailto: URL -->
<xsl:template match="email">
    <xsl:text>[</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>](mailto:</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- Section Headings -->
<!-- A specified number of octothorpes          -->
<!-- Followed by necessary space (not hash tag) -->
<xsl:template name="heading-format">
    <xsl:param name="count"/>
    <xsl:choose>
        <xsl:when test="$count = 1">
            <xsl:text># </xsl:text>
        </xsl:when>
        <xsl:when test="$count > 1">
            <xsl:text>#</xsl:text>
            <xsl:call-template name="heading-format">
                <xsl:with-param name="count" select="$count - 1" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="yes">MBX:BUG  Markdown heading-format template needs positive count</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Images -->

<!-- Markdown syntax for an image -->
<!-- Not much control             -->
<xsl:template name="image-wrap">
    <xsl:param name="filename" />
    <xsl:param name="alt-description" select="''" />
    <xsl:param name="tooltip-title" select="''" />
    <!-- exclamation mark mandatory -->
    <xsl:text>!</xsl:text>
    <!-- alt text is mandatory, but might be empty -->
    <xsl:text>[</xsl:text>
    <xsl:value-of select="$alt-description" />
    <xsl:text>]</xsl:text>
    <!-- parentheses for the main event -->
    <xsl:text>(</xsl:text>
    <!-- filename always -->
    <xsl:value-of select="$filename" />
    <!-- optional string for title, escape the quotes here -->
    <xsl:if test="not($tooltip-title = '')">
        <xsl:text> \"</xsl:text>
        <xsl:value-of select="$tooltip-title" />
        <xsl:text>\"</xsl:text>
    </xsl:if>
    <xsl:text>)</xsl:text>
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
    <xsl:text>\\#</xsl:text>
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
    <xsl:text>\\</xsl:text>
</xsl:template>

<!-- Asterisk -->
<!-- Centered as a character, not an exponent -->
<xsl:template match="asterisk">
    <xsl:text>\*</xsl:text>
</xsl:template>

<!-- Lists -->
<!--<xsl:template match="ul|ol|dl">
    <xsl:variable name="new-indentation" select="concat($indentation, '    ')" />
    <xsl:variable name="indentation" select="$new-indentation" />


<xsl:template>

<xsl:template name="process-list-contents"-->

</xsl:stylesheet>