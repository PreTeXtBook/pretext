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


<!-- WARNING: this is an experimental conversion for LaTeX -->
<!-- Use `pretext-latex.xsl` for the standard conversion.  -->


<!-- Conveniences for classes of similar elements -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "./entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<!-- We override specific templates of the common conversion   -->

<xsl:import href="./pretext-latex-common.xsl" />

<!-- Note (2025-01-29): This is the start of a new "classic"    -->
<!-- latex conversion that can be used to create journal-ready  -->
<!-- latex documents. It is still a work in progress, although  -->
<!-- it does now produce a working amsart latex file.           -->


<xsl:template match="/">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">You are using (a version of) the pretext-latex-classic conversion, which is still experimental and under development.</xsl:with-param>
      </xsl:call-template>
  <xsl:apply-imports />
</xsl:template>

<!-- Currently there are no changes for a book (or letter or memo), so we note this and exit -->
<xsl:template match="book|letter|memo">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">You have selected a latex style designed for articles, but are not building an article.  The resulting output will be identical to that of not specifying any latex style.</xsl:with-param>
      </xsl:call-template>
</xsl:template>

<!-- Do not support exercises or reading questions or solutions -->
<xsl:template match="exercises|reading-questions|solutions">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Exercises divisions are not yet supported in latex-classic conversions.  No content of such a division will be included in your output.</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Do not support glossary yet -->
<xsl:template match="glossary">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Glossary divisions are not yet supported in latex-classic conversions.  No content of such a division will be included in your output.</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="section//references">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">References (bibliography) for individual sections are not yet supported in latex-classic conversions.  No content of such a division will be included in your output. You can still have a bibliography at the end of your article.</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="worksheet">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Worksheets are not yet supported in latex-classic conversions.  No content of such a division will be included in your output. </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Defaults that can be overriden by style files -->
<xsl:variable name="documentclass" select="'amsart'"/>
<xsl:variable name="bibliographystyle" select="'amsplain'"/>

<!-- An article, LaTeX structure -->
<!--     One page, full of sections (with abstract, references)                    -->
<!--     Or, one page, totally unstructured, just lots of paragraphs, widgets, etc -->
<xsl:template match="article">
    <xsl:call-template name="converter-blurb-latex"/>
    <xsl:call-template name="snapshot-package-info"/>
    <xsl:text>\documentclass[</xsl:text>
    <xsl:call-template name="sidedness"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$font-size"/>
    <xsl:text>,</xsl:text>
    <xsl:if test="$b-latex-draft-mode" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$documentclass" />
    <xsl:text>}&#xa;&#xa;</xsl:text>

    <xsl:call-template name="latex-preamble" />

    <xsl:call-template name="bibinfo-pre-begin-document" />
    <xsl:text>\begin{document}&#xa;&#xa;</xsl:text>
    <xsl:call-template name="bibinfo-post-begin-document" />

    <xsl:apply-templates />

    <xsl:text>\end{document}&#xa;&#xa;</xsl:text>
</xsl:template>


<xsl:template name="latex-preamble">
    <xsl:call-template name="preamble-early"/>
    <xsl:call-template name="cleardoublepage"/>
    <xsl:call-template name="standard-packages"/>
    <xsl:call-template name="latex-theorem-environments"/>
    <xsl:call-template name="tcolorbox-init"/>
    <xsl:call-template name="page-setup"/>
    <xsl:call-template name="latex-engine-support"/>
    <xsl:call-template name="font-support"/>
    <xsl:call-template name="math-packages"/>
    <xsl:call-template name="pdfpages-package"/>
    <!--<xsl:call-template name="division-titles"/>-->
    <xsl:call-template name="semantic-macros"/>
    <xsl:call-template name="exercises-and-solutions"/>
    <xsl:call-template name="chapter-start-number"/>
    <xsl:call-template name="equation-numbering"/>
    <xsl:call-template name="image-tcolorbox"/>
    <xsl:call-template name="tables"/>
    <xsl:call-template name="footnote-numbering"/>
    <xsl:call-template name="font-awesome"/>
    <xsl:call-template name="poetry-support"/>
    <xsl:call-template name="music-support"/>
    <xsl:call-template name="code-support"/>
    <xsl:call-template name="list-layout"/>
    <xsl:call-template name="load-configure-hyperref"/>
    <xsl:call-template name="create-numbered-tcolorbox"/>
    <xsl:call-template name="watermark"/>
    <xsl:call-template name="showkeys"/>
    <xsl:call-template name="latex-image-support"/>
    <xsl:call-template name="sidebyside-environment"/>
    <xsl:call-template name="kbd-keys"/>
    <xsl:call-template name="late-preamble-adjustments"/>
</xsl:template>


<!-- paragraph and page setup -->
<!-- TODO: Clean this up with just what -classic needs. -->
<xsl:template name="page-setup">
    <!-- This should save-off the indentation used for the first line of  -->
    <!-- a paragraph, in effect for the chosen document class.  Then the  -->
    <!-- "parbox" used by "tcolorbox" can restore indentation rather than -->
    <!-- run with none.  Part of                                          -->
    <!-- https://tex.stackexchange.com/questions/250165/                  -->
    <!-- normal-body-text-within-tcolorbox                                -->
    <!-- In a similar fashion we save/restore the parskip, only should    -->
    <!-- an ambitious publisher try to set it globally                    -->
    <xsl:text>%% Save default paragraph indentation and parskip for use later, when adjusting parboxes&#xa;</xsl:text>
    <!--<xsl:text>\newlength{\normalparindent}&#xa;</xsl:text>-->
    <xsl:text>\newlength{\normalparskip}&#xa;</xsl:text>
    <xsl:text>\AtBeginDocument{\setlength{\normalparindent}{\parindent}}&#xa;</xsl:text>
    <xsl:text>\AtBeginDocument{\setlength{\normalparskip}{\parskip}}&#xa;</xsl:text>
    <xsl:text>\newcommand{\setparstyle}{\setlength{\parindent}{\normalparindent}\setlength{\parskip}{\normalparskip}}</xsl:text>

    <!-- could condition on "subfigure-reps" -->
    <xsl:if test="$b-has-sidebyside">
        <xsl:text>%% shorter subnumbers in some side-by-side require manipulations&#xa;</xsl:text>
        <xsl:text>\usepackage{xstring}&#xa;</xsl:text>
    </xsl:if>
    <!--<xsl:if test="$document-root//fn|$document-root//part">
        <xsl:text>%% Footnote counters and part/chapter counters are manipulated&#xa;</xsl:text>
        <xsl:text>%% April 2018:  chngcntr  commands now integrated into the kernel,&#xa;</xsl:text>
        <xsl:text>%% but circa 2018/2019 the package would still try to redefine them,&#xa;</xsl:text>
        <xsl:text>%% so we need to do the work of loading conditionally for old kernels.&#xa;</xsl:text>
        <xsl:text>%% From version 1.1a,  chngcntr  should detect defintions made by LaTeX kernel.&#xa;</xsl:text>
        <xsl:text>\ifdefined\counterwithin&#xa;</xsl:text>
        <xsl:text>\else&#xa;</xsl:text>
        <xsl:text>    \usepackage{chngcntr}&#xa;</xsl:text>
        <xsl:text>\fi&#xa;</xsl:text>-->
        <!-- implies book/part -->
        <!--<xsl:if test="$parts = 'structural'">
            <xsl:text>%% Structural chapter numbers reset within parts&#xa;</xsl:text>
            <xsl:text>%% Starred form will not prefix part number&#xa;</xsl:text>
            <xsl:text>\counterwithin*{chapter}{part}&#xa;</xsl:text>
        </xsl:if>-->
    <!--</xsl:if>-->
    <!-- Determine height of text block, assumes US letterpaper (11in height) -->
    <!-- Could react to document type, paper, margin specs                    -->
    <!--<xsl:variable name="text-height">
        <xsl:text>9.0in</xsl:text>
    </xsl:variable>-->
    <!-- Bringhurst: 30x => 66 chars, so 34x => 75 chars -->
    <!--<xsl:variable name="text-width">
        <xsl:value-of select="34 * substring-before($font-size, 'pt')" />
        <xsl:text>pt</xsl:text>
    </xsl:variable>-->
    <!--<xsl:text>%% Text height identically 9 inches, text width varies on point size&#xa;</xsl:text>
    <xsl:text>%% See Bringhurst 2.1.1 on measure for recommendations&#xa;</xsl:text>
    <xsl:text>%% 75 characters per line (count spaces, punctuation) is target&#xa;</xsl:text>
    <xsl:text>%% which is the upper limit of Bringhurst's recommendations&#xa;</xsl:text>
    <xsl:text>\geometry{letterpaper,total={</xsl:text>
    <xsl:value-of select="$text-width" />
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$text-height" />
    <xsl:text>}}&#xa;</xsl:text>-->
    <xsl:text>%% Custom Page Layout Adjustments (use publisher page-geometry entry)&#xa;</xsl:text>
    <xsl:if test="$latex-page-geometry != ''">
        <xsl:text>\geometry{</xsl:text>
        <xsl:value-of select="$latex-page-geometry" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <!-- Crop marks, as independent of author tools           -->
    <!-- Always *after* geometry package, no driver selected, -->
    <!-- since it should auto-detect.  Tested with xelatex.   -->
    <!-- crop  package suggests explicitly turning off driver -->
    <!-- options for the geometery package.  We don't.        -->
    <xsl:if test="$b-latex-crop-marks">
        <xsl:text>\usepackage[</xsl:text>
        <xsl:value-of select="$latex-crop-papersize"/>
        <xsl:text>,cam,center]{crop}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$latex-right-alignment = 'ragged'">
        <xsl:text>%% better handing of text alignment&#xa;</xsl:text>
        <xsl:text>\usepackage{ragged2e}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- By default, no bibinfo is included before the \begin{document}.     -->
<!-- Other latex styles can override this to put some information there. -->
<xsl:template name="bibinfo-pre-begin-document"/>


<!-- By default, all bibinfo goes inside (after) \begin{document}.             -->
<!-- Other latex styles can override this in combination with the pre-version. -->
<xsl:template name="bibinfo-post-begin-document">
    <xsl:apply-templates select="$document-root" mode="article-title"/>
    <xsl:if test="$bibinfo/author or $bibinfo/editor">
        <xsl:apply-templates select="$bibinfo/author" mode="article-info"/>
        <xsl:apply-templates select="$bibinfo/editor" mode="article-info"/>
    </xsl:if>
    <xsl:if test="$bibinfo/keywords[@authority='msc']">
        <xsl:text>\subjclass[</xsl:text>
        <xsl:value-of select="$bibinfo/keywords[@authority='msc']/@variant"/>
        <xsl:text>]{</xsl:text>
        <xsl:apply-templates select="$bibinfo/keywords[@authority='msc']"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$bibinfo/date">
        <xsl:text>\date{</xsl:text>
        <xsl:apply-templates select="$bibinfo/date"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$bibinfo/keywords[not(@authority='msc')]">
        <xsl:text>\keywords{</xsl:text>
        <xsl:apply-templates select="$bibinfo/keywords[not(@authority='msc')]"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$bibinfo/support">
        <xsl:text>\dedicatory{</xsl:text>
        <xsl:apply-templates select="$bibinfo/support" mode="article-info"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root/frontmatter/abstract">
        <xsl:apply-templates select="$document-root/frontmatter/abstract"/>
    </xsl:if>
    <xsl:text>\maketitle&#xa;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="*" mode="article-title">
    <xsl:text>%% Title page information for article&#xa;</xsl:text>
    <xsl:text>\title[</xsl:text>
    <xsl:apply-templates select="." mode="title-short"/>
    <xsl:text>]{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:if test="subtitle">
        <xsl:text>\\&#xa;</xsl:text>
        <!-- Trying to match author fontsize -->
        <xsl:text>{\small </xsl:text>
        <xsl:apply-templates select="." mode="subtitle"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>}&#xa;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="bibinfo/author" mode="article-info">
    <xsl:text>\author{</xsl:text>
    <xsl:apply-templates select="personname"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:if test="affiliation">
        <xsl:text>\address{</xsl:text>
        <xsl:apply-templates select="affiliation"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="email">
        <xsl:text>\email{</xsl:text>
        <xsl:apply-templates select="email"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="support">
        <xsl:text>\thanks{</xsl:text>
        <xsl:apply-templates select="support"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Preprocessor always puts Department, Institution, and Address          -->
<!-- inside Affiliation. This just adds line breaks between them as needed. -->
<xsl:template match="affiliation">
    <xsl:if test="department">
        <xsl:apply-templates select="department" />
        <xsl:text>\\&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="institution">
        <xsl:apply-templates select="institution" />
        <xsl:text>\\&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="location">
        <xsl:apply-templates select="location" />
        <xsl:text>\\&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="bibinfo/keywords">
    <xsl:apply-templates select="*" />
    <xsl:text>.</xsl:text>
</xsl:template>

<xsl:template match="abstract">
    <xsl:text>\begin{abstract}&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{abstract}&#xa;</xsl:text>
</xsl:template>


<!-- Since the bibinfo-post-begin-document takes care of all frontmatter, we kill the frontmatter as a separate thing here -->
<xsl:template match="article/frontmatter"/>


<!-- latex-common includes a title-page-info-article template, but latex-classic -->
<!-- does not use this.  So we warn in case we forget and call it by mistake.    -->
<xsl:template name="title-page-info-article">
    <xsl:message>PTX:BUG:     latex-classic based templates do not use title-page-info-article template.</xsl:message>
</xsl:template>


<!-- Theorems, Proofs, Definitions, Examples, Exercises -->

<!-- Theorems have statement/proof structure                    -->
<!-- Definitions have notation, which is handled elsewhere      -->
<!-- Examples have no structure, or have statement and solution -->
<!-- Exercises have hints, answers and solutions                -->

<!-- For preamble -->
<xsl:template name="latex-theorem-environments">
    <xsl:text>%% Theorem-like environments&#xa;</xsl:text>
    <xsl:text>\theoremstyle{plain}&#xa;</xsl:text>
    <!-- We add a basic block element "thmbox" just to have a counter always -->
    <xsl:text>\newtheorem{thmbox}{}[section]&#xa;</xsl:text>
    <xsl:variable name="theoremstyle-plain" select="
        ($document-root//theorem)[1]|
        ($document-root//lemma)[1]|
        ($document-root//proposition)[1]|
        ($document-root//corollary)[1]|
        ($document-root//claim)[1]|
        ($document-root//fact)[1]|
        ($document-root//identity)[1]|
        ($document-root//conjecture)[1]"/>
    <xsl:for-each select="$theoremstyle-plain">
        <xsl:apply-templates select="." mode="newtheorem"/>
    </xsl:for-each>
    <xsl:text>\newtheorem*{assemblage}{}&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>

    <xsl:text>\theoremstyle{definition}&#xa;</xsl:text>
    <xsl:variable name="theoremstyle-definition" select="
        ($document-root//definition)[1]|
        ($document-root//axiom)[1]|
        ($document-root//principle)[1]|
        ($document-root//heuristic)[1]|
        ($document-root//hypothesis)[1]|
        ($document-root//assumption)[1]|
        ($document-root//openproblem)[1]|
        ($document-root//openquestion)[1]|
        ($document-root//algorithm)[1]|
        ($document-root//question)[1]|
        ($document-root//activity)[1]|
        ($document-root//exercise)[1]|
        ($document-root//inlineexercise)[1]|
        ($document-root//investigation)[1]|
        ($document-root//exploration)[1]|
        ($document-root//problem)[1]|
        ($document-root//example)[1]|
        ($document-root//project)[1]
    "/>
    <xsl:for-each select="$theoremstyle-definition">
        <xsl:apply-templates select="." mode="newtheorem"/>
    </xsl:for-each>
    <xsl:text>&#xa;</xsl:text>

    <xsl:text>\theoremstyle{remark}&#xa;</xsl:text>
        <xsl:variable name="theoremstyle-remark" select="
        ($document-root//convention)[1]|
        ($document-root//warning)[1]|
        ($document-root//remark)[1]|
        ($document-root//insight)[1]|
        ($document-root//note)[1]|
        ($document-root//observation)[1]|
        ($document-root//computation)[1]|
        ($document-root//technology)[1]|
        ($document-root//data)[1]
    "/>
    <xsl:for-each select="$theoremstyle-remark">
        <xsl:apply-templates select="." mode="newtheorem"/>
    </xsl:for-each>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="*" mode="newtheorem">
        <xsl:text>\newtheorem{</xsl:text>
        <xsl:choose>
            <!-- One exception for inline exercises -->
            <xsl:when test="local-name(.) = 'exercise'">
                <xsl:text>inlineexercise</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="local-name(.)"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>}[thmbox]{</xsl:text>
        <xsl:apply-templates select="." mode="type-name"/>
        <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- In document -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;|&DEFINITION-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&OPENPROBLEM-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&ASIDE-LIKE;|exercise[boolean(&INLINE-EXERCISE-FILTER;)]|assemblage" mode="block-options">

    <xsl:call-template name="env-title"/>
    <xsl:text>\label{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id"/>
    <xsl:text>}</xsl:text>
</xsl:template>


<!-- Proofs and cases are handled using amsthm; anything other than a proof gets a title or the name of the proof-like env. -->
<xsl:template match="&PROOF-LIKE;">
    <xsl:text>\begin{proof}</xsl:text>
    <xsl:choose>
        <xsl:when test="title">
            <xsl:text>[</xsl:text>
            <xsl:apply-templates select="." mode="title-simple"/>
            <xsl:text>]</xsl:text>
        </xsl:when>
        <xsl:when test="local-name(.)!='proof'">
            <xsl:text>[</xsl:text>
            <xsl:apply-templates select="." mode="type-name"/>
            <xsl:text>]</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>\label{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{proof}&#xa;&#xa;</xsl:text>
</xsl:template>

<!-- Cases in proofs -->
<xsl:template match="case">
    <xsl:text>\textit{</xsl:text>
    <xsl:if test="@direction">
        <xsl:apply-templates select="." mode="case-direction"/>
        <xsl:text>&#xa0;</xsl:text>
    </xsl:if>
    <xsl:if test="title">
        <xsl:text>&#xa0;</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
    </xsl:if>
    <xsl:if test="not(title) and not(@direction)">
        <xsl:apply-templates select="." mode="type-name"/>
    </xsl:if>
    <xsl:text>}</xsl:text>
    <!-- label -->
    <xsl:text>\label{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>


<xsl:template name="env-title">
    <xsl:if test="title|creator">
        <xsl:text>[</xsl:text>
        <xsl:if test="title">
            <xsl:apply-templates select="." mode="title-full"/>
        </xsl:if>
        <xsl:if test="(title) and (creator)">
            <xsl:text>&#160;</xsl:text>
        </xsl:if>
        <xsl:if test="creator">
            <xsl:apply-templates select="." mode="creator-full"/>
        </xsl:if>
        <xsl:text>]</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Divisions -->

<xsl:template match="section|subsection|subsubsection|appendix">
    <xsl:text>\</xsl:text>
    <xsl:value-of select="local-name(.)"/>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}&#xa;&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>% end of </xsl:text>
    <xsl:value-of select="local-name(.)"/>
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>&#xa;&#xa;</xsl:text>
</xsl:template>
<xsl:template match="subsubsubsection">
    <xsl:text>\paragraph</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}&#xa;&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>% end of subsubsubsection: </xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>&#xa;&#xa;</xsl:text>
</xsl:template>

<!-- Paragraphs -->
<!-- Use *-version of section/subsection/subsubsection/etc at a level one below parent -->
<xsl:template match="paragraphs">
    <xsl:choose>
        <xsl:when test="parent::article">
            <xsl:text>\section*{</xsl:text>
        </xsl:when>
        <xsl:when test="parent::section">
            <xsl:text>\subsection*{</xsl:text>
        </xsl:when>
        <xsl:when test="parent::subsection">
            <xsl:text>\subsubsection*{</xsl:text>
        </xsl:when>
        <xsl:when test="parent::subsubsection">
            <xsl:text>\paragraph*{</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\subparagraph*{</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}</xsl:text>
    <xsl:text>\label{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>%% end paragraphs&#xa;&#xa;</xsl:text>
</xsl:template>

<!-- Introductions and Conclusions -->
<!-- Introductions and conclusions are just their contents at their position. -->
<xsl:template match="article/introduction|chapter/introduction|section/introduction|subsection/introduction|appendix/introduction|exercises/introduction|solutions/introduction|worksheet/introduction|reading-questions/introduction|references/introduction">
    <xsl:text>% Introduction&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>% end introduction&#xa;</xsl:text>
</xsl:template>

<xsl:template match="article/conclusion|chapter/conclusion|section/conclusion|subsection/conclusion|appendix/conclusion|exercises/conclusion|solutions/conclusion|worksheet/conclusion|reading-questions/conclusion|references/conclusion">
    <xsl:text>% Conclusion&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>% End conclusion&#xa;</xsl:text>
</xsl:template>



<!-- ################### -->
<!-- References Sections -->
<!-- ################### -->
<!-- TODO: The following will certainly change when the bibliography work is completed -->

<xsl:template match="references">
    <xsl:text>\bibliographystyle{</xsl:text>
    <xsl:value-of select="$bibliographystyle"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\begin{thebibliography}{99}&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{thebibliography}&#xa;&#xa;</xsl:text>
</xsl:template>



<xsl:template match="biblio[@type='raw'] | biblio[@type='bibtex']">

    <xsl:text>\bibitem</xsl:text>
    <!-- "label" (e.g. Jud99), or by default serial number -->
    <!-- LaTeX's bibitem will provide the visual brackets  -->
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="." mode="serial-number" />
    <xsl:text>]</xsl:text>
    <!-- "key" for cross-referencing -->
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id"/>
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>

</xsl:template>



<!-- A much smaller version from common: -->
<!-- TODO: Refactor this to give only what we need. -->
<xsl:template name="create-numbered-tcolorbox">
    <!-- ################## -->
    <!-- Division Numbering -->
    <!-- ################## -->
    <xsl:text>%% Division Numbering: Chapters, Sections, Subsections, etc&#xa;</xsl:text>
    <xsl:text>%% Division numbers may be turned off at some level ("depth")&#xa;</xsl:text>
    <xsl:text>%% A section *always* has depth 1, contrary to us counting from the document root&#xa;</xsl:text>
    <xsl:text>%% The latex default is 3.  If a larger number is present here, then&#xa;</xsl:text>
    <xsl:text>%% removing this command may make some cross-references ambiguous&#xa;</xsl:text>
    <xsl:text>%% The precursor variable $numbering-maxlevel is checked for consistency in the common XSL file&#xa;</xsl:text>
    <xsl:text>\setcounter{secnumdepth}{</xsl:text>
        <xsl:value-of select="$latex-numbering-maxlevel" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>

    <!--  -->
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% A faux tcolorbox whose only purpose is to provide common numbering&#xa;</xsl:text>
    <xsl:text>%% facilities for most blocks (possibly not projects, 2D displays)&#xa;</xsl:text>
    <xsl:text>%% Controlled by  numbering.theorems.level  processing parameter&#xa;</xsl:text>
    <xsl:text>\newtcolorbox[auto counter</xsl:text>
    <!-- control the levels of the numbering -->
    <!-- global (no periods) is the default  -->
    <xsl:if test="not($numbering-blocks = 0)">
        <xsl:text>, number within=</xsl:text>
        <xsl:call-template name="level-to-name">
            <xsl:with-param name="level" select="$numbering-blocks" />
        </xsl:call-template>
    </xsl:if>
    <xsl:text>]{block}{}&#xa;</xsl:text>
    <!-- should condition on $project-reps, but it is not defined yet -->
    <xsl:if test="$b-number-project-distinct">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% This document is set to number PROJECT-LIKE on a separate numbering scheme&#xa;</xsl:text>
        <xsl:text>%% So, a faux tcolorbox whose only purpose is to provide this numbering&#xa;</xsl:text>
        <xsl:text>%% Controlled by  numbering.projects.level  processing parameter&#xa;</xsl:text>
        <xsl:text>\newtcolorbox[auto counter</xsl:text>
        <!-- control the levels of the numbering -->
        <!-- global (no periods) is the default  -->
        <xsl:if test="not($numbering-projects = 0)">
            <xsl:text>, number within=</xsl:text>
            <xsl:call-template name="level-to-name">
                <xsl:with-param name="level" select="$numbering-projects" />
            </xsl:call-template>
        </xsl:if>
        <xsl:text>]{project-distinct}{}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$b-number-exercise-distinct">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% This document is set to number inline exercises on a separate numbering scheme&#xa;</xsl:text>
        <xsl:text>%% So, a faux tcolorbox whose only purpose is to provide this numbering&#xa;</xsl:text>
        <xsl:text>\newtcolorbox[auto counter</xsl:text>
        <!-- control the levels of the numbering -->
        <!-- global (no periods) is the default  -->
        <xsl:if test="not($numbering-exercises = 0)">
            <xsl:text>, number within=</xsl:text>
            <xsl:call-template name="level-to-name">
                <xsl:with-param name="level" select="$numbering-exercises" />
            </xsl:call-template>
        </xsl:if>
        <xsl:text>]{exercise-distinct}{}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$b-number-figure-distinct">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% This document is set to number figure, table, list, listing on a separate numbering scheme&#xa;</xsl:text>
        <xsl:text>%% So, a faux tcolorbox whose only purpose is to provide this numbering&#xa;</xsl:text>
        <xsl:text>\newtcolorbox[auto counter</xsl:text>
        <!-- control the levels of the numbering -->
        <!-- global (no periods) is the default  -->
        <xsl:if test="not($numbering-figures = 0)">
            <xsl:text>, number within=</xsl:text>
            <xsl:call-template name="level-to-name">
                <xsl:with-param name="level" select="$numbering-figures" />
            </xsl:call-template>
        </xsl:if>
        <xsl:text>]{figure-distinct}{}&#xa;</xsl:text>
    </xsl:if>
    <!-- TODO: condition of figure/*/figure-like, or $subfigure-reps -->
    <xsl:text>%% A faux tcolorbox whose only purpose is to provide common numbering&#xa;</xsl:text>
    <xsl:text>%% facilities for 2D displays which are subnumbered as part of a "sidebyside"&#xa;</xsl:text>
    <!-- faux subdisplay requires manipulating low-level counters -->
    <!-- TODO: condition on presence of (plain) 2-D displays to limit use? -->
    <xsl:text>\makeatletter&#xa;</xsl:text>
    <xsl:text>\newtcolorbox[auto counter</xsl:text>
    <!-- control the levels of the numbering -->
    <!-- global (no periods) is the default  -->
    <xsl:text>, number within=</xsl:text>
    <xsl:choose>
        <xsl:when test="$b-number-figure-distinct">
            <xsl:text>tcb@cnt@figure-distinct</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>tcb@cnt@block</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>, number freestyle={\noexpand\thetcb@cnt@block(\noexpand\alph{\tcbcounter})}</xsl:text>
    <xsl:text>]{subdisplay}{}&#xa;</xsl:text>
    <!-- faux subdisplay requires manipulating low-level counters -->
    <xsl:text>\makeatother&#xa;</xsl:text>
   <!-- Groups of environments/blocks -->

    <!-- GOAL-LIKE -->
    <xsl:variable name="goal-reps" select="
        ($document-root//objectives)[1]|
        ($document-root//outcomes)[1]"/>
    <xsl:if test="$goal-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for GOAL-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$goal-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- ASIDE-LIKE -->
    <xsl:variable name="aside-reps" select="
        ($document-root//aside)[1]|
        ($document-root//historical)[1]|
        ($document-root//biographical)[1]"/>
    <xsl:if test="$aside-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for ASIDE-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$aside-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- FIGURE-LIKE -->
    <!-- FIGURE-LIKE come in three flavors: blocks (not in a side-by-side),  -->
    <!-- panels (in a side-by-side, but not in an overall "figure"), or      -->
    <!-- subnumbered (panel of a side-by-side, which is then in an overall   -->
    <!-- "figure').  Selections must be careful (not like dropping through   -->
    <!-- a choose/when).  Environments need to consider title/caption        -->
    <!-- placement and counters.  So we might create twelve different        -->
    <!-- environments here.  In -common, see the "figure-placement" template -->
    <!-- for another determination, and a more careful explanation.          -->
    <!-- (There was once a subtle bug when we were not so careful here.)     -->
    <xsl:variable name="figure-reps" select="
        ($document-root//figure[not(parent::sidebyside)])[1]|
        ($document-root//table[not(parent::sidebyside)])[1]|
        ($document-root//listing[not(parent::sidebyside)])[1]|
        ($document-root//list[not(parent::sidebyside)])[1]"/>
    <xsl:if test="$figure-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for FIGURE-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$figure-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- (PANEL)FIGURE-LIKE -->
    <!-- sidebyside panel versions, if not contained by overall figure -->
    <xsl:variable name="panel-reps" select="
        ($document-root//sidebyside/figure[not(ancestor::figure)])[1]|
        ($document-root//sidebyside/table[not(ancestor::figure)])[1]|
        ($document-root//sidebyside/listing[not(ancestor::figure)])[1]|
        ($document-root//sidebyside/list[not(ancestor::figure)])[1]"/>
    <xsl:if test="$panel-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for (PANEL)FIGURE-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$panel-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- (SUB)FIGURE-LIKE -->
    <!-- subnumbered versions, if contained by overall figure -->
    <xsl:variable name="subnumber-reps" select="
        ($document-root//figure/sidebyside/figure|$document-root//figure/sbsgroup/sidebyside/figure)[1]|
        ($document-root//figure/sidebyside/table|$document-root//figure/sbsgroup/sidebyside/table)[1]|
        ($document-root//figure/sidebyside/listing|$document-root//figure/sbsgroup/sidebyside/listing)[1]|
        ($document-root//figure/sidebyside/list|$document-root//figure/sbsgroup/sidebyside/list)[1]"/>
    <xsl:if test="$subnumber-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for (SUB)FIGURE-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$subnumber-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>

    <!-- MISCELLANEOUS -->
    <!-- "paragraphs" are partly like a division, -->
    <!-- but we include it here as a one-off      -->
    <xsl:variable name="miscellaneous-reps" select="
        ($document-root//gi)[1]|
        ($document-root//backmatter/colophon)[1]"/>
    <xsl:if test="$miscellaneous-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for miscellaneous environments&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$miscellaneous-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
</xsl:template>


</xsl:stylesheet>