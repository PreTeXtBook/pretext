<?xml version='1.0'?>

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
    <xsl:number count="section|exercises|reading-questions|solutions|references|glossary|worksheet" format="1" />
</xsl:template>
<xsl:template match="subsection" mode="division-serial-number">
    <xsl:number count="subsection|exercises|reading-questions|solutions|references|glossary|worksheet" format="1" />
</xsl:template>
<xsl:template match="subsubsection" mode="division-serial-number">
    <xsl:number count="subsubsection|exercises|reading-questions|solutions|references|glossary|worksheet" format="1" />
</xsl:template>

<!-- Specialized Divisions -->
<!-- "exercises", "solutions", references,             -->
<!-- "worksheet", "reading-questions", "glossary"      -->
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
<xsl:template match="exercises|reading-questions|solutions|references|glossary|worksheet" mode="division-serial-number">
    <xsl:number count="chapter|section|subsection|subsubsection|exercises|reading-questions|solutions|references|glossary|worksheet" format="1" />
</xsl:template>
<!-- Following "backmatter" matches will be more specific than above -->
<!-- A "solutions" is a specialized division, but is numbered        -->
<!-- as an appendix when present in the backmatter, see above        -->
<xsl:template match="backmatter/solutions" mode="division-serial-number">
    <xsl:number from="backmatter" level="any" count="appendix|solutions" format="A"/>
</xsl:template>

</xsl:stylesheet>
