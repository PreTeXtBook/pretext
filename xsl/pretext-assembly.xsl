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

<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

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
<!-- * $original will point to source file/tree/XML at the overall -->
<!--   "pretext" element.                                          -->
<!-- * The "version" templates are applied to decide if certain    -->
<!--   elements are excluded from the source tree.  This creates   -->
<!--   the new $version source tree by *removing* source.          -->
<!-- * The modal "assembly" templates are applied to the source    -->
<!--   root element, creating a new version of the source, which   -->
<!--   has been "enhanced".  Various things happen in this pass,   -->
<!--   such as assembling auxiliary files of content (WeBWorK      -->
<!--   representations, private solutions, bibliographic items).   -->
<!--   This creates the $assembly source tree by *adding* new      -->
<!--   source elements.                                            -->
<!-- * The "repair" templates will automatically repair deprecated -->
<!--   constructions so that actual conversions can remove         -->
<!--   orphaned code.  Despite the name, we also implement         -->
<!--   conveniences that are universal accross all conversions, so -->
<!--   that conversions can assume a more canonical version of the -->
<!--   source, or remove the need for additional templates to      -->
<!--   realize certain constructions (e.g. url/@visual).  This     -->
<!--   creates the $repair source tree by *changing* source.       -->
<!-- * $root will point to the root of the final enhanced          -->
<!--   source file/tree/XML.                                       -->
<!-- * Derived variables, $docinfo and $document-root, will        -->
<!--   be created here for use in subsequent stylesheets.          -->
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
<!--                                                               -->
<!-- The "publisher-variables.xsl" and "pretext-assembly.xsl"      -->
<!-- stylesheets are symbiotic, and should be imported             -->
<!-- simultaneously.  Assembly will change the source in various   -->
<!-- ways, while some defaults for publisher variables will depend -->
<!-- on source.  The default variables should depend on gross      -->
<!-- structure and adjustments should be to smaller portions of    -->
<!-- the source, but we don't take any chances.  So, note in       -->
<!-- "assembly" that an intermediate tree is defined as a          -->
<!-- variable, which is then used in defining some variables,      -->
<!-- based on assembled source.  Conversely, certain variables,    -->
<!-- such as locations of customizations or private solutions,     -->
<!-- are needed early in assembly, while other variables, such     -->
<!-- as options for numbering, are needed for later enhancements   -->
<!-- to the source.  If new code results in undefined, or          -->
<!-- recursively defined, variables, this discussion may be        -->
<!-- relevant.  (This is repeated verbatim in the other            -->
<!-- stylesheet).                                                  -->


<!-- Isolate computation of numbers -->
<xsl:import href="./pretext-numbers.xsl"/>
<!-- Isolate conversion of Runestone/interactive to PreTeXt/static -->
<xsl:import href="./pretext-runestone-static.xsl"/>

<!-- The "representations" pass is used to make derived versions of      -->
<!-- authored exercises which can be rendered dynamically.  For example, -->
<!-- a multiple choice question.  These representations can be "static"  -->
<!-- and so meant for use in PDF or braille output, or "dynamic", which  -->
<!-- means anyplace Javascript (or similar) is available.  Right now     -->
<!-- that is just HTML (and not output built on HTML, such as EPUB).     -->
<!--                                                                     -->
<!-- Notes:                                                              -->
<!--   * We default here to "static".  HTML production will override     -->
<!--     to "dynamic" and then any importing stylesheet will need to     -->
<!--     override back to "static".                                      -->
<!--   * If testing, the pretext-enhanced-source.xsl  stylesheet will    -->
<!--     need a stringparam override to view and test dynamic versions.  -->
<xsl:variable name="exercise-style" select="'static'"/>

<!-- Timing debugging -->
<xsl:param name="debug.assembly.time" select="'no'"/>
<xsl:variable name="time-assembly" select="$debug.assembly.time = 'yes'"/>

<!-- ############################## -->
<!-- Source Assembly Infrastructure -->
<!-- ############################## -->

<!-- When building duplicates, we have occasion -->
<!-- to inspect the original in various places  -->
<!-- We do not know if we have "fixed" the      -->
<!-- deprecated overall element, so need to     -->
<!-- try both.                                  -->
<xsl:variable name="original" select="/mathbook|/pretext"/>

<!-- These modal templates duplicate the source exactly for each -->
<!-- pass: elements, attributes, text, whitespace, comments,     -->
<!-- everything. Various other templates will override these     -->
<!-- templates to create a new enhanced source tree.             -->
<xsl:template match="node()|@*" mode="version">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="version"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="assembly">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="assembly"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="repair">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="language">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="language"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="augment">
    <xsl:param name="parent-struct" select="''"/>
    <xsl:param name="level" select="0"/>
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="augment">
            <xsl:with-param name="parent-struct" select="$parent-struct"/>
            <xsl:with-param name="level" select="$level"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="exercise">
    <xsl:param name="division" select="''"/>

    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="exercise">
            <xsl:with-param name="division" select="$division"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="representations">
    <xsl:param name="fn-subtree-number"/>
    <xsl:param name="fn-subtree"/>

    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="representations"/>
    </xsl:copy>
</xsl:template>

<!-- These templates initiate and create several iterations of -->
<!-- the source tree via modal templates.  Think of each as a  -->
<!-- "pass" through the source. Generally this constructs the  -->
<!-- new tree as a (text) result tree fragment and then we     -->
<!-- convert it into real XML nodes. These "real" trees have a -->
<!-- root element, as a result of the node-set() manufacture.  -->
<xsl:variable name="version-rtf">
    <xsl:call-template name="assembly-warnings"/>
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: start version</xsl:message>
    </xsl:if>
    <xsl:apply-templates select="/" mode="version"/>
    <!--  -->
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: end version</xsl:message>
    </xsl:if>
    <!--  -->
</xsl:variable>
<xsl:variable name="version" select="exsl:node-set($version-rtf)"/>

<xsl:variable name="assembly-rtf">
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: start assembly</xsl:message>
    </xsl:if>
    <!--  -->
    <xsl:apply-templates select="$version" mode="assembly"/>
    <!--  -->
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: end assembly</xsl:message>
    </xsl:if>
    <!--  -->
</xsl:variable>
<xsl:variable name="assembly" select="exsl:node-set($assembly-rtf)"/>

<xsl:variable name="repair-rtf">
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: start repair</xsl:message>
    </xsl:if>
    <!--  -->
    <xsl:apply-templates select="$assembly" mode="repair"/>
    <!--  -->
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: end repair</xsl:message>
    </xsl:if>
    <!--  -->
</xsl:variable>
<xsl:variable name="repair" select="exsl:node-set($repair-rtf)"/>

<!-- Once the "repair" tree is formed, any source modifications      -->
<!-- have been made, and it is on to *augmenting* the source.        -->
<!-- Various publisher variables are consulted for the augmentation, -->
<!-- notably the style/depth of numbering.  So this tree needs to    -->
<!-- be available for creating those variables, notably sensible     -->
<!-- defaults based on the source.  We refer to this tree as the     -->
<!-- "assembly" tree.                                                -->
<xsl:variable name="assembly-root" select="$repair/pretext"/>
<xsl:variable name="assembly-docinfo" select="$assembly-root/docinfo"/>
<xsl:variable name="assembly-document-root" select="$assembly-root/*[not(self::docinfo)]"/>

<xsl:variable name="language-rtf">
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: start language</xsl:message>
    </xsl:if>
    <!--  -->
    <xsl:apply-templates select="$repair" mode="language"/>
    <!--  -->
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: end language</xsl:message>
    </xsl:if>
    <!--  -->
</xsl:variable>
<xsl:variable name="language" select="exsl:node-set($language-rtf)"/>

<xsl:variable name="augment-rtf">
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: start augment</xsl:message>
    </xsl:if>
    <!--  -->
    <xsl:apply-templates select="$language" mode="augment"/>
    <!--  -->
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: end augment</xsl:message>
    </xsl:if>
    <!--  -->
</xsl:variable>
<xsl:variable name="augment" select="exsl:node-set($augment-rtf)"/>

<xsl:variable name="exercise-rtf">
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: start exercise</xsl:message>
    </xsl:if>
    <!--  -->
    <!-- initialize with default, 'inline' -->
    <xsl:apply-templates select="$augment" mode="exercise">
        <xsl:with-param name="division" select="'inline'"/>
    </xsl:apply-templates>
    <!--  -->
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: end exercise</xsl:message>
    </xsl:if>
    <!--  -->
</xsl:variable>
<xsl:variable name="exercise" select="exsl:node-set($exercise-rtf)"/>

<xsl:variable name="representations-rtf">
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: start representations</xsl:message>
    </xsl:if>
    <!--  -->
    <xsl:apply-templates select="$exercise" mode="representations"/>
    <!--  -->
    <xsl:if test="$time-assembly">
        <xsl:message><xsl:value-of select="date:date-time()"/>: end representations</xsl:message>
    </xsl:if>
    <!--  -->
</xsl:variable>
<xsl:variable name="representations" select="exsl:node-set($representations-rtf)"/>

<!-- The main "pretext" element only has two possible children      -->
<!-- One is "docinfo", the other is "book", "article", etc.         -->
<!-- This is of interest by itself, or the root of content searches -->
<!-- And docinfo is the other child, these help prevent searching   -->
<!-- the wrong half.                                                -->
<!-- NB: source repair below converts a /mathbook to a /pretext     -->
<xsl:variable name="root" select="$representations/pretext"/>
<xsl:variable name="docinfo" select="$root/docinfo"/>
<xsl:variable name="document-root" select="$root/*[not(self::docinfo)]"/>


<!-- ######################## -->
<!-- Bibliography Manufacture -->
<!-- ######################## -->

<!-- Initial experiment, overall "references" flagged with -->
<!-- a @source filename as the place to go get a list of   -->
<!-- candidate "biblio" (in desired order)                 -->
<!-- NB: this needs a rethink when revisited.  A file of   -->
<!-- bibliography items can be specified, perhaps in       -->
<!-- in docinfo (runs with the source?), formed as         -->
<!-- $biblios in -common, and then mined for matches not   -->
<!-- explicitly present?                                   -->
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
                        <xsl:when test="$target/statement|$target/task|$target/stage">
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
            <xsl:copy-of select="document($webwork-representations-file, $original)/webwork-representations/webwork-reps[@ww-id=$ww-id]" />
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
<!-- actual URL.  So "@visual" is a version of the URL that is pleasing to  -->
<!-- look at, maybe just a TLD, no protocol (e.g "https://"), no "www."     -->
<!-- if unnecessary, etc.  Here it becomes a special variant of a footnote, -->
<!-- which allows for numbering and special-handling in LaTeX, based        -->
<!-- strictly on the element itself.  But placing the URL in an attribute   -->
<!-- signals this is an exceptional footnote, so the URL can be handled     -->
<!-- specially, say in a monospace font, or in the LaTeX case, treatment    -->
<!-- like \nolinkurl{}. This is great in print, and is a knowl in HTML.     -->
<!--                                                                        -->
<!-- Advantages: however a conversion does footnotes, this will be the      -->
<!-- right markup for that conversion.  Note that LaTeX pulls footnotes     -->
<!-- out of "tcolorbox" environments, which is based on the *context*,      -->
<!-- so a result-tree fragment implementation is doomed to fail.            -->
<!--                                                                        -->
<!-- N.B.  We are only interpreting the "content" form here by simply       -->
<!-- adding the footnote element.  This leaves various decisions about      -->
<!-- formatting to the subsequent conversion.                               -->

<xsl:template match="url[node()]" mode="repair">
    <xsl:copy>
        <!-- we drop the @visual attribute, a decision we might revisit -->
        <xsl:apply-templates select="node()|@*[not(local-name(.) = 'visual')]" mode="repair"/>
    </xsl:copy>
    <xsl:choose>
        <!-- deprecated, force the issue using @href -->
        <xsl:when test="not(@visual)">
            <fn pi:url="{@href}"/>
        </xsl:when>
        <!-- explicitly opt-out, so no footnote -->
        <xsl:when test="@visual = ''"/>
        <!-- go for it, as requested by author -->
        <xsl:otherwise>
            <fn pi:url="{@visual}"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ############# -->
<!-- Source Repair -->
<!-- ############# -->

<!-- We unilaterally make various changes to an author's source -->
<!-- so a conversion (every conversion?) can assume more        -->
<!-- accurately that the source has certain characteristics.    -->

<!-- 2019-04-02  "mathbook" replaced by "pretext" -->
<xsl:template match="/mathbook" mode="repair">
    <pretext>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </pretext>
</xsl:template>

<!-- 2021-07-02 wrap notation/usage in "m" if not present -->
<xsl:template match="notation/usage[not(m)]" mode="repair">
    <!-- duplicate "usage" w/ attributes, insert "m" as repair -->
    <usage>
        <xsl:apply-templates select="@*" mode="repair"/>
        <m>
            <xsl:apply-templates select="node()|@*" mode="repair"/>
        </m>
    </usage>
</xsl:template>

<!-- 2021-10-04 "glossary" was finalized, so old-style preserved -->

<!-- glossary introductions become headnotes -->
<xsl:template match="glossary/introduction" mode="repair">
    <headnote>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </headnote>
</xsl:template>

<!-- "terms" only ever had "defined-term" as children    -->
<!-- and is now obsolete, so dropped as excess structure -->
<xsl:template match="glossary/terms" mode="repair">
    <xsl:apply-templates select="defined-term" mode="repair"/>
</xsl:template>

<!-- "defined-term" was structured, so we just select elements -->
<xsl:template match="glossary/terms/defined-term" mode="repair">
    <gi>
        <xsl:apply-templates select="*|@*" mode="repair"/>
    </gi>
</xsl:template>

<!-- no more "conclusion", so drop it here; deprecation will warn -->
<xsl:template match="glossary/conclusion" mode="repair"/>

<!-- 2022-04-22 replace Python Tutor with Runestone CodeLens -->
<xsl:template match="program/@interactive" mode="repair">
    <xsl:choose>
        <xsl:when test=". = 'pythontutor'">
            <xsl:attribute name="interactive">
                <xsl:text>codelens</xsl:text>
            </xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
            <xsl:copy/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- 2022-04-25 @label deprecated, slated for renewal in starring  -->
<!-- role. Lists with markers (not description lists) -->
<xsl:template match="ol/@label|ul/@label" mode="repair">
    <xsl:attribute name="marker">
        <xsl:value-of select="."/>
    </xsl:attribute>
</xsl:template>

<!-- 2022-04-24 An exception, label on video tracks mimicing HTML -->
<xsl:template match="video/track/@label" mode="repair">
    <xsl:attribute name="listing">
        <xsl:value-of select="."/>
    </xsl:attribute>
</xsl:template>


<!-- ######### -->
<!-- Languages -->
<!-- ######### -->

<!-- The variable $locales is a node-set of all the locales which have    -->
<!-- supported localization files.  A comparison of an @xml:lang (string) -->
<!-- with $locales (node-set) will be true if the attribute value is a    -->
<!-- string value of one of the nodes in the node-set.  So it is easy to  -->
<!-- create a boolean value for localization support .                    -->
<xsl:variable name="locales" select="document('localizations/localizations.xml')/localizations/locale" />

<!-- We want the root node to always have full and accurate language         -->
<!-- information since it will be the fail-safe node on a query up the tree. -->
<!-- Earlier "repair" pass eliminates "mathbook".                            -->
<xsl:template match="/pretext" mode="language">
    <!-- see above description of $locales, false if missing -->
    <xsl:variable name="b-is-supported" select="@xml:lang = $locales"/>
    <!-- duplicate with better language information -->
    <xsl:copy>
        <xsl:apply-templates select="@*" mode="language"/>
        <xsl:choose>
            <xsl:when test="$b-is-supported">
                <!-- if supported, it was just duplicated, save off a -->
                <!-- new attribute indicating use for localizations   -->
                <xsl:attribute name="locale-lang">
                    <xsl:value-of select="@xml:lang"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <!-- if missing we add the default          -->
                <!-- if unsupported, overwrite with default -->
                <xsl:attribute name="xml:lang">
                    <xsl:text>en-US</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="locale-lang">
                    <xsl:text>en-US</xsl:text>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="node()" mode="language"/>
    </xsl:copy>
</xsl:template>

<!-- An  @xml:id  is checked to see if it is supported for localizations.  -->
<!-- If so, we augment the elment with an internal attribute.  If not,     -->
<!-- we just leave a copy alone, it might be relevant for future features. -->
<xsl:template match="*[@xml:lang]" mode="language">
    <!-- see above description of $locales -->
    <xsl:variable name="b-is-supported" select="@xml:lang = $locales"/>
    <!-- duplicate with additional language information -->
    <xsl:copy>
        <xsl:apply-templates select="@*" mode="language"/>
        <xsl:if test="$b-is-supported">
            <xsl:attribute name="locale-lang">
                <xsl:value-of select="@xml:lang"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="node()" mode="language"/>
    </xsl:copy>
</xsl:template>

<!-- ######## -->
<!-- Versions -->
<!-- ######## -->

<xsl:template match="*" mode="version">
    <xsl:choose>
        <!-- version scheme not elected, so use element no matter what -->
        <xsl:when test="$components-fenced = ''">
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="version"/>
            </xsl:copy>
        </xsl:when>
        <!-- version scheme elected, but element not participating, -->
        <!-- so a 100% un-tagged element is included by default     -->
        <xsl:when test="not(@component)">
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="version"/>
            </xsl:copy>
        </xsl:when>
        <!-- version scheme elected, element participating, so use element -->
        <!-- if it is a component in publisher's selection of components   -->
        <xsl:when test="@component">
            <xsl:variable name="single-component-fenced" select="concat('|', normalize-space(@component), '|')"/>
            <xsl:if test="contains($components-fenced, $single-component-fenced)">
                <xsl:copy>
                    <xsl:apply-templates select="node()|@*" mode="version"/>
                </xsl:copy>
            </xsl:if>
            <!-- scheme in publisher file, element tagged,    -->
            <!-- but not elected, hence element dropped here  -->
        </xsl:when>
        <!-- previous two "when" mutually-exclusive, -->
        <!-- thus we should not ever reach here      -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:template>

<!-- ######### -->
<!-- Numbering -->
<!-- ######### -->

<!-- We use the "augment" pass to compute, and add, partially naïve        -->
<!-- information about numbers of objects, to be interpreted later by      -->
<!-- templates in the "-common" stylesheet.  By "naïve" we mean that       -->
<!-- these routines may depend on publisher variables (e.g. specification  -->
<!-- of roots of subtrees for serial numbers of blocks) but do not depend  -->
<!-- on subtlties of numbering (such as the structured/unstructured        -->
<!-- division dichotomy), which are addressed in the "-common" stylesheet. -->
<!-- In this way, this information could be interpreted in new ways by     -->
<!-- additional conversions.                                               -->
<!--                                                                       -->
<!-- The manufactured @struct attribute is the (naïve) hierarchical number -->
<!-- of the *container* of an element, known as the "structure number"     -->
<!-- of an element.  The @serial attribute is the computed serial number   -->
<!-- of the element, known as the "serial number".  Typically combining    -->
<!-- these two attributes forms teh number of an element.  As many         -->
<!-- practical subtleties about these numbers is delayed until their       -->
<!-- interpretation by templates in the "-common" stylesheet.              -->

<!-- For every type of division, everywhere, the "division-serial-number"   -->
<!-- modal template will return a count of preceding peers at that level.   -->
<!-- The @struct attribute is the structure number of the *parent*          -->
<!-- (container), which seems odd here, but fits the general scheme better. -->
<!-- The @level attribute is helpful, and trvislly to compute here.         -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|exercises|solutions|reading-questions|references|glossary|worksheet" mode="augment">
    <xsl:param name="parent-struct"/>
    <xsl:param name="level"/>

    <xsl:variable name="the-serial">
        <xsl:apply-templates select="." mode="division-serial-number"/>
    </xsl:variable>
    <xsl:variable name="new-struct">
        <xsl:choose>
            <!-- Parts as Roman numerals make for a lot of clutter.      -->
            <!-- We tend to only use them when necessary to diambiguate  -->
            <!-- a cross-reference in the case where these numbers are   -->
            <!-- structural.  So rightly or wrongly, and owing to        -->
            <!-- historical work, we squelch them as the lead item of a  -->
            <!-- structural number.  So here the Roman numeral will be   -->
            <!-- preserved as a serial number, but the construction of   -->
            <!-- the structural numbers will be delayed one level.       -->
            <!-- (It seems harder to strip these in -common.)            -->
            <xsl:when test="self::part"/>
            <xsl:otherwise>
                <xsl:value-of select="$parent-struct"/>
                <xsl:if test="not($parent-struct='')">
                    <xsl:text>.</xsl:text>
                </xsl:if>
                <xsl:value-of select="$the-serial"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="next-level" select="$level + 1"/>
    <xsl:copy>
        <xsl:attribute name="struct">
            <xsl:value-of select="$parent-struct"/>
        </xsl:attribute>
        <xsl:attribute name="serial">
            <xsl:value-of select="$the-serial"/>
        </xsl:attribute>
        <xsl:attribute name="level">
            <xsl:value-of select="$next-level"/>
        </xsl:attribute>
        <xsl:apply-templates select="node()|@*" mode="augment">
            <xsl:with-param name="parent-struct" select="$new-struct"/>
            <xsl:with-param name="level" select="$next-level"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<!-- See the definitions of levels in -common.  For a book with parts   -->
<!-- ($parts != 'absent') we consider parts as peers of frontmatter and -->
<!-- backmatter.  So we need to increment the level in this case, only. -->
<!-- NB: this might consolidate with above, but seems better solo.      -->
<!-- NB: with some study and work, this situation might be improved?    -->
<xsl:template match="frontmatter|backmatter" mode="augment">
    <xsl:param name="parent-struct"/>
    <xsl:param name="level"/>

    <xsl:variable name="next-level">
        <xsl:choose>
            <xsl:when test="($parts = 'decorative') or ($parts = 'structural')">
                <xsl:value-of select="$level + 1"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$level"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- we only add a level (not necessary?) -->
    <!-- and just pass along structure number -->
    <xsl:copy>
        <xsl:attribute name="level">
            <xsl:value-of select="$next-level"/>
        </xsl:attribute>
        <xsl:apply-templates select="node()|@*" mode="augment">
            <xsl:with-param name="parent-struct" select="$parent-struct"/>
            <xsl:with-param name="level" select="$next-level"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<!-- ######### -->
<!-- Exercises -->
<!-- ######### -->

<!-- Exercises, and their kin, are complicated.  They come in five types   -->
<!-- (inline, divisional, reading, worksheet, project-like) based largely  -->
<!-- on location.  They can be static, interactive in HTML, interactive    -->
<!-- on a server.  Interactive versions come in many flavors, such as      -->
<!-- short answer, multiple choice, true/false, Parson, matching, fill-in, -->
<!-- and so on.  Their solutions (hint, answer, solution) apear, or do not -->
<!-- appear, where born or in specialized "solutions" divisions.  We       -->
<!-- scribble on each to record as much as we can right now.  It'll be     -->
<!-- useful below and forever.                                             -->

<!-- Record exercise ancestors/location-->
<!-- An "exercise" can be in one of four places.  We reset the parameter   -->
<!-- as we pass through.  Default is "inline" and we initialize with that  -->
<!-- value.  These three specialized divisions are always terminal, so we  -->
<!-- will never find an inline exercise contained within.  We allow        -->
<!-- publisher customization of exercises based on these locations, *and*  -->
<!-- for project-like.  These templates are just about divisions.          -->

<xsl:template match="reading-questions" mode="exercise">
    <xsl:param name="division"/>

    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="exercise">
            <xsl:with-param name="division" select="'reading'"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<xsl:template match="worksheet" mode="exercise">
    <xsl:param name="division"/>

    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="exercise">
            <xsl:with-param name="division" select="'worksheet'"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<xsl:template match="exercises" mode="exercise">
    <xsl:param name="division"/>

    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="exercise">
            <xsl:with-param name="division" select="'divisional'"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<!-- Annotate "exercise" and PROJECT-LIKE -->
<!-- Pre-processing here is entirely about supporting interactive       -->
<!-- exercises powered by Runestone Services.  We allow publisher       -->
<!-- options to control interactivity of "short answer" questions       -->
<!-- when hosted on a server, so that is why locations are being noted. -->
<!--   1.  "exercise-customization" refers to the situation where       -->
<!--       certain publication options can vary behavior or visibility  -->
<!--   2.  "exercise-interactive" refers to the type of                 -->
<!--        interactivity, "static" is the default                      -->
<!--                                                                    -->
<!-- TODO:                                                              -->
<!-- 1.  Expand to WW, example-like, and task                           -->
<!-- 2.  Insert "statement" when not authored                           -->
<!-- 3.  Use locations computed here, remove elsewhere                  -->

<xsl:template match="exercise|&PROJECT-LIKE;" mode="exercise">
    <xsl:param name="division"/>

    <xsl:copy>
        <!-- Record one of five categories for customization, which    -->
        <!-- are not relevant for "example" (always inline), or "task" -->
        <!-- (always just a component of something larger).  WeBWork   -->
        <!-- problems are interactive or static, inline or not, based  -->
        <!-- on publisher options.                                     -->
        <xsl:attribute name="exercise-customization">
            <xsl:choose>
                <xsl:when test="&PROJECT-FILTER;">
                    <xsl:text>project</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$division"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <!-- Determine and record types of interactivity, partially based   -->
        <!-- on location due to publisher options for "short answer" (only) -->
        <xsl:apply-templates select="." mode="exercise-interactive-attribute">
            <xsl:with-param name="division" select="$division"/>
        </xsl:apply-templates>
        <!-- catch remaining attributes -->
        <xsl:apply-templates select="@*" mode="exercise">
            <xsl:with-param name="division" select="$division"/>
        </xsl:apply-templates>
        <!-- Now the child elements -->
        <!-- NB: this would be a place to insert a "statement" for  -->
        <!-- "exercise", "example", "project" and "task", for which -->
        <!-- an author has not needed/elected to use one.           -->
        <xsl:apply-templates select="node()" mode="exercise">
            <xsl:with-param name="division" select="$division"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<!-- These "interactivity types" are meant for Runestone-enabled  -->
<!-- interactive exercises and projects                           -->
<xsl:template match="*" mode="exercise-interactive-attribute">
    <xsl:param name="division"/>

    <xsl:attribute name="exercise-interactive">
        <xsl:choose>
            <!-- hack for temporary demo HTML versions -->
            <xsl:when test="@runestone">
                <xsl:text>htmlhack</xsl:text>
            </xsl:when>
            <!-- true/false -->
            <xsl:when test="statement/@correct">
                <xsl:text>truefalse</xsl:text>
            </xsl:when>
            <!-- multiple choice -->
            <xsl:when test="statement and choices">
                <xsl:text>multiplechoice</xsl:text>
            </xsl:when>
            <xsl:when test="statement and blocks">
                <xsl:text>parson</xsl:text>
            </xsl:when>
            <xsl:when test="statement and matches">
                <xsl:text>matching</xsl:text>
            </xsl:when>
            <xsl:when test="statement and areas">
                <xsl:text>clickablearea</xsl:text>
            </xsl:when>
            <xsl:when test="statement//var and not(webwork)">
                <xsl:text>fillin-basic</xsl:text>
            </xsl:when>
            <xsl:when test="statement and program">
                <xsl:text>coding</xsl:text>
            </xsl:when>
            <!-- Now we have what once would have been called a "traditional"     -->
            <!-- PreTeXt question, which is just "statement|hint|answer|solution" -->
            <!-- (perhaps after a bit of preprocessing.  More accurately, these   -->
            <!-- are "short answer", "essay", or "free response".  We have allow  -->
            <!-- these to be interactive (or not) for a capable platform.         -->
            <!-- Conveniently, we have the cusomization types in the $division    -->
            <!-- parameter. This only matters when we are on a Runestone server.  -->
            <xsl:when test="$b-host-runestone">
                <xsl:choose>
                    <xsl:when test="($division = 'inline') and $b-sa-inline-dynamic">
                        <xsl:text>shortanswer</xsl:text>
                    </xsl:when>
                    <xsl:when test="($division = 'divisional') and $b-sa-divisional-dynamic">
                        <xsl:text>shortanswer</xsl:text>
                    </xsl:when>
                    <xsl:when test="($division = 'reading') and $b-sa-reading-dynamic">
                        <xsl:text>shortanswer</xsl:text>
                    </xsl:when>
                    <xsl:when test="($division = 'worksheet') and $b-sa-worksheet-dynamic">
                        <xsl:text>shortanswer</xsl:text>
                    </xsl:when>
                    <xsl:when test="($division = 'project') and $b-sa-project-dynamic">
                        <xsl:text>shortanswer</xsl:text>
                    </xsl:when>
                    <!-- examples are never assesments                -->
                    <!-- maybe WeBWork will someday be on a RS server -->
                    <xsl:otherwise>
                        <xsl:text>static</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- That's it, we are out of opportunities to be interactive -->
            <xsl:otherwise>
                <xsl:text>static</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:attribute>
</xsl:template>


<!-- ############### -->
<!-- Representations -->
<!-- ############### -->

<!-- Build multiple (two) representations of exercises that are produced  -->
<!-- in static (almost everything) and dynamic (HTML) versions.            -->
<!-- Generally these templates are parameterized by the $exercise-style   -->
<!-- variable/parameter.  We need the parameterization, since we do not   -->
<!-- want to make *multiple* copies of each exercise in the source, since -->
<!-- then duplicate items might confuse later templates e.g numbering).   -->
<!--                                                                      -->
<!-- A "static" version should be entirely in the style of a "regular"    -->
<!-- PreTeXt exercise, having a statement|hint|answer|solution structure. -->
<!-- Then it can be leveraged through all the infrastructure for things   -->
<!-- like solutions manuals and non-capable output formats.               -->
<!--                                                                      -->
<!-- A "dynamic" version is simply a duplicate of the author's source,    -->
<!-- which is handled by templates elsewhere, applied in the HTML         -->
<!-- conversion itself.                                                   -->

<!-- Hacked -->
<!-- Will eventually be obsolete -->

<xsl:template match="exercise[@exercise-interactive = 'htmlhack']" mode="representations">
    <xsl:choose>
        <xsl:when test="$exercise-style = 'static'">
            <!-- punt for static versions, we have nothing -->
            <exercise>
                <statement>
                    <p>An interactive Runestone problem goes here, but there is not yet a static representation.</p>
                </statement>
            </exercise>
        </xsl:when>
        <xsl:when test="$exercise-style = 'dynamic'">
            <!-- pass on to the HTML conversion -->
            <xsl:copy-of select="."/>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- True/False        -->
<!-- Multiple Choice   -->
<!-- Parson problems   -->
<!-- Matching problems -->
<!-- Clickable Area    -->
<!-- ActiveCode        -->

<xsl:template match="exercise[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'coding')]
                              |project[@exercise-interactive = 'coding']
                              |activity[@exercise-interactive = 'coding']
                              |exploration[@exercise-interactive = 'coding']
                              |investigation[@exercise-interactive = 'coding']" mode="representations">
    <!-- always preserve "exercise" container, with attributes -->
    <xsl:copy>
        <xsl:apply-templates select="@*" mode="representations"/>
        <xsl:choose>
            <!-- make a static version, in a PreTeXt   -->
            <!-- statement|hint|answer|solution style  -->
            <!-- for use naturally by most conversions -->
            <xsl:when test="$exercise-style = 'static'">
                <xsl:apply-templates select="." mode="runestone-to-static"/>
            </xsl:when>
            <!-- duplicate for a dynamic version -->
            <xsl:when test="$exercise-style = 'dynamic'">
                <xsl:apply-templates select="node()" mode="representations"/>
            </xsl:when>
        </xsl:choose>
    </xsl:copy>
</xsl:template>

<!-- Short Answer -->
<!-- @exercise-interactive = 'shortanswer' needs no adjustments -->

<!-- Static (non-interactive) -->
<!-- @exercise-interactive = 'static' needs no adjustments -->


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
                <xsl:when test="$target/statement|$target/task|$target/stage"/>
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
                    <xsl:message>             points to a WeBWorK problem that does not have a statement, task, or stage.</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>
