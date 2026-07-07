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


</xsl:stylesheet>
