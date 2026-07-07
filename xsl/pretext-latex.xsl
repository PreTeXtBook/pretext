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
<!-- preamble driver, covers, title pages, and (eventually) the  -->
<!-- styling of divisions and front/back matter.  Machinery      -->
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
    <!-- If there is a <support> tag in an article, create a unnumbered footnote environment for it -->
    <xsl:if test="$b-is-article and $bibinfo/support">
        <xsl:text>%% add a \ptxsupport command as unnumbered footnote&#xa;</xsl:text>
        <xsl:text>\let\ptxsvdthefootnote\thefootnote%&#xa;</xsl:text>
        <xsl:text>\newcommand\ptxsupport[1]{%&#xa;</xsl:text>
        <xsl:text>  \let\thefootnote\relax%&#xa;</xsl:text>
        <xsl:text>  \footnotetext{#1}%&#xa;</xsl:text>
        <xsl:text>  \let\thefootnote\ptxsvdthefootnote%&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
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


</xsl:stylesheet>
