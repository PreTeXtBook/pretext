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
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:pf="https://prefigure.org"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl date str"
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
<!--   the new $version source tree by *removing* source.  It also -->
<!--   resolves "custom" elements.  If these two features have     -->
<!--   been used properly by an author, then the result should be  -->
<!--   valid PreTeXt (when perhaps the authored source was not).   -->
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
<!--  -->
<!-- Note too, that we want this stylesheet to be independent, and -->
<!-- that can be tested with the  pretext-enhanced-source.xsl      -->
<!-- stylesheet.  There is one danger: any (modal) template        -->
<!-- applied here, needs to be defined here.  "Normal" conversions -->
<!-- will import things like "pretext-common.xsl" and templates    -->
<!-- defined there will be available.  But when not defined here,  -->
<!-- the default is to just apply default templates to the         -->
<!-- content, which may generally just produce a lot of text.      -->
<!-- Which is no good, say as an attribute value.                  -->

<!-- Isolate computation of numbers -->
<xsl:import href="./pretext-numbers.xsl"/>
<!-- Isolate conversion of Runestone/interactive to PreTeXt/static -->
<xsl:import href="./pretext-runestone-static.xsl"/>

<!-- We explicitly do not import "pretext-common.xsl" as we want    -->
<!-- this important pre-processing stylesheet to have no hidden     -->
<!-- dependencies.  In almost every rational use, the "-common"     -->
<!-- stylesheet is imported by a conversion, so it is easy to       -->
<!-- miss these dependencies.  An example in 2022-06 was the use    -->
<!-- of the "visible-id" template to coordinate construction and    -->
<!-- insertion of WeBWorK problems with an intervening trip to a    -->
<!-- WW server.  The "pretext-enhanced-source.xsl" stylesheet is    -->
<!-- one place where "-common" does not creep in.  Use of a modal   -->
<!-- template here, with a definition in -common, will do a         -->
<!-- massive "value-of" when not defined for the "-enhanced-source" -->
<!-- stylesheet, which might be detectable (in strange ways).       -->

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
<!--   * 'pg-problems' are WeBWork problems for an archive               -->
<!--   * If testing, the pretext-enhanced-source.xsl  stylesheet will    -->
<!--     need a stringparam override to view and test dynamic versions.  -->
<xsl:variable name="exercise-style" select="'static'"/>

<!-- Short-Circuit -->
<!-- Sometimes we only want to convert to a "version" (valid PreTeXt) via -->
<!-- the resolution of version support and customizations.  Examples are  -->
<!-- determining publisher variables (for generating something like LaTeX -->
<!-- images, when we do not process the whole source) or performiong      -->
<!-- validation.  We control this with an internal variable, which is not -->
<!-- documented as an author or publisher feature.  When we select only   -->
<!-- the production of the "version" tree, the choice of "exercise-style" -->
<!-- is irrelevant.                                                       -->

<!-- default is empty, so we ccan detect non-use -->
<xsl:param name="assembly.version-only" select="''"/>

<!-- onvert to a boolean, with error-checking -->
<xsl:variable name="version-only">
    <xsl:choose>
        <xsl:when test="$assembly.version-only = ''">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <xsl:when test="$assembly.version-only = 'yes'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:when test="$assembly.version-only = 'no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:BUG:  the internal parameter  assembly.version-only  received an unrecognized value of "<xsl:value-of select="$assembly.version-only"/>" (possible values are "yes" and "no")</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="b-version-only" select="$version-only = 'yes'"/>

<!-- ############################## -->
<!-- Source Assembly Infrastructure -->
<!-- ############################## -->

<!-- When building duplicates, we have occasion -->
<!-- to inspect the original in various places  -->
<!-- We do not know if we have "fixed" the      -->
<!-- deprecated overall element, so need to     -->
<!-- try both.  For example, this variable is   -->
<!-- employed by the warnings and deprecation   -->
<!-- messages that result from analyzing an     -->
<!-- author's source, since we may "repair"     -->
<!-- some of them later, so we have to catch    -->
<!-- them early. -->
<xsl:variable name="original" select="/mathbook|/pretext"/>

<!-- These modal templates duplicate the source exactly for each -->
<!-- pass: elements, attributes, text, whitespace, comments,     -->
<!-- everything. Various other templates will override these     -->
<!-- templates to create a new enhanced source tree.             -->

<xsl:template match="node()|@*" mode="private-solutions">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="private-solutions"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="version">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="version"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="webwork">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="webwork"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="assembly">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="assembly"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="dynamic-substitution">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="dynamic-substitution"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="representations">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="representations"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="repair">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="enrichment">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="enrichment"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="labels">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="labels"/>
    </xsl:copy>
</xsl:template>

<!-- Later, this template only *adds* an attribute to an element -->
<!-- it is copying over to the result tree.  Here we copy text   -->
<!-- nodes and the other attributes and the parameters are not   -->
<!-- needed.  This is a general-purpose template, see comments   -->
<!-- at further definition for elements.                         -->
<xsl:template match="node()|@*" mode="id-attribute">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="id-attribute"/>
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
    <xsl:param name="ordered-list-level" select="0"/>

    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="augment">
            <xsl:with-param name="parent-struct" select="$parent-struct"/>
            <xsl:with-param name="level" select="$level"/>
            <xsl:with-param name="ordered-list-level" select="$ordered-list-level"/>
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

<!-- These templates initiate and create several iterations of -->
<!-- the source tree via modal templates.  Think of each as a  -->
<!-- "pass" through the source. Generally this constructs the  -->
<!-- new tree as a (text) result tree fragment and then we     -->
<!-- convert it into real XML nodes. These "real" trees have a -->
<!-- root element, as a result of the node-set() manufacture.  -->

<!-- Grab private solutions first.  The "exercise" (and more) -->
<!-- that they belong to might be part of a version (have a   -->
<!-- @component attribute) and we don't want to miss that.    -->
<!-- It can happen next.                                      -->
<xsl:variable name="private-solutions-rtf">
    <xsl:apply-templates select="/" mode="private-solutions"/>
</xsl:variable>
<xsl:variable name="private-solutions" select="exsl:node-set($private-solutions-rtf)"/>

<xsl:variable name="version-rtf">
    <xsl:apply-templates select="$private-solutions" mode="version"/>
</xsl:variable>
<xsl:variable name="version" select="exsl:node-set($version-rtf)"/>

<!-- The "version" tree should be valid PreTeXt.  Furthermore, there -->
<!-- should not be anymore modifactions in subsequent passes which   -->
<!-- change the gross structure of a document (i.e. nature of the    -->
<!-- divisions).  The determination of various pubisher variables,   -->
<!-- mostly relative to numbering depth, have default values that    -->
<!-- depend on the structure.  So aspects of this tree are consulted -->
<!-- frequently in  publisher-variables.xsl.                         -->
<!-- Also, note that this tree is useful for certain tasks, like     -->
<!-- validation, or reporting values of publisher variables, without -->
<!-- regard to the subsequent passes.                                -->
<xsl:variable name="version-root" select="$version/pretext"/>
<xsl:variable name="version-docinfo" select="$version-root/docinfo"/>
<xsl:variable name="version-document-root" select="$version-root/*[not(self::docinfo)]"/>

<!-- This pass adds 100% internal identification for elements before   -->
<!-- anything has been added or subtracted. The tree it builds is used -->
<!-- for constructing "View Source" knowls in HTML output as a form of -->
<!-- always-accurate documentation.  And this is its only purpose.     -->
<!-- N.B.: see the $original-labeled tree used in the HTML conversion, -->
<!-- optionally, under the sway of a string parameter.  This is in the -->
<!-- (imported) pretext-view-source.xsl stylesheet.                    -->
<!-- Hack: to short-circuit this stylesheet, in the case of desiring   -->
<!-- the "version" tree *only*, we create an empty RTF.  This becomes  -->
<!-- a (essentially) empty node-set.  The empty node-set is the input  -->
<!-- the next pass, which will create an empty RTF, which will create  -->
<!-- an empty node-set.  Rinse.  Repeat.  Even though all these        -->
<!-- passes/variables are created, this is about a 17x speed-up.       -->
<!-- A review suggests there is no fixed overhead in any of these      -->
<!-- subsequent passes.                                                -->
<xsl:variable name="original-labeled-rtf">
    <!-- written as a "choose" for clarity -->
    <xsl:choose>
        <!-- short-circuit to stop after "version" -->
        <xsl:when test="$b-version-only"/>
        <!-- build on "version" to add original id's -->
        <xsl:otherwise>
            <xsl:apply-templates select="$version" mode="id-attribute">
                <!-- $parent-id defaults to 'root' in template -->
                <xsl:with-param name="attr-name" select="'original-id'"/>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="original-labeled" select="exsl:node-set($original-labeled-rtf)"/>

<!-- A global list of all "webwork" used for       -->
<!-- efficient backward-compatible indentification -->
<xsl:variable name="all-webwork" select="$original-labeled//webwork"/>

<xsl:variable name="webwork-rtf">
    <xsl:apply-templates select="$original-labeled" mode="webwork"/>
</xsl:variable>
<xsl:variable name="webworked" select="exsl:node-set($webwork-rtf)"/>

<xsl:variable name="assembly-rtf">
    <xsl:apply-templates select="$webworked" mode="assembly"/>
</xsl:variable>
<xsl:variable name="assembly" select="exsl:node-set($assembly-rtf)"/>

<!-- Make static substitutions for dynamic exercises.  -->
<xsl:variable name="dynamic-rtf">
    <xsl:apply-templates select="$assembly" mode="dynamic-substitution"/>
</xsl:variable>
<xsl:variable name="dynamic" select="exsl:node-set($dynamic-rtf)"/>

<!-- Exercises are "tagged" as to their nature (division, inline, -->
<!-- worksheet, reading, project-like) and interactive exercises  -->
<!-- get more precise categorization.  The latter is used to      -->
<!-- determine if Runestone Services are loaded.                  -->

<xsl:variable name="exercise-rtf">
    <!-- initialize with default, 'inline' -->
    <xsl:apply-templates select="$dynamic" mode="exercise">
        <xsl:with-param name="division" select="'inline'"/>
    </xsl:apply-templates>
</xsl:variable>
<xsl:variable name="exercise" select="exsl:node-set($exercise-rtf)"/>

<xsl:variable name="assembly-label-rtf">
    <xsl:apply-templates select="$exercise" mode="id-attribute">
        <!-- $parent-id defaults to 'root' in template -->
        <xsl:with-param name="attr-name" select="'assembly-id'"/>
    </xsl:apply-templates>
</xsl:variable>
<xsl:variable name="assembly-label" select="exsl:node-set($assembly-label-rtf)"/>

<xsl:variable name="representations-rtf">
    <xsl:apply-templates select="$assembly-label" mode="representations"/>
</xsl:variable>
<xsl:variable name="representations" select="exsl:node-set($representations-rtf)"/>

<!-- Dependency: "repair" will fix some exercise representations, -->
<!-- especially coming from an "old" WeBWorK server, so the       -->
<!-- "repair" pass must come after the "representations" pass.    -->
<xsl:variable name="repair-rtf">
    <xsl:apply-templates select="$representations" mode="repair"/>
</xsl:variable>
<xsl:variable name="repair" select="exsl:node-set($repair-rtf)"/>

<!-- "enrichment" will *add* to the source automatically,  -->
<!-- such as footnotes with URLs that might not be visible -->
<!-- in static formats.                                    -->
<xsl:variable name="enrichment-rtf">
    <xsl:apply-templates select="$repair" mode="enrichment"/>
</xsl:variable>
<xsl:variable name="enrichment" select="exsl:node-set($enrichment-rtf)"/>

<!-- 2024-02-08: the construction of @label from @xml:id was split  -->
<!-- out of the "identification" pass, so is located here.  Perhaps -->
<!-- it can/should move earlier, maybe not.                         -->
<xsl:variable name="labels-rtf">
    <!-- pass in all elements with authored @xml:id -->
    <!-- to look for authored duplicates            -->
    <xsl:call-template name="duplication-check-xmlid">
        <xsl:with-param name="nodes" select="$enrichment//*[@xml:id]"/>
        <xsl:with-param name="purpose" select="'authored'"/>
    </xsl:call-template>
    <!-- pass in all elements with authored @label -->
    <!-- to look for authored duplicates           -->
    <xsl:call-template name="duplication-check-label">
        <xsl:with-param name="nodes" select="$enrichment//*[@label]"/>
        <xsl:with-param name="purpose" select="'authored'"/>
    </xsl:call-template>
    <xsl:apply-templates select="$enrichment" mode="labels"/>
</xsl:variable>
<xsl:variable name="labels" select="exsl:node-set($labels-rtf)"/>

<xsl:variable name="identification-rtf">
    <xsl:apply-templates select="$labels" mode="id-attribute">
        <!-- $parent-id defaults to 'root' in template -->
        <xsl:with-param name="attr-name" select="'unique-id'"/>
    </xsl:apply-templates>
</xsl:variable>
<xsl:variable name="identification" select="exsl:node-set($identification-rtf)"/>

<xsl:variable name="language-rtf">
    <xsl:apply-templates select="$identification" mode="language"/>
</xsl:variable>
<xsl:variable name="language" select="exsl:node-set($language-rtf)"/>

<xsl:variable name="augment-rtf">
    <xsl:apply-templates select="$language" mode="augment"/>
</xsl:variable>
<xsl:variable name="augment" select="exsl:node-set($augment-rtf)"/>

<!--                        IMPORTANT                           -->
<!--                                                            -->
<!-- Definitions that follow may be overridden after additional -->
<!-- per-conversion passes that takeoff from the final tree,    -->
<!-- here $augment.                                             -->
<!--                                                            -->
<!--    IF $augment CHANGES, SEARCH FOR AFFECTED CONVERSIONS    -->
<!--                                                            -->
<!-- 2023-03-20: braille conversion incorporares Nemeth braille -->

<!-- The main "pretext" element only has two possible children      -->
<!-- One is "docinfo", the other is "book", "article", etc.         -->
<!-- This is of interest by itself, or the root of content searches -->
<!-- And docinfo is the other child, these help prevent searching   -->
<!-- the wrong half.                                                -->
<!-- NB: source repair below converts a /mathbook to a /pretext     -->
<xsl:variable name="root" select="$augment/pretext"/>
<xsl:variable name="docinfo" select="$root/docinfo"/>
<xsl:variable name="document-root" select="$root/*[not(self::docinfo)]"/>
<xsl:variable name="bibinfo" select="$document-root/frontmatter/bibinfo"/>


<!-- ################# -->
<!-- Private Solutions -->
<!-- ################# -->

<!-- "solutions" here refers generically to "hint", "answer",  -->
<!-- and "solution" elements of an "exercise".  An author may  -->
<!-- wish to provide limited distribution of some solutions to -->
<!-- exercises, which we deem "private" here.  If a            -->
<!-- "private-solutions-file" is provided, it will be mined    -->
<!-- for these private solutions.                              -->

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

<!-- Note that when there are any private solutions then we make a copy that     -->
<!--   - does not preserve interstitial text nodes (whitespace indentation)      -->
<!--   - preserves things like "feedback", "choices", but may reorder them       -->
<!--     to occur before solutions                                               -->
<!--   - this happens for *every* "exercise", even if it does not have           -->
<!--     private solutions                                                       -->
<!--                                                                             -->
<!-- So there could be                                                           -->
<!--   - more care about placing new "hint", "answer", "solution"                -->
<!--     in the right order, perhaps by exploding this out into templates        -->
<!--   - condition on                                                            -->
<!--     $n-hint[@ref=$the-id]|$n-answer[@ref=$the-id]|$n-solution[@ref=$the-id] -->
<!--     to only manipulate an exercise that needs it                            -->
<xsl:template match="exercise|task" mode="private-solutions">
    <xsl:choose>
        <!-- $b-private-solutions is a publisher variable determined   -->
        <!-- by the specification of a file of private solutions there -->
        <xsl:when test="$b-private-solutions">
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
                <xsl:apply-templates select="*[not(self::hint or self::answer or self::solution)]|@*" mode="private-solutions"/>
                <!-- hints, answers, solutions; first regular, second private -->
                <xsl:apply-templates select="hint" mode="private-solutions"/>
                <xsl:apply-templates select="$n-hint[@ref=$the-id]" mode="private-solutions"/>
                <xsl:apply-templates select="answer" mode="private-solutions"/>
                <xsl:apply-templates select="$n-answer[@ref=$the-id]" mode="private-solutions"/>
                <xsl:apply-templates select="solution" mode="private-solutions"/>
                <xsl:apply-templates select="$n-solution[@ref=$the-id]" mode="private-solutions"/>
            </xsl:copy>
        </xsl:when>
        <!-- otherwise, just a straight xerox -->
        <xsl:otherwise>
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="private-solutions"/>
            </xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ######## -->
<!-- Versions -->
<!-- ######## -->

<!-- The version feature (@component markings) allows for   -->
<!-- invalid PreTeXt source.  For example, an author might  -->
<!-- have two different "docinfo" elements for some reason. -->
<!-- So we allow a sort of pre-PreTeXt, which does not      -->
<!-- satisfy the schema.  Support for the "custom" element  -->
<!-- is similar in spirit.  So very early on, we unravel    -->
<!-- (resolve) these features, and if used properly the     -->
<!-- result will be valid PreTeXt, according to the schema. -->

<!-- Only elements "marked" with @component need to be      -->
<!-- examined, the catch-all xerox template above suffices. -->
<xsl:template match="*[@component]" mode="version">
    <!-- prepare for test below -->
    <xsl:variable name="single-component-fenced" select="concat('|', normalize-space(@component), '|')"/>
    <xsl:choose>
        <!-- version scheme not elected, so use element no matter what -->
        <!-- note that @include="" yields "||" in test here            -->
        <xsl:when test="$components-fenced = ''">
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="version"/>
            </xsl:copy>
        </xsl:when>
        <!-- version scheme elected, element participating, so use element -->
        <!-- if it is a component in publisher's selection of components   -->
        <xsl:when test="contains($components-fenced, $single-component-fenced)">
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="version"/>
            </xsl:copy>
        </xsl:when>
        <!-- version scheme elected, element participating, but its component -->
        <!-- has not been selected in publisher file, so it gets dropped here -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:template>

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

<xsl:template match="custom[@ref]" mode="version">
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
        <!-- Copying the contents of "custom" via the "version" templates  -->
        <!-- will keep the "pi" namespace from appearing in places, as it  -->
        <!-- will with an "xsl:copy-of" on the same node set.  But it      -->
        <!-- allows nested "custom" elements.                              -->
        <!--                                                               -->
        <!-- Do we want authors to potentially create cyclic references?   -->
        <!-- A simple 2-cycle test failed quickly and obviously, so it     -->
        <!-- will be caught quite easily, it seems.                        -->
        <xsl:apply-templates select="$the-lookup/node()" mode="version"/>
    </xsl:for-each>
</xsl:template>

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

<!-- We cosmetically change a "drag-n-drop" style matching problem from    -->
<!-- being signaled by "matches" and instead call it a "cardsort" problem, -->
<!-- which is a more accurate description of the interface from Runestoone -->
<!-- Services.  We can't wait for "repair" since we do manipulation of     -->
<!-- exercises in advance.  Why's that?  So an old WeBWorK server can send -->
<!-- back old PreTeXt and have it be repaired.  So we do this change in an -->
<!-- earlier pass.                                                         -->
<xsl:template match="exercise/matches|project/matches|activit/matches|exploration/matches|investigation/matches|task/matches" mode="assembly">
    <!-- literal element gets namespace declarations -->
    <xsl:element name="cardsort">
        <xsl:apply-templates select="node()|@*" mode="assembly"/>
    </xsl:element>
</xsl:template>

<!-- Ordering for static version of a cardsort exercise no longer goes   -->
<!-- on the "match", due to the possibility of multiple "premise" inside -->
<!-- the "match".  If the problem is an old-style 1-1 corrspondence, we  -->
<!-- will move it onto *all* contained "premise", which will be fine if  -->
<!-- there is one or less within the "match".  We allow for a recent     -->
<!-- transition from "matches" to "cardsort".                            -->
<xsl:template match="matches/match/@order|cardsort/match/@order" mode="assembly"/>

<xsl:template match="matches/match/premise|cardsort/match/premise" mode="assembly">
    <xsl:copy>
        <xsl:apply-templates select="@*" mode="assembly"/>
        <xsl:if test="parent::match/@order">
            <xsl:attribute name="order">
                <xsl:value-of select="parent::match/@order"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="node()" mode="assembly"/>
    </xsl:copy>
</xsl:template>

<!-- ##################################################### -->
<!-- Dynamic Substitutions                                 -->
<!-- Cut out dynamic setup and evaluation for static mode. -->
<!-- ##################################################### -->
<xsl:template match="setup[de-object|setupScript]" mode="dynamic-substitution">
    <xsl:if test="$exercise-style = 'dynamic'">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="dynamic-substitution"/>
        </xsl:copy>
    </xsl:if>
</xsl:template>

<xsl:template match="numcmp|strcmp|jscmp|mathcmp|logic[parent::test]" mode="dynamic-substitution">
    <xsl:if test="$exercise-style = 'dynamic'">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="dynamic-substitution"/>
        </xsl:copy>
    </xsl:if>
</xsl:template>

<xsl:template match="fillin[@ansobj]" mode="dynamic-substitution">
    <xsl:choose>
        <xsl:when test="$exercise-style = 'static'">
            <xsl:variable name="parent-id">
                <xsl:apply-templates select="ancestor::statement/../@label" />
            </xsl:variable>
            <xsl:variable name="eval-subs" select="document($dynamic-substitutions-file,$original)"/>
            <xsl:variable name="object" select="@ansobj"/>
            <xsl:variable name="substitution">
                <xsl:value-of select="$eval-subs//dynamic-substitution[@id=$parent-id]/eval-subst[@obj=$object]"/>
            </xsl:variable>
            <xsl:message>
                <xsl:text>DYNAMIC SUBSTITUTION::</xsl:text>
                <xsl:value-of select="$parent-id"/>
                <xsl:text>$</xsl:text>
                <xsl:value-of select="$object"/>
                <xsl:text>=</xsl:text>
                <xsl:value-of select="$substitution"/>
            </xsl:message>
            <xsl:copy>
                <xsl:attribute name="answer">
                    <xsl:value-of select="$substitution"/>
                </xsl:attribute>
                <xsl:apply-templates select="@*|node()" mode="dynamic-substitution"/>
            </xsl:copy>
        </xsl:when>
        <xsl:otherwise>
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="dynamic-substitution"/>
            </xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="eval[@obj]" mode="dynamic-substitution">
    <xsl:choose>
        <!-- static, for multiple conversions, but primarily LaTeX -->
        <xsl:when test="$exercise-style = 'static'">
            <xsl:variable name="parent-id">
               <xsl:apply-templates select="(ancestor::statement|ancestor::solution|ancestor::evaluation)/../@label" />
            </xsl:variable>
            <xsl:variable name="eval-subs" select="document($dynamic-substitutions-file,$original)"/>
            <xsl:variable name="object" select="@obj"/>
            <xsl:variable name="substitution">
                <xsl:value-of select="$eval-subs//dynamic-substitution[@id=$parent-id]/eval-subst[@obj=$object]"/>
            </xsl:variable>
            <xsl:message>
                <xsl:text>DYNAMIC SUBSTITUTION::</xsl:text>
                <xsl:value-of select="$parent-id"/>
                <xsl:text>$</xsl:text>
                <xsl:value-of select="$object"/>
                <xsl:text>=</xsl:text>
                <xsl:value-of select="$substitution"/>
            </xsl:message>
            <xsl:value-of select="$substitution"/>
        </xsl:when>
        <!-- dynamic (aka HTML), needs static previews, server base64, etc, -->
        <!-- so just copy as-is with "webwork-reps" to signal and organize  -->
        <!-- to/for HTML conversion                                         -->
        <xsl:otherwise>
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="dynamic-substitution"/>
            </xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- An #eval child of test is implicit mathcmp. -->
<xsl:template match="test/eval[@obj]" mode="dynamic-substitution">
    <xsl:choose>
        <xsl:when test="$exercise-style = 'static'">
            <evaluation/>
        </xsl:when>
        <xsl:when test="$exercise-style = 'dynamic'">
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="dynamic-substitution"/>
            </xsl:copy>
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- ################### -->
<!-- WeBWorK Manufacture -->
<!-- ################### -->


<!-- This pre-processing stylesheet will be run prior to isolating WW      -->
<!-- problems for their eventual trip to a WW server ("extraction").       -->
<!-- This is necessary so certain numbers are formed properly, etc.        -->
<!-- In this phase we handle making copies of WW problems by duplicating   -->
<!-- them.  This stylesheet is parameterized by the boolean variable       -->
<!-- $b-extracting-pg, and is set by the stylesheet that actually harvests -->
<!-- the WW problems and converts them to PG versions (extract-pg.xsl).    -->
<xsl:variable name="b-extracting-pg" select="false()"/>

<!-- Don't match on simple WeBWorK logo       -->
<!-- But do match with a @copy attribute      -->
<!-- Seed and possibly source attributes      -->
<!-- Then authored?, pg?, and static children -->
<!-- NB: "xref" check elsewhere is not        -->
<!-- performed here since we accept           -->
<!-- representations at face-value            -->

<!-- NB: when working to improve which parts of the webwork representations -->
<!-- move on to assembled source, realize that the "static" version meant   -->
<!-- for non-HTML outputs is also the best thing to provide to the HTML     -->
<!-- conversion for use as a search document.  Perhaps create the full-on   -->
<!-- JSON (escaped) string here from "static" and provide it as an internal -->
<!-- element ("pi:") for later consumption.  Review the destination for     -->
<!-- similar notes about possible changes.                                  -->

<xsl:template match="webwork[* or @copy or @source]" mode="webwork">
    <!-- Every "webwork" that is a problem (not a generator) gets a   -->
    <!-- lifetime identification in both passes through the source.   -->
    <!-- The first migrates through the "extract-pg.xsl" template,    -->
    <!-- then the Python communication with the server, and into the  -->
    <!-- representations file.  The second is then used to align the  -->
    <!-- source with the representations file on the second pass.     -->
    <!-- For historical reasons, this ID genertaion is slow and       -->
    <!-- clumsy, we can improve by using a recursive generation,      -->
    <!-- which would require parameter passing through all the        -->
    <!-- "assembly" templates.  Better to perhaps break out a         -->
    <!-- "webwork" pass just prior to assembly.                       -->
    <!-- 2022-11-21: we are a bit careful to optimize the computation -->
    <!-- of the identifiers in a backwards-compatible way.  Better to -->
    <!-- someday switch to a purely recursive descent version as a    -->
    <!-- one-time jolt to authors. (Remove global $all-webwork.)      -->
    <xsl:variable name="ww-id">
        <xsl:choose>
            <xsl:when test="@xml:id">
                <xsl:value-of select="@xml:id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="local-name(.)" />
                <xsl:text>-</xsl:text>
                <!-- compute the eqivalent of the count of all previous WW:     -->
                <!-- <xsl:number from="book|article|letter|memo" level="any" /> -->
                <!-- Save off the WW in question -->
                <xsl:variable name="the-ww" select="self::*"/>
                <!-- Run over global list, looking for a match -->
                <xsl:for-each select="$all-webwork">
                    <xsl:if test="count($the-ww|.) = 1">
                        <!-- context is the $all-webwork node-set, so   -->
                        <!-- position() gives index/location of $the-ww -->
                        <xsl:value-of select="position()"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <!-- "normally" not extracting to build PGML, it -->
        <!-- should be saved off in the representations  -->
        <!-- file and available for making replacements  -->
        <xsl:when test="not($b-extracting-pg)">
            <!-- the "webwork-reps" element from the server for this "webwork" -->
            <xsl:variable name="the-webwork-rep" select="document($webwork-representations-file, $original)/webwork-representations/webwork-reps[@ww-id=$ww-id]"/>
            <xsl:choose>
                <!-- An empty string for $webwork-representations-file, and      -->
                <!-- the "document()" still succeeds (returns the source file?). -->
                <!-- But this is hopeless. So just totally bail out repeatedly   -->
                <!-- and leave the containing "exercise" hollow.                 -->
                <xsl:when test="$webwork-representations-file = ''">
                    <xsl:message>PTX:ERROR:    There is a WeBWorK exercise with internal id "<xsl:value-of select="$ww-id"/>"</xsl:message>
                    <xsl:message>              but your publication file does not indicate the file</xsl:message>
                    <xsl:message>              of problem representations created by a WeBWorK server.</xsl:message>
                    <xsl:message>              Your WeBWorK exercises will all, at best, be empty.</xsl:message>
                </xsl:when>
                <!-- This should only fail if the file is missing.  Repeatedly. -->
                <xsl:when test="not($the-webwork-rep)">
                    <xsl:message>PTX:ERROR:    The WeBWorK problem with internal id "<xsl:value-of select="$ww-id"/>"</xsl:message>
                    <xsl:message>              could not be located in the file of WeBWorK problems from</xsl:message>
                    <xsl:message>              the server, which your publication file indicates should be located</xsl:message>
                    <xsl:message>              at "<xsl:value-of select="$webwork-representations-file"/>". </xsl:message>
                    <xsl:message>              If there are many messages like this, then likely your file is missing. </xsl:message>
                    <xsl:message>              But if this is an isolated error message, then it may indicate a bug,</xsl:message>
                    <xsl:message>              which should be reported.</xsl:message>
                </xsl:when>
                <!-- Copy the "webwork-reps" in place of the "webwork", so this is  -->
                <!-- a new signal of a WW problem for the second pass.  This is     -->
                <!-- also temporary, since we will subset and slim this down later. -->
                <xsl:otherwise>
                    <xsl:apply-templates select="$the-webwork-rep" mode="webwork"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- Now we are doing a pass to support extraction -->
        <!-- of PGML, so $b-extracting-pg is true          -->
        <!--                                               -->
        <!-- This is where we copy PTX source to prevent   -->
        <!-- multiple versions foating in around in an     -->
        <!-- author's source                               -->
        <xsl:when test="@copy">
            <!-- Find the target.  Maybe. -->
            <xsl:variable name="target" select="id(@copy)"/>
            <!-- Trap potential pitfalls and record part of an error -->
            <!-- message.  Use a non-empty error message as a signal -->
            <!-- to bail out gracefully on the copy.                 -->
            <xsl:variable name="error-message-for-copy">
                <xsl:choose>
                    <xsl:when test="not($target)">
                        <xsl:text>the @copy attribute points to nothing, check the spelling?</xsl:text>
                    </xsl:when>
                    <xsl:when test="not($target/self::webwork)">
                        <xsl:text>the @copy attribute points to a "</xsl:text>
                        <xsl:value-of select="local-name($target)"/>
                        <xsl:text>" element, not another "webwork".</xsl:text>
                    </xsl:when>
                    <xsl:when test="$target/self::webwork[@source]">
                        <xsl:text>the @copy attribute points a "webwork" with a @source attribute.  (Replace the @copy by the @source?)</xsl:text>
                    </xsl:when>
                    <xsl:when test="$target/self::webwork[@copy]">
                        <xsl:text>the @copy attribute points to "webwork" with a @copy attribute. Sorry, we are not that sophisticated.</xsl:text>
                    </xsl:when>
                    <!-- Presumably OK, no error message -->
                    <xsl:otherwise/>
                </xsl:choose> <!-- end: gauntlet of bad @copy discovery -->
            </xsl:variable>

            <xsl:choose>
                <!-- no error means to proceed with copy -->
                <xsl:when test="$error-message-for-copy = ''">
                    <xsl:copy>
                        <xsl:attribute name="copied-from">
                            <xsl:value-of select="@copy"/>
                        </xsl:attribute>
                        <!-- Duplicate attributes, but remove the @copy attribute -->
                        <!-- used as a signal here.  We don't want to copy this   -->
                        <!-- again after we have been to the WW server.           -->
                        <xsl:apply-templates select="@*[not(local-name(.) = 'copy')]" mode="webwork"/>
                        <!-- The @seed makes the problem different, and there are also   -->
                        <!-- unique identifiers, so grab any other attributes of the     -->
                        <!-- original, but exclude these while formulating a copy/clone. -->
                        <xsl:apply-templates select="$target/@*[(not(local-name(.) = 'id')) and
                                                                (not(local-name(.) = 'label')) and
                                                                (not(local-name(.) = 'seed'))]" mode="webwork"/>
                        <!-- Add a @ww-id for the trip to the server -->
                        <xsl:attribute name="ww-id">
                            <xsl:value-of select="$ww-id"/>
                        </xsl:attribute>
                        <!-- TODO: The following should scrub unique IDs as it continues down the tree. -->
                        <!-- Perhaps with a param to the assembly modal template.                       -->
                        <!-- Does the contents of the original WW have any @xml:id or @label?           -->
                        <xsl:apply-templates select="$target/node()" mode="webwork"/>
                    </xsl:copy>
                </xsl:when>
                <!-- with an error in formulation, drop in something very -->
                <!-- similar in gross form, and alert at the console      -->
                <xsl:otherwise>
                    <xsl:copy>
                        <!-- As for a legitimate copy above , we carry over as much -->
                        <!-- metadata as possible, and in particular include a      -->
                        <!-- @ww-id  for tracking through the server                -->
                        <xsl:apply-templates select="@*[not(local-name(.) = 'copy')]" mode="webwork"/>
                        <xsl:attribute name="ww-id">
                            <xsl:value-of select="$ww-id"/>
                        </xsl:attribute>
                        <!-- Now a minimal, but correct PreTeXt, WW problem into the       -->
                        <!-- extraction machinery, and out into all possible final outputs -->
                        <statement>
                            <p>
                                A WeBWorK problem right here was meant to be a copy of another problem,
                                but potentially with different randomization, but there was a failure.
                                The <c>@copy</c> attribute was set to <c><xsl:value-of select="@copy"/></c>.
                                Please report me, so the publisher can get more details by searching the
                                runtime output for <q><c>PTX:ERROR</c></q>.
                            </p>
                        </statement>
                    </xsl:copy>
                    <!-- minimalist report into source, more at console -->
                    <xsl:message>PTX:ERROR:   A WeBWorK problem has a @copy attribute with value "<xsl:value-of select="@copy"/>".</xsl:message>
                    <xsl:message>             However, the problem did not render:</xsl:message>
                    <xsl:message><xsl:text>             </xsl:text><xsl:value-of select="$error-message-for-copy"/></xsl:message>
                    <xsl:message>             A placeholder problem will appear in your output instead.</xsl:message>
                </xsl:otherwise>
            </xsl:choose> <!-- end: action for copy is good/bad -->
        </xsl:when>
        <!-- extracting, but not copying, so xerox author's source, plus an ID -->
        <xsl:otherwise>
            <xsl:copy>
                <xsl:apply-templates select="@*" mode="webwork"/>
                <!-- Add a @ww-id for the trip to the server -->
                <xsl:attribute name="ww-id">
                    <xsl:value-of select="$ww-id"/>
                </xsl:attribute>
                <xsl:apply-templates select="node()" mode="webwork"/>
            </xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ########## -->
<!-- Enrichment -->
<!-- ########## -->

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
<!--                                                                        -->
<!-- N.B. the automatic "fn/@pi:url" creates a *new* element that is not    -->
<!-- in an author's source.  When we annotate source (as a form of perfect  -->
<!-- documentation) we take care to not annotate these elements which  have -->
<!-- no source to show.                                                     -->

<xsl:template match="url[node()]|dataurl[node()]" mode="enrichment">
    <xsl:copy>
        <!-- we drop the @visual attribute, a decision we might revisit -->
        <xsl:apply-templates select="node()|@*[not(local-name(.) = 'visual')]" mode="enrichment"/>
    </xsl:copy>
    <!-- Now make footnote, as long as we don't create a footnote in a footnote -->
    <xsl:if test="not(self::url and ancestor::fn)">
        <!-- manufacture a footnote with (private) attribute -->
        <!-- as a signal to conversions as to its origin     -->
        <xsl:choose>
            <!-- explicitly opt-out, so no footnote -->
            <xsl:when test="@visual = ''"/>
            <!-- go for it, as requested by author -->
            <xsl:when test="@visual">
                <fn pi:url="{@visual}"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- When an author has not made an effort to provide a visual   -->
                <!-- alternative, then attempt some obvious clean-up of the      -->
                <!-- default, and if not possible, settle for an ugly visual URL -->
                <!--                                                             -->
                <!-- We get a candidate visual URI from the @href attribute      -->
                <!-- link/reference/location may be external -->
                <!-- (@href) or internal (dataurl[@source]) -->
                <xsl:variable name="uri">
                    <xsl:choose>
                        <!-- "url" and "dataurl" both support external @href -->
                        <xsl:when test="@href">
                            <xsl:value-of select="@href"/>
                        </xsl:when>
                        <!-- a "dataurl" might be local, @source is         -->
                        <!-- indication, so prefix with a base URL,         -->
                        <!-- add "external" directory, via template useful  -->
                        <!-- also for visual URL formulation in -assembly   -->
                        <!-- N.B. we are using the base URL, since this is  -->
                        <!-- the most likely need by employing conversions. -->
                        <!-- It would eem duplicative in a conversion to    -->
                        <!-- HTML, so could perhaps be killed in that case. -->
                        <!-- But it is what we want for LaTeX, and perhaps  -->
                        <!-- for EPUB, etc.                                 -->
                        <xsl:when test="self::dataurl and @source">
                            <xsl:apply-templates select="." mode="static-url"/>
                        </xsl:when>
                        <!-- empty will be non-functional -->
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:variable>
                <!-- And clean-up automatically in the prevalent cases -->
                <xsl:variable name="truncated-href">
                    <xsl:choose>
                        <xsl:when test="substring(@href, 1, 8) = 'https://'">
                            <xsl:value-of select="substring($uri, 9)"/>
                        </xsl:when>
                        <xsl:when test="substring(@href, 1, 7) = 'http://'">
                            <xsl:value-of select="substring($uri, 8)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$uri"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <fn pi:url="{$truncated-href}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
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

<!-- 2022-06-09 WeBWorK "stage" deprecated in favor of "task"       -->
<!-- We could use  match="webwork/stage"  but then this would only  -->
<!-- happen to the author's source while being prepared for the     -->
<!-- "extract-pg.xsl" worksheet.  But we also want to catch "stage" -->
<!-- coming back from an old WeBWorK server, which may be various   -->
<!-- places after we algorithmically manipulate the "webwork-reps"  -->
<!-- structure.  Instead, we just wait until now.  If necessary,    -->
<!-- perhaps "exercise/stage" for the post-server pass.             -->
<xsl:template match="stage" mode="repair">
    <task>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </task>
</xsl:template>

<!-- 2022-07-10 webwork//latex-image[syntax='PGtikz'] deprecated    -->
<!-- to just a normal latex-image. The text content for the code    -->
<!-- must be wrapped in a tikzpicture environment.                  -->
<xsl:template match="latex-image[@syntax='PGtikz']" mode="repair">
    <xsl:copy>
        <!-- we drop the @syntax attribute -->
        <xsl:apply-templates select="node()|@*[not(local-name(.) = 'syntax')]" mode="repair"/>
    </xsl:copy>
</xsl:template>
<xsl:template match="latex-image[@syntax='PGtikz']/text()" mode="repair">
    <xsl:text>\begin{tikzpicture}&#xa;</xsl:text>
    <xsl:call-template name="sanitize-latex">
        <xsl:with-param name="text">
            <xsl:copy>
                <xsl:apply-templates select="."/>
            </xsl:copy>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>&#xa;\end{tikzpicture}&#xa;</xsl:text>
</xsl:template>

<!-- Deprecated 2018-12-30 in favor of "ca"   -->
<!-- Copy attributes...because you never know -->
<xsl:template match="circa" mode="repair">
    <ca>
        <xsl:apply-templates select="@*" mode="repair"/>
    </ca>
</xsl:template>

<!-- Due to naivete, we had empty templates for "keyboard characters"    -->
<!-- we did not have the skills to handle.  A good example was <dollar/> -->
<!-- simply because it is a (very) special character in LaTeX.  These    -->
<!-- were deprecated on 2019-02-06.  Beginning in 2022-12-26, we are     -->
<!-- providing fixes here, and removing all the (dead) code meant for    -->
<!-- backward compatibility.                                             -->

<!-- XML characters -->

<xsl:template match="less" mode="repair">
    <xsl:text>&lt;</xsl:text>
</xsl:template>

<xsl:template match="greater" mode="repair">
    <xsl:text>&gt;</xsl:text>
</xsl:template>

<!-- Ten LaTeX characters -->
<!-- # $ % ^ & _ { } ~ \  -->

<xsl:template match="hash" mode="repair">
    <xsl:text>#</xsl:text>
</xsl:template>

<xsl:template match="ampersand" mode="repair">
    <xsl:text>&amp;</xsl:text>
</xsl:template>

<xsl:template match="dollar" mode="repair">
    <xsl:text>$</xsl:text>
</xsl:template>

<xsl:template match="percent" mode="repair">
    <xsl:text>%</xsl:text>
</xsl:template>

<xsl:template match="circumflex" mode="repair">
    <xsl:text>^</xsl:text>
</xsl:template>

<xsl:template match="underscore" mode="repair">
    <xsl:text>_</xsl:text>
</xsl:template>

<xsl:template match="lbrace" mode="repair">
    <xsl:text>{</xsl:text>
</xsl:template>

<xsl:template match="rbrace" mode="repair">
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="tilde" mode="repair">
    <xsl:text>~</xsl:text>
</xsl:template>

<xsl:template match="backslash" mode="repair">
    <xsl:text>\</xsl:text>
</xsl:template>

<!-- Lesser keyboard characters -->
<!-- [, ], *, /, `,             -->

<xsl:template match="lbracket" mode="repair">
    <xsl:text>[</xsl:text>
</xsl:template>

<xsl:template match="rbracket" mode="repair">
    <xsl:text>]</xsl:text>
</xsl:template>

<xsl:template match="asterisk" mode="repair">
    <xsl:text>*</xsl:text>
</xsl:template>

<xsl:template match="slash" mode="repair">
    <xsl:text>/</xsl:text>
</xsl:template>

<xsl:template match="backtick" mode="repair">
    <xsl:text>`</xsl:text>
</xsl:template>

<!-- Grouping constructions  -->
<!-- "braces" and "brackets" -->

<xsl:template match="braces" mode="repair">
    <xsl:text>{</xsl:text>
    <!-- attributes will be lost -->
    <xsl:apply-templates select="node()" mode="repair"/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="brackets" mode="repair">
    <xsl:text>[</xsl:text>
    <!-- attributes will be lost -->
    <xsl:apply-templates select="node()" mode="repair"/>
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- 2023-01-27: deprecate "datafile" to make way for a better    -->
<!-- Runestone-powered version.  Cosmetic replacement: "dataurl". -->
<!-- 2023-01-30: refine deprecation repair just after a minor CLI -->
<!-- release. A "datafile" element may be OK as a "new" use,      -->
<!-- with the presence of @label indicating use/application with  -->
<!-- Runestone Javascript.  So only automatically upgrade "old"   -->
<!-- uses lacking @label.                                         -->
<xsl:template match="datafile[not(@label)]" mode="repair">
    <dataurl>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </dataurl>
</xsl:template>

<xsl:template match="colophon/website[address]" mode="repair">
    <website>
        <xsl:apply-templates select="@*" mode="repair"/>
        <url>
            <xsl:attribute name="href">
                <xsl:value-of select="address"/>
            </xsl:attribute>
            <xsl:apply-templates select="name/node()" mode="repair"/>
        </url>
    </website>
</xsl:template>

<!-- 2023-08-28: deprecate the "console" "prompt" element -->

<!-- Removing this entire line typically orphans a text node    -->
<!-- just prior with a newline and indentation, but this should -->
<!-- not harm subsequent processing since we do not assume      -->
<!-- source is carefully authored as one element per line.      -->
<xsl:template match="console/prompt" mode="repair"/>

<!-- If there was a "prompt" element just preceding an "input"      -->
<!-- element, then we reach up and grab it and make it an attribute -->
<!-- of the "input" - but not if somebody happened to already start -->
<!-- using a @prompt attribute.                                     -->
<!-- https://www.oxygenxml.com/archives/xsl-list/199910/msg00541.html -->
<xsl:template match="console/input" mode="repair">
    <xsl:copy>
        <xsl:if test="not(@prompt) and preceding-sibling::*[1][self::prompt]">
            <xsl:attribute name="prompt">
                <xsl:value-of select="preceding-sibling::*[1][self::prompt]"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </xsl:copy>
</xsl:template>

<!-- 2023-09-07: move "description" to "shortdescription" -->

<xsl:template match="image/description[not(*[not(self::var)])]" mode="repair">
    <xsl:element name="shortdescription" namespace="">
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </xsl:element>
</xsl:template>

<!-- 2023-10-17: docinfo/latex-preamble is history -->

<xsl:template match="docinfo/latex-preamble" mode="repair">
    <!-- any attributes (no such thing?) are simply  -->
    <!-- orphaned and we just process child elements -->
    <xsl:apply-templates select="node()" mode="repair"/>
</xsl:template>

<!-- 2023-10-17: and "extra" LaTeX packages are re-worked -->

<xsl:template match="docinfo/latex-preamble/package" mode="repair">
    <xsl:element name="math-package">
        <xsl:attribute name="latex-name">
            <xsl:value-of select="."/>
        </xsl:attribute>
        <xsl:attribute name="mathjax-name">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:element>
</xsl:template>

<!-- 2024-10-29: program is reworked -->

<!-- Add code element around text in program when missing -->
<xsl:template match="program[not(input|code)]" mode="repair">
    <xsl:copy>
        <xsl:apply-templates select="@*" mode="repair"/>
        <code>
            <xsl:value-of select="text()"/>
        </code>
    </xsl:copy>
</xsl:template>

<xsl:template match="program[not(code)]/input" mode="repair">
    <xsl:element name="code">
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </xsl:element>
</xsl:template>

<!-- Index deprecations -->
<!-- The way an index was constructed changed in 2017-07-14.  At 2024-08-08  -->
<!-- we are using the "repair" phase to move the old style to the new.  The  -->
<!-- old style looked like a "index-part" division with a mandatory          -->
<!-- "index-list" child.  Elements sprinkled into the text were an           -->
<!-- unstructured "index" or an "index" with up to three headings: "main",   -->
<!-- followed by possibly two "sub".  Now the division is "index" (as it     -->
<!-- should be!) and the entries are "idx".  A structured "idx" can have     -->
<!-- one to three "h" elements as the headings.                              -->

<!-- Change the division element -->
<xsl:template match="index-part" mode="repair">
    <index>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </index>
</xsl:template>

<!-- Change tne entry element, but avoid a new division name -->
<xsl:template match="index[not(index-list)]" mode="repair">
    <idx>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </idx>
</xsl:template>

<!-- Change first old style heading -->
<xsl:template match="index[not(index-list)]/main" mode="repair">
    <h>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </h>
</xsl:template>

<!-- Change second and third old style headings -->
<xsl:template match="index[not(index-list)]/sub" mode="repair">
    <h>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </h>
</xsl:template>

<!-- Frontmatter repairs -->
<!-- 2024-10-10: we will no longer require an author to decide  -->
<!-- which frontmatter elements belong on a titlepage or in the -->
<!-- front colophon.  All the elements from both titlepage and  -->
<!-- colophon should now go in bibinfo. We run repair whenever  -->
<!-- the author has an existing titlepage or colophon without   -->
<!-- the new titlepage-items or colophon-items children.        -->
<xsl:template match="frontmatter[titlepage[not(titlepage-items)] or colophon[not(colophon-items)]]" mode="repair">
    <xsl:copy>
        <xsl:apply-templates select="@*" mode="repair"/>
        <bibinfo>
            <!-- Include deprecated children of titlepage and colophon -->
            <xsl:apply-templates select="titlepage/author" mode="repair"/>
            <xsl:apply-templates select="titlepage/editor" mode="repair"/>
            <xsl:apply-templates select="titlepage/credit" mode="repair"/>
            <xsl:apply-templates select="titlepage/date" mode="repair"/>
            <!-- for slides, we allowed an "event" -->
            <xsl:apply-templates select="titlepage/event" mode="repair"/>
            <xsl:apply-templates select="colophon/credit" mode="repair"/>
            <xsl:apply-templates select="colophon/edition" mode="repair"/>
            <xsl:apply-templates select="colophon/website" mode="repair"/>
            <xsl:apply-templates select="colophon/copyright" mode="repair"/>
        </bibinfo>
        <!-- We (pretty much) duplicate everything, except two templates -->
        <!-- below hollow-out old-style "titlepage" and "colophon" to    -->
        <!-- match the new style with generators.                        -->
        <xsl:apply-templates select="node()" mode="repair"/>
    </xsl:copy>
</xsl:template>

<!-- We repair a "titlepage" that is not in the new style using a text   -->
<!-- generator.  The "titlepage" is structural and the empty text        -->
<!-- generator will be implemented in conversions to do the right thing. -->
<xsl:template match="titlepage[not(titlepage-items)]" mode="repair">
    <xsl:copy>
        <xsl:apply-templates select="titlepage/@*" mode="repair"/>
        <titlepage-items/>
    </xsl:copy>
</xsl:template>

<!-- We repair a front "colophon" that is not in the new style using a   -->
<!-- text generator.  The "colophon" is structural and the empty text    -->
<!-- generator will be implemented in conversions to do the right thing. -->
<!-- NB: "frontmatter" is necessary so we don't clobber a BACK colophon! -->
<xsl:template match="frontmatter/colophon[not(colophon-items)]" mode="repair">
    <xsl:copy>
        <xsl:choose>
            <!-- Keep authored xml:id or label -->
            <xsl:when test="colophon/@xml:id|colophon/@label">
                <xsl:apply-templates select="colophon/@xml:id|colophon/@label" mode="repair"/>
            </xsl:when>
            <!-- Otherwise, use the label "front-colophon" -->
            <xsl:otherwise>
                <xsl:attribute name="label">
                    <xsl:text>front-colophon</xsl:text>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
        <!-- Include the colophon-items generator -->
        <colophon-items/>
    </xsl:copy>
</xsl:template>

<!-- We allow an author/editor/contributor to have their affiliation information not -->
<!-- wrapped in affiliation tags, but in that case we put them in affiliation tags.  -->
<xsl:template match="frontmatter//author[not(affiliation)]|frontmatter//editor[not(affiliation)]|frontmatter//contributor[not(affiliation)]" mode="repair">
    <xsl:copy>
        <!-- Include "personname" first -->
        <xsl:apply-templates select="personname|@*" mode="repair"/>
        <!-- If there are bare deparmtment/institution/address, wrap them in affailiation -->
        <xsl:if test="department or institution or location">
            <affiliation>
                <xsl:apply-templates select="department|institution|location" mode="repair"/>
            </affiliation>
        </xsl:if>
        <!-- Include all additional elements as they are -->
        <xsl:apply-templates select="*[not(self::personname or self::department or self::institution or self::location)]" mode="repair"/>
    </xsl:copy>
</xsl:template>

<!-- 2025-03-08:  "commentary" is deprecated.  Authors should remove it, -->
<!-- but we have suggested that it could be used with version support.   -->
<!-- So, if extant here in the repair phase, then it must have had a     -->
<!-- @component value that a publication file suggested retaining.       -->
<!-- So, just like the previous (now gone) "component" pass, we just     -->
<!-- unwrap the element.                                                 -->
<xsl:template match="commentary" mode="repair">
    <!-- do not duplicate "commentary", do not replicate   -->
    <!-- @component, do replicate element and text children -->
    <xsl:apply-templates select="node()" mode="repair"/>
</xsl:template>

<!-- Change listing captions to titles if there is not already a title -->
<xsl:template match="listing/caption" mode="repair">
    <xsl:if test="not(parent::listing/title)">
        <title>
            <xsl:apply-templates select="node()|@*" mode="repair"/>
        </title>
    </xsl:if>
</xsl:template>


<!-- ############################## -->
<!-- Killed, in Chronological Order -->
<!-- ############################## -->

<!-- 2017-07-16  killed, from 2015-03-13 deprecation -->
<xsl:template match="paragraph" mode="repair"/>

<!-- 2019-02-20  deprecated and killed simultaneously -->
<xsl:template match="todo" mode="repair"/>

<!-- A "pagebreak" should have had limited -->
<!-- uptake, so no real care taken,        -->
<!-- Deprecated 2021-03-17                 -->
<xsl:template match="pagebreak" mode="repair"/>

<!-- @permid experiments retired 2024-07-24, -->
<!-- so eliminated in this phase             -->
<xsl:template match="@permid" mode="repair"/>

<!-- 2024-08-05: remove metadata elements from a sidebyside, -->
<!-- which have not been schema-compliant since circa 2017   -->
<xsl:template match="sidebyside/*[&METADATA-FILTER;]" mode="repair"/>

<!-- ########### -->
<!-- Assembly ID -->
<!-- ########### -->

<!-- Some maniulations of source require stable identification *before*     -->
<!-- we assign @unique-id values for general use in the very late           -->
<!-- "identification" phase.  This is a role for the "@assembly-id" which   -->
<!-- is formed after the author's source has been versioned, customized,    -->
<!-- repaired, but before replacements. It should suffice for "big" objects -->
<!-- which are unlikely to change much (other than going away in a version) -->
<!-- and may only be "repaired" in a one-to-one cosmetic rename.  We use    -->
<!-- this sparingly, thus we are careful about the match, along with        -->
<!-- documenting rationale for each object.                                 -->
<!--                                                                        -->
<!-- Another way to think about this is as an "early" id, versus the        -->
<!-- more general "late" id.                                                -->
<!--                                                                        -->
<!-- audio|video|interactive                                                -->
<!--     Static versions of these interactive elements have previews        -->
<!--     (YouTube thumbnails, automatically generated screenshots),         -->
<!--     generated QR codes, and various links meant for use in static      -->
<!--     contexts.  So we form names of these related objects based on      -->
<!--     an "earlier" id.                                                   -->
<!--                                                                        -->
<!-- datafile                                                               -->
<!--     For static versions of this Runestone component, when the file is  -->
<!--     a text file provided in the external directory, we need to         -->
<!--     interrogate the file manufactured in the generated directory in    -->
<!--     order to make a sample of its content.  This happens before we     -->
<!--     construct unique-id.                                               -->

<!-- NB: we believe the @assembly-id will equal the @unique-id    -->
<!-- ("visible-id" template) for objects at the level of blocks,  -->
<!-- and certainly for any object replaced by a different static  -->
<!-- representation.  But for generated objects, e.g. QR codes,   -->
<!-- it would be best if the generation process used the          -->
<!-- "assembly-id" template for guranteed consistency.  This *is* -->
<!-- being done for "datafile" but is technical debt otherwise.   -->

<!-- [Ed. this once prefaced the "visible-id-early" template, a weak  -->
<!-- forerunner of the "assembly-id" template.  But the commentary    -->
<!-- is still good, so we have preserved it here.]                    -->
<!-- This template produces identification that happens early in the  -->
<!-- passes this stylesheet executes.  The idea is that some elements -->
<!-- get replaced wholesale (such as an "interactive" being replaced  -->
<!-- by a "sidebyside" in the creation of a static precursor.  But we -->
<!-- want these ids, especially if automatic, to be consistent when   -->
<!-- used in derived versions (such as manufacturing, or displaying,  -->
<!-- a QR code file for a static "interactive").                      -->
<!-- NB: this template needs to be defined in this stylesheet, since  -->
<!-- we want the stylesheet to be independent, and the template is    -->
<!-- also applied here.                                               -->

<xsl:template match="audio|video|interactive|image" mode="assembly-id">
    <xsl:value-of select="@assembly-id"/>
</xsl:template>

<xsl:template match="exercise[@exercise-interactive='fillin' and setup]
                   | project[@exercise-interactive='fillin' and setup]
                   | activity[@exercise-interactive='fillin' and setup]
                   | exploration[@exercise-interactive='fillin' and setup]
                   | investigation[@exercise-interactive='fillin' and setup]"
                   mode="assembly-id">
    <xsl:value-of select="@assembly-id"/>
</xsl:template>
<xsl:template match="exercise[.//task and .//task/@exercise-interactive='fillin' and .//setup]
                   | project[.//task and .//task/@exercise-interactive='fillin' and .//setup]
                   | activity[.//task and .//task/@exercise-interactive='fillin' and .//setup]
                   | exploration[.//task and .//task/@exercise-interactive='fillin' and .//setup]
                   | investigation[.//task and .//task/@exercise-interactive='fillin' and .//setup]"
                   mode="assembly-id">
    <xsl:value-of select="@assembly-id"/>
</xsl:template>

<xsl:template match="datafile" mode="assembly-id">
    <xsl:value-of select="@assembly-id"/>
</xsl:template>

<xsl:template match="*" mode="assembly-id">
    <xsl:message>
        <xsl:text>PTX:BUG:  the "assembly-id" template was applied to an element it did not expect--</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>.</xsl:text>
        <xsl:value-of select="@exercise-interactive"/>
        <xsl:text>.</xsl:text>
        <xsl:value-of select="@assembly-id"/>
    </xsl:message>
    <xsl:text>unexpected-assembly-id-template-use-here</xsl:text>
</xsl:template>


<!-- ############## -->
<!-- Identification -->
<!-- ############## -->

<!-- The "visible-id" template switched to prefer @label,         -->
<!-- rather than @xml:id (at 1779e6dbc84c6ecc).  So to preserve   -->
<!-- authored (crafted) identifier strings, we copy the old over  -->
<!-- into the new.  This preserves identifiers in output          -->
<!-- (filenames, fragment identifiers).  Subsequent passes        -->
<!-- should not introduce or remove elements.                     -->

<!-- 2023-03-30: This is old commentary about the use of the -->
<!-- "unique-id" identifier in the LaTeX conversion, which   -->
<!-- has now become more universal.  Once identifiers settle -->
<!-- down, we can clean up the parts of this worth keeping.  -->
<!--  -->
<!-- This produces unique strings that are internal to the  -->
<!-- LaTeX (intermediate) file.  Since neither author nor   -->
<!-- reader will ever see these, they can be as fast and as -->
<!-- wild as necessary.  But for mature works, likely with  -->
<!-- @permid on many relevant objects, or many @xml:id      -->
<!-- provided for URLs in HTML, these can be predictable    -->
<!-- across runs (and therefore help with tweaking the LaTeX-->
<!-- output under revision control) These are employed with -->
<!-- \label{}, \ref{}, \cite{}, \pageref{}, \eqref{}, etc.  -->
<!-- We can change this at will, with no adverse effects    -->
<!-- NB: colons are banned from PTX @xml:id, and will not   -->
<!-- appear in @permid, though we could use dashes instead  -->
<!-- without getting duplicates.  The prefixes guarantee    -->
<!-- that the three uniqueness schemes do not overlap.      -->

<!-- First, we upgrade an authored @xml:id to a @label,       -->
<!-- WHEN there is no authored @label present.  This is a     -->
<!-- sort of backward-compatibility maneuver.  An @xml:id     -->
<!-- now serves only as a sort of internal name for a target  -->
<!-- node (like a cross-reference, "xref"), while it formerly -->
<!-- served as a string to generate various bits of output,   -->
<!-- such as filenames in HTML output.                        -->

<xsl:template match="*" mode="labels">
    <xsl:copy>
        <!-- duplicate all attributes -->
        <xsl:apply-templates select="@*" mode="labels"/>
        <!-- Case: an authored @xml:id, not an authored @label -->
        <xsl:if test="@xml:id and not(@label)">
            <xsl:attribute name="label">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>
        </xsl:if>
        <!-- Case: a @label provided in source by author                 -->
        <!-- It is helpful to distinguish between an authored @label and -->
        <!-- one that this template creates by copying over a @xml:id.   -->
        <!-- So we drop an (empty) attribute as a boolean indicator.     -->
        <!-- This form will simplify checks later at "run-time".         -->
        <xsl:if test="@label">
            <xsl:attribute name="authored-label"/>
        </xsl:if>
        <!-- recurse -->
        <xsl:apply-templates select="node()" mode="labels"/>
    </xsl:copy>
</xsl:template>

<!-- This general-purpose template constructs unique strings as part   -->
<!-- of a natural depth-first exploration of the tree.  Strings are    -->
<!-- reset when provided by authors on elements (ideally via @label).  -->
<!-- Otherwise the tree structure is reflected by location at each     -->
<!-- level of the subtree rooted at the last authored string.  A bit   -->
<!-- unsightly, and only partialy effective to unwind the numers back  -->
<!-- to an element.  But super-fast to construct and reliably unique   -->
<!-- (though an author could provide two strings that make a conflict, -->
<!-- we believe).                                                      -->
<xsl:template match="*" mode="id-attribute">
    <xsl:param name="parent-id"  select="'root'"/>
    <xsl:param name="attr-name"  select="''"/>

    <xsl:copy>
        <!-- duplicate all attributes -->
        <xsl:apply-templates select="@*" mode="id-attribute"/>
        <!-- * Strategy is much like @original-id but maybe needs as much care            -->
        <!-- * Element counts are used to reflect document tree structure                 -->
        <!-- * Non-numeric separator needed to preserve uniqueness (e.g.1-12 != 11-2).    -->
        <!-- * Separators are therefore hyphens                                           -->
        <!-- * Colons as separators would create confusion with namespaces                -->
        <!-- * Salt added to authored values could decrease risk of collision             -->
        <xsl:variable name="new-id">
            <xsl:choose>
                <!-- A @label might be authored.  Or not authored, and   -->
                <!-- then an authored @xml:id was promoted into a @label -->
                <xsl:when test="@label">
                    <xsl:value-of select="@label"/>
                </xsl:when>
                <!-- This mimics the upgrade of an authored xml:id to a label -->
                <!-- NB: this might not ever happen in some passes, when an   -->
                <!-- @xml:id value has been upgraed to a @label value in a    -->
                <!-- prior pass, because if there was an @xml:id, then it     -->
                <!-- was upgraded to being a @label and if this "choose" gets -->
                <!-- here, then the next test is false.                       -->
                <xsl:when test="@xml:id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:when>
                <!-- Author has not supplied any sort of identification, no -->
                <!-- @label and no @xml:id.  So we automatically devise one -->
                <xsl:otherwise>
                    <xsl:value-of select="$parent-id"/>
                    <xsl:text>-</xsl:text>
                    <!-- Start counting from 1, easier to debug -->
                    <xsl:number value="count(preceding-sibling::*) + 1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:attribute name="{$attr-name}">
            <xsl:value-of select="$new-id"/>
        </xsl:attribute>
        <!-- recurse -->
        <xsl:apply-templates select="node()" mode="id-attribute">
            <xsl:with-param name="parent-id" select="$new-id"/>
            <xsl:with-param name="attr-name" select="$attr-name"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<!-- There is no real purpose to put identification onto an     -->
<!-- (X)HTML element floating around as part of an interactive. -->
<xsl:template match="pf:*|xhtml:*" mode="id-attribute">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()" mode="id-attribute"/>
    </xsl:copy>
</xsl:template>

<!-- We look for duplicate identifiers both right after    -->
<!-- assembly and right after automatic generation.  The   -->
<!-- application of these templates is mixed-in to the     -->
<!-- creation of the trees.                                -->
<!-- NB: these were built as regular templates and the     -->
<!-- root of the relevant tree was passed in, this created -->
<!-- some error with the construction of the final tree:   -->
<!-- "Recursive definition of root"                        -->
<xsl:template name="duplication-check-xmlid">
    <!-- pass in all elements with @xml:id attributes -->
    <xsl:param name="nodes"/>
    <!-- 'authored' or 'generated', just influences messages -->
    <xsl:param name="purpose"/>

    <xsl:call-template name="duplication-check-attribute">
        <xsl:with-param name="nodes" select="$nodes"/>
        <xsl:with-param name="purpose" select="$purpose"/>
        <xsl:with-param name="target-attr" select="'xml:id'"/>
    </xsl:call-template>
</xsl:template>

<xsl:template name="duplication-check-label">
    <!-- pass in all elements with @label attributes -->
    <xsl:param name="nodes"/>
    <!-- 'authored' or 'generated', just influences messages -->
    <xsl:param name="purpose"/>

    <xsl:call-template name="duplication-check-attribute">
        <xsl:with-param name="nodes" select="$nodes"/>
        <xsl:with-param name="purpose" select="$purpose"/>
        <xsl:with-param name="target-attr" select="'label'"/>
    </xsl:call-template>
</xsl:template>

<xsl:template name="duplication-check-attribute">
    <xsl:param name="nodes"/>
    <!-- 'authored' or 'generated', just influences messages -->
    <xsl:param name="purpose"/>
    <xsl:param name="target-attr"/>

    <!-- construct a list of just the sorted labels -->
    <xsl:variable name="attr-values-sorted-rtf">
        <xsl:for-each select="$nodes/@*[name() = $target-attr]">
            <xsl:sort select="."/>
            <label>
                <xsl:value-of select="."/>
            </label>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="attr-values-sorted" select="exsl:node-set($attr-values-sorted-rtf)"/>

    <!-- traverse sorted list to find duplicates -->
    <xsl:for-each select="$attr-values-sorted/*">
        <!-- save off the string on current node -->
        <xsl:variable name="attr-value" select="."/>
        <!-- get previous two labels - will be '' if out of bounds -->
        <xsl:variable name="prev-value" select="string(preceding-sibling::*[1])"/>
        <xsl:variable name="prev-prev-value" select="string(preceding-sibling::*[2])"/>
        <!-- identify only first instance of a duplicate for each label -->
        <xsl:if test="($attr-value= $prev-value) and ($attr-value != $prev-prev-value)">
            <xsl:choose>
                <xsl:when test="$purpose = 'authored'">
                    <xsl:message>PTX:ERROR: the @<xsl:value-of select="$target-attr"/> value "<xsl:value-of select="$attr-value"/>" should be unique, but is authored multiple times.</xsl:message>
                </xsl:when>
            </xsl:choose>
            <xsl:message>           Results will be unpredictable, and likely incorrect.  Information on the locations follows:</xsl:message>
            <!-- use the original nodes to report location of instances -->
            <!-- select where they have an attr with the correct name and it has correct value -->
            <xsl:for-each select="$nodes[@*[name() = $target-attr] = $attr-value]">
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:for-each>
        </xsl:if>
    </xsl:for-each>
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
    <xsl:param name="ordered-list-level" />

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
    <xsl:variable name="next-ordered-list-level">
        <xsl:choose>
            <xsl:when test="self::exercises or self::worksheet or self::reading-questions or self::references">
                <xsl:number value="1" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:number value="0" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
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
            <xsl:with-param name="ordered-list-level" select="$next-ordered-list-level"/>
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

<!-- Labels of ordered lists have formatting codes, which  -->
<!-- we detect here and pass on to other more specialized  -->
<!-- templates for implementation specifics                -->
<!-- In order: Arabic (0-based), Arabic (1-based)          -->
<!-- lower-case Latin, upper-case Latin,                   -->
<!-- lower-case Roman numeral, upper-case Roman numeral    -->
<!-- Absent a label attribute, defaults go 4 levels deep   -->
<!-- (max for Latex) as: Arabic, lower-case Latin,         -->
<!-- lower-case Roman numeral, upper-case Latin            -->
<xsl:template match="ol" mode="format-code">
    <xsl:param name="level"/>
    <xsl:choose>
        <xsl:when test="@marker">
            <xsl:choose>
                <xsl:when test="contains(@marker,'0')">0</xsl:when>
                <xsl:when test="contains(@marker,'1')">1</xsl:when>
                <xsl:when test="contains(@marker,'a')">a</xsl:when>
                <xsl:when test="contains(@marker,'A')">A</xsl:when>
                <xsl:when test="contains(@marker,'i')">i</xsl:when>
                <xsl:when test="contains(@marker,'I')">I</xsl:when>
                <!-- DEPRECATED 2015-12-12 -->
                <xsl:when test="@marker=''" />
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR: ordered list label (<xsl:value-of select="@marker" />) not recognized</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:choose>
                <xsl:when test="$level='0'">1</xsl:when>
                <xsl:when test="$level='1'">a</xsl:when>
                <xsl:when test="$level='2'">i</xsl:when>
                <xsl:when test="$level='3'">A</xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR: ordered list is more than 4 levels deep (at level <xsl:value-of select="$level" />) or is inside an "exercise" and is more than 3 levels deep  (at level <xsl:value-of select="$level - 1" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="ol" mode="augment">
    <xsl:param name="ordered-list-level"/>
    <xsl:variable name="next-level" select="$ordered-list-level + 1" />
    <xsl:variable name="format-code">
        <xsl:apply-templates select="." mode="format-code">
            <xsl:with-param name="level" select="$ordered-list-level"/>
        </xsl:apply-templates>
    </xsl:variable>
    <!-- deconstruct the left and right adornments of the label   -->
    <!-- or provide default adornments, consistent with LaTeX     -->
    <!-- then store them                                          -->
    <xsl:variable name="marker-prefix">
        <xsl:choose>
            <xsl:when test="@marker">
                <xsl:value-of select="substring-before(@marker, $format-code)" />
            </xsl:when>
            <xsl:when test="$format-code = 'a' and $ordered-list-level = '1'">
                <xsl:text>(</xsl:text>
            </xsl:when>
            <xsl:otherwise />
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="marker-suffix">
        <xsl:choose>
            <xsl:when test="@marker">
                <xsl:value-of select="substring-after(@marker, $format-code)" />
            </xsl:when>
            <xsl:when test="$format-code = 'a' and $ordered-list-level = '1'">
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>.</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:copy>
        <xsl:attribute name="ordered-list-level">
            <xsl:value-of select="$ordered-list-level"/>
        </xsl:attribute>
        <xsl:attribute name="format-code">
            <xsl:value-of select="$format-code"/>
        </xsl:attribute>
        <xsl:attribute name="marker-prefix">
            <xsl:value-of select="$marker-prefix"/>
        </xsl:attribute>
        <xsl:attribute name="marker-suffix">
            <xsl:value-of select="$marker-suffix"/>
        </xsl:attribute>
        <xsl:apply-templates select="node()|@*" mode="augment">
            <xsl:with-param name="ordered-list-level" select="$next-level"/>
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
<!-- short answer, multiple choice, true/false, Parson, cardsort, fill-in, -->
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
<!-- 4.  Recognize new, modern fill-in problems                         -->

<xsl:template match="exercise|&PROJECT-LIKE;|task" mode="exercise">
    <xsl:param name="division"/>

    <xsl:copy>
        <!-- Record one of five categories for customization, which    -->
        <!-- are not relevant for "example" (always inline), or "task" -->
        <!-- (always just a component of something larger).  WeBWork   -->
        <!-- problems are interactive or static, inline or not, based  -->
        <!-- on publisher options.                                     -->
        <xsl:if test="not(self::task)">
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
        </xsl:if>
        <!-- Determine and record types of interactivity -->
        <xsl:apply-templates select="." mode="exercise-interactive-attribute"/>
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
    <xsl:attribute name="exercise-interactive">
        <xsl:choose>
            <!-- This is defensive, so statement//var below does not   -->
            <!-- match for WW.  Ancestor varies on extraction, or not. -->
            <xsl:when test="self::task and (ancestor::webwork|ancestor::webwork-reps)">
                <xsl:text>webwork-task</xsl:text>
            </xsl:when>
            <!-- WeBWorK next, signal is clear.  Again, -->
            <!-- two passes and we identify which one.  -->
            <xsl:when test="webwork and $b-extracting-pg">
                <xsl:text>webwork-authored</xsl:text>
            </xsl:when>
            <xsl:when test="webwork-reps and not(b-extracting-pg)">
                <xsl:text>webwork-reps</xsl:text>
            </xsl:when>
            <xsl:when test="myopenmath">
                <xsl:text>myopenmath</xsl:text>
            </xsl:when>
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
            <!-- vertical is default/traditional -->
            <xsl:when test="statement and blocks and not(blocks/@layout = 'horizontal')">
                <xsl:text>parson</xsl:text>
            </xsl:when>
            <xsl:when test="statement and blocks and (blocks/@layout = 'horizontal')">
                <xsl:text>parson-horizontal</xsl:text>
            </xsl:when>
            <xsl:when test="statement and cardsort">
                <xsl:text>cardsort</xsl:text>
            </xsl:when>
            <xsl:when test="statement and matching">
                <xsl:text>matching</xsl:text>
            </xsl:when>
            <xsl:when test="statement and areas">
                <xsl:text>clickablearea</xsl:text>
            </xsl:when>
            <xsl:when test="select">
                <xsl:text>select</xsl:text>
            </xsl:when>
            <!-- noted WeBWork earlier, so this is Runestone fillin -->
            <xsl:when test="statement//var">
                <xsl:text>fillin-basic</xsl:text>
            </xsl:when>
            <!-- new dynamic fillin goes here, perhaps:                     -->
            <!-- statement//fillin[(@*|node()) and not(@characters|@fill)]? -->
            <xsl:when test="statement//fillin and evaluation">
                <xsl:text>fillin</xsl:text>
            </xsl:when>
            <!-- only interactive programs make sense after a "statement" -->
            <xsl:when test="statement and program[(@interactive = 'codelens') or (@interactive = 'activecode')]">
                <xsl:text>coding</xsl:text>
            </xsl:when>
            <xsl:when test="statement and response">
                <xsl:text>shortanswer</xsl:text>
            </xsl:when>
            <!-- That's it, we are out of opportunities to be interactive -->

            <!-- A child that is a task indicates the exercise/project/task -->
            <!-- that is its parent is simply a container, rather than a    -->
            <!-- terminal task which would be structured with a "statement" -->
            <!-- in order to be interactive                                 -->
            <xsl:when test="task">
                <xsl:text>container</xsl:text>
            </xsl:when>
            <!-- Now we have what once would have been called a "traditional"     -->
            <!-- PreTeXt question, which is just "statement|hint|answer|solution" -->
            <!-- Or maybe just a bare statement that is not structured as such    -->
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
<!-- Cardsort problems -->
<!-- Matching problems -->
<!-- Clickable Area    -->
<!-- ActiveCode        -->

<!-- TODO: definitely need better filters -->
<!-- complement (not()), single attribute -->
<!-- Also in Runestone manifest creation  -->

<xsl:template match="exercise[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'cardsort') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'select') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'fillin') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')]
                      |
                      project[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'cardsort') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'select') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'fillin') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')]
                     |
                     activity[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'cardsort') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'select') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'fillin') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')]
                     |
                  exploration[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'cardsort') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'select') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'fillin') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')]
                     |
                investigation[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'cardsort') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'select') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'fillin') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')]
                     |
                         task[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'cardsort') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'select') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'fillin') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')]" mode="representations">
    <!-- always preserve "exercise/project" container here, with attributes -->
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

<!-- Static (non-interactive) -->
<!-- @exercise-interactive = 'static' needs no adjustments -->

<!-- Mine webwork-reps for relevant application -->

<!-- Matching with the filter means this will only happen on     -->
<!-- the non-extraction pass, since the 'webwork-reps' value     -->
<!-- is placed after the WW representations file has been built. -->
<!-- We split three ways, for PGML, static, and dynamic (HTML)   -->
<!-- employment, via modal templates.                            -->
<!-- NB: including "task" though this may not be supported.      -->
<xsl:template match="exercise[(@exercise-interactive = 'webwork-reps')]
                   | project[(@exercise-interactive = 'webwork-reps')]
                   | activity[(@exercise-interactive = 'webwork-reps')]
                   | exploration[(@exercise-interactive = 'webwork-reps')]
                   | investigation[(@exercise-interactive = 'webwork-reps')]" mode="representations">
    <xsl:choose>
        <!-- destined for creating problem sets, really just need PG code -->
        <xsl:when test="$exercise-style = 'pg-problems'">
            <!-- duplicate exercise, task, PROJECT-LIKE -->
            <xsl:copy>
                <!-- and duplicate the associated attributes, while moving to new mode -->
                <xsl:apply-templates select="@*" mode="webwork-rep-to-pg"/>
                <!-- for building problem sets, we do not need much metadata,      -->
                <!-- nor the connecting "introduction" or "conclusion", we just    -->
                <!-- want to make the PG code available in a predictable way       -->
                <!-- (see templates following).  But we do need a title for naming -->
                <!-- files and building the set definition files pointing to them. -->
                <xsl:apply-templates select="title" mode="webwork-rep-to-pg"/>
                <xsl:apply-templates select="webwork-reps" mode="webwork-rep-to-pg"/>
            </xsl:copy>
        </xsl:when>
        <!-- static, for multiple conversions, but primarily LaTeX -->
        <xsl:when test="$exercise-style = 'static'">
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="webwork-rep-to-static"/>
            </xsl:copy>
        </xsl:when>
        <!-- dynamic (aka HTML), needs static previews, server base64, etc, -->
        <!-- so just copy as-is with "webwork-reps" to signal and organize  -->
        <!-- to/for HTML conversion                                         -->
        <xsl:otherwise>
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="webwork-rep-to-html"/>
            </xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Edit a "webwork-reps" from the server into just PG material -->
<xsl:template match="node()|@*" mode="webwork-rep-to-pg">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="webwork-rep-to-pg"/>
    </xsl:copy>
</xsl:template>

<!-- Promote "pg" specific information to "webwork-reps" -->
<xsl:template match="webwork-reps" mode="webwork-rep-to-pg">
    <xsl:copy>
        <!-- copy existing attributes -->
        <xsl:apply-templates select="@*" mode="webwork-rep-to-pg"/>
        <!-- promote "pg" attributes (@source, @copied-from) -->
        <xsl:apply-templates select="pg/@*" mode="webwork-rep-to-pg"/>
        <!-- attributes done, recurse into child *elements*  -->
        <!-- no node() here, so drops interstial whitespace  -->
        <!-- that accumulates into the textual PG code, even -->
        <!-- if it does get sanitized in its use/application -->
        <xsl:apply-templates select="*" mode="webwork-rep-to-pg"/>
    </xsl:copy>
</xsl:template>

<!-- Attributes preserved, drop "pg" element, duplicate the guts -->
<!-- which should just be the actual PG version of the problem   -->
<xsl:template match="webwork-reps/pg" mode="webwork-rep-to-pg">
    <xsl:apply-templates select="node()" mode="webwork-rep-to-pg"/>
</xsl:template>

<!-- Drop "webwork-reps" children we don't need for problem sets -->
<xsl:template match="webwork-reps/static" mode="webwork-rep-to-pg"/>
<xsl:template match="webwork-reps/server-data" mode="webwork-rep-to-pg"/>


<!-- Static from webwork-reps as a generic exercise  -->
<!-- Edit a "webwork-reps" from the server into guts -->
<!-- of a static exercise or PROJECT-LIKE            -->

<!-- Kill author's lead-in/lead-out material on sight, we recreate -->
<!-- their children with "node()" in main reorganization template  -->
<xsl:template match="introduction[following-sibling::webwork-reps]" mode="webwork-rep-to-static"/>
<xsl:template match="conclusion[preceding-sibling::webwork-reps]" mode="webwork-rep-to-static"/>

<!-- Meld an author's "introduction" and "conclusion" into          -->
<!-- (a) the similarly-named items of a task-structured object      -->
<!-- (b) the statement of an object with a simpler structure        -->
<!-- We recurse into (many, principal) selected components of       -->
<!-- webwork-reps/static which effectively ignores  webwork-reps/pg -->
<!-- and  webwork-reps/server  so these pieces never make it into   -->
<!-- the assembled source.                                          -->
<!--                                                                -->
<!-- NB: we lose some attributes attached above to                  -->
<!-- "introduction" and "conclusion" (not "exercise"), BUT          -->
<!--   (i) we cannot point *into* a WW problem (no targets)         -->
<!--   (ii) we do not have numbered items (eg Figure)               -->
<!--   (iii) by removing them, we just disrupt any                  -->
<!--         sequences, and uniqueness is preserved                 -->
<!--   (iv) we could figure out which ones to copy where, if needed -->
<!-- NB: a possible refactor here:                                  -->
<!-- (i)  kill all the children of "webwork-reps", barring "static" -->
<!--      (currently they are just ignored)                         -->
<!-- (ii) rerwrite this template to have "static" as the context.   -->
<!--      This would mean adjust some paths to go one more step up  -->
<!--      to find things like "introduction".                       -->
<!-- Consequence: when leveraged for HTML previews this rearrangment-->
<!-- will be a big change.  Not clear if it is a desirable change.  -->
<xsl:template match="webwork-reps" mode="webwork-rep-to-static">
    <xsl:choose>
        <!-- a WW "staged" exercise, may have an top-level introduction and -->
        <!-- conclusion already, and does not have a top-level statement    -->
        <xsl:when test="static/task">
            <xsl:if test=".//introduction|static/introduction">
                <introduction>
                    <xsl:apply-templates select="../introduction/node()" mode="webwork-rep-to-static"/>
                    <xsl:apply-templates select="static/introduction/node()" mode="webwork-rep-to-static"/>
                </introduction>
            </xsl:if>
            <xsl:apply-templates select="static/task" mode="webwork-rep-to-static"/>
            <xsl:if test="../conclusion|static/conclusion">
                <conclusion>
                    <xsl:apply-templates select="../conclusion/node()" mode="webwork-rep-to-static"/>
                    <xsl:apply-templates select="static/conclusion/node()" mode="webwork-rep-to-static"/>
                </conclusion>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <statement>
                <xsl:apply-templates select="../introduction/node()" mode="webwork-rep-to-static"/>
                <xsl:apply-templates select="static/statement/node()" mode="webwork-rep-to-static"/>
                <xsl:apply-templates select="../conclusion/node()" mode="webwork-rep-to-static"/>
            </statement>
            <xsl:apply-templates select="static/hint" mode="webwork-rep-to-static"/>
            <xsl:apply-templates select="static/answer" mode="webwork-rep-to-static"/>
            <xsl:apply-templates select="static/solution" mode="webwork-rep-to-static"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Good time to clean-up what came back from a WW server.     -->
<!-- As part of the "webwork-rep-to-static" mode, we can be     -->
<!-- sure that only returns from the server are being adjusted. -->

<!-- From the code comment when this was done with Python: "p with -->
<!-- only a single fillin, not counting those inside an li without -->
<!-- preceding siblings"                                           -->
<xsl:template match="p" mode="webwork-rep-to-static">
    <!-- Substantially faster to have a simple match and then selectively -->
    <!-- filter matched elements. Start with the tests that are cheapest  -->
    <!-- and hope short-circuit evaluation avoids expensive ones.         -->
    <xsl:variable name="prune">
        <xsl:if test="count(fillin)=1 and 
                      count(*)=1 and 
                      not(normalize-space(text())) and
                      (not(parent::li) or preceding-sibling::*)">
            <xsl:value-of select="true()"/>
        </xsl:if>
    </xsl:variable>
    <xsl:if test="$prune != 'true'">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="webwork-rep-to-static"/>
        </xsl:copy>
    </xsl:if>
</xsl:template>


<!-- Some answer forms return a default/initial choice that is -->
<!-- simply a question-mark.  We scrub them here, with care.   -->
<xsl:template match="statement//var[@form = 'popup']/li[(p[. = '?']) or (normalize-space(.) = '?')]" mode="webwork-rep-to-static"/>
<!-- This may only be needed as support for older servers' generated PreTeXt. -->
<xsl:template match="statement//var[@form = 'checkboxes']/li[(p[. = '?']) or (normalize-space(.) = '?')]" mode="webwork-rep-to-static"/>

<!-- "var/@form" come back from the server as a result of authored -->
<!-- "answer forms" and should be rendered as lists in static      -->
<!-- representations.                                              -->
<!-- NB: this does not preclude the match below (scrubbing default -->
<!-- items) from functioning.                                      -->
<xsl:template match="statement//var[@form]" mode="webwork-rep-to-static">
    <ul>
        <!-- duplicate attributes, but for @form -->
        <xsl:apply-templates select="@*[not(name() = 'form')]" mode="repair"/>
        <!-- internal attribute to indicate WW origins -->
        <xsl:attribute name="pi:ww-form">
            <xsl:value-of select="@form"/>
        </xsl:attribute>
        <!-- add a marker for an unordered list -->
        <xsl:attribute name="marker">
            <xsl:choose>
                <xsl:when test="@form = 'popup'">
                    <xsl:text>square</xsl:text>
                </xsl:when>
                <xsl:when test="@form = 'buttons'">
                    <xsl:text>circle</xsl:text>
                </xsl:when>
                <xsl:when test="@form = 'checkboxes'">
                    <xsl:text>square</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates select="node()" mode="webwork-rep-to-static"/>
    </ul>
</xsl:template>

<!-- Default xeroxing template -->
<xsl:template match="node()|@*" mode="webwork-rep-to-static">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="webwork-rep-to-static"/>
    </xsl:copy>
</xsl:template>

<!-- Edit a "webwork-reps" from the server into just HTML material -->

<!-- We have a static version that gets employed in the HTML conversion -->
<!-- as a "preview" before a reader hits an "Activate" button.  We are  -->
<!-- leveraging the clean-up of static versions here.                   -->
<!-- NB: for historical reasons, and so as to get a clean refactor, we  -->
<!-- apply this modal template to "static" which is a level lower down  -->
<!-- than its complete implementation, which starts at "webwork-reps".  -->
<!-- This means that there is no rearrangement of the overall           -->
<!-- "introduction" into the "statement".  But see the comments about a -->
<!-- potential refactor of the "webwork-rep-to-static" templates.       -->
<xsl:template match="static" mode="webwork-rep-to-html">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="webwork-rep-to-static"/>
    </xsl:copy>
</xsl:template>

<!-- Default xeroxing template -->
<xsl:template match="node()|@*" mode="webwork-rep-to-html">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="webwork-rep-to-html"/>
    </xsl:copy>
</xsl:template>

<!-- MyOpenMath (MOM) to static -->

<!-- Static versions come from a MOM server, and have been stored  -->
<!-- as a "generated" component of a project.  We meld with a      -->
<!-- PreTeXt introduction and conclusion, into a "regular" PreTeXt -->
<!-- format, for any conversion to a static format to use.         -->
<xsl:template match="exercise[(@exercise-interactive = 'myopenmath')]
                   | project[(@exercise-interactive = 'myopenmath')]
                   | activity[(@exercise-interactive = 'myopenmath')]
                   | exploration[(@exercise-interactive = 'myopenmath')]
                   | investigation[(@exercise-interactive = 'myopenmath')]" mode="representations">
    <!-- duplicate the exercise/project -->
    <xsl:copy>
        <!-- and preserve attributes on the exercise/project -->
        <xsl:apply-templates select="@*" mode="representations"/>
        <!-- Now bifurcate on static/dynamic.  PG problem creation should not fall in here. -->
        <xsl:choose>
            <xsl:when test="($exercise-style = 'static') and not($b-extracting-pg)">
                <!-- locate the static representation in a file, generated independently -->
                <!-- NB: this filename is relative to the author's source                -->
                <xsl:variable name="filename">
                    <xsl:if test="$b-managed-directories">
                        <xsl:value-of select="$generated-directory-source"/>
                    </xsl:if>
                    <xsl:text>problems/mom-</xsl:text>
                    <xsl:value-of select="myopenmath/@problem"/>
                    <xsl:text>.xml</xsl:text>
                </xsl:variable>
                <!-- "myopenmath" child guaranteed by @exercise-interactive value -->
                <xsl:variable name="mom-static-rep" select="document($filename, $original)/myopenmath"/>
                <!-- duplicate metadata first -->
                <xsl:apply-templates select="title|idx" mode="representations"/>
                <!-- Meld PreTeXt introduction, conclusion with MOM statement. We could -->
                <!-- duplicate MOM/statement attributes here, if there were any.        -->
                <statement>
                    <xsl:apply-templates select="introduction/node()" mode="representations"/>
                    <xsl:apply-templates select="$mom-static-rep/statement/node()" mode="representations"/>
                    <xsl:apply-templates select="conclusion/node()" mode="representations"/>
                </statement>
                <!-- these might not all be present, ever, but just to be safe -->
                <xsl:apply-templates select="$mom-static-rep/hint" mode="representations"/>
                <xsl:apply-templates select="$mom-static-rep/answer" mode="representations"/>
                <xsl:apply-templates select="$mom-static-rep/solution" mode="representations"/>
                <!-- NB: the "myopenmath" element has been ignored is now gone -->
            </xsl:when>
            <xsl:when test="($exercise-style = 'dynamic') or ($exercise-style = 'pg-problems')">
                <!-- duplicate authored content for the non-static conversions -->
                <xsl:apply-templates select="node()" mode="representations"/>
            </xsl:when>
        </xsl:choose>
    </xsl:copy>
</xsl:template>

<xsl:template match="datafile|query" mode="representations">
    <xsl:choose>
        <!-- make a static version, in a PreTeXt style -->
        <!-- for use naturally by most conversions     -->
        <xsl:when test="$exercise-style = 'static'">
            <xsl:apply-templates select="." mode="runestone-to-static"/>
        </xsl:when>
        <!-- duplicate for a dynamic version -->
        <xsl:when test="$exercise-style = 'dynamic'">
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="representations"/>
            </xsl:copy>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Static versions of Audio, Video, Interactives -->

<!-- This variable will be overriden during an extraction used to write image files -->
<xsl:variable name="mermaid-extracting"><xsl:value-of select="false()"/></xsl:variable>
<xsl:template match="image[mermaid]" mode="representations">
    <xsl:choose>
        <xsl:when test="$mermaid-extracting = 'false'">
            <!-- Generating document -->
            <xsl:choose>
                <xsl:when test="$exercise-style = 'dynamic'">
                    <!-- interactive target -->
                    <xsl:copy>
                        <xsl:apply-templates select="node()|@*" mode="representations"/>
                    </xsl:copy>
                </xsl:when>
                <xsl:when test="$exercise-style = 'static'">
                    <!-- static target -->
                    <image>
                        <xsl:attribute name="pi:generated">
                            <xsl:text>mermaid/</xsl:text>
                            <xsl:apply-templates select="." mode="assembly-id"/>
                            <xsl:choose>
                                <!-- latex-print will be B&W target -->
                                <xsl:when test="$b-latex-print">
                                    <xsl:text>-bw.png</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>-color.png</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                    </image>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <!-- Extracting Mermaid -->
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="representations"/>
            </xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Form a PreTeXt side-by-side with an image, a QR code and links -->

<xsl:template match="audio|video|interactive[not(static)]" mode="representations">
    <xsl:variable name="the-url">
        <xsl:apply-templates select="." mode="static-url"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$exercise-style = 'static'">
            <!-- panel widths are experimental -->
            <sidebyside margins="7.5% 7.5%" widths="47% 21%" valign="top" halign="center">
                <xsl:choose>
                    <!-- @preview present, so author provides a static image  -->
                    <!--                                                      -->
                    <!-- "video" is exceptional, we allow for a generic image -->
                    <xsl:when test="self::video and (@preview = 'generic')">
                        <image>
                            <xsl:attribute name="pi:generated">
                                <xsl:text>play-button/play-button.png</xsl:text>
                            </xsl:attribute>
                        </image>
                    </xsl:when>
                    <!--  -->
                    <xsl:when test="@preview">
                        <image>
                            <xsl:attribute name="source">
                                <xsl:value-of select="@preview"/>
                            </xsl:attribute>
                        </image>
                    </xsl:when>
                    <!-- semi-automatic images vary by format     -->
                    <!--                                          -->
                    <!-- interactive: screenshots with playwright -->
                    <!-- video: we scrape YouTube, only           -->
                    <!--        YouTube playlist gets generic     -->
                    <!-- audio: immature                          -->
                    <xsl:when test="self::interactive">
                        <image>
                            <xsl:attribute name="pi:generated">
                                <xsl:text>preview/</xsl:text>
                                <xsl:apply-templates select="." mode="assembly-id"/>
                                <xsl:text>-preview.png</xsl:text>
                            </xsl:attribute>
                        </image>
                    </xsl:when>
                    <!--  -->
                    <xsl:when test="self::video and @youtube">
                        <image>
                            <xsl:attribute name="pi:generated">
                                <xsl:text>youtube/</xsl:text>
                                <xsl:apply-templates select="." mode="assembly-id"/>
                                <xsl:text>.jpg</xsl:text>
                            </xsl:attribute>
                        </image>
                    </xsl:when>
                    <!--  -->
                    <xsl:when test="self::video and @youtubeplaylist">
                        <image>
                            <xsl:attribute name="pi:generated">
                                <xsl:text>play-button/play-button.png</xsl:text>
                            </xsl:attribute>
                        </image>
                    </xsl:when>
                    <!--  -->
                    <xsl:when test="self::audio">
                        <p>No static image provided via <c>@preview</c> attribute</p>
                    </xsl:when>
                    <!--  -->
                    <xsl:otherwise>
                        <p>BUG: PREVIEW NOT HANDLED</p>
                    </xsl:otherwise>
                </xsl:choose>
                <stack>
                    <!-- 2023-02-07: wrapping in a URL failed    -->
                    <!-- for a LaTeX build of the sample article -->
                    <image>
                        <xsl:attribute name="pi:generated">
                            <xsl:text>qrcode/</xsl:text>
                            <xsl:apply-templates select="." mode="assembly-id"/>
                            <xsl:text>.png</xsl:text>
                        </xsl:attribute>
                    </image>
                    <!-- URL templates create empty strings as signals URLs do not (yet) exist -->
                    <!-- We kill the automatic footnotes, a debatable decision                 -->
                    <!--  -->
                    <xsl:variable name="standalone-url">
                        <xsl:apply-templates select="." mode="standalone-url"/>
                    </xsl:variable>
                    <xsl:if test="not($standalone-url = '')">
                        <p>
                            <url href="{$standalone-url}" visual="">
                                <xsl:text>Standalone</xsl:text>
                            </url>
                        </p>
                    </xsl:if>
                    <!--  -->
                    <xsl:variable name="embed-iframe-url">
                        <xsl:apply-templates select="." mode="embed-iframe-url"/>
                    </xsl:variable>
                    <xsl:if test="not($embed-iframe-url = '')">
                        <p>
                            <!-- Kill the automatic footnote    -->
                            <url href="{$embed-iframe-url}" visual="">
                                <xsl:text>Embed</xsl:text>
                            </url>
                        </p>
                    </xsl:if>
                    <!--  -->
                </stack>
            </sidebyside>
        </xsl:when>
        <xsl:when test="($exercise-style = 'dynamic') or ($exercise-style = 'pg-problems')">
            <!-- duplicate authored content for the non-static conversions -->
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="representations"/>
            </xsl:copy>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- If a "static" is given, just copy it's children -->
<xsl:template match="interactive[static]" mode="representations">
    <xsl:choose>
        <!-- duplicate the contents of an alternative "static" element -->
        <xsl:when test="$exercise-style = 'static'">
            <xsl:apply-templates select="static" mode="representations"/>
        </xsl:when>
        <xsl:when test="($exercise-style = 'dynamic') or ($exercise-style = 'pg-problems')">
            <!-- duplicate authored content for the non-static conversions -->
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="representations"/>
            </xsl:copy>
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- ###################################### -->
<!-- Static versions of Interactive Content -->
<!-- ###################################### -->

<!-- Templates for the pre-processor (and other stylesheets) to use -->
<!-- for the creation of static versions of interactive content.    -->

<!-- The HTML conversion generates "standalone" pages for videos   -->
<!-- and other interactives.  Then the LaTeX conversion will make  -->
<!-- links to these pages (eg, via QR codes).  And we might use    -->
<!-- these pages as the basis for scraping preview images.  So we  -->
<!-- place a template here to achieve consistency across uses.     -->
<!--                                                               -->
<!-- We need to always import this assembly stylesheet, so these   -->
<!-- templates will be available in all conversions, but notably   -->
<!-- in the creation of a "universal" static version of the        -->
<!-- document ("assembly-static" in the pretext/pretext script)    -->
<!-- which is fed to specific conversion into static output        -->
<!-- formats (e.g. LaTeX, braille).  As such, these templates      -->
<!-- should                                                        -->
<!--   (a) be applied someplace as part of the assembly process    -->
<!--   (b) produce only text (i.e. not XML, not HTML, not LaTeX)   -->


<!-- NB: it could be tempting to change the next template to stuff -->
<!-- these "iframe" files into a dedicated directory.  Even though -->
<!-- this template ensures some consistency, a pile of links still -->
<!-- need to change, such as the "script" tag for locations of     -->
<!-- extra JS as part of making one of these go.                   -->
<xsl:template match="audio|video|interactive" mode="iframe-filename">
    <xsl:apply-templates select="." mode="assembly-id" />
    <xsl:text>-if.html</xsl:text>
</xsl:template>

<xsl:template match="audio|video|interactive" mode="standalone-filename">
    <xsl:apply-templates select="." mode="assembly-id" />
    <xsl:text>.html</xsl:text>
</xsl:template>
<xsl:template match="*" mode="standalone-filename">
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>-ERROR-no-standalone-filename.html</xsl:text>
</xsl:template>

<xsl:template match="exercise[@exercise-interactive='fillin' and setup]
                   | project[@exercise-interactive='fillin' and setup]
                   | activity[@exercise-interactive='fillin' and setup]
                   | exploration[@exercise-interactive='fillin' and setup]
                   | investigation[@exercise-interactive='fillin' and setup]"
                   mode="standalone-filename">
    <xsl:apply-templates select="." mode="assembly-id" />
    <xsl:text>.html</xsl:text>
</xsl:template>

<xsl:template match="exercise[//task/@exercise-interactive='fillin' and //task/setup]
                   | project[//task/@exercise-interactive='fillin' and //task/setup]
                   | activity[//task/@exercise-interactive='fillin' and //task/setup]
                   | exploration[//task/@exercise-interactive='fillin' and //task/setup]
                   | investigation[//task/@exercise-interactive='fillin' and //task/setup]"
                   mode="standalone-filename">
    <xsl:apply-templates select="." mode="assembly-id" />
    <xsl:text>.html</xsl:text>
</xsl:template>

<xsl:template match="*" mode="standalone-filename">
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>-ERROR-no-standalone-filename.html</xsl:text>
</xsl:template>

<xsl:template match="audio|video|interactive" mode="standalone-url">
    <xsl:if test="$b-has-baseurl">
        <xsl:value-of select="$baseurl"/>
        <xsl:apply-templates select="." mode="standalone-filename" />
    </xsl:if>
    <!-- empty without a baseurl -->
</xsl:template>

<xsl:template match="audio|video|interactive" mode="embed-iframe-url">
    <xsl:if test="$b-has-baseurl">
        <xsl:value-of select="$baseurl"/>
        <xsl:apply-templates select="." mode="iframe-filename" />
    </xsl:if>
    <!-- empty without a baseurl -->
</xsl:template>

<!-- These interactives *are* iFrames, so we don't build a dedicated   -->
<!-- page to make them into iFrames.  Over in -html we construct a URL -->
<!-- for each one, embedded in a iFrame construction.  We need to work -->
<!-- out the right thing to do for an "Embed" link in static formats.  -->
<!-- For now, an empty result means no link in sttic formats.          -->
<!-- NB: coordinate with "create-iframe-page" in -html                 -->
<xsl:template match="audio|video"  mode="embed-iframe-url"/>
<xsl:template match="interactive[@desmos|@geogebra|@calcplot3d|@circuitjs|@iframe]"  mode="embed-iframe-url"/>


<!-- Static URL's -->
<!-- Predictable and/or stable URLs for versions         -->
<!-- of interactives available online.  These are        -->
<!--                                                     -->
<!--   (1) "standalone" pages for author/local material, -->
<!--       as a product of the HTML conversion           -->
<!--   (2) computable addresses of network resources,    -->
<!--       eg the YouTube page of a resource             -->

<!-- Point to HTML-produced, and canonically-hosted, standalone page -->
<!-- NB: baseurl is assumed to have a trailing slash                 -->

<xsl:template match="audio[@source|@href]|video[@source|@href]|interactive" mode="static-url">
    <xsl:value-of select="$baseurl"/>
    <xsl:apply-templates select="." mode="standalone-filename" />
</xsl:template>

<!-- Natural override for YouTube videos               -->
<!-- Better - standalone page, with "View on You Tube" -->

<!-- NB: ampersand is escaped for LaTeX use, be careful with switch to QR codes via Python! -->
<!-- POTENTIAL BUG: this should be un-LaTeX'ed for general use and then  -->
<!-- sanitized on the receiving end in the LaTeX conversion, or maybe    -->
<!-- the LaTeX conversion will do just fine if the right URL package is  -->
<!-- used and the ampersand is handled correctly?                        -->

<xsl:template match="video[@youtube|@youtubeplaylist]" mode="static-url">
    <xsl:apply-templates select="." mode="youtube-view-url" />
    <xsl:if test="@start">
        <xsl:text>\&amp;start=</xsl:text>
        <xsl:value-of select="@start" />
    </xsl:if>
    <xsl:if test="@end">
        <xsl:text>\&amp;end=</xsl:text>
        <xsl:value-of select="@end" />
    </xsl:if>
</xsl:template>

<xsl:template match="video[@youtube|@youtubeplaylist]" mode="youtube-view-url">
    <xsl:variable name="youtube">
        <xsl:choose>
            <xsl:when test="@youtubeplaylist">
                <xsl:value-of select="normalize-space(@youtubeplaylist)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="normalize-space(str:replace(@youtube, ',', ' '))" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>https://www.youtube.com/</xsl:text>
    <xsl:choose>
        <xsl:when test="@youtubeplaylist">
            <xsl:text>playlist?list=</xsl:text>
            <xsl:value-of select="$youtube" />
        </xsl:when>
        <xsl:when test="contains($youtube, ' ')">
            <xsl:text>watch_videos?video_ids=</xsl:text>
            <xsl:value-of select="str:replace($youtube, ' ', ',')" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>watch?v=</xsl:text>
            <xsl:value-of select="$youtube" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Vimeo view URL -->
<xsl:template match="video[@vimeo]" mode="static-url">
    <xsl:text>https://vimeo.com/</xsl:text>
    <xsl:value-of select="@vimeo"/>
</xsl:template>

<!-- A bit different than above, but same mode -->
<!-- When a "datafile" is produced in a static -->
<!-- context, then we append the $baseurl, and -->
<!-- provide the external directory.           -->
<xsl:template match="dataurl[@source]" mode="static-url">
    <xsl:value-of select="$baseurl"/>
    <!-- empty when not using managed directories -->
    <xsl:value-of select="$external-directory"/>
    <xsl:apply-templates select="@source" />
</xsl:template>

<!-- The contents of a datafile may be encoded as text in an XML   -->
<!-- file within the generated/datafile directory.  The filename   -->
<!-- has this construction, even if we do not always consult it.   -->
<!-- NB: these XML files will be read with a "document()" call,    -->
<!-- with a path relative to the author's main source file, hence  -->
<!-- the filename uses the directory name in author's source.      -->
<!-- NB: identical code in static constructions.                   -->
<xsl:template match="datafile" mode="datafile-filename">
    <xsl:value-of select="$generated-directory-source"/>
    <xsl:text>datafile/</xsl:text>
    <!-- context is "datafile", the basis for identifier -->
    <!-- ned an early identifier in assembly phase       -->
    <xsl:apply-templates select="." mode="assembly-id"/>
    <xsl:text>.xml</xsl:text>
</xsl:template>

<!-- The actual text contents of a "datafile", specified in a "pre" element.  -->
<!-- We assume (enforce) a "pre" child.  Then actual text comes authored in   -->
<!-- the source "pre" element or in an author-provided external file.         -->
<xsl:template match="datafile[pre]" mode="datafile-text-contents">
    <xsl:choose>
        <!-- via an external file -->
        <!-- Once upon a time, we hit the text from a file with   -->
        <!-- "sanitize-text".  This was a bad idea because        -->
        <!--   (a) the manipulations (especially pad-length (?) ) -->
        <!--       caused a false infinite recursion warning, and -->
        <!--   (b) the file should be *exactly* what is desired.  -->
        <xsl:when test="pre/@source">
            <!-- filename is relative to author's source -->
            <xsl:variable name="data-filename">
                <xsl:apply-templates select="."  mode="datafile-filename"/>
            </xsl:variable>
            <xsl:variable name="text-file-elt" select="document($data-filename, $original)/pi:text-file"/>
            <xsl:value-of select="$text-file-elt"/>
        </xsl:when>
        <!-- via source "pre" element content -->
        <xsl:otherwise>
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text">
                    <xsl:value-of select="pre"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>
