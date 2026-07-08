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


<!-- ##### Division levels ##### -->
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

<!-- ##### Serial / structure / full number ##### -->
<!-- Backmatter references and glossary are unique and un-numbered, -->
<!-- so an empty serial number.  These matches supersede the above. -->
<xsl:template match="backmatter/references" mode="serial-number" />
<xsl:template match="backmatter/glossary" mode="serial-number" />

<!-- Serial number of a block: read the @serial that the assembly -->
<!-- "serial-stamp" pass stamped.  That pass decides, from the    -->
<!-- publication "@distinct" switches, whether a group shares the -->
<!-- overall blocks counter or runs on its own distinct counter.  -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&FIGURE-LIKE;|&OPENPROBLEM-LIKE;|exercise" mode="serial-number">
    <xsl:value-of select="@serial"/>
</xsl:template>

<!-- Proofs may be numbered (for cross-reference knowls) -->
<xsl:template match="&PROOF-LIKE;" mode="serial-number">
    <xsl:number count="&PROOF-LIKE;"/>
</xsl:template>


<!-- Serial Numbers: Equations                                          -->
<!-- The assembly equation-serial pass stamps @serial on every numbered -->
<!-- <mrow>; here we just read it back.  Scope rules and pad/truncate   -->
<!-- behaviour live in the assembly pass.                               -->
<xsl:template match="mrow[@pi:numbered = 'yes']" mode="serial-number">
    <xsl:value-of select="@serial"/>
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
<!-- @serial is stamped on every fn during assembly; here we read it back. -->
<xsl:template match="fn" mode="serial-number">
    <xsl:value-of select="@serial"/>
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
    <xsl:number format="a" count="&FIGURE-LIKE;"/>
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- when inside a sbsgroup, subnumbers range across entire group -->
<xsl:template match="figure/sbsgroup/sidebyside/figure | figure/sbsgroup/sidebyside/table | figure/sbsgroup/sidebyside/listing | figure/sbsgroup/sidebyside/list" mode="serial-number">
    <xsl:text>(</xsl:text>
    <xsl:number format="a" count="&FIGURE-LIKE;" level="any" from="sbsgroup"/>
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

<!-- OPENPROBLEM-LIKE are blocks: their serial number is read from @serial,  -->
<!-- alongside the other block families above.  Their structure number      -->
<!-- follows the figure/project pattern: the open-problem level when they    -->
<!-- run on a distinct counter, otherwise the shared "blocks" level.         -->
<xsl:template match="&OPENPROBLEM-LIKE;" mode="structure-number">
    <xsl:variable name="openproblem-levels">
        <xsl:choose>
            <xsl:when test="$b-number-openproblem-distinct">
                <xsl:value-of select="$numbering-openproblems" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$numbering-blocks" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="block-structure-number">
        <xsl:with-param name="levels" select="$openproblem-levels"/>
    </xsl:call-template>
</xsl:template>

<!-- DISCUSSION-LIKE are appendages; their number is inherited from the parent. -->
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
    <xsl:call-template name="block-structure-number">
        <xsl:with-param name="levels" select="$numbering-blocks"/>
    </xsl:call-template>
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
    <xsl:call-template name="block-structure-number">
        <xsl:with-param name="levels" select="$project-levels"/>
    </xsl:call-template>
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
    <xsl:call-template name="block-structure-number">
        <xsl:with-param name="levels" select="$figure-levels"/>
    </xsl:call-template>
</xsl:template>
<!-- Proofs get structure number from parent theorem -->
<!-- NB: assumes proofs are not detached? Maybe not.      -->
<!-- Definitely a detached proof in a "paragraphs" is bad -->
<xsl:template match="&PROOF-LIKE;" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
</xsl:template>
<!-- Captioned items, arranged in a side-by-side,      -->
<!-- then inside a captioned figure, earn a serial     -->
<!-- number that is a letter.  So their structure      -->
<!-- number comes from the enclosing captioned figure. -->
<!-- The sidebyside may be a child of the figure,      -->
<!-- or wrapped in an sbsgroup.                        -->
<xsl:template match="figure/sidebyside/figure | figure/sidebyside/table | figure/sidebyside/listing | figure/sidebyside/list" mode="structure-number">
    <xsl:apply-templates select="parent::sidebyside/parent::figure" mode="number" />
</xsl:template>
<xsl:template match="figure/sbsgroup/sidebyside/figure | figure/sbsgroup/sidebyside/table | figure/sbsgroup/sidebyside/listing | figure/sbsgroup/sidebyside/list" mode="structure-number">
    <xsl:apply-templates select="parent::sidebyside/parent::sbsgroup/parent::figure" mode="number" />
</xsl:template>

<!-- Structure Numbers: Equations -->
<!-- "mrow" may be numbered, and bare "md" inherit a number from their  -->
<!-- manufactured single "mrow".  So we need a structure number for the -->
<!-- numbered versions of these elements.                               -->
<xsl:template match="mrow|md[@pi:authored-one-line]" mode="structure-number">
    <xsl:call-template name="block-structure-number">
        <xsl:with-param name="levels" select="$numbering-equations"/>
    </xsl:call-template>
</xsl:template>

<!-- Structure Numbers: Inline Exercises -->
<!-- Follows the theorem/figure/etc scheme.  The second alternative   -->
<!-- adds an inline exercise in a division introduction or conclusion -->
<!-- (its parent is not in the inline filter); divisional-container   -->
<!-- exercises are handled by the next template instead.              -->
<xsl:template match="exercise[boolean(&INLINE-EXERCISE-FILTER;)]|exercise[(parent::introduction or parent::conclusion) and not(ancestor::exercises or ancestor::worksheet or ancestor::reading-questions)]" mode="structure-number">
    <xsl:variable name="exercise-levels">
        <xsl:choose>
            <xsl:when test="$b-number-exercise-distinct">
                <xsl:value-of select="$numbering-exercises" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$numbering-blocks" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="block-structure-number">
        <xsl:with-param name="levels" select="$exercise-levels"/>
    </xsl:call-template>
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
    <xsl:call-template name="block-structure-number">
        <xsl:with-param name="levels" select="$numbering-footnotes"/>
    </xsl:call-template>
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
                    <!-- A figure-like inside a sidebyside (or       -->
                    <!-- sbsgroup) inside a figure is subnumbered    -->
                    <!-- with a letter like "(a)", so the serial     -->
                    <!-- number already carries its own delimiter    -->
                    <!-- and no period separator is needed.          -->
                    <xsl:when test="(&FIGURE-FILTER;) and (parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)"/>
                    <xsl:otherwise>
                        <xsl:text>.</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:value-of select="$serial" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ##### Division serial numbers ##### -->
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
</xsl:stylesheet>
