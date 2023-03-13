<?xml version='1.0'?>

<!--********************************************************************
Copyright 2018 Robert A. Beezer

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
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="pi exsl date str"
>

<!-- Standard conversion groundwork -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>

<xsl:output method="xml" indent="yes" encoding="UTF-8"/>

<xsl:variable name="exercise-style" select="'static'"/>

<!-- Necessary to get pre-constructed Nemeth braille for math elements. -->
<!-- This file of math representations will come from another process   -->
<!-- that involves mathJax and Speech Rule Engine (SRE).                -->
<!-- Note: this is a manual step during development.                    -->
<xsl:param name="mathfile" select="''"/>
<xsl:variable name="math-repr"  select="document($mathfile)/pi:math-representations"/>

<!-- Not so much "include" as "manipulate"            -->
<!-- Switch to "all" when display math is accomodated -->
<xsl:param name="math.punctuation.include" select="'inline'"/>

<!-- xsltproc -o sa.xml -stringparam publisher ~/mathbook/mathbook/examples/sample-article/publication.xml ~/mathbook/mathbook/xsl/pretext-braille-preprint.xsl ~/mathbook/mathbook/examples/sample-article/sample-article.xml -->

<!-- xsltproc -xinclude  -o sa.xml -stringparam publisher ~/books/aata/aata/publisher/public.xml  ~/mathbook/mathbook/xsl/pretext-braille-preprint.xsl ~/books/aata/aata/src/aata.xml 2> missing.txt -->

<xsl:template match="/">
    <xsl:apply-templates select="$root"/>
</xsl:template>

<!-- with /, so a plain generator can match others -->
<xsl:template match="/pretext">
    <!-- Need an overall container   -->
    <!-- Maybe copy a language code? -->
    <brf>
        <segment>Temporary Transcriber Notes: </segment>
        <!-- See "c" template for explanation -->
        <segment>1. Literal, or verbatim, computer code used in sentences is indicated by a set of transcriber-defined emphasis given by the following indicators, which all begin with the two cells dot-4 and dot-3456.  Single letter: 4-3456-23.  Begin, end word: 4-3456-2, 4-3456-3.  Begin, end phrase: 4-3456-2356, 4-3456-3.</segment>
        <xsl:apply-templates select="*"/>
    </brf>
</xsl:template>


<!-- Generators -->

<xsl:template match="pretext">
    <xsl:text>PreTeXt</xsl:text>
</xsl:template>

<xsl:template match="tex">
    <xsl:text>TeX</xsl:text>
</xsl:template>

<xsl:template match="latex">
    <xsl:text>LaTeX</xsl:text>
</xsl:template>

<!-- static, all "webwork" as problems are gone -->
<xsl:template match="webwork">
    <xsl:text>WeBWorK</xsl:text>
</xsl:template>

<xsl:template match="ie">
    <xsl:text>i.e.</xsl:text>
</xsl:template>

<xsl:template match="etc">
    <xsl:text>etc.</xsl:text>
</xsl:template>

<xsl:template match="copyright">
    <xsl:text>(c)</xsl:text>
</xsl:template>

<!-- [BANA-2016] Appendix G                 -->
<!-- Says UEB uses three periods (dots-256) -->
<!-- liblouis seems to translate as such    -->
<xsl:template match="ellipsis">
    <xsl:text>...</xsl:text>
</xsl:template>


<!-- Empty Elements, Characters -->

<!-- Unicode Character 'NO-BREAK SPACE' (U+00A0)     -->
<!-- yields a template for "nbsp" in -common         -->
<!-- liblouis seems to pass this through in-kind     -->
<!-- Used in teh manufacture of a cross-reference,   -->
<!--we'll want to strip just before it eds up in BRF -->
<xsl:template name="nbsp-character">
    <xsl:text>&#x00A0;</xsl:text>
</xsl:template>

<!-- Unicode Character 'EN DASH' (U+2013) -->
<!-- Seems to become ",-"                 -->
<xsl:template name="ndash-character">
    <xsl:text>&#x2013;</xsl:text>
</xsl:template>

<!-- Unicode Character 'EM DASH' (U+2014) -->
<!-- Seems to also become ",-"            -->
<xsl:template name="mdash-character">
    <xsl:text>&#x2014;</xsl:text>
</xsl:template>

<!-- Italics -->
<xsl:template match="em|foreign|articletitle|pubtitle">
    <!-- Python will assume "italic" as element name -->
    <italic>
        <xsl:apply-templates select="node()"/>
    </italic>
</xsl:template>

<!-- Bold -->
<xsl:template match="term|alert">
    <!-- Python will assume "bold" as element name -->
    <bold>
        <xsl:apply-templates select="node()"/>
    </bold>
</xsl:template>

<!-- Code -->
<!-- Accomplished in UEB Grade 2, but with transcriber emphasis scheme 1 -->
<!-- from liblouis (where is this defined?).  See liblouis table         -->
<!-- "en-ueb-g1.ctb" for exact definition of emphasis code "trans1".     -->
<!--                                                                     -->
<!--     emphletter trans1 4-3456-23                                     -->
<!--     begemphword trans1 4-3456-2                                     -->
<!--     endemphword trans1 4-3456-3                                     -->
<!--     lenemphphrase trans1 3                                          -->
<!--     begemphphrase trans1 4-3456-2356                                -->
<!--     endemphphrase trans1 after 4-3456-3                             -->
<xsl:template match="c">
    <code>
        <xsl:apply-templates select="node()"/>
    </code>
</xsl:template>

<!-- Pass-through/Dropped -->
<xsl:template match="abbr|acro|init">
    <xsl:apply-templates select="node()"/>
</xsl:template>

<!-- "idx" must be dealt with from source otherwise during    -->
<!-- index construction, but when encountered in a paragraph  -->
<!-- or a block they should just be killed.  Should never     -->
<!-- reach an interior "h".  Entirely similar for "notation"  -->
<!-- and an interior "usage", and "description".              -->

<xsl:template match="idx|notation"/>

<!-- non-breaking space -->
<!-- will liblouis preserve? -->
<!-- or do we need markup for page-formatting? -->

<!-- Groupings -->

<xsl:template match="q">
    <xsl:text>"</xsl:text>
    <xsl:apply-templates select="node()"/>
    <xsl:text>"</xsl:text>
</xsl:template>

<xsl:template match="sq">
    <xsl:text>'</xsl:text>
    <xsl:apply-templates select="node()"/>
    <xsl:text>'</xsl:text>
</xsl:template>



<xsl:template match="tag">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>&gt;</xsl:text>
</xsl:template>

<xsl:template match="tage">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>/&gt;</xsl:text>
</xsl:template>

<xsl:template match="attr">
    <xsl:text>@</xsl:text>
    <xsl:value-of select="."/>
</xsl:template>

<!-- #### -->
<!-- Math -->
<!-- #### -->

<!-- $math-rep is a "global" variable with "pi:math" elements -->
<xsl:key name="math-elts" match="pi:math" use="@id"/>

<xsl:template match="m">
    <!-- We connect source location with representations via id -->
    <!-- NB: math-representation file writes with "visible-id"  -->
    <xsl:variable name="id">
        <xsl:apply-templates select="." mode="visible-id"/>
    </xsl:variable>
    <!-- Unicode braille cells from Speech Rule Engine (SRE) -->
    <xsl:variable name="raw-braille">
        <!-- sets the context for the key -->
        <xsl:for-each select="$math-repr">
            <xsl:value-of select="key('math-elts', $id)/div[@class = 'braille']"/>
        </xsl:for-each>
    </xsl:variable>
    <!-- inline vs. spatial makes a difference -->
    <xsl:variable name="b-multiline" select="contains($raw-braille, '&#xa;')"/>
    <!-- We investigate actual source for very simple math   -->
    <!-- such as one-letter variable names as Latin letters  -->
    <!-- or positive integers, so we process the orginal     -->
    <!-- content outside of a MathJax/SRE translation (which -->
    <!-- could have "xref", etc)                             -->
    <xsl:variable name="content">
        <xsl:apply-templates select="node()"/>
    </xsl:variable>
    <xsl:variable name="original-content" select="normalize-space($content)"/>
    <!-- Note: this mark is *always* removed from the trailing text node,    -->
    <!-- so we need to *always* restore it.  In other wordds, we usually     -->
    <!-- put it into an attribute to get picked up by  lxml  in the Python.  -->
    <!-- But if we short-circuit that process here by turning integers into  -->
    <!-- digits or making single-letter variables unadorned, then we need to -->
    <!-- restore the mark in this template.                                  -->
    <xsl:variable name="clause-ending-mark">
        <xsl:apply-templates select="." mode="get-clause-punctuation-mark"/>
    </xsl:variable>
    <!-- Various cases, more specific first -->
    <xsl:choose>
        <!-- Inline math with just one Latin letter. No formatting,  -->
        <!-- no italics, according to BANA rules via Michael Cantino -->
        <!-- (2023-01-26) so drop-in $original.  C'est la vie.       -->
        <xsl:when test="(string-length($original-content) = 1) and contains(&ALPHABET;, $original-content)">
            <xsl:value-of select="$original-content"/>
            <!-- restore clause-ending punctuation -->
            <xsl:value-of select="$clause-ending-mark"/>
        </xsl:when>
        <!-- Test is true for non-negative integers, which we drop into -->
        <!-- the stream as if they were never authored as math anyway   -->
        <xsl:when test="translate($original-content, &DIGIT; ,'') = ''">
            <xsl:value-of select="$original-content"/>
            <!-- restore clause-ending punctuation -->
            <xsl:value-of select="$clause-ending-mark"/>
        </xsl:when>
        <!-- We construct a fragment for teh Python formatter.   -->
        <!-- SRE may convert inline "m" into a spatial layout,   -->
        <!-- such as a fraction or column vector authored inline -->
        <!-- We ignore this situation for now                    -->
        <xsl:when test="not($b-multiline)">
            <math>
                <!-- Add punctuation as an attribute conditionally. -->
                <!-- We could probably just add an empty string     -->
                <!-- routinely and push that through to the closing -->
                <!-- Nemeth indicator, but we take a bit more care. -->
                <xsl:if test="not($clause-ending-mark = '')">
                    <xsl:attribute name="punctuation">
                        <xsl:value-of select="$clause-ending-mark"/>
                    </xsl:attribute>
                </xsl:if>
                <xsl:value-of select="$raw-braille"/>
            </math>
        </xsl:when>
        <xsl:otherwise>
            <!-- TEMPORARY: Multi-line case -->
            <xsl:text>MATH</xsl:text>
            <!-- restore clause-ending punctuation -->
            <xsl:value-of select="$clause-ending-mark"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- Simple implementations of the basic -->
<!-- components of a cross-reference     -->

<!-- This device is just for the LaTeX conversion -->
<xsl:template match="*" mode="xref-number">
    <xsl:apply-templates select="." mode="number"/>
</xsl:template>

<!-- Nothing much to be done, we just -->
<!-- xerox the text representation    -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="target" />
    <xsl:param name="content" />

    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- #### -->
<!-- URLs -->
<!-- #### -->

<!-- Some technical debt: these to variables (or at least one) should -->
<!-- perhaps be placed in -common rather than duplicating them.       -->

<!-- 2023-03-06: these two vraiables have been copied verbatim from the HTML conversion -->

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
                <xsl:apply-templates />
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

    <xsl:value-of select="$visible-text"/>
</xsl:template>


<!-- ######### -->
<!-- Footnotes -->
<!-- ######### -->

<!-- Drop a mark at sight, Need to devise an        -->
<!-- add-on to division-processing to make endnotes -->
<!-- [BANA-2016] 16.1.4(g): (print observations)  -->
<!-- In a note section, either at the end of each -->
<!-- chapter or at the back of the book.          -->
<!-- [BANA-2016] 16.1.5(c): (braille placement)   -->
<!-- At the end of the chapter or volume.         -->

<!-- See BANA 16.2.2 for superscripted number (two-cell indicator, number sign, number). -->
<xsl:template match="fn">
    <xsl:text> [</xsl:text>
    <xsl:apply-templates select="." mode="number"/>
    <xsl:text>]</xsl:text>
</xsl:template>


<!-- ############ -->
<!-- EXPERIMENTAL -->
<!-- ############ -->

<xsl:template match="p">
    <segment newpage="no" indent="2">
        <xsl:apply-templates select="node()"/>
    </segment>
</xsl:template>

<!-- inline at this stage -->
<xsl:template match="me|men|md|mdn">
    <xsl:text> DISPLAY MATH</xsl:text>
</xsl:template>

<!-- inline at this stage -->
<xsl:template match="ol|ul|dl">
    <xsl:text> LIST</xsl:text>
</xsl:template>

<!-- inline at this stage -->
<xsl:template match="cd">
    <xsl:text> CODE DISPLAY</xsl:text>
</xsl:template>

<!-- ############ -->
<!-- EXPERIMENTAL -->
<!-- ############ -->

<!-- Uncaught elements for debugging reporting                     -->
<!-- These elements have full implementations in -common, or       -->
<!-- partial/abstract implementations which we extend hee.         -->
<!-- So we just hit them with "apply-imports" so they do not       -->
<!-- all into the (temporary, development) template below          -->
<!-- reporting missed elements.   "Commenting out this template    -->
<!-- should have zero effect, except to generate more debugging    -->
<!-- messages, since this reporting template will take precedence. -->

<xsl:template match="nbsp|ndash|mdash|xref">
    <xsl:apply-imports/>
</xsl:template>

<xsl:template match="*">
    <!-- target informative messages to "blocks" being considered -->
    <xsl:if test="ancestor::p">
        <xsl:message>Pass: <xsl:value-of select="local-name()"/></xsl:message>
    </xsl:if>
    <!-- recurse into child elements to find more "missing" elements -->
    <xsl:apply-templates select="*"/>
</xsl:template>

</xsl:stylesheet>
