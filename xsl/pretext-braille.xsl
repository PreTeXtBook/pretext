<?xml version='1.0' encoding="UTF-8"?>

<!--********************************************************************
Copyright 2019 Robert A. Beezer

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

<!-- A conversion to "stock" PreTeXt HTML, but optimized as an     -->
<!-- eventual input for the liblouis system to produce Grade 2     -->
<!-- and Nemeth Braille into BRF format with ASCII Braille         -->
<!-- (encoding the 6-dot-patterns of cells with 64 well-behaved    -->
<!-- ASCII characters).  By itself this conversion is not useful.  -->
<!-- The math bits (as LaTeX) need to be converted to Braille by   -->
<!-- MathJax and Speech Rules Engine, saved in a structured file   -->
<!-- and pulled in here as replacements for the authored LaTeX.    -->
<!-- Then we apply liblouisutdml's  file2brl  program.             -->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
    exclude-result-prefixes="pi"
    >

<!-- Trade on HTML markup, numbering, chunking, etc.        -->
<!-- Override as pecularities of liblouis conversion arise  -->
<!-- NB: this will import -assembly and -common stylesheets -->
<xsl:import href="./pretext-html.xsl" />

<!-- This variable controls representations of interactive exercises   -->
<!-- built in  pretext-assembly.xsl.  The imported  pretext-html.xsl   -->
<!-- stylesheet sets it to "dynamic".  But for this stylesheet we want -->
<!-- to utilize the "standard" PreTeXt exercise versions built with    -->
<!-- "static".  See both  pretext-assembly.xsl  and  pretext-html.xsl  -->
<!-- for more discussion. -->
<xsl:variable name="exercise-style" select="'static'"/>

<!-- Output (xsl:output) is controlled by an explicit exsl:document() call -->
<!-- later, for better control over the header of the resulting file       -->

<!-- This variable is exclusive to the (imported) HTML conversion -->
<!-- stylesheet.  It is defined there as false() and here we      -->
<!-- redefine it as true().  This allows for minor variations     -->
<!-- to be made in the -html stylesheet conditionally.            -->
<xsl:variable name="b-braille" select="true()"/>

<!-- On 2021-12-30 we removed the use of the HTML chunking routines to     -->
<!-- create the one monolithic HTML file that liblouis needs as input.     -->
<!-- So we are now basically operating as if this is chunking at level 0.  -->
<!-- The HTML templates are designed to produce "hN" elements for          -->
<!-- accessibility, and these are critically sensitive to the chunk level. -->
<!-- So we need to explicitly override the default value.  The (one) place -->
<!-- where this is necessary is teh modal "hN" template in the             -->
<!-- pretext-html.xsl stylesheet.  Remove this variable override and       -->
<!-- certain blocks (definition, theorem, example,...) will have their     -->
<!-- hN change to one less due to a change in the variable                 -->
<!-- $chunk-level-zero-adjustment.                                         -->
<!--                                                                       -->
<!-- The braille conversion does not rely on hN levels at this depth,      -->
<!-- so this all may be moot, and possibly not even correct or best.       -->
<!-- The only motivation right now is minimal (zero) impact due to         -->
<!-- abandoning the chunking templates.                                    -->
<xsl:variable name="chunk-level" select="0"/>

<!-- All the ways we can have a division at the subsubsection level.     -->
<!-- This influences how headings of divisions are indicated (centered,  -->
<!-- cell5, cell7) when subdivisions go this deep.  Or not.              -->
<xsl:variable name="b-has-subsubsection" select="boolean($document-root//subsubsection |
                                                         $document-root//subsection/exercises |
                                                         $document-root//subsection/reading-questions |
                                                         $document-root//subsection/worksheet |
                                                         $document-root//subsection/solutions |
                                                         $document-root//subsection/references |
                                                         $document-root//subsection/glossary
                                                        )"/>

<!-- Necessary to get pre-constructed Nemeth braille for math elements. -->
<xsl:param name="mathfile" select="''"/>
<xsl:variable name="math-repr"  select="document($mathfile)/pi:math-representations"/>

<!-- This stylesheet is (minimally) parameterized by the "emboss" or     -->
<!-- "electronic" physical formats eventually generated by liblouis.     -->
<!-- Calling routines (Python scripts) should always set this parameter. -->
<xsl:param name="page-format" select="''"/>

<!-- BANA Nemeth Guidance: "All other text, including -->
<!-- punctuation that is logically associated with    -->
<!-- surrounding sentences, should be done in UEB."   -->
<xsl:variable name="math.punctuation.include" select="'none'"/>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- These two templates are similar to those of  pretext-html.xsl. -->
<!-- Primarily the production of cross-reference ("xref") knowls    -->
<!-- has been removed.  The pretext-html.xsl template will have     -->
<!-- done the assembly phase, adjusting $root to point to the       -->
<!-- in-memory enhanced source, along with $document-root.          -->
<xsl:template match="/">
    <xsl:apply-templates select="$root"/>
</xsl:template>

<xsl:template match="/pretext">
    <!-- No point in proceeding without the file of braille   -->
    <!-- representations, and right at the start, so a banner -->
    <!-- warning for those who think this stylesheet alone    -->
    <!-- might be good enough                                 -->
    <xsl:if test="$mathfile = ''">
        <xsl:call-template name="banner-warning">
            <xsl:with-param name="warning">
                <xsl:text>Conversion to braille requires using the pretext/pretext script to produce&#xa;a file of the Nemeth braille versions of mathematics (it might be relatively empty).&#xa;And then you might as well use the script itself to manage the whole process.&#xa;Quitting...</xsl:text>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:message terminate="yes"/>
    </xsl:if>
    <!-- the usual warnings, as part of a primary conversion -->
    <xsl:apply-templates select="$original" mode="generic-warnings"/>
    <xsl:apply-templates select="$original" mode="deprecation-warnings"/>
    <!-- One monolithic HTML page, as input to liblouis' file2brl   -->
    <!-- executable.  The HTML templates are engineered to be       -->
    <!-- chunked into multiple pages, however a "chunk level" of    -->
    <!-- zero corresponds to one big page, starting at the document -->
    <!-- root.  So we apply templates to the document root, wrapped -->
    <!-- as an HTML file/page. We hard-code the name of the output  -->
    <!-- file as "liblouis-precursor.html" and ensure here that we  -->
    <!-- get an XML declaration, indentation, and encoding.         -->
    <!-- file2brl seems to be sensitive to the form of the header   -->
    <!-- of the output here.                                        -->
    <!-- N.B. when we abandoned the chunking routines (they were    -->
    <!-- not necessary) some headings elements changed (e.g.        -->
    <!-- h3 -> h2).  Always smaller by one, and maybe not           -->
    <!-- universal. Passing in level 2 at the start seems to not    -->
    <!-- have an effect (nor 1, nor 3) We don't seem to rely on     -->
    <!-- them (using class names instead) and BRF output seemed     -->
    <!-- unchanged.                                                 -->
    <!--  -->
    <exsl:document href="liblouis-precursor.xml" method="xml" version="1.0" indent="yes" encoding="UTF-8">
        <html>
            <head>
            </head>
            <body>
                <xsl:apply-templates select="$document-root">
                    <xsl:with-param name="heading-level" select="2"/>
                </xsl:apply-templates>
            </body>
        </html>
    </exsl:document>
    <!--  -->
</xsl:template>

<!-- The "frontmatter" and "backmatter" of the HTML version are possibly -->
<!-- summary pages and need to step the heading level (h1-h6) for screen -->
<!-- readers and accessibility.  But here we want to style items at      -->
<!-- similar levels to be at the same HTML level so we can use liblouis' -->
<!-- device for this.  So, for example, we want  book/preface/chapter    -->
<!-- to be h2, not h3.  Solution: we don't need the frontmatter and      -->
<!-- backmatter distinctions in Braille, so we simply recurse with a     -->
<!-- pass-through of the heading level.  This is a very tiny subset of   -->
<!-- the HTML template matching &STRUCTURAL;.                            -->
<xsl:template match="frontmatter|backmatter">
    <xsl:param name="heading-level"/>

    <xsl:apply-templates>
        <xsl:with-param name="heading-level" select="$heading-level"/>
    </xsl:apply-templates>
</xsl:template>


<!-- ########## -->
<!-- Title Page -->
<!-- ########## -->

<!-- This has the same @match as in the HTML conversion,        -->
<!-- so keep them in-sync.  Here we make adjustments:           -->
<!--   * One big h1 for liblouis styling (centered, etc)        -->
<!--   * No extra HTML, just line breaks                        -->
<!--   * exchange the subtitle semicolon/space for a line break -->
<!--   * dropped credit, and included edition                   -->
<!-- See [BANA-2016, 1.8.1]                                     -->
<xsl:template match="titlepage">
    <xsl:variable name="b-has-subtitle" select="parent::frontmatter/parent::*/subtitle"/>
    <div class="fullpage">
        <xsl:apply-templates select="parent::frontmatter/parent::*" mode="title-full" />
        <br/>
        <xsl:if test="$b-has-subtitle">
            <xsl:apply-templates select="parent::frontmatter/parent::*" mode="subtitle" />
            <br/>
        </xsl:if>
        <!-- We list authors and editors in document order -->
        <xsl:apply-templates select="author|editor" mode="full-info"/>
        <!-- A credit is subsidiary, so follows -->
        <!-- <xsl:apply-templates select="credit" /> -->
        <xsl:if test="colophon/edition or date">
            <br/> <!-- a small gap -->
            <xsl:if test="colophon/edition">
                <xsl:apply-templates select="colophon/edition"/>
                <br/>
            </xsl:if>
            <xsl:if test="date">
                <xsl:apply-templates select="date"/>
                <br/>
            </xsl:if>
        </xsl:if>
    </div>
    <!-- A marker for generating the Table of Contents,      -->
    <!-- content of the element is the title of the new page -->
    <div data-braille="tableofcontents">
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'toc'" />
            <xsl:with-param name="lang" select="$document-language"/>
        </xsl:call-template>
    </div>
</xsl:template>

<xsl:template match="titlepage/author|titlepage/editor" mode="full-info">
    <xsl:apply-templates select="personname"/>
    <xsl:if test="self::editor">
        <xsl:text> (Editor)</xsl:text>
    </xsl:if>
    <br/>
    <xsl:if test="department">
        <xsl:apply-templates select="department"/>
        <br/>
    </xsl:if>
    <xsl:if test="institution">
        <xsl:apply-templates select="institution"/>
        <br/>
    </xsl:if>
</xsl:template>


<!-- ######### -->
<!-- Divisions -->
<!-- ######### -->

<!-- We override the "section-heading" template to place classes  -->
<!--                                                              -->
<!--     fullpage centerpage center cell5 cell7                   -->
<!--                                                              -->
<!-- onto the heading so liblouis can style it properly           -->
<!-- This is greatly simplified, "hX" elements just become "div", -->
<!-- which is all we need for the  liblouis  semantic action file -->

<xsl:template match="*" mode="section-heading">
    <div>
        <xsl:attribute name="class">
            <xsl:apply-templates select="." mode="division-class"/>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="heading-content" />
    </div>
</xsl:template>

<!-- Verbatim from -html conversion for book, article, so read -->
<!-- about it there.  Slideshow doesn't get a heading either.  -->
<xsl:template match="book|article|slideshow" mode="section-heading" />

<!-- Heading Content (for divisions) -->

<!-- This is an override of the template in the HTML conversion. -->
<!-- We drop the names of divisions (which are usually squelced  -->
<!-- by CSS), except we keep "Chapter" since the chapter-busting -->
<!-- Python depends on it.  Otherwise, number and title, as      -->
<!-- recommended by Cantino and Maneki.                          -->
<xsl:template match="*" mode="heading-content">
    <!-- retain "Chapter" as a necessary component -->
    <!-- of the regular-expressions used in the    -->
    <!-- chapter-busting Python routine            -->
    <!-- Note: to test without the "Chapter"       -->
    <!-- string in the heading, replace            -->
    <!--     "self::chapter" -> "false()"          -->
    <!-- or "comment-out" the whole "if" stanza    -->
    <xsl:if test="self::chapter">
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
        </span>
        <xsl:text> </xsl:text>
    </xsl:if>
    <span class="codenumber">
        <xsl:apply-templates select="." mode="number" />
    </span>
    <xsl:text> </xsl:text>
    <span class="title">
        <xsl:apply-templates select="." mode="title-full" />
    </span>
</xsl:template>

<!-- Unnumbered, chapter-level headings, just title text -->
<xsl:template match="preface|acknowledgement|biography|foreword|dedication|solutions[parent::backmatter]|references[parent::backmatter]|index|colophon" mode="heading-content">
    <span class="title">
        <xsl:apply-templates select="." mode="title-full" />
    </span>
</xsl:template>

<!-- This is an override of the template in the HTML conversion, -->
<!-- but now for specilaized divisions. We drop the names of     -->
<!-- divisions (which are usually squelced by CSS), especially   -->
<!-- since this is often a duplicate of the (default) title we   -->
<!-- provide.  Also, links to HTML worksheets are killed (and a  -->
<!-- heading is a strange place to have them anyway?).           -->
<xsl:template match="exercises|solutions|glossary|references|worksheet|reading-questions" mode="heading-content">
    <!-- be selective about displaying numbers at birth-->
    <xsl:variable name="is-numbered">
        <xsl:apply-templates select="." mode="is-specialized-own-number"/>
    </xsl:variable>
    <xsl:if test="($is-numbered = 'true')">
        <span class="codenumber">
            <xsl:apply-templates select="." mode="number"/>
        </span>
        <xsl:text> </xsl:text>
    </xsl:if>
    <span class="title">
        <xsl:apply-templates select="." mode="title-full" />
    </span>
</xsl:template>

<!-- Heading Classes -->

<!-- Default is indeterminate (search while debugging) -->
<xsl:template match="*" mode="division-class">
    <xsl:text>none</xsl:text>
</xsl:template>

<!-- Part is more like a title page -->
<xsl:template match="part" mode="division-class">
    <xsl:call-template name="division-class-part-like"/>
</xsl:template>

<!-- Chapters headings are always centered -->
<xsl:template match="chapter|appendix" mode="division-class">
    <xsl:call-template name="division-class-chapter-like"/>
</xsl:template>

<!-- Chapter-level headings are always centered -->
<xsl:template match="preface|acknowledgement|biography|foreword|dedication|backmatter/solutions|backmatter/references|index|colophon" mode="division-class">
    <xsl:call-template name="division-class-chapter-like"/>
</xsl:template>

<xsl:template match="section" mode="division-class">
    <xsl:call-template name="division-class-section-like"/>
</xsl:template>

<xsl:template match="subsection" mode="division-class">
    <xsl:call-template name="division-class-subsection-like"/>
</xsl:template>

<!-- terminal always, according to schema -->
<xsl:template match="subsubsection" mode="division-class">
    <xsl:call-template name="division-class-subsubsection-like"/>
</xsl:template>

<!-- The "look" of a specialized division (not in the backmatter)      -->
<!-- depends on its depth, which we determine by a look at its parent. -->
<xsl:template match="exercises|reading-questions|worksheet|references|solutions|glossary" mode="division-class">
    <xsl:choose>
        <xsl:when test="parent::chapter|parent::appendix">
            <xsl:call-template name="division-class-section-like"/>
        </xsl:when>
        <xsl:when test="parent::section">
            <xsl:call-template name="division-class-subsection-like"/>
        </xsl:when>
        <xsl:when test="parent::subsection">
            <xsl:call-template name="division-class-subsubsection-like"/>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- A "section" in a slideshow is a major division,      -->
<!-- holding many slides, so much like a "part" of a book -->
<xsl:template match="slideshow/section" mode="division-class">
    <xsl:call-template name="division-class-part-like"/>
</xsl:template>

<!-- New centered pages for each new slide -->
<xsl:template match="slide" mode="division-class">
    <xsl:call-template name="division-class-chapter-like"/>
</xsl:template>


<!-- Heading Classes Named Templates-->

<!-- These are named templates, hence context-free, intentionally.        -->
<!-- These templated provide the five classes present in teh semantic     -->
<!-- file to control the look of headings at various depths.  They do     -->
<!-- rely on the global boolean  $b-has-subsubsection  variable.          -->
<!--                                                                      -->
<!-- The "*-like" names make the most sense in the case of a book with    -->
<!-- subsubsections, where the hierachy goes right down the line.         -->
<!-- Absent subsubsections, centering is abandoned sooner for a           -->
<!-- cell5/cell7  look below a chapter.                                   -->
<!--                                                                      -->
<!-- The purpose of isolating these to allow for their use with           -->
<!-- specialized divisions that occur at many different depths, so a      -->
<!-- parent can be examined as a clue to depth, and a choice can be made. -->

<xsl:template name="division-class-part-like">
    <xsl:text>fullpage</xsl:text>
</xsl:template>

<xsl:template name="division-class-chapter-like">
    <xsl:text>centerpage</xsl:text>
</xsl:template>

<xsl:template name="division-class-section-like">
    <xsl:choose>
        <xsl:when test="$b-has-subsubsection">
            <xsl:text>center</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>cell5</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="division-class-subsection-like">
    <xsl:choose>
        <xsl:when test="$b-has-subsubsection">
            <xsl:text>cell5</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>cell7</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="division-class-subsubsection-like">
    <xsl:text>cell7</xsl:text>
</xsl:template>

<!-- Heading Utilities -->

<!-- We override two templates of the generic HTML conversion.   -->
<!-- There, spans for styling cause liblouis to insert a space,  -->
<!-- which is definitely not desirable.  This primarily affects  -->
<!-- headings and titles of blocks, in addition to the numbers   -->
<!-- for exercises.  E.g. "5."  These are "span-less" versions.  -->

<xsl:template name="space-styled">
    <xsl:text> </xsl:text>
</xsl:template>

<xsl:template name="period-styled">
    <xsl:text>.</xsl:text>
</xsl:template>


<!-- ################### -->
<!-- Environments/Blocks -->
<!-- ################### -->

<!-- Born-hidden behavior is generally configurable,  -->
<!-- but we do not want any automatic, or configured, -->
<!-- knowlization to take place.  Ever.  Never.       -->

<!-- Everything configurable by author, 2020-01-02         -->
<!-- Roughly in the order of old  html.knowl.*  switches   -->
<!-- Similar HTML templates return string for boolean test -->
<xsl:template match="&THEOREM-LIKE;|&PROOF-LIKE;|&DEFINITION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|task|&FIGURE-LIKE;|&REMARK-LIKE;|&GOAL-LIKE;|exercise" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- A hook in the HTML conversion allows for the addition of a @data-braille attribute to the "body-element".  Then liblouis can select on these values to apply the "boxline" style which delimits the blocks.  Here we define these values.  The stub in the HTML conversion does nothing (empty text) and so is a signal to not employ this attribute at all.  So a non-empty definition here also activates the attribute's existence. -->

<xsl:template match="&REMARK-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>remark-like</xsl:text>
</xsl:template>

<xsl:template match="&COMPUTATION-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>computation-like</xsl:text>
</xsl:template>

<xsl:template match="&DEFINITION-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>definition-like</xsl:text>
</xsl:template>

<xsl:template match="&ASIDE-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>aside-like</xsl:text>
</xsl:template>

<xsl:template match="&FIGURE-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>figure-like</xsl:text>
</xsl:template>

<xsl:template match="assemblage" mode="data-braille-attribute-value">
    <xsl:text>assemblage-like</xsl:text>
</xsl:template>

<xsl:template match="&GOAL-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>goal-like</xsl:text>
</xsl:template>

<xsl:template match="&EXAMPLE-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>example-like</xsl:text>
</xsl:template>

<xsl:template match="&PROJECT-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>project-like</xsl:text>
</xsl:template>

<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>theorem-like</xsl:text>
</xsl:template>

<!-- NB: could edit to "proof-like" and adjust styles -->
<xsl:template match="&PROOF-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>proof</xsl:text>
</xsl:template>

<!-- Absent an implementation above, empty text signals  -->
<!-- that the @data-braille attribute is not desired.    -->
<xsl:template match="*" mode="data-braille-attribute-value"/>

<!-- The HTML conversion has a "block-data-braille-attribute" -->
<!-- hook with a no-op stub template.  Here we activate the   -->
<!-- attribute iff a non-empty value is defined above.  Why   -->
<!-- do this?  Because liblouis can only match attributes     -->
<!-- with one value, not space-separated lists like many of   -->
<!-- our @class attributes.                                   -->
<xsl:template match="*" mode="block-data-braille-attribute">
    <xsl:variable name="attr-value">
        <xsl:apply-templates select="." mode="data-braille-attribute-value"/>
    </xsl:variable>
    <xsl:if test="not($attr-value = '')">
        <xsl:attribute name="data-braille">
            <xsl:value-of select="$attr-value"/>
        </xsl:attribute>
    </xsl:if>
</xsl:template>

<!-- ################# -->
<!-- WeBWorK Exercises -->
<!-- ################# -->

<!-- The "webwork-reps" element contains a "static" representation in    -->
<!-- PreTeXt syntax, which we process as if it was a sttic exercise      -->
<!-- authored as such.  We do need to know if the publisher wants        -->
<!-- hints, answers, or solutions available where the exercises is born. -->
<!-- NB: this is a simplified version of the stock HTML conversion which -->
<!-- avoids having things like an "Activate" button, and similar         -->
<!-- interactive features.                                               -->
<xsl:template match="webwork-reps">
    <xsl:param name="b-original" select="true()"/>
    <!-- TODO: simplify these variables, much like for LaTeX -->
    <xsl:variable name="b-has-hint" select="(ancestor::*[&PROJECT-FILTER;] and $b-has-project-hint) or
                                            (ancestor::exercises and $b-has-divisional-hint) or
                                            (ancestor::reading-questions and $b-has-reading-hint) or
                                            (ancestor::worksheet and $b-has-worksheet-hint) or
                                            (not(ancestor::*[&PROJECT-FILTER;] or ancestor::exercises or ancestor::reading-questions or ancestor::worksheet) and $b-has-inline-hint)" />
    <xsl:variable name="b-has-answer" select="(ancestor::*[&PROJECT-FILTER;] and $b-has-project-answer) or
                                              (ancestor::exercises and $b-has-divisional-answer) or
                                              (ancestor::reading-questions and $b-has-reading-answer) or
                                              (ancestor::worksheet and $b-has-worksheet-answer) or
                                              (not(ancestor::*[&PROJECT-FILTER;] or ancestor::exercises or ancestor::reading-questions or ancestor::worksheet) and $b-has-inline-answer)" />
    <xsl:variable name="b-has-solution" select="(ancestor::*[&PROJECT-FILTER;] and $b-has-project-solution) or
                                                (ancestor::exercises and $b-has-divisional-solution) or
                                                (ancestor::reading-questions and $b-has-reading-solution) or
                                                (ancestor::worksheet and $b-has-worksheet-solution) or
                                                (not(ancestor::*[&PROJECT-FILTER;] or ancestor::exercises or ancestor::reading-questions or ancestor::worksheet) and $b-has-inline-solution)"/>
    <xsl:apply-templates select="static" mode="exercise-components">
        <xsl:with-param name="b-original"      select="$b-original"/>
        <xsl:with-param name="b-has-statement" select="true()"/>
        <xsl:with-param name="b-has-hint"      select="$b-has-hint"/>
        <xsl:with-param name="b-has-answer"    select="$b-has-answer"/>
        <xsl:with-param name="b-has-solution"  select="$b-has-solution"/>
    </xsl:apply-templates>
</xsl:template>


<!-- ################ -->
<!-- Subsidiary Items -->
<!-- ################ -->

<!-- These tend to "hang" off other structures and/or are routinely -->
<!-- rendered as knowls.  So we turn off automatic knowlization     -->
<xsl:template match="&SOLUTION-LIKE;" mode="is-hidden">
    <xsl:text>no</xsl:text>
</xsl:template>

<!-- We extend their headings with an additional colon. -->
<!-- These render then like "Hint:" or "Hint 6:"        -->
<xsl:template match="&SOLUTION-LIKE;" mode="heading-simple">
    <xsl:apply-imports/>
    <xsl:text>:</xsl:text>
</xsl:template>

<!-- ########## -->
<!-- Sage Cells -->
<!-- ########## -->

<!-- Implementing the abstract templates gives us a lot of       -->
<!-- freedom.  We wrap in an                                     -->
<!--    article/@data-braille="sage"                             -->
<!-- with a                                                      -->
<!--    h6/@class="heading"/span/@class="type"                   -->
<!-- to get  liblouis  styling as a box and to make a heading.   -->
<!--                                                             -->
<!-- div/@data-braille="<table-filename>" is a  liblouis  device -->
<!-- to switch the translation table, and is the best we can     -->
<!-- do to make computer braille                                 -->

<xsl:template match="sage" mode="sage-active-markup">
    <xsl:param name="block-type"/>
    <xsl:param name="language-attribute" />
    <xsl:param name="in" />
    <xsl:param name="out" />
    <xsl:param name="b-original"/>

    <article data-braille="sage">
        <h6 class="heading">
            <span class="type">Sage</span>
        </h6>

        <!-- code marker is literary, not computer braille -->
        <p>Input:</p>
        <div sage-code="en-us-comp6.ctb">
            <xsl:choose>
                <xsl:when test="$in = ''">
                    <!-- defensive, prevents HTML processing  -->
                    <!-- writing non-XML for an empty element -->
                    <xsl:text>&#xa0;&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$in"/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
        <xsl:if test="not($out = '')">
            <!-- code marker is literary, not computer braille -->
            <p>Output:</p>
            <div sage-code="en-us-comp6.ctb">
                <xsl:value-of select="$out" />
            </div>
        </xsl:if>
    </article>
</xsl:template>

<xsl:template name="sage-display-markup">
    <xsl:param name="block-type"/>
    <xsl:param name="in" />

    <article data-braille="sage">
        <h6 class="heading">
            <span class="type">Sage</span>
        </h6>
        <!-- code marker is literary, not computer braille -->
        <p>Input:</p>
        <div sage-code="en-us-comp6.ctb">
            <xsl:choose>
                <xsl:when test="$in = ''">
                    <!-- defensive, prevents HTML processing  -->
                    <!-- writing non-XML for an empty element -->
                    <xsl:text>&#xa0;&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$in"/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </article>
</xsl:template>

<!-- ################# -->
<!-- Verbatim Material -->
<!-- ################# -->

<!-- cd is for use in paragraphs, inline -->
<!-- Unstructured is pure text           -->
<xsl:template match="cd">
    <pre class="code-block">
        <xsl:value-of select="." />
    </pre>
</xsl:template>

<!-- cline template is in xsl/pretext-common.xsl -->
<xsl:template match="cd[cline]">
    <pre class="code-block">
        <xsl:call-template name="break-lines-html">
            <xsl:with-param name="text">
                <xsl:apply-templates select="cline"/>
            </xsl:with-param>
        </xsl:call-template>
    </pre>
</xsl:template>

<xsl:template match="pre">
    <pre class="code-block">
        <xsl:call-template name="break-lines-html">
            <xsl:with-param name="text">
                <xsl:apply-templates select="." mode="interior"/>
            </xsl:with-param>
        </xsl:call-template>
    </pre>
</xsl:template>

<!-- Utility to insert explicit HTML (only) line breaks       -->
<!-- Recursively strip a leading line from pure text chunk    -->
<!-- based on character, and add HTML newlines ("br") to each -->
<!-- so liblouis will break lines in "computerCoded" format.  -->
<!-- It seems that text must arrive with trailing newlines,   -->
<!-- so recursion behaves.                                    -->
<xsl:template name="break-lines-html">
    <xsl:param name="text"/>

    <xsl:choose>
        <xsl:when test="$text = ''"/>
        <xsl:otherwise>
            <xsl:value-of select="substring-before($text, '&#xa;')"/>
            <br/>
            <xsl:call-template name="break-lines-html">
                <xsl:with-param name="text" select="substring-after($text, '&#xa;')"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ###################### -->
<!-- Paragraph-Level Markup -->
<!-- ###################### -->

<!-- Certain PreTeXt elements create characters beyond the -->
<!-- "usual" Unicode range of U+0000-U+00FF.  We defer the -->
<!-- translation to the "pretext-symbol.dis" file which    -->
<!-- liblouis  will consult for characters/code-points it  -->
<!-- does not recognize.  We make notes here, but the file -->
<!-- should be consulted for accurate information.         -->

<!-- PTX: ldblbracket, rdblbracket, dblbrackets     -->
<!-- Unicode:                                       -->
<!-- MATHEMATICAL LEFT WHITE SQUARE BRACKET, x27e6  -->
<!-- MATHEMATICAL RIGHT WHITE SQUARE BRACKET, x27e7 -->
<!-- Translation:  [[, ]]                           -->


<!-- ########### -->
<!-- Mathematics -->
<!-- ########### -->

<!-- Nemeth indicators as pairs of braille Unicode cells -->
<xsl:variable name="nemeth-open" select="'&#x2838;&#x2829;'"/>
<xsl:variable name="nemeth-close" select="'&#x2838;&#x2831;'"/>

<!-- Nemeth braille representation of mathematics are constructed  -->
<!-- previously and collected in the $math-repr variable/tree.     -->
<!-- Here we do replacement and Nemeth indicators.  liblouis       -->
<!-- passes through braille characters from the Unicode U+2800     -->
<!-- block as the corresponding (a 1-1 map) BRF ASCII characters.  -->
<!-- Wrap using classes to signal liblouis.                        -->

<!-- First, authored as inline, but maybe becomes multiline. -->
<xsl:template match="m|me|men|md|mdn">
    <!-- We connect source location with representations via id -->
    <!-- NB: math-representation file writes with "visible-id"  -->
    <xsl:variable name="id">
        <xsl:apply-templates select="." mode="visible-id"/>
    </xsl:variable>
    <!-- Unicode braille cells from Speech Rule Engine (SRE) -->
    <xsl:variable name="raw-braille" select="$math-repr/pi:math[@id = $id]/div[@class = 'braille']"/>
    <!-- SRE uses U+2800 for all "spaces".  For single-line math bits,  -->
    <!-- sometimes we want these to be breakable spaces, sometimes not. -->
    <!-- For multiline braille (2D layout, no matter how authored) we   -->
    <!-- need to be more careful.                                       -->
    <!-- Note: we once called this "$breakable-braille"                 -->
    <!--                                                                -->
    <!-- Read code comments near the definition of the modal            -->
    <!-- "sanitize-nemeth-braille" template for full details.           -->
    <!-- Briefly, U+2800 remain only for indentation of 2D layout       -->
    <!-- beyond line 1, and other spaces are "regular" spaces, U+0020.  -->
    <xsl:variable name="braille">
        <xsl:call-template name="sanitize-nemeth-braille">
            <xsl:with-param name="text" select="$raw-braille"/>
        </xsl:call-template>
    </xsl:variable>
    <!-- Length is critical for various decisions about formatting output -->
    <xsl:variable name="braille-length" select="string-length($braille)"/>
    <!-- For single-line braille expressions up to about the length of  -->
    <!-- line, we find it advantageous to employ a non-breaking version.   -->
    <!-- The means making a "regular" space into a non-breaking one,  -->
    <!-- which here is U+2800 (not U+00A0). -->
    <xsl:variable name="no-break-braille" select="str:replace($braille, '&#x0020;', '&#xa0;')"/>
    <!-- We investigate actual source for very simple math   -->
    <!-- such as one-letter variable names as Latin letters  -->
    <!-- or positive integers, so we process the orginal     -->
    <!-- content outside of a MathJax/SRE translation (which -->
    <!-- could have "xref", etc)                             -->
    <xsl:variable name="content">
        <xsl:apply-templates select="node()"/>
    </xsl:variable>
    <xsl:variable name="original-content" select="normalize-space($content)"/>
    <!-- An "m" could have a fraction that is complicated enough that SRE -->
    <!-- will produce a visual layout spread over multiple lines.  So all -->
    <!-- flavors of math could occupy several lines in braille output     -->
    <xsl:variable name="b-multiline" select="contains($braille, '&#xa;')"/>
    <!-- An author's intent is different than what gets realized -->
    <xsl:variable name="b-inline-math" select="boolean(self::m)"/>
    <xsl:variable name="b-display-math" select="not($b-inline-math)"/>
    <!-- We need to know how much width we have available.  This  -->
    <!-- should be a publisher setting, but right now we are just -->
    <!-- hard-coding 40 characters, which is the most common.     -->
    <xsl:variable name="page-width" select="40"/>
    <!-- List items are indented.  Math (of any kind) goes in     -->
    <!-- paragraphs, which are constituents of paragraphs.  So    -->
    <!-- $page-width is not the whole story and we need to reduce -->
    <!-- the space available on a line.  There may well be other  -->
    <!-- such situations?                                         -->
    <!--                                                          -->
    <!-- A chunk of math is usually followed by whitespace, with  -->
    <!-- the exception of clause-ending punctuation.  For         -->
    <!-- example, a period may immediately follow the             -->
    <!-- closing-Nemeth indicator.  To avoid a line-break via     -->
    <!-- a hyphen we reduce the available width by 1 (thus,       -->
    <!-- two "- 1" below).  This means some other situations have -->
    <!-- less space than is really possible.  One experiment      -->
    <!-- suggests the number of times this is needed about        -->
    <!-- equals the number of times it is harmful. We could       -->
    <!-- condition on the occurence of clause-ending              -->
    <!-- punctuation and only subtract when necessary.            -->
    <xsl:variable name="line-width">
        <xsl:choose>
            <!-- inside a list item, could be a few levels up -->
            <xsl:when test="ancestor::li">
                <xsl:variable name="nested" select="count(ancestor::ol|ancestor::ul|ancestor::dl)"/>
                <xsl:value-of select="$page-width - (2 * $nested) - 1"/>
            </xsl:when>
            <!-- no restrictions, we have the entire width -->
            <xsl:otherwise>
                <xsl:value-of select="$page-width - 1"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Authored as "m" first -->
    <xsl:if test="$b-inline-math">
        <!-- Ready: various situations, more specific first -->
        <xsl:choose>
            <!-- Multi-line first, SRE has done layout on inline math. -->
            <!-- Mimic display math as in next template.               -->
            <xsl:when test="$b-multiline">
                <div data-braille="nemeth-display">
                    <span data-braille="nemeth-oneline">
                        <xsl:value-of select="$nemeth-open"/>
                    </span>
                    <br/>
                    <xsl:call-template name="wrap-multiline-math">
                        <xsl:with-param name="braille" select="$braille"/>
                    </xsl:call-template>
                    <span data-braille="nemeth-oneline">
                        <xsl:value-of select="$nemeth-close"/>
                    </span>
                    <br/>
                </div>
            </xsl:when>
            <!-- Positive integers inside of "m" should not be wrapped at all. -->
            <!-- The translate() ends up empty in exactly this case.           -->
            <xsl:when test="$b-inline-math and (translate($original-content, &DIGIT; ,'') = '')">
                <xsl:value-of select="$original-content"/>
            </xsl:when>
            <!-- inline math with one Latin letter  -->
            <!-- $braille is ignored.  c'est la vie -->
            <xsl:when test="$b-inline-math and (string-length($original-content) = 1) and
                            contains(&ALPHABET;, $original-content)">
                <!-- class is signal to liblouis styling rules -->
                <i class="one-letter">
                    <xsl:value-of select="$original-content"/>
                </i>
            </xsl:when>

            <!-- Fits on one line, including 6 characters of Nemeth -->
            <!-- indicators. Fix all spaces to be unbreakable,      -->
            <!-- Michael Cantino says a wholesale wrap to the next  -->
            <!-- line is better than any kind of line break within. -->
            <xsl:when test="$braille-length &lt; ($line-width - 5)">
                <!-- Bind open/close indicators and all characters via a non-breaking    -->
                <!-- space, so liblouis will never break this shorter inline expression. -->
                <!-- It will be fine on current line, or it will push/wrap to the next   -->
                <!-- line, where it will always fit.                                     -->
                <span data-braille="nemeth-inline">
                    <xsl:value-of select="$nemeth-open"/>
                    <xsl:text>&#xa0;</xsl:text>
                    <xsl:value-of select="$no-break-braille"/>
                    <xsl:text>&#xa0;</xsl:text>
                    <xsl:value-of select="$nemeth-close"/>
                </span>
            </xsl:when>
            <!-- In a grey zone where Nemeth indicators are just too much -->
            <!-- Open on current line, braille on its own line, close on  -->
            <!-- the next line and immediately pick up with remainder.    -->
            <xsl:when test="(($line-width - 6) &lt; $braille-length) and ($braille-length &lt; ($line-width + 1))">
                <span data-braille="nemeth-inline">
                    <xsl:value-of select="$nemeth-open"/>
                </span>
                <br/>
                <!-- Now onto a new line, do the actual Nemeth, which  -->
                <!-- will (a) fill much of the line, (b) always fit.   -->
                <!-- Then afterwards, always go to a new line.         -->
                <span data-braille="nemeth-inline">
                    <xsl:value-of select="$no-break-braille"/>
                </span>
                <br/>
                <!-- Now onto a new line (again).  Drop the closing marker, -->
                <!-- with no prior space, and then let following literary   -->
                <!-- text fill that line.                                   -->
                <span data-braille="nemeth-inline">
                    <xsl:value-of select="$nemeth-close"/>
                </span>
            </xsl:when>
            <!-- Now we are longer than the line-width available, though  -->
            <!-- this was authored as inline math. So make it a display   -->
            <!-- (drop to new line for opening Nemeth with an unbreakable -->
            <!-- space, then let the expression break as it wants to,     -->
            <!-- however liblouis does it (since spaces are breakable).   -->
            <xsl:otherwise>
                <div data-braille="nemeth-display">
                    <span data-braille="nemeth-inline">
                        <xsl:value-of select="$nemeth-open"/>
                        <xsl:text>&#xa0;</xsl:text>
                        <xsl:value-of select="$braille"/>
                        <xsl:text>&#xa0;</xsl:text>
                        <xsl:value-of select="$nemeth-close"/>
                    </span>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- Mutually exclusive, now authored as display -->
    <xsl:if test="$b-display-math">
        <xsl:choose>
            <!-- single line, authored as such, and converted by SRE as such -->
            <xsl:when test="(self::me or self::men) and not($b-multiline)">
                <!-- Similarly, but div puts onto a newline, and breaks after -->
                <div data-braille="nemeth-display">
                    <span data-braille="nemeth-inline">
                        <xsl:value-of select="$nemeth-open"/>
                        <xsl:text>&#xa0;</xsl:text>
                        <xsl:value-of select="$braille"/>
                        <xsl:text>&#xa0;</xsl:text>
                        <xsl:value-of select="$nemeth-close"/>
                    </span>
                </div>
            </xsl:when>
            <!-- Now, authored as display, or converted by SRE, as multiline.  -->
            <!-- liblouis defaults to breaking lines before and after the div. -->
            <!-- We supply opening and closing Nemeth indicators on their own  -->
            <!-- lines, by virtue of the "oneline" span (described below) and  -->
            <!-- trailing line-breaks.                                         -->
            <xsl:otherwise>
                <div data-braille="nemeth-display">
                    <span data-braille="nemeth-oneline">
                        <xsl:value-of select="$nemeth-open"/>
                    </span>
                    <br/>
                    <xsl:call-template name="wrap-multiline-math">
                        <xsl:with-param name="braille" select="$braille"/>
                    </xsl:call-template>
                    <span data-braille="nemeth-oneline">
                        <xsl:value-of select="$nemeth-close"/>
                    </span>
                    <br/>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- The braille representations of math elements should not migrate any -->
    <!-- clause-ending punctuation from trailing text nodes.  So we should   -->
    <!-- not need to invoke the "get-clause-punctuation" modal template here -->
    <!-- NB: we could set  math.punctuation.include  to strip punctuation,   -->
    <!-- and then use "get-clause-punctuation" to put it back somewhere      -->
    <!-- above, such as inside the "displaymath" div so that it appears      -->
    <!-- before a concluding line break, say.                                -->
</xsl:template>

<!-- We recursively isolate lines of braille from SRE that are potentially -->
<!-- laid-out in a manner similar to print.                                -->
<!--   1.  Spans contain each line, which we will process as-is.           -->
<!--   2.  Braille spaces (U+2800) are converted to ASCII non-breaking     -->
<!--       spaces. This is necessary to preserve leading spaces.           -->
<!--       Note: if this indentation is too long, liblouis will line-break -->
<!--      at these spaces with a hyphen, which is highly undesirable.      -->
<!--   3.  A "br" element is needed so we can convince liblouis to         -->
<!--       create a newline.                                               -->

<xsl:template name="wrap-multiline-math">
    <xsl:param name="braille"/>

    <xsl:choose>
        <xsl:when test="not(contains($braille, '&#xa;'))">
            <!-- finished, output, don't recurse -->
            <span data-braille="nemeth-oneline">
                <xsl:value-of select="$braille"/>
            </span>
            <br/>
        </xsl:when>
        <xsl:otherwise>
            <!-- else, bust-up, wrap initial, recurse on trailing -->
            <!-- we *must* have a newline if we reach this point  -->
            <!-- split is on the very first newline, as desired   -->
            <xsl:variable name="initial" select="substring-before($braille, '&#xa;')" />
            <xsl:variable name="trailing" select="substring-after($braille, '&#xa;')" />
            <span data-braille="nemeth-oneline">
                <xsl:value-of select="translate($initial, '&#x2800;', '&#x00a0;')"/>
            </span>
            <br/>
            <xsl:call-template name="wrap-multiline-math">
                <xsl:with-param name="braille" select="translate($trailing, '&#x2800;', '&#x00a0;')"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- This is just a device for LaTeX conversion -->
<xsl:template match="*" mode="xref-number">
    <xsl:apply-templates select="." mode="number"/>
</xsl:template>

<!-- Nothing much to be done, we just -->
<!-- xerox the text representation    -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="target" />
    <xsl:param name="content" />

    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- ########## -->
<!-- Paragraphs -->
<!-- ########## -->

<!-- We do not worry about lists, display math, or code  -->
<!-- displays which PreTeXt requires inside paragraphs.  -->
<!-- Especially since the pipeline corrects this anyway. -->
<!-- NB: see p[1] modified in "paragraphs" elsewhere     -->

<!-- ########## -->
<!-- Quotations -->
<!-- ########## -->

<!-- liblouis recognizes the single/double, left/right -->
<!-- smart quotes so we just let wander in from the    -->
<!-- standard HTML conversion, covering the elements:  -->
<!--                                                   -->
<!--   Characters: "lq", "rq", "lsq", "rsq"            -->
<!--   Grouping: "q", "sq"                             -->

<!-- http://www.dotlessbraille.org/aposquote.htm -->

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Preliminary: be sure to notate HTML with regard to override -->
<!-- here.  Template will help locate for subsequent work.       -->
<!-- <xsl:template match="ol/li|ul/li|var/li" mode="body">       -->

<xsl:template match="ol|ul|dl">
    <xsl:copy>
        <xsl:attribute name="class">
            <xsl:text>outerlist</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="li"/>
    </xsl:copy>
</xsl:template>

<!-- In the imported HTML conversion, an unstructured "li" gets    -->
<!-- a "p" wrapper, to aid in styling certain output formats.      -->
<!-- But we override the template for every possible "li" here.    -->
<!-- This is good, since we have to work hard to ignore an initial -->
<!-- "p" (and friends) in order to write a list label and have the -->
<!-- contents of the list item continue on the same line.          -->

<!-- TODO: subtract 1 from "item-number"   -->
<!-- when "format-code" template gives '0' -->
<xsl:template match="ol/li" mode="body">
    <li>
        <xsl:apply-templates select="." mode="item-number"/>
        <xsl:text>. </xsl:text>
        <xsl:apply-templates/>
    </li>
</xsl:template>

<xsl:template match="ul/li" mode="body">
    <xsl:variable name="format-code">
        <xsl:apply-templates select="parent::ul" mode="format-code"/>
    </xsl:variable>
    <li>
        <!-- The list label.  The file  en-ueb-chardefs.uti        -->
        <!-- associates these Unicode values with the indicated    -->
        <!-- dot patterns.  This jibes with [BANA-2016, 8.6.2],    -->
        <!-- which says the open circle needs a Grade 1 indicator. -->
        <!-- The file  en-ueb-g2.ctb  lists  x25cb  and  x24a0  as -->
        <!-- both being "contraction" and so needing a             -->
        <!-- Grade 1 indicator.                                    -->
        <xsl:choose>
            <!-- Unicode Character 'BULLET' (U+2022)       -->
            <!-- Dot pattern: 456-256                      -->
            <xsl:when test="$format-code = 'disc'">
                <xsl:text>&#x2022; </xsl:text>
            </xsl:when>
            <!-- Unicode Character 'WHITE CIRCLE' (U+25CB) -->
            <!-- Dot pattern: 1246-123456                  -->
            <xsl:when test="$format-code = 'circle'">
                <xsl:text>&#x25cb; </xsl:text>
            </xsl:when>
            <!-- Unicode Character 'BLACK SQUARE' (U+25A0) -->
            <!-- Dot pattern: 456-1246-3456-145            -->
            <xsl:when test="$format-code = 'square'">
                <xsl:text>&#x25a0; </xsl:text>
            </xsl:when>
            <!-- a bad idea for Braille -->
            <xsl:when test="$format-code = 'none'">
                <xsl:text/>
            </xsl:when>
        </xsl:choose>
        <!-- and the contents -->
        <xsl:apply-templates/>
    </li>
</xsl:template>

<xsl:template match="dl">
    <dl class="outerlist">
        <xsl:apply-templates select="li"/>
    </dl>
</xsl:template>

<xsl:template match="dl/li">
    <li class="description">
        <b>
            <xsl:apply-templates select="." mode="title-full"/>
        </b>
        <xsl:apply-templates/>
    </li>
</xsl:template>


<!-- The conversion to braille sometimes needs an exceptional        -->
<!-- element for the first block of a list item, so we can get       -->
<!-- list labels onto the same line as the following content.        -->
<!-- Here in the braille conversion, we usually mimic the HTML       -->
<!-- conversion. The three simple "text" blocks of a list item just  -->
<!-- coincidentally have PreTeXt names that match HTML names - this  -->
<!-- could need to be adjusted later.  In the exceptional case of an -->
<!-- initial list item we provide a throwaway element name, which    -->
<!-- quite literally is cast aside via a rule in  pretext.sem.       -->
<!-- This causes  liblouis  to output the list label (e.g. "a.") and -->
<!-- the first content onto the same line. We documentthis near      -->
<!-- lists, even if use is distributed around.                       -->
<!-- NB: the "otherwise" could be an "apply-imports"?                -->
<xsl:template match="p|blockquote|pre" mode="initial-list-item-element">
    <xsl:choose>
        <xsl:when test="parent::li and not(preceding-sibling::*)">
            <xsl:text>first-li-block</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="local-name(.)"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- An image may be a child of a "figure".  It can also be buried  -->
<!-- within a "sidebyside", perhaps in a "figure", or in a "stack". -->
<!-- This is the other case, a "naked" tabular, perhaps just        -->
<!-- between paragraphs, and thus a child of a division or a block. -->
<!-- We always replace with the textual version.  In the embossed   -->
<!-- case, we move to new placeholder page for a tactile version.   -->
<xsl:template match="image[not(parent::figure|ancestor::sidebyside)]">
    <xsl:apply-templates select="." mode="textual-version"/>
    <xsl:if test="$page-format = 'emboss'">
        <div data-braille="pageeject"/>
        <xsl:apply-templates select="." mode="placeholder-page"/>
    </xsl:if>
</xsl:template>

<!-- If a "figure" has an "image", we let the image do its thing -->
<!-- (as just above) and we also let the figure wrap it.  But we -->
<!-- follow with a (nearly) blank page suggesting a tactile      -->
<!-- version of the image should be subsituted in.               -->
<xsl:template match="figure[image]">
    <xsl:apply-imports/>
    <xsl:if test="$page-format = 'emboss'">
        <div data-braille="pageeject"/>
        <xsl:call-template name="transcriber-note">
            <xsl:with-param name="message">
                <xsl:text>Replace this page with image "</xsl:text>
                <xsl:apply-templates select="." mode="visible-id" />
                <xsl:text>.</xsl:text>
            </xsl:with-param>
        </xsl:call-template>
        <div data-braille="pageeject"/>
    </xsl:if>
</xsl:template>

<!-- We write a paragraph with the "description"  -->
<!-- (authored as a bare string of sorts) and a   -->
<!-- paragraph with our internal id, which is the -->
<!-- basis of a filename that would be used to    -->
<!-- construct any tactile versions.              -->
<xsl:template match="image" mode="textual-version">
    <div data-braille="image">
        <xsl:call-template name="transcriber-note">
            <xsl:with-param name="message">
                <xsl:text>Image "</xsl:text>
                <xsl:apply-templates select="." mode="visible-id" />
                <xsl:text>" goes here.</xsl:text>
                <xsl:if test="description">
                    <xsl:text>  A text description follows.</xsl:text>
                </xsl:if>
                <xsl:if test="$page-format = 'emboss'">
                    <xsl:text> The next page can be replaced with a tactile version.</xsl:text>
                </xsl:if>
            </xsl:with-param>
        </xsl:call-template>
        <br/>
        <xsl:if test="description">
            <xsl:text>Description: </xsl:text>
            <xsl:apply-templates select="description"/>
        </xsl:if>
    </div>
</xsl:template>

<!-- We assume the embossable case has been checked, and a -->
<!-- page-ejection has happened just before this template  -->
<!-- is applied.  And then we follow with a page ejection. -->
<xsl:template match="image" mode="placeholder-page">
    <xsl:call-template name="transcriber-note">
        <xsl:with-param name="message">
            <xsl:text>Replace this page with image "</xsl:text>
            <xsl:apply-templates select="." mode="visible-id" />
            <xsl:text>".</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
    <div data-braille="pageeject"/>
</xsl:template>


<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->

<!-- Transcriber Notes -->

<!-- Here code is the transcriber, so we can explain places where we   -->
<!-- have done something different than it might be realized in print. -->
<!--                                                                   -->
<!-- Two three-cell sequences indicate the begin and end of a          -->
<!-- transcriber note.  Additionally, the indentation is 7-5           -->
<!-- margins, which we achieve with a div.data-braille attribute       -->
<!-- set to "transcribernote" (no dash is intentional) for the         -->
<!-- liblouis semantic action file.  See BANA Formats 3.2.1:           -->
<!-- www.brailleauthority.org/formats/2016manual-web/section03.html    -->
<!--                                                                   -->
<!-- The content provided in the "message" parameter by a calling      -->
<!-- instance should look like the HTML produced by this stylesheet.   -->
<!-- For example to get emphasis, code here should provide             -->
<!-- <em class="emphasis"> so the correct semantic action is applied.  -->
<!-- No overall root element is necessary.  "xsl:text" can be used to  -->
<!-- control stray whitespace.  "xsl:apply-templates" can also be used -->
<!-- to access variable properties, such as identification of objects  -->
<!-- like images. See examples throughout this stylesheet.             -->
<!-- Short answer: the value of "message" is made into a deep copy for -->
<!-- the HTML output (which is next seen by liblouis.                  -->
<!--                                                                   -->
<!-- Template is context-free intentionally.                           -->
<xsl:template name="transcriber-note">
    <xsl:param name="message"/>

    <div data-braille="transcriber-note">
        <!-- dot 4, dot 46, dot 126 -->
        <xsl:text>&#x2808;&#x2828;&#x2823;</xsl:text>
        <!-- straight duplication of raw HTML provided as a parameter -->
        <xsl:copy-of select="$message"/>
        <!-- dot 4, dot 46, dot 345 -->
        <xsl:text>&#x2808;&#x2828;&#x281C;</xsl:text>
    </div>
</xsl:template>

</xsl:stylesheet>