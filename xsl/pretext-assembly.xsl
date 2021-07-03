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

<!-- This is the once-mythical pre-processor, though we prefer     -->
<!-- to describe it as the "assembly" of "enhanced" source.  By    -->
<!-- "assembly" we mean pre-processing of source, by "assembling"  -->
<!-- various pieces of material or content, authored or computed,  -->
<!-- into an enhanced source tree. This template operates by       -->
<!-- successive passes through the entire source tree making       -->
<!-- adjustments into a new "enhanced" or modified source tree     -->
<!-- with each pass.                                               -->
<!--                                                               -->
<!-- Import this stylesheet immediately after pretext-common.xsl.  -->
<!--                                                               -->
<!-- * $original will point to source file/tree/XML at the overall -->
<!--   "pretext" element.                                          -->
<!-- * The modal "assembly" templates are applied to the source    -->
<!--   root element, creating a new version of the source, which   -->
<!--   has been "enhanced".  Various things happen in this pass,   -->
<!--   such as assembling auxiliary files of content (WeBWorK      -->
<!--   representations, private solutions, bibliographic items),   -->
<!--   or automatically repairing deprecated constructions so that -->
<!--   actual conversions can remove orphaned code.  This creates  -->
<!--   the $assembly source tree.                                  -->
<!-- * The two modal "version" templates are applied to decide if  -->
<!--   certain elements are included or excluded from the source   -->
<!--   tree.  This creates the $version source tree.               -->
<!-- * $version will point to the root of the final enhanced       -->
<!--   source file/tree/XML.                                       -->
<!-- * $root will override (via this import) the similar variable  -->
<!--   defined in -common.                                         -->
<!-- * Derived variables, $docinfo and $document-root, will        -->
<!--   reference the final enhanced source tree ($version).        -->
<!--                                                               -->
<!-- Notes:                                                        -->
<!--                                                               -->
<!-- 1.  $original is needed for context switches back into the    -->
<!--     original authored source, such as for determining the     -->
<!--     location of the source in the file system.                -->
<!-- 2.  Any coordination of automatically assigned identifiers    -->
<!--     requires identical source, so even a simple extraction    -->
<!--     stylesheet might require preparing identical source       -->
<!--     via this method.                                          -->
<!-- 3.  Overrides, customization of the assembly will typically   -->
<!--     happen here, but can be converter-specific in some ways.  -->

<!-- Timing debugging -->
<xsl:param name="debug.assembly.time" select="'no'"/>
<xsl:variable name="time-assembly" select="$debug.assembly.time = 'yes'"/>

<!-- ############################## -->
<!-- Source Assembly Infrastructure -->
<!-- ############################## -->

<!-- When building duplicates, we have occasion -->
<!-- to inspect the original in various places  -->
<xsl:variable name="original" select="/mathbook|/pretext"/>

<!-- These modal templates duplicate the source exactly for each -->
<!-- pass: elements, attributes, text, whitespace, comments,     -->
<!-- everything. Various other templates will override these     -->
<!-- templates to create a new enhanced source tree.             -->
<xsl:template match="node()|@*" mode="assembly">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="assembly"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="version">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="version"/>
    </xsl:copy>
</xsl:template>

<!-- These templates initiate and create several iterations of -->
<!-- the source tree via modal templates.  Think of each as a  -->
<!-- "pass" through the source. Generally this constructs the  -->
<!-- new tree as a (text) result tree fragment and then we     -->
<!-- convert it into real XML nodes. These "real" trees have a -->
<!-- root element, as a result of the node-set() manufacture.  -->
<xsl:variable name="assembly-rtf">
    <xsl:call-template name="assembly-warnings"/>
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: start assembly</xsl:message>
    </xsl:if>
    <!--  -->
    <xsl:apply-templates select="/" mode="assembly"/>
    <!--  -->
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: end assembly</xsl:message>
    </xsl:if>
    <!--  -->
</xsl:variable>
<xsl:variable name="assembly" select="exsl:node-set($assembly-rtf)"/>

<xsl:variable name="version-rtf">
    <xsl:apply-templates select="$assembly" mode="version"/>
    <!--  -->
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: end version</xsl:message>
    </xsl:if>
    <!--  -->
</xsl:variable>
<xsl:variable name="version" select="exsl:node-set($version-rtf)"/>

<!-- -common defines a "$root" which is the overall named element. -->
<!-- We override it here and then -common will define some derived -->
<!-- variables based upon the $root                                -->
<!-- NB: source repair below converts a /mathbook to a /pretext    -->
<xsl:variable name="root" select="$version/pretext" />


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

<!-- Normally we are not extracting PG. When we do, extract-pg.xsl -->
<!-- will override the following with true()                       -->
<xsl:variable name="b-extracting-pg" select="false()"/>

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
        <xsl:when test="$b-extracting-pg">
            <xsl:choose>
                <xsl:when test="@copy">
                    <!-- this will need to switch to a document-wide search     -->
                    <!-- for a match on the @name value, once that attribute    -->
                    <!-- is in place, since we do not yet have the              -->
                    <!-- @name -> @xml:id  mapping until we are done assembling -->
                    <xsl:variable name="target" select="id(@copy)"/>
                    <xsl:choose>
                        <xsl:when test="$target/statement|$target/stage">
                            <xsl:copy>
                                <xsl:attribute name="copied-from">
                                    <xsl:value-of select="@copy"/>
                                </xsl:attribute>
                                <xsl:apply-templates select="@*[not(local-name(.) = 'copy')]" mode="assembly"/>
                                <xsl:apply-templates select="$target/@*[not(local-name(.) = 'id')][not(local-name(.) = 'seed')]" mode="assembly"/>
                                <!-- TODO: The following should scrub unique IDs as it continues down the tree. -->
                                <!-- Perhaps with a param to the assembly modal template.                       -->
                                <xsl:apply-templates select="$target/node()" mode="assembly"/>
                            </xsl:copy>
                        </xsl:when>
                        <xsl:otherwise>
                            <webwork>
                                <statement>
                                    <p>
                                        A WeBWorK problem would appear here, but something about its <c>@copy</c> attribute is not right.
                                        Search the runtime output for <q><c>PTX:ERROR</c></q>.
                                    </p>
                                </statement>
                            </webwork>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy>
                        <xsl:apply-templates select="node()|@*" mode="assembly"/>
                    </xsl:copy>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
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

<!-- ############## -->
<!-- Customizations -->
<!-- ############## -->

<!-- The "custom" element, with a @name in an auxiliary file,     -->
<!-- and a @ref in a source file, allows for custom substitutions -->

<!-- If the publisher variable  $customizations-file  is bad, -->
<!-- then  document()  will raise an error.  The empty string -->
<!-- (default) will not raise an error, so if not specified,  -->
<!-- no problem.  But an empty string, and an attempted       -->
<!-- access in the template *will* raise the error below.     -->
<xsl:variable name="customizations" select="document($customizations-file, $original)"/>

<!-- Set the key, nodes to be located are named -->
<!-- "custom" within the file just accessed     -->
<!-- For each one, @name is the search term     -->
<!-- that will locate it: the key, the index    -->
<xsl:key name="name-key" match="custom" use="@name"/>

<xsl:template match="custom[@ref]" mode="assembly">
    <!-- We need to get the @ref attribute now, due to a context shift -->
    <!-- And the "custom" context also, for use in a location report   -->
    <xsl:variable name="the-ref" select="string(@ref)"/>
    <xsl:variable name="the-custom" select="."/>
    <!-- Now the context shift to query the customizations -->
    <xsl:for-each select="$customizations">
        <xsl:variable name="the-lookup" select="key('name-key', $the-ref)"/>
        <!-- This is an AWOL node, not empty content (which is allowed) -->
        <xsl:if test="not($the-lookup)">
            <xsl:text>[MISSING CUSTOM CONTENT HERE]</xsl:text>
            <xsl:message>PTX:WARNING:   lookup for a "custom" element with @name set to "<xsl:value-of select="$the-ref"/>" has failed, while consulting the customization file "<xsl:value-of select="$customizations-file"/>".  Output will contain "[MISSING CUSTOM CONTENT HERE]" instead</xsl:message>
            <xsl:apply-templates select="$the-custom" mode="location-report"/>
        </xsl:if>
        <!-- Copying the contents of "custom" via the "assembly" templates -->
        <!-- will keep the "pi" namespace from appearing in palces, as it  -->
        <!-- will with an "xsl:copy-of" on the same node set.  But it      -->
        <!-- allows nested "custom" elements.                              -->
        <!--                                                               -->
        <!-- Do we want authors to potentially create cyclic references?   -->
        <!-- A simple 2-cycle test failed quickly and obviously, so it     -->
        <!-- will be caught quite easily, it seems.                        -->
        <xsl:apply-templates select="$the-lookup/node()" mode="assembly"/>
    </xsl:for-each>
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

<!-- N.B.  We considered interpreting the "no content" form here by simply  -->
<!-- duplicating @href as the content (in a "c" element).  This would mean  -->
<!-- just a single template/case in conversions.  But it would prevent      -->
<!-- LaTeX from being able to use a \url{} construction which does sensible -->
<!-- line-breaking. -->

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

<!-- 2021-07-02 wrap notation/usage in "m" if not present -->
<xsl:template match="notation/usage[not(m)]" mode="assembly">
    <!-- duplicate "usage" w/ attributes, insert "m" as repair -->
    <usage>
        <xsl:apply-templates select="@*" mode="assembly"/>
        <m>
            <xsl:apply-templates select="node()|@*" mode="assembly"/>
        </m>
    </usage>
</xsl:template>

<!-- ######## -->
<!-- Warnings -->
<!-- ######## -->

<!-- A place for warnings about missing files, etc -->
<!-- and/or temporary/experimental features        -->
<xsl:template name="assembly-warnings">
    <xsl:if test="$original/*[not(self::docinfo)]//webwork/node() and not($b-doing-webwork-assembly or $b-extracting-pg)">
        <xsl:message>PTX:WARNING: Your document has WeBWorK exercises,</xsl:message>
        <xsl:message>             but your publisher file does not indicate the file</xsl:message>
        <xsl:message>             of problem representations created by a WeBWorK server.</xsl:message>
        <xsl:message>             Exercises will have a small informative message instead</xsl:message>
        <xsl:message>             of the intended content.  Not making this file available</xsl:message>
        <xsl:message>             can cause difficulties when parts of your document get</xsl:message>
        <xsl:message>             processed by external programs (e.g. graphics, previews)</xsl:message>
    </xsl:if>
    <xsl:if test="$b-extracting-pg">
        <xsl:variable name="webwork-with-copy" select="$original//webwork[@copy]"/>
        <xsl:for-each select="$webwork-with-copy">
            <!-- this will need to switch to a document-wide search     -->
            <!-- for a match on the @name value, once that attribute    -->
            <!-- is in place, since we do not yet have the              -->
            <!-- @name -> @xml:id  mapping until we are done assembling -->
            <xsl:variable name="target" select="id(@copy)"/>
            <xsl:choose>
                <xsl:when test="$target/statement|$target/stage"/>
                <xsl:when test="$target/@source">
                    <xsl:message>PTX:ERROR:   A WeBWorK problem with copy="<xsl:value-of select="@copy"/>"</xsl:message>
                    <xsl:message>             points to a WeBWorK problem that uses a source attribute</xsl:message>
                    <xsl:message>             to generate a problem using a file that exists on the WeBWorK server.</xsl:message>
                    <xsl:message>             Instead of using the copy attribute, use the same source attribute.</xsl:message>
                </xsl:when>
                <xsl:when test="not($target)">
                    <xsl:message>PTX:ERROR:   A WeBWorK problem uses copy="<xsl:value-of select="@copy"/>",</xsl:message>
                    <xsl:message>             but there is no WeBWorK problem with xml:id="<xsl:value-of select="@copy"/>".</xsl:message>
                    <xsl:message>             Is it a typo? Is the target WeBWorK problem currently commented out in source?</xsl:message>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   A WeBWorK problem with copy="<xsl:value-of select="@copy"/>"</xsl:message>
                    <xsl:message>             points to a WeBWorK problem that does not have a statement or stage.</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>
