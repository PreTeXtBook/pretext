<?xml version='1.0'?>

<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!--********************************************************************
Copyright 2020 Robert A. Beezer

This file is part of PreTeXt.

PreTeXt is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

PreTeXt is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
    exclude-result-prefixes="pi"
>

<!-- Intend output as plain text (numbers) -->
<xsl:output method="text" encoding="UTF-8"/>

<!-- Read documentation in the "-assembly" stylesheet to understand -->
<!-- employment/purpose of these templates there.                   -->
<!--                                                                -->
<!-- 2021-12-22: moving the computation of serial numbers out of    -->
<!-- the "-common" stylesheet, so as to be pre-computed.            -->

<!-- ############## -->
<!-- Serial Numbers -->
<!-- ############## -->

<!-- These templates count the occurences of an element within a       -->
<!-- subtree.  Sometimes that subtree is rooted just above the element -->
<!-- (e.g. divisions) or sometimes it is many levels higher, such as   -->
<!-- when an "example" might be in a "subsubsection" but they are      -->
<!-- grouped ("count within" in LaTeX-speak) and counted across all    -->
<!-- "example" within a chapter (ignoring the divisions by section,    -->
<!-- subsection, and subsubsection).                                   -->
<!--                                                                   -->
<!-- All of the hard work of counting is done in these templates.      -->
<!-- Elsewhere, serial numbers are combined with hierarchical          -->
<!-- numbering of divisions to form "full" numbers.                    -->

<!-- Traditional Divisions -->
<!-- Mostly obvious, counting peers, including specialized         -->
<!-- divisions.  Roman numerals for parts, letters for appendices. -->
<xsl:template match="part" mode="division-serial-number">
    <xsl:number format="I" />
</xsl:template>
<xsl:template match="chapter" mode="division-serial-number">
    <!-- chapters, in parts or not -->
    <xsl:choose>
        <xsl:when test="($parts = 'absent') or ($parts = 'decorative')">
            <xsl:variable name="true-count">
                <xsl:number from="book" level="any" count="chapter" format="1" />
            </xsl:variable>
            <!-- $chapter-start defaults to 1 -->
            <xsl:value-of select="$true-count + $chapter-start - 1" />
        </xsl:when>
        <!-- author-specified chapter start number does  -->
        <!-- not really make sense for structural parts? -->
        <xsl:when test="$parts = 'structural'">
            <xsl:number from="part" count="chapter" format="1" />
        </xsl:when>
    </xsl:choose>
</xsl:template>
<!-- A "solutions" is a specialized division, but is numbered -->
<!-- as an appendix when present in the backmatter, so        -->
<!-- included in the count here.                              -->
<xsl:template match="appendix" mode="division-serial-number">
    <xsl:number from="backmatter" level="any" count="appendix|solutions" format="A"/>
</xsl:template>
<!-- NB: following do not assume an ordering on the subdivisions,     -->
<!-- since this has not been solidified in the schema. At that point, -->
<!-- we might enforce some assumptions here, and elsewhere, by only   -->
<!-- including predecessors in the @count attribute.                  -->
<xsl:template match="section" mode="division-serial-number">
    <xsl:number count="section|exercises|reading-questions|solutions|references|glossary|worksheet|handout" format="1" />
</xsl:template>
<xsl:template match="subsection" mode="division-serial-number">
    <xsl:number count="subsection|exercises|reading-questions|solutions|references|glossary|worksheet|handout" format="1" />
</xsl:template>
<xsl:template match="subsubsection" mode="division-serial-number">
    <xsl:number count="subsubsection|exercises|reading-questions|solutions|references|glossary|worksheet|handout" format="1" />
</xsl:template>

<!-- Specialized Divisions -->
<!-- "exercises", "solutions", references, "worksheet",-->
<!-- "handout", "reading-questions", "glossary"        -->
<!-- This is the case of a "structured" division,      -->
<!-- where we use the resulting number for the         -->
<!-- division. (In the unstructured case, the number   -->
<!-- will be inherited from the parent, so this number -->
<!-- is incorrect, meaningless, and ignored.)  So we   -->
<!-- simply count preceding peers.  Note that every    -->
<!-- possible traditional division that could be a     -->
<!-- peer is listed here in the "match", but only one  -->
<!-- type will actually be present in the structured   -->
<!-- division.                                         -->
<xsl:template match="exercises|reading-questions|solutions|references|glossary|worksheet|handout" mode="division-serial-number">
    <xsl:number count="chapter|section|subsection|subsubsection|exercises|reading-questions|solutions|references|glossary|worksheet|handout" format="1" />
</xsl:template>
<!-- Following "backmatter" matches will be more specific than above -->
<!-- A "solutions" is a specialized division, but is numbered        -->
<!-- as an appendix when present in the backmatter, see above        -->
<xsl:template match="backmatter/solutions" mode="division-serial-number">
    <xsl:number from="backmatter" level="any" count="appendix|solutions" format="A"/>
</xsl:template>

<!-- ######################### -->
<!-- Structured vs. Decorative -->
<!-- ######################### -->

<!-- These templates determine the structure of divisions, needed    -->
<!-- during assembly to compute block structure numbers.  They are   -->
<!-- also used at render time from pretext-common.xsl and elsewhere, -->
<!-- available via cross-import resolution (every conversion         -->
<!-- stylesheet imports both pretext-assembly.xsl and                -->
<!-- pretext-common.xsl).                                            -->

<!-- There are two models for most of the divisions (part -->
<!-- through subsubsection, plus appendix).  One has      -->
<!-- subdivisions, and possibly specialized subdivisions. -->
<!-- The other has no subdivisions, and then at most one  -->
<!-- of each type of specialized subdivision, which       -->
<!-- inherit numbers from their parent division. This is  -->
<!-- the test, which is very similar to "is-leaf" in      -->
<!-- pretext-common.xsl.                                  -->
<!--                                                      -->
<!-- A "part" must have chapters, so will always return   -->
<!-- 'true' and for a 'subsubsection' there are no more   -->
<!-- subdivisions to employ and so will return empty.     -->
<!--                                                      -->
<!-- An exception is a division of *only* worksheets.     -->
<!-- Although there could be titles and the like.         -->
<!-- So we compare all-children to  metadata + worksheet. -->
<!-- TODO: should there be a similar exception for handouts? -->
<xsl:template match="book|article|part|chapter|appendix|section|subsection|subsubsection" mode="is-structured-division">
    <xsl:variable name="has-traditional" select="boolean(&TRADITIONAL-DIVISION;)"/>
    <xsl:variable name="all-children" select="*"/>
    <xsl:variable name="all-worksheet" select="title|shorttitle|plaintitle|idx|introduction|worksheet|handout|conclusion"/>
    <xsl:variable name="only-worksheets" select="count($all-children) = count($all-worksheet)"/>

    <xsl:value-of select="$has-traditional or $only-worksheets"/>
</xsl:template>

<xsl:template match="*" mode="is-structured-division">
    <xsl:message>PTX:BUG: asking if a non-traditional division (<xsl:value-of select="local-name(.)"/>) is structured or not</xsl:message>
</xsl:template>

<!-- Specialized divisions sometimes inherit a number from their  -->
<!-- parent (as part of an unstructured division) and sometimes   -->
<!-- they do not even have a number (singleton "references" as    -->
<!-- child of "backmatter").  This template returns "true" if a   -->
<!-- specialized division "owns" its "own" number.                -->
<xsl:template match="exercises|worksheet|handout|references|glossary|reading-questions|solutions" mode="is-specialized-own-number">
    <xsl:choose>
        <!-- *Some* specialized divisions can appear as a child of the    -->
        <!-- "backmatter" too.  But only those below.  The rest are       -->
        <!-- banned as top-level items in the backmatter, but might       -->
        <!-- occur in an "appendix" or below, with or without structure.  -->
        <!--   "solutions" will look like an appendix, thus numbered.     -->
        <!--   "references" or "glossary" are singletons, never numbered. -->
        <xsl:when test="parent::*[self::backmatter]">
            <xsl:choose>
                <xsl:when test="self::solutions">
                    <xsl:text>true</xsl:text>
                </xsl:when>
                <xsl:when test="self::references or self::glossary">
                    <xsl:text>false</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   encountered a specialized division ("<xsl:value-of select="local-name(.)"/>") as a child of "backmatter" that was unexpected.  Results will be unpredictable</xsl:message>
                    <!-- no idea if we should say true or false here -->
                    <xsl:text>true</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- parent must now be a "traditional" division -->
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="is-structured-division"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="is-specialized-own-number">
    <xsl:message>PTX:BUG: asking if a non-specialized division (<xsl:value-of select="local-name(.)"/>) is numbered or not</xsl:message>
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- ######################## -->
<!-- Block Structure Numbers  -->
<!-- ######################## -->

<!-- Given a block element, produce its structure number prefix      -->
<!-- by reading the pre-computed @block-struct from the nearest      -->
<!-- ancestor division, then truncating or padding to the configured -->
<!-- number of levels.  The @block-struct chain already excludes     -->
<!-- parts (they are squelched in assembly), so when parts are       -->
<!-- present the caller's $levels (which counts from "part" depth)   -->
<!-- must be reduced by one to match the shorter chain.              -->
<xsl:template name="block-structure-number">
    <xsl:param name="levels"/>
    <xsl:variable name="raw-struct"
        select="ancestor::*[@block-struct][1]/@block-struct"/>
    <!-- The @block-struct chain already excludes parts, so when  -->
    <!-- parts are present the $levels count (which includes the -->
    <!-- part depth) must be reduced by one.  But only for       -->
    <!-- blocks actually inside a part or backmatter — blocks    -->
    <!-- in frontmatter have no part ancestor and should use     -->
    <!-- $levels unmodified.                                     -->
    <xsl:variable name="effective-levels">
        <xsl:choose>
            <xsl:when test="not($parts = 'absent') and ancestor::*[self::part or self::backmatter]">
                <xsl:choose>
                    <xsl:when test="$levels > 0">
                        <xsl:value-of select="$levels - 1"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="0"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$levels"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="truncate-pad-struct">
        <xsl:with-param name="struct" select="$raw-struct"/>
        <xsl:with-param name="levels" select="$effective-levels"/>
    </xsl:call-template>
</xsl:template>

<!-- Truncate a dotted-number string to a given number of     -->
<!-- components, padding with ".0" if fewer components exist.  -->
<xsl:template name="truncate-pad-struct">
    <xsl:param name="struct"/>
    <xsl:param name="levels"/>
    <xsl:param name="count" select="0"/>

    <xsl:choose>
        <!-- Emitted enough levels, halt -->
        <xsl:when test="$count = $levels"/>
        <!-- Components remaining in the string -->
        <xsl:when test="$struct != ''">
            <xsl:if test="$count > 0">
                <xsl:text>.</xsl:text>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="contains($struct, '.')">
                    <xsl:value-of select="substring-before($struct, '.')"/>
                    <xsl:call-template name="truncate-pad-struct">
                        <xsl:with-param name="struct"
                            select="substring-after($struct, '.')"/>
                        <xsl:with-param name="levels" select="$levels"/>
                        <xsl:with-param name="count" select="$count + 1"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$struct"/>
                    <xsl:call-template name="truncate-pad-struct">
                        <xsl:with-param name="struct" select="''"/>
                        <xsl:with-param name="levels" select="$levels"/>
                        <xsl:with-param name="count" select="$count + 1"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- Out of components, pad with zero -->
        <xsl:otherwise>
            <xsl:if test="$count > 0">
                <xsl:text>.</xsl:text>
            </xsl:if>
            <xsl:text>0</xsl:text>
            <xsl:call-template name="truncate-pad-struct">
                <xsl:with-param name="struct" select="''"/>
                <xsl:with-param name="levels" select="$levels"/>
                <xsl:with-param name="count" select="$count + 1"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>
