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

<!-- This is the default LaTeX stylesheet for PreTeXt.  -->


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

<!-- This stylesheet holds the templates specific to the regular -->
<!-- (PreTeXt-styled) LaTeX conversion: document shells, the     -->
<!-- preamble driver, division title styling, covers, title      -->
<!-- pages, and front and back matter presentation.  Machinery   -->
<!-- shared with other LaTeX-based conversions (classic, Beamer) -->
<!-- lives in pretext-latex-common.xsl.                          -->

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<!-- font-size also dictates document class for -->
<!-- those provided by extsizes, but we can get -->
<!-- these by just inserting the "ext" prefix   -->
<!-- We don't load the package, the classes     -->
<!-- are incorporated in the documentclass[]{}  -->
<!-- and only if we need the extreme values     -->

<!-- A convenient shortcut/hack that might need expansion later   -->
<!-- insert "ext" or nothing in front of "regular" document class -->
<xsl:variable name="document-class-prefix">
    <xsl:choose>
        <xsl:when test="$font-size='10pt'"></xsl:when>
        <xsl:when test="$font-size='12pt'"></xsl:when>
        <xsl:when test="$font-size='11pt'"></xsl:when>
        <xsl:otherwise>
            <xsl:text>ext</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- ############### -->
<!-- Document Shells -->
<!-- ############### -->

<!-- TODO: combine article, book, letter, templates -->
<!-- with abstract templates for latex classes, page sizes -->

<!-- An article, LaTeX structure -->
<!--     One page, full of sections (with abstract, references)                    -->
<!--     Or, one page, totally unstructured, just lots of paragraphs, widgets, etc -->
<xsl:template match="article">
    <xsl:call-template name="converter-blurb-latex" />
    <xsl:call-template name="snapshot-package-info"/>
    <xsl:text>\documentclass[</xsl:text>
    <xsl:call-template name="sidedness"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$font-size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$b-latex-draft-mode" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$document-class-prefix" />
    <xsl:text>article}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <!-- parameterize preamble template with "page-geometry" template conditioned on self::article etc -->
    <xsl:call-template name="title-page-info-article" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:call-template name="text-alignment"/>
    <xsl:call-template name="front-cover"/>
    <!-- Target for xref to top-level element -->
    <!-- immediately, or first in ToC         -->
    <xsl:choose>
        <xsl:when test="$b-has-toc">
            <xsl:text>%% Target for xref to top-level element is ToC&#xa;</xsl:text>
            <xsl:text>\addtocontents{toc}{</xsl:text>
            <xsl:if test="$b-pageref">
                <xsl:text>\protect\label{</xsl:text>
                <xsl:apply-templates select="." mode="unique-id" />
                <xsl:text>}</xsl:text>
            </xsl:if>
            <xsl:text>\protect\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="unique-id" />
            <xsl:text>}{}</xsl:text>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>%% Target for xref to top-level element is document start&#xa;</xsl:text>
            <xsl:if test="$b-pageref">
                <xsl:text>\label{</xsl:text>
                <xsl:apply-templates select="." mode="unique-id" />
                <xsl:text>}</xsl:text>
            </xsl:if>
            <xsl:text>\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="unique-id" />
            <xsl:text>}{}&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- If no frontmatter/titlepage, then title is not printed       -->
    <!-- so we make sure it happens here, else triggered by titlepage -->
    <!-- If a title, we know it is page 1, so use empty style -->
    <xsl:if test="title and not(frontmatter/titlepage)">
        <xsl:text>\maketitle&#xa;</xsl:text>
        <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="*"/>
    <xsl:call-template name="back-cover"/>
    <xsl:text>\end{document}&#xa;</xsl:text>
</xsl:template>

<!-- A book, LaTeX structure -->
<!-- The ordering of the frontmatter is from             -->
<!-- "Bookmaking", 3rd Edition, Marshall Lee, Chapter 27 -->
<xsl:template match="book">
    <xsl:call-template name="converter-blurb-latex" />
    <xsl:call-template name="snapshot-package-info"/>
    <xsl:text>\documentclass[</xsl:text>
    <xsl:call-template name="sidedness"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$font-size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$b-latex-draft-mode" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$document-class-prefix" />
    <xsl:text>book}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:call-template name="text-alignment"/>
    <!-- Front cover before \frontmatter is OK,     -->
    <!-- since we do not number the page (main role -->
    <!-- of \frontmatter is to use Roman numerals)  -->
    <xsl:call-template name="front-cover"/>
    <xsl:apply-templates select="*"/>
    <xsl:call-template name="back-cover"/>
    <xsl:text>\end{document}&#xa;</xsl:text>
</xsl:template>

<!-- A letter, LaTeX structure -->
<xsl:template match="letter">
    <xsl:call-template name="converter-blurb-latex" />
    <xsl:call-template name="snapshot-package-info"/>
    <xsl:text>\documentclass[</xsl:text>
    <xsl:call-template name="sidedness"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$font-size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$b-latex-draft-mode" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$document-class-prefix" />
    <xsl:text>article}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:call-template name="text-alignment"/>
    <xsl:apply-templates select="*"/>
    <xsl:text>\end{document}&#xa;</xsl:text>
</xsl:template>

<!-- A memo, LaTeX structure -->
<xsl:template match="memo">
    <xsl:call-template name="converter-blurb-latex" />
    <xsl:call-template name="snapshot-package-info"/>
    <xsl:text>\documentclass[</xsl:text>
    <xsl:call-template name="sidedness"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$font-size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$b-latex-draft-mode" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$document-class-prefix" />
    <xsl:text>article}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:call-template name="text-alignment"/>
    <xsl:apply-templates select="*"/>
    <xsl:text>\end{document}&#xa;</xsl:text>
</xsl:template>

<!-- ################ -->
<!-- Preamble, Driver -->
<!-- ################ -->

<!-- LaTeX preamble is common for both books, articles, memos and letters -->
<!-- Except: title info allows an "event" for an article (presentation)   -->
<xsl:template name="latex-preamble">
    <xsl:call-template name="preamble-early"/>
    <xsl:call-template name="cleardoublepage"/>
    <xsl:call-template name="standard-packages"/>
    <xsl:call-template name="tcolorbox-init"/>
    <xsl:call-template name="page-setup"/>
    <xsl:call-template name="latex-engine-support"/>
    <xsl:call-template name="font-support"/>
    <xsl:call-template name="math-packages"/>
    <xsl:call-template name="text-symbols"/>
    <xsl:call-template name="pdfpages-package"/>
    <xsl:call-template name="division-titles"/>
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
    <!-- This is the place to add part numbers to the numbering, which   -->
    <!-- is *not* the default LaTeX behavior.  The \p@section scheme     -->
    <!-- is complicated, leading to about ten constructions like         -->
    <!--                                                                 -->
    <!-- \ifdefined\p@namedlist\renewcommand{\p@namedlist}{\thepart.}\fi -->
    <!--                                                                 -->
    <!-- Advice is to redefine these *before* loading hyperref           -->
    <!-- https://tex.stackexchange.com/questions/172962                  -->
    <!-- (hyperref-include-part-number-for-cross-references-to-chapters) -->
    <!-- Easier is to just adjust the chapter number, which filters down -->
    <!-- into anything that uses the chapter, though perhaps per-part    -->
    <!-- numbering will still need something?                            -->
    <!--                                                                 -->
    <!-- \renewcommand{\thechapter}{\thepart.\arabic{chapter}}           -->
    <!--                                                                 -->
    <xsl:call-template name="load-configure-hyperref"/>
    <!-- We create counters and numbered  tcolorbox  environments -->
    <!-- *after* loading the  hyperref  package, so as to avoid a -->
    <!-- pdfTeX warning about duplicate identifiers.              -->
    <xsl:call-template name="create-numbered-tcolorbox"/>
    <!-- The "xwatermark" package has way more options, including the -->
    <!-- possibility of putting the watermark onto the foreground     -->
    <!-- (above shaded/colored "tcolorbox").  But on 2018-10-24,      -->
    <!-- xwatermark was at v1.5.2d, 2012-10-23, and draftwatermark    -->
    <!-- was at v1.2, 2015-02-19.                                     -->

    <xsl:call-template name="watermark"/>
    <xsl:call-template name="showkeys"/>
    <xsl:call-template name="latex-image-support"/>
    <xsl:call-template name="sidebyside-environment"/>
    <xsl:call-template name="kbd-keys"/>
    <xsl:call-template name="late-preamble-adjustments"/>

</xsl:template>

<!-- Division titles and headers/footers for styling -->
<xsl:template name="division-titles">
    <xsl:text>%% Division Titles, and Page Headers/Footers&#xa;</xsl:text>
    <!-- The final mandatory argument of the titlesec \titleformat  -->
    <!-- command is the "before-code", meaning before the text of   -->
    <!-- the title.  For greater flexibility, the text of the title -->
    <!-- can be referenced *explicitly* by macro parameter #1 in    -->
    <!-- whatever code is placed into this argument.  This is       -->
    <!-- accomplished with the "explicit" argument.                 -->
    <!-- In particular, the numberless, chapter-level "Index" and   -->
    <!-- "Contents" are generated semi-automatically with a macro,  -->
    <!-- so PTX never sees the title (but can use built-in LaTeX    -->
    <!-- facilities to change it to another language)               -->
    <!-- "pagestyles" option is equivalent to loading the           -->
    <!-- "titleps" package and have it execute cooperatively        -->
    <xsl:text>%% titlesec package, loading "titleps" package cooperatively&#xa;</xsl:text>
    <xsl:text>%% See code comments about the necessity and purpose of "explicit" option.&#xa;</xsl:text>
    <xsl:text>%% The "newparttoc" option causes a consistent entry for parts in the ToC &#xa;</xsl:text>
    <xsl:text>%% file, but it is only effective if there is a \titleformat for \part.&#xa;</xsl:text>
    <xsl:text>%% "pagestyles" loads the  titleps  package cooperatively.&#xa;</xsl:text>
    <xsl:text>\usepackage[explicit, newparttoc, pagestyles]{titlesec}&#xa;</xsl:text>
    <xsl:text>%% The companion titletoc package for the ToC.&#xa;</xsl:text>
    <xsl:text>\usepackage{titletoc}&#xa;</xsl:text>
    <!-- Necessary fix for chapter/appendix transition              -->
    <!-- From titleps package author, 2013 post                     -->
    <!-- https://tex.stackexchange.com/questions/117222/            -->
    <!-- issue-with-titlesec-page-styles-and-appendix-in-book-class -->
    <!-- Maybe this is a problem for an "article" as well?  Hints:  -->
    <!-- https://tex.stackexchange.com/questions/319581/   issue-   -->
    <!-- with-titlesec-section-styles-and-appendix-in-article-class -->
    <xsl:if test="$b-is-book">
        <xsl:text>%% Fixes a bug with transition from chapters to appendices in a "book"&#xa;</xsl:text>
        <xsl:text>%% See generating XSL code for more details about necessity&#xa;</xsl:text>
        <xsl:text>\newtitlemark{\chaptertitlename}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% begin: customizations of page styles via the modal "titleps-style" template&#xa;</xsl:text>
    <xsl:text>%% Designed to use commands from the LaTeX "titleps" package&#xa;</xsl:text>
    <xsl:apply-templates select="$document-root" mode="titleps-style"/>
    <xsl:text>%% end: customizations of page styles via the modal "titleps-style" template&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <!--  -->
    <xsl:text>%% Create globally-available macros to be provided for style writers&#xa;</xsl:text>
    <xsl:text>%% These are redefined for each occurence of each division&#xa;</xsl:text>
    <xsl:text>\newcommand{\divisionnameptx}{\relax}%&#xa;</xsl:text>
    <xsl:text>\newcommand{\titleptx}{\relax}%&#xa;</xsl:text>
    <xsl:text>\newcommand{\subtitleptx}{\relax}%&#xa;</xsl:text>
    <xsl:text>\newcommand{\shortitleptx}{\relax}%&#xa;</xsl:text>
    <xsl:text>\newcommand{\authorsptx}{\relax}%&#xa;</xsl:text>
    <xsl:text>\newcommand{\epigraphptx}{\relax}%&#xa;</xsl:text>
    <!-- Create xparse enviroments for each PTX division.          -->
    <!-- The pervasive environments need qualification so          -->
    <!-- that the right LaTeX divisions are created.               -->
    <!-- These look like environments like "solutions-subsection"  -->
    <!-- We want one (and only one) of each type that is necessary -->
    <!-- For each line below think CAREFULLY about the level       -->
    <!-- created, it is one level below what it might appear       -->
    <xsl:variable name="division-reps" select="
        ($document-root//acknowledgement)[1]|
        ($document-root//foreword)[1]|
        ($document-root//preface)[1]|
        ($document-root//part)[1]|
        ($document-root//chapter)[1]|
        ($document-root//section)[1]|
        ($document-root//subsection)[1]|
        ($document-root//subsubsection)[1]|
        ($document-root//subsubsection)[1]|
        ($root/book/backmatter/appendix|$root/article/backmatter/appendix)[1]|
        ($document-root//index)[1]|
        ($document-root//chapter/exercises|$root/book/backmatter/appendix/exercises|$root/article/exercises)[1]|
        ($document-root//section/exercises|$root/article/backmatter/appendix/exercises)[1]|
        ($document-root//subsection/exercises)[1]|
        ($document-root//subsubsection/exercises)[1]|
        ($root/book/backmatter/solutions)[1]|
        ($document-root//chapter/solutions|$root/article/solutions|$root/article/backmatter/solutions)[1]|
        ($document-root//section/solutions)[1]|
        ($document-root//subsection/solutions)[1]|
        ($document-root//subsubsection/solutions)[1]|
        ($document-root//chapter/worksheet|$root/article/worksheet)[1]|
        ($document-root//section/worksheet)[1]|
        ($document-root//subsection/worksheet)[1]|
        ($document-root//subsubsection/worksheet)[1]|
        ($document-root//chapter/handout|$root/article/handout)[1]|
        ($document-root//section/handout)[1]|
        ($document-root//subsection/handout)[1]|
        ($document-root//subsubsection/handout)[1]|
        ($document-root//chapter/reading-questions|$root/article/reading-questions)[1]|
        ($document-root//section/reading-questions)[1]|
        ($document-root//subsection/reading-questions)[1]|
        ($document-root//subsubsection/reading-questions)[1]|
        ($root/book/backmatter/glossary)[1]|
        ($document-root//chapter/glossary|$root/article/backmatter/glossary|$root/book/backmatter/appendix/glossary)[1]|
        ($document-root//section/glossary|$root/article/backmatter/appendix/glossary)[1]|
        ($document-root//subsection/glossary)[1]|
        ($document-root//subsubsection/glossary)[1]|
        ($root/book/backmatter/references)[1]|
        ($document-root//chapter/references|$root/article/references|$root/article/backmatter/references|$root/book/backmatter/appendix/references)[1]|
        ($document-root//section/references|$root/article/backmatter/appendix/references)[1]|
        ($document-root//subsection/references)[1]|
        ($document-root//subsubsection/references)[1]"/>
    <xsl:text>%% Create environments for possible occurences of each division&#xa;</xsl:text>
    <xsl:for-each select="$division-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% Styles for six traditional LaTeX divisions&#xa;</xsl:text>
    <!-- Create six title styles, part to paragraph     -->
    <!-- NB: paragraph is like a "subsubsubsection"     -->
    <!-- "titlesec" works on a level basis, so          -->
    <!-- we just build all six named styles             -->
    <!-- N.B.: we are using the LaTeX "subparagraph"    -->
    <!-- traditional division for a PTX "paragraphs",   -->
    <!-- but perhaps we can fake that with a tcolorbox, -->
    <!-- since we don't allow it to be styled.          -->
    <xsl:call-template name="titlesec-part-style"/>
    <xsl:call-template name="titlesec-chapter-style"/>
    <xsl:call-template name="titlesec-section-style"/>
    <xsl:call-template name="titlesec-subsection-style"/>
    <xsl:call-template name="titlesec-subsubsection-style"/>
    <xsl:call-template name="titlesec-paragraph-style"/>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% Styles for five traditional LaTeX divisions&#xa;</xsl:text>
    <!-- Create five title styles, part to subsubsection -->
    <xsl:call-template name="titletoc-part-style"/>
    <xsl:call-template name="titletoc-chapter-style"/>
    <xsl:call-template name="titletoc-section-style"/>
    <xsl:call-template name="titletoc-subsection-style"/>
    <xsl:call-template name="titletoc-subsubsection-style"/>
    <xsl:text>%%&#xa;</xsl:text>
</xsl:template>

<!-- Numbering Footnotes -->
<xsl:template name="footnote-numbering">
    <xsl:if test="$document-root//fn">
        <xsl:text>%% Footnote Numbering&#xa;</xsl:text>
        <xsl:text>%% Specified by numbering.footnotes.level&#xa;</xsl:text>
        <xsl:if test="$b-is-book">
            <xsl:text>%% Undo counter reset by chapter for a book&#xa;</xsl:text>
            <xsl:text>\counterwithout{footnote}{chapter}&#xa;</xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$numbering-footnotes = 0">
                <xsl:text>%% Global numbering, since numbering.footnotes.level = 0&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>\counterwithin*{footnote}{</xsl:text>
                <xsl:call-template name="level-to-name">
                    <xsl:with-param name="level" select="$numbering-footnotes" />
                </xsl:call-template>
                <xsl:text>}&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <xsl:call-template name="support-footnote"/>
</xsl:template>

<!-- Text Alignment, Right and Bottom -->
<!-- \RaggedRight is from the "ragged2e" package, and  -->
<!-- will allow for some hypenation (vs. \raggedright) -->
<!-- Bottom varies by oneside/twoside, and by          -->
<!-- book/article, so we just make it explicit no      -->
<!-- matter what (breaking that dichotomy)             -->
<!-- See: https://www.sascha-frank.com/page-break.html -->
<!-- N.B. Perhaps this template should be used in the  -->
<!-- LaTeX preamble, perhaps with \AtBeginDocument{}   -->
<!-- https://tex.stackexchange.com/questions/33913/    -->
<!-- global-ragged-right-justification-of-report       -->
<xsl:template name="text-alignment">
    <!-- horizontal/right first -->
    <xsl:choose>
        <xsl:when test="$latex-right-alignment = 'ragged'">
            <xsl:text>\RaggedRight&#xa;</xsl:text>
        </xsl:when>
        <!-- Flush right is default LaTeX -->
        <xsl:when test="$latex-right-alignment = 'flush'"/>
    </xsl:choose>
    <!-- vertical/bottom -->
    <xsl:text>%% bottom alignment is explicit, since it normally depends on oneside, twoside&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="$latex-bottom-alignment = 'ragged'">
            <xsl:text>\raggedbottom&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$latex-bottom-alignment = 'flush'">
            <xsl:text>\flushbottom&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- For a "book" place *before* \frontmatter so  -->
<!-- as to not disrupt Roman numeral numbering -->
<xsl:template name="front-cover">
    <xsl:if test="$b-has-latex-front-cover">
        <xsl:text>%% Cover image, not numbered&#xa;</xsl:text>
        <xsl:text>\setcounter{page}{0}%&#xa;</xsl:text>
        <xsl:text>\includepdf[noautoscale=false]{</xsl:text>
        <xsl:value-of select="$latex-front-cover-filename"/>
        <xsl:text>}%&#xa;</xsl:text>
        <xsl:if test="$latex-sides= 'two'">
            <xsl:text>%% Blank obverse for 2-sided version&#xa;</xsl:text>
            <xsl:text>\thispagestyle{empty}\hbox{}\setcounter{page}{0}\cleardoublepage%&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
</xsl:template>

<xsl:template name="back-cover">
    <xsl:if test="$b-has-latex-back-cover">
        <xsl:text>%% Back cover image, not numbered&#xa;</xsl:text>
        <xsl:text>\cleardoublepage%&#xa;</xsl:text>
        <xsl:if test="$latex-sides= 'two'">
            <xsl:text>%% 2-sided, and at end of even page, so add odd page&#xa;</xsl:text>
            <xsl:text>\thispagestyle{empty}\hbox{}\newpage%&#xa;</xsl:text>
        </xsl:if>
        <xsl:text>\includepdf[noautoscale=false]{</xsl:text>
        <xsl:value-of select="$latex-back-cover-filename"/>
        <xsl:text>}%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Includes an "event" for presentations -->
<xsl:template name="title-page-info-article">
    <xsl:text>%% Title page information for article&#xa;</xsl:text>
    <xsl:text>\title{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:if test="subtitle">
        <xsl:text>\\&#xa;</xsl:text>
        <!-- Trying to match author fontsize -->
        <xsl:text>{\large </xsl:text>
        <xsl:apply-templates select="." mode="subtitle" />
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:if test="$docinfo/event">
        <xsl:if test="title">
            <xsl:text>\\</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="$docinfo/event" />
    </xsl:if>
    <xsl:if test="$bibinfo/support">
        <xsl:text>\ptxsupport{</xsl:text>
        <xsl:apply-templates select="$bibinfo/support" mode="article-info"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:if test="$bibinfo/author or $bibinfo/editor">
        <xsl:text>\author{</xsl:text>
        <xsl:apply-templates select="$bibinfo/author" mode="article-info"/>
        <xsl:apply-templates select="$bibinfo/editor" mode="article-info"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\date{</xsl:text><xsl:apply-templates select="$bibinfo/date" /><xsl:text>}&#xa;</xsl:text>
</xsl:template>


<!-- ################### -->
<!-- Titles of Divisions -->
<!-- ################### -->

<!-- Section 9.2 of the "titlesec" package has default parameters   -->
<!-- which mimic LaTeX style and spacing.  We use those here, so    -->
<!-- we can integrate an author credit into the heading/title       -->
<!-- before any spacing happens.  Authors are one fontsize smaller, -->
<!-- and placed in the optional "after-code" argument.              -->
<!-- We provide variants for the "numberless" case, which are only  -->
<!-- primarily necessary for chapter-level items (eg "preface"),    -->
<!-- but might also occur due to one-count specialized divisions,   -->
<!-- present in "unstructured" divisions. "chapter" has a "display" -->
<!-- format, to mimic the LaTeX two-line look, even for multiline   -->
<!-- titles.  For finer divisions, when numbered, we use a "hang"   -->
<!-- format, so any extra lines begin aligned with the first line   -->
<!-- (whether they are authored-too long and then wtap, or if       -->
<!-- structured with a "line" element and so earning dedicated "\\" -->
<!-- automatically.  For "numberless" variants the "block" shape    -->
<!-- seems sufficient as there is no label.  If more elaborate      -->
<!-- styling is employed, it may be necessary to put titles into    -->
<!-- "minipage" environments, or other LaTex boxes                  -->
<!-- NB: since have elected to use the "explicit" package option    -->
<!-- of titlesec, we need to *explicity* place a parameter #1.      -->
<!-- This will allow maximum flexibility for style writers.         -->
<!-- Simple use (as here) will be as the last thing in the          -->
<!-- "before-code" argument.                                        -->
<!-- TODO: integrate "epigraph" package perhaps                     -->

<!-- This is adapted from the chapter format, and   -->
<!-- could be simpler than desired, specifically    -->
<!--   * no "number-less" version                   -->
<!--   * no \titlespacing needed for full page      -->
<!--   * author placement is untested               -->
<!--   * otherwise, jut a bit grander, and centered -->
<!-- There must be a  \titleformat{\part}  to get   -->
<!-- consistent entries in the ToC files            -->
<xsl:template name="titlesec-part-style">
    <xsl:text>\titleformat{\part}[display]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\Huge\bfseries\centering}{\divisionnameptx\space\thepart}{30pt}{\Huge#1}&#xa;</xsl:text>
    <xsl:text>[{\Large\centering\authorsptx}]&#xa;</xsl:text>
</xsl:template>

<!-- Note the use of "\divisionnameptx" macro              -->
<!-- A multiline title should be fine in a "display" shape -->
<xsl:template name="titlesec-chapter-style">
    <xsl:text>\titleformat{\chapter}[display]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\huge\bfseries}{\divisionnameptx\space\thechapter}{20pt}{\Huge#1}&#xa;</xsl:text>
    <xsl:text>[{\Large\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titleformat{name=\chapter,numberless}[display]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\huge\bfseries}{}{0pt}{#1}&#xa;</xsl:text>
    <xsl:text>[{\Large\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titlespacing*{\chapter}{0pt}{50pt}{40pt}&#xa;</xsl:text>
</xsl:template>

<!-- Refences, and especially Index, are unnumbered -->
<!-- section-level items in the back matter         -->
<xsl:template name="titlesec-section-style">
    <xsl:text>\titleformat{\section}[hang]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\Large\bfseries}{\thesection}{1ex}{#1}&#xa;</xsl:text>
    <xsl:text>[{\large\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titleformat{name=\section,numberless}[block]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\Large\bfseries}{}{0pt}{#1}&#xa;</xsl:text>
    <xsl:text>[{\large\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titlespacing*{\section}{0pt}{3.5ex plus 1ex minus .2ex}{2.3ex plus .2ex}&#xa;</xsl:text>
</xsl:template>

<xsl:template name="titlesec-subsection-style">
    <xsl:text>\titleformat{\subsection}[hang]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\large\bfseries}{\thesubsection}{1ex}{#1}&#xa;</xsl:text>
    <xsl:text>[{\normalsize\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titleformat{name=\subsection,numberless}[block]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\large\bfseries}{}{0pt}{#1}&#xa;</xsl:text>
    <xsl:text>[{\normalsize\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titlespacing*{\subsection}{0pt}{3.25ex plus 1ex minus .2ex}{1.5ex plus .2ex}&#xa;</xsl:text>
</xsl:template>

<xsl:template name="titlesec-subsubsection-style">
    <xsl:text>\titleformat{\subsubsection}[hang]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\normalsize\bfseries}{\thesubsubsection}{1em}{#1}&#xa;</xsl:text>
    <xsl:text>[{\small\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titleformat{name=\subsubsection,numberless}[block]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\normalsize\bfseries}{}{0pt}{#1}&#xa;</xsl:text>
    <xsl:text>[{\normalsize\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titlespacing*{\subsubsection}{0pt}{3.25ex plus 1ex minus .2ex}{1.5ex plus .2ex}&#xa;</xsl:text>
</xsl:template>

<!-- We stick with LaTeX names for the hierarchy, so "paragraph" is next. -->
<!-- This will be used for single (hence numberless only) specialized     -->
<!-- divisions (e.g. "exercises") contained within a PTX subsubsection.   -->
<xsl:template name="titlesec-paragraph-style">
    <xsl:text>\titleformat{\paragraph}[hang]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\normalsize\bfseries}{\theparagraph}{1em}{#1}&#xa;</xsl:text>
    <xsl:text>[{\small\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titleformat{name=\paragraph,numberless}[block]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\normalsize\bfseries}{}{0pt}{#1}&#xa;</xsl:text>
    <xsl:text>[{\normalsize\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titlespacing*{\paragraph}{0pt}{3.25ex plus 1ex minus .2ex}{1.5em}&#xa;</xsl:text>
</xsl:template>

<!-- ################# -->
<!-- Table of Contents -->
<!-- ################# -->

<!-- Like division headings, the entries of the Table of -->
<!-- Contents can be styled on a per-division basis      -->

<!-- As normally written into LaTeX's *.toc file, the Roman     -->
<!-- number/label is tightly bound to the title and so it       -->
<!-- would be  the "number-less" argument in control.  Instead, -->
<!-- we load the  titlesec  package with the "newparttoc"       -->
<!-- option and get ToC entries that use LaTeX's "\numberline"  -->
<!-- macro, and so look to  titlesec  as numbered divisions.    -->
<!-- Hence the formatting here is the numbered argument.        -->
<!--                                                            -->
<!-- We drop page numbers for the parts as being redundant,     -->
<!-- since there *must* be a chapter starting on the next page. -->
<xsl:template name="titletoc-part-style">
    <xsl:text>\titlecontents{part}%&#xa;</xsl:text>
    <xsl:text>[0pt]{\contentsmargin{0em}\addvspace{1pc}\contentsfont\bfseries}%&#xa;</xsl:text>
    <xsl:text>{\Large\thecontentslabel\enspace}{\Large}%&#xa;</xsl:text>
    <xsl:text>{}%&#xa;</xsl:text>
    <xsl:text>[\addvspace{.5pc}]%&#xa;</xsl:text>
</xsl:template>

<!-- This should be mostly self-explanatory -->
<xsl:template name="titletoc-chapter-style">
    <xsl:text>\titlecontents{chapter}%&#xa;</xsl:text>
    <xsl:text>[0pt]{\contentsmargin{0em}\addvspace{1pc}\contentsfont\bfseries}%&#xa;</xsl:text>
    <xsl:text>{\large\thecontentslabel\enspace}{\large}%&#xa;</xsl:text>
    <xsl:text>{\hfill\bfseries\thecontentspage}%&#xa;</xsl:text>
    <xsl:text>[\addvspace{.5pc}]%&#xa;</xsl:text>
</xsl:template>

<!-- The indent, and space for the number/label are straight  -->
<!-- from the  titletoc  documentation, which says they match -->
<!-- the LaTeX  book  class                                   -->
<xsl:template name="titletoc-section-style">
    <xsl:text>\dottedcontents{section}[3.8em]{\contentsfont}{2.3em}{1pc}%&#xa;</xsl:text>
</xsl:template>

<!-- The indent, and space for the number/label are straight  -->
<!-- from the  titletoc  documentation, which says they match -->
<!-- the LaTeX  book  class                                   -->
<xsl:template name="titletoc-subsection-style">
    <xsl:text>\dottedcontents{subsection}[6.1em]{\contentsfont}{3.2em}{1pc}%&#xa;</xsl:text>
</xsl:template>

<!-- Each successive indent is increased by the maximum width -->
<!-- of the preceding label, so we just continue that pattern -->
<xsl:template name="titletoc-subsubsection-style">
    <xsl:text>\dottedcontents{subsubsection}[9.3em]{\contentsfont}{4.3em}{1pc}%&#xa;</xsl:text>
</xsl:template>

<!-- ############################ -->
<!-- Page Styles, Headers/Footers -->
<!-- ############################ -->

<!-- These definitions are just default LaTeX.  Why?  To insert the    -->
<!-- \pagefont font-change command into just the right places          -->
<!-- (later we can add color).                                         -->
<!--                                                                   -->
<!-- In more general use, make new page styles, or renew the "empty",  -->
<!-- "plain", "headings", and/or "myheadings" styles.  *Always* finish -->
<!-- by declaring a \pagestyle to be in effect.  But note, LaTeX will  -->
<!-- automagically decide some pages are plain or some are empty.  And -->
<!-- if you adjust "headings" or "myheadings" by doing something like  -->
<!-- changing a font, you might want to also change "plain" so that    -->
<!-- the (presumably) simple numbers or other information will be in   -->
<!-- a matching font.                                                  -->

<!-- N.B. This would be a natural place for \geometry{} commands       -->
<!-- N.B. We use an XSL variable to make the LaTeX output specific to  -->
<!-- one-sided or two-sided output.  Conceivably this *could* be done  -->
<!-- with a LaTeX conditional (at the cost of extraneous code)         -->
<!-- NB: the \ifthechapter conditional stops a "Chapter 0"             -->
<!-- appearing in the front matter                                     -->
<!-- NB: titlesec (not titleps) provides \chaptertitlename so that the -->
<!-- LaTeX \chaptername and \appendixname (which we internationalize)  -->
<!-- are used in the right places                                      -->
<!-- N.B. Investigate the "textcase" package for a more capable        -->
<!-- "\MakeTextUppercase" (or similar)                                 -->
<!-- TODO: redefine article, memo, letter correctly                    -->
<xsl:template match="book" mode="titleps-style">
    <xsl:text>%% Plain pages should have the same font for page numbers&#xa;</xsl:text>
    <xsl:text>\renewpagestyle{plain}{%&#xa;</xsl:text>
    <xsl:text>\setfoot{}{\pagefont\thepage}{}%&#xa;</xsl:text>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="not($b-latex-two-sides)">
            <!-- Every "regular" page has number top right -->
            <!-- CHAPTER 8. TITLE                      234 -->
            <xsl:text>%% Single pages as in default LaTeX&#xa;</xsl:text>
            <xsl:text>\renewpagestyle{headings}{%&#xa;</xsl:text>
            <xsl:text>\sethead{\pagefont\slshape\MakeUppercase{\ifthechapter{\chaptertitlename\space\thechapter.\space}{}\chaptertitle}}{}{\pagefont\thepage}%&#xa;</xsl:text>
            <xsl:text>}%&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$b-latex-two-sides">
            <!-- Two-page spread:  (Section empty if not in use)           -->
            <!-- 234       CHAPTER 8. TITLE || SECTION 8.4 TITLE       235 -->
            <xsl:text>%% Two-page spread as in default LaTeX&#xa;</xsl:text>
            <xsl:text>\renewpagestyle{headings}{%&#xa;</xsl:text>
            <xsl:text>\sethead%&#xa;</xsl:text>
            <xsl:text>[\pagefont\thepage]%&#xa;</xsl:text>
            <xsl:text>[]&#xa;</xsl:text>
            <xsl:text>[\pagefont\slshape\MakeUppercase{\ifthechapter{\chaptertitlename\space\thechapter.\space}{}\chaptertitle}]%&#xa;</xsl:text>
            <!-- LaTeX book style lacks  \sectionname                                                -->
            <!-- 2022-12-14: we tried our own \sectionnameptx but it was not satisfactory            -->
            <!--   (a) need to handle specialized divisions at the section level                     -->
            <!--   (b) still got mismatches like running head with "References 2.6 Exercises"        -->
            <!--       (where the 2.6 is for the Exercises, but 2.7 on the same page is "references" -->
            <xsl:text>{\pagefont\slshape\MakeUppercase{\ifthesection{\thesection.\space\sectiontitle}{}}}%&#xa;</xsl:text>
            <xsl:text>{}%&#xa;</xsl:text>
            <xsl:text>{\pagefont\thepage}%&#xa;</xsl:text>
            <xsl:text>}%&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>\pagestyle{headings}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="article|letter|memo" mode="titleps-style">
    <xsl:text>\pagestyle{plain}&#xa;</xsl:text>
</xsl:template>


<!-- "half-title" is leading page with -->
<!-- title only, at about 1:2 split    -->
<xsl:template match="book" mode="half-title-ad-card" >
    <xsl:text>%% begin: half-title&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:text>{\titlepagefont\centering&#xa;</xsl:text>
    <xsl:text>\vspace*{0.28\textheight}&#xa;</xsl:text>
    <xsl:text>{\Huge </xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}\\</xsl:text> <!-- always end line inside centering -->
    <xsl:if test="subtitle">
        <xsl:text>[2\baselineskip]&#xa;</xsl:text> <!-- extend line break if subtitle -->
        <xsl:text>{\LARGE </xsl:text>
        <xsl:apply-templates select="." mode="subtitle"/>
        <xsl:text>}\\&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text> <!-- finish centering, title page font -->
    <xsl:text>\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   half-title&#xa;</xsl:text>
    <!-- ad-card may very well be blank, and otherwise -->
    <!-- requires some customization                   -->
    <xsl:variable name="the-ad-card">
        <xsl:apply-templates select="." mode="ad-card"/>
    </xsl:variable>
    <xsl:choose>
        <!-- Additional page for non-empty ad-card, -->
        <!-- sideness is irrelevant                 -->
        <xsl:when test="not($the-ad-card = '')">
            <xsl:text>%% begin: adcard&#xa;</xsl:text>
            <xsl:value-of select="$the-ad-card"/>
            <xsl:text>\clearpage&#xa;</xsl:text>
            <xsl:text>%% end:   adcard&#xa;</xsl:text>
        </xsl:when>
        <!-- need an empty page, obverse of half-title    -->
        <!-- could also be left-side of title page spread -->
        <xsl:when test="($b-latex-two-sides) or ($latex-open-odd = 'add-blanks')">
            <xsl:text>%% begin: adcard (empty)&#xa;</xsl:text>
            <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
            <xsl:text>\null%&#xa;</xsl:text>
            <xsl:text>\clearpage&#xa;</xsl:text>
            <xsl:text>%% end:   adcard (empty)&#xa;</xsl:text>
        </xsl:when>
        <!-- no content, and one-sided, do nothing -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:template>

<!-- Ad card is the obverse of half-title, and may contain a list -->
<!-- of other books by the author, or in a two-sided version, it  -->
<!-- can be used as the left-side of a title page spread.  Send   -->
<!-- a feature request if you need/want both. This template is as -->
<!-- a hook meant to be overidden as part of custom XSL provided  -->
<!-- by a knowledgeable publisher, so empty in typical use.  When -->
<!-- overridden, it should produce a complete page, but without   -->
<!-- a \clearpage at the bottom, that happens automatically.      -->
<!-- The macro \titlepagefont can be used (scoped to the page)    -->
<!-- for harmony with the actual title page, which appears next.  -->
<xsl:template match="book" mode="ad-card"/>

<!-- LaTeX's title page is not very robust, so we totally redo it         -->
<!-- Template produces a single page, followed by a \clearpage            -->
<!-- Customize with an override of this template in an imported stylesheet -->
<!-- For a two-page spread, consider modifying the "ad-card" template     -->
<!-- For "\centering" to work properly, obey the following scheme:              -->
<!-- Each group, but first, should begin with [<length>]&#xa; as vertical break -->
<!-- Each group, should end with only \\ as prelude to vertical break           -->
<xsl:template match="book" mode="title-page">
    <xsl:text>%% begin: title page&#xa;</xsl:text>
    <xsl:text>%% Inspired by Peter Wilson's "titleDB" in "titlepages" CTAN package&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:text>{\titlepagefont\centering&#xa;</xsl:text>
    <xsl:text>\vspace*{0.14\textheight}&#xa;</xsl:text>
    <!-- Target for xref to top-level element -->
    <!-- immediately, or first in ToC         -->
    <xsl:choose>
        <xsl:when test="$b-has-toc">
            <!-- N.B.  A font change command for the entire ToC -->
            <!-- could be inserted here with something like     -->
            <!--   \addtocontents{toc}{\protect\contentsfont}   -->
            <!-- but I wanted to document it in place and could -->
            <!-- not determine how to add a comment into the    -->
            <!-- *.toc file.  Perhaps best to just employ the   -->
            <!-- font in the  titletoc  style templates anyway. -->
            <xsl:text>%% Target for xref to top-level element is ToC&#xa;</xsl:text>
            <xsl:text>\addtocontents{toc}{</xsl:text>
            <xsl:if test="$b-pageref">
                <xsl:text>\protect\label{</xsl:text>
                <xsl:apply-templates select="." mode="unique-id" />
                <xsl:text>}</xsl:text>
            </xsl:if>
            <xsl:text>\protect\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="unique-id" />
            <xsl:text>}{}</xsl:text>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>%% Target for xref to top-level element is document start&#xa;</xsl:text>
            <xsl:if test="$b-pageref">
                <xsl:text>\label{</xsl:text>
                <xsl:apply-templates select="." mode="unique-id" />
                <xsl:text>}</xsl:text>
            </xsl:if>
            <xsl:text>\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="unique-id" />
            <xsl:text>}{}&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>{\Huge </xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}\\</xsl:text> <!-- end line inside centering -->
    <xsl:if test="subtitle">
        <xsl:text>[\baselineskip]&#xa;</xsl:text>  <!-- extend if subtitle -->
        <xsl:text>{\LARGE </xsl:text>
        <xsl:apply-templates select="." mode="subtitle" />
        <xsl:text>}\\</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="frontmatter/titlepage/titlepage-items" />
    <xsl:text>}&#xa;</xsl:text> <!-- finish centering, titlepage font -->
    <xsl:text>\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   title page&#xa;</xsl:text>
</xsl:template>

<xsl:template match="titlepage-items">
    <xsl:apply-templates select="$bibinfo/author" mode="title-page"/>
    <xsl:apply-templates select="$bibinfo/editor" mode="title-page" />
    <xsl:apply-templates select="$bibinfo/credit[title]" mode="title-page" />
    <xsl:apply-templates select="$bibinfo/date"   mode="title-page" />
</xsl:template>

<xsl:template match="author|editor" mode="title-page">
    <xsl:text>[3\baselineskip]&#xa;</xsl:text>
    <xsl:text>{\Large </xsl:text>
    <xsl:apply-templates select="personname" />
    <xsl:if test="self::editor">
        <xsl:text>, </xsl:text>
        <xsl:apply-templates select="." mode="type-name"/>
    </xsl:if>
    <xsl:text>}\\</xsl:text>
    <xsl:if test="affiliation/institution">
        <xsl:text>[0.5\baselineskip]&#xa;</xsl:text>
        <xsl:text>{\Large </xsl:text>
        <xsl:apply-templates select="affiliation/institution" />
        <xsl:text>}\\</xsl:text>
    </xsl:if>
</xsl:template>

<!-- One "title" per-credit, but multiple authors are OK -->
<xsl:template match="credit" mode="title-page">
    <xsl:text>[3\baselineskip]&#xa;</xsl:text>
    <xsl:text>{\Large </xsl:text>
    <xsl:apply-templates  select="." mode="title-full" />
    <xsl:text>}\\[0.5\baselineskip]&#xa;</xsl:text>
    <xsl:for-each select="author">
        <xsl:text>{\normalsize </xsl:text>
        <xsl:apply-templates select="personname" />
        <xsl:text>}\\</xsl:text>
        <xsl:if test="affiliation/institution">
            <xsl:text>[0.25\baselineskip]&#xa;</xsl:text>
            <xsl:apply-templates select="affiliation/institution" />
            <xsl:text>\\</xsl:text>
        </xsl:if>
        <xsl:if test="following-sibling::author">
            <xsl:text>[0.5\baselineskip]&#xa;</xsl:text>
        </xsl:if>
        <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>
</xsl:template>

<xsl:template match="date" mode="title-page">
    <xsl:text>[3\baselineskip]&#xa;</xsl:text>
    <xsl:text>{\Large </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}\\</xsl:text>
</xsl:template>

<!-- Copyright page is obverse of title page    -->
<!-- Lots of stuff here, much of it optional    -->
<!-- But we assume an author eventually states  -->
<!-- their copyright, so do not handle the case -->
<!-- of this content ever being empty (such as  -->
<!-- with the ad-card).  So a LaTeX label is OK -->
<!-- as well.  A final "\null" is just          -->
<!-- protection for a non-mature project.       -->
<xsl:template match="book" mode="copyright-page" >
    <!-- TODO: split out sections like "website" -->
    <!-- ISBN, Cover Design, Publisher -->
    <xsl:text>%% begin: copyright-page&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <!-- This is the most obvious place for   -->
    <!-- a target to the front colophon       -->
    <!-- NB: only a book has a front colophon -->
    <xsl:apply-templates select="frontmatter/colophon" mode="label" />
    <xsl:if test="not(../docinfo/author-biographies/@length = 'long')">
        <xsl:apply-templates select="frontmatter/biography" mode="copyright-page" />
    </xsl:if>
    <xsl:text>\vspace*{\stretch{2}}&#xa;</xsl:text>

    <xsl:if test="$bibinfo/credit[role]">
        <xsl:text>\par\noindent&#xa;</xsl:text>
    </xsl:if>
    <!-- We accomodate multiple "credit" with a context shift -->
    <xsl:for-each select="$bibinfo/credit[role]">
        <xsl:text>\textbf{</xsl:text>
        <xsl:apply-templates select="role" />
        <xsl:text>}:\ \ </xsl:text>
        <xsl:apply-templates select="entity" />
        <xsl:if test="following-sibling::credit">
            <xsl:text>\\</xsl:text>
        </xsl:if>
        <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>
    <xsl:if test="$bibinfo/credit[role]">
        <xsl:text>\par\vspace*{\stretch{2}}&#xa;</xsl:text>
    </xsl:if>

    <!-- A book cannot be multiple editions, and if -->
    <!-- attempted this will produce a mish-mash.   -->
    <xsl:if test="$bibinfo/edition" >
        <xsl:text>\noindent{\bfseries </xsl:text>
        <xsl:apply-templates select="$bibinfo/edition" mode="type-name"/>
        <xsl:text>}: </xsl:text>
        <xsl:apply-templates select="$bibinfo/edition" />
        <xsl:text>\par\medskip&#xa;</xsl:text>
    </xsl:if>

    <!-- We accomodate zero to many "website". -->
    <xsl:apply-templates select="$bibinfo/website"/>

    <!-- There may be multiple copyrights (a fork under the GFDL -->
    <!-- requires as much).  This accomodates zero to many.  The -->
    <!-- "for-each" enacts a context shift so we know we are     -->
    <!-- mining one "copyright" element at a time.               -->
    <xsl:for-each select="$bibinfo/copyright">
        <xsl:text>\noindent</xsl:text>
        <xsl:call-template name="copyright-character"/>
        <xsl:apply-templates select="year" />
        <xsl:text>\quad{}</xsl:text>
        <xsl:apply-templates select="holder" />
        <xsl:if test="shortlicense">
            <xsl:text>\\[0.5\baselineskip]&#xa;</xsl:text>
            <xsl:apply-templates select="shortlicense" />
        </xsl:if>
        <xsl:text>\par\medskip&#xa;</xsl:text>
    </xsl:for-each>

    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <!-- Add support statement from bibinfo if present. -->
    <xsl:if test="$bibinfo/support">
        <xsl:apply-templates select="$bibinfo/support" mode="copyright-page"/>
    </xsl:if>
    <!-- Something so page is not totally nothing -->
    <xsl:text>\null\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   copyright-page&#xa;</xsl:text>
</xsl:template>

<!-- Only for a book with a colophon, we put the statement of support at the bottom of the colophon -->
<xsl:template match="bibinfo/support" mode="copyright-page">
    <xsl:text>%% Funding/Support statement:</xsl:text>
    <xsl:text>\par\medskip&#xa;</xsl:text>
    <xsl:text>\noindent{}</xsl:text>
    <xsl:apply-templates select="*" />
    <xsl:text>\par&#xa;</xsl:text>
    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
</xsl:template>

<!-- URL for canonical project website -->
<xsl:template match="frontmatter/bibinfo/website">
    <xsl:text>\noindent{\bfseries </xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>}: </xsl:text>
    <!-- NB: interior of "website" is a "url" in author's -->
    <!-- source, but the pre-processor adds a footnote    -->
    <!-- Only one presumed, and thus enforced here        -->
    <xsl:apply-templates select="url[1]|fn[1]" />
    <xsl:text>\par\medskip&#xa;</xsl:text>
</xsl:template>


<!-- Author biographies -->
<!-- Verso of title page, we call this the front colophon -->
<!-- Title is optional, presumably for a single author    -->
<xsl:template match="biography" mode="copyright-page">
    <xsl:if test="preceding-sibling::*[self::biography]">
        <xsl:text>\bigskip</xsl:text>
    </xsl:if>
    <xsl:text>\noindent</xsl:text>
    <xsl:if test="title">
        <xsl:text>\textbf{</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>}\space\space</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <!-- drop a par, for next bio, or for big vspace -->
    <xsl:text>\par&#xa;</xsl:text>
</xsl:template>

<!-- ###################### -->
<!-- Front Matter, Articles -->
<!-- ###################### -->

<!-- The DTD should enforce order(titlepage|abstract) -->
<!-- An optional ToC follows and is final decoration  -->
<xsl:template match="article/frontmatter">
    <xsl:apply-templates select="titlepage|abstract" />
    <xsl:if test="$latex-toc-level > 0">
        <xsl:text>%% Adjust Table of Contents&#xa;</xsl:text>
        <xsl:text>\setcounter{tocdepth}{</xsl:text>
        <xsl:value-of select="$latex-toc-level" />
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\renewcommand*\contentsname{</xsl:text>
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'toc'"/>
        </xsl:apply-templates>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\tableofcontents&#xa;</xsl:text>
        <xsl:text>\clearpage&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Title information handling is a bit ad-hoc                        -->
<!-- We should perhaps roll-our-own here                               -->
<!-- Instead we assume the title-page-info-article has set *something* -->
<!-- NB: it is possible for there to be no article/title               -->
<xsl:template match="article/frontmatter/titlepage">
    <xsl:text>\maketitle&#xa;</xsl:text>
    <!-- If a title, we know it is page 1, so use empty style -->
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
</xsl:template>

<!-- Articles may have an abstract in the frontmatter. We -->
<!-- accept the LaTeX article class approach and switch   -->
<!-- to a localization of the heading just prior to use.  -->
<!-- Keywords are placed inside the abstract, at the end. -->
<xsl:template match="article/frontmatter/abstract">
    <xsl:text>\renewcommand*{\abstractname}{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\begin{abstract}&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:if test="$bibinfo/keywords">
        <xsl:apply-templates select="$bibinfo/keywords"/>
    </xsl:if>
    <xsl:text>\end{abstract}&#xa;</xsl:text>
</xsl:template>

<!-- ################### -->
<!-- Front Matter, Books -->
<!-- ################### -->

<!-- The <colophon> portion of <frontmatter> generally  -->
<!-- gets mined to migrate various places, so we kill   -->
<!-- it as part of processing the front matter element. -->
<!-- Author biography migrates to the obverse of the    -->
<!-- copyright page in LaTeX, sans any provided title.  -->
<!-- So we kill this part of the front matter as        -->
<!-- a section of its own.  (In HTML the material       -->
<!-- is its own titled division).                       -->
<xsl:template match="book/frontmatter">
    <!-- DTD: does the next line presume <frontmatter> is required? -->
    <xsl:text>\frontmatter&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::colophon or self::biography)]" />
    <xsl:text>%% begin: table of contents&#xa;</xsl:text>
    <xsl:if test="$latex-toc-level > -1">
        <xsl:text>%% Adjust Table of Contents&#xa;</xsl:text>
        <xsl:text>\setcounter{tocdepth}{</xsl:text>
        <xsl:value-of select="$latex-toc-level" />
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\renewcommand*\contentsname{</xsl:text>
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'toc'"/>
        </xsl:apply-templates>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\tableofcontents&#xa;</xsl:text>
        <xsl:text>%% end:   table of contents&#xa;</xsl:text>
    </xsl:if>
    <!-- Potentially: list of illustrations, etc.     -->
    <!-- Potentially: introduction, second half-title -->
    <!-- if we have a \frontmatter, we must end it with \mainmatter -->
    <xsl:text>\mainmatter&#xa;</xsl:text>
</xsl:template>

<!-- A huge decoration, spanning many pages             -->
<!-- Not structural, titlepage element is just a signal -->
<!-- Includes items from the colophon                   -->
<xsl:template match="book/frontmatter/titlepage">
    <!-- first page, half-title only; obverse -->
    <!-- of half-title is possible adcard     -->
    <xsl:apply-templates select="../.." mode="half-title-ad-card" />
    <!-- title page -->
    <xsl:apply-templates select="../.." mode="title-page" />
    <!-- title page obverse is copyright, assumed non-empty -->
    <xsl:apply-templates select="../.." mode="copyright-page" />
    <!-- long biographies come earliest, since normally on copyright page -->
    <!-- short biographies are part of the copyright-page template        -->
    <xsl:if test="$docinfo/author-biographies/@length = 'long' and ../biography">
        <xsl:apply-templates select="../.." mode="author-biography-subdivision" />
    </xsl:if>
</xsl:template>

<xsl:template match="book" mode="author-biography-subdivision">
    <xsl:variable name="number-authors" select="count(frontmatter/biography)" />
    <xsl:variable name="title-string">
        <xsl:choose>
            <xsl:when test="$number-authors > 1">
                <xsl:apply-templates select="frontmatter" mode="type-name">
                    <xsl:with-param name="string-id" select="'about-authors'"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="frontmatter" mode="type-name">
                    <xsl:with-param name="string-id" select="'about-author'"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>%% begin: author biography (long)&#xa;</xsl:text>
    <xsl:text>\chapter*{</xsl:text>
    <xsl:value-of select="$title-string" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\addcontentsline{toc}{chapter}{</xsl:text>
    <xsl:value-of select="$title-string" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="$number-authors > 1">
            <xsl:apply-templates select="frontmatter/biography" mode="biography-subdivision" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:if test="frontmatter/biography/title">
                <xsl:text>\section*{</xsl:text>
                <xsl:apply-templates select="frontmatter/biography" mode="title-full" />
                <xsl:text>}&#xa;</xsl:text>
            </xsl:if>
            <!-- else don't bother titling-->
            <xsl:apply-templates select="frontmatter/biography/*" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\cleardoublepage</xsl:text>
    <xsl:text>%% end: author biography (long)&#xa;</xsl:text>
</xsl:template>

<xsl:template match="biography" mode="biography-subdivision">
    <xsl:text>\section*{</xsl:text>
    <xsl:choose>
        <xsl:when test="title">
            <xsl:apply-templates select="." mode="title-full" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>DEFAULT TO FULL NAME HERE</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- Dedication page is very plain, with a blank obverse     -->
<!-- Accomodates multiple recipient (eg if multiple authors) -->
<xsl:template match="dedication">
    <xsl:text>%% begin: dedication-page&#xa;</xsl:text>
    <xsl:text>\cleardoublepage&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <!-- paragraphs only, one per dedication -->
    <xsl:apply-templates select="p"/>
    <xsl:text>\vspace*{\stretch{2}}&#xa;</xsl:text>
    <xsl:text>\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   dedication-page&#xa;</xsl:text>
    <xsl:if test="$b-latex-two-sides">
        <xsl:text>%% begin: obverse-dedication-page (empty)&#xa;</xsl:text>
        <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
        <xsl:text>\null%&#xa;</xsl:text>
        <xsl:text>\clearpage&#xa;</xsl:text>
        <xsl:text>%% end:   obverse-dedication-page (empty)&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Dedications are meant to be very short      -->
<!-- so are each a single paragraph and          -->
<!-- are centered on a page of their own         -->
<!-- The center environment provides good        -->
<!-- vertical break between multiple instances   -->
<!-- Each "p" may be structured by "line"        -->
<!-- The p[1] elsewhere is the default,          -->
<!-- hence we use the priority mechanism (>0.5)  -->
<xsl:template match="dedication/p|dedication/p[1]" priority="1">
    <xsl:text>\begin{center}\Large%&#xa;</xsl:text>
        <xsl:apply-templates/>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\end{center}&#xa;</xsl:text>
</xsl:template>


<!-- ##################### -->
<!-- Front Matter, Letters -->
<!-- ##################### -->

<xsl:template match="letter/frontmatter">
    <!-- Logos (letterhead images) immediately -->
    <xsl:apply-templates select="$docinfo/logo" />
    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <!-- Push down some on first page to accomodate letterhead -->
    <xsl:text>\vspace*{0.75in}&#xa;</xsl:text>
    <!-- Stretchy vertical space if page 1 does not fill -->
    <xsl:text>\vspace*{\stretch{1}}&#xa;%&#xa;</xsl:text>
    <!-- Sender's address, sans name typically -->
    <!-- and if not already on letterhead      -->
    <!-- Structured as lines, always           -->
    <!-- http://tex.stackexchange.com/questions/13542/flush-a-left-flushed-box-right -->
    <xsl:if test="from or date">
        <xsl:text>\hfill\begin{tabular}{l@{}}&#xa;</xsl:text>
        <xsl:if test="from">
            <xsl:apply-templates select="from/line" />
            <xsl:if test="date">
                <!-- end from -->
                <xsl:text>\\&#xa;</xsl:text>
                <!-- introduce a blank line -->
                <xsl:text>\mbox{}\\&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
        <!-- Date -->
        <xsl:if test="date">
            <xsl:apply-templates select="date" />
        </xsl:if>
        <xsl:text>&#xa;\end{tabular}\\\par&#xa;</xsl:text>
    </xsl:if>
    <!-- Destination address, flush left -->
    <!-- Structured as lines, always     -->
    <xsl:if test="to">
        <xsl:text>\noindent{}</xsl:text>
        <xsl:apply-templates select="to/line" />
        <xsl:text>\\\par</xsl:text>
        <!-- extra comment line before salutation/body -->
        <xsl:text>&#xa;%&#xa;</xsl:text>
    </xsl:if>
    <!-- Salutation, flush left                   -->
    <!-- No punctuation (author's responsibility) -->
    <xsl:if test="salutation">
        <xsl:text>\noindent{}</xsl:text>
        <xsl:apply-templates select="salutation" />
        <xsl:text>\\\par</xsl:text>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Final lines of from/to address get treated carefully above -->
<!-- Differentiate from memo versions                           -->
<xsl:template match="letter/frontmatter/from/line|letter/frontmatter/to/line">
    <xsl:apply-templates/>
    <!-- is there a following line to separate? -->
    <xsl:if test="following-sibling::*">
        <xsl:text>\\&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- ################### -->
<!-- Front Matter, Memos -->
<!-- ################### -->

<xsl:template match="memo/frontmatter">
    <xsl:text>\thispagestyle{empty}&#xa;%&#xa;</xsl:text>
    <!-- Logos (letterhead images) to first page -->
    <xsl:apply-templates select="$docinfo/logo" />
    <!-- Get width of widest out-dented text -->
    <xsl:text>\newlength{\ptxsubjectwidth}&#xa;</xsl:text>
    <xsl:text>\settowidth{\ptxsubjectwidth}{\textsf{Subject:}}&#xa;</xsl:text>
    <!-- Push down some on first page to accomodate letterhead -->
    <xsl:text>\vspace*{0.75in}&#xa;</xsl:text>
    <!-- Outdent experimentally, scales well at 10pt, 11pt, 12pt -->
    <!-- Control separation                                      -->
    <xsl:text>\hspace*{-1.87\ptxsubjectwidth}%&#xa;</xsl:text>
    <xsl:text>{\setlength{\tabcolsep}{1ex}%&#xa;</xsl:text>
    <!-- Second column at textwidth is slightly too much -->
    <xsl:text>\begin{tabular}{rp{0.97\textwidth}}&#xa;</xsl:text>
    <xsl:text>\textsf{To:}</xsl:text>
    <xsl:choose>
        <!-- multiline structured -->
        <xsl:when test="to/line">
            <xsl:apply-templates select="to/line" />
        </xsl:when>
        <!-- always a newline, even if blank -->
        <xsl:otherwise>
            <xsl:text>&amp;</xsl:text>
            <xsl:apply-templates select="to" />
            <xsl:text>\\&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\textsf{From:}</xsl:text>
    <xsl:choose>
        <!-- multiline structured -->
        <xsl:when test="from/line">
            <xsl:apply-templates select="from/line" />
        </xsl:when>
        <!-- always a newline, even if blank -->
        <xsl:otherwise>
            <xsl:text>&amp;</xsl:text>
            <xsl:apply-templates select="from" />
            <xsl:text>\\&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\textsf{Date:}&amp;</xsl:text>
    <xsl:apply-templates select="date" /><xsl:text>\\&#xa;</xsl:text>
    <xsl:text>\textsf{Subject:}&amp;</xsl:text>
    <xsl:apply-templates select="subject" /><xsl:text>&#xa;</xsl:text>
    <xsl:text>\end{tabular}%&#xa;</xsl:text>
    <xsl:text>}%&#xa;</xsl:text>
    <!-- And drop a bit -->
    <xsl:text>\par\bigskip&#xa;</xsl:text>
</xsl:template>

<!-- Differentiate from letter versions -->
<xsl:template match="memo/frontmatter/from/line|memo/frontmatter/to/line">
    <xsl:text>&amp;</xsl:text>
    <xsl:apply-templates/>
    <!-- part of a big block, use newline everywhere -->
    <xsl:text>\\&#xa;</xsl:text>
</xsl:template>

<!-- A graphic with a scan of the author's initials: used within -->
<!-- the "from" of a "memo" (or within a "line" of "from") to    -->
<!-- initial the memo near the sender's name, as a mark of       -->
<!-- authorization.  The "@source" attribute names the graphics  -->
<!-- file.  The height is scaled to just avoid disrupting line   -->
<!-- spacing, and placement is inline (so, no carriage returns   -->
<!-- in the output).  Small amounts of negative space (0.75ex)   -->
<!-- precede and follow the graphic, so extra horizontal space   -->
<!-- may need to be inserted directly in the source (\, or \ ).  -->
<!-- NB: "initial" is not presently in the schema.               -->
<xsl:template match="initial">
  <xsl:text>\hspace*{-0.75ex}{}</xsl:text>
  <xsl:text>\raisebox{0.2\baselineskip}{\includegraphics[height=0.55\baselineskip]{</xsl:text>
  <xsl:apply-templates select="@source" />
  <xsl:text></xsl:text>
  <xsl:text>}}\hspace*{-0.75ex}{}</xsl:text>
</xsl:template>

<!-- #################### -->
<!-- Back Matter, Letters -->
<!-- #################### -->

<xsl:template match="letter/backmatter">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:if test="closing">
        <xsl:text>\par&#xa;</xsl:text>
        <xsl:text>\vspace*{1.5\baselineskip}\noindent&#xa;</xsl:text>
        <xsl:text>\hspace{\stretch{2}}&#xa;</xsl:text>
        <xsl:text>\begin{tabular}{l@{}}&#xa;</xsl:text>
        <xsl:apply-templates select="closing" />
        <xsl:choose>
            <xsl:when test="graphic-signature">
                <xsl:text>\\[1ex]&#xa;</xsl:text>
                <xsl:text>\includegraphics[height=</xsl:text>
                <xsl:choose>
                    <xsl:when test="graphic-signature/@height">
                        <xsl:value-of select="graphic-signature/@height" />
                    </xsl:when>
                    <xsl:otherwise>24pt</xsl:otherwise>
                </xsl:choose>
                <xsl:text>]{</xsl:text>
                <xsl:value-of select="graphic-signature/@source" />
                <xsl:text>}\\[0.5ex]&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!-- About two blank lines for written signature -->
                <xsl:text>\\[5.5ex]&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="signature/line" />
        <xsl:text>&#xa;\end{tabular}&#xa;</xsl:text>
        <xsl:text>\hspace{\stretch{1}}&#xa;</xsl:text>
    </xsl:if>
    <!-- Stretchy vertical space, useful if still on page 1 -->
    <xsl:text>\par\vspace*{\stretch{2}}&#xa;%&#xa;</xsl:text>
</xsl:template>

<!-- Final line of signature get treated carefully above -->
<xsl:template match="signature/line">
    <xsl:apply-templates/>
    <!-- is there a following line to separate? -->
    <xsl:if test="following-sibling::*">
        <xsl:text>\\&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- ################## -->
<!-- Back Matter, Memos -->
<!-- ################## -->

<!-- No such thing yet                -->
<!-- TODO: add "cc" block like to/from -->
<xsl:template match="memo/backmatter" />

<!-- ####################### -->
<!-- Logos (image placements) -->
<!-- ####################### -->

<!-- Fine-grained placement of graphics files on pages      -->
<!-- May be placed anywhere on current page                 -->
<!-- Page coordinates are measured in "true" points         -->
<!-- (72.27 points to the inch)                             -->
<!-- (0,0) is the lower left corner of the page             -->
<!-- llx, lly: places lower-left corner of graphic          -->
<!-- at the specified coordinates of the page               -->
<!-- Use width, in fixed units (eg cm), to optionally scale -->
<!-- pages='first|all' controls repetition, default: first  -->
<xsl:template match="docinfo/logo" >
    <xsl:text>\AddToShipoutPicture</xsl:text>
    <xsl:if test="not(@pages) or @pages='first'">
        <xsl:text>*</xsl:text>
    </xsl:if>
    <xsl:text>{\put(</xsl:text>
    <xsl:value-of select="@llx" />
    <xsl:text>,</xsl:text>
    <xsl:value-of select="@lly" />
    <xsl:text>){\includegraphics</xsl:text>
    <xsl:if test="@width">
        <xsl:text>[width=</xsl:text>
            <xsl:value-of select="@width" />
        <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="@source" />
    <xsl:text>}}}&#xa;</xsl:text>
</xsl:template>

<!-- Exercises and solutions setup -->
<xsl:template name="exercises-and-solutions">
    <xsl:if test="$document-root//solutions or $b-needs-solution-styles">
        <xsl:text>%% begin: environments for duplicates in solutions divisions&#xa;</xsl:text>
        <!-- Solutions present, check for exercise types     -->
        <!-- This may have false positives, but no real harm -->
        <!--  -->
        <!-- solutions to inline exercises -->
        <xsl:if test="$document-root//exercise[boolean(&INLINE-EXERCISE-FILTER;)]">
        <xsl:text>%% Solutions to inline exercises, style and environment&#xa;</xsl:text>
            <xsl:text>\tcbset{ inlinesolutionstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, after title={\space}, breakable, before upper app={\ptxsetparstyle} } }&#xa;</xsl:text>
            <xsl:text>\newtcolorbox{inlinesolution}[4]</xsl:text>
            <xsl:text>{inlinesolutionstyle, title={\hyperref[#4]{#1~#2}\notblank{#3}{\space#3}{}}}&#xa;</xsl:text>
        </xsl:if>
        <!-- Division Solution -->
        <!-- Explicitly breakable, run-in title -->
        <xsl:if test="$document-root//exercises//exercise[not(ancestor::exercisegroup)]|$document-root//worksheet//exercise[not(ancestor::exercisegroup)]|$document-root//reading-questions//exercise[not(ancestor::exercisegroup)]">
            <xsl:text>%% Solutions to division exercises, not in exercise group&#xa;</xsl:text>
            <xsl:text>%% Parameter #1 is type-name and is ignored&#xa;</xsl:text>
            <xsl:text>\tcbset{ divisionsolutionstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, after title={\space}, breakable, before upper app={\ptxsetparstyle} } }&#xa;</xsl:text>
            <xsl:text>\newtcolorbox{divisionsolution}[4]</xsl:text>
            <xsl:text>{divisionsolutionstyle, title={\hyperlink{#4}{#2}.\notblank{#3}{\space#3}{}}}&#xa;</xsl:text>
        </xsl:if>
        <!-- Division Solution, Exercise Group -->
        <!-- Explicitly breakable, run-in title -->
        <xsl:if test="$document-root//exercisegroup[not(@cols)]">
            <xsl:text>%% Solutions to division exercises, in exercise group, no columns&#xa;</xsl:text>
            <xsl:text>%% Parameter #1 is type-name and is ignored&#xa;</xsl:text>
            <xsl:text>\tcbset{ divisionsolutionegstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, after title={\space}, left skip=\ptxegindent, breakable, before upper app={\ptxsetparstyle} } }&#xa;</xsl:text>
            <xsl:text>\newtcolorbox{divisionsolutioneg}[4]</xsl:text>
            <xsl:text>{divisionsolutionegstyle, title={\hyperlink{#4}{#2}.\notblank{#3}{\space#3}{}}}&#xa;</xsl:text>
        </xsl:if>
        <!-- Division Solution, Exercise Group, Columnar -->
        <!-- Explicity unbreakable, to behave in multicolumn tcbraster -->
        <xsl:if test="$document-root//exercisegroup/@cols">
            <xsl:text>%% Solutions to division exercises, in exercise group with columns&#xa;</xsl:text>
            <xsl:text>%% Parameter #1 is type-name and is ignored&#xa;</xsl:text>
            <xsl:text>\tcbset{ divisionsolutionegcolstyle/.style={bwminimalstyle, runintitlestyle,  exercisespacingstyle, after title={\space}, halign=flush left, unbreakable, before upper app={\ptxsetparstyle} } }&#xa;</xsl:text>
            <xsl:text>\newtcolorbox{divisionsolutionegcol}[4]</xsl:text>
            <xsl:text>{divisionsolutionegcolstyle, title={\hyperlink{#4}{#2}.\notblank{#3}{\space#3}{}}}&#xa;</xsl:text>
        </xsl:if>
        <!-- solutions to PROJECT-LIKE -->
        <!-- "project-rep" variable defined twice (each local) -->
        <xsl:variable name="project-reps" select="
            ($document-root//project)[1]|
            ($document-root//activity)[1]|
            ($document-root//exploration)[1]|
            ($document-root//investigation)[1]"/>
        <xsl:for-each select="$project-reps">
            <xsl:variable name="elt-name">
                <xsl:value-of select="local-name(.)"/>
            </xsl:variable>
            <!-- set the style -->
            <xsl:text>\tcbset{ </xsl:text>
            <xsl:value-of select="$elt-name"/>
            <xsl:text>solutionstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, after title={\space}, breakable, before upper app={\ptxsetparstyle} } }&#xa;</xsl:text>
            <!-- create the environment -->
            <xsl:text>\newtcolorbox{</xsl:text>
            <xsl:value-of select="$elt-name"/>
            <xsl:text>solution}[4]</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="$elt-name"/>
            <xsl:text>solutionstyle, title={\hyperref[#4]{#1~#2}\notblank{#3}{\space#3}{}}}&#xa;</xsl:text>
        </xsl:for-each>
    </xsl:if>
    <!-- Generic exercise lead-in -->
    <xsl:if test="$document-root//exercises//exercise|$document-root//worksheet//exercise|$document-root//reading-questions//exercise">
        <xsl:text>%% Divisional exercises (and worksheet) as LaTeX environments&#xa;</xsl:text>
        <xsl:text>%% Third argument is option for extra workspace in worksheets&#xa;</xsl:text>
        <xsl:text>%% Hanging indent occupies a 5ex width slot prior to left margin&#xa;</xsl:text>
        <xsl:text>%% Experimentally this seems just barely sufficient for a bold "888."&#xa;</xsl:text>
    </xsl:if>
    <!-- Division Exercise -->
    <!-- Numbered, styled with a hanging indent -->
    <xsl:if test="$document-root//exercises//exercise[not(ancestor::exercisegroup)]|$document-root//worksheet//exercise[not(ancestor::exercisegroup)]|$document-root//reading-questions//exercise[not(ancestor::exercisegroup)]">
        <xsl:text>%% Division exercises, not in exercise group&#xa;</xsl:text>
        <!-- Outdenting the problem number requires an "\hspace*" to avoid an edge case -->
        <!-- https://tex.stackexchange.com/questions/722329/unwanted-space-in-tcbraster -->
        <!-- https://tex.stackexchange.com/questions/89082/hspace-vs-hspace             -->
        <xsl:text>\tcbset{ divisionexercisestyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, left=5ex, breakable, before upper app={\ptxsetparstyle} } }&#xa;</xsl:text>
        <xsl:text>\newtcolorbox{divisionexercise}[4]</xsl:text>
        <xsl:text>{divisionexercisestyle, before title={\hspace*{-5ex}\makebox[5ex][l]{#1.}}, title={\notblank{#2}{#2}{}}, after title={\notblank{#2}{\space}{}}, phantom={</xsl:text>
        <xsl:if test="$b-pageref">
            <xsl:text>\label{#4}</xsl:text>
        </xsl:if>
        <xsl:text>\hypertarget{#4}{}}, after={\notblank{#3}{\par\rule{\ptxworkspacestrutwidth}{#3}\par\vfill}{\par}}}&#xa;</xsl:text>
    </xsl:if>
    <!-- Division Exercise, Exercise Group -->
    <!-- The exercise itself carries the indentation, hence we can use breakable -->
    <!-- boxes and get good page breaks (as these problems could be long)        -->
    <xsl:if test="$document-root//exercisegroup[not(@cols)]">
        <xsl:text>%% Division exercises, in exercise group, no columns&#xa;</xsl:text>
        <!-- Outdenting the problem number requires an "\hspace*" to avoid an edge case -->
        <!-- https://tex.stackexchange.com/questions/722329/unwanted-space-in-tcbraster -->
        <!-- https://tex.stackexchange.com/questions/89082/hspace-vs-hspace             -->
        <xsl:text>\tcbset{ divisionexerciseegstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, left=5ex, left skip=\ptxegindent, breakable, before upper app={\ptxsetparstyle} } }&#xa;</xsl:text>
        <xsl:text>\newtcolorbox{divisionexerciseeg}[4]</xsl:text>
        <xsl:text>{divisionexerciseegstyle, before title={\hspace*{-5ex}\makebox[5ex][l]{#1.}}, title={\notblank{#2}{#2}{}}, after title={\notblank{#2}{\space}{}}, phantom={</xsl:text>
        <xsl:if test="$b-pageref">
            <xsl:text>\label{#4}</xsl:text>
        </xsl:if>
        <xsl:text>\hypertarget{#4}{}}, after={\notblank{#3}{\par\rule{\ptxworkspacestrutwidth}{#3}\par\vfill}{\par}}}&#xa;</xsl:text>
    </xsl:if>
    <!-- Division Exercise, Exercise Group, Columnar -->
    <!-- Explicity unbreakable, to behave in multicolumn tcbraster -->
    <xsl:if test="$document-root//exercisegroup/@cols">
        <xsl:text>%% Division exercises, in exercise group with columns&#xa;</xsl:text>
        <!-- Outdenting the problem number requires an "\hspace*" to avoid an edge case -->
        <!-- https://tex.stackexchange.com/questions/722329/unwanted-space-in-tcbraster -->
        <!-- https://tex.stackexchange.com/questions/89082/hspace-vs-hspace             -->
        <xsl:text>\tcbset{ divisionexerciseegcolstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, left=5ex, halign=flush left, unbreakable, before upper app={\ptxsetparstyle} } }&#xa;</xsl:text>
        <xsl:text>\newtcolorbox{divisionexerciseegcol}[4]</xsl:text>
        <xsl:text>{divisionexerciseegcolstyle, before title={\hspace*{-5ex}\makebox[5ex][l]{#1.}}, title={\notblank{#2}{#2}{}}, after title={\notblank{#2}{\space}{}}, phantom={</xsl:text>
        <xsl:if test="$b-pageref">
            <xsl:text>\label{#4}</xsl:text>
        </xsl:if>
        <xsl:text>\hypertarget{#4}{}}, after upper={\notblank{#3}{\par\rule{\ptxworkspacestrutwidth}{#3}\par\vfill}{\par}}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//@workspace">
        <xsl:text>%% Worksheets and handouts children may have workspaces&#xa;</xsl:text>
        <xsl:text>\newlength{\ptxworkspacestrutwidth}&#xa;</xsl:text>
        <xsl:choose>
            <xsl:when test="$b-latex-draft-mode">
                <xsl:text>%% LaTeX draft mode, @workspace strut is visible&#xa;</xsl:text>
                <xsl:text>\setlength{\ptxworkspacestrutwidth}{2pt}&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>%% @workspace strut is invisible&#xa;</xsl:text>
                <xsl:text>\setlength{\ptxworkspacestrutwidth}{0pt}&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- ############################################################# -->
<!-- Infrastructure surrounding Exercises (but not main Divisions) -->
<!-- ############################################################# -->

<!-- ############ -->
<!-- Subexercises -->
<!-- ############ -->

<!-- A minimal division within an "exercises" division. -->

<xsl:template match="subexercises">
    <xsl:variable name="id">
        <xsl:apply-templates select="." mode="unique-id"/>
    </xsl:variable>
    <xsl:apply-templates select="." mode="newpage"/>
    <xsl:text>\paragraph{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}</xsl:text>
    <xsl:if test="$b-pageref">
        <xsl:text>\label{</xsl:text>
        <xsl:value-of select="$id"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>\hypertarget{</xsl:text>
    <xsl:value-of select="$id"/>
    <xsl:text>}{}&#xa;</xsl:text>
    <xsl:apply-templates select="idx|notation|introduction|exercisegroup|exercise|conclusion"/>
</xsl:template>

<!-- The generic driver in pretext-common.xsl decides if anything -->
<!-- appears at all, and renders the items; the wrapping here      -->
<xsl:template match="subexercises" mode="present-solutions-container">
    <xsl:param name="b-has-statement"/>
    <xsl:param name="content"/>

    <xsl:if test="title">
        <xsl:text>\paragraph</xsl:text>
        <!-- keep optional title if LaTeX source is re-purposed -->
        <xsl:text>[{</xsl:text>
        <xsl:apply-templates select="." mode="title-short" />
        <xsl:text>}]</xsl:text>
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>}</xsl:text>
        <!-- no label, as this is a duplicate              -->
        <!-- no title, no heading, so only line-break here -->
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$b-has-statement">
        <xsl:apply-templates select="introduction" />
    </xsl:if>
    <xsl:copy-of select="$content"/>
    <xsl:if test="$b-has-statement">
        <xsl:apply-templates select="conclusion" />
    </xsl:if>
    <xsl:text>\par\medskip\noindent&#xa;</xsl:text>
</xsl:template>

<!-- ############### -->
<!-- Exercise Groups -->
<!-- ############### -->

<!-- Exercise Group -->
<!-- We interrupt a run of exercises with short discussion, -->
<!-- typically instructions for a list of similar exercises -->
<!-- discussion goes in an introduction and/or conclusion   -->
<!-- When we point to these, we use custom hypertarget, etc -->
<xsl:template match="exercisegroup">
    <!-- Determine the number of columns -->
    <!-- Restrict to 1-6 via the schema  -->
    <xsl:variable name="ncols">
        <xsl:choose>
            <xsl:when test="@cols">
                <xsl:value-of select="@cols"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- build it -->
    <xsl:apply-templates select="." mode="newpage"/>
    <xsl:text>\par\medskip\noindent%&#xa;</xsl:text>
    <xsl:text>\textbf{</xsl:text>
    <!-- title may be default title -->
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}\space\space</xsl:text>
    <xsl:apply-templates select="." mode="optional-label"/>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates select="introduction" />
    <xsl:choose>
        <xsl:when test="$ncols = 1">
            <xsl:text>\begin{exercisegroup}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\begin{exercisegroupcol}</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="$ncols"/>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- Each "idx" produces its own newline -->
    <xsl:apply-templates select="idx"/>
    <!-- an exercisegroup can only appear in an "exercises" division,    -->
    <!-- the template for exercises//exercise will consult switches for  -->
    <!-- visibility of components when born (not doing "solutions" here) -->
    <xsl:apply-templates select="exercise"/>
    <xsl:choose>
        <xsl:when test="$ncols = 1">
            <xsl:text>\end{exercisegroup}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\end{exercisegroupcol}&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="conclusion">
        <xsl:text>\par\noindent%&#xa;</xsl:text>
        <xsl:apply-templates select="conclusion" />
    </xsl:if>
    <xsl:text>\par\medskip\noindent&#xa;</xsl:text>
</xsl:template>

<!-- Exercise Group (in solutions division) -->
<!-- Nothing produced if there is no content         -->
<!-- Otherwise, no label, since duplicate            -->
<!-- Introduction and conclusion iff with statements -->
<!-- Echoed in a "solutions" division; the generic driver in     -->
<!-- pretext-common.xsl decides if anything appears at all, and  -->
<!-- renders the items; the wrapping here                        -->
<xsl:template match="exercisegroup" mode="present-solutions-container">
    <xsl:param name="b-has-statement"/>
    <xsl:param name="content"/>

    <!-- Determine the number of columns         -->
    <!-- Restrict to 1-6 via the schema          -->
    <!-- Override for solutions takes precedence -->
    <xsl:variable name="ncols">
        <xsl:choose>
            <xsl:when test="@solutions-cols">
                <xsl:value-of select="@solutions-cols"/>
            </xsl:when>
            <xsl:when test="@cols">
                <xsl:value-of select="@cols"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="title">
        <xsl:text>\subparagraph</xsl:text>
        <!-- keep optional title if LaTeX source is re-purposed -->
        <xsl:text>[{</xsl:text>
        <xsl:apply-templates select="." mode="title-short" />
        <xsl:text>}]</xsl:text>
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>}</xsl:text>
        <!-- no label, as this is a duplicate              -->
        <!-- no title, no heading, so only line-break here -->
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$b-has-statement">
        <xsl:apply-templates select="introduction" />
    </xsl:if>
    <!-- the container for the exercisegroup does not need to change -->
    <!-- when in a solutions list.  The indentation might look odd   -->
    <!-- without an introduction (when there are no statements), or  -->
    <!-- it might remind the reader of the grouping                  -->
    <xsl:choose>
        <xsl:when test="$ncols = 1">
            <xsl:text>\begin{exercisegroup}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\begin{exercisegroupcol}</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="$ncols"/>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:copy-of select="$content"/>
    <xsl:choose>
        <xsl:when test="$ncols = 1">
            <xsl:text>\end{exercisegroup}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\end{exercisegroupcol}&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="$b-has-statement">
        <xsl:apply-templates select="conclusion" />
    </xsl:if>
    <xsl:text>\par\medskip\noindent&#xa;</xsl:text>
</xsl:template>

<!-- ####################################### -->
<!-- Solutions Divisions, Content Generation -->
<!-- ####################################### -->

<!-- The "division-in-solutions" modal template from -common   -->
<!-- calls the "duplicate-heading" modal template.             -->
<!-- Stacked headings all share one size, fixed by the level   -->
<!-- of the originating "solutions" division, regardless of    -->
<!-- the depth each entry reflects.  This is consistent with   -->
<!-- treating stacked headings as a single "squashed" heading. -->

<xsl:template match="*" mode="duplicate-heading">
    <xsl:param name="heading-level"/>
    <xsl:param name="heading-stack" select="."/>
    <xsl:variable name="text-size">
        <xsl:call-template name="get-heading-text-size">
            <xsl:with-param name="heading-level" select="$heading-level"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:text>\par\medskip&#xa;\noindent\textbf{</xsl:text>
    <xsl:value-of select="$text-size"/>
    <xsl:text>{}</xsl:text>
    <xsl:apply-templates select="$heading-stack" mode="duplicate-heading-content">
        <xsl:with-param name="heading-stack" select="$heading-stack"/>
    </xsl:apply-templates>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="*" mode="duplicate-heading-content">
    <xsl:param name="heading-stack"/>
    <xsl:variable name="show-number">
        <xsl:apply-templates select="." mode="duplicate-heading-show-number"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$show-number = 'false'">
            <xsl:text>\textperiodcentered\space{}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="number" />
            <xsl:text>\space\textperiodcentered\space{}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="." mode="title-full" />
    <!-- line break, but not on last -->
    <xsl:if test="count(descendant::*[count(.|$heading-stack) = count($heading-stack)]) > 0">
        <xsl:text>\\&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template name="get-heading-text-size">
    <xsl:param name="heading-level" select="6"/>
    <xsl:choose>
        <xsl:when test="$heading-level = 1">
            <xsl:text>\Huge</xsl:text>
        </xsl:when>
        <xsl:when test="$heading-level = 2">
            <xsl:text>\huge</xsl:text>
        </xsl:when>
        <xsl:when test="$heading-level = 3">
            <xsl:text>\Large</xsl:text>
        </xsl:when>
        <xsl:when test="$heading-level = 4">
            <xsl:text>\large</xsl:text>
        </xsl:when>
        <xsl:when test="$heading-level = 5">
            <xsl:text>\normalsize</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\normalsize</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############################################## -->
<!-- Exercises and Projects for Solutions Divisions -->
<!-- ############################################## -->

<!-- A template formulates the various possible environments -->
<!-- Just as above, but now a different mode                 -->
<xsl:template match="exercise|&PROJECT-LIKE;" mode="solutions-environment-name">
    <xsl:choose>
        <!-- projects sit in divisions according to schema,  -->
        <!-- just like inline exercises, so we catch them    -->
        <!-- first, before differentiating exercises based   -->
        <!-- on placement, just recycle PreTeXt element name -->
        <xsl:when test="&PROJECT-FILTER;">
            <xsl:value-of select="local-name(.)" />
            <xsl:text>solution</xsl:text>
        </xsl:when>
        <!-- must now be an "exercise" -->
        <xsl:when test="&INLINE-EXERCISE-FILTER;">
            <xsl:text>inlinesolution</xsl:text>
        </xsl:when>
        <xsl:when test="ancestor::exercises or ancestor::worksheet or ancestor::reading-questions">
            <xsl:text>divisionsolution</xsl:text>
            <!-- "exercisegroup" and "exercisegroup/@cols" become  -->
            <!-- progressively more complicated to organize -->
            <xsl:if test="ancestor::exercisegroup">
                <xsl:text>eg</xsl:text>
            </xsl:if>
            <xsl:if test="ancestor::exercisegroup/@cols">
                <xsl:text>col</xsl:text>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>exercise-solution-without-environment-name</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Exercises and projects (as above) in solutions-->
<!-- Nothing produced if there is no content       -->
<!-- Otherwise, no label, since duplicate          -->
<!-- Different environment, with hard-coded number -->
<!-- Switches for solutions are generated          -->
<!-- elsewhere and always supplied in call         -->
<!-- NB: switches originate in solutions generator -->
<xsl:template match="exercise[boolean(&INLINE-EXERCISE-FILTER;)]|&PROJECT-LIKE;|exercises//exercise|worksheet//exercise|reading-questions//exercise" mode="solutions">
    <xsl:param name="purpose"/>
    <xsl:param name="admit"/>
    <xsl:param name="b-component-heading"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint"      />
    <xsl:param name="b-has-answer"    />
    <xsl:param name="b-has-solution"  />

    <!-- Subsetting, especially in the back matter can yield no content at all    -->
    <!-- Schema says there is always some sort of statement, explicit or implicit -->
    <!-- We frequently build collections of "dry-run" output to determine if a    -->
    <!-- collection of exercises (e.g. in an "exercisegroup") is empty or not.    -->
    <!-- So it is *critical* that we get zero output for an exercise that has     -->
    <!-- no content due to settings of switches.                                  -->

     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
            <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
            <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
        <!-- no project-like prelude, as duplicating in solutions division -->
        <!-- The exact environment depends on the placement of the -->
        <!-- "exercise" when located in an "exercises" division    -->
        <xsl:variable name="env-name">
            <xsl:apply-templates select="." mode="solutions-environment-name"/>
        </xsl:variable>
        <xsl:text>\begin{</xsl:text>
        <xsl:value-of select="$env-name"/>
        <xsl:text>}</xsl:text>
        <!-- Always supply a type-name, even if the     -->
        <!-- receiving environment does not utilize it. -->
        <!-- Five categories, four are "exercise".      -->
        <xsl:text>{</xsl:text>
        <xsl:choose>
            <!--divisional exercise -->
            <xsl:when test="self::exercise and ancestor::exercises">
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'divisionalexercise'"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- worksheet exercise -->
            <xsl:when test="self::exercise and ancestor::worksheet">
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'worksheetexercise'"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- reading question -->
            <xsl:when test="self::exercise and ancestor::reading-questions">
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'readingquestion'"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- inline exercise ("Checkpoint") by elimination -->
            <xsl:when test="self::exercise">
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'inlineexercise'"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- now PROJECT-LIKE by elimination, don't need $string-id -->
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="type-name"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>}</xsl:text>
        <!-- Always a hard-coded full number, never any workspace -->
        <!-- indication, so unified across the four types         -->
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="number" />
        <xsl:text>}</xsl:text>
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>}</xsl:text>
        <!-- label of the exercise, to link back to it -->
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="unique-id"/>
        <xsl:text>}</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
        <!-- Now the guts of the exercise, inside of its  -->
        <!-- (variable) identification, environment, etc. -->
        <!-- NB: this is where we say goodbye to the      -->
        <!-- "solutions" modal templates and switch to    -->
        <!-- the "exercise-components"templates with the  -->
        <!-- $b-original flag.                            -->
        <xsl:apply-templates select="." mode="exercise-components">
            <xsl:with-param name="b-original" select="false()" />
            <xsl:with-param name="purpose" select="$purpose" />
            <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
            <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
            <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
        </xsl:apply-templates>
        <!-- closing % necessary, as newline between adjacent environments -->
        <!-- will cause a slight indent on trailing exercise               -->
        <xsl:text>\end{</xsl:text>
        <xsl:value-of select="$env-name"/>
        <xsl:text>}%&#xa;</xsl:text>
        <!-- no project-like postlude, as duplicating in solutions division -->
    </xsl:if>
</xsl:template>

</xsl:stylesheet>
