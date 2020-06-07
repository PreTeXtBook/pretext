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
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
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
    <xsl:call-template name="assembly-warnings"/>
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

<!-- ################# -->
<!-- Private Solutions -->
<!-- ################# -->

<!-- "solutions" here refers generically to "hint", "answer",  -->
<!-- and "solution" elements of an "exercise".  An author may  -->
<!-- wish to provide limited distribution of some solutions to -->
<!-- exercises, which we deem "private" here.  If a            -->
<!-- "solutions.file" is provided, it will be mined for these  -->
<!-- private solutions.                                        -->

<xsl:param name="solutions.file" select="''"/>
<xsl:variable name="b-private-solutions" select="not($solutions.file = '')"/>

<xsl:variable name="n-hint"     select="document($solutions.file, /pretext)/pi:privatesolutions/hint"/>
<xsl:variable name="n-answer"   select="document($solutions.file, /pretext)/pi:privatesolutions/answer"/>
<xsl:variable name="n-solution" select="document($solutions.file, /pretext)/pi:privatesolutions/solution"/>

<xsl:template match="exercise" mode="assembly">
    <!-- <xsl:message>FOO:<xsl:value-of select="count($n-solution)"/></xsl:message> -->
    <xsl:variable name="the-id" select="@xml:id"/>
    <xsl:copy>
        <!-- attributes, then all elements that are not solutions -->
        <xsl:apply-templates select="*[not(self::hint or self::answer or self::solution)]|@*" mode="assembly"/>
        <!-- hints, answers, solutions; first regular, second private -->
        <xsl:apply-templates select="hint" mode="assembly"/>
        <xsl:apply-templates select="$n-hint[@ref=$the-id]" mode="assembly"/>
        <xsl:apply-templates select="answer" mode="assembly"/>
        <xsl:apply-templates select="$n-answer[@ref=$the-id]" mode="assembly"/>
        <xsl:apply-templates select="solution" mode="assembly"/>
        <xsl:apply-templates select="$n-solution[@ref=$the-id]" mode="assembly"/>
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

<!-- ############### -->
<!-- Source Warnings -->
<!-- ############### -->

<!-- A mistyped xref/@ref, or a replacement @xml:id, makes -->
<!-- for a broken cross-reference.  So we warn at run-time -->
<!-- and leave behind placeholder text.                    -->

<!-- TODO: move in @first/@last compatibility and order checks -->
<!-- TODO: perhaps parts of the following should be placed     -->
<!-- in -common so the "author tools" stylesheet could use it, -->
<!-- in addition to a more general source-checker stylesheet   -->

<xsl:template match="xref[not(@provisional)]" mode="assembly">
    <!-- commas to blanks, normalize spaces, -->
    <!-- add trailing space for final split  -->
    <xsl:variable name="normalized-ref-list">
        <xsl:choose>
            <xsl:when test="@ref">
                <xsl:value-of select="concat(normalize-space(str:replace(@ref,',', ' ')), ' ')"/>
            </xsl:when>
            <!-- put @first and @last into a normalized two-part list -->
            <xsl:when test="@first">
                <xsl:value-of select="concat(normalize-space(@first), ' ', normalize-space(@last), ' ')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>PTX:ERROR:   an "xref" lacks a @ref, @first, and @provisional; check your source or report as a potential bug</xsl:message>
                <xsl:apply-templates select="." mode="location-report"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- variable will contain comma-separated list  -->
    <!-- of @ref values that have no target, so if   -->
    <!-- empty that is success                       -->
    <xsl:variable name="bad-xrefs-in-list">
        <xsl:apply-templates select="." mode="check-ref-list">
            <xsl:with-param name="ref-list" select="$normalized-ref-list"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
        <!-- let assembly procede, do "xref" literally  -->
        <xsl:when test="$bad-xrefs-in-list = ''">
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="assembly"/>
            </xsl:copy>
        </xsl:when>
        <!-- error condition, so warn and leave  -->
        <!-- placeholder text in enhanced source -->
        <xsl:otherwise>
            <xsl:variable name="error-list" select="substring($bad-xrefs-in-list, 1, string-length($bad-xrefs-in-list) - 2)"/>
            <xsl:message>PTX:ERROR:   a cross-reference ("xref") uses references [<xsl:value-of select="$error-list"/>] that do not point to any target.  Maybe you typed an @xml:id value wrong, maybe the target of the @xml:id is nonexistent, or maybe you temporarily removed the target from your source.  Your output will contain some placeholder text that you will not want to distribute to your readers.</xsl:message>
            <xsl:apply-templates select="." mode="location-report"/>
            <!-- placeholder text -->
            <c>
                <xsl:text>[cross-reference to target(s) "</xsl:text>
                <xsl:value-of select="$error-list"/>
                <xsl:text>" missing]</xsl:text>
            </c>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="xref" mode="check-ref-list">
    <xsl:param name="ref-list"/>
    <xsl:choose>
        <!-- no more to test, stop recursing -->
        <xsl:when test="$ref-list = ''"/>
        <!-- test/check initial ref of the list -->
        <xsl:otherwise>
            <xsl:variable name="initial" select="substring-before($ref-list, ' ')" />
            <xsl:if test="not(exsl:node-set(id($initial)))">
                <!-- drop the failed lookup, plus a separator.  A nonempty -->
                <!-- result for this template is indicative of a failure   -->
                <!-- and the list can be reported in the error message     -->
                <xsl:value-of select="$initial"/>
                <xsl:text>, </xsl:text>
            </xsl:if>
            <xsl:apply-templates select="." mode="check-ref-list">
                <xsl:with-param name="ref-list" select="substring-after($ref-list, ' ')"/>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- An xref/@provisional is a tool for authors so we just -->
<!-- drop a reminder of some planned (forward) reference   -->
<xsl:template match="xref[@provisional]" mode="assembly">
    <c>
        <xsl:text>[provisional cross-reference: </xsl:text>
        <xsl:value-of select="@provisional"/>
        <xsl:text>]</xsl:text>
    </c>
</xsl:template>

<!-- ######## -->
<!-- Warnings -->
<!-- ######## -->

<xsl:template name="assembly-warnings">
    <xsl:if test="$b-private-solutions">
        <xsl:call-template name="banner-warning">
            <xsl:with-param name="warning">Use of a private solutions file is experimental and not supported.  Markup,&#xa;string parameters, and procedures are all subject to change.  (2020-06-06)</xsl:with-param>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>