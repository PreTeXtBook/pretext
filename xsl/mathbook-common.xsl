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
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="date"
>


<!-- MathBook XML common templates                        -->
<!-- Text creation/manipulation common to HTML, TeX, Sage -->

<!-- So outpt methods here are just text -->
<xsl:output method="text" />

<!-- Mathematics (LaTeX/MathJax)                                                 -->
<!-- Multi-line displayed equations container, globally unnumbered or numbered   -->
<!-- mrow logic controls numbering, based on variant here, and per-row overrides -->
<!-- align if there are ampersands, gather otherwise                             -->
<!-- Output follows source line breaks                                           -->
<!-- Individual mrows are handled differently for HTML versus MathJax            -->
<xsl:template match="md|mdn">
    <xsl:choose>
        <xsl:when test="contains(., '&amp;')">
            <xsl:text>\begin{align}</xsl:text>
            <xsl:apply-templates select="mrow" />
            <xsl:text>\end{align}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\begin{gather}</xsl:text>
            <xsl:apply-templates select="mrow" />
            <xsl:text>\end{gather}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Sanitize Sage code                 -->
<!-- No leading whitespace, no trailing -->
<!-- http://stackoverflow.com/questions/1134318/xslt-xslstrip-space-does-not-work -->
<xsl:variable name="whitespace"><xsl:text>&#x20;&#x9;&#xD;&#xA;</xsl:text></xsl:variable>

<!-- Trim all whitespace at end of code hunk -->
<!-- Append carriage return to mark last line, remove later -->
<xsl:template name="trim-end">
   <xsl:param name="text"/>
   <xsl:variable name="last-char" select="substring($text, string-length($text), 1)" />
   <xsl:choose>
        <xsl:when test="$last-char=''">
            <xsl:text>&#xA;</xsl:text>
        </xsl:when>
        <xsl:when test="contains($whitespace, $last-char)">
            <xsl:call-template name="trim-end">
                <xsl:with-param name="text" select="substring($text, 1, string-length($text) - 1)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$text" />
            <xsl:text>&#xA;</xsl:text>
        </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<!-- Trim all totally whitespace lines from beginning of code hunk -->
<xsl:template name="trim-start-lines">
   <xsl:param name="text"/>
   <xsl:param name="pad" default="''"/>
   <xsl:variable name="first-char" select="substring($text, 1, 1)" />
   <xsl:choose>
        <xsl:when test="$first-char='&#xA;'">
            <xsl:call-template name="trim-start-lines">
                <xsl:with-param name="text" select="substring($text, 2)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:when test="contains($whitespace, $first-char)">
            <xsl:call-template name="trim-start-lines">
                <xsl:with-param name="text" select="substring($text, 2)" />
                <xsl:with-param name="pad"  select="concat($pad, $first-char)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="concat($pad, $text)" />
        </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<!-- Compute length of indentation of first line                   -->
<!-- Assumes no leading blank lines                                -->
<!-- Assumes each line, including last, ends in a carriage return  -->
<xsl:template name="count-pad-length">
   <xsl:param name="text"/>
   <xsl:param name="pad" default=''/>
   <xsl:variable name="first-char" select="substring($text, 1, 1)" />
   <xsl:choose>
        <xsl:when test="$first-char='&#xA;'">
            <xsl:value-of select="string-length($pad)" />
        </xsl:when>
        <xsl:when test="contains($whitespace, $first-char)">
            <xsl:call-template name="count-pad-length">
                <xsl:with-param name="text" select="substring($text, 2)" />
                <xsl:with-param name="pad"  select="concat($pad, $first-char)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="string-length($pad)" />
        </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<!-- An "out-dented" line is assumed to be intermediate blank line     -->
<!-- indent parameter is a number giving number of characters to strip -->
<xsl:template name="strip-indentation">
    <xsl:param name="text" />
    <xsl:param name="indent" />
    <xsl:if test="$text != ''">
        <xsl:variable name="first-line" select="substring-before($text, '&#xA;')" />
        <xsl:if test="string-length($first-line) > $indent" >
            <xsl:value-of select="substring($first-line, $indent + 1)" />
        </xsl:if>
        <xsl:text>&#xA;</xsl:text>
        <xsl:call-template name="strip-indentation">
            <xsl:with-param name="text" select="substring-after($text, '&#xA;')" />
            <xsl:with-param name="indent" select="$indent" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Add a common string in front of every line of a block -->
<!-- Typically spaces to format output block for doctest   -->
<!-- indent parameter is a string                          -->
<!-- Assumes last character is xA                          -->
<!-- Result has trailing xA                                -->
<xsl:template name="add-indentation">
    <xsl:param name="text" />
    <xsl:param name="indent" />
    <xsl:if test="$text != ''">
        <xsl:value-of select="concat($indent,substring-before($text, '&#xA;'))" />
        <xsl:text>&#xA;</xsl:text>
        <xsl:call-template name="add-indentation">
            <xsl:with-param name="text" select="substring-after($text, '&#xA;')" />
            <xsl:with-param name="indent" select="$indent" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!--
1) Trim all trailing whitespace, add carriage return marker to last line
2) Strip all totally blank leading lines
3) Determine indentation of first line
4) Strip indentation from all lines
5) Allow intermediate blank lines
-->
<xsl:template name="sanitize-sage">
    <xsl:param name="raw-sage-code" />
    <xsl:variable name="trimmed-sage-code">
        <xsl:call-template name="trim-start-lines">
            <xsl:with-param name="text">
                <xsl:call-template name="trim-end">
                    <xsl:with-param name="text" select="$raw-sage-code" />
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="pad-length">
        <xsl:call-template name="count-pad-length">
            <xsl:with-param name="text" select="$trimmed-sage-code" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="strip-indentation" >
        <xsl:with-param name="text" select="$trimmed-sage-code" />
        <xsl:with-param name="indent" select="$pad-length" />
    </xsl:call-template>
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

<!-- Identifiers                          -->
<!-- A unique identifier for any element  -->
<!-- Useful for internal cross-references -->
<!-- in HTML or latex cross-references    -->
<xsl:template match="*" mode="unique-id">
    <xsl:value-of select="local-name(.)" />
    <xsl:text>-</xsl:text>
    <xsl:number level="any" />
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

<xsl:template match="subsubsection" mode="short-name">
    <xsl:text>subsubsec-</xsl:text>
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<xsl:template match="paragraph" mode="short-name">
    <xsl:text>para-</xsl:text>
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<xsl:template match="*" mode="long-name">
    <xsl:message terminate="no">Warning: node with no long-name (likely sectioning)</xsl:message>
</xsl:template>

<xsl:template match="preface" mode="long-name">
    <xsl:text>Preface: </xsl:text>
    <xsl:apply-templates select="title/node()"/>
</xsl:template>

<xsl:template match="chapter" mode="long-name">
    <xsl:text>Chapter </xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="title/node()"/>
</xsl:template>

<xsl:template match="appendix" mode="long-name">
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

<xsl:template match="subsubsection" mode="long-name">
    <xsl:text>Subsubsection </xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="title/node()"/>
</xsl:template>

<xsl:template match="paragraph" mode="long-name">
    <xsl:text>Paragraph </xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="title/node()"/>
</xsl:template>

<!-- Numbering  -->
<!-- Nodes "know" how to number themselves, -->
<!-- which is helful in a variety of places -->
<!-- Default is LaTeX's numbering scheme -->

<!-- Chapters: x -->
<xsl:template match="chapter" mode="number">
    <xsl:number level="single" count="chapter" />
</xsl:template>

<!-- Appendices: A -->
<xsl:template match="appendix" mode="number">
    <xsl:number level="single" count="appendix" format="A"/>
</xsl:template>

<!-- Sections: chapter.x -->
<xsl:template match="section" mode="number">
    <xsl:number level="multiple" count="chapter|section" />
</xsl:template>

<!-- Subsections: chapter.section.x -->
<xsl:template match="subsection" mode="number">
    <xsl:number level="multiple" count="chapter|section|subsection" />
</xsl:template>

<!-- Subsubsections: chapter.section.subsection.x -->
<xsl:template match="subsubsection" mode="number">
    <xsl:number level="multiple" count="chapter|section|subsection|subsubsection" />
</xsl:template>

<!-- Paragraphs: chapter.section.subsection.subsubsection.x -->
<xsl:template match="paragraph" mode="number">
    <xsl:number level="multiple" count="chapter|section|subsection|subsubsection|paragraph" />
</xsl:template>

<!-- Figures:  chapter.x -->
<xsl:template match="caption" mode="number">
    <xsl:number level="multiple" count="chapter|figure" />
</xsl:template>

<!-- Theorems:  x -->
<xsl:template match="theorem" mode="number">
    <xsl:number level="any" count="theorem" />
</xsl:template>

<!-- Lemmas:  x -->
<xsl:template match="lemma" mode="number">
    <xsl:number level="any" count="lemma" />
</xsl:template>

<!-- Corollaries:  x -->
<xsl:template match="corollary" mode="number">
    <xsl:number level="any" count="corollary" />
</xsl:template>

<!-- Definitions:  x -->
<xsl:template match="definition" mode="number">
    <xsl:number level="any" count="definition" />
</xsl:template>

<!-- Examples:  x -->
<xsl:template match="example" mode="number">
    <xsl:number level="any" count="example" />
</xsl:template>

<!-- Exercises  x -->
<xsl:template match="exercise" mode="number">
    <xsl:number level="any" count="exercise" />
</xsl:template>

<!-- Footnotes  x -->
<xsl:template match="fn" mode="number">
    <xsl:number level="any" count="fn" />
</xsl:template>

<!-- Equations:           -->
<!--   chapter.x in books -->
<!--   x in articles      -->
<xsl:template match="mrow|men" mode="number">
    <xsl:if test="ancestor::chapter">
        <xsl:apply-templates select="ancestor::chapter" mode="number" />
        <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:number from="chapter" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]" />
</xsl:template>

<!-- Bibliography items: x -->
<xsl:template match="bibliography//article|bibliography//book" mode="number">
    <xsl:number from="bibliography" level="single" count="article|book" />
</xsl:template>

</xsl:stylesheet>