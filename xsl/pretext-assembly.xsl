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

<!-- ################### -->
<!-- WeBWorK Manufacture -->
<!-- ################### -->

<!-- Prevents repeated access attempts to non-existent file    -->
<!-- Also use for overall warning about inability to create WW -->
<!-- $webwork-representations-file is from publisher file      -->
<xsl:variable name="b-doing-webwork-assembly" select="not($webwork-representations-file = '')"/>

<!-- Don't match on simple WeBWorK logo       -->
<!-- Seed and possibly source attributes      -->
<!-- Then authored?, pg?, and static children -->
<!-- NB: "xref" check elsewhere is not        -->
<!-- performed here since we accept           -->
<!-- representations at face-value            -->
<xsl:template match="webwork[node()|@*]" mode="assembly">
    <xsl:variable name="ww-id">
        <xsl:apply-templates select="." mode="visible-id" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$b-doing-webwork-assembly">
            <xsl:copy-of select="document($webwork-representations-file, /pretext)/webwork-representations/webwork-reps[@ww-id=$ww-id]" />
        </xsl:when>
        <xsl:otherwise>
            <statement>
                <p>The WeBWorK problem with ID <q><xsl:value-of select="$ww-id"/></q> will appear here if you provide the file of problems that have been processed by a WeBWorK server (<c>webwork-representations.ptx</c>).</p>
            </statement>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################# -->
<!-- Private Solutions -->
<!-- ################# -->

<!-- "solutions" here refers generically to "hint", "answer",  -->
<!-- and "solution" elements of an "exercise".  An author may  -->
<!-- wish to provide limited distribution of some solutions to -->
<!-- exercises, which we deem "private" here.  If a            -->
<!-- "private-solutions-file" is provided, it will be mined    -->
<!-- for these private solutions.                              -->

<xsl:variable name="b-private-solutions" select="not($private-solutions-file = '')"/>

<!-- Note: there may be (nested) "pi:privatesolutionsdivision"  -->
<!-- elements in this file.  They are largely meaningless, but  -->
<!-- are necessary if an author wants to modularize their       -->
<!-- collection across multiple files.  Then each file can be a -->
<!-- single overall element.  (We expect/require no additional  -->
<!-- structure in this file.)  The consequence is the "//" in   -->
<!-- each expression below.                                     -->
<!-- NB: relative to *original* source file/tree                -->
<xsl:variable name="privatesolns" select="document($private-solutions-file, $original)"/>
<xsl:variable name="n-hint"     select="$privatesolns/pi:privatesolutions//hint"/>
<xsl:variable name="n-answer"   select="$privatesolns/pi:privatesolutions//answer"/>
<xsl:variable name="n-solution" select="$privatesolns/pi:privatesolutions//solution"/>

<xsl:template match="exercise|task" mode="assembly">
    <xsl:variable name="the-id" select="@xml:id"/>
    <xsl:copy>
        <!-- attributes, then all elements that are not solutions                               -->
        <!--   unstructured exercise:  "p" etc, then solutions OK even if schema violation?     -->
        <!--   structured exercise: copy statement, then interleave solutions                   -->
        <!--   non-terminal Task: introduction, task, conclusion                                -->
        <!--   terminal unstructured task: "p" etc, then solutions OK even if schema violation? -->
        <!--   terminal structured task: copy statement, then interleave solutions              -->
        <!-- TODO: defend against non-terminal task, unstructured cases      -->
        <!-- (identify proper structure + non-empty union of three additions -->
        <!-- Fix unstructured cases by inserting "statement",                -->
        <!-- warn about non-terminal task case and drop additions (error)    -->
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
<!-- Conveniences  -->
<!-- ############# -->

<!-- Certain markup can be translated into more primitive versions using      -->
<!-- existing markup, so we do a translation of certain forms into more       -->
<!-- potentially verbose forms that an author might tire of doing repeatedly. -->
<!-- See below for examples.  This is better than making a result-tree        -->
<!-- fragment and applying templates, since all context is lost that way.     -->

<!-- Visual URLs -->
<!-- A great way to present a URL is with some clickable text.  But that    -->
<!-- is useless in print.  And maybe a reader really would like to see the  -->
<!-- actual URL.  So "@visual" is a version of the URL that is pleasing to -->
<!-- look at, maybe just a TLD, no protocol (e.g "https://"), no "www."     -->
<!-- if unnecessary, etc.  Here it becomes a footnote, and in monospace     -->
<!-- ("code") font.  This is great in print, and is a knowl in HTML.        -->
<!--                                                                        -->
<!-- Advantages: however a conversion does footnotes, this will be the      -->
<!-- right markup for that conversion.  Note that LaTeX pulls footnotes     -->
<!-- out of "tcolorbox" environments, which is based on the *context*,      -->
<!-- so a result-tree fragment implementation is doomed to fail.            -->

<xsl:template match="url[@visual]" mode="assembly">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*[not(local-name(.) = 'visual')]" mode="assembly"/>
    </xsl:copy>
    <fn><c><xsl:value-of select="@visual"/></c></fn>
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
            <xsl:message>PTX:ERROR:   a cross-reference ("xref") uses references [<xsl:value-of select="$error-list"/>] that do not point to any target, or perhaps point to multiple targets.  Maybe you typed an @xml:id value wrong, maybe the target of the @xml:id is nonexistent, or maybe you temporarily removed the target from your source, or maybe an auxiliary file contains a duplicate.  Your output will contain some placeholder text that you will not want to distribute to your readers.</xsl:message>
            <xsl:apply-templates select="." mode="location-report"/>
            <!-- placeholder text -->
            <c>
                <xsl:text>[cross-reference to target(s) "</xsl:text>
                <xsl:value-of select="$error-list"/>
                <xsl:text>" missing or not unique]</xsl:text>
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
            <!-- Look up the ref in all relevant "documents":          -->
            <!-- the original source, and private solution file.       -->
            <!-- Count the number of successes, hoping it will be 1.   -->
            <!-- Long-term, this check should be performed in a second -->
            <!-- pass on a completely assembled source, so the id()    -->
            <!-- function does not need to survey multiple documents.  -->
            <xsl:variable name="hits">
                <!-- always do a context shift to $original -->
                <xsl:for-each select="$original">
                    <xsl:if test="exsl:node-set(id($initial))">
                        <xsl:text>X</xsl:text>
                    </xsl:if>
                </xsl:for-each>
                <!-- optionally do a context shift to private solutions file -->
                <xsl:if test="$b-private-solutions">
                    <xsl:for-each select="$privatesolns">
                        <xsl:if test="exsl:node-set(id($initial))">
                            <xsl:text>X</xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:if>
            </xsl:variable>
            <xsl:if test="not($hits = 'X')">
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

<!-- A place for warnings about missing files, etc -->
<!-- and/or temporary/experimental features        -->
<xsl:template name="assembly-warnings">
    <xsl:if test="$original/*[not(self::docinfo)]//webwork/node() and not($b-doing-webwork-assembly)">
        <xsl:message>PTX:WARNING: Your document has WeBworK exercises,</xsl:message>
        <xsl:message>             but your publisher file does not indicate the file</xsl:message>
        <xsl:message>             of problem representations created by a WeBWorK server.</xsl:message>
        <xsl:message>             Exercises will have a small informative message instead</xsl:message>
        <xsl:message>             of the intended content.  Not making this file available</xsl:message>
        <xsl:message>             can cause difficulties when parts of your document get</xsl:message>
        <xsl:message>             processed by external programs (e.g. graphics, previews)</xsl:message>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>
