<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2020 Robert A. Beezer

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
<!-- NB: directories affect location -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "../xsl/entities.ent">
    %entities;
]>
<!-- Identify as a stylesheet -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace">

<!-- Report on console, or redirect/option to a file -->
<xsl:output method="text"/>

<!-- Single line output allows for sorting on "fields" with the     -->
<!-- sort utility. So design messages to *lead* with something      -->
<!-- precise and unique that will sort cleanly with other messages. -->
<xsl:param name="single.line.output" select="'no'"/>
<xsl:variable name="b-single-line" select="$single.line.output = 'yes'"/>

<!-- Walk the tree, so messages appear in document order, not topically.  -->
<!-- Be sure to recurse into larger elements after interrupting to        -->
<!-- process certain situations.  This is not necessary for templates     -->
<!-- matching attributes or elements guarnteed to be empty and without    -->
<!-- any attributes, ever.                                                -->
<!--                                                                      -->
<!-- Sections:                                                            -->
<!--   * Deprecations:                                                    -->
<!--       moved here once old, to minimize usual start-up times,         -->
<!--       includes explanations of necessity and alternatives,           -->
<!--   * Real-Time Checks:                                                -->
<!--       items the usual schema checking cannot compute                 -->
<!--   * WeBWorK:                                                         -->
<!--       WW-specific items that the schema suggests are OK, but are not -->

<!-- ############ -->
<!-- Deprecations -->
<!-- ############ -->

<!-- Comments are copied from original warnings in -common templates -->

<!-- 2014-05-04  @filebase has been replaced in function by @xml:id -->
<!-- 2018-07-21  remove all relevant code                           -->
<xsl:template match="@filebase">
    <xsl:apply-templates select="parent::*" mode="messaging">
        <xsl:with-param name="severity" select="'error'"/>
        <xsl:with-param name="message">
            <xsl:text>The @filebase attribute is deprecated (2014-05-04) and no code&#xa;</xsl:text>
            <xsl:text>remains (2018-07-21), convert to using @xml:id for this purpose</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- 2014-06-25  xref once had cite as a variant -->
<!-- 2018-07-21  remove all relevant code        -->
<xsl:template match="cite">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'error'"/>
        <xsl:with-param name="message">
            <xsl:text>The &lt;cite&gt; element is deprecated (2014-06-25) and no&#xa;</xsl:text>
            <xsl:text>code remains (2018-07-21), convert to an &lt;xref&gt;</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<!-- 2015-01-28  once both circum and circumflex existed, circumflex won -->
<!-- 2018-07-21  remove all relevant code                                -->
<xsl:template match="circum">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'error'"/>
        <xsl:with-param name="message">
            <xsl:text>The &lt;circum&gt; element is deprecated (2015-01-28) and no&#xa;</xsl:text>
            <xsl:text>code remains (2018-07-22), convert to a &lt;circumflex&gt;</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- 2017-12-21 remove sage/@copy               -->
<!-- 2021-02-25 remove all code due to id() use -->
<xsl:template match="sage[@copy]">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'error'"/>
        <xsl:with-param name="message">
            <xsl:text>@copy on a &quot;sage&quot; element was deprecated (2017-12-21)</xsl:text>
            <xsl:text>Use the xinclude mechanism with common code in an external file</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- 2017-12-21 remove image/@copy              -->
<!-- 2021-02-25 remove all code due to id() use -->
<xsl:template match="image[@copy]">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'error'"/>
        <xsl:with-param name="message">
            <xsl:text>@copy on an &quot;image&quot; element was deprecated (2017-12-21)</xsl:text>
            <xsl:text>Perhaps use the xinclude mechanism with common code in an external file</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>


<!-- ################ -->
<!-- Real-Time Checks -->
<!-- ################ -->

<!-- Checks that the schema cannot perform since some -->
<!-- sort of look-up or source analysis is necessary  -->

<!-- More information about an "author" is achieved   -->
<!-- with a cross-reference to a "contributor". Only. -->
<xsl:template match="author/xref">
    <xsl:if test="not(id(@ref)/self::contributor)">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>An &lt;xref&gt; within an &lt;author&gt; is meant to point&#xa;</xsl:text>
                <xsl:text>to a &lt;contributor&gt;, not to a &lt;</xsl:text>
                <xsl:value-of select="local-name(id(@ref))"/>
                <xsl:text>&gt;</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<!-- Docinfo should have at most one latex-image-preamble -->
<!-- of each value for @syntax (including no @syntax)     -->
<xsl:template match="latex-image-preamble[not(@syntax)][1]">
    <xsl:if test="count(parent::docinfo/latex-image-preamble[not(@syntax)]) > 1">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>There should be at most one &lt;latex-image-preamble&gt; without a&#xa;</xsl:text>
                <xsl:text>@syntax within the &lt;docinfo&gt; element. There are more than one,&#xa;</xsl:text>
                <xsl:text>and they should be consolidated.</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="latex-image-preamble[@syntax = 'PGtikz'][1]">
    <xsl:if test="count(parent::docinfo/latex-image-preamble[@syntax = 'PGtikz']) > 1">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>There should be at most one &lt;latex-image-preamble&gt; with @syntax&#xa;</xsl:text>
                <xsl:text>having value 'PGtikz' within the &lt;docinfo&gt; element. There are&#xa;</xsl:text>
                <xsl:text>more than one, and they should be consolidated.</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<!-- ########## -->
<!-- Advisories -->
<!-- ########## -->

<xsl:template match="sidebyside[not(parent::interactive)]">
    <xsl:if test="count(*[not(&METADATA-FILTER;)]) = 1">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>A &lt;sidebyside&gt; normally does not have a single panel.&#xa;</xsl:text>
                <xsl:text>If this construct is only for layout control, try moving&#xa;</xsl:text>
                <xsl:text>layout onto the element used as panel ("</xsl:text>
                <xsl:value-of select="local-name(*[not(&METADATA-FILTER;)])"/>
                <xsl:text>") and remove the &lt;sidebyside&gt;&#xa;</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="title[m]">
    <xsl:if test="parent::chapter|appendix|preface|acknowledgement|biography|foreword|dedication|colophon|section|subsection|subsubsection|slide|exercises|worksheet|reading-questions|solutions|references|glossary|backmatter and not(following-sibling::shorttitle)">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>You have a title containing m but no shorttitle.&#xa;</xsl:text>
                <xsl:text>Because this title will be used many places, errors may result.&#xa;</xsl:text>
                <xsl:text>Please add a shorttitle.</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<!-- Image elements should have meaningful descriptions.   -->
<!-- We catch any "image" that does not either declare     -->
<!-- @decorative="yes" or have a non-empty description.    -->
<!-- Warn if there is a description and @decorative="yes". -->
<!-- Warn if a description length is over 125 characters.  -->
<xsl:template match="image">
    <xsl:if test="not(@decorative = 'yes') and description = ''">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>You have an image without a description and do not declare the image to be decorative.&#xa;</xsl:text>
                <xsl:text>Because of this, output may not be accessible.&#xa;</xsl:text>
                <xsl:text>If the image does not add information that is not already present, use @decorative="yes".&#xa;</xsl:text>
                <xsl:text>Otherwise, provide a &lt;description&gt;.</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="@decorative = 'yes' and not(description = '')">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>You have an image with @decorative="yes" that has a nonempty description.&#xa;</xsl:text>
                <xsl:text>The description may not appear in output.&#xa;</xsl:text>
                <xsl:text>Either remove the description, remove @decorative, or change @decorative to "no".</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="string-length(description) > 125">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'advice'"/>
            <xsl:with-param name="message">
                <xsl:text>You have an image description that is more than 125 characters long.&#xa;</xsl:text>
                <xsl:text>Some screen readers will cut off reading alt text after the 125th character.&#xa;</xsl:text>
                <xsl:text>Rewrite the description to be 125 characters or fewer.</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>


<!-- ####### -->
<!-- WeBWorK -->
<!-- ####### -->

<!-- Certain constructions are only meant for use in WW problems, -->
<!-- but we allow them (apparently) everywhere when writing the   -->
<!-- official schema.  We indicate these situations here.         -->

<!-- "var" is specific to WW -->
<xsl:template match="var[not(ancestor::webwork)]">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'error'"/>
        <xsl:with-param name="message">
            <xsl:text>The &lt;var&gt; element is exclusive to a WeBWorK problem,&#xa;</xsl:text>
            <xsl:text>and so must only appear within a &lt;webwork&gt; element,&#xa;</xsl:text>
            <xsl:text>not here.  It will be ignored.</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<!-- WW tables can't express the range of borders/rules that PreTeXt can -->

<xsl:template match="webwork//tabular/col/@top">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'warn'"/>
        <xsl:with-param name="message">
            <xsl:text>Column-specific top border attributes are not implemented for the&#xa;</xsl:text>
            <xsl:text>output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="webwork//tabular/cell/@bottom">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'warn'"/>
        <xsl:with-param name="message">
            <xsl:text>Cell-specific bottom border border attributes are not implemented for the&#xa;</xsl:text>
            <xsl:text>output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="webwork//tabular/*[@top='medium' or @bottom='medium' or @left='medium' or @right='medium' or @top='major' or @bottom='major' or @left='major' or @right='major']">
    <xsl:apply-templates select="." mode="messaging">
        <xsl:with-param name="severity" select="'warn'"/>
        <xsl:with-param name="message">
            <xsl:text>'medium' or 'major' table rule attributes will be handled as 'minor' in the&#xa;</xsl:text>
            <xsl:text>output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- recurse further -->
    <xsl:apply-templates/>
</xsl:template>

<!-- ############################### -->
<!-- Text and Troublesome Characters -->
<!-- ############################### -->

<!-- When converting from other sources (Word, Google Drive, etc.) we -->
<!-- often see smart quotes, fancy apostrophes, em-dashes, etc that   -->
<!-- come through as Unicode characters.  They may not be obvious     -->
<!-- (rendered similarly) or they may even be actual entities         -->
<!-- (&#dddd in decimal or &#xhhhh in hex).                           -->
<!--     ** They are all the smae character to the   **               -->
<!--     ** XML processor once we get to this point. **               -->
<!-- We employ the hex versions to match the U+hhhh notation common   -->
<!-- for Unicode.  Note: some characters, like a dumb apostrophe      -->
<!-- (U+0027), might be entities in source, but invisible to us here. -->

<!-- Note: a single text node can have many problems, -->
<!-- we catch such a node and then test for problems  -->
<xsl:template match="text()[contains(., '&#x00B0;') or contains(., '&#x00D7;') or contains(., '&#x200B;') or contains(., '&#x2013;') or contains(., '&#x2014;') or contains(., '&#x2018;') or contains(., '&#x2019;') or contains(., '&#x201C;') or contains(., '&#x201D;')]">
    <!-- Unicode Character 'DEGREE SIGN' (U+00B0) decimal: 176 -->
    <xsl:if test="contains(., '&#x00B0;')">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>A run of text contains a Unicode character for a degree symbol (U+00B0, decimal 176).&#xa;</xsl:text>
                <xsl:text>Likely this was introduced in a conversion of source material authored in a word-processor.&#xa;</xsl:text>
                <xsl:text>The symbol will behave better as the empty element "&lt;degree/&gt;"</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- Unicode Character 'MULTIPLICATION SIGN' (U+00D7) decimal: 215 -->
    <xsl:if test="contains(., '&#x00D7;')">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>A run of text contains a Unicode character for a multiplication sign (U+00D7, decimal 215).&#xa;</xsl:text>
                <xsl:text>Likely this was introduced in a conversion of source material authored in a word-processor.&#xa;</xsl:text>
                <xsl:text>The symbol will behave better as the empty element "&lt;times/&gt;"</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- Unicode Character 'ZERO WIDTH SPACE' (U+200B) decimal: 8203 -->
    <xsl:if test="contains(., '&#x200B;')">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>A run of text contains a Unicode character for zero-width character (U+200B, decimal 8203).&#xa;</xsl:text>
                <xsl:text>Likely this was introduced in a conversion of source material authored in a word-processor.&#xa;</xsl:text>
                <xsl:text>It is unnecessary and likely to cause errors.  It should be removed.</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- Unicode Character 'EN DASH' (U+2013) decimal: 8211 -->
    <xsl:if test="contains(., '&#x2013;')">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>A run of text contains a Unicode character for an en-dash (U+2013, decimal 8211).&#xa;</xsl:text>
                <xsl:text>Likely this was introduced in a conversion of source material authored in a word-processor.&#xa;</xsl:text>
                <xsl:text>The en-dash will behave better as the empty element "&lt;ndash/&gt;".&#xa;</xsl:text>
                <xsl:text>Understand the difference between an en-dash and an em-dash before editing.&#xa;</xsl:text>
                <xsl:text>An en-dash is used for a range, such as the years 2013-22.</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- Unicode Character 'EM DASH' (U+2014) decimal: 8212 -->
    <xsl:if test="contains(., '&#x2014;')">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>A run of text contains a Unicode character for an em-dash (U+2014, decimal 8212).&#xa;</xsl:text>
                <xsl:text>Likely this was introduced in a conversion of source material authored in a word-processor.&#xa;</xsl:text>
                <xsl:text>The em-dash will behave better as the empty element "&lt;mdash/&gt;".&#xa;</xsl:text>
                <xsl:text>Understand the difference between an en-dash and an em-dash before editing.&#xa;</xsl:text>
                <xsl:text>An em-dash is used for a pause in a sentence, and should not be authored with a space on either side.</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- Unicode Character 'LEFT SINGLE QUOTATION MARK' (U+2018) decimal: 8216 -->
    <!-- Unicode Character 'RIGHT SINGLE QUOTATION MARK' (U+2019) decimal: 8217 -->
    <xsl:if test="contains(., '&#x2018;') or contains(., '&#x2019;')">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>A run of text contains Unicode characters for single quotation marks (U+2018, decimal 8216; U+2019, decimal 8217).&#xa;</xsl:text>
                <xsl:text>Likely this was introduced in a conversion of source material authored in a word-processor.&#xa;</xsl:text>
                <xsl:text>A U+2019 in isolation could be an apostrophe.  Replace it with the keyboard version: U+0027.&#xa;</xsl:text>
                <xsl:text>A matching pair U+2018, U+2019 should be replaced by the "&lt;sq&gt;" element enclosing content.&#xa;</xsl:text>
                <xsl:text>In rare cases, U+2018 might be replaced by the empty element "&lt;lsq/&gt;".&#xa;</xsl:text>
                <xsl:text>In rare cases, U+2019 might be replaced by the empty element "&lt;rsq/&gt;".</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- Unicode Character 'LEFT DOUBLE QUOTATION MARK' (U+201C) decimal: 8220 -->
    <!-- Unicode Character 'RIGHT DOUBLE QUOTATION MARK' (U+201D) decimal: 8221-->
    <xsl:if test="contains(., '&#x201C;') or contains(., '&#x201D;')">
        <xsl:apply-templates select="." mode="messaging">
            <xsl:with-param name="severity" select="'warn'"/>
            <xsl:with-param name="message">
                <xsl:text>A run of text contains Unicode characters for double quotation marks (U+201C, decimal 8220; U+201D, decimal 8221).&#xa;</xsl:text>
                <xsl:text>Likely this was introduced in a conversion of source material authored in a word-processor.&#xa;</xsl:text>
                <xsl:text>A matching pair U+201C, U+201D should be replaced by the "&lt;q&gt;" element enclosing content.&#xa;</xsl:text>
                <xsl:text>In rare cases, U+201C might be replaced by the empty element "&lt;lq/&gt;".&#xa;</xsl:text>
                <xsl:text>In rare cases, U+201D might be replaced by the empty element "&lt;rq/&gt;".</xsl:text>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!--                                                              -->
    <!-- there is no recursing further, a text() node has no children -->
    <!--                                                              -->
</xsl:template>


<!-- ############## -->
<!-- Infrastructure -->
<!-- ############## -->

<!-- Entry template -->
<xsl:template match="/">
    <xsl:apply-templates/>
</xsl:template>

<!-- Traverse the tree, looking for trouble -->
<xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
</xsl:template>

<!-- ######### -->
<!-- Messaging -->
<!-- ######### -->

<xsl:template match="*|text()" mode="messaging">
    <xsl:param name="severity"/>
    <xsl:param name="message"/>

    <!-- Separator is noise for (sortable) single-line output -->
    <xsl:if test="not($b-single-line)">
        <xsl:text>################################################################&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>PTX:</xsl:text>
    <xsl:choose>
        <xsl:when test="$severity = 'error'">
            <xsl:text>ERROR</xsl:text>
        </xsl:when>
        <xsl:when test="$severity = 'warn'">
            <xsl:text>WARNING</xsl:text>
        </xsl:when>
        <xsl:when test="$severity = 'advice'">
            <xsl:text>ADVICE</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>################################################################</xsl:message>
            <xsl:message>Validation+ stylesheet is passing incorrect severity ("<xsl:value-of select="$severity"/>")</xsl:message>
            <xsl:message>################################################################</xsl:message>
            <xsl:message terminate='yes'/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="." mode="numbered-path"/>
    <!-- Consolidating output on a single line? space or newline here -->
    <!-- Then consolidate $message into one line, or leave alone      -->
    <xsl:choose>
        <xsl:when test="$b-single-line">
            <xsl:text>&#x20;</xsl:text>
            <xsl:value-of select="translate($message, '&#xa;', '&#x20;')"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>&#xa;</xsl:text>
            <xsl:value-of select="$message"/>
        </xsl:otherwise>
    </xsl:choose>
    <!-- supply final newline always -->
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="*|text()" mode="numbered-path">
    <!-- If "self" is a text node, then this variable will not include it -->
    <!-- since it is not an element, but it will begin with the element   -->
    <!-- *containing* the text node of interest, and hence be locatable.  -->
    <xsl:variable name="ancestors" select="ancestor-or-self::*"/>
    <xsl:for-each select="$ancestors">
        <xsl:text>/</xsl:text>
        <xsl:value-of select="local-name(.)"/>
        <xsl:text>[</xsl:text>
        <xsl:number/>
        <xsl:text>]</xsl:text>
    </xsl:for-each>
</xsl:template>

</xsl:stylesheet>


