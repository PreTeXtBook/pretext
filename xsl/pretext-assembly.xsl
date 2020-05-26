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
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
>

<!-- This is the once-mythical pre-processor, though we prefer     -->
<!-- to describe it as the "assembly" of "enhanced" source.  By    -->
<!-- "assembly" we mean pre-processing of source, by "assembling"  -->
<!-- various pieces of material or content, authored or computed,  -->
<!-- into an enhanced source tree.                                 -->
<!--                                                               -->
<!-- Import this stylesheet immediately after pretext-common.xsl. -->
<!--                                                               -->
<!-- * $original will point to source file/tree/XML at the overall -->
<!--   "pretext" element.                                          -->
<!-- * The modal "assembly" template will be applied to the source -->
<!--   root element, creating a new version of the source, which   -->
<!--   has been "enhanced".                                        -->
<!-- * $duplicate will point to the root of the enhanced source    -->
<!--   file/tree/XML.                                              -->
<!-- * $root will override (via this import) the similar variable  -->
<!--   defined in -common.                                         -->
<!-- * Derived variables, $docinfo and $document-root, will        -->
<!--   reference the enhanced source.                              -->
<!--                                                               -->
<!-- Notes:                                                        -->
<!--                                                               -->
<!-- 1.  $original is needed here for context switches into the    -->
<!--     authored source.                                          -->
<!-- 2.  Any coordination of automatically assigned identifiers    -->
<!--     requires identical source, so even a simple extraction    -->
<!--     stylesheet might require preparing identical source       -->
<!--     via this method.                                          -->
<!-- 3.  Overrides, customization of the assembly will typically   -->
<!--     happen here, but can be converter-specific in some ways.  -->


<!-- ############################## -->
<!-- Source Assembly Infrastructure -->
<!-- ############################## -->

<!-- When building the duplicate, we have occasion -->
<!-- to inspect the orginal in various places      -->
<xsl:variable name="original" select="/mathbook|/pretext"/>

<!-- This modal "assembly" template duplicates the source        -->
<!-- exactly: elements, attributes, text, whitespace, comments,  -->
<!-- everything. Various other templates may override this       -->
<!-- template in various ways to create an enhanced source tree. -->
<xsl:template match="node()|@*" mode="assembly">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="assembly"/>
    </xsl:copy>
</xsl:template>

<!-- This constructs the new tree as a (text) result tree      -->
<!-- fragment and then we convert it into real XML nodes. It   -->
<!-- has a root element as part of the node-set() manufacture. -->
<xsl:variable name="duplicate-rtf">
    <xsl:apply-templates select="/" mode="assembly"/>
</xsl:variable>
<xsl:variable name="duplicate" select="exsl:node-set($duplicate-rtf)"/>

<!-- -common defines a "$root" which is the overall named element. -->
<!-- We override it here and then -common will define some derived -->
<!-- variables based upon the $root                                -->
<!-- NB: source repair below converts a /mathbook to a /pretext    -->
<xsl:variable name="root" select="$duplicate/pretext" />


<!-- ######################## -->
<!-- Bibliography Manufacture -->
<!-- ######################## -->

<!-- Initial experiment, overall "references" flagged with -->
<!-- a @source filename as the place to go get a list of   -->
<!-- candidate "biblio" (in desired order)                 -->
<xsl:template match="backmatter/references[@source]" mode="assembly">
    <!-- Grab the list, filename is relative to the -->
    <!-- "document" holding "references" (original) -->
    <xsl:variable name="biblios" select="document(@source, .)"/>
    <!-- Copy the "references" element (could be literal, but maybe not in "text" output mode) -->
    <xsl:copy>
        <!-- @source attribute not needed in enhanced source -->
        <xsl:apply-templates select="@*[not(local-name() = 'source')]" mode="assembly"/>
        <!-- likely more elements to duplicate, consult schema -->
        <xsl:apply-templates select="title" mode="assembly"/>
        <!-- Look at each "biblio" in the external file -->
        <xsl:for-each select="$biblios/pretext-biblios/biblio">
            <xsl:variable name="the-id" select="@xml:id"/>
            <xsl:message>@xml:id of &lt;biblio&gt; in bibliography file: <xsl:value-of select="$the-id"/></xsl:message>
            <!-- Building duplicate, so look at $original for    -->
            <!-- "xref" pointing to the current context "biblio" -->
            <xsl:if test="$original//xref[@ref = $the-id]">
                <xsl:message>  Located this &lt;biblio&gt; cited in original source</xsl:message>
                <xsl:apply-templates select="." mode="assembly"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:copy>
</xsl:template>

<!-- ############# -->
<!-- Source Repair -->
<!-- ############# -->

<!-- We unilaterally make various changes to an author's source -->
<!-- so a conversion (every conversion?) can assume more        -->
<!-- accurately that the source has certain characteristics.    -->

<!-- 2019-04-02  "mathbook" replaced by "pretext" -->
<xsl:template match="/mathbook" mode="assembly">
    <pretext>
        <xsl:apply-templates select="node()|@*" mode="assembly"/>
    </pretext>
</xsl:template>

</xsl:stylesheet>