<?xml version='1.0'?> <!-- As XML file -->
<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace" 
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="date"
>


<!-- MathBook XML common templates                        -->
<!-- Text creation/manipulation common to HTML, TeX, Sage -->

<!-- So outpt methods here are just text -->
<xsl:output method="text" />


<!-- Sanitize Sage code                 -->
<!-- No leading whitespace, no trailing -->
<!-- http://stackoverflow.com/questions/1134318/xslt-xslstrip-space-does-not-work -->
<xsl:variable name="whitespace"><xsl:text>&#x20;&#x9;&#xD;&#xA;</xsl:text></xsl:variable>

<!-- Trim all whitespace at beginning of string -->
<xsl:template name="trim-start">
   <xsl:param name="text"/>
<!--     <xsl:text>In trim-start</xsl:text> -->
   <xsl:variable name="first-char" select="substring($text, 1, 1)" />
<!--    <xsl:text>fc:</xsl:text><xsl:value-of select="$first-char" /> -->
   <xsl:choose>
        <xsl:when test="$first-char=''">
            <xsl:text></xsl:text>
        </xsl:when>
        <xsl:when test="contains($whitespace, $first-char)">
<!--         <xsl:when test="matches($whitespace, $first-char)"> -->
            <xsl:call-template name="trim-start">
                <xsl:with-param name="text" select="substring($text, 2)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
   </xsl:choose>
<!--     <xsl:text>Out trim-start</xsl:text> -->
</xsl:template>

<!-- Trim all whitespace at end of string -->
<xsl:template name="trim-end">
   <xsl:param name="text"/>
<!--     <xsl:text>In trim-end</xsl:text> -->
   <xsl:variable name="last-char" select="substring($text, string-length($text), 1)" />
<!--    <xsl:text>lc:</xsl:text><xsl:value-of select="$last-char" /> -->
   <xsl:choose>
        <xsl:when test="$last-char=''">
            <xsl:text></xsl:text>
        </xsl:when>
        <xsl:when test="contains($whitespace, $last-char)">
<!--         <xsl:when test="matches($last-char, '\s')"> -->
<!--             <xsl:text>White</xsl:text> -->
            <xsl:call-template name="trim-end">
                <xsl:with-param name="text" select="substring($text, 1, string-length($text) - 1)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
<!--             <xsl:text>Otherwise</xsl:text> -->
            <xsl:value-of select="$text" />
        </xsl:otherwise>
   </xsl:choose>
<!--     <xsl:text>Out trim-end</xsl:text> -->
</xsl:template>

<!-- Put it together, call this on Sage hunks -->
<xsl:template name="trim-sage">
    <xsl:param name="sagecode" />
<!--     <xsl:text>In trim-sage</xsl:text> -->
    <xsl:call-template name="trim-start">
        <xsl:with-param name="text">
            <xsl:call-template name="trim-end">
                <xsl:with-param name="text" select="$sagecode" />
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
<!--     <xsl:text>Out trim-sage</xsl:text> -->
</xsl:template>

<!-- Date and Time Functions -->
<!-- http://stackoverflow.com/questions/1437995/how-to-convert-2009-09-18-to-18th-sept-in-xslt -->
<!-- http://remysharp.com/2008/08/15/how-to-default-a-variable-in-xslt/ -->
<xsl:template match="today">
    <xsl:variable name="format">
        <xsl:choose>
            <xsl:when test="@format"><xsl:value-of select="@format" /></xsl:when>
            <xsl:otherwise>month-day-year</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="datetime" select="substring(date:date-time(),1,10)" />
    <xsl:choose>
        <xsl:when test="$format='month-day-year'">
            <xsl:value-of select="date:month-name($datetime)" />
            <xsl:text> </xsl:text>
            <xsl:value-of select="date:day-in-month($datetime)" />
            <xsl:text>, </xsl:text>
            <xsl:value-of select="date:year($datetime)" />
        </xsl:when>
        <xsl:when test="$format='yyyy/mm/dd'">
            <xsl:value-of select="substring($datetime, 1, 4)" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="substring($datetime, 6, 2)" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="substring($datetime, 9, 2)" />
        </xsl:when>
    </xsl:choose>
</xsl:template>    

<!-- Filenames -->
<!-- Automatically generated basenames for -->
<!-- filenames, when chunking, especially  -->
<xsl:template match="*" mode="basename">
    <xsl:if test="local-name(.) != 'chapter'" >
        <xsl:apply-templates select="parent::*" mode="basename" />
        <xsl:text>-</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="short-name" />
</xsl:template>


<!-- Reporting Templates -->
<!--   conveniences for annotating derivative products,     -->
<!--   such as Sage doc tests, LaTeX source                 -->
<!--   long form for content, short form for filenames, ids -->
<xsl:template match="chapter" mode="short-name">
    <xsl:text>chap-</xsl:text>
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<xsl:template match="section" mode="short-name">
    <xsl:text>sec-</xsl:text>
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<xsl:template match="subsection" mode="short-name">
    <xsl:text>subsec-</xsl:text>
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<xsl:template match="chapter" mode="long-name">
    <xsl:text>Chapter </xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="title/node()"/>
</xsl:template>

<xsl:template match="section" mode="long-name">
    <xsl:text>Section </xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="title/node()"/>
</xsl:template>

<xsl:template match="subsection" mode="long-name">
    <xsl:text>Subsection </xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="title/node()"/>
</xsl:template>

<!-- Numbering  -->
<!-- Nodes "know" how to number themselves, -->
<!-- which is helful in a vaiety of places -->
<!-- Default is LaTeX's numbering scheme -->

<!-- Chapters: x -->
<xsl:template match="chapter" mode="number">
    <xsl:number level="single" count="chapter" />
</xsl:template>

<!-- Sections: chapter.x -->
<xsl:template match="section" mode="number">
    <xsl:number level="multiple" count="chapter|section" />
</xsl:template>

<!-- Subsections: chapter.section.x -->
<xsl:template match="subsection" mode="number">
    <xsl:number level="multiple" count="chapter|section|subsection" />
</xsl:template>





</xsl:stylesheet>