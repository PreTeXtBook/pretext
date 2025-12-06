<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2013 Robert A. Beezer

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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    xmlns:dyn="http://exslt.org/dynamic"
    extension-element-prefixes="pi exsl date str dyn"
    xmlns:mb="https://pretextbook.org/"
    xmlns:pf="https://prefigure.org"
    exclude-result-prefixes="mb"
>

<!-- PreTeXt common templates                             -->
<!-- Text creation/manipulation common to HTML, TeX, Sage -->

<!-- This collection of XSL routines is like a base library,          -->
<!-- it has no entry template and hence used by itself almost         -->
<!-- nothing should happen.  Typically the situation looks like this: -->
<!-- (example is LaTeX-specific but generalizes easily)               -->
<!--                                                                  -->
<!-- your-book-latex.xsl                                              -->
<!--   (a) is what you use on the command line                        -->
<!--   (b) contains very specific, atomic overrides for your project  -->
<!--   (c) imports xsl/pretext-latex.xsl                             -->
<!--                                                                  -->
<!-- xsl/pretext-latex.xsl                                           -->
<!--   (a) general conversion from PTX to LaTeX                       -->
<!--   (b) could be used at the command line for default conversion   -->
<!--   (c) imports xsl/pretext-common.xsl                            -->
<!--                                                                  -->
<!-- xsl/pretext-common.xsl                                          -->
<!--   (a) this file                                                  -->
<!--   (b) ensures commonality, such as text versions                 -->
<!--       of numbers for theorems, equations, etc                    -->
<!--   (c) has some abstract routines that require implementation     -->
<!--       in files above, such as file wrapping for a LaTeX file     -->
<!--       in this case                                               -->
<!--                                                                  -->
<!-- This creates a linear sequence of imports, so overrides          -->
<!-- behave as you might expect or predict.                           -->
<!-- To do otherwise is to invite confusion.                          -->

<!-- Output methods here are just pure text -->
<xsl:output method="text" />

<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!-- These here are independent of the output format as well                  -->

<!-- Author tools are for drafts, mostly "todo" items  -->
<!-- and "provisional" citations and cross-references  -->
<!-- Default is to hide todo's, inline provisionals    -->
<!-- Otherwise ('yes'), todo's show in red paragraphs, -->
<!-- provisional cross-references show in red          -->
<xsl:param name="author.tools" select="''" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<!-- The single quote character cannot be directly     -->
<!-- used in a string in XSLT functions, not even as   -->
<!-- &apos;. But if it is stored as a variable, then   -->
<!-- XSLT 1.0 will be OK with using $apos.             -->
<!-- Use like "concat('L',$apos,'Hospital')"           -->
<!-- Unicode Character 'APOSTROPHE' (U+0027)           -->
<xsl:variable name="apos">&#x0027;</xsl:variable>

<!-- Here we perform manipulations of math elements and subsequent  -->
<!-- text nodes that lead with punctuation.  Basically, punctuation -->
<!-- can migrate from the start of the text node and into the math, -->
<!-- wrapped in a \text{}.  We generally do this to display math as -->
<!-- a service to authors.  MathJax needs help for inline math.     -->
<!-- Braille and audio do not do so well with this manipulation.    -->
<!-- These variables are meant to be set by other stylesheets in    -->
<!-- various situations and there should be no cause for authors to -->
<!-- change them (this no elaborate error-checking, etc.)           -->
<xsl:variable name="math.punctuation.include" select="'none'"/>
<xsl:variable name="b-include-inline"
    select="($math.punctuation.include = 'inline')  or ($math.punctuation.include = 'all')"/>
<xsl:variable name="b-include-display"
    select="($math.punctuation.include = 'display') or ($math.punctuation.include = 'all')"/>

<!-- We set this variable a bit differently -->
<!-- for different conversions, so this is  -->
<!-- basically an abstract implementation   -->
<xsl:variable name="chunk-level" select="number(0)"/>

<!-- Inline Exercises can optionally run on their own numbering scheme -->
<!-- This is set (temporarily) in docinfo, which will change           -->
<!-- We do no special error-checking here since this will change       -->
<!-- The variable will be empty if not set                             -->
<xsl:variable name="numbering-exercises">
    <xsl:value-of select="$docinfo/numbering/exercises/@level"/>
</xsl:variable>

<!-- Figure-Like can optionally run on their own numbering scheme      -->
<!-- This is set (temporarily) in docinfo, which will change           -->
<!-- We do no special error-checking here since this will change       -->
<!-- The variable will be empty if not set                             -->
<xsl:variable name="numbering-figures">
    <xsl:value-of select="$docinfo/numbering/figures/@level"/>
</xsl:variable>

<!-- The pre-processing stylesheet ("pretext-assembly.xsl") guarantees   -->
<!-- a root "pretext" element with a valid @xml:lang, even if it is the  -->
<!-- default "en-US".                                                    -->
<xsl:variable name="document-language">
    <xsl:value-of select="$root/@xml:lang"/>
</xsl:variable>

<!-- An author may elect to place a unique string into   -->
<!-- the docinfo/document-id element and conversions may -->
<!-- use this to distinguish one document from another.  -->
<!-- The global variable here is empty to signal         -->
<!-- "no choice" by the author.                          -->
<!-- NB: at some point this should be specified as an    -->
<!-- attribute, rather than as content, which would make -->
<!-- things like newlines less likely to appear.  Much   -->
<!-- as "doucment-id/@edition" is given.  Keep the       -->
<!-- normalizationcan, it just becomes less necessary.   -->
<xsl:variable name="document-id">
    <xsl:value-of select="normalize-space($docinfo/document-id)"/>
</xsl:variable>

<!-- And an edition is critical for maintaing the -->
<!-- Runestone database, though it may have other -->
<!-- uses related to maintaining changes.         -->
<xsl:variable name="edition">
    <xsl:value-of select="normalize-space($docinfo/document-id/@edition)"/>
</xsl:variable>

<!-- The new version can return to the generic version  -->
<!-- once we kill the dashed version for author use.    -->
<xsl:variable name="author-tools-new">
    <xsl:choose>
        <!-- respect old switch, if set properly -->
        <!-- but don't error check or anything   -->
        <xsl:when test="$author-tools = 'yes'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:when test="$author-tools = 'no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <xsl:when test="$author.tools = 'yes'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:when test="$author.tools = 'no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- could error-check not-empty here -->
        <!-- default is "no"                  -->
        <xsl:otherwise>
            <xsl:text>no</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>


<!-- ############### -->
<!-- Source Analysis -->
<!-- ############### -->

<!-- We check certain aspects of the source and record the results  -->
<!-- in boolean ($b-has-*) variables or as particular nodes high    -->
<!-- up in the structure ($document-root).  Scans here in -common   -->
<!-- should be short and definite (no searching paths with //!),    -->
<!-- and universally useful, largely conveniences for consistency.  -->
<!-- Remember that many basic templates are shared out of this      -->
<!-- file for often very simple conversions (e.g. extractions)      -->
<!-- so excessive setup is an unnecessary drain on processing time. -->
<!-- $root, $docinfo, $document-root are a product of the           -->
<!-- "pretext-assembly.xsl" stylesheet                              -->

<!-- "book" and "article" are sometimes different, esp. for LaTeX -->
<xsl:variable name="b-is-book"    select="$document-root/self::book" />
<xsl:variable name="b-is-article" select="$document-root/self::article" />
<!-- w/, w/o parts induces variants -->
<xsl:variable name="b-has-parts" select="boolean($root/book/part)" />


<!-- Some groups of elements are counted distinct -->
<!-- from other blocks.  A configuration element  -->
<!-- in "docinfo" is indicative of this           -->
<!-- Note: the "docinfo/numbering" signals will     -->
<!-- move to the publisher file once numbering gets -->
<!-- refactored.  The elements work as signals, but -->
<!-- actual usage needs @level to be effective.     -->
<xsl:variable name="b-number-figure-distinct" select="boolean($docinfo/numbering/figures)" />
<!-- project historical default, switch it     -->
<!-- 2021-07-02: debug variable is unsupported -->
<xsl:variable name="b-number-project-distinct" select="$debug.project.number = ''" />
<!-- historically false -->
<xsl:variable name="b-number-exercise-distinct" select="boolean($docinfo/numbering/exercises)" />

<!-- File extensions can be set globally for a conversion, -->
<!-- we set it here to something outlandish                -->
<!-- This should be overridden in an importing stylesheet  -->
<xsl:variable name="file-extension" select="'.need-to-set-file-extension-variable'" />

<!-- We preserve action of the "autoname" parameter         -->
<!-- But originally the default was "no", and now is        -->
<!-- equivalent to "yes".  We set to blank on creation,     -->
<!-- so we can see if there is command-line action          -->
<!-- There is a warning that the default behavior has       -->
<!-- changed, and a warning that setting this is deprecated -->
<!-- (Deprecation 2017-07-25) -->
<xsl:variable name="legacy-autoname">
    <xsl:choose>
        <!-- nothing on command-line, nothing in docinfo    -->
        <!-- then this is what will be used globally        -->
        <!-- so preserve this behavior when this is removed -->
        <xsl:when test="$autoname = ''">
            <xsl:text>unset</xsl:text>
        </xsl:when>
        <!-- legacy had zero error-checking -->
        <xsl:otherwise>
            <xsl:value-of select="$autoname" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Employing variants of the text displayed for a cross-reference -->
<!-- affects the words shown to the reader, and hence is a choice   -->
<!-- preserved in the source, and is not just a processing decision -->
<!-- $xref-text-style is the global choice, based on                -->
<!--   docinfo/cross-references/@text                               -->
<!-- We control the possible values with the schema, allowing junk  -->
<!-- NB: blank is not set, and is ignored so the legacy-autoname    -->
<!-- scheme controls the global default.  When that goes away, we   -->
<!-- should set the default here when there is no attribute.        -->
<xsl:variable name="xref-text-style">
    <xsl:choose>
        <xsl:when test="$docinfo/cross-references/@text">
            <xsl:value-of select="$docinfo/cross-references/@text" />
        </xsl:when>
        <xsl:otherwise>
            <text />
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- To forward-reference solutions to exercises, we need       -->
<!-- to know which ones atually have solutions in place later.  -->
<!-- So we build 30 node-lists according to the direct product  -->
<!--                                                            -->
<!--   {inline, divisional, worksheet, reading, project}        -->
<!--     x                                                      -->
<!--   {hint, answer, solution}                                 -->
<!--     x                                                      -->
<!--   {main, back}                                             -->
<!--                                                            -->
<!-- iff they are elected to be displayed at some point         -->
<!-- (intra-division or back matter) via a "solutions" element. -->
<!--                                                            -->
<!-- First, we provide enough of a path to clearly identify the -->
<!-- exercise component and its location, allowing steps where  -->
<!-- there may be intervening structure (such as an             -->
<!-- "exercisegroup").  Careful - a component in a "worksheet"  -->
<!-- can be part of an "exercise" (worksheet exercise) or part  -->
<!-- of "project" inside a worksheet.                           -->
<!--                                                            -->
<!-- Second, we condition on whether there is a                 -->
<!-- backmatter/solutions  that elects inclusion of the         -->
<!-- component, or if there is a containing division which      -->
<!-- contains a solutions (ancestor::*/child::solutions)        -->
<!-- with the same election.                                    -->

<!-- Hint, Main Matter -->
<xsl:variable name="inline-hint-main"     select="$document-root//exercise[&INLINE-EXERCISE-FILTER;]//hint[ancestor::*/solutions[contains(@inline, 'hint')]]"/>
<xsl:variable name="divisional-hint-main" select="$document-root//exercises//hint[ancestor::*/solutions[contains(@divisional, 'hint')]]"/>
<xsl:variable name="worksheet-hint-main"  select="$document-root//worksheet//exercise//hint[ancestor::*/solutions[contains(@worksheet, 'hint')]]"/>
<xsl:variable name="reading-hint-main"    select="$document-root//reading-questions//hint[ancestor::*/solutions[contains(@reading, 'hint')]]"/>
<xsl:variable name="project-hint-main"    select="$document-root//*[&PROJECT-FILTER;]//hint[ancestor::*/solutions[contains(@project, 'hint')]]"/>
<!-- Hint, Back Matter -->
<xsl:variable name="inline-hint-back"     select="$document-root//exercise[&INLINE-EXERCISE-FILTER;]//hint[$document-root/backmatter/solutions[contains(@inline, 'hint')]]"/>
<xsl:variable name="divisional-hint-back" select="$document-root//exercises//hint[$document-root/backmatter/solutions[contains(@divisional, 'hint')]]"/>
<xsl:variable name="worksheet-hint-back"  select="$document-root//worksheet//exercise//hint[$document-root/backmatter/solutions[contains(@worksheet, 'hint')]]"/>
<xsl:variable name="reading-hint-back"    select="$document-root//reading-questions//hint[$document-root/backmatter/solutions[contains(@reading, 'hint')]]"/>
<xsl:variable name="project-hint-back"    select="$document-root//*[&PROJECT-FILTER;]//hint[$document-root/backmatter/solutions[contains(@project, 'hint')]]"/>
<!-- Answer, Main Matter -->
<xsl:variable name="inline-answer-main"     select="$document-root//exercise[&INLINE-EXERCISE-FILTER;]//answer[ancestor::*/solutions[contains(@inline, 'answer')]]"/>
<xsl:variable name="divisional-answer-main" select="$document-root//exercises//answer[ancestor::*/solutions[contains(@divisional, 'answer')]]"/>
<xsl:variable name="worksheet-answer-main"  select="$document-root//worksheet//exercise//answer[ancestor::*/solutions[contains(@worksheet, 'answer')]]"/>
<xsl:variable name="reading-answer-main"    select="$document-root//reading-questions//answer[ancestor::*/solutions[contains(@reading, 'answer')]]"/>
<xsl:variable name="project-answer-main"    select="$document-root//*[&PROJECT-FILTER;]//answer[ancestor::*/solutions[contains(@project, 'answer')]]"/>
<!-- Answer, Back Matter -->
<xsl:variable name="inline-answer-back"     select="$document-root//exercise[&INLINE-EXERCISE-FILTER;]//answer[$document-root/backmatter/solutions[contains(@inline, 'answer')]]"/>
<xsl:variable name="divisional-answer-back" select="$document-root//exercises//answer[$document-root/backmatter/solutions[contains(@divisional, 'answer')]]"/>
<xsl:variable name="worksheet-answer-back"  select="$document-root//worksheet//exercise//answer[$document-root/backmatter/solutions[contains(@worksheet, 'answer')]]"/>
<xsl:variable name="reading-answer-back"    select="$document-root//reading-questions//answer[$document-root/backmatter/solutions[contains(@reading, 'answer')]]"/>
<xsl:variable name="project-answer-back"    select="$document-root//*[&PROJECT-FILTER;]//answer[$document-root/backmatter/solutions[contains(@project, 'answer')]]"/>
<!-- Solution, Main Matter -->
<xsl:variable name="inline-solution-main"     select="$document-root//exercise[&INLINE-EXERCISE-FILTER;]//solution[ancestor::*/solutions[contains(@inline, 'solution')]]"/>
<xsl:variable name="divisional-solution-main" select="$document-root//exercises//solution[ancestor::*/solutions[contains(@divisional, 'solution')]]"/>
<xsl:variable name="worksheet-solution-main"  select="$document-root//worksheet//exercise//solution[ancestor::*/solutions[contains(@worksheet, 'solution')]]"/>
<xsl:variable name="reading-solution-main"    select="$document-root//reading-questions//solution[ancestor::*/solutions[contains(@reading, 'solution')]]"/>
<xsl:variable name="project-solution-main"    select="$document-root//*[&PROJECT-FILTER;]//solution[ancestor::*/solutions[contains(@project, 'solution')]]"/>
<!-- Solution, Back Matter -->
<xsl:variable name="inline-solution-back"     select="$document-root//exercise[&INLINE-EXERCISE-FILTER;]//solution[$document-root/backmatter/solutions[contains(@inline, 'solution')]]"/>
<xsl:variable name="divisional-solution-back" select="$document-root//exercises//solution[$document-root/backmatter/solutions[contains(@divisional, 'solution')]]"/>
<xsl:variable name="worksheet-solution-back"  select="$document-root//worksheet//exercise//solution[$document-root/backmatter/solutions[contains(@worksheet, 'solution')]]"/>
<xsl:variable name="reading-solution-back"    select="$document-root//reading-questions//solution[$document-root/backmatter/solutions[contains(@reading, 'solution')]]"/>
<xsl:variable name="project-solution-back"    select="$document-root//*[&PROJECT-FILTER;]//solution[$document-root/backmatter/solutions[contains(@project, 'solution')]]"/>

<!-- Combinations that are useful -->
<!-- First: main matter placement vs. back matter placement -->
<xsl:variable name="solutions-mainmatter" select="
$inline-hint-main    |$divisional-hint-main    |$worksheet-hint-main    |$reading-hint-main    |$project-hint-main|
$inline-answer-main  |$divisional-answer-main  |$worksheet-answer-main  |$reading-answer-main  |$project-answer-main|
$inline-solution-main|$divisional-solution-main|$worksheet-solution-main|$reading-solution-main|$project-solution-main"/>
<xsl:variable name="solutions-backmatter" select="
$inline-hint-back    |$divisional-hint-back    |$worksheet-hint-back    |$reading-hint-back    |$project-hint-back|
$inline-answer-back  |$divisional-answer-back  |$worksheet-answer-back  |$reading-answer-back  |$project-answer-back|
$inline-solution-back|$divisional-solution-back|$worksheet-solution-back|$reading-solution-back|$project-solution-back"/>

<!-- ################### -->
<!-- Debugging Variables -->
<!-- ################### -->

<!-- Collect debugging and transition string parameters.   -->
<!-- (1) Military style names: debug.*.*, finer purposes   -->
<!-- (2) Minimal documentation here.                       -->
<!-- (3) No error-checking, no deprecation plan            -->
<!-- (4) Perhaps warnings on removal, migrate to Bad Bank  -->

<!-- Look in "publisher variables" stylesheet for some -->
<!-- (convenience) debugging switches that override    -->
<!-- publisher/default settings                        -->

<!-- Sometimes  xsltproc fails, and fails spectacularly,        -->
<!-- setting this switch will dump lots of location info to the -->
<!-- console, and perhaps will be helpful in locating a failure -->
<!-- You might redirect stderror to a file with "2> errors.txt" -->
<!-- appended to your command line                              -->
<xsl:param name="debug" select="'no'" />
<xsl:variable name="b-debug" select="$debug = 'yes'" />

<xsl:param name="debug.datedfiles" select="'yes'" />
<xsl:variable name="b-debug-datedfiles" select="not($debug.datedfiles = 'no')" />


<!-- Single-use to display low-level info on whitespace manipulation -->
<xsl:param name="ws.debug" select="'no'" />
<xsl:variable name="wsdebug" select="boolean($ws.debug = 'yes')" />

<!-- Colored boxes on panels -->
<xsl:param name="sbs.debug" select="'no'" />
<xsl:variable name="sbsdebug" select="boolean($sbs.debug = 'yes')" />

<!-- very temporary, just for testing -->
<xsl:param name="debug.exercises.forward" select="''"/>

<!-- LaTeX display style in list items -->
<xsl:param name="debug.displaystyle" select="'yes'"/>

<!-- 2021-07-30: HTML only, experimental -->
<!-- Switch to kill all knowls, intended to facilitate -->
<!-- quick preview builds for use while authoring. -->
<!-- Change to non-empty string to enable -->
<xsl:param name="debug.skip-knowls" select="''"/>
<xsl:variable name="b-skip-knowls" select="not($debug.skip-knowls = '')"/>

<!-- HTML only, experimental -->
<!-- Temporary, undocumented, and experimental           -->
<!-- Makes randomization buttons for inline WW probmlems -->
<xsl:param name="debug.webwork.inline.randomize" select="''"/>
<xsl:variable name="b-webwork-inline-randomize" select="$debug.webwork.inline.randomize = 'yes'"/>

<!-- MathJax SVG option (yes/no, could be generalized to -->
<!-- specifying various options).  Totally unsupported.  -->
<xsl:param name="debug.mathjax.svg" select="''"/>

<!-- Definitely not debugging.  Transitional.  Top-secret. -->
<xsl:param name="debug.editable" select="''"/>

<!-- 2021-07-02: any non-empty string will cause project-like  -->
<!-- to run on the same counter as other blocks. Un-supported. -->
<xsl:param name="debug.project.number" select="''"/>

<!-- 2022-01-30: transition to React components, get ReactJS -->
<!-- bundles, etc, locally or globally.  'yes' to activate.  -->
<!-- Never use both, chaos might result, not error-checked   -->
<xsl:param name="debug.react.local" select="'no'"/>
<xsl:param name="debug.react.global" select="'no'"/>
<!-- three derived internal variables, primarily use latter -->
<xsl:variable name= "b-debug-react-local" select="not($debug.react.local = 'no')"/>
<xsl:variable name= "b-debug-react-global" select="not($debug.react.global = 'no')"/>
<xsl:variable name="b-debug-react" select="$b-debug-react-local or $b-debug-react-global"/>

<!-- HTML only, a developer must elect to use this CSS file -->
<xsl:param name="debug.developer.css" select="'no'"/>

<!-- HTML only, testing early-releases of MathJax 4                    -->
<!-- See: https://github.com/mathjax/MathJax/releases                  -->
<!-- https://github.com/mathjax/MathJax-src/releases/tag/4.0.0-alpha.1 -->
<xsl:param name="debug.mathjax4" select="'no'"/>
<xsl:variable name="mathjax4-testing" select="$debug.mathjax4 = 'yes'"/>

<!-- A permanent string parameter to control the creation of  -->
<!-- "View Source" knowls, which is a developer task, not a   -->
<!-- publisher task (though it could be?).  So permanent, but -->
<!-- undocumented.                                            -->
<xsl:param name="debug.html.annotate" select="'no'"/>
<xsl:variable name="b-view-source" select="$debug.html.annotate = 'yes'"/>

<!-- Maybe not debugging, but transitional variables -->

<!-- Prior to January 2017 we treated all whitespace as -->
<!-- significant in mixed-content nodes.  With changes  -->
<!-- in this policy we preserve the option to process   -->
<!-- in this older style.  This could avoid frequent    -->
<!-- applications of low-level text-processing routines -->
<!-- and perhaps speed up processing.  Switch here      -->
<!-- controls possible whitespace modes.                -->
<xsl:param name="whitespace" select="'flexible'" />
<xsl:variable name="whitespace-style">
    <xsl:choose>
        <xsl:when test="$whitespace='strict' or $whitespace='flexible'">
            <xsl:value-of select="$whitespace" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>
                <xsl:text>PTX:ERROR: the whitespace parameter can be 'strict' or 'flexible', not '</xsl:text>
                <xsl:value-of select="$whitespace" />
                <xsl:text>'.  Using the default ('flexible').</xsl:text>
            </xsl:message>
            <xsl:text>flexible</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- We never process using just this file, and often want  -->
<!-- to import it elsewhere for the utilities it contains.  -->
<!-- So there is no entry template, nor should there be.    -->
<!-- An importing file, designed for a specific conversion, -->
<!-- can have an entry template and use the general         -->
<!-- "chunking" templates defined below.                    -->


<!-- ###### -->
<!-- Levels -->
<!-- ###### -->

<!-- Certain characteristics of the output can be configured    -->
<!-- based on how deep they are in the hierachy of a structured -->
<!-- document.  Authors specify these characteristics relative  -->
<!-- to their own project, more specifically relative to the    -->
<!-- logical top-level element, such as "book" or "article".    -->
<!-- These are "Level 0". We normalize these numbers internally -->
<!-- so that level 0 is the first possible division in any      -->
<!-- document, which would be a "part"                          -->


<!-- (Relative) Levels -->
<!-- Input: an element that is a division of some kind -->
<!-- Output: its relative level, eg "book" is 0        -->
<!-- Front and back matter are faux divisions, so we   -->
<!-- filter them out.                                  -->


<!--
Schematic of levels of divisions
*  "preface" has 4 peers, eg, "dedication"
*  "appendix" has two peers, "index" and "colophon"
*  specialized divisions, e.g "references" can go numerous places

Article, "section" at level 1
||         0            ||    1     ||     2      ||      3        ||
||          frontmatter ||          ||            ||               ||
|| article              || section  || subsection || subsubsection ||
||          backmatter  || appendix || subsection || subsubsection ||


Book (no parts), "section" at level 2
||        0         ||    1     ||    2     ||     3      ||      4        ||
||      frontmatter || preface  ||          ||            ||               ||
|| book             || chapter  || section  || subsection || subsubsection ||
||      backmatter  || appendix || section  || subsection || subsubsection ||


Book (with parts), "section" at level 3
||  0   ||     1       ||    2     ||    3     ||     4      ||      5        ||
||      || frontmatter || preface  ||          ||            ||               ||
|| book || part        || chapter  || section  || subsection || subsubsection ||
||      || backmatter  || appendix || section  || subsection || subsubsection ||
-->

<!-- 2021-12-22: we are transitioning to selected (and eventually universal) -->
<!-- use of levels computed during the "assembly" phase.  So we use careful  -->
<!-- matches and we use careful choices for application.  At every           -->
<!-- application we compute the "old" level to test for consistency.         -->

<!-- ####################################################################### -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|exercises|solutions|reading-questions|references|glossary|worksheet|handout" mode="new-level">
    <xsl:variable name="old-level">
        <xsl:apply-templates select="." mode="level"/>
    </xsl:variable>
    <xsl:if test="not($old-level = @level)">
        <xsl:message>PTX:BUG:  development bug, new level does not match old level for "<xsl:value-of select="local-name(.)"/>"</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <!-- actual value here, above is debugging -->
    <xsl:value-of select="@level"/>
</xsl:template>

<xsl:template match="*" mode="new-level">
    <xsl:message>PTX:BUG:   an element ("<xsl:value-of select="local-name(.)"/>") does not know its *new* level</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
</xsl:template>
<!-- ####################################################################### -->

 <!-- Specific top-level divisions -->
<!-- article/frontmatter, article/backmatter are faux divisions, but   -->
<!-- will function as a terminating condition in recursive count below -->
<xsl:template match="book|article|slideshow|letter|memo|article/frontmatter|article/backmatter" mode="level">
    <xsl:value-of select="0"/>
</xsl:template>

<!-- A book/part will divide the mainmatter, so a "chapter" is at -->
<!-- level 2, so we also put the faux divisions at level 1 in the -->
<!-- case of parts, to again terminate recursive count            -->
<xsl:template match="book/part|book/frontmatter|book/backmatter" mode="level">
    <xsl:choose>
        <xsl:when test="$b-has-parts">
            <xsl:value-of select="1"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="0"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Remaining divisions will follow a strict progression from their    -->
<!-- parents.  We have front matter divisions of a book first, which    -->
<!-- will have the same level as a chapter, then traditional divisions, -->
<!-- which may structure a chapter of a book, section of an article,    -->
<!-- or an appendix (structured as a chapter in a book or a sections    -->
<!-- in an article).  Then follows specialized divisions of the back    -->
<!-- matter, which are peers of an appendix.  Finally we have the       -->
<!-- "specialized divisions" of PreTeXt, which can be descendants of    -->
<!-- chapters of books, sections of articles, or in the case of         -->
<!-- solutions or references, children of an appendix.                  -->

<xsl:template match="colophon|biography|dedication|acknowledgement|preface|chapter|section|subsection|subsubsection|slide|appendix|index|colophon|exercises|reading-questions|references|solutions|glossary|worksheet|handout" mode="level">
    <xsl:variable name="level-above">
        <xsl:apply-templates select="parent::*" mode="level"/>
    </xsl:variable>
    <xsl:value-of select="$level-above + 1"/>
</xsl:template>

<xsl:template match="*" mode="level">
    <xsl:message>PTX:BUG:   an element ("<xsl:value-of select="local-name(.)"/>") does not know its level</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
</xsl:template>


<!-- Enclosing Level -->
<!-- For any element, work up the tree to a structural -->
<!-- node and then compute level as above              -->
<!-- NB: to meld with previous would require a better     -->
<!-- definition of structural, and care with introduction -->
<xsl:template match="*" mode="enclosing-level">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$structural = 'true'">
            <xsl:apply-templates select="." mode="level" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="enclosing-level" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Relative level offset -->
<!-- This is the adjustment to move a relative       -->
<!-- level onto the absolute scale                   -->
<!--     part: 0                                     -->
<!--     chapter, appendix: 1                        -->
<!--     section: 2                                  -->
<!--     subsection: 3                               -->
<!--     subsubsection: 4                            -->
<!-- It can be defined as the value on this absolute -->
<!-- scale that the $document-root (book, article,   -->
<!-- memo, etc.) would have, depending on options    -->
<!-- for structure beneath it.  So for all divisions -->
<!--                                                 -->
<!-- absolute-level = (relative-)level + root-level  -->
<!--                                                 -->
<!-- NB: 2017-09-05, three places, keep as variable  -->
<xsl:variable name="root-level">
    <xsl:choose>
        <xsl:when test="$version-root/book/part">-1</xsl:when>
        <xsl:when test="$version-root/book/chapter">0</xsl:when>
        <!-- An article is rooted just above sections, -->
        <!-- on par with chapters of a book            -->
        <xsl:when test="$version-root/article">1</xsl:when>
        <xsl:when test="$version-root/slideshow">1</xsl:when>
        <xsl:when test="$version-root/letter">1</xsl:when>
        <xsl:when test="$version-root/memo">1</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:BUG: Level offset undefined for this document type</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Names for Levels -->
<!-- Levels (ie depths in the tree) translate to PTX element -->
<!-- names and LaTeX divisions, which are generally the same -->
<!-- This is useful for "new" sections (eg exercises) when   -->
<!-- used with standard LaTeX sectioning and numbering       -->

<!-- Input:  a relative level, ie counted from document root -->
<!-- Output:  the LaTeX name (or close), HTML element        -->
<!-- NB:  this is a named template, independent of context   -->
<!-- NB: (2019-05-09) This could go to the -latex conversion -->
<xsl:template name="level-to-name">
    <xsl:param name="level" />
    <xsl:variable name="normalized-level" select="$level + $root-level" />
    <xsl:choose>
        <xsl:when test="$normalized-level=0">part</xsl:when>
        <xsl:when test="$normalized-level=1">chapter</xsl:when>
        <xsl:when test="$normalized-level=2">section</xsl:when>
        <xsl:when test="$normalized-level=3">subsection</xsl:when>
        <xsl:when test="$normalized-level=4">subsubsection</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: Level computation is out-of-bounds (input as <xsl:value-of select="$level" />, normalized to <xsl:value-of select="$normalized-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- LaTex Native Levels -->
<!-- LaTeX has its own internal absolute numbering scheme, -->
<!-- where sections are always level 1, while PTX uses     -->
<!-- level 2. So while a LaTeX-specific computation, we do -->
<!-- the translation here, so as to isolate the use of the -->
<!-- root-level variable in this -common file.             -->
<xsl:template name="level-to-latex-level">
    <xsl:param name="level" />
    <xsl:value-of select="$level + $root-level -1" />
</xsl:template>

<!-- ########### -->
<!-- Mathematics -->
<!-- ########### -->

<!-- Mathematics authored in LaTeX syntax should be       -->
<!-- independent of output format.  Despite MathJax's     -->
<!-- broad array of capabilities, there are still some    -->
<!-- differences which we need to accomodate via abstract -->
<!-- templates.  Those abstractions are documented here   -->
<!-- and also where implemented.  Elsewhere are low-level -->
<!-- manipulations of whitespace in processed versions    -->
<!-- of LaTeX output                                      -->


<!-- Inline Mathematics ("m") -->
<!--                                                     -->
<!-- This is fairly simple.  Differences are             -->
<!--   (1) Some conversions require different delimiters -->
<!--   (2) We adjust punctuation for HTML, but not Latex -->
<!--                                                     -->
<!-- Abstract Templates                                  -->
<!--                                                     -->
<!-- (1) named "inline-math-wrapper"                     -->
<!--       Provides the delimiters for inline math       -->
<!--       Stub warnings follow below                    -->
<!-- (2) get-clause-punctuation                          -->
<!--       Look at next node, and if a text node,        -->
<!--       then look for leading punctuation, and        -->
<!--       bring into math with \text() wrapper          -->
<!--       when  $math.punctuation.include  indicates    -->

<!-- $debug.displaystyle defaults to yes for testing -->

<xsl:template match="m">
    <!-- wrap in math delimiters -->
    <xsl:call-template name="inline-math-wrapper">
        <xsl:with-param name="math">
            <!-- Build a textual version of the latex,  -->
            <!-- applying the rare templates allowed,   -->
            <!-- save for minor manipulation later.     -->
            <!-- Note: generic text() template here in  -->
            <!-- -common should always pass through the -->
            <!-- text nodes within "m" with no changes  -->
            <xsl:variable name="raw-latex">
                <xsl:choose>
                    <xsl:when test="ancestor::static/parent::webwork-reps">
                        <xsl:apply-templates select="text()|var" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="text()|eval|fillin" />
                    </xsl:otherwise>
                </xsl:choose>
                <!-- look ahead to absorb immediate clause-ending punctuation   -->
                <!-- this is useful for HTML/MathJax to prevent bad line breaks -->
                <!-- The template here in -common is generally useful, but      -->
                <!-- for LaTeX we override to be a no-op, since not necessary   -->
                <xsl:apply-templates select="." mode="get-clause-punctuation" />
            </xsl:variable>
            <!-- Prefix will normally be empty and have no effect.  We also have  -->
            <!-- an undocumented switch to totally kill the possibility entirely. -->
            <!-- This was added to support testing of braille output.             -->
            <xsl:if test="not($debug.displaystyle = 'no')">
                <xsl:apply-templates select="."  mode="display-style-prefix"/>
            </xsl:if>
            <!-- we clean whitespace that is irrelevant to LaTeX so that we -->
            <!--   (1) avoid LaTeX compilation errors                       -->
            <!--   (2) avoid spurious blank lines leading to new paragraphs -->
            <!--   (3) provide human-readable source of high quality        -->
            <!-- sanitize-latex template does not provide a final newline   -->
            <!-- and we do not add one here either, since it is inline math -->
            <!-- MathJax is more tolerant, but readability is still useful  -->
            <xsl:call-template name="sanitize-latex">
                <xsl:with-param name="text" select="$raw-latex" />
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- This template needs an override in each output mode. -->
<xsl:template name="inline-math-wrapper">
    <xsl:param name="math"/>
    <xsl:message>PTX:BUG:   the "wrapper" modal template for inline math needs an implementation in the current conversion</xsl:message>
    <xsl:text>[[[</xsl:text>
    <xsl:value-of select="$math"/>
    <xsl:text>]]]</xsl:text>
</xsl:template>


<!-- Display Style LaTeX markup for inline math -->
<!--                                                     -->
<!-- If the current context "m" is a child of an "li",   -->
<!-- perhaps with an intervening "p", then we            -->
<!-- contemplate injecting a \displaystyle, if *the "m"  -->
<!-- is the only content of the "li"*.-->
<xsl:template match="m" mode="display-style-prefix">
    <!-- We first obtain a parent "li" (or come away    -->
    <!-- empty-handed). Booleans help readability later -->
    <xsl:variable name="parent-li" select="boolean(parent::li)"/>
    <xsl:variable name="grandparent-li" select="boolean(parent::p/parent::li)"/>
    <xsl:variable name="the-list-item" select="parent::li|parent::p/parent::li"/>
    <!-- If we have inline math inside a list item then we   -->
    <!-- can collect all of non-whitespace text() nodes.     -->
    <!-- We are only interested in the case of a single "p". -->
    <xsl:variable name="actual-text">
        <xsl:if test="$the-list-item">
            <xsl:choose>
                <xsl:when test="$parent-li">
                    <xsl:for-each select="$the-list-item/text()">
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="$grandparent-li">
                    <xsl:for-each select="$the-list-item/p[1]/text()">
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:for-each>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>
    <!-- Potential prefix with \displaystyle                        -->
    <!--                                                            -->
    <!-- (1) If there is not a list item, the next two tests fail.  -->
    <!-- (2) If there is any significant text() the tests will fail.-->
    <!-- (3) If there is a parent li, or li/p, the tests will fail  -->
    <!--     if there are more than two "p" or if the content       -->
    <!--     contains other markup (elements) other elements        -->
    <!--     besides just the lone "m".                             -->
    <!--                                                            -->
    <!-- So we improve the appearance of a lone "m" inside an "li". -->
    <!-- Authors who do not like this can add innocuous content.    -->
    <!--  -->
    <!-- The two "when" are disjoint and both may be false.  They   -->
    <!-- produce the same result.  This is meant to be more         -->
    <!-- readable than a big "or".  Note: this could be wrapped in  -->
    <!-- a big "if" based on the common $actual-text.               -->
    <!-- The result of this template is "\displaystyle " or ""      -->
    <xsl:choose>
        <xsl:when test="$parent-li and ($actual-text = '') and (count($the-list-item/*) = 1)">
            <xsl:text>\displaystyle </xsl:text>
        </xsl:when>
        <xsl:when test="$grandparent-li and ($actual-text = '') and (count($the-list-item/p) = 1) and (count($the-list-item/p[1]/*) = 1)">
            <xsl:text>\displaystyle </xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- Displayed Multi-Line Math ("md", with "mrow" children)         -->
<!-- "md" is a container for  "mrow" and intermediate "intertext".  -->
<!-- Note that the pre-processor guarantees that every "md"         -->
<!-- is structured with "mrow" and optionally "intertext".          -->
<!--                                                                -->
<!-- Abstract Templates                                             -->
<!--                                                                -->
<!-- (1) display-math-visual-blank-line, a named template           -->
<!--       Just a line in source to help visually (% for LaTeX)     -->
<!--                                                                -->
<!-- (2) display-math-wrapper                                       -->
<!--       An enclosing environment for any displayed mathematics   -->
<!--       Necessary for HTML, no-op for LaTeX                      -->

<!-- Default implementationis a no-op, can be overidden -->
<xsl:template name="display-math-visual-blank-line"/>

<!-- All displayed mathematics gets wrapped by  -->
<!-- an abstract template, a necessity for HTML -->
<!-- output.  By default, just a copy machine.  -->
<xsl:template match="md[mrow]" mode="display-math-wrapper">
    <xsl:param name="content" />
    <xsl:value-of select="$content" />
</xsl:template>

<!-- The HTML conversion accomodates duplicated content (i.e. knowls) -->
<!-- with an elaborate scheme.  The mode="body" template is central,  -->
<!-- so we run with that here.                                        -->
<xsl:template match="md[mrow]" mode="body">
    <!-- block-type parameter is ignored, since the          -->
    <!-- representation never varies, no heading, no wrapper -->
    <xsl:param name="block-type" />
    <!-- If original content, or a duplication -->
    <xsl:param name="b-original" select="true()" />
    <!-- If the only content of a knowl then we do not -->
    <!-- include adjacent (trailing) punctuation,      -->
    <!-- since it is meaningless                       -->
    <xsl:param name="b-top-level" select="false()" />
    <!-- Optionally, the \begin{} (the "open") or the \end{}  -->
    <!-- (the "close") can be suppressed.  This only happens  -->
    <!-- when making LaTeX output, and only when un-exploding -->
    <!-- an "md" that has "intertext" in it.  So the default  -->
    <!-- values are true, and most conversions can safely     -->
    <!-- ignore the use of these parameters.                  -->
    <xsl:param name="b-needs-open"  select="true()"/>
    <xsl:param name="b-needs-close" select="true()"/>
    <!-- Look across all mrow for 100% no-number rows.  We do not -->
    <!-- flag local tags as being numbered, but this affects        -->
    <!-- LaTeX environment construction, so we need to consider it. -->
    <!-- This just allows for slightly nicer human-readable source. -->
    <xsl:variable name="b-nonumbers" select="not(mrow[@pi:numbered = 'yes' or @tag])" />
    <xsl:variable name="complete-latex">
        <xsl:if test="$b-needs-open">
            <!-- we provide a newline for visual appeal -->
            <xsl:call-template name="display-math-visual-blank-line" />
            <xsl:text>\begin{</xsl:text>
            <xsl:apply-templates select="." mode="displaymath-alignment">
                <xsl:with-param name="b-nonumbers" select="$b-nonumbers" />
            </xsl:apply-templates>
            <xsl:text>}</xsl:text>
            <xsl:apply-templates select="." mode="alignat-columns" />
            <!-- leading whitespace not present, or stripped -->
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="mrow|intertext">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="b-top-level" select="$b-top-level" />
            <xsl:with-param name="b-nonumbers" select="$b-nonumbers" />
        </xsl:apply-templates>
        <!-- each mrow provides a newline, so unlike  -->
        <!-- above, we do not need to add one here    -->
        <xsl:if test="$b-needs-close">
            <xsl:text>\end{</xsl:text>
            <xsl:apply-templates select="." mode="displaymath-alignment">
                <xsl:with-param name="b-nonumbers" select="$b-nonumbers" />
            </xsl:apply-templates>
            <xsl:text>}</xsl:text>
            <!-- We must return to a paragraph, so                     -->
            <!-- we can add an unprotected newline                     -->
            <!-- Note: clause-ending punctuation has been absorbed,    -->
            <!-- so is not left orphaned at the start of the next line -->
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:apply-templates select="." mode="display-math-wrapper">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="content" select="$complete-latex" />
    </xsl:apply-templates>
</xsl:template>

<!-- Rows of Displayed Multi-Line Math ("mrow") -->
<!-- Each mrow finishes with a newline, for visual output      -->
<!-- We perform LaTeX sanitization on each "mrow" here;        -->
<!--                                                           -->
<!-- Abstract Templates                                        -->
<!--                                                           -->
<!-- (1) display-page-break                                    -->
<!--       LaTeX scheme, no-op here as base                    -->
<!-- (2) tag                                                   -->
<!--       on *rows* of multiline                              -->

<!-- Default implementations of specialized templates -->
<xsl:template match="mrow" mode="display-page-break"/>

<xsl:template match="mrow" mode="tag">
     <xsl:message>PTX:BUG:   the modal "tag" template needs an implementation for "mrow" in the current conversion</xsl:message>
</xsl:template>

<xsl:template match="mrow">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="b-top-level" select="false()" />
    <xsl:param name="b-nonumbers" />
    <!-- Build a textual version of the latex,       -->
    <!-- applying the rare templates allowed,        -->
    <!-- save for minor manipulation later.          -->
    <!-- Note: generic text() template here in       -->
    <!-- -common should always pass through the text -->
    <!-- nodes within "mrow" with no changes         -->
    <xsl:variable name="raw-latex">
        <xsl:choose>
            <xsl:when test="ancestor::webwork">
                <xsl:apply-templates select="text()|xref|var" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="text()|xref|eval|fillin" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="sanitize-latex">
        <xsl:with-param name="text" select="$raw-latex" />
    </xsl:call-template>
    <xsl:if test="not(following-sibling::*[self::mrow or self::intertext])">
        <!-- look ahead to absorb immediate clause-ending punctuation         -->
        <!-- for original versions, and as a child of a duplicated element    -->
        <!-- but not in a duplicate that is entirely the display math         -->
        <!-- pass the context as enclosing environment (parent::*, md or mdn) -->
        <xsl:if test="$b-original or not($b-top-level)">
            <xsl:apply-templates select="parent::*" mode="get-clause-punctuation" />
        </xsl:if>
    </xsl:if>
    <!-- If we built a pure no-number environment, then we add nothing   -->
    <!-- Otherwise, we are in a non-starred environment and get a number -->
    <!-- unless we "\notag" it, which is the better choice under AMSmath -->
    <!-- The modal "tag" template is more complicated than just forming  -->
    <!-- a tag, it is everything associated with an equation, like a     -->
    <!-- \label{} for LaTeX, and also for HTML/MathJax.  It does depend  -->
    <!-- on if the display is the original version or not                -->
    <!-- http://tex.stackexchange.com/questions/48965                    -->
    <!-- The @tag attribute trumps almost everything                     -->
    <xsl:choose>
        <xsl:when test="$b-nonumbers" />
        <!-- "local" tag is not numbered, but needs treatment -->
        <xsl:when test="(@pi:numbered = 'yes') or @tag">
            <xsl:apply-templates select="." mode="tag">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\notag</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- we have a discretionary page break scheme for LaTeX -->
    <xsl:if test="following-sibling::mrow">
       <xsl:text>\\</xsl:text>
       <xsl:apply-templates select="." mode="display-page-break" />
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- We convert a token into the LaTeX for a symbol     -->
<!-- for use as a local tag. Since we need this to work -->
<!-- in MathJax, we need symbols that are available in  -->
<!-- its limited set of supported commands.  Generally, -->
<!-- AMSMath symbols are the best description.  See     -->
<!-- http://docs.mathjax.org/en/latest/tex.html         -->
<!--     #supported-latex-commands                      -->
<!-- Note: \tag{} expects text mode                     -->
<!-- More? \checkmark, \bullet?                         -->
<!-- TODO: if some text symbols are used, perhaps from  -->
<!-- the textcomp package, then math delimiters will    -->
<!-- move down into the "when" parts of the "choose"    -->
<xsl:template match="@tag" mode="tag-symbol">
    <xsl:choose>
        <!-- Stars -->
        <xsl:when test=". = 'star'">
            <xsl:call-template name="tag-star"/>
        </xsl:when>
        <xsl:when test=". = 'dstar'">
            <xsl:call-template name="tag-star"/>
            <xsl:call-template name="tag-star"/>
        </xsl:when>
        <xsl:when test=". = 'tstar'">
            <xsl:call-template name="tag-star"/>
            <xsl:call-template name="tag-star"/>
            <xsl:call-template name="tag-star"/>
        </xsl:when>
        <!-- Dagger -->
        <xsl:when test=". = 'dagger'">
            <xsl:call-template name="tag-dagger"/>
        </xsl:when>
        <xsl:when test=". = 'ddagger'">
            <xsl:call-template name="tag-dagger"/>
            <xsl:call-template name="tag-dagger"/>
        </xsl:when>
        <xsl:when test=". = 'tdagger'">
            <xsl:call-template name="tag-dagger"/>
            <xsl:call-template name="tag-dagger"/>
            <xsl:call-template name="tag-dagger"/>
        </xsl:when>
        <!-- Double Dagger -->
        <xsl:when test=". = 'daggerdbl'">
            <xsl:call-template name="tag-daggerdbl"/>
        </xsl:when>
        <xsl:when test=". = 'ddaggerdbl'">
            <xsl:call-template name="tag-daggerdbl"/>
            <xsl:call-template name="tag-daggerdbl"/>
        </xsl:when>
        <xsl:when test=". = 'tdaggerdbl'">
            <xsl:call-template name="tag-daggerdbl"/>
            <xsl:call-template name="tag-daggerdbl"/>
            <xsl:call-template name="tag-daggerdbl"/>
        </xsl:when>
        <!-- Hash -->
        <xsl:when test=". = 'hash'">
            <xsl:call-template name="tag-hash"/>
        </xsl:when>
        <xsl:when test=". = 'dhash'">
            <xsl:call-template name="tag-hash"/>
            <xsl:call-template name="tag-hash"/>
        </xsl:when>
        <xsl:when test=". = 'thash'">
            <xsl:call-template name="tag-hash"/>
            <xsl:call-template name="tag-hash"/>
            <xsl:call-template name="tag-hash"/>
        </xsl:when>
        <!-- Maltese -->
        <xsl:when test=". = 'maltese'">
            <xsl:call-template name="tag-maltese"/>
        </xsl:when>
        <xsl:when test=". = 'dmaltese'">
            <xsl:call-template name="tag-maltese"/>
            <xsl:call-template name="tag-maltese"/>
        </xsl:when>
        <xsl:when test=". = 'tmaltese'">
            <xsl:call-template name="tag-maltese"/>
            <xsl:call-template name="tag-maltese"/>
            <xsl:call-template name="tag-maltese"/>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- ####################### -->
<!-- Display Math Alignments -->
<!-- ####################### -->

<!-- We sniff around for ampersands, to decide between "align"    -->
<!-- and "gather", plus an asterisk for the unnumbered version    -->
<!-- AMSMath has no easy way to make a one-off number within      -->
<!-- the *-form, so we lean toward always using the un-starred    -->
<!-- versions, except when we flag 100% no numbers inside an "md" -->
<!-- Template is applied twice (begin/end) and its use ensures    -->
<!-- consistency.                                                 -->
<xsl:template match="md[mrow]" mode="displaymath-alignment">
    <xsl:param name="b-nonumbers" select="false()" />
    <xsl:choose>
        <!-- look for @alignment override, possibly bad -->
        <xsl:when test="@alignment='gather'">
            <xsl:text>gather</xsl:text>
        </xsl:when>
        <xsl:when test="@alignment='alignat'">
            <xsl:text>alignat</xsl:text>
        </xsl:when>
        <xsl:when test="@alignment='align'">
            <xsl:text>align</xsl:text>
        </xsl:when>
        <xsl:when test="@alignment">
            <xsl:message>PTX:ERROR: display math @alignment attribute "<xsl:value-of select="@alignment" />" is not recognized (should be "align", "gather", "alignat")</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
            <xsl:text>bad-alignment-choice</xsl:text>
        </xsl:when>
        <!-- perhaps authored as obviously one-line (no alignment) -->
        <!-- and manipulated into an  md/@mrow  form               -->
        <xsl:when test="@pi:authored-one-line">
            <xsl:text>equation</xsl:text>
        </xsl:when>
        <!-- sniff for alignment specifications    -->
        <!-- this can be easily fooled, eg matrices-->
        <xsl:when test="contains(., '&amp;') or contains(., '\amp')">
            <xsl:text>align</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>gather</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- if absolutely no numbers and no local tags,   -->
    <!-- we'll economize in favor of human-readability -->
    <xsl:if test="$b-nonumbers">
        <xsl:text>*</xsl:text>
    </xsl:if>
</xsl:template>

<!-- With alignment="alignat" we need the number of columns     -->
<!-- as an argument, complete with the LaTeX group (braces)     -->
<!-- Mostly we call this regularly, and it usually does nothing -->
<xsl:template match="md[mrow]" mode="alignat-columns" />

<xsl:template match="md[mrow and (@alignment='alignat')]" mode="alignat-columns">
    <xsl:variable name="number-equation-columns">
        <xsl:choose>
            <!-- override first -->
            <xsl:when test="@alignat-columns">
                <!-- MathJax chokes on spaces here -->
                <xsl:value-of select="normalize-space(@alignat-columns)" />
            </xsl:when>
            <!-- count ampersands, compute columns -->
            <xsl:otherwise>
                <xsl:variable name="number-ampersands">
                    <xsl:apply-templates select="mrow[1]" mode="max-ampersands" />
                </xsl:variable>
                <!-- amps + 1, divide by 2, round up; 0.5 becomes 0.25, round behaves -->
                <xsl:value-of select="round(($number-ampersands + 1.5) div 2)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$number-equation-columns" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- count ampersands in a string              -->
<!-- both as LaTeX macro and as bare character -->
<xsl:template name="count-ampersands">
    <xsl:param name="text" />
    <xsl:variable name="amp-char">
        <xsl:call-template name="count-substring">
            <xsl:with-param name="text" select="$text" />
            <xsl:with-param name="word" select="'&amp;'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="amp-macro">
        <xsl:call-template name="count-substring">
            <xsl:with-param name="text" select="$text" />
            <xsl:with-param name="word" select="'\amp'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="$amp-char + $amp-macro" />
</xsl:template>

<!-- Recurse through "mrow"s of a presumed "md"   -->
<!-- counting ampersands and tracking the maximum -->
<xsl:template match="mrow" mode="max-ampersands">
    <xsl:param name="max" select="0"/>
    <!-- build string/text content -->
    <xsl:variable name="row-content">
        <xsl:for-each select="text()">
            <xsl:value-of select="." />
        </xsl:for-each>
    </xsl:variable>
    <!-- count row's ampersands -->
    <xsl:variable name="ampersands">
        <xsl:call-template name="count-ampersands">
            <xsl:with-param name="text" select="$row-content" />
        </xsl:call-template>
    </xsl:variable>
    <!-- recalculate maximum -->
    <xsl:variable name="new-max">
        <xsl:choose>
            <xsl:when test="$ampersands > $max">
                <xsl:value-of select="$ampersands" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$max" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- recurse or report -->
    <xsl:variable name="following-mrows" select="following-sibling::mrow" />
    <xsl:choose>
        <xsl:when test="$following-mrows">
            <xsl:apply-templates select="$following-mrows[1]" mode="max-ampersands">
                <xsl:with-param name="max" select="$new-max" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$new-max" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ######### -->
<!-- Intertext -->
<!-- ######### -->

<!-- Unless overridden somehow, an internal "pi:intertext" element -->
<!-- (coming from the "intertext-exploder" mode in -assembly) just -->
<!-- needs a full-on "xsl:apply-templates"                         -->
<xsl:template match="pi:intertext">
    <xsl:apply-templates/>
</xsl:template>

<!-- #################### -->
<!-- LaTeX Image Preamble -->
<!-- #################### -->

<!-- A docinfo may have latex-image-preamble without a  -->
<!-- @syntax. There should only be one, but schema does -->
<!-- not enforce that. It is stored here as a variable  -->
<!-- (possibly empty) to facilitate having other        -->
<!-- latex-image-preamble that do have special @syntax. -->
<xsl:variable name="latex-image-preamble">
    <xsl:choose>
        <xsl:when test="$docinfo/latex-image-preamble[not(@syntax)]">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text" select="$docinfo/latex-image-preamble[not(@syntax)][1]" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise/>
    </xsl:choose>
</xsl:variable>

<!-- ############## -->
<!-- LaTeX Preamble -->
<!-- ############## -->

<!-- We pick up user-supplied macros, and         -->
<!-- add three of our own that are useful         -->
<!-- for avoiding conflicts with XML reserved     -->
<!-- characters.  Even though MathJax defines     -->
<!-- \lt  and  \gt  we go ahead and do it         -->
<!-- anyway for completeness.  We add these       -->
<!-- last with a \newcommand to minimize the      -->
<!-- possibility author defines them earlier      -->
<!-- This should be the primary and only          -->
<!-- interface to the macros list, though         -->
<!-- it might need some extra                     -->
<!-- conversion-specific wrapping in use          -->
<!-- and it may be necessary/desirable to replace -->
<!-- newline line-endings with something like {}  -->
<!-- First, we move left-margin as far left as    -->
<!-- possible, then strip all comments,  without  -->
<!-- stripping too much, such as useful \%        -->
<!-- We save in a variable, so only here once     -->
<!-- NB: the \lt definition is removed in the     -->
<!-- Jupyter conversion, since the Jupyter        -->
<!-- "print to LaTeX" converter will also define  -->
<!-- it in order to cover for MathJax's decision  -->
<!-- to make the definition. So if *any* edit is  -->
<!-- made here, then the "replace()" there will   -->
<!-- need to be edited to match.                  -->
<xsl:variable name="latex-macros">
    <xsl:variable name="latex-left-justified">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text">
                <xsl:value-of select="$docinfo/macros" />
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="latex-macro-first-percent">
        <xsl:with-param name="latex-code">
            <xsl:value-of select="$latex-left-justified" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>\newcommand{\lt}{&lt;}&#xa;</xsl:text>
    <xsl:text>\newcommand{\gt}{&gt;}&#xa;</xsl:text>
    <xsl:text>\newcommand{\amp}{&amp;}&#xa;</xsl:text>
</xsl:variable>

<!-- Recursively, line-by-line, find first %                             -->
<!-- If preceded by \, then output and reform with rest of line          -->
<!-- If a naked %, then drop rest of line, tidy up and move to next line -->
<!-- Every output line ends with a newline                               -->
<xsl:template name="latex-macro-first-percent">
    <xsl:param name="latex-code" />
    <xsl:variable name="first-line" select="concat(substring-before($latex-code, '&#xA;'), '&#xA;')" />
    <xsl:variable name="remainder" select="substring-after($latex-code, '&#xA;')" />
    <xsl:choose>
        <!-- done, quit recursing -->
        <xsl:when test="not($latex-code)" />
        <!-- first potential comment character-->
        <xsl:when test="contains($first-line, '%')">
            <xsl:variable name="initial" select="substring-before($first-line, '%')" />
            <xsl:choose>
                <xsl:when test="substring($initial, string-length($initial))='\'">
                    <!-- false positive, output symptom and reorganize -->
                    <xsl:value-of select="concat($initial, '%')" />
                    <xsl:call-template name="latex-macro-first-percent">
                        <xsl:with-param name="latex-code" select="concat(substring-after($first-line, '%'), $remainder)" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <!-- comment character in first column is no line        -->
                    <!-- else, content prior, with stripped newline restored -->
                    <xsl:if test="$initial">
                        <xsl:value-of select="concat($initial, '&#xA;')" />
                    </xsl:if>
                    <!-- move on to remaining lines -->
                    <xsl:call-template name="latex-macro-first-percent">
                        <xsl:with-param name="latex-code" select="$remainder" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <!-- no action, just echo and work the rest -->
            <xsl:value-of select="$first-line" />
            <xsl:call-template name="latex-macro-first-percent">
                <xsl:with-param name="latex-code" select="substring-after($latex-code, '&#xA;')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- For a "fillin" within math.                                       -->
<!-- First, define math fillin macro that is common to LaTeX, MathJax. -->
<!-- Then below, template for matching on each "fillin".               -->
<xsl:template name="fillin-math">
    <xsl:choose>
        <xsl:when test="$fillin-math-style = 'underline'">
            <xsl:text>\newcommand{\fillinmath}[1]{\mathchoice</xsl:text>
            <xsl:text>{\underline{\displaystyle     \phantom{\ \,#1\ \,}}}</xsl:text>
            <xsl:text>{\underline{\textstyle        \phantom{\ \,#1\ \,}}}</xsl:text>
            <xsl:text>{\underline{\scriptstyle      \phantom{\ \,#1\ \,}}}</xsl:text>
            <xsl:text>{\underline{\scriptscriptstyle\phantom{\ \,#1\ \,}}}}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$fillin-math-style = 'box'">
            <xsl:text>\newcommand{\fillinmath}[1]{\mathchoice</xsl:text>
            <xsl:text>{\boxed{\displaystyle     \phantom{\,#1\,}}}</xsl:text>
            <xsl:text>{\boxed{\textstyle        \phantom{\,#1\,}}}</xsl:text>
            <xsl:text>{\boxed{\scriptstyle      \phantom{\,#1\,}}}</xsl:text>
            <xsl:text>{\boxed{\scriptscriptstyle\phantom{\,#1\,}}}}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$fillin-math-style = 'shade'">
            <xsl:text>\definecolor{fillinmathshade}{gray}{0.9}&#xa;</xsl:text>
            <xsl:text>\newcommand{\fillinmath}[1]{\mathchoice</xsl:text>
            <xsl:text>{\colorbox{fillinmathshade}{$\displaystyle     \phantom{\,#1\,}$}}</xsl:text>
            <xsl:text>{\colorbox{fillinmathshade}{$\textstyle        \phantom{\,#1\,}$}}</xsl:text>
            <xsl:text>{\colorbox{fillinmathshade}{$\scriptstyle      \phantom{\,#1\,}$}}</xsl:text>
            <xsl:text>{\colorbox{fillinmathshade}{$\scriptscriptstyle\phantom{\,#1\,}$}}}&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template match="m/fillin|mrow/fillin">
    <xsl:choose>
        <xsl:when test="@fill">
            <xsl:text>\fillinmath{</xsl:text>
            <xsl:value-of select="@fill"/>
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:when test="@characters">
            <xsl:text>\fillinmath{</xsl:text>
                <xsl:call-template name="duplicate-string">
                    <xsl:with-param name="count" select="@characters" />
                    <xsl:with-param name="text"  select="'X'" />
                </xsl:call-template>
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\fillinmath{XXX}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- For a fillin (not in math) that describes itself as an array -->
<xsl:template match="fillin" mode="fillin-array">
    <xsl:variable name="rows">
        <xsl:choose>
            <xsl:when test="@rows">
                <xsl:value-of select="@rows"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="1"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="cols">
        <xsl:choose>
            <xsl:when test="@cols">
                <xsl:value-of select="@cols"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="1"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="$rows &gt; 1 or $cols &gt; 1">
        <xsl:text> (</xsl:text>
        <xsl:value-of select="$rows"/>
        <xsl:call-template name="nbsp-character"/>
        <xsl:call-template name="times-character"/>
        <xsl:call-template name="nbsp-character"/>
        <xsl:value-of select="$cols"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'array'"/>
        </xsl:apply-templates>
        <xsl:text>)</xsl:text>
    </xsl:if>
</xsl:template>


<!-- Sage Cells -->
<!-- Contents are text manipulations (below)     -->
<!-- Two abstract named templates in other files -->
<!-- provide the necessary wrapping, per format  -->

<!-- Utility: Class Names -->
<!-- This is the class we place on "pre" elements to have them configure    -->
<!-- as Sage cells.  This is given in the Javascript call in the head, and  -->
<!-- on the actual instances of Sage cells.  So this provides consistency.  -->
<!-- Passing an empty string for the language is historical, and could      -->
<!-- perhaps be unwound to be the default language in the parameter.        -->
<xsl:template name="sagecell-class-name">
    <xsl:param name="language-attribute"/>
    <xsl:param name="b-autoeval"/>

    <xsl:text>sagecell</xsl:text>
    <xsl:text>-</xsl:text>
    <xsl:choose>
        <xsl:when test="$language-attribute=''">
            <xsl:text>sage</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$language-attribute"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="$b-autoeval">
        <xsl:text>-</xsl:text>
        <xsl:text>autoeval</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Type; empty element                      -->
<!-- Provide an empty cell to scribble in     -->
<!-- Or break text cells in the Sage notebook -->
<!-- This cell does respect @language         -->
<xsl:template match="sage[not(input) and not(output) and not(@type)]">
    <xsl:apply-templates select="." mode="sage-active-markup">
        <!-- OK to send empty string, implementation reacts -->
        <xsl:with-param name="language-attribute">
            <xsl:value-of select="@language" />
        </xsl:with-param>
        <xsl:with-param name="b-autoeval" select="@auto-evaluate = 'yes'"/>
        <xsl:with-param name="in" select="''"/>
        <xsl:with-param name="out" select="''" />
    </xsl:apply-templates>
</xsl:template>

<!-- Type: "invisible"; to doctest, but never show to a reader -->
<xsl:template match="sage[@type='invisible']" />

<!-- Type: "practice"; empty, but with practice announcement -->
<!-- We override this in LaTeX, since it is useless          -->
<!-- (and we can't tell in the abstract wrapping template)   -->
<xsl:template match="sage[@type='practice']">
    <xsl:apply-templates select="." mode="sage-active-markup">
        <xsl:with-param name="language-attribute">
            <xsl:value-of select="'practice'" />
        </xsl:with-param>
        <xsl:with-param name="in" select="'# Practice area (not linked for Sage Cell use)&#xa;'"/>
        <xsl:with-param name="out" select="''" />
    </xsl:apply-templates>
</xsl:template>

<!-- Type: "display"; input portion as uneditable, unevaluatable -->
<!-- This calls a slightly different abstract template           -->
<!-- We do not pass along any output, since this is silly        -->
<!-- These cells are meant to be be incorrect or incomplete      -->
<xsl:template match="sage[@type='display']">
    <xsl:call-template name="sage-display-markup">
        <xsl:with-param name="language-attribute">
            <xsl:value-of select="'display'" />
        </xsl:with-param>
        <xsl:with-param name="in">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text" select="input" />
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Type: "full" (the default)         -->
<!-- Absent meeting any other condition -->
<xsl:template match="sage|sage[@type='full']">
    <xsl:apply-templates select="." mode="sage-active-markup">
        <!-- OK to send empty string, implementation reacts -->
        <xsl:with-param name="language-attribute">
            <xsl:value-of select="@language" />
        </xsl:with-param>
        <xsl:with-param name="b-autoeval" select="@auto-evaluate = 'yes'"/>
        <xsl:with-param name="in">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text" select="input" />
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="out">
            <xsl:if test="output">
                <xsl:call-template name="sanitize-text" >
                    <xsl:with-param name="text" select="output" />
                </xsl:call-template>
            </xsl:if>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- Console Session, prompt on input line-->
<!-- An interactive command-line session with pairs of input and output -->
<!-- Determining the prompt is a bit complicated, but always the same   -->
<!-- and always a pure textual result.  It becomes a part of the input  -->
<!-- line, so this modal template has an "input" as its context.        -->
<!--                                                                    -->
<!-- Priority:                                                          -->
<!--   1.  a specific @prompt on the "input" element                    -->
<!--   2.  an overall session-wide @prompt on the "console" element     -->
<!--   3.  a default, which can be superseded by a session-wide version -->
<!-- NB: could add a "docinfo" element for use just before the default? -->
<xsl:template match="console/input" mode="determine-console-prompt">
    <xsl:choose>
        <xsl:when test="@prompt">
            <xsl:value-of select="@prompt"/>
        </xsl:when>
        <!-- parent is guaranteed to be a "console", which can -->
        <!-- carry a default prompt for the entire session     -->
        <xsl:when test="parent::console/@prompt">
            <xsl:value-of select="parent::console/@prompt"/>
        </xsl:when>
        <!-- Default is a $-space, could just as well have been >-space -->
        <xsl:otherwise>
            <xsl:text>$&#x20;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Determine what string, if any, should be used for input "continuation" -->
<!-- Each line after the first would be prepended by this string -->
<!-- Looks for @continuation in the input, fall back to @continuation in console -->
<!-- Else default to empty. (Or should it be a number of spaces equaling the prompt?) -->
<xsl:template match="console/input" mode="determine-console-continuation">
    <xsl:choose>
        <xsl:when test="@continuation">
            <xsl:value-of select="@continuation"/>
        </xsl:when>
        <!-- parent is guaranteed to be a "console", which can    -->
        <!-- carry a default continuation for the entire session  -->
        <xsl:when test="parent::console/@continuation">
            <xsl:value-of select="parent::console/@continuation"/>
        </xsl:when>
        <!-- Default is empty -->
        <xsl:otherwise>
            <xsl:text/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################# -->
<!-- Preformatted Text -->
<!-- ################# -->

<!-- Inline "code" uses a "c" element and we want to be careful, so    -->
<!-- we use a universal template here, while leaving peculiarities     -->
<!-- of output formats to their respective stylesheets.  The "c"       -->
<!-- element never has any elements as children, so we grab the        -->
<!-- author's characters as their intent.  Output markup languages     -->
<!-- Important: we use a "value-of" instruction so that the            -->
<!-- text-manipulation routines do not get their hands on any          -->
<!-- whitespace or anything else.  So the parameter $content is pure   -->
<!-- character data.  A named template means no context, which is only -->
<!-- a problem when WeBWorK PG formulation wants to provide a location -->
<!-- report on a failure due to banned markup.                         -->
<!-- NB: newlines are assumed to be an editing convenience (hard       -->
<!-- line-breaks as part of word-wrapping, and not intended by the     -->
<!-- author to be literal.  We have other devices for multi-line       -->
<!-- verbatim text. -->
<xsl:template match="c">
    <!-- With no newlines, we use "value-of" to get the characters -->
    <!-- precisely.  Otherwise, we have newlines and likely each   -->
    <!-- will be followed by a run of spaces (indentation on the   -->
    <!-- subsequent line of the source), so we use a recursive     -->
    <!-- template to scrub the spaces.                             -->
    <xsl:variable name="raw-content">
        <xsl:choose>
            <xsl:when test="not(contains(., '&#xa;'))">
                <xsl:value-of select="."/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="reduce-line-break">
                    <xsl:with-param name="text">
                        <xsl:value-of select="."/>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- The newlines remain, but all trailing spaces have been -->
    <!-- scrubbed, so we replace newlines with spaces as part   -->
    <!-- of the application of the wrapper.                     -->
    <xsl:call-template name="code-wrapper">
        <xsl:with-param name="content" select="translate($raw-content, '&#xa;', '&#x20;')"/>
    </xsl:call-template>
</xsl:template>

<xsl:template name="code-wrapper">
    <xsl:message>PTX:BUG:  current conversion needs an implementation of the "code-wrapper" template</xsl:message>
</xsl:template>


<!-- The content of a "pre" element is wrapped many ways, -->
<!-- but the content itself is always strictly text       -->

<!-- With no "cline", we adjust left margin -->
<xsl:template match="pre" mode="interior">
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="." />
    </xsl:call-template>
</xsl:template>

<!-- With a "cline", we process the lines -->
<xsl:template match="pre[cline]" mode="interior">
    <xsl:apply-templates select="cline" />
</xsl:template>

<!-- Code Lines -->
<!-- A "cline" is used to (optionally) structure hunks     -->
<!-- of verbatim text.  Due to its simplicity, it should   -->
<!-- be universal and the only efffect is to add a newline -->
<!-- character, which the output format should recognize   -->
<!-- via its own devices.                                  -->
<!-- NB: the newline provide by the last "cline" of a      -->
<!-- structure is used by some recursive text utilities as -->
<!-- a signal, such as the "braille-source-code" template. -->
<xsl:template match="cline">
    <xsl:value-of select="." />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ############## -->
<!-- Lists of Names -->
<!-- ############## -->

<!-- Authors and editors are people credited in the front matter and in   -->
<!-- mastheads, etc.  Authors can appear on major divisions, such as      -->
<!-- chapters and sections.  There can be multiple, and we want to string -->
<!-- them together with commas, and give editors a parenthetical          -->
<!-- distinction.                                                         -->

<!-- First, we kill these elements as metadata, so we do not process them  -->
<!-- in document order, but instead need to always process them with modal -->
<!-- templates.                                                            -->
<xsl:template match="author|editor" />

<!-- Names can appear structured in the front matter, unstructured on -->
<!-- divisions, or as cross-references to contributors.               -->
<xsl:template match="author|editor" mode="name-only">
    <xsl:choose>
        <!-- structured version -->
        <xsl:when test="personname">
            <xsl:apply-templates select="personname"/>
        </xsl:when>
        <!-- Schematron assertion requires the target -->
        <!-- of the xref to be a contributor element  -->
        <xsl:when test="xref">
            <xsl:apply-templates select="xref"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="node()"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Authors, editors in serial lists for headers -->
<xsl:template match="author|editor" mode="name-list" >
    <!-- separator, if following -->
    <xsl:if test="preceding-sibling::author|preceding-sibling::editor">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <!-- name itself, from "personname" or the content -->
    <xsl:apply-templates select="." mode="name-only"/>
    <xsl:if test="self::editor">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates select="." mode="type-name" />
        <xsl:text>)</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Text Utilities -->
<!-- (2022-03-27) A number of basic named templates were split out from this -->
<!-- location.  Likely wise to move this to the top of this stylesheet.      -->
<xsl:include href = "./pretext-text-utilities.xsl"/>


<!-- When trying to represent XML source as it would have been authored, -->
<!-- we "break" the escape characters to result in their authored form.  -->
<!-- TODO: add &apos; and &quot; (which we *never* author,               -->
<!-- since just necessary for attributes).                               -->
<xsl:template match="node()" mode="serialize-content">
    <xsl:param name="as-authored-source"/>

    <xsl:choose>
        <xsl:when test="$as-authored-source = 'no'">
            <xsl:value-of select="."/>
        </xsl:when>
        <xsl:otherwise>
            <!-- fix raw ampersands before introducing more -->
            <xsl:variable name="fix-ampersand"    select="str:replace(.,              '&amp;', '&amp;amp;')"/>
            <xsl:variable name="fix-lessthan"     select="str:replace($fix-ampersand, '&lt;',  '&amp;lt;' )"/>
            <xsl:variable name="fix-greaterthan"  select="str:replace($fix-lessthan,  '&gt;',  '&amp;gt;' )"/>
            <xsl:value-of select="$fix-greaterthan"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ################## -->
<!-- LaTeX Shortcomings -->
<!-- ################## -->

<!-- Math bits are authored in LaTeX syntax, -->
<!-- but sometimes LaTeX needs a little help -->
<!-- to do the right thing.  This help is    -->
<!-- often common to several output formats, -->
<!-- so we put these modal templates here.   -->

<!-- Clauses ending with math -->
<!-- We look for an immediately adjacent/subsequent text -->
<!-- node and if we get any punctuation, we wrap it for  -->
<!-- inclusion in the final throes of the math part      -->
<!-- A corresponding event happens with the following    -->
<!-- text() node: the punctuation will get scrubbed      -->
<!-- from there iff the punctuation migrates in this     -->

<!-- Sometimes we just need the mark itself (e.g. braille).  Note -->
<!-- that the "mark" could well be plural, but usuually is not.   -->
<xsl:template match="m|md" mode="get-clause-punctuation-mark">
    <xsl:if test="(self::m and $b-include-inline) or (self::md and $b-include-display)">
        <xsl:variable name="trailing-text" select="following-sibling::node()[1]/self::text()" />
        <xsl:call-template name="leading-clause-punctuation">
            <xsl:with-param name="text" select="$trailing-text" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Usually we wrap the punctuation with \text{} for use   -->
<!-- inside LaTeX rendering.                                -->
<!-- NB: this mode name is not great, but we leave it as-is -->
<!-- from a refactor. A cosmetic refactor could improve it. -->
<xsl:template match="m|md" mode="get-clause-punctuation">
    <xsl:if test="(self::m and $b-include-inline) or (self::md and $b-include-display)">
        <xsl:variable name="punctuation">
            <xsl:apply-templates select="." mode="get-clause-punctuation-mark"/>
        </xsl:variable>
        <xsl:if test="not($punctuation = '')">
            <xsl:text>\text{</xsl:text>
            <xsl:value-of select="$punctuation" />
            <xsl:text>}</xsl:text>
        </xsl:if>
    </xsl:if>
</xsl:template>


<!-- ################################## -->
<!-- General Text Handling and Clean-Up -->
<!-- ################################## -->

<!-- Text adjustments -->
<!-- This is a general template for every text node.  -->
<!-- Note that most verbatim-ish elements should not  -->
<!-- be applying templates, but instead will use      -->
<!-- "xsl:value-of".  Math is an exception, since     -->
<!-- we allow some elements in amongst the            -->
<!-- "pure text" LaTeX syntax.  We are first using    -->
<!-- it to adjust for clause-ending punctuation       -->
<!-- being absorbed elsewhere into math, so we place  -->
<!-- this near math handling.                         -->
<!--                                                  -->
<!-- Later Strategy                                   -->
<!--                                                  -->
<!-- 1.  "Display" objects, such as lists, display    -->
<!-- math, and displayed verbatim text, can have text -->
<!-- nodes (before and after), stripped of whitespace -->
<!-- (trailing and leading, respectively).            -->
<!--                                                  -->
<!-- 2.  Any newlines left after this can be removed, -->
<!-- with some whitespace consolidated                -->

<!-- Punctuation ending a clause of a sentence   -->
<!-- Asymmetric: no space, mark, space           -->
<xsl:variable name="clause-ending-marks">
    <xsl:text>.?!:;,</xsl:text>
</xsl:variable>

<xsl:template match="text()">
    <!-- Scrub clause-ending punctuation immediately after math  -->
    <!-- It migrates and is absorbed in math templates elsewhere -->
    <!-- Side-effect: resulting leading whitespace is scrubbed   -->
    <!-- for displayed mathematics (only) as it is irrelevant    -->
    <xsl:variable name="first-char" select="substring(., 1, 1)" />
    <xsl:variable name="math-punctuation">
        <xsl:choose>
            <!-- drop punctuation after display math, if moving to math -->
            <xsl:when test="$b-include-display and contains($clause-ending-marks, $first-char) and preceding-sibling::node()[1][self::md[mrow]]">
                <xsl:call-template name="strip-leading-whitespace">
                    <xsl:with-param name="text">
                        <xsl:call-template name="drop-clause-punctuation">
                            <xsl:with-param name="text" select="." />
                        </xsl:call-template>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <!-- drop punctuation after inline math, if moving to math -->
            <xsl:when test="$b-include-inline and contains($clause-ending-marks, $first-char) and preceding-sibling::node()[1][self::m]">
                <xsl:call-template name="drop-clause-punctuation">
                    <xsl:with-param name="text" select="." />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="." />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- After math clause-ending rearrangements, we provide some    -->
    <!-- low-level text manipulations.  We do this via a conversion- -->
    <!-- specific hook, so we do not do more processing than is      -->
    <!-- necessary, presuming this template is executed frequently.  -->
    <!-- A math element that allows XML elements within will         -->
    <!-- be hit with "xsl:apply-templates" and arrive here,          -->
    <!-- so we need to guard against "text()" with parents:          -->
    <!-- "fillin", "xref", "var"   inside   "m",  "mrow"             -->
    <!-- The default behavior is a straight copy, with no changes.   -->
    <!-- NB: We defer WW-specific work for now.                      -->
    <xsl:variable name="text-processed">
        <xsl:choose>
            <xsl:when test="not(parent::m|parent::mrow)">
                <xsl:call-template name="text-processing">
                    <xsl:with-param name="text" select="$math-punctuation"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$math-punctuation"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- TODO: strip leading whitespace above only under  -->
    <!-- 'strict' policy, and combine two when clauses.   -->
    <!-- Below, strip leading and trailing whitespace on  -->
    <!-- either side of displayed objects, math and lists -->
    <!-- (only?), in addition to first and last nodes     -->
    <xsl:choose>
        <!-- pass through if assuming strict adherence to whitespace policy -->
        <xsl:when test="$whitespace-style = 'strict'">
            <xsl:value-of select="$text-processed" />
        </xsl:when>
        <!-- We must "apply-templates" to math bits in order    -->
        <!-- to process "var", "fillin" and "xref", so we pass  -->
        <!-- through neighboring text nodes under any policy    -->
        <!-- and we handle whitespace specially afterward       -->
        <xsl:when test="parent::*[self::m|self::mrow]">
            <xsl:value-of select="$text-processed" />
        </xsl:when>
        <!-- If a pure-whitespace text node is bracketed on both sides by -->
        <!-- index or notation elements, then almost certainly the space  -->
        <!-- is for source-formatting clarity and not significant for the -->
        <!-- content.  In particular, in LaTeX output the macros left     -->
        <!-- behind prevent consolidation of this whitespace and can lead -->
        <!-- to significant runs of abnormal whitespace in the output.    -->
        <xsl:when test="normalize-space($text-processed) = '' and preceding-sibling::node()[1][self::idx|self::notation] and following-sibling::node()[1][self::idx|self::notation]"/>
        <!-- manipulate leading, trailing, intermediate whitespace under flexible policy -->
        <!-- if only text node inside parent, all three transformations may apply        -->
        <!-- Note: space after clause-punctuation will not be deleted here               -->
        <xsl:when test="$whitespace-style = 'flexible'">
            <xsl:variable name="original" select="$text-processed" />
            <xsl:variable name="front-cleaned">
                <xsl:choose>
                    <xsl:when test="not(preceding-sibling::node()[self::*|self::text()]) or preceding-sibling::node()[self::*|self::text()][1][self::md[mrow]|self::cd|self::pre|self::ol/parent::p|self::ul/parent::p|self::dl/parent::p]">
                        <xsl:call-template name="strip-leading-whitespace">
                            <xsl:with-param name="text" select="$original" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$original" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="back-cleaned">
                <xsl:choose>
                    <xsl:when test="not(following-sibling::node()[self::*|self::text()])  or following-sibling::node()[self::*|self::text()][1][self::md[mrow]|self::cd|self::pre|self::ol/parent::p|self::ul/parent::p|self::dl/parent::p]">
                        <xsl:call-template name="strip-trailing-whitespace">
                            <xsl:with-param name="text" select="$front-cleaned" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$front-cleaned" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="middle-cleaned">
                <xsl:call-template name="strip-newlines">
                    <xsl:with-param name="text" select="$back-cleaned" />
                </xsl:call-template>
            </xsl:variable>
            <!-- ACTUAL output -->
            <xsl:value-of select="$middle-cleaned" />
            <!-- comes from ws.debug string parameter -->
            <xsl:if test="$wsdebug and not($text-processed = $middle-cleaned)">
                <!-- DEBUGGING follows, maybe move outward later -->
                <xsl:message>
                    <xsl:text>****&#xa;</xsl:text>
                    <xsl:text>O:</xsl:text>
                    <xsl:value-of select="." />
                    <xsl:text>:O&#xa;</xsl:text>
                    <xsl:text>M:</xsl:text>
                    <xsl:value-of select="$text-processed" />
                    <xsl:text>:M&#xa;</xsl:text>
                    <xsl:text>F:</xsl:text>
                    <xsl:value-of select="$front-cleaned" />
                    <xsl:text>:F&#xa;</xsl:text>
                    <xsl:text>B:</xsl:text>
                    <xsl:value-of select="$back-cleaned" />
                    <xsl:text>:B&#xa;</xsl:text>
                    <xsl:text>M:</xsl:text>
                    <xsl:value-of select="$middle-cleaned" />
                    <xsl:text>:M&#xa;</xsl:text>
                    <xsl:text>****&#xa;</xsl:text>
                </xsl:message>
            </xsl:if>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Text-processing should be done carefully in a per-conversion -->
<!-- manner.  Absent anything special, we just duplicate.         -->
<xsl:template name="text-processing">
    <xsl:param name="text"/>
    <xsl:value-of select="$text"/>
</xsl:template>

<!-- Date and Time Functions -->
<!-- http://stackoverflow.com/questions/1437995/how-to-convert-2009-09-18-to-18th-sept-in-xslt -->
<!-- http://remysharp.com/2008/08/15/how-to-default-a-variable-in-xslt/ -->
<xsl:template match="today">
    <xsl:variable name="format">
        <xsl:choose>
            <xsl:when test="@format"><xsl:value-of select="@format" /></xsl:when>
            <xsl:otherwise>month-day-year</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="datetime" select="substring(date:date-time(),1,10)" />
    <xsl:choose>
        <xsl:when test="$format='month-day-year'">
            <xsl:value-of select="date:month-name($datetime)" />
            <xsl:text> </xsl:text>
            <xsl:value-of select="date:day-in-month($datetime)" />
            <xsl:text>, </xsl:text>
            <xsl:value-of select="date:year($datetime)" />
        </xsl:when>
        <xsl:when test="$format='yyyy/mm/dd'">
            <xsl:value-of select="substring($datetime, 1, 4)" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="substring($datetime, 6, 2)" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="substring($datetime, 9, 2)" />
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Could use a format to suppress/manipulate time zone -->
<xsl:template match="timeofday">
    <xsl:value-of select="substring(date:date-time(),12,8)" />
    <xsl:text> (</xsl:text>
    <xsl:value-of select="substring(date:date-time(),20)" />
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- ################## -->
<!-- Document Structure -->
<!-- ################## -->

<!-- Structural Nodes -->
<!-- Some elements of the XML tree are structural elements of the document tree  -->
<!-- This is our logical overlay on the (finer, larger, more expansive) XML tree -->
<!-- Example: <section> is structural, and ancestors are all structural          -->
<!-- Example: <title> is not structural, but does have a structural ancestor     -->
<!-- NB: These elements need only be specified here, and in leaf template (next) -->
<xsl:template match="&STRUCTURAL;" mode="is-structural">
    <xsl:value-of select="true()" />
</xsl:template>

<xsl:template match="*" mode="is-structural">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- Structural Leaves -->
<!-- Some structural elements of the document tree     -->
<!-- are the leaves of that tree, meaning they do      -->
<!-- not contain any structural nodes themselves       -->
<!-- backmatter is always structured, else no purpose  -->
<!-- frontmatter is anomalous:  "titlepage" (and       -->
<!-- for an "article", "abstract") are not treated     -->
<!-- as divisions, they just get mined as part of the  -->
<!-- frontmatter itself.  So an article/frontmatter    -->
<!-- is always a leaf, and a book/frontmatter is not   -->
<!-- a leaf if it has a child other than a "titlepage" -->
<!-- Generally, we look for definitive markers         -->
<!-- NB: references, exercises, solutions not relevant -->
<xsl:template match="&STRUCTURAL;" mode="is-leaf">
    <xsl:choose>
        <xsl:when test="self::frontmatter">
            <xsl:choose>
                <xsl:when test="parent::article">
                    <xsl:value-of select="true()" />
                </xsl:when>
                <xsl:when test="parent::book">
                    <xsl:value-of select="not(*[not(self::titlepage)])" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:BUG:     asking if a "frontmatter" is a leaf, for a document that is not a "book" nor an "article"</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="self::backmatter">
            <xsl:value-of select="false()" />
        </xsl:when>
        <!-- The presence of a traditional division is emblematic of a structured -->
        <!-- division, so not a leaf of the structural/document tree              -->
        <xsl:when test="part or chapter or section or subsection or subsubsection">
            <xsl:value-of select="false()" />
        </xsl:when>
        <!-- One exception, a division full of only "worksheet" or "handout"     -->
        <!-- (as a subdivision, there could be metadata, "introduction", etc.)   -->
        <!-- We know there are no traditional divisions as subdiivisions at this -->
        <!-- point.  So we test for at least one worksheet or handout and no     -->
        <!-- other specialized divisions.                                        -->
        <xsl:when test="(worksheet or handout) and not(exercises|references|glossary|reading-questions|solutions)">
            <xsl:value-of select="false()" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="true()" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- This once just returned false,      -->
<!-- but should maybe not even be called -->
<xsl:template match="*" mode="is-leaf">
    <xsl:value-of select="false()" />
    <!-- <xsl:message>PTX:BUG:     asking if a non-structural division is a leaf</xsl:message> -->
</xsl:template>

<!-- There are two models for most of the divisions (part -->
<!-- through subsubsection, plus appendix).  One has      -->
<!-- subdivisions, and possibly multiple "exercises", or  -->
<!-- other specialized subdivisions.  (Namely "worksheet",-->
<!-- "handout", "exercises", "solutions", and not         -->
<!-- "references", "glossary", nor "reading-questions".)  -->
<!-- The other has no subdivisions, and then at most one  -->
<!-- of each type of specialized subdivision, which       -->
<!-- inherit numbers from their parent division. This is  -->
<!-- the test, which is very similar to "is-leaf" above.  -->
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

<!-- Test if element is a specialized division or not. -->
<!-- If element is not even a division, give error.    -->
<xsl:template match="*" mode="is-specialized-division">
    <xsl:choose>
        <xsl:when test="&TRADITIONAL-DIVISION-FILTER;">
            <xsl:value-of select="false()"/>
        </xsl:when>
        <xsl:when test="&SPECIALIZED-DIVISION-FILTER;">
            <xsl:value-of select="true()"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:BUG: asking if a non-division (<xsl:value-of select="local-name(.)"/>) is a specialized division</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- We also want to identify smaller pieces of a document,          -->
<!-- such as when they contain an index element or defined term,     -->
<!-- so we can reference back to them.  We call these "blocks" here, -->
<!-- which mostly corresponds to the use of the term in the DTD.     -->
<!-- The difference is that a paragraph is a "block" if and only if  -->
<!-- it is a direct descendant of a structural node or a directly    -->
<!-- descended introduction or conclusion .                          -->
<!-- Also, list items are considered blocks.                         -->
<!-- NB: we don't point to a sidebyside, so not included here        -->
<xsl:template match="md[mrow]|ul|ol|dl|blockquote|pre|sage|&FIGURE-LIKE;|poem|program|image|tabular|paragraphs|&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|assemblage|exercise|li" mode="is-block">
    <xsl:value-of select="true()" />
</xsl:template>

<xsl:template match="p" mode="is-block">
    <xsl:choose>
        <xsl:when test="parent::introduction or parent::conclusion">
            <xsl:variable name="interloper" select="parent::*" />
            <xsl:apply-templates select="$interloper/parent::*" mode="is-structural" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="is-structural" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="is-block">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- FIGURE-LIKE as panels of sidebyside -->
<!-- A "figure", "table", "list", or "listing" has slightly different    -->
<!-- behavior (potentially) when appearing as a panel of a "sidebyside". -->
<!-- It can be "subnumbered" (e.g. (a), (b), (c),...) or it may normally -->
<!-- be titled above, and we want to place the title below (more like a  -->
<!-- caption) so the faux-titles and captions seem to (almost) align     -->
<!-- vertically with each other.  Generally this means authoring the     -->
<!-- panel with bottom alignment.                                        -->
<!--                                                                     -->
<!--   "block" - child of a division, captions below, titles above,      -->
<!--     as according to CMoS.                                           -->
<!--                                                                     -->
<!--   "panel" - a panel of a side-by-side, but with a block number      -->
<!--     of its own, since there is no enclosing "figure"                -->
<!--                                                                     -->
<!--   "subnumber" - a panel of a side-by-side, which in turn is a       -->
<!--     child/descendant of a "figure" (a "sbsgroup" may intervene).    -->
<!--     This triggers a block number foor the exterior "figure" and     -->
<!--     a subnumber for the interior FIGURE-LIKE.                       -->
<!--                                                                     -->
<!-- (These code comments are referenced in the LaTeX conversion.)       -->
<!--                                                                     -->
<xsl:template match="&FIGURE-LIKE;" mode="figure-placement">
    <!-- more specific first, reverse of description above -->
    <xsl:choose>
        <xsl:when test="parent::sidebyside and ancestor::figure">
            <xsl:text>subnumber</xsl:text>
        </xsl:when>
        <xsl:when test="parent::sidebyside">
            <xsl:text>panel</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>block</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ####################### -->
<!-- Chunking Document Nodes -->
<!-- ####################### -->


<!-- When we break a document into pieces, known as "chunks,"       -->
<!-- there is a configurable level (the "chunk-level") where        -->
<!-- the document nodes at that level are always a chunk.           -->
<!-- At a lesser level, document nodes are "intermediate" nodes     -->
<!-- and so are output as summaries of their children.              -->
<!-- However, an intermediate node may have no children             -->
<!-- (is a "leaf") and hence is output as a chunk.                  -->
<!--                                                                -->
<!-- Said differently, chunks are natural leaves of the document    -->
<!-- tree, or leaves (dead-ends) manufactured by an arbitrary       -->
<!-- cutoff given by the chunk-level variable                       -->
<!--                                                                -->
<!-- So we have three types of document nodes:                      -->
<!-- Intermediate: structural node, not a document leaf, smaller    -->
<!--               level than chunk-level                           -->
<!--   Realization: some content (title, introduction, conclusion), -->
<!--                links/includes to children                      -->
<!-- Leaf: structural node, at chunk-level or a leaf at smaller     -->
<!--       level than chunk-level                                   -->
<!--   Realization: a chunk will all content                        -->
<!-- Neither: A structural node that is simply a (visual)           -->
<!--          division of a chunk                                   -->
<!--   Realization: usual presentation, within the enclosing chunk  -->


<!-- An intermediate node is at lesser level -->
<!-- than chunk-level and is not a leaf      -->
 <xsl:template match="*" mode="is-intermediate">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$structural='true'">
            <xsl:variable name="current-level">
                <xsl:apply-templates select="." mode="level" />
            </xsl:variable>
            <xsl:variable name="leaf">
                <xsl:apply-templates select="." mode="is-leaf" />
            </xsl:variable>
            <xsl:value-of select="($leaf='false') and ($chunk-level > $current-level)" />
        </xsl:when>
        <xsl:when test="$structural='false'">
            <xsl:value-of select="$structural" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:BUG: Structural determination (<xsl:value-of select="$structural" />) failed for is-intermediate at <xsl:apply-templates select="." mode="long-name"/></xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A chunk node is at the chunk-level, -->
<!-- or a leaf at a lesser level         -->
<xsl:template match="*" mode="is-chunk">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$structural='true'">
            <xsl:variable name="current-level">
                <xsl:apply-templates select="." mode="level" />
            </xsl:variable>
            <xsl:variable name="leaf">
                <xsl:apply-templates select="." mode="is-leaf" />
            </xsl:variable>
            <xsl:value-of select="($chunk-level = $current-level) or ( ($leaf='true') and ($chunk-level > $current-level) )" />
        </xsl:when>
        <xsl:when test="$structural='false'">
            <xsl:value-of select="$structural" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:BUG: Structural determination (<xsl:value-of select="$structural" />) failed for is-chunk at <xsl:apply-templates select="." mode="long-name"/></xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- #################################### -->
<!-- Abstract Chunking of Structural Nodes-->
<!-- #################################### -->

<!-- Implementations get structural nodes of two types          -->
<!--                                                            -->
<!--   1) "chunk"                                               -->
<!--       usually realizable as a single file by               -->
<!--       applying default templates                           -->
<!--                                                            -->
<!--   2) "intermediate":                                       -->
<!--       usually realizable as a single file with a title,    -->
<!--       introduction and conclusion surrounding a summary    -->
<!--       of the subdivisions it contains                      -->
<!--                                                            -->
<!-- So an implementation must implement two modal templates    -->
<!--                                                            -->
<!--   1) match="&STRUCTURAL;" mode="chunk"                     -->
<!--   2) match="&STRUCTURAL;" mode="intermediate"              -->
<!--                                                            -->
<!-- Similarities can be consolidated within the implementation -->
<!-- See  xsl/pretext-html.xsl  for a canonical example         -->
<!--                                                            -->
<!-- See the discussion just above to understand leaves of the  -->
<!-- document tree (always chunks), manufactured leaves (due to -->
<!-- an arbitrary, but configured, chunk level depth), and      -->
<!-- intermediate nodes (structured divisions above the chunk   -->
<!-- level line).                                               -->
<!--                                                            -->
<!-- NB: as of 2020-12-30 these implementations are used        -->
<!-- directly as-is or are overridden (in part) by the          -->
<!-- conversions to WeBWorK problem sets and logical files for  -->
<!-- Sage doctesting.  They are also extended in the HTML       -->
<!-- conversion, which is again extended by the EPUB and        -->
<!-- Jupyter conversions.  This is an exhaustive list of uses.  -->

<xsl:template match="&STRUCTURAL;" mode="chunking">
    <xsl:variable name="chunk">
        <xsl:apply-templates select="." mode="is-chunk" />
    </xsl:variable>
     <xsl:choose>
        <xsl:when test="$chunk='true'">
            <xsl:apply-templates select="." mode="chunk" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="intermediate" />
            <xsl:apply-templates select="&STRUCTURAL;" mode="chunking" />
        </xsl:otherwise>
    </xsl:choose>
 </xsl:template>

<!-- docinfo, and anything else, is immune and dead-ends -->
<xsl:template match="*" mode="chunking" />

<!-- With an implementation of a file-wrapping routine,     -->
<!-- a typical use is to                                    -->
<!--                                                        -->
<!--   (a) apply a default template to the structural       -->
<!--       node for a complete (chunk'ed) node              -->
<!--                                                        -->
<!--   (b) apply a modal template to the structural         -->
<!--       node for a summary (intermediate) node           -->
<!--                                                        -->
<!-- The "file-wrap" routine should accept a $content       -->
<!-- parameter holding the contents of the body of the page -->

<!-- A complete file/page for a structural division         -->
<xsl:template match="&STRUCTURAL;" mode="chunk">
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="content">
            <xsl:apply-templates select="." />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- An intermediate file/page for a structural division    -->
<!-- It is very possible this implementation is not correct -->
<!-- or desirable, since the notion of an "intermediate"    -->
<!-- (or "summary") page/file is a bit unusual.             -->
<!--                                                        -->
<!-- See  xsl/pretext-ww-problem-sets.xsl  for an example   -->
<!-- use, in addition to a non-trivial application for the  -->
<!-- (primary) HTML conversion. -->
<!--                                                        -->
<!-- See  xsl/pretext-sage-doctest.xsl  for a conversion    -->
<!-- which only implements the "file-wrap" template.        -->
<xsl:template match="&STRUCTURAL;" mode="intermediate">
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="content">
            <xsl:apply-templates select="*[not(&STRUCTURAL-FILTER;)]" />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- Containing Filenames, URLs -->
<!-- Relative to the chunking in effect, every -->
<!-- XML element is born within some file.     -->
<!-- That filename will have a different       -->
<!-- suffix in different conversions.          -->
<!-- Parameter: $file-extension, set globally  -->
<xsl:template match="*" mode="containing-filename">
    <!-- this is a frequent programming error -->
    <xsl:if test="$chunk-level = ''">
        <xsl:message>PTX:BUG:   the $chunk-level variable is empty, so must have been set improperly, perhaps when overridden in a conversion.  The "containing-filename" template is likely to act incorrectly.  Please report me</xsl:message>
    </xsl:if>
    <xsl:variable name="intermediate">
        <xsl:apply-templates select="." mode="is-intermediate" />
    </xsl:variable>
    <xsl:variable name="chunk">
        <xsl:apply-templates select="." mode="is-chunk" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$intermediate='true' or $chunk='true'">
            <xsl:apply-templates select="." mode="visible-id" />
            <xsl:value-of select="$file-extension" />
        </xsl:when>
        <!-- Halts since "mathbook" element will be chunk (or earlier) -->
        <xsl:otherwise>
            <xsl:apply-templates select=".." mode="containing-filename" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ###### -->
<!-- Titles -->
<!-- ###### -->

<!-- Titles are like metadata, they are a useful property    -->
<!-- of many things and they migrate many different places.  -->
<!-- So principally, we kill them on sight.  But we provide  -->
<!-- modal templates as interfaces to titles and derivatives -->
<!-- of them for purposes where only a restricted subset of  -->
<!-- their content is allowed.                               -->
<!--                                                         -->
<!-- Also, many stock divisions have natural default titles, -->
<!-- so we want to accomodate that option, and do so via     -->
<!-- the localization routines.                              -->


<!-- With modal templates below, the default template does nothing   -->
<!-- We include the "creator" element of a theorem/axiom as metadata -->
<!-- NB: since these elements get killed on-sight, when we actually  -->
<!-- want to process them we need to use a "select" attribute        -->
<!-- similar to  title/*|title/text() or title/node().               -->
<xsl:template match="title" />
<xsl:template match="subtitle" />
<xsl:template match="shorttitle"/>
<xsl:template match="plaintitle"/>
<xsl:template match="creator" />

<!-- Some items have default titles that make sense         -->
<!-- Typically these are one-off subdivisions (eg preface), -->
<!-- or repeated generic divisions (eg exercises)           -->
<xsl:template match="frontmatter|colophon|preface|foreword|acknowledgement|dedication|biography|abstract|references|glossary|exercises|worksheet|handout|reading-questions|exercisegroup|solutions|backmatter|index|case|interactive/instructions|keywords" mode="has-default-title">
    <xsl:text>true</xsl:text>
</xsl:template>
<xsl:template match="*" mode="has-default-title">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- NB: these templates return a property of the title's parent -->

<xsl:template match="keywords" mode="default-title">
    <xsl:choose>
        <xsl:when test="@authority='msc'">
            <xsl:if test="@variant">
                <xsl:value-of select="@variant"/>
                <xsl:text>&#160;</xsl:text>
            </xsl:if>
            <xsl:text>Math Subject Classification</xsl:text>
        </xsl:when>
        <!-- Default is @authority='author' or no recognized authority given -->
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="type-name"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Normally a default title is the "type-name" of the object. -->
<!-- But to indicate that a "worksheet" or "exercises" division -->
<!-- is groupwork, we preface the title.                        -->
<xsl:template match="*" mode="default-title">
    <xsl:if test="(@groupwork= 'yes') and (self::worksheet or self::exercises)">
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'group'"/>
        </xsl:apply-templates>
        <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="type-name"/>
</xsl:template>


<!-- This has much of the logic of producing a title, but lacks any  -->
<!-- additional punctuation, so is useful for titles employed places  -->
<!-- other than immediately adjacent to the content they describe. -->
<xsl:template match="*" mode="title-xref">
    <xsl:variable name="default-exists">
        <xsl:apply-templates select="." mode="has-default-title" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="title/line">
            <xsl:apply-templates select="title/line">
                <xsl:with-param name="separator" select="$title-separator"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- select="title" would just get it killed -->
        <xsl:when test="title">
            <xsl:apply-templates select="title/node()" />
        </xsl:when>
        <xsl:when test="$default-exists='true'">
            <xsl:apply-templates select="." mode="default-title"/>
        </xsl:when>
        <!-- otherwise empty -->
        <xsl:otherwise />
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="title-full">
    <!-- first, the punctuation-less version -->
    <xsl:apply-templates select="." mode="title-xref"/>
    <!-- Should we add punctuation?                       -->
    <!--   1. Should not have any already,                -->
    <!--   2. Or should be a default version,             -->
    <!--   3. Plus should be a situation where we want it -->

    <!-- with no title present, first variable is an empty string -->
    <xsl:variable name="has-punctuation">
        <xsl:apply-templates select="title" mode="has-punctuation"/>
    </xsl:variable>
    <xsl:variable name="default-exists">
        <xsl:apply-templates select="." mode="has-default-title" />
    </xsl:variable>
    <xsl:variable name="default-in-use">
        <xsl:value-of select="not(title) and $default-exists = 'true'"/>
    </xsl:variable>
    <xsl:variable name="wants-period">
        <xsl:apply-templates select="." mode="title-wants-punctuation"/>
    </xsl:variable>
    <xsl:if test="(($has-punctuation = 'false') or ($default-in-use = 'true')) and ($wants-period = 'true')">
        <xsl:text>.</xsl:text>
    </xsl:if>
</xsl:template>

<!-- This template does elective sanitization of a title, which  -->
<!-- is distinct for universal adjustments (such as protecting   -->
<!-- LaTeX macros, or making any "xref" static.  So removing a   -->
<!-- footnote is such a sanitization (we allow it on a "real"    -->
<!-- title, but not when migrating other places).  This template -->
<!-- is not called often, usually the "title-short" template is  -->
<!-- the right template to call when a title is duplicated.      -->
<!-- We pass a space for the version structured with "line".     -->
<!-- TODO: ban fn in titles, then maybe this is obsolete -->
<!-- or maybe we should be careful about math            -->
<xsl:template match="*" mode="title-simple">
    <xsl:variable name="default-exists">
        <xsl:apply-templates select="." mode="has-default-title" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="title/line">
            <xsl:apply-templates select="title/line">
                <xsl:with-param name="separator" select="' '"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- select="title" would just get it killed -->
        <!-- avoid footnotes in simple version       -->
        <xsl:when test="title">
            <xsl:apply-templates select="title/*[not(self::fn)]|title/text()" />
        </xsl:when>
        <xsl:when test="$default-exists='true'">
            <xsl:apply-templates select="." mode="default-title"/>
        </xsl:when>
        <!-- otherwise empty -->
        <xsl:otherwise />
    </xsl:choose>
</xsl:template>

<!-- Short titles are meant for places such as the Table of  -->
<!-- Contents and for LaTeX, the page headers and/or footers -->
<!-- It'd be silly to structure this with "line"             -->
<xsl:template match="*" mode="title-short">
    <xsl:choose>
        <!-- schema should control content, eg no footnotes -->
        <!-- optional, so check for author's suggestion     -->
        <xsl:when test="shorttitle">
            <xsl:apply-templates select="shorttitle/node()[not(self::fn)]"/>
        </xsl:when>
        <!-- else, existing title, cleaned up -->
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="title-simple"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A version of the title with all abnormal characters stripped -->
<!-- and using underscores in place of spaces                     -->
<!-- http://stackoverflow.com/questions/1267934/                  -->
<!-- removing-non-alphanumeric-characters-from-string-in-xsl      -->
<xsl:template match="*" mode="title-filesafe">
    <!-- first, the simple title -->
    <xsl:variable name="raw-title">
        <xsl:apply-templates select="." mode="title-simple"/>
    </xsl:variable>
    <xsl:variable name="letter-only-title">
        <xsl:value-of select="translate($raw-title, translate($raw-title, concat(&SIMPLECHAR;,' '), ''), '')" />
    </xsl:variable>
    <xsl:value-of select="translate($letter-only-title, ' ', '_')" />
</xsl:template>

<!-- This comes from writing out WW problems to filenames    -->
<!-- in some sort of reasonable numbering scheme             -->
<!-- It is not integrated into the above complexity-scheme   -->
<!-- (though does call the "title-filesafe" modal template)  -->
<!-- Consider integration if there is a refactoring of above -->
<xsl:template match="*" mode="numbered-title-filesafe">
    <!-- traditional "dotted" number -->
    <xsl:variable name="dotted-number">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:variable name="title-string">
        <xsl:apply-templates select="." mode="title-filesafe" />
    </xsl:variable>
    <!-- number output, with dot to dash conversion -->
    <xsl:value-of select="translate($dotted-number, '.', '_')" />
    <!-- separator, if needed -->
    <xsl:if test="not($dotted-number = '' or $title-string = '')">
        <xsl:text>-</xsl:text>
    </xsl:if>
    <xsl:value-of select="$title-string" />
</xsl:template>

<!-- We get subtitles the same way, but with no variations -->
<!-- Structured with "line" is a possibility               -->
<xsl:template match="*" mode="subtitle">
    <xsl:choose>
        <xsl:when test="subtitle/line">
            <xsl:apply-templates select="subtitle/line">
                <xsl:with-param name="separator" select="$title-separator"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- select="subtitle" would just get it killed -->
        <xsl:when test="subtitle">
            <xsl:apply-templates select="subtitle/*|subtitle/text()" />
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Plain title: motivation is browser tabs without extensive -->
<!-- MathJax markup around (little bits) of mathematics        -->
<!-- Also used for <meta> in HTML carrying identification      -->
<xsl:template match="*" mode="title-plain">
    <xsl:variable name="default-exists">
        <xsl:apply-templates select="." mode="has-default-title" />
    </xsl:variable>
    <xsl:choose>
        <!-- "plaintitle" has *no* markup, but we do strip extra   -->
        <!-- whitespace by sending to generic text node processing -->
        <xsl:when test="plaintitle">
            <xsl:apply-templates select="plaintitle/text()"/>
        </xsl:when>
        <xsl:when test="title">
            <xsl:apply-templates select="title/node()[not(self::fn)]" mode="plain-title-edit"/>
        </xsl:when>
        <!-- We assume the automatic titles are plain -->
        <xsl:when test="$default-exists='true'">
            <xsl:apply-templates select="." mode="default-title"/>
        </xsl:when>
        <!-- just empty if there is no titles, no default -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:template>

<!-- We do not wrap an "m" element as part of a plain title -->
<!-- This will misbehave for m/xref and m/fillin, etc, but  -->
<!-- these devices should not be in a title anyway          -->
<!-- N.B. this would be a place to do some crude            -->
<!-- substitutions, such as "\delta" -> "δ" (U+03B4)        -->
<xsl:template match="m" mode="plain-title-edit">
    <xsl:value-of select="."/>
</xsl:template>

<!-- We do not wrap an "c" element as part of a plain title -->
<xsl:template match="c" mode="plain-title-edit">
    <xsl:value-of select="."/>
</xsl:template>

<!-- We dumb-down quotation marks to "straight" ASCII. -->
<!-- These behave well in output as attribute values,  -->
<!-- the HTML serialization seems "smart" enough to    -->
<!-- escape properly, even when both typesare present. -->

<xsl:template match="q" mode="plain-title-edit">
    <xsl:text>"</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>"</xsl:text>
</xsl:template>

<xsl:template match="sq" mode="plain-title-edit">
    <xsl:text>'</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>'</xsl:text>
</xsl:template>

<!-- Return processing to defaults for most elements of titles -->
<xsl:template match="node()" mode="plain-title-edit">
    <xsl:apply-templates select="."/>
</xsl:template>

<!-- We let styling provide punctuation for titles, principally       -->
<!-- a period at the end.  But this is awkward if there is already    -->
<!-- punctuation there.  This template returns the string 'true' if,  -->
<!-- and only if, such punctuation exists.  Else, it returns 'false'. -->
<!-- Consolidating interior whitespace should have no effect.         -->
<!-- Text generators (eg <today />) may fool this, but applying       -->
<!-- templates first will introduce LaTeX macros that will fool this  -->
<!-- To debug: add messages here, then call via this default template -->
<!-- TODO: maybe warn about "bad" ending-punctuation, like a colon? -->
<xsl:template match="title|subtitle" mode="has-punctuation">
    <xsl:variable name="title-ending-punctuation" select="'?!'" />
    <xsl:variable name="all-text" select="normalize-space(string(.))" />
    <xsl:variable name="last-char" select="substring($all-text, string-length($all-text))" />
    <!-- title should not be empty, but if so, the contains() alone is true -->
    <xsl:value-of select="$last-char and contains($title-ending-punctuation, $last-char)" />
</xsl:template>

<!-- Some titles should have periods supplied by PTX, mostly   -->
<!-- "smaller" objects like "example" and not "larger" objects -->
<!-- like "chapter".  We create a template to signal this, for -->
<!-- consistency across conversions, and so that it can be     -->
<!-- consciously overridden as part of styling work.  In       -->
<!-- pieces simply so it is more readable.                     -->
<!--                                                           -->
<!-- Blocks -->
<xsl:template match="&THEOREM-LIKE;|&PROOF-LIKE;|&AXIOM-LIKE;|&DEFINITION-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&ASIDE-LIKE;|exercise|assemblage" mode="title-wants-punctuation">
    <xsl:value-of select="true()"/>
</xsl:template>
<!-- Miscellaneous -->
<xsl:template match="paragraphs|case|exercisegroup" mode="title-wants-punctuation">
    <xsl:value-of select="true()"/>
</xsl:template>
<!-- Titled: list items; tasks of exercise, PROJECT-LIKE, EXAMPLE-LIKE; glossary items -->
<xsl:template match="ol/li|ul/li|task|gi" mode="title-wants-punctuation">
    <xsl:value-of select="true()"/>
</xsl:template>
<!-- Introductions and Conclusions -->
<xsl:template match="article/introduction|chapter/introduction|section/introduction|subsection/introduction|appendix/introduction|exercises/introduction|solutions/introduction|worksheet/introduction|handout/introduction|reading-questions/introduction|glossary/introduction|references/introduction|article/conclusion|chapter/conclusion|section/conclusion|subsection/conclusion|appendix/conclusion|exercises/conclusion|solutions/conclusion|worksheet/conclusion|handout/conclusion|reading-questions/conclusion|glossary/conclusion|references/conclusion" mode="title-wants-punctuation">
    <xsl:value-of select="true()"/>
</xsl:template>
<xsl:template match="*" mode="title-wants-punctuation">
    <xsl:value-of select="false()"/>
</xsl:template>

<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="creator-full">
    <!-- select="creator" would just get it killed -->
    <xsl:apply-templates select="creator/*|creator/text()" />
</xsl:template>

<!-- Structured titles -->

<!-- Each "line", except the last, gets a separator     -->
<!-- Almost always a space, but for LaTeX, at birth,    -->
<!-- a newline.  We make it obvious that this character -->
<!-- has not been overridden in a conversion            -->

<xsl:variable name="title-separator" select="'[TITLESEP]'"/>

<!-- Books:    overall title and subtitle, titles of parts, chapters and sections -->
<!-- Articles: overall title and subtitle, titles of sections                     -->
<xsl:template match="book/title/line|book/subtitle/line|book/part/title/line|book/part/chapter/title/line|book/chapter/title/line|book/part/chapter/section/title/line|book/chapter/section/title/line|article/title/line|article/subtitle/line|article/section/title/line">
    <xsl:param name="separator"/>

    <xsl:apply-templates/>
    <xsl:if test="following-sibling::line">
        <xsl:value-of select="$separator"/>
    </xsl:if>
</xsl:template>


<!-- ######## -->
<!-- Captions -->
<!-- ######## -->

<!-- Captions are similar to titles.  They should be -->
<!-- killed as metadata and requested when needed.   -->

<xsl:template match="caption"/>

<!-- A caption can have a footnote, thus HTML will create    -->
<!-- a knowl, and we need to distinguish between original    -->
<!-- and duplicate scenarios.  For other conversions, the    -->
<!-- "b-original" parameter should just be silently ignored. -->
<xsl:template match="figure|listing" mode="caption-full">
    <xsl:param name="b-original" select="true()"/>

    <xsl:if test="caption">
        <xsl:apply-templates select="caption/node()">
            <xsl:with-param name="b-original" select="$b-original"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- #################################### -->
<!-- Widths of Images, Audio, Videos, Etc -->
<!-- #################################### -->

<!-- Because we allow width settings as consequences of sidebyside     -->
<!-- layout parameters, we need to "reach up" and get these widths     -->
<!-- on occassion.  So we consider the PreTeXt markup/situation and    -->
<!-- produce a percentage as a string.  Consumers need to convert to   -->
<!-- a percentage, pixels, fractional linewidths - whatever is needed. -->

<!-- An image appears -->
<!--                                                                      -->
<!--   1.  in a figure (itself not in a sidebyside) where it              -->
<!--       can have a width specification on itself                       -->
<!--   2.  in a sidebyside directly, or a figure in a sidebyside.         -->
<!--       These widths come from the layout, and are converter dependent -->
<!--                                                                      -->
<!-- Entirely similar for jsxgraph, audio and video but we do             -->
<!-- not consult default *image* width in docinfo                         -->

<xsl:template match="image[not(ancestor::sidebyside)]|audio[not(ancestor::sidebyside)]|video[not(ancestor::sidebyside)]|jsxgraph[not(ancestor::sidebyside)]|interactive[not(ancestor::sidebyside)]|slate[not(ancestor::sidebyside)]" mode="get-width-percentage">
    <!-- find it first -->
    <xsl:variable name="raw-width">
        <xsl:choose>
            <!-- right on the element! -->
            <xsl:when test="@width">
                <xsl:value-of select="@width" />
            </xsl:when>
            <!-- not on an image, but doc-wide default exists -->
            <xsl:when test="self::image and $docinfo/defaults/image-width">
                <xsl:value-of select="$docinfo/defaults/image-width" />
            </xsl:when>
            <!-- naked slate, look to enclosing interactive -->
            <xsl:when test="self::slate">
                <xsl:apply-templates select="parent::interactive" mode="get-width-percentage" />
            </xsl:when>
            <!-- what to do? Author will figure it out if too extreme -->
            <xsl:otherwise>
                <xsl:text>100%</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- now sanitize it -->
    <xsl:variable name="normalized-width" select="normalize-space($raw-width)" />
    <xsl:choose>
        <xsl:when test="not(substring($normalized-width, string-length($normalized-width)) = '%')">
            <xsl:message>PTX:ERROR:   a "width" attribute should be given as a percentage (such as "40%", not as "<xsl:value-of select="$normalized-width" />, using 100% instead"</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
            <!-- replace by 100% -->
            <xsl:text>100%</xsl:text>
        </xsl:when>
        <!-- test for stray interior spaces here? -->
        <xsl:otherwise>
            <xsl:value-of select="$normalized-width" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Any way that an image gets placed in a sidebyside -->
<!-- panel it should have a relative size filling that -->
<!-- panel, so this is easy, just 100% all the time    -->
<!-- Exception: asymptote WebGL needs actual pixels    -->
<xsl:template match="image[ancestor::sidebyside]" mode="get-width-percentage">
    <xsl:text>100%</xsl:text>
</xsl:template>

<!-- The exception is an image inside a sidebyside in a webwork  -->
<!-- where the parent sidebyside should only have a single percentage in its @widths -->
<!-- N.B. This should be reworked/removed when there is a one-item sbs equivalent -->
<xsl:template match="webwork//image[parent::sidebyside/@widths]" mode="get-width-percentage">
    <xsl:value-of select="parent::sidebyside/@widths" />
</xsl:template>

<!-- We need to get the right entry from the sidebyside layout.         -->
<!-- This is complicated slightly by two possibilities for the element  -->
<!-- of the sidebyside, a naked object, or a figure holding the object  -->
<!-- Widths from sidebyside layouts have been error-checked as input    -->

<!-- occurs in a figure, not contained in a sidebyside -->
<xsl:template match="audio[ancestor::sidebyside]|video[ancestor::sidebyside]|jsxgraph[ancestor::sidebyside]|interactive[ancestor::sidebyside]|slate[ancestor::sidebyside]|image[asymptote and ancestor::sidebyside]|image[sageplot and ancestor::sidebyside]" mode="get-width-percentage">
    <!-- in a side-by-side, get layout, locate in layout -->
    <!-- and get width.  The layout-parameters template  -->
    <!-- will analyze an enclosing sbsgroup              -->
    <xsl:variable name="enclosing-sbs" select="ancestor::sidebyside" />
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="$enclosing-sbs" mode="layout-parameters" />
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
    <xsl:choose>
        <xsl:when test="parent::figure or parent::stack">
            <xsl:variable name="panel-number" select="count(parent::*/preceding-sibling::*) + 1" />
            <xsl:value-of select="$layout/width[$panel-number]" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="panel-number" select="count(preceding-sibling::*) + 1" />
            <xsl:value-of select="$layout/width[$panel-number]" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Assumes element may have an @aspect attribute   -->
<!-- Caller can provide a default for its context    -->
<!-- Input:  "width:height", or decimal width/height -->
<!-- Return: real number as fraction width/height    -->
<!-- Totally blank means nothing could be determined -->
<xsl:template match="slate|interactive|jsxgraph|audio|video|image[asymptote]|image[sageplot]" mode="get-aspect-ratio">
    <xsl:param name="default-aspect" select="''" />

    <!-- look to element first, then to supplied default          -->
    <!-- this could be empty (default default), then return empty -->
    <xsl:variable name="the-aspect">
        <xsl:choose>
            <!-- The aspect ratio is a property of an       -->
            <!-- interactive Asymptote WebGL version, only. -->
            <xsl:when test="self::image and asymptote/@aspect">
                <xsl:value-of select="asymptote/@aspect" />
            </xsl:when>
            <xsl:when test="self::image and sageplot/@aspect">
                <xsl:value-of select="sageplot/@aspect" />
            </xsl:when>
            <xsl:when test="not(self::image) and @aspect">
                <xsl:value-of select="@aspect" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$default-aspect" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <!-- nothing provided by element or caller -->
        <xsl:when test="$the-aspect = ''" />
        <!-- test if a ratio is given, and assume parts are good -->
        <xsl:when test="contains($the-aspect, ':')">
            <xsl:variable name="width" select="substring-before($the-aspect, ':')" />
            <xsl:variable name="height" select="substring-after($the-aspect, ':')" />
            <xsl:value-of select="$width div $height" />
        </xsl:when>
        <!-- assume a number and see if it is bad, return nothing -->
        <!-- NaN does not equal *anything*, so tests if a number  -->
        <!-- http://stackoverflow.com/questions/6895870           -->
        <xsl:when test="not(number($the-aspect) = number($the-aspect)) or ($the-aspect &lt; 0)">
            <xsl:message>PTX:WARNING: the @aspect attribute should be a ratio, like 4:3, or a positive number, not "<xsl:value-of select="$the-aspect" />"</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
        <!-- survives as a number -->
        <xsl:otherwise>
            <xsl:value-of select="$the-aspect" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- This is cribbed from the CSS "max-width"-->
<!-- Design width, measured in pixels        -->
<!-- NB: the exact same value, for similar,  -->
<!-- but not identical, reasons is used in   -->
<!-- the formation of WeBWorK problems       -->
<xsl:variable name="design-width-pixels" select="'600'" />


<!-- Pixels are an HTML thing, but we may need these numbers -->
<!-- elsewhere, and these are are pure text templates        -->
<!-- NB 3D "sageplot" needs an "iframe" with pixels for size -->
<xsl:template match="slate|audio|video|interactive|image[asymptote]|image[sageplot]" mode="get-width-pixels">
    <xsl:variable name="width-percent">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:variable name="width-fraction">
        <xsl:value-of select="substring-before($width-percent,'%') div 100" />
    </xsl:variable>
    <xsl:value-of select="round($design-width-pixels * $width-fraction)" />
</xsl:template>

<!-- Square by default, when asked.  Can override -->
<xsl:template match="slate|audio|video|interactive|image[asymptote]|image[sageplot]" mode="get-height-pixels">
    <xsl:param name="default-aspect" select="'1:1'" />

    <xsl:variable name="width-percent">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:variable name="width-fraction">
        <xsl:value-of select="substring-before($width-percent,'%') div 100" />
    </xsl:variable>
    <xsl:variable name="aspect-ratio">
        <xsl:apply-templates select="." mode="get-aspect-ratio">
            <xsl:with-param name="default-aspect" select="$default-aspect" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:value-of select="round($design-width-pixels * $width-fraction div $aspect-ratio)" />
</xsl:template>


<!-- ################ -->
<!-- Names of Objects -->
<!-- ################ -->

<!-- The  xsl/localizations/localizations.xml  file contains the base -->
<!-- filenames for the individual (per-language) files.  We form a    -->
<!-- node-set of these filenames in the  $locale-files  variable.     -->
<!-- Then the  document()  function will read multiple files and      -->
<!-- form one grand node-set with all of the translations for         -->
<!-- all languages.  The  xi:include  device is possible within the   -->
<!-- localizations  directory, but would require activating that      -->
<!-- feature (e.g.  xsltproc -xinclude) for even the simplest         -->
<!-- (non-modular) documents.  Better to accomplish the consolidation -->
<!-- with standard XSLT.                                              -->
<!-- NB: the $localizations variable has multiple root nodes, so when -->
<!-- used in a context-switch before looking up a key, the "for-each" -->
<!-- is actually looping over multiple root nodes.  So when we switch -->
<!-- context with a "for-each" we restrict to the root node for the   -->
<!-- specific language in play.                                       -->
<xsl:variable name="locale-files" select="document('localizations/localizations.xml')/localizations/filename" />
<xsl:variable name="localizations" select="document($locale-files)" />
<!-- Key to lookup a particular localization -->
<xsl:key name="localization-key" match="localization" use="@string-id"/>

<!-- Ultimately translations are all contained in the files of  -->
<!-- the xsl/localizations directory, which provides            -->
<!-- upper-case, singular versions.  In this way, we only ever  -->
<!-- hardcode a string (like "Chapter") once                    -->
<!-- Template is intentionally modal.                           -->
<xsl:template match="*" mode="type-name">
    <xsl:param name="string-id" select="''"/>
    <!-- The $string-id parameter allows for an override on        -->
    <!-- semi-automatic determination of the object being named    -->
    <!-- (see the modal "string-id" templates).  This is necessary -->
    <!-- for items like the names of interface buttons that are    -->
    <!-- not associated closely with a certain PreTeXt element.    -->
    <xsl:variable name="str-id">
        <xsl:choose>
            <xsl:when test="not($string-id = '')">
                <xsl:value-of select="$string-id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="string-id"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Look up the tree for the "closest" indication of a language  -->
    <!-- for localization. The  @locale-lang  attribute is set by the -->
    <!-- -assembly  stylesheet, and guarantees the language is        -->
    <!-- supported by an extant localization file.                    -->
    <!--                                                              -->
    <!-- Tip: To get the "document-language" as the in-force          -->
    <!-- language, *only* for the case of setting a string-id         -->
    <!-- override, set the context to $root in the employing @select, -->
    <!-- then $lang-element *will* be $root and $lang *will* be the   -->
    <!-- overall, document-wide, language (set by -assembly).         -->
    <xsl:variable name="lang-element" select="ancestor-or-self::*[@locale-lang][1]"/>
    <xsl:variable name="lang">
        <xsl:value-of select="$lang-element/@locale-lang"/>
    </xsl:variable>

    <!-- Now, build the actual translation via a lookup -->
    <xsl:variable name="lookup">
        <xsl:choose>
            <!-- First, look in docinfo for document-specific rename with correct language -->
            <xsl:when test="$docinfo/rename[@element=$str-id and @xml:lang=$lang]">
                <xsl:apply-templates select="$docinfo/rename[@element=$str-id and @xml:lang=$lang]"/>
            </xsl:when>
            <!-- Second, look in docinfo for document-specific rename with correct language, -->
            <!-- but with @lang attribute which was deprecated on 2019-02-23                 -->
            <xsl:when test="$docinfo/rename[@element=$str-id and @lang=$lang]">
                <xsl:apply-templates select="$docinfo/rename[@element=$str-id and @lang=$lang]"/>
            </xsl:when>
            <!-- Third, look in docinfo for document-specific rename, but now explicitly language-agnostic -->
            <xsl:when test="$docinfo/rename[@element=$str-id and not(@lang) and not(@xml:lang)]">
                <xsl:apply-templates select="$docinfo/rename[@element=$str-id and not(@lang) and not(@xml:lang)]"/>
            </xsl:when>
            <!-- Finally, default to a lookup from the localization file's nodes -->
            <!-- Use a "for-each" to effect a context switch for the look-up and -->
            <!-- restrict the context to the language in play.                   -->
            <xsl:otherwise>
                <xsl:for-each select="$localizations/locale[@language = $lang]">
                    <xsl:value-of select="key('localization-key', $str-id)"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Exceptions to failed lookups                     -->
    <!-- Some un-implemented translations are ubiquitous, -->
    <!-- so we recognize failure and fallback to English  -->
    <xsl:variable name="translation">
        <xsl:choose>
            <!-- $lookup is good, echo it -->
            <xsl:when test="not($lookup = '')">
                <xsl:value-of select="$lookup"/>
            </xsl:when>
            <!-- substitute English since $lookup is empty     -->
            <!-- NB: could test with an "or" for multiple      -->
            <!-- exceptions and then get en-US version with a  -->
            <!-- proper lookup as a single statement, but not  -->
            <!-- bothering yet.                                -->
            <!-- "Close" is on every knowl, too many warnings  -->
            <xsl:when test="$str-id = 'close'">
                <xsl:text>Close</xsl:text>
            </xsl:when>
            <!-- "Reveal" is on every knowl, too many warnings -->
            <xsl:when test="$str-id = 'reveal'">
                <xsl:text>Reveal</xsl:text>
            </xsl:when>
            <!-- $lookup empty and not exceptional    -->
            <!-- echo the empty lookup as translation -->
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$translation != ''">
            <xsl:value-of select="$translation" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[</xsl:text>
            <xsl:value-of select="$str-id" />
            <xsl:text>]</xsl:text>
            <xsl:message>PTX:WARNING: could not translate string with id "<xsl:value-of select="$str-id"/>" into language for code "<xsl:value-of select="$lang"/>"</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- In the assembly pass, we sometimes need to postpone localization, -->
<!-- since we have not analyzed languages and we maybe don't have the  -->
<!-- $docinfo element needed for renaming.  So we emit a placeholder,  -->
<!-- in a "pi:localize" element with the "string-id" as an attribute.  -->
<!-- Now, as part of a conversion, the substitution can be made.       -->
<xsl:template match="pi:localize">
    <xsl:apply-templates select="." mode="type-name">
        <xsl:with-param name="string-id" select="@string-id"/>
    </xsl:apply-templates>
</xsl:template>

<!-- Most PreTeXt elements have names, and their localizations, indexed   -->
<!-- by a "string-id" that is simply their local name.  However, others   -->
<!-- ("exercise" is archetypical) have names that vary according to their -->
<!-- context.  The following templates just report these "string-id",     -->
<!-- defaulting to the "local name".  See the "en-US" localization file   -->
<!-- for the best documentation of these non-standard string-id.          -->

<!-- A single objective or outcome is authored as a list item -->
<xsl:template match="objectives/ol/li|objectives/ul/li|objectives/dl/li" mode="string-id">
    <xsl:text>objective</xsl:text>
</xsl:template>
<xsl:template match="outcomes/ol/li|outcomes/ul/li|outcomes/dl/li" mode="string-id">
    <xsl:text>outcome</xsl:text>
</xsl:template>

<!-- There are lots of exercises, but differentiated by their parents,  -->
<!-- so we use identifiers that remind us of their location in the tree -->

<!-- First, a "divisional" "exercise" in an "exercises",      -->
<!-- with perhaps intervening groups, like an "exercisegroup" -->
<xsl:template match="exercises//exercise" mode="string-id">
    <xsl:text>divisionalexercise</xsl:text>
</xsl:template>

<!-- Second, an "exercise" placed within a "worksheet"-->
<xsl:template match="worksheet//exercise" mode="string-id">
    <xsl:text>worksheetexercise</xsl:text>
</xsl:template>

<!-- Third, an "exercise" placed within a "reading-questions"-->
<xsl:template match="reading-questions//exercise" mode="string-id">
    <xsl:text>readingquestion</xsl:text>
</xsl:template>

<!-- Finally, an inline exercise has a division (several possible)        -->
<!-- as a parent. We just drop in here last if other matches do not       -->
<!-- succeed, but could improve with a filter or list of specific matches -->
<!-- This matches the LaTeX environment of the same name, so              -->
<!-- template to create an "inlineexercise" environment runs smoothly     -->
<xsl:template match="exercise" mode="string-id">
    <xsl:text>inlineexercise</xsl:text>
</xsl:template>

<!-- "solutions" divisions are "Solutions 5.6" in the  -->
<!-- main matter, but "Appendix D" in the back matter -->
<xsl:template match="solutions" mode="string-id">
    <xsl:choose>
        <xsl:when test="parent::backmatter">
            <xsl:text>appendix</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>solutions</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Display Mathematics can be a single line or multiple      -->
<!-- lines and the two do not always align with element names, -->
<!-- so we use two strings to signal the two situations.       -->

<xsl:template match="mrow|md[@pi:authored-one-line]" mode="string-id">
    <xsl:text>equation</xsl:text>
</xsl:template>

<xsl:template match="md[not(@pi:authored-one-line)]" mode="string-id">
    <xsl:text>displaymath</xsl:text>
</xsl:template>

<!-- And with no better match, the default is  -->
<!-- the PreTeXt name for the element itself. -->
<xsl:template match="*" mode="string-id">
    <xsl:value-of select="local-name(.)"/>
</xsl:template>

<!-- ################## -->
<!-- Language direction -->
<!-- ################## -->

<!-- Every localiztion should specify the direction of the  -->
<!-- language, which we record as a variable and as a flag. -->
<xsl:variable name="document-language-direction">
    <xsl:value-of select="$localizations/locale[@language = $document-language]/@direction"/>
</xsl:variable>

<!-- We consider right-to-left as exceptional, so we set a flag   -->
<!-- for this case.  This should be the primary determinant in    -->
<!-- code such as the LaTeX coionversion, though the actual value -->
<!-- of "$language-direction" is meant to be used in attributes   -->
<!-- for HTML pages.                                              -->
<xsl:variable name="b-rtl" select="$document-language-direction = 'rtl'"/>

<!-- ##### -->
<!-- Icons -->
<!-- ##### -->

<!-- Information about icons -->
<!--     @name: PreTeXt name, what authors know/use              -->
<!--     @font-awesome-family: Font Awesome family,              -->
<!--                           "classic" or "brands"             -->
<!--     @font-awesome: the font-awesome name, which becomes     -->
<!--                    CamelCase for use with the LaTeX package -->
<!--     @unicode: for use in less-capable formats               -->
<!--                                                             -->
<xsl:variable name="icon-rtf">
    <!-- see Unicode Character 'LEFTWARDS HEAVY ARROW' (U+1F844) -->
    <!-- for bulkier arrows (in "Supplemental Arrows-C Block")   -->
    <iconinfo name="arrow-left"
              font-awesome-family="classic"
              font-awesome="arrow-left"
              unicode="&#x2190;"/> <!-- LEFTWARDS ARROW -->
    <iconinfo name="arrow-up"
              font-awesome-family="classic"
              font-awesome="arrow-up"
              unicode="&#x2191;"/> <!-- UPWARDS ARROW -->
    <iconinfo name="arrow-right"
              font-awesome-family="classic"
              font-awesome="arrow-right"
              unicode="&#x2192;"/> <!-- RIGHTWARDS ARROW -->
    <iconinfo name="arrow-down"
              font-awesome-family="classic"
              font-awesome="arrow-down"
              unicode="&#x2193;"/> <!-- DOWNWARDS ARROW -->
    <iconinfo name="file-save"
              font-awesome-family="classic"
              font-awesome="save"
              unicode="&#x1f4be;"/> <!-- FLOPPY DISK -->
    <iconinfo name="gear"
              font-awesome-family="classic"
              font-awesome="cog"
              unicode="&#x2699;" /> <!-- GEAR -->
    <iconinfo name="menu"
              font-awesome-family="classic"
              font-awesome="bars"
              unicode="&#x2630;" /> <!-- TRIGRAM FOR HEAVEN -->
    <iconinfo name="wrench"
              font-awesome-family="classic"
              font-awesome="wrench"
              unicode="&#x1f527;"/> <!-- WRENCH -->
    <iconinfo name="power"
              font-awesome-family="classic"
              font-awesome="power-off"
              unicode="&#x23FB;"/> <!-- POWER SYMBOL -->
    <iconinfo name="media-play"
              font-awesome-family="classic"
              font-awesome="play"
              unicode="&#x25B6;"/> <!--BLACK RIGHT-POINTING TRIANGLE-->
    <iconinfo name="media-pause"
              font-awesome-family="classic"
              font-awesome="pause"
              unicode="&#x23F8;"/> <!-- DOUBLE VERTICAL BAR -->
    <iconinfo name="media-stop"
              font-awesome-family="classic"
              font-awesome="stop"
              unicode="&#x23F9;"/> <!-- BLACK SQUARE FOR STOP-->
    <iconinfo name="media-fast-forward"
              font-awesome-family="classic"
              font-awesome="forward"
              unicode="&#x23E9;"/> <!-- BLACK RIGHT-POINTING DOUBLE TRIANGLE -->
    <iconinfo name="media-rewind"
              font-awesome-family="classic"
              font-awesome="backward"
              unicode="&#x23EA;"/> <!-- BLACK LEFT-POINTING DOUBLE TRIANGLE -->
    <iconinfo name="media-skip-to-end"
              font-awesome-family="classic"
              font-awesome="fast-forward"
              unicode="&#x23ED;"/> <!-- BLACK RIGHT-POINTING DOUBLE TRIANGLE WITH VERTICAL BAR -->
    <iconinfo name="media-skip-to-start"
              font-awesome-family="classic"
              font-awesome="fast-backward"
              unicode="&#x23EE;"/> <!-- BLACK LEFT-POINTING DOUBLE TRIANGLE WITH VERTICAL BAR -->
    <!-- Creative Commons, Font Awesome Brands family -->
    <!-- https://creativecommons.org/2020/03/18/the-unicode-standard-now-includes-cc-license-symbols/ -->
    <iconinfo name="cc"
              font-awesome-family="brands"
              font-awesome="creative-commons"
              unicode="&#x1F16D;"/> <!-- CIRCLED CC -->
    <iconinfo name="cc-by"
              font-awesome-family="brands"
              font-awesome="creative-commons-by"
              unicode="&#x1F16F;"/> <!-- CIRCLED HUMAN FIGURE -->
    <iconinfo name="cc-sa"
              font-awesome-family="brands"
              font-awesome="creative-commons-sa"
              unicode="&#x1F10E;"/> <!-- CIRCLED ANTICLOCKWISE ARROW -->
    <iconinfo name="cc-nc"
              font-awesome-family="brands"
              font-awesome="creative-commons-nc"
              unicode="&#x1F10F;"/> <!-- CIRCLED DOLLAR SIGN WITH OVERLAID BACKSLASH -->
    <iconinfo name="cc-pd"
              font-awesome-family="brands"
              font-awesome="creative-commons-pd"
              unicode="&#x1F16E;"/> <!-- CIRCLED C WITH OVERLAID BACKSLASH -->
    <iconinfo name="cc-zero"
              font-awesome-family="brands"
              font-awesome="creative-commons-zero"
              unicode="&#x1F16D;"/> <!-- CIRCLED ZERO WITH BACKSLASH -->
</xsl:variable>

<!-- If read from a file via "document()" then   -->
<!-- the exsl:node-set() call would seem to be   -->
<!-- unnecessary.  When list above gets too big, -->
<!-- migrate to a new file after consulting      -->
<!-- localization scheme                         -->
<xsl:variable name="icon-table" select="exsl:node-set($icon-rtf)"/>

<xsl:key name="icon-key" match="iconinfo" use="@name"/>

<!-- ##### -->
<!-- Icons -->
<!-- ##### -->

<xsl:template match="icon">
    <!-- the name attribute of the "icon" in text as a string -->
    <xsl:variable name="icon-name">
        <xsl:value-of select="@name"/>
    </xsl:variable>

    <!-- for-each is just one node, but sets context for key() -->
    <xsl:for-each select="$icon-table">
        <xsl:value-of select="key('icon-key', $icon-name)/@unicode" />
    </xsl:for-each>
</xsl:template>

<!-- ############# -->
<!-- Keyboard Keys -->
<!-- ############# -->

<!-- Comments are Unicode names, from fileformat.info             -->
<!-- @latex values are macros in the menukeys package specifying  -->
<!-- keyboard keys that are typically labeled with graphics,      -->
<!-- or "textcomp Text-mode Math Symbols" from "The Comprehensive -->
<!-- LaTeX Symbol List", or constructions combining them          -->
<xsl:variable name="kbdkey-rtf">
    <kbdkeyinfo name="left"
                latex="\arrowkeyleft"
                unicode="&#x2190;"/> <!-- LEFTWARDS ARROW -->
    <kbdkeyinfo name="up"
                latex="\arrowkeyup"
                unicode="&#x2191;"/> <!-- UPWARDS ARROW -->
    <kbdkeyinfo name="right"
                latex="\arrowkeyright"
                unicode="&#x2192;"/> <!-- RIGHTWARDS ARROW -->
    <kbdkeyinfo name="down"
                latex="\arrowkeydown"
                unicode="&#x2193;"/> <!-- DOWNWARDS ARROW -->
    <kbdkeyinfo name="enter"
                latex="\return"
                unicode="&#x2BA0;"/> <!-- DOWNWARDS TRIANGLE-HEADED ARROW WITH LONG TIP LEFTWARDS -->
    <kbdkeyinfo name="shift"
                latex="\shift"
                unicode="&#x21E7;"/> <!-- UPWARDS WHITE ARROW -->
    <kbdkeyinfo name="ampersand"
                latex="\&amp;"
                unicode="&#x0026;"/> <!-- AMPERSAND -->
    <kbdkeyinfo name="less"
                latex='\textless'
                unicode="&#x003C;"/> <!-- LESS-THAN SIGN-->
    <kbdkeyinfo name="greater"
                latex='\textgreater'
                unicode="&#x003E;"/> <!-- GREATER-THAN SIGN-->
    <kbdkeyinfo name="dollar"
                latex='\$'
                unicode="&#x0024;"/> <!-- DOLLAR SIGN -->
    <kbdkeyinfo name="percent"
                latex='\%'
                unicode="&#x0025;"/> <!-- PERCENT SIGN -->
    <!-- pair of braces is not confused as AVT notation -->
    <kbdkeyinfo name="openbrace"
                latex='\textbraceleft'
                unicode="{{"/> <!-- LEFT CURLY BRACKET -->
    <kbdkeyinfo name="closebrace"
                latex='\textbraceright'
                unicode="}}"/> <!-- RIGHT CURLY BRACKET -->
    <kbdkeyinfo name="hash"
                latex='\#'
                unicode="&#x0023;"/> <!-- OCTOTHORPE -->
    <kbdkeyinfo name="backslash"
                latex='\textbackslash'
                unicode="&#x005C;"/> <!-- BACKSLASH -->
    <kbdkeyinfo name="tilde"
                latex='\textasciitilde'
                unicode="&#x007E;"/> <!-- TILDE -->
    <kbdkeyinfo name="circumflex"
                latex='\textasciicircum'
                unicode="&#x005E;"/> <!-- CIRCUMFLEX ACCENT -->
    <kbdkeyinfo name="underscore"
                latex='\textunderscore'
                unicode="&#x005F;"/> <!-- LOW LINE -->
    <kbdkeyinfo name="plus"
                latex='+'
                unicode="&#x002B;"/> <!-- PLUS SIGN -->
    <!-- MINUS SIGN is U+2212, but not in all fonts? -->
    <kbdkeyinfo name="minus"
                latex='\textminus'
                unicode="&#x002D;"/> <!-- HYPHEN-MINUS -->
    <kbdkeyinfo name="times"
                latex='\texttimes'
                unicode="&#x00D7;"/> <!-- MULTIPLICATION SIGN -->
    <kbdkeyinfo name="solidus"
                latex='\textfractionsolidus'
                unicode="&#x002F;"/> <!-- SOLIDUS -->
    <kbdkeyinfo name="obelus"
                latex='\textdiv'
                unicode="&#x00F7;"/> <!-- DIVISION SIGN -->
    <kbdkeyinfo name="squared"
                latex='x\textasciicircum{}2'
                unicode="x&#x005E;2"/> <!--  -->
    <kbdkeyinfo name="inverse"
                latex='x\textasciicircum{-1}'
                unicode="x&#x005E;-1"/> <!--  -->
    <kbdkeyinfo name="left-paren"
                latex='('
                unicode="&#x0028;"/> <!-- LEFT PARENTHESIS -->
    <kbdkeyinfo name="right-paren"
                latex=')'
                unicode="&#x0029;"/> <!-- RIGHT PARENTHESIS -->
</xsl:variable>

<!-- If read from a file via "document()" then   -->
<!-- the exsl:node-set() call would seem to be   -->
<!-- unnecessary.  When list above gets too big, -->
<!-- migrate to a new file after consulting      -->
<!-- localization scheme                         -->
<xsl:variable name="kbdkey-table" select="exsl:node-set($kbdkey-rtf)"/>

<xsl:key name="kbdkey-key" match="kbdkeyinfo" use="@name"/>

<!-- ###################### -->
<!-- Identifiers and Labels -->
<!-- ###################### -->

<!-- Identifiers are in flux, as of 2023-03-30.  The "unique-id" is    -->
<!-- an attribute built during the descent of the tree during the      -->
<!-- pre-processor/assembly phase.  As such, it is fast and ugly.      -->
<!-- Do not let a reader catch sight of it in output ever, beacuase it -->
<!-- is ugly, and because it is not really permanant.  That is what    -->
<!-- "visible-id" is for.  But constructing "visible-id" is very slow  -->
<!-- (we hope to speed htat up as well).  So we are transitioning to   -->
<!-- the "unique-id" wherever possible, but with careful testing.      -->
<xsl:template match="*" mode="unique-id">
    <xsl:value-of select="@unique-id"/>
</xsl:template>

<!-- These strings are used for items an author must manage              -->
<!-- (image files) or that a reader will interact with (shared URLs)     -->
<!-- Since items like filenames and URLs are sometimes shared across     -->
<!-- conversions (or extractions) this template is in -common            -->
<xsl:template match="*" mode="visible-id">
    <xsl:value-of select="@unique-id"/>
</xsl:template>

<!-- An image described by source code, using languages Asymptote,     -->
<!-- Sage, or LaTeX, should have its filename determined by properties -->
<!-- of the associated language-specific element, specifically this is -->
<!-- the province of the @label attribute.  So this is the preference  -->
<!-- from approximately 2023-08-12.  Looking to the enclosing (parent) -->
<!-- "image" is historical, preserving backward-compatibility.         -->
<xsl:template match="asymptote|sageplot|mermaid|latex-image" mode="image-source-basename">
    <xsl:choose>
        <!-- 2023-08-12: new behavior, prefer a @label (not @xml:id) -->
        <!-- on the source code element to provide the filename      -->
        <xsl:when test="@label">
           <xsl:value-of select="@label"/>
        </xsl:when>
        <!-- Next stanza preserves backward-compatibility: previously an       -->
        <!-- @xml:id value was used to form the filename of an image described -->
        <!-- by source code (or a default was provided, like image-37).        -->
        <xsl:when test="parent::image">
            <xsl:apply-templates select="parent::image" mode="visible-id"/>
        </xsl:when>
        <!-- Well-formed PTX source means we never reach the "otherwise" -->
        <xsl:otherwise>
            <xsl:message>PTX:BUG:  parent of a "<xsl:value-of select="local-name()"/>" element in your PreTeXt source is not an "image".  If you think this is a programming error (not an error in your source), please report me.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- PreFigure images debuted after the switch to preferring a @label on -->
<!-- the "prefigure" element, and not on the enclosing image, so we can  -->
<!-- employ an improved version of the "image-source-basename" template. -->
<xsl:template match="pf:prefigure" mode="image-source-basename">
    <xsl:choose>
        <!-- Determine if @label is authored or generated for backwrd compatibility -->
        <xsl:when test="not(@authored-label)">
            <xsl:apply-templates select="." mode="visible-id"/>
            <xsl:message>PTX:WARNING:  you are encouraged to place a @label attribute on every "prefigure" element.  Otherwise, associated image files will have unreliable filenames.</xsl:message>
        </xsl:when>
        <!-- this @label is now guaranteed to be authored -->
        <xsl:when test="@label">
           <xsl:value-of select="@label"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:BUG:  a "prefigure" element is confused about where its @label came from</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- When hosted on Runestone, an interactive exercise is tracked in a    -->
<!-- database across courses ("base course") and semesters ("time").      -->
<!-- And the HTML representation of an interactive exercise, when powered -->
<!-- by Runestone services, needs an HTML id.  But the PreTeXt "exercise" -->
<!-- that wraps it has its own HTML id necessary for targets of           -->
<!-- cross-reference (in-context) URLs.  We will prefer @label for the    -->
<!-- PreTeXt "exercise" HTML id.  And we will require a *stable* @label   -->
<!-- from an author, which we will dress up here.  Notice that this can   -->
<!-- change when an author declares a new edition.                        -->
<xsl:template match="exercise|program|datafile|query|&PROJECT-LIKE;|task|video[@youtube]|exercises|worksheet|interactive[@platform = 'doenetml']|interactive[@iframe]" mode="runestone-id">
    <!-- With no @xml:id and no @label we realize the author has not given    -->
    <!-- any thought to a (semi-)peersistent identifire for the Runestone     -->
    <!-- database.  So we call that out as an error.  And we do not even      -->
    <!-- attempt to fallback to an automatically generated string, which      -->
    <!-- would be malleable over time and editing.                            -->
    <!-- As part of backwards-compatibility, we copy old @xml:id values into  -->
    <!-- fresh @label.  But have an internal  @authored-label attribute whose -->
    <!-- absence alerts us to the copying, which is now not best practice.    -->
    <xsl:choose>
         <!-- 2024-02-20: neuter thse warnings.  Somehow, it seems @authored-label -->
         <!-- is not very reliable.  Were added in commit 29a42dc689cd772a         -->
        <!--  -->
        <xsl:when test="true()"/>
        <!--  -->
        <xsl:when test="$b-host-runestone and not(@xml:id) and not(@authored-label)">
            <xsl:message>
                <xsl:text>PTX:ERROR:  While building for a Runestone server, a PreTeXt "</xsl:text>
                <xsl:value-of select="local-name(.)"/>
                <xsl:text>" element&#xa;</xsl:text>
                <xsl:text>has been encountered without a @label attribute and without a @xml:id attribute.&#xa;</xsl:text>
                <xsl:text>This will cause this Runestone component to fail to perform and there will be no&#xa;</xsl:text>
                <xsl:text>identification of this component in the Runestone database.  You must add a&#xa;</xsl:text>
                <xsl:text>@label attribute with a unique value.  (It is not necessary to add a @xml:id, &#xa;</xsl:text>
                <xsl:text>it is consulted as part of a backward-compatibility arrangement you do not need).&#xa;</xsl:text>
                <xsl:text>[You may get more than one message about this instance.]&#xa;</xsl:text>
            </xsl:message>
            <xsl:apply-templates select="." mode="location-report"/>
        </xsl:when>
        <xsl:when test="$b-host-runestone and not(@authored-label)">
            <xsl:message>
                <xsl:text>PTX:WARNING:  While building for a Runestone server, a PreTeXt "</xsl:text>
                <xsl:value-of select="local-name(.)"/>
                <xsl:text>" element&#xa;</xsl:text>
                <xsl:text>has been encountered without a @label attribute.  For reasons of backward-compatibility &#xa;</xsl:text>
                <xsl:text>we have used the value of an @xml:id.  This may not be what you want, and as of 2024-02-15 &#xa;</xsl:text>
                <xsl:text>is no longer best practice.  You can copy the @xml:id value exactly into a new @label &#xa;</xsl:text>
                <xsl:text>attribute and this warning will stop AND your project's entries in any Runestone database &#xa;</xsl:text>
                <xsl:text>will be preserved and function exactly as before.&#xa;</xsl:text>
                <xsl:text>[You may get more than one message about this instance.]&#xa;</xsl:text>
            </xsl:message>
            <xsl:apply-templates select="." mode="location-report"/>
        </xsl:when>
    </xsl:choose>
    <!-- We require a @label attribute, but allow it to be -->
    <!-- the result of an automatic copy from an @xml:id.  -->
    <xsl:variable name="label">
        <xsl:value-of select="@label"/>
    </xsl:variable>
    <xsl:if test="$label != ''">
        <xsl:call-template name="runestone-label-prefix"/>
        <xsl:value-of select="$label"/>
    </xsl:if>
</xsl:template>

<!-- Special handling for programs in exercise-like elements.              -->
<!-- We want to associate those programs with the label on their container -->
<!-- and NOT with an auto-generated label on the program itself that might -->
<!-- come from an @xml:id.                                                 -->
<!-- This is an implicit use of &PROJECT-LIKE; and should be kept in sync  -->
<xsl:template match="exercise/program|task/program|project/program|activity/program|exploration/program|investigation/program" mode="runestone-id">
    <xsl:variable name="label">
        <xsl:value-of select="../@label"/>
    </xsl:variable>
    <xsl:if test="$label != ''">
        <xsl:call-template name="runestone-label-prefix"/>
        <xsl:value-of select="$label"/>
    </xsl:if>
</xsl:template>

<!-- Prefix just for RS-server builds, in order that the database -->
<!-- of exercises gets a globally unique identifier.              -->
<!-- And for a non-RS-server build, we add a prefix in order to   -->
<!-- differentiate from nearby (wrappers) uses of @label for      -->
<!-- PreTeXt functions.                                           -->
<xsl:template name="runestone-label-prefix">
    <xsl:choose>
        <xsl:when test="$b-host-runestone">
            <!-- global variables defined in this stylesheet -->
            <xsl:value-of select="$document-id"/>
            <xsl:text>_</xsl:text>
            <xsl:value-of select="$edition"/>
            <xsl:text>_</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>rs-</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Need a unique filename for codelens traces                                -->
<!-- visible-id can change if an xml:id is added to program for other reasons  -->
<!-- Can't vary with build target (so no runestone-id)                         -->
<!-- Should generally mirror rs-id but without prefix                          -->
<xsl:template match="program[@interactive = 'codelens']" mode="runestone-codelens-trace-filename">
    <xsl:choose>
        <!-- If part of exercise-like, use that label, otherwise own                -->
        <!-- This is an implicit use of &PROJECT-LIKE; and should be kept in sync   -->
        <xsl:when test="parent::exercise|parent::task|parent::project|parent::activity|parent::exploration|parent::investigation">
            <xsl:value-of select="../@unique-id"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="@unique-id"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>.js</xsl:text>
</xsl:template>

<!--            -->
<!-- Long Names -->
<!--            -->

<!-- Simple text representations of structural elements        -->
<!-- Type, number (empty?), optional title typically           -->
<!-- Ignore footnotes in these constructions                   -->
<!-- Used for author's report, LaTeX typeout during processing -->
<xsl:template match="*" mode="long-name">
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="title-simple"/>
</xsl:template>


<!-- ######### -->
<!-- Numbering -->
<!-- ######### -->

<!-- We mimic default LaTeX behavior as much as possible    -->
<!--                                                        -->
<!-- There are six numbering schemes in place:              -->
<!-- 1) divisions: sections, subsections, etc.              -->
<!-- 2) environments: theorems, examples, exercises, figures -->
<!-- 3) equations: display mathematics                      -->
<!-- 4) exercises: as part of a section of exercises        -->
<!-- 5) bibliographic items: in multiple sections           -->
<!-- 6) footnotes:                                          -->

<!-- Every such item has two numbers                   -->
<!--                                                   -->
<!-- a) "structural": for example, X.Y.Z for an item   -->
<!--     in Chapter X, Section Y, Subsection Z         -->
<!-- b) "serial": for example N, where the item is     -->
<!--     number N of its scheme, within some division  -->
<!--                                                   -->
<!-- We form a "full number" by concatenating these,   -->
<!-- so "Claim X.Y.Z.N" would be the N-th instance of  -->
<!-- a scheme 2 item with division X.Y.Z. An empty     -->
<!-- serial number is indicative of not being numbered -->
<!--                                                   -->
<!-- Parameters of the form "numbering.<scheme>.level" -->
<!-- control the number of components in these numbers -->

<!-- ############## -->
<!-- Serial Numbers -->
<!-- ############## -->

<!-- Serial Numbers: Divisions -->
<!-- To respect the maximum level for numbering, we          -->
<!-- return an empty serial number at an excessive level,    -->
<!-- otherwise we call for a serial number relative to peers -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|backmatter/solutions" mode="serial-number">
    <xsl:variable name="relative-level">
        <xsl:apply-templates select="." mode="new-level" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$relative-level > $numbering-maxlevel" />
        <xsl:otherwise>
            <xsl:value-of select="@serial"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Specialized Divisions -->
<xsl:template match="exercises|solutions|worksheet|handout|reading-questions|references|glossary" mode="serial-number">
    <xsl:variable name="is-numbered">
        <xsl:apply-templates select="." mode="is-specialized-own-number"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$is-numbered = 'true'">
            <xsl:variable name="relative-level">
                <xsl:apply-templates select="." mode="new-level" />
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$relative-level > $numbering-maxlevel" />
                <xsl:otherwise>
                    <xsl:value-of select="@serial"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="serial-number" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Backmatter references and glossary are unique and un-numbered, -->
<!-- so an empty serial number.  These matches supersede the above. -->
<xsl:template match="backmatter/references" mode="serial-number" />
<xsl:template match="backmatter/glossary" mode="serial-number" />

<!-- Serial Numbers: Theorems, Examples, Inline Exercise, Figures, Etc. -->
<!-- We determine the appropriate subtree to count within     -->
<!-- given the document root and the configured depth         -->
<!-- Note: the "from" attribute can only take a match pattern -->
<!-- See: the footnote template below for a simpler example   -->

<!-- First, if we are at the maximum numbering level,                            -->
<!-- or less, for a particular scheme then we always base the                    -->
<!-- subtree at the most immediate enclosing structural element                  -->
<!-- If we are at a greater level than the maximum numbering level,              -->
<!-- then we base the subtree at the enclosing structural                        -->
<!-- element that is at the maximum level                                        -->
<!-- This template returns the absolute level necessary based on                 -->
<!-- the particular scheme as a parameter: theorems, equations and footnotes.    -->
<!-- Divisional exercises and bibliographic items (in references) will always     -->
<!-- get their serial numbers from within their immediately enclosing structure. -->
<xsl:template match="*" mode="absolute-subtree-level">
    <xsl:param name="numbering-items" />
    <!-- determine enclosing level of numbered item -->

    <!-- determine if the object being numbered is inside    -->
    <!-- a decorative "exercises", "worksheet", or "handout" -->
    <xsl:variable name="inside-decorative">
        <xsl:if test="ancestor::*[self::exercises or self::reading-questions or self::worksheet or self::handout]">
            <xsl:variable name="is-numbered">
                <xsl:apply-templates select="ancestor::*[self::exercises or self::worksheet or self::handout or self::reading-questions]" mode="is-specialized-own-number"/>
            </xsl:variable>
            <xsl:if test="not($is-numbered ='true')">
                <xsl:text>true</xsl:text>
            </xsl:if>
        </xsl:if>
    </xsl:variable>

    <xsl:variable name="enclosing-level">
        <xsl:apply-templates select="." mode="enclosing-level" />
    </xsl:variable>
    <!-- we move up a level if the structural element is decorative -->
    <xsl:variable name="raw-element-level">
        <xsl:choose>
            <xsl:when test="$inside-decorative = 'true'">
                <xsl:value-of select="$enclosing-level - 1"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$enclosing-level"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- if we are deep into the tree, beyond resetting counters,           -->
    <!-- then count from a subtree at the numbering level,                  -->
    <!-- else remain within enclosing level, as structure number will reset -->
    <xsl:variable name="raw-subtree-level">
        <xsl:choose>
            <xsl:when test="$raw-element-level > $numbering-items">
                <xsl:value-of select="$numbering-items" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$raw-element-level" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$raw-subtree-level + $root-level" />
</xsl:template>

<!-- "Blocks" can be counted "all together," or some types may be "split out." -->
<!--                                                                           -->
<!-- Definitions, theorems, axioms, remarks, computations,                     -->
<!-- and examples always go together.                                          -->
<!-- Projects, figures, and inline exercises may be split out individually.    -->
<!--                                                                           -->
<!-- For each of these items, we count the predecessors within each of the     -->
<!-- four subgroups.  So every item has four "atomic" numbers.  The "block"    -->
<!-- count may, or may not, contain the three other counts as determined by    -->
<!-- options selected through the "docinfo/numbering" configuration.           -->


<!-- Serial Numbers: Fundamental Blocks (Theorems, Etc.) -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" mode="serial-number">
    <xsl:apply-templates select="." mode="overall-blocks-serial-number" />
</xsl:template>

<!-- Serial Numbers: Projects -->
<xsl:template match="&PROJECT-LIKE;" mode="serial-number">
    <xsl:choose>
        <xsl:when test="$b-number-project-distinct">
            <xsl:apply-templates select="." mode="atomic-project-serial-number" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="overall-blocks-serial-number" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Figures -->
<xsl:template match="&FIGURE-LIKE;" mode="serial-number">
    <xsl:choose>
        <xsl:when test="$b-number-figure-distinct">
            <xsl:apply-templates select="." mode="atomic-figure-serial-number" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="overall-blocks-serial-number" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Inline Exercises -->
<xsl:template match="exercise" mode="serial-number">
    <xsl:choose>
        <xsl:when test="$b-number-exercise-distinct">
            <xsl:apply-templates select="." mode="atomic-exercise-serial-number" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="overall-blocks-serial-number" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- We accumulate counts for any elements     -->
<!-- included in the grand, overall block      -->
<!-- count, while excluding those not included -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&FIGURE-LIKE;|exercise" mode="overall-blocks-serial-number">
    <!-- always count fundamental blocks -->
    <xsl:variable name="atomic-block">
        <xsl:apply-templates select="." mode="atomic-block-serial-number" />
    </xsl:variable>
    <!-- include project count? -->
    <xsl:variable name="atomic-project">
        <xsl:choose>
            <xsl:when test="$b-number-project-distinct">
                <xsl:value-of select="0" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="atomic-project-serial-number" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- include figure count? -->
    <xsl:variable name="atomic-figure">
        <xsl:choose>
            <xsl:when test="$b-number-figure-distinct">
                <xsl:value-of select="0" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="atomic-figure-serial-number" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- include exercise count? -->
    <xsl:variable name="atomic-exercise">
        <xsl:choose>
            <xsl:when test="$b-number-exercise-distinct">
                <xsl:value-of select="0" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="atomic-exercise-serial-number" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Add four groups and report -->
    <xsl:value-of select="$atomic-block + $atomic-project + $atomic-figure + $atomic-exercise" />
</xsl:template>

<!-- Atomic block serial number -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&FIGURE-LIKE;|exercise" mode="atomic-block-serial-number">
    <xsl:variable name="subtree-level">
        <xsl:apply-templates select="." mode="absolute-subtree-level">
            <xsl:with-param name="numbering-items" select="$numbering-blocks" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1">
            <xsl:number from="book|article|letter|memo" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=0">
            <xsl:number from="part" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=1">
            <xsl:number from="chapter|book/backmatter/appendix" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=2">
            <xsl:number from="section|article/backmatter/appendix|chapter/exercises|chapter/worksheet|chapter/handout|chapter/reading-questions" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=3">
            <xsl:number from="subsection|section/exercises|section/worksheet|section/handout|section/reading-questions" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=4">
            <xsl:number from="subsubsection|subsection/exercises|subsection/worksheet|subsection/handout|subsection/reading-questions" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: Subtree level for atomic block number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Atomic project serial number -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&FIGURE-LIKE;|exercise" mode="atomic-project-serial-number">
    <xsl:variable name="subtree-level">
        <xsl:choose>
            <xsl:when test="$b-number-project-distinct">
                <xsl:apply-templates select="." mode="absolute-subtree-level">
                    <xsl:with-param name="numbering-items" select="$numbering-projects" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="absolute-subtree-level">
                    <xsl:with-param name="numbering-items" select="$numbering-blocks" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1">
            <xsl:number from="book|article|letter|memo" level="any" count="&PROJECT-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=0">
            <xsl:number from="part" level="any" count="&PROJECT-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=1">
            <xsl:number from="chapter|book/backmatter/appendix" level="any" count="&PROJECT-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=2">
            <xsl:number from="section|article/backmatter/appendix|chapter/exercises|chapter/worksheet|chapter/handout|chapter/reading-questions" level="any" count="&PROJECT-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=3">
            <xsl:number from="subsection|section/exercises|section/worksheet|section/handout|section/reading-questions" level="any" count="&PROJECT-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=4">
            <xsl:number from="subsubsection|subsection/exercises|subsection/worksheet|subsection/handout|subsection/reading-questions" level="any" count="&PROJECT-LIKE;" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: Subtree level for project number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Atomic figure serial number -->
<!-- Note that since these are captioned items:       -->
<!-- If these live in "sidebyside", which is in       -->
<!-- turn contained in a "figure", then they will     -->
<!-- earn a subnumber (e.g (a), (b),..), so we ignore -->
<!-- them in these counts of top-level numbered items -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&FIGURE-LIKE;|exercise" mode="atomic-figure-serial-number">
    <xsl:variable name="subtree-level">
        <xsl:choose>
            <xsl:when test="$b-number-figure-distinct">
                <xsl:apply-templates select="." mode="absolute-subtree-level">
                    <xsl:with-param name="numbering-items" select="$numbering-figures" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="absolute-subtree-level">
                    <xsl:with-param name="numbering-items" select="$numbering-blocks" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1">
            <xsl:number from="book|article|letter|memo" level="any"
                count="figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                list[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=0">
            <xsl:number from="part" level="any"
                count="figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                list[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=1">
            <xsl:number from="chapter|book/backmatter/appendix" level="any"
                count="figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                list[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=2">
            <xsl:number from="section|article/backmatter/appendix|chapter/exercises|chapter/worksheet|chapter/handout|chapter/reading-questions" level="any"
                count="figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                list[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=3">
            <xsl:number from="subsection|section/exercises|section/worksheet|section/handout|section/reading-questions" level="any"
                count="figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                list[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=4">
            <xsl:number from="subsubsection|subsection/exercises|subsection/worksheet|subsection/handout|subsection/reading-questions" level="any"
                count="figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                list[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: Subtree level for atomic figure number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Atomic inline exercise serial number -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|exercise|&FIGURE-LIKE;" mode="atomic-exercise-serial-number">
    <xsl:variable name="subtree-level">
        <xsl:choose>
            <xsl:when test="$b-number-exercise-distinct">
                <xsl:apply-templates select="." mode="absolute-subtree-level">
                    <xsl:with-param name="numbering-items" select="$numbering-exercises" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="absolute-subtree-level">
                    <xsl:with-param name="numbering-items" select="$numbering-blocks" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1">
            <xsl:number from="book|article|letter|memo" level="any"
                count="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=0">
            <xsl:number from="part" level="any"
                count="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=1">
            <xsl:number from="chapter|book/backmatter/appendix" level="any"
                count="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=2">
            <xsl:number from="section|article/backmatter/appendix|chapter/exercises|chapter/worksheet|chapter/handout" level="any"
                count="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=3">
            <xsl:number from="subsection|section/exercises|section/worksheet|section/handout" level="any"
                count="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=4">
            <xsl:number from="subsubsection|subsection/exercises|subsection/worksheet|subsection/handout" level="any"
                count="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: Subtree level for atomic exercise number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Proofs may be numbered (for cross-reference knowls) -->
<xsl:template match="&PROOF-LIKE;" mode="serial-number">
    <xsl:number count="&PROOF-LIKE;"/>
</xsl:template>


<!-- Serial Numbers: Equations -->
<!-- We determine the appropriate subtree to count within   -->
<!-- given the document root and the configured depth       -->
<!-- Pre-processor supplies @pi:numbered onto every "mrow"  -->
<!-- and every displayed equation is eventually held in an  -->
<!-- "mrow", so counting is straightforward.  Presence of a -->
<!-- local tag (@tag) is considered to be unnumbered.       -->
<xsl:template match="mrow[@pi:numbered = 'yes']" mode="serial-number">
    <xsl:variable name="subtree-level">
        <xsl:apply-templates select="." mode="absolute-subtree-level">
            <xsl:with-param name="numbering-items" select="$numbering-equations" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1">
            <xsl:number from="book|article|letter|memo" level="any" count="mrow[@pi:numbered = 'yes']"/>
        </xsl:when>
        <xsl:when test="$subtree-level=0">
            <xsl:number from="part" level="any" count="mmrow[@pi:numbered = 'yes']"/>
            </xsl:when>
        <xsl:when test="$subtree-level=1">
            <xsl:number from="chapter|book/backmatter/appendix" level="any" count="mrow[@pi:numbered = 'yes']"/>
        </xsl:when>
        <xsl:when test="$subtree-level=2">
            <xsl:number from="section|article/backmatter/appendix|chapter/exercises|chapter/worksheet|chapter/handout|chapter/reading-questions" level="any" count="mrow[@pi:numbered = 'yes']"/>
        </xsl:when>
        <xsl:when test="$subtree-level=3">
            <xsl:number from="subsection|section/exercises|section/worksheet|section/handout|section/reading-questions" level="any" count="mrow[@pi:numbered = 'yes']"/>
        </xsl:when>
        <xsl:when test="$subtree-level=4">
            <xsl:number from="subsubsection|subsection/exercises|subsection/worksheet|subsection/handout|subsection/reading-questions" level="any" count="mrow[@pi:numbered = 'yes']"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: Subtree level for equation number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- An authored bare "md" may carry an @xml:id, and so may be cross-referenced. -->
<!-- We consider its number, as a target of a cross-reference to be that of the  -->
<!-- contained, single "mrow".  This may be an actual number or may be an empty  -->
<!-- string, depending on how the "md" was meant to be numbered.                 -->
<xsl:template match="md[@pi:authored-one-line]" mode="serial-number">
    <xsl:apply-templates select="mrow" mode="serial-number"/>
</xsl:template>

<!-- Serial Numbers: Exercises in Exercises or Worksheet or Reading Question Divisions -->
<!-- Note: numbers may be hard-coded for longevity        -->
<!-- exercisegroups  and future lightweight divisions may -->
<!-- be intermediate, but should not hinder the count     -->
<!-- NB: there are three historical "apply-templates"     -->
<!-- here which might now be written as "value-of",       -->
<!-- but perhaps it is irrelevant                         -->
<xsl:template match="exercises//exercise" mode="serial-number">
    <xsl:number from="exercises" level="any" count="exercise" />
</xsl:template>

<xsl:template match="exercises//exercise[@number]" mode="serial-number">
    <xsl:apply-templates select="@number" />
</xsl:template>

<xsl:template match="worksheet//exercise" mode="serial-number">
    <xsl:number from="worksheet" level="any" count="exercise" />
</xsl:template>

<xsl:template match="worksheet//exercise[@number]" mode="serial-number">
    <xsl:apply-templates select="@number" />
</xsl:template>

<xsl:template match="reading-questions//exercise" mode="serial-number">
    <xsl:number from="reading-questions" level="any" count="exercise" />
</xsl:template>

<xsl:template match="reading-questions//exercise[@number]" mode="serial-number">
    <xsl:apply-templates select="@number" />
</xsl:template>

<!-- Serial Numbers: Solutions -->
<!-- Hints, answers, solutions may be numbered (for cross-reference knowls) -->
<xsl:template match="&SOLUTION-LIKE;" mode="serial-number">
    <xsl:number />
</xsl:template>

<!-- Serial Numbers: Bibliographic Items -->
<!-- Always sequential within a References section -->
<xsl:template match="biblio" mode="serial-number">
    <xsl:number from="references" level="any" count="biblio" />
</xsl:template>
<!-- Notes may be numbered (for cross-reference knowls) -->
<xsl:template match="biblio/note" mode="serial-number">
    <xsl:number />
</xsl:template>

<!-- Hints, answers, solutions, notes are often singletons.     -->
<!-- This utility returns the serial number, or if a singleton, -->
<!-- returns an empty string.  Employing templates will need    -->
<!-- to check if they want to react accordingly, or they should -->
<!-- just ask for the serial number itself if they don't care.  -->
<xsl:template match="&SOLUTION-LIKE;|biblio/note" mode="non-singleton-number">
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="serial-number" />
    </xsl:variable>
    <xsl:choose>
        <!-- non-singletons always of interest/use -->
        <xsl:when test="not($the-number = 1)">
            <xsl:value-of select="$the-number" />
        </xsl:when>
        <!-- now being careful with "1" -->
        <xsl:otherwise>
            <xsl:variable name="elt-name" select="local-name(.)" />
            <!-- We go to the parent, get all like children, then     -->
            <!-- filter by name, since hints and answers, etc all mix -->
            <xsl:variable name="siblings-and-self" select="parent::*/*[local-name(.) = $elt-name]" />
            <!-- maybe "1" is interesting too -->
            <!-- if not, no result whatsoever -->
            <xsl:if test="count($siblings-and-self) > 1">
                <xsl:value-of select="$the-number" />
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Footnotes -->
<!-- We determine the appropriate subtree to count within -->
<!-- given the document root and the configured depth     -->
<xsl:template match="fn" mode="serial-number">
    <xsl:variable name="subtree-level">
        <xsl:apply-templates select="." mode="absolute-subtree-level">
            <xsl:with-param name="numbering-items" select="$numbering-footnotes" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1">
            <xsl:number from="book|article|letter|memo" level="any" count="fn" />
        </xsl:when>
        <xsl:when test="$subtree-level=0">
            <xsl:number from="part" level="any" count="fn" />
        </xsl:when>
        <xsl:when test="$subtree-level=1">
            <xsl:number from="chapter|book/backmatter/appendix" level="any" count="fn" />
        </xsl:when>
        <xsl:when test="$subtree-level=2">
            <xsl:number from="section|article/backmatter/appendix|chapter/exercises|chapter/worksheet|chapter/handout|chapter/reading-questions" level="any" count="fn" />
        </xsl:when>
        <xsl:when test="$subtree-level=3">
            <xsl:number from="subsection|section/exercises|section/worksheet|section/handout|section/reading-questions" level="any" count="fn" />
        </xsl:when>
        <xsl:when test="$subtree-level=4">
            <xsl:number from="subsubsection|subsection/exercises|subsection/worksheet|subsection/handout|subsection/reading-questions" level="any" count="fn" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: Subtree level for footnote number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Subfigures, Subtables, Sublisting-->
<!-- Subnumbering only happens with figures            -->
<!-- or tables arranged in a sidebyside, which         -->
<!-- is again contained inside a figure, the           -->
<!-- element providing the overall caption             -->
<!-- The serial number is a sub-number, (a), (b), (c), -->
<!-- *Always* with the parenthetical formatting        -->
<!-- Debatable if parentheses should come from here    -->


<!-- In this case the structure number is the          -->
<!-- full number of the enclosing figure               -->

<!-- a lone sidebyside, not in a sbsgroup -->
<xsl:template match="figure/sidebyside/figure | figure/sidebyside/table | figure/sidebyside/listing | figure/sidebyside/list" mode="serial-number">
    <xsl:text>(</xsl:text>
    <xsl:number format="a" count="figure|table|listing|list"/>
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- when inside a sbsgroup, subnumbers range across entire group -->
<xsl:template match="figure/sbsgroup/sidebyside/figure | figure/sbsgroup/sidebyside/table | figure/sbsgroup/sidebyside/listing | figure/sbsgroup/sidebyside/list" mode="serial-number">
    <xsl:text>(</xsl:text>
    <xsl:number format="a" count="figure|table|listing|list" level="any" from="sbsgroup"/>
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- Serial Numbers: List Items -->

<!-- First, the number of a list item within its own ordered list.  This -->
<!-- trades on the PTX format codes being identical to the XSLT codes.   -->
<xsl:template match="ol/li" mode="item-number">
    <xsl:variable name="code" select="../@format-code" />
    <xsl:number format="{$code}" />
</xsl:template>

<!-- Second, the serial number computed recursively.  The       -->
<!-- entire hierarchy should be ordered lists, since otherwise, -->
<!-- the template just below will apply instead.                -->
<xsl:template match="ol/li" mode="serial-number">
    <xsl:if test="ancestor::li">
        <xsl:apply-templates select="ancestor::li[1]" mode="serial-number" />
        <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="item-number" />
</xsl:template>

<!-- If any ancestor of a list item is not ordered, this     -->
<!-- template should match first, and the serial number      -->
<!-- will be empty, the signal that an object has no number. -->
<xsl:template match="ul//li|dl//li" mode="serial-number" />


<!-- Serial Numbers: Exercise Groups -->
<!-- We provide the range of the     -->
<!-- group as its serial number.     -->
<xsl:template match="exercisegroup" mode="serial-number">
    <xsl:apply-templates select="exercise[1]" mode="serial-number" />
    <xsl:call-template name="ndash-character"/>
    <xsl:apply-templates select="exercise[last()]" mode="serial-number" />
</xsl:template>

<!-- Serial Numbers: Tasks (in Projects) -->
<!-- Tasks have "list" numbers, which we use on labels -->
<!-- (we could use serial numbers for a more complex look) -->
<xsl:template match="task" mode="list-number">
    <xsl:number format="a" />
</xsl:template>
<xsl:template match="task/task" mode="list-number">
    <xsl:number format="i" />
</xsl:template>
<xsl:template match="task/task/task" mode="list-number">
    <xsl:number format="A" />
</xsl:template>
<!-- concatenate list numbers to get serial numbers, eg a.i.A -->
<xsl:template match="task" mode="serial-number">
    <xsl:apply-templates select="." mode="list-number" />
</xsl:template>
<xsl:template match="task/task" mode="serial-number">
    <xsl:apply-templates select="parent::task" mode="serial-number" />
    <xsl:text>.</xsl:text>
    <xsl:apply-templates select="." mode="list-number" />
</xsl:template>
<xsl:template match="task/task/task" mode="serial-number">
    <xsl:apply-templates select="parent::task" mode="serial-number" />
    <xsl:text>.</xsl:text>
    <xsl:apply-templates select="." mode="list-number" />
</xsl:template>

<!-- Serial Numbers: fragments -->
<!-- Simply numbered sequentially, globally. -->
<xsl:template match="fragment" mode="serial-number">
    <xsl:number level="any"/>
</xsl:template>


<!-- Serial Numbers: the unnumbered     -->
<!-- Empty string signifies not numbered -->

<!-- We choose not to number unique, or semi-unique      -->
<!-- (eg prefaces, colophons), elements.  Other elements -->
<!-- are meant as local commentary, and may also carry   -->
<!-- a title for identification and cross-referencing.   -->
<xsl:template match="book|article|letter|memo|paragraphs|blockquote|preface|abstract|acknowledgement|biography|foreword|dedication|contributors|index-part|index[index-list]|colophon|webwork|p|assemblage|aside|biographical|historical|case|contributor" mode="serial-number" />

<!-- Some divisions, like "exercises", "solutions", "references",     -->
<!-- are part of the hierarchical numbering scheme, and look simply   -->
<!-- to their parent.  Which could be the top-level when in th main   -->
<!-- matter (we handle cases of children of "backmatter" carefully    -->
<!-- elsewhere or it does not happen).  So we need an empty structure -->
<!-- number for these cases.                                          -->
<xsl:template match="book|article|letter|memo" mode="structure-number" />

<!-- Some items are "containers".  They are not numbered, you  -->
<!-- cannot point to them, they are invisible to the reader    -->
<!-- in a way.  We kill their serial numbers explicitly here.  -->
<!-- Lists live in paragraphs, exercises, objectives, so       -->
<!-- should be referenced as part of some enclosing element.   -->
<!-- "mathbook" helps some tree-climbing routines halt -->
<xsl:template match="mathbook|pretext|introduction|conclusion|frontmatter|backmatter|sidebyside|sbsgroup|ol|ul|dl|statement" mode="serial-number" />

<!-- Poems go by their titles, not numbers -->
<xsl:template match="poem" mode="serial-number" />

<!-- Preformatted ("pre") appear in search results by name -->
<xsl:template match="pre" mode="serial-number" />

<!-- List items, subordinate to an unordered list, or a description  -->
<!-- list, will have numbers that are especically ambiguous, perhaps -->
<!-- even very clsoe within a multi-level list. They are unnumbered  -->
<!-- in the vicinity of computing serial numbers of list items in    -->
<!-- ordered lists.                                                  -->

<!-- Every displayed equation eventually lands inside an "mrow" and  -->
<!-- the pre-processor identifies it as numbered or not, so the      -->
<!-- unnumbered ones are straightforward.  A local tag (@tag)        -->
<!-- authored on an "mrow" is considered an unnumbered equation.     -->
<xsl:template match="mrow[@pi:numbered = 'no']" mode="serial-number"/>

<!-- WeBWorK problems are never numbered, because they live    -->
<!-- in (numbered) exercises.  But they have identically named -->
<!-- components of exercises, so we might need to explicitly   -->
<!-- make webwork/solution, etc to be unnumbered.              -->

<!-- Glossary items ("gi"), in a "glossary", are known by their title -->
<xsl:template match="gi" mode="serial-number"/>

<!-- GOAL-LIKE are one-per-subdivision,               -->
<!-- and so get their serial number from their parent -->
<xsl:template match="&GOAL-LIKE;" mode="serial-number">
    <xsl:apply-templates select="parent::*" mode="serial-number" />
</xsl:template>

<!-- A subexercises is meant to be minimal, and does not have a number -->
<xsl:template match="subexercises" mode="serial-number"/>

<!-- We only allow one "instructions" for an "interactive" -->
<xsl:template match="interactive/instructions" mode="serial-number"/>

<!-- Multi-part WeBWorK problems have PTX elements        -->
<!-- called "stage" which typically render as "Part..."   -->
<!-- Their serial numbers are useful, there is no attempt -->
<!-- above to integrate these into our general scheme     -->
<!-- These are just counted among enclosing "webwork"     -->
<xsl:template match="webwork/stage" mode="serial-number">
    <xsl:number count="stage" from="webwork" />
</xsl:template>

<!-- But when a problem is part of the OPL and is retrieved -->
<!-- from the server, then we don't see the "stage" element -->
<!-- until we merge in the "static" version as part of the  -->
<!-- "webwork-reps" collection                              -->
<xsl:template match="webwork-reps/static/stage" mode="serial-number">
    <xsl:number count="stage" from="static" />
</xsl:template>

<!-- TEMPORARY -->
<!-- 2023-02-16: placeholder numbers for OPENPROBLEM-LIKE, DISCUSSION-LIKE -->
<xsl:template match="&OPENPROBLEM-LIKE;" mode="serial-number">
    <xsl:text>N</xsl:text>
</xsl:template>
<xsl:template match="&OPENPROBLEM-LIKE;" mode="structure-number">
    <xsl:text>M</xsl:text>
</xsl:template>
<xsl:template match="&DISCUSSION-LIKE;" mode="serial-number">
    <xsl:number select="parent::*" count="&DISCUSSION-LIKE;"/>
</xsl:template>
<xsl:template match="&DISCUSSION-LIKE;" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number"/>
</xsl:template>

<!-- No numbers on pages of worksheets -->
<xsl:template match="page" mode="serial-number"/>

<!-- Should not drop in here.  Ever. -->
<xsl:template match="*" mode="serial-number">
    <xsl:text>[NUM]</xsl:text>
    <xsl:message>PTX:ERROR:   An object (<xsl:value-of select="local-name(.)" />) lacks a serial number, search output for "[NUM]"</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
</xsl:template>

<!--                       -->
<!-- Multi-Numbers Utility -->
<!--                       -->

<!-- We concatenate serial numbers of divisions to form the       -->
<!-- "structure number" of a division or element.                 -->
<!-- NOTE: this is not the number of a division (or element),     -->
<!-- it is everything but the "serial number".  Later, the        -->
<!-- serial number is appended to form the "number".              -->
<!-- So if the context is a division element we look at strict    -->
<!-- *ancestors* to accumulate serial numbers into a structure    -->
<!-- number.  For example, an implication of this is that the     -->
<!-- structure number of a chapter in a part-less book will be    -->
<!-- empty - its number is just its serial-number.                -->
<!-- NB: the structure number never ends in a separator (period). -->
<!--                                                              -->
<!-- We initialize the recursion with exactly the ancestors       -->
<!-- that contributes to a structure number.  This is the only    -->
<!-- time the context is employed.  The level is                  -->
<!--   (a) $pad = 'no',  the maximum number of levels, which      -->
<!--   may not be reached if the $nodes get depleted              -->
<!--   (b) $pad = 'yes', the exact number of serial numbers       -->
<!--   accumulated, and hence the number of separators            -->
<!--   in the final number (after the serial number is appended)  -->
<!-- NB: decorative parts may mean we need                        -->
<!-- to exclude "part" from the ancestors?                        -->
<!-- NB: for a book with parts, we include the "backmatter" in    -->
<!-- the list of $nodes, to impersonate the "part" nodes when     -->
<!-- working with the main matter.  Like a "part", we silently    -->
<!-- drop it and decrement the level.                             -->

<!-- BUG: we include specialized divisions here, which inherit -->
<!-- their serial number from their parent.  The symptom is a  -->
<!-- duplicated serial number just before padding begins.  The -->
<!-- offending specialized division should be skipped with no  -->
<!-- contribution to the multi-number and no decrease in the   -->
<!-- level when passed recursively.                            -->

<xsl:template match="*" mode="multi-number">
    <xsl:param name="nodes" select="ancestor::*[self::part or self::chapter or self::appendix or self::section or self::subsection or self::subsubsection or self::exercises or self::reading-questions or self::solutions or self::references or self::glossary or self::worksheet or self::handout or self::backmatter[$b-has-parts]]"/>
    <xsl:param name="levels" />
    <xsl:param name="pad" />

    <!-- Test if last node is unnumbered specialized division -->
    <!-- we do not want to duplicate the serial number, which is from the containing division -->
    <xsl:variable name="decorative-division">
        <xsl:if test="$nodes[last()][self::exercises or self::worksheet or self::handout or self::reading-questions]">
            <xsl:variable name="is-numbered">
                <xsl:apply-templates select="$nodes[last()]" mode="is-specialized-own-number"/>
            </xsl:variable>
            <xsl:if test="not($is-numbered = 'true')">
                <xsl:text>true</xsl:text>
            </xsl:if>
        </xsl:if>
    </xsl:variable>

    <xsl:choose>
        <!-- always halt when levels met, do this check *before* -->
        <!-- adjusting for parts or for decorative divisions     -->
        <xsl:when test="$levels = 0" />
        <!-- When the lead node is a part, we just drop it,   -->
        <!-- and we decrement the level.  A lead node of      -->
        <!-- backmatter will appear for a book with parts,    -->
        <!-- which is dropped also.  We may later devise      -->
        <!-- an option with more part numbers, and we can     -->
        <!-- condition here to include the part number in the -->
        <!-- numbering scheme NB: this is *not* the serial    -->
        <!-- number, so for example, the summary page for     -->
        <!-- a part *will* have a number, and the right one   -->
        <!-- NB: can $nodes be stripped without the  position()  function? -->
        <xsl:when test="$nodes[1][self::part or self::backmatter]">
            <xsl:apply-templates select="." mode="multi-number">
                <xsl:with-param name="nodes" select="$nodes[position() > 1]" />
                <xsl:with-param name="levels" select="$levels - 1" />
                <xsl:with-param name="pad" select="$pad" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- strip a decorative division -->
        <xsl:when test="$decorative-division = 'true'">
            <xsl:apply-templates select="." mode="multi-number">
                <xsl:with-param name="nodes" select="$nodes[position() &lt; last()]" />
                <xsl:with-param name="levels" select="$levels" />
                <xsl:with-param name="pad" select="$pad" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- not padding, halt if $nodes exhausted -->
        <xsl:when test="($pad = 'no') and not($nodes)" />
        <xsl:otherwise>
            <xsl:choose>
                <xsl:when test="$nodes">
                    <xsl:apply-templates select="$nodes[1]" mode="serial-number"/>
                </xsl:when>
                <!-- no nodes, so must be padding -->
                <xsl:otherwise>
                    <xsl:text>0</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <!-- mutuially exclusive conditions, just for clarity           -->
            <!-- (a) if halting next pass, no separator, no-padding version -->
            <xsl:if test="($pad = 'no') and not(count($nodes) = 1) and not($levels = 1)">
                <xsl:text>.</xsl:text>
            </xsl:if>
            <!-- (b) if halting next pass, no separator, padding version -->
            <xsl:if test="($pad = 'yes') and not($levels = 1)">
                <xsl:text>.</xsl:text>
            </xsl:if>
            <!-- decrease $nodes and $levels             -->
            <!-- padding: empty $nodes can't get emptier -->
            <xsl:apply-templates select="." mode="multi-number">
                <xsl:with-param name="nodes" select="$nodes[position() > 1]" />
                <xsl:with-param name="levels" select="$levels - 1" />
                <xsl:with-param name="pad" select="$pad" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!--                         -->
<!-- Structure Numbers       -->
<!--                         -->

<!-- We compute multi-part numbers to the necessary,  -->
<!-- or configured, number of components              -->
<!-- NB: *every* structure number should finish with  -->
<!-- a period as a separator, which is often provided -->
<!-- by the "multi-number" template.  Some of the     -->
<!-- cross-reference text code adds a period before   -->
<!-- testing equality of strings                      -->

<!-- Structure Numbers: Divisions -->
<!-- NB: this is number of the *container* of the division,   -->
<!-- a serial number for the division itself will be appended -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|backmatter/solutions" mode="structure-number">
    <xsl:value-of select="@struct"/>
</xsl:template>

<!-- Structure Numbers: Specialized Divisions -->
<!-- Some divisions get their numbers from their parents, or  -->
<!-- in other ways.  We are careful to do this by determining -->
<!-- the serial-numer and the structure-number, so that other -->
<!-- devices (like local numbers) will behave correctly.      -->
<!-- Serial numbers are computed elsewhere, but in tandem.    -->
<xsl:template match="exercises|solutions[not(parent::backmatter)]|worksheet|handout|reading-questions|references[not(parent::backmatter)]|glossary[not(parent::backmatter)]" mode="structure-number">
    <xsl:variable name="is-numbered">
        <xsl:apply-templates select="." mode="is-specialized-own-number"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$is-numbered = 'true'">
            <xsl:value-of select="@struct"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="structure-number" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<!-- "references" and "glossary" are solo in main matter -->
<!-- divisions, unique and not numbered in back matter   -->
<xsl:template match="backmatter/references" mode="structure-number" />
<xsl:template match="backmatter/glossary" mode="structure-number" />


<!-- Structure Numbers: Theorems, Examples, Projects, Figures -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" mode="structure-number">
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$numbering-blocks" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>
<!-- PROJECT-LIKE is now independent, under control of $numbering-projects -->
<!-- But all ready to become elective -->
<xsl:template match="&PROJECT-LIKE;"  mode="structure-number">
    <xsl:variable name="project-levels">
        <xsl:choose>
            <xsl:when test="$b-number-project-distinct">
                <xsl:value-of select="$numbering-projects" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$numbering-blocks" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$project-levels" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>
<!-- FIGURE-LIKE get a structure number from default $numbering-blocks -->
<!-- or from "docinfo" independent numbering configuration             -->
<xsl:template match="&FIGURE-LIKE;"  mode="structure-number">
    <xsl:variable name="figure-levels">
        <xsl:choose>
            <xsl:when test="$b-number-figure-distinct">
                <xsl:value-of select="$numbering-figures" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$numbering-blocks" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$figure-levels" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>
<!-- Proofs get structure number from parent theorem -->
<!-- NB: assumes proofs are not detached? Maybe not.      -->
<!-- Definitely a detached proof in a "paragraphs" is bad -->
<xsl:template match="&PROOF-LIKE;" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
</xsl:template>
<!-- Captioned items, arranged in a side-by-side,  -->
<!-- then inside a captioned figure, earn a serial -->
<!-- number that is a letter.  So their structure  -->
<!-- number comes from their grandparent figure    -->
<xsl:template match="figure/sidebyside/figure | figure/sidebyside/table | figure/sidebyside/listing | figure/sidebyside/list" mode="structure-number">
    <xsl:apply-templates select="parent::sidebyside/parent::figure" mode="number" />
</xsl:template>

<!-- Structure Numbers: Equations -->
<!-- "mrow" may be numbered, and bare "md" inherit a number from their  -->
<!-- manufactured single "mrow".  So we need a structure number for the -->
<!-- numbered versions of these elements.                               -->
<xsl:template match="mrow|md[@pi:authored-one-line]" mode="structure-number">
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$numbering-equations" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>

<!-- Structure Numbers: Inline Exercises -->
<!-- Follows the theorem/figure/etc scheme (can't poll parent) -->
<xsl:template match="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" mode="structure-number">
    <xsl:variable name="equation-levels">
        <xsl:choose>
            <xsl:when test="$b-number-exercise-distinct">
                <xsl:value-of select="$numbering-exercises" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$numbering-blocks" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$equation-levels" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>

<!-- Structure Numbers: Divisional and Worksheet Exercises -->
<!-- Within a "exercises" or "worksheet", look up to enclosing division -->
<!-- in order to decide where the structure number comes from           -->
<xsl:template match="exercises//exercise|worksheet//exercise|reading-questions//exercise" mode="structure-number">
    <!-- Need to look up through "exercisegroup", "subexercises", "sidebyside", etc -->
    <!-- Only one of these specialized divisions, just a single node in variable    -->
    <xsl:variable name="container" select="ancestor::*[self::exercises or self::worksheet or self::reading-questions]"/>
    <xsl:apply-templates select="$container" mode="number" />
</xsl:template>

<!-- Structure Numbers: Exercise Groups -->
<!-- An exercisegroup gets it structure number from the parent exercises -->
<xsl:template match="exercisegroup" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
</xsl:template>

<!-- Hints, answers, solutions get structure number from parent       -->
<!-- exercise's number. Identical for inline and divisional exercises -->
<xsl:template match="&SOLUTION-LIKE;" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
</xsl:template>

<!-- Anything within a webwork-reps that needs a structure number    -->
<!-- gets it from the enclosing exercise.                            -->
<xsl:template match="webwork-reps//*" mode="structure-number">
    <xsl:apply-templates select="ancestor::exercise" mode="number" />
</xsl:template>

<!-- Structure Numbers: Bibliographic Items -->
<!-- Bibliographic items get their number from the containing     -->
<!-- "references", which may be solo in an unstructured division, -->
<!-- or one of potentially several in a structured division.      -->
<!-- Since the global "references" (child of "backmatter") is not -->
<!-- numbered, these items will have un-qualified numbers         -->
<!-- (serial number only). -->
<xsl:template match="biblio" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
</xsl:template>

<!-- Notes get structure number from parent biblio's number -->
<xsl:template match="biblio/note" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
</xsl:template>

<!-- Structure Numbers: Footnotes -->
<xsl:template match="fn" mode="structure-number">
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$numbering-footnotes" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>

<!-- Structure Numbers: Lists -->
<!-- Lists occur in paragraphs (anonymously), in "list"      -->
<!-- blocks (numbered), and within exercises (numbered).     -->
<!-- Typically we are interested in list items (only),       -->
<!-- since that is where there is content.  And then we      -->
<!-- are only interested in the list items within an ordered -->
<!-- list.  We control for items under unordered lists or    -->
<!-- description lists elsewhere by providing empty numbers. -->
<!-- NB: the order of these templates may matter             -->
<xsl:template match="li" mode="structure-number" />

<xsl:template match="list//li" mode="structure-number">
    <xsl:apply-templates select="ancestor::list" mode="number" />
</xsl:template>

<xsl:template match="exercise//li" mode="structure-number">
    <xsl:apply-templates select="ancestor::exercise" mode="number" />
</xsl:template>

<!-- Structure Numbers: Tasks (in projects) -->
<!-- A task gets it structure number from the parent project-like -->
<xsl:template match="task" mode="structure-number">
    <!-- ancestors, strip tasks, get number of next enclosure -->
    <xsl:apply-templates select="ancestor::*[not(self::task)][1]" mode="number" />
</xsl:template>

<!-- Structure Numbers: GOAL-LIKE -->
<!-- Objectives are one-per-subdivision, and so   -->
<!-- get their structure number from their parent -->
<xsl:template match="&GOAL-LIKE;" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="structure-number" />
</xsl:template>

<!-- Structure Numbers: Objective and Outcome-->
<!-- A single objective or outcome is a list item -->
<!-- in an objectives or outcomes environment     -->
<xsl:template match="objectives/ol/li|outcomes/ol/li" mode="structure-number">
    <xsl:apply-templates select="ancestor::*[&STRUCTURAL-FILTER;][1]" mode="number" />
</xsl:template>

<!-- Structure Numbers: Fragment -->
<!-- We number serially, see below -->
<xsl:template match="fragment" mode="structure-number"/>

<!-- worksheet pages are unnumbered -->
<xsl:template match="page" mode="structure-number"/>

<!-- Should not drop in here.  Ever. -->
<xsl:template match="*" mode="structure-number">
    <xsl:text>[STRUCT]</xsl:text>
    <xsl:message>PTX:ERROR:   An object (<xsl:value-of select="local-name(.)" />) lacks a structure number, search output for "[STRUCT]"</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
</xsl:template>

<!--              -->
<!-- Full Numbers -->
<!--              -->

<!-- Now trivial, the container structure plus the serial.  -->
<!-- We condition on empty serial number in order to create -->
<!-- empty full numbers.  This is where we add separator,   -->
<!-- normally a period, but for a list item within a named  -->
<!-- list, we use a colon (a double period?).               -->
<xsl:template match="*" mode="number">
    <xsl:variable name="serial">
        <xsl:apply-templates select="." mode="serial-number" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$serial = ''" />
        <xsl:otherwise>
            <xsl:variable name="structure">
                <xsl:apply-templates select="." mode="structure-number" />
            </xsl:variable>
            <xsl:if test="not($structure='')">
                <xsl:value-of select="$structure" />
                <xsl:choose>
                    <xsl:when test="self::li and ancestor::list">
                        <xsl:text>:</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>.</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:value-of select="$serial" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!--                       -->
<!-- Circular Case Numbers -->
<!--                       -->

<!-- These two templates are to facilitate outputting ⇒	and ⇐ in different target formats. -->
<!-- They are (or should be) overridden with appropriate templates of same name in the     -->
<!-- -latex, -html, etc conversions.                                                       -->
<xsl:template name="double-right-arrow-symbol">
    <xsl:message>PTX:BUG: A "case" has "direction" equal to either "forward" or "cycle", but the conversion for this output target does not have a double right arrow symbol defined.</xsl:message>
    <xsl:apply-templates select="." mode="location-report"/>
</xsl:template>
<xsl:template name="double-left-arrow-symbol">
    <xsl:message>PTX:BUG: A "case" has "direction" equal to "backward", but the conversion for this output target does not have a double left arrow symbol defined.</xsl:message>
    <xsl:apply-templates select="." mode="location-report"/>
</xsl:template>
<!-- This template is to add an extra small horizontal space between the outer delimiters -->
<!-- and the inner content of the "cycle" title for a "case", in case the "marker" on the -->
<!-- corresponding "ol" also involves delimiters. Not an error if this is left undefined  -->
<!-- or is defined to be a null string in a particular conversion stylesheet, in which    -->
 <!-- case no extra space is added. -->
<xsl:template name="case-cycle-delimiter-space">
    <xsl:message>PTX:BUG A "case" has "direction" equal to "cycle", but the conversion for this output target does not have a "delimiter space" symbol defined. The maintainer for this output target may wish to know about this (or may wish to set the "delimiter space" symbol to be a null string to suppress this warning message).</xsl:message>
    <xsl:apply-templates select="." mode="location-report"/>
</xsl:template>

<xsl:template match="ol" mode="marker-formatted-case-cycle">
    <xsl:param name="from" />
    <xsl:param name="to" />
    <xsl:variable name="format-code">
        <xsl:choose>
            <xsl:when test="self::node()[@format-code]">
                <xsl:value-of select="./@format-code" />
            </xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="adjusted-from">
        <xsl:choose>
            <xsl:when test="$format-code = '0'"><xsl:value-of select="$from - 1" /></xsl:when>
            <xsl:otherwise><xsl:value-of select="$from" /></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="adjusted-to">
        <xsl:choose>
            <xsl:when test="$format-code = '0'"><xsl:value-of select="$to - 1" /></xsl:when>
            <xsl:otherwise><xsl:value-of select="$to" /></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="original-marker-suffix" select="./@marker-suffix" />
    <xsl:variable name="marker-suffix">
        <xsl:choose>
            <!-- Strip out any trailing dot from the marker format. -->
            <xsl:when test="substring($original-marker-suffix, string-length($original-marker-suffix)) = '.'">
                <xsl:value-of select="substring($original-marker-suffix,1,string-length($original-marker-suffix) - 1)" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$original-marker-suffix" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="formatted-case-cycle">
        <xsl:with-param name="from">
            <xsl:value-of select="./@marker-prefix" />
            <xsl:number value="$adjusted-from" format="{$format-code}" />
            <xsl:value-of select="$marker-suffix" />
        </xsl:with-param>
        <xsl:with-param name="to">
            <xsl:value-of select="./@marker-prefix" />
            <xsl:number value="$adjusted-to" format="{$format-code}" />
            <xsl:value-of select="$marker-suffix" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template name="formatted-case-cycle">
    <xsl:param name="from" />
    <xsl:param name="to" />
    <xsl:text>(</xsl:text>
    <xsl:call-template name="case-cycle-delimiter-space" />
    <xsl:value-of select="$from" />
    <xsl:text>&#xa0;</xsl:text>
    <xsl:call-template name="double-right-arrow-symbol" />
    <xsl:text>&#xa0;</xsl:text>
    <xsl:value-of select="$to" />
    <xsl:call-template name="case-cycle-delimiter-space" />
    <xsl:text>)&#xa0;</xsl:text>
</xsl:template>

<xsl:template match="case" mode="case-cycle-numbers">
    <xsl:variable name="cycle-position">
        <xsl:number count="case[@direction='cycle']" />
    </xsl:variable>
    <xsl:number value="$cycle-position" />
    <xsl:text>|</xsl:text>
    <xsl:choose>
        <xsl:when test="$cycle-position = count(../case[@direction='cycle'])">
            <xsl:if test="$cycle-position = 1">
                <xsl:message>PTX:WARNING: a "case" with @direction "cycle" should be one of several</xsl:message>
                <xsl:apply-templates select="../.." mode="location-report"/>
            </xsl:if>
            <xsl:number value="1" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:number value="$cycle-position + 1" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="proof[@ref]/case" mode="case-cycle">
    <!-- NB existence/validity of "@ref" is already error checked   -->
    <!-- by code that augments the proof title based on the "@ref". -->
    <xsl:variable name="cycle-numbers">
        <xsl:apply-templates select="." mode="case-cycle-numbers" />
    </xsl:variable>
    <xsl:variable name="cycle-position" select="substring-before($cycle-numbers,'|')" />
    <xsl:variable name="cycle-position-plus-one" select="substring-after($cycle-numbers,'|')" />
    <xsl:variable name="target" select="id(../@ref)"/>
    <!-- "@ref" should point to something containing an "ol". -->
    <!-- NB In future this might be a "statement" child of a  -->
    <!-- THEOREM-LIKE instead of specifically a THEOREM-LIKE. -->
    <xsl:choose>
        <xsl:when test="$target//ol[1]">
            <xsl:apply-templates select="$target//ol[1]" mode="marker-formatted-case-cycle">
                <xsl:with-param name="from" select="$cycle-position" />
                <xsl:with-param name="to" select="$cycle-position-plus-one" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING:   a cross-reference ("ref") from a "<xsl:value-of select="local-name(..)"/>" containing at least one "case" with "direction" set to "cycle" uses a reference [<xsl:value-of select="../@ref"/>] that does not point to an element that contains an "ol".</xsl:message>
            <xsl:apply-templates select="../.." mode="location-report"/>
            <xsl:call-template name="formatted-case-cycle">
                <xsl:with-param name="from" select="$cycle-position" />
                <xsl:with-param name="to" select="$cycle-position-plus-one" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="proof[not(@ref)]/case" mode="case-cycle">
    <xsl:variable name="cycle-numbers">
        <xsl:apply-templates select="." mode="case-cycle-numbers" />
    </xsl:variable>
    <xsl:variable name="cycle-position" select="substring-before($cycle-numbers,'|')" />
    <xsl:variable name="cycle-position-plus-one" select="substring-after($cycle-numbers,'|')" />
    <xsl:choose>
        <!-- Check if the "proof" has a "statement" sibling    -->
        <!-- (implying the "proof" is a child of THEOREM-LIKE) -->
        <!-- where that "statement" sibling contains an "ol"   -->
        <!-- from which we can copy the marker information.    -->
        <!-- NB We don't filter on "ol[@marker]" because we    -->
        <!-- still need to honour the format code which may    -->
        <!-- be derived from nesting during -assembly. Not     -->
        <!-- relevant now because our "ol" should be top level -->
        <!-- in its "statement" but potentially relevant in    -->
        <!-- future if THEOREM-LIKE supports multiple          -->
        <!-- "statement" children which would then become the  -->
        <!-- top-level numbering for any list-like children.   -->
        <xsl:when test="../preceding-sibling::statement[1]//ol[1]">
            <xsl:apply-templates select="../preceding-sibling::statement[1]//ol[1]" mode="marker-formatted-case-cycle">
                <xsl:with-param name="from" select="$cycle-position" />
                <xsl:with-param name="to" select="$cycle-position-plus-one" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="formatted-case-cycle">
                <xsl:with-param name="from" select="$cycle-position" />
                <xsl:with-param name="to" select="$cycle-position-plus-one" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="case" mode="case-direction">
    <xsl:choose>
        <xsl:when test="@direction='forward'">
            <xsl:text>(</xsl:text>
            <xsl:call-template name="double-right-arrow-symbol" />
            <xsl:text>)&#xa0;</xsl:text>
        </xsl:when>
        <xsl:when test="@direction='backward'">
            <xsl:text>(</xsl:text>
            <xsl:call-template name="double-left-arrow-symbol" />
            <xsl:text>)&#xa0;</xsl:text>
        </xsl:when>
        <xsl:when test="@direction='cycle'">
            <xsl:apply-templates select="." mode="case-cycle" />
        </xsl:when>
        <!-- DTD will catch wrong values -->
        <xsl:otherwise />
    </xsl:choose>
</xsl:template>

<!-- TESTING -->
<!-- Some test images and debugging output, -->
<!-- while this is still in development -->

<!--
<image />
<image margins="20% 5%" />
<image width="75%" />
<image margins="20% 5%" width="75%" />
 -->
<!-- ~~~~~~~~~~~~~~ -->
<!--
<image margins="150pt" />
<image width="2000" />
<image margins="-40%" />
<image margins="300%" />
<image margins="-20% 5%" />
<image margins="20% 150%" />
<image margins="90% 40%" />
<image margins="5% 10%" width="120%" />
<image margins="5% 10%" width="-10%" />
<image margins="5% 10%" width="90%" />
<image margins="35% 25%" width="39.5%" />
-->

<!--
<xsl:template match="image[not(parent::sidebyside or parent::figure)]">
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters" />
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
    <xsl:message><xsl:value-of select="$layout/left-margin" /></xsl:message>
    <xsl:message><xsl:value-of select="$layout/width" /></xsl:message>
    <xsl:message><xsl:value-of select="$layout/right-margin" /></xsl:message>
    <xsl:message><xsl:value-of select="$layout/left-margin = $layout/right-margin" /></xsl:message>
</xsl:template>
-->

<!-- ############## -->
<!-- Simple Layouts -->
<!-- ############## -->

<!-- This template creates a RTF (result tree fragment), -->
<!-- which needs to be captured in one variable, then    -->
<!-- converted to a node-set with an extension function  -->

<!-- aspect-ratio is only needed for videos in HTML.     -->
<!-- Long story.  It needs to match what is provided     -->
<!-- in the video (a file or an embedded player).  A     -->
<!-- sensible default is "1:1" but in context we might   -->
<!-- want to supply some other sensible default like     -->
<!-- "16:9".  The ONLY purpose of specifying an          -->
<!-- aspect-ratio is to compute some sort of height.     -->
<!-- So we do not report the aspect-ratio itself, but    -->
<!-- instead compute a height (*only* for video).        -->

<!-- NB: An RTF has a "root" node.  Then the elements    -->
<!-- manufactured for it occur as children.  If the      -->
<!-- "apply-templates" fails to have the "/*" at the end -->
<!-- of the "select", then the main entry template will  -->
<!-- be called to do any housekeeping it might do.       -->
<!-- This was a really tough bug to track down.          -->

<xsl:template match="image|audio|video|program|console|tabular" mode="layout-parameters">
    <xsl:param name="default-aspect" select="'1:1'"/>

    <!-- clean up margins -->
    <xsl:variable name="normalized-margins">
        <xsl:choose>
            <xsl:when test="@margins">
                <xsl:value-of select="normalize-space(@margins)" />
            </xsl:when>
            <!-- default if not specified -->
            <xsl:otherwise>
                <xsl:text>auto</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- split on space, or else duplicate (signals centered) -->
    <xsl:variable name="normalized-left-margin">
        <xsl:choose>
            <xsl:when test="contains($normalized-margins, ' ')">
                <xsl:value-of select="substring-before($normalized-margins, ' ')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$normalized-margins" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="normalized-right-margin">
        <xsl:choose>
            <xsl:when test="contains($normalized-margins, ' ')">
                <xsl:value-of select="substring-after($normalized-margins, ' ')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$normalized-margins" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- clean-up single width -->
    <xsl:variable name="normalized-width">
        <xsl:choose>
            <xsl:when test="@width">
                <xsl:value-of select="normalize-space(@width)" />
            </xsl:when>
            <!-- not placed on image, or figure/image,    -->
            <!-- but a document-wide default width exists -->
            <xsl:when test="self::image and not(ancestor::sidebyside) and $docinfo/defaults/image-width">
                <xsl:value-of select="$docinfo/defaults/image-width" />
            </xsl:when>
            <!-- default setting if not specified, and not global -->
            <xsl:otherwise>
                <xsl:value-of select="'auto'" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- clean-up aspect-ratio -->
    <!-- may be a hollow exercise, but no harm since a -->
    <!-- valid ratio is given in parameter default     -->
    <xsl:variable name="normalized-aspect">
        <xsl:variable name="entered-aspect">
            <xsl:choose>
                <xsl:when test="@aspect">
                    <xsl:value-of select="normalize-space(@aspect)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space($default-aspect)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- test if a ratio is given, and assume parts are -->
            <!-- good and that there is only one colon, etc,... -->
            <xsl:when test="contains($entered-aspect, ':')">
                <xsl:variable name="width" select="substring-before($entered-aspect, ':')" />
                <xsl:variable name="height" select="substring-after($entered-aspect, ':')" />
                <xsl:value-of select="$width div $height" />
            </xsl:when>
            <!-- else assume a number was entered -->
            <xsl:otherwise>
                <xsl:value-of select="$entered-aspect"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Error checks on author's specifications     -->
    <!-- First, normalized to strings or percentages -->

    <xsl:if test="not(($normalized-left-margin = 'auto') or substring($normalized-left-margin, string-length($normalized-left-margin)) = '%')">
        <xsl:message>PTX:ERROR:   left margin (<xsl:value-of select="$normalized-left-margin" />) should be given as a percentage (such as "40%"), or as the string "auto"</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <xsl:if test="not(($normalized-width = 'auto') or substring($normalized-width, string-length($normalized-width)) = '%')">
        <xsl:message>PTX:ERROR:   width (<xsl:value-of select="$normalized-width" />) should be given as a percentage (such as "40%"), or as the string "auto"</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <xsl:if test="not(($normalized-right-margin = 'auto') or substring($normalized-right-margin, string-length($normalized-right-margin)) = '%')">
        <xsl:message>PTX:ERROR:   right margin (<xsl:value-of select="$normalized-right-margin" />) should be given as a percentage (such as "40%"), or as the string "auto"</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- Second, cases where computed values could be negative or too large -->

    <!-- Sanity check author's left margin -->
    <xsl:if test="not($normalized-left-margin = 'auto') and ((substring-before($normalized-left-margin, '%') &lt; 0) or (substring-before($normalized-left-margin, '%') &gt; 100))">
        <xsl:message>PTX:ERROR:   left margin (<xsl:value-of select="$normalized-left-margin" />) must be in the interval [0%, 100%]</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- Sanity check author's width -->
    <xsl:if test="not($normalized-width= 'auto') and ((substring-before($normalized-width, '%') &lt; 0) or (substring-before($normalized-width, '%') &gt; 100))">
        <xsl:message>PTX:ERROR:   width (<xsl:value-of select="$normalized-width" />) must be in the interval [0%, 100%]</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- Sanity check author's right margin -->
    <xsl:if test="not($normalized-right-margin = 'auto') and ((substring-before($normalized-right-margin, '%') &lt; 0) or (substring-before($normalized-right-margin, '%') &gt; 100))">
        <xsl:message>PTX:ERROR:   right margin (<xsl:value-of select="$normalized-right-margin" />) must be in the interval [0%, 100%]</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- Sanity check author's cumulative margins -->
    <xsl:if test="not($normalized-left-margin = 'auto') and ((substring-before($normalized-left-margin, '%') + substring-before($normalized-right-margin, '%') &gt; 100))">
        <xsl:message>PTX:ERROR:   margins (<xsl:value-of select="$normalized-left-margin" />, <xsl:value-of select="$normalized-right-margin" />) must not have a sum exceeding 100%</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- Sanity check all parameters together as too large -->
    <xsl:if test="not($normalized-left-margin = 'auto') and not($normalized-width= 'auto') and ((substring-before($normalized-left-margin, '%') + substring-before($normalized-width, '%') + substring-before($normalized-right-margin, '%') &gt; 100))">
        <xsl:message>PTX:ERROR:   margins and width (<xsl:value-of select="$normalized-left-margin" />, <xsl:value-of select="$normalized-width" />, <xsl:value-of select="$normalized-right-margin" />) must not have a sum exceeding 100%</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- Sanity check that all three parameters together sum to 100 *exactly* -->
    <xsl:if test="not($normalized-left-margin = 'auto') and not($normalized-width= 'auto') and not((substring-before($normalized-left-margin, '%') + substring-before($normalized-width, '%') + substring-before($normalized-right-margin, '%') = 100))">
        <xsl:message>PTX:ERROR:   margins and width (<xsl:value-of select="$normalized-left-margin" />, <xsl:value-of select="$normalized-width" />, <xsl:value-of select="$normalized-right-margin" />) must sum to 100%</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- Sanity check on the aspect-ratio -->
    <!-- NaN does not equal *anything*, so tests if a number  -->
    <!-- http://stackoverflow.com/questions/6895870           -->
    <xsl:if test="not(number($normalized-aspect) = number($normalized-aspect)) or ($normalized-aspect &lt; 0)">
        <xsl:message>PTX:ERROR:   the @aspect attribute should be a ratio, like 4:3, or a positive number, not "<xsl:value-of select="@aspect" />"</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <xsl:if test="$normalized-aspect = 0">
        <xsl:message>PTX:FATAL:   an @aspect attribute equal to zero will cause serious errors.</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
        <xsl:message terminate="yes">Quitting...</xsl:message>
    </xsl:if>

    <!-- Perhaps save for debugging -->
    <!-- <xsl:message>L:<xsl:value-of select="$normalized-left-margin" />:L W:<xsl:value-of select="$normalized-width" />:W R:<xsl:value-of select="$normalized-right-margin" />:R</xsl:message> -->

    <!-- Now have three "normalized" percentages, with percentages   -->
    <!-- or default string values.  We would read the table below as -->
    <!-- rows (cases), but we instead focus on the three outcomes    -->
    <!-- as a single variable each.                                  -->
    <!--                                                             -->
    <!--     Margin   Width      Left      Width     Right           -->
    <!--                                                             -->
    <!--     auto     auto          0        100         0           -->
    <!--     value    auto      value    compute     value           -->
    <!--     auto     value    center      value    center           -->
    <!--     value    value     value      value     value           -->
    <!--                                                             -->
    <!-- In contrast to earlier practice, we now (2018-07-20) return -->
    <!-- percentages with no percent sign, so as to do the least     -->
    <!-- manipulation possible here.  Consumers can add back the     -->
    <!-- percent sign, divide by 100, take a fraction of a maximum   -->
    <!-- width, and so on.                                           -->

    <xsl:variable name="left-margin">
        <xsl:choose>
            <xsl:when test="($normalized-left-margin = 'auto') and ($normalized-width = 'auto')">
                <xsl:value-of select="'0'" />
            </xsl:when>
            <xsl:when test="not($normalized-left-margin = 'auto') and ($normalized-width = 'auto')">
                <xsl:value-of select="substring-before($normalized-left-margin, '%')" />
            </xsl:when>
            <xsl:when test="($normalized-left-margin = 'auto') and not($normalized-width = 'auto')">
                <xsl:value-of select="(100 - substring-before($normalized-width, '%')) div 2" />
            </xsl:when>
            <xsl:when test="not($normalized-left-margin = 'auto') and not($normalized-width = 'auto')">
                <xsl:value-of select="substring-before($normalized-left-margin, '%')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>OOOPS1111</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="right-margin">
        <xsl:choose>
            <xsl:when test="($normalized-left-margin = 'auto') and ($normalized-width = 'auto')">
                <xsl:value-of select="'0'" />
            </xsl:when>
            <xsl:when test="not($normalized-left-margin = 'auto') and ($normalized-width = 'auto')">
                <xsl:value-of select="substring-before($normalized-right-margin, '%')" />
            </xsl:when>
            <xsl:when test="($normalized-left-margin = 'auto') and not($normalized-width = 'auto')">
                <xsl:value-of select="(100 - substring-before($normalized-width, '%')) div 2" />
            </xsl:when>
            <xsl:when test="not($normalized-left-margin = 'auto') and not($normalized-width = 'auto')">
                <xsl:value-of select="substring-before($normalized-right-margin, '%')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>OOOPS22222</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="width">
        <xsl:choose>
            <xsl:when test="($normalized-left-margin = 'auto') and ($normalized-width = 'auto')">
                <xsl:value-of select="'100'" />
            </xsl:when>
            <xsl:when test="not($normalized-left-margin = 'auto') and ($normalized-width = 'auto')">
                <xsl:value-of select="100 - substring-before($normalized-left-margin, '%') - substring-before($normalized-right-margin, '%')" />
            </xsl:when>
            <xsl:when test="($normalized-left-margin = 'auto') and not($normalized-width = 'auto')">
                <xsl:value-of select="substring-before($normalized-width, '%')" />
            </xsl:when>
            <xsl:when test="not($normalized-left-margin = 'auto') and not($normalized-width = 'auto')">
                <xsl:value-of select="substring-before($normalized-width, '%')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>OOOPS33333</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- "height" is derived from width and aspect-ratio.  -->
    <!-- We warn above about a potential division by zero. -->
    <xsl:variable name="height" select="$width div $normalized-aspect"/>

    <xsl:variable name="centered" select="$left-margin = $right-margin" />

    <!-- This is the RTF, which will automatically be bundled with -->
    <!-- a root. Elements should be mostly self-explanatory.       -->
    <!-- "centered" is reported NOW, not computed later, when the  -->
    <!-- two margins are either                                    -->
    <!--   (a) specified identically by the author,                -->
    <!--   (b) computed identically above, or                      -->
    <!--   (c) default to identical values.                        -->

    <left-margin>
        <xsl:value-of select="$left-margin" />
    </left-margin>
    <width>
        <xsl:value-of select="$width" />
    </width>
    <!-- Only a "video" gets its height from this layout object, -->
    <!-- so even if we have computed it, we do not report it     -->
    <xsl:if test="self::video">
        <height>
            <xsl:value-of select="$height"/>
        </height>
    </xsl:if>
    <right-margin>
        <xsl:value-of select="$right-margin" />
    </right-margin>
    <centered>
        <xsl:value-of select="$centered" />
    </centered>

    <!-- This will be useful in a debugging switch -->
<!--
    <xsl:message>l:<xsl:value-of select="$left-margin" />:l w:<xsl:value-of select="$width" />:w r:<xsl:value-of select="$right-margin" />:r c:<xsl:value-of select="$centered" />:c</xsl:message>
    <xsl:message>- - - - - - - - - - - - - </xsl:message>
-->
</xsl:template>

<!-- ################## -->
<!-- SideBySide Layouts -->
<!-- ################## -->

<!-- Horizontal layouts of "panels" with vertical alignments      -->
<!-- A container for layout of other elements, eg figures, images -->
<!-- No notion of columns, no rules or dividers, no row headers   -->
<!-- This is purely a container to specify layout parameters,     -->
<!-- and place/control the horizontal arrangement in converters   -->

<!-- Debug with sbs.debug string parameter, $sbsdebug variable  -->
<!-- Colored boxes in HTML, black boxes in LaTeX with baselines -->

<!-- A "sidebyside" is a sequence of objects laid out       -->
<!-- horizontally in panels.  This is a deviation from      -->
<!-- the usual vertical rythym of a page.  The "best"       -->
<!-- objects are those that are pliable horizontally,       -->
<!-- such as a paragraph, or a scalable image.  Rigid       -->
<!-- objects, like pre-formatted text or some tables,       -->
<!-- require some care from the author.  Attributes         -->
<!-- that control the layout follow, and override           -->
<!-- identical attributes placed on an enclosing            -->
<!-- "sbsgroup" (if employed).                              -->
<!--                                                        -->
<!-- (a) "margins"                                          -->
<!--  - one percentage for both left and right (nn%)        -->
<!--  - "auto" => margins are half the space between panels -->
<!--  - default is "auto"                                   -->
<!-- (b) "widths"                                           -->
<!--  - widths of panels, one per panel                     -->
<!--  - space separated list of percentages                 -->
<!--  - default is equal division of available total width  -->
<!-- (c) "valigns", "valign"                                -->
<!--  - vertical alignment of content within panel          -->
<!--  - space separated list of top, middle, bottom         -->
<!--  - singular is common alignment for all panels         -->
<!--  - default is top                                      -->
<!--                                                        -->
<!-- Default behavior is automatic margins, no spacing      -->
<!-- between panels and equally wide panels.                -->
<!--                                                        -->
<!-- With widths specified, remaining space is              -->
<!-- used to create equal spacing between panels            -->

<!-- Extensive layout analysis first, main templates follow -->

<!-- We analyze the attributes of a "sidebyside" element -->
<!-- in order to extract/compute the layout parameters   -->
<!-- This template creates a RTF (result tree fragment), -->
<!-- which needs to be captured in one variable, then    -->
<!-- converted to a node-set with an extension function  -->
<xsl:template match="sidebyside" mode="layout-parameters">

    <!-- Number of Panels -->
    <!-- count the elements destined for panels  -->
    <xsl:variable name="number-panels" select="count(*)" />
    <xsl:if test="$sbsdebug">
        <xsl:message>N:<xsl:value-of select="$number-panels" />:N</xsl:message>
    </xsl:if>
    <!-- Add to RTF -->
    <number-panels>
        <xsl:value-of select="$number-panels" />
    </number-panels>

    <!-- Vertical Alignments of Panels -->
    <!-- Produce temporary space-separated list, with trailing space     -->
    <!-- Look up into enclosing "sbsgroup" if none given on "sidebyside" -->
    <!-- Error-check attribute values as $valigns string gets unpacked   -->
    <xsl:variable name="valigns">
        <xsl:choose>
            <!-- individual sbs takes priority -->
            <xsl:when test="@valigns">
                <xsl:value-of select="concat(normalize-space(@valigns), ' ')" />
            </xsl:when>
            <!-- singular form is convenience -->
            <xsl:when test="@valign">
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat(normalize-space(@valign), ' ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
            </xsl:when>
            <!-- look to enclosing sbsgroup -->
            <xsl:when test="parent::sbsgroup[@valigns]">
                <xsl:value-of select="concat(normalize-space(parent::sbsgroup/@valigns), ' ')" />
            </xsl:when>
            <!-- look to enclosing sbsgroup for singular convenience -->
            <xsl:when test="parent::sbsgroup[@valign]">
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat(normalize-space(parent::sbsgroup/@valign), ' ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
            </xsl:when>
            <!-- default: place all panels at the top   -->
            <!-- NB: space at end of $text is separator -->
            <xsl:otherwise>
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="'top '" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
             </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="$sbsdebug">
        <xsl:message>VA:<xsl:value-of select="$valigns" />:VA</xsl:message>
    </xsl:if>
    <!-- check length (author-supplied could be wrong) -->
    <xsl:variable name="nspaces-valigns" select="string-length($valigns) - string-length(translate($valigns, ' ', ''))" />
    <xsl:choose>
        <xsl:when test="$nspaces-valigns &lt; $number-panels">
            <xsl:message>PTX:FATAL:   a &lt;sidebyside&gt; or &lt;sbsgroup&gt; does not have enough "@valigns" (maybe you did not specify enough?)</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
            <xsl:message terminate="yes">             That's fatal.  Sorry.  Quitting...</xsl:message>
        </xsl:when>
        <xsl:when test="$nspaces-valigns &gt; $number-panels">
            <xsl:message>PTX:WARNING: a &lt;sidebyside&gt; or &lt;sbsgroup&gt; has extra "@valigns" (did you confuse singular and plural attribute names?)</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
    </xsl:choose>
    <!-- unpack with an error-check on attribute values -->
    <!-- RTF formation happens with unpacking           -->
    <xsl:call-template name="decompose-valigns">
        <xsl:with-param name="valigns" select="$valigns" />
    </xsl:call-template>


    <!-- Margins and Widths -->
    <!-- clean up and organize widths                             -->
    <!-- Always produces space-separated list with trailing space -->
    <!-- Error-check as $widths string gets depleted below        -->
    <xsl:variable name="normalized-widths">
        <xsl:choose>
            <!-- individual sbs takes priority -->
            <xsl:when test="@widths">
                <xsl:value-of select="concat(normalize-space(@widths), ' ')" />
            </xsl:when>
            <!-- singular form is convenience -->
            <xsl:when test="@width">
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat(normalize-space(@width), ' ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
            </xsl:when>
            <!-- look to enclosing sidebyside group -->
            <xsl:when test="parent::sbsgroup[@widths]">
                <xsl:value-of select="concat(normalize-space(parent::sbsgroup/@widths), ' ')" />
            </xsl:when>
            <!-- look to enclosing sidebyside group for singular convenience -->
            <xsl:when test="parent::sbsgroup[@width]">
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat(normalize-space(parent::sbsgroup/@width), ' ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
            </xsl:when>
            <!-- defer default computation post-margins      -->
            <!-- NB: "undetermined" widths is a single space -->
            <xsl:otherwise>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- clean up margins -->
    <xsl:variable name="normalized-margins">
        <xsl:choose>
            <!-- individual sbs takes priority -->
            <xsl:when test="@margins">
                <xsl:value-of select="normalize-space(@margins)" />
            </xsl:when>
            <!-- look to enclosing sidebyside group -->
            <xsl:when test="parent::sbsgroup[@margins]">
                <xsl:value-of select="normalize-space(parent::sbsgroup/@margins)" />
            </xsl:when>
            <!-- default will make pleasing layout: -->
            <!--   (a) for one panel, no settings -->
            <!--   (b) no margin given, all sensible widths -->
            <xsl:otherwise>
                <xsl:text>auto</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- construct left and right margins, possibly identical      -->
    <!-- these may be 'auto' and get updated later (hence "early") -->
    <xsl:variable name="left-margin-early">
        <xsl:choose>
            <xsl:when test="contains($normalized-margins, ' ')">
                <xsl:value-of select="substring-before($normalized-margins, ' ')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$normalized-margins" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="right-margin-early">
        <xsl:choose>
            <xsl:when test="contains($normalized-margins, ' ')">
                <xsl:value-of select="substring-after($normalized-margins, ' ')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$normalized-margins" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- total widths used/available    -->
    <!-- no attributes, use 100         -->
    <!-- no width, subtract two margins -->
    <!-- widths given, sum them         -->
    <!-- no percent sign, just internal -->
    <!-- TOD: error-check that sum is 100 or less -->
    <xsl:variable name="sum-widths">
        <xsl:choose>
            <xsl:when test="$normalized-widths = ' ' and $normalized-margins = 'auto'">
                <xsl:text>100</xsl:text>
            </xsl:when>
            <xsl:when test="$normalized-widths = ' '">
                <xsl:value-of select="100 - substring-before($left-margin-early, '%') - substring-before($right-margin-early, '%')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="sum-percentages">
                    <xsl:with-param name="percent-list" select="$normalized-widths" />
                    <xsl:with-param name="sum" select="'0'" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- have width totals, determine margins         -->
    <!-- automatic creates margins that will be half -->
    <!-- of the subsequent space-width computation   -->
    <!-- Input assumes % present (unless 'auto')     -->
    <!-- Output preserves % on result                -->
    <xsl:variable name="left-margin">
        <xsl:choose>
            <xsl:when test="$number-panels = 0">
                <xsl:text>0%</xsl:text>
            </xsl:when>
            <xsl:when test="$normalized-margins = 'auto'">
                <xsl:value-of select="(100 - $sum-widths) div (2 * $number-panels)" />
                <xsl:text>%</xsl:text>
            </xsl:when>
            <!-- TODO: condition on % present, let otherwise report failure -->
            <xsl:otherwise>
                <xsl:value-of select="$left-margin-early" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="right-margin">
        <xsl:choose>
            <xsl:when test="$number-panels = 0">
                <xsl:text>0%</xsl:text>
            </xsl:when>
            <xsl:when test="$normalized-margins = 'auto'">
                <xsl:value-of select="(100 - $sum-widths) div (2 * $number-panels)" />
                <xsl:text>%</xsl:text>
            </xsl:when>
            <!-- TODO: condition on % present, let otherwise report failure -->
            <xsl:otherwise>
                <xsl:value-of select="$right-margin-early" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="$sbsdebug">
        <xsl:message>M:<xsl:value-of select="$left-margin" />:<xsl:value-of select="$right-margin" />:M</xsl:message>
    </xsl:if>
    <!-- error check for reasonable values -->
    <!-- When there are three values, the "left" margin still -->
    <!-- has a space character to split on (which of course,  -->
    <!-- we don't do!).  It seems to survive until here.      -->
    <xsl:if test="contains($right-margin, ' ')">
        <xsl:message>PTX:ERROR:   it appears that a &lt;sidebyside&gt; has a @margins attribute with three or more values ("<xsl:value-of select="@margins" />").  There should be at most two values (a left margin and a right margin).  Results may be unpredictable.</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <xsl:if test="(substring-before($left-margin, '%') &lt; 0) or (substring-before($left-margin, '%') &gt; 100)">
        <xsl:message>PTX:ERROR:   left margin of a &lt;sidebyside&gt; ("<xsl:value-of select="$left-margin" />") is outside the interval [0%, 100%], (this may be computed, check consistency of "@margins" and "@widths")</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <xsl:if test="(substring-before($right-margin, '%') &lt; 0) or (substring-before($right-margin, '%') &gt; 100)">
        <xsl:message>PTX:ERROR:   right margin of a &lt;sidebyside&gt; ("<xsl:value-of select="$right-margin" />") is outside the interval [0%, 100%], (this may be computed, check consistency of "@margins" and "@widths")</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <!-- Add to RTF -->
    <left-margin>
        <xsl:value-of select="$left-margin" />
    </left-margin>
    <right-margin>
        <xsl:value-of select="$right-margin" />
    </right-margin>

    <!-- if no widths given, distribute excess beyond margins -->
    <!-- NB: with percent signs, blank at end always          -->
    <!-- Error-check as $widths string gets depleted below    -->
    <xsl:variable name="widths">
        <xsl:choose>
            <xsl:when test="$normalized-widths = ' '">
                <xsl:variable name="common-width" select="(100 - substring-before($left-margin, '%') - substring-before($right-margin, '%')) div $number-panels" />
                <!-- transfer as percentages (abstract), with blank at end -->
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat($common-width, '% ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
             </xsl:when>
             <xsl:otherwise>
                <xsl:value-of select="$normalized-widths" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="$sbsdebug">
        <xsl:message>W:<xsl:value-of select="$widths" />:W</xsl:message>
    </xsl:if>
    <!-- check length (author-supplied could be wrong) -->
    <xsl:variable name="nspaces-widths" select="string-length($widths) - string-length(translate($widths, ' ', ''))" />
    <xsl:choose>
        <xsl:when test="$nspaces-widths &lt; $number-panels">
            <xsl:message>PTX:FATAL:   a &lt;sidebyside&gt; or &lt;sbsgroup&gt; does not have enough "@widths" (maybe you did not specify enough?)</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
            <xsl:message terminate="yes">             That's fatal.  Sorry.  Quitting...</xsl:message>
        </xsl:when>
        <xsl:when test="$nspaces-widths &gt; $number-panels">
            <xsl:message>PTX:WARNING: a &lt;sidebyside&gt; or &lt;sbsgroup&gt; has extra "@widths" (did you confuse singular and plural attribute names?)</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
    </xsl:choose>
    <!-- unpack with an error-check on attribute values -->
    <!-- RTF formation happens with unpacking           -->
    <xsl:call-template name="decompose-widths">
        <xsl:with-param name="widths" select="$widths" />
    </xsl:call-template>

    <!-- Spacing Between Panels -->
    <!-- compute common spacing between panels, as percent -->
    <!-- subtract margins and sum-widths from 100,         -->
    <!-- and then distribute to n - 1 spaces               -->
    <!-- includes % for external use                       -->
    <xsl:variable name="space-width">
        <xsl:choose>
            <xsl:when test="$number-panels &lt; 2">
                <!-- no spaces, avoids all division by zero -->
                <xsl:text>0</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="(100 - $sum-widths  - substring-before($left-margin, '%') - substring-before($right-margin, '%')) div ($number-panels - 1)" />
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>%</xsl:text>
    </xsl:variable>
    <xsl:if test="$sbsdebug">
        <xsl:message>SW:<xsl:value-of select="$space-width" />:SW</xsl:message>
    </xsl:if>
    <!-- overall error check on space width -->
    <xsl:choose>
        <xsl:when test="substring-before($space-width, '%') &lt; 0">
            <xsl:message>PTX:ERROR:   computed space between panels of a &lt;sidebyside&gt; ("<xsl:value-of select="$space-width" />") is negative (this value is computed, check consistency of "@margins" and "@widths")</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
        <xsl:when test="substring-before($space-width, '%') = 'NaN'">
            <xsl:message>PTX:ERROR:   computed space between panels of a &lt;sidebyside&gt; is not a number (this value is computed, check that margins ("<xsl:value-of select="$left-margin" />, <xsl:value-of select="$right-margin" />") and widths ("<xsl:value-of select="$widths" />") are percentages of the form "nn%")</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
    </xsl:choose>
    <!-- Add to RTF -->
    <space-width>
        <xsl:value-of select="$space-width" />
    </space-width>
</xsl:template>

<!-- ########################### -->
<!-- SidebySide Layout Utilities -->
<!-- ########################### -->

<!-- From a space-separated list of vertical alignments -->
<!-- create error-checked result tree fragment          -->
<xsl:template name="decompose-valigns">
    <xsl:param name="valigns" />
    <xsl:variable name="the-valign" select="substring-before($valigns, ' ')" />
    <xsl:if test="not($the-valign = '')">
        <!-- error-check, since list bypasses schema -->
        <!-- "top" is default, so check first        -->
        <xsl:choose>
            <xsl:when test="$the-valign = 'top'" />
            <xsl:when test="$the-valign = 'bottom'" />
            <xsl:when test="$the-valign = 'middle'" />
            <xsl:otherwise>
                <xsl:message>PTX:ERROR:   @valign(s) ("<xsl:value-of select="$the-valign" />") in &lt;sidebyside&gt; or &lt;sbsgroup&gt; is not "top," "middle" or "bottom"</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:otherwise>
        </xsl:choose>
        <!-- okay, output element -->
        <valign>
            <xsl:value-of select="$the-valign" />
        </valign>
        <!-- recurse on trailing -->
        <xsl:call-template name="decompose-valigns">
            <xsl:with-param name="valigns" select="substring-after($valigns, ' ')" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- From a space-separated list of widths (percentages) -->
<!-- create error-checked result tree fragment           -->
<xsl:template name="decompose-widths">
    <xsl:param name="widths" />
    <xsl:variable name="the-width" select="substring-before($widths, ' ')" />
    <xsl:if test="not($the-width = '')">
        <!-- error-check, since author-supplied could be wild -->
        <xsl:choose>
            <xsl:when test="substring-before($the-width, '%') &lt; 0">
                <xsl:message>PTX:ERROR:   panel width ("<xsl:value-of select="$the-width" />") in a &lt;sidebyside&gt; or &lt;sbsgroup&gt; is negative (this may be computed, check "@margin(s)" and "@width(s)")</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:when>
            <xsl:when test="substring-before($the-width, '%') &gt; 100">
                <xsl:message>PTX:ERROR:   panel width ("<xsl:value-of select="$the-width" />") in a &lt;sidebyside&gt; or &lt;sbsgroup&gt; is bigger than 100% (this may be computed, check "@margin(s)" and "@width(s)")</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:when>
        </xsl:choose>
        <!-- output element -->
        <width>
            <xsl:value-of select="$the-width" />
        </width>
        <!-- recurse on trailing -->
        <xsl:call-template name="decompose-widths">
            <xsl:with-param name="widths" select="substring-after($widths, ' ')" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- recursive template to sum percentages         -->
<!-- input: a space-separated list, with %'s'      -->
<!-- NB: expect trailing space as sentinel for end -->
<!-- Output: total, without %, -common use only    -->
<xsl:template name="sum-percentages">
    <xsl:param name="percent-list" />
    <xsl:param name="sum" />
    <xsl:choose>
        <xsl:when test="$percent-list = ''">
            <xsl:value-of select="$sum" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="sum-percentages">
                <xsl:with-param name="percent-list" select="substring-after($percent-list, ' ')" />
                <xsl:with-param name="sum" select="$sum + substring-before($percent-list, '%')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ######################## -->
<!-- SideBySide Main Template -->
<!-- ######################## -->

<xsl:template match="sidebyside">
    <xsl:param name="b-original" select="true()" />

    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters" />
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />

    <!-- local names of objects? -->
    <!-- below useful for debugging, worth keeping for a while, 2017-07 -->
    <!--
    <xsl:message>N:<xsl:value-of select="$layout/number-panels" />:N</xsl:message>
    <xsl:message>
        <xsl:text>VA:</xsl:text>
        <xsl:for-each select="$layout/valign">
            <xsl:value-of select="." />
            <xsl:text> </xsl:text>
        </xsl:for-each>
        <xsl:text>:VA</xsl:text>
    </xsl:message>
    <xsl:message>
        <xsl:text>W:</xsl:text>
        <xsl:for-each select="$layout/width">
            <xsl:value-of select="." />
            <xsl:text> </xsl:text>
        </xsl:for-each>
        <xsl:text>:W</xsl:text>
    </xsl:message>
    <xsl:message>
        <xsl:text>M:</xsl:text>
        <xsl:value-of select="$layout/margins" />
        <xsl:text>:M</xsl:text>
    </xsl:message>
    <xsl:message>
        <xsl:text>SW:</xsl:text>
        <xsl:value-of select="$layout/space-width" />
        <xsl:text>:SW</xsl:text>
    </xsl:message>
    <xsl:message>~~~~~~~~~~~~~~~~~~~~</xsl:message>
     -->

    <!-- "paragraphs" deprecated within sidebyside, 2018-05-02 -->
    <!-- jsxgraph deprecated?  Check                           -->

     <xsl:variable name="panels" select="p|pre|ol|ul|dl|program|console|poem|audio|video|interactive|slate|exercise|image|figure|table|listing|list|tabular|stack|jsxgraph|paragraphs" />

    <!-- We build up lists of various parts of a panel      -->
    <!-- It has setup (LaTeX), headers (titles), panels,    -->
    <!-- and captions.  These then go to "compose-panels".  -->
    <!-- Implementations need to define modal templates     -->
    <!--   panel-header, panel-panel, panel-caption         -->
    <!-- The parameters passed to each is the union of what -->
    <!-- is needed for LaTeX and HTML implementations.      -->
    <!-- Final results are collectively sent to modal       -->
    <!--   compose-panels                                   -->
    <!-- template to be arranged                            -->
    <!-- TODO: Instead we could pass the $layout to the four,    -->
    <!-- and infer the $panel-number in the receiving templates. -->

    <xsl:variable name="panel-panels">
        <xsl:for-each select="$panels">
            <!-- context is now a particular panel -->
            <xsl:variable name="panel-number" select="count(preceding-sibling::*) + 1" />
            <xsl:apply-templates select="." mode="panel-panel">
                <xsl:with-param name="b-original" select="$b-original" />
                <xsl:with-param name="width" select="$layout/width[$panel-number]" />
                <xsl:with-param name="left-margin" select="$layout/left-margin" />
                <xsl:with-param name="right-margin" select="$layout/right-margin" />
                <xsl:with-param name="valign" select="$layout/valign[$panel-number]" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:variable>

    <!-- now collect components into output wrappers -->
    <xsl:apply-templates select="." mode="compose-panels">
        <xsl:with-param name="b-original" select="$b-original" />

        <xsl:with-param name="layout" select="$layout" />
        <xsl:with-param name="panels" select="$panel-panels" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="post-sidebyside"/>
</xsl:template>

<!-- ########################################### -->
<!-- Side-By-Side Group (sbsgroup) main template -->
<!-- ########################################### -->

<!-- A side-by-side group ("sbsgroup") is a wrapper    -->
<!-- around a sequence of "sidebyside".  It provides   -->
<!-- a place to specify common parameters for several  -->
<!-- side-by-side, for uniformity.  Also sub-captions  -->
<!-- should respect the grouping.  It is as pure a     -->
<!-- container as there can be.  Output is to just     -->
<!-- pile them up vertically.  Note, layout parameters -->
<!-- on enclosed "sidebyside" take precedence, and     -->
<!-- it is the layout template for each sidebyside     -->
<!-- that goes out to the enclosing group to get them  -->

<!-- default wrapper does nothing, output modes may    -->
<!-- optionally provide some containing structure      -->
<xsl:template name="sbsgroup-wrapper">
    <xsl:param name="sbsgroup-content"/>
    <xsl:copy-of select="$sbsgroup-content"/>
</xsl:template>

<xsl:template match="sbsgroup">
    <xsl:variable name="data">
        <xsl:apply-templates select="sidebyside" />
        <xsl:apply-templates select="." mode="post-sbsgroup"/>
    </xsl:variable>
    <xsl:call-template name="sbsgroup-wrapper">
        <xsl:with-param name="sbsgroup-content" select="$data"/>
    </xsl:call-template>
</xsl:template>

<!-- Since stackable items do not carry titles or captions,   -->
<!-- their templates do the right thing.  Items that normally -->
<!-- could go nline within a paragraph without any spacing    -->
<!-- will be preceded by a \par in their LaTeX representation -->
<!-- to get them onto a line of their own                     -->
<!-- 2019-06-28: parameters only consumed by HTML templates   -->
<xsl:template match="sidebyside/stack">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="width" />

    <xsl:apply-templates select="tabular|image|p|pre|ol|ul|dl|audio|video|interactive|slate|program|console|exercise">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="width" select="$width"/>
    </xsl:apply-templates>
</xsl:template>

<!-- ################# -->
<!-- Post-Layout Hooks -->
<!-- ################# -->

<!-- We may wish to add information below a "sidebyside"    -->
<!-- or a "sbsgroup".  Motivation is keyboard shortcut help -->
<!-- for interactive accessible diagrams out of PreFigure   -->
<!-- code with the diagcess JS library.  See invocations    -->
<!-- above, with no-op stubs here. -->

<xsl:template match="sidebyside" mode="post-sidebyside"/>
<xsl:template match="sbsgroup" mode="post-sbsgroup"/>

<!-- ############## -->
<!-- List Utilities -->
<!-- ############## -->

<!-- A list item may be:                                        -->
<!--   * unstructured, like a sentence of a "p"                 -->
<!--   * structured into paragraphs, sublists, etc.             -->
<!-- For the first, we cannot automatically strip space         -->
<!-- To be flexible about the second, we kill interstitial text -->
<xsl:template match="li[p|ol|ul|dl]/text()">
    <xsl:variable name="text" select="normalize-space(.)" />
    <xsl:if test="$text">
        <xsl:message>PTX:WARNING: Unstructured content within a list item is being ignored ("<xsl:value-of select="$text" />")</xsl:message>
         <xsl:apply-templates select=".." mode="location-report" />
    </xsl:if>
</xsl:template>

<!-- List Levels -->
<!-- Utility templates to determine the depth      -->
<!-- of a list, relative to nesting in other lists -->

<!-- We determine the depth of an unordered     -->
<!-- list, relative only to other unordered     -->
<!-- lists in a nesting, so as to determine     -->
<!-- the right label to apply, esp. as defaults -->
<!-- The recursive template should be called    -->
<!-- without a level, since it defaults to zero -->
<xsl:template match="ul" mode="unordered-list-level">
    <!-- Start with level zero, and increment on successive calls -->
    <xsl:param name="level" select="0"/>
    <xsl:choose>
        <!-- Another unordered list above, add one and recurse -->
        <xsl:when test="ancestor::ul">
            <xsl:apply-templates select="ancestor::ul[1]" mode="unordered-list-level">
                <xsl:with-param name="level" select="$level + 1" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- No unordered list above, done, so return level -->
        <xsl:otherwise>
            <xsl:value-of select="$level" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Ordered lists follow the same strategy,           -->
<!-- except we implement exercises and references      -->
<!-- elements as ordered lists, so we need to absorb   -->
<!-- them into the general treatment of nested lists   -->
<!-- They do only occur as top-level elements, so that -->
<!-- assumption allows for some economy                -->
<xsl:template match="ol" mode="ordered-list-level">
    <xsl:param name="level" select="0"/>
    <xsl:choose>
        <!-- Since exercises divisions and references are top-level -->
        <!-- ordered lists, when these are the only interesting     -->
        <!-- ancestor, we add one to the level and return           -->
        <xsl:when test="(ancestor::exercises or ancestor::worksheet or ancestor::handout or ancestor::reading-questions or ancestor::references) and not(ancestor::ol)">
            <xsl:value-of select="$level + 1" />
        </xsl:when>
        <xsl:when test="ancestor::ol">
            <xsl:apply-templates select="ancestor::ol[1]" mode="ordered-list-level">
                <xsl:with-param name="level" select="$level + 1" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$level" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Exercises and References are        -->
<!-- specialized top-level ordered lists -->
<xsl:template match="exercises|worksheet|handout|reading-questions|references" mode="ordered-list-level">
    <xsl:value-of select="0" />
</xsl:template>

<!-- To indent properly in markdown, we  -->
<!-- need to count every type of list    -->
<xsl:template match="*" mode="list-level">
    <xsl:param name="level" select="0" />
    <xsl:choose>
        <xsl:when test="ancestor-or-self::ol or ancestor-or-self::ul or ancestor-or-self::dl">
            <xsl:choose>
                <!-- at a node to count -->
                <xsl:when test="self::ol or self::ul or self::dl">
                    <xsl:apply-templates select="parent::*" mode="list-level">
                        <xsl:with-param name="level" select="$level + 1" />
                    </xsl:apply-templates>
                </xsl:when>
                <!-- go up a level w/out incrementing-->
                <xsl:otherwise>
                    <xsl:apply-templates select="parent::*" mode="list-level">
                        <xsl:with-param name="level" select="$level" />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- now done, report level -->
        <xsl:otherwise>
            <xsl:value-of select="$level" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Labels of unordered list have formatting codes, which -->
<!-- we detect here and pass on to other more specialized  -->
<!-- templates for implementation specifics                -->
<!-- disc, circle, square or blank are the options         -->
<!-- Default order: disc, circle, square, disc             -->
<xsl:template match="ul" mode="format-code">
    <xsl:choose>
        <xsl:when test="@marker">
            <xsl:choose>
                <xsl:when test="@marker='disc'">disc</xsl:when>
                <xsl:when test="@marker='circle'">circle</xsl:when>
                <xsl:when test="@marker='square'">square</xsl:when>
                <xsl:when test="@marker=''">none</xsl:when>
                <xsl:otherwise>
                    <xsl:message>ptx:ERROR: unordered list label (<xsl:value-of select="@marker" />) not recognized</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="level">
                <xsl:apply-templates select="." mode="unordered-list-level" />
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$level='0'">disc</xsl:when>
                <xsl:when test="$level='1'">circle</xsl:when>
                <xsl:when test="$level='2'">square</xsl:when>
                <xsl:when test="$level='3'">disc</xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR: unordered list is more than 4 levels deep (at level <xsl:value-of select="$level" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- CSS class for multi-column lists -->
<!-- Context is element with potential "cols" attribute -->
<!-- Return value is "colsN" with 2 <= N <= 6           -->
<!-- @cols absent produces no result (i.e. classless)   -->
<!-- @cols = 1 produces no result (i.e. classless)      -->
<!-- Error message if out-of-range, could be made fatal -->
<!-- Schema should enforce this restriction also        -->
<xsl:template match="ol|ul|exercisegroup" mode="number-cols-CSS-class">
    <xsl:choose>
        <xsl:when test="not(@cols)"/>
        <xsl:when test="@cols = 1"/>
        <xsl:when test="(@cols = 2) or (@cols = 3) or (@cols = 4) or (@cols = 5) or (@cols = 6)">
            <xsl:text>cols</xsl:text>
            <xsl:value-of select="@cols" />
            <xsl:text> multicolumn</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR:   @cols attribute of lists or exercise groups, must be between 1 and 6 (inclusive), not "cols=<xsl:value-of select="@cols" />"</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################## -->
<!-- Exercise Utilities -->
<!-- ################## -->

<!-- Exercises, projects and tasks, generally have "statement",    -->
<!-- "hint", "answer", and "solution".  Switches control           -->
<!-- appearance in the main matter and in solution lists.          -->
<!--                                                               -->
<!-- But they are surrounded by infrastructure:  number and title, -->
<!-- exercise group with introduction and conclusion, division     -->
<!-- headings.  If switches make all the content disappear within  -->
<!-- some infrastructure, then the infrastructure becomes          -->
<!-- superfluous.  So we provide a hierarchy of templates to       -->
<!-- determine if structure and content yield output.              -->

<!-- Bottom-up, a "traditional" exercise is clearest, so first.   -->
<!-- Strategy is to produce non-empty output if the item would    -->
<!-- normally produce some *real* output.                         -->

<!-- "exercise", not WeBWorK or MyOpenMath, plus project-like. -->
<!-- Easiest to switch on structured by task, or simpler       -->
<!-- "traditional" exercise.                                   -->

<xsl:template match="exercise[not(webwork-reps or myopenmath)]|&PROJECT-LIKE;" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:variable name="admitted">
        <xsl:apply-templates select="." mode="determine-admission">
            <xsl:with-param name="admit" select="$admit"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="b-admitted" select="boolean($admitted = 'yes')"/>

    <xsl:choose>
        <!-- return nothing if not admitted -->
        <xsl:when test="not($b-admitted)"/>
        <!-- recurse down into "task" via two templates above -->
        <xsl:when test="task">
            <xsl:apply-templates select="task" mode="dry-run">
                <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- simple "traditional" exercise -->
        <xsl:otherwise>
            <xsl:if test="$b-has-statement or ($b-has-hint and hint) or ($b-has-answer and answer) or ($b-has-solution and solution)">
                <xsl:text>X</xsl:text>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- We explicitly burrow down into tasks, since when we produce -->
<!-- the solutions, the labels on the tasks are infrastructure   -->
<!-- and we need the precision of knowing just which "task"      -->
<!-- harbor solutions (and which do not).                        -->

<!-- terminal (leaf) tasks -->
<xsl:template match="task[not(task)]" mode="dry-run">
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:if test="$b-has-statement or ($b-has-hint and hint) or ($b-has-answer and answer) or ($b-has-solution and solution)">
        <xsl:text>X</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Simply pass through intermediate task since they  -->
<!-- cannot harbor solutions (says schema) -->
<xsl:template match="task[task]" mode="dry-run">
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:apply-templates select="task" mode="dry-run">
        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
    </xsl:apply-templates>
</xsl:template>

<!-- WeBWorK are exceptional.  We use the "webwork-reps" element -->
<!-- added by the assembly routine to examine "static" for the   -->
<!-- indication of existence of solutions - even if the problem  -->
 <!-- is "live" in interactive output.  Note that "stage" is     -->
 <!-- similar to "task" above, we need to carefully burrow down  -->
 <!-- into them to get indications of infrastructure when        -->
 <!-- producing output.                                          -->

<!-- WeBWorK exercise, structured by stages or not -->
<xsl:template match="exercise[webwork-reps]" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:variable name="admitted">
        <xsl:apply-templates select="." mode="determine-admission">
            <xsl:with-param name="admit" select="$admit"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="b-admitted" select="boolean($admitted = 'yes')"/>

    <xsl:choose>
        <!-- return nothing if not admitted -->
        <xsl:when test="not($b-admitted)"/>
        <xsl:when test="webwork-reps/static/task|webwork-reps/static/stage">
            <xsl:apply-templates select="webwork-reps/static/task|webwork-reps/static/stage" mode="dry-run">
                <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:if test="$b-has-statement or ($b-has-hint and webwork-reps/static/hint) or ($b-has-answer and webwork-reps/static/answer) or ($b-has-solution and webwork-reps/static/solution)">
                <xsl:text>X</xsl:text>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- webwork stage is like a problem by itself-->
<xsl:template match="exercise/webwork-reps/static/stage" mode="dry-run">
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:if test="$b-has-statement or ($b-has-hint and hint) or ($b-has-answer and answer) or ($b-has-solution and solution)">
        <xsl:text>X</xsl:text>
    </xsl:if>
</xsl:template>

<!-- 2020-08-31: MyOpenMath is not really implemented fully, this is a -->
<!-- marker that will just prevent thse problems from appearing at all -->
<xsl:template match="exercise[myopenmath]" mode="dry-run"/>


<!-- Now we can tell is a given exercise (or project-like) will -->
<!-- generate some solutions, relative to the various switches  -->
<!-- in play.  So we now decide if various bits of surrounding  -->
<!-- infrastructure need repeating, since they do, or do not,   -->
<!-- contain exercises which will produce solutions.            -->


<!-- An "exercisegroup" potentially has an "introduction"  -->
<!-- and "conclusion" as infrastructure, and can only      -->
<!-- contain divisional "exercise" as varying items        -->
<!-- In a way, this is like an "exercise", it has content  -->
<!-- that is like a "statement", so a "dry-run" is checked -->
<!-- before outputting its introduction/conclusion         -->
<xsl:template match="exercisegroup" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:apply-templates select="exercise" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
    </xsl:apply-templates>
</xsl:template>

<!-- A "subexercises" potentially has an "introduction"    -->
<!-- and "conclusion" as infrastructure, and can only      -->
<!-- contain divisional "exercise" as varying items        -->
<!-- in addition to possible "exercisegroup"               -->
<!-- In a way, this is like an "exercisegroup", it has     -->
<!-- content that is like a "statement", so a "dry-run" is -->
<!-- checked before outputting its introduction/conclusion -->
<xsl:template match="subexercises" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:apply-templates select="exercise|exercisegroup" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
    </xsl:apply-templates>
</xsl:template>

<!-- Now specialized divisions that can hold "exercise".  These      -->
<!-- typically receive many parameters (~20) but only react/consider -->
<!-- the ones relevant to the type of division being investigated.   -->

<xsl:template match="exercises" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-divisional-statement" />
    <xsl:param name="b-divisional-hint" />
    <xsl:param name="b-divisional-answer" />
    <xsl:param name="b-divisional-solution" />

    <xsl:apply-templates select=".//exercise" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-divisional-statement" />
        <xsl:with-param name="b-has-hint"      select="$b-divisional-hint" />
        <xsl:with-param name="b-has-answer"    select="$b-divisional-answer" />
        <xsl:with-param name="b-has-solution"  select="$b-divisional-solution" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="worksheet" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-worksheet-statement" />
    <xsl:param name="b-worksheet-hint" />
    <xsl:param name="b-worksheet-answer" />
    <xsl:param name="b-worksheet-solution" />
    <xsl:param name="b-project-statement" />
    <xsl:param name="b-project-hint" />
    <xsl:param name="b-project-answer" />
    <xsl:param name="b-project-solution" />

    <xsl:apply-templates select=".//exercise" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-worksheet-statement" />
        <xsl:with-param name="b-has-hint"      select="$b-worksheet-hint" />
        <xsl:with-param name="b-has-answer"    select="$b-worksheet-answer" />
        <xsl:with-param name="b-has-solution"  select="$b-worksheet-solution" />
    </xsl:apply-templates>
    <xsl:apply-templates select=".//activity|.//exploration|.//investigation|.//project" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-project-statement" />
        <xsl:with-param name="b-has-hint"      select="$b-project-hint" />
        <xsl:with-param name="b-has-answer"    select="$b-project-answer" />
        <xsl:with-param name="b-has-solution"  select="$b-project-solution" />
    </xsl:apply-templates>

</xsl:template>

<xsl:template match="reading-questions" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-reading-statement" />
    <xsl:param name="b-reading-hint" />
    <xsl:param name="b-reading-answer" />
    <xsl:param name="b-reading-solution" />

    <xsl:apply-templates select="exercise" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-reading-statement" />
        <xsl:with-param name="b-has-hint"      select="$b-reading-hint" />
        <xsl:with-param name="b-has-answer"    select="$b-reading-answer" />
        <xsl:with-param name="b-has-solution"  select="$b-reading-solution" />
    </xsl:apply-templates>
</xsl:template>

<!-- An arbitrary division will have a heading as infrastructure.     -->
<!-- We drill down into the division at any depth looking for objects -->
<!-- based on the switches that control them.  This means we do not   -->
<!-- have to examine all possible subdivisions, both traditional      -->
<!-- and specialized.  Instead, we just pass through them.  But we do -->
<!-- need to be careful about sort of division is being considered    -->
<!-- and what switches are passed along.                              -->
<xsl:template match="part|chapter|section|subsection|subsubsection" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-inline-statement" />
    <xsl:param name="b-inline-answer" />
    <xsl:param name="b-inline-hint" />
    <xsl:param name="b-inline-solution" />
    <xsl:param name="b-divisional-statement" />
    <xsl:param name="b-divisional-answer" />
    <xsl:param name="b-divisional-hint" />
    <xsl:param name="b-divisional-solution" />
    <xsl:param name="b-worksheet-statement" />
    <xsl:param name="b-worksheet-answer" />
    <xsl:param name="b-worksheet-hint" />
    <xsl:param name="b-worksheet-solution" />
    <xsl:param name="b-reading-statement" />
    <xsl:param name="b-reading-answer" />
    <xsl:param name="b-reading-hint" />
    <xsl:param name="b-reading-solution" />
    <xsl:param name="b-project-statement" />
    <xsl:param name="b-project-answer" />
    <xsl:param name="b-project-hint" />
    <xsl:param name="b-project-solution" />

    <xsl:apply-templates select=".//exercise[boolean(&INLINE-EXERCISE-FILTER;)]" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-inline-statement" />
        <xsl:with-param name="b-has-answer"    select="$b-inline-answer" />
        <xsl:with-param name="b-has-hint"      select="$b-inline-hint" />
        <xsl:with-param name="b-has-solution"  select="$b-inline-solution" />
    </xsl:apply-templates>
    <xsl:apply-templates select=".//exercises//exercise" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-divisional-statement" />
        <xsl:with-param name="b-has-answer"    select="$b-divisional-answer" />
        <xsl:with-param name="b-has-hint"      select="$b-divisional-hint" />
        <xsl:with-param name="b-has-solution"  select="$b-divisional-solution" />
    </xsl:apply-templates>
    <xsl:apply-templates select=".//worksheet//exercise" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-worksheet-statement" />
        <xsl:with-param name="b-has-answer"    select="$b-worksheet-answer" />
        <xsl:with-param name="b-has-hint"      select="$b-worksheet-hint" />
        <xsl:with-param name="b-has-solution"  select="$b-worksheet-solution" />
    </xsl:apply-templates>
    <xsl:apply-templates select=".//reading-questions//exercise" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-reading-statement" />
        <xsl:with-param name="b-has-answer"    select="$b-reading-answer" />
        <xsl:with-param name="b-has-hint"      select="$b-reading-hint" />
        <xsl:with-param name="b-has-solution"  select="$b-reading-solution" />
    </xsl:apply-templates>
    <!-- &PROJECT-LIKE; "project|activity|exploration|investigation"> -->
    <xsl:apply-templates select=".//project|.//activity|.//exploration|.//investigation" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-project-statement" />
        <xsl:with-param name="b-has-answer"    select="$b-project-answer" />
        <xsl:with-param name="b-has-hint"      select="$b-project-hint" />
        <xsl:with-param name="b-has-solution"  select="$b-project-solution" />
    </xsl:apply-templates>
</xsl:template>

<!-- If not explicitly addressed in another template, dry-run returns      -->
<!-- empty. This is necessary when stacking headings in output from the    -->
<!-- solutions generator.  The preceding siblings are examined, and it     -->
<!-- may include elements that do not naturally does a dry-run inspection. -->
<!-- This wildcard match could make debugging harder, perhaps reporting    -->
<!-- the element from this template would be useful.                       -->
<xsl:template match="*" mode="dry-run"/>

<!-- This template is called for items in a printout that can have a   -->
<!-- workspace specified.  It is important that this sometimes returns -->
<!-- an empty string, since that is a signal to not construct some     -->
<!-- surrounding infrastructure to implement the necessary space.      -->
<xsl:template match="*" mode="sanitize-workspace">
    <!-- bail out quickly and empty if not on a printout     -->
    <!-- bail out if at a "task" that is not a terminal task -->
    <!-- we assume LaTeX will only request this template if  -->
    <!-- the publisher file allows it.                       -->
    <!-- NB: a blank workspace is used as a signal in "divisionexercise" -->
    <!--     in LaTeX conversion, via parameter #3 of the  environment   -->

    <xsl:if test="(ancestor::worksheet or ancestor::handout) and not(child::task)">
        <!-- First element with @workspace, confined to the printout   -->
        <!-- Could be empty node-set, which will be empty string later -->
        <xsl:variable name="raw-workspace">
            <xsl:choose>
                <!-- @workspace on the terminal task or exercise, if it has it. -->
                <!-- NB can't have children tasks by conditional above. -->
                <xsl:when test="self::task[@workspace] or self::exercise[@workspace]">
                    <xsl:value-of select="normalize-space(@workspace)"/>
                </xsl:when>
                <!-- task/exercise w/out workspace but @workspace on the first ancestor with it, if any -->
                <!-- This can happen for an exercise in an exercisegroup -->
                <xsl:when test="(self::task or self::exercise) and ancestor::*[@workspace][1]">
                    <xsl:value-of select="normalize-space(ancestor::*[@workspace][1]/@workspace)"/>
                </xsl:when>
                <!-- otherwise, @workspace on the element, if any -->
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space(@workspace)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- bail out empty if empty or absent -->
            <xsl:when test="$raw-workspace = ''"/>
            <!-- old-style fraction of a page, indicated by a % at end   -->
            <!-- warn and convert to inches based on 10-inch page height -->
            <!-- ( (percent div 100) * 10 inch = div 10 )                -->
            <xsl:when test="substring($raw-workspace, string-length($raw-workspace) - 0) = '%'">
                <xsl:variable name="approximate-inches" select="concat(substring($raw-workspace, 1, string-length($raw-workspace) - 1) div 10, 'in')"/>
                <xsl:value-of select="$approximate-inches"/>
                <xsl:message>PTX:WARNING:  as of 2020-03-17 worksheet exercises' workspace should be specified in 'in' or in 'cm'.  Approximating a page fraction of <xsl:value-of select="@workspace"/> by <xsl:value-of select="$approximate-inches"/>.</xsl:message>
                <xsl:apply-templates select="." mode="location-report"/>
            </xsl:when>
            <xsl:when test="substring($raw-workspace, string-length($raw-workspace) - 1) = 'in'">
                <xsl:value-of select="$raw-workspace"/>
            </xsl:when>
            <xsl:when test="substring($raw-workspace, string-length($raw-workspace) - 1) = 'cm'">
                <xsl:value-of select="$raw-workspace"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>PTX:ERROR:  a worksheet exercises', project-likes' or tasks' workspace should be specified with units of 'in' or 'cm', and not as "<xsl:value-of select="@workspace"/>".  Using a default of "2in".</xsl:message>
                <xsl:text>2in</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- We have a restrictive match above on a modal template,            -->
<!-- but it is employed with a wider variety of objects so we          -->
<!-- need an implementation that does nothing                          -->
<!-- We kill the worksheet @workspace option for WW exercises until    -->
<!-- we have a better understanding of just how this will be specified -->
<!-- A no-op, just remove to enable, but will need testing             -->
<xsl:template match="webwork-reps/static|webwork-reps/static/stage|exercisegroup|&SOLUTION-LIKE;" mode="sanitize-workspace"/>


<!-- Get an RTF element containing information about what components of an exercise -->
<!-- should be rendered based on its type and publisher settings                    -->
<xsl:template match="exercise|&PROJECT-LIKE;|task" mode="exercise-components-report">
    <xsl:variable name="exercise-type">
        <xsl:choose>
            <xsl:when test="self::task">project</xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="./@exercise-customization"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$exercise-type = 'inline'">
            <exercise-component-report has-hint="{$b-has-inline-hint}" has-answer="{$b-has-inline-answer}" has-solution="{$b-has-inline-solution}"/>
        </xsl:when>
        <xsl:when test="$exercise-type = 'project'">
            <exercise-component-report has-hint="{$b-has-project-hint}" has-answer="{$b-has-project-answer}" has-solution="{$b-has-project-solution}"/>
        </xsl:when>
        <xsl:when test="$exercise-type = 'divisional'">
            <exercise-component-report has-hint="{$b-has-divisional-hint}" has-answer="{$b-has-divisional-answer}" has-solution="{$b-has-divisional-solution}"/>
        </xsl:when>
        <xsl:when test="$exercise-type = 'worksheet'">
            <exercise-component-report has-hint="{$b-has-worksheet-hint}" has-answer="{$b-has-worksheet-answer}" has-solution="{$b-has-worksheet-solution}"/>
        </xsl:when>
        <xsl:when test="$exercise-type = 'reading'">
            <exercise-component-report has-hint="{$b-has-reading-hint}" has-answer="{$b-has-reading-answer}" has-solution="{$b-has-reading-solution}"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: can't determine exercise type</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ####################################### -->
<!-- Solutions Divisions, Content Generation -->
<!-- ####################################### -->

<!-- A light wrapper around the "solutions-generator" template (next). -->
<!-- We just examine the attributes describing a "solutions" division. -->
<!-- The division is one-off (not knowled), so we treat the            -->
<!-- introduction and conclusion as original                           -->
<xsl:template match="solutions" mode="solutions">
    <xsl:param name="heading-level"/>

    <!-- A "solutions" division may exist in the main matter  -->
    <!-- or the back matter.  When we generate a solution, we -->
    <!-- want to know which kind it is, so it can be labeled  -->
    <!-- so that a forward-reference is accurate.             -->
    <xsl:variable name="purpose">
        <xsl:choose>
            <xsl:when test="parent::backmatter">
                <xsl:text>backmatter</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>mainmatter</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- A "solutions" may have an @admit that indicates a subset -->
    <!-- of which exercises to admit. The default is 'all'        -->
    <xsl:variable name="admit">
        <xsl:choose>
            <xsl:when test="@admit">
                <xsl:value-of select="@admit"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>all</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:apply-templates select="introduction">
        <xsl:with-param name="b-original" select="true()" />
    </xsl:apply-templates>
    <!-- We call the solutions-generator one of two ways, either by     -->
    <!-- looking up a level, to the parent (jumping over "backmatter")  -->
    <!-- or by respecting a @scope attribute that specifies the parent. -->
    <!-- The "call" is identical, only the @select is different.        -->
    <!-- (Maybe there is a better way to use just one call?)            -->

    <xsl:choose>
        <xsl:when test="@scope">
            <!-- First check that the scope is reasonable, i.e. it -->
            <!-- exists and is one of the elements defined for the -->
            <!-- "solutions-generator" template                    -->
            <xsl:variable name="scope" select="id(@scope)"/>
            <xsl:if test="not($scope)">
                <xsl:message>PTX:WARNING: unresolved @scope ("<xsl:value-of select="@scope"/>") for a &lt;solutions&gt; division</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:if>
            <xsl:if test="not($scope/self::book|$scope/self::article|$scope/self::chapter|$scope/self::section|$scope/self::subsection|$scope/self::subsubsection|$scope/self::exercises|$scope/self::worksheet|$scope/self::reading-questions)">
                <xsl:message>PTX:ERROR: the @scope ("<xsl:value-of select="@scope"/>") of a &lt;solutions&gt; division is not a supported division.  If you think your attempt is reasonable, please make a feature request.  Results now will be unpredictable</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:if>

            <xsl:apply-templates select="$scope" mode="solutions-generator">
                <xsl:with-param name="purpose" select="$purpose" />
                <xsl:with-param name="admit"   select="$admit"/>
                <xsl:with-param name="heading-level" select="$heading-level"/>
                <xsl:with-param name="scope" select="$scope"/>
                <xsl:with-param name="b-inline-statement"     select="contains(@inline,     'statement')" />
                <xsl:with-param name="b-inline-hint"          select="contains(@inline,     'hint')"      />
                <xsl:with-param name="b-inline-answer"        select="contains(@inline,     'answer')"    />
                <xsl:with-param name="b-inline-solution"      select="contains(@inline,     'solution')"  />
                <xsl:with-param name="b-divisional-statement" select="contains(@divisional, 'statement')" />
                <xsl:with-param name="b-divisional-hint"      select="contains(@divisional, 'hint')"      />
                <xsl:with-param name="b-divisional-answer"    select="contains(@divisional, 'answer')"    />
                <xsl:with-param name="b-divisional-solution"  select="contains(@divisional, 'solution')"  />
                <xsl:with-param name="b-worksheet-statement"  select="contains(@worksheet,  'statement')" />
                <xsl:with-param name="b-worksheet-hint"       select="contains(@worksheet,  'hint')"      />
                <xsl:with-param name="b-worksheet-answer"     select="contains(@worksheet,  'answer')"    />
                <xsl:with-param name="b-worksheet-solution"   select="contains(@worksheet,  'solution')"  />
                <xsl:with-param name="b-reading-statement"    select="contains(@reading,    'statement')" />
                <xsl:with-param name="b-reading-hint"         select="contains(@reading,    'hint')"      />
                <xsl:with-param name="b-reading-answer"       select="contains(@reading,    'answer')"    />
                <xsl:with-param name="b-reading-solution"     select="contains(@reading,    'solution')"  />
                <xsl:with-param name="b-project-statement"    select="contains(@project,    'statement')" />
                <xsl:with-param name="b-project-hint"         select="contains(@project,    'hint')"      />
                <xsl:with-param name="b-project-answer"       select="contains(@project,    'answer')"    />
                <xsl:with-param name="b-project-solution"     select="contains(@project,    'solution')"  />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <!-- the default scope, first ancestor -->
            <xsl:apply-templates select="ancestor::*[not(self::backmatter)][1]" mode="solutions-generator">
                <xsl:with-param name="purpose" select="$purpose" />
                <xsl:with-param name="admit"   select="$admit"/>
                <xsl:with-param name="heading-level" select="$heading-level"/>
                <xsl:with-param name="scope" select="ancestor::*[not(self::backmatter)][1]"/>
                <xsl:with-param name="b-inline-statement"     select="contains(@inline,     'statement')" />
                <xsl:with-param name="b-inline-hint"          select="contains(@inline,     'hint')"      />
                <xsl:with-param name="b-inline-answer"        select="contains(@inline,     'answer')"    />
                <xsl:with-param name="b-inline-solution"      select="contains(@inline,     'solution')"  />
                <xsl:with-param name="b-divisional-statement" select="contains(@divisional, 'statement')" />
                <xsl:with-param name="b-divisional-hint"      select="contains(@divisional, 'hint')"      />
                <xsl:with-param name="b-divisional-answer"    select="contains(@divisional, 'answer')"    />
                <xsl:with-param name="b-divisional-solution"  select="contains(@divisional, 'solution')"  />
                <xsl:with-param name="b-worksheet-statement"  select="contains(@worksheet,  'statement')" />
                <xsl:with-param name="b-worksheet-hint"       select="contains(@worksheet,  'hint')"      />
                <xsl:with-param name="b-worksheet-answer"     select="contains(@worksheet,  'answer')"    />
                <xsl:with-param name="b-worksheet-solution"   select="contains(@worksheet,  'solution')"  />
                <xsl:with-param name="b-reading-statement"    select="contains(@reading,    'statement')" />
                <xsl:with-param name="b-reading-hint"         select="contains(@reading,    'hint')"      />
                <xsl:with-param name="b-reading-answer"       select="contains(@reading,    'answer')"    />
                <xsl:with-param name="b-reading-solution"     select="contains(@reading,    'solution')"  />
                <xsl:with-param name="b-project-statement"    select="contains(@project,    'statement')" />
                <xsl:with-param name="b-project-hint"         select="contains(@project,    'hint')"      />
                <xsl:with-param name="b-project-answer"       select="contains(@project,    'answer')"    />
                <xsl:with-param name="b-project-solution"     select="contains(@project,    'solution')"  />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>


    <xsl:apply-templates select="conclusion">
        <xsl:with-param name="b-original" select="true()" />
    </xsl:apply-templates>
</xsl:template>

<!-- Determine whether an exercise should be admitted, given its serial -->
<!-- number and some specification for what should be admitted.         -->
<xsl:template match="exercise|&PROJECT-LIKE;" mode="determine-admission">
    <xsl:param name="admit"/>
    <xsl:variable name="serial-number">
        <xsl:apply-templates select="." mode="serial-number"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="($admit='odd') and ($serial-number mod 2 = 1)">
            <xsl:value-of select="'yes'"/>
        </xsl:when>
        <xsl:when test="($admit='even') and ($serial-number mod 2 = 0)">
            <xsl:value-of select="'yes'"/>
        </xsl:when>
        <xsl:when test="$admit='all'">
            <xsl:value-of select="'yes'"/>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Solutions Generator -->

<!-- Context is the originally the scope (root of subtree examined)      -->
<!-- and is meant to be a "traditional" division, as expressed in        -->
<!-- the schema.  However, on recursion context can be any division      -->
<!-- containing exercises, such as "worksheet".  We do not allow a       -->
<!-- "solutions" division to live inside a "part", so in the default     -->
<!-- use a part is not the context.  This is all to explain that         -->
<!-- the match is more expansive than first use, in practice.            -->
<!--                                                                     -->
<!-- On first call, the placing division should have a descriptive       -->
<!-- title from the author, such as "Solutions to Chapter Exercises",    -->
<!-- when placed at the level of a section (and assuming default scope). -->
<!--                                                                     -->
<!-- "scope" is replicated/preserved/remembered in recursive calls.      -->
<!--                                                                     -->
<!-- "heading-stack" is a node set consisting of all divisional nodes    -->
<!-- between the current node and the scope that warrant having their    -->
<!-- heading printed when the "leaf" division is finally dropping its    -->
<!-- content. It includes the "scope" even though the scope's heading    -->
<!-- may ultimately not be printed. The "division-in-solutions"          -->
<!-- template can cut scope from the heading-stack when desired.         -->
<!--                                                                     -->
<!-- NB: this template is used/called directly by the                    -->
<!-- "solution-manual-latex.xsl" stylesheet, so coordinate               -->
<!-- changes here with usage there.                                      -->

<xsl:template match="book|article|part|chapter|section|subsection|subsubsection|exercises|worksheet|reading-questions" mode="solutions-generator">
    <xsl:param name="purpose"/>
    <xsl:param name="admit"/>
    <xsl:param name="heading-level"/>
    <xsl:param name="heading-stack" select="."/>
    <xsl:param name="scope"/>
    <xsl:param name="b-inline-statement"     />
    <xsl:param name="b-inline-hint"          />
    <xsl:param name="b-inline-answer"        />
    <xsl:param name="b-inline-solution"      />
    <xsl:param name="b-divisional-statement" />
    <xsl:param name="b-divisional-hint"      />
    <xsl:param name="b-divisional-answer"    />
    <xsl:param name="b-divisional-solution"  />
    <xsl:param name="b-worksheet-statement"  />
    <xsl:param name="b-worksheet-hint"       />
    <xsl:param name="b-worksheet-answer"     />
    <xsl:param name="b-worksheet-solution"   />
    <xsl:param name="b-reading-statement"    />
    <xsl:param name="b-reading-hint"         />
    <xsl:param name="b-reading-answer"       />
    <xsl:param name="b-reading-solution"     />
    <xsl:param name="b-project-statement"    />
    <xsl:param name="b-project-hint"         />
    <xsl:param name="b-project-answer"       />
    <xsl:param name="b-project-solution"     />

    <!-- See if division has *any* content, at any depth, in light of switches. -->
    <!-- Traditional divisions expect many switches, while specialized          -->
    <!-- divisions expect a limited subset                                      -->
    <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="admit"                  select="$admit"/>
            <xsl:with-param name="b-inline-statement"     select="$b-inline-statement" />
            <xsl:with-param name="b-inline-answer"        select="$b-inline-answer" />
            <xsl:with-param name="b-inline-hint"          select="$b-inline-hint" />
            <xsl:with-param name="b-inline-solution"      select="$b-inline-solution" />
            <xsl:with-param name="b-divisional-statement" select="$b-divisional-statement" />
            <xsl:with-param name="b-divisional-answer"    select="$b-divisional-answer" />
            <xsl:with-param name="b-divisional-hint"      select="$b-divisional-hint" />
            <xsl:with-param name="b-divisional-solution"  select="$b-divisional-solution" />
            <xsl:with-param name="b-worksheet-statement"  select="$b-worksheet-statement" />
            <xsl:with-param name="b-worksheet-answer"     select="$b-worksheet-answer" />
            <xsl:with-param name="b-worksheet-hint"       select="$b-worksheet-hint" />
            <xsl:with-param name="b-worksheet-solution"   select="$b-worksheet-solution" />
            <xsl:with-param name="b-reading-statement"    select="$b-reading-statement" />
            <xsl:with-param name="b-reading-answer"       select="$b-reading-answer" />
            <xsl:with-param name="b-reading-hint"         select="$b-reading-hint" />
            <xsl:with-param name="b-reading-solution"     select="$b-reading-solution" />
            <xsl:with-param name="b-project-statement"    select="$b-project-statement" />
            <xsl:with-param name="b-project-answer"       select="$b-project-answer" />
            <xsl:with-param name="b-project-hint"         select="$b-project-hint" />
            <xsl:with-param name="b-project-solution"     select="$b-project-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <!-- Now apply dry-run to preceding-siblings. If this comes back empty, -->
    <!-- we know that this division should pass along the heading-stack     -->
    <!-- node set of ancestors for grouping stacked headings.               -->
    <!-- Otherwise, set the heading-stack to just this division.            -->
    <xsl:variable name="preceding-sibling-dry-run">
        <xsl:apply-templates select="preceding-sibling::*" mode="dry-run">
            <xsl:with-param name="admit"                  select="$admit"/>
            <xsl:with-param name="b-inline-statement"     select="$b-inline-statement" />
            <xsl:with-param name="b-inline-answer"        select="$b-inline-answer" />
            <xsl:with-param name="b-inline-hint"          select="$b-inline-hint" />
            <xsl:with-param name="b-inline-solution"      select="$b-inline-solution" />
            <xsl:with-param name="b-divisional-statement" select="$b-divisional-statement" />
            <xsl:with-param name="b-divisional-answer"    select="$b-divisional-answer" />
            <xsl:with-param name="b-divisional-hint"      select="$b-divisional-hint" />
            <xsl:with-param name="b-divisional-solution"  select="$b-divisional-solution" />
            <xsl:with-param name="b-worksheet-statement"  select="$b-worksheet-statement" />
            <xsl:with-param name="b-worksheet-answer"     select="$b-worksheet-answer" />
            <xsl:with-param name="b-worksheet-hint"       select="$b-worksheet-hint" />
            <xsl:with-param name="b-worksheet-solution"   select="$b-worksheet-solution" />
            <xsl:with-param name="b-reading-statement"    select="$b-reading-statement" />
            <xsl:with-param name="b-reading-answer"       select="$b-reading-answer" />
            <xsl:with-param name="b-reading-hint"         select="$b-reading-hint" />
            <xsl:with-param name="b-reading-solution"     select="$b-reading-solution" />
            <xsl:with-param name="b-project-statement"    select="$b-project-statement" />
            <xsl:with-param name="b-project-answer"       select="$b-project-answer" />
            <xsl:with-param name="b-project-hint"         select="$b-project-hint" />
            <xsl:with-param name="b-project-solution"     select="$b-project-solution" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="b-preceding-empty" select="$preceding-sibling-dry-run = ''"/>
    <xsl:variable name="next-heading-stack" select=".|ancestor::*[$b-preceding-empty and (count(.|$heading-stack) = count($heading-stack))]"/>

    <xsl:if test="not($dry-run = '')">
        <!-- We call the only real abstract template, it simply        -->
        <!-- provides the correct wrapping for a division appearing    -->
        <!-- to aid in organizing a collection of solutions.           -->
        <!--                                                           -->
        <!-- Context is a division: traditional, or specialized.       -->
        <!-- We want all "exercise" and "project", in document order,  -->
        <!-- without descending into subdivisions.  We handle          -->
        <!-- "exercisegroup" specially, since it has "statement"       -->
        <!-- characteristics.  In a traditional division, an inline    -->
        <!-- exercise can be inside a "paragraphs".  If we divide an   -->
        <!-- "exercises" division, we will need to explicitly burrow   -->
        <!-- down into it.  Finally, a "worksheet" can have "exercise" -->
        <!-- laid out via "sidebyside".                                -->
        <!-- The purpose is sent to the modal "solutions" templates    -->
        <!-- in order to generate accurate labels based on position    -->
        <!-- The "heading-level" is the same as the originating        -->
        <!-- "solutions" division on the first call here               -->

        <!-- But first, we see if just one type of component has been  -->
        <!-- requested, across the various types of "exercise".  The   -->
        <!-- point is to squelch a repetitive heading all through a    -->
        <!-- list of solutions, so we need to pass the condition on    -->
        <!-- through.                                                  -->
        <!-- NB: this gets recomputed as we recurse into subdivisions, -->
        <!-- but it must be awful fast, so we don't try to set some    -->
        <!-- flag indicating necessity of computing it.  But recognize -->
        <!-- we don't need to pass it in the recursive call below.     -->
        <!-- NB: this is different than the actual components selected -->
        <!-- all ending up as the same type in the output, because     -->
        <!-- some requested type never appears.                        -->

        <xsl:variable name="variety">
            <xsl:if test="$b-inline-statement or $b-divisional-statement or $b-worksheet-statement or $b-reading-statement or $b-project-statement">
                <xsl:text>T</xsl:text>
            </xsl:if>
            <xsl:if test="$b-inline-hint or $b-divisional-hint or $b-worksheet-hint or $b-reading-hint or $b-project-hint">
                <xsl:text>H</xsl:text>
            </xsl:if>
            <xsl:if test="$b-inline-answer or $b-divisional-answer or $b-worksheet-answer or $b-reading-answer or $b-project-answer">
                <xsl:text>A</xsl:text>
            </xsl:if>
            <xsl:if test="$b-inline-solution or $b-divisional-solution or $b-worksheet-solution or $b-reading-solution or $b-project-solution">
                <xsl:text>S</xsl:text>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="b-component-heading" select="string-length($variety) &gt; 1"/>

        <!-- Specialized divisions in unstructured divisions have a heading   -->
        <!-- level that is 2 deeper from invoking "solutions".                -->
        <!-- Other leaf divisions are 1 deeper than the invoking "solutions". -->
        <xsl:variable name="is-specialized-division">
            <xsl:apply-templates select="." mode="is-specialized-division"/>
        </xsl:variable>
        <xsl:variable name="is-child-of-structured">
            <xsl:apply-templates select="parent::*" mode="is-structured-division"/>
        </xsl:variable>
        <xsl:variable name="next-heading-level">
            <xsl:choose>
                <xsl:when test="$is-specialized-division = 'true' and $is-child-of-structured = 'false'">
                    <xsl:value-of select="$heading-level + 2"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$heading-level + 1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:apply-templates select="." mode="division-in-solutions">
            <xsl:with-param name="scope" select="$scope" />
            <xsl:with-param name="heading-level" select="$next-heading-level"/>
            <xsl:with-param name="heading-stack" select="$next-heading-stack"/>
            <xsl:with-param name="content">

                <!-- N.B.: inline exercises and PROJECT-LIKE can be   -->
                <!-- "hidden" inside the "paragraphs" pseudo-division -->
                <!-- Everything below is 1 deeper than the division's heading -->
                <xsl:for-each select="exercise|subexercises|exercisegroup|&PROJECT-LIKE;|paragraphs/*[self::exercise or &PROJECT-FILTER;]|self::worksheet//*[self::exercise or &PROJECT-FILTER;]">
                     <xsl:choose>
                        <xsl:when test="self::exercise and boolean(&INLINE-EXERCISE-FILTER;)">
                            <xsl:apply-templates select="." mode="solutions">
                                <xsl:with-param name="purpose" select="$purpose" />
                                <xsl:with-param name="admit"   select="$admit"/>
                                <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                                <xsl:with-param name="heading-level"       select="$next-heading-level + 1"/>
                                <xsl:with-param name="b-has-statement" select="$b-inline-statement" />
                                <xsl:with-param name="b-has-answer"    select="$b-inline-answer" />
                                <xsl:with-param name="b-has-hint"      select="$b-inline-hint" />
                                <xsl:with-param name="b-has-solution"  select="$b-inline-solution" />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="self::subexercises|self::exercisegroup">
                            <xsl:apply-templates select="." mode="solutions">
                                <xsl:with-param name="purpose" select="$purpose"/>
                                <xsl:with-param name="admit"   select="$admit"/>
                                <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                                <xsl:with-param name="heading-level"       select="$next-heading-level + 1"/>
                                <xsl:with-param name="b-has-statement" select="$b-divisional-statement" />
                                <xsl:with-param name="b-has-answer"    select="$b-divisional-answer" />
                                <xsl:with-param name="b-has-hint"      select="$b-divisional-hint" />
                                <xsl:with-param name="b-has-solution"  select="$b-divisional-solution" />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="self::exercise and ancestor::exercises">
                            <xsl:apply-templates select="." mode="solutions">
                                <xsl:with-param name="purpose" select="$purpose"/>
                                <xsl:with-param name="admit"   select="$admit"/>
                                <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                                <xsl:with-param name="heading-level"       select="$next-heading-level + 1"/>
                                <xsl:with-param name="b-has-statement" select="$b-divisional-statement" />
                                <xsl:with-param name="b-has-answer"    select="$b-divisional-answer" />
                                <xsl:with-param name="b-has-hint"      select="$b-divisional-hint" />
                                <xsl:with-param name="b-has-solution"  select="$b-divisional-solution" />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="self::exercise and ancestor::worksheet">
                            <xsl:apply-templates select="." mode="solutions">
                                <xsl:with-param name="purpose" select="$purpose"/>
                                <xsl:with-param name="admit"   select="$admit"/>
                                <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                                <xsl:with-param name="heading-level"       select="$next-heading-level + 1"/>
                                <xsl:with-param name="b-has-statement" select="$b-worksheet-statement" />
                                <xsl:with-param name="b-has-answer"    select="$b-worksheet-answer" />
                                <xsl:with-param name="b-has-hint"      select="$b-worksheet-hint" />
                                <xsl:with-param name="b-has-solution"  select="$b-worksheet-solution" />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="self::exercise and ancestor::reading-questions">
                            <xsl:apply-templates select="." mode="solutions">
                                <xsl:with-param name="purpose" select="$purpose"/>
                                <xsl:with-param name="admit"   select="$admit"/>
                                <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                                <xsl:with-param name="heading-level"       select="$next-heading-level + 1"/>
                                <xsl:with-param name="b-has-statement" select="$b-reading-statement" />
                                <xsl:with-param name="b-has-answer"    select="$b-reading-answer" />
                                <xsl:with-param name="b-has-hint"      select="$b-reading-hint" />
                                <xsl:with-param name="b-has-solution"  select="$b-reading-solution" />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="&PROJECT-FILTER;">
                            <xsl:apply-templates select="." mode="solutions">
                                <xsl:with-param name="purpose" select="$purpose"/>
                                <xsl:with-param name="admit"   select="$admit"/>
                                <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                                <xsl:with-param name="heading-level"       select="$next-heading-level + 1"/>
                                <xsl:with-param name="b-has-statement" select="$b-project-statement" />
                                <xsl:with-param name="b-has-answer"    select="$b-project-answer" />
                                <xsl:with-param name="b-has-hint"      select="$b-project-hint" />
                                <xsl:with-param name="b-has-solution"  select="$b-project-solution" />
                            </xsl:apply-templates>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- recurse into (sub)divisions which can contain exercises     -->
    <!-- On every recursion (not initial call) we request a heading  -->
    <!-- and we pass in the scope of original call for help deciding -->
    <!-- the level of headings given surroundings.                   -->
    <!-- This is recurrence, so one might expect to increment $heading-level. -->
    <!-- But to collapse stacked headings, we leave heading-level stable at   -->
    <!-- the "solutions" level and the output stylesheet should increment 1.  -->
    <!-- NB: $b-component-heading is recomputed, so is not passed    -->
    <xsl:apply-templates select="book|article|part|chapter|section|subsection|subsubsection|exercises|worksheet|reading-questions" mode="solutions-generator">
        <xsl:with-param name="purpose" select="$purpose" />
        <xsl:with-param name="admit"   select="$admit"/>
        <xsl:with-param name="heading-level" select="$heading-level"/>
        <xsl:with-param name="heading-stack" select="$next-heading-stack"/>
        <xsl:with-param name="scope" select="$scope" />
        <xsl:with-param name="b-inline-statement"     select="$b-inline-statement" />
        <xsl:with-param name="b-inline-answer"        select="$b-inline-answer" />
        <xsl:with-param name="b-inline-hint"          select="$b-inline-hint" />
        <xsl:with-param name="b-inline-solution"      select="$b-inline-solution" />
        <xsl:with-param name="b-divisional-statement" select="$b-divisional-statement" />
        <xsl:with-param name="b-divisional-answer"    select="$b-divisional-answer" />
        <xsl:with-param name="b-divisional-hint"      select="$b-divisional-hint" />
        <xsl:with-param name="b-divisional-solution"  select="$b-divisional-solution" />
        <xsl:with-param name="b-worksheet-statement"  select="$b-worksheet-statement" />
        <xsl:with-param name="b-worksheet-answer"     select="$b-worksheet-answer" />
        <xsl:with-param name="b-worksheet-hint"       select="$b-worksheet-hint" />
        <xsl:with-param name="b-worksheet-solution"   select="$b-worksheet-solution" />
        <xsl:with-param name="b-reading-statement"    select="$b-reading-statement" />
        <xsl:with-param name="b-reading-answer"       select="$b-reading-answer" />
        <xsl:with-param name="b-reading-hint"         select="$b-reading-hint" />
        <xsl:with-param name="b-reading-solution"     select="$b-reading-solution" />
        <xsl:with-param name="b-project-statement"    select="$b-project-statement" />
        <xsl:with-param name="b-project-answer"       select="$b-project-answer" />
        <xsl:with-param name="b-project-hint"         select="$b-project-hint" />
        <xsl:with-param name="b-project-solution"     select="$b-project-solution" />
    </xsl:apply-templates>
</xsl:template>

<!-- An abstract outer template for each division when repeated in the solutions.                             -->
<!-- This calls "duplicate-heading" modal template, which implements output-specific mechanisms for headings. -->

<xsl:template match="book|article|part|chapter|section|subsection|subsubsection|exercises|worksheet|reading-questions" mode="division-in-solutions">
    <xsl:param name="scope" />
    <xsl:param name="heading-level"/>
    <xsl:param name="heading-stack"/>
    <xsl:param name="content" />
    <xsl:variable name="is-specialized-division">
        <xsl:apply-templates select="." mode="is-specialized-division"/>
    </xsl:variable>
    <xsl:variable name="is-structured">
        <xsl:choose>
            <xsl:when test="$is-specialized-division = 'false'">
                <xsl:apply-templates select="." mode="is-structured-division"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="is-child-of-structured">
        <xsl:apply-templates select="parent::*" mode="is-structured-division"/>
    </xsl:variable>

    <!-- We cut "scope" from heading-stack if needed.                    -->
    <!-- Or reset stack if specialized division in unstructured division -->
    <xsl:variable name="final-heading-stack" select=".|ancestor-or-self::*[
        ($is-specialized-division = 'false' or $is-child-of-structured = 'true')
        and (count(.|$heading-stack) = count($heading-stack))
        and (count(.|$scope) != count($scope))]"
    />

    <!-- A structured division cannot have children that have solution-like things   -->
    <!-- So we withhold headings for such divisions, passing to the "leaf" division, -->
    <!-- which must itself be unstructured.                                          -->
    <xsl:choose>
        <xsl:when test="count($final-heading-stack) = 0">
            <xsl:copy-of select="$content" />
        </xsl:when>
        <xsl:when test="not($is-structured = 'true')">
            <xsl:apply-templates select="." mode="duplicate-heading">
                <xsl:with-param name="heading-level" select="$heading-level"/>
                <xsl:with-param name="heading-stack" select="$final-heading-stack"/>
            </xsl:apply-templates>
            <xsl:copy-of select="$content" />
        </xsl:when>
        <!-- Content in something structred should just be recursing down to unstructured leaves. -->
        <xsl:otherwise>
            <xsl:copy-of select="$content" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################ -->
<!-- Printout Margins -->
<!-- ################ -->

<xsl:template match="worksheet|handout" mode="printout-margin">
    <xsl:param name="author-side"/>
    <xsl:param name="publisher-side"/>
    <xsl:choose>
        <xsl:when test="$author-side">
            <xsl:value-of select="normalize-space($author-side)"/>
        </xsl:when>
        <xsl:when test="@margin">
            <xsl:value-of select="normalize-space(@margin)"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="normalize-space($publisher-side)"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ##################-->
<!-- Frontmatter Items -->
<!-- ##################-->

<!-- Bibliographic information for a document is contained in the     -->
<!-- frontmatter/bibinfo element.  Items then move to either a        -->
<!-- titlepage or colophon that contain then empty titlepage-items    -->
<!-- or colophon-items.  These are implemented by each template.      -->
 <!--Here we define these abstract templates with warnings to do this.-->
<xsl:template match="titlepage-items">
    <xsl:message>PTX:BUG:    a conversion to a new output format requires implementation of a named template ("titlepage-items") in order to specify which bibliographic information to include in the titlepage.</xsl:message>
</xsl:template>

<xsl:template match="colophon-items">
    <xsl:message>PTX:BUG:    a conversion to a new output format requires implementation of a named template ("colophon-items") in order to specify which bibliographic information to include in the front colophon.</xsl:message>
</xsl:template>

<!-- No conversion will create content directly from bibinfo -->
<xsl:template match="bibinfo"/>

<!-- Keywords: create a comma-separated list of each keyword -->
<!-- (the comma can be overridden by a passed param).        -->
<!-- Include "Primary" or "Secondary" appropriately, ";" to  -->
<!-- separate the list of primary and secondary keywords.    -->
<!-- No ending period (some styles don't include it).        -->
<xsl:template match="keywords/keyword">
    <xsl:param name="sep" select="', '"/>
    <xsl:if test="@primary='yes'">
        <xsl:text>Primary </xsl:text>
    </xsl:if>
    <xsl:if test="@primary='no' or @secondary='yes'">
        <xsl:text>Secondary </xsl:text>
    </xsl:if>
    <xsl:value-of select="."/>
    <xsl:choose>
        <xsl:when test="following-sibling::keyword[1][@primary='no' or @secondary='yes']">
            <xsl:text>; </xsl:text>
        </xsl:when>
        <xsl:when test="following-sibling::keyword">
            <xsl:value-of select="$sep"/>
        </xsl:when>
        <xsl:otherwise/>
    </xsl:choose>
</xsl:template>


<!-- ############# -->
<!-- Notation List -->
<!-- ############# -->

<!-- A list/table where each row is a sample usage (as mathematics), -->
<!-- a short narrative description, and then a cross-reference or    -->
<!-- locator to the place where the original "notation" element was  -->
<!-- authored, presumably in the vicinity of a more complete         -->
<!-- explanation.  These appear in the order of appearance, so no    -->
<!-- sorting takes place here, document order is what we want.       -->

<!-- Abstract Templates -->
<!--                                                             -->
<!-- These require implementation for a new conversion to        -->
<!-- provide formatting peculiar to an output format.            -->
<!-- Logic/organization is provided here.                        -->
<!--                                                             -->
<!-- "present-notation-list"                                     -->
<!-- A named template (context is not employed), typically with  -->
<!-- infrastructure to surround the "content parameter, which is -->
<!-- the rows of the list/table.  This is applied once.          -->
<!--                                                             -->
<!-- "present-notation-item"                                     -->
<!-- A modal template (since a generic template kills "notation" -->
<!-- on-sight) for each instance, forming one row of the table.  -->

<!-- The "notation" element can be placed inside a "p" or inside a  -->
<!-- "definition".  When encountered in document order it is simply -->
<!-- killed.  We collect them as a group when forming the list.     -->
<!-- NB: this is overidden in the conversion to LaTeX since a       -->
<!-- marker needs to be dropped in order for the cross-reference    -->
<!-- to find its target.                                            -->
<xsl:template match="notation"/>

<!-- Match the (single?) "notation-list" element, presumably in a     -->
<!-- back matter division (appendix?).  Provide infrastructure        -->
<!-- (wrapping) and process global list of individual items in order. -->
<!-- NB: we tried a "for-each", in hopes of easily determining the    -->
<!-- last "notation" so the LaTeX table would not have a final        -->
<!-- unnecessary "\\".  But that context switch was lost in the       -->
<!-- transition to the LaTeX implementation template.  We might form  -->
<!-- a boolean parameter here ("$last") to pass along to every        -->
<!-- implementation, but that seems like a lot of effort for a        -->
<!-- problem nobody has mentioned in years.                           -->
<xsl:template match="notation-list">
    <xsl:call-template name="present-notation-list">
        <xsl:with-param name="content">
            <xsl:apply-templates select="$document-root//notation" mode="present-notation-item"/>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Stub abstract template, with warning -->
<xsl:template name="present-notation-list">
    <xsl:param name="content"/>

    <xsl:message>PTX:BUG:    a conversion to a new output format requires implementation of a named template ("present-notation-list") in order to structure a notation list.</xsl:message>
</xsl:template>

<!-- Stub abstract template, with warning -->
<xsl:template match="notation" mode="present-notation-item">

    <xsl:message>PTX:BUG:    a conversion to a new output format requires implementation of a modal template ("present-notation-item") in order to structure an explanation of a single "notation" element.</xsl:message>
</xsl:template>


<!-- ################ -->
<!-- Index Production -->
<!-- ################ -->

<!-- We have templates here that produce an index, provoked      -->
<!-- by the "index-list" element.  They contain the logic of     -->
<!-- collecting, analyzing, sorting, and grouping the index      -->
<!-- entries found in the "idx" elements.  They rely on abstract -->
<!-- templates found in conversion stylesheets which handle the  -->
<!-- peculiarities of the relevant output format. We describe    -->
<!-- these here, along with stub templates in the vicinity.      -->

<!-- Abstract templates -->

<!-- "present-index" -->
<!-- A named template (context is not employed), typically with -->
<!-- infrastructure to surround the "content" parameter, which  -->
<!-- the entire body of the index.  This is applied once.       -->

<!-- "present-letter-group" -->
<!-- A named template (context is not employed), to present -->
<!-- several entries, all leading with the same letter.     -->

<!-- "present-index-heading" -->
<!-- A named template (context is not employed), to format -->
<!-- a single heading of an index entry (there may be up   -->
<!-- to three of these).                                   -->

<!-- "present-index-locator"  -->
<!-- "present-index-see"      -->
<!-- "present-index-see-also" -->
<!-- "present-index-italics"  -->
<!-- Named templates (context is not employed) for the  -->
<!-- format of individual pieces of the locators at the -->
<!-- end of an index entry.                             -->

<!-- Used at the end of the next template to group index       -->
<!-- entries by letter for eventual output organized by letter -->
<xsl:key name="index-entry-by-letter" match="index" use="@letter"/>

<!-- "index-list":                                           -->
<!--     build a sorted list of every "index" in text        -->
<!--     use Muenchian Method to group by letter and process -->
<!-- "group-by-heading":                                     -->
<!--     consolidate/accumulate entries with common heading  -->
<!-- "knowl-list":                                           -->
<!--     output the locators, see, see also                  -->
<xsl:template match="index-list">
    <!-- Save-off the "index-list" as context for placement  -->
    <!-- of eventual xref/cross-references, since we use a   -->
    <!-- for-each and context changes.  Not strictly         -->
    <!-- necessary, but correct.                             -->
    <!-- We also pass this node down into the construction   -->
    <!-- of headings, to provide context for the             -->
    <!-- localization of words like "see" and "see also" in  -->
    <!-- the index.  (So it is an @xml:lang on the           -->
    <!-- "index-list" generator which dictates this,         -->
    <!-- allowing for indices in two different languages.)   -->
    <!-- TODO: perhaps the originating "index-list" should   -->
    <!-- be the context of this chain of templates, moving   -->
    <!-- later ones away from named templates?               -->
    <xsl:variable name="the-index-list" select="."/>
    <!-- "idx" as mixed content.                             -->
    <!-- Or, "idx" structured with up to three "h"           -->
    <!-- Start attribute is actual end of a "page            -->
    <!-- range", goodies at @finish.                         -->

    <!-- "index-items" is an internal structure, so very     -->
    <!-- predictable.  Looks like:                           -->
    <!--                                                     -->
    <!-- text/key: always three pairs, some may be empty.    -->
    <!-- "text" is author's heading and will be output at    -->
    <!-- the end, "key" is a sanitized version for sorting,  -->
    <!-- and could be an entire replacement if the @sortby   -->
    <!-- attribute is used.                                  -->
    <!--                                                     -->
    <!-- locator-type: used to identify a "traditional" page -->
    <!-- locator which points back to a place in the text,   -->
    <!-- versus a "see" or "see also" entry.  Only used for  -->
    <!-- sorting, and really only used to be sure a "see"    -->
    <!-- *follows* the page locator.                         -->
    <xsl:variable name="index-items">
        <xsl:for-each select="$document-root//idx[not(@start)]">
            <index>
                <!-- identify content of primary sort key      -->
                <!-- this follows the logic of creating key[1] -->
                <!-- TODO: this may be too ad-hoc, study       -->
                <!--       closely on a refactor               -->
                <xsl:variable name="letter-content">
                    <xsl:choose>
                        <xsl:when test="@sortby">
                            <xsl:value-of select="@sortby" />
                        </xsl:when>
                        <xsl:when test="not(h)">
                            <xsl:apply-templates/>
                        </xsl:when>
                        <xsl:when test="h and h[1]/@sortby">
                            <xsl:apply-templates select="h[1]/@sortby"/>
                        </xsl:when>
                        <xsl:when test="h">
                            <xsl:apply-templates select="h[1]"/>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:variable>
                <!-- lowercase first letter of primary sort key    -->
                <!-- used later to group items by letter in output -->
                <xsl:attribute name="letter">
                    <xsl:value-of select="translate(substring($letter-content,1,1), &UPPERCASE;, &LOWERCASE;)"/>
                </xsl:attribute>
                <xsl:choose>
                    <!-- simple mixed-content first, no structure -->
                    <!-- one text-key pair, two more empty        -->
                    <xsl:when test="not(h)">
                        <xsl:variable name="content">
                            <xsl:apply-templates/>
                        </xsl:variable>
                        <!-- text, key-value for single index heading -->
                        <text>
                            <xsl:copy-of select="$content" />
                        </text>
                        <key>
                            <xsl:choose>
                                <xsl:when test="@sortby">
                                    <xsl:value-of select="translate(@sortby, &UPPERCASE;, &LOWERCASE;)" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="translate($content, &UPPERCASE;, &LOWERCASE;)" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </key>
                        <!-- plus two more empty text, key pairs -->
                        <text/><key/>
                        <text/><key/>
                    </xsl:when>
                    <!-- structured index entry, multiple text-key pairs -->
                    <!-- "main" as indicator is deprecated               -->
                    <xsl:when test="h">
                        <!-- "h" occur in order, main-sub-sub deprecated -->
                        <xsl:for-each select="h">
                            <xsl:variable name="content">
                                <xsl:apply-templates/>
                            </xsl:variable>
                            <text>
                                <xsl:copy-of select="$content" />
                            </text>
                            <key>
                                <xsl:choose>
                                    <xsl:when test="@sortby">
                                        <xsl:value-of select="translate(@sortby, &UPPERCASE;, &LOWERCASE;)" />
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="translate($content, &UPPERCASE;, &LOWERCASE;)" />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </key>
                        </xsl:for-each>
                        <!-- add additional empty text, key pairs -->
                        <!-- so there are always three            -->
                        <xsl:if test="(count(h) = 1) or (count(h) = 2)">
                            <text/><key/>
                        </xsl:if>
                        <xsl:if test="count(h) = 1">
                            <text/><key/>
                        </xsl:if>
                        <!-- final sort key will prioritize  -->
                        <!-- this mimics LaTeX's ordering    -->
                        <!--   0 - has "see also"            -->
                        <!--   1 - has "see"                 -->
                        <!--   2 - is usual index reference  -->
                        <xsl:if test="not(following-sibling::*[self::h])">
                            <locator-type>
                                <xsl:choose>
                                    <xsl:when test="seealso">
                                        <xsl:text>2</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="see">
                                        <xsl:text>1</xsl:text>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>0</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </locator-type>
                        </xsl:if>
                    </xsl:when>
                </xsl:choose>
                <!-- Create the full locator and save now, since context will -->
                <!-- be lost later.  Save a page locator in "cross-reference" -->
                <!-- element.  We use the context of the index itself as the  -->
                <!-- location where the cross-reference is placed.  The       -->
                <!-- location of the "idx" is the start of a search for the   -->
                <!-- enclosing element.  See and "see also" take precedence.  -->
                <xsl:choose>
                    <xsl:when test="see">
                        <see>
                            <xsl:apply-templates select="see"/>
                        </see>
                    </xsl:when>
                    <xsl:when test="seealso">
                        <seealso>
                            <xsl:apply-templates select="seealso"/>
                        </seealso>
                    </xsl:when>
                    <xsl:otherwise>
                        <cross-reference>
                            <xsl:apply-templates select="$the-index-list" mode="index-enclosure">
                                <xsl:with-param name="enclosure" select="."/>
                            </xsl:apply-templates>
                        </cross-reference>
                    </xsl:otherwise>
                </xsl:choose>
            </index>
        </xsl:for-each>
    </xsl:variable>
    <!-- Sort, now that info from document tree ordering is recorded     -->
    <!-- Keys, normalized to lowercase, or @sortby attributes, are the   -->
    <!-- primary key for sorting, but if we have index entries that just -->
    <!-- differ by upper- or lower-case distinctions, we need to have    -->
    <!-- identical variants sort next to each other so they get grouped  -->
    <!-- as one entry with multiple cross-references, so we sort         -->
    <!-- secondarily on the actual text as well.  The page locators were -->
    <!-- built in document order and so should remain that way after the -->
    <!-- sort and so be output in order of appearance.                   -->
    <xsl:variable name="sorted-index">
        <xsl:for-each select="exsl:node-set($index-items)/*">
            <xsl:sort select="./key[1]" />
            <xsl:sort select="./text[1]"/>
            <xsl:sort select="./key[2]" />
            <xsl:sort select="./text[2]"/>
            <xsl:sort select="./key[3]" />
            <xsl:sort select="./text[3]"/>
            <xsl:sort select="./locator-type" />
            <xsl:sort select="./see"/>
            <xsl:sort select="./seealso"/>
            <xsl:copy-of select="." />
        </xsl:for-each>
    </xsl:variable>
    <!-- Group by Letter -->
    <!-- A careful exposition of the Muenchian Method, named after Steve Muench  -->
    <!-- of Oracle.  This is an well-known, but complicated, XSLT 1.0 technique. -->
    <!-- (This is much easier in XSLT 2.0 with certain instructions).  We follow -->
    <!-- the XSLT Cookbook 2.0, Recipe 6.2, modulo one critical typo, and also   -->
    <!-- Jeni Tennison's instructive  "Grouping Using the Muenchian Method" at   -->
    <!-- http://www.jenitennison.com/xslt/grouping/muenchian.html.               -->
    <!--                                                                         -->
    <!-- Initial "for-each" sieves out a single (the first) representative of    -->
    <!-- each group of "index" that have a common initial letter for their sort  -->
    <!-- criteria.  Each becomes the context node for the remainder.             -->
    <xsl:call-template name="present-index">
        <xsl:with-param name="content">
            <xsl:for-each select="exsl:node-set($sorted-index)/index[count(.|key('index-entry-by-letter', @letter)[1]) = 1]">
                <!-- save the key to use again in selecting the group -->
                <xsl:variable name="current-letter" select="@letter"/>
                <!-- collect all the "index" with the same initial letter as representative    -->
                <!-- this key is still perusing the nodes of $sorted-index as context document -->
                <xsl:variable name="letter-group" select="key('index-entry-by-letter', $current-letter)"/>
                <!-- Employ abstract template to present/style a letter group -->
                <xsl:call-template name="present-letter-group">
                    <xsl:with-param name="the-index-list" select="$the-index-list"/>
                    <xsl:with-param name="letter-group" select="$letter-group"/>
                    <xsl:with-param name="current-letter" select="$current-letter"/>
                    <xsl:with-param name="content">
                        <!-- send to group-by-headings, which is vestigal -->
                        <xsl:apply-templates select="$letter-group[1]" mode="group-by-heading">
                            <xsl:with-param name="the-index-list" select="$the-index-list"/>
                            <xsl:with-param name="heading-group" select="/.." />
                            <xsl:with-param name="letter-group" select="$letter-group" />
                        </xsl:apply-templates>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>


<xsl:template name="present-index">
    <xsl:param name="content"/>

    <xsl:message>PTX:BUG:    a conversion to a new output format requires implementation of a named template ("present-index") in order to structure the overall index.</xsl:message>
</xsl:template>

<xsl:template name="present-letter-group">
    <xsl:param name="the-index-list"/>
    <xsl:param name="letter-group"/>
    <xsl:param name="current-letter"/>
    <xsl:param name="content"/>

    <xsl:message>PTX:BUG:    a conversion to a new output format requires implementation of a named template ("present-letter-group") in order to structure a group of entries all leading with the same letter.</xsl:message>
</xsl:template>

<!-- Accumulate index entries with identical headings - their    -->
<!-- exact text, not anything related to the keys.  Quit         -->
<!-- accumulating when look-ahead shows next entry differs.      -->
<!-- Output the (3-part) heading and locators before restarting. -->
<!-- TODO: investigate reworking this via Muenchian Method       -->
<xsl:template match="index" mode="group-by-heading">
    <xsl:param name="the-index-list"/>
    <!-- Empty node list from parent of root node -->
    <xsl:param name="heading-group"/>
    <xsl:param name="letter-group"/>

    <!-- look ahead at next index entry -->
    <xsl:variable name="next-index" select="following-sibling::index[1]"/>
    <!-- check if context node is still in the letter-group -->
    <xsl:if test="count(.|$letter-group) = count($letter-group)">
        <xsl:variable name="new-heading-group" select="$heading-group|."/>
        <xsl:choose>
            <!-- same heading, accumulate and iterate -->
            <xsl:when test="($next-index/text[1] = ./text[1]) and ($next-index/text[2] = ./text[2]) and ($next-index/text[3] = ./text[3])">
                <xsl:apply-templates select="$next-index" mode="group-by-heading">
                    <xsl:with-param name="the-index-list" select="$the-index-list"/>
                    <xsl:with-param name="heading-group" select="$new-heading-group" />
                    <xsl:with-param name="letter-group" select="$letter-group"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- some text differs in next index entry, -->
            <!-- write and restart heading accumulation -->
            <xsl:otherwise>
                <xsl:call-template name="output-one-heading-group">
                    <xsl:with-param name="the-index-list" select="$the-index-list"/>
                    <xsl:with-param name="heading-group" select="$new-heading-group" />
                </xsl:call-template>
                <!-- restart grouping by heading, pass through letter-group -->
                <xsl:apply-templates select="$next-index" mode="group-by-heading">
                    <xsl:with-param name="the-index-list" select="$the-index-list"/>
                    <xsl:with-param name="heading-group" select="/.." />
                    <xsl:with-param name="letter-group" select="$letter-group"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
</xsl:template>


<!-- Place the (possibly three) components of -->
<!-- the heading(s) into their proper divs.   -->
<!-- Do not duplicate prior components that   -->
<!-- match, do not write an empty heading.    -->
<xsl:template name="output-one-heading-group">
    <xsl:param name="the-index-list"/>
    <xsl:param name="heading-group" />

    <xsl:if test="$heading-group/see and $heading-group/cross-reference">
        <xsl:message>PTX:WARNING: an index entry should not have both a locator and a "see" reference.  Results may be unpredictable.  Perhaps you meant to employ a "seealso" reference?  Heading is: "<xsl:value-of select="text[1]"/>; <xsl:value-of select="text[2]"/>; <xsl:value-of select="text[3]"/>"</xsl:message>
    </xsl:if>
    <xsl:if test="$heading-group/seealso and not($heading-group/cross-reference)">
        <xsl:message>PTX:WARNING: an index entry should not have a "seealso" reference without also having a locator.  Results may be unpredictable.  Perhaps you meant to employ a "see" reference?  Heading is: "<xsl:value-of select="text[1]"/>; <xsl:value-of select="text[2]"/>; <xsl:value-of select="text[3]"/>"</xsl:message>
    </xsl:if>

    <xsl:variable name="pattern" select="$heading-group[1]" />
    <xsl:variable name="pred" select="$pattern/preceding-sibling::index[1]" />
    <!-- booleans for analysis of format of heading, locators -->
    <xsl:variable name="match1" select="($pred/text[1] = $pattern/text[1]) and $pred" />
    <xsl:variable name="match2" select="($pred/text[2] = $pattern/text[2]) and $pred" />
    <xsl:variable name="match3" select="($pred/text[3] = $pattern/text[3]) and $pred" />
    <xsl:variable name="empty2" select="boolean($pattern/text[2] = '')" />
    <xsl:variable name="empty3" select="boolean($pattern/text[3] = '')" />
    <!-- Write headings of a group, indicating the level of -->
    <!-- each heading (up to 3 levels) and then follow with -->
    <!-- the associated locators.                           -->

    <!-- First key differs from predecessor, or leads letter group  -->
    <!-- if $empty2 is true, then headings are complete and time to -->
    <!-- write locators.  The next conditional will fail so no more -->
    <!-- output for this heading group. -->
    <xsl:if test="not($match1)">
        <xsl:call-template name="present-index-heading">
            <xsl:with-param name="the-index-list" select="$the-index-list"/>
            <xsl:with-param name="heading-group" select="$heading-group"/>
            <xsl:with-param name="b-write-locators" select="$empty2"/>
            <xsl:with-param name="heading-level" select="1"/>
            <xsl:with-param name="content" select="$pattern/text[1]/node()"/>
        </xsl:call-template>
    </xsl:if>

    <!-- Second key is substantial, and mis-match is in the second key,  -->
    <!-- or first key (ie to the left).  If $empty3 is true, then        -->
    <!-- headings are complete and time to write locators.  The next     -->
    <!-- conditional will fail so no more output for this heading group. -->
    <xsl:if test="not($empty2) and (not($match1) or not($match2))">
        <xsl:call-template name="present-index-heading">
            <xsl:with-param name="the-index-list" select="$the-index-list"/>
            <xsl:with-param name="heading-group" select="$heading-group"/>
            <xsl:with-param name="b-write-locators" select="$empty3"/>
            <xsl:with-param name="heading-level" select="2"/>
            <xsl:with-param name="content" select="$pattern/text[2]/node()"/>
        </xsl:call-template>
    </xsl:if>

    <!-- Third key is substantial, and mis-match is in the first key, -->
    <!-- the second key, or the third key (ie to the left).  Last     -->
    <!-- chance to write locators, so we pass true.                   -->
    <xsl:if test="not($empty3) and (not($match1) or not($match2) or not($match3))">
        <xsl:call-template name="present-index-heading">
            <xsl:with-param name="the-index-list" select="$the-index-list"/>
            <xsl:with-param name="heading-group" select="$heading-group"/>
            <xsl:with-param name="b-write-locators" select="true()"/>
            <xsl:with-param name="heading-level" select="3"/>
            <xsl:with-param name="content" select="$pattern/text[3]/node()"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<xsl:template name="present-index-heading">
    <xsl:param name="the-index-list"/>
    <xsl:param name="heading-group"/>
    <xsl:param name="b-write-locators"/>
    <xsl:param name="heading-level"/>
    <xsl:param name="content"/>

    <xsl:message>PTX:BUG:    a conversion to a new output format requires implementation of a named template ("present-index-heading") in order to format a single heading of an index entry.</xsl:message>
</xsl:template>


<!-- Place all the locators into the div for -->
<!-- the final (sub)item in its own span.    -->

<!-- Chicago Manual of Style, 15th edition, 18.14 - 18.22  -->
<!-- "see", following main entry, 18.16                    -->
<!--    Period after entry                                 -->
<!--    "See" capitalized (assumed from localization file) -->
<!--     multiple: alphabetical order, semicolon separator -->
<!-- "see", following a subentry, 18.17                    -->
<!--    Space after entry                                  -->
<!--    "see" lower case                                   -->
<!--    wrapped in parentheses                             -->
<!-- "see also", following main entry, 18.19               -->
<!--    Period after entry                                 -->
<!--    "See" capitalized (assumed from localization file) -->
<!--     multiple: alphabetical order, semicolon separator -->
<!-- "see", following a subentry, 18.19                    -->
<!--    Space after entry                                  -->
<!--    "see" lower case                                   -->
<!--    wrapped in parentheses                             -->
<!-- generic references, 18.22                             -->
<!--   TODO: use content of "see" and "seealso"            -->
<xsl:template name="locator-list">
    <xsl:param name="the-index-list"/>
    <xsl:param name="heading-group"/>
    <xsl:param name="cross-reference-separator"/>

    <!-- Some formatting depends on presence of subentries -->
    <xsl:variable name="b-has-subentry" select="not(text[2] = '')"/>
    <!-- range through node-list, making cross-references -->
    <!-- Use a comma after the heading, then prefix each  -->
    <!-- cross-reference with a space as separators       -->
    <xsl:call-template name="present-index-locator">
        <xsl:with-param name="content">
            <xsl:choose>
                <xsl:when test="$heading-group/see and not($b-has-subentry)">
                    <xsl:text>. </xsl:text>
                </xsl:when>
                <!-- no punctuation, will earn parentheses -->
                <xsl:when test="$heading-group/see and $b-has-subentry">
                    <xsl:text> </xsl:text>
                </xsl:when>
                <!-- cross-reference, w/ or w/out "see also" -->
                <!-- don't do anything as we will prefix     -->
                <!-- instances of "cross-reference" below    -->
                <xsl:otherwise/>
            </xsl:choose>
            <!-- course over the "index" in the group -->
            <xsl:for-each select="$heading-group">
                <xsl:choose>
                    <!--  -->
                    <xsl:when test="cross-reference">
                        <!-- *prefix* with a separator, since we do not     -->
                        <!-- create it previously and this way we can avoid -->
                        <!-- determining the last "cross-reference" element -->
                        <!-- (which seems difficult)                        -->
                        <xsl:value-of select="$cross-reference-separator"/>
                        <xsl:copy-of select="cross-reference/node()"/>
                    </xsl:when>
                    <!--  -->
                    <!-- Various uses of  position()  here are not as dangerous -->
                    <!-- as they seem, since the nodeset comes from an RTF of   -->
                    <!-- our construction.  Still, remove them in an eventual   -->
                    <!-- refactor and abstraction of index construction.        -->
                    <xsl:when test="see">
                        <xsl:call-template name="present-index-see">
                            <xsl:with-param name="content">
                            <xsl:if test="position() = 1">
                                <xsl:if test="$b-has-subentry">
                                    <xsl:text>(</xsl:text>
                                </xsl:if>
                                <xsl:call-template name="present-index-italics">
                                    <xsl:with-param name="content">
                                    <xsl:choose>
                                        <xsl:when test="$b-has-subentry">
                                            <!-- lower-case "see" -->
                                            <xsl:variable name="upper">
                                                <xsl:apply-templates select="$the-index-list" mode="type-name">
                                                    <xsl:with-param name="string-id" select="'see'"/>
                                                </xsl:apply-templates>
                                            </xsl:variable>
                                            <xsl:value-of select="translate(substring($upper, 1, 1), &UPPERCASE;, &LOWERCASE;)"/>
                                            <xsl:value-of select="substring($upper, 2)"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <!-- upper-case "See" -->
                                            <xsl:apply-templates select="$the-index-list" mode="type-name">
                                                <xsl:with-param name="string-id" select="'see'"/>
                                            </xsl:apply-templates>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:if>
                            <!-- just a space after "see", before first  -->
                            <!-- semi-colon before second and subsequent -->
                            <xsl:choose>
                                <xsl:when test="position() = 1">
                                    <xsl:text> </xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>; </xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:copy-of select="see/node()" />
                            <xsl:if test="$b-has-subentry and (position() = last())">
                                <xsl:text>)</xsl:text>
                            </xsl:if>
                        </xsl:with-param>
                    </xsl:call-template>
                    </xsl:when>
                    <!--  -->
                    <xsl:when test="seealso">
                        <xsl:if test="preceding-sibling::index[1]/cross-reference and not($b-has-subentry)">
                            <xsl:text>. </xsl:text>
                        </xsl:if>
                        <xsl:call-template name="present-index-see-also">
                            <xsl:with-param name="content">
                            <xsl:choose>
                                <xsl:when test="preceding-sibling::index[1]/cross-reference">
                                    <xsl:choose>
                                        <xsl:when test="$b-has-subentry">
                                            <xsl:text> </xsl:text>
                                            <xsl:text>(</xsl:text>
                                            <xsl:call-template name="present-index-italics">
                                                <xsl:with-param name="content">
                                                <!-- lower-case "see also" -->
                                                <xsl:variable name="upper">
                                                    <xsl:apply-templates select="$the-index-list" mode="type-name">
                                                            <xsl:with-param name="string-id" select="'also'"/>
                                                    </xsl:apply-templates>
                                                </xsl:variable>
                                                <xsl:value-of select="translate(substring($upper, 1, 1), &UPPERCASE;, &LOWERCASE;)"/>
                                                <xsl:value-of select="substring($upper, 2)"/>
                                                </xsl:with-param>
                                            </xsl:call-template>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:call-template name="present-index-italics">
                                                <xsl:with-param name="content">
                                                <!-- upper-case "See also" -->
                                                <xsl:apply-templates select="$the-index-list" mode="type-name">
                                                        <xsl:with-param name="string-id" select="'also'"/>
                                                </xsl:apply-templates>
                                                </xsl:with-param>
                                            </xsl:call-template>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>;</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:text> </xsl:text>
                            <xsl:copy-of select="seealso/node()"/>
                            <xsl:if test="(position() = last()) and $b-has-subentry">
                                <xsl:text>)</xsl:text>
                            </xsl:if>
                        </xsl:with-param>
                    </xsl:call-template>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>


<xsl:template name="present-index-locator">
    <xsl:param name="content"/>

    <xsl:message>PTX:BUG:    a conversion to a new output format requires implementation of a named template ("present-index-locator") in order to format a locator at the end of an index entry.</xsl:message>
</xsl:template>

<xsl:template name="present-index-see">
    <xsl:param name="content"/>

    <xsl:message>PTX:BUG:    a conversion to a new output format requires implementation of a named template ("present-index-see") in order to format a "see" cross-reference at the end of an index entry.</xsl:message>
</xsl:template>

<xsl:template name="present-index-see-also">
    <xsl:param name="content"/>

    <xsl:message>PTX:BUG:    a conversion to a new output format requires implementation of a named template ("present-index-see-also") in order to format a "see also" coross-reference at the end of an index entry.</xsl:message>
</xsl:template>

<xsl:template name="present-index-italics">
    <xsl:param name="content"/>

    <xsl:message>PTX:BUG:    a conversion to a new output format requires implementation of a named template ("present-index-italics") in order to format italic text at the end of an index entry.</xsl:message>
</xsl:template>



<!-- ############### -->
<!-- Arbitrary Lists -->
<!-- ############### -->

<!-- Format-independent construction of a list of    -->
<!-- intermediate elements, in order of appearance,  -->
<!-- with headings from indicated divisions          -->
<!--                                                 -->
<!-- Implementation requires four abstract templates -->
<!--                                                 -->
<!-- 1.  name="list-of-begin"                        -->
<!-- hook for start of list                          -->
<!--                                                 -->
<!-- 2.  mode="list-of-heading"                      -->
<!-- Format/output per division                      -->
<!--                                                 -->
<!-- 3.  mode="list-of-element"                      -->
<!-- Format/output per element                       -->
<!--                                                 -->
<!-- 4. name="list-of-end"                           -->
<!-- hook for end of list                            -->

<!-- NB: possible improvements -->
<!-- 1.  Get $subroot via @ref and work with element, not a string            -->
<!-- 2.  Somehow abandon user strings sooner, so less reliant on local-name() -->

<xsl:template match="list-of">
    <xsl:param name="heading-level"/>

    <!-- "str:tokenize()" in this form makes a node-set, which has no root -->
    <!-- the elements may be "token" but that is irrelevant for use below  -->
    <!-- Documentation may say spaces, we also allow comma as a delimiter  -->
    <xsl:variable name="elements" select="str:tokenize(@elements, ', ')"/>
    <xsl:variable name="divisions" select="str:tokenize(@divisions, ', ')"/>
    <!-- Lists of various types of exercises can be useful, but they are         -->
    <!-- categorized by their ancestors.  So we recognize certain strings        -->
    <!-- as "pseudo-elements".  We do this once and then pass them along.        -->
    <!--                                                                         -->
    <!--   * inlineexercise                                                      -->
    <!--   * divisionexercise                                                    -->
    <!--   * worksheetexercise                                                   -->
    <!--   * readingquestion                                                     -->
    <!--                                                                         -->
    <!-- Equality of strings (e.g. 'inlineexercise') and the node-set ($elements)-->
    <!-- is true when the *string-value* of *one* node in the set is identical   -->
    <!-- NB: if this gets out-of-hand, it should be passed as a structure        -->
    <xsl:variable name="b-inline-exercises" select="'inlineexercise' = $elements"/>
    <xsl:variable name="b-division-exercises" select="'divisionexercise' = $elements"/>
    <xsl:variable name="b-worksheet-exercises" select="'worksheetexercise' = $elements"/>
    <xsl:variable name="b-reading-questions" select="'readingquestion' = $elements"/>
    <!-- display subdivision headings with empty contents? -->
    <xsl:variable name="entered-empty">
        <xsl:choose>
            <xsl:when test="not(@empty)">
                <xsl:text>no</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@empty" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Schema restricts to 'yes' or 'no'.  Thus we can just interpret -->
    <!-- absent or anything-but-yes indicating to skip empty divisions. -->
    <xsl:variable name="b-empty" select="$entered-empty = 'yes'"/>
    <!-- root of the document subtree for list formation     -->
    <!-- defaults to document-wide                           -->
    <!-- DTD should enforce subdivisions as values for scope -->
    <!-- TODO: perhaps use @ref to indicate $subroot,  -->
    <!-- and protect against both a @scope and a @ref  -->
    <xsl:variable name="scope">
        <xsl:choose>
            <xsl:when test="@scope">
                <xsl:value-of select="@scope" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="local-name($document-root)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="subroot" select="ancestor-or-self::*[local-name() = $scope]" />
    <!-- variable behavior set, now setup -->
    <xsl:call-template name="list-of-begin" />
    <!-- recursive procedure, starting from indicated scope -->
    <xsl:apply-templates select="$subroot" mode="list-of-content">
        <!-- list-of was passed a heading level that was incremented by its parent division -->
        <!-- Since the list-of has no heading itself, we back this up by 1                  -->
        <xsl:with-param name="heading-level" select="$heading-level - 1"/>
        <xsl:with-param name="elements" select="$elements"/>
        <xsl:with-param name="divisions" select="$divisions"/>
        <xsl:with-param name="b-empty" select="$b-empty"/>
        <xsl:with-param name="b-inline-exercises" select="$b-inline-exercises"/>
        <xsl:with-param name="b-division-exercises" select="$b-division-exercises"/>
        <xsl:with-param name="b-worksheet-exercises" select="$b-worksheet-exercises"/>
        <xsl:with-param name="b-reading-questions" select="$b-reading-questions"/>
    </xsl:apply-templates>
    <xsl:call-template name="list-of-end" />
</xsl:template>

<xsl:template match="*" mode="list-of-content">
    <xsl:param name="heading-level"/>
    <xsl:param name="elements"/>
    <xsl:param name="divisions"/>
    <xsl:param name="b-empty"/>
    <xsl:param name="b-inline-exercises"/>
    <xsl:param name="b-division-exercises"/>
    <xsl:param name="b-worksheet-exercises"/>
    <xsl:param name="b-reading-questions"/>

    <!-- Check if we are at a divison that needs a heading                      -->
    <xsl:variable name="b-division-element" select="local-name(.) = $divisions"/>
    <xsl:choose>
        <xsl:when test="$b-division-element">
            <!-- handling a division element that *may* need a heading -->
            <xsl:choose>
                <xsl:when test="not($b-empty)">
                    <!-- probe subtree, even if we found empty super-tree earlier -->
                    <!-- to see if a heading is *needed*, author has elected to   -->
                    <!-- not have a heading if there are no elements to list      -->
                    <!-- N.B. these booleans look rather expensive, owing to the  -->
                    <!-- extensive searching for "exercise", but we hope the      -->
                    <!-- booleans passed in will short-circuit and result in no   -->
                    <!-- searching when it is not necessary                       -->
                    <xsl:variable name="by-name-elements" select="boolean(.//*[local-name(.) = $elements])" />
                    <xsl:variable name="division-exercises" select="$b-division-exercises and .//exercise[ancestor::exercises]"/>
                    <xsl:variable name="worksheet-exercises" select="$b-worksheet-exercises and .//exercise[ancestor::worksheet]"/>
                    <xsl:variable name="reading-questions" select="$b-reading-questions and .//exercise[ancestor::reading-questions]"/>
                    <xsl:variable name="inline-exercises" select="$b-inline-exercises and .//exercise[not(ancestor::exercises or ancestor::worksheet or ancestor::reading-questions)]"/>
                    <xsl:variable name="any-elements" select="$by-name-elements or $inline-exercises or $division-exercises or $worksheet-exercises or $reading-questions"/>
                    <xsl:if test="$any-elements">
                        <xsl:apply-templates select="." mode="list-of-heading">
                            <xsl:with-param name="heading-level" select="$heading-level"/>
                        </xsl:apply-templates>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$b-empty">
                    <!-- always write a heading, even if there will be no items listed -->
                    <xsl:apply-templates select="." mode="list-of-heading">
                        <xsl:with-param name="heading-level" select="$heading-level"/>
                    </xsl:apply-templates>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <!-- not at a division, so test element for inclusion -->
            <xsl:if test="(local-name(.) = $elements)
                       or ($b-division-exercises and self::exercise and ancestor::exercises)
                       or ($b-worksheet-exercises and self::exercise and ancestor::worksheet)
                       or ($b-reading-questions and self::exercise and ancestor::reading-questions)
                       or ($b-inline-exercises and self::exercise and not(ancestor::exercises or ancestor::worksheet or ancestor::reading-questions))">
                <xsl:apply-templates select="." mode="list-of-element" />
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
    <!-- recurse into children; recursion ends when no children   -->
    <!-- increment heading-level, correct right now for divisions -->
    <xsl:apply-templates select="*" mode="list-of-content">
        <xsl:with-param name="heading-level" select="$heading-level + 1"/>
        <xsl:with-param name="elements" select="$elements"/>
        <xsl:with-param name="divisions" select="$divisions"/>
        <xsl:with-param name="b-empty" select="$b-empty"/>
        <xsl:with-param name="b-inline-exercises" select="$b-inline-exercises"/>
        <xsl:with-param name="b-division-exercises" select="$b-division-exercises"/>
        <xsl:with-param name="b-worksheet-exercises" select="$b-worksheet-exercises"/>
        <xsl:with-param name="b-reading-questions" select="$b-reading-questions"/>
    </xsl:apply-templates>
</xsl:template>

<!-- Stub implementations, with warnings -->
<xsl:template name="list-of-begin">
     <xsl:message>PTX:BUG:   the "list-of-begin" template needs an implementation in the current conversion</xsl:message>
     <xsl:text>[[[BEGINLIST]]]</xsl:text>
 </xsl:template>

<xsl:template name="list-of-end">
     <xsl:message>PTX:BUG:   the "list-of-end" template needs an implementation in the current conversion</xsl:message>
     <xsl:text>[[[ENDLIST]]]</xsl:text>
 </xsl:template>


<!-- Programming Language Names -->
<!-- Packages for listing and syntax highlighting             -->
<!-- have their own ideas about the names of languages        -->
<!-- We use keys to perform the translation                   -->
<!-- See: https://gist.github.com/frabad/4189876              -->
<!-- for motivation and document() syntax for standalone file -->
<!-- Also: see contributors in FCLA work                      -->

<!-- The data: attribute is our usage, elements belong to     -->
<!-- other packages. Blank means not explicitly supported.    -->
<!-- Alphabetical by type.                                    -->

<!-- Prism: -->
<!-- Last reviewed 2020-10-21                        -->
<!-- 2020-10-21: Cutover from Google Code Prettifier -->

<!-- Listings: -->
<!-- Last reviewed carefully: 2014/06/28           -->
<!-- Exact matches, or best guesses, some          -->
<!-- unimplemented.  [] notation is for variants.  -->
<!-- 2019-09-23: minor review, v 1.7 (2018-09-02)  -->

<!-- ActiveCode (Runestone) -->
<!-- Languages supported by Runestone ActiveCode and  -->
<!-- CodeLens interactive elements, added 2020-08-13. -->
<!-- "python3" is just on Runestone servers where     -->
<!-- additional popular packages (e.g. numpy, pandas) -->
<!-- are available.                                   -->

<!-- Our strings (@ptx) are always all-lowercase, no symbols, no punctuation -->
<mb:programming>
    <!-- Procedural -->
    <language ptx="basic"       active=""            listings="Basic"            prism="basic"/>
    <language ptx="c"           active="c"           listings="C"                prism="c"/>
    <language ptx="cpp"         active="cpp"         listings="C++"              prism="cpp"/>
    <language ptx="go"          active=""            listings="C"                prism="go"/>
    <language ptx="java"        active="java"        listings="Java"             prism="java"/>
    <language ptx="javascript"  active="javascript"  listings=""                 prism="javascript"/>
    <language ptx="kotlin"      active="kotlin"      listings=""                 prism="kotlin"/>
    <language ptx="lua"         active=""            listings="Lua"              prism="lua"/>
    <language ptx="pascal"      active=""            listings="Pascal"           prism="pascal"/>
    <language ptx="perl"        active=""            listings="Perl"             prism="perl"/>
    <language ptx="python"      active="python"      listings="Python"           prism="py"/>
    <language ptx="python3"     active="python3"     listings="Python"           prism="py"/>
    <language ptx="r"           active=""            listings="R"                prism="r"/>
    <language ptx="s"           active=""            listings="S"                prism="s"/>
    <language ptx="sas"         active=""            listings="SAS"              prism="s"/>
    <language ptx="sage"        active=""            listings="Python"           prism="py"/>
    <language ptx="splus"       active=""            listings="[Plus]S"          prism="s"/>
    <language ptx="vbasic"      active=""            listings="[Visual]Basic"    prism="visual-basic"/>
    <language ptx="vbscript"    active=""            listings="VBscript"         prism="visual-basic"/>
    <!-- Others (esp. functional)  -->
    <language ptx="clojure"     active=""            listings="Lisp"             prism="clojure"/>
    <language ptx="lisp"        active=""            listings="Lisp"             prism="lisp"/>
    <language ptx="clisp"       active=""            listings="Lisp"             prism="lisp"/>
    <language ptx="elisp"       active=""            listings="Lisp"             prism="elisp"/>
    <language ptx="scheme"      active=""            listings="Lisp"             prism="scheme"/>
    <language ptx="racket"      active=""            listings="Lisp"             prism="racket"/>
    <language ptx="sql"         active="sql"         listings="SQL"              prism="sql"/>
    <language ptx="llvm"        active=""            listings="LLVM"             prism="llvm"/>
    <language ptx="matlab"      active=""            listings="Matlab"           prism="matlab"/>
    <language ptx="octave"      active="octave"      listings="Octave"           prism="matlab"/>
    <language ptx="ml"          active=""            listings="ML"               prism=""/>
    <language ptx="ocaml"       active=""            listings="[Objective]Caml"  prism="ocaml"/>
    <language ptx="fsharp"      active=""            listings="ML"               prism="fsharp"/>
    <!-- Text Manipulation -->
    <language ptx="css"         active=""            listings=""                 prism="css"/>
    <language ptx="latex"       active=""            listings="[LaTeX]TeX"       prism="latex"/>
    <language ptx="html"        active="html"        listings="HTML"             prism="html"/>
    <language ptx="tex"         active=""            listings="[plain]TeX"       prism="tex"/>
    <language ptx="xml"         active=""            listings="XML"              prism="xml"/>
    <language ptx="xslt"        active=""            listings="XSLT"             prism="xml"/>
</mb:programming>

<!-- Define the key for indexing into the data list -->
<xsl:key name="proglang" match="language" use="@ptx" />
<!-- And make a variable with the context for key lookups useing that key -->
<!-- doing the 'document('')/*/mb:programming' repeatedly is expensive.   -->
<!-- (Especially in program|pf[prism-language]                            -->
<xsl:variable name="proglang-key-context" select="exsl:node-set(document('')/*/mb:programming)"/>

<!-- Define variables for default active language - will be picked up by -->
<!-- RS manifest and can be a different string than the raw language. -->
<xsl:variable name="default-active-programming-language">
    <xsl:if test="$version-docinfo/programs/@language">
        <xsl:for-each select="$proglang-key-context">
            <xsl:value-of select="key('proglang', $version-docinfo/programs/@language)/@active" />
        </xsl:for-each>
    </xsl:if>
</xsl:variable>

<!-- Determine programming language to use. First choice is @language     -->
<!-- on current element. If that is not available, check docinfo default. -->
<!-- "exercise" might be a Runestone interactive (programming) exercise.  -->
<xsl:template match="program|pf" mode="get-programming-language">
    <xsl:call-template name="get-program-attr-or-default">
        <xsl:with-param name="attr" select="'language'"/>
    </xsl:call-template>
</xsl:template>

<!-- For a parsons, use @language, default parsons language, or default -->
<!-- programming language in that order of preference.                  -->
<xsl:template match="*[@exercise-interactive = 'parson' or @exercise-interactive = 'parson-horizontal']" mode="get-programming-language">
    <xsl:choose>
        <xsl:when test="@language">
            <xsl:value-of select="@language" />
        </xsl:when>
        <xsl:when test="$version-docinfo/parsons/@language">
            <xsl:value-of select="$version-docinfo/parsons/@language" />
        </xsl:when>
        <xsl:when test="$version-docinfo/programs/@language">
            <xsl:value-of select="$version-docinfo/programs/@language" />
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- A whole <program> node comes in,  -->
<!-- text of ActiveCode name comes out -->
<xsl:template match="program|*[@exercise-interactive = 'parson' or @exercise-interactive = 'parson-horizontal']" mode="active-language">
    <xsl:variable name="language">
        <xsl:apply-templates select="." mode="get-programming-language"/>
    </xsl:variable>
    <xsl:for-each select="$proglang-key-context">
        <xsl:value-of select="key('proglang', $language)/@active" />
    </xsl:for-each>
</xsl:template>

<!-- A whole <program> node comes in,  -->
<!-- text of listings name comes out -->
<xsl:template match="program|pf" mode="listings-language">
    <xsl:variable name="language">
        <xsl:apply-templates select="." mode="get-programming-language"/>
    </xsl:variable>
    <xsl:for-each select="$proglang-key-context">
        <xsl:value-of select="key('proglang', $language)/@listings" />
    </xsl:for-each>
</xsl:template>

<!-- This works, without keys, and could be adapted to range over actual data in text -->
<!-- For example, this approach is used for contributors to FCLA                      -->
<!--
<xsl:template match="*" mode="listings-language">
    <xsl:variable name="language">
        <xsl:value-of select="@language"/>
    </xsl:variable>
    <xsl:value-of select="document('')/*/mb:programming/language[@ptx=$language]/listings"/>
</xsl:template>
-->

<!-- A whole <program> node comes in,  -->
<!-- text of prism name comes out -->
<xsl:template match="program|pf" mode="prism-language">
    <xsl:variable name="language">
        <xsl:apply-templates select="." mode="get-programming-language"/>
    </xsl:variable>
    <xsl:for-each select="$proglang-key-context">
        <xsl:value-of select="key('proglang', $language)/@prism" />
    </xsl:for-each>
</xsl:template>

<!-- Try an attribute, and if it does not exist, try to get it from docinfo -->
<!-- if that fails, use the optional default passed in                      -->
<xsl:template name="get-program-attr-or-default">
    <xsl:param name="attr"/>
    <xsl:param name="default" select="''"/>
    <xsl:choose>
        <xsl:when test="@*[name() = $attr]">
            <xsl:value-of select="@*[name() = $attr]" />
        </xsl:when>
        <xsl:when test="$docinfo/programs/@*[name() = $attr]">
            <xsl:value-of select="$docinfo/programs/@*[name() = $attr]" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$default" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Helper templates to ensure consistent processing of whitespace in programs. -->
<!-- We trim leading/trailing whitespace, but preserve possible intentionally    -->
<!-- authored space as follows:                                                  -->
<!--   preamble: preserve trailing                                               -->
<!--   code: preserve leading/trailing                                           -->
<!--   postamble/tests: preserve leading                                         -->
<xsl:template match="preamble|code|postamble|tests" mode="program-part-processing">
    <xsl:call-template name="trim-start-lines">
        <xsl:with-param name="text">
            <xsl:call-template name="trim-end">
                <xsl:with-param name="text" select="." />
                <xsl:with-param name="preserve-intentional" select="self::preamble or self::code" />
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="preserve-intentional" select="self::code or self::postamble or self::tests" />
    </xsl:call-template>
</xsl:template>

<!-- ############################ -->
<!-- Table construction utilities -->
<!-- ############################ -->

<!-- These templates provide frequently-used      -->
<!-- functions for the construction of tables.    -->
<!-- Document uses carefully when newly employed. -->

<!-- Translate thickness attribute value to integer short name -->
<!-- HTML: makes portion of CSS class names for cells          -->
<!-- PG: makes portion of optional parameter for DataTable     -->
<!-- macro from niceTable.pl for thickness of table cells      -->
<xsl:template name="thickness-specification">
    <xsl:param name="width" />
    <xsl:choose>
        <xsl:when test="$width='none'">
            <xsl:text>0</xsl:text>
        </xsl:when>
        <xsl:when test="$width='minor'">
            <xsl:text>1</xsl:text>
        </xsl:when>
        <xsl:when test="$width='medium'">
            <xsl:text>2</xsl:text>
        </xsl:when>
        <xsl:when test="$width='major'">
            <xsl:text>3</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING: tabular rule thickness not recognized: use none, minor, medium, major</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate horizontal alignment to CSS short name    -->
<!-- HTML:  makes portion of CSS class names for cells   -->
<!-- LaTeX: provides standard LaTeX horizontal alignment -->
<!-- PG: provide LaTeX-style alignment string for        -->
<!-- DataTable macro from niceTable.pl                   -->
<xsl:template name="halign-specification">
    <xsl:param name="align" />
    <xsl:choose>
        <xsl:when test="$align='left' or $align='justify'">
            <xsl:text>l</xsl:text>
        </xsl:when>
        <xsl:when test="$align='center'">
            <xsl:text>c</xsl:text>
        </xsl:when>
        <xsl:when test="$align='right'">
            <xsl:text>r</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING: tabular horizontal alignment attribute not recognized: use left, center, right, justify</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate vertical alignment to CSS short name         -->
<!-- HTML:  makes portion of CSS class names for cells      -->
<!-- LaTeX: provides one standard LaTeX vertical alignment  -->
<!-- PG: provide LaTeX-style alignment string for           -->
<!-- DataTable macro from niceTable.pl                      -->
<xsl:template name="valign-specification">
    <xsl:param name="align" />
    <xsl:choose>
        <xsl:when test="$align='top'">
            <xsl:text>t</xsl:text>
        </xsl:when>
        <xsl:when test="$align='middle'">
            <xsl:text>m</xsl:text>
        </xsl:when>
        <xsl:when test="$align='bottom'">
            <xsl:text>b</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING: tabular vertical alignment attribute not recognized: use top, middle, bottom</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################### -->
<!-- Structured by Lines -->
<!-- ################### -->

<!-- Some items, such as an address or an attribution,          -->
<!-- can be formatted like a poem, as a sequence of lines,      -->
<!-- without really being able to say just why or how in        -->
<!-- advance via markup.  So the schema will allow an element   -->
<!-- to be a simple, single line of text, OR a sequence of      -->
<!-- "line" elements (only), each "line" being the same simple  -->
<!-- text.  Generally, all we need is an abstract separator for -->
<!-- the first n-1 lines.  What happens after the last line     -->
<!-- should be in agreement with the single line version.       -->


<!-- Allowed to be structured, and handled abstractly -->
<!--   * department (author, editor, etc.)            -->
<!--   * institution (author, editor, etc.)           -->
<!--   * dedication/p                                 -->
<!--   * attribution                                  -->
<!--   * cell (tabular/row/cell/line)                 -->
<!--                                                  -->
<!-- Specialized, handled specifically (ie not here)  -->
<!--   * poem/stanza/line                             -->
<!--   * letter/frontmatter/to/line (from) (LaTeX)    -->
<!--   * memo/frontmatter/to/line (from) (LaTeX)      -->

<!-- The markup, and visual source necessary for the  -->
<!-- end of each line, default indicates a problem    -->
<!-- Needs an override for each conversion            -->
<xsl:template name="line-separator">
    <xsl:text>[LINESEP]</xsl:text>
</xsl:template>

<!-- Explicitly assumes a sequence of "line" -->
<xsl:template match="line">
    <xsl:apply-templates/>
    <!-- is there a next line to separate? -->
    <xsl:if test="following-sibling::line">
        <xsl:call-template name="line-separator"/>
    </xsl:if>
</xsl:template>


<!-- ################ -->
<!-- Poetry Utilities -->
<!-- ################ -->

<!-- These inherit from their containers,    -->
<!-- which is why "poem" has a default value -->

<xsl:template match="poem|poem/author|stanza|stanza/line" mode="poem-indent">
    <xsl:choose>
        <xsl:when test="@indent">
            <xsl:value-of select="@indent" />
        </xsl:when>
        <xsl:when test="self::poem">
            <xsl:text>0</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="poem-indent" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="poem|poem/author|stanza|stanza/line" mode="poem-halign">
    <xsl:choose>
        <xsl:when test="@halign">
            <xsl:value-of select="@halign" />
        </xsl:when>
        <xsl:when test="self::poem">
            <xsl:text>left</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="poem-halign" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ##### -->
<!-- Music -->
<!-- ##### -->

<!-- Uses inline math rendering -->
<xsl:template match="n|scaledeg|timesignature|chord">
    <xsl:call-template name="inline-math-wrapper">
        <xsl:with-param name="math">
            <xsl:apply-templates select="." mode="inner-music"/>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Note -->
<xsl:template match="n" mode="inner-music">
    <!-- Test that pitch class is NOT castable as a number -->
    <xsl:if test="not(number(@pc) = number(@pc))">
        <xsl:text>\text{</xsl:text>
        <xsl:value-of select="@pc"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <!-- Provide something to place accidental -->
    <!-- on if the pitch class is numeric.     -->
    <xsl:if test="number(@pc) = number(@pc) and @acc">
        <xsl:text>{}</xsl:text>
    </xsl:if>
    <!-- Add an accidental if applicable -->
    <xsl:if test="@acc">
        <xsl:text>^</xsl:text>
        <xsl:call-template name="accidentals">
            <xsl:with-param name="accidental"><xsl:value-of select="@acc"/></xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <!-- Test that pitch class IS castable as a number -->
    <!-- Accidentals precede numeric pitch classes     -->
    <xsl:if test="number(@pc) = number(@pc)">
        <xsl:value-of select="@pc"/>
    </xsl:if>
    <!-- Add an octave number if applicable -->
    <xsl:if test="@octave">
        <!-- Consideration: should we accommodate other octave notations?    -->
        <!-- Current support is for scientific pitch notation (the standard), -->
        <!-- other octave notation exists such as "Helmholtz pitch notation"  -->
        <xsl:text>_{</xsl:text>
        <xsl:value-of select="@octave"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Scale Degrees -->
<xsl:template match="scaledeg" mode="inner-music">
    <!-- Arabic numeral with circumflex accent above)-->
    <xsl:text>\hat{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
    <!-- TODO: unclear if trailing space is necessary -->
    <xsl:text> </xsl:text>
</xsl:template>

<!-- Time Signatures -->
<xsl:template match="timesignature" mode="inner-music">
    <xsl:text>\begin{smallmatrix}</xsl:text>
    <xsl:value-of select="@top"/>
    <xsl:text>\\</xsl:text>
    <xsl:value-of select="@bottom"/>
    <xsl:text>\end{smallmatrix}</xsl:text>
</xsl:template>

<!-- Chord -->
<xsl:template match="chord" mode="inner-music">
    <xsl:text>\left.</xsl:text>
    <!-- Root -->
    <xsl:choose>
        <!-- There is an accidental -->
        <xsl:when test="contains(@root, ' ')">
            <!-- Pitch Class -->
            <xsl:text>\text{</xsl:text>
            <xsl:value-of select="substring-before(@root, ' ')"/>
            <xsl:text>}</xsl:text>
            <!-- Accidental -->
            <xsl:text>^</xsl:text>
            <xsl:call-template name="accidentals">
                <xsl:with-param name="accidental"><xsl:value-of select="substring-after(@root, ' ')"/></xsl:with-param>
            </xsl:call-template>
            <!-- prevent "double superscript" error -->
            <xsl:text>{}</xsl:text>
        </xsl:when>
        <!-- There is not an accidental -->
        <xsl:otherwise>
            <xsl:text>\text{</xsl:text>
            <xsl:value-of select="@root"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- Mode (augmented, major, minor, half-diminished, diminished, etc.) -->
    <xsl:if test="@mode">
        <xsl:choose>
            <!-- There is a two part mode -->
            <xsl:when test="contains(@mode, ' ')">
                <!-- Lower Mode -->
                <xsl:call-template name="chordsymbols">
                    <xsl:with-param name="mode"><xsl:value-of select="substring-before(@mode, ' ')"/></xsl:with-param>
                </xsl:call-template>
                <!-- Raise to be in line with bps -->
                <xsl:text>^</xsl:text>
                <!-- Higher Mode -->
                <xsl:call-template name="chordsymbols">
                    <xsl:with-param name="mode"><xsl:value-of select="substring-after(@mode, ' ')"/></xsl:with-param>
                </xsl:call-template>
                <!-- prevent "double superscript" error -->
                <xsl:text>{}</xsl:text>
            </xsl:when>
            <!-- There is a single mode -->
            <xsl:otherwise>
                <xsl:call-template name="chordsymbols">
                    <xsl:with-param name="mode"><xsl:value-of select="@mode"/></xsl:with-param>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- Bass Position Symbol -->
    <xsl:if test="@bps">
        <!-- Consideration: Even if it is not standard practice, -->
        <!-- will anyone ever want more than two bps numbers?    -->
        <xsl:choose>
            <!-- We use a space to delineate the breaking point of the bps -->
            <!-- e.g. for 6/4 we write "6 4" -->
            <xsl:when test="contains(@bps, ' ')">
                <xsl:text>^{</xsl:text>
                <xsl:value-of select="substring-before(@bps, ' ')"/>
                <xsl:text>}</xsl:text>
                <xsl:text>_{</xsl:text>
                <xsl:value-of select="substring-after(@bps, ' ')"/>
                <xsl:text>}</xsl:text>
            </xsl:when>
            <!-- If there is no space, then we only need a superscript -->
            <xsl:otherwise>
                <xsl:text>^{</xsl:text>
                <xsl:value-of select="@bps"/>
                <xsl:text>}</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- Suspended -->
    <xsl:if test="@suspended = 'yes'">
        <!-- Consideration: should we make "sus" localized/customizable? -->
        <xsl:text>\text{sus}</xsl:text>
    </xsl:if>
    <!-- Chord Alterations -->
    <xsl:if test="./*">
        <xsl:choose>
            <!-- Turning off parentheses is usually for showing why parenthesization clarifies meaning. -->
            <xsl:when test="@parentheses = 'no'">
                <xsl:text>\left.</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>\left(</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <!-- We only use a smallmatrix if we have more than one alteration         -->
        <!-- Using smallmatrix with a single entry makes the alteration too small. -->
        <xsl:if test="count(*) > 1">
            <xsl:text>\begin{smallmatrix}</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="*"/>
        <xsl:if test="count(*) > 1">
            <xsl:text>\end{smallmatrix}</xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="@parentheses = 'no'">
                <xsl:text>\right.</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>\right)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- Alternate Bass Note (e.g. C/G) -->
    <xsl:if test="@bass">
        <!-- Resizes based on components of chord -->
        <xsl:text>\middle/</xsl:text>
        <xsl:choose>
            <!-- Bass note has an accidental -->
            <xsl:when test="contains(@bass, ' ')">
                <!-- Pitch Class -->
                <xsl:text>\text{</xsl:text>
                <xsl:value-of select="substring-before(@bass, ' ')"/>
                <xsl:text>}</xsl:text>
                <!-- Accidental -->
                <xsl:text>^{</xsl:text>
                <xsl:call-template name="accidentals">
                    <xsl:with-param name="accidental"><xsl:value-of select="substring-after(@bass, ' ')"/></xsl:with-param>
                </xsl:call-template>
                <xsl:text>}</xsl:text>
            </xsl:when>
            <!-- Bass note does not have an accidental -->
            <xsl:otherwise>
                <!-- Pitch Class -->
                <xsl:text>\text{</xsl:text>
                <xsl:value-of select="@bass"/>
                <xsl:text>}</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <xsl:text>\right.</xsl:text>
</xsl:template>

<!-- Chord Alteration -->
<!-- Put a break after each alteration that is not the last -->
<xsl:template match="chord/alteration">
    <xsl:text>\text{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
    <!-- Separate alterations -->
    <xsl:if test="following-sibling::*">
        <xsl:text>\\</xsl:text>
    </xsl:if>
</xsl:template>

<!--                 -->
<!-- Musical Symbols -->
<!--                 -->

<!-- Accidentals -->

<!-- TODO: If requested, add semi- and sesqui- versions of sharp and flat -->
<!-- (Easy with LilyPond in LaTeX) -->
<!-- (For HTML ,there are Unicode characters, though font support may be iffy) -->

<!-- Double-Sharp -->
<xsl:template match="doublesharp">
    <xsl:call-template name="doublesharp"/>
</xsl:template>

<!-- Sharp -->
<xsl:template match="sharp">
    <xsl:call-template name="sharp"/>
</xsl:template>

<!-- Natural -->
<xsl:template match="natural">
    <xsl:call-template name="natural"/>
</xsl:template>

<!-- Flat -->
<xsl:template match="flat">
    <xsl:call-template name="flat"/>
</xsl:template>

<!-- Double-Flat -->
<xsl:template match="doubleflat">
    <xsl:call-template name="doubleflat"/>
</xsl:template>

<!-- Insert the correct accidental -->
<!-- (For use in <n> and <chord>)  -->
<xsl:template name="accidentals">
    <xsl:param name="accidental"/>
    <xsl:choose>
        <xsl:when test="$accidental = 'doubleflat'">
            <xsl:call-template name="doubleflat"/>
        </xsl:when>
        <xsl:when test="$accidental = 'flat'">
            <xsl:call-template name="flat"/>
        </xsl:when>
        <xsl:when test="$accidental = 'natural'">
            <xsl:call-template name="natural"/>
        </xsl:when>
        <xsl:when test="$accidental = 'sharp'">
            <xsl:call-template name="sharp"/>
        </xsl:when>
        <xsl:when test="$accidental = 'doublesharp'">
            <xsl:call-template name="doublesharp"/>
        </xsl:when>
        <!-- For unknown accidentals, use the given value wrapped in \text{} -->
        <xsl:otherwise>
            <xsl:text>\text{</xsl:text>
            <xsl:value-of select="$accidental"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Fall-Back values for Accidentals -->

<!-- Double-Sharp -->
<xsl:template name="doublesharp">
    <xsl:text>[DOUBLESHARP]</xsl:text>
</xsl:template>

<!-- Sharp -->
<xsl:template name="sharp">
    <xsl:text>[SHARP]</xsl:text>
</xsl:template>

<!-- Natural -->
<xsl:template name="natural">
    <xsl:text>[NATURAL]</xsl:text>
</xsl:template>

<!-- Flat -->
<xsl:template name="flat">
    <xsl:text>[FLAT]</xsl:text>
</xsl:template>

<!-- Double-Flat -->
<xsl:template name="doubleflat">
    <xsl:text>[DOUBLEFLAT]</xsl:text>
</xsl:template>

<!-- Insert the correct chord symbol -->
<!-- (For use in <chord>)  -->
<xsl:template name="chordsymbols">
    <xsl:param name="mode"/>
    <xsl:choose>
        <xsl:when test="$mode = 'augmented'">
            <xsl:call-template name="augmentedchordsymbol"/>
        </xsl:when>
        <xsl:when test="$mode = 'major'">
            <xsl:call-template name="majorchordsymbol"/>
        </xsl:when>
        <xsl:when test="$mode = 'minor'">
            <xsl:call-template name="minorchordsymbol"/>
        </xsl:when>
        <xsl:when test="$mode = 'halfdiminished'">
            <xsl:text>^</xsl:text>
            <xsl:call-template name="halfdiminishedchordsymbol"/>
            <xsl:text>{}</xsl:text>
        </xsl:when>
        <xsl:when test="$mode = 'diminished'">
            <xsl:text>^</xsl:text>
            <xsl:call-template name="diminishedchordsymbol"/>
            <xsl:text>{}</xsl:text>
        </xsl:when>
        <!-- For unknown chord symbols, use the given value wrapped in \text{} -->
        <!-- e.g. mode="maj" will use \text{maj}                               -->
        <xsl:otherwise>
            <xsl:text>\text{</xsl:text>
            <xsl:value-of select="$mode"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Chord Symbols -->

<!-- Augmented -->
<xsl:template name="augmentedchordsymbol">
    <xsl:text>{+}</xsl:text>
</xsl:template>

<!-- Major -->
<xsl:template name="majorchordsymbol">
    <xsl:text>{\Delta}</xsl:text>
</xsl:template>

<!-- Minor -->
<xsl:template name="minorchordsymbol">
    <xsl:text>{-}</xsl:text>
</xsl:template>

<!-- Half Diminished -->
<xsl:template name="halfdiminishedchordsymbol">
    <xsl:text>\text{\o}</xsl:text>
</xsl:template>

<!-- Diminished -->
<xsl:template name="diminishedchordsymbol">
    <xsl:text>{\circ}</xsl:text>
</xsl:template>

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- The logic of the visible text of a cross-reference is all  -->
<!-- here in the common routines. That text and the target node -->
<!-- is then sent to templates that are output-format-specific. -->

<!-- The actual manufacture of a (active) link is delegated  -->
<!-- to implementations, see abstract (null) implementations -->
<!-- at the end of the "utilities" section below             -->

<!-- Match on:                                       -->
<!--     @ref, no list: the most frequent case       -->
<!--     @ref, a list: mostly for bibliography lists -->
<!--     @first, @last: a range                      -->
<!--     @provisional: author convenience            -->
<!--     remainder: error check                      -->

<!-- Primary case, no separators in @ref -->
<xsl:template match="xref[@ref and not(contains(normalize-space(@ref), ' ')) and  not(contains(normalize-space(@ref), ','))]">
    <xsl:variable name="error-message">
        <xsl:apply-templates select="." mode="error-check-xref"/>
    </xsl:variable>
    <xsl:variable name="b-custom-biblio-text" select="@pi:custom-text = 'yes'"/>

    <xsl:choose>
        <xsl:when test="not($error-message = '')">
            <xsl:variable name="warning-rtf">
                <c>
                    <xsl:value-of select="$error-message"/>
                </c>
            </xsl:variable>
            <xsl:apply-templates select="exsl:node-set($warning-rtf)/c"/>
        </xsl:when>
        <!-- clear of errors, so on to main event -->
        <xsl:otherwise>
            <xsl:variable name="target" select="id(@ref)"/>
            <!-- Determine style of visible text in link -->
            <xsl:variable name="text-style">
                <xsl:apply-templates select="." mode="get-text-style" />
            </xsl:variable>
            <!-- if target is a bibliography item, generic -->
            <!-- text template only makes a number, we add -->
            <!-- brackets before link manufacture          -->
            <xsl:variable name="b-is-biblio-target" select="boolean($target/self::biblio)" />
            <!-- form text of the clickable, wrap biblio target -->
            <!-- since xref-text outputs just a number          -->
            <xsl:variable name="text">
                <xsl:if test="parent::mrow">
                    <xsl:text>\text{</xsl:text>
                </xsl:if>
                <xsl:if test="$b-is-biblio-target and not($b-custom-biblio-text)">
                    <xsl:text>[</xsl:text>
                </xsl:if>
                <xsl:apply-templates select="." mode="xref-text" >
                    <xsl:with-param name="target" select="$target" />
                    <xsl:with-param name="text-style" select="$text-style" />
                    <!-- pass content as an RTF, test vs. empty string, use copy-of -->
                    <xsl:with-param name="custom-text">
                        <xsl:apply-templates/>
                    </xsl:with-param>
                </xsl:apply-templates>
                <!-- a bibliography citation (only) may have extra @detail          -->
                <!-- maybe the detail should migrate to content of a xref to biblio -->
                <xsl:if test="@detail">
                    <xsl:choose>
                        <xsl:when test="$b-is-biblio-target">
                            <xsl:text>,</xsl:text>
                            <xsl:call-template name="nbsp-character"/>
                            <!-- this info should not be in an attribute! -->
                            <xsl:apply-templates select="@detail" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>PTX:WARNING: &lt;xref @detail="<xsl:value-of select="@detail" />" /&gt; only implemented for single references to &lt;biblio&gt; elements</xsl:message>
                            <xsl:apply-templates select="." mode="location-report" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <xsl:if test="$b-is-biblio-target and not($b-custom-biblio-text)">
                    <xsl:text>]</xsl:text>
                </xsl:if>
                <xsl:if test="parent::mrow">
                    <xsl:text>}</xsl:text>
                </xsl:if>
            </xsl:variable>
            <!-- Send the text representation for link and target to a    -->
            <!-- format-specific and target-specific link manufacture.    -->
            <!-- This depends primarly on the $target, but the context is -->
            <!-- holds the location of the link.  Example: a link in      -->
            <!-- display mathematics (rendered by MathJax for HTML)       -->
            <!-- requires radically different constructions as a knowl,   -->
            <!-- or as a hyperlink.  LaTeX barely cares.  We do wrap the  -->
            <!-- xref-text in \text{} for receipt in display mathematics. -->
            <!-- NB: could a xref with title text have math in it and mess-up here? -->
            <xsl:apply-templates select="." mode="xref-link">
                <xsl:with-param name="target" select="$target" />
                <xsl:with-param name="origin" select="'xref'" />
                <xsl:with-param name="content" select="$text" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A range given by @first, @last            -->
<!-- Makes one chunk of text, linked to @first -->
<!-- Requires same type for targets, since     -->
<!-- type only occurs once in text             -->
<!-- Equations look like (4.2)-(4.8)           -->
<!-- Bibliography looks like [6-14]            -->
<xsl:template match="xref[@first and @last]">
    <xsl:variable name="error-message">
        <xsl:apply-templates select="." mode="error-check-xref"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="not($error-message = '')">
            <xsl:variable name="warning-rtf">
                <c>
                    <xsl:value-of select="$error-message"/>
                </c>
            </xsl:variable>
            <xsl:apply-templates select="exsl:node-set($warning-rtf)/c"/>
        </xsl:when>
        <!-- clear of errors, so on to main event -->
        <xsl:otherwise>
            <xsl:variable name="target-one" select="id(@first)"/>
            <xsl:variable name="target-two" select="id(@last)" />
            <!-- Determine style of visible text in link -->
            <xsl:variable name="text-style-one">
                <xsl:apply-templates select="." mode="get-text-style" />
            </xsl:variable>
            <!-- Adjust/set style for end of range          -->
            <!-- Basically supress text manufacture of type -->
            <!-- Also, no content is passed with @last      -->
            <xsl:variable name="text-style-two">
                <xsl:choose>
                    <!-- do not replicate type name -->
                    <xsl:when test="$text-style-one = 'type-global'">
                        <xsl:text>global</xsl:text>
                    </xsl:when>
                    <xsl:when test="$text-style-one = 'type-local'">
                        <xsl:text>local</xsl:text>
                    </xsl:when>
                    <!-- pass through 'global', 'local', 'title', 'phrase-global' -->
                    <xsl:otherwise>
                        <xsl:value-of select="$text-style-one" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!-- enforce @first, @last point to same kind of element, -->
            <!-- since we implicitly recycle the type-name of @first  -->
            <!-- Schematron: possible by inserting id() into XPath test? -->
            <xsl:if test="not(local-name($target-one) = local-name($target-two))">
                <xsl:message>PTX:ERROR:   &lt;xref @first="<xsl:value-of select="@first" />" @last="<xsl:value-of select="@last" />" /&gt; references two elements with different tags (<xsl:value-of select="local-name($target-one)" /> vs. <xsl:value-of select="local-name($target-two)" />), so are incompatible as endpoints of a range.  Rewrite using two &lt;xref&gt; elements</xsl:message>
            </xsl:if>
            <!-- Once there was a courtesy check here that range  -->
            <!-- is not out-of-order. It was very inefficient due -->
            <!-- to two uses of the "preceeding::" axis. Seven    -->
            <!-- instances in the sample article accounted for    -->
            <!-- ~6% of processing time.                          -->
            <!-- For the old code, see commit                     -->
            <!--     05c88bb632e1d232a46955f4e3552494c3219cdc     -->
            <!-- Testing @last target in the nodes preceeding the -->
            <!-- first target might cut the time in half, which   -->
            <!-- is still not great.                              -->
            <!--  -->
            <!-- Biblio check assumes targets are equal       -->
            <!-- If target is a bibliography item, generic    -->
            <!-- text template only makes numbers, we add     -->
            <!-- brackets and detail before link manufacture  -->
            <!-- Content passes with @first, not with @second -->
            <xsl:variable name="b-is-biblio-target" select="boolean($target-one/self::biblio)" />
            <!-- Compose two text parts with an ndash, perhaps wrappped -->
            <xsl:variable name="text">
                <xsl:if test="parent::mrow">
                    <xsl:text>\text{</xsl:text>
                </xsl:if>
                <xsl:if test="$b-is-biblio-target">
                    <xsl:text>[</xsl:text>
                </xsl:if>
                <xsl:apply-templates select="." mode="xref-text" >
                    <xsl:with-param name="target" select="$target-one" />
                    <xsl:with-param name="text-style" select="$text-style-one" />
                    <!-- pass content as an RTF, test vs. empty string, use copy-of -->
                    <xsl:with-param name="custom-text">
                        <xsl:apply-templates/>
                    </xsl:with-param>
                </xsl:apply-templates>
                <xsl:call-template name="ndash-character"/>
                <xsl:apply-templates select="." mode="xref-text" >
                    <xsl:with-param name="target" select="$target-two" />
                    <xsl:with-param name="text-style" select="$text-style-two" />
                </xsl:apply-templates>
                <xsl:if test="$b-is-biblio-target">
                    <xsl:text>]</xsl:text>
                </xsl:if>
                <xsl:if test="parent::mrow">
                    <xsl:text>}</xsl:text>
                </xsl:if>
            </xsl:variable>
            <!-- Send the text representation for link and target to a    -->
            <!-- format-specific and target-specific link manufacture.    -->
            <!-- This depends primarly on the $target, but the context is -->
            <!-- holds the location of the link.  Example: a link in      -->
            <!-- display mathematics (rendered by MathJax for HTML)       -->
            <!-- requires radically different constructions as a knowl,   -->
            <!-- or as a hyperlink.  LaTeX barely cares.  We do wrap the  -->
            <!-- xref-text in \text{} for receipt in display mathematics. -->
            <!-- NB: could a xref with title text have math in it and mess-up here? -->
            <xsl:apply-templates select="." mode="xref-link">
                <xsl:with-param name="target" select="$target-one" />
                <xsl:with-param name="origin" select="'xref'" />
                <xsl:with-param name="content" select="$text" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A comma-, or space-separated list is unusual, -->
<!-- outside of a list of bibliography items.  For -->
<!-- other items we just mimic this case.          -->
<xsl:template match="xref[@ref and (contains(normalize-space(@ref), ' ') or contains(normalize-space(@ref), ','))]">
    <xsl:variable name="error-message">
        <xsl:apply-templates select="." mode="error-check-xref"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="not($error-message = '')">
            <xsl:variable name="warning-rtf">
                <c>
                    <xsl:value-of select="$error-message"/>
                </c>
            </xsl:variable>
            <xsl:apply-templates select="exsl:node-set($warning-rtf)/c"/>
        </xsl:when>
        <!-- clear of errors, so on to main event -->
        <xsl:otherwise>
            <!-- Determine style of visible text in link -->
            <xsl:variable name="text-style">
                <xsl:apply-templates select="." mode="get-text-style" />
            </xsl:variable>
            <!-- commas to blanks, normalize, add trailing blank for parsing   -->
            <!-- initialize with empty previous node, recurse through the list -->
            <xsl:variable name="normalized-ref-list"
                select="concat(normalize-space(str:replace(@ref,',', ' ')), ' ')" />
            <xsl:apply-templates select="." mode="process-ref-list">
                <xsl:with-param name="previous-target" select="/.." />
                <xsl:with-param name="ref-list" select="$normalized-ref-list" />
                <xsl:with-param name="text-style" select="$text-style" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- $ref-list must always have a trailing blank, if non-empty      -->
<!-- $previous-target serves two purposes:                          -->
<!--     empty signals start of the list, so no separator           -->
<!--     type-checking to preserve a consistent list (unimplmented) -->
<!-- $text-style is set on first call, then just pass-through       -->
<!-- Wrapping for bibiography list is based on first, last element  -->
<!-- No content overrides are allowed, since unclear jut how        -->
<!-- TODO: improve checking to avoid goofy results -->
<xsl:template match="xref" mode="process-ref-list">
    <xsl:param name="previous-target" select="/.." />
    <xsl:param name="ref-list" select="' '" />
    <xsl:param name="text-style" select="''" />
    <!-- split list at first blank, later recurse on $trailing -->
    <xsl:variable name="ref" select="substring-before($ref-list, ' ')" />
    <xsl:variable name="trailing" select="substring-after($ref-list, ' ')" />
    <!-- now work with one $ref and the configured $text-style -->
    <!-- get the target as a node -->
    <xsl:variable name="target" select="id($ref)" />
    <!-- bibiographic targets are special -->
    <xsl:variable name="b-is-biblio-target" select="$target/self::biblio" />
    <!-- if starting, begin bibliography list wrapping -->
    <xsl:if test="not($previous-target) and $b-is-biblio-target">
        <xsl:text>[</xsl:text>
    </xsl:if>
    <!-- output a seperator, if not just starting -->
    <!-- protect text in a math display           -->
    <xsl:if test="$previous-target">
        <xsl:if test="parent::mrow">
            <xsl:text>\text{</xsl:text>
        </xsl:if>
        <xsl:text>, </xsl:text>
        <xsl:if test="parent::mrow">
            <xsl:text>}</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- create the visual/clickable/readable text      -->
    <!-- no content is passed, so no override in effect -->
    <xsl:variable name="text">
        <xsl:if test="parent::mrow">
            <xsl:text>\text{</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="xref-text">
            <xsl:with-param name="target" select="$target" />
            <xsl:with-param name="text-style" select="$text-style" />
        </xsl:apply-templates>
        <xsl:if test="parent::mrow">
            <xsl:text>}</xsl:text>
        </xsl:if>
    </xsl:variable>
    <!-- Send the text representation for link and target to a    -->
    <!-- format-specific and target-specific link manufacture.    -->
    <!-- This depends primarly on the $target, but the context is -->
    <!-- holds the location of the link.  Example: a link in      -->
    <!-- display mathematics (rendered by MathJax for HTML)       -->
    <!-- requires radically different constructions as a knowl,   -->
    <!-- or as a hyperlink.  LaTeX barely cares.  We do wrap the  -->
    <!-- xref-text in \text{} for receipt in display mathematics. -->
    <!-- NB: could a xref with title text have math in it and mess-up here? -->
    <xsl:apply-templates select="." mode="xref-link">
        <xsl:with-param name="target" select="$target" />
        <xsl:with-param name="origin" select="'xref'" />
        <xsl:with-param name="content" select="$text" />
    </xsl:apply-templates>
    <!-- check if we have exhausted the list, -->
    <!-- so check bibliography wrapping       -->
    <xsl:if test="not($trailing) and $b-is-biblio-target">
        <xsl:text>]</xsl:text>
    </xsl:if>
    <!-- recurse into next reference in the list -->
    <xsl:if test="$trailing">
        <xsl:apply-templates select="." mode="process-ref-list">
            <xsl:with-param name="previous-target" select="$target" />
            <xsl:with-param name="ref-list" select="$trailing" />
            <xsl:with-param name="text-style" select="$text-style" />
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- Provisional cross-references -->
<!-- A convenience for authors in early stages of writing -->
<!-- Just drop a reminder in text                         -->
<xsl:template match="xref[@provisional]">
    <xsl:variable name="warning-rtf">
        <c>
            <xsl:text>[provisional cross-reference: </xsl:text>
            <xsl:value-of select="@provisional"/>
            <xsl:text>]</xsl:text>
        </c>
    </xsl:variable>
    <xsl:variable name="warning" select="exsl:node-set($warning-rtf)"/>
    <xsl:apply-templates select="$warning/c"/>
</xsl:template>

<!-- Warnings for a high-frequency mistake -->
<xsl:template match="xref[not(@ref) and not(@first and @last) and not(@provisional)]">
    <xsl:message>PTX:WARNING: A cross-reference (&lt;xref&gt;) must have a @ref attribute, a @first/@last attribute pair, or a @provisional attribute</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:call-template name="inline-warning">
        <xsl:with-param name="warning">
            <xsl:text>xref without ref, first/last, or provisional attribute (check spelling)</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="margin-warning">
        <xsl:with-param name="warning">
            <xsl:text>xref, no recognized attribute</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- ######################### -->
<!-- Cross-Reference Utilities -->
<!-- ######################### -->

<!-- Error-checking first, an "xref" in, a placeholder message back -->
<!-- to insert into text that screams there is a problem.  Routine  -->
<!-- also scribbles on the console.  To use, capture the output in  -->
<!--  avariable, if non-empty then use text as result, if empty     -->
<!-- then do the work.                                              -->

<xsl:template match="xref" mode="error-check-xref">
    <!-- A @ref attribute can be a list (e.g. of biblio) and the   -->
    <!-- @first/@last construction is really two @ref.  We package -->
    <!-- up a list as a string no matter what.  No commas, plus a  -->
    <!-- trailing space added so we can chop up the list reliably. -->
    <!-- commas to blanks, normalize spaces, -->
    <!-- add trailing space for final split  -->
    <xsl:variable name="normalized-ref-list">
        <xsl:choose>
            <xsl:when test="@ref">
                <xsl:value-of select="concat(normalize-space(str:replace(@ref,',', ' ')), ' ')"/>
            </xsl:when>
            <!-- put @first and @last into a normalized two-part list -->
            <xsl:when test="@first and @last">
                <xsl:value-of select="concat(normalize-space(@first), ' ', normalize-space(@last), ' ')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>PTX:ERROR:   an "xref" lacks a @ref, @first/@last, or @provisional; check your source</xsl:message>
                <xsl:apply-templates select="." mode="location-report"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Variable will have a list of bad cross-reference -->
    <!-- labels (no target located!) in a comma-separated -->
    <!-- list.  Empty is success and we then do nothing.  -->
    <xsl:variable name="bad-xrefs-in-list">
        <!-- recursive, start with full list -->
        <xsl:apply-templates select="." mode="check-ref-list">
            <xsl:with-param name="ref-list" select="$normalized-ref-list"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="not($bad-xrefs-in-list = '')">
        <!-- error condition, so warn and return  -->
        <!-- placeholder text as template result  -->
        <xsl:variable name="error-list" select="substring($bad-xrefs-in-list, 1, string-length($bad-xrefs-in-list) - 2)"/>
        <xsl:message>PTX:ERROR:   a cross-reference ("xref") uses references [<xsl:value-of select="$error-list"/>] that do not point to any target, or perhaps point to multiple targets.  Maybe you typed an @xml:id value wrong, maybe the target of the @xml:id is nonexistent, or maybe you temporarily removed the target from your source, or maybe an auxiliary file contains a duplicate.  Your output will contain some placeholder text that you will not want to distribute to your readers.</xsl:message>
        <xsl:apply-templates select="." mode="location-report"/>
        <!-- placeholder text -->
        <xsl:text>[cross-reference to target(s) "</xsl:text>
        <xsl:value-of select="$error-list"/>
        <xsl:text>" missing or not unique]</xsl:text>
    </xsl:if>
</xsl:template>

<!-- yes/no boolean for valid targets of an "xref"         -->
<!-- Initial list from entities file as of 2021-02-10      -->
<!-- Others from test docs, public testing via pretext-dev -->
<!-- NB: "men" is historical.  This element gets repaired  -->
<!-- to a one-line "md" but the target is found in the     -->
<!-- original source and is identified as an "men" element, -->
<!-- which really *should not* be not on this list.         -->
<xsl:template match="&STRUCTURAL;|&DEFINITION-LIKE;|&THEOREM-LIKE;|&PROOF-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&ASIDE-LIKE;|&OPENPROBLEM-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&GOAL-LIKE;|&FIGURE-LIKE;|&SOLUTION-LIKE;|&DISCUSSION-LIKE;|exercise|task|subexercises|exercisegroup|poem|assemblage|paragraphs|li|fn|men|md|mrow|biblio|interactive/instructions|case|contributor|gi" mode="is-xref-target">
    <xsl:value-of select="'yes'"/>
</xsl:template>

<xsl:template match="*" mode="is-xref-target">
    <xsl:value-of select="'no'"/>
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
                    <xsl:if test="id($initial)">
                        <xsl:text>X</xsl:text>
                        <xsl:variable name="target" select="id($initial)"/>
                        <xsl:variable name="is-a-target">
                            <xsl:apply-templates select="$target" mode="is-xref-target"/>
                        </xsl:variable>
                        <xsl:if test="$is-a-target = 'no'">
                            <xsl:message>PTX:DEBUG: xref/@ref "<xsl:value-of select="$initial"/>" points to a "<xsl:value-of select="local-name($target)"/>" element.  (1) we made a mistake, and we need to add this element to a list of potential targets of a cross-reference, or (2) you made a mistake and really did not mean this particular construction, or (3) we need to have a discussion about the advisability of this element being a target.   (4) If you are trying to cross-reference a "p" element, perhaps using a "paragraphs" element is a good alternative.  If (1) or (3) could you please report me!</xsl:message>
                        </xsl:if>
                    </xsl:if>
                </xsl:for-each>
            </xsl:variable>
            <xsl:if test="not($hits = 'X')">
                <!-- drop the failed lookup, plus a separator.  A nonempty -->
                <!-- result for this template is indicative of a failure   -->
                <!-- and the list can be reported in the error message     -->
                <xsl:value-of select="$initial"/>
                <xsl:text>, </xsl:text>
            </xsl:if>
            <!-- recurse to next label -->
            <xsl:apply-templates select="." mode="check-ref-list">
                <xsl:with-param name="ref-list" select="substring-after($ref-list, ' ')"/>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Parse, analyze switches, attributes -->
<!--   global:      5.2                  -->
<!--   type-global: Theorem 5.2          -->
<!--   title:       Smith's Theorem      -->
<xsl:template match="xref|&PROOF-LIKE;" mode="get-text-style">
    <xsl:choose>
        <!-- local specification is override of global  -->
        <!-- new @text attribute first, and if so, bail -->
        <xsl:when test="@text='global'">
            <xsl:text>global</xsl:text>
        </xsl:when>
        <xsl:when test="@text='local'">
            <xsl:text>local</xsl:text>
        </xsl:when>
        <xsl:when test="@text='hybrid'">
            <xsl:text>hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="@text='type-global'">
            <xsl:text>type-global</xsl:text>
        </xsl:when>
        <xsl:when test="@text='type-local'">
            <xsl:text>type-local</xsl:text>
        </xsl:when>
        <xsl:when test="@text='type-hybrid'">
            <xsl:text>type-hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="@text='type-global-title'">
            <xsl:text>type-global-title</xsl:text>
        </xsl:when>
        <xsl:when test="@text='type-local-title'">
            <xsl:text>type-local-title</xsl:text>
        </xsl:when>
        <!-- no 'type-hybrid-title' yet -->
        <xsl:when test="@text='phrase-global'">
            <xsl:text>phrase-global</xsl:text>
        </xsl:when>
        <xsl:when test="@text='phrase-hybrid'">
            <xsl:text>phrase-hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="@text='title'">
            <xsl:text>title</xsl:text>
        </xsl:when>
        <xsl:when test="@text='custom'">
            <xsl:text>custom</xsl:text>
        </xsl:when>
        <!-- old (deprecated, 2017-07-25) autoname attribute -->
        <xsl:when test="@autoname='no'">
            <xsl:text>global</xsl:text>
        </xsl:when>
        <xsl:when test="@autoname='yes'">
            <xsl:text>type-global</xsl:text>
        </xsl:when>
        <xsl:when test="@autoname='title'">
            <xsl:text>title</xsl:text>
        </xsl:when>
        <!-- otherwise, global setting via attribute/switch  -->
        <!-- New scheme is set from docinfo attribute        -->
        <!-- No setting in docinfo yields empty string for   -->
        <!-- $xref-text-style, so we drop into legacy scheme -->
        <!-- for the default, which is 'yes'/'type-global'   -->
        <xsl:when test="$xref-text-style='global'">
            <xsl:text>global</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='local'">
            <xsl:text>local</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='hybrid'">
            <xsl:text>hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='type-global'">
            <xsl:text>type-global</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='type-local'">
            <xsl:text>type-local</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='type-hybrid'">
            <xsl:text>type-hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='type-global-title'">
            <xsl:text>type-global-title</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='type-local-title'">
            <xsl:text>type-local-title</xsl:text>
        </xsl:when>
        <!-- no 'type-hybrid-title' yet -->
        <xsl:when test="$xref-text-style='phrase-global'">
            <xsl:text>phrase-global</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='phrase-hybrid'">
            <xsl:text>phrase-hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='title'">
            <xsl:text>title</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='custom'">
            <xsl:text>custom</xsl:text>
        </xsl:when>
        <!-- use this when choose goes away
        <xsl:if test="not($xref-text-style = '')">
            <xsl:value-of select="$xref-text-style" />
        </xsl:if>
        -->
        <!-- legacy-autoname is a pass-thru of old autoname  -->
        <!-- except with no command-line, no docinfo, then   -->
        <!-- a 'unset' will appear here to activate new      -->
        <!-- default this could move later to the "otherwise"-->
        <xsl:when test="$legacy-autoname='unset'">
            <xsl:text>type-global</xsl:text>
        </xsl:when>
        <xsl:when test="$legacy-autoname='no'">
            <xsl:text>global</xsl:text>
        </xsl:when>
        <xsl:when test="$legacy-autoname='yes'">
            <xsl:text>type-global</xsl:text>
        </xsl:when>
        <xsl:when test="$legacy-autoname='title'">
            <xsl:text>title</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:BUG:    NO TEXT STYLE DETERMINED</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- The text that will be visible and clickable    -->
<!-- Bibliography items return a naked number,      -->
<!-- caller is responsible for adjusting text with  -->
<!-- brackets prior to shipping to link manufacture -->
<xsl:template match="xref|&PROOF-LIKE;" mode="xref-text">
    <xsl:param name="target" />
    <xsl:param name="text-style" />
    <xsl:param name="custom-text" select="''" />
    <!-- an equation target is exceptional -->
    <!-- Targets are "mrow" or bare "md" -->
    <xsl:variable name="b-is-equation-target" select="$target/self::mrow or $target/self::md[@pi:authored-one-line]" />
    <!-- a bibliography target is exceptional -->
    <xsl:variable name="b-is-biblio-target" select="boolean($target/self::biblio)" />
    <!-- a contributor target is exceptional -->
    <xsl:variable name="b-is-contributor-target" select="boolean($target/self::contributor)"/>
    <!-- recognize content s potential override -->
    <xsl:variable name="b-has-content" select="not($custom-text = '')" />
    <!-- check some situations that would lead to ineffective -->
    <!-- cross-references due to empty text                   -->
    <xsl:choose>
        <xsl:when test="$text-style = 'title'">
            <xsl:variable name="the-title">
                <xsl:apply-templates select="$target" mode="title-xref"/>
            </xsl:variable>
            <xsl:if test="$the-title = ''">
                <xsl:message>
                    <xsl:text>PTX:WARNING:    </xsl:text>
                    <xsl:text>An &lt;xref&gt; wants to build text using a title to identify the target, but the target (which has @xml:id "</xsl:text>
                    <xsl:value-of select="@ref"/>
                    <xsl:text>") has no title, not even a default title.</xsl:text>
                </xsl:message>
                <xsl:apply-templates select="." mode="location-report"/>
            </xsl:if>
        </xsl:when>
        <xsl:when test="$text-style = 'custom'">
            <xsl:if test="not($b-has-content)">
                <xsl:message>
                    <xsl:text>PTX:WARNING:    </xsl:text>
                    <xsl:text>An &lt;xref&gt; wants to use custom text to describe the target, but no custom text was provided as the content of the "xref".</xsl:text>
                </xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:if>
        </xsl:when>
        <!-- Any other case of a cross-reference employs a number, or parts -->
        <!-- of a number for the target.  The signal of being numberless is -->
        <!-- an empty result for the modal "number" template.  But it is    -->
        <!-- subtler than that, especially for equations that can have      -->
        <!-- "symbolic" tags via @tag, and the number/no-number dichotomy   -->
        <!-- is complicated by element names and attributes.                -->
        <!-- A cross-reference to a contributor is an exception.            -->
        <xsl:otherwise>
            <xsl:variable name="the-number">
                <xsl:apply-templates select="$target" mode="xref-number">
                    <xsl:with-param name="xref" select="." />
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:if test="($the-number = '') and not($b-is-contributor-target)">
                <xsl:message>
                    <xsl:text>PTX:WARNING:    </xsl:text>
                    <xsl:text>An &lt;xref&gt; wants to build text using a number to identify the target, but the target (which has @xml:id "</xsl:text>
                    <xsl:value-of select="@ref"/>
                    <xsl:text>") does not have a number. You could try 'text="title"' or 'text="custom"' on the "xref".</xsl:text>
                </xsl:message>
                <xsl:apply-templates select="." mode="location-report"/>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
    <!-- Start massive "choose" for exceptions and twelve general styles -->
    <xsl:choose>
        <xsl:when test="$b-is-contributor-target">
            <xsl:apply-templates select="$target/personname" />
        </xsl:when>
        <!-- equations are different -->
        <!-- custom or full number   -->
        <xsl:when test="$b-is-equation-target">
            <!-- "custom" style replaces the number -->
            <xsl:choose>
                <xsl:when test="$text-style = 'custom'">
                    <xsl:copy-of select="$custom-text"/>
                </xsl:when>
                <!-- prefixing with content is anomalous -->
                <xsl:otherwise>
                    <xsl:if test="$b-has-content">
                        <xsl:copy-of select="$custom-text"/>
                        <xsl:apply-templates select="." mode="xref-text-separator"/>
                    </xsl:if>
                    <xsl:text>(</xsl:text>
                    <xsl:apply-templates select="$target" mode="xref-number">
                        <xsl:with-param name="xref" select="." />
                    </xsl:apply-templates>
                    <xsl:text>)</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- bibliography override       -->
        <!-- number only, consumer wraps -->
        <!-- warn about useless content override (use as @detail?) -->
        <xsl:when test="$b-is-biblio-target">
            <xsl:choose>
                <xsl:when test="$custom-text = ''">
                    <xsl:apply-templates select="$target" mode="xref-number">
                        <xsl:with-param name="xref" select="." />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$custom-text"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- now not an equation or bibliography target -->
        <!-- custom text is additional, as prefix, with no type -->
        <xsl:when test="$text-style = 'global'">
            <xsl:if test="$b-has-content">
                <xsl:copy-of select="$custom-text" />
                <xsl:apply-templates select="." mode="xref-text-separator"/>
            </xsl:if>
            <xsl:apply-templates select="$target" mode="xref-number">
                <xsl:with-param name="xref" select="." />
            </xsl:apply-templates>
        </xsl:when>
        <!-- custom text is additional, as prefix, with no type -->
        <xsl:when test="$text-style = 'local'">
            <xsl:if test="$b-has-content">
                <xsl:copy-of select="$custom-text" />
                <xsl:apply-templates select="." mode="xref-text-separator"/>
            </xsl:if>
            <xsl:apply-templates select="$target" mode="serial-number" />
        </xsl:when>
        <xsl:when test="$text-style = 'type-global'">
            <xsl:choose>
                <!-- content override of type-prefix -->
                <xsl:when test="$b-has-content">
                    <xsl:copy-of select="$custom-text" />
                    <xsl:apply-templates select="." mode="xref-text-separator"/>
                    <xsl:apply-templates select="$target" mode="xref-number">
                        <xsl:with-param name="xref" select="." />
                    </xsl:apply-templates>
                </xsl:when>
                <!-- usual, default case -->
                <xsl:otherwise>
                    <xsl:apply-templates select="$target" mode="type-name" />
                    <xsl:apply-templates select="." mode="xref-text-separator"/>
                    <xsl:apply-templates select="$target" mode="xref-number">
                        <xsl:with-param name="xref" select="." />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="$text-style = 'type-local'">
            <xsl:choose>
                <!-- content override of type-prefix -->
                <xsl:when test="$b-has-content">
                    <xsl:copy-of select="$custom-text" />
                    <xsl:apply-templates select="." mode="xref-text-separator"/>
                    <xsl:apply-templates select="$target" mode="serial-number" />
                </xsl:when>
                <!-- usual, default case -->
                <xsl:otherwise>
                    <xsl:apply-templates select="$target" mode="type-name" />
                    <xsl:apply-templates select="." mode="xref-text-separator"/>
                    <xsl:apply-templates select="$target" mode="serial-number" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="($text-style = 'type-global-title') or ($text-style = 'type-local-title')">
            <xsl:choose>
                <!-- content override of type-prefix -->
                <xsl:when test="$b-has-content">
                    <xsl:copy-of select="$custom-text" />
                </xsl:when>
                <!-- usual, default case -->
                <xsl:otherwise>
                    <xsl:apply-templates select="$target" mode="type-name" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="." mode="xref-text-separator"/>
            <!-- only difference in behavior is global/local number -->
            <xsl:choose>
                <xsl:when test="$text-style = 'type-global-title'">
                    <xsl:apply-templates select="$target" mode="xref-number">
                        <xsl:with-param name="xref" select="." />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$text-style = 'type-local-title'">
                    <xsl:apply-templates select="$target" mode="serial-number"/>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
            <xsl:variable name="the-title">
                <xsl:apply-templates select="$target" mode="title-xref"/>
            </xsl:variable>
            <!-- no title, no problem -->
            <xsl:if test="not($the-title = '')">
                <xsl:apply-templates select="." mode="xref-text-separator"/>
                <!-- title might have markup (eg math in HTML), so copy -->
                <xsl:copy-of select="$the-title"/>
            </xsl:if>
        </xsl:when>
        <!-- special case for phrase options and list items of anonymous lists        -->
        <!-- catch this first and provide no text at all (could provide busted text?) -->
        <!-- anonymous lists live in "p", but this is an unreliable indication        -->
        <xsl:when test="($text-style = 'phrase-global' or $text-style = 'phrase-hybrid') and ($target/self::li and not($target/ancestor::list or $target/ancestor::objectives or $target/ancestor::outcomes or $target/ancestor::exercise))">
            <xsl:message>PTX:WARNING: a cross-reference to a list item of an anonymous list ("<xsl:apply-templates select="$target" mode="serial-number" />") with 'phrase-global' and 'phrase-hybrid' styles for the xref text will yield no text at all, and possibly create unpredictable results in output</xsl:message>
        </xsl:when>
        <xsl:when test="$text-style = 'phrase-global' or $text-style = 'phrase-hybrid'">
            <!-- no content override in this case -->
            <!-- maybe we can relax this somehow? -->
            <xsl:if test="$b-has-content">
                <xsl:message>PTX:WARNING: providing content ("<xsl:value-of select="." />") for an "xref" element is ignored for 'phrase-global' and 'phrase-hybrid' styles for xref text</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:if>
            <!-- type-local first, no matter what    -->
            <!-- for each of the two phrase styles   -->
            <xsl:apply-templates select="$target" mode="type-name" />
            <xsl:apply-templates select="." mode="xref-text-separator"/>
            <xsl:apply-templates select="$target" mode="serial-number" />
            <!-- climb up tree to find highest matching structure numbers -->
            <!-- we pass through the two styles so reaction can occur     -->
            <!-- For example for the target Theorem 37.8 of an article,   -->
            <!-- phrase-global: "of Section 37" always                    -->
            <!-- phrase-hybrid: "of Section 37" only if necessary         -->
            <xsl:apply-templates select="$target" mode="smart-xref-text">
                <xsl:with-param name="text-style" select="$text-style" />
                <xsl:with-param name="xref" select="." />
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="highest-match" select="/.." />
                <xsl:with-param name="target-structure-number">
                    <xsl:apply-templates select="$target" mode="structure-number" />
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="($text-style = 'hybrid') or ($text-style = 'type-hybrid')">
            <xsl:choose>
                <!-- content override of type-prefix -->
                <!-- or addtion to plain number      -->
                <xsl:when test="$b-has-content">
                    <xsl:copy-of select="$custom-text" />
                    <xsl:apply-templates select="." mode="xref-text-separator"/>
                </xsl:when>
                <!-- no override, use type as prefix -->
                <xsl:when test="$text-style = 'type-hybrid'">
                    <xsl:apply-templates select="$target" mode="type-name" />
                    <xsl:apply-templates select="." mode="xref-text-separator"/>
                </xsl:when>
                <!-- just a plain number, do nothing at all -->
                <xsl:otherwise />
            </xsl:choose>
            <!-- For example for the target Theorem 37.8 of an article, -->
            <!-- hybrid: 8 or if necessary, 37.8                        -->
            <!-- type-hybrid: Theorem 8 or if necessary, Theorem 37.8   -->
            <xsl:apply-templates select="$target" mode="smart-xref-text">
                <xsl:with-param name="text-style" select="$text-style" />
                <xsl:with-param name="xref" select="." />
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="highest-match" select="/.." />
                <xsl:with-param name="target-structure-number">
                    <xsl:apply-templates select="$target" mode="structure-number" />
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="$text-style = 'title'">
            <xsl:choose>
                <!-- 2020-02-18: a content override of a title is now  -->
                <!-- deprecated (since there is now a "custom" option  -->
                <!-- for text).  But it still "works", with warnings   -->
                <!-- here.  Clean this up to complete the deprecation. -->
                <!-- (We don't do this with other deprecations since   -->
                <!-- we can get here by a variety of routes.)          -->
                <xsl:when test="$b-has-content">
                    <xsl:message>
                        <xsl:text>PTX:WARNING:    </xsl:text>
                        <xsl:text>An &lt;xref&gt; requests a 'title' as its text but also provides alternate content.  The construction is deprecated as of 2020-02-18.  Instead, specify that xref/@text should be 'custom', either globally or on a per-xref basis.</xsl:text>
                    </xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                    <xsl:copy-of select="$custom-text" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$target" mode="title-xref"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="$text-style = 'custom'">
            <!-- use the content, do not include a number, a warning -->
            <!-- if the content is empty is provided elsewhere       -->
            <xsl:copy-of select="$custom-text" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:BUG:  NO XREF TEXT GENERATED</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="." mode="latex-page-number">
        <xsl:with-param name="target" select="$target"/>
    </xsl:apply-templates>
</xsl:template>

<!-- "xref text" like "Theorem 4.5" benefits from a non-breaking   -->
<!-- space to keep the pieces together and discourage line-breaks  -->
<!-- in the middle.  This is less relevant when used as a "reason" -->
<!-- inside of display mathematics *and* it does not play nicely   -->
<!-- with WeBWorK's PGML, so this template handles the necessary   -->
<!-- exception for "xref" immediately inside of an "mrow".         -->
<xsl:template match="xref|&PROOF-LIKE;" mode="xref-text-separator">
    <xsl:choose>
        <xsl:when test="parent::mrow">
            <xsl:text> </xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="nbsp-character"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- This is a hook to add page numbers to the end of the    -->
<!-- xref text in LaTeX output via a \pageref{}, optionally. -->
<!-- Default for this hook is to do nothing.                 -->
<xsl:template match="xref|&PROOF-LIKE;" mode="latex-page-number"/>

<!-- A THEOREM-LIKE can have a *detached* PROOF-LIKE (which is not "inner" nor  -->
<!-- "solution") that has @ref attribute which points to the THEOREM-LIKE being -->
<!-- proved.  This abstract template will provide the link/knowl/whatever.      -->
<!-- It is up to the employing conversion to place and format the result.       -->
<xsl:template match="&PROOF-LIKE;" mode="proof-xref-theorem">
    <xsl:choose>
        <!-- produce nothing when there is not even a @ref -->
        <xsl:when test="not(@ref)"/>
        <!-- only for "detached" proofs -->
        <xsl:when test="&INNER-PROOF-FILTER;"/>
        <xsl:when test="&SOLUTION-PROOF-FILTER;"/>
        <!-- now really get into it analyzing target -->
        <xsl:otherwise>
            <xsl:variable name="target" select="id(@ref)"/>
            <xsl:choose>
                <xsl:when test="not($target)">
                    <xsl:message>PTX:ERROR:   a cross-reference ("ref") from a "<xsl:value-of select="local-name()"/>" uses a reference [<xsl:value-of select="@ref"/>] that does not point to any target.  Maybe the @ref and @xml:id values do not match?</xsl:message>
                    <xsl:apply-templates select="." mode="location-report"/>
                </xsl:when>
                <xsl:when test="not($target[&THEOREM-FILTER;])">
                    <xsl:message>PTX:ERROR:   a cross-reference ("ref") from a "<xsl:value-of select="local-name()"/>" uses a reference [<xsl:value-of select="@ref"/>] that does not point to an element that is THEOREM-LIKE (target is a "<xsl:value-of select="local-name($target)"/>" element).</xsl:message>
                    <xsl:apply-templates select="." mode="location-report"/>
                </xsl:when>
                <!-- have a good target finally, do it -->
                <xsl:otherwise>
                    <xsl:variable name="text-style">
                        <xsl:apply-templates select="." mode="get-text-style" />
                    </xsl:variable>
                    <xsl:apply-templates select="." mode="xref-link">
                        <xsl:with-param name="target" select="$target" />
                        <xsl:with-param name="origin" select="'xref'" />
                        <xsl:with-param name="content">
                            <xsl:apply-templates select="." mode="xref-text" >
                                <xsl:with-param name="target" select="$target" />
                                <xsl:with-param name="text-style" select="$text-style" />
                                <!-- $custom-text is not an option -->
                            </xsl:apply-templates>
                        </xsl:with-param>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ###################### -->
<!-- Smart Cross-References -->
<!-- ###################### -->

<!-- We climb the tree upward (ancestors) until we hit    -->
<!-- the "mathbook" element, and then quit and assess.    -->
<!-- The "xref" that started all this is used for the     -->
<!-- eventual "hybrid" schemes, to see how close it is.   -->
<!-- We record the oldest ancestor (highest) with a       -->
<!-- *number* that is the *structure number* of the       -->
<!-- target of the cross-reference.  So we know the       -->
<!-- element (and its type) that originates the bulk      -->
<!-- of the target's number.                              -->
<!--                                                      -->
<!-- There is one subtlety.  Usually one, and only one,   -->
<!-- ancestor has the matching number, so we could halt   -->
<!-- once found.  However, the immediately older ancestor -->
<!-- can have the same number.  The "objective" element   -->
<!-- is this way, it shares numbering with its containing -->
<!-- division.  So we track through all the ancestors.    -->
<!--                                                      -->
<!-- To see if a xref is close to its target, we add the  -->
<!-- *single* xref node to the subtree of the (highest)   -->
<!-- node that provides the target's structure number.    -->
<!-- By comparing the sizes of these node-sets, we can    -->
<!-- determine if the xref lies outside the subtree and   -->
<!-- then stick with global numbers.                      -->
<!--                                                      -->
<!-- $text-style                                          -->
<!--   gets passed through, in order to consolidate       -->
<!-- $xref                                                -->
<!--   gets passed through for eventual membership test   -->
<!-- $target                                              -->
<!--   gets passed through for producing hybrid numbers   -->
<!-- $highest-match                                       -->
<!--   starts empty and is updated, if it finishes        -->
<!--   empty then the target is high in the tree          -->
<!--   or a match is a root for the structure number      -->
<!-- $target-structure-number                             -->
<!--   is produced once as a string, and passed through   -->
<!--                                                      -->
<!-- Result is a string that completes the xref text      -->
<!--                                                      -->
<xsl:template match="*" mode="smart-xref-text">
    <xsl:param name="text-style" />
    <xsl:param name="xref" />
    <xsl:param name="target" />
    <xsl:param name="highest-match" select="/.." />
    <xsl:param name="target-structure-number" />
    <!-- step up immediately, else test on  -->
    <!-- structure numbers is vacuous       -->
    <xsl:variable name="parent" select="parent::*" />
    <xsl:variable name="parent-number">
        <xsl:apply-templates select="$parent" mode="number" />
    </xsl:variable>
    <xsl:choose>
        <!-- quit at the top, and examine highest-match,    -->
        <!-- and for phrase-hybrid, we do a membership test -->
        <xsl:when test="$parent/self::mathbook|$parent/self::pretext">
            <xsl:variable name="requires-global">
                <xsl:choose>
                    <!-- no match, already high up tree, so no  -->
                    <!-- qualification is needed in either case -->
                    <xsl:when test="not($highest-match)">
                        <xsl:text>false</xsl:text>
                    </xsl:when>
                    <!-- now have a match, so for phrase-global -->
                    <!-- we will always print the global info   -->
                    <xsl:when test="$text-style='phrase-global'">
                        <xsl:text>true</xsl:text>
                    </xsl:when>
                    <!-- now have a match, so for all other styles -->
                    <!-- we check to see if xref is in subtree     -->
                    <xsl:otherwise>
                        <xsl:variable name="target-tree-size" select="count($highest-match/descendant-or-self::*)" />
                        <xsl:variable name="xref-union-tree-size" select="count(($xref | $highest-match/descendant-or-self::*))" />
                        <xsl:value-of select="$xref-union-tree-size = $target-tree-size + 1" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!-- now know local/global, write trailing portion of text -->
            <!-- here based on the style and the global requirement    -->
            <!-- NB: the "choose" is mirrored in the more specific template, next -->
            <!-- Question:  why does "phrase-global" come through here?           -->
            <xsl:choose>
                <!-- phrase styles may need remainder of phrase -->
                <xsl:when test="(($text-style='phrase-global') or ($text-style='phrase-hybrid')) and ($requires-global = 'true')">
                    <!-- connector, internationalize -->
                    <xsl:text> of </xsl:text>
                    <xsl:apply-templates select="$highest-match" mode="type-name" />
                    <xsl:call-template name="nbsp-character"/>
                    <xsl:apply-templates select="$highest-match" mode="xref-number">
                        <xsl:with-param name="xref" select="." />
                    </xsl:apply-templates>
                </xsl:when>
                <!-- hybrid styles need number for remainder -->
                <xsl:when test="($text-style='hybrid') or ($text-style='type-hybrid')">
                    <xsl:choose>
                        <xsl:when test="$requires-global = 'true'">
                            <xsl:apply-templates select="$target" mode="xref-number">
                                <xsl:with-param name="xref" select="." />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$target" mode="serial-number" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
        <!-- possible missing implementation bug in numbering -->
        <xsl:when test="$parent-number = '[NUM]'">
            <xsl:message>PTX:BUG:     Looks like a [<xsl:value-of select="local-name($parent)" />] element has an ambiguous number, found while making cross-reference text</xsl:message>
        </xsl:when>
        <!-- no match, just recurse, and preserve $highest-match -->
        <xsl:when test="not($parent-number = $target-structure-number)">
            <xsl:apply-templates select="$parent" mode="smart-xref-text">
                <xsl:with-param name="text-style" select="$text-style" />
                <xsl:with-param name="xref" select="$xref" />
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="highest-match" select="$highest-match" />
                <xsl:with-param name="target-structure-number" select="$target-structure-number" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- a match, record in updated $highest-match -->
        <xsl:when test="$parent-number = $target-structure-number">
            <xsl:apply-templates select="$parent" mode="smart-xref-text">
                <xsl:with-param name="text-style" select="$text-style" />
                <xsl:with-param name="xref" select="$xref" />
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="highest-match" select="$parent" />
                <xsl:with-param name="target-structure-number" select="$target-structure-number" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- impossible to get here -->
    </xsl:choose>
</xsl:template>

<!-- A hybrid scheme for a list item is only for list items         -->
<!-- of an ordered list, we drop the list number (structure number) -->
<!-- when xref and target are both inside the same list.            -->
<!-- No need to recurse.  $target is context, allowing a match.     -->

<xsl:template match="list//li" mode="smart-xref-text">
    <xsl:param name="text-style" />
    <xsl:param name="xref" />
    <xsl:param name="target" />

    <xsl:variable name="targets-list" select="$target/ancestor::list" />
    <xsl:variable name="xrefs-list"   select="$xref/ancestor::list" />

    <!-- To be a local xref, the "xref" must live in some "list", and -->
    <!-- it must be the same "list" as the "li" (which is in a list   -->
    <!-- due to the match).  We use the negation to keep the logic    -->
    <!-- the same as in the more general template, above              -->
    <xsl:variable name="requires-global" select="not((count($xrefs-list) = 1) and (count($targets-list|$xrefs-list) = 1))" />

    <!-- This "choose" largely matches above, and so maybe  -->
    <!-- could be consolidated into a parameterized template -->
    <xsl:choose>
        <!-- phrase styles may need remainder of phrase -->
        <xsl:when test="(($text-style='phrase-global') or ($text-style='phrase-hybrid')) and ($requires-global = 'true')">
            <!-- connector, internationalize -->
            <xsl:text> of </xsl:text>
            <xsl:apply-templates select="$targets-list" mode="type-name" />
            <xsl:call-template name="nbsp-character"/>
            <xsl:apply-templates select="$targets-list" mode="xref-number">
                <xsl:with-param name="xref" select="." />
            </xsl:apply-templates>
        </xsl:when>
        <!-- hybrid styles need number for remainder -->
        <xsl:when test="($text-style='hybrid') or ($text-style='type-hybrid')">
            <xsl:choose>
                <xsl:when test="$requires-global = 'true'">
                    <xsl:apply-templates select="$target" mode="xref-number">
                        <xsl:with-param name="xref" select="." />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$target" mode="serial-number" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- This is an abstract template, to accomodate -->
<!-- hard-coded HTML numbers and for LaTeX the   -->
<!-- \ref and \label mechanism                   -->
<xsl:template match="*" mode="xref-number">
    <xsl:text>[XREFNUM]</xsl:text>
</xsl:template>

<!-- This is a base implementation for the xref-link -->
<!-- template, which just repeats the content, with  -->
<!-- an indication that this needs to be overridden  -->
<!--   context -                                     -->
<!--      an xref usually, typically its parent      -->
<!--      is inspected to vary link style            -->
<!--   content -                                     -->
<!--     an RTF of the visual text,                  -->
<!--     suitable for location of the link           -->
<!--   target -                                      -->
<!--     the target of the link, so the right        -->
<!--     identification can be produced              -->
<!--  implementation is based on location            -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="target" />
    <xsl:param name="origin"/>
    <xsl:param name="content" />

    <xsl:message>PTX:BUG:     a new conversion needs an implementation of the modal "xref-link" template.  Search your output for "[LINK:"</xsl:message>
    <xsl:text>[LINK: </xsl:text>
    <xsl:copy-of select="$content" />
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- For cross-references in books with parts, we only     -->
<!-- want a part number in the cross-reference when the    -->
<!-- "xref" and the "$target" are "far apart," so the part -->
<!-- number is necessary to disambiguate the result.  This -->
<!-- utility uses the target as context and the xref as a  -->
<!-- parameter.  It evaluates to 'true' if and only if the -->
<!-- two nodes cross a part boundary *and* the target lies -->
<!-- inside a part.                                        -->
<!-- NB: "ancestor-or-self" is not used here               -->
<!--   (a) the $xref is not a part                         -->
<!--   (b) if the target is a part, its number will be     -->
<!--       its serial number, and will not need a prefix,  -->
<!--       so this will return false                       -->
<xsl:template match="*" mode="crosses-part-boundary">
    <xsl:param name="xref" select="/.." />
    <xsl:choose>
        <!-- if parts are not structural, no need -->
        <xsl:when test="$parts='absent' or $parts='decorative'">
            <xsl:value-of select="false()" />
        </xsl:when>
        <!-- if target is not in a part, no need -->
        <xsl:when test="not(ancestor::part)">
            <xsl:value-of select="false()" />
        </xsl:when>
        <!-- xref can't be in target's part, so necessary -->
        <xsl:when test="not($xref/ancestor::part)">
            <xsl:value-of select="true()" />
        </xsl:when>
        <!-- target and xref both in parts.  Same one? -->
        <xsl:otherwise>
            <xsl:value-of select="count(ancestor::part|$xref/ancestor::part) = 2" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- #################### -->
<!-- Common Constructions -->
<!-- #################### -->

<!-- With no special formatting, "PreTeXt" can be in -common -->
<!-- Ditto PreFigure, a great companion project.             -->
<!-- Use of "pretext" as a root container should get higher  -->
<!-- priority when used with /, or as a variable             -->
<!-- NB: there is a \XeTeX macro which renders the first "E" -->
<!-- backwards, but it is only defined when actually using   -->
<!-- xelatex (not pdflatex).  The LaTeX/PDF conversion could -->
<!-- conditionally define an internal macro based on the     -->
<!-- engine.  But we do not talk about XeTeX as much as      -->
<!-- XeLaTeX.                                                -->
<!-- NB: We have not attempted to make the "xe-" variants    -->
<!-- with fancy typography for HTML output, but one could    -->
<!-- mimic the HTML/CSS used for TeX and LaTeX in that       -->
<!-- conversion.                                             -->
<xsl:template match="pretext">
    <xsl:text>PreTeXt</xsl:text>
</xsl:template>
<!-- NB: when PreFigure has a namespace then the empty  -->
<!-- element text generator can be a simpler match here -->
<xsl:template match="prefigure[not(node())]">
    <xsl:text>PreFigure</xsl:text>
</xsl:template>
<xsl:template match="xetex">
    <xsl:text>XeTeX</xsl:text>
</xsl:template>
<xsl:template match="xelatex">
    <xsl:text>XeLaTeX</xsl:text>
</xsl:template>


<!-- We place the 13 Latin abbreviations here since they -->
<!-- are fairly basic.  The final period is implemented  -->
<!-- as a named template, so we can override it in the   -->
<!-- LaTeX conversion and get reasonable behavior (i.e.  -->
<!-- not confused as the end of a sentence).             -->

<!-- See: Chicago Manual of Style, 15e, 15.44, 15.55     -->
<!-- See: Bringhurst, 4e, 5.4.4                          -->

<xsl:template name="abbreviation-period">
    <xsl:text>.</xsl:text>
</xsl:template>

<!-- anno Domini, in the year of the Lord -->
<!-- CMOS, Bringurst 5.4.4, no periods    -->
<xsl:template match="ad">
    <xsl:text>AD</xsl:text>
</xsl:template>
<!-- ante meridiem, before midday      -->
<!-- CMOS, Bringurst 5.4.4, no periods -->
<xsl:template match="am">
    <xsl:text>AM</xsl:text>
</xsl:template>
<!-- before Christ                     -->
<!-- CMOS, Bringurst 5.4.4, no periods -->
<xsl:template match="bc">
    <xsl:text>BC</xsl:text>
</xsl:template>
<!-- circa, about                         -->
<!-- CMOS, ca. preferable (c. is century) -->
<!-- "circa" deprecated 2018-12-30        -->
<xsl:template match="ca">
    <xsl:text>ca</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>
<!-- exempli gratia, for example -->
<xsl:template match="eg">
    <xsl:text>e.g</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>
<!-- et alia, and others -->
<xsl:template match="etal">
    <xsl:text>et al</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>
<!-- et caetera, and the rest -->
<xsl:template match="etc">
    <xsl:text>etc</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>
<!-- id est, in other words -->
<xsl:template match="ie">
    <xsl:text>i.e</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>
<!-- nota bene, note well -->
<!-- CMOS, no periods     -->
<xsl:template match="nb">
    <xsl:text>NB</xsl:text>
</xsl:template>
<!-- post meridiem, after midday       -->
<!-- CMOS, Bringurst 5.4.4, no periods -->
<xsl:template match="pm">
    <xsl:text>PM</xsl:text>
</xsl:template>
<!-- post scriptum, after what has been written -->
<!-- CMOS, no periods                           -->
<xsl:template match="ps">
    <xsl:text>PS</xsl:text>
</xsl:template>
<!-- versus, against                 -->
<!-- CMOS, v. only in legal contexts -->
<xsl:template match="vs">
    <xsl:text>vs</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>
<!-- videlicet, namely -->
<xsl:template match="viz">
    <xsl:text>viz</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>

<!-- ################## -->
<!-- Special Characters -->
<!-- ################## -->

<!-- Dashes and hyphens - worth reviewing       -->
<!-- http://www.cs.tut.fi/~jkorpela/dashes.html -->

<xsl:template name="nbsp-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'nbsp'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="nbsp">
    <xsl:call-template name="nbsp-character"/>
</xsl:template>

<xsl:template name="ndash-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'ndash'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="ndash">
    <xsl:call-template name="ndash-character"/>
</xsl:template>

<!-- An mdash may have thin space around it, otherwise it        -->
<!-- should have none.  It might be difficult to enforce this    -->
<!-- (we could!), but we don't.  Instead, we make the thin-space -->
<!-- version a publisher option.  So we need two base characters -->
<!-- as abstract templates and do everything else here.          -->

<xsl:template name="mdash-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'mdash'"/>
    </xsl:call-template>
</xsl:template>

<xsl:template name="thin-space-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'thin-space'"/>
    </xsl:call-template>
</xsl:template>

<!-- The variable, surrounding space. This approach is   -->
<!-- executed once, so not local to template for "mdash" -->
<xsl:variable name="emdash-space-char">
    <xsl:choose>
        <xsl:when test="$emdash-space='none'">
            <xsl:text />
        </xsl:when>
        <xsl:when test="$emdash-space='thin'">
            <xsl:call-template name="thin-space-character"/>
        </xsl:when>
    </xsl:choose>
</xsl:variable>

<xsl:template match="mdash">
    <xsl:value-of select="$emdash-space-char"/>
    <xsl:call-template name="mdash-character"/>
    <xsl:value-of select="$emdash-space-char"/>
</xsl:template>

<!-- ################## -->
<!-- Special Characters -->
<!-- ################## -->


<!-- These are characters which may look really bad                 -->
<!-- if faked from a keyboard (double brackets),                    -->
<!-- or lack an ASCII equivalent (like per-mille).  So we leave     -->
<!-- them undefined here as named templates with warnings and       -->
<!-- alarm bells, so that if a new conversion does not have an      -->
<!-- implementation, that will be discovered early in development.  -->

<xsl:template name="warn-unimplemented-character">
    <xsl:param name="char-name"/>
     <xsl:message>PTX:BUG:   the character named "<xsl:value-of select="$char-name"/>" needs an implementation in the current conversion</xsl:message>
     <xsl:text>[[[</xsl:text>
     <xsl:value-of select="$char-name"/>
     <xsl:text>]]]</xsl:text>
</xsl:template>

<!-- Left Single Quote -->
<xsl:template name="lsq-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'lsq'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="lsq">
    <xsl:call-template name="lsq-character"/>
</xsl:template>

<!-- Right Single Quote -->
<xsl:template name="rsq-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'rsq'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="rsq">
    <xsl:call-template name="rsq-character"/>
</xsl:template>

<!-- Left (Double) Quote -->
<xsl:template name="lq-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'lq'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="lq">
    <xsl:call-template name="lq-character"/>
</xsl:template>

<!-- Right (Double) Quote -->
<xsl:template name="rq-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'rq'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="rq">
    <xsl:call-template name="rq-character"/>
</xsl:template>

<!-- Left Double Bracket -->
<xsl:template name="ldblbracket-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'ldblbracket'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="ldblbracket">
    <xsl:call-template name="ldblbracket-character"/>
</xsl:template>

<!-- Right Double Bracket -->
<xsl:template name="rdblbracket-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'rdblbracket'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="rdblbracket">
    <xsl:call-template name="rdblbracket-character"/>
</xsl:template>

<!-- Left Angle Bracket -->
<xsl:template name="langle-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'langle'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="langle">
    <xsl:call-template name="langle-character"/>
</xsl:template>

<!-- Right Angle Bracket -->
<xsl:template name="rangle-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'rangle'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="rangle">
    <xsl:call-template name="rangle-character"/>
</xsl:template>

<!-- Ellipsis (dots), for text, not math -->
<xsl:template name="ellipsis-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'ellipsis'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="ellipsis">
    <xsl:call-template name="ellipsis-character"/>
</xsl:template>

<!-- Midpoint -->
<!-- A centered dot used sometimes like a decorative dash -->
<xsl:template name="midpoint-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'midpoint'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="midpoint">
    <xsl:call-template name="midpoint-character"/>
</xsl:template>

<!-- Swung Dash -->
<!-- A decorative dash, like a tilde, but bigger, and centered -->
<xsl:template name="swungdash-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'swungdash'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="swungdash">
    <xsl:call-template name="swungdash-character"/>
</xsl:template>

<!-- Per Mille -->
<!-- Or, per thousand, like a percent sign -->
<xsl:template name="permille-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'permille'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="permille">
    <xsl:call-template name="permille-character"/>
</xsl:template>

<!-- Pilcrow -->
<!-- Often used to mark the start of a paragraph -->
<xsl:template name="pilcrow-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'pilcrow'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="pilcrow">
    <xsl:call-template name="pilcrow-character"/>
</xsl:template>

<!-- Section Mark -->
<!-- The stylized double-S to indicate section numbers -->
<xsl:template name="section-mark-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'section-mark'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="section-mark">
    <xsl:call-template name="section-mark-character"/>
</xsl:template>

<!-- Minus -->
<!-- A hyphen/dash for use in text as subtraction or negation-->
<xsl:template name="minus-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'minus'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="minus">
    <xsl:call-template name="minus-character"/>
</xsl:template>

<!-- Times -->
<!-- A "multiplication sign" symbol for use in text -->
<xsl:template name="times-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'times'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="times">
    <xsl:call-template name="times-character"/>
</xsl:template>

<!-- Solidus -->
<!-- Fraction bar, not as steep as a forward slash -->
<xsl:template name="solidus-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'solidus'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="solidus">
    <xsl:call-template name="solidus-character"/>
</xsl:template>

<!-- Obelus -->
<!-- A "division" symbol for use in text -->
<xsl:template name="obelus-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'obelus'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="obelus">
    <xsl:call-template name="obelus-character"/>
</xsl:template>

<!-- Plus/Minus -->
<!-- The combined symbol -->
<xsl:template name="plusminus-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'plusminus'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="plusminus">
    <xsl:call-template name="plusminus-character"/>
</xsl:template>

<!-- Copyright -->
<!-- Bringhurst: on baseline (i.e. not superscript) -->
<xsl:template name="copyright-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'copyright'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="copyright">
    <xsl:call-template name="copyright-character"/>
</xsl:template>

<!-- Phonomark -->
<!-- copyright on sound recordings                 -->
<!-- Bringhurst: counterpart copyright on baseline -->
<xsl:template name="phonomark-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'phonomark'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="phonomark">
    <xsl:call-template name="phonomark-character"/>
</xsl:template>

<!-- Copyleft -->
<!-- Bringhurst: counterpart copyright on baseline -->
<xsl:template name="copyleft-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'copyleft'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="copyleft">
    <xsl:call-template name="copyleft-character"/>
</xsl:template>

<!-- Registered -->
<!-- Bringhurst: should be superscript -->
<xsl:template name="registered-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'registered'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="registered">
    <xsl:call-template name="registered-character"/>
</xsl:template>

<!-- Trademark -->
<!-- Bringhurst: should be superscript -->
<xsl:template name="trademark-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'trademark'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="trademark">
    <xsl:call-template name="trademark-character"/>
</xsl:template>

<!-- Servicemark -->
<!-- Bringhurst: counterpart trademark should be superscript -->
<xsl:template name="servicemark-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'servicemark'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="servicemark">
    <xsl:call-template name="servicemark-character"/>
</xsl:template>

<!-- Coordinates, Temperature, English distance -->
<!-- Intended for simple non-technical uses, without too -->
<!-- much overhead.  The SI unit markup would be better  -->
<!-- suited for scientific or technical work.            -->

<!-- Degree -->
<xsl:template name="degree-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'degree'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="degree">
    <xsl:call-template name="degree-character"/>
</xsl:template>

<!-- Prime -->
<xsl:template name="prime-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'prime'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="prime">
    <xsl:call-template name="prime-character"/>
</xsl:template>

<!-- Double Prime -->
<xsl:template name="dblprime-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'dblprime'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="dblprime">
    <xsl:call-template name="dblprime-character"/>
</xsl:template>

<!-- Characters for Tagging Equations -->

<xsl:template name="tag-star">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'tag-star'"/>
    </xsl:call-template>
</xsl:template>

<xsl:template name="tag-dagger">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'tag-dagger'"/>
    </xsl:call-template>
</xsl:template>

<xsl:template name="tag-daggerdbl">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'tag-daggerdbl'"/>
    </xsl:call-template>
</xsl:template>

<xsl:template name="tag-hash">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'tag-hash'"/>
    </xsl:call-template>
</xsl:template>

<!-- AMS symbol designed for both text and math modes -->
<xsl:template name="tag-maltese">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'tag-maltese'"/>
    </xsl:call-template>
</xsl:template>

<!-- Dots
http://tex.stackexchange.com/questions/19180/which-dot-character-to-use-in-which-context

Swung Dash
http://andrewmccarthy.ie/2014/11/06/swung-dash-in-latex/
 -->
<!-- ######### -->
<!-- Groupings -->
<!-- ######## -->

<!-- Characters with left and right variants naturally       -->
<!-- give rise to tags with begin and end variants           -->
<!-- We implement these here with Result Tree Fragments      -->
<!-- as a polymorphic technique for the actual characters    -->
<!-- LaTeX quotes are odd, so we override "q" and "sq" there -->

<xsl:template match="q">
    <xsl:call-template name="lq-character"/>
    <xsl:apply-templates/>
    <xsl:call-template name="rq-character"/>
</xsl:template>

<xsl:template match="sq">
    <xsl:call-template name="lsq-character"/>
    <xsl:apply-templates/>
    <xsl:call-template name="rsq-character"/>
</xsl:template>

<xsl:template match="dblbrackets">
    <xsl:call-template name="ldblbracket-character"/>
    <xsl:apply-templates/>
    <xsl:call-template name="rdblbracket-character"/>
</xsl:template>

<xsl:template match="angles">
    <xsl:call-template name="langle-character"/>
    <xsl:apply-templates/>
    <xsl:call-template name="rangle-character"/>
</xsl:template>

<!-- ########## -->
<!-- XML Syntax -->
<!-- ########## -->

<!-- So we can write knowledgeably about XML in documentation -->
<!-- NB: we can use RTFs to keep this in -common since the    -->
<!-- content of each element is so simple                     -->

<!-- A tag, with angle brackets and monospace font -->
<xsl:template match="tag">
    <xsl:call-template name="code-wrapper">
        <xsl:with-param name="content">
            <xsl:text>&lt;</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>&gt;</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- An empty tag, with angle brackets and monospace font -->
<xsl:template match="tage">
    <xsl:call-template name="code-wrapper">
        <xsl:with-param name="content">
            <xsl:text>&lt;</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>/&gt;</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- An attribute, with @ and monospace font -->
<xsl:template match="attr">
    <xsl:call-template name="code-wrapper">
        <xsl:with-param name="content">
            <xsl:text>@</xsl:text>
            <xsl:value-of select="."/>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- ################### -->
<!-- Non-Semantic Markup -->
<!-- ################### -->

<!-- It is useful, initially for bibliographies to be able    -->
<!-- to render some chunks of text as simply bold or italic.  -->
<!--                                                          -->
<!-- So we make an abstract modal templates for this purpose, -->
<!-- with implementations in derived stylesheets.  We are     -->
<!-- also able to employ these to define "internal" markup,   -->
<!-- which we use on externally produced source.              -->

<!-- These stubs alert a developer to the need for      -->
<!-- implementation in a derived stylesheet.  These     -->
<!-- allow us to define our own bibliography management -->
<!-- here, not repeatedly in derived stylesheets.       -->

<xsl:template match="*" mode="italic">
    <xsl:message>PTX:BUG:  current conversion needs an implementation of the italic font</xsl:message>
</xsl:template>

<xsl:template match="*" mode="bold">
    <xsl:message>PTX:BUG:  current conversion needs an implementation of the bold font</xsl:message>
</xsl:template>

<xsl:template match="*" mode="monospace">
    <xsl:message>PTX:BUG:  current conversion needs an implementation of the monospace font</xsl:message>
</xsl:template>

<xsl:template name="biblio-period">
    <xsl:message>PTX:BUG:  current conversion needs an implementation of a bibliographic period</xsl:message>
</xsl:template>

<!-- Single implementations of highly non-semantic elements    -->
<!-- which trade on the modal templates.  We can use these in  -->
<!-- manufactured text which is not authored, nor rarely seen. -->

<xsl:template match="pi:italic">
    <xsl:apply-templates select="." mode="italic"/>
</xsl:template>

<xsl:template match="pi:bold">
    <xsl:apply-templates select="." mode="bold"/>
</xsl:template>

<!-- ############## -->
<!-- Bibliographies -->
<!-- ############## -->

<!-- Note: this general approach to "biblio" entries is by-passed     -->
<!-- in the HTML conversion, due to larger architectural limitations. -->

<!-- Historical: first pass, mixed content, with a  -->
<!-- few elements implemented for visual appearance -->
<xsl:template match="biblio[@type = 'raw']">
    <xsl:apply-templates select="." mode="bibentry-wrapper">
        <xsl:with-param name="content">
            <!-- mixed-content, text is relevant -->
            <xsl:apply-templates select="text()|*"/>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- "BibTeX style": initiated by David Farmer  -->
<!-- December 2021, see commit 44c9f8e00d525796 -->
<!-- Structured, but rendered in document order -->
<xsl:template match="biblio[@type = 'bibtex']">
    <xsl:apply-templates select="." mode="bibentry-wrapper">
        <xsl:with-param name="content">
            <!-- structured, elements only, document order -->
            <xsl:apply-templates select="*"/>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- If a plain "biblio" survives pre-processing, it means there -->
<!-- is no CSL stylesheet specified and we just do our best to   -->
<!-- make something reasonable.  We do assume the author knows   -->
<!-- this, and has authored the elements in the desired order    -->
<!-- (processing is in "document order").                        -->
<xsl:template match="biblio[not(@type = 'raw') and not(@type = 'bibtex')]">
    <xsl:apply-templates select="." mode="bibentry-wrapper">
        <xsl:with-param name="content">
            <!-- structured, elements only, document order -->
            <xsl:apply-templates select="*"/>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="biblio" mode="bibentry-wrapper">
    <xsl:message>PTX:BUG:  current conversion needs an implementation of the "bibentry-wrapper" template</xsl:message>
</xsl:template>


<!-- Raw Bibliographic Entry Formatting              -->
<!-- Markup really, not full-blown data preservation -->

<xsl:template match="pi:csl-citation">
    <!-- Some citations have titles, some titles have  -->
    <!-- math, and so cannot just select "text + xref" -->
    <xsl:apply-templates select="node()"/>
</xsl:template>

<!-- Title in italics -->
<xsl:template match="biblio[@type='raw']/title">
    <xsl:apply-templates select="." mode="italic"/>
</xsl:template>

<!-- No treatment for journal -->
<xsl:template match="biblio[@type='raw']/journal">
    <xsl:apply-templates/>
</xsl:template>

<!-- Volume in bold -->
<xsl:template match="biblio[@type='raw']/volume">
    <xsl:apply-templates select="." mode="bold"/>
</xsl:template>

<!-- Year in parentheses -->
<xsl:template match="biblio[@type='raw']/year">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- Number -->
<xsl:template match="biblio[@type='raw']/number">
    <xsl:text>no</xsl:text>
    <xsl:call-template name="biblio-period"/>
    <xsl:call-template name="thin-space-character"/>
    <xsl:apply-templates/>
</xsl:template>

<!-- Ibid, nee ibidem, empty element -->
<xsl:template match="biblio[@type='raw']/ibid">
    <xsl:text>Ibid</xsl:text>
    <xsl:call-template name="biblio-period"/>
    <!-- Generally has a trailing comma, so no thin space -->
</xsl:template>


<!-- Fully marked-up bibtex-style bibliographic entry formatting -->
<!-- Current treatment assumes elements are in the correct order -->

<!-- Comma after author or editor -->
<xsl:template match="biblio[@type='bibtex']/author">
    <xsl:apply-templates select="text()"/>
    <xsl:text>, </xsl:text>
</xsl:template>
<xsl:template match="biblio[@type='bibtex']/editor">
    <xsl:apply-templates select="text()"/>
    <xsl:text>, </xsl:text>
</xsl:template>

<!-- Title in italics, followed by comma -->
<xsl:template match="biblio[@type='bibtex']/title">
    <xsl:apply-templates select="." mode="italic"/>
    <xsl:text>, </xsl:text>
</xsl:template>

<!-- Space after journal -->
<xsl:template match="biblio[@type='bibtex']/journal">
    <xsl:apply-templates select="text()|m"/>
    <xsl:text> </xsl:text>
</xsl:template>

<!-- Volume in bold -->
<xsl:template match="biblio[@type='bibtex']/volume">
    <xsl:apply-templates select="." mode="bold"/>
    <xsl:text> </xsl:text>
</xsl:template>

<!-- Series is plain (but space after) -->
<xsl:template match="biblio[@type='bibtex']/series">
    <xsl:apply-templates select="text()"/>
    <xsl:text> </xsl:text>
</xsl:template>

<!-- Publisher is plain (but semicolon after) -->
<xsl:template match="biblio[@type='bibtex']/publisher">
    <xsl:apply-templates select="text()"/>
    <xsl:text>; </xsl:text>
</xsl:template>

<!-- Year in parentheses -->
<xsl:template match="biblio[@type='bibtex']/year">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="text()"/>
    <xsl:text>) </xsl:text>
</xsl:template>

<!-- Number: no. and comma after -->
<!-- Note: original pure LaTeX implemenation did not have -->
<!-- a trailing comma, the pure HTML implementation did   -->
<xsl:template match="biblio[@type='bibtex']/number">
    <xsl:text>no</xsl:text>
    <xsl:call-template name="biblio-period"/>
    <xsl:call-template name="thin-space-character"/>
    <xsl:apply-templates select="text()"/>
    <xsl:text>, </xsl:text>
</xsl:template>

<!-- A "pubnote", which could contain any publication information -->
<xsl:template match="biblio[@type='bibtex']/pubnote">
    <xsl:text> [</xsl:text>
    <xsl:apply-templates select="text()"/>
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- Pages should come last, so put a period.    -->
<!-- Two forms: @start and @end,                 -->
<!-- or total number as content (as for a book). -->
<xsl:template match="biblio[@type='bibtex']/pages[not(@start)]">
    <xsl:apply-templates select="text()"/>
    <xsl:text>.</xsl:text>
</xsl:template>
<xsl:template match="biblio[@type='bibtex']/pages[@start]">
    <xsl:text>pp</xsl:text>
    <xsl:call-template name="biblio-period"/>
    <xsl:call-template name="thin-space-character"/>
    <xsl:value-of select="@start"/><xsl:text>-</xsl:text><xsl:value-of select="@end"/>
    <xsl:text>.</xsl:text>
</xsl:template>

<!-- Always: authors first, no leading separator -->
<!-- Others: leading separators                  -->
<!-- Document order                              -->
<!-- Final period when no following-siblings     -->

<xsl:template match="biblio[not(@type = 'raw') and not(@type = 'bibtex')]/*">
    <xsl:message>PTX:WARNING:  a child of "biblio" (<xsl:value-of select="local-name()"/>) is not being processed.  Please report me so this can be fixed.</xsl:message>
</xsl:template>

<!-- Authors, no lead-in, no trailing space -->
<xsl:template match="biblio[not(@type = 'raw') and not(@type = 'bibtex')]/author">
    <xsl:for-each select="name">
        <xsl:choose>
            <!-- First, name with family name first -->
            <xsl:when test="not(preceding-sibling::name)">
                <xsl:apply-templates select="family"/>
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="given"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="given"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="family"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <!-- separators come before subsequent items -->
            <xsl:when test="count(following-sibling::name) = 0"/>
            <!-- one more left, use "and" -->
            <xsl:when test="count(following-sibling::name) = 1">
                <xsl:text> and </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>; </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
    <xsl:apply-templates select="." mode="plain-biblio-period"/>
</xsl:template>

<!-- Title, in italics -->
<xsl:template match="biblio[not(@type = 'raw') and not(@type = 'bibtex')]/title">
    <xsl:text>, </xsl:text>
    <xsl:apply-templates select="." mode="italic"/>
    <xsl:apply-templates select="." mode="plain-biblio-period"/>
</xsl:template>

<!-- Collection title -->
<!-- Once had "lq-character" and "rq-character", but -->
<!-- removed for consistency with other formats      -->
<xsl:template match="biblio[not(@type = 'raw') and not(@type = 'bibtex')]/collection-title">
    <xsl:text>, </xsl:text>
    <xsl:apply-templates/>
    <xsl:apply-templates select="." mode="plain-biblio-period"/>
</xsl:template>

<!-- Publisher -->
<xsl:template match="biblio[not(@type = 'raw') and not(@type = 'bibtex')]/publisher">
    <xsl:text>, </xsl:text>
    <xsl:apply-templates/>
    <xsl:apply-templates select="." mode="plain-biblio-period"/>
</xsl:template>

<!-- Publisher place-->
<xsl:template match="biblio[not(@type = 'raw') and not(@type = 'bibtex')]/publisher-place">
    <xsl:text>, </xsl:text>
    <xsl:apply-templates/>
    <xsl:apply-templates select="." mode="plain-biblio-period"/>
</xsl:template>

<!-- Collection title -->
<!-- Once had "lq-character" and "rq-character", but -->
<!-- removed for consistency with other formats      -->
<xsl:template match="biblio[not(@type = 'raw') and not(@type = 'bibtex')]/collection-title">
    <xsl:text>, </xsl:text>
    <xsl:apply-templates/>
    <xsl:apply-templates select="." mode="plain-biblio-period"/>
</xsl:template>

<!-- Volume in bold -->
<xsl:template match="biblio[not(@type = 'raw') and not(@type = 'bibtex')]/volume">
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="bold"/>
    <xsl:apply-templates select="." mode="plain-biblio-period"/>
</xsl:template>

<!-- Number, presumes it follows volume -->
<xsl:template match="biblio[not(@type = 'raw') and not(@type = 'bibtex')]/number">
    <xsl:text> no. </xsl:text>
    <xsl:apply-templates/>
    <xsl:apply-templates select="." mode="plain-biblio-period"/>
</xsl:template>

<!-- Date as a year, in parentheses -->
<xsl:template match="biblio[not(@type = 'raw') and not(@type = 'bibtex')]/issued">
    <xsl:text> </xsl:text>
    <xsl:text>(</xsl:text>
    <xsl:value-of select="date/@year"/>
    <xsl:text>)</xsl:text>
    <xsl:apply-templates select="." mode="plain-biblio-period"/>
</xsl:template>

<!-- Pages as a range             -->
<!-- Differs from "bibtex" format -->
<xsl:template match="biblio[not(@type = 'raw') and not(@type = 'bibtex')]/page">
    <xsl:text> </xsl:text>
    <xsl:apply-templates/>
    <xsl:apply-templates select="." mode="plain-biblio-period"/>
</xsl:template>

<!-- URL (upper-case?) -->
<xsl:template match="biblio[not(@type = 'raw') and not(@type = 'bibtex')]/URL">
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="monospace"/>
    <xsl:apply-templates select="." mode="plain-biblio-period"/>
</xsl:template>

<xsl:template match="*" mode="plain-biblio-period">
    <xsl:if test="not(following-sibling::*)">
        <xsl:text>.</xsl:text>
    </xsl:if>
</xsl:template>


<!-- ############ -->
<!-- Conveniences -->
<!-- ############ -->

<!-- Conveniences, possibly overridden in format-specific conversions -->
<!-- NB: we need to distinguish empty elements in some cases.  Since  -->
<!-- pre-processing is likely to add some attributes, and perhaps an  -->
<!-- element could have an opening and ending tag split across lines, -->
<!-- we just presume the non-empty case is indicated by elements as   -->
<!-- children.  Also, the schema should indicate that there are       -->
<!-- extraneous authored elements, so the less-severe testing is not  -->
<!-- a contract.                                                      -->
<!-- TODO: kern, etc. into LaTeX, HTML versions -->
<xsl:template match="webwork[not(* or @copy or @source)]">
    <xsl:text>WeBWorK</xsl:text>
</xsl:template>

<!-- ##############-->
<!-- Prophylactics -->
<!-- ############# -->

<!-- We nullify certain elements here that should only be active -->
<!-- in some formats, and templates there can override these     -->

<xsl:template match="instruction" />

<!-- ################### -->
<!-- Errors and Warnings -->
<!-- ################### -->

<!-- Sometimes we want a big warning as part of  -->
<!-- every use of some conversion.  This is it.  -->
<!-- Feed a linefeed in if you want line breaks. -->
<!-- Designed for an 80 column terminal.         -->
<xsl:template name="banner-warning">
    <xsl:param name="warning" />
    <xsl:message>********************************************************************************</xsl:message>
    <xsl:call-template name="warning-line-by-line">
        <xsl:with-param name="warning" select="$warning" />
    </xsl:call-template>
    <xsl:message>********************************************************************************</xsl:message>
</xsl:template>

<xsl:template name="warning-line-by-line">
    <xsl:param name="warning" />
    <xsl:variable name="after" select="substring-before($warning,'&#xa;')"/>
    <xsl:choose>
        <!-- no line breaks in warning, just print it -->
        <xsl:when test="substring-before($warning,'&#xa;') = ''">
            <xsl:message><xsl:value-of select="$warning" /></xsl:message>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message><xsl:value-of select="substring-before($warning,'&#xa;')" /></xsl:message>
            <xsl:call-template name="warning-line-by-line">
                <xsl:with-param name="warning" select="substring-after($warning,'&#xa;')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- We search up the tree, looking for something -->
<!-- an author will recognize, and then report it -->
<!-- Useful for warnings that do not contain any  -->
<!-- identifying information themselves           -->
<xsl:template match="*|@*" mode="location-report">
    <xsl:choose>
        <xsl:when test="@xml:id or title">
            <!-- print information about location -->
            <xsl:message>
                <xsl:text>             located within: </xsl:text>
                <xsl:if test="@xml:id">
                    <xsl:text>"</xsl:text>
                    <xsl:value-of select="@xml:id" />
                    <xsl:text>" (xml:id)</xsl:text>
                </xsl:if>
                <xsl:if test="@xml:id and title">
                    <xsl:text>, </xsl:text>
                </xsl:if>
                <xsl:if test="title">
                    <xsl:text>"</xsl:text>
                    <xsl:value-of select="title" />
                    <xsl:text>" (title)</xsl:text>
                </xsl:if>
            </xsl:message>
        </xsl:when>
        <xsl:when test="mathbook|pretext">
            <!-- at root, fail with no action -->
        </xsl:when>
        <xsl:otherwise>
            <!-- pop up a level and try again -->
            <xsl:apply-templates select="parent::*[1]" mode="location-report" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Debugging info -->
<!-- @xml:base attribute of xinclude scheme -->
<!-- @xml:id - self-explanatory             -->
<!-- title - if there is one                -->
<xsl:template match="*" mode="debug-location">
    <xsl:if test="$b-debug">
        <xsl:message>
            <xsl:text>PTX:DEBUG:   </xsl:text>
            <xsl:text>f: </xsl:text>
            <xsl:choose>
                <xsl:when test="@xml:base">
                    <xsl:value-of select="@xml:base" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text></xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>|e: </xsl:text>
            <xsl:value-of select="local-name(.)" />
            <xsl:text>|i: </xsl:text>
            <xsl:value-of select="@xml:id" />
            <xsl:text>|t: </xsl:text>
            <xsl:apply-templates select="." mode="title-simple" />
        </xsl:message>
    </xsl:if>
</xsl:template>

<!-- ############### -->
<!-- Global Warnings -->
<!-- ############### -->

<!-- Checks for errors that would be time-consuming -->
<!-- if done repeatedly, so a pre-processing step   -->
<!-- Calling context could be "mathbook" element    -->
<!-- NB: this is called early by any author-facing  -->
<!-- "mainline" conversion (and not by some         -->
<!-- utilities) where the select attribute is the   -->
<!-- "$original" tree defined as the author's       -->
<!-- actual source file.                            -->
<xsl:template match="mathbook|pretext" mode="generic-warnings">
    <xsl:apply-templates select="." mode="literate-programming-warning" />
    <xsl:apply-templates select="." mode="xinclude-warnings" />
    <xsl:apply-templates select="." mode="identifier-warning"/>
    <xsl:apply-templates select="." mode="text-element-warning" />
    <xsl:apply-templates select="." mode="subdivision-structure-warning" />
    <xsl:apply-templates select="." mode="table-paragraph-cells-warning" />
</xsl:template>

<!-- Literate Programming support is half-baked, 2017-07-21 -->
<xsl:template match="mathbook|pretext" mode="literate-programming-warning">
    <xsl:if test=".//fragment">
        <xsl:call-template name="banner-warning">
            <xsl:with-param name="warning">
                <xsl:text>  Literate Programming support is incomplete&#xa;</xsl:text>
                <xsl:text>&#xa;</xsl:text>
                <xsl:text>    1.  Code generation is functional, but does not respect indentation&#xa;</xsl:text>
                <xsl:text>    2.  LaTeX generation is functional, could be improved, 2020-11-11&#xa;</xsl:text>
                <xsl:text>    2.  HTML generation is functional, could be improved, 2020-11-11&#xa;</xsl:text>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Using the modular  xinclude  scheme at the top level,      -->
<!-- and forgetting the command-line switch is a common mistake -->
<!-- The following is not perfect, but reasonably effective     -->
<xsl:template match="mathbook|pretext" mode="xinclude-warnings">
    <xsl:if test="book and not(book/chapter or book/part/chapter)">
        <xsl:message>
            <xsl:text>PTX:WARNING:    </xsl:text>
            <xsl:text>Your &lt;book&gt; does not have any chapters.  Maybe you forgot the '--xinclude' switch on your 'xsltproc' command line?</xsl:text>
        </xsl:message>
    </xsl:if>
    <xsl:if test="article and not(article/p) and not(article/section) and not(article/worksheet) and not(article/handout)">
        <xsl:message>
            <xsl:text>PTX:WARNING:    </xsl:text>
            <xsl:text>Your &lt;article&gt; does not have any sections, worksheets, or handouts, nor any top-level paragraphs.  Maybe you forgot the '--xinclude' switch on your 'xsltproc' command line?</xsl:text>
        </xsl:message>
    </xsl:if>
</xsl:template>

<!-- We warn about bad xml:id.  Our limits: -->
<!-- 26 Latin letters (upper, lower case),  -->
<!-- 10 digits, hyphen/dash, underscore     -->
<!-- TODO: Added 2016-10-29, make into a fatal error later -->
<!-- Unique UI id's added 2017-09-25 as fatal error -->
<xsl:template match="mathbook|pretext" mode="identifier-warning">
    <xsl:variable name="xmlid-characters" select="concat('-_', &SIMPLECHAR;)" />
    <xsl:for-each select=".//@xml:id">
        <xsl:if test="not(translate(., $xmlid-characters, '') = '')">
            <xsl:message>
                <xsl:text>PTX:ERROR:      </xsl:text>
                <xsl:text>The @xml:id "</xsl:text>
                <xsl:value-of select="." />
                <xsl:text>" is invalid.  Use only letters, numbers, hyphens and underscores.</xsl:text>
            </xsl:message>
        </xsl:if>
        <!-- unique HTML id's in use for PreTeXt-provided UI -->
        <xsl:if test="(. = 'masthead') or
                      (. = 'content') or
                      (. = 'primary-navbar') or
                      (. = 'sidebar-left') or
                      (. = 'sidebar-right') or
                      (. = 'toc') or
                      (. = 'logo-link')">
            <xsl:message terminate="yes">
                <xsl:text>PTX:FATAL:   </xsl:text>
                <xsl:text>The @xml:id "</xsl:text>
                <xsl:value-of select="." />
                <xsl:text>" is invalid since it will conflict with a unique HTML id in use by the user interface.  Please use a different string.  Quitting...</xsl:text>
            </xsl:message>
        </xsl:if>
        <!-- index.html is built automatically, so preclude a clash -->
        <!-- Not terminating until 2019-07-10 deprecation expires   -->
        <xsl:if test=". = 'index'">
            <xsl:message terminate="no">
                <xsl:text>PTX:ERROR:   </xsl:text>
                <xsl:text>The @xml:id "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>" is invalid since it will conflict with the construction of an automatic HTML "index.html" page.  Use some alternative for the real index - sorry.</xsl:text>
            </xsl:message>
        </xsl:if>
    </xsl:for-each>
</xsl:template>


<!-- Elements should never happen like this, so we     -->
<!-- can match on them and offer pretty good advice    -->
<!-- Last: since both summary and specifics.  We       -->
<!-- can't catch with a template, since we don't apply -->
<!-- templates in the places where elements are banned -->
<!-- c, cline; unstructured cd, pre                    -->
<!-- prompt, input, output for sage, console, program  -->
<!-- NB: cline/area is used in Clickable Area problems -->
<xsl:template match="mathbook|pretext" mode="text-element-warning">
    <xsl:variable name="bad-elements" select=".//c/*|.//cline/*[not(self::area)]|.//cd[not(cline)]/*|.//pre[not(cline)]/*|.//prompt[not(parent::checkpoint)]/*|.//input/*|.//output/*" />
    <xsl:if test="$bad-elements">
        <xsl:message>
            <xsl:text>PTX:WARNING: </xsl:text>
            <xsl:text>There are apparent XML elements in locations that should be text only (</xsl:text>
            <xsl:value-of select="count($bad-elements)" />
            <xsl:text> times).</xsl:text>
        </xsl:message>
    </xsl:if>
    <xsl:for-each select="$bad-elements">
        <xsl:message>
            <xsl:text>PTX:WARNING: </xsl:text>
            <xsl:text>There is an apparent XML element (&lt;</xsl:text>
            <xsl:value-of select="local-name(.)" />
            <xsl:text>&gt;) inside an &lt;</xsl:text>
            <xsl:value-of select="local-name(parent::*)" />
            <xsl:text>&gt; element, which should only contain text.  Using an escaped "less than" ('&amp;lt;') might be the solution, or using a CDATA section.</xsl:text>
        </xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:for-each>
</xsl:template>

<!-- New authors often begin a subdivision with some material,     -->
<!-- then begin a run of further subdivisions.  This preliminary   -->
<!-- material belongs in an introduction (or is for a conclusion). -->
<!-- This test is not exhaustive, but will catch most cases.       -->
<xsl:template match="mathbook|pretext" mode="subdivision-structure-warning">
    <xsl:for-each select="./book/chapter">
        <xsl:if test="p and section">
            <xsl:message>
                <xsl:text>PTX:WARNING: </xsl:text>
                <xsl:text>In a chapter containing sections, any content that is not inside a section needs to be inside an &lt;introduction&gt; and/or  &lt;conclusion&gt;.</xsl:text>
            </xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:if>
    </xsl:for-each>
    <xsl:for-each select="./article/section|./book/chapter/section">
        <xsl:if test="p and subsection">
            <xsl:message>
                <xsl:text>PTX:WARNING: </xsl:text>
                <xsl:text>In a section containing subsections, any content that is not inside a subsection needs to be inside an &lt;introduction&gt; and/or  &lt;conclusion&gt;.</xsl:text>
            </xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:if>
    </xsl:for-each>
    <xsl:for-each select="./article/section/subsection|./book/chapter/section/subsection">
        <xsl:if test="p and subsubsection">
            <xsl:message>
                <xsl:text>PTX:WARNING: </xsl:text>
                <xsl:text>In a subsection containing subsubsections, any content that is not inside a subsubsection needs to be inside an &lt;introduction&gt; and/or  &lt;conclusion&gt;.</xsl:text>
            </xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<xsl:template match="mathbook|pretext" mode="table-paragraph-cells-warning">
    <xsl:for-each select=".//tabular">
        <xsl:if test="row/cell/p and not(col/@width)">
            <xsl:message>PTX:ERROR:   a &lt;tabular&gt; has at least one paragraph (&lt;p&gt;) inside a &lt;cell&gt;, yet there are no &lt;col&gt; elements with a @width attribute.  Default widths will be supplied.</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:if>
    </xsl:for-each>
</xsl:template>



<!-- ############ -->
<!-- Deprecations -->
<!-- ############ -->

<!-- Locating all instances of a deprecated element looks  -->
<!-- expensive. (Turns out it might be less than 1% of the -->
<!-- time to build a full book.) But we have a scheme to   -->
<!-- only look back a limited time period (four years),    -->
<!-- controlled by a string parameter (not a publisher     -->
<!-- switch).  The default is to perform a full search     -->
<!-- of all such deprecations.                             -->
<xsl:param name="author.deprecations.all" select="''" />
<xsl:variable name="deprecation-max-age">
    <xsl:choose>
        <xsl:when test="($author.deprecations.all = 'yes') or ($author.deprecations.all = '')">
            <xsl:text>P100Y</xsl:text>
        </xsl:when>
        <xsl:when test="$author.deprecations.all = 'no'">
            <xsl:text>P4Y</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>P100Y</xsl:text>
            <xsl:message>PTX:ERROR:   "author.deprecations.all" should be "yes" or "no", not "<xsl:value-of select="$author.deprecations.all"/>", using the default value of "yes"</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Generic deprecation message for uniformity    -->
<!-- "occurrences" is a quote-protected expression -->
<!-- that evaluates to node-set of "problem" nodes -->
<!-- A message string like "'foo'" cannot contain  -->
<!-- a single quote, even if entered as &apos;.    -->
<!-- If despearate, concatentate with $apos.       -->
<!-- A &#xa; can be used if necessary, but only    -->
<!-- rarely do we bother.                          -->
<!-- NB: this is called early by any author-facing -->
<!-- "mainline" conversion (and not by some        -->
<!-- utilities) where the select attribute is the  -->
<!-- "$original" tree defined as the author's      -->
<!-- actual source file.                           -->
<xsl:template name="deprecation-message">
    <xsl:param name="occurrences" />
    <xsl:param name="date-string" />
    <xsl:param name="message" />
    <xsl:param name="b-bulk" select="false()"/>

    <!-- These apparent re-definitions are local to this template -->
    <!-- Reasons are historical, so to be a convenience           -->
    <xsl:variable name="docinfo" select="./docinfo"/>
    <xsl:variable name="document-root" select="./*[not(self::docinfo)]"/>

    <xsl:variable name="expire-date" select="date:seconds(date:add($date-string, $deprecation-max-age))"/>
    <xsl:variable name="today" select="date:seconds(date:date-time())"/>

    <!-- Document-wide searches for deprecated constructions are expensive. -->
    <!-- So we provide for automatic filtering by age.  (We limit this to   -->
    <!-- "current" versus "all" as an author/publisher choice.)  So this    -->
    <!-- templates receives a *string* version of an APath expression,      -->
    <!-- not the actual *node-set*.  Then the "dyn:evaluate()" function     -->
    <!-- constructs the node-set, but after it survives the date filter.    -->
    <xsl:if test="$expire-date > $today">
        <xsl:variable name="occurrences-rtf" select="dyn:evaluate($occurrences)" />
        <xsl:if test="$occurrences-rtf">
            <xsl:message>
                <xsl:text>PTX:DEPRECATE: (</xsl:text>
                <xsl:value-of select="$date-string" />
                <xsl:text>) </xsl:text>
                <xsl:value-of select="$message" />
                <xsl:text> (</xsl:text>
                <xsl:value-of select="count($occurrences-rtf)" />
                <xsl:text> time</xsl:text>
                <xsl:if test="count($occurrences-rtf) > 1">
                    <xsl:text>s</xsl:text>
                </xsl:if>
                <xsl:text>)</xsl:text>
                <!-- once verbosity is implemented -->
                <!-- <xsl:text>, set log.level to see more details</xsl:text> -->
            </xsl:message>
            <!-- Give location reports, except optionally, when the $occurences -->
            <!-- are so pervasive, squelch a (useless) long list of instances   -->
            <!-- that nobody would really want to see.                        . -->
            <xsl:if test="not($b-bulk)">
                <xsl:for-each select="$occurrences-rtf">
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:for-each>
            </xsl:if>
            <xsl:message>
                <xsl:text>--------------</xsl:text>
            </xsl:message>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- On the suspicion that the next template frequently "scans" the entire   -->
<!-- document tree, we attempted to add a developer-only "debug" switch      -->
<!-- that would bypass the tests here, and in "generic-warnings" and         -->
<!-- "parameter-deprecation-warnings". For the sample article the speed-up   -->
<!-- was about 1%, and for AATA the speed-up was apparently less.  Which was -->
<!-- all not worth the danger that authors and publishers could "turn off"   -->
<!-- deprecation warnings. (2023-05-11)                                      -->
<xsl:template match="mathbook|pretext" mode="element-deprecation-warnings">

    <!-- Element deprecation checks can be limited by time   -->
    <!-- and we want to issue an informational warning about -->
    <!-- the (possibly limited) time coverage:               -->
    <!--   * once only, per output build                     -->
    <!--   * only if a stylesheet actually does the checks   -->
    <!-- So this is the spot, right before launcing into     -->
    <!-- the actual checks.                                  -->
    <xsl:choose>
        <xsl:when test="$deprecation-max-age = 'P100Y'">
            <xsl:message>PTX:INFO:   checking all deprecated elements.</xsl:message>
        </xsl:when>
        <xsl:when test="$deprecation-max-age = 'P4Y'">
            <xsl:message>PTX:INFO:   checking ONLY the last FOUR YEARS of element deprecations.&#xa;Rerun with the string parameter "author.deprecations.all" set to "yes" to check your source against all deprecations.</xsl:message>
        </xsl:when>
        <xsl:otherwise/>
    </xsl:choose>

    <!-- Older deprecations at the top of this list, -->
    <!-- so author will see new at the tail end.     -->
    <!-- NB: XPath expressions to select "problem"   -->
    <!-- nodes must be given as strings, to allow    -->
    <!-- for delayed evaluation, only if the warning -->
    <!-- survives a date filter.                     -->
    <!-- Comments without implementations have moved -->
    <!-- to Schematron rules after residing here for -->
    <!-- at least 16 months (one year plus grace)    -->
    <!--  -->
    <!-- 2014-05-04  @filebase has been replaced in function by @xml:id -->
    <!-- 2014-06-25  xref once had cite as a variant -->
    <!-- 2015-01-28  once both circum and circumflex existed, circumflex won -->
    <!--  -->
    <!-- These have been outright removed since they simply became confusing -->
    <!-- 2017-07-05  top-level items that should have captions, but don't -->
    <!-- 2017-07-05  sidebyside items that do not have captions, so ineffective -->
    <!--  -->
    <!-- 2015-02-08  naked tikz, asymptote, sageplot are no longer accomodated -->
    <!-- 2015-02-20  tikz element is entirely abandoned -->
    <!-- 2017-12-22  latex-image-code element is entirely abandoned -->
    <!--  -->
    <!-- Active deprecations follow -->
    <!--  -->
    <!-- 2015-03-13  paragraph is renamed more accurately to paragraphs           -->
    <!-- 2017-07-16  removed all backwards compatibility and added empty template -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//paragraph&quot;" />
        <xsl:with-param name="date-string" select="'2015-03-13'" />
        <xsl:with-param name="message" select="'the &quot;paragraph&quot; element is deprecated and any contained content will silently not appear, replaced by functional equivalent &quot;paragraphs&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2015-03-17  various indicators of table rearrangement -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//tgroup&quot;" />
        <xsl:with-param name="date-string" select="'2015-03-17'" />
        <xsl:with-param name="message" select="'tables are done quite differently, the &quot;tgroup&quot; element is indicative'" />
    </xsl:call-template>
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//tgroup/thead/row/entry|$document-root//tgroup/tbody/row/entry&quot;" />
        <xsl:with-param name="date-string" select="'2015-03-17'" />
            <xsl:with-param name="message" select="'tables are done quite differently, the &quot;entry&quot; element should be replaced by the &quot;cell&quot; element'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2015-12-12  empty labels on an ordered list was a bad idea -->
     <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//ol[@label='']&quot;" />
        <xsl:with-param name="date-string" select="'2015-12-12'" />
        <xsl:with-param name="message" select="'an ordered list (&lt;ol&gt;) may not have empty labels, and numbering will be unpredictable.  Switch to an unordered list  (&lt;ul&gt;)'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-04-07  'plural' option for @autoname discarded -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//xref[@autoname='plural']&quot;" />
        <xsl:with-param name="date-string" select="'2016-04-07'" />
        <xsl:with-param name="message" select="'a &lt;xref&gt; element may not have an @autoname attribute set to plural.  There is no replacement, perhaps use content in the &lt;xref&gt;.'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-05-23  Require parts of a letter to be structured (could be relaxed) -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//letter/frontmatter/from[not(line)] | $document-root//letter/frontmatter/to[not(line)] | $document-root//letter/backmatter/signature[not(line)]&quot;" />
        <xsl:with-param name="date-string" select="'2016-05-23'" />
        <xsl:with-param name="message" select="'&lt;to&gt;, &lt;from&gt;, and &lt;signature&gt; of a letter must be structured as a sequence of &lt;line&gt;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-05-23  line breaks are not XML-ish, some places allow "line" -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//br&quot;" />
        <xsl:with-param name="date-string" select="'2016-05-23'" />
        <xsl:with-param name="message" select="'&lt;br&gt; can no longer be used to create multiline output; you may use &lt;line&gt; elements in select situations'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-07-31  ban @height attribute, except within webwork problems -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//image[@height and not(ancestor::*[self::webwork])]&quot;" />
        <xsl:with-param name="date-string" select="'2016-07-31'" />
        <xsl:with-param name="message" select="'@height attribute on &lt;image&gt; is no longer effective and will be ignored, except within a WeBWorK exercise'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-07-31  widths of images must be expressed as percentages -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//image[@width and not(contains(@width, '%'))]&quot;" />
        <xsl:with-param name="date-string" select="'2016-07-31'" />
        <xsl:with-param name="message" select="'@width attribute on &lt;image&gt; must be expressed as a percentage'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-02-05  hyphen-minus replaces hyphen; 2018-12-01 use keyboard hyphen -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//hyphen&quot;" />
        <xsl:with-param name="date-string" select="'2017-02-05'" />
        <xsl:with-param name="message" select="'use the keyboard hyphen character as a direct replacement for &lt;hyphen/&gt;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-05  a sidebyside cannot have a caption -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//sidebyside[caption]&quot;" />
        <xsl:with-param name="date-string" select="'2017-07-05'" />
        <xsl:with-param name="message" select="'a &lt;sidebyside&gt; cannot have a &lt;caption&gt;.  Place the &lt;sidebyside&gt; inside a &lt;figure&gt;, employing the &lt;caption&gt;, which will be the functional equivalent.'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-14  index specification and production reworked -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//index-part&quot;" />
        <xsl:with-param name="date-string" select="'2017-07-14'" />
        <xsl:with-param name="message" select="'the &quot;index-part&quot; element is deprecated, replaced by functional equivalent &quot;index&quot;'" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//index[not(main) and not(index-list)]&quot;" />
        <xsl:with-param name="date-string" select="'2017-07-14'" />
        <xsl:with-param name="message" select="'a &quot;index&quot; element is deprecated, replaced by functional equivalent &quot;idx&quot;'" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//index[main]&quot;" />
        <xsl:with-param name="date-string" select="'2017-07-14'" />
        <xsl:with-param name="message" select="'a &quot;index&quot; element with &quot;main&quot; and &quot;sub&quot; headings is deprecated, replaced by functional equivalent &quot;idx&quot; with &quot;h&quot; headings'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-14  cosmetic replacement of WW image/@tex_size by image/@tex-size -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//@tex_size&quot;" />
        <xsl:with-param name="date-string" select="'2017-07-18'" />
        <xsl:with-param name="message" select="'the &quot;tex_size&quot; attribute is deprecated, replaced by functional equivalent &quot;tex-size&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-25  replacement of three xref/@autoname attributes by @text -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//xref[@autoname='no']&quot;" />
        <xsl:with-param name="date-string" select="'2017-07-25'" />
        <xsl:with-param name="message" select="'the &quot;xref/autoname&quot; attribute is deprecated, replace  autoname=&quot;no&quot;  by functional equivalent  text=&quot;global&quot;'" />
    </xsl:call-template>
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//xref[@autoname='yes']&quot;" />
        <xsl:with-param name="date-string" select="'2017-07-25'" />
        <xsl:with-param name="message" select="'the &quot;xref/autoname&quot; attribute is deprecated, replace  autoname=&quot;yes&quot;  by functional equivalent  text=&quot;type-global&quot;'" />
    </xsl:call-template>
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//xref[@autoname='title']&quot;" />
        <xsl:with-param name="date-string" select="'2017-07-25'" />
        <xsl:with-param name="message" select="'the &quot;xref/autoname&quot; attribute is deprecated, replace  autoname=&quot;title&quot;  by functional equivalent  text=&quot;title&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-08-04  repurpose task block for division of project-like -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//task[parent::chapter or parent::appendix or parent::section or parent::subsection or parent::subsubsection or parent::paragraphs or parent::introduction or parent::conclusion]&quot;" />
        <xsl:with-param name="date-string" select="'2017-08-04'" />
        <xsl:with-param name="message" select="'the &quot;task&quot; element is no longer used as a child of a top-level division, but is instead being used to divide the other &quot;project-like&quot; elements.  It can be replaced by a functional equivalent: &quot;project&quot;, &quot;activity&quot;, &quot;exploration&quot;, or &quot;investigation&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-09-10  deprecate title-less paragraphs, outside of sidebyside -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//paragraphs[not(title) and not(parent::sidebyside)]&quot;" />
        <xsl:with-param name="date-string" select="'2017-09-10'" />
        <xsl:with-param name="message" select="'the &quot;paragraphs&quot; element (outside of a &quot;sidebyside&quot;) now requires a &quot;title&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-11-09  WeBWorK images now with widths as percentages, only on an enclosing sidebyside -->
    <!-- 2020-11-04  One-panel sidebysides not necessary, so now only warn about old attributes     -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//webwork//image[@height or @tex-size]&quot;" />
        <xsl:with-param name="date-string" select="'2017-11-09'" />
        <xsl:with-param name="message" select="'an &quot;image&quot; within a &quot;webwork&quot; now has its size given by just a &quot;width&quot; attribute expressed as a percentage, including the percent sign (so in particular do not use &quot;height&quot; or &quot;tex-size&quot;)'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-11-09  Assemblages have been rationalized, warn about captioned items -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//assemblage//*[caption]&quot;" />
        <xsl:with-param name="date-string" select="'2017-11-09'" />
        <xsl:with-param name="message" select="'an &quot;assemblage&quot; should not contain any items with a &quot;caption&quot;.  You can instead place the content in a bare &quot;sidebyside&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-12-07  "c" content totally escaped for LaTeX -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//c/@latexsep|$document-root//cd/@latexsep&quot;" />
        <xsl:with-param name="date-string" select="'2017-12-07'" />
        <xsl:with-param name="message" select="'the &quot;@latexsep&quot; attribute on the &quot;c&quot; and &quot;cd&quot; elements is no longer necessary.  It is being ignored, and can be removed'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2018-02-04  geogebra-applet gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//geogebra-applet&quot;" />
        <xsl:with-param name="date-string" select="'2018-02-04'" />
        <xsl:with-param name="message" select="'the &quot;geogebra-applet&quot; element has been removed, investigate newer &quot;interactive&quot; element'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2018-02-05  booktitle becomes pubtitle -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//booktitle&quot;" />
        <xsl:with-param name="date-string" select="'2018-02-05'" />
        <xsl:with-param name="message" select="'the &quot;booktitle&quot; element has been replaced by the functionally equivalent &quot;pubtitle&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2018-04-06  jsxgraph absorbed into interactive -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//jsxgraph&quot;" />
        <xsl:with-param name="date-string" select="'2018-04-06'" />
        <xsl:with-param name="message" select="'the &quot;jsxgraph&quot; element has been deprecated, but remains functional, rework with the &quot;interactive&quot; element'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2018-05-02  paragraphs purely as a lightweight division -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//sidebyside/paragraphs&quot;" />
        <xsl:with-param name="date-string" select="'2018-04-06'" />
        <xsl:with-param name="message" select="'a &quot;paragraphs&quot; can no longer appear within a &quot;sidebyside&quot;, replace with a &quot;stack&quot; containing multiple elements, such as &quot;p&quot;'" />
    </xsl:call-template>
    <!-- 2018-05-18  WeBWorK refactor no longer needs setup/var elements for static representations-->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//webwork/setup/var&quot;" />
        <xsl:with-param name="date-string" select="'2018-05-18'" />
        <xsl:with-param name="message" select="'&quot;var&quot; elements in a &quot;webwork/setup&quot; no longer do anything; you may delete them from source'" />
    </xsl:call-template>
    <!-- 2018-07-04  "solution-list" generator element replaced by "solutions" division -->
    <!-- 2020-08-31  element, controlling switches, supporting templates, removed/deactivated -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//solution-list&quot;" />
        <xsl:with-param name="date-string" select="'2020-08-31'" />
        <xsl:with-param name="message" select="'the &quot;solution-list&quot; element has been removed (deprecated since 2018-07-04), please switch to using the improved &quot;solutions&quot; division in your back matter (and elsewhere)'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2018-09-26  appendix subdivision confusion resolved -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$root/article/backmatter/appendix/section&quot;" />
        <xsl:with-param name="date-string" select="'2018-09-26'" />
        <xsl:with-param name="message" select="'the first division of an &quot;appendix&quot; of an &quot;article&quot; should be a &quot;subsection&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2018-12-30  circa shortened to ca -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//circa&quot;" />
        <xsl:with-param name="date-string" select="'2018-12-30'" />
        <xsl:with-param name="message" select="'the &quot;circa&quot; element has been replaced by the functionally equivalent &quot;ca&quot;'" />
    </xsl:call-template>
    <!--                                                     -->
    <!-- LaTeX's 10 reserved characters: # $ % ^ & _ { } ~ \ -->
    <!--                                                     -->
    <!--  -->
    <!-- 2019-02-06  hash gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//hash&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;hash&quot; element is no longer necessary, simply replace with a bare &quot;#&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  dollar gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//dollar&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;dollar&quot; element is no longer necessary, simply replace with a bare &quot;$&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  percent gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//percent&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;percent&quot; element is no longer necessary, simply replace with a bare &quot;%&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  circumflex gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//circumflex&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;circumflex&quot; element is no longer necessary, simply replace with a bare &quot;^&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  ampersand gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//ampersand&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;ampersand&quot; element is no longer necessary, simply replace with a bare &quot;&amp;&quot; character (properly escaped, i.e. &quot;&amp;amp;&quot;)'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  underscore gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//underscore&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;underscore&quot; element is no longer necessary, simply replace with a bare &quot;_&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  lbrace gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//lbrace&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;lbrace&quot; element is no longer necessary, simply replace with a bare &quot;{&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  rbrace gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//rbrace&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;rbrace&quot; element is no longer necessary, simply replace with a bare &quot;}&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  tilde gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//tilde&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;tilde&quot; element is no longer necessary, simply replace with a bare &quot;~&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  backslash gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//backslash&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;backslash&quot; element is no longer necessary, simply replace with a bare &quot;\&quot; character'"/>
    </xsl:call-template>
    <!--                           -->
    <!-- Nine unnecessary elements -->
    <!--                           -->
    <!--  -->
    <!-- 2019-02-06  less gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//less&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;less&quot; element is no longer necessary, simply replace with a bare &quot;&lt;&quot; character (properly escaped, i.e. &quot;&amp;lt;&quot;)'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  greater gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//greater&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;greater&quot; element is no longer necessary, simply replace with a bare &quot;&gt;&quot; character (possibly escaped, i.e. &quot;&amp;gt;&quot;)'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  lbracket gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//lbracket&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;lbracket&quot; element is no longer necessary, simply replace with a bare &quot;[&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  rbracket gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//rbracket&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;rbracket&quot; element is no longer necessary, simply replace with a bare &quot;]&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  asterisk gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//asterisk&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;asterisk&quot; element is no longer necessary, simply replace with a bare &quot;*&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  slash gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//slash&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;slash&quot; element is no longer necessary, simply replace with a bare &quot;/&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  backtick gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//backtick&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;backtick&quot; element is no longer necessary, simply replace with a bare &quot;`&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  braces gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//braces&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;braces&quot; element is no longer necessary, simply replace with bare &quot;{&quot; and &quot;}&quot; characters'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  brackets gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//brackets&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;brackets&quot; element is no longer necessary, simply replace with bare &quot;[&quot; and &quot;]&quot; characters'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-20  "todo" items now in comments -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//todo&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-20'" />
        <xsl:with-param name="message" select="'a &quot;todo&quot; element is no longer effective.  Replace with an XML comment whose first four non-whitespace characters spell &quot;todo&quot; (with no spaces)'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-23  "rename/@lang" replaced by (optional) rename/@xml:lang -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo//rename[@lang]&quot;" />
        <xsl:with-param name="date-string" select="'2019-02-20'" />
        <xsl:with-param name="message" select="'the &quot;@lang&quot; attribute of &quot;rename&quot; has been replaced by &quot;@xml:lang&quot;, and is now optional if your document only uses one language'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-04-02  "mathbook" replaced by "pretext" -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;/mathbook&quot;" />
        <xsl:with-param name="date-string" select="'2019-04-02'" />
        <xsl:with-param name="message" select="'the &quot;mathbook&quot; top-level element has been replaced by the functionally equivalent &quot;pretext&quot;'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-04-14  analytics ID are now a publisher option -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/analytics&quot;" />
        <xsl:with-param name="date-string" select="'2019-04-14'" />
        <xsl:with-param name="message" select="'site-specific ID for HTML analytics services (Statcounter, Google) provided within &quot;docinfo/analytics&quot; are now options supplied by publishers as command-line options.  See the Publishers Guide for specifics.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-04-14  Google search ID is now a publisher option -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/search&quot;" />
        <xsl:with-param name="date-string" select="'2019-04-14'" />
        <xsl:with-param name="message" select="'site-specific ID for HTML search services (Google) is no longer provided within &quot;docinfo/search&quot;.  Please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2017-08-25  once deprecated named lists to be captioned lists -->
    <!-- 2019-06-28  deprecated captioned lists to be titled lists     -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//list[caption]&quot;" />
        <xsl:with-param name="date-string" select="'2017-06-28'" />
        <xsl:with-param name="message" select="'the &quot;list&quot; element requires a &quot;title&quot;, an existing &quot;caption&quot; is being ignored'" />
    </xsl:call-template>
    <!--  -->
    <!--  -->
    <!-- 2019-06-28  deprecated captioned tables to be titled tables  -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//table[caption]&quot;" />
        <xsl:with-param name="date-string" select="'2019-06-28'" />
        <xsl:with-param name="message" select="'the &quot;table&quot; element requires a &quot;title&quot;, an existing &quot;caption&quot; is being ignored'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2019-07-10  @xml:id = 'index' deprecated in favor of publisher's @ref  -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//*[@xml:id = 'index']&quot;" />
        <xsl:with-param name="date-string" select="'2019-07-10'" />
        <xsl:with-param name="message" select="'an element should no longer have an @xml:id equal to &quot;index&quot; as a way to create an HTML index.html page.  See the Publishers Guides chapter on the HTML conversion for instructions.'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2019-11-28  deprecated docinfo analytics in favor of publisher's file  -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/analytics&quot;" />
        <xsl:with-param name="date-string" select="'2019-11-28'" />
        <xsl:with-param name="message" select="'use of the docinfo/analytics element has been deprecated.  Existing elements are being respected, but please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.&#xa;  * For StatCounter this is a cosmetic change.&#xa;  * Google Classic has been deprecated by Google and will not be supported.&#xa;  * Google Universal has been replaced, your ID may continue to work.&#xa;  * Google Global Site Tag is fully supported, try your Universal ID.&#xa;'" />
    </xsl:call-template>

    <!-- 2020-03-13  deprecated setup element in a webwork -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//webwork/setup&quot;" />
        <xsl:with-param name="date-string" select="'2020-03-13'" />
        <xsl:with-param name="message" select="'the &quot;setup&quot; element in a &quot;webwork&quot; is no longer necessary, simply use &quot;pg-code&quot;'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2020-11-22  deprecate HTML base URL in docinfo -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/html/baseurl/@href&quot;" />
        <xsl:with-param name="date-string" select="'2020-11-22'" />
        <xsl:with-param name="message" select="'the &quot;baseurl/@href&quot; element in the &quot;docinfo&quot; has been replaced and is now specified in the publisher file with &quot;html/baseurl/@href&quot;, as documented in the PreTeXt Guide.  If you have multiple values due to multiple &quot;docinfo&quot; controlled by versions, then results will be very unpredictable.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2021-01-07  deprecate sidebyside within a webwork -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//webwork//sidebyside&quot;" />
        <xsl:with-param name="date-string" select="'2021-01-07'" />
        <xsl:with-param name="message" select="'a &quot;sidebyside&quot; as a descendant of a &quot;webwork&quot; has been replaced and now &quot;image&quot; and &quot;tabular&quot; elements should be used directly.'"/>
    </xsl:call-template>

    <!-- 2021-02-14  deprecate using docinfo for part structure -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/numbering/division/@part&quot;" />
        <xsl:with-param name="date-string" select="'2021-02-14'" />
        <xsl:with-param name="message" select="'docinfo/numbering/division/@part has been replaced by the  numbering/divisions/@part-structure  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2021-03-17  deprecate worksheet/pagebreak in favor of worksheet/page -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//worksheet/pagebreak&quot;" />
        <xsl:with-param name="date-string" select="'2021-03-17'" />
        <xsl:with-param name="message" select="'use of the empty &quot;pagebreak&quot; element has been deprecated in favor of a &quot;page&quot; element.  We will attempt to honor the empty element, but new features may only be available with the new element.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2021-06-24  deprecate @source to specify media on network -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//video[substring(@source,1,4) = 'http']|$document-root//audio[substring(@source,1,4) = 'http']&quot;" />
        <xsl:with-param name="date-string" select="'2021-06-24'" />
        <xsl:with-param name="message" select="'use of a &quot;@source&quot; attribute on a &quot;video&quot; or &quot;audio&quot; element to specify a network location (leading with &quot;http&quot;) has been deprecated, but will still be effective.  Replace with a &quot;@href&quot; attribute.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2021-07-02  deprecate notation/usage as bare LaTeX, needs exactly 1 "m"       -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//notation/usage[not(m)]&quot;" />
        <xsl:with-param name="date-string" select="'2021-07-02'" />
        <xsl:with-param name="message" select="'a &quot;notation/usage&quot; element should contain *exactly* one &quot;m&quot;.  There is none, but we will attempt to honor your intent'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2021-09-19  obsolete Reveal.js slideshow @minified option -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$publication/revealjs/resources/@minified&quot;" />
        <xsl:with-param name="date-string" select="'2021-09-19'" />
        <xsl:with-param name="message" select="'the Reveal.js publisher option for minified resources (revealjs/resources/@minified) is obsolete and is being ignored.  Removing it will stop this message'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2021-10-04  glossary "introduction" is now a "headnote" -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//glossary/introduction&quot;" />
        <xsl:with-param name="date-string" select="'2021-10-04'" />
        <xsl:with-param name="message" select="'a &quot;glossary&quot; &quot;introduction&quot; is now a &quot;headnote&quot;.  We will attempt to fix your source.  See the documentation for this, and other changes for &quot;glossary&quot;'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2021-10-04  "terms" was necessary to structure a "glossary", now obsolete -->
    <!-- Never in the schema, but a warning here as a public service -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//glossary/terms&quot;" />
        <xsl:with-param name="date-string" select="'2021-10-04'" />
        <xsl:with-param name="message" select="'a &quot;glossary&quot; no longer needs &quot;terms&quot; to structure its items.  We will attempt to fix your source.  See the documentation for this, and other changes for &quot;glossary&quot;'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2021-10-04  "defined-term" has been replaced by "gi" -->
    <!-- Never in the schema, but a warning here as a public service -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//glossary/terms/defined-term&quot;" />
        <xsl:with-param name="date-string" select="'2021-10-04'" />
        <xsl:with-param name="message" select="'a &quot;glossary&quot; no longer has &quot;defined-term&quot; but instead has glossary items (&quot;gi&quot;).  We will attempt to fix your source.  See the documentation for this, and other changes for &quot;glossary&quot;'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2021-10-04  glossary "conclusion" is obsolete -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//glossary/conclusion&quot;" />
        <xsl:with-param name="date-string" select="'2021-10-04'" />
        <xsl:with-param name="message" select="'a &quot;glossary&quot; no longer has a &quot;conclusion&quot;.  It is being ignored, so you will need to design an alternative.  See the documentation for this, and other changes for &quot;glossary&quot;'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2022-04-22  Python Tutor via @interactive="pythontutor" replaced by Runestone CodeLens-->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//program[@interactive = 'pythontutor']&quot;" />
        <xsl:with-param name="date-string" select="'2022-04-22'" />
        <xsl:with-param name="message" select="'a Python &quot;program&quot; with the attribute &quot;@interactive&quot; set to &quot;pythontutor&quot; is deprecated, but we will attempt to honor your intent.  Change the attribute value to &quot;codelens&quot; instead, and be certain to manufacture trace data using allied PreTeXt tools'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2022-04-25  "label" (typically on a list) is deprecated for renewal -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//ul/@label|$document-root//ol/@label&quot;" />
        <xsl:with-param name="date-string" select="'2022-04-25'" />
        <xsl:with-param name="message" select="'a &quot;@label&quot; attribute (on a &quot;ul&quot; or &quot;ol&quot; element) has been deprecated and should be replaced by the functionally equivalent &quot;@marker&quot;.  We will attempt to honor your request'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2022-04-25  "label" (typically on a list) is deprecated for renewal -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//video/track/@label&quot;" />
        <xsl:with-param name="date-string" select="'2022-04-25'" />
        <xsl:with-param name="message" select="'a &quot;@label&quot; attribute (on a &quot;video/track&quot; element) has been deprecated and should be replaced by the functionally equivalent &quot;@listing&quot;.  We will attempt to honor your request'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2022-06-09  replace a WebWorK "stage" by a standard "task" -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//webwork/stage&quot;" />
        <xsl:with-param name="date-string" select="'2022-06-09'" />
        <xsl:with-param name="message" select="'an ad-hoc &quot;stage&quot; element in a scaffolded WeBWorK problem has been replaced by a standard PreTeXt &quot;task&quot; element, so make simple subsitutions.  We will attempt to honor your request'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2022-07-10  deprecate latex-image with @syntax="PGtikz" -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//latex-image[@syntax='PGtikz']&quot;" />
        <xsl:with-param name="date-string" select="'2022-07-10'" />
        <xsl:with-param name="message" select="'a &quot;latex-image&quot; with &quot;@syntax&quot; attribute set to &quot;PGtikz&quot; is deprecated in favor of a plain &quot;latex-image&quot;.  After removing the attribute, the &quot;latex-image&quot; code needs to be placed inside a &quot;tikzpicture&quot; environment. Until you make such changes to your source, we will attempt to honor your request'"/>
    </xsl:call-template>
    <!-- 2022-07-25  warn of impending Wolfram CDF deprecation -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//interactive[@wolfram-cdf]&quot;" />
        <xsl:with-param name="date-string" select="'2022-07-25'" />
        <xsl:with-param name="message" select="'support for Wolfram CDF &quot;interactive&quot; is slated to be removed soon.  Post on the &quot;pretext-support&quot; Google Group if this is an issue for your project'"/>
    </xsl:call-template>
    <!-- 2022-08-07  Wolfram CDF deprecation -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//interactive[@wolfram-cdf]&quot;" />
        <xsl:with-param name="date-string" select="'2022-08-07'" />
        <xsl:with-param name="message" select="'support for Wolfram CDF &quot;interactive&quot; has been removed'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2023-01-07  feedback button deprecation -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/feedback&quot;" />
        <xsl:with-param name="date-string" select="'2023-01-07'" />
        <xsl:with-param name="message" select="'election and configuration of a feedback button via a &quot;docinfo/feedback&quot; element has moved to the publication file with some small changes.  We will try to honor your intent, but results could be unpredictable'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2023-01-10  LaTeX front cover and back cover to publication file -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/covers&quot;" />
        <xsl:with-param name="date-string" select="'2023-01-10'" />
        <xsl:with-param name="message" select="'PDF front and back covers via a &quot;docinfo/covers&quot; element has moved to the publication file with some small changes.  We will try to honor your intent'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2023-01-27  deprecate "datafile" in favor of "dataurl"   -->
    <!-- 2023-02-01  tightened deprecation to uses without @label -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//datafile[not(@label)]&quot;" />
        <xsl:with-param name="date-string" select="'2023-01-27'" />
        <xsl:with-param name="message" select="'the old use of the &quot;datafile&quot; element has been replaced by the functionally-equivalent &quot;dataurl&quot; element.   New uses of &quot;datafile&quot; require a @label attribute.  So you are seeing this warning since your source has a &quot;datafile&quot; without a @label attribute.  We will try to honor your intent, but please make the change at your first convenience, as an automatic conversion might not be desirable in some cases.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2023-08-08  Simplify, and make more reliable, the URL for website entry of copyright page -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//colophon/website[address]&quot;" />
        <xsl:with-param name="date-string" select="'2023-08-08'" />
        <xsl:with-param name="message" select="'a &quot;website&quot; element with &quot;address&quot; and &quot;name&quot; children has changed.  Continue to use the &quot;website&quot; element as before, but replace the &quot;address&quot; and &quot;name&quot; children with a single &quot;url&quot; element, which is more flexible and reliable.  We will try to honor your intent, but you may prefer your own adjustments.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2023-08-10  Kill the half-baked "demonstration" element-->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//demonstration&quot;" />
        <xsl:with-param name="date-string" select="'2023-08-10'" />
        <xsl:with-param name="message" select="'the &quot;demonstration&quot; element has been removed with no natural replacement.  The &quot;interactive&quot; element may be sufficiently flexible to do something similar and will produce a standalone page that might serve a similar purpose.'"/>
    </xsl:call-template>
    <!-- 2023-08-28  Deprecate console/prompt in favor of attributes-->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//console/prompt&quot;" />
        <xsl:with-param name="date-string" select="'2023-08-28'" />
        <xsl:with-param name="message" select="'the &quot;prompt&quot; element of a &quot;console&quot; has been deprecated.  In its place, an &quot;input&quot; can have a @prompt attribute, or you can place a session-wide (not document-wide) @prompt attribute on the &quot;console&quot; element.  Until then, we will try to honor your intent.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2023-10-17  Deprecate docinfo/latex-preamble/package in favor of docinfo/math-package -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/latex-preamble/package&quot;" />
        <xsl:with-param name="date-string" select="'2023-10-17'" />
        <xsl:with-param name="message" select="'the &quot;docinfo/latex-preamble/package&quot; element has been replaced by a &quot;docinfo/math-package&quot; element with &quot;@latex-name&quot; and &quot;@mathjax-name&quot; attributes.  Both attributes are required, but may be different, identical, or empty.  Note too that &quot;latex-preamble&quot; is no longer used for anything.  Until adjusted, we will honor your intent.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2023-10-17  docinfo/latex-preamble element is history -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/latex-preamble&quot;" />
        <xsl:with-param name="date-string" select="'2023-10-17'" />
        <xsl:with-param name="message" select="'the &quot;docinfo/latex-preamble&quot; element no longer has a purpose.  Remove the element and adjust any contained &quot;package&quot; elements.  Then this warning will cease.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2023-02-13   initiate warnings about deprecation/removal of "commentary" string parameter -->
    <!-- This is out of order chronologically, so that it is adjacent to a later follow-up message -->
    <!-- NB: search entire code base on "2023-02-13"  and 2024-02-16                               -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//commentary[not(@component)]&quot;" />
        <xsl:with-param name="date-string" select="'2023-02-13'" />
        <xsl:with-param name="message" select="'the string parameter &quot;commentary&quot; will be removed on, or after, 2024-02-13 (but not yet).  Any &quot;commentary&quot; elements present should be adjusted to have their visibility controlled by version support, specifically by first being placed in a &quot;component&quot;, and then controlled by entries of a publisher file.  Then &quot;commentary&quot; elements can be hidden just with version support.  To be visible you will need to use version support AND continue to use the string parameter.  On, or after, 2024-02-13, this warning will become a fatal error.'"/>
    </xsl:call-template>
    <!-- 2024-02-16: add an additional warning message -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//commentary[not(@component)]&quot;" />
        <xsl:with-param name="date-string" select="'2024-02-16'" />
        <xsl:with-param name="message" select="'a &quot;commentary&quot; element without a @component attribute is now routinely visible in all conversions.  This is unlikely to be what you want since the same effect can be had with no &quot;commentary&quot; element at all.  This message expands on the warning of 2023-02-13, and you might also be getting messages about the deprecation of the string parameter also named &quot;commentary&quot;.   Remove the &quot;commentary&quot; element, or consult the PreTeXt Guide to learn about version support and place the &quot;commentary&quot; element into a component using the attribute of the same name.'"/>
    </xsl:call-template>
    <!-- 2025-03-08: add yet another warning message, but now -->
    <!-- it is serious - "commentary" is deprecated (even if  -->
    <!-- its use with version support will be respected)      -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//commentary&quot;" />
        <xsl:with-param name="date-string" select="'2025-03-08'" />
        <xsl:with-param name="message" select="'the &quot;commentary&quot; element has been deprecated.  Remove the &quot;commentary&quot; element, and consult the PreTeXt Guide to learn about how version support can have the same effect. (If your &quot;commentary&quot; element uses a &quot;component&quot; attribute, we will try to honor your intent.)'"/>
    </xsl:call-template>
    <!-- Any componentless "commentary" at all - fatal error -->
    <!-- NB: $document-root is "too late" here it seems,     -->
    <!-- as this is not the "deprecation-message" template,  -->
    <!-- so we instead hard-code the $original tree          -->
    <xsl:if test="$original//commentary[not(@component)]">
        <xsl:message terminate="yes">PTX:FATAL:    a "commentary" without a @component attribute is a fatal error from 2024-02-16 onward.  Read preceding error messages (2023-02-13, 2024-02-16, 2025-03-08), and make the suggested changes.  Quitting...</xsl:message>
    </xsl:if>
    <!--  -->
    <!-- 2024-07-08  various mis-matches all settled in favor of "qrcode" -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$publication/common/qr-code&quot;" />
        <xsl:with-param name="date-string" select="'2024-07-08'" />
        <xsl:with-param name="message" select="'the publisher file entry &quot;common/qr-code&quot; is obsolete and is being ignored.  Make a cosmetic change to &quot;common/qrcode&quot;.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2024-07-29  "label" element in "latex-image" is deprecated -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//latex-image/label&quot;" />
        <xsl:with-param name="date-string" select="'2024-07-29'" />
        <xsl:with-param name="message" select="'use of a &quot;label&quot; element inside a &quot;latex-image&quot; is deprecated and there is no replacement.  Formulate the appropriate LaTeX code (TikZ) as a replacement.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2024-07-31 (warning added 2024-08-05) metadata, notably idx, banned as child of sidebyside -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//sidebyside/*[&METADATA-FILTER;]&quot;" />
        <xsl:with-param name="date-string" select="'2017-07-31'" />
        <xsl:with-param name="message" select="'metadata elements &quot;&METADATA;&quot; in a sidebyside will be ignored'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2024-10-08 titlepage no longer required for holding author|editor|credit|date in frontmatter -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root/frontmatter/titlepage[author or editor or credit or date or event]&quot;" />
        <xsl:with-param name="date-string" select="'2024-10-08'" />
        <xsl:with-param name="message" select="'elements previously included in a &quot;titlepage&quot; element inside the &quot;frontmatter&quot; (author, editor, credit, date, and event) should now be placed in &quot;frontmatter/bibinfo&quot;.  To ensure a title page is created, put only the empty element &quot;titlepage-items&quot; inside &quot;titlepage&quot;.  Until you move these elements, we will try to honor your intent.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2024-10-08 colophon no longer required for holding copyright|credit|edition|website in frontmatter -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root/frontmatter/colophon[credit or copyright or edition or website]&quot;" />
        <xsl:with-param name="date-string" select="'2024-10-08'" />
        <xsl:with-param name="message" select="'elements previously included in a &quot;colophon&quot; element inside the &quot;frontmatter&quot; (credit, copyright, edition, and website) should now be placed in &quot;frontmatter/bibinfo&quot;. To produce a &quot;colophon&quot;, include only the empty element &quot;colophon-items&quot; inside &quot;colophon&quot; Until you move these elements, we will try to honor your intent.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2024-11-09 docinfo "favicon" now is a publisher file option -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/html/favicon&quot;"/>
        <xsl:with-param name="date-string" select="'2024-11-09'" />
        <xsl:with-param name="message" select="'use of a favicon in HTML output is no longer accomplished with a &quot;favicon&quot; element inside &quot;docinfo&quot;.  Instead use the publication file and put a &quot;@favicon&quot; attribute on the &quot;html&quot; element.  Set its value to &quot;simple&quot; for equivalent behavior.  Until you remove the element in &quot;docinfo&quot;, we will try to honor your intent.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2024-11-19 (warning added 2024-11-19) program/input renamed program/code and input repurposed -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//program/input&quot;" />
        <xsl:with-param name="date-string" select="'2024-11-19'" />
        <xsl:with-param name="message" select="'program/input now should be program/code. An automatic correction will be attempted.'"/>
    </xsl:call-template>
    <!--  -->
    <!--  -->
    <!-- 2025-03-09: mass removal of backward-compatiblity of old-style specifications in "docinfo" -->
    <!--  -->
    <!--  -->
    <!-- From 2019-04-14 -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/analytics&quot;" />
        <xsl:with-param name="date-string" select="'2025-03-09'" />
        <xsl:with-param name="message" select="'site-specific ID for HTML analytics services (Statcounter, Google) provided within &quot;docinfo/analytics&quot; are now options supplied by publishers as command-line options.  See the Publishers Guide for specifics.  Specification in &quot;docinfo&quot; is now being ignored.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- From 2019-04-14 -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/search&quot;" />
        <xsl:with-param name="date-string" select="'2025-03-09'" />
        <xsl:with-param name="message" select="'site-specific ID for HTML search services (Google) is no longer provided within &quot;docinfo/search&quot;.  Please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide. Specification in &quot;docinfo&quot; is now being ignored.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- From 2020-11-22 -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/html/baseurl/@href&quot;" />
        <xsl:with-param name="date-string" select="'2025-03-09'" />
        <xsl:with-param name="message" select="'the &quot;baseurl/@href&quot; element in the &quot;docinfo&quot; has been replaced and is now specified in the publisher file with &quot;html/baseurl/@href&quot;, as documented in the PreTeXt Guide.  Specification in &quot;docinfo&quot; is now being ignored.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- From 2023-01-07 -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/feedback&quot;" />
        <xsl:with-param name="date-string" select="'2025-03-09'" />
        <xsl:with-param name="message" select="'election and configuration of a feedback button via a &quot;docinfo/feedback&quot; element has moved to the publication file with some small changes.  Specification in &quot;docinfo&quot; is now being ignored.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- From 2023-01-10  -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/covers&quot;" />
        <xsl:with-param name="date-string" select="'2025-03-09'" />
        <xsl:with-param name="message" select="'PDF front and back covers via a &quot;docinfo/covers&quot; element has moved to the publication file with some small changes.  Specification in &quot;docinfo&quot; is now being ignored.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2024-07-24 @permid abolished (bulk message added 2025-11-03) -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//@permid&quot;"/>
        <xsl:with-param name="date-string" select="'2024-07-24'" />
        <xsl:with-param name="b-bulk" select="true()" />
        <xsl:with-param name="message" select="'Experiments using the @permid attribute have concluded, and the attribute is now being ignored.  You can safely remove them all and then this message will stop.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2024-11-19 listing no longer has caption, uses title only -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//listing/caption"/>
        <xsl:with-param name="date-string" select="'2024-11-19'" />
        <xsl:with-param name="message" select="'Use of caption in listings is no longer supported. Listings should only have a title. We will try to honor your intent.'"/>
    </xsl:call-template>
  <!--  -->
    <!-- 2025-04-18 -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//matches&quot;"/>
        <xsl:with-param name="date-string" select="'2025-04-18'" />
        <xsl:with-param name="message" select="'the &quot;matches&quot; element inside an &quot;exercise&quot; (or similar) to specify a drag-n-drop problem has been replaced by the &quot;cardsort&quot; element.  This is an entirely cosmetic change.  Until you make the change in your source, we will try to honor your intent.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2025-04-23 -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//matches/match/@order|$document-root//cardsort/match/@order&quot;"/>
        <xsl:with-param name="date-string" select="'2025-04-23'" />
        <xsl:with-param name="message" select="'an &quot;@order&quot; attribute on a &quot;match&quot; is deprecated and should instead be placed on the contained &quot;premise&quot; element(s).  If your cardsort problem is simply a 1-1 correspondence, then we will honor your intent.  If your problem is more complicated (multiple &quot;premise&quot; inside a &quot;match&quot;) results may be variable and unpredictable.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2025-04-25  deprecate "program@datafile" in favor of "program@add-files"   -->
    <xsl:call-template name="deprecation-message">
      <xsl:with-param name="occurrences" select="&quot;$document-root//datafile[@datafile]&quot;" />
      <xsl:with-param name="date-string" select="'2025-04-25'" />
      <xsl:with-param name="message" select="'the program@datafile attribute containing datafile@filename has been deprecated. You should change programs to use the @add-files attribute and use it specify the xml:id of datafiles to make available.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2025-07-19  Docinfo worksheet margins for LaTeX now ignored -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$docinfo/latex-output/worksheet&quot;" />
        <xsl:with-param name="date-string" select="'2025-07-19'" />
        <xsl:with-param name="message" select="'Custom margin specification for worksheets (in both HTML and LaTeX) has moved to the publication file in &quot;/publication/common/worksheet&quot;.  Any margins specified in &quot;docinfo/latex-output/worksheet&quot; will be ignored.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2025-08-27  "label" element in "latex-image" is no longer functional -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//latex-image/label&quot;" />
        <xsl:with-param name="date-string" select="'2025-08-27'" />
        <xsl:with-param name="message" select="'use of a &quot;label&quot; element inside a &quot;latex-image&quot; was deprecated on 2024-07-29.  It is no longer functional, so you must formulate the appropriate LaTeX code (TikZ) as a replacement.  If the &quot;label&quot; element remains, results could be unpredictable.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2025-11-04  @runestone attribute signals obsolete "htmlhack" exercises -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//@runestone&quot;" />
        <xsl:with-param name="date-string" select="'2025-11-04'" />
        <xsl:with-param name="message" select="'the temporary &quot;@runestone&quot; attribute was used to temporarily specify a raw HTML version of a Runestone problem.  That device is now obsolete.  The exercise remains, but its contents have been neutered to form an informational message.  Consider authoring the exercise using supported PreTeXt syntax.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2025-11-14  bare "mdn" construction was only ever temporary/transitional -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="&quot;$document-root//mdn[not(mrow)]&quot;" />
        <xsl:with-param name="date-string" select="'2025-11-14'" />
        <xsl:with-param name="message" select="'an &quot;mdn&quot; element without any &quot;mrow&quot; children (&quot;bare&quot;) was only implemented briefly and was never supported.  Your instance is being ignored and will not be visible in output.  You can switch it to the supported bare &quot;md&quot; element with a &quot;@number&quot; attribute set to &quot;yes&quot;.'"/>
    </xsl:call-template>
    <!--  -->
</xsl:template>

<!-- Miscellaneous -->

<!-- ToDo's are silent unless requested as part of an -->
<!-- author's report, then marginal.  They exist in   -->
<!-- source as prefixed comments, and that prefix     -->
<!-- suffices as part of the output                   -->
<xsl:template match="comment()[translate(substring(normalize-space(string(.)), 1, 4), &UPPERCASE;, &LOWERCASE;) = 'todo']">
    <xsl:call-template name="margin-warning">
        <xsl:with-param name="warning">
            <xsl:call-template name="strip-leading-whitespace">
                <xsl:with-param name="text">
                    <xsl:value-of select="."/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Converter information for header, generic -->
<!-- params are strings to make comment lines in target file    -->
<!-- "copy-of" supresses output-escaping of HTML/XML characters -->
<!-- Parameterize by need/desire for date/commit information    -->
<xsl:template name="converter-blurb">
    <xsl:param name="lead-in" />
    <xsl:param name="lead-out" />
    <xsl:copy-of select="$lead-in" /><xsl:text>********************************************</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*       Generated from PreTeXt source      *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:if test="$b-debug-datedfiles">
    <xsl:copy-of select="$lead-in" /><xsl:text>*       on </xsl:text>  <xsl:value-of select="date:date-time()" />
                                                                      <xsl:text>       *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*   A recent stable commit (2022-07-01):   *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>* 6c761d3dba23af92cba35001c852aac04ae99a5f *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:copy-of select="$lead-in" /><xsl:text>*                                          *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*         https://pretextbook.org          *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*                                          *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>********************************************</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- This version is identical (keep in sync) but *never* has any date  -->
<!-- information.  This was added for the multitude of files in an HTML  -->
<!-- conversion, when we just left one file (index.html) with a date. -->
<xsl:template name="converter-blurb-no-date">
    <xsl:param name="lead-in" />
    <xsl:param name="lead-out" />
    <xsl:copy-of select="$lead-in" /><xsl:text>********************************************</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*       Generated from PreTeXt source      *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*                                          *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*         https://pretextbook.org          *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*                                          *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>********************************************</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- We issue specialized blurbs with appropriate comment lines -->
<xsl:template name="converter-blurb-text">
    <xsl:call-template name="converter-blurb">
        <xsl:with-param name="lead-in"  select="''" />
        <xsl:with-param name="lead-out" select="''" />
    </xsl:call-template>
</xsl:template>

<xsl:template name="converter-blurb-latex">
    <xsl:call-template name="converter-blurb">
        <xsl:with-param name="lead-in"  select="'%'" />
        <xsl:with-param name="lead-out" select="'%'" />
    </xsl:call-template>
</xsl:template>

<xsl:template name="converter-blurb-html">
    <xsl:call-template name="converter-blurb">
        <xsl:with-param name="lead-in">
            <xsl:text disable-output-escaping='yes'>&lt;!--</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="lead-out">
            <xsl:text disable-output-escaping='yes'>--&gt;</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template name="converter-blurb-html-no-date">
    <xsl:call-template name="converter-blurb-no-date">
        <xsl:with-param name="lead-in">
            <xsl:text disable-output-escaping='yes'>&lt;!--</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="lead-out">
            <xsl:text disable-output-escaping='yes'>--&gt;</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template name="converter-blurb-python">
    <xsl:call-template name="converter-blurb">
        <xsl:with-param name="lead-in"  select="'#'" />
        <xsl:with-param name="lead-out" select="'#'" />
    </xsl:call-template>
</xsl:template>

<xsl:template name="converter-blurb-perl">
    <xsl:call-template name="converter-blurb">
        <xsl:with-param name="lead-in"  select="'#'" />
        <xsl:with-param name="lead-out" select="'#'" />
    </xsl:call-template>
</xsl:template>

<!-- WeBWorK's editor is not monospaced, so the right border       -->
<!-- looks ragged.  We effectively rubout the right margin,        -->
<!-- then translate all asterisks to octothorpes.  The left margin -->
<!-- becomes three octothorpes to not be confused with metadata    -->
<!-- This can revert to  -perl  if the editor changes              -->
<xsl:template name="converter-blurb-webwork">
    <xsl:variable name="blurb">
        <xsl:call-template name="converter-blurb">
            <xsl:with-param name="lead-in"  select="'##'" />
            <xsl:with-param name="lead-out" select="'XXX'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="str:replace(str:replace($blurb, '*XXX', ''), '*', '#')" />
</xsl:template>

<!-- ################# -->
<!-- Percent Utilities -->
<!-- ################# -->

<!-- Take as input a node set of attributes -->
<!-- of percentages (with '%' at the end)   -->
<!-- Check that sum is under 100%           -->
<!-- NB: can $nodes be stripped without the  position()  function? -->
<xsl:template name="cap-width-at-one-hundred-percent">
    <xsl:param name="nodeset" />
    <xsl:param name="cap" select="100" />
    <xsl:if test="$nodeset">
        <xsl:if test="substring-before($nodeset[1], '%')&gt;$cap">
            <xsl:message terminate="yes">PTX:FATAL:   percentage attributes sum to over 100%</xsl:message>
        </xsl:if>
        <xsl:call-template name="cap-width-at-one-hundred-percent">
            <xsl:with-param name="nodeset" select="$nodeset[position()&gt;1]" />
            <xsl:with-param name="cap" select="$cap - substring-before($nodeset[1], '%')" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Take a string as input    -->
<!-- Abort if not in the form  -->
<!-- \s*[0-9]*\.?[0-9]*\s*%\s* -->
<!-- Normalize to              -->
<!-- [0-9]*\.?[0-9]*%          -->
<xsl:template name="normalize-percentage">
    <xsl:param name="percentage" />
    <xsl:variable name="stripped-percentage">
        <xsl:value-of select="normalize-space($percentage)" />
    </xsl:variable>
    <xsl:if test="substring($stripped-percentage,string-length($stripped-percentage)) != '%'">
        <xsl:message terminate="yes">PTX:FATAL:   expecting a percentage ending in '%'; got <xsl:value-of select="$stripped-percentage"/></xsl:message>
    </xsl:if>
    <xsl:variable name="percent">
        <xsl:value-of select="normalize-space(substring($stripped-percentage,1,string-length($stripped-percentage) - 1))" />
    </xsl:variable>
    <xsl:if test="number($percent) != $percent">
        <xsl:message terminate="yes">PTX:FATAL:   expecting a numerical value preceding '%'; got <xsl:value-of select="$percent"/></xsl:message>
    </xsl:if>
    <xsl:value-of select="concat($percent,'%')" />
</xsl:template>

<!-- Sometimes this template is useful to see which    -->
<!-- templates are not implemented at all in some new  -->
<!-- (basic) conversion building just on this -common. -->
<!-- Maybe "dead-ending" is preferable (remove the     -->
<!-- apply-templates) and/or maybe a lower priority    -->
<!-- will work better.                                 -->

<!--
<xsl:template match="*" priority="0">
    <xsl:message>[<xsl:value-of select="local-name(.)"/>]</xsl:message>
    <xsl:apply-templates/>
</xsl:template>
-->

</xsl:stylesheet>
