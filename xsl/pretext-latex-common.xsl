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
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:pf="https://prefigure.org"
    extension-element-prefixes="exsl date str"
>

<!-- Standard conversion groundwork -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="text" encoding="UTF-8"/>

<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!--  -->
<!--  -->
<!-- Author's Tools                                            -->
<!-- Set the author-tools parameter to 'yes'                   -->
<!-- (Documented in pretext-common.xsl)                       -->
<!-- Installs some LaTeX-specific behavior                     -->
<!-- (1) Index entries in margin of the page                   -->
<!--      where defined, on single pass (no real index)        -->
<!-- (2) LaTeX labels near definition and use                  -->
<!--     N.B. Some are author-defined; others are internal,    -->
<!--     and CANNOT be used as xml:id's (will raise a warning) -->
<!--  -->
<!-- Preamble insertions                    -->
<!-- Insert packages, options into preamble -->
<!-- early or late                          -->
<xsl:param name="latex.preamble.early" select="''" />
<xsl:param name="latex.preamble.late" select="''" />


<!-- ############### -->
<!-- Source Analysis -->
<!-- ############### -->

<!-- We check certain aspects of the source and record the results   -->
<!-- in boolean ($b-has-*) variables or as particular nodes high     -->
<!-- up in the structure ($document-root).  Scans here in -latex     -->
<!-- should help streamline the construction of the preamble by      -->
<!-- computing properties that will be checked more than once.       -->
<!-- While technically generally part of constructing the preamble,  -->
<!-- there is no real harm in making these global variables.  Short, -->
<!-- simple, and universal properties are determined in -common.     -->
<!-- These may duplicate variables in disjoint conversions.          -->

<xsl:variable name="b-has-icon"         select="boolean($document-root//icon)" />
<xsl:variable name="b-has-webwork-var"  select="boolean($document-root//statement//ul[@pi:ww-form])" />
<xsl:variable name="b-has-program"      select="boolean($document-root//program|$document-root//pf)" />
<xsl:variable name="b-has-console"      select="boolean($document-root//console)" />
<xsl:variable name="b-has-sidebyside"   select="boolean($document-root//sidebyside)" />
<xsl:variable name="b-has-sage"         select="boolean($document-root//sage)" />
<!-- 2023-10-18: this is a bit buggy, as it ignores the "men" element.  -->
<!-- And it examines the "md" element which will never be true. It has  -->
<!-- been fine for years, and it hopefully will go away some day, so no -->
<!-- fix right now.                                                     -->
<xsl:variable name="b-has-sfrac"        select="boolean($document-root//m[contains(text(),'sfrac')] or $document-root//md[contains(text(),'sfrac')] or $document-root//me[contains(text(),'sfrac')] or $document-root//mrow[contains(text(),'sfrac')])" />
<!-- These are *significant*, *intentional* source elements requiring a monospace font   -->
<!-- (and not incindentals like an email address which could just be the default tt font -->
<xsl:variable name="b-needs-mono-font" select="$b-has-program or $b-has-sage or $b-has-console or $document-root//c or $document-root//cd or $document-root//pre or $document-root//tag or $document-root//tage or $document-root//attr"/>
<xsl:variable name="b-has-long-tabular" select="boolean($document-root//notation-list|$document-root//list-of|$document-root//tabular[@break='yes'])" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<!-- Variables that affect LaTeX creation -->
<!-- More in the -common file             -->

<!-- Search for the "math.punctuation.include" -->
<!-- global variable, which is discussed in    -->
<!-- closer proximity to its application.      -->

<!-- Not a parameter, a variable to override deliberately within a conversion -->
<xsl:variable name="b-latex-hardcode-numbers" select="false()"/>

<!-- LaTeX always puts sections at level "1", while PTX         -->
<!-- has sections at level "2", so we provide adjusted,         -->
<!-- LaTeX-only variables for packages/macros that crudely      -->
<!-- expect these kinds of numbers (rather than division names) -->
<xsl:variable name="latex-toc-level">
    <xsl:call-template name="level-to-latex-level">
        <xsl:with-param name="level" select="$toc-level" />
    </xsl:call-template>
</xsl:variable>
<xsl:variable name="latex-numbering-maxlevel">
    <xsl:call-template name="level-to-latex-level">
        <xsl:with-param name="level" select="$numbering-maxlevel" />
    </xsl:call-template>
</xsl:variable>

<!-- We override the default ToC structure    -->
<!-- just to kill the ToC always for articles -->
<xsl:variable name="toc-level-override">
    <xsl:choose>
        <!-- this is really bad, we should not be consulting -->
        <!-- the publisher file here, so consider a better   -->
        <!-- way to make this override                       -->
        <xsl:when test="$publication/common/tableofcontents/@level">
            <xsl:value-of select="$publication/common/tableofcontents/@level"/>
        </xsl:when>
        <!-- legacy, respect string parameter -->
        <xsl:when test="$toc.level != ''">
            <xsl:value-of select="$toc.level" />
        </xsl:when>
        <xsl:when test="$root/book/article">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: Table of Contents level (for LateX conversion) not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="toc-level" select="number($toc-level-override)"/>

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

<!-- Including page numbers in cross-references defaults to      -->
<!-- 'yes' for an electronic PDF and to 'no' for a print PDF,    -->
<!-- and of course can be switched away from the default at will -->
<!-- $latex-pageref is a publisher variable, and so guaranteed   -->
<!-- to be "yes", "no" or empty.                                 -->
<!-- NB: upgrade the latex.print variable to something like this -->
<xsl:variable name="pagerefs-option">
    <xsl:choose>
        <!-- electronic PDF -->
        <xsl:when test="not($b-latex-print)">
            <xsl:choose>
                <xsl:when test="$latex-pageref = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="($latex-pageref = 'no') or ($latex-pageref = '')">
                    <xsl:text>no</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
        <!-- print PDF -->
        <xsl:when test="$b-latex-print">
            <xsl:choose>
                <xsl:when test="$latex-pageref = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:when test="($latex-pageref = 'yes') or ($latex-pageref = '')">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="b-pageref" select="$pagerefs-option = 'yes'"/>

<!-- Conversions, like creating a solutions manual, may need   -->
<!-- LaTeX styles for the solutions to exercises, even if the  -->
<!-- source never has a "solutions" element.  So this variable -->
<!-- is set to false here, and an importing stylesheet can     -->
<!-- override it to be true.                                   -->
<xsl:variable name="b-needs-solution-styles" select="false()"/>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:apply-templates select="$original" mode="generic-warnings"/>
    <xsl:apply-templates select="$original" mode="element-deprecation-warnings"/>
    <xsl:apply-templates select="$original" mode="parameter-deprecation-warnings"/>
    <!-- We process the enhanced source pointed  -->
    <!-- to by $root at  /mathbook  or  /pretext -->
    <xsl:apply-templates select="$root"/>
</xsl:template>

<!-- We will have just one of the following -->
<!-- four types, and totally ignore docinfo -->
<xsl:template match="/mathbook|/pretext">
    <xsl:apply-templates select="article|book|letter|memo"/>
</xsl:template>

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

<!-- We write "snapshot" information into <job>.dep, primarily for     -->
<!-- developer's use to see what possible (dependent) packages are     -->
<!-- loaded.  Some authors may be able to copy this information out of -->
<!-- the dep file and use it to make an "archival" version of their    -->
<!-- LaTeX source with frozen dependencies.                            -->
<!-- 2022-11-22: Now opt-in since this package is maybe not standard?  -->
<!-- David Farmer uploaded to the arXiv and this caused an error.      -->
<xsl:template name="snapshot-package-info">
    <xsl:if test="$b-latex-snapshot">
        <xsl:text>%% A publication file entry has requested writing snapshot output into the &lt;job&gt;.dep file&#xa;</xsl:text>
        <xsl:text>\RequirePackage{snapshot}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

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


<!--####################-->
<!-- Preamble Templates -->
<!--####################-->

<!-- As of 2021-02-28 we have begun modularizing the components of the -->
<!-- preamble, into topical, similar/related groups of commands and    -->
<!-- definitions.  This was prompted by the necessity of  tcolorbox's  -->
<!-- numbering scheme needing to *follow* the introduction of the      -->
<!-- hyperref  package, contrary to the usual advice.  Routines here   -->
<!-- should mimic the order of their use in the real template.         -->

<!-- Preamble early -->
<xsl:template name="preamble-early">
    <xsl:text>%% Custom Preamble Entries, early (use latex.preamble.early)&#xa;</xsl:text>
    <xsl:if test="$latex.preamble.early != ''">
        <xsl:value-of select="$latex.preamble.early" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Redefine "cleardoublepage" -->
<xsl:template name="cleardoublepage">
    <xsl:choose>
        <xsl:when test="($b-latex-two-sides) or ($latex-open-odd = 'add-blanks')">
            <!-- Redefines \cleardoublepage as suggested, plus empty page style on blanks: -->
            <!-- https://tex.stackexchange.com/questions/185821/openright-in-oneside-book  -->
            <xsl:text>%% Always open on odd page&#xa;</xsl:text>
            <xsl:text>%%   The following adjusts cleardoublepage to remove twosided&#xa;</xsl:text>
            <xsl:text>%%   check so that we open on odd pages even in one-sided mode&#xa;</xsl:text>
            <xsl:text>%%   by adding an extra blank page on the preceding even page.&#xa;</xsl:text>
            <xsl:text>\makeatletter%&#xa;</xsl:text>
            <xsl:text>\def\cleardoublepage{%&#xa;</xsl:text>
            <xsl:text>\clearpage\ifodd\c@page\else\thispagestyle{empty}\hbox{}\newpage\if@twocolumn\hbox{}\newpage\fi\fi%&#xa;</xsl:text>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>\makeatother%&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="not($b-latex-two-sides) and ($latex-open-odd = 'skip-pages')">
            <xsl:text>%% Always open on odd page&#xa;</xsl:text>
            <xsl:text>%%   The following adjusts cleardoublepage to remove twosided&#xa;</xsl:text>
            <xsl:text>%%   check so that we open on odd pages even in one-sided mode&#xa;</xsl:text>
            <xsl:text>%%   by incrementing the page number to skip over the preceding&#xa;</xsl:text>
            <xsl:text>%%   even page.&#xa;</xsl:text>
            <xsl:text>\makeatletter%&#xa;</xsl:text>
            <xsl:text>\def\cleardoublepage{%&#xa;</xsl:text>
            <xsl:text>\clearpage\ifodd\c@page\else\addtocounter{page}{1}\fi%&#xa;</xsl:text>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>\makeatother%&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Standard packages -->
<xsl:template name="standard-packages">
    <!-- Following need to be mature, robust, powerful, flexible, well-maintained -->
    <xsl:text>%% Default LaTeX packages&#xa;</xsl:text>
    <xsl:text>%%   1.  always employed (or nearly so) for some purpose, or&#xa;</xsl:text>
    <xsl:text>%%   2.  a stylewriter may assume their presence&#xa;</xsl:text>
    <xsl:text>\usepackage{geometry}&#xa;</xsl:text>
    <xsl:text>%% Some aspects of the preamble are conditional,&#xa;</xsl:text>
    <xsl:text>%% the LaTeX engine is one such determinant&#xa;</xsl:text>
    <xsl:text>\usepackage{ifthen}&#xa;</xsl:text>
    <xsl:text>%% etoolbox has a variety of modern conveniences&#xa;</xsl:text>
    <!-- e.g, \notblank -->
    <xsl:text>\usepackage{etoolbox}&#xa;</xsl:text>
    <xsl:text>\usepackage{ifxetex,ifluatex}&#xa;</xsl:text>
    <xsl:text>%% Raster graphics inclusion&#xa;</xsl:text>
    <xsl:text>\usepackage{graphicx}&#xa;</xsl:text>
    <xsl:text>%% Color support, xcolor package&#xa;</xsl:text>
    <xsl:text>%% Always loaded, for: add/delete text, author tools&#xa;</xsl:text>
    <xsl:text>%% Here, since tcolorbox loads tikz, and tikz loads xcolor&#xa;</xsl:text>
    <!-- Avoid option conflicts causing errors:                                       -->
    <!-- http://tex.stackexchange.com/questions/57364/option-clash-for-package-xcolor -->
    <!-- svg later will clobber dvips?  See starred versions in xcolor documentation  -->
    <!-- v3.02, 2024-09-29 package documentation says                                 -->
    <!--   * "usenames" option is obsolete                                            -->
    <!--   * "table" option loads the "colortbl" package                              -->
    <!--   * Section 2.15.1 discusses "Name clashs between dvipsnames and svgnames"   -->
    <xsl:text>\PassOptionsToPackage{dvipsnames,svgnames,table}{xcolor}&#xa;</xsl:text>
    <xsl:text>\usepackage{xcolor}&#xa;</xsl:text>
    <!-- This tempalte for defining colors is provisional, and subject to change -->
    <xsl:text>%% begin: defined colors, via xcolor package, for styling&#xa;</xsl:text>
    <xsl:call-template name="xcolor-style"/>
    <xsl:text>%% end: defined colors, via xcolor package, for styling&#xa;</xsl:text>
</xsl:template>

<!-- tcolorbox initial setup -->
<xsl:template name="tcolorbox-init">
    <xsl:text>%% Colored boxes, and much more, though mostly styling&#xa;</xsl:text>
    <xsl:text>%% skins library provides "enhanced" skin, employing tikzpicture&#xa;</xsl:text>
    <xsl:text>%% boxes may be configured as "breakable" or "unbreakable"&#xa;</xsl:text>
    <xsl:text>%% "raster" controls grids of boxes, aka side-by-side&#xa;</xsl:text>
    <xsl:text>\usepackage{tcolorbox}&#xa;</xsl:text>
    <xsl:text>\tcbuselibrary{skins}&#xa;</xsl:text>
    <xsl:text>\tcbuselibrary{breakable}&#xa;</xsl:text>
    <xsl:text>\tcbuselibrary{raster}&#xa;</xsl:text>
    <xsl:text>%% We load some "stock" tcolorbox styles that we use a lot&#xa;</xsl:text>
    <xsl:text>%% Placement here is provisional, there will be some color work also&#xa;</xsl:text>
    <xsl:text>%% First, black on white, no border, transparent, but no assumption about titles&#xa;</xsl:text>
    <xsl:text>\tcbset{ bwminimalstyle/.style={size=minimal, boxrule=-0.3pt, frame empty,&#xa;</xsl:text>
    <xsl:text>colback=white, colbacktitle=white, coltitle=black, opacityfill=0.0} }&#xa;</xsl:text>
    <xsl:text>%% Second, bold title, run-in to text/paragraph/heading&#xa;</xsl:text>
    <xsl:text>%% Space afterwards will be controlled by environment,&#xa;</xsl:text>
    <xsl:text>%% independent of constructions of the tcb title&#xa;</xsl:text>
    <xsl:text>%% Places \blocktitlefont onto many block titles&#xa;</xsl:text>
    <xsl:text>\tcbset{ runintitlestyle/.style={fonttitle=\blocktitlefont\upshape\bfseries, attach title to upper} }&#xa;</xsl:text>
    <xsl:text>%% Spacing prior to each exercise, anywhere&#xa;</xsl:text>
    <xsl:text>\tcbset{ exercisespacingstyle/.style={before skip={1.5ex plus 0.5ex}} }&#xa;</xsl:text>
    <xsl:text>%% Spacing prior to each block&#xa;</xsl:text>
    <xsl:text>\tcbset{ blockspacingstyle/.style={before skip={2.0ex plus 0.5ex}} }&#xa;</xsl:text>
    <xsl:text>%% xparse allows the construction of more robust commands,&#xa;</xsl:text>
    <xsl:text>%% this is a necessity for isolating styling and behavior&#xa;</xsl:text>
    <xsl:text>%% The tcolorbox library of the same name loads the base library&#xa;</xsl:text>
    <xsl:text>\tcbuselibrary{xparse}&#xa;</xsl:text>
    <xsl:text>%% The tcolorbox library loads TikZ, its calc package is generally useful,&#xa;</xsl:text>
    <xsl:text>%% and is necessary for some smaller documents that use partial tcolor boxes&#xa;</xsl:text>
    <xsl:text>%% See:  https://github.com/PreTeXtBook/pretext/issues/1624&#xa;</xsl:text>
    <xsl:text>\usetikzlibrary{calc}&#xa;</xsl:text>
    <xsl:text>%% We use some more exotic tcolorbox keys to restore indentation to parboxes&#xa;</xsl:text>
    <xsl:text>\tcbuselibrary{hooks}&#xa;</xsl:text>
</xsl:template>

<!-- paragraph and page setup -->
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
    <xsl:text>\newlength{\normalparindent}&#xa;</xsl:text>
    <xsl:text>\newlength{\normalparskip}&#xa;</xsl:text>
    <xsl:text>\AtBeginDocument{\setlength{\normalparindent}{\parindent}}&#xa;</xsl:text>
    <xsl:text>\AtBeginDocument{\setlength{\normalparskip}{\parskip}}&#xa;</xsl:text>
    <xsl:text>\newcommand{\setparstyle}{\setlength{\parindent}{\normalparindent}\setlength{\parskip}{\normalparskip}}</xsl:text>
    <xsl:text>%% Hyperref should be here, but likes to be loaded late&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% Inline math delimiters, \(, \), need to be robust&#xa;</xsl:text>
    <xsl:text>%% 2016-01-31:  latexrelease.sty  supersedes  fixltx2e.sty&#xa;</xsl:text>
    <xsl:text>%% If  latexrelease.sty  exists, bugfix is in kernel&#xa;</xsl:text>
    <xsl:text>%% If not, bugfix is in  fixltx2e.sty&#xa;</xsl:text>
    <xsl:text>%% See:  https://tug.org/TUGboat/tb36-3/tb114ltnews22.pdf&#xa;</xsl:text>
    <xsl:text>%% and read "Fewer fragile commands" in distribution's  latexchanges.pdf&#xa;</xsl:text>
    <xsl:text>\IfFileExists{latexrelease.sty}{}{\usepackage{fixltx2e}}&#xa;</xsl:text>
    <!-- could condition on "subfigure-reps" -->
    <xsl:if test="$b-has-sidebyside">
        <xsl:text>%% shorter subnumbers in some side-by-side require manipulations&#xa;</xsl:text>
        <xsl:text>\usepackage{xstring}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//fn|$document-root//part">
        <xsl:text>%% Footnote counters and part/chapter counters are manipulated&#xa;</xsl:text>
        <xsl:text>%% April 2018:  chngcntr  commands now integrated into the kernel,&#xa;</xsl:text>
        <xsl:text>%% but circa 2018/2019 the package would still try to redefine them,&#xa;</xsl:text>
        <xsl:text>%% so we need to do the work of loading conditionally for old kernels.&#xa;</xsl:text>
        <xsl:text>%% From version 1.1a,  chngcntr  should detect defintions made by LaTeX kernel.&#xa;</xsl:text>
        <xsl:text>\ifdefined\counterwithin&#xa;</xsl:text>
        <xsl:text>\else&#xa;</xsl:text>
        <xsl:text>    \usepackage{chngcntr}&#xa;</xsl:text>
        <xsl:text>\fi&#xa;</xsl:text>
        <xsl:if test="$parts = 'structural'">  <!-- implies book/part -->
            <xsl:text>%% Structural chapter numbers reset within parts&#xa;</xsl:text>
            <xsl:text>%% Starred form will not prefix part number&#xa;</xsl:text>
            <xsl:text>\counterwithin*{chapter}{part}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- Determine height of text block, assumes US letterpaper (11in height) -->
    <!-- Could react to document type, paper, margin specs                    -->
    <xsl:variable name="text-height">
        <xsl:text>9.0in</xsl:text>
    </xsl:variable>
    <!-- Bringhurst: 30x => 66 chars, so 34x => 75 chars -->
    <xsl:variable name="text-width">
        <xsl:value-of select="34 * substring-before($font-size, 'pt')" />
        <xsl:text>pt</xsl:text>
    </xsl:variable>
    <xsl:text>%% Text height identically 9 inches, text width varies on point size&#xa;</xsl:text>
    <xsl:text>%% See Bringhurst 2.1.1 on measure for recommendations&#xa;</xsl:text>
    <xsl:text>%% 75 characters per line (count spaces, punctuation) is target&#xa;</xsl:text>
    <xsl:text>%% which is the upper limit of Bringhurst's recommendations&#xa;</xsl:text>
    <xsl:text>\geometry{letterpaper,total={</xsl:text>
    <xsl:value-of select="$text-width" />
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$text-height" />
    <xsl:text>}}&#xa;</xsl:text>
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

<!-- Conditional LaTeX engine support (exclusive of fonts) -->
<xsl:template name="latex-engine-support">
    <xsl:text>%% This LaTeX file may be compiled with pdflatex, xelatex, or lualatex executables&#xa;</xsl:text>
    <xsl:text>%% LuaTeX is not explicitly supported, but we do accept additions from knowledgeable users&#xa;</xsl:text>
    <xsl:text>%% The conditional below provides  pdflatex  specific configuration last&#xa;</xsl:text>
    <xsl:text>%% begin: engine-specific capabilities&#xa;</xsl:text>
    <xsl:text>\ifthenelse{\boolean{xetex} \or \boolean{luatex}}{%&#xa;</xsl:text>
    <xsl:text>%% begin: xelatex and lualatex-specific default configuration&#xa;</xsl:text>
    <xsl:text>\ifxetex\usepackage{xltxtra}\fi&#xa;</xsl:text>
    <xsl:text>%% realscripts is the only part of xltxtra relevant to lualatex &#xa;</xsl:text>
    <xsl:text>\ifluatex\usepackage{realscripts}\fi&#xa;</xsl:text>
    <xsl:text>%% end:   xelatex and lualatex-specific default configuration&#xa;</xsl:text>
    <xsl:text>}{&#xa;</xsl:text>
    <xsl:text>%% begin: pdflatex-specific default configuration&#xa;</xsl:text>
    <xsl:text>%% We assume a PreTeXt XML source file may have Unicode characters&#xa;</xsl:text>
    <xsl:text>%% and so we ask LaTeX to parse a UTF-8 encoded file&#xa;</xsl:text>
    <xsl:text>%% This may work well for accented characters in Western language,&#xa;</xsl:text>
    <xsl:text>%% but not with Greek, Asian languages, etc.&#xa;</xsl:text>
    <xsl:text>%% When this is not good enough, switch to the  xelatex  engine&#xa;</xsl:text>
    <xsl:text>%% where Unicode is better supported (encouraged, even)&#xa;</xsl:text>
    <xsl:text>\usepackage[utf8]{inputenc}&#xa;</xsl:text>
    <xsl:text>%% end: pdflatex-specific default configuration&#xa;</xsl:text>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>%% end:   engine-specific capabilities&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
</xsl:template>

<!-- Font support (conditional on engine) -->
<xsl:template name="font-support">
    <xsl:text>%% Fonts.  Conditional on LaTex engine employed.&#xa;</xsl:text>
    <xsl:text>%% Default Text Font: The Latin Modern fonts are&#xa;</xsl:text>
    <xsl:text>%% "enhanced versions of the [original TeX] Computer Modern fonts."&#xa;</xsl:text>
    <xsl:text>%% We use them as the default text font for PreTeXt output.&#xa;</xsl:text>
    <xsl:if test="$b-needs-mono-font">
        <xsl:text>%% Default Monospace font: Inconsolata (aka zi4)&#xa;</xsl:text>
        <xsl:text>%% Sponsored by TUG: http://levien.com/type/myfonts/inconsolata.html&#xa;</xsl:text>
        <xsl:text>%% Loaded for documents with intentional objects requiring monospace&#xa;</xsl:text>
        <xsl:text>%% See package documentation for excellent instructions&#xa;</xsl:text>
        <xsl:text>%% fontspec will work universally if we use filename to locate OTF files&#xa;</xsl:text>
        <xsl:text>%% Loads the "upquote" package as needed, so we don't have to&#xa;</xsl:text>
        <xsl:text>%% Upright quotes might come from the  textcomp  package, which we also use&#xa;</xsl:text>
        <xsl:text>%% We employ the shapely \ell to match Google Font version&#xa;</xsl:text>
        <xsl:text>%% pdflatex: "varl" package option produces shapely \ell&#xa;</xsl:text>
        <xsl:text>%% pdflatex: "var0" package option produces plain zero (not used)&#xa;</xsl:text>
        <xsl:text>%% pdflatex: "varqu" package option produces best upright quotes&#xa;</xsl:text>
        <xsl:text>%% xelatex,lualatex: add OTF StylisticSet 1 for shapely \ell&#xa;</xsl:text>
        <xsl:text>%% xelatex,lualatex: add OTF StylisticSet 2 for plain zero (not used)&#xa;</xsl:text>
        <xsl:text>%% xelatex,lualatex: add OTF StylisticSet 3 for upright quotes&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Automatic Font Control&#xa;</xsl:text>
    <xsl:text>%% Portions of a document, are, or may, be affected by defined commands&#xa;</xsl:text>
    <xsl:text>%% These are perhaps more flexible when using  xelatex  rather than  pdflatex&#xa;</xsl:text>
    <xsl:text>%% The following definitions are meant to be re-defined in a style, using \renewcommand&#xa;</xsl:text>
    <xsl:text>%% They are scoped when employed (in a TeX group), and so should not be defined with an argument&#xa;</xsl:text>
    <xsl:text>\newcommand{\divisionfont}{\relax}&#xa;</xsl:text>
    <xsl:text>\newcommand{\blocktitlefont}{\relax}&#xa;</xsl:text>
    <xsl:text>\newcommand{\contentsfont}{\relax}&#xa;</xsl:text>
    <xsl:text>\newcommand{\pagefont}{\relax}&#xa;</xsl:text>
    <xsl:text>\newcommand{\tabularfont}{\relax}&#xa;</xsl:text>
    <xsl:text>\newcommand{\xreffont}{\relax}&#xa;</xsl:text>
    <xsl:text>\newcommand{\titlepagefont}{\relax}&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>\ifthenelse{\boolean{xetex} \or \boolean{luatex}}{%&#xa;</xsl:text>
    <xsl:text>%% begin: font setup and configuration for use with xelatex&#xa;</xsl:text>
    <!--  -->
    <xsl:text>%% Generally, xelatex is necessary for non-Western fonts&#xa;</xsl:text>
    <xsl:text>%% fontspec package provides extensive control of system fonts,&#xa;</xsl:text>
    <xsl:text>%% meaning *.otf (OpenType), and apparently *.ttf (TrueType)&#xa;</xsl:text>
    <xsl:text>%% that live *outside* your TeX/MF tree, and are controlled by your *system*&#xa;</xsl:text>
    <xsl:text>%% (it is possible that a TeX distribution will place fonts in a system location)&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% The fontspec package is the best vehicle for using different fonts in  xelatex&#xa;</xsl:text>
    <xsl:text>%% So we load it always, no matter what a publisher or style might want&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>\usepackage{fontspec}&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <!--  -->
    <xsl:text>%% begin: xelatex main font ("font-xelatex-main" template)&#xa;</xsl:text>
    <xsl:call-template name="font-xelatex-main"/>
    <xsl:text>%% end:   xelatex main font ("font-xelatex-main" template)&#xa;</xsl:text>
    <!--  -->
    <xsl:text>%% begin: xelatex mono font ("font-xelatex-mono" template)&#xa;</xsl:text>
    <xsl:text>%% (conditional on non-trivial uses being present in source)&#xa;</xsl:text>
    <xsl:call-template name="font-xelatex-mono"/>
    <xsl:text>%% end:   xelatex mono font ("font-xelatex-mono" template)&#xa;</xsl:text>
    <!--  -->
    <xsl:text>%% begin: xelatex font adjustments ("font-xelatex-style" template)&#xa;</xsl:text>
    <xsl:call-template name="font-xelatex-style"/>
    <xsl:text>%% end:   xelatex font adjustments ("font-xelatex-style" template)&#xa;</xsl:text>
    <!--  -->
    <xsl:if test="$b-has-icon">
        <xsl:text>%% Icons being used, so xelatex needs a system font&#xa;</xsl:text>
        <xsl:text>%% This can only be determined at compile-time&#xa;</xsl:text>
        <xsl:call-template name="xelatex-font-check">
            <xsl:with-param name="font-name" select="'Font Awesome 5 Free'"/>
        </xsl:call-template>
        <xsl:call-template name="xelatex-font-check">
            <xsl:with-param name="font-name" select="'Font Awesome 5 Brands'"/>
        </xsl:call-template>
    </xsl:if>
    <xsl:text>%%&#xa;</xsl:text>
    <!-- language tags appear in docinfo in renames, so be careful -->
    <xsl:text>%% Extensive support for other languages&#xa;</xsl:text>
    <xsl:text>\usepackage{polyglossia}&#xa;</xsl:text>
    <xsl:text>%% Set main/default language based on pretext/@xml:lang value&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="$document-language = 'en-US'">
            <xsl:text>%% document language code is "en-US", US English&#xa;</xsl:text>
            <xsl:text>%% usmax variant has extra hypenation&#xa;</xsl:text>
            <xsl:text>\setmainlanguage[variant=usmax]{english}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$document-language = 'el'">
            <xsl:text>%% document language code is "el", Modern Greek (1453-)&#xa;</xsl:text>
            <xsl:text>\setmainlanguage[variant=monotonic]{greek}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$document-language = 'es-ES'">
            <xsl:text>%% document language code is "es-ES", Spanish&#xa;</xsl:text>
            <xsl:text>\setmainlanguage{spanish}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$document-language = 'hu-HU'">
            <xsl:text>%% document language code is "hu-HU", Magyar (Hungarian)&#xa;</xsl:text>
            <xsl:text>\setmainlanguage{magyar}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$document-language = 'ko-KR'">
            <xsl:text>%% document language code is "ko-KR", Korean&#xa;</xsl:text>
            <xsl:text>\setmainlanguage{korean}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$document-language = 'ru-RU'">
            <xsl:text>%% document language code is "ru-RU", Russian&#xa;</xsl:text>
            <xsl:text>\setmainlanguage{russian}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$document-language = 'vi-VN'">
            <xsl:text>%% document language code is "vi-VN", Vietnamese&#xa;</xsl:text>
            <xsl:text>\setmainlanguage{vietnamese}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$document-language = 'it-IT'">
            <xsl:text>%% document language code is "it-IT", Italian&#xa;</xsl:text>
            <xsl:text>\setmainlanguage{italian}&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>%% Enable secondary languages based on discovery of @xml:lang values&#xa;</xsl:text>
    <!-- collect every @xml:lang attribute in use into a variable/node-set -->
    <xsl:variable name="secondary-languages" select="$document-root//@xml:lang"/>

    <!-- sort into a new node-set so we can eliminate duplicate values -->
    <xsl:variable name="sorted-language-values-rtf">
        <xsl:for-each select="$secondary-languages">
            <xsl:sort select="."/>
            <language>
                <xsl:value-of select="."/>
            </language>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="sorted-language-values" select="exsl:node-set($sorted-language-values-rtf)"/>

    <!-- secondary language support, not already the "main" language -->
    <xsl:for-each select="$sorted-language-values/language">
        <!-- take action for first occurence -->
        <xsl:if test="not(. = preceding-sibling::language)">
            <xsl:variable name="language">
                <xsl:value-of select="."/>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="not($document-language = 'en-US') and ($language = 'en-US')">
                    <xsl:text>%% document contains language code "en-US", US English&#xa;</xsl:text>
                    <xsl:text>%% usmax variant has extra hypenation&#xa;</xsl:text>
                    <xsl:text>\setotherlanguage[variant=usmax]{english}&#xa;</xsl:text>
                </xsl:when>
                <xsl:when test="not($document-language = 'es-ES') and ($language = 'es-ES')">
                    <xsl:text>%% document contains language code "es-ES", Spanish&#xa;</xsl:text>
                    <xsl:text>\setotherlanguage{spanish}&#xa;</xsl:text>
                </xsl:when>
                <xsl:when test="not($document-language = 'el') and ($language = 'el')">
                    <xsl:text>%% document contains language code "el", Modern Greek (1453-)&#xa;</xsl:text>
                    <xsl:text>\setotherlanguage[variant=monotonic]{greek}&#xa;</xsl:text>
                </xsl:when>
                <xsl:when test="not($document-language = 'hu-HU') and ($language = 'hu-HU')">
                    <xsl:text>%% document contains language code "hu-HU", Magyar (Hungarian)&#xa;</xsl:text>
                    <xsl:text>\setotherlanguage{magyar}&#xa;</xsl:text>
                </xsl:when>
                <xsl:when test="not($document-language = 'ko-KR') and ($language = 'ko-KR')">
                    <xsl:text>%% document contains language code "ko-KR", Korean&#xa;</xsl:text>
                    <xsl:text>\setotherlanguage{korean}&#xa;</xsl:text>
                </xsl:when>
                <xsl:when test="not($document-language = 'ru-RU') and ($language = 'ru-RU')">
                    <xsl:text>%% document contains language code "ru-RU", Russian&#xa;</xsl:text>
                    <xsl:text>\setotherlanguage{russian}&#xa;</xsl:text>
                </xsl:when>
                <xsl:when test="not($document-language = 'vi-VN') and ($language = 'vi-VN')">
                    <xsl:text>%% document contains language code "vi-VN", Vietnamese&#xa;</xsl:text>
                    <xsl:text>\setotherlanguage{vietnamese}&#xa;</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:for-each>

    <xsl:text>%% Enable fonts/scripts based on discovery of @xml:lang values&#xa;</xsl:text>
    <xsl:text>%% Western languages should be ably covered by Latin Modern Roman&#xa;</xsl:text>
    <xsl:for-each select="$sorted-language-values/language">
        <!-- take action for first occurence -->
        <xsl:if test="not(. = preceding-sibling::language)">
            <xsl:variable name="language">
                <xsl:value-of select="."/>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$language = 'el'">
                    <xsl:text>%% Font for Modern Greek&#xa;</xsl:text>
                    <xsl:text>%% Font families: CMU Serif (Ubuntu fonts-cmu package), Linux Libertine O, GFS Artemisia&#xa;</xsl:text>
                    <xsl:text>%% OTF Script needs to be enabled&#xa;</xsl:text>
                    <xsl:text>\newfontfamily\greekfont[Script=Greek]{CMU Serif}&#xa;</xsl:text>
                </xsl:when>
                <xsl:when test="$language = 'ko-KR'">
                    <xsl:text>%% Font for Hangul&#xa;</xsl:text>
                    <xsl:text>%% Font families: alternate - UnBatang with [Script=Hangul]&#xa;</xsl:text>
                    <xsl:text>%% Debian/Ubuntu "fonts-nanum" package&#xa;</xsl:text>
                    <xsl:text>\newfontfamily\koreanfont{NanumMyeongjo}&#xa;</xsl:text>
                </xsl:when>
                <xsl:when test="$language = 'ru-RU'">
                    <xsl:text>%% Font for Cyrillic&#xa;</xsl:text>
                    <xsl:text>%% Font families: CMU Serif, Linux Libertine O&#xa;</xsl:text>
                    <xsl:text>%% OTF Script needs to be enabled&#xa;</xsl:text>
                    <xsl:text>\newfontfamily\russianfont[Script=Cyrillic]{CMU Serif}&#xa;</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:for-each>
    <xsl:text>%% end:   font setup and configuration for use with xelatex&#xa;</xsl:text>
    <!--  -->
    <xsl:text>}{%&#xa;</xsl:text>
    <!--  -->
    <xsl:text>%% begin: font setup and configuration for use with pdflatex&#xa;</xsl:text>
    <!--  -->
    <xsl:text>%% begin: pdflatex main font ("font-pdflatex-main" template)&#xa;</xsl:text>
    <xsl:call-template name="font-pdflatex-main"/>
    <xsl:text>%% end:   pdflatex main font ("font-pdflatex-main" template)&#xa;</xsl:text>
    <!--  -->
    <xsl:text>%% begin: pdflatex mono font ("font-pdflatex-mono" template)&#xa;</xsl:text>
    <xsl:text>%% (conditional on non-trivial uses being present in source)&#xa;</xsl:text>
    <xsl:call-template name="font-pdflatex-mono"/>
    <xsl:text>%% end:   pdflatex mono font ("font-pdflatex-mono" template)&#xa;</xsl:text>
    <!--  -->
    <xsl:text>%% begin: pdflatex font adjustments ("font-pdflatex-style" template)&#xa;</xsl:text>
    <xsl:call-template name="font-pdflatex-style"/>
    <xsl:text>%% end:   pdflatex font adjustments ("font-pdflatex-style" template)&#xa;</xsl:text>
    <!--  -->
    <xsl:text>%% end:   font setup and configuration for use with pdflatex&#xa;</xsl:text>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>%% Micromanage spacing, etc.  The named "microtype-options"&#xa;</xsl:text>
    <xsl:text>%% template may be employed to fine-tune package behavior&#xa;</xsl:text>
    <xsl:text>\usepackage</xsl:text>
    <!-- This template supplies [] w options iff there really are options -->
    <xsl:call-template name="microtype-option-argument"/>
    <xsl:text>{microtype}&#xa;</xsl:text>
</xsl:template>

<!-- Additional packages for math -->
<xsl:template name="math-packages">
    <xsl:text>%% Symbols, align environment, commutative diagrams, bracket-matrix&#xa;</xsl:text>
    <xsl:text>\usepackage{amsmath}&#xa;</xsl:text>
    <xsl:text>\usepackage{amscd}&#xa;</xsl:text>
    <xsl:text>\usepackage{amssymb}&#xa;</xsl:text>
    <xsl:text>%% allow page breaks within display mathematics anywhere&#xa;</xsl:text>
    <xsl:text>%% level 4 is maximally permissive&#xa;</xsl:text>
    <xsl:text>%% this is exactly the opposite of AMSmath package philosophy&#xa;</xsl:text>
    <xsl:text>%% there are per-display, and per-equation options to control this&#xa;</xsl:text>
    <xsl:text>%% split, aligned, gathered, and alignedat are not affected&#xa;</xsl:text>
    <xsl:text>\allowdisplaybreaks[4]&#xa;</xsl:text>
    <xsl:text>%% allow more columns to a matrix&#xa;</xsl:text>
    <xsl:text>%% can make this even bigger by overriding with  latex.preamble.late  processing option&#xa;</xsl:text>
    <xsl:text>\setcounter{MaxMatrixCols}{30}&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
</xsl:template>

<!-- pdfpages package for covers -->
<xsl:template name="pdfpages-package">
    <xsl:if test="$b-has-latex-front-cover or $b-has-latex-back-cover">
        <xsl:text>%% pdfpages package for front and back covers as PDFs&#xa;</xsl:text>
        <xsl:text>\usepackage[</xsl:text>
        <xsl:choose>
            <xsl:when test="$b-latex-draft-mode">
                <xsl:text>draft</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>final</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>]{pdfpages}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%%&#xa;</xsl:text>
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

<!-- Semantic Macros -->
<xsl:template name="semantic-macros">
    <xsl:text>%% Begin: Semantic Macros&#xa;</xsl:text>
    <xsl:text>%% To preserve meaning in a LaTeX file&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% \mono macro for content of "c", "cd", "tag", etc elements&#xa;</xsl:text>
    <xsl:text>%% Also used automatically in other constructions&#xa;</xsl:text>
    <xsl:text>%% Simply an alias for \texttt&#xa;</xsl:text>
    <xsl:text>%% Always defined, even if there is no need, or if a specific tt font is not loaded&#xa;</xsl:text>
    <xsl:text>\newcommand{\mono}[1]{\texttt{#1}}&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% Following semantic macros are only defined here if their&#xa;</xsl:text>
    <xsl:text>%% use is required only in this specific document&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:variable name="one-line-reps" select="
        ($document-root//abbr)[1]|
        ($document-root//acro)[1]|
        ($document-root//init)[1]"/>
    <!-- (after fillin before swung-dash) -->
    <!-- Eventually move explanation of section to condition  -->
    <xsl:for-each select="$one-line-reps">
        <xsl:apply-templates select="." mode="tex-macro"/>
    </xsl:for-each>
    <xsl:if test="$document-root//alert">
        <xsl:text>%% Used for warnings, typically bold and italic&#xa;</xsl:text>
        <xsl:text>\newcommand{\alert}[1]{\textbf{\textit{#1}}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//term">
        <xsl:text>%% Used for inline definitions of terms&#xa;</xsl:text>
        <xsl:text>\newcommand{\terminology}[1]{\textbf{#1}}&#xa;</xsl:text>
    </xsl:if>
    <!-- 2018-02-05: "booktitle" deprecated -->
    <xsl:if test="$document-root//pubtitle|$document-root//booktitle">
        <xsl:text>%% Titles of longer works (e.g. books, versus articles)&#xa;</xsl:text>
        <xsl:text>\newcommand{\pubtitle}[1]{\textsl{#1}}&#xa;</xsl:text>
    </xsl:if>
    <!-- http://tex.stackexchange.com/questions/23711/strikethrough-text -->
    <!-- http://tex.stackexchange.com/questions/287599/thickness-for-sout-strikethrough-command-from-ulem-package -->
    <xsl:if test="$document-root//insert|$document-root//delete|$document-root//stale">
        <xsl:text>%% Edits (insert, delete), stale (irrelevant, obsolete)&#xa;</xsl:text>
        <xsl:text>%% Package: underlines and strikethroughs, no change to \emph{}&#xa;</xsl:text>
        <xsl:text>\usepackage[normalem]{ulem}&#xa;</xsl:text>
        <xsl:text>%% Rules in this package reset proportional to fontsize&#xa;</xsl:text>
        <xsl:text>%% NB: *never* reset to package default (0.4pt?) after use&#xa;</xsl:text>
        <xsl:text>%% Macros will use colors for "electronic" version (the default)&#xa;</xsl:text>
        <xsl:if test="$document-root//insert">
            <xsl:text>%% Used for an edit that is an addition&#xa;</xsl:text>
            <xsl:text>\newcommand{\insertthick}{.1ex}&#xa;</xsl:text>
            <xsl:choose>
                <xsl:when test="$b-latex-print">
                    <xsl:text>\newcommand{\inserted}[1]{\renewcommand{\ULthickness}{\insertthick}\uline{#1}}&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\newcommand{\inserted}[1]{\renewcommand{\ULthickness}{\insertthick}\textcolor{green}{\uline{#1}}}&#xa;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="$document-root//delete">
            <xsl:text>%% Used for an edit that is a deletion&#xa;</xsl:text>
            <xsl:text>\newcommand{\deletethick}{.25ex}&#xa;</xsl:text>
            <xsl:choose>
                <xsl:when test="$b-latex-print">
                    <xsl:text>\newcommand{\deleted}[1]{\renewcommand{\ULthickness}{\deletethick}\sout{#1}}&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\newcommand{\deleted}[1]{\renewcommand{\ULthickness}{\deletethick}\textcolor{red}{\sout{#1}}}&#xa;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="$document-root//stale">
            <xsl:text>%% Used for inline irrelevant or obsolete text&#xa;</xsl:text>
            <xsl:text>\newcommand{\stalethick}{.1ex}&#xa;</xsl:text>
            <xsl:text>\newcommand{\stale}[1]{\renewcommand{\ULthickness}{\stalethick}\sout{#1}}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$document-root//fillin[not(parent::m or parent::me or parent::men or parent::mrow)]">
        <xsl:call-template name="fillin-text"/>
    </xsl:if>
    <xsl:if test="$document-root//m/fillin|$document-root//me/fillin|$document-root//men/fillin|$document-root//mrow/fillin">
        <xsl:call-template name="fillin-math"/>
    </xsl:if>
    <!-- http://andrewmccarthy.ie/2014/11/06/swung-dash-in-latex/ -->
    <xsl:if test="$document-root//swungdash">
        <xsl:text>%% A character like a tilde, but different&#xa;</xsl:text>
        <xsl:text>\newcommand{\swungdash}{\raisebox{-2.25ex}{\scalebox{2}{\~{}}}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//quantity">
        <xsl:text>%% Used for units and number formatting&#xa;</xsl:text>
        <xsl:text>\usepackage[per-mode=fraction]{siunitx}&#xa;</xsl:text>
        <!-- v2 -> v3 is a major upgrade, we need to accomodate both    -->
        <!-- Eventually we may want to just fail on version 2 and warn. -->
        <!-- Kernel test is actually "equal or later" according to      -->
        <!-- https://tex.stackexchange.com/questions/47743/             -->
        <!--   require-a-certain-or-later-version-of-a-package          -->
        <!-- IfPackageAtLeastTF: maybe only available since 2020-10-01? -->
        <xsl:text>%% v3 dated 2021-05-17, fix major behavior change&#xa;</xsl:text>
        <xsl:text>\makeatletter%&#xa;</xsl:text>
        <xsl:text>\@ifpackagelater{siunitx}{2021/05/17}&#xa;</xsl:text>
        <xsl:text>{%&#xa;</xsl:text>
        <xsl:text>\typeout{PTX: discovered siunitx v3, >= 2021-05-17}%&#xa;</xsl:text>
        <xsl:text>\sisetup{parse-numbers = false}%&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>{%&#xa;</xsl:text>
        <xsl:text>\typeout{PTX: discovered siunitx v2, &lt; 2021-05-17}%&#xa;</xsl:text>
        <xsl:text>}%&#xa;</xsl:text>
        <xsl:text>\makeatother%&#xa;</xsl:text>
        <xsl:text>\sisetup{inter-unit-product=\cdot}&#xa;</xsl:text>
        <xsl:text>\ifxetex\sisetup{math-micro=\text{µ},text-micro=µ}\fi</xsl:text>
        <xsl:text>\ifluatex\sisetup{math-micro=\text{µ},text-micro=µ}\fi</xsl:text>
        <xsl:text>%% Common non-SI units&#xa;</xsl:text>
        <xsl:for-each select="document('pretext-units.xsl')//base[@siunitx]">
            <xsl:text>\DeclareSIUnit\</xsl:text>
            <xsl:value-of select="@full" />
            <xsl:text>{</xsl:text>
            <xsl:choose>
                <xsl:when test="@siunitx='none'">
                    <xsl:value-of select="@short" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@siunitx" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:for-each>
    </xsl:if>
    <xsl:if test="$document-root//ol/li/title|$document-root//ul/li/title|$document-root//task/title">
        <!-- Styling: expose this macro to easier overriding for style work -->
        <!-- NB: needs a rename (and duplication) before exposing publicly  -->
        <!-- conditional can be split for list items v. tasks               -->
        <xsl:text>%% Style of a title on a list item, for ordered and unordered lists&#xa;</xsl:text>
        <xsl:text>%% Also "task" of exercise, PROJECT-LIKE, EXAMPLE-LIKE&#xa;</xsl:text>
        <xsl:text>\newcommand{\lititle}[1]{{\slshape#1}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% End: Semantic Macros&#xa;</xsl:text>
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
            <xsl:text>\tcbset{ inlinesolutionstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, after title={\space}, breakable, before upper app={\setparstyle} } }&#xa;</xsl:text>
            <xsl:text>\newtcolorbox{inlinesolution}[4]</xsl:text>
            <xsl:text>{inlinesolutionstyle, title={\hyperref[#4]{#1~#2}\notblank{#3}{\space#3}{}}}&#xa;</xsl:text>
        </xsl:if>
        <!-- Division Solution -->
        <!-- Explicitly breakable, run-in title -->
        <xsl:if test="$document-root//exercises//exercise[not(ancestor::exercisegroup)]|$document-root//worksheet//exercise[not(ancestor::exercisegroup)]|$document-root//reading-questions//exercise[not(ancestor::exercisegroup)]">
            <xsl:text>%% Solutions to division exercises, not in exercise group&#xa;</xsl:text>
            <xsl:text>%% Parameter #1 is type-name and is ignored&#xa;</xsl:text>
            <xsl:text>\tcbset{ divisionsolutionstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, after title={\space}, breakable, before upper app={\setparstyle} } }&#xa;</xsl:text>
            <xsl:text>\newtcolorbox{divisionsolution}[4]</xsl:text>
            <xsl:text>{divisionsolutionstyle, title={\hyperlink{#4}{#2}.\notblank{#3}{\space#3}{}}}&#xa;</xsl:text>
        </xsl:if>
        <!-- Division Solution, Exercise Group -->
        <!-- Explicitly breakable, run-in title -->
        <xsl:if test="$document-root//exercisegroup[not(@cols)]">
            <xsl:text>%% Solutions to division exercises, in exercise group, no columns&#xa;</xsl:text>
            <xsl:text>%% Parameter #1 is type-name and is ignored&#xa;</xsl:text>
            <xsl:text>\tcbset{ divisionsolutionegstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, after title={\space}, left skip=\egindent, breakable, before upper app={\setparstyle} } }&#xa;</xsl:text>
            <xsl:text>\newtcolorbox{divisionsolutioneg}[4]</xsl:text>
            <xsl:text>{divisionsolutionegstyle, title={\hyperlink{#4}{#2}.\notblank{#3}{\space#3}{}}}&#xa;</xsl:text>
        </xsl:if>
        <!-- Division Solution, Exercise Group, Columnar -->
        <!-- Explicity unbreakable, to behave in multicolumn tcbraster -->
        <xsl:if test="$document-root//exercisegroup/@cols">
            <xsl:text>%% Solutions to division exercises, in exercise group with columns&#xa;</xsl:text>
            <xsl:text>%% Parameter #1 is type-name and is ignored&#xa;</xsl:text>
            <xsl:text>\tcbset{ divisionsolutionegcolstyle/.style={bwminimalstyle, runintitlestyle,  exercisespacingstyle, after title={\space}, halign=flush left, unbreakable, before upper app={\setparstyle} } }&#xa;</xsl:text>
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
            <xsl:text>solutionstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, after title={\space}, breakable, before upper app={\setparstyle} } }&#xa;</xsl:text>
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
        <xsl:text>\tcbset{ divisionexercisestyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, left=5ex, breakable, before upper app={\setparstyle} } }&#xa;</xsl:text>
        <xsl:text>\newtcolorbox{divisionexercise}[4]</xsl:text>
        <xsl:text>{divisionexercisestyle, before title={\hspace*{-5ex}\makebox[5ex][l]{#1.}}, title={\notblank{#2}{#2}{}}, after title={\notblank{#2}{\space}{}}, phantom={</xsl:text>
        <xsl:if test="$b-pageref">
            <xsl:text>\label{#4}</xsl:text>
        </xsl:if>
        <xsl:text>\hypertarget{#4}{}}, after={\notblank{#3}{\par\rule{\workspacestrutwidth}{#3}\par\vfill}{\par}}}&#xa;</xsl:text>
    </xsl:if>
    <!-- Division Exercise, Exercise Group -->
    <!-- The exercise itself carries the indentation, hence we can use breakable -->
    <!-- boxes and get good page breaks (as these problems could be long)        -->
    <xsl:if test="$document-root//exercisegroup[not(@cols)]">
        <xsl:text>%% Division exercises, in exercise group, no columns&#xa;</xsl:text>
        <!-- Outdenting the problem number requires an "\hspace*" to avoid an edge case -->
        <!-- https://tex.stackexchange.com/questions/722329/unwanted-space-in-tcbraster -->
        <!-- https://tex.stackexchange.com/questions/89082/hspace-vs-hspace             -->
        <xsl:text>\tcbset{ divisionexerciseegstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, left=5ex, left skip=\egindent, breakable, before upper app={\setparstyle} } }&#xa;</xsl:text>
        <xsl:text>\newtcolorbox{divisionexerciseeg}[4]</xsl:text>
        <xsl:text>{divisionexerciseegstyle, before title={\hspace*{-5ex}\makebox[5ex][l]{#1.}}, title={\notblank{#2}{#2}{}}, after title={\notblank{#2}{\space}{}}, phantom={</xsl:text>
        <xsl:if test="$b-pageref">
            <xsl:text>\label{#4}</xsl:text>
        </xsl:if>
        <xsl:text>\hypertarget{#4}{}}, after={\notblank{#3}{\par\rule{\workspacestrutwidth}{#3}\par\vfill}{\par}}}&#xa;</xsl:text>
    </xsl:if>
    <!-- Division Exercise, Exercise Group, Columnar -->
    <!-- Explicity unbreakable, to behave in multicolumn tcbraster -->
    <xsl:if test="$document-root//exercisegroup/@cols">
        <xsl:text>%% Division exercises, in exercise group with columns&#xa;</xsl:text>
        <!-- Outdenting the problem number requires an "\hspace*" to avoid an edge case -->
        <!-- https://tex.stackexchange.com/questions/722329/unwanted-space-in-tcbraster -->
        <!-- https://tex.stackexchange.com/questions/89082/hspace-vs-hspace             -->
        <xsl:text>\tcbset{ divisionexerciseegcolstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, left=5ex, halign=flush left, unbreakable, before upper app={\setparstyle} } }&#xa;</xsl:text>
        <xsl:text>\newtcolorbox{divisionexerciseegcol}[4]</xsl:text>
        <xsl:text>{divisionexerciseegcolstyle, before title={\hspace*{-5ex}\makebox[5ex][l]{#1.}}, title={\notblank{#2}{#2}{}}, after title={\notblank{#2}{\space}{}}, phantom={</xsl:text>
        <xsl:if test="$b-pageref">
            <xsl:text>\label{#4}</xsl:text>
        </xsl:if>
        <xsl:text>\hypertarget{#4}{}}, after upper={\notblank{#3}{\par\rule{\workspacestrutwidth}{#3}\par\vfill}{\par}}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//@workspace">
        <xsl:text>%% Worksheet exercises may have workspaces&#xa;</xsl:text>
        <xsl:text>\newlength{\workspacestrutwidth}&#xa;</xsl:text>
        <xsl:choose>
            <xsl:when test="$b-latex-draft-mode">
                <xsl:text>%% LaTeX draft mode, @workspace strut is visible&#xa;</xsl:text>
                <xsl:text>\setlength{\workspacestrutwidth}{2pt}&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>%% @workspace strut is invisible&#xa;</xsl:text>
                <xsl:text>\setlength{\workspacestrutwidth}{0pt}&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- Chapter start number -->
<xsl:template name="chapter-start-number">
    <!-- Publishers can start chapter numbering at will.  Chapter 0 for -->
    <!-- the computer scientists, and perhaps a certain chapter number  -->
    <!-- for a book spread across multiple physical valumes.            -->
    <xsl:if test="$document-root//chapter and not($chapter-start = 1)">
        <xsl:text>%% Publisher file requests an alternate chapter numbering&#xa;</xsl:text>
        <xsl:text>\setcounter{chapter}{</xsl:text>
        <xsl:value-of select="$chapter-start - 1" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Equation numbering -->
<xsl:template name="equation-numbering">
    <!-- Numbering Equations -->
    <!-- See numbering-equations variable being set in pretext-common.xsl         -->
    <!-- With number="yes|no" on mrow, we must allow for the possibility of an md  -->
    <!-- variant having numbers (we could be more careful, but it is not critical) -->
    <!-- NB: global numbering is level 0 and "level-to-name" is (a) incorrect,     -->
    <!-- and (b) not useful (\numberwithin will fail)                              -->
    <!-- NB: perhaps the chngcntr package should/could be used here                -->
    <xsl:if test="$document-root//men|$document-root//mdn|$document-root//md">
        <xsl:text>%% Equation Numbering&#xa;</xsl:text>
        <xsl:text>%% Controlled by  numbering.equations.level  processing parameter&#xa;</xsl:text>
        <xsl:text>%% No adjustment here implies document-wide numbering&#xa;</xsl:text>
        <xsl:if test="not($numbering-equations = 0)">
            <xsl:text>\numberwithin{equation}{</xsl:text>
            <xsl:call-template name="level-to-name">
                <xsl:with-param name="level" select="$numbering-equations" />
            </xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- tcolorbox for images -->
<xsl:template name="image-tcolorbox">
    <xsl:if test="$document-root//image">
        <xsl:text>%% "tcolorbox" environment for a single image, occupying entire \linewidth&#xa;</xsl:text>
        <xsl:text>%% arguments are left-margin, width, right-margin, as multiples of&#xa;</xsl:text>
        <xsl:text>%% \linewidth, and are guaranteed to be positive and sum to 1.0&#xa;</xsl:text>
        <xsl:text>\tcbset{ imagestyle/.style={bwminimalstyle} }&#xa;</xsl:text>
        <xsl:text>\NewTColorBox{tcbimage}{mmm}{imagestyle,left skip=#1\linewidth,width=#2\linewidth}&#xa;</xsl:text>
        <xsl:text>%% Wrapper environment for tcbimage environment with a fourth argument&#xa;</xsl:text>
        <xsl:text>%% Fourth argument, if nonempty, is a vertical space adjustment&#xa;</xsl:text>
        <xsl:text>%% and implies image will be preceded by \leavevmode\nopagebreak&#xa;</xsl:text>
        <xsl:text>%% Intended use is for alignment with a list marker&#xa;</xsl:text>
        <xsl:text>\NewDocumentEnvironment{image}{mmmm}{\notblank{#4}{\leavevmode\nopagebreak\vspace{#4}}{}\begin{tcbimage}{#1}{#2}{#3}}{\end{tcbimage}%&#xa;}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Tables -->
<xsl:template name="tables">
    <xsl:if test="$document-root//tabular">
        <xsl:text>%% For improved tables&#xa;</xsl:text>
        <xsl:text>\usepackage{array}&#xa;</xsl:text>
        <xsl:text>%% Some extra height on each row is desirable, especially with horizontal rules&#xa;</xsl:text>
        <xsl:text>%% Increment determined experimentally&#xa;</xsl:text>
        <xsl:text>\setlength{\extrarowheight}{0.2ex}&#xa;</xsl:text>
        <xsl:text>%% Define variable thickness horizontal rules, full and partial&#xa;</xsl:text>
        <xsl:text>%% Thicknesses are 0.03, 0.05, 0.08 in the  booktabs  package&#xa;</xsl:text>
        <!-- http://tex.stackexchange.com/questions/119153/table-with-different-rule-widths -->
        <xsl:text>\newcommand{\hrulethin}  {\noalign{\hrule height 0.04em}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\hrulemedium}{\noalign{\hrule height 0.07em}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\hrulethick} {\noalign{\hrule height 0.11em}}&#xa;</xsl:text>
        <!-- http://tex.stackexchange.com/questions/24549/horizontal-rule-with-adjustable-height-behaving-like-clinen-m -->
        <!-- Could preserve/restore \arrayrulewidth on entry/exit to tabular -->
        <!-- But we'll get cleaner source with this built into macros        -->
        <!-- Could condition \setlength debacle on the use of extpfeil       -->
        <!-- arrows (see discussion below)                                   -->
        <xsl:text>%% We preserve a copy of the \setlength package before other&#xa;</xsl:text>
        <xsl:text>%% packages (extpfeil) get a chance to load packages that redefine it&#xa;</xsl:text>
        <xsl:text>\let\oldsetlength\setlength&#xa;</xsl:text>
        <xsl:text>\newlength{\Oldarrayrulewidth}&#xa;</xsl:text>
        <xsl:text>\newcommand{\crulethin}[1]%&#xa;</xsl:text>
        <xsl:text>{\noalign{\global\oldsetlength{\Oldarrayrulewidth}{\arrayrulewidth}}%&#xa;</xsl:text>
        <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{0.04em}}\cline{#1}%&#xa;</xsl:text>
        <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{\Oldarrayrulewidth}}}%&#xa;</xsl:text>
        <xsl:text>\newcommand{\crulemedium}[1]%&#xa;</xsl:text>
        <xsl:text>{\noalign{\global\oldsetlength{\Oldarrayrulewidth}{\arrayrulewidth}}%&#xa;</xsl:text>
        <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{0.07em}}\cline{#1}%&#xa;</xsl:text>
        <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{\Oldarrayrulewidth}}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\crulethick}[1]%&#xa;</xsl:text>
        <xsl:text>{\noalign{\global\oldsetlength{\Oldarrayrulewidth}{\arrayrulewidth}}%&#xa;</xsl:text>
        <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{0.11em}}\cline{#1}%&#xa;</xsl:text>
        <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{\Oldarrayrulewidth}}}&#xa;</xsl:text>
        <!-- http://tex.stackexchange.com/questions/119153/table-with-different-rule-widths -->
        <xsl:text>%% Single letter column specifiers defined via array package&#xa;</xsl:text>
        <xsl:text>\newcolumntype{A}{!{\vrule width 0.04em}}&#xa;</xsl:text>
        <xsl:text>\newcolumntype{B}{!{\vrule width 0.07em}}&#xa;</xsl:text>
        <xsl:text>\newcolumntype{C}{!{\vrule width 0.11em}}&#xa;</xsl:text>
        <!-- naked tabulars work best in a tcolorbox -->
        <xsl:text>%% tcolorbox to place tabular outside of a sidebyside&#xa;</xsl:text>
        <xsl:text>\tcbset{ tabularboxstyle/.style={bwminimalstyle,} }&#xa;</xsl:text>
        <xsl:text>\newtcolorbox{tabularbox}[3]{tabularboxstyle, left skip=#1\linewidth, width=#2\linewidth,}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//cell/line">
        <xsl:text>\newcommand{\tablecelllines}[3]%&#xa;</xsl:text>
        <xsl:text>{\begin{tabular}[#2]{@{}#1@{}}#3\end{tabular}}&#xa;</xsl:text>
    </xsl:if>
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
        <xsl:text>%% add a \support command as unnumbered footnote&#xa;</xsl:text>
        <xsl:text>\let\svdthefootnote\thefootnote%&#xa;</xsl:text>
        <xsl:text>\newcommand\support[1]{%&#xa;</xsl:text>
        <xsl:text>  \let\thefootnote\relax%&#xa;</xsl:text>
        <xsl:text>  \footnotetext{#1}%&#xa;</xsl:text>
        <xsl:text>  \let\thefootnote\svdthefootnote%&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Font Awesome package -->
<xsl:template name="font-awesome">
    <xsl:if test="$b-has-icon">
        <xsl:text>%% Font Awesome 5 icons in a LaTeX package&#xa;</xsl:text>
        <xsl:text>%% https://ctan.org/pkg/fontawesome5 (v5.15.4) &#xa;</xsl:text>
        <xsl:text>\usepackage{fontawesome5}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Poetry -->
<xsl:template name="poetry-support">
    <xsl:if test="$document-root//poem">
        <xsl:text>%% Poetry Support&#xa;</xsl:text>
        <xsl:text>\newenvironment{poem}{\setlength{\parindent}{0em}}{}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemTitle}[1]{\begin{center}\large\textbf{#1}\end{center}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemIndent}{\hspace{2 em}}&#xa;</xsl:text>
        <xsl:text>\newenvironment{stanza}{\vspace{0.25 em}\hangindent=4em}{\vspace{1 em}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\stanzaTitle}[1]{{\centering\textbf{#1}\par}\vspace{-\parskip}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemauthorleft}[1]{\vspace{-1em}\begin{flushleft}\textit{#1}\end{flushleft}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemauthorcenter}[1]{\vspace{-1em}\begin{center}\textit{#1}\end{center}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemauthorright}[1]{\vspace{-1em}\begin{flushright}\textit{#1}\end{flushright}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemlineleft}[1]{{\raggedright{#1}\par}\vspace{-\parskip}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemlinecenter}[1]{{\centering{#1}\par}\vspace{-\parskip}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemlineright}[1]{{\raggedleft{#1}\par}\vspace{-\parskip}}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Music -->
<xsl:template name="music-support">
    <xsl:if test="$document-root//flat | $document-root//doubleflat | $document-root//sharp | $document-root//doublesharp | $document-root//natural | $document-root//n | $document-root//scaledeg | $document-root//chord">
        <xsl:text>%% Musical Symbol Support&#xa;</xsl:text>
        <xsl:text>%% The musicography package builds on the "musix" fonts and&#xa;</xsl:text>
        <xsl:text>%% provides music notation for use with both pdflatex and xelatex&#xa;</xsl:text>
        <xsl:text>%% For Ubuntu/Debian use the  texlive-music  package&#xa;</xsl:text>
        <!-- Note: package's shorthand macros  \fl, \sh, \na  might conflict with authors' macros? -->
        <xsl:text>\usepackage{musicography}&#xa;</xsl:text>
        <xsl:text>\renewcommand{\flat}{\musFlat}&#xa;</xsl:text>
        <xsl:text>\newcommand{\doubleflat}{\musDoubleFlat}&#xa;</xsl:text>
        <xsl:text>\renewcommand{\sharp}{\musSharp}&#xa;</xsl:text>
        <xsl:text>\newcommand{\doublesharp}{\musDoubleSharp}&#xa;</xsl:text>
        <xsl:text>\renewcommand{\natural}{\musNatural}&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Code support -->
<xsl:template name="code-support">
    <!-- Inconsolata font, sponsored by TUG: http://levien.com/type/myfonts/inconsolata.html            -->
    <!-- As seen on: http://tex.stackexchange.com/questions/50810/good-monospace-font-for-code-in-latex -->
    <!-- "Fonts for Displaying Program Code in LaTeX":  http://nepsweb.co.uk/docs%/progfonts.pdf        -->
    <!-- Fonts and xelatex:  http://tex.stackexchange.com/questions/102525/use-type-1-fonts-with-xelatex -->
    <!--   http://tex.stackexchange.com/questions/179448/beramono-in-xetex -->
    <!-- http://tex.stackexchange.com/questions/25249/how-do-i-use-a-particular-font-for-a-small-section-of-text-in-my-document -->
    <!-- Bitstream Vera Font names within: https://github.com/timfel/texmf/blob/master/fonts/map/vtex/bera.ali -->
    <!-- Coloring listings: http://tex.stackexchange.com/questions/18376/beautiful-listing-for-csharp -->
    <!-- Song and Dance for font changes: http://jevopi.blogspot.com/2010/03/nicely-formatted-listings-in-latex-with.html -->
    <xsl:if test="$b-has-program or $b-has-console or $b-has-sage">
        <xsl:text>%% Program listing support: for listings, programs, consoles, and Sage code&#xa;</xsl:text>
        <!-- NB: the "listingsutf8" package is not a panacea, as it only       -->
        <!-- cooperates with UTF-8 characters when code snippets are read      -->
        <!-- in from external files.  We do condition on the LaTeX engines     -->
        <!-- since (a) it is easy and (b) the tcolorbox documentation warns    -->
        <!-- about not being careful.  NB: LuaTeX is not tested nor supported. -->
        <xsl:text>\ifthenelse{\boolean{xetex} \or \boolean{luatex}}%&#xa;</xsl:text>
        <xsl:text>  {\tcbuselibrary{listings}}%&#xa;</xsl:text>
        <xsl:text>  {\tcbuselibrary{listingsutf8}}%&#xa;</xsl:text>
        <xsl:text>%% We define the listings font style to be the default "ttfamily"&#xa;</xsl:text>
        <xsl:text>%% To fix hyphens/dashes rendered in PDF as fancy minus signs by listing&#xa;</xsl:text>
        <xsl:text>%% http://tex.stackexchange.com/questions/33185/listings-package-changes-hyphens-to-minus-signs&#xa;</xsl:text>
        <xsl:text>\makeatletter&#xa;</xsl:text>
        <xsl:text>\lst@CCPutMacro\lst@ProcessOther {"2D}{\lst@ttfamily{-{}}{-{}}}&#xa;</xsl:text>
        <xsl:text>\@empty\z@\@empty&#xa;</xsl:text>
        <xsl:text>\makeatother&#xa;</xsl:text>
        <xsl:text>%% We define a null language, free of any formatting or style&#xa;</xsl:text>
        <xsl:text>%% for use when a language is not supported, or pseudo-code, or consoles&#xa;</xsl:text>
        <xsl:text>%% Not necessary for Sage code, so in limited cases included unnecessarily&#xa;</xsl:text>
        <xsl:text>\lstdefinelanguage{none}{identifierstyle=,commentstyle=,stringstyle=,keywordstyle=}&#xa;</xsl:text>
        <xsl:text>\ifthenelse{\boolean{xetex}}{}{%&#xa;</xsl:text>
        <xsl:text>%% begin: pdflatex-specific listings configuration&#xa;</xsl:text>
        <xsl:text>%% translate U+0080 - U+00F0 to their textmode LaTeX equivalents&#xa;</xsl:text>
        <xsl:text>%% Data originally from https://www.w3.org/Math/characters/unicode.xml, 2016-07-23&#xa;</xsl:text>
        <xsl:text>%% Lines marked in XSL with "$" were converted from mathmode to textmode&#xa;</xsl:text>
        <!-- encoding, etc: http://tex.stackexchange.com/questions/24528/ -->
        <!-- Format: {Unicode}{TeX}{rendered-length} Unicode name (in numerical order) -->
        <xsl:text>\lstset{extendedchars=true}&#xa;</xsl:text>
        <xsl:text>\lstset{literate=</xsl:text>
        <xsl:text>{&#x00A0;}{{~}}{1}</xsl:text>    <!--NO-BREAK SPACE-->
        <xsl:text>{&#x00A1;}{{\textexclamdown }}{1}</xsl:text>    <!--INVERTED EXCLAMATION MARK-->
        <xsl:text>{&#x00A2;}{{\textcent }}{1}</xsl:text>    <!--CENT SIGN-->
        <xsl:text>{&#x00A3;}{{\textsterling }}{1}</xsl:text>    <!--POUND SIGN-->
        <xsl:text>{&#x00A4;}{{\textcurrency }}{1}</xsl:text>    <!--CURRENCY SIGN-->
        <xsl:text>{&#x00A5;}{{\textyen }}{1}</xsl:text>    <!--YEN SIGN-->
        <xsl:text>{&#x00A6;}{{\textbrokenbar }}{1}</xsl:text>    <!--BROKEN BAR-->
        <xsl:text>{&#x00A7;}{{\textsection }}{1}</xsl:text>    <!--SECTION SIGN-->
        <xsl:text>{&#x00A8;}{{\textasciidieresis }}{1}</xsl:text>    <!--DIAERESIS-->
        <xsl:text>{&#x00A9;}{{\textcopyright }}{1}</xsl:text>    <!--COPYRIGHT SIGN-->
        <xsl:text>{&#x00AA;}{{\textordfeminine }}{1}</xsl:text>    <!--FEMININE ORDINAL INDICATOR-->
        <xsl:text>{&#x00AB;}{{\guillemotleft }}{1}</xsl:text>    <!--LEFT-POINTING DOUBLE ANGLE QUOTATION MARK-->
        <xsl:text>{&#x00AC;}{{\textlnot }}{1}</xsl:text>    <!--NOT SIGN-->  <!-- $ -->
        <xsl:text>{&#x00AD;}{{\-}}{1}</xsl:text>    <!--SOFT HYPHEN-->
        <xsl:text>{&#x00AE;}{{\textregistered }}{1}</xsl:text>    <!--REGISTERED SIGN-->
        <xsl:text>{&#x00AF;}{{\textasciimacron }}{1}</xsl:text>    <!--MACRON-->
        <xsl:text>{&#x00B0;}{{\textdegree }}{1}</xsl:text>    <!--DEGREE SIGN-->
        <xsl:text>{&#x00B1;}{{\textpm }}{1}</xsl:text>    <!--PLUS-MINUS SIGN-->  <!-- $ -->
        <xsl:text>{&#x00B2;}{{\texttwosuperior }}{1}</xsl:text>    <!--SUPERSCRIPT TWO-->  <!-- $ -->
        <xsl:text>{&#x00B3;}{{\textthreesuperior }}{1}</xsl:text>    <!--SUPERSCRIPT THREE-->   <!-- $ -->
        <xsl:text>{&#x00B4;}{{\textasciiacute }}{1}</xsl:text>    <!--ACUTE ACCENT-->
        <xsl:text>{&#x00B5;}{{\textmu }}{1}</xsl:text>    <!--MICRO SIGN-->  <!-- $ -->
        <xsl:text>{&#x00B6;}{{\textparagraph }}{1}</xsl:text>    <!--PILCROW SIGN-->
        <xsl:text>{&#x00B7;}{{\textperiodcentered }}{1}</xsl:text>    <!--MIDDLE DOT-->  <!-- $ -->
        <xsl:text>{&#x00B8;}{{\c{}}}{1}</xsl:text>    <!--CEDILLA-->
        <xsl:text>{&#x00B9;}{{\textonesuperior }}{1}</xsl:text>    <!--SUPERSCRIPT ONE-->  <!-- $ -->
        <xsl:text>{&#x00BA;}{{\textordmasculine }}{1}</xsl:text>    <!--MASCULINE ORDINAL INDICATOR-->
        <xsl:text>{&#x00BB;}{{\guillemotright }}{1}</xsl:text>    <!--RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK-->
        <xsl:text>{&#x00BC;}{{\textonequarter }}{1}</xsl:text>    <!--VULGAR FRACTION ONE QUARTER-->
        <xsl:text>{&#x00BD;}{{\textonehalf }}{1}</xsl:text>    <!--VULGAR FRACTION ONE HALF-->
        <xsl:text>{&#x00BE;}{{\textthreequarters }}{1}</xsl:text>    <!--VULGAR FRACTION THREE QUARTERS-->
        <xsl:text>{&#x00BF;}{{\textquestiondown }}{1}</xsl:text>    <!--INVERTED QUESTION MARK-->
        <xsl:text>{&#x00C0;}{{\`{A}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER A WITH GRAVE-->
        <xsl:text>{&#x00C1;}{{\'{A}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER A WITH ACUTE-->
        <xsl:text>{&#x00C2;}{{\^{A}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER A WITH CIRCUMFLEX-->
        <xsl:text>{&#x00C3;}{{\~{A}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER A WITH TILDE-->
        <xsl:text>{&#x00C4;}{{\"{A}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER A WITH DIAERESIS-->
        <xsl:text>{&#x00C5;}{{\AA }}{1}</xsl:text>    <!--LATIN CAPITAL LETTER A WITH RING ABOVE-->
        <xsl:text>{&#x00C6;}{{\AE }}{1}</xsl:text>    <!--LATIN CAPITAL LETTER AE-->
        <xsl:text>{&#x00C7;}{{\c{C}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER C WITH CEDILLA-->
        <xsl:text>{&#x00C8;}{{\`{E}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER E WITH GRAVE-->
        <xsl:text>{&#x00C9;}{{\'{E}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER E WITH ACUTE-->
        <xsl:text>{&#x00CA;}{{\^{E}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER E WITH CIRCUMFLEX-->
        <xsl:text>{&#x00CB;}{{\"{E}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER E WITH DIAERESIS-->
        <xsl:text>{&#x00CC;}{{\`{I}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER I WITH GRAVE-->
        <xsl:text>{&#x00CD;}{{\'{I}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER I WITH ACUTE-->
        <xsl:text>{&#x00CE;}{{\^{I}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER I WITH CIRCUMFLEX-->
        <xsl:text>{&#x00CF;}{{\"{I}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER I WITH DIAERESIS-->
        <xsl:text>{&#x00D0;}{{\DH }}{1}</xsl:text>    <!--LATIN CAPITAL LETTER ETH-->
        <xsl:text>{&#x00D1;}{{\~{N}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER N WITH TILDE-->
        <xsl:text>{&#x00D2;}{{\`{O}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER O WITH GRAVE-->
        <xsl:text>{&#x00D3;}{{\'{O}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER O WITH ACUTE-->
        <xsl:text>{&#x00D4;}{{\^{O}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER O WITH CIRCUMFLEX-->
        <xsl:text>{&#x00D5;}{{\~{O}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER O WITH TILDE-->
        <xsl:text>{&#x00D6;}{{\"{O}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER O WITH DIAERESIS-->
        <xsl:text>{&#x00D7;}{{\texttimes }}{1}</xsl:text>    <!--MULTIPLICATION SIGN-->
        <xsl:text>{&#x00D8;}{{\O }}{1}</xsl:text>    <!--LATIN CAPITAL LETTER O WITH STROKE-->
        <xsl:text>{&#x00D9;}{{\`{U}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER U WITH GRAVE-->
        <xsl:text>{&#x00DA;}{{\'{U}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER U WITH ACUTE-->
        <xsl:text>{&#x00DB;}{{\^{U}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER U WITH CIRCUMFLEX-->
        <xsl:text>{&#x00DC;}{{\"{U}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER U WITH DIAERESIS-->
        <xsl:text>{&#x00DD;}{{\'{Y}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER Y WITH ACUTE-->
        <xsl:text>{&#x00DE;}{{\TH }}{1}</xsl:text>    <!--LATIN CAPITAL LETTER THORN-->
        <xsl:text>{&#x00DF;}{{\ss }}{1}</xsl:text>    <!--LATIN SMALL LETTER SHARP S-->
        <xsl:text>{&#x00E0;}{{\`{a}}}{1}</xsl:text>    <!--LATIN SMALL LETTER A WITH GRAVE-->
        <xsl:text>{&#x00E1;}{{\'{a}}}{1}</xsl:text>    <!--LATIN SMALL LETTER A WITH ACUTE-->
        <xsl:text>{&#x00E2;}{{\^{a}}}{1}</xsl:text>    <!--LATIN SMALL LETTER A WITH CIRCUMFLEX-->
        <xsl:text>{&#x00E3;}{{\~{a}}}{1}</xsl:text>    <!--LATIN SMALL LETTER A WITH TILDE-->
        <xsl:text>{&#x00E4;}{{\"{a}}}{1}</xsl:text>    <!--LATIN SMALL LETTER A WITH DIAERESIS-->
        <xsl:text>{&#x00E5;}{{\aa }}{1}</xsl:text>    <!--LATIN SMALL LETTER A WITH RING ABOVE-->
        <xsl:text>{&#x00E6;}{{\ae }}{1}</xsl:text>    <!--LATIN SMALL LETTER AE-->
        <xsl:text>{&#x00E7;}{{\c{c}}}{1}</xsl:text>    <!--LATIN SMALL LETTER C WITH CEDILLA-->
        <xsl:text>{&#x00E8;}{{\`{e}}}{1}</xsl:text>    <!--LATIN SMALL LETTER E WITH GRAVE-->
        <xsl:text>{&#x00E9;}{{\'{e}}}{1}</xsl:text>    <!--LATIN SMALL LETTER E WITH ACUTE-->
        <xsl:text>{&#x00EA;}{{\^{e}}}{1}</xsl:text>    <!--LATIN SMALL LETTER E WITH CIRCUMFLEX-->
        <xsl:text>{&#x00EB;}{{\"{e}}}{1}</xsl:text>    <!--LATIN SMALL LETTER E WITH DIAERESIS-->
        <xsl:text>{&#x00EC;}{{\`{\i}}}{1}</xsl:text>    <!--LATIN SMALL LETTER I WITH GRAVE-->
        <xsl:text>{&#x00ED;}{{\'{\i}}}{1}</xsl:text>    <!--LATIN SMALL LETTER I WITH ACUTE-->
        <xsl:text>{&#x00EE;}{{\^{\i}}}{1}</xsl:text>    <!--LATIN SMALL LETTER I WITH CIRCUMFLEX-->
        <xsl:text>{&#x00EF;}{{\"{\i}}}{1}</xsl:text>    <!--LATIN SMALL LETTER I WITH DIAERESIS-->
        <xsl:text>{&#x00F0;}{{\dh }}{1}</xsl:text>    <!--LATIN SMALL LETTER ETH-->
        <xsl:text>{&#x00F1;}{{\~{n}}}{1}</xsl:text>    <!--LATIN SMALL LETTER N WITH TILDE-->
        <xsl:text>{&#x00F2;}{{\`{o}}}{1}</xsl:text>    <!--LATIN SMALL LETTER O WITH GRAVE-->
        <xsl:text>{&#x00F3;}{{\'{o}}}{1}</xsl:text>    <!--LATIN SMALL LETTER O WITH ACUTE-->
        <xsl:text>{&#x00F4;}{{\^{o}}}{1}</xsl:text>    <!--LATIN SMALL LETTER O WITH CIRCUMFLEX-->
        <xsl:text>{&#x00F5;}{{\~{o}}}{1}</xsl:text>    <!--LATIN SMALL LETTER O WITH TILDE-->
        <xsl:text>{&#x00F6;}{{\"{o}}}{1}</xsl:text>    <!--LATIN SMALL LETTER O WITH DIAERESIS-->
        <xsl:text>{&#x00F7;}{{\textdiv }}{1}</xsl:text>    <!--DIVISION SIGN-->  <!-- $ -->
        <xsl:text>{&#x00F8;}{{\o }}{1}</xsl:text>    <!--LATIN SMALL LETTER O WITH STROKE-->
        <xsl:text>{&#x00F9;}{{\`{u}}}{1}</xsl:text>    <!--LATIN SMALL LETTER U WITH GRAVE-->
        <xsl:text>{&#x00FA;}{{\'{u}}}{1}</xsl:text>    <!--LATIN SMALL LETTER U WITH ACUTE-->
        <xsl:text>{&#x00FB;}{{\^{u}}}{1}</xsl:text>    <!--LATIN SMALL LETTER U WITH CIRCUMFLEX-->
        <xsl:text>{&#x00FC;}{{\"{u}}}{1}</xsl:text>    <!--LATIN SMALL LETTER U WITH DIAERESIS-->
        <xsl:text>{&#x00FD;}{{\'{y}}}{1}</xsl:text>    <!--LATIN SMALL LETTER Y WITH ACUTE-->
        <xsl:text>{&#x00FE;}{{\th }}{1}</xsl:text>    <!--LATIN SMALL LETTER THORN-->
        <xsl:text>{&#x00FF;}{{\"{y}}}{1}</xsl:text>    <!--LATIN SMALL LETTER Y WITH DIAERESIS-->
        <xsl:text>}&#xa;</xsl:text> <!-- end of literate set -->
        <xsl:text>%% end: pdflatex-specific listings configuration&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>%% End of generic listing adjustments&#xa;</xsl:text>
        <xsl:if test="$b-has-program">
            <xsl:text>%% Program listings via new tcblisting environment&#xa;</xsl:text>
            <xsl:text>%% First a universal color scheme for parts of any language&#xa;</xsl:text>
            <xsl:if test="not($b-latex-print)" >
                <xsl:text>%% Colors match a subset of Google prettify "Default" style&#xa;</xsl:text>
                <xsl:text>%% Full colors for "electronic" version&#xa;</xsl:text>
                <xsl:text>%% http://code.google.com/p/google-code-prettify/source/browse/trunk/src/prettify.css&#xa;</xsl:text>
                <xsl:text>\definecolor{identifiers}{rgb}{0.375,0,0.375}&#xa;</xsl:text>
                <xsl:text>\definecolor{comments}{rgb}{0.5,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{strings}{rgb}{0,0.5,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{keywords}{rgb}{0,0,0.5}&#xa;</xsl:text>
            </xsl:if>
            <xsl:if test="$b-latex-print" >
                <xsl:text>%% All-black colors for "print" version&#xa;</xsl:text>
                <xsl:text>\definecolor{identifiers}{rgb}{0,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{comments}{rgb}{0,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{strings}{rgb}{0,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{keywords}{rgb}{0,0,0}&#xa;</xsl:text>
            </xsl:if>
            <xsl:text>%% Options passed to the listings package via tcolorbox&#xa;</xsl:text>
            <xsl:text>\lstdefinestyle{programcodestyle}{identifierstyle=\color{identifiers},commentstyle=\color{comments},stringstyle=\color{strings},keywordstyle=\color{keywords}, breaklines=true, breakatwhitespace=true, columns=fixed, extendedchars=true, aboveskip=0pt, belowskip=0pt}&#xa;</xsl:text>
            <!-- This variant style is what will turn on line numbering -->
            <xsl:text>\lstdefinestyle{programcodenumberedstyle}{style=programcodestyle, numbers=left}&#xa;</xsl:text>
            <!-- We want a "program" to be able to break across pages -->
            <!-- 2020-10-07: "breakable" seems ineffective            -->
            <!-- 3 ex left margin moves code off of leftrule by a generous amount -->
            <xsl:text>\tcbset{ programboxstyle/.style={left=3ex, right=0pt, top=0ex, bottom=0ex, middle=0pt, toptitle=0pt, bottomtitle=0pt, boxsep=0pt, &#xa;</xsl:text>
            <xsl:text>listing only, fontupper=\small\ttfamily,&#xa;</xsl:text>
            <xsl:text>colback=white, sharp corners, boxrule=-0.3pt, leftrule=0.5pt, toprule at break=-0.3pt, bottomrule at break=-0.3pt,&#xa;</xsl:text>
            <xsl:text>breakable,&#xa;</xsl:text>
            <xsl:text>} }&#xa;</xsl:text>
            <!-- Repeat the box style, but move numbers out of the margin and past -->
            <!-- the left rule with a 6ex space.  Plenty of room for double-digit  -->
            <!-- line numbers, and should be OK for triple-digits                   -->
            <xsl:text>%% Overwrite the margin to make room for numbers (up to line 999)&#xa;</xsl:text>
            <xsl:text>\tcbset{ programboxnumberedstyle/.style={programboxstyle, left=6ex} }&#xa;</xsl:text>
            <!-- Two "tcblisting" environments for numbered v. not numbered,            -->
            <!-- see switching between them in employment in body                       -->
            <!-- Arguments: language, left margin, width, right margin (latter ignored) -->
            <xsl:text>\newtcblisting{program}[4]{programboxstyle, left skip=#2\linewidth, width=#3\linewidth, listing options={language=#1, style=programcodestyle}}&#xa;</xsl:text>
            <xsl:text>\newtcblisting{programnumbered}[4]{programboxnumberedstyle, left skip=#2\linewidth, width=#3\linewidth, listing options={language=#1, style=programcodenumberedstyle}}&#xa;</xsl:text>
            <!-- Arguments: language, body text. body text must start and end with a    -->
            <!-- single character delimeter not in the text itself.                     -->
            <xsl:text>\newcommand{\programfragment}[2]{\lstinline[language=#1, style=programcodestyle, basicstyle=\ttfamily]#2}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$document-root//console">
            <xsl:text>%% Console session with prompt, input, output&#xa;</xsl:text>
            <xsl:text>%% listings allows for escape sequences to enable LateX,&#xa;</xsl:text>
            <xsl:text>%% so we bold the input commands via the following macro&#xa;</xsl:text>
            <xsl:text>\newcommand{\consoleinput}[1]{\textbf{#1}}&#xa;</xsl:text>
            <!-- https://tex.stackexchange.com/questions/299401/bold-just-one-line-inside-of-lstlisting/299406 -->
            <!-- Syntax highlighting is not so great for "language=bash" -->
            <!-- Line-breaking off to match old behavior, prebreak option fails inside LaTeX for input -->
            <xsl:text>\lstdefinestyle{consolecodestyle}{language=none, escapeinside={(*}{*)}, identifierstyle=, commentstyle=, stringstyle=, keywordstyle=, breaklines=true, breakatwhitespace=true, columns=fixed, extendedchars=true, aboveskip=0pt, belowskip=0pt}&#xa;</xsl:text>
            <!--  -->
            <xsl:text>\tcbset{ consoleboxstyle/.style={left=0pt, right=0pt, top=0ex, bottom=0ex, middle=0pt, toptitle=0pt, bottomtitle=0pt, boxsep=0pt,&#xa;</xsl:text>
            <xsl:text>listing only, fontupper=\small\ttfamily,&#xa;</xsl:text>
            <xsl:text>colback=white, boxrule=-0.3pt, toprule at break=-0.3pt, bottomrule at break=-0.3pt,&#xa;</xsl:text>
            <xsl:text>breakable,&#xa;</xsl:text>
            <xsl:text>} }&#xa;</xsl:text>
            <!-- Arguments: left margin, width, right margin (latter ignored) -->
            <xsl:text>\newtcblisting{console}[3]{consoleboxstyle, left skip=#1\linewidth, width=#2\linewidth, listing options={style=consolecodestyle}}&#xa;</xsl:text>
       </xsl:if>
        <xsl:if test="$b-has-sage">
            <xsl:text>%% The listings package as tcolorbox for Sage code&#xa;</xsl:text>
            <xsl:text>%% We do as much styling as possible with tcolorbox, not listings&#xa;</xsl:text>
            <xsl:text>%% Sage's blue is 50%, we go way lighter (blue!05 would also work)&#xa;</xsl:text>
            <xsl:text>%% Note that we defuse listings' default "aboveskip" and "belowskip"&#xa;</xsl:text>
            <!-- NB: tcblisting "forgets" its colors as it breaks across pages, -->
            <!-- and "frame empty" on the output is not sufficient.  So we set  -->
            <!-- the frame color to white.                                      -->
            <!-- See: https://tex.stackexchange.com/questions/240246/           -->
            <!-- problem-with-tcblisting-at-page-break                          -->
            <!-- TODO: integrate into the LaTeX styling schemes -->
            <xsl:text>\definecolor{sageblue}{rgb}{0.95,0.95,1}&#xa;</xsl:text>
            <xsl:text>\tcbset{ sagestyle/.style={left=0pt, right=0pt, top=0ex, bottom=0ex, middle=0pt, toptitle=0pt, bottomtitle=0pt,&#xa;</xsl:text>
            <xsl:text>boxsep=4pt, listing only, fontupper=\small\ttfamily,&#xa;</xsl:text>
            <xsl:text>breakable, &#xa;</xsl:text>
            <xsl:text>listing options={language=Python,breaklines=true,breakatwhitespace=true, extendedchars=true, aboveskip=0pt, belowskip=0pt}} }&#xa;</xsl:text>
            <xsl:text>\newtcblisting{sageinput}{sagestyle, colback=sageblue, sharp corners, boxrule=0.5pt, toprule at break=-0.3pt, bottomrule at break=-0.3pt, }&#xa;</xsl:text>
            <xsl:text>\newtcblisting{sageoutput}{sagestyle, colback=white, colframe=white, frame empty, before skip=0pt, after skip=0pt, }&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$document-root//pre|$document-root//cd|$document-root//fragment">
        <xsl:text>%% Fancy Verbatim for consoles, preformatted, code display, literate programming&#xa;</xsl:text>
        <xsl:text>\usepackage{fancyvrb}&#xa;</xsl:text>
        <xsl:if test="$document-root//pre|$document-root//fragment">
            <xsl:text>%% Pre-formatted text, a peer of paragraphs&#xa;</xsl:text>
            <xsl:text>\DefineVerbatimEnvironment{preformatted}{Verbatim}{}&#xa;</xsl:text>
        </xsl:if>
        <!-- see commit d2560edd0cc3974c for removal of code for a centered box of verbatim text -->
        <xsl:if test="$document-root//cd">
            <xsl:text>%% code display (cd), by analogy with math display (md)&#xa;</xsl:text>
            <xsl:text>%% (a) indented slightly, so a paragraph appears to hang together&#xa;</xsl:text>
            <xsl:text>\DefineVerbatimEnvironment{codedisplay}{Verbatim}{xleftmargin=4ex}&#xa;</xsl:text>
            <xsl:text>%% (b) flush left works well in exceptions like list items, etc&#xa;</xsl:text>
            <xsl:text>\DefineVerbatimEnvironment{codedisplayleft}{Verbatim}{}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- Lists and related layouts -->
<xsl:template name="list-layout">
    <!-- TODO:  \showidx package as part of a draft mode, prints entries in margin -->
     <xsl:if test="($index-maker = 'pretext') or
                   ($document-root//ol[@cols]|$document-root//ul[@cols]|$document-root//contributors)">
        <xsl:text>%% Multiple column, column-major lists&#xa;</xsl:text>
        <xsl:text>%% ol, ul, contributors, PreTeXt index&#xa;</xsl:text>
        <xsl:text>\usepackage{multicol}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//@landscape">
        <xsl:text>%% The rotating package provides sidewaysfigure and sidewaystables environments&#xa;</xsl:text>
        <xsl:text>\usepackage{rotating}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//ol or $document-root//ul or $document-root//task or $document-root//references or $b-has-webwork-var">
        <xsl:text>%% More flexible list management, esp. for references&#xa;</xsl:text>
        <xsl:text>%% But also for specifying labels (i.e. custom order) on nested lists&#xa;</xsl:text>
        <xsl:text>\usepackage</xsl:text>
        <!-- next test is simpler than necessary, only needed for 'popup' versions of @form -->
        <xsl:if test="$b-has-webwork-var">
            <xsl:text>[inline]</xsl:text>
        </xsl:if>
        <xsl:text>{enumitem}&#xa;</xsl:text>
        <xsl:if test="$document-root//references">
            <xsl:text>%% Lists of references in their own section, maximum depth 1&#xa;</xsl:text>
            <xsl:text>\newlist{referencelist}{description}{4}&#xa;</xsl:text>
            <!-- labelindent defaults to 0, ! means computed -->
            <xsl:text>\setlist[referencelist]{leftmargin=!,labelwidth=!,labelsep=0ex,itemsep=1.0ex,topsep=1.0ex,partopsep=0pt,parsep=0pt}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$document-root//dl">
        <xsl:text>%% Description lists as tcolorbox sidebyside&#xa;</xsl:text>
        <xsl:text>%% "dli" short for "description list item"&#xa;</xsl:text>
        <!-- title widths, gaps, from David Farmer, ~2021-09-15, pretext-support, "inline titles" -->
        <xsl:text>\newlength{\dlititlewidth}&#xa;</xsl:text>
        <xsl:text>\newlength{\dlimaxnarrowtitle}\setlength{\dlimaxnarrowtitle}{11ex}&#xa;</xsl:text>
        <xsl:text>\newlength{\dlimaxmediumtitle}\setlength{\dlimaxmediumtitle}{18ex}&#xa;</xsl:text>
        <!-- "top seam" alignment works better for titles that are display math -->
        <!-- halign applies only to "upper", which is "right" in sidebyside     -->
        <xsl:text>\tcbset{ dlistyle/.style={sidebyside, sidebyside align=top seam, lower separated=false, bwminimalstyle, bottomtitle=0.75ex, after skip=1.5ex, boxsep=0pt, left=0pt, right=0pt, top=0pt, bottom=0pt, before lower app={\setparstyle\noindent}} }&#xa;</xsl:text>
        <xsl:text>\tcbset{ dlinarrowstyle/.style={dlistyle, lefthand width=\dlimaxnarrowtitle, sidebyside gap=1ex, halign=flush left, righttitle=10ex} }&#xa;</xsl:text>
        <xsl:text>\tcbset{ dlimediumstyle/.style={dlistyle, lefthand width=\dlimaxmediumtitle, sidebyside gap=4ex, halign=flush right} }&#xa;</xsl:text>
        <xsl:text>\NewDocumentEnvironment{descriptionlist}{}{\par\vspace*{1.5ex}}{\par\vspace*{1.5ex}}%&#xa;</xsl:text>
        <xsl:text>%% begin enviroment has an if/then to open the tcolorbox&#xa;</xsl:text>
        <xsl:text>\NewDocumentEnvironment{dlinarrow}{mm}{%&#xa;</xsl:text>
        <xsl:text>\settowidth{\dlititlewidth}{{\textbf{#1}}}%&#xa;</xsl:text>
        <xsl:text>\ifthenelse{\dlititlewidth > \dlimaxnarrowtitle}%&#xa;</xsl:text>
        <xsl:text>{\begin{tcolorbox}[title={\textbf{#1}}, phantom={\hypertarget{#2}{}}, dlinarrowstyle]\tcblower}%&#xa;</xsl:text>
        <xsl:text>{\begin{tcolorbox}[dlinarrowstyle, phantom={\hypertarget{#2}{}}]\textbf{#1}\tcblower}%&#xa;</xsl:text>
        <xsl:text>}%&#xa;</xsl:text>
        <xsl:text>{\end{tcolorbox}}%&#xa;</xsl:text>
        <xsl:text>%% medium option is simpler&#xa;</xsl:text>
        <xsl:text>\NewDocumentEnvironment{dlimedium}{mm}%&#xa;</xsl:text>
        <xsl:text>{\begin{tcolorbox}[dlimediumstyle, phantom={\hypertarget{#2}{}}]\textbf{#1}\tcblower}%&#xa;</xsl:text>
        <xsl:text>{\end{tcolorbox}}%&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//exercisegroup">
        <xsl:text>%% Indented groups of "exercise" within an "exercises" division&#xa;</xsl:text>
        <xsl:text>%% Lengths control the indentation (always) and gaps (multi-column)&#xa;</xsl:text>
        <xsl:text>\newlength{\egindent}\setlength{\egindent}{0.05\linewidth}&#xa;</xsl:text>
        <xsl:text>\newlength{\exggap}\setlength{\exggap}{0.05\linewidth}&#xa;</xsl:text>
        <xsl:if test="$document-root//exercisegroup[not(@cols)]">
            <xsl:text>%% Thin "xparse" environments will represent the entire exercise&#xa;</xsl:text>
            <xsl:text>%% group, in the case when it does not hold multiple columns.&#xa;</xsl:text>
            <!-- DO NOT make this a tcolorbox, since we would want it -->
            <!-- to be breakable, and then the individual exercises   -->
            <!-- could not be breakable tcolorbox themselves          -->
            <!-- TODO: add some pre- spacing commands here -->
            <xsl:text>\NewDocumentEnvironment{exercisegroup}{}&#xa;</xsl:text>
            <xsl:text>{}{}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$document-root//exercisegroup/@cols">
            <xsl:text>%% An exercise group with multiple columns is a tcbraster.&#xa;</xsl:text>
            <xsl:text>%% If the contained exercises are explicitly unbreakable,&#xa;</xsl:text>
            <xsl:text>%% the raster should break at rows for page breaks.&#xa;</xsl:text>
            <xsl:text>%% The number of columns is a parameter, passed to tcbraster.&#xa;</xsl:text>
            <!-- raster equal height: boxes of same *row* have same height    -->
            <!-- raster left skip: indentation of all exercises               -->
            <!-- raster columns: controls layout, so no line separators, etc. -->
            <xsl:text>\tcbset{ exgroupcolstyle/.style={raster equal height=rows, raster left skip=\egindent, raster column skip=\exggap} }&#xa;</xsl:text>
            <xsl:text>\NewDocumentEnvironment{exercisegroupcol}{m}&#xa;</xsl:text>
            <xsl:text>{\begin{tcbraster}[exgroupcolstyle,raster columns=#1]}{\end{tcbraster}}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$document-root//index-list">
        <!-- See http://tex.blogoverflow.com/2012/09/dont-forget-to-run-makeindex/ for "imakeidx" usage -->
        <xsl:text>%% Support for index creation&#xa;</xsl:text>
        <xsl:if test="$author-tools-new = 'no'">
            <xsl:text>%% imakeidx package does not require extra pass (as with makeidx)&#xa;</xsl:text>
            <xsl:text>%% Title of the "Index" section set via a keyword&#xa;</xsl:text>
            <xsl:text>%% Language support for the "see" and "see also" phrases,&#xa;</xsl:text>
            <xsl:text>%% but to do so presumes exactly one "index-list" generator is present&#xa;</xsl:text>
            <xsl:text>\usepackage{imakeidx}&#xa;</xsl:text>
            <!-- context for localization is single extant $document-root//index-list -->
            <!-- Restrict to just a single instance, multiple may be unpredictable    -->
            <xsl:variable name="the-index" select="($document-root//index-list)[1]"/>
            <!-- NB: multiple indices will require major adjustments here             -->
            <xsl:text>\makeindex[title=</xsl:text>
            <xsl:apply-templates select="$the-index" mode="type-name">
                <xsl:with-param name="string-id" select="'index'"/>
            </xsl:apply-templates>
            <xsl:text>, intoc=true]&#xa;</xsl:text>
            <xsl:text>\renewcommand{\seename}{</xsl:text>
            <xsl:apply-templates select="$the-index" mode="type-name">
                <xsl:with-param name="string-id" select="'see'"/>
            </xsl:apply-templates>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>\renewcommand{\alsoname}{</xsl:text>
            <xsl:apply-templates select="$the-index" mode="type-name">
                <xsl:with-param name="string-id" select="'also'"/>
            </xsl:apply-templates>
           <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$author-tools-new = 'yes'">
            <xsl:text>%% author-tools = 'yes' activates marginal notes about index&#xa;</xsl:text>
            <xsl:text>%% and supresses the actual creation of the index itself&#xa;</xsl:text>
            <xsl:text>\usepackage{showidx}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$docinfo/logo">
        <xsl:text>%% Package for precise image placement (for logos on pages)&#xa;</xsl:text>
        <xsl:text>\usepackage{eso-pic}&#xa;</xsl:text>
    </xsl:if>
    <!-- Lists are built as "longtable" so they span multiple pages    -->
    <!-- and get "continuation" footers, for example.  It is the       -->
    <!-- "list generator" element which provokes the package inclusion -->
    <!-- An author can elect breakable "tabular" as well                -->
    <xsl:if test="$b-has-long-tabular">
        <xsl:text>%% Package for tables (potentially) spanning multiple pages&#xa;</xsl:text>
        <xsl:text>\usepackage{longtable}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- http://tex.stackexchange.com/questions/106159/why-i-shouldnt-load-pdftex-option-with-hyperref -->
<xsl:template name="load-configure-hyperref">
    <xsl:text>%% hyperref driver does not need to be specified, it will be detected&#xa;</xsl:text>
    <xsl:text>%% Footnote marks in tcolorbox have broken linking under&#xa;</xsl:text>
    <xsl:text>%% hyperref, so it is necessary to turn off all linking&#xa;</xsl:text>
    <xsl:text>%% It *must* be given as a package option, not with \hypersetup&#xa;</xsl:text>
    <xsl:text>\usepackage[hyperfootnotes=false]{hyperref}&#xa;</xsl:text>
    <!-- http://tex.stackexchange.com/questions/79051/how-to-style-text-in-hyperref-url -->
    <xsl:if test="$document-root//url">
    <xsl:text>%% configure hyperref's  \href{}{}  and  \nolinkurl  to match listings' inline verbatim&#xa;</xsl:text>
        <xsl:text>\renewcommand\UrlFont{\small\ttfamily}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="not($b-latex-print)">
        <xsl:text>%% Hyperlinking active in electronic PDFs, all links without surrounding boxes and blue&#xa;</xsl:text>
        <xsl:text>\hypersetup{colorlinks=true,linkcolor=blue,citecolor=blue,filecolor=blue,urlcolor=blue}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$b-latex-print">
        <xsl:text>%% For a print PDF, no surrounding boxes, so simply textcolor (but still active to preserve spacing)&#xa;</xsl:text>
        <!-- https://tex.stackexchange.com/questions/503000/          -->
        <!-- unexpected-value-for-option-hidelinkshyperref-is-ignored -->
        <!-- https://tex.stackexchange.com/a/503001                   -->
        <xsl:text>\hypersetup{hidelinks}&#xa;</xsl:text>
    </xsl:if>
    <!-- Hyperref gives names to destinations for links that look like      -->
    <!-- "section*.5.2" which you can guess is the second section of        -->
    <!-- Chapter 5.  But if you have structural parts and chapter names     -->
    <!-- do not incorporate part numbers, then you can get two "chapter*.3" -->
    <!-- and things like the Table of Contents do not work as expected.     -->
    <!-- Instead you can have hyperref use names like "chapter.748" from a  -->
    <!-- sequential numbering that will always provide unique names.        -->
    <!-- Short, but concise, explanation:                                   -->
    <!-- https://tex.stackexchange.com/questions/3188/                      -->
    <!-- what-does-the-hyperref-option-hypertexnames-do                     -->
    <!--                                                                    -->
    <!-- Another approach is to "renewcommand" macros like "\theHchapter"   -->
    <!-- within respective environments to use our LaTeX label (usually a   -->
    <!-- final parameter of the environment).  These make very interesting  -->
    <!-- names in files like "*.out" and "*.toc", a dotted hierachy of very -->
    <!-- long strings.  For us, the origin of these are 100% unambiguous    -->
    <!-- (an of course, unique).  But very verbose.  And the environment    -->
    <!-- changes need to go lots of places to have the same effect.  But a  -->
    <!-- simple experiment was very effective at resolving just chapters in -->
     <!-- structural parts.                                                 -->
    <!--                                                                    -->
    <!-- For both approaches, see revalatory post:                          -->
    <!-- https://tex.stackexchange.com/questions/231361/                    -->
    <!-- table-of-contents-labels-not-directing-hyperlinks-to-correct-page  -->
    <xsl:text>%% Less-clever names for hyperlinks are more reliable, *especially* for structural parts&#xa;</xsl:text>
    <xsl:text>%% See comments in the code to learn more about the importance of this setting&#xa;</xsl:text>
    <xsl:text>\hypersetup{hypertexnames=false}&#xa;</xsl:text>
    <!-- Index entries now have the correct (printed) page number, but the -->
    <!-- hyperlink is way off (owing to significant front matter) and uses -->
    <!-- a page number that is way too early.  Fix comes from the answer:  -->
    <!--     https://tex.stackexchange.com/a/516275                        -->
    <!-- on the post:                                                      -->
    <!--     https://tex.stackexchange.com/questions/516267/               -->
    <!--     compatibility-of-hypertexnames-false-and-indexes              -->
    <xsl:text>%%The  hypertexnames  setting then confuses the hyperlinking from the index&#xa;</xsl:text>
    <xsl:text>%%This patch resolves the incorrect links, see code for StackExchange post.&#xa;</xsl:text>
    <xsl:text>\makeatletter&#xa;</xsl:text>
    <xsl:text>\patchcmd\Hy@EveryPageBoxHook{\Hy@EveryPageAnchor}{\Hy@hypertexnamestrue\Hy@EveryPageAnchor}{}{\fail}&#xa;</xsl:text>
    <xsl:text>\makeatother&#xa;</xsl:text>
    <!-- Title goes interesting places in a PDF -->
    <xsl:text>\hypersetup{pdftitle={</xsl:text>
    <xsl:apply-templates select="." mode="title-short" />
    <xsl:text>}}&#xa;</xsl:text>
    <!-- http://tex.stackexchange.com/questions/44088/when-do-i-need-to-invoke-phantomsection -->
    <!-- NB: \phantomsection is rarely used - literate programming fragments and the ToC      -->
    <xsl:text>%% If you manually remove hyperref, leave in this next command&#xa;</xsl:text>
    <xsl:text>%% This will allow LaTeX compilation, employing this no-op command&#xa;</xsl:text>
    <xsl:text>\providecommand\phantomsection{}&#xa;</xsl:text>
</xsl:template>

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
    <!-- Variables hold exactly one node of each type in use -->
    <!-- "environment" template constructs...environments -->
    <!-- THEOREM-LIKE -->
    <xsl:variable name="theorem-reps" select="
        ($document-root//theorem)[1]|
        ($document-root//lemma)[1]|
        ($document-root//corollary)[1]|
        ($document-root//algorithm)[1]|
        ($document-root//proposition)[1]|
        ($document-root//claim)[1]|
        ($document-root//fact)[1]|
        ($document-root//identity)[1]"/>
    <xsl:if test="$theorem-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for THEOREM-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$theorem-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- PROOF-LIKE -->
    <!-- detached/standalone and inner are same style     -->
    <!-- solution have a more minimal (hard-coded) style -->
    <xsl:variable name="proof-reps" select="
        ($document-root//proof[ancestor::hint|ancestor::answer|ancestor::solution])[1]|
        ($document-root//proof[not(ancestor::hint|ancestor::answer|ancestor::solution)])[1]|
        ($document-root//argument[ancestor::hint|ancestor::answer|ancestor::solution])[1]|
        ($document-root//argument[not(ancestor::hint|ancestor::answer|ancestor::solution)])[1]|
        ($document-root//justification[ancestor::hint|ancestor::answer|ancestor::solution])[1]|
        ($document-root//justification[not(ancestor::hint|ancestor::answer|ancestor::solution)])[1]|
        ($document-root//reasoning[ancestor::hint|ancestor::answer|ancestor::solution])[1]|
        ($document-root//reasoning[not(ancestor::hint|ancestor::answer|ancestor::solution)])[1]|
        ($document-root//explanation[ancestor::hint|ancestor::answer|ancestor::solution])[1]|
        ($document-root//explanation[not(ancestor::hint|ancestor::answer|ancestor::solution)])[1]"/>
    <xsl:if test="$proof-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for PROOF-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$proof-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- AXIOM-LIKE -->
    <xsl:variable name="axiom-reps" select="
        ($document-root//axiom)[1]|
        ($document-root//conjecture)[1]|
        ($document-root//principle)[1]|
        ($document-root//heuristic)[1]|
        ($document-root//hypothesis)[1]|
        ($document-root//assumption)[1]"/>
    <xsl:if test="$axiom-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for AXIOM-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$axiom-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- DEFINITION-LIKE -->
    <xsl:variable name="definition-reps" select="
        ($document-root//definition)[1]"/>
    <xsl:if test="$definition-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for DEFINITION-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$definition-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- REMARK-LIKE -->
    <!-- NB: a "note" in "biblio" is a (harmless?) false positive here -->
    <xsl:variable name="remark-reps" select="
        ($document-root//remark)[1]|
        ($document-root//convention)[1]|
        ($document-root//note)[1]|
        ($document-root//observation)[1]|
        ($document-root//warning)[1]|
        ($document-root//insight)[1]"/>
    <xsl:if test="$remark-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for REMARK-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$remark-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- COMPUTATION-LIKE -->
    <xsl:variable name="computation-reps" select="
        ($document-root//computation)[1]|
        ($document-root//technology)[1]|
        ($document-root//data)[1]"/>
    <xsl:if test="$computation-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for COMPUTATION-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$computation-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- OPENPROBLEM-LIKE -->
    <xsl:variable name="openproblem-reps" select="
        ($document-root//openproblem)[1]|
        ($document-root//openquestion)[1]|
        ($document-root//openconjecture)[1]"/>
    <xsl:if test="$openproblem-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for OPENPROBLEM-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$openproblem-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- EXAMPLE-LIKE -->
    <xsl:variable name="example-reps" select="
        ($document-root//example)[1]|
        ($document-root//question)[1]|
        ($document-root//problem)[1]"/>
    <xsl:if test="$example-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for EXAMPLE-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$example-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- Inline Exercises -->
    <xsl:variable name="inlineexercise-reps" select="
        ($document-root//exercise[boolean(&INLINE-EXERCISE-FILTER;)])[1]"/>
    <xsl:if test="$inlineexercise-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for inline exercises&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$inlineexercise-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- PROJECT-LIKE -->
    <!-- "project-rep" variable defined twice (each local) -->
    <!-- Used several times, search on "project-reps"      -->
    <xsl:variable name="project-reps" select="
        ($document-root//project)[1]|
        ($document-root//activity)[1]|
        ($document-root//exploration)[1]|
        ($document-root//investigation)[1]"/>
    <xsl:if test="$project-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for PROJECT-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$project-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
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
    <!-- INTRODUCTION, CONCLUSION (divisional) -->
    <xsl:variable name="introduction-reps" select="
        ($root/article/introduction|$document-root//chapter/introduction|$document-root//section/introduction|$document-root//subsection/introduction|$document-root//appendix/introduction|$document-root//exercises/introduction|$document-root//solutions/introduction|$document-root//worksheet/introduction|$document-root//handout/introduction|$document-root//reading-questions/introduction|$document-root//glossary/introduction|$document-root//references/introduction)[1]|
        ($root/article/conclusion|$document-root//chapter/conclusion|$document-root//section/conclusion|$document-root//subsection/conclusion|$document-root//appendix/conclusion|$document-root//exercises/conclusion|$document-root//solutions/conclusion|$document-root//worksheet/conclusion|$document-root//handout/conclusion|$document-root//handout/conclusion|$document-root//reading-questions/conclusion|$document-root//glossary/conclusion|$document-root//references/conclusion)[1]"/>
    <xsl:if test="$introduction-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% xparse environments for introductions and conclusions of divisions&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$introduction-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- MISCELLANEOUS -->
    <!-- "paragraphs" are partly like a division, -->
    <!-- but we include it here as a one-off      -->
    <xsl:variable name="miscellaneous-reps" select="
        ($document-root//gi)[1]|
        ($document-root//case)[1]|
        ($document-root//assemblage)[1]|
        ($document-root//backmatter/colophon)[1]|
        ($document-root//paragraphs)[1]"/>
    <xsl:if test="$miscellaneous-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for miscellaneous environments&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$miscellaneous-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
</xsl:template>

<!-- Watermark -->
<xsl:template name="watermark">
    <xsl:if test="$b-watermark or $b-latex-watermark">
        <xsl:text>\usepackage{draftwatermark}&#xa;</xsl:text>
        <xsl:text>\SetWatermarkText{</xsl:text>
        <xsl:value-of select="$watermark-text" />
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\SetWatermarkScale{</xsl:text>
        <xsl:value-of select="$watermark-scale" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- showkeys for author tools -->
<xsl:template name="showkeys">
    <xsl:if test="$author-tools-new = 'yes'" >
        <xsl:text>%% Collected author tools options (author-tools='yes')&#xa;</xsl:text>
        <xsl:text>%% others need to be elsewhere, these are simply package additions&#xa;</xsl:text>
        <xsl:text>\usepackage{showkeys}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- latex-image support -->
<xsl:template name="latex-image-support">
    <xsl:if test="$latex-image-preamble">
        <xsl:text>%% Graphics Preamble Entries&#xa;</xsl:text>
        <xsl:value-of select="$latex-image-preamble"/>
    </xsl:if>
    <xsl:text>%% If tikz has been loaded, replace ampersand with \amp macro&#xa;</xsl:text>
    <xsl:if test="$document-root//latex-image">
        <xsl:text>\ifdefined\tikzset&#xa;</xsl:text>
        <xsl:text>    \tikzset{ampersand replacement = \amp}&#xa;</xsl:text>
        <xsl:text>\fi&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Side-by-side environmnet -->
<xsl:template name="sidebyside-environment">
    <xsl:if test="$document-root//sidebyside">
        <!-- "minimal" is no border or spacing at all -->
        <!-- set on $sbsdebug to "tight" with some background    -->
        <!-- From the tcolorbox manual, "center" vs. "flush center":      -->
        <!-- "The differences between the flush and non-flush version     -->
        <!-- are explained in detail in the TikZ manual. The short story  -->
        <!-- is that the non-flush versions will often look more balanced -->
        <!-- but with more hyphenations."                                 -->
        <xsl:choose>
            <xsl:when test="$sbsdebug">
                <xsl:text>%% tcolorbox styles for *DEBUGGING* sidebyside layout&#xa;</xsl:text>
                <xsl:text>%% "tight" -> 0.4pt border, pink background&#xa;</xsl:text>
                <xsl:text>\tcbset{ sbsstyle/.style={raster equal height=rows,raster force size=false} }&#xa;</xsl:text>
                <xsl:text>\tcbset{ sbspanelstyle/.style={size=tight,colback=pink} }&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>%% tcolorbox styles for sidebyside layout&#xa;</xsl:text>
                <!-- "frame empty" is needed to counteract very faint outlines in some PDF viewers -->
                <!-- framecol=white is inadvisable, "frame hidden" is ineffective for default skin -->
                <xsl:text>\tcbset{ sbsstyle/.style={raster before skip=2.0ex, raster equal height=rows, raster force size=false, raster after skip=0.7\baselineskip} }&#xa;</xsl:text>
                <xsl:text>\tcbset{ sbspanelstyle/.style={bwminimalstyle, fonttitle=\blocktitlefont, before upper app={\setparstyle}} }&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>%% Enviroments for side-by-side and components&#xa;</xsl:text>
        <xsl:text>%% Necessary to use \NewTColorBox for boxes of the panels&#xa;</xsl:text>
        <xsl:text>%% "newfloat" environment to squash page-breaks within a single sidebyside&#xa;</xsl:text>
        <!-- Main side-by-side environment, given by xparse            -->
        <!-- raster equal height: boxes of same *row* have same height -->
        <!-- raster force size: false lets us control width            -->
        <!-- We do not try here to keep captions attached (when not    -->
        <!-- in a "figure"), unfortunately, this is an un-semantic     -->
        <!-- command inbetween the list of panels and the captions     -->
        <xsl:text>%% "xparse" environment for entire sidebyside&#xa;</xsl:text>
        <xsl:text>\NewDocumentEnvironment{sidebyside}{mmmm}&#xa;</xsl:text>
        <xsl:text>  {\begin{tcbraster}&#xa;</xsl:text>
        <xsl:text>    [sbsstyle,raster columns=#1,&#xa;</xsl:text>
        <xsl:text>    raster left skip=#2\linewidth,raster right skip=#3\linewidth,raster column skip=#4\linewidth]}&#xa;</xsl:text>
        <xsl:text>  {\end{tcbraster}}&#xa;</xsl:text>
        <xsl:text>%% "tcolorbox" environment for a panel of sidebyside&#xa;</xsl:text>
        <xsl:text>\NewTColorBox{sbspanel}{mO{top}}{sbspanelstyle,width=#1\linewidth,valign=#2}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- kbd keys -->
<xsl:template name="kbd-keys">
    <xsl:if test="$document-root//kbd">
        <!-- https://github.com/tweh/menukeys/issues/41 -->
        <xsl:text>%% menukeys package says:&#xa;</xsl:text>
        <xsl:text>%%   Since menukeys uses catoptions, which does some heavy&#xa;</xsl:text>
        <xsl:text>%%   changes on key-value options, it is recommended to load&#xa;</xsl:text>
        <xsl:text>%%   menukeys as the last package (even after hyperref)!&#xa;</xsl:text>
        <xsl:text>\usepackage{menukeys}&#xa;</xsl:text>
        <!-- https://tex.stackexchange.com/questions/96300/how-to-change-the-style-of-menukeys -->
        <xsl:text>\renewmenumacro{\keys}{shadowedroundedkeys}&#xa;</xsl:text>
        <!-- Seemingly extra braces protect comma that kbdkeys package uses -->
        <xsl:text>\newcommand{\kbd}[1]{\keys{{#1}}}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Late preamble, misc. adjustments           -->
<!-- NB: This could be split up more if needed. -->
<xsl:template name="late-preamble-adjustments">
    <!-- N.B. Author-supplied LaTeX macros come *after* the -->
    <!-- late-preamble stringparam in order that an author  -->
    <!-- cannot attempt a conversion-specific redefinition  -->
    <!-- of a macro that has been used used in a less       -->
    <!-- capable conversion, i.e. HTML/MathJax              -->
    <xsl:text>%% Custom Preamble Entries, late (use latex.preamble.late)&#xa;</xsl:text>
    <xsl:if test="$latex.preamble.late != ''">
        <xsl:value-of select="$latex.preamble.late" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <!-- "extra" packages specified by the author -->
    <xsl:variable name="latex-packages">
        <xsl:for-each select="$docinfo/math-package">
            <!-- must be specified, but can be empty/null -->
            <xsl:if test="not(normalize-space(@latex-name)) = ''">
                <xsl:text>\usepackage{</xsl:text>
                <xsl:value-of select="@latex-name"/>
                <xsl:apply-templates/>
                <xsl:text>}</xsl:text>
                <!-- one per line for readability -->
                <xsl:text>&#xa;</xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>
    <!-- We could use contains() on the 5 types of arrows  -->
    <!-- to really defend against this problematic package -->
    <!-- 2023-10-19: this test is buggy, there is no consideration -->
    <!-- of "men", while "md" and "mrow" are duplicative           -->
    <xsl:if test="$document-root//m|$document-root//md|$document-root//mrow">
        <xsl:choose>
            <xsl:when test="contains($latex-packages, '\usepackage{extpfeil}')">
                <xsl:text>%% You have elected to load the LaTeX "extpfeil" package&#xa;</xsl:text>
                <xsl:text>%% for certain extensible arrows, and it should appear just below.&#xa;</xsl:text>
                <xsl:text>%% This package has numerous shortcomings leading to conflicts with&#xa;</xsl:text>
                <xsl:text>%% packages like "stmaryrd" and our manipulations of lengths to support&#xa;</xsl:text>
                <xsl:text>%% variable thickness of rules in tables.  It should appear late&#xa;</xsl:text>
                <xsl:text>%% in the preamble in an effort to mitigate these shortcomings.&#xa;</xsl:text>
            </xsl:when>
            <!-- 2023-10-19: at the first hint of trouble with automatic loading of this package,     -->
            <!-- feel free to jettison the "otherwise" clause.  Then move the warning (in the "when") -->
            <!-- to simply condition on the appearance in the list of packages being included.        -->
            <!-- Following preserves backward-compatible behavior.                                    -->
            <xsl:otherwise>
                <xsl:text>%% extpfeil package for certain extensible arrows,&#xa;</xsl:text>
                <xsl:text>%% as also provided by MathJax extension of the same name&#xa;</xsl:text>
                <xsl:text>%% NB: this package loads mtools, which loads calc, which redefines&#xa;</xsl:text>
                <xsl:text>%%     \setlength, so it can be removed if it seems to be in the &#xa;</xsl:text>
                <xsl:text>%%     way and your math does not use:&#xa;</xsl:text>
                <xsl:text>%%     &#xa;</xsl:text>
                <xsl:text>%%     \xtwoheadrightarrow, \xtwoheadleftarrow, \xmapsto, \xlongequal, \xtofrom&#xa;</xsl:text>
                <xsl:text>%%     &#xa;</xsl:text>
                <xsl:text>%%     we have had to be extra careful with variable thickness&#xa;</xsl:text>
                <xsl:text>%%     lines in tables, and so also load this package late&#xa;</xsl:text>
                <xsl:text>\usepackage{extpfeil}&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <xsl:if test="not($latex-packages = '')">
        <xsl:text>%% Begin: Author-provided TeX/LaTeX packages&#xa;</xsl:text>
        <xsl:text>%% (From  docinfo/math-package  elements)&#xa;</xsl:text>
        <xsl:value-of select="$latex-packages"/>
        <xsl:text>%% End: Author-provided TeX/LaTeX packages&#xa;</xsl:text>
    </xsl:if>
    <!-- "extra" macros specified by the author -->
    <xsl:text>%% Begin: Author-provided macros&#xa;</xsl:text>
    <xsl:text>%% (From  docinfo/macros  element)&#xa;</xsl:text>
    <xsl:text>%% Plus three from PTX for XML characters&#xa;</xsl:text>
    <xsl:value-of select="$latex-macros" />
    <xsl:text>%% End: Author-provided macros&#xa;</xsl:text>
    <!-- 2023-10-18: source has \sfrac{}{} macro, but now author needs     -->
    <!-- to specify the LaTeX "xfrac" package in a docinfo/math-package    -->
    <!-- element to continue support.  This is the fallback subpar macro,  -->
    <!-- just like we use in HTML, when author has not loaded the package. -->
    <!-- Perhaps relevant: http://tex.stackexchange.com/questions/3372/    -->
    <xsl:if test="$b-has-sfrac and not(contains($latex-packages, '\usepackage{xfrac}'))">
        <xsl:text>%% Historical (subpar) support for \sfrac macro&#xa;</xsl:text>
        <xsl:text>%% to achieve pleasing slanted (beveled) fractions.&#xa;</xsl:text>
        <xsl:text>%% Add "xfrac" package with a  docinfo/math-package  element&#xa;</xsl:text>
        <xsl:text>%% to achieve superior typesetting in LaTeX/PDF output&#xa;</xsl:text>
        <xsl:text>\newcommand{\sfrac}[2]{{#1}/{#2}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//contributors">
        <xsl:text>%% Semantic macros for contributor list&#xa;</xsl:text>
        <xsl:text>\newcommand{\contributor}[1]{\parbox{\linewidth}{#1}\par\bigskip}&#xa;</xsl:text>
        <xsl:text>\newcommand{\contributorname}[1]{\textsc{#1}\\[0.25\baselineskip]}&#xa;</xsl:text>
        <xsl:text>\newcommand{\contributorinfo}[1]{\hspace*{0.05\linewidth}\parbox{0.95\linewidth}{\textsl{#1}}}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- End of Preamble Templates -->


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

<!-- Sidedness -->
<!-- \documentclass option, no comma -->
<xsl:template name="sidedness">
    <xsl:choose>
        <xsl:when test="$latex-sides= 'one'">
            <xsl:text>oneside</xsl:text>
        </xsl:when>
        <xsl:when test="$latex-sides= 'two'">
            <xsl:text>twoside</xsl:text>
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

<!-- Fill-in-the-blank in text content -->
<xsl:template name="fillin-text">
    <xsl:text>%% Used for fillin answer blank in text&#xa;</xsl:text>
    <xsl:text>%% Relies on calc package, loaded via tcolorbox&#xa;</xsl:text>
    <xsl:text>%% Argument is intended number of characters of blank&#xa;</xsl:text>
    <xsl:text>%% Length may compress for output to fit in one line&#xa;</xsl:text>
    <xsl:text>\newlength{\fillinmaxwidth}&#xa;</xsl:text>
    <xsl:text>\newlength{\fillincontract}&#xa;</xsl:text>
    <xsl:text>\newlength{\charmaxwidth}\setlength{\charmaxwidth}{0.5em}&#xa;</xsl:text>
    <xsl:text>\newlength{\charminwidth}\setlength{\charminwidth}{0.1em}&#xa;</xsl:text>
    <xsl:text>\newlength{\fillinheight}&#xa;</xsl:text>
    <xsl:if test="$fillin-text-style = 'shade'">
        <xsl:text>\definecolor{fillintextshade}{gray}{0.9}</xsl:text>
    </xsl:if>
    <xsl:text>\newcommand{\fillintext}[1]{%&#xa;</xsl:text>
    <xsl:text>\setlength{\fillinmaxwidth}{#1\charmaxwidth}%&#xa;</xsl:text>
    <xsl:text>\setlength{\fillincontract}{#1\charminwidth}%&#xa;</xsl:text>
    <xsl:text>\setlength{\fillinheight}{\baselineskip}\addtolength{\fillinheight}{1.2pt}%&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="$fillin-text-style = 'underline'">
            <xsl:text>\strut\nobreak\leaders\vbox{\hrule width 0.3pt height 0.3pt \vskip -1.2pt}\hskip 1\fillinmaxwidth minus \fillincontract\nobreak\strut%&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$fillin-text-style = 'box'">
            <xsl:text>\rule[-1.2pt]{0.3pt}{\heightof{\strut}+1.8pt}\nobreak\hspace{-0.3pt}\nobreak\leaders\vbox{\hrule width 0.3pt height 0.3pt \vskip \fillinheight \hrule width 0.3pt height 0.3pt \vskip -1.2pt}\hskip 1\fillinmaxwidth minus \fillincontract\nobreak\hspace{-0.3pt}\rule[-1.2pt]{0.3pt}{\heightof{\strut}+1.8pt}%&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$fillin-text-style = 'shade'">
            <xsl:text>{\color{fillintextshade}\strut\nobreak\leaders\vbox{\hrule width 0.3pt height \fillinheight \vskip -1.2pt}\hskip 1\fillinmaxwidth minus \fillincontract}%&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Vertical workspace for worksheets and handouts -->
<xsl:template match="*" mode="workspace">
    <xsl:variable name="vertical-space">
        <xsl:apply-templates select="." mode="sanitize-workspace"/>
    </xsl:variable>
    <xsl:if test="not($vertical-space = '')">
        <xsl:text>\par\rule{\workspacestrutwidth}{</xsl:text>
        <xsl:value-of select="$vertical-space"/>
        <xsl:text>}%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- When workspace is requested, we call the modal "sanitize-workspace" which in -->
<!-- pretext-common returns an empty string if the requested workspace is not in  -->
<!-- an appropriate division.  But we automatically want the empty string if the  -->
<!-- publisher variable latex-worksheet-formatted is not set to "yes", so here we -->
<!-- only apply the template in pretext-common if the variable is set to "yes".   -->
<!-- NB: it is important to do this here and not in the  pretext-common           -->
<!-- stylesheet's template since that is also used for HTML                       -->
<xsl:template match="*" mode="sanitize-workspace">
    <xsl:if test="$b-latex-worksheet-formatted">
        <xsl:apply-imports/>
    </xsl:if>
</xsl:template>


<!--##################################-->
<!-- PTX Divisions to LaTeX Divisions -->
<!--##################################-->


<!-- PTX has a variety of divisions not native to LaTeX, so normally -->
<!-- an author would have to engineer/design these themselves.  We   -->
<!-- do something similar and implement them using the stock LaTeX   -->
<!-- divisons.  This is the dictionary which maps PreTeXt division   -->
<!-- elements to stock LaTeX division environments.                  -->
<!-- NB: we formerly did this using the "level" template and the     -->
<!-- "level-to-name" templates, which we should consider obsoleting, -->
<!-- simplifying, or consolidating.                                  -->
<xsl:template match="part|chapter|section|subsection|subsubsection" mode="division-name">
    <xsl:value-of select="local-name(.)"/>
</xsl:template>

<!-- Front matter divisions are only in book, and always at chapter level -->
<xsl:template match="acknowledgement|foreword|preface" mode="division-name">
    <xsl:text>chapter</xsl:text>
</xsl:template>

<!-- Some divisions can appear at multiple levels (eg, exercises) -->
<!-- Divisions in the back matter vary between books and articles -->
<!--     Book:    children of backmatter -> chapter               -->
<!--     Article: children of backmatter -> section               -->
<xsl:template match="exercises|solutions|worksheet|handout|reading-questions|references|glossary|appendix|index" mode="division-name">
    <xsl:choose>
        <xsl:when test="parent::article">
            <xsl:text>section</xsl:text>
        </xsl:when>
        <xsl:when test="parent::chapter">
            <xsl:text>section</xsl:text>
        </xsl:when>
        <xsl:when test="parent::section">
            <xsl:text>subsection</xsl:text>
        </xsl:when>
        <xsl:when test="parent::subsection">
            <xsl:text>subsubsection</xsl:text>
        </xsl:when>
        <xsl:when test="parent::subsubsection">
            <xsl:text>paragraph</xsl:text>
        </xsl:when>
        <!-- children of backmatter (appendix, solutions, reference, index) -->
        <!-- in book/article are at chapter/section level                   -->
        <xsl:when test="parent::backmatter">
            <xsl:choose>
                <xsl:when test="ancestor::book">
                    <xsl:text>chapter</xsl:text>
                </xsl:when>
                <xsl:when test="ancestor::article">
                    <xsl:text>section</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
        <!-- appendix in book/article is at chapter/section level -->
        <!-- so descendants (exercises, solutions) down one level -->
        <xsl:when test="parent::appendix">
            <xsl:choose>
                <xsl:when test="ancestor::book">
                    <xsl:text>section</xsl:text>
                </xsl:when>
                <xsl:when test="ancestor::article">
                    <xsl:text>subsection</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="division-name">
    <xsl:message>PTX:BUG: Asking for the name of an element (<xsl:value-of select="local-name(.)" />) that is not a division</xsl:message>
</xsl:template>

<!-- ####################### -->
<!-- LaTeX Macro Definitions -->
<!-- ####################### -->

<!-- These are not yet meant for style writer use. -->

<!-- Abbreviations, Acronyms, Initialisms, -->
<!-- "abbr", "acro", "init"                -->
<!-- Body: \abbreviation{ABC}              -->
<!-- Titles: \abbreviationuntitle{ABC}     -->
<!-- PDF navigation panels has titles as simple strings,    -->
<!-- devoid of any formatting, so we just give up, as any   -->
<!-- attempt to use title-specific macros, \texorpdfstring, -->
<!-- \protect, \DeclareRobustCommand does not help get      -->
<!-- ToC, PDF navigation panel, text heading all correct    -->
<!-- Obstacle is that sc shape does not come in bold,       -->
<!-- http://tex.stackexchange.com/questions/17830/using-textsc-within-section -->
<xsl:template match="abbr" mode="tex-macro">
    <xsl:text>\newcommand{\abbreviation}[1]{</xsl:text>
    <xsl:text>%% Used to markup abbreviations, text or titles&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="tex-macro-style"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\DeclareRobustCommand{\abbreviationintitle}[1]{\texorpdfstring{#1}{#1}}&#xa;</xsl:text>
</xsl:template>
<xsl:template match="acro" mode="tex-macro">
    <xsl:text>%% Used to markup acronyms, text or titles&#xa;</xsl:text>
    <xsl:text>\newcommand{\acronym}[1]{</xsl:text>
    <xsl:apply-templates select="." mode="tex-macro-style"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\DeclareRobustCommand{\acronymintitle}[1]{\texorpdfstring{#1}{#1}}&#xa;</xsl:text>
</xsl:template>
<xsl:template match="init" mode="tex-macro">
    <xsl:text>%% Used to markup initialisms, text or titles&#xa;</xsl:text>
    <xsl:text>\newcommand{\initialism}[1]{</xsl:text>
    <xsl:apply-templates select="." mode="tex-macro-style"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\DeclareRobustCommand{\initialismintitle}[1]{\texorpdfstring{#1}{#1}}&#xa;</xsl:text>
</xsl:template>

<!-- ############################# -->
<!-- LaTeX Environment Definitions -->
<!-- ############################# -->

<!-- These are not yet meant for style writer use. -->

<!-- Notes: -->
<!-- *  Generally, all boxes should be "breakable"     -->
<!--    tcolorbox uses minipages and parboxes, which   -->
<!--    seem to kill indentation and line spacing to   -->
<!--    delineate paragraphs. If the contents can be   -->
<!--    reasonably expected toto be organized as       -->
<!--    paragraphs we add to the style:                -->
<!--                                                   -->
<!--    before upper app={\setparstyle} -->
<!--                                                   -->
<!--    which *appends* to the "before upper" code     -->
<!--    and requires the tcolorbox "hooks" library.    -->
<!--    Order may be important (such as after          -->
<!--    "runinstyle") and we may not  have it right    -->
<!--    everywhere.                                    -->
<!-- *  The  etoolbox  package has some good tools     -->
<!-- *  Some items need a "phantom={\hypertarget{}{}}" -->
<!--    search on mode="xref-as-ref" for more          -->
<!-- *  Traditional LaTeX labels are implemented with  -->
<!--    tcolorbox "phantomlabel=" option               -->
<!-- *  tcolor box seem to begin in horizontal mode,   -->
<!--    and need to return to vertical mode once       -->
<!--    concluded (lest, e.g., consecutive boxes       -->
<!--    overlap). Use of "after={\par}" is the right   -->
<!--    fix.  See                                      -->
<!--    https://tex.stackexchange.com/questions/235848 -->
<!--    /how-to-leave-horizontal-mode                  -->

<!-- Style: -->
<!-- Provide some comments for the LaTeX source, to aid     -->
<!-- with standalone use or debugging.  Preface with "%% ". -->

<!-- We have lots of divisions, some traditional (chapters),      -->
<!-- some one-off (preface), some pervasive (exercises).  Many    -->
<!-- are always numbered (chapters), some are never numbered      -->
<!-- (prefaces), some go both ways (exercises).  All get their    -->
<!-- own environments, with two for the numbered/unnumbered.      -->
<!-- Traditional need a suffix 'ptx' to distinguish from the      -->
<!-- built-in LaTeX names, one-off get their own natural name,    -->
<!-- and pervasive get a suffix that indicates their level.       -->
<!--                                                              -->
<!-- These environments will be defined using the LaTeX macros    -->
<!-- which correspond to the traditional names, so as to leverage -->
<!-- LaTeX numbering, titlesec styling, and migration of titles   -->
<!-- to running heads via the cooperating titleps package.  But   -->
<!-- the environments will also be enhanced through the titlesec  -->
<!-- package to allow the seamless addition of authors and        -->
<!-- epigraphs, in addition to actual styling.                    -->

<!-- "introduction", "conclusion" -->
<!-- Body:  \begin{outcomes}{title}              -->
<!-- Divisional, want to obsolete title soon     -->
<!-- Simple, w/ temporary run-in title, no label -->
<!-- (so don't merge with other titled environments) -->

<!-- NB: Once upon a time, this was a breakable tcolorbox.  But then if   -->
<!-- the contents were too complicated, then a breakable tcolorbox might  -->
<!-- be contained (like a theorem, say).  That interior breakable         -->
<!-- tcolorbox would *automatically* be made unbreakable, and the result  -->
<!-- was really bad page breaks, or worse, the potential for the interior -->
<!-- box dribbling off the bottom of the page.                            -->
<xsl:template match="introduction|conclusion" mode="environment">
    <xsl:variable name="environment-name">
        <xsl:value-of select="local-name(.)"/>
    </xsl:variable>
    <xsl:text>%% </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>: in a structured division&#xa;</xsl:text>
    <xsl:text>\NewDocumentEnvironment{</xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>}{m}&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="self::introduction">
            <xsl:text>{\notblank{#1}{\noindent\textbf{#1}\space}{}}</xsl:text>
        </xsl:when>
        <xsl:when test="self::conclusion">
            <xsl:text>{\par\medskip\noindent\notblank{#1}{\textbf{#1}\space}{}}</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:choose>
        <xsl:when test="self::introduction">
            <xsl:text>{\par\medskip}</xsl:text>
        </xsl:when>
        <xsl:when test="self::conclusion">
            <xsl:text>{}</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- A division has a PTX name via local-name() and a corresponding -->
<!-- LaTeX traditional division via the "division-name" template.   -->
<!-- The following templates build the names of the environments,   -->
<!-- so we can build and employ them consistently.                  -->

<!-- Traditional -->
<!-- Add suffix to avoid clashes (NB: \appendix, \index exists) -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|index" mode="division-environment-name">
    <xsl:value-of select="local-name(.)"/>
    <xsl:text>ptx</xsl:text>
</xsl:template>

<!-- One-Off -->
<!-- Free here to use the PTX name, without clashing with LaTeX -->
<xsl:template match="acknowledgement|foreword|preface" mode="division-environment-name">
    <xsl:value-of select="local-name(.)"/>
</xsl:template>

<!-- Pervasive -->
<!-- Specialized divisions                         -->
<!-- Product of PTX name with LaTeX level/division -->
<xsl:template match="exercises|solutions|worksheet|handout|reading-questions|glossary|references|index" mode="division-environment-name">
    <xsl:value-of select="local-name(.)"/>
    <xsl:text>-</xsl:text>
    <xsl:apply-templates select="." mode="division-name"/>
</xsl:template>

<xsl:template match="*" mode="division-environment-name">
    <xsl:message>NO DIVISION ENVIRONMENT NAME for <xsl:value-of select="local-name(.)"/></xsl:message>
</xsl:template>

<!-- Possibly numberless?  When employed, we can tell if a specialized -->
<!-- division should be numberless at birth.  This needs to be broken  -->
<!-- out since when we *create* the environments in the preamble we    -->
<!-- just make "regular" and "numberless" variants, always.            -->
<xsl:template match="exercises|worksheet|handout|references|glossary|reading-questions|solutions" mode="division-environment-name-suffix">
    <xsl:variable name="is-numbered">
        <xsl:apply-templates select="." mode="is-specialized-own-number"/>
    </xsl:variable>
    <xsl:if test="$is-numbered = 'false'">
        <xsl:text>-numberless</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Only specialized divisions get a "numberless" variant, -->
<!-- so we return nothing and do not call a template about  -->
<!-- specialized divisions improperly                       -->
<xsl:template match="*" mode="division-environment-name-suffix"/>

<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|acknowledgement|foreword|preface|index|exercises|solutions|worksheet|handout|reading-questions|glossary|references" mode="environment">
    <!-- for specialized divisions we always make a numbered -->
    <!-- and unnumbered version, with the latter happening   -->
    <!-- on a second trip through the template               -->
    <xsl:param name="second-trip" select="false()"/>

    <xsl:variable name="elt-name" select="local-name(.)"/>
    <!-- the (traditional) LaTex name of this division -->
    <xsl:variable name="div-name">
        <xsl:apply-templates select="." mode="division-name"/>
    </xsl:variable>
    <!-- explanatory string in preamble -->
    <xsl:text>%% Environment for a PTX "</xsl:text>
    <xsl:value-of select="$elt-name"/>
    <xsl:text>" at the level of a LaTeX "</xsl:text>
    <xsl:value-of select="$div-name"/>
    <xsl:text>"&#xa;</xsl:text>
    <!-- Define implementation of a 5-argument environment          -->
    <!-- Template ensures consistency of definition and application -->
    <xsl:text>\NewDocumentEnvironment{</xsl:text>
    <xsl:apply-templates select="." mode="division-environment-name"/>
    <!-- second trip through for a specialized -->
    <!-- division, build unnumbered version    -->
    <xsl:if test="$second-trip">
        <xsl:text>-numberless</xsl:text>
    </xsl:if>
    <xsl:text>}{mmmmmmm}&#xa;</xsl:text>
    <xsl:text>{%&#xa;</xsl:text>
    <!-- load 6 macros with values, for style writer use -->
    <xsl:text>\renewcommand{\divisionnameptx}{#1}%&#xa;</xsl:text>
    <xsl:text>\renewcommand{\titleptx}{#2}%&#xa;</xsl:text>
    <xsl:text>\renewcommand{\subtitleptx}{#3}%&#xa;</xsl:text>
    <xsl:text>\renewcommand{\shortitleptx}{#4}%&#xa;</xsl:text>
    <xsl:text>\renewcommand{\authorsptx}{#5}%&#xa;</xsl:text>
    <xsl:text>\renewcommand{\epigraphptx}{#6}%&#xa;</xsl:text>
    <!-- invoke the right LaTeX division, causes title format -->
    <!-- and spacing, along with setting running heads        -->
    <xsl:text>\</xsl:text>
    <xsl:value-of select="$div-name"/>
    <xsl:choose>
        <!-- Second trip through, building unnumbered version -->
        <!-- OR                                               -->
        <!-- Never numbered, always build a starred form      -->
        <!-- and manually add short version to ToC            -->
        <xsl:when test="$second-trip or boolean(self::acknowledgement|self::foreword|self::preface|self::index)">
            <xsl:text>*</xsl:text>
            <xsl:text>{#2}%&#xa;</xsl:text>
            <xsl:text>\addcontentsline{toc}{</xsl:text>
            <xsl:value-of select="$div-name"/>
            <xsl:text>}{#4}&#xa;</xsl:text>
        </xsl:when>
        <!-- optional short title, and the real title  -->
        <!-- NB: the short title (#3) needs a group to -->
        <!-- protect a right square bracket "]" from   -->
        <!-- prematurely ending the optional argument  -->
        <xsl:otherwise>
            <xsl:text>[{#4}]{#2}%&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\label{#7}%&#xa;</xsl:text>
    <!-- close the environment definition, no finish -->
    <xsl:text>}{}%&#xa;</xsl:text>
    <!-- send specialized division back through a second time -->
    <xsl:if test="not($second-trip) and boolean(self::exercises|self::solutions|self::worksheet|self::handout|self::reading-questions|self::glossary|self::references)">
        <xsl:apply-templates select="." mode="environment">
            <xsl:with-param name="second-trip" select="true()"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- PROOF-LIKE (regular, major) -->
<!-- Breakable tcolorbox since a child of a       -->
<!-- division, i.e. top level, and hence stylable -->
<!-- Body:  \begin{proof}{title}{label}           -->
<!-- Title comes with punctuation, always.        -->
<xsl:template match="*[&PROOF-FILTER;][not(&SOLUTION-PROOF-FILTER;)]" mode="environment">
    <xsl:variable name="proof-name" select="local-name(.)"/>
    <xsl:text>%% proof: title is a replacement&#xa;</xsl:text>
    <xsl:text>\tcbset{ </xsl:text>
    <xsl:value-of select="$proof-name"/>
    <xsl:text>style/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style" />
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{</xsl:text>
    <xsl:value-of select="$proof-name"/>
    <xsl:text>}[3]{title={\notblank{#2}{#2}{#1.}}, phantom={</xsl:text>
    <xsl:if test="$b-pageref">
        <xsl:text>\label{#3}</xsl:text>
    </xsl:if>
    <xsl:text>\hypertarget{#3}{}}, breakable, after={\par}, </xsl:text>
    <xsl:value-of select="$proof-name"/>
    <xsl:text>style, before upper app={\setparstyle} }&#xa;</xsl:text>
</xsl:template>

<!-- PROOF-LIKE (solutions, minor) -->
<!-- NOT a tcolorbox since embedded in others,      -->
<!-- hence an inner box and thus always unbreakable -->
<!-- Body:  \begin{solutionproof}                   -->
<!-- Really simple.  No label, so not a target of a -->
<!-- cross-reference.  Not stylable, though we      -->
<!-- could use a macro for the tombstone/Halmos/QED -->
<!-- so that could be set.                          -->
<xsl:template match="*[&PROOF-FILTER;][&SOLUTION-PROOF-FILTER;]" mode="environment">
    <xsl:text>\NewDocumentEnvironment{solution</xsl:text>
    <xsl:value-of select="local-name(.)"/>
    <xsl:text>}{m}&#xa;</xsl:text>
    <xsl:text>{\par\smallskip\noindent\textit{#1}.\space\space}{\space\space\hspace*{\stretch{1}}\(\blacksquare\)\par\smallskip}&#xa;</xsl:text>
</xsl:template>

<!-- "case" (of a PROOF-LIKE) -->
<!-- Body:  \begin{proof}{directionarrow}{title}{label} -->
<!-- Title comes with punctuation, always.              -->
<!-- TODO: move implication definitions here, and       -->
<!-- pass semantic strings out of the construction      -->
<xsl:template match="case" mode="environment">
    <xsl:text>\NewDocumentEnvironment{case}{mmmm}&#xa;</xsl:text>
    <xsl:text>{\par\medskip\noindent\notblank{#2}{#2\space{}}{}\textit{\notblank{#3}{#3\space{}}{}\notblank{#2#3}{}{#1.\space{}}}</xsl:text>
    <xsl:if test="$b-pageref">
        <xsl:text>\label{#4}</xsl:text>
    </xsl:if>
    <xsl:text>\hypertarget{#4}{}}{}&#xa;</xsl:text>
</xsl:template>

<!-- "objectives" -->
<!-- Body:  \begin{objectives}{m:title}    -->
<!-- Title comes without new punctuation.  -->
<xsl:template match="objectives" mode="environment">
    <xsl:text>%% objectives: early in a subdivision, introduction/list/conclusion&#xa;</xsl:text>
    <xsl:text>\tcbset{ objectivesstyle/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style" />
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{objectives}[2]{title={#1}, phantomlabel={#2}, breakable, objectivesstyle, before upper app={\setparstyle}}&#xa;</xsl:text>
</xsl:template>

<!-- "outcomes" -->
<!-- Body:  \begin{outcomes}{m:title}      -->
<!-- Title comes without new punctuation.  -->
<xsl:template match="outcomes" mode="environment">
    <xsl:text>%% outcomes: late in a subdivision, introduction/list/conclusion&#xa;</xsl:text>
    <xsl:text>\tcbset{ outcomesstyle/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style" />
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{outcomes}[2]{title={#1}, phantomlabel={#2}, breakable, outcomesstyle, before upper app={\setparstyle}}&#xa;</xsl:text>
</xsl:template>

<!-- back "colophon" -->
<!-- Body:  \begin{backcolophon}{label} -->
<xsl:template match="backmatter/colophon" mode="environment">
    <xsl:text>%% back colophon, at the very end, typically on its own page&#xa;</xsl:text>
    <xsl:text>\tcbset{ backcolophonstyle/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style" />
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{backcolophon}[2]{title={#1}, phantom={</xsl:text>
    <xsl:if test="$b-pageref">
        <xsl:text>\label{#2}</xsl:text>
    </xsl:if>
    <xsl:text>\hypertarget{#2}{}}, breakable, backcolophonstyle, before upper app={\setparstyle}}&#xa;</xsl:text>
</xsl:template>

<!-- "assemblage" -->
<!-- Identical to ASIDE-LIKE, but we keep it distinct -->
<xsl:template match="assemblage" mode="environment">
    <!-- Names of various pieces use the element name -->
    <xsl:variable name="environment-name">
        <xsl:value-of select="local-name(.)"/>
    </xsl:variable>
    <xsl:text>%% </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>: fairly simple un-numbered block/structure&#xa;</xsl:text>
    <xsl:text>\tcbset{ </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style"/>
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{</xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>}[3]{title={\notblank{#2}{#2}{}}, </xsl:text>
    <xsl:text>phantomlabel={#3}, breakable, </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style, before upper app={\setparstyle}}&#xa;</xsl:text>
</xsl:template>

<!-- "gi" -->
<!-- A "glossary item"                         -->
<!-- Body:  \begin{glossaryitem}{title}{label} -->
<xsl:template match="gi" mode="environment">
    <xsl:text>%% glossary item, style and tcolorbox&#xa;</xsl:text>
    <xsl:text>\tcbset{ glossaryitemstyle/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style" />
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{glossaryitem}[2]{title={#1}, after title={\notblank{#1}{\space}{}}, phantomlabel={#2}, breakable, glossaryitemstyle, before upper app={\setparstyle}}&#xa;</xsl:text>
</xsl:template>

<!-- "paragraphs" -->
<!-- Body:  \begin{paragraphs}{title}{label}   -->
<!-- "titlesec" package, Subsection 9.2 has LaTeX defaults -->
<!-- We drop the indentation, and we pass the title itself -->
<!-- explicity with macro parameter #1 since we do not save-->
<!-- off the title in a PTX macro.  None of this is meant  -->
<!-- to support customization in a style.                  -->
<!-- Once a tcolorbox, see warnings as part of divisional  -->
<!-- introductions and conclusions.                        -->
<xsl:template match="paragraphs" mode="environment">
    <xsl:text>%% paragraphs: the terminal, pseudo-division&#xa;</xsl:text>
    <xsl:text>%% We use the lowest LaTeX traditional division&#xa;</xsl:text>
    <xsl:text>\titleformat{\subparagraph}[runin]{\normalfont\normalsize\bfseries}{\thesubparagraph}{1em}{#1}&#xa;</xsl:text>
    <xsl:text>\titlespacing*{\subparagraph}{0pt}{3.25ex plus 1ex minus .2ex}{1em}&#xa;</xsl:text>
    <xsl:text>\NewDocumentEnvironment{paragraphs}{mm}&#xa;</xsl:text>
    <xsl:text>{\subparagraph*{#1}</xsl:text>
    <xsl:if test="$b-pageref">
        <xsl:text>\label{#2}</xsl:text>
    </xsl:if>
    <xsl:text>\hypertarget{#2}{}}{}&#xa;</xsl:text>
</xsl:template>

<!-- ASIDE-LIKE: "aside", "historical", "biographical" -->
<!-- Note: do not integrate into others, as treatment may necessarily vary -->
<xsl:template match="&ASIDE-LIKE;" mode="environment">
    <!-- Names of various pieces use the element name -->
    <xsl:variable name="environment-name">
        <xsl:value-of select="local-name(.)"/>
    </xsl:variable>
    <xsl:text>%% </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>: fairly simple un-numbered block/structure&#xa;</xsl:text>
    <xsl:text>\tcbset{ </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style"/>
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{</xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>}[3]{title={\notblank{#2}{#2}{}}, </xsl:text>
    <xsl:text>phantomlabel={#3}, breakable, </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style, before upper app={\setparstyle}}&#xa;</xsl:text>
</xsl:template>


<!-- THEOREM-LIKE: "theorem", "corollary", "lemma",    -->
<!--               "algorithm", "proposition",         -->
<!--               "claim", "fact", "identity"         -->
<!-- AXIOM-LIKE: "axiom", "conjecture", "principle",   -->
<!--             "heuristic", "hypothesis",            -->
<!--             "assumption                           -->
<!-- DEFINITION-LIKE: "definition"                     -->
<!-- REMARK-LIKE: "remark", "convention", "note",      -->
<!--              "observation", "warning", "insight"  -->
<!-- COMPUTATION-LIKE: "computation", "technology",    -->
<!--                    "data"                         -->
<!-- OPENPROBLEM-LIKE: "openproblem", "openquestion"   -->
<!-- EXAMPLE-LIKE: "example", "question", "problem"    -->
<!-- PROJECT-LIKE: "activity", "exploration",          -->
<!--               "exploration", "investigation"      -->
<!-- Inline Exercises                                  -->
<!-- Body: \begin{example}{title}{label}, etc.         -->
<!--       \begin{inlineexercise}{title}{label}        -->
<!-- Type, number, optional title                      -->
<!-- Title comes without new punctuation.              -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;|&DEFINITION-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&OPENPROBLEM-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|exercise[boolean(&INLINE-EXERCISE-FILTER;)]" mode="environment">
    <!-- Names of various pieces normally use the      -->
    <!-- element name, but "exercise" does triple duty -->
    <xsl:variable name="environment-name">
        <xsl:choose>
            <!-- TODO: filter is redundant, here and below, given match? -->
            <xsl:when test="self::exercise and boolean(&INLINE-EXERCISE-FILTER;)">
                <xsl:text>inlineexercise</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="local-name(.)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- projects and inline exercises sometimes run on their own counters -->
    <xsl:variable name="counter">
        <xsl:choose>
            <xsl:when test="(&PROJECT-FILTER;) and $b-number-project-distinct">
                <xsl:text>project-distinct</xsl:text>
            </xsl:when>
            <xsl:when test="self::exercise and boolean(&INLINE-EXERCISE-FILTER;) and $b-number-exercise-distinct">
                <xsl:text>exercise-distinct</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>block</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>%% </xsl:text>
    <!-- per-environment style -->
    <xsl:value-of select="$environment-name"/>
    <xsl:text>: fairly simple numbered block/structure&#xa;</xsl:text>
    <xsl:text>\tcbset{ </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style"/>
    <xsl:text>} }&#xa;</xsl:text>
    <!-- create and configure the environment/tcolorbox -->
    <xsl:text>\newtcolorbox</xsl:text>
    <!-- run on a common, default, faux counter -->
    <xsl:text>[</xsl:text>
    <xsl:text>use counter from=</xsl:text>
    <xsl:value-of select="$counter"/>
    <xsl:text>]</xsl:text>
    <!-- environment's tcolorbox name, pair -->
    <!-- with actual constructions in body  -->
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>}</xsl:text>
    <!-- number of arguments -->
    <xsl:choose>
        <xsl:when test="&THEOREM-FILTER; or &AXIOM-FILTER;">
            <xsl:text>[4]</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[3]</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- begin: options -->
    <xsl:text>{</xsl:text>
    <!-- begin: title construction -->
    <xsl:text>title={{#1~\thetcbcounter</xsl:text>
    <xsl:choose>
        <xsl:when test="&THEOREM-FILTER; or &AXIOM-FILTER;">
            <!-- first space of double space -->
            <xsl:text>\notblank{#2#3}{\space}{}</xsl:text>
            <xsl:text>\notblank{#2}{\space#2}{}</xsl:text>
            <xsl:text>\notblank{#3}{\space(#3)}{}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\notblank{#2}{\space\space#2}{}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}}, </xsl:text>
    <!-- end: title construction -->
    <!-- label in argument 3 or argument 4 -->
    <xsl:choose>
        <xsl:when test="&THEOREM-FILTER; or &AXIOM-FILTER;">
            <xsl:text>phantomlabel={#4}, </xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>phantomlabel={#3}, </xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- always breakable -->
    <xsl:text>breakable, after={\par}, </xsl:text>
    <!-- italic body (this should be set elsewhere) -->
    <xsl:if test="&THEOREM-FILTER; or &AXIOM-FILTER;">
        <xsl:text>fontupper=\itshape, </xsl:text>
    </xsl:if>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style, }&#xa;</xsl:text>
    <!-- end: options -->
</xsl:template>

<xsl:template match="figure|table|listing|list" mode="environment">
    <xsl:variable name="fig-placement">
        <xsl:apply-templates select="." mode="figure-placement"/>
    </xsl:variable>
    <xsl:variable name="b-subnumbered" select="$fig-placement = 'subnumber'"/>
    <xsl:variable name="b-panel" select="$fig-placement = 'panel'"/>
    <xsl:variable name="environment-name">
        <xsl:apply-templates select="." mode="environment-name"/>
    </xsl:variable>
    <!-- counters may run as: subnumbers, independently, or with blocks -->
    <xsl:variable name="counter">
        <xsl:choose>
            <xsl:when test="$b-subnumbered">
                <xsl:text>subdisplay</xsl:text>
            </xsl:when>
            <xsl:when test="$b-number-figure-distinct">
                <xsl:text>figure-distinct</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>block</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>%% </xsl:text>
    <!-- per-environment style -->
    <xsl:value-of select="$environment-name"/>
    <xsl:text>: 2-D display structure&#xa;</xsl:text>
    <xsl:text>\tcbset{ </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style"/>
    <xsl:text>} }&#xa;</xsl:text>
    <!-- subnumbered version requires manipulating low-level counters -->
    <xsl:if test="$b-subnumbered">
        <xsl:text>\makeatletter&#xa;</xsl:text>
    </xsl:if>
    <!-- create and configure the environment/tcolorbox -->
    <xsl:text>\newtcolorbox</xsl:text>
    <xsl:text>[</xsl:text>
    <xsl:text>use counter from=</xsl:text>
    <xsl:value-of select="$counter"/>
    <xsl:text>]</xsl:text>
    <!-- environment's tcolorbox name, pair -->
    <!-- with actual constructions in body  -->
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>}</xsl:text>
    <!-- number of arguments -->
    <xsl:text>[4]</xsl:text>
    <!-- begin: options -->
    <xsl:text>{</xsl:text>
    <!-- begin: title/caption construction -->
    <xsl:choose>
        <!-- Captions/titlesof 2D displays within panels of figure/sidebyside  -->
        <!-- \thetcbcounter comes from subdisplay, looks like 25.3(b),         -->
        <!-- and this is what will render in a cross-reference via \label/\ref -->
        <!-- The enclosing figure is numbered from block or figure-distinct.   -->
        <!-- We us the "xstring" package to strip out this number (e.g. 25.3)  -->
        <!-- and leave just the sub-numbering (e.g, (b)).                      -->
        <!-- NB: parameter #3 is a hardcoded number supplied by the -common    -->
        <!-- routines, since it gets massaged to (a), (b), (c), etc. and this  -->
        <!-- part is independent of the structure number, it will be right     -->
        <!-- even if the LaTeX source is a subset (we can't optionally include -->
        <!-- panels of a "sidebyside").  Short answer, we ignore #3 in this    -->
        <!-- case.  Always.                                                    -->
        <xsl:when test="$b-subnumbered">
            <xsl:text>lower separated=false, </xsl:text>
            <xsl:text>before lower={{</xsl:text>
            <xsl:choose>
                <xsl:when test="$b-number-figure-distinct">
                    <xsl:text>\textbf{\StrSubstitute{\thetcbcounter}{\thetcb@cnt@figure-distinct}{}}</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\textbf{\StrSubstitute{\thetcbcounter}{\thetcb@cnt@block}{}}</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>\space#2</xsl:text>
            <xsl:text>}}, </xsl:text>
        </xsl:when>
        <!-- Case for text placed below, but "regular" numbers.  "figure"  -->
        <!-- and "listing" always, and always for panels of a side-by-side -->
        <!-- not already handled as subnumbered panels.                    -->
        <!-- Only the type-number is bolded, caption in #1 is plain text   -->
        <xsl:when test="self::figure or $b-panel">
            <xsl:text>lower separated=false, </xsl:text>
            <xsl:text>before lower={{</xsl:text>
            <xsl:text>\textbf{#1~</xsl:text>
            <xsl:choose>
                <xsl:when test="$b-latex-hardcode-numbers">
                    <xsl:text>#4</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\thetcbcounter</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>}</xsl:text>
            <xsl:text>\space#2</xsl:text>
            <xsl:text>}}, </xsl:text>
        </xsl:when>
        <!-- Case for titles placed above with "regular" numbers,            -->
        <!-- just remaining "table", "list" and "listing", as per CMoS       -->
        <!-- Only the type-number is bolded here, caption in #1 is bold text -->
        <xsl:when test="self::table|self::list|self::listing">
            <xsl:text>title={{</xsl:text>
            <xsl:text>\textbf{#1~</xsl:text>
            <xsl:choose>
                <xsl:when test="$b-latex-hardcode-numbers">
                    <xsl:text>#4</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\thetcbcounter</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>}</xsl:text>
            <xsl:text>\space#2</xsl:text>
            <xsl:text>}}, </xsl:text>
        </xsl:when>
    </xsl:choose>
    <!-- end: title/caption construction -->
    <!-- label in argument 2             -->
    <xsl:text>phantomlabel={#3}, </xsl:text>
    <!-- always unbreakable, except for "list"               -->
    <!-- and list needs paragraph=style indentation restored -->
    <!-- 2023-09-01: next comment seems incorrect?           -->
    <!-- list will be unbreakable once inside sidebyside     -->
    <xsl:choose>
        <xsl:when test="self::list">
            <xsl:text>breakable, </xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>unbreakable, </xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style, </xsl:text>
    <xsl:if test="self::list">
        <xsl:text>before upper app={\setparstyle}, </xsl:text>
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
    <!-- end: options -->
    <!-- subnumbered version requires manipulating low-level counters -->
    <xsl:if test="$b-subnumbered">
        <xsl:text>\makeatother&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- ########################## -->
<!-- LaTeX Styling via Preamble -->
<!-- ########################## -->

<!-- General Notes: -->
<!--                -->
<!-- * Protect tcolorbox arguments with braces, especially titles, -->
<!--   since commas will bleed through into the options otherwise  -->
<!-- * Separate the tcolorbox options with spaces after commas     -->
<!-- * Run the LaTeX compilation at least twice before giving up   -->
<!-- * The tcolorbox "title" option is set in the environment      -->
<!-- * End lists of styling options with a trailing comma          -->
<!-- * tcolorbox, boxrule=-0.3pt seems necessary to avoid          -->
<!--   very faint lines/rules appearing in some PDF viewers,       -->
<!--   not clear if "frame empty" is also necessary                -->
<!-- * See discussion of end-of-block markers (eg, a PROOF-LIKE    -->
<!--   tombstone/Halmos) at the default style for PROOF-LIKE       -->

<!-- "abbr", "acro", "init" -->
<!-- We default to small caps for abbreviations, acronyms, and  -->
<!-- initialisms.  See Bringhurst, 4e, 3.2.2, p. 48.  These can -->
<!-- be overridden with simply "#1" to provide macros that just -->
<!-- repeat their arguments.                                    -->
<!-- lower-casing macro:  ("force-all-small-caps") at           -->
<!-- http://tex.stackexchange.com/questions/114592/             -->
<xsl:template match="abbr|acro|init" mode="tex-macro-style">
    <!-- <xsl:text>{\scshape #1}</xsl:text> -->
    <xsl:text>\textsc{\MakeLowercase{#1}}</xsl:text>
</xsl:template>

<!-- Colors -->
<!-- This named template is called immediately after the "xcolor"     -->
<!-- package is loaded.  It can be overridden to define colors used   -->
<!-- later in a style, so as to modularize these choices.  It is      -->
<!-- provisional since there may be better ways to specify or handle  -->
<!--                                                                  -->
<!--   (a) switching easily between color and black-and-white schemes -->
<!--   (b) specifiying a default set of color names employed          -->
<!--       automatically in certain locations                         -->
<!--                                                                  -->
<!-- Both of these features could be handled in an ad-hoc way now     -->
<xsl:template name="xcolor-style"/>

<!-- "introduction", "conclusion" -->
<!-- Run-in optional title, which will eventually go away       -->
<!-- We add a gap before just a "conclusion", using XSL.        -->
<!-- If you are using this as an example/guide, and don't       -->
<!-- understand this more advanced use of XSL, just make two    -->
<!-- templates, one for "introduction" and one for "conclusion" -->
<xsl:template match="introduction|conclusion" mode="tcb-style">
    <xsl:text>bwminimalstyle, runintitlestyle, blockspacingstyle, </xsl:text>
    <xsl:if test="self::conclusion">
        <xsl:text>before skip=3ex</xsl:text>
    </xsl:if>
</xsl:template>

<!-- PROOF-LIKE -->
<!-- Title in italics, as in amsthm style.           -->
<!-- Filled, black square as QED, tombstone, Halmos. -->
<!-- Pushing the tombstone flush-right is a bit      -->
<!-- ham-handed, but more elegant TeX-isms           -->
<!-- (eg \hfill) did not get it done.  We require at -->
<!-- least two spaces gap to remain on the same      -->
<!-- line. Presumably the line will stretch when the -->
<!-- tombstone moves onto its own line.              -->
<!-- NB: this style is NOT used for a PROOF-LIKE     -->
<!-- inside a "hint", "answer", or "solution", since -->
<!-- that would lead to an inner tcolorbox which is  -->
<!-- *always* unbreakable and leads to real          -->
<!-- formatting problems.  We could restrict the     -->
<!-- match, but that would complicate style writing. -->
<!-- Instead, this template is simply not employed   -->
<!-- for the "solution proof" case.                  -->
<xsl:template match="&PROOF-LIKE;" mode="tcb-style">
    <xsl:text>bwminimalstyle, fonttitle=\blocktitlefont\itshape, attach title to upper, after title={\space}, after upper={\space\space\hspace*{\stretch{1}}\(\blacksquare\)},&#xa;</xsl:text>
</xsl:template>

<!-- "objectives" -->
<!-- Rules top and bottom, title on its own line, as a heading -->
<xsl:template match="objectives" mode="tcb-style">
    <xsl:text>bwminimalstyle, blockspacingstyle, fonttitle=\blocktitlefont\large\bfseries, toprule=0.1ex, toptitle=0.5ex, top=2ex, bottom=0.5ex, bottomrule=0.1ex</xsl:text>
</xsl:template>

<!-- "outcomes" -->
<!-- Differs only by spacing prior, this could go away  -->
<!-- if headings, etc handle vertical space correctly   -->
<xsl:template match="outcomes" mode="tcb-style">
    <xsl:text>bwminimalstyle, blockspacingstyle, fonttitle=\blocktitlefont\large\bfseries, toprule=0.1ex, toptitle=0.5ex, top=2ex, bottom=0.5ex, bottomrule=0.1ex, before skip=2ex</xsl:text>
</xsl:template>

<!-- back "colophon" -->
<xsl:template match="backmatter/colophon" mode="tcb-style">
    <xsl:text>bwminimalstyle, blockspacingstyle, before skip=5ex, left skip=0.15\textwidth, right skip=0.15\textwidth, fonttitle=\blocktitlefont\large\bfseries, center title, halign=center, bottomtitle=2ex</xsl:text>
</xsl:template>

<!-- "gi" -->
<!-- Differs only by spacing prior, this could go away  -->
<!-- if headings, etc handle vertical space correctly   -->
<xsl:template match="gi" mode="tcb-style">
    <xsl:text>bwminimalstyle, runintitlestyle, </xsl:text>
</xsl:template>


<!-- THEOREM-LIKE: "theorem", "corollary", "lemma",    -->
<!--               "algorithm", "proposition",         -->
<!--               "claim", "fact", "identity"         -->
<!-- AXIOM-LIKE: "axiom", "conjecture", "principle",   -->
<!--             "heuristic", "hypothesis",            -->
<!--             "assumption                           -->
<!-- DEFINITION-LIKE: "definition"                     -->
<!-- REMARK-LIKE: "remark", "convention", "note",      -->
<!--              "observation", "warning", "insight"  -->
<!-- COMPUTATION-LIKE: "computation", "technology",    -->
<!--                    "data"                         -->
<!-- OPENPROBLEM-LIKE: "openproblem", "openquestion"   -->
<!-- EXAMPLE-LIKE: "example", "question", "problem"    -->
<!-- PROJECT-LIKE: "activity", "exploration",          -->
<!--               "exploration", "investigation"      -->
<!-- ASIDE-LIKE: "aside", "historical", "biographical" -->
<!-- Inline Exercises                                  -->
<!--                                                   -->
<!-- Inline, bold face title, otherwise B/W, plain     -->
<!-- The "\normalfont" on the title is to counteract   -->
<!-- the italicized bodies of theorems and axioms      -->
<!-- coming from the "environment" template, since the -->
<!-- title is being smashed inline into the upper part -->
<!-- of the box.  It has no effect on other            -->
<!-- environments.  But ideally, we would split out    -->
<!-- this piece into a template for just theorems      -->
<!-- and axioms.                                       -->
<!-- DEFINITION-LIKE and EXAMPLE-LIKE are exceptional  -->
<!-- in that markers are inserted with "after upper"   -->
<!-- to indicate the end of the environment.           -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&OPENPROBLEM-LIKE;|&PROJECT-LIKE;|exercise[boolean(&INLINE-EXERCISE-FILTER;)]|&ASIDE-LIKE;" mode="tcb-style">
    <xsl:text>bwminimalstyle, runintitlestyle, blockspacingstyle, after title={\space}, before upper app={\setparstyle}, </xsl:text>
</xsl:template>

<xsl:template match="&DEFINITION-LIKE;" mode="tcb-style">
    <xsl:text>bwminimalstyle, runintitlestyle, blockspacingstyle, after title={\space}, after upper={\space\space\hspace*{\stretch{1}}\(\lozenge\)}, before upper app={\setparstyle}, </xsl:text>
</xsl:template>

<xsl:template match="&EXAMPLE-LIKE;" mode="tcb-style">
    <xsl:text>bwminimalstyle, runintitlestyle, blockspacingstyle, after title={\space}, after upper={\space\space\hspace*{\stretch{1}}\(\square\)}, before upper app={\setparstyle}, </xsl:text>
</xsl:template>

<!-- FIGURE-LIKE: -->
<!-- 2019-08-08: ad-hoc for now, named-styles will evolve      -->
<!-- "table", "list", and "listing" are very similar (titles)  -->
<!-- NB: these will be used for "plain" 2D displays and for    -->
<!-- when these are the panels of a "sidebyside".  So within   -->
<!-- environments we bold titles (table and list) as produced, -->
<!-- and do not bold captions as produced.  This way titles    -->
<!-- that migrate to the lower part when subnumbered will be   -->
<!-- bold.  So we also bold type names and numbers as          -->
<!-- produced. Net result is that we do not apply font weights -->
<!-- to titles via styles.                                     -->
<!-- NB: there could be 4 more styles, conditioning all 8 on   -->
<!-- "ancestor::*[self::figure]" (or "not()") to manage the    -->
<!-- panels of a subnumbered sidebyside.                      -->
<xsl:template match="figure" mode="tcb-style">
    <xsl:text>bwminimalstyle, middle=1ex, blockspacingstyle, fontlower=\blocktitlefont</xsl:text>
</xsl:template>

<!-- panels of a subnumbered sidebyside.                      -->
<xsl:template match="listing" mode="tcb-style">
    <xsl:text>bwminimalstyle, blockspacingstyle, bottomtitle=2ex, fonttitle=\blocktitlefont</xsl:text>
</xsl:template>

<!-- This style is "breakable" to allow for "tabular" realized as "longtable". -->
<!-- Normally a table will not break at all, so the breakability of the        -->
<!-- tcolorbox is not really relevant.  This is in lieu of trying to make      -->
<!-- a special-case style within the confines of the semi-elaborate process    -->
<!-- of naming/using styles. -->
<xsl:template match="table" mode="tcb-style">
    <xsl:text>bwminimalstyle, middle=1ex, blockspacingstyle, coltitle=black, bottomtitle=2ex, titlerule=-0.3pt, fonttitle=\blocktitlefont, breakable</xsl:text>
</xsl:template>

<!-- "list" contents are breakable, so we rub out annoying faint lines -->
<xsl:template match="list" mode="tcb-style">
    <xsl:text>middle=1ex, blockspacingstyle, colback=white, colbacktitle=white, coltitle=black, colframe=black, titlerule=-0.3pt, toprule at break=-0.3pt, bottomrule at break=-0.3pt, sharp corners, fonttitle=\blocktitlefont</xsl:text>
</xsl:template>

<!-- This is mostly ad-hoc.  An assemblage is meant to be prominent,   -->
<!-- we just use a simple box with rounded corners as a default, with  -->
<!-- the title (if present) centered.  Note that we get a bit of extra -->
<!-- vertical space in the title box in the event the title is null.   -->
<!-- For a document with titled and untitled assemblages maybe we need -->
<!-- a way to have two styles (tcb-title-style, tcb-notitle-style?)    -->
<!-- specified?                                                        -->
<!--                                                                   -->
<!-- A "list" will have square corners, thus the explicit rounded      -->
<!-- corners (the default).  We want to tell the difference when       -->
<!-- debugging or authoring.                                           -->
<!--                                                                   -->
<!-- NB: standard jigsaw, opacityback=0.0, opacitybacktitle=0.0  makes -->
<!-- title rule visible, and  opacity-fill=0.0  kills the the border   -->
<xsl:template match="assemblage" mode="tcb-style">
    <xsl:text>size=normal, colback=white, colbacktitle=white, coltitle=black, colframe=black, rounded corners, titlerule=0.0pt, center title, fonttitle=\blocktitlefont\bfseries, blockspacingstyle, </xsl:text>
</xsl:template>

<!-- This is the gross default, across all objects and all styles -->
<!-- It is convenient for development, testing, and convenience    -->
<xsl:template match="*" mode="tcb-style" />

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

<!-- Pretty much everything for actually manipulating titles -->
<!-- happens in the -common template. But when structured by -->
<!-- "line" we need to implement an abstract variable with a -->
<!-- separator string.                                       -->
<!-- NB: \\ works better than \newline in a \centering       -->
<xsl:variable name="title-separator" select="'\\'"/>

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


<!-- ##### -->
<!-- Fonts -->
<!-- ##### -->

<!-- General notes:                                                   -->
<!--                                                                  -->
<!-- * Any preamble activity relative to fonts can be set here        -->
<!-- * A font which has a "T1" encoding is more modern than one       -->
<!--   with "OT1" encoding, and preferred                             -->
<!--   https://tex.stackexchange.com/questions/664/                   -->
<!--   https://tex.stackexchange.com/questions/108417/                -->
<!-- * We could assume everybody will use fonts with T1 encoding,     -->
<!--   but have instead allowed for flexibility, so be sure to        -->
<!--   include the \usepackage{fontenc} with an option for the        -->
<!--   default encoding                                               -->
<!-- * If the <, > characters become upside-down exclamation or       -->
<!--   question mark, then you have a problem with font-encoding      -->
<!--   https://tex.stackexchange.com/questions/2369/                  -->
<!-- * The LaTeX Font Catalogue is a good place to start and shows    -->
<!--   recommended commands.  That is all we have done here to obtain -->
<!--   Latin Modern (which seems to be universally recommended)       -->
<!--   http://www.tug.dk/FontCatalogue/                               -->
<!-- * Some math fonts are designed to be more harmonious             -->
<!--   with certain text fonts, do your research                      -->
<!-- * If you only use "\usepackage[T1]{fontenc}" then the            -->
<!--   CM-Super fonts will be loaded.  These work well, but           -->
<!--   are inferior to Latin Modern in some ways                      -->
<!--   http://tex.stackexchange.com/questions/88368/                  -->
<!--   https://tex.stackexchange.com/questions/1390/                  -->
<!-- * Check new fonts carefully for missing, or poorly created,      -->
<!--   glyphs.  The sample article can be useful for this.            -->
<!--   Also: search the LaTeX *.log file for the string               -->
<!--   "Missing character:" for further clues.                        -->

<!-- Actual font commands to specifically influence fonts             -->
<!-- These are the defaults for out-of-the-box behavior               -->
<!--   -main: the "document font"                                     -->
<!--   -mono: "typewriter" or monospace font                          -->
<!--   -style: additions, adjustments, esp. via font-control commands -->

<!-- This is the default Latin Modern Roman font/package -->
<xsl:template name="font-pdflatex-main">
    <xsl:text>\usepackage{lmodern}&#xa;</xsl:text>
    <xsl:text>\usepackage[T1]{fontenc}&#xa;</xsl:text>
</xsl:template>

<!-- Inconsolata package, conditionally            -->
<!-- Formerly known as  zi4.sty based on NFSS name -->
<xsl:template name="font-pdflatex-mono">
    <xsl:if test="$b-needs-mono-font">
        <xsl:text>\usepackage[varqu,varl]{inconsolata}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- No extra adjustments for default out-of-the-box behavior             -->
<!-- But one example of switching to a sans serif font on division titles -->
<!-- See the "font-xelatex-style" template for more clues                 -->
<xsl:template name="font-pdflatex-style">
    <!-- uncomment to test -->
    <!-- <xsl:text>\renewcommand{\divisionfont}{\fontfamily{lmss}\selectfont}&#xa;</xsl:text> -->
</xsl:template>


<!-- Latin Modern Roman is the xelatex default -->
<xsl:template name="font-xelatex-main">
    <xsl:text>%% Latin Modern Roman is the default font for xelatex and so is loaded with a TU encoding&#xa;</xsl:text>
    <xsl:text>%% *in the format* so we can't touch it, only perhaps adjust it later&#xa;</xsl:text>
    <xsl:text>%% in one of two ways (then known by NFSS names such as "lmr")&#xa;</xsl:text>
    <xsl:text>%% (1) via NFSS with font family names such as "lmr" and "lmss"&#xa;</xsl:text>
    <xsl:text>%% (2) via fontspec with commands like \setmainfont{Latin Modern Roman}&#xa;</xsl:text>
    <xsl:text>%% The latter requires the font to be known at the system-level by its font name,&#xa;</xsl:text>
    <xsl:text>%% but will give access to OTF font features through optional arguments&#xa;</xsl:text>
    <xsl:text>%% https://tex.stackexchange.com/questions/470008/&#xa;</xsl:text>
    <xsl:text>%% where-and-how-does-fontspec-sty-specify-the-default-font-latin-modern-roman&#xa;</xsl:text>
    <xsl:text>%% http://tex.stackexchange.com/questions/115321&#xa;</xsl:text>
    <xsl:text>%% /how-to-optimize-latin-modern-font-with-xelatex&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="not($latex-font-main-regular = '')">
            <xsl:text>\setmainfont{</xsl:text>
            <xsl:value-of select="$latex-font-main-regular"/>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <!-- nothing to do, see comments above -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:template>

<!-- Filenames necessary to be cross-platform -->
<xsl:template name="font-xelatex-mono">
    <xsl:if test="$b-needs-mono-font">
        <xsl:call-template name="xelatex-font-check">
            <xsl:with-param name="font-name" select="'Inconsolatazi4-Regular.otf'"/>
        </xsl:call-template>
        <xsl:call-template name="xelatex-font-check">
            <xsl:with-param name="font-name" select="'Inconsolatazi4-Bold.otf'"/>
        </xsl:call-template>
        <xsl:text>\usepackage{zi4}&#xa;</xsl:text>
        <xsl:text>\setmonofont[BoldFont=Inconsolatazi4-Bold.otf,StylisticSet={1,3}]{Inconsolatazi4-Regular.otf}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- We describe how to adjust the default font in specific locations     -->
<!-- * The LaTeX macro, \divisionfont, is hard-wired into every division  -->
<!--   title of your output.  By default the macro does nothing.  Instead -->
<!-- * (1) Out-of-the-box xelatex sets up various Latin Modern font       -->
<!--       families.  Below we use "lmss" (Latin Modern Sans Serif)       -->
<!--        to redefine \divisionfont to make a font switch.              -->
<!-- * (2) Use fontspec to define a new font family (like standard        -->
<!--       LaTeX \rmfamily) named "\lmsansserif" and then redefine        -->
<!--       \divisionfont to make a font switch.                           -->
<!-- Long-term (1) is easier, while (2) may allow more fine-tuning        -->
<!-- with OTF font features and may be used to provide entirely different -->
<!-- fonts (provided they are known at the system level).                 -->

<xsl:template name="font-xelatex-style">
    <!-- (1) NFSS, uncomment to test -->
    <!-- <xsl:text>\renewcommand{\divisionfont}{\fontfamily{lmss}\selectfont}&#xa;</xsl:text> -->
    <!-- (2) fontspec, uncomment to test -->
    <!-- <xsl:text>\newfontfamily{\lmsansserif}{Latin Modern Sans}&#xa;</xsl:text> -->
    <!-- <xsl:text>\renewcommand{\divisionfont}{\lmsansserif}&#xa;</xsl:text> -->
</xsl:template>

<!-- This template calls the "microtype-options" template, but     -->
<!-- uses a variable to not produce an empty [ ].  Thus two        -->
<!-- templates. This one is internal, not for a stylewriter's use. -->
<xsl:template name="microtype-option-argument">
    <xsl:variable name="the-options">
        <xsl:call-template name="microtype-options"/>
    </xsl:variable>
    <xsl:if test="not($the-options = '')">
        <xsl:text>[</xsl:text>
        <xsl:value-of select="$the-options"/>
        <xsl:text>]</xsl:text>
    </xsl:if>
</xsl:template>

<!-- This is the template a stylewriter can override to influence fonts. -->
<!-- See the documentation for the  microtype  package for details.      -->
<xsl:template name="microtype-options"/>


<!-- ################## -->
<!-- End: LaTeX Styling -->
<!-- ################## -->

<!-- Tack in a graphic with initials                   -->
<!-- Height is just enough to not disrupt line spacing -->
<!-- Place inline, no carriage returns                 -->
<xsl:template match="initial">
  <xsl:text>\hspace*{-0.75ex}{}</xsl:text>
  <xsl:text>\raisebox{0.2\baselineskip}{\includegraphics[height=0.55\baselineskip]{</xsl:text>
  <xsl:apply-templates select="@source" />
  <xsl:text></xsl:text>
  <xsl:text>}}\hspace*{-0.75ex}{}</xsl:text>
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
        <xsl:text>\support{</xsl:text>
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

<!-- Authors, editors, info for article info to \maketitle -->
<!-- http://stackoverflow.com/questions/2817664/xsl-how-to-tell-if-element-is-last-in-series -->
<xsl:template match="author" mode="article-info">
    <xsl:apply-templates select="personname" />
    <xsl:if test="affiliation">
        <xsl:apply-templates select="affiliation" />
    </xsl:if>
    <xsl:if test="email">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="email" />
    </xsl:if>
    <xsl:if test="support">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="support" />
    </xsl:if>
    <xsl:if test="following-sibling::author" >
        <xsl:text>&#xa;\and</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="editor" mode="article-info">
    <xsl:apply-templates select="personname" />
    <xsl:text>, </xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:if test="affiliation">
        <xsl:apply-templates select="affiliation"/>
    </xsl:if>
    <xsl:if test="email">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="email" />
    </xsl:if>
    <xsl:if test="following-sibling::editor" >
        <xsl:text>&#xa;\and</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Preprocessor always puts Department, Institution, and Location         -->
<!-- inside Affiliation. This just adds line breaks between them as needed. -->
<xsl:template match="affiliation">
    <xsl:if test="department">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="department" />
    </xsl:if>
    <xsl:if test="institution">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="institution" />
    </xsl:if>
    <xsl:if test="location">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="location" />
    </xsl:if>
</xsl:template>

<xsl:template match="bibinfo/support" mode="article-info">
    <xsl:apply-templates select="*"/>
</xsl:template>

<xsl:template match="bibinfo/support" mode="article-info">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- Departments, Institutions, and Addresses are free-form, or sequences of lines  -->
<!-- Line breaks are inserted above, due to \and, etc, so do not end last line here -->
<xsl:template match="department|institution|location">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="department[line]|institution[line]|location[line]">
    <xsl:apply-templates select="line" />
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

<xsl:template match="bibinfo/keywords">
    <xsl:text>\par\medskip&#xa;</xsl:text>
    <xsl:text>\noindent{\bfseries </xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}. </xsl:text>
    <xsl:apply-templates select="*" />
    <xsl:text>.&#xa;</xsl:text>
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
    <xsl:text>\newlength{\subjectwidth}&#xa;</xsl:text>
    <xsl:text>\settowidth{\subjectwidth}{\textsf{Subject:}}&#xa;</xsl:text>
    <!-- Push down some on first page to accomodate letterhead -->
    <xsl:text>\vspace*{0.75in}&#xa;</xsl:text>
    <!-- Outdent experimentally, scales well at 10pt, 11pt, 12pt -->
    <!-- Control separation                                      -->
    <xsl:text>\hspace*{-1.87\subjectwidth}%&#xa;</xsl:text>
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

<!-- ############ -->
<!-- Back Matter -->
<!-- ############ -->

<!-- A PreTeXt "backmatter" includes appendices, references, index,  -->
<!-- colophon, etc.  However, LaTeX uses \appendix to morph chapters -->
<!-- into appendices (name and numbering), and then uses \backmatter -->
<!-- to switch to un-numbered chapters, though we should write these -->
<!-- as un-numbered anyway, since the "article" class has no         -->
<!-- \backmatter command anyway.  So our "backmatter" is not a       -->
<!-- significant marker for LaTeX conversion.  We instead process    -->
<!-- appendices and solutions (specialized appendices), and then     -->
<!-- everything left in "backmatter".                                -->
<!-- NB: could restrict the second "select" further                  -->
<!-- NB: these two templates are similar logically, but merging      -->
<!-- them had too many exceptions and they became unreadable         -->
<!--                                                                 -->
<!-- A LaTeX "article" can only have sections (i.e. at most) so we   -->
<!-- just add visual breaks into the ToC, which already works well   -->
<!-- in a PDF sidebar.  A LaTeX "book" can have parts.  Whether or   -->
<!-- not the PreTeXt "book" has parts, using a LaTeX part works very -->
<!-- well in either case.                                            -->

<xsl:template match="article/backmatter">
    <xsl:variable name="appendices-name">
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'appendices'"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="appendix|solutions">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>\appendix%&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>%% A lineskip in table of contents as a transition to the appendices&#xa;</xsl:text>
        <xsl:text>\addtocontents{toc}{\vspace{\normalbaselineskip}}%&#xa;</xsl:text>
        <!-- backmatter solutions divisions are realized as appendices -->
        <xsl:apply-templates select="appendix|solutions"/>
    </xsl:if>
    <xsl:if test="*[not(self::appendix|self::solutions)]">
        <!-- Some vertical separation into ToC prior to backmatter is useful -->
        <xsl:text>%% A lineskip in table of contents as a transition to the rest of the backmatter&#xa;</xsl:text>
        <xsl:text>\addtocontents{toc}{\vspace{\normalbaselineskip}}&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
        <xsl:apply-templates select="*[not(self::appendix|self::solutions)]"/>
    </xsl:if>
</xsl:template>

<xsl:template match="book/backmatter">
    <xsl:if test="appendix|solutions">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>\appendix%&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
        <!-- A book without parts gets a ToC entry, which is functional, -->
        <!-- while a book with parts gets a full-fledged part that is a  -->
        <!-- page of its own, etc, along with a ToC entry                -->
        <xsl:choose>
            <xsl:when test="$parts = 'absent'">
                <!-- make sure we are on a fresh page and drop a target -->
                <xsl:text>\clearpage\phantomsection%&#xa;</xsl:text>
                <xsl:text>\addcontentsline{toc}{part}{</xsl:text>
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'appendices'"/>
                </xsl:apply-templates>
                <xsl:text>}%&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>\part*{</xsl:text>
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'appendices'"/>
                </xsl:apply-templates>
                <xsl:text>}%&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <!-- backmatter solutions divisions are realized as appendices -->
        <xsl:apply-templates select="appendix|solutions"/>
    </xsl:if>
    <xsl:if test="*[not(self::appendix|self::solutions)]">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>\backmatter%&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
        <!-- make sure we are on a fresh page and drop a target -->
        <xsl:text>\clearpage\phantomsection%&#xa;</xsl:text>
        <!-- We only *enhance* the ToC, parts or not -->
        <xsl:text>\addcontentsline{toc}{part}{</xsl:text>
        <xsl:apply-templates select="." mode="type-name"/>
        <xsl:text>}%&#xa;</xsl:text>
        <xsl:apply-templates select="*[not(self::appendix|self::solutions)]"/>
    </xsl:if>
</xsl:template>

<!-- The back colophon of a book goes on its own recto page -->
<!-- The "backcolophon" environment is a tcolorbox          -->
<xsl:template match="book/backmatter/colophon">
    <xsl:choose>
        <xsl:when test="$b-latex-two-sides">
            <xsl:text>\cleardoublepage&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\clearpage&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\pagestyle{empty}&#xa;</xsl:text>
    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <xsl:text>\begin{backcolophon}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>\end{backcolophon}%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
    <xsl:text>\vspace*{\stretch{2}}&#xa;</xsl:text>
</xsl:template>

<!-- The back colophon of an article is simpler -->
<xsl:template match="article/backmatter/colophon">
    <xsl:text>\begin{backcolophon}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>\end{backcolophon}%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- Appendices are handled in the general subdivision template -->

<!-- The index itself needs special handling    -->
<!-- The "index" element signals an index,      -->
<!-- and the content is just an optional title  -->
<!-- and a compulsory "index-list"              -->
<!-- For a LaTeX-native index, we just          -->
<!-- apply-templates to the "index-list"        -->
<!-- element since the "\printindex macro takes -->
<!-- care of the heading.  For a PreTeXt index  -->
<!-- we utilize an environment purpose-built    -->
<!-- for the index.                             -->
<!-- TODO: multiple indices, with different titles -->
<xsl:template match="index">
    <xsl:choose>
        <xsl:when test="$index-maker = 'pretext'">
            <!-- The LaTeX "classic" index always appears on a new page. -->
            <!-- Perhaps this should be part of some page/division       -->
            <!-- infrastructure and not so hard-coded as it is here.     -->
            <xsl:text>\newpage%&#xa;</xsl:text>
            <xsl:apply-templates select="." mode="latex-division-heading"/>
            <xsl:apply-templates select="index-list"/>
            <xsl:apply-templates select="." mode="latex-division-footing"/>
        </xsl:when>
        <xsl:when test="$index-maker = 'latex'">
            <xsl:apply-templates select="index-list"/>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- TEMPORARY (2024-08-11) (migrate to publisher)  -->
<!-- We parameterize creation of the index with     -->
<!-- a switch that determines "who" does the work.  -->
<!-- 'latex'                                        -->
<!--     The usual default semi-automatic procedure -->
<!-- 'pretext'                                      -->
<!--     Logic, organization, and content via the   -->
<!--     same routines that create an HTML index,   -->
<!--     with presentation details handled here     -->
<!--     (Not implemented yet!)                     -->
<xsl:param name="index-maker" select="'latex'"/>

<xsl:template match="index-list">
    <xsl:choose>
        <!-- Reach down into -common for shared code that   -->
        <!-- relies on abstract templates for presentation. -->
        <!-- Start here with abstract template matching     -->
        <!-- "index-list"                                   -->
        <xsl:when test="$index-maker = 'pretext'">
            <xsl:apply-imports/>
        </xsl:when>
        <!-- Have LaTeX do all the work. -->
        <xsl:when test="$index-maker = 'latex'">
            <xsl:text>%&#xa;</xsl:text>
            <xsl:text>%% The index is here, setup is all in preamble&#xa;</xsl:text>
            <xsl:text>%% Index locators are cross-references, so same font here&#xa;</xsl:text>
            <xsl:text>{\xreffont\printindex}&#xa;</xsl:text>
            <xsl:text>%&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise/>
    </xsl:choose>
</xsl:template>


<xsl:template name="present-index">
    <xsl:param name="content"/>

    <xsl:text>\begin{multicols*}{2}%&#xa;</xsl:text>
    <!-- Turn off paragraph indentation within the -->
    <!-- scope of the multicolumn environment      -->
    <xsl:text>\setlength{\parindent}{0pt}%&#xa;</xsl:text>
    <xsl:copy-of select="$content"/>
    <xsl:text>\end{multicols*}%&#xa;</xsl:text>
</xsl:template>

<xsl:template name="present-letter-group">
    <xsl:param name="the-index-list"/>
    <xsl:param name="letter-group"/>
    <xsl:param name="current-letter"/>
    <xsl:param name="content"/>

    <xsl:copy-of select="$content"/>

    <!-- The index for CMoS has only gaps between letter groups,  -->
    <!-- about 2 lines, much like default LaTeX.  Bringhurst has  -->
    <!-- fleurons and in the margin, the first and last entry of  -->
    <!-- each page.                                               -->

    <!-- Visual separation to next letter group          -->
    <!-- Seems to be about 20% taller than default LaTeX -->
    <!-- TODO: pass in flag for last letter group, so we don't write -->
    <!-- this out when not necessary (and maybe force a new page?    -->
    <xsl:text>\par\vspace*{1.0\parskip}%&#xa;</xsl:text>
</xsl:template>

<xsl:template name="present-index-heading">
    <xsl:param name="the-index-list"/>
    <xsl:param name="heading-group"/>
    <xsl:param name="b-write-locators"/>
    <xsl:param name="heading-level"/>
    <xsl:param name="content"/>

    <!-- TODO: implement indentation with macros? -->
    <xsl:choose>
        <xsl:when test="$heading-level = 1">
            <!-- visual formatting, break with the past -->
            <xsl:text>%&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$heading-level = 2">
            <xsl:text>\hspace*{18pt}</xsl:text>
        </xsl:when>
        <xsl:when test="$heading-level = 3">
            <xsl:text>\hspace*{36pt}</xsl:text>
        </xsl:when>
    </xsl:choose>

    <xsl:copy-of select="$content"/>

    <!-- perhaps time to write locators -->
    <xsl:if test="$b-write-locators">
        <xsl:call-template name="locator-list">
            <xsl:with-param name="the-index-list" select="$the-index-list"/>
            <xsl:with-param name="heading-group" select="$heading-group" />
            <!-- use comma-space to separate knowls -->
            <xsl:with-param name="cross-reference-separator" select="', '" />
        </xsl:call-template>
    </xsl:if>
    <xsl:text>\\%&#xa;</xsl:text>
</xsl:template>

<!-- This is poorly named and maybe needs a refactor.  For an HTML index,  -->
<!-- we look up the tree to find an object that can be knowlized as the    -->
<!-- locator, and build a knowl cross-reference.  The $enclosure parameter -->
<!-- is the provoking "idx", unclear why that is not passed through the    -->
<!-- match/select.  In any event, we need to make a cross-reference here,  -->
<!-- a standard page reference, which will be fine in print and which will -->
<!-- be a hyperlink in electronic versions.  The \pageref\label mechanism  -->
<!-- uses the string from the "unique-id" for the "idx" element, so the    -->
<!-- \label must be set elsewhere.                                         -->
<xsl:template match="index-list" mode="index-enclosure">
    <xsl:param name="enclosure"/>

    <!-- NB: $enclosure is always an "idx" element, -->
    <!-- this should be unwound in a refactor       -->

    <xsl:text>\pageref{</xsl:text>
    <xsl:apply-templates select="$enclosure" mode="unique-id"/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template name="present-index-locator">
    <xsl:param name="content"/>
    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- Just duplicate, processed text from -->
<!-- abstract templates is sufficient    -->
<xsl:template name="present-index-see">
    <xsl:param name="content"/>
    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- Just duplicate, processed text from -->
<!-- abstract templates is sufficient    -->
<xsl:template name="present-index-see-also">
    <xsl:param name="content"/>
    <xsl:copy-of select="$content"/>
</xsl:template>

<xsl:template name="present-index-italics">
    <xsl:param name="content"/>

    <xsl:text>{\textit </xsl:text>
    <xsl:copy-of select="$content"/>
    <xsl:text>}</xsl:text>
</xsl:template>


<!--               -->
<!-- Notation List -->
<!--               -->

<!-- At location, we just drop a marker to get the page number -->
<xsl:template match="notation">
    <xsl:apply-templates select="." mode="label" />
    <!-- do not introduce anymore whitespace into a "p" than there   -->
    <!-- already is, but do format these one-per-line outside of "p" -->
    <xsl:if test="not(ancestor::p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Implementation of abstract templates.       -->
<!-- See more complete code comments in -common. -->

<!-- Deccription column is "p" to enable word-wrapping  -->
<!-- The 60% width is arbitrary, could see improvements -->
<!-- This is not a PreTeXt "table" so we don't let      -->
<!-- LaTeX number it, nor increment the table counter   -->
<xsl:template name="present-notation-list">
    <xsl:param name="content"/>

    <xsl:text>\begin{longtable}[l]{lp{0.60\textwidth}r}&#xa;</xsl:text>
    <xsl:text>\addtocounter{table}{-1}&#xa;</xsl:text>
    <xsl:text>\textbf{</xsl:text>
    <xsl:apply-templates select="." mode="type-name">
        <xsl:with-param name="string-id" select="'symbol'"/>
    </xsl:apply-templates>
    <xsl:text>}&amp;\textbf{</xsl:text>
    <xsl:apply-templates select="." mode="type-name">
        <xsl:with-param name="string-id" select="'description'"/>
    </xsl:apply-templates>
    <xsl:text>}&amp;\textbf{</xsl:text>
    <xsl:apply-templates select="." mode="type-name">
        <xsl:with-param name="string-id" select="'page'"/>
    </xsl:apply-templates>
    <xsl:text>}\\[1em]&#xa;</xsl:text>
    <xsl:text>\endfirsthead&#xa;</xsl:text>
    <xsl:text>\textbf{</xsl:text>
    <xsl:apply-templates select="." mode="type-name">
        <xsl:with-param name="string-id" select="'symbol'"/>
    </xsl:apply-templates>
    <xsl:text>}&amp;\textbf{</xsl:text>
    <xsl:apply-templates select="." mode="type-name">
        <xsl:with-param name="string-id" select="'description'"/>
    </xsl:apply-templates>
    <xsl:text>}&amp;\textbf{</xsl:text>
    <xsl:apply-templates select="." mode="type-name">
        <xsl:with-param name="string-id" select="'page'"/>
    </xsl:apply-templates>
    <xsl:text>}\\[1em]&#xa;</xsl:text>
    <xsl:text>\endhead&#xa;</xsl:text>
    <xsl:text>\multicolumn{3}{r}{(</xsl:text>
    <xsl:apply-templates select="." mode="type-name">
        <xsl:with-param name="string-id" select="'continued'"/>
    </xsl:apply-templates>
    <xsl:text>)}\\&#xa;</xsl:text>
    <xsl:text>\endfoot&#xa;</xsl:text>
    <xsl:text>\endlastfoot&#xa;</xsl:text>
    <!-- the actual body/rows/content -->
    <xsl:copy-of select="$content"/>
    <xsl:text>\end{longtable}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="notation" mode="present-notation-item">
    <!-- Process *exactly* one "m" element -->
    <xsl:apply-templates select="usage/m[1]"/>
    <xsl:text>&amp;</xsl:text>
    <xsl:apply-templates select="description" />
    <xsl:text>&amp;</xsl:text>
    <xsl:text>\pageref{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id" />
    <xsl:text>}</xsl:text>
    <!-- It seems very expensive to test for the last "notation"    -->
    <!-- globally (not(following::notation)), adding a second or    -->
    <!-- two to a 12-second run-time for the sample article.        -->
    <!-- But it would be nice not to have the unnecessary "\\"      -->
    <!-- on the last row of the table.  See comments in -common for -->
    <!-- a complicated approach that might be reasonably efficient. -->
    <xsl:text>\\&#xa;</xsl:text>
</xsl:template>


<!-- ####################################### -->
<!-- Solutions Divisions, Content Generation -->
<!-- ####################################### -->

<!-- The "division-in-solutions" modal template from -common   -->
<!-- calls the "duplicate-heading" modal template.             -->
<!-- Stacked headings are all \Large, regardless of which      -->
<!-- level of depth they reflect. This is consistent with      -->
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
    <xsl:variable name="is-specialized-division">
        <xsl:choose>
            <xsl:when test="self::task">
                <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="is-specialized-division"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="is-child-of-structured">
        <xsl:choose>
            <xsl:when test="parent::*[&TRADITIONAL-DIVISION-FILTER;]">
                <xsl:apply-templates select="parent::*[&TRADITIONAL-DIVISION-FILTER;]" mode="is-structured-division"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$is-specialized-division = 'true' and $is-child-of-structured = 'false'">
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



<!-- ############### -->
<!-- Arbitrary Lists -->
<!-- ############### -->

<!-- See general routine in  xsl/pretext-common.xsl -->
<!-- which expects the two named templates and the  -->
<!-- two division'al and element'al templates below,  -->
<!-- it contains the logic of constructing such a list -->

<!-- List-of entry/exit hooks, for long table,        -->
<!-- two columns and just "continued" adornment       -->
<!-- This is not a PreTeXt "table" so we don't let    -->
<!-- LaTeX number it, nor increment the table counter -->
<xsl:template name="list-of-begin">
    <xsl:text>\noindent&#xa;</xsl:text>
    <xsl:text>\begin{longtable}[l]{ll}&#xa;</xsl:text>
    <xsl:text>\addtocounter{table}{-1}&#xa;</xsl:text>
    <xsl:text>\endfirsthead&#xa;</xsl:text>
    <xsl:text>\endhead&#xa;</xsl:text>
    <xsl:text>\multicolumn{2}{r}{(</xsl:text>
    <xsl:apply-templates select="." mode="type-name">
        <xsl:with-param name="string-id" select="'continued'"/>
    </xsl:apply-templates>
    <xsl:text>)}\\&#xa;</xsl:text>
    <xsl:text>\endfoot&#xa;</xsl:text>
    <xsl:text>\endlastfoot&#xa;</xsl:text>
</xsl:template>

<!-- Done -->
<xsl:template name="list-of-end">
    <xsl:text>\end{longtable}&#xa;</xsl:text>
</xsl:template>

<!-- Some insulating space around headings    -->
<!-- All in one, so not part of table columns -->
<xsl:template match="*" mode="list-of-heading">
    <xsl:text>\multicolumn{2}{l}{\null}\\[1.5ex] </xsl:text>
    <xsl:text>\multicolumn{2}{l}{\large </xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}\\[0.5ex]&#xa;</xsl:text>
</xsl:template>

<!-- Hyperlink with type, number, then a title -->
<!-- TODO: xref-link's select is a fiction and may lead to  bugs -->
<xsl:template match="*" mode="list-of-element">
    <xsl:apply-templates select="." mode="xref-link">
        <xsl:with-param name="target" select="." />
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="type-name"/>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="number" />
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- title plain, separated             -->
    <!-- xref version, no additional period -->
    <xsl:text>&amp;</xsl:text>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="title-xref"/>
    <xsl:text>\\&#xa;</xsl:text>
</xsl:template>

<!-- ################ -->
<!-- Contributor List -->
<!-- ################ -->

<xsl:template match="contributors">
    <!-- <xsl:text>\par\bigskip&#xa;</xsl:text> -->
    <xsl:text>\begin{multicols}{2}&#xa;</xsl:text>
    <xsl:apply-templates select="contributor" />
    <xsl:text>\end{multicols}&#xa;</xsl:text>
</xsl:template>

<!-- label works best before *anything* happens -->
<!-- tested for first name in second column     -->
<xsl:template match="contributor">
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\contributor{</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\contributorname{</xsl:text>
    <xsl:apply-templates select="personname" />
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:if test="affiliation|email">
        <xsl:text>\contributorinfo{</xsl:text>
        <xsl:if test="affiliation/department">
            <xsl:apply-templates select="affiliation/department" />
            <xsl:if test="affiliation/department/following-sibling::*">
                <xsl:text>\\&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
        <xsl:if test="affiliation/institution">
            <xsl:apply-templates select="affiliation/institution" />
            <xsl:if test="affiliation/institution/following-sibling::*">
                <xsl:text>\\&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
        <xsl:if test="affiliation/location">
            <xsl:apply-templates select="affiliation/location" />
            <xsl:if test="affiliation/location/following-sibling::*">
                <xsl:text>\\&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
        <xsl:if test="affiliation/following-sibling::*">
            <xsl:text>\\&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="email">
            <!-- switch to node-set with "c" if characters need escaping -->
            <xsl:text>\mono{</xsl:text>
            <xsl:apply-templates select="email" />
            <xsl:text>}</xsl:text>
        </xsl:if>
        <xsl:text>}%&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>}%&#xa;</xsl:text>
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


<!-- ################ -->
<!-- Structural Nodes -->
<!-- ################ -->

<!-- Divisions, "part" to "subsubsection", and specialized -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|acknowledgement|foreword|preface|exercises|worksheet|handout|reading-questions|solutions|glossary|references">
    <xsl:apply-templates select="." mode="console-typeout" />
    <xsl:apply-templates select="." mode="begin-language" />
    <xsl:apply-templates select="." mode="latex-division-heading" />
    <!-- Process the contents, title, idx killed, but avoid author -->
    <!-- "solutions" content needs to call content generator       -->
    <xsl:choose>
        <xsl:when test="self::solutions">
            <xsl:apply-templates select="idx"/>
            <xsl:apply-templates select="." mode="solutions">
                <xsl:with-param name="heading-level">
                    <xsl:choose>
                        <xsl:when test="parent::book">1</xsl:when>
                        <xsl:when test="parent::part">2</xsl:when>
                        <xsl:when test="parent::article">3</xsl:when>
                        <xsl:when test="parent::chapter">3</xsl:when>
                        <xsl:when test="parent::section">4</xsl:when>
                        <xsl:when test="parent::subsection">5</xsl:when>
                        <xsl:when test="parent::subsubsection">6</xsl:when>
                        <xsl:when test="parent::backmatter and $b-is-book">2</xsl:when>
                        <xsl:when test="parent::backmatter and $b-is-article">3</xsl:when>
                        <xsl:when test="parent::appendix and $b-is-book">3</xsl:when>
                        <xsl:when test="parent::appendix and $b-is-article">4</xsl:when>
                        <xsl:otherwise>6</xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="*"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="." mode="latex-division-footing" />
    <xsl:apply-templates select="." mode="end-language" />
</xsl:template>

<!-- Information to console for latex run -->
<!-- Generally these precede structural divisions, so some -->
<!-- nearly-blank lines provide some visual organization   -->
<xsl:template match="*" mode="console-typeout">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\typeout{************************************************}&#xa;</xsl:text>
    <xsl:text>\typeout{</xsl:text>
    <xsl:apply-templates select="." mode="long-name" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\typeout{************************************************}&#xa;</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- ############################## -->
<!-- Division Headings and Footings -->
<!-- ############################## -->

<!-- A typical division has 5 arguments (below).  For specialized       -->
<!-- divisions we need to adjust the environment name for numbered      -->
<!-- v. unnumbered instances.  Worksheets are exception with a          -->
<!-- page layout change.                                                -->
<!--                                                                    -->
<!--    1. title                                                        -->
<!--    2. subtitle                                                     -->
<!--    3. shorttitle                                                   -->
<!--    4. author                                                       -->
<!--    5. epigraph (unimplemented)                                     -->
<!--                                                                    -->
<!-- A "solutions" division in the back matter is implemented as an     -->
<!-- appendix.  The levels and division-name templates will produce a   -->
<!-- LaTeX chapter for a "book" and a LaTeX "section" for an "article". -->
<!-- Specialized Divisions: we do not implement "author", "subtitle",   -->
<!-- or "epigraph" yet.  These may be added/supported later.            -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|acknowledgement|foreword|preface|exercises|solutions|reading-questions|glossary|references|index|worksheet|handout" mode="latex-division-heading">
    <!-- NB: could be obsoleted, see single use -->
    <xsl:variable name="b-is-specialized" select="boolean(self::exercises|self::solutions[not(parent::backmatter)]|self::reading-questions|self::glossary|self::references|self::worksheet|self::handout|self::index)"/>

    <!-- change geometry if worksheet should be formatted -->
    <xsl:if test="(self::worksheet or self::handout) and $b-latex-worksheet-formatted">
        <!-- \newgeometry includes a \clearpage -->
        <xsl:apply-templates select="." mode="new-geometry"/>
    </xsl:if>
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="." mode="division-environment-name" />
    <!-- possibly numberless -->
    <xsl:apply-templates select="." mode="division-environment-name-suffix" />
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <!-- subtitle here -->
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-short"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <!-- author here -->
    <!-- historical, could be relaxed -->
    <xsl:if test="not($b-is-specialized)">
        <xsl:apply-templates select="author" mode="name-list"/>
    </xsl:if>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <!-- epigraph here -->
    <!-- <xsl:text>An epigraph here\\with two lines\\-Rob</xsl:text> -->
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <!-- Various LaTeX classes and packages define various names, see   -->
    <!-- two links below.  The ones redefined here seem critical for    -->
    <!-- how the "titleps" package makes heads and foots, in concert    -->
    <!-- with the "titlesec" package.  We want these to change to the   -->
    <!-- right language when a division indicates a different language. -->
    <!-- NB: not clear if this should be after, or before, the \begin{} -->
    <!-- of the environment.  In other words, when is the head/foot     -->
    <!-- manufactured?                                                  -->
    <!-- https://texfaq.org/FAQ-fixnam -->
    <!-- http://tex.stackexchange.com/questions/62020/how-to-change-the-word-proof-in-the-proof-environment -->
    <!-- https://tex.stackexchange.com/questions/82993/how-to-change-the-name-of-document-elements-like-figure-contents-bibliogr -->
    <xsl:if test="self::part">
        <xsl:text>\renewcommand*{\partname}{</xsl:text>
        <xsl:apply-templates select="." mode="type-name"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="self::chapter">
        <xsl:text>\renewcommand*{\chaptername}{</xsl:text>
        <xsl:apply-templates select="." mode="type-name"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="self::appendix">
        <xsl:text>\renewcommand*{\appendixname}{</xsl:text>
        <xsl:apply-templates select="." mode="type-name"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <!-- For references we open a list to hold "biblio" -->
    <!-- unless we need to wait for an "introduction"   -->
    <xsl:if test="self::references and not(introduction)">
        <xsl:call-template name="open-reference-list"/>
    </xsl:if>
</xsl:template>

<!-- Exceptional, for a worksheet only, we clear the page  -->
<!-- at the start and provide many options for specifying  -->
<!-- the four margins, in units LaTeX understands (such as -->
<!-- cm, in, pt).  This only produces text, so could go in -->
<!-- -common, but is also only useful for LaTeX output.    -->
<xsl:template match="worksheet|handout" mode="new-geometry">
    <!-- Four similar "choose" effect hierarchy/priority -->
    <!-- NB: a publisher string parameter to      -->
    <!-- *really* override (worksheet.left, etc.) -->
    <xsl:text>\newgeometry{</xsl:text>
    <xsl:text>left=</xsl:text>
    <xsl:apply-templates select="." mode="worksheet-margin">
        <xsl:with-param name="author-side" select="@left"/>
        <xsl:with-param name="publisher-side" select="$ws-margin-left"/>
    </xsl:apply-templates>
    <xsl:text>, right=</xsl:text>
    <xsl:apply-templates select="." mode="worksheet-margin">
        <xsl:with-param name="author-side" select="@right"/>
        <xsl:with-param name="publisher-side" select="$ws-margin-right"/>
    </xsl:apply-templates>
    <xsl:text>, top=</xsl:text>
    <xsl:apply-templates select="." mode="worksheet-margin">
        <xsl:with-param name="author-side" select="@top"/>
        <xsl:with-param name="publisher-side" select="$ws-margin-top"/>
    </xsl:apply-templates>
    <xsl:text>, bottom=</xsl:text>
    <xsl:apply-templates select="." mode="worksheet-margin">
        <xsl:with-param name="author-side" select="@bottom"/>
        <xsl:with-param name="publisher-side" select="$ws-margin-bottom"/>
    </xsl:apply-templates>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Footings are straightforward -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|acknowledgement|foreword|preface|exercises|solutions|reading-questions|glossary|references|index|worksheet|handout" mode="latex-division-footing">
    <!-- For references we close a list holding "biblio"    -->
    <!-- unless we already added it before the "conclusion" -->
    <xsl:if test="self::references and not(conclusion)">
        <xsl:call-template name="close-reference-list"/>
    </xsl:if>

    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="." mode="division-environment-name" />
    <!-- possibly numberless -->
    <xsl:apply-templates select="." mode="division-environment-name-suffix" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:if test="(self::worksheet or self::handout) and $b-latex-worksheet-formatted">
        <!-- \restoregeometry includes a \clearpage -->
        <xsl:text>\restoregeometry&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Introductions and Conclusions -->
<!-- Simple containers, allowed before and after      -->
<!-- explicit subdivisions, to introduce or summarize -->
<!-- Title optional (and discouraged), in argument    -->
<!-- typically just a few paragraphs                  -->
<!-- NB: a glossary has a "headnote" (elsewhere) and does not have a "conclusion" -->
<xsl:template match="article/introduction|chapter/introduction|section/introduction|subsection/introduction|appendix/introduction|exercises/introduction|solutions/introduction|worksheet/introduction|handout/introduction|reading-questions/introduction|references/introduction">
    <xsl:text>\begin{introduction}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>\end{introduction}%&#xa;</xsl:text>
    <!-- We have not opened the list of references yet    -->
    <!-- when it has an "introduction".  Now is the time. -->
    <xsl:if test="parent::references">
        <xsl:call-template name="open-reference-list"/>
    </xsl:if>
</xsl:template>

<xsl:template match="article/conclusion|chapter/conclusion|section/conclusion|subsection/conclusion|appendix/conclusion|exercises/conclusion|solutions/conclusion|worksheet/conclusion|handout/conclusion|reading-questions/conclusion|references/conclusion">
    <!-- We will not close the list of references when -->
    <!-- it has an "introduction".  Now is the time.   -->
    <xsl:if test="parent::references">
        <xsl:call-template name="close-reference-list"/>
    </xsl:if>
    <xsl:text>\begin{conclusion}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>\end{conclusion}%&#xa;</xsl:text>
</xsl:template>

<!-- "exercisegroup" and "task" have structured -->
<!-- "introduction" and "conclusion"            -->

<xsl:template match="exercisegroup/introduction|task/introduction">
    <xsl:apply-templates select="*"/>
</xsl:template>

<xsl:template match="exercisegroup/conclusion|task/conclusion">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- Pages in a Worksheet -->
<!-- Produce a  \clearpage  indicating the end -->
<!-- of a page, but not for the last page.     -->

<xsl:template match="worksheet/page|handout/page">
    <xsl:apply-templates select="*"/>
    <xsl:if test="following-sibling::page and $b-latex-worksheet-formatted">
        <xsl:text>\clearpage&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- 2020-03-17: Empty element, since originally a       -->
<!-- "page" element interrupted numbering of contents.   -->
<!-- Now deprecated in favor of a proper "page" element. -->
<xsl:template match="worksheet/pagebreak">
    <xsl:if test="$b-latex-worksheet-formatted">
        <xsl:text>\clearpage&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Statement -->
<!-- Simple containier for blocks with structured contents -->
<!-- Consumers are responsible for surrounding breaks      -->
<xsl:template match="statement">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- Prelude, Interlude, Postlude -->
<!-- Very simple containiers, to help with movement, use -->
<xsl:template match="prelude|interlude|postlude">
    <xsl:text>\par&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
</xsl:template>


<!-- Paragraphs -->
<!-- Non-structural, even if they appear to be -->
<xsl:template match="paragraphs">
    <!-- Warn about paragraph deprecation -->
    <xsl:text>\begin{paragraphs}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>\end{paragraphs}%&#xa;</xsl:text>
</xsl:template>

<!-- Theorems, Proofs, Definitions, Examples, Exercises -->

<!-- Theorems have statement/proof structure                    -->
<!-- Definitions have notation, which is handled elsewhere      -->
<!-- Examples have no structure, or have statement and solution -->
<!-- Exercises have hints, answers and solutions                -->

<!-- Environments/blocks implemented with tcolorbox          -->
<!-- expect certain arguments.  This template provides them. -->
<!--                                                         -->
<!-- 1.  title, with punctuation as needed                   -->
<!-- 2.  the "unique-id", which suffices for                 -->
<!--     the LaTeX label/ref mechanism                       -->
<!--                                                         -->
<!-- Or, for THEOREM-LIKE and AXIOM-LIKE,                    -->
<!--                                                         -->
<!-- 1.  title, right now we add punctuation as needed       -->
<!-- 2.  a list of creator(s)                                -->
<!-- 3.  the "unique-id", which suffices for                 -->
<!--     the LaTeX label/ref mechanism                       -->
<!-- N.B.: "objectives", "outcomes" need to use this         -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;|&DEFINITION-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&OPENPROBLEM-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&ASIDE-LIKE;|exercise[boolean(&INLINE-EXERCISE-FILTER;)]|assemblage" mode="block-options">
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}</xsl:text>
    <xsl:if test="&THEOREM-FILTER; or &AXIOM-FILTER;">
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="creator-full" />
        <xsl:text>}</xsl:text>
    </xsl:if>
    <!-- unique-id destined for tcolorbox  phantomlabel=  option -->
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id"/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Theorems and Axioms-->
<!-- Very similar to case of definitions       -->
<!-- Adds (potential) PROOF-LIKE, and creators -->
<!-- Statement structure should be relaxed     -->
<!-- Style is controlled in the preamble       -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;">
    <!-- environment, title, label string, newline -->
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="block-options"/>
    <xsl:text>%&#xa;</xsl:text>
    <!-- statement is required now, to be relaxed in schema             -->
    <!-- explicitly ignore PROOF-LIKE and pickup just for theorems      -->
    <!-- Alternative: ocate first PROOF-LIKE, select only preceding:: ? -->
    <xsl:apply-templates select="*[not(&PROOF-FILTER;)]" />
    <!-- Apply workspace if appropriate -->
    <xsl:apply-templates select="." mode="workspace"/>
    <xsl:text>\end{</xsl:text>
        <xsl:value-of select="local-name(.)" />
    <xsl:text>}&#xa;</xsl:text>
    <!-- PROOF-LIKE(s) are optional, so may not match at all          -->
    <!-- And the point of the AXIOM-LIKE is that they lack PROOF-LIKE -->
    <xsl:if test="&THEOREM-FILTER;">
        <xsl:apply-templates select="&PROOF-LIKE;" />
    </xsl:if>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- PROOF-LIKE (regular, major) -->
<!-- Subsidary to THEOREM-LIKE, or standalone        -->
<!-- Defaults to "Proof", can be replaced by "title" -->
<xsl:template match="proof[not(&SOLUTION-PROOF-FILTER;)]|argument[not(&SOLUTION-PROOF-FILTER;)]|justification[not(&SOLUTION-PROOF-FILTER;)]|reasoning[not(&SOLUTION-PROOF-FILTER;)]|explanation[not(&SOLUTION-PROOF-FILTER;)]">
    <xsl:variable name="environment-name">
        <xsl:value-of select="local-name(.)"/>
    </xsl:variable>
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:if test="title">
        <xsl:apply-templates select="." mode="title-full"/>
    </xsl:if>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id" />
    <xsl:text>}</xsl:text>
    <!-- TODO: move this into an environment argument -->
    <!-- to enable styling options (possibly blank)   -->
    <xsl:if test="@ref">
        <xsl:text>\space(</xsl:text>
        <xsl:apply-templates select="." mode="proof-xref-theorem"/>
        <xsl:text>)\space</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <!-- Apply workspace if appropriate -->
    <xsl:apply-templates select="." mode="workspace"/>
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- PROOF-LIKE (solutions, minor) -->
<!-- Inside "hint", "answer", solution" -->
<xsl:template match="proof[&SOLUTION-PROOF-FILTER;]|argument[&SOLUTION-PROOF-FILTER;]|justification[&SOLUTION-PROOF-FILTER;]|reasoning[&SOLUTION-PROOF-FILTER;]|explanation[&SOLUTION-PROOF-FILTER;]">
    <xsl:variable name="environment-name">
        <xsl:text>solution</xsl:text>
        <xsl:value-of select="local-name(.)"/>
    </xsl:variable>
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <!-- Apply workspace if appropriate -->
    <xsl:apply-templates select="." mode="workspace"/>
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- cases in PROOF-LIKEs -->

<!-- First we need to set up arrow symbols for this output target. -->
<!-- Perhaps customize these via something like tex-macro-style.   -->
<xsl:template name="double-right-arrow-symbol">
    <xsl:text>$\Rightarrow$</xsl:text>
</xsl:template>
<xsl:template name="double-left-arrow-symbol">
    <xsl:text>$\Leftarrow$</xsl:text>
</xsl:template>
<!-- Also need a "delimiter space" for when "direction" is "cycle". -->
<xsl:template name="case-cycle-delimiter-space" />

<!-- case -->
<!-- Three arguments: direction arrow, title, label -->
<!-- The environment combines and styles            -->
<xsl:template match="case">
    <xsl:text>\begin{case}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <!-- optional direction, given by attribute -->
    <xsl:apply-templates select="." mode="case-direction" />
    <xsl:text>}</xsl:text>
    <!-- optional title -->
    <xsl:text>{</xsl:text>
    <xsl:if test="title">
        <xsl:apply-templates select="." mode="title-full" />
    </xsl:if>
    <xsl:text>}</xsl:text>
    <!-- label -->
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <!-- Apply workspace if appropriate -->
    <xsl:apply-templates select="." mode="workspace"/>
    <xsl:text>\end{case}&#xa;</xsl:text>
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

<xsl:template match="subexercises" mode="solutions">
    <xsl:param name="purpose"/>
    <xsl:param name="admit"/>
    <xsl:param name="b-component-heading"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <!-- When we subset exercises for solutions, an entire      -->
    <!-- "subexercises" can become empty.  So we do a dry-run  -->
    <!-- and if there is no content at all we bail out.         -->
     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
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
        <xsl:apply-templates select="exercise|exercisegroup" mode="solutions">
            <xsl:with-param name="purpose" select="$purpose" />
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
        <xsl:if test="$b-has-statement">
            <xsl:apply-templates select="conclusion" />
        </xsl:if>
        <xsl:text>\par\medskip\noindent&#xa;</xsl:text>
    </xsl:if>
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
<xsl:template match="exercisegroup" mode="solutions">
    <xsl:param name="purpose"/>
    <xsl:param name="admit"/>
    <xsl:param name="b-component-heading"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <!-- When we subset exercises for solutions, an entire      -->
    <!-- "exercisegroup" can become empty.  So we do a dry-run  -->
    <!-- and if there is no content at all we bail out.         -->
     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
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
        <xsl:apply-templates select="exercise" mode="solutions">
            <xsl:with-param name="purpose" select="$purpose" />
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
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
    </xsl:if>
</xsl:template>


<!-- ###################### -->
<!-- Exercises and Projects -->
<!-- ###################### -->

<!-- Exercises are inline (parent is a division), or           -->
<!-- divisional by virtue of being in an "exercises"           -->
<!-- division, though they may be buried down in an            -->
<!-- "exercisedivision" or an "exercisegroup"                  -->

<!-- Switches provided here as defaults are the global values  -->
<!-- specified for the main narrative by an author, so these   -->
<!-- are employed when matching in document order.  Other uses -->
<!-- will need more care about passing in the right switches.  -->
<!-- Some of these switches might be moot, eg WeBWorK does not -->
<!-- have an "answer" and MyOpenMath only has "solution".  But -->
<!-- passing in values for the relevant switches will not do   -->
<!-- any harm in these cases.                                  -->

<!-- Every exercise may have its four components               -->
<!-- (statement, hint, answer, solution) visible or not        -->

<!-- A template formulates the various possible environments   -->
<xsl:template match="exercise|&PROJECT-LIKE;" mode="environment-name">
    <xsl:choose>
        <!-- projects sit in divisions according to schema,  -->
        <!-- just like inline exercises, so we catch them    -->
        <!-- first, before differentiating exercises based   -->
        <!-- on placement, just recycle PreTeXt element name -->
        <xsl:when test="&PROJECT-FILTER;">
            <xsl:value-of select="local-name(.)" />
        </xsl:when>
        <!-- must now be an "exercise" -->
        <xsl:when test="&INLINE-EXERCISE-FILTER;">
            <xsl:text>inlineexercise</xsl:text>
        </xsl:when>
        <!-- "exercisegroup" and "exercisegroup/@cols" become -->
        <!-- progressively more complicated to organize       -->
        <xsl:when test="ancestor::exercises or ancestor::worksheet or ancestor::reading-questions">
            <xsl:text>divisionexercise</xsl:text>
            <xsl:if test="ancestor::exercisegroup">
                <xsl:text>eg</xsl:text>
            </xsl:if>
            <xsl:if test="ancestor::exercisegroup/@cols">
                <xsl:text>col</xsl:text>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>exercise-project-without-environment-name</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Inline exercises (inside divisions, or pseudo-divisons     -->
<!-- like "paragraphs"), project-like, and divisional exercises -->
<!-- (exercises//exercise, worksheet//exercise, etc) when born, -->
<!-- so appearance of components is under control of switches   -->
<!-- A division with "exercise" might be divided by a           -->
<!-- "subexercises", "exercisegroup" or "sidebyside"            -->
<!-- (worksheet), so we match with a //                         -->
<xsl:template match="exercise[boolean(&INLINE-EXERCISE-FILTER;)]|&PROJECT-LIKE;|exercises//exercise|worksheet//exercise|reading-questions//exercise">
    <!-- Four types of exercises, we use local variables when we -->
    <!-- need to condition.  Exactly one of these is true, which -->
    <!-- is important in the more complicated booleans below.    -->
    <xsl:variable name="inline" select="self::exercise and boolean(&INLINE-EXERCISE-FILTER;)"/>
    <xsl:variable name="project" select="boolean(&PROJECT-FILTER;)"/>
    <xsl:variable name="divisional" select="boolean(ancestor::exercises)"/>
    <xsl:variable name="worksheet" select="boolean(ancestor::worksheet)"/>
    <xsl:variable name="reading" select="boolean(ancestor::reading-questions)"/>
    <!-- TODO: check that at least one is true? -->

    <!-- This template is for exercises when born and so should always -->
    <!-- include the statement, so we set this parameter to true.      -->
    <xsl:variable name="b-has-statement" select="true()"/>

    <!-- There are five sets of switches, so we build a single set,  -->
    <!-- depending on what type of location the "exercise" lives in. -->
    <!-- For each, exactly one location is true, and then the        -->
    <!-- expression will evaluate to the corresponding global switch -->
    <xsl:variable name="b-has-hint"
        select="($inline and $b-has-inline-hint)  or
                ($project and $b-has-project-hint)  or
                ($divisional and $b-has-divisional-hint) or
                ($worksheet and $b-has-worksheet-hint)  or
                ($reading and $b-has-reading-hint)"/>
    <xsl:variable name="b-has-answer"
        select="($inline and $b-has-inline-answer)  or
                ($project and $b-has-project-answer)  or
                ($divisional and $b-has-divisional-answer) or
                ($worksheet and $b-has-worksheet-answer)  or
                ($reading and $b-has-reading-answer)"/>
    <xsl:variable name="b-has-solution"
        select="($inline and $b-has-inline-solution)  or
                ($project and $b-has-project-solution)  or
                ($divisional and $b-has-divisional-solution) or
                ($worksheet and $b-has-worksheet-solution)  or
                ($reading and $b-has-reading-solution)"/>

    <!-- structured version of a project-like may contain a     -->
    <!-- prelude, which is rendered *before* environment begins -->
    <xsl:if test="$project and (statement or task)">
        <xsl:apply-templates select="prelude" />
    </xsl:if>
    <!-- The exact environment depends on the placement of the -->
    <!-- "exercise" when located in an "exercises" division    -->
    <xsl:variable name="env-name">
        <xsl:apply-templates select="." mode="environment-name"/>
    </xsl:variable>
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="$env-name"/>
    <xsl:text>}</xsl:text>
    <xsl:choose>
        <xsl:when test="$inline or $project">
            <!-- Looks like lots of other environments -->
            <xsl:apply-templates select="." mode="block-options"/>
        </xsl:when>
        <xsl:when test="$divisional or $worksheet or $reading">
            <!-- just a shortened number, since in a division -->
            <xsl:text>{</xsl:text>
            <xsl:apply-templates select="." mode="serial-number" />
            <xsl:text>}</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:apply-templates select="." mode="title-full"/>
            <xsl:text>}</xsl:text>
            <!-- if not in a "worksheet" and if the exercise or project-like does  -->
            <!-- not have a "workspace" attribute then this argument will be blank -->
            <xsl:text>{</xsl:text>
            <xsl:apply-templates select="." mode="sanitize-workspace"/>
            <xsl:text>}</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:apply-templates select="." mode="unique-id"/>
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{exercise-arguments-missing}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>%&#xa;</xsl:text>
    <!-- Each "idx" produces its own newline -->
    <xsl:apply-templates select="idx"/>
    <!-- Now the guts of the exercise, inside of its  -->
    <!-- (variable) identification, environment, etc. -->
    <!-- NB: the "b-component-heading" relates to     -->
    <!-- reducing duplication in solutions divisions, -->
    <!-- so comes down through the "solutions" modal  -->
    <!-- templates.  So we set it to "true()" for     -->
    <!-- "where born" exercises.                      -->
    <!-- NB: this is where we say goodbye to the      -->
    <!-- "solutions" modal templates and switch to    -->
    <!-- the "exercise-components"templates with the  -->
    <!-- $b-original flag.                            -->
    <xsl:apply-templates select="." mode="exercise-components">
        <xsl:with-param name="b-original" select="true()" />
        <xsl:with-param name="b-component-heading" select="true()"/>
        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
    </xsl:apply-templates>
    <!-- Currently inline exercises and project-like elements -->
    <!-- are not getting workspace above, so we add it here.  -->
    <xsl:if test="$inline or $project">
        <xsl:apply-templates select="." mode="workspace"/>
    </xsl:if>
    <!-- closing % necessary, as newline between adjacent environments -->
    <!-- will cause a slight indent on trailing exercise               -->
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="$env-name"/>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
    <!-- structured version of a project may contain a postlude, -->
    <!-- which is rendered *after* environment ends              -->
    <xsl:if test="$project and (statement or task)">
        <xsl:apply-templates select="postlude" />
    </xsl:if>
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


<!-- ######################### -->
<!-- Components of an Exercise -->
<!-- ######################### -->

<!-- NB: this bit of documentation seems to have hd most of the       -->
<!-- relevant code near it removed (as variations of exercises have   -->
<!-- moved to the -assembly stylesheet).  So parts are no longer      -->
<!-- applicable and maybe none of it is useful.                       -->

<!-- Five components of a "regular" exercise, two components          -->
<!-- of a "webwork" exercise, two components of a "webwork/stage",    -->
<!-- and one component of a "myopenmath".  In other words, "hint",    -->
<!-- "answer", "solution".  For re-use in solution lists and          -->
<!-- solutions manuals, we also interpret "statement" as a component. -->
<!-- $purpose determines if the components are being built for the    -->
<!-- main matter or back matter and so help be certain the right      -->
<!-- label is created.                                                -->
<!-- NB: once into an exercise, we abandon the "solutions" modal      -->
<!-- templates and instead rely on the $b-original flag to            -->
<!-- distinguish between "when born" ($b-original = true()) and a     -->
<!-- duplicate in some sort of collection of solutions                -->
<!-- ($b-original = false()).                                         -->
<!-- NB: The $b-component-heading variable gets passed down from the  -->
<!-- solutions generator, to prevent repeated headings when they are  -->
<!-- all the same.  For use when an exercise is born the situation    -->
<!-- is simpler and always has a "statement", necessitating a heading -->
<!-- on a component.  So we default the parameter to true right here. -->


<!-- ################ -->
<!-- WeBWorK Problems -->
<!-- ################ -->

<!-- The following routines are particular to extensions present  -->
<!-- in "static" versions of a WeBWorK problem.  In some cases,   -->
<!-- the PTX/XML markup includes tags and attributes generated    -->
<!-- by a WW server.  These may not be part of an author's source -->
<!-- and so is not part of the PTX schema.                        -->

<!-- A few WW-specific items need special interpretation     -->
<!-- answer blank for other kinds of answers                 -->
<xsl:template match="ul[@pi:ww-form]">
    <xsl:choose>
        <xsl:when test="@pi:ww-form = 'popup'" >
            <xsl:text>\quad(\begin{itemize*}[label=$\square$,leftmargin=3em,itemjoin=\hspace{1em}]&#xa;</xsl:text>
            <xsl:apply-templates select="li"/>
            <xsl:text>\end{itemize*})\quad&#xa;</xsl:text>
        </xsl:when>
        <!-- Radio button alternatives:                                -->
        <!--     \odot, \circledcirc (amssymb),                        -->
        <!--     \textopenbullet, \textbigcircle (textcomp)            -->
        <!-- To adjust in preamble, see use of $b-has-webwork-var      -->
        <xsl:when test="@pi:ww-form = 'buttons'" >
            <xsl:text>\begin{itemize}[label=$\bigcirc$,leftmargin=3em,]&#xa;</xsl:text>
            <xsl:apply-templates select="li"/>
            <xsl:text>\end{itemize}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="@pi:ww-form = 'checkboxes'" >
            <xsl:text>\begin{itemize}[label=$\Box$,leftmargin=3em,]&#xa;</xsl:text>
            <xsl:apply-templates select="li"/>
            <xsl:text>\end{itemize}&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- ################################################ -->
<!-- Task (for structured exercises and project-like) -->
<!-- ################################################ -->

<!-- "exercise", PROJECT-LIKE and EXAMPLE-LIKE can be structured     -->
<!-- with up to three level of "task".  When this is done, each      -->
<!-- level may have an "introduction" and a "conclusion".  This      -->
<!-- template handles every structure that can have a "task" child,  -->
<!-- which includes a "task" itself. We run over each nested "task". -->
<!-- We make sure a nested list has content, before starting (and    -->
<!-- later ending) a list to hold the tasks.  Only terminal tasks    -->
<!-- have statement|hint|answer|solution.                            -->
<xsl:template match="exercise[task]|project[task]|activity[task]|exploration[task]|investigation[task]|example[task]|question[task]|problem[task]|task[task]" mode="exercise-components">
    <xsl:param name="b-original" />
    <xsl:param name="purpose" />
    <xsl:param name="b-component-heading"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer"  />
    <xsl:param name="b-has-solution"  />

    <xsl:if test="$b-has-statement">
        <xsl:apply-templates select="introduction"/>
    </xsl:if>

    <!-- Now we see if the list of contained tasks is empty or not -->
    <xsl:variable name="task-list-dry-run">
        <xsl:apply-templates select="task" mode="dry-run">
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
            <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
            <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="b-has-task-list" select="not($task-list-dry-run = '')"/>

    <xsl:if test="$b-has-task-list">
        <xsl:apply-templates select="." mode="begin-task-list"/>

        <xsl:for-each select="task">
            <!-- just for this particular task -->
            <xsl:variable name="dry-run">
                <xsl:apply-templates select="." mode="dry-run">
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                    <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                    <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                </xsl:apply-templates>
            </xsl:variable>

            <!-- The entire task list is non-empty, so some particular task -->
            <!-- must be non-empty, ensuring we never create a list without -->
            <!-- at least one \item inside it.                              -->
            <xsl:if test="not($dry-run = '')">
                <!-- always a list item -->
                <xsl:text>\item</xsl:text>
                <!-- We use the ref/label mechanism for tasks where born. -->
                <!-- But if in a "solutions" division, we may be skipping -->
                <!-- some and need to hard-code the task label/number.    -->
                <xsl:choose>
                    <xsl:when test="$b-original">
                        <!-- \label{} will separate content, if   -->
                        <!-- employed, else we use an empty group -->
                        <xsl:choose>
                            <!-- not quite tight for modal "optional-label" -->
                            <xsl:when test="@xml:id">
                                <xsl:apply-templates select="." mode="label" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>{}</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- hard-code the number when duplicating, since some items -->
                        <!-- are absent, and then automatic numbering would be wrong -->
                        <xsl:text>[(</xsl:text>
                        <xsl:apply-templates select="." mode="list-number" />
                        <xsl:text>)]</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- Something is being output, so include an (optional) title  -->
                <!-- Semantic macro defined in preamble, mostly for font change -->
                <xsl:if test="title">
                    <xsl:text>\lititle{</xsl:text>
                    <xsl:apply-templates select="." mode="title-full"/>
                    <xsl:text>}\par%&#xa;</xsl:text>
                </xsl:if>
                <!-- Identification in place, we can write the generic guts -->
                <xsl:apply-templates select="." mode="exercise-components">
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                    <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                </xsl:apply-templates>
                <!-- possibly add some workspace for items from a worksheet     -->
                <!-- an empty result is a signal there is no workspace authored -->
                <xsl:apply-templates select="." mode="workspace"/>
            </xsl:if>
        </xsl:for-each>

        <xsl:apply-templates select="." mode="end-task-list"/>
    </xsl:if>

    <xsl:if test="$b-has-statement">
        <xsl:apply-templates select="conclusion"/>
    </xsl:if>
</xsl:template>

<!-- These two templates construct the infrastructure around a sequence  -->
<!-- of "task" realized as a LaTeX list, with help from the "enumitem"   -->
<!-- package to set the label style.  Might be better as a wrapper, but  -->
<!-- since LaTeX is text we can use different templates for the          -->
<!-- beginning and ending.  Note that the context is a *container*       -->
<!-- which has a sequence of "task" children, and the container could be -->
 <!-- a "task" itself, since we nest them.  Each produces a single line, -->
 <!-- with a trailing newline. -->

<xsl:template match="exercise|&PROJECT-LIKE;|&OPENPROBLEM-LIKE;|&EXAMPLE-LIKE;|task" mode="begin-task-list">
    <xsl:text>\begin{enumerate}[font=\bfseries,label=</xsl:text>
    <xsl:choose>
        <!-- parent is a "task", so context/container is a "task"   -->
        <!-- and it's children are "task" three deep in the nesting -->
        <xsl:when test="parent::task">
            <xsl:text>(\Alph*),ref=\theenumi.\theenumii.\Alph*</xsl:text>
        </xsl:when>
        <!-- container/context is a "task" (but it's parent is not), so -->
        <!-- the children that are "task" are two deep in the nesting   -->
        <xsl:when test="self::task">
            <xsl:text>(\roman*),ref=\theenumi.\roman*</xsl:text>
        </xsl:when>
        <!-- container/context is *not* a "task", it is something else,  -->
        <!-- and so children that are "task" are one deep in the nesting -->
        <xsl:otherwise>
            <xsl:text>(\alph*),ref=\alph*</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>]%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="exercise|&PROJECT-LIKE;|&OPENPROBLEM-LIKE;|&EXAMPLE-LIKE;|task" mode="end-task-list">
    <xsl:text>\end{enumerate}%&#xa;</xsl:text>
</xsl:template>


<!-- An object that reaches here is either just a statement (bare) or        -->
<!-- is structured as statement|hint|answer|solution.  Likely we could       -->
<!-- split this into two templates, but a choose seems more convenient.      -->
<!-- When structured, a forward reference is constructed to the first        -->
<!-- hint|answer|solution that might appear somewhere else.  Since there     -->
<!-- could be multiple targets, we use the heuristic of choosing main matter -->
<!-- over back matter.  Unclear what happens if there are multiple targets.  -->
<xsl:template match="exercise|&EXAMPLE-LIKE;|&PROJECT-LIKE;|task[not(task)]" mode="exercise-components">
    <xsl:param name="b-original" />
    <xsl:param name="purpose" />
    <xsl:param name="b-component-heading"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer"  />
    <xsl:param name="b-has-solution"  />

    <!-- The  $b-has-*  variables are a *desire* to see some component.   -->
    <!-- But if an individual exercise does not have such a component,    -->
    <!-- then it will not be shown.  So these  $b-showing-*s  variables   -->
    <!-- are per-exercise indications.                                    -->
    <!--                                                                  -->
    <!-- An exercise always has a "statement" and if shown, it is inline. -->
    <!-- When not shown (like in backmatter solutions) the exercise may   -->
    <!-- still have a "title" which is shown inline.  So the first        -->
    <!-- solution-like may be inline (no statement shown, no title        -->
    <!-- authored), or it may follow the statement/title and need a       -->
    <!-- separator to begin on a new line with a bit of a break.          -->

    <xsl:variable name="b-showing-statement" select="$b-has-statement or title"/>
    <xsl:variable name="b-showing-hints" select="$b-has-hint and hint"/>
    <xsl:variable name="b-showing-answers" select="$b-has-answer and answer"/>
    <xsl:variable name="b-showing-solutions" select="$b-has-solution and solution"/>

    <!-- structured (with components) versus unstructured (simply a bare statement) -->
    <xsl:choose>
        <xsl:when test="statement">
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="statement">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
                <!-- we consider a "program" of a coding exercise as part of the "statement" -->
                <xsl:apply-templates select="program"/>
                <xsl:if test="$b-original and ($debug.exercises.forward = 'yes')">
                    <!-- if several, all exist together, so just work with first one -->
                    <xsl:for-each select="hint[1]|answer[1]|solution[1]">
                        <!-- closer is better, so mainmatter solutions first -->
                        <xsl:choose>
                            <xsl:when test="count(.|$solutions-mainmatter) = count($solutions-mainmatter)">
                                <xsl:text>\space</xsl:text>
                                <xsl:text>\hyperlink{</xsl:text>
                                <xsl:apply-templates select="." mode="unique-id-duplicate">
                                    <xsl:with-param name="suffix" select="'main'"/>
                                </xsl:apply-templates>
                                <xsl:text>}{[</xsl:text>
                                <xsl:apply-templates select="." mode="type-name"/>
                                <xsl:text>]}</xsl:text>
                            </xsl:when>
                            <xsl:when test="count(.|$solutions-backmatter) = count($solutions-backmatter)">
                                <xsl:text>\space</xsl:text>
                                <xsl:text>\hyperlink{</xsl:text>
                                <xsl:apply-templates select="." mode="unique-id-duplicate">
                                    <xsl:with-param name="suffix" select="'back'"/>
                                </xsl:apply-templates>
                                <xsl:text>}{[</xsl:text>
                                <xsl:apply-templates select="." mode="type-name"/>
                                <xsl:text>]}</xsl:text>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:if>
            </xsl:if>
            <!-- more coming and inline presentation already used up, so add a final separator -->
            <xsl:if test="$b-showing-statement and ($b-showing-hints or $b-showing-answers or $b-showing-solutions)">
                <xsl:call-template name="exercise-component-separator"/>
            </xsl:if>
            <xsl:if test="$b-showing-hints">
                <xsl:apply-templates select="hint">
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                    <xsl:with-param name="b-has-answer" select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution" select="$b-has-solution" />
                </xsl:apply-templates>
                <!-- more coming, add a final separator -->
                <xsl:if test="$b-showing-answers or $b-showing-solutions">
                    <xsl:call-template name="exercise-component-separator"/>
                </xsl:if>
            </xsl:if>
            <xsl:if test="$b-showing-answers">
                <xsl:apply-templates select="answer">
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                    <xsl:with-param name="b-has-solution" select="$b-has-solution" />
                </xsl:apply-templates>
                <!-- more coming, add a final separator -->
                <xsl:if test="$b-showing-solutions">
                    <xsl:call-template name="exercise-component-separator"/>
                </xsl:if>
            </xsl:if>
            <xsl:if test="$b-showing-solutions">
                <xsl:apply-templates select="solution">
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                </xsl:apply-templates>
            </xsl:if>
            <!-- done, no final separator is provided -->
        </xsl:when>
        <xsl:otherwise>
            <!-- no explicit "statement", so all content is the statement -->
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="*">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
                <!-- no separator, since no trailing components -->
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- We place a separator *after* an exercise component if, and only if, -->
<!-- we know there are more components to come.  So if we have multiple  -->
<!-- solution-like, we place one after instance, but the last (see       -->
<!-- templates for each solution-like).  Between groups of identical     -->
<!-- solution-like we need to *perhaps* place a separator.               -->
<xsl:template name="exercise-component-separator">
    <xsl:text>\par\smallskip%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="hint">
    <xsl:param name="b-original" />
    <xsl:param name="purpose" />
    <xsl:param name="b-component-heading"/>
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:apply-templates select="." mode="solution-heading">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="purpose" select="$purpose" />
        <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="*">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
    <!-- separate hints after all but final one -->
    <xsl:if test="following-sibling::hint">
        <xsl:call-template name="exercise-component-separator"/>
    </xsl:if>
</xsl:template>

<xsl:template match="answer">
    <xsl:param name="b-original" />
    <xsl:param name="purpose" />
    <xsl:param name="b-component-heading"/>
    <xsl:param name="b-has-solution" />

    <xsl:apply-templates select="." mode="solution-heading">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="purpose" select="$purpose" />
        <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="*">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
    <!-- separate answers after all but final one -->
    <xsl:if test="following-sibling::answer">
        <xsl:call-template name="exercise-component-separator"/>
    </xsl:if>
</xsl:template>

<xsl:template match="solution">
    <xsl:param name="b-original" />
    <xsl:param name="purpose" />
    <xsl:param name="b-component-heading"/>

    <xsl:apply-templates select="." mode="solution-heading">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="purpose" select="$purpose" />
        <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="*">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
    <!-- separate solutions after all but final one -->
    <xsl:if test="following-sibling::solution">
        <xsl:call-template name="exercise-component-separator"/>
    </xsl:if>
</xsl:template>

<!-- Each component has a similar look, so we combine here -->
<!-- Separators depend on possible trailing items, so no   -->
<!-- vertical spacing beforehand is present here           -->
<xsl:template match="&SOLUTION-LIKE;" mode="solution-heading">
    <xsl:param name="b-original" />
    <xsl:param name="purpose" />
    <xsl:param name="b-component-heading"/>


    <!-- NB: this is the only place \blocktitlefont is written into   -->
    <!-- the body, so a tcbcolorbox could be a great idea to maintain -->
    <!-- a separation between the preamble and body                   -->
    <!-- Two slight variants, one with the type-name, one without     -->
    <!-- Here we compute numbers of multiple versions of a component, -->
    <!-- so we can later tell if we need spacing at the very end. An  -->
    <!-- empty value means element is a singleton, else the serial    -->
    <!-- number comes through.                                        -->
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="non-singleton-number" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$b-component-heading">
            <xsl:text>\noindent\textbf{\blocktitlefont </xsl:text>
            <xsl:apply-templates select="." mode="type-name"/>
            <xsl:if test="not($the-number = '')">
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="." mode="serial-number" />
            </xsl:if>
            <xsl:text>}</xsl:text> <!-- end bold type/number -->
            <xsl:if test="title">
                <xsl:text> (</xsl:text>
                <xsl:apply-templates select="." mode="title-full" />
                <xsl:text>)</xsl:text>
            </xsl:if>
            <xsl:text>.</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\noindent</xsl:text>
            <xsl:if test="not($the-number = '') or title">
                <xsl:text>\textbf{\blocktitlefont </xsl:text>
            </xsl:if>
            <xsl:if test="not($the-number = '')">
                <xsl:apply-templates select="." mode="serial-number" />
                <xsl:text>.</xsl:text>
            </xsl:if>
            <xsl:if test="title">
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="." mode="title-full" />
                <xsl:text>.</xsl:text>
            </xsl:if>
            <xsl:if test="not($the-number = '') or title">
                <xsl:text>}</xsl:text> <!-- end bold number/title -->
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
    <!-- if original, label in the usual ways  -->
    <!-- if duplicate, use extraordinary label -->
    <xsl:choose>
        <!-- a solution right where the exercise is born -->
        <xsl:when test="$b-original">
            <xsl:apply-templates select="." mode="label"/>
        </xsl:when>
            <!-- Finally, the purpose of $purpose.  We know if this  -->
            <!-- solution is being displayed in the main matter or   -->
            <!-- in the back matter, so we can provide the correct   -->
            <!-- suffix to the label.                                -->
        <xsl:when test="$purpose = 'mainmatter'">
            <xsl:text>\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="unique-id-duplicate">
                <xsl:with-param name="suffix" select="'main'"/>
            </xsl:apply-templates>
            <xsl:text>}{}</xsl:text>
        </xsl:when>
        <xsl:when test="$purpose = 'backmatter'">
            <xsl:text>\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="unique-id-duplicate">
                <xsl:with-param name="suffix" select="'back'"/>
            </xsl:apply-templates>
            <xsl:text>}{}</xsl:text>
        </xsl:when>
        <!-- linking not enabled for PDF solution manual -->
        <xsl:when test="$purpose = 'solutionmanual'" />
        <!-- born (original=true), or mainmatter, or backmatter, or solutionmanual -->
        <xsl:otherwise>
            <xsl:message>PTX:BUG:     Exercise component mis-labeled</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <!-- some distance to actual content, if necessary -->
    <xsl:if test="$b-component-heading or not($the-number = '') or title">
        <xsl:text>\quad{}</xsl:text>
    </xsl:if>
</xsl:template>


<!-- Definition Like, Remark Like, Computation Like, Example Like  -->
<!-- Simpler than theorems, definitions, etc      -->
<!-- Only EXAMPLE-LIKE has hint, answer, solution -->
<xsl:template match="&DEFINITION-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&OPENPROBLEM-LIKE;|&EXAMPLE-LIKE;">
    <!-- structured version may contain a prelude -->
    <!-- no structure => don't even consider it   -->
    <xsl:if test="statement or task">
        <xsl:apply-templates select="prelude" />
    </xsl:if>
    <!-- environment, title, label string, newline -->
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="block-options"/>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:choose>
        <!-- We use common routines for this variant, but     -->
        <!-- components of these objects are not controllable -->
        <!-- by switches, as their nomenclature implies they  -->
        <!-- are essential, not like exercises or projects.   -->
        <!-- NB: template is not parameterized at all         -->
        <!-- prelude?, statement, hint*, answer*, solution*, postlude? -->
        <xsl:when test="&EXAMPLE-FILTER;">
            <xsl:apply-templates select="." mode="exercise-components">
                <xsl:with-param name="b-original" select="true()" />
                <xsl:with-param name="b-component-heading" select="true()" />
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint" select="true()" />
                <xsl:with-param name="b-has-answer" select="true()" />
                <xsl:with-param name="b-has-solution" select="true()" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="&OPENPROBLEM-FILTER;">
            <xsl:apply-templates select="." mode="openproblem-components"/>
        </xsl:when>
        <!-- unstructured, just a bare statement          -->
        <!-- no need to avoid dangerous misunderstandings -->
        <xsl:otherwise>
            <xsl:apply-templates select="*"/>
        </xsl:otherwise>
    </xsl:choose>
    <!-- Apply workspace if appropriate -->
    <xsl:apply-templates select="." mode="workspace"/>
    <xsl:text>\end{</xsl:text>
        <xsl:value-of select="local-name(.)" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
    <!-- structured version may contain a postlude -->
    <!-- no structure => don't even consider it    -->
    <xsl:if test="statement or task">
        <xsl:apply-templates select="postlude" />
    </xsl:if>
</xsl:template>

<!-- An aside goes into a framed box             -->
<!-- We do not distinguish biographical or       -->
<!-- historical semantically, but perhaps should -->
<!-- title is inline, boldface in mdframe setup  -->
<xsl:template match="&ASIDE-LIKE;">
    <!-- environment, title, label string, newline -->
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="block-options"/>
    <xsl:text>%&#xa;</xsl:text>
    <!-- Process any metadata-type elements,  -->
    <!-- except title is in the block options -->
    <xsl:apply-templates select="idx"/>
    <!-- Coordinate with schema, since we enforce it here -->
    <xsl:apply-templates select="p|blockquote|pre|image|video|program|console|tabular"/>
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- Assemblages -->
<!-- Low-structure content, high-visibility presentation -->
<!-- Title is optional, keep remainders coordinated      -->
<xsl:template match="assemblage">
    <!-- environment, title, label string, newline -->
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="block-options"/>
    <xsl:text>%&#xa;</xsl:text>
    <!-- Coordinate with schema, since we enforce it here -->
    <xsl:apply-templates select="p|blockquote|pre|image|video|program|console|tabular|sidebyside|sbsgroup" />
    <!-- Apply workspace if appropriate -->
    <xsl:apply-templates select="." mode="workspace"/>
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- A GOAL-LIKE element holds a list,         -->
<!-- surrounded by introduction and conclusion -->
<xsl:template match="&GOAL-LIKE;">
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <!-- Following is not consistent, might be better to    -->
    <!-- opt for a default title of one is not provided     -->
    <!-- Then maybe integrate with "block-options" template -->
    <!-- 2022-12-14: now more consistent, as in-context     -->
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:if test="title">
        <xsl:text>: </xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
    </xsl:if>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id"/>
    <xsl:text>}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="introduction" />
    <xsl:apply-templates select="ol|ul|dl" />
    <xsl:apply-templates select="conclusion" />
    <!-- Apply workspace if appropriate -->
    <xsl:apply-templates select="." mode="workspace"/>
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- DISCUSSION-LIKE -->

<!-- DISCUSSION-LIKE are appendages of OPENPROBLEM-LIKE, or an        -->
<!-- OPENPROBLEM-LIKE can be structured with "task" and then the      -->
<!-- appendages are the content of *terminal* "task".  So we always   -->
<!-- have the OPEN-PROBLEMLIKE as an overall container (giving rise   -->
<!-- to a LaTeX environment) and perhaps "task" as a container at     -->
<!-- the leaves of the tree of "task".                                -->
<!--                                                                  -->
<!-- This is very similar to "exercise" (and similar) and appendages  -->
<!-- that are SOLUTION-LIKE.  However, it is much simpler since we do -->
<!-- not have varieties of options for visibility and "dry-run"       -->
<!-- templates to see if enclosing structures are needed or not.      -->
<!--                                                                  -->
<!-- The modal "openproblem-components" template is modeled after     -->
<!-- the earlier-implemented "exercise-components".  It is recursive  -->
<!-- in the case of (nested) "task".  And it is much simpler.  As a   -->
<!-- modal template, this will maintain a separation with the modal   -->
<!-- "exercise-components", especially as it pertains to              -->
<!-- intermediate "task".                                             -->

 <!-- The case of terminal containers.  We do not entertain bare content   -->
 <!-- as a "statement", though a pre-processor might allow that in source. -->
<xsl:template match="&OPENPROBLEM-LIKE;|task" mode="openproblem-components">
    <xsl:apply-templates select="statement|&DISCUSSION-LIKE;"/>
</xsl:template>

<xsl:template match="openproblem[task]|openquestion[task]|openconjecture[task]|task[task]" mode="openproblem-components">
    <xsl:apply-templates select="introduction"/>

    <xsl:apply-templates select="." mode="begin-task-list"/>
    <xsl:for-each select="task">
        <xsl:text>\item</xsl:text>
        <!-- We use the ref/label mechanism       -->
        <!-- \label{} will separate content, if   -->
        <!-- employed, else we use an empty group -->
        <xsl:choose>
            <xsl:when test="@xml:id">
                <xsl:apply-templates select="." mode="label" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>{}</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <!-- Semantic macro defined in preamble, mostly for font change -->
        <xsl:if test="title">
            <xsl:text>\lititle{</xsl:text>
            <xsl:apply-templates select="." mode="title-full"/>
            <xsl:text>}\par%&#xa;</xsl:text>
        </xsl:if>
        <!-- Note: context is *child* task due to context switch via "for-each" -->
        <xsl:apply-templates select="." mode="openproblem-components"/>
    </xsl:for-each>
    <xsl:apply-templates select="." mode="end-task-list"/>

    <xsl:apply-templates select="conclusion"/>
</xsl:template>

<!-- DISCUSSION-LIKE proper are fairly simple and hard-coded to a  -->
<!-- large extent, since using tcolorbox for these might lead to a -->
<!-- breakable/unbreakable mess.  Still, these could have their    -->
<!-- matches split out to provide finer distinctions.              -->

<xsl:template match="&DISCUSSION-LIKE;">
    <!-- break *before* the appendage -->
    <xsl:text>\par%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="discussion-heading"/>
    <!-- DISCUSSION-LIKE assumed to be structured -->
    <xsl:apply-templates select="*"/>
</xsl:template>

<xsl:template match="&DISCUSSION-LIKE;" mode="discussion-heading">
    <xsl:text>\noindent\textbf{\blocktitlefont </xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="serial-number" />
    <xsl:text>}</xsl:text> <!-- end bold type/number -->
    <xsl:if test="title">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:text>.\space\space</xsl:text>
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>


<!-- Paragraphs -->
<!-- \par *separates* paragraphs So look backward for          -->
<!-- cases where a paragraph would have been the previous      -->
<!-- thing in the output Not: "notation", "todo", index, etc   -->
<!-- Guarantee: Never a blank line, always finish with newline -->
<!--                                                           -->
<!-- Note: a paragraph could end with an item we want          -->
<!-- to look good in the source, like a list or display        -->
<!-- math and we already have a newline so any subsequent      -->
<!-- content from the paragraph will start anwew.  But         -->
<!-- there might not be anything more to output.  So we        -->
<!-- always end with a %-newline combo.                        -->

<!-- TODO: maybe we could look backward at the end of a paragraph       -->
<!-- to see if the above scenario happens, and we could end gracefully. -->
<xsl:template match="p">
    <xsl:variable name="node-preceding-current" select="preceding-sibling::*[not(&SUBDIVISION-METADATA-FILTER;)][1]" />
    <xsl:if test="$node-preceding-current[self::p or self::paragraphs or self::sidebyside or self::case]">
        <xsl:text>\par</xsl:text>
        <xsl:if test="$node-preceding-current[self::paragraphs or self::case]">
            <xsl:text>\medskip</xsl:text>
        </xsl:if>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <!-- we can't cross-reference here without an @xml:id -->
    <!-- place it on a line of its own just prior to guts -->
    <xsl:apply-templates select="." mode="optional-label"/>
    <!-- line break is optional as well -->
    <xsl:if test="@xml:id">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:text>%&#xa;</xsl:text>
    <!-- Add workspace if appropriate -->
    <xsl:apply-templates select="." mode="workspace"/>
</xsl:template>

<!-- For a memo, not indenting the first paragraph helps -->
<!-- with alignment and the to/from/subject/date block   -->
<!-- TODO: maybe memo header should set this up          -->
<xsl:template match="memo/p[1]">
    <xsl:text>\noindent{}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- ########### -->
<!-- Mathematics -->
<!-- ########### -->

<!-- Mathematics authored in LaTeX syntax should be       -->
<!-- independent of output format.  Despite MathJax's     -->
<!-- broad array of capabilities, there are still some    -->
<!-- differences which we need to accomodate via abstract -->
<!-- templates.                                           -->

<!-- See the -common stylesheet for manipulations of math elements     -->
<!-- and subsequent text nodes that lead with punctuation.  Basically, -->
<!-- punctuation can migrate from the start of the text node and into  -->
<!-- the math, wrapped in a \text{}.  We do this to display math as a  -->
<!-- service to authors.  But LaTeX handles this situation carefully   -->
<!-- for inline math.                                                  -->
<xsl:variable name="math.punctuation.include" select="'display'"/>

<!-- Inline Mathematics ("m") -->
<!-- We use the asymmetric LaTeX delimiters \( and \).     -->
<!-- For LaTeX these are not "robust", hence break moving  -->
<!-- items (titles, index), so use the "fixltx2e" package, -->
<!-- which declares \MakeRobust\( and \MakeRobust\)        -->

<!-- This template wraps inline math in delimiters -->
<xsl:template name="inline-math-wrapper">
    <xsl:param name="math"/>
    <xsl:text>\(</xsl:text>
    <xsl:value-of select="$math"/>
    <xsl:text>\)</xsl:text>
</xsl:template>

<!-- Displayed Single-Line Math ("me", "men") -->

<!-- The default template just calls the modal "body"      -->
<!-- template needed for the HTML knowl production scheme. -->
<!-- The variables in the "body" template have the right   -->
<!-- defaults for this application                         -->
<xsl:template match="me|men">
    <xsl:apply-templates select="." mode="body" />
</xsl:template>

<xsl:template name="display-math-visual-blank-line">
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- Simply apply modal "label" template,  -->
<!-- to allow for LaTeX equation numbering -->
<xsl:template match="men|mrow" mode="tag">
    <xsl:apply-templates select="." mode="label" />
</xsl:template>

<!-- An mrow with a \label{} can be cross-referenced    -->
<!-- md/mdn and \notag in -common control much of this  -->
<!-- For a local tag, we need to provide the symbol AND -->
<!-- also provide a label for the cross-reference       -->
<xsl:template match="mrow[@tag]" mode="tag">
    <!-- if mrow has custom tag, we add it here -->
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="@tag" mode="tag-symbol" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
</xsl:template>


<!-- Displayed Multi-Line Math ("md", "mdn") -->

<!-- The default template for the "md" and "mdn" containers   -->
<!-- just calls the modal "body" template needed for the HTML -->
<!-- knowl production scheme. The variables in the "body"     -->
<!-- template have the right defaults for this application    -->

<xsl:template match="md|mdn">
    <xsl:apply-templates select="." mode="body" />
</xsl:template>

<!-- Rows of Displayed Multi-Line Math ("mrow") -->
<!-- Template in -common is sufficient with abstract templates -->
<!--                                                           -->
<!-- (1) "display-page-break"                                  -->

<!-- Page Breaks within Display Math -->
<!-- \allowdisplaybreaks is on globally always          -->
<!-- If parent has  break="no"  then surpress with a *  -->
<!-- Unless "mrow" has  break="yes" then leave alone    -->
<!-- no-op for the base version, where it is irrelevant -->

<xsl:template match="mrow" mode="display-page-break">
    <xsl:if test="parent::*/@break='no' and not(@break='yes')">
        <xsl:text>*</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Intertext -->
<!-- An <mrow> will provide trailing newline, -->
<!-- so we do the same here for visual source -->
<!-- We need to do this very differently for  -->
<!-- HTML (we fake it), so there is no        -->
<!-- implementation in the -common scheme     -->
<xsl:template match="intertext">
    <xsl:text>\intertext{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>


<!-- ##### -->
<!-- Index -->
<!-- ##### -->

<!-- Support LaTeX-native or PreTeXt universal -->

<!-- $index-maker is a parameter that will eventually be set as a  -->
<!-- publisher variable.  It defaults to "latex", though this may  -->
<!-- change.  We support two schemes for marking index locations.  -->

<xsl:template match="idx">
    <xsl:choose>
        <xsl:when test="$index-maker = 'pretext'">
            <xsl:apply-templates select="." mode="pretext-index"/>
        </xsl:when>
        <xsl:when test="$index-maker = 'latex'">
            <xsl:apply-templates select="." mode="latex-index"/>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template match="idx" mode="pretext-index">
    <xsl:text>\label{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id"/>
    <xsl:text>}</xsl:text>
    <!-- do not introduce anymore whitespace into a "p" than there   -->
    <!-- already is, but do format these one-per-line outside of "p" -->
    <xsl:if test="not(ancestor::p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- Unstructured                       -->
<!-- simple and quick, minimal features -->
<!-- Only supports  @sortby  attribute  -->
<xsl:template match="idx[not(h)]" mode="latex-index">
    <xsl:text>\index{</xsl:text>
    <xsl:apply-templates select="@sortby" mode="latex-index"/>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
    <!-- do not introduce anymore whitespace into a "p" than there   -->
    <!-- already is, but do format these one-per-line outside of "p" -->
    <xsl:if test="not(ancestor::p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Structured                                      -->
<!--   h - one to three                              -->
<!--   see, seealso - one total                      -->
<!--   @start, @finish support page ranges for print -->
<xsl:template match="idx[h]" mode="latex-index">
    <xsl:text>\index{</xsl:text>
    <xsl:apply-templates select="h" mode="latex-index"/>
    <xsl:apply-templates select="see" mode="latex-index"/>
    <xsl:apply-templates select="seealso" mode="latex-index"/>
    <xsl:apply-templates select="@finish" mode="latex-index"/>
    <xsl:text>}</xsl:text>
    <!-- do not introduce anymore whitespace into a "p" than there   -->
    <!-- already is, but do format these one-per-line outside of "p" -->
    <xsl:if test="not(ancestor::p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Page Range, Finish Variant              -->
<!-- @start is a marker for END of a range   -->
<!-- End of page range duplicates it's start -->
<xsl:template match="index[@start] | idx[@start]" mode="latex-index">
    <xsl:variable name="start" select="id(@start)" />
    <xsl:text>\index{</xsl:text>
    <xsl:apply-templates select="$start/h" mode="latex-index"/>
    <xsl:apply-templates select="$start/see" mode="latex-index"/>
    <xsl:apply-templates select="$start/seealso" mode="latex-index"/>
    <xsl:apply-templates select="@start" mode="latex-index"/>
    <xsl:text>}</xsl:text>
    <!-- do not introduce anymore whitespace into a "p" than there   -->
    <!-- already is, but do format these one-per-line outside of "p" -->
    <xsl:if test="not(ancestor::p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="index/@sortby|idx/@sortby|h/@sortby" mode="latex-index">
    <xsl:value-of select="." />
    <xsl:text>@</xsl:text>
</xsl:template>

<xsl:template match="idx/h" mode="latex-index">
    <xsl:if test="preceding-sibling::h">
        <xsl:text>!</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="@sortby" mode="latex-index"/>
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="idx/see" mode="latex-index">
    <xsl:text>|see{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="idx/seealso" mode="latex-index">
    <xsl:text>|seealso{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- finish  attribute suggests range (only) -->
<xsl:template match="@finish" mode="latex-index">
    <xsl:text>|(</xsl:text>
</xsl:template>

<!-- start  attribute marks end of range  -->
<xsl:template match="@start" mode="latex-index">
    <xsl:text>|)</xsl:text>
</xsl:template>

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Good match between basic HTML types and basic LaTeX types -->

<!-- Utility templates to translate @marker specification -->
<!-- for use with LaTeX enumitem package's label keyword  -->
<xsl:template match="ol" mode="latex-list-label">
    <xsl:variable name="format-code" select="./@format-code" />
    <xsl:value-of select="./@marker-prefix" />
    <xsl:choose>
        <xsl:when test="$format-code = '0'">\arabic*</xsl:when>
        <xsl:when test="$format-code = '1'">\arabic*</xsl:when>
        <xsl:when test="$format-code = 'a'">\alph*</xsl:when>
        <xsl:when test="$format-code = 'A'">\Alph*</xsl:when>
        <xsl:when test="$format-code = 'i'">\roman*</xsl:when>
        <xsl:when test="$format-code = 'I'">\Roman*</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:BUG: bad ordered list label format code in LaTeX conversion</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="./@marker-suffix" />
</xsl:template>

<xsl:template match="ul" mode="latex-list-label">
    <xsl:variable name="format-code">
        <xsl:apply-templates select="." mode="format-code" />
    </xsl:variable>
   <xsl:choose>
        <xsl:when test="$format-code = 'disc'">\textbullet</xsl:when>
        <xsl:when test="$format-code = 'circle'">$\circ$</xsl:when>
        <xsl:when test="$format-code = 'square'">$\blacksquare$</xsl:when>
        <xsl:when test="$format-code = 'none'"></xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:BUG: bad unordered list label format code in LaTeX conversion</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Utility template to translate unordered    -->
<!-- list level to HTML list-style-type         -->
<!-- This is similar to Firefox default choices -->
<!-- but different in the fourth slot           -->
<!-- disc, circle, square, disc                 -->
<!-- TODO: cannot find text mode filled black square symbol -->
<!-- TODO: textcomp (now in main latex) has \textopenbullet (unexamined) -->
<xsl:template match="*" mode="latex-unordered-list-label-default">
    <xsl:variable name="level">
        <xsl:apply-templates select="." mode="unordered-list-level" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$level='0'">\textbullet</xsl:when>
        <xsl:when test="$level='1'">$\circ$</xsl:when>
        <xsl:when test="$level='2'">$\blacksquare$</xsl:when>
        <xsl:when test="$level='3'">\textbullet</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: unordered list is more than 4 levels deep</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Lists themselves -->
<!-- If columns are specified, we        -->
<!-- wrap in the multicolumn environment -->
<xsl:template match="ol">
    <!-- need to switch on 0-1 for ol Arabic -->
    <!-- no harm if called on "ul"           -->
    <xsl:variable name="format-code" select="./@format-code" />
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
    <xsl:text>%&#xa;</xsl:text>
    <xsl:if test="not($ncols = 1)">
        <xsl:text>\begin{multicols}{</xsl:text>
        <xsl:value-of select="@cols" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{enumerate}</xsl:text>
    <!-- override LaTeX defaults as indicated -->
    <xsl:if test="@marker or ($format-code = '0') or ancestor::exercises or ancestor::worksheet or ancestor::handout or ancestor::reading-questions or ancestor::references">
        <xsl:text>[label={</xsl:text>
        <xsl:apply-templates select="." mode="latex-list-label" />
        <xsl:if test="$format-code = '0'">
            <xsl:text>, start=0</xsl:text>
        </xsl:if>
        <xsl:text>}]</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
     <xsl:apply-templates select="li"/>
    <xsl:text>\end{enumerate}&#xa;</xsl:text>
    <xsl:if test="not($ncols = 1)">
        <xsl:text>\end{multicols}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- PTX unordered list scheme is distinct -->
<!-- from LaTeX's so we write out a label  -->
<!-- choice for each such list             -->
<xsl:template match="ul">
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
    <xsl:text>%&#xa;</xsl:text>
    <xsl:if test="not($ncols = 1)">
        <xsl:text>\begin{multicols}{</xsl:text>
        <xsl:value-of select="@cols" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{itemize}[label=</xsl:text>
    <xsl:apply-templates select="." mode="latex-list-label" />
    <xsl:text>]&#xa;</xsl:text>
    <xsl:apply-templates select="li"/>
    <xsl:text>\end{itemize}&#xa;</xsl:text>
    <xsl:if test="not($ncols = 1)">
        <xsl:text>\end{multicols}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="dl">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\begin{descriptionlist}&#xa;</xsl:text>
    <xsl:apply-templates select="li"/>
    <xsl:text>\end{descriptionlist}&#xa;</xsl:text>
</xsl:template>

<!-- List Items -->
<!-- If the content is structured, we presume the last  -->
<!-- element ends the line with a newline of some sort. -->
<!-- If the content is unstructured, we end the line    -->
<!-- with at least some content (%) and a newline.      -->
<!-- Keep the tests here in sync with DTD.              -->

<!-- In an ordered list, an item can be a target -->
<!-- but only if it has an @xml:id to use        -->
<xsl:template match="ol/li">
    <xsl:text>\item</xsl:text>
    <!-- \label{} will separate content, if   -->
    <!-- employed, else we use an empty group -->
    <xsl:choose>
        <!-- not quite tight for modal "optional-label" -->
        <xsl:when test="@xml:id">
            <xsl:apply-templates select="." mode="label" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- "title" only possible for structured version of a list item -->
    <!-- Semantic macro defined in preamble, mostly for font change  -->
    <xsl:if test="title">
        <xsl:text>\lititle{</xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>}\par%&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="not(p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="workspace"/>
</xsl:template>

<!-- In an unordered list, an item cannot be a target -->
<!-- So we use an empty group to end the \item        -->
<xsl:template match="ul/li">
    <xsl:text>\item{}</xsl:text>
    <!-- "title" only possible for structured version of a list item -->
    <!-- Semantic macro defined in preamble, mostly for font change  -->
    <xsl:if test="title">
        <xsl:text>\lititle{</xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>}\par%&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="not(p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="workspace"/>
</xsl:template>

<!-- Description lists always have title as additional -->
<!-- argument In a description list, an item can be a  -->
<!-- target but only if it has an @xml:id to use       -->
<xsl:template match="dl/li">
    <xsl:variable name="item-environment">
        <xsl:choose>
            <xsl:when test="parent::dl/@width = 'narrow'">
                <xsl:text>dlinarrow</xsl:text>
            </xsl:when>
            <!-- the default (specified, or absent) -->
            <xsl:otherwise>
                <xsl:text>dlimedium</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="$item-environment"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id" />
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="$item-environment"/>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>


<!-- ############ -->
<!-- Music Scores -->
<!-- ############ -->

<!-- Embed an interactive score from MuseScore                          -->
<!-- Flag: score element has two MuseScore-specific attributes          -->
<!-- https://musescore.org/user/{usernumber}/scores/{scorenumber}/embed -->
<!-- into an iframe with width and height (todo)                        -->
<xsl:template match="score[@musescoreuser and @musescore]">
    <xsl:text>[\mono{\nolinkurl{https://musescore.org/user/</xsl:text>
    <xsl:value-of select="@musescoreuser" />
    <xsl:text>/scores/</xsl:text>
    <xsl:value-of select="@musescore" />
    <xsl:text>}} not yet realized in \LaTeX]&#xa;</xsl:text>
</xsl:template>

<!-- ######## -->
<!-- SI Units -->
<!-- ######## -->

<xsl:template match="quantity">
    <xsl:choose>
        <!-- no magnitude, only units -->
        <xsl:when test="not(mag) and (unit or per)">
            <xsl:text>\si{</xsl:text>
            <xsl:apply-templates select="unit"/>
            <xsl:apply-templates select="per"/>
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- magnitude, plus units -->
        <xsl:when test="mag and (unit or per)">
            <xsl:text>\SI{</xsl:text>
            <xsl:value-of select="mag"/>
            <xsl:text>}{</xsl:text>
            <xsl:apply-templates select="unit"/>
            <xsl:apply-templates select="per"/>
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- magnitude only -->
        <xsl:when test="mag">
            <xsl:text>\num{</xsl:text>
            <xsl:value-of select="mag"/>
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- nothing (really should be caught in schema) -->
        <!-- but no real harm in just doing nothing      -->
        <xsl:otherwise />
    </xsl:choose>
</xsl:template>

<xsl:template match="unit|per">
    <xsl:if test="self::per">
        <xsl:text>\per</xsl:text>
    </xsl:if>
    <!-- prefix is optional -->
    <xsl:if test="@prefix">
        <xsl:text>\</xsl:text>
        <xsl:value-of select="@prefix"/>
    </xsl:if>
    <!-- base unit is required -->
    <xsl:text>\</xsl:text>
    <xsl:value-of select="@base"/>
    <!-- optional exponent -->
    <xsl:if test="@exp">
        <xsl:text>\tothe{</xsl:text>
            <xsl:value-of select="@exp"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>


<!-- Actual Quotations                -->
<!-- TODO: <quote> element for inline -->
<xsl:template match="blockquote">
    <xsl:text>\begin{quote}</xsl:text>
    <xsl:apply-templates select="." mode="optional-label"/>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>\end{quote}&#xa;</xsl:text>
</xsl:template>

<!-- ############ -->
<!-- Attributions -->
<!-- ############ -->

<!-- At end of: blockquote, preface, foreword       -->
<!-- free-form for one line, or structured as lines -->
<!-- LaTeX lacks a quotation dash, emdash instead   -->
<!-- Discourage a page break prior                  -->
<!-- TODO: make a rule for quotation-dash?          -->

<!-- Single line, mixed-content                     -->
<!-- Or structured by "line" elements               -->
<!-- Quotation dash if within blockquote            -->
<!-- A table, pushed right, with left-justification -->
<!-- TODO: CMOS says blockquote-attribution goes in -->
<!-- parentheses (see 5e, 11.81), while this style  -->
<!-- is for chapter epigraphs (see 5e, 1.39, 11.40) -->
<xsl:template match="attribution">
    <xsl:text>\nopagebreak\par%&#xa;</xsl:text>
    <xsl:text>\hfill</xsl:text>
    <xsl:if test="parent::blockquote">
        <xsl:call-template name="mdash-character"/>
        <!-- remove the left-side column spacing -->
        <xsl:text>{\setlength{\tabcolsep}{0pt}</xsl:text>
    </xsl:if>
    <xsl:text>\begin{tabular}[t]{l@{}}&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="line">
            <xsl:apply-templates select="line" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\end{tabular}</xsl:text>
    <!-- end group with table spacing change -->
    <xsl:if test="parent::blockquote">
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>\\\par&#xa;</xsl:text>
</xsl:template>

<!-- Emphasis -->
<xsl:template match="em">
    <xsl:text>\emph{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Alert -->
<!-- \alert{} defined in preamble as semantic macro -->
<xsl:template match="alert">
    <xsl:text>\alert{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Insert (an edit) -->
<!-- \inserted{} defined in preamble as semantic macro -->
<xsl:template match="insert">
    <xsl:text>\inserted{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<!-- Protect the version of the macro appearing in titles -->
<xsl:template match="title//insert|shortitle//insert">
    <xsl:text>\protect\inserted{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Delete (an edit) -->
<!-- \deleted{} defined in preamble as semantic macro -->
<xsl:template match="delete">
    <xsl:text>\deleted{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<!-- Protect the version of the macro appearing in titles -->
<xsl:template match="title//delete|shortitle//delete">
    <xsl:text>\protect\deleted{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Stale (no longer relevant) -->
<!-- \stale{} defined in preamble as semantic macro -->
<xsl:template match="stale">
    <xsl:text>\stale{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<!-- Protect the version of the macro appearing in titles -->
<xsl:template match="title//stale|shorttitle//stale">
    <xsl:text>\protect\stale{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Term (defined terms) -->
<!-- \terminology{} defined in preamble as semantic macro -->
<xsl:template match="term">
    <xsl:text>\terminology{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Acronyms, Initialisms, Abbreviations -->
<!-- abbreviation: contracted form                             -->
<!-- acronym: initials, pronounced as a word (eg SCUBA, RADAR) -->
<!-- initialism: one letter at a time, (eg CIA, FBI)           -->
<!-- All use (no-op) semantic macros, defined in preamble      -->
<!-- TODO:  Test here for content ends in a period            -->
<!-- if next char is space, use macro that accomplishes "\@." -->
<!-- if next char is a char, use macro for .\@                -->
<!-- BUT if new sentence, then just leave the period alone    -->
<xsl:template match="abbr">
    <xsl:text>\abbreviation{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="acro">
    <xsl:text>\acronym{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="init">
    <xsl:text>\initialism{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Titles migrate to PDF bookmarks/ToC and need to be handled  -->
<!-- differently, even if we haven't quite figured out how       -->
<xsl:template match="title//abbr|shortitle//abbr">
    <xsl:text>\abbreviationintitle{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="title//acro|shortitle//acro">
    <xsl:text>\acronymintitle{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="title//init|shortitle//acro">
    <xsl:text>\initialismintitle{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>


<!-- ############# -->
<!-- External URLs -->
<!-- ############# -->

<!-- We escape all the problem LaTeX characters      -->
<!-- when given in the @href attribute, \nolinkurl{} -->
<!-- and \href{}{} seem to do the right thing        -->
<!-- and they do better in footnotes and table cells -->
<!-- Within titles, we just produce (formatted)      -->
<!-- text, but nothing active                        -->
<!-- N.B. compare with LaTeX version, could move much to -common -->

<!-- \nolinkurl{} seems to provide line-breaking     -->
<xsl:template match="url|dataurl">
    <!-- link/reference/location may be external -->
    <!-- (@href) or internal (dataurl[@source])  -->
    <xsl:variable name="uri">
        <xsl:choose>
            <!-- "url" and "dataurl" both support external @href -->
            <xsl:when test="@href">
                <xsl:value-of select="@href"/>
            </xsl:when>
            <!-- a "dataurl" might be local, @source is        -->
            <!-- indication, so prefix with a local path/URI,  -->
            <!-- add "external" directory, via template useful -->
            <!-- also for visual URL formulation in -assembly  -->
            <xsl:when test="self::dataurl and @source">
                <xsl:apply-templates select="." mode="static-url"/>
            </xsl:when>
            <!-- empty will be non-functional -->
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:variable>
    <!-- form the "clickable" (visible) text -->
    <xsl:variable name="visible-text">
        <xsl:choose>
            <!-- process content, as-is, when authored -->
            <xsl:when test="node()">
                <xsl:apply-templates/>
            </xsl:when>
            <!-- absent content, use a URL, with   -->
            <!-- preference for @visual over @href -->
            <xsl:otherwise>
                <xsl:text>\nolinkurl{</xsl:text>
                <!-- sanitize the URL for LaTeX output -->
                <xsl:call-template name="escape-url-to-latex">
                    <xsl:with-param name="text">
                        <xsl:choose>
                            <xsl:when test="@visual">
                                <xsl:value-of select="@visual"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$uri"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                </xsl:call-template>
                <xsl:text>}</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::shorttitle|ancestor::subtitle">
            <xsl:choose>
                <xsl:when test="node()">
                    <xsl:copy-of select="$visible-text"/>
                </xsl:when>
                <!-- migration to a title requires a version without a -->
                <!-- "\nolinkurl{}" else the *.out file gets messed up -->
                <!-- (PDF bookmarks?)                                  -->
                <xsl:when test="@visual">
                    <xsl:text>\mono{</xsl:text>
                    <xsl:value-of select="@visual"/>
                    <xsl:text>}</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\mono{</xsl:text>
                    <xsl:value-of select="$uri"/>
                    <xsl:text>}</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <!-- the actual URL -->
            <xsl:text>\href{</xsl:text>
            <xsl:call-template name="escape-url-to-latex">
                <xsl:with-param name="text">
                    <xsl:value-of select="$uri" />
                </xsl:with-param>
            </xsl:call-template>
            <xsl:text>}</xsl:text>
            <!-- the visible clickable -->
            <xsl:text>{</xsl:text>
            <xsl:copy-of select="$visible-text"/>
            <xsl:text>}</xsl:text>
            <!-- A content-full URL will have an authored @visual version,  -->
            <!-- or the pre-processor will have manufactured a reasonable   -->
            <!-- one.  Only if an author explicitly denies this option with -->
            <!-- an empty string will this not be available/possible.  For  -->
            <!-- print versions of a PDF we add this parenthetically.       -->
            <xsl:if test="$b-latex-print and node() and not(@visual = '')">
                <!-- space to separate -->
                <xsl:text> </xsl:text>
                <!-- parentheses, plus line-breakable monospace font -->
                <xsl:text>(\nolinkurl{</xsl:text>
                <xsl:call-template name="escape-url-to-latex">
                    <xsl:with-param name="text">
                        <xsl:value-of select="@visual" />
                    </xsl:with-param>
                </xsl:call-template>
                <xsl:text>})</xsl:text>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############# -->
<!-- Verbatim Text -->
<!-- ############# -->

<!-- Code, inline -->
<!-- We escape every possible problematic character before     -->
<!-- applying a macro which will presumably apply a typewriter -->
<!-- font (which is not presumed to get strict mono spacing).  -->
<xsl:template name="code-wrapper">
    <xsl:param name="content"/>

    <xsl:text>\mono{</xsl:text>
    <xsl:call-template name="escape-text-to-latex">
        <xsl:with-param name="text" select="$content" />
    </xsl:call-template>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- cd is for use in paragraphs, inline            -->
<!-- One line is mixed content, and should be tight -->
<!-- Formatted for visual appeal in LaTeX source    -->
<!-- "cd" could be first in a paragraph, so do not  -->
<!-- drop an empty line                             -->
<!-- With a "cline" element present, we assume      -->
<!-- that is the entire structure (see the cline    -->
<!-- template in the pretext-common.xsl file)       -->
<xsl:template match="cd">
    <xsl:variable name="cd-env">
        <xsl:apply-templates select="." mode="environment-name"/>
    </xsl:variable>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="$cd-env"/>
    <xsl:text>}</xsl:text>
    <!-- optional visible spaces -->
    <xsl:choose>
        <xsl:when test="not(@showspaces) or (@showspaces = 'none')">
            <!-- line break now for verbatim text -->
            <xsl:text>&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="@showspaces = 'all'">
            <!-- option, *then* line break now for verbatim text -->
            <xsl:text>[showspaces=true]&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <!-- content: structured, then single line -->
    <xsl:choose>
        <xsl:when test="cline">
            <xsl:apply-templates select="cline"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="."/>
            <xsl:text>&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="$cd-env"/>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- An indented structure. like an item in a list likely does not -->
<!-- need *more* indentation.  A "cd" inside a "p" inside a list   -->
<!-- *will* be indented, but a bare "cd" as a *child* of an "li"   -->
<!-- will not be.  Unclear if we want this condition for when the  -->
<!-- "cd" is the only non-metadate element of an "li".             -->
<xsl:template match="cd" mode="environment-name">
    <xsl:choose>
        <xsl:when test="parent::li">
            <xsl:text>codedisplayleft</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>codedisplay</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- "pre" is analogous to the HTML tag of the same name -->
<!-- The "interior" templates decide between two styles  -->
<!--   (a) clean up raw text, just like for Sage code    -->
<!--   (b) interpret cline as line-by-line structure     -->
<!-- (See templates in xsl/pretext-common.xsl file)     -->
<!-- Then wrap in a  verbatim  environment               -->
<xsl:template match="pre">
    <xsl:text>\begin{preformatted}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="interior"/>
    <xsl:text>\end{preformatted}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="email">
    <xsl:text>\href{mailto:</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>}{\nolinkurl{</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>}}</xsl:text>
</xsl:template>


<!-- ################## -->
<!-- Special Characters -->
<!-- ################## -->

<!-- Note: characters given by argument-less macros    -->
<!-- should finish with an empty group ({}) so that    -->
<!-- they do not run-in to subsequent text.            -->
<!-- Alternatives:                                     -->
<!--   1.  Wrap macro in a group, eg "{\foo}".         -->
<!--       Disrupts any kerning that might occur.      -->
<!--   2.  Add a trailing space, eg "\foo ".           -->
<!--       Breaks when output is edited, lines broken. -->
<!--   3.  \xspace might work after words.             -->
<!--       Even if followed by punctuation (?).  Ugly. -->

<!-- Left Single Quote -->
<xsl:template name="lsq-character">
    <xsl:text>`</xsl:text>
</xsl:template>

<!-- Right Single Quote -->
<xsl:template name="rsq-character">
    <xsl:text>'</xsl:text>
</xsl:template>

<!-- Left (Double) Quote -->
<xsl:template name="lq-character">
    <xsl:text>``</xsl:text>
</xsl:template>

<!-- Right (Double) Quote -->
<xsl:template name="rq-character">
    <xsl:text>''</xsl:text>
</xsl:template>

<!-- Left Double Bracket -->
<xsl:template name="ldblbracket-character">
    <xsl:text>\textlbrackdbl{}</xsl:text>
</xsl:template>

<!-- Right Double Bracket -->
<xsl:template name="rdblbracket-character">
    <xsl:text>\textrbrackdbl{}</xsl:text>
</xsl:template>

<!-- Left Angle Bracket -->
<xsl:template name="langle-character">
    <xsl:text>\textlangle{}</xsl:text>
</xsl:template>

<!-- Right Angle Bracket -->
<xsl:template name="rangle-character">
    <xsl:text>\textrangle{}</xsl:text>
</xsl:template>

<!-- Vertical Bar -->
<!-- Bringhurst: a "pipe" is a broken bar -->
<!-- Exists as \textbrokenbar             -->
<xsl:template name="bar-character">
    <xsl:text>\textbar{}</xsl:text>
</xsl:template>

<!-- Other Miscellaneous Symbols, Constructions -->

<!-- Ellipsis (dots), for text, not math -->
<xsl:template name="ellipsis-character">
    <xsl:text>\textellipsis{}</xsl:text>
</xsl:template>

<!-- Midpoint -->
<!-- A centered dot used sometimes like a decorative dash -->
<!-- http://tex.stackexchange.com/questions/19180/which-dot-character-to-use-in-which-context -->
<xsl:template name="midpoint-character">
    <xsl:text>\textperiodcentered{}</xsl:text>
</xsl:template>

<!-- Swung Dash -->
<!-- A decorative dash, like a tilde, but bigger, and centered -->
<!-- http://andrewmccarthy.ie/2014/11/06/swung-dash-in-latex/  -->
<xsl:template name="swungdash-character">
    <xsl:text>\swungdash{}</xsl:text>
</xsl:template>
<!-- Protect the version of the macro appearing in titles -->
<!-- This is an override of the base *template*           -->
<xsl:template match="title//swungdash|shortitle//swungdash">
    <xsl:text>\protect</xsl:text>
    <xsl:call-template name="swungdash-character"/>
</xsl:template>

<!-- Per Mille -->
<!-- Or, per thousand, like a percent sign -->
<xsl:template name="permille-character">
    <xsl:text>\textperthousand{}</xsl:text>
</xsl:template>

<!-- Pilcrow -->
<!-- Often used to mark the start of a paragraph -->
<xsl:template name="pilcrow-character">
    <xsl:text>\textpilcrow{}</xsl:text>
</xsl:template>

<!-- Section Mark -->
<!-- The stylized double-S to indicate section numbers -->
<xsl:template name="section-mark-character">
    <xsl:text>\textsection{}</xsl:text>
</xsl:template>

<!-- Minus -->
<!-- A hyphen/dash for use in text as subtraction or negation-->
<xsl:template name="minus-character">
    <xsl:text>\textminus{}</xsl:text>
</xsl:template>

<!-- Times -->
<!-- A "multiplication sign" symbol for use in text -->
<xsl:template name="times-character">
    <xsl:text>\texttimes{}</xsl:text>
</xsl:template>

<!-- Solidus -->
<!-- Fraction bar, not as steep as a forward slash -->
<!-- This should not allow a linebreak, not tested -->
<xsl:template name="solidus-character">
    <xsl:text>\textfractionsolidus{}</xsl:text>
</xsl:template>

<!-- Obelus -->
<!-- A "division" symbol for use in text -->
<xsl:template name="obelus-character">
    <xsl:text>\textdiv{}</xsl:text>
</xsl:template>

<!-- Plus/Minus -->
<!-- The combined symbol -->
<xsl:template name="plusminus-character">
    <xsl:text>\textpm{}</xsl:text>
</xsl:template>

<!-- All Latin abbreviations are defined in -common    -->
<!-- since they are largely very simple.  But we       -->
<!-- implement the final period with a named template, -->
<!-- so we can get better behavior from LaTeX, mostly  -->
<!-- avoiding confusion with the end of a sentence.    -->

<!-- \@ following a period makes it an abbreviation, not the end of          -->
<!-- a sentence. So use it for abbreviations which will not end a sentence   -->
<!-- Best: \makeatletter\newcommand\etc{etc\@ifnextchar.{}{.\@}}\makeatother -->
<!-- http://latex-alive.tumblr.com/post/827168808/                           -->
<!-- correct-punctuation-spaces                                              -->
<!-- https://tex.stackexchange.com/questions/22561/                          -->
<!-- what-is-the-proper-use-of-i-e-backslash-at                              -->

<xsl:template name="abbreviation-period">
    <xsl:text>.\@</xsl:text>
</xsl:template>

<!-- Copyright symbol -->
<!-- http://tex.stackexchange.com/questions/1676/             -->
<!-- how-to-get-good-looking-copyright-and-registered-symbols -->
<xsl:template name="copyright-character">
    <xsl:text>\textcopyright{}</xsl:text>
</xsl:template>

<!-- Phonomark symbol -->
<xsl:template name="phonomark-character">
    <xsl:text>\textcircledP{}</xsl:text>
</xsl:template>

<!-- Copyleft symbol -->
<xsl:template name="copyleft-character">
    <xsl:text>\textcopyleft{}</xsl:text>
</xsl:template>

<!-- Registered symbol -->
<xsl:template name="registered-character">
    <xsl:text>\textregistered{}</xsl:text>
</xsl:template>

<!-- Trademark symbol -->
<xsl:template name="trademark-character">
    <xsl:text>\texttrademark{}</xsl:text>
</xsl:template>

<!-- Servicemark symbol -->
<xsl:template name="servicemark-character">
    <xsl:text>\textservicemark{}</xsl:text>
</xsl:template>

<!-- Degree -->
<xsl:template name="degree-character">
    <xsl:text>\textdegree{}</xsl:text>
</xsl:template>

<!-- Prime -->
<!-- A construction such as  \(^{\prime}\)  looks much better,     -->
<!-- but will require a lot of extra care in the "text-processing" -->
<!-- template since all this math-mode will need to be protected   -->
<!-- at the outset.  Bringhurst opines that many text fonts lack   -->
<!-- a prime and/or double-prime glyph, and LaTeX does not seem    -->
<!-- to have any good way to realize them without using math-mode. -->
<xsl:template name="prime-character">
    <xsl:text>\textquotesingle{}</xsl:text>
</xsl:template>

<!-- Double Prime -->
<xsl:template name="dblprime-character">
    <xsl:text>\textquotesingle\textquotesingle{}</xsl:text>
</xsl:template>

<!-- Characters for Tagging Equations -->

<xsl:template name="tag-star">
    <xsl:text>\textasteriskcentered</xsl:text>
</xsl:template>

<xsl:template name="tag-dagger">
    <xsl:text>\textdagger</xsl:text>
</xsl:template>

<xsl:template name="tag-daggerdbl">
    <xsl:text>\textdaggerdbl</xsl:text>
</xsl:template>

<xsl:template name="tag-hash">
    <xsl:text>\#</xsl:text>
</xsl:template>

<!-- AMS symbol designed for both text and math modes -->
<xsl:template name="tag-maltese">
    <xsl:text>\maltese</xsl:text>
</xsl:template>

<!-- Fill-in blank -->
<!-- \fillintext{} defined in preamble as semantic macro   -->
<!-- Argument is intended number of characters             -->
<xsl:template match="fillin[not(parent::m or parent::me or parent::men or parent::mrow)]">
    <xsl:variable name="characters">
        <xsl:choose>
            <xsl:when test="@characters">
                <xsl:value-of select="@characters" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>10</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>\fillintext{</xsl:text>
    <xsl:value-of select="$characters" />
    <xsl:text>}</xsl:text>
    <xsl:if test="@rows or @cols">
        <xsl:apply-templates select="." mode="fillin-array"/>
    </xsl:if>
</xsl:template>

<!-- Implication Symbols -->
<!-- TODO: better names! -->
<xsl:template match="imply">
    <xsl:text>$\Rightarrow$</xsl:text>
</xsl:template>
<xsl:template match="implyreverse">
    <xsl:text>$\Leftarrow$</xsl:text>
</xsl:template>

<!-- TeX, LaTeX via macros -->
<!-- PreTeXt, XeLaTeX, XeTeX are in -common -->
<xsl:template match="latex">
    <xsl:text>\LaTeX{}</xsl:text>
</xsl:template>
<xsl:template match="tex">
    <xsl:text>\TeX{}</xsl:text>
</xsl:template>

<!-- Foreign words/idioms -->
<xsl:template match="foreign">
    <xsl:apply-templates select="." mode="begin-language" />
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="end-language" />
</xsl:template>

<!-- Single and Double Quote Groupings -->
<!-- LaTeX is a bit brain-dead when a single quote        -->
<!-- is up tight against a double quote, or vice-versa,   -->
<!-- as the three consecutive single-quote characters are -->
<!-- ambiguous.  So we protect single quotes anytime it   -->
<!-- could be dangerous, even if precedence might do the  -->
<!-- right thing.  Double quotes are unmolested since     -->
<!-- they will work fine even in consecutive runs         -->
<!-- We have to override the RTF routines here.           -->

<xsl:template match="q">
    <xsl:text>``</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>''</xsl:text>
</xsl:template>

<!-- We look left (up the tree) and right   -->
<!-- (down the tree) for adjacent groupings -->
<xsl:template match="sq">
    <xsl:choose>
        <!-- left quote, possibly protected in a group -->
        <xsl:when test="(parent::q or parent::sq) and not(preceding-sibling::*) and not(preceding-sibling::text())">
            <xsl:text>{`}</xsl:text>
        </xsl:when>
        <xsl:when test="(*|text())[1][self::q or self::sq]">
            <xsl:text>{`}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>`</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- content -->
    <xsl:apply-templates/>
    <!-- right quote, possibly protected in a group -->
    <xsl:choose>
        <xsl:when test="(parent::q or parent::sq) and not(following-sibling::*) and not(following-sibling::text())">
            <xsl:text>{'}</xsl:text>
        </xsl:when>
        <xsl:when test="(*|text())[last()][self::q or self::sq]">
            <xsl:text>{'}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>'</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ##### -->
<!-- Icons -->
<!-- ##### -->

<xsl:template match="icon">
    <!-- the name attribute of the "icon" in text as a string -->
    <xsl:variable name="icon-name">
        <xsl:value-of select="@name"/>
    </xsl:variable>

    <xsl:variable name="fa-name">
        <!-- for-each is just one node, but sets context for key() -->
        <xsl:for-each select="$icon-table">
            <xsl:value-of select="key('icon-key', $icon-name)/@font-awesome"/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:text>\fa</xsl:text>
    <xsl:call-template name="camel-case-font-name">
        <xsl:with-param name="text" select="$fa-name"/>
    </xsl:call-template>
    <xsl:text>{}</xsl:text>
</xsl:template>

<xsl:template name="camel-case-font-name">
    <xsl:param name="text"/>
    <xsl:choose>
        <xsl:when test="not(contains($text, '-'))">
            <xsl:value-of select="translate(substring($text, 1, 1), &LOWERCASE;, &UPPERCASE;)"/>
            <xsl:value-of select="substring($text, 2)"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="first-part">
                <xsl:value-of select="substring-before($text, '-')"/>
            </xsl:variable>
            <xsl:value-of select="translate(substring($first-part, 1, 1), &LOWERCASE;, &UPPERCASE;)"/>
            <xsl:value-of select="substring($first-part, 2)"/>
            <xsl:call-template name="camel-case-font-name">
                <xsl:with-param name="text" select="substring-after($text, '-')"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ############## -->
<!-- Keyboard Input -->
<!-- ############## -->

<xsl:template match="kbd[not(@name)]">
    <xsl:text>\kbd{</xsl:text>
        <xsl:call-template name="escape-text-to-latex">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="kbd[@name]">
    <!-- the name attribute of the "kbd" in text as a string -->
    <xsl:variable name="kbdkey-name">
        <xsl:value-of select="@name"/>
    </xsl:variable>

    <xsl:text>\kbd{</xsl:text>
        <!-- for-each is just one node, but sets context for key() -->
        <xsl:for-each select="$kbdkey-table">
            <xsl:value-of select="key('kbdkey-key', $kbdkey-name)/@latex" />
        </xsl:for-each>
    <xsl:text>}</xsl:text>
</xsl:template>


<!-- ################ -->
<!-- Biological Names -->
<!-- ################ -->

<!-- See a potentially cleaner template in the braille conversion -->

<xsl:template match="taxon[not(genus) and not(species)]">
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="taxon[genus or species]">
    <xsl:if test="genus">
        <xsl:text>\textit{</xsl:text>
        <xsl:apply-templates select="genus"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:if test="genus and species">
        <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:if test="species">
        <xsl:text>\textit{</xsl:text>
        <xsl:apply-templates select="species"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>


<!-- Titles of Publications -->
<!-- 2018-02-05: Deprecate "booktitle" in favor of       -->
<!-- "pubtitle".  Will still maintain all for a while.   -->
<!-- CMOS:  When quoted in text or listed in a           -->
<!-- bibliography, titles of books, journals, plays,     -->
<!-- and other freestanding works are italicized; titles -->
<!-- of articles, chapters, and other shorter works      -->
<!-- are set in roman and enclosed in quotation marks.   -->
<!-- \pubtitle is a semantic macro defined only if       -->
<!-- "pubtitle" or "booktitle" is employed.  Adjust if   -->
<!-- deprecation is removed.                             -->
<xsl:template match="pubtitle|booktitle">
    <xsl:text>\pubtitle{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="articletitle">
    <xsl:call-template name="lq-character"/>
    <xsl:apply-templates/>
    <xsl:call-template name="rq-character"/>
</xsl:template>

<!-- ################-->
<!-- Other Characters -->
<!-- ################ -->

<!-- These are specific instances of abstract templates        -->
<!-- See the similar section of  pretext-common.xsl  for more -->

<!-- TODO: Perhaps use LaTeX double and triple hyphen variants of  -->
<!-- en-dash and em-dash under some option for human-variant LaTeX -->

<xsl:template name="nbsp-character">
    <xsl:text>~</xsl:text>
</xsl:template>

<xsl:template name="ndash-character">
    <xsl:text>\textendash{}</xsl:text>
</xsl:template>

<xsl:template name="mdash-character">
    <xsl:text>\textemdash{}</xsl:text>
</xsl:template>

<!-- The abstract template for "mdash" consults a publisher option -->
<!-- for thin space, or no space, surrounding an em-dash.  So the  -->
<!-- "thin-space-character" is needed for that purpose, and does   -->
<!-- not have an associated empty PTX element.                     -->

<xsl:template name="thin-space-character">
    <xsl:text>\,</xsl:text>
</xsl:template>

<!-- Sage Cells -->

<!-- An abstract named template accepts input text and               -->
<!-- output text, then wraps it for print, including output          -->
<!-- But we do not write an environment if there isn't any content   -->
<!-- So conceivably, this template can do nothing (ie an empty cell) -->
<!-- As a named template, the context is a calling sage element,     -->
<!-- this could be reworked and many of the parameters inferred      -->
<xsl:template match="sage" mode="sage-active-markup">
    <xsl:param name="in" />
    <xsl:param name="out" />

    <xsl:if test="$in!=''">
        <xsl:text>\begin{sageinput}&#xa;</xsl:text>
        <xsl:value-of select="$in" />
        <xsl:text>\end{sageinput}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$out!=''">
        <xsl:text>\begin{sageoutput}&#xa;</xsl:text>
        <xsl:value-of select="$out" />
        <xsl:text>\end{sageoutput}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- An abstract named template accepts input text -->
<!-- and wraps it, untouchable by default in print -->
<xsl:template name="sage-display-markup">
    <xsl:param name="in" />
    <xsl:if test="$in!=''">
        <xsl:text>\begin{sageinput}&#xa;</xsl:text>
        <xsl:value-of select="$in" />
        <xsl:text>\end{sageinput}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Type: "practice"; not much point to show to a print reader  -->
<!-- This overrides the default, which is a small annotated cell -->
<xsl:template match="sage[@type='practice']" />

<!-- ##################### -->
<!-- Programs and Consoles -->
<!-- ##################### -->

<!-- Program fragment, inline                                  -->
<!-- Similar to a "c" element, but will attempt to syntax      -->
<!-- highlight language in the same way as "program"           -->
<xsl:template match="pf">
    <xsl:variable name="language">
        <xsl:apply-templates select="." mode="listings-language" />
    </xsl:variable>
    <xsl:if test="$language = ''">
        <xsl:message>PTX:WARNING: pf element without a language. Styling will be unpredictable.</xsl:message>
    </xsl:if>
    <!-- Need a single delimiter char not present in body -->
    <xsl:variable name="delimiter">
        <xsl:call-template name="find-unused-character">
            <xsl:with-param name="string" select="."/>
            <!-- Try a few ascii symbols before iterating through alphanumerics -->
            <xsl:with-param name="charset" select="concat('`~^|#',&SIMPLECHAR;)"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:text>\programfragment{</xsl:text>
    <xsl:value-of select="$language"/>
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="$delimiter"/>
    <xsl:call-template name="escape-latex-special-chars">
        <xsl:with-param name="text" select="." />
    </xsl:call-template>
        <!-- <xsl:value-of select="." /> -->
    <xsl:value-of select="$delimiter"/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Both "program" and "console" are implemented as tcolorbox -->
<!-- "tcblisting", based on the LaTeX "lstlistings" package.   -->
<!-- As such they are tcolorboxes, amenable to manipulation.   -->
<!-- When placed in a "sidebyside" they will word-wrap to fit  -->
<!-- within the constraints imposed by the layout control of   -->
<!-- the "sidebyside".  When naked, or in a "listing" element, -->
<!-- they carry basic layout information, and as a tcolorbox   -->
<!-- we can constrain them.  There is a commonality in the     -->
<!-- approach here, but they are distinct.                     -->

<!-- Embeddings first -->

<xsl:template match="program[not(ancestor::sidebyside)]">
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters" />
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />

    <xsl:apply-templates select="." mode="program-inclusion">
        <xsl:with-param name="left-margin" select="$layout/left-margin div 100"/>
        <xsl:with-param name="width" select="$layout/width div 100"/>
        <xsl:with-param name="right-margin" select="$layout/right-margin div 100"/>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="program[ancestor::sidebyside]">
    <xsl:apply-templates select="." mode="program-inclusion">
        <!-- no margins, "full" width, constrained in tcbraster -->
        <xsl:with-param name="left-margin" select="0"/>
        <xsl:with-param name="width" select="1"/>
        <xsl:with-param name="right-margin" select="0"/>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="program" mode="program-inclusion">
    <!-- parameters are real numbers (not percentages) -->
    <xsl:param name="left-margin"/>
    <xsl:param name="width"/>
    <xsl:param name="right-margin"/>

    <xsl:variable name="language">
        <xsl:apply-templates select="." mode="listings-language" />
    </xsl:variable>
    <xsl:variable name="b-has-language" select="not($language = '')" />
    <!-- a "program" element may be empty in a coding       -->
    <!-- exercise, and just used to indicate an interactive -->
    <!-- area supporting some language                      -->
    <xsl:variable name="b-has-code" select="not(normalize-space(code) = '') or preamble[@visible = 'yes'] or postamble[@visible = 'yes']"/>
    <xsl:if test="$b-has-code">
          <!-- build up full program text so we can apply sanitize-text to entire blob -->
          <!-- and thus allow relative indentation for preamble/code/postamble         -->
          <xsl:variable name="program-text">
              <xsl:if test="preamble[not(@visible = 'no')]">
                  <xsl:call-template name="substring-before-last">
                      <xsl:with-param name="input" select="preamble" />
                      <xsl:with-param name="substr" select="'&#xA;'" />
                  </xsl:call-template>
              </xsl:if>
              <xsl:call-template name="substring-before-last">
                  <xsl:with-param name="input" select="code" />
                  <xsl:with-param name="substr" select="'&#xA;'" />
              </xsl:call-template>
              <xsl:text>&#xA;</xsl:text>
              <xsl:if test="postamble[not(@visible = 'no')]">
                  <xsl:value-of select="substring-after(postamble,'&#xA;')" />
              </xsl:if>
        </xsl:variable>
        <!-- Style choices for numbering lines filter though into different    -->
        <!-- "tcblisting" environments.  We set the environment in a variable, -->
        <!-- so the begin/end are consistent.                                  -->
        <xsl:variable name="program-env">
            <xsl:choose>
                <xsl:when test="@line-numbers = 'yes'">
                    <xsl:text>programnumbered</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>program</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:text>\begin{</xsl:text>
        <xsl:value-of select="$program-env"/>
        <xsl:text>}</xsl:text>
        <xsl:text>{</xsl:text>
        <xsl:choose>
            <xsl:when test="$b-has-language">
                <xsl:value-of select="$language" />
            </xsl:when>
            <!-- null language defined in preamble -->
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>}</xsl:text>
        <xsl:text>{</xsl:text>
        <xsl:value-of select="$left-margin"/>
        <xsl:text>}</xsl:text>
        <xsl:text>{</xsl:text>
        <xsl:value-of select="$width"/>
        <xsl:text>}</xsl:text>
        <xsl:text>{</xsl:text>
        <xsl:value-of select="$right-margin"/>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="$program-text" />
        </xsl:call-template>
        <!-- Concluding line is still being parsed as verbatim text, -->
        <!-- so *any* extra characters will produce a LaTeX warning  -->
        <!-- starting with "Character dropped after \end{program}"   -->
        <!-- So...do not put a % (or anything else extra) here       -->
        <xsl:text>\end{</xsl:text>
        <xsl:value-of select="$program-env"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- Consoles, specialized code listings -->
<!-- An interactive command-line session with a prompt, input and output -->

<xsl:template match="console[not(ancestor::sidebyside)]">
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters" />
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
    <xsl:apply-templates select="." mode="console-inclusion">
        <xsl:with-param name="left-margin" select="$layout/left-margin div 100"/>
        <xsl:with-param name="width" select="$layout/width div 100"/>
        <xsl:with-param name="right-margin" select="$layout/right-margin div 100"/>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="console[ancestor::sidebyside]">
    <xsl:apply-templates select="." mode="console-inclusion">
        <!-- no margins, "full" width, constrained in tcbraster -->
        <xsl:with-param name="left-margin" select="0"/>
        <xsl:with-param name="width" select="1"/>
        <xsl:with-param name="right-margin" select="0"/>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="console" mode="console-inclusion">
    <!-- parameters are real numbers (not percentages) -->
    <xsl:param name="left-margin"/>
    <xsl:param name="width"/>
    <xsl:param name="right-margin"/>

    <!-- ignore prompt, and pick it up in trailing input  -->
    <xsl:text>\begin{console}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$left-margin"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$width"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$right-margin"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="input|output" />
    <!-- Concluding line is still being parsed as verbatim text, -->
    <!-- so *any* extra characters will produce a LaTeX warning  -->
    <!-- starting with "Character dropped after \end{console}"   -->
    <!-- So...do not put a % (or anything else extra) here       -->
    <xsl:text>\end{console}&#xa;</xsl:text>
</xsl:template>

<!-- match immediately preceding, only if a prompt:                   -->
<!-- https://www.oxygenxml.com/archives/xsl-list/199910/msg00541.html -->
<xsl:template match="console/input">
    <xsl:variable name="prompt">
        <xsl:apply-templates select="." mode="determine-console-prompt"/>
    </xsl:variable>
    <xsl:variable name="continuation">
        <xsl:apply-templates select="." mode="determine-console-continuation"/>
    </xsl:variable>
    <!-- We first sanitize left-margin, etc -->
    <xsl:variable name="sanitized-text">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
    </xsl:variable>
    <!-- Special case where input is empty/whitespace, in which -->
    <!-- case the for loop finds no tokens -->
    <xsl:if test="not(normalize-space($sanitized-text))">
        <xsl:call-template name="wrap-console-input-line">
            <xsl:with-param name="text" select="normalize-space($sanitized-text)" />
            <xsl:with-param name="prefix" select="$prompt" />
        </xsl:call-template>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <!-- Other cases are caught by the loop -->
    <xsl:for-each select="str:tokenize($sanitized-text, '&#xa;')">
        <xsl:choose>
            <xsl:when test="preceding-sibling::token">
                <xsl:call-template name="wrap-console-input-line">
                    <xsl:with-param name="text" select="." />
                    <xsl:with-param name="prefix" select="$continuation" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="wrap-console-input-line">
                    <xsl:with-param name="text" select="." />
                    <xsl:with-param name="prefix" select="$prompt" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>
</xsl:template>

<!-- Input helper to prepare one line of console input -->
<!-- Including any needed "prefix" prompt/continuation -->
<xsl:template name="wrap-console-input-line">
    <xsl:param name="text" />
    <xsl:param name="prefix" />
    <!-- Prefix first, assumes does not exceed one line -->
    <xsl:if test="not($prefix = '')">
        <xsl:call-template name="escape-console-prefix-output">
            <xsl:with-param name="text" select="$prefix" />
        </xsl:call-template>
    </xsl:if>
    <!-- Then employ \consoleinput macro on the line -->
    <xsl:text>(*\consoleinput{</xsl:text>
        <xsl:call-template name="escape-console-input-to-latex">
            <xsl:with-param name="text" select="$text" />
        </xsl:call-template>
    <xsl:text>}*)</xsl:text>
</xsl:template>

<!-- Output code gets massaged to remove a left margin, -->
<!-- leading blank lines, etc., then wrap as above-->
<xsl:template match="console/output">
    <xsl:call-template name="wrap-console-output">
        <xsl:with-param name="text">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text">
                    <xsl:call-template name="escape-console-prefix-output">
                        <xsl:with-param name="text"  select="."/>
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- TODO: consolidate/generalize next two templates -->

<!-- Line-by-line  -->
<xsl:template name="wrap-console-output">
    <xsl:param name="text" />
    <xsl:choose>
        <xsl:when test="$text=''" />
        <xsl:otherwise>
            <xsl:value-of select="substring-before($text, '&#xa;')" />
            <xsl:text>&#xa;</xsl:text>
            <xsl:call-template name="wrap-console-output">
                <xsl:with-param name="text" select="substring-after($text, '&#xa;')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############ -->
<!-- Interactives -->
<!-- ############ -->

<!-- Geogebra -->
<xsl:template match="interactive[@geogebra]" mode="info-text">
    <xsl:text>Geogebra: \href{https://www.geogebra.org/m/</xsl:text>
    <xsl:value-of select="@geogebra" />
    <xsl:text>}{\mono{www.geogebra.org/m/</xsl:text>
    <xsl:value-of select="@geogebra" />
    <xsl:text>}}</xsl:text>
</xsl:template>

<!-- Desmos -->
<xsl:template match="interactive[@desmos]" mode="info-text">
    <xsl:text>Desmos: \href{https://www.desmos.com/calculator/</xsl:text>
    <xsl:value-of select="@desmos" />
    <xsl:text>}{\mono{www.desmos.com/calculator/</xsl:text>
    <xsl:value-of select="@desmos" />
    <xsl:text>}}&#xa;</xsl:text>
</xsl:template>

<!-- CalcPlot3D -->
<xsl:template match="interactive[@platform='calcplot3d']" mode="info-text">
    <!-- code/url too much to include! -->
    <xsl:text>CalcPlot3D: \href{https://c3d.libretexts.org/CalcPlot3D/index.html}</xsl:text>
    <xsl:text>{\mono{c3d.libretexts.org/CalcPlot3D/index.html}}&#xa;</xsl:text>
</xsl:template>

<!-- JSXGraph -->
<xsl:template match="jsxgraph">
    <xsl:text>\par\smallskip\centerline{A deprecated JSXGraph interactive demonstration goes here in interactive output.}\smallskip&#xa;</xsl:text>
</xsl:template>

<!-- We sometimes need to explicitly leave LaTeX's vertical mode.     -->
<!-- But we try to be judicious about using this.  Overuse makes      -->
<!-- for bad spacing.                                                 -->
<!-- Explanation:  http://tex.stackexchange.com/questions/22852/      -->
<!-- function-and-usage-of-leavevmode                                 -->
<!--   "Use \leavevmode for all macros which could be used at         -->
<!--   the begin of the paragraph and add horizontal boxes            -->
<!--   by themselves (e.g. in form of text)."                         -->
<!-- Potential alternate solution: write a leading "empty" \mbox{}    -->
<!-- http://tex.stackexchange.com/questions/171220/                   -->
<!-- include-non-floating-graphic-in-a-theorem-environment            -->
<xsl:template match="sidebyside" mode="leave-vertical-mode">
    <xsl:if test="not(preceding-sibling::*[not(&SUBDIVISION-METADATA-FILTER;)]) and parent::paragraphs">
        <xsl:text>\leavevmode\par\noindent%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="figure|table|list|listing" mode="environment-name">
    <xsl:variable name="fig-placement">
        <xsl:apply-templates select="." mode="figure-placement"/>
    </xsl:variable>
    <!-- prefix first -->
    <xsl:choose>
        <xsl:when test="$fig-placement = 'subnumber'">
            <xsl:text>sub</xsl:text>
        </xsl:when>
        <xsl:when test="$fig-placement = 'panel'">
            <xsl:text>panel</xsl:text>
        </xsl:when>
        <xsl:when test="$fig-placement = 'block'"/>
        <xsl:otherwise>
            <xsl:message>PTX:BUG: figure placement not recognized, plase report me</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <!-- always element name and suffix -->
    <xsl:value-of select="local-name(.)"/>
    <!-- too many LaTeX names to clash with -->
    <xsl:text>ptx</xsl:text>
</xsl:template>

<!-- Figures, Listings -->
<!-- 0: enviroment name may be prefixed with "sub" -->
<!-- 1: caption text                               -->
<!-- 2: standard identifier for cross-references   -->
<!-- 3: empty, or a hard-coded number from -common -->
<xsl:template match="figure">
    <xsl:if test="@landscape and $b-latex-print">
      <xsl:text>\begin{sidewaysfigure}%&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="." mode="environment-name"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="." mode="caption-full"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id"/>
    <xsl:text>}{</xsl:text>
    <xsl:if test="$b-latex-hardcode-numbers">
        <xsl:apply-templates select="." mode="number"/>
    </xsl:if>
    <xsl:text>}%&#xa;</xsl:text>
    <!-- images have margins and widths, so centering not needed -->
    <!-- likewise, sidebyside and tabular will center themselves -->
    <!-- Eventually everything in a figure should control itself -->
    <!-- TODO: need to investigate more (poem? etc)              -->
    <xsl:if test="self::figure and not(image or sidebyside or tabular)">
        <xsl:text>\centering&#xa;</xsl:text>
    </xsl:if>
    <!-- TODO: process meta-data, then restrict contents -->
    <!-- multiple, program|console                       -->
    <xsl:apply-templates select="*"/>
    <!-- reserve space for the caption -->
    <xsl:text>\tcblower&#xa;</xsl:text>
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="." mode="environment-name"/>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:if test="@landscape and $b-latex-print">
      <xsl:text>\end{sidewaysfigure}%&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- Tables, (Named) Lists -->
<!-- 0: enviroment name may be prefixed with "sub"  -->
<!-- 1: title text, bolded here, not in environment -->
<!-- 2: standard identifier for cross-references    -->
<!-- 3: empty, or a hard-coded number from -common  -->
<xsl:template match="table|list|listing">
    <xsl:if test="@landscape and $b-latex-print">
      <xsl:text>\begin{sidewaystable}%&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="." mode="environment-name"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>}{</xsl:text>
    <xsl:text>\textbf{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}</xsl:text>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id"/>
    <xsl:text>}{</xsl:text>
    <xsl:if test="$b-latex-hardcode-numbers">
        <xsl:apply-templates select="." mode="number"/>
    </xsl:if>
    <xsl:text>}%&#xa;</xsl:text>
    <!-- A "list" has an introduction/conclusion, with a       -->
    <!-- list of some type in-between, and these will all      -->
    <!-- automatically word-wrap to fill the available width.  -->
    <!-- TODO: process meta-data, then restrict contents -->
    <!-- tabular, introduction|list|conclusion           -->
    <xsl:apply-templates select="*"/>
    <xsl:variable name="fig-placement">
        <xsl:apply-templates select="." mode="figure-placement"/>
    </xsl:variable>
    <!-- title goes in lower part when in a sidebyside -->
    <xsl:if test="($fig-placement = 'subnumber') or ($fig-placement = 'panel')">
        <xsl:text>\tcblower&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="." mode="environment-name"/>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:if test="@landscape and $b-latex-print">
        <xsl:text>\end{sidewaystable}%&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>


<!-- ################## -->
<!-- SideBySide Layouts -->
<!-- ################## -->

<!-- See xsl/pretext-common.xsl for descriptions of the  -->
<!-- four modal templates which must be implemented here  -->
<!-- The main templates for "sidebyside" and "sbsgroup"   -->
<!-- are in xsl/pretext-common.xsl, as befits containers -->

<!-- Note: Various end-of-line "%" are necessary to keep  -->
<!-- headers, panels, and captions together as one unit   -->
<!-- without a page -break, via the LaTeX                 -->
<!-- \nopagebreak=\nopagebreak[4] command                 -->

<xsl:template match="*" mode="panel-panel">
    <xsl:param name="width" />
    <xsl:param name="valign" />

    <xsl:text>\begin{sbspanel}{</xsl:text>
    <xsl:value-of select="substring-before($width,'%') div 100" />
    <xsl:text>}</xsl:text>
    <!-- 'top' is the sbspanel environment default -->
    <!-- could generate brackets of optional       -->
    <!-- argument outside of the choose            -->
    <xsl:choose>
        <xsl:when test="$valign = 'top'" />
        <xsl:when test="$valign = 'middle'">
            <xsl:text>[center]</xsl:text>
        </xsl:when>
        <xsl:when test="$valign = 'bottom'">
            <xsl:text>[bottom]</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>%&#xa;</xsl:text>
    <!-- Realize each panel's object -->
    <xsl:apply-templates select="."/>
    <xsl:text>\end{sbspanel}%&#xa;</xsl:text>
</xsl:template>


<!-- We take in all three rows of a LaTeX    -->
<!-- table and package them up appropriately -->
<xsl:template match="sidebyside" mode="compose-panels">
    <xsl:param name="layout" />
    <xsl:param name="panels" />

    <xsl:variable name="number-panels" select="$layout/number-panels" />
    <xsl:variable name="left-margin" select="$layout/left-margin" />
    <xsl:variable name="right-margin" select="$layout/right-margin" />
    <xsl:variable name="space-width" select="$layout/space-width" />

    <!-- TODO: Make "sidebyside" a 3-argument environment:          -->
    <!-- headers, panels, captions.  Then put "\nopagebreak"        -->
    <!-- into the definition, so it is "hidden" and not in the body -->

    <xsl:apply-templates select="." mode="leave-vertical-mode"/>
    <xsl:text>\begin{sidebyside}{</xsl:text>
    <xsl:value-of select="$number-panels" />
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="substring-before($left-margin, '%') div 100" />
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="substring-before($right-margin, '%') div 100" />
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="substring-before($space-width, '%') div 100" />
    <xsl:text>}%&#xa;</xsl:text>
    <!-- The main event -->
    <xsl:value-of select="$panels" />
    <xsl:text>\end{sidebyside}%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- First: images in full-width contexts                   -->
<!-- naked images go into a tcolorbox for layout control    -->
<!-- figure/image (not in a sidebyside) into same tcolorbox -->
<xsl:template match="image[not(ancestor::sidebyside)]">
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters" />
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
    <xsl:text>\begin{image}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$layout/left-margin div 100"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$layout/width div 100"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$layout/right-margin div 100"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="vertical-adjustment"/>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="image-inclusion" />
    <xsl:text>\end{image}%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="image" mode="vertical-adjustment">
    <xsl:choose>
        <!-- When the image is the first thing in an exercisegroup (tcbraster) exercise -->
        <!-- NB: ancestor::exercisegroup would catch too many cases                     -->
        <xsl:when test="parent::statement/parent::exercise/parent::exercisegroup or parent::exercise/parent::exercisegroup and not(preceding-sibling::*)">
            <xsl:text>-0.5\baselineskip</xsl:text>
        </xsl:when>
        <!-- When the image is the first thing in a list item, project-like, (not exercisegroup) exercise, or task -->
        <xsl:when test="(parent::li|parent::statement|parent::exercise|parent::task|parent::*[PROJECT-FILTER]) and not(preceding-sibling::*)">
            <xsl:text>-1.5\baselineskip</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Second: images already constrained by side-by-side panels -->
<xsl:template match="image[ancestor::sidebyside]">
    <!-- get a newline if inside a "stack" -->
    <xsl:if test="parent::stack and preceding-sibling::*">
        <xsl:text>\par&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\noindent</xsl:text>
    <xsl:apply-templates select="." mode="image-inclusion" />
</xsl:template>

<!-- Various versions of images have their width set to the         -->
<!-- prevailing available width.  This is \linewidth when:          -->
<!-- full text width is available, width is constrained (like in    -->
<!-- a list item), or width is constrained by a side-by-side panel. -->

<!-- With full source specified, default to PDF format -->
<xsl:template match="image[@source|@pi:generated]" mode="image-inclusion">
    <xsl:variable name="extension">
        <xsl:call-template name="file-extension">
            <xsl:with-param name="filename">
                <xsl:choose>
                    <xsl:when test="@pi:generated">
                        <xsl:value-of select="@pi:generated" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@source" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:text>\includegraphics[width=\linewidth</xsl:text>
    <xsl:if test="@rotate">
      <xsl:text>,angle=</xsl:text>
      <xsl:value-of select="@rotate"/>
      <xsl:text>,origin=c</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:choose>
        <xsl:when test="@pi:generated">
            <xsl:value-of select="$generated-directory"/>
            <xsl:value-of select="@pi:generated"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- empty when not using managed directories -->
            <xsl:value-of select="$external-directory"/>
            <xsl:value-of select="@source"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="$extension = ''">
        <xsl:text>.pdf</xsl:text>
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Asymptote graphics language  -->
<!-- PDF's produced by mbx script -->
<xsl:template match="image[asymptote]" mode="image-inclusion">
    <!-- need image filename in two different scenarios -->
    <xsl:variable name="image-file-name">
        <xsl:value-of select="$generated-directory"/>
        <xsl:if test="$b-managed-directories">
            <xsl:text>asymptote/</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="asymptote" mode="image-source-basename"/>
        <xsl:text>.pdf</xsl:text>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$b-asymptote-links">
        <xsl:variable name="image-html-url">
            <xsl:value-of select="$baseurl"/>
            <xsl:value-of select="$generated-directory"/>
            <xsl:if test="$b-managed-directories">
                <xsl:text>asymptote/</xsl:text>
            </xsl:if>
            <xsl:apply-templates select="asymptote" mode="image-source-basename"/>
            <xsl:text>.html</xsl:text>
        </xsl:variable>
        <xsl:text>\href{</xsl:text>
        <xsl:value-of select="$image-html-url"/>
        <xsl:text>}</xsl:text>
        <xsl:text>{\includegraphics[width=\linewidth]</xsl:text>
        <xsl:text>{</xsl:text>
        <xsl:value-of select="$image-file-name"/>
        <xsl:text>}</xsl:text>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>\includegraphics[width=\linewidth]</xsl:text>
        <xsl:text>{</xsl:text>
        <xsl:value-of select="$image-file-name"/>
        <xsl:text>}</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <!-- end line universally -->
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Sage graphics plots              -->
<!-- PDF's produced by pretext script -->
<!-- PDF for 2d, PNG for 3d           -->
<xsl:template match="image[sageplot]" mode="image-inclusion">
    <xsl:text>\includegraphics[width=\linewidth]</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$generated-directory"/>
    <xsl:if test="$b-managed-directories">
        <xsl:text>sageplot/</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="sageplot" mode="image-source-basename"/>
    <xsl:choose>
        <xsl:when test="not(sageplot/@variant) or (sageplot/@variant = '2d')">
            <xsl:text>.pdf</xsl:text>
        </xsl:when>
        <xsl:when test="sageplot/@variant = '3d'">
            <xsl:text>.png</xsl:text>
        </xsl:when>
        <!-- attribute errors found out in generation? -->
        <xsl:otherwise/>
    </xsl:choose>
    <xsl:text>}%&#xa;</xsl:text>
</xsl:template>

<!-- PreFigure diagrams always produced as PDF for LaTeX -->
<xsl:template match="image[pf:prefigure]" mode="image-inclusion">
    <xsl:text>\includegraphics[width=\linewidth]</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$generated-directory"/>
    <xsl:if test="$b-managed-directories">
        <xsl:text>prefigure/</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="pf:prefigure" mode="image-source-basename"/>
    <xsl:text>.pdf</xsl:text>
    <xsl:text>}%&#xa;</xsl:text>
</xsl:template>

<!-- LaTeX Image Code (tikz, pgfplots, pstricks, etc) -->
<!-- Clean indentation, drop into LaTeX               -->
<!-- See "latex-image-preamble" for critical parts    -->
<!-- Side-By-Side scaling happens there, could be here -->
<!-- TODO: maybe these should be split into current v. legacy -->
<xsl:template match="image[latex-image]" mode="image-inclusion">
    <!-- tikz images go into a tcolorbox where \linewidth is reset. -->
    <!-- grouping reins in the scope of any local graphics settings -->
    <!-- we resize what tikz produces, to fill a containing box     -->
    <!-- changes to accomodate resizing to fit requested layouts -->
    <xsl:text>\resizebox{\linewidth}{!}{%&#xa;</xsl:text>
    <xsl:apply-templates select="latex-image"/>
    <xsl:text>}%&#xa;</xsl:text>
</xsl:template>

<!-- EXPERIMENTAL -->
<!-- We allow some mark-up inside the "latex-image" element, -->
<!-- which was formerly assumed to be purely text.  Then we  -->
<!-- sanitize it.                                            -->
<!-- NB: the only experimental aspect here is the use of a   -->
<!-- "label" element mixed in with text nodes of a           -->
<!-- "latex-image".  This was deprecated on 2024-07-29 and   -->
<!-- that suggests manual replacement.  We *could* move the  -->
<!-- templates supporting this to the "repair" phase of      -->
<!-- pretext-assembly.xsl  or just remove these templates.   -->

<!-- This template (and those it employs) are also used  -->
<!-- in "extract-latex-image.xsl" so check consequences  -->
<!-- there if this changes.                              -->
<xsl:template match="latex-image">
    <xsl:variable name="latex-code">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text">
                <!-- we need to copy text bits verbatim (value-of), -->
                <!-- versus applying templates to "label" elements  -->
                <!-- (could match on, e.g., latex-image/text() )    -->
                <xsl:for-each select="text()|label">
                    <xsl:choose>
                        <xsl:when test="self::text()">
                            <xsl:value-of select="."/>
                        </xsl:when>
                        <xsl:when test="self::label">
                            <xsl:apply-templates select="."/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <!-- All but a guaranteed trailing newline as last -->
    <!-- character (which comes from "sanitize-text")  -->
    <xsl:value-of select="substring($latex-code, 1, string-length($latex-code)-1)"/>
    <!-- A percent to control unwanted space, post-LaTeX  -->
    <!-- code, then newline as visual formatting          -->
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- This is producing TikZ code, so will not be effective in all poassible -->
<!-- "LaTeX image" scenarios.  Thus the experimental designation above.     -->
<xsl:template match="label">
    <xsl:text>\node [</xsl:text>
    <xsl:apply-templates select="@direction" mode="tikz-direction"/>
    <xsl:text>=</xsl:text>
    <!-- Always an offset, default is 4pt, about a "normal space" -->
    <xsl:apply-templates select="." mode="get-label-offset"/>
    <xsl:text>] at (</xsl:text>
    <xsl:value-of select="@location"/>
    <xsl:text>) {</xsl:text>
    <!-- process content as if structured -->
    <!-- like contents of a paragraph     -->
    <xsl:apply-templates/>
    <xsl:text>};</xsl:text>
</xsl:template>

<!-- We translate PreTeXt directions from an 8-wind compass rose into -->
<!-- TikZ shorthand for anchors.  TikZ places a node by placing the   -->
<!-- node's center onto a specific point.  Instead, you can specify   -->
<!-- a location around the perimeter of the node to be an "anchor"    -->
<!-- instead.  Choosing a "south" anchor would place the label        -->
<!-- *above* the point.                                               -->
<!--                                                                  -->
<!-- 1.  PreTeXt uses compass directions, which we can refine later   -->
<!-- into more (sub)directions.                                       -->
<!--                                                                  -->
<!-- 2.  TikZ shorthand (e.g. "below right") allow the specification  -->
<!-- of an offset (e.g. below right=20) which we should find useful   -->
<!-- internally, and perhaps useful as author markup later.           -->
<xsl:template match="@direction" mode="tikz-direction">
    <xsl:choose>
        <xsl:when test=". = 'north'">
            <xsl:text>above</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'northeast'">
            <xsl:text>above right</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'east'">
            <xsl:text>right</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'southeast'">
            <xsl:text>below right</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'south'">
            <xsl:text>below</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'southwest'">
            <xsl:text>below left</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'west'">
            <xsl:text>left</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'northwest'">
            <xsl:text>above left</xsl:text>
        </xsl:when>
        <!-- this will allow tikz to continue, but perhaps incorrectly -->
        <!-- schema should catch incorrect values                      -->
        <xsl:otherwise>
            <xsl:text>above</xsl:text>
            <xsl:message>PTX:ERROR:   a label @direction ("<xsl:value-of select="."/>") is not recognized, using "above" as a default</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- TikZ's "inner sep" functions like our offset but is a           -->
<!-- horizontal and vertical shift, while the TikZ offset with the   -->
<!-- anchor mechanism is a straight line distance.                   -->
<!-- Section 11.8 at                                                 -->
<!-- https://stuff.mit.edu/afs/athena/contrib/                       -->
<!-- tex-contrib/beamer/pgf-1.01/doc/generic/pgf/                    -->
<!-- version-for-tex4ht/en/pgfmanualse11.html                        -->
<!-- says:                                                           -->
<!-- "An additional (invisible) separation space of <dimension> will -->
<!-- be added inside the shape, between the text and the shape’s     -->
<!-- background path. The effect is as if you had added appropriate  -->
<!-- horizontal and vertical skips at the beginning and end of the   -->
<!-- text to make it a bit “larger.” The default inner sep is the    -->
<!-- size of a normal space."                                        -->
<!--                                                                 -->
<!-- We use a default of 4pt, and this template is employed for      -->
<!-- consistency, such as in the more elaborate template for tactile -->
<!-- versions, located  elsewhere.                                   -->
<xsl:template match="label" mode="get-label-offset">
    <xsl:choose>
        <xsl:when test="@offset">
            <xsl:value-of select="@offset"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>4pt</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- EXPERIMENTAL -->
<!-- use only for testing uses of QR codes          -->
<!-- this WILL change and/or disappear              -->
<!-- For LaTeX output only, place within an "image" -->
<!-- @size - a length LaTeX understands             -->
<!-- @href - realtive path or URL                   -->
<xsl:template match="image[qrcode-trial]">
    <xsl:apply-templates select="qrcode-trial" />
</xsl:template>

<xsl:template match="qrcode-trial">
    <xsl:text>{\hypersetup{urlcolor=black}</xsl:text>
    <xsl:text>\qrcode[height=</xsl:text>
    <xsl:value-of select="@size" />
    <xsl:text>]{</xsl:text>
        <xsl:value-of select="@href" />
    <xsl:text>}}%&#xa;</xsl:text>
</xsl:template>

<!-- ############## -->
<!-- Tabular Layout -->
<!-- ############## -->

<xsl:template match="tabular[not(ancestor::sidebyside)]">
    <xsl:choose>
        <!-- the "natural width" case, centered -->
        <xsl:when test="not(@margins) and not(@width)">
            <xsl:choose>
                <xsl:when test="parent::table">
                    <!-- center with no space more than "tableptx" provides -->
                    <xsl:text>\centering%&#xa;</xsl:text>
                    <xsl:apply-templates select="." mode="tabular-inclusion"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- center with some vertical separation -->
                    <xsl:text>\begin{center}%&#xa;</xsl:text>
                    <xsl:apply-templates select="." mode="tabular-inclusion"/>
                    <xsl:text>\end{center}%&#xa;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- an option for a long table here? -->
        <!-- Or does it go with "table"?      -->
        <xsl:otherwise>
            <xsl:variable name="rtf-layout">
                <xsl:apply-templates select="." mode="layout-parameters" />
            </xsl:variable>
            <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
            <xsl:text>\begin{tabularbox}</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="$layout/left-margin div 100"/>
            <xsl:text>}</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="$layout/width div 100"/>
            <xsl:text>}</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="$layout/right-margin div 100"/>
            <xsl:text>}%&#xa;</xsl:text>
            <!-- with layout control, scale down, but not up                      -->
            <!-- https://tex.stackexchange.com/questions/327887/                  -->
            <!-- resizing-or-scaling-table-only-if-it-is-larger-than-column-width -->
            <xsl:text>\resizebox{\ifdim\width > \linewidth\linewidth\else\width\fi}{!}{%&#xa;</xsl:text>
            <xsl:apply-templates select="." mode="tabular-inclusion"/>
            <xsl:text>}%&#xa;</xsl:text>
            <xsl:text>\end{tabularbox}%&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="tabular[ancestor::sidebyside]">
    <!-- with layout control (inside sidebyside), scale down, but not up  -->
    <!-- https://tex.stackexchange.com/questions/327887/                  -->
    <!-- resizing-or-scaling-table-only-if-it-is-larger-than-column-width -->
    <xsl:text>\noindent\resizebox{\ifdim\width > \linewidth\linewidth\else\width\fi}{!}{%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="tabular-inclusion"/>
    <xsl:text>}%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="tabular" mode="tabular-inclusion">
    <!-- Abort if tabular's cols have widths summing to over 100% -->
    <xsl:call-template name="cap-width-at-one-hundred-percent">
        <xsl:with-param name="nodeset" select="col/@width" />
    </xsl:call-template>
    <!-- Determine global, table-wide properties -->
    <!-- set defaults here if values not given   -->
    <xsl:variable name="table-top">
        <xsl:choose>
            <xsl:when test="@top">
                <xsl:value-of select="@top" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="table-left">
        <xsl:choose>
            <xsl:when test="@left">
                <xsl:value-of select="@left" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="table-bottom">
        <xsl:choose>
            <xsl:when test="@bottom">
                <xsl:value-of select="@bottom" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="table-right">
        <xsl:choose>
            <xsl:when test="@right">
                <xsl:value-of select="@right" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="table-halign">
        <xsl:choose>
            <xsl:when test="@halign">
                <xsl:value-of select="@halign" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>left</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="table-valign">
        <xsl:choose>
            <xsl:when test="@valign">
                <xsl:value-of select="@valign" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>middle</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- set environment based on breakability -->
    <xsl:variable name="tabular-environment">
        <xsl:choose>
            <xsl:when test="@break = 'yes'">
                <xsl:text>longtable</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>tabular</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- get a newline if inside a "stack" -->
    <xsl:if test="parent::stack and preceding-sibling::*">
        <xsl:text>\par&#xa;</xsl:text>
    </xsl:if>
    <!-- center within a sidebyside if by itself       -->
    <!-- \centering needs a closing \par within a      -->
    <!-- defensive group if it is to be effective      -->
    <!-- https://tex.stackexchange.com/questions/23650 -->
    <!-- Necessary for both sidebyside/tabular AND sidebyside/table/tabular -->
    <!-- Does latter get a double-nested centering?                         -->
    <!-- Maybe this goes away with tcolorbox?                               -->
    <!-- NB: paired conditional way below!                                  -->
    <xsl:if test="ancestor::sidebyside">
        <xsl:text>{\centering%&#xa;</xsl:text>
    </xsl:if>
    <!-- Build latex column specification                         -->
    <!--   vertical borders (left side, right side, three widths) -->
    <!--   horizontal alignment (left, center, right)             -->
    <xsl:text>{\tabularfont%&#xa;</xsl:text>
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="$tabular-environment"/>
    <xsl:text>}{</xsl:text>
    <!-- start with left vertical border -->
    <xsl:call-template name="vrule-specification">
        <xsl:with-param name="width" select="$table-left" />
    </xsl:call-template>
    <xsl:choose>
        <!-- Potential for individual column overrides    -->
        <!--   Deduce number of columns from col elements -->
        <!--   Employ individual column overrides,        -->
        <!--   or use global table-wide values            -->
        <!--   write alignment (mandatory)                -->
        <!--   follow with right border (optional)        -->
        <xsl:when test="col">
            <xsl:for-each select="col">
                <xsl:call-template name="halign-specification">
                    <xsl:with-param name="align">
                        <xsl:choose>
                            <xsl:when test="@halign">
                                <xsl:value-of select="@halign" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$table-halign" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                </xsl:call-template>
                <xsl:call-template name="vrule-specification">
                    <xsl:with-param name="width">
                        <xsl:choose>
                            <xsl:when test="@right">
                                <xsl:value-of select="@right" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$table-right" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:when>
        <!-- No col specifiaction                                  -->
        <!--   so default identically to global, table-wide values -->
        <!--   first row determines the  number of columns         -->
        <!--   write the alignment (mandatory)                     -->
        <!--   follow with right border (optional)                 -->
        <!-- TODO: error check each row for correct number of columns -->
        <xsl:otherwise>
            <xsl:variable name="ncols" select="count(row[1]/cell) + sum(row[1]/cell[@colspan]/@colspan) - count(row[1]/cell[@colspan])" />
            <xsl:call-template name="duplicate-string">
                <xsl:with-param name="count" select="$ncols" />
                <xsl:with-param name="text">
                    <xsl:call-template name="halign-specification">
                        <xsl:with-param name="align" select="$table-halign" />
                    </xsl:call-template>
                    <xsl:call-template name="vrule-specification">
                        <xsl:with-param name="width" select="$table-right" />
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}</xsl:text>
    <!-- column specification done -->
    <!-- top horizontal rule is specified after column specification -->
    <xsl:choose>
        <!-- A col element might indicate top border customizations   -->
        <!-- so we walk the cols to build a cline-style specification -->
        <!-- $clines accumulates the specification when complicated   -->
        <!-- For convenience, recursion passes along the $table-top   -->
        <xsl:when test="col/@top">
            <xsl:apply-templates select="col[1]" mode="column-cols">
                <xsl:with-param name="col-number" select="1" />
                <xsl:with-param name="clines" select="''" />
                <xsl:with-param name="table-top" select="$table-top"/>
                <xsl:with-param name="start-run" select="1" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- with no customization, we have one continuous rule (if at all) -->
        <!-- use global, table-wide value of top specification              -->
        <xsl:otherwise>
            <xsl:call-template name="hrule-specification">
                <xsl:with-param name="width" select="$table-top" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
    <!-- now ready to build rows -->
    <xsl:text>&#xa;</xsl:text>
    <!-- table-wide values are needed to reconstruct/determine overrides -->
    <!-- We *actively* enforce header rows being (a) initial, and        -->
    <!-- (b) contiguous.  So following two-part match will do no harm    -->
    <!-- to correct source, but will definitely harm incorrect source.   -->
    <xsl:apply-templates select="row[@header]">
        <xsl:with-param name="table-left" select="$table-left" />
        <xsl:with-param name="table-bottom" select="$table-bottom" />
        <xsl:with-param name="table-right" select="$table-right" />
        <xsl:with-param name="table-halign" select="$table-halign" />
        <xsl:with-param name="table-valign" select="$table-valign" />
    </xsl:apply-templates>
    <xsl:apply-templates select="row[not(@header)]">
        <xsl:with-param name="table-left" select="$table-left" />
        <xsl:with-param name="table-bottom" select="$table-bottom" />
        <xsl:with-param name="table-right" select="$table-right" />
        <xsl:with-param name="table-halign" select="$table-halign" />
        <xsl:with-param name="table-valign" select="$table-valign" />
    </xsl:apply-templates>
    <!-- mandatory finish, exclusive of any final row specifications -->
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="$tabular-environment"/>
    <xsl:text>}&#xa;</xsl:text>
    <!-- finish grouping for tabular font -->
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
    <xsl:if test="ancestor::sidebyside">
        <xsl:text>\par}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- We recursively traverse the "col" elements of the "column" group         -->
<!-- The cline specification is accumulated in the clines variable            -->
<!-- A similar strategy is used to traverse the "cell" elements of each "row" -->
<!-- but becomes much more involved, see the "row-cells" template             -->
<xsl:template match="col" mode="column-cols">
    <xsl:param name="col-number" />
    <xsl:param name="clines" />
    <xsl:param name="table-top" />
    <xsl:param name="start-run" />

    <!-- Look ahead one column, anticipating recursion           -->
    <!-- but also probing for end of column group (no more cols) -->
    <!-- An empty node-set will signal final "col" element       -->
    <xsl:variable name="next-col"  select="following-sibling::col[1]"/>
    <xsl:variable name="b-final-col" select="not($next-col)"/>
    <!-- The desired top border styles for columns, both -->
    <!-- current and next, so as to recognize a change   -->
    <xsl:variable name="current-top">
        <xsl:choose>
            <!-- cell specification -->
            <xsl:when test="@top">
                <xsl:value-of select="@top" />
            </xsl:when>
            <!-- inherited specification for top -->
            <xsl:otherwise>
                <xsl:value-of select="$table-top" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="next-top">
        <xsl:choose>
            <!-- empty is sentinel for currently on the final -->
             <!-- "col", and will not match any specification -->
            <xsl:when test="$b-final-col"/>
            <!-- cell specification -->
            <xsl:when test="$next-col/@top">
                <xsl:value-of select="$next-col/@top" />
            </xsl:when>
            <!-- inherited specification for top -->
            <xsl:otherwise>
                <xsl:value-of select="$table-top" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Formulate any necessary update to    -->
    <!-- cline information for the top border -->
    <xsl:variable name="updated-cline">
        <!-- write current cline information -->
        <xsl:value-of select="$clines" />
        <!-- is there a change, or end of column group, indicating need to flush -->
        <xsl:if test="not($current-top = $next-top)">
            <xsl:choose>
                <!-- end of column group and have never flushed -->
                <!-- hence a uniform top border                 -->
                <xsl:when test="$b-final-col and ($start-run = 1)">
                    <xsl:call-template name="hrule-specification">
                        <xsl:with-param name="width" select="$current-top" />
                    </xsl:call-template>
                </xsl:when>
                <!-- write cline for up-to, and including, current col -->
                <!-- if current run is "none" nothing is written       -->
                <xsl:when test="not($current-top = 'none')">
                    <xsl:call-template name="crule-specification">
                        <xsl:with-param name="width" select="$current-top" />
                        <xsl:with-param name="start" select="$start-run" />
                        <xsl:with-param name="finish" select="$col-number" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>
    <!-- recycle start-run if contiguous, else we have flushed  -->
    <!-- a partial specification into accululated $clines, so   -->
    <!-- restart at next "col".  If the new start is "too big", -->
    <!-- then no matter, since recursion halts anyway           -->
    <xsl:variable name="new-start-run" >
        <xsl:choose>
            <xsl:when test="$current-top = $next-top">
                <xsl:value-of select="$start-run"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$col-number + 1"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- if this is the final "col" the recursion will end (next) -->
    <!-- and we need to drop the accumulated cline specification  -->
    <xsl:if test="$b-final-col">
        <xsl:value-of select="$updated-cline"/>
    </xsl:if>
    <!-- Recursive call of this template on next "col",    -->
    <!-- which if empty will be a no-op and recursion ends -->
    <xsl:apply-templates select="$next-col" mode="column-cols">
        <xsl:with-param name="col-number" select="$col-number + 1" />
        <xsl:with-param name="clines" select="$updated-cline" />
        <xsl:with-param name="table-top" select="$table-top" />
        <xsl:with-param name="start-run" select="$new-start-run" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="row">
    <xsl:param name="table-left" />
    <xsl:param name="table-bottom" />
    <xsl:param name="table-right" />
    <xsl:param name="table-halign" />
    <xsl:param name="table-valign" />
    <!-- inherit global table-wide values    -->
    <!-- or replace with row-specific values -->
    <xsl:variable name="row-left">
        <xsl:choose>
            <xsl:when test="@left">
                <xsl:value-of select="@left" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$table-left" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="row-bottom">
        <xsl:choose>
            <xsl:when test="@bottom">
                <xsl:value-of select="@bottom" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$table-bottom" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Walking the row's cells, write contents and bottom borders -->
    <xsl:apply-templates select="cell[1]">
        <xsl:with-param name="left-col" select="parent::tabular/col[1]" /> <!-- possibly empty -->
        <xsl:with-param name="left-column-number" select="1" />
        <xsl:with-param name="clines" select="''" />
        <xsl:with-param name="start-run" select="1" />
        <xsl:with-param name="table-left" select="$table-left"/>
        <xsl:with-param name="table-bottom" select="$table-bottom"/>
        <xsl:with-param name="table-right" select="$table-right" />
        <xsl:with-param name="table-halign" select="$table-halign" />
        <xsl:with-param name="table-valign" select="$table-valign" />
        <xsl:with-param name="row-left" select="$row-left" />
        <xsl:with-param name="row-bottom" select="$row-bottom" />
    </xsl:apply-templates>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Recursively traverse the "cell" of a "row" while simultaneously       -->
<!-- traversing the "col" elements of the column group, if present.        -->
<!-- Inspect the (previously) built column specifications to see if        -->
<!-- a \multicolumn is necessary for an override on a table entry          -->
<!-- Accumulate cline information to write at the end of the line/row.     -->
<!-- Study the "column-cols" template for a less-involved template         -->
<!-- that uses an identical strategy, if you want to see something simpler -->
<!-- NB: column numbers are always accurate.  There may be either (1) no   -->
<!-- tabular/col or (2) one tabular/col for each column of the table.  So  -->
<!-- the $left-col parameter might  be empty through the entire recursion. -->
<!-- NB: the $table-* and $row-* parameters could be recomputed inside     -->
<!-- this template by looking outward and implmenting the same effective   -->
<!-- override and defaults strategy.  They are left in place as a          -->
<!-- historical artifact, and they might be just a smidge more efficient.  -->
<xsl:template match="cell">
    <xsl:param name="left-col" />
    <xsl:param name="left-column-number" />
    <xsl:param name="clines" />
    <xsl:param name="start-run" />
    <xsl:param name="table-left" />
    <xsl:param name="table-bottom" />
    <xsl:param name="table-right" />
    <xsl:param name="table-halign" />
    <xsl:param name="table-valign" />
    <xsl:param name="row-left" />
    <xsl:param name="row-bottom" />
    <!-- A cell may span several columns, or default to just 1              -->
    <!-- When colspan is not trivial, we identify the left and right ends   -->
    <!-- of the span, both as col elements and as column numbers            -->
    <!-- When colspan is trivial, the left and right versions are identical -->
    <!-- Left is used for left border and for horizontal alignment          -->
    <!-- Right is used for right border                                     -->
    <xsl:variable name="column-span">
        <xsl:choose>
            <xsl:when test="@colspan">
                <xsl:value-of select="@colspan" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="b-multiple-columns" select="$column-span > 1"/>
    <xsl:variable name="right-column-number" select="$left-column-number + $column-span - 1"/>
    <xsl:variable name="right-col" select="(parent::row/parent::tabular/col)[$right-column-number]"/>
    <!-- recreate the column specification for a right border       -->
    <!-- either a per-column value, or the global, table-wide value -->
    <xsl:variable name="column-right">
        <xsl:choose>
            <xsl:when test="$right-col/@right">
                <xsl:value-of select="$right-col/@right" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$table-right" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- determine a custom right border on a cell -->
    <!-- else default to the column value          -->
    <xsl:variable name="cell-right">
        <xsl:choose>
            <xsl:when test="@right">
                <xsl:value-of select="@right" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$column-right" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Use cell attributes, or col attributes for horizontal alignment -->
    <!-- recreate the column specification for horizontal alignment      -->
    <!-- either a per-column value, or the global, table-wide value      -->
    <xsl:variable name="column-halign">
        <xsl:choose>
            <xsl:when test="$left-col/@halign">
                <xsl:value-of select="$left-col/@halign" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$table-halign" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- determine a custom horizontal alignment on a cell        -->
    <!-- check for row override, else default to the column value -->
    <xsl:variable name="cell-halign">
        <xsl:choose>
            <xsl:when test="@halign">
                <xsl:value-of select="@halign" />
            </xsl:when>
            <!-- look to the row -->
            <xsl:when test="parent::row/@halign">
                <xsl:value-of select="parent::row/@halign" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$column-halign" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Use row attributes for vertical alignment                -->
    <!-- recreate the row specification for vertical alignment    -->
    <!-- either a per-row value, or the global, table-wide value  -->
    <xsl:variable name="row-valign">
        <xsl:choose>
            <xsl:when test="parent::row/@valign">
                <xsl:value-of select="parent::row/@valign" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$table-valign" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Look ahead to next cell, anticipating recursion     -->
    <!-- but also probing for end of row (empty $next-cell), -->
    <!-- which is needed when flushing cline specification.  -->
    <!-- Also for identifying changes in border styles       -->
    <xsl:variable name="next-cell" select="following-sibling::cell[1]"/>
    <!-- Write the cell's contents -->
    <!-- Wrap in a multicolumn in any of the following situations for    -->
    <!-- the purposes of vertical boundary rules or content formatting:  -->
    <!--    -if the left border, horizontal alignment or right border    -->
    <!--         conflict with the column specification                  -->
    <!--    -if we have a colspan                                        -->
    <!--    -if there are paragraphs in the cell                         -->
    <!-- $table-left and $row-left *can* differ on first use,            -->
    <!-- but row-left is subsequently set to $table-left.                -->
    <xsl:choose>
        <xsl:when test="not($table-left = $row-left) or not($column-halign = $cell-halign) or not($column-right = $cell-right) or $b-multiple-columns or p">
            <xsl:text>\multicolumn{</xsl:text>
            <xsl:value-of select="$column-span" />
            <xsl:text>}{</xsl:text>
            <!-- only place latex allows/needs a left border -->
            <xsl:if test="$left-column-number = 1">
                <xsl:call-template name="vrule-specification">
                    <xsl:with-param name="width" select="$row-left" />
                </xsl:call-template>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="p">
                    <!-- paragraph-valign-specification differs from valign-specification -->
                    <xsl:call-template name="paragraph-valign-specification">
                        <xsl:with-param name="align" select="$row-valign" />
                    </xsl:call-template>
                    <xsl:text>{</xsl:text>
                    <xsl:choose>
                        <xsl:when test="$left-col/@width">
                            <xsl:variable name="width">
                                <xsl:call-template name="normalize-percentage">
                                    <xsl:with-param name="percentage" select="$left-col/@width" />
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:value-of select="substring-before($width, '%') div 100" />
                        </xsl:when>
                        <!-- If there is no $left-col/@width, silently use 20% as default -->
                        <!-- We get some ill-formed WW exercises here, so a less-precise  -->
                        <!-- warning is given on the author's source.                     -->
                        <xsl:otherwise>
                            <xsl:text>0.2</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>\linewidth}</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="halign-specification">
                        <xsl:with-param name="align" select="$cell-halign" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="vrule-specification">
                <xsl:with-param name="width" select="$cell-right" />
            </xsl:call-template>
            <xsl:text>}{</xsl:text>
            <xsl:apply-templates select="." mode="table-cell-wrapper">
                <xsl:with-param name="halign" select="$cell-halign" />
                <xsl:with-param name="valign" select="$row-valign" />
            </xsl:apply-templates>
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="table-cell-wrapper">
                <xsl:with-param name="halign" select="$cell-halign" />
                <xsl:with-param name="valign" select="$row-valign" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
    <!-- more content to come, use tabular separator -->
    <xsl:if test="$next-cell">
        <xsl:text>&amp;</xsl:text>
    </xsl:if>
    <!-- The desired bottom border style for this cell     -->
    <xsl:variable name="current-bottom">
        <xsl:choose>
            <!-- cell specification -->
            <xsl:when test="@bottom">
                <xsl:value-of select="@bottom" />
            </xsl:when>
            <!-- inherited specification for row -->
            <xsl:otherwise>
                <xsl:value-of select="$row-bottom" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- The desired bottom border style for the next cell     -->
    <xsl:variable name="next-bottom">
        <xsl:choose>
            <!-- end of row, no next cell, so      -->
            <!-- bottom style signals change/flush -->
            <xsl:when test="not($next-cell)">
                <xsl:text>undefined-bottom</xsl:text>
            </xsl:when>
            <!-- next cell's specification -->
            <xsl:when test="$next-cell/@bottom">
                <xsl:value-of select="$next-cell/@bottom" />
            </xsl:when>
            <!-- inherited specification for row -->
            <xsl:otherwise>
                <xsl:value-of select="$row-bottom" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Formulate any necessary update to cline -->
    <!-- information for the bottom border       -->
    <xsl:variable name="updated-cline">
        <xsl:value-of select="$clines" />
        <!-- if there a change in bottom border, and always at end -->
        <!-- of row, conclude the creation of a specification      -->
        <xsl:if test="not($current-bottom = $next-bottom)">
            <xsl:choose>
                <!-- end of row and have never flushed -->
                <!-- hence a uniform bottom border     -->
                <xsl:when test="not($next-cell) and ($start-run = 1)">
                    <xsl:call-template name="hrule-specification">
                        <xsl:with-param name="width" select="$current-bottom" />
                    </xsl:call-template>
                </xsl:when>
                <!-- write cline for up-to, and including, prior cell      -->
                <!-- prior-bottom always lags, so never operate on cell #1 -->
                <xsl:when test="not($current-bottom = 'none')">
                    <xsl:call-template name="crule-specification">
                        <xsl:with-param name="width" select="$current-bottom" />
                        <xsl:with-param name="start" select="$start-run" />
                        <xsl:with-param name="finish" select="$right-column-number" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>
    <!-- duplicate start of current border style or reset to next column -->
    <xsl:variable name="new-start-run">
        <xsl:choose>
            <xsl:when test="$current-bottom = $next-bottom">
                <xsl:value-of select="$start-run" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$right-column-number + 1" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Always attempt a recursive call.  If cells are exhausted, -->
    <!-- $next-cell is empty/false and nothing happens here        -->
    <!-- Leap forward to column element just beyond end of colspan -->
    <xsl:apply-templates select="$next-cell">
        <xsl:with-param name="left-col" select="$right-col/following-sibling::col[1]" />
        <xsl:with-param name="left-column-number" select="$right-column-number + 1" />
        <xsl:with-param name="clines" select="$updated-cline" />
        <xsl:with-param name="start-run" select="$new-start-run" />
        <xsl:with-param name="table-left" select="$table-left" />
        <xsl:with-param name="table-bottom" select="$table-bottom" />
        <xsl:with-param name="table-right" select="$table-right" />
        <xsl:with-param name="table-halign" select="$table-halign" />
        <xsl:with-param name="table-valign" select="$table-valign" />
        <xsl:with-param name="row-left" select="$table-left" />
        <xsl:with-param name="row-bottom" select="$row-bottom" />
    </xsl:apply-templates>

    <!-- finish the row, dump cline info, etc -->
    <xsl:if test="not($next-cell)">
        <xsl:choose>
            <!-- \tabularnewline is unambiguous, better than \\ -->
            <!-- *any* line with decoration needs a conclusion  -->
            <xsl:when test="not($updated-cline = '')">
                <xsl:text>\tabularnewline</xsl:text>
                <xsl:value-of select="$updated-cline"/>
            </xsl:when>
            <!-- Test determines if there are more rows.         -->
            <!-- Next row could begin with bare [ and LaTeX sees -->
            <!-- the start of \tabularnewline[] which would      -->
            <!-- indicate the need for some unit of length for a -->
            <!-- space, so we just appease the macro with a 0pt. -->
            <!-- https://github.com/rbeezer/mathbook/issues/300  -->
            <xsl:when test="parent::row/following-sibling::row">
                <xsl:text>\tabularnewline[0pt]</xsl:text>
            </xsl:when>
            <!-- last row, no decoration, \end{tabular} concludes-->
            <xsl:otherwise/>
         </xsl:choose>
    </xsl:if>
</xsl:template>


<!-- ############################ -->
<!-- Table construction utilities -->
<!-- ############################ -->

<!-- Mostly translating PTX terms to LaTeX terms         -->
<!-- Typically use these at the last moment,             -->
<!-- while outputting, and thus use PTX terms internally -->

<!-- Some utilities are defined in xsl/pretext-common.xsl -->

<!-- "halign-specification" : param "align" -->
<!--     left, right, center -> l, c, r     -->

<!-- "valign-specification" : param "align" -->
<!--     top, middle, bottom -> t, m, b     -->

<!-- paragraph valign-specifications (p, m, b) are  -->
<!-- different from (t, m, b) in pretext-common    -->

<!-- paragraph halign-specifications (left, center, right, justify) -->
<!-- converted to \raggedright, \centering, \raggedleft, <empty>    -->

<xsl:template name="paragraph-valign-specification">
    <xsl:param name="align" />
    <xsl:choose>
        <xsl:when test="$align='top'">
            <xsl:text>p</xsl:text>
        </xsl:when>
        <xsl:when test="$align='middle'">
            <xsl:text>m</xsl:text>
        </xsl:when>
        <xsl:when test="$align='bottom'">
            <xsl:text>b</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING: vertical alignment attribute not recognized: use top, middle, bottom</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="paragraph-halign-specification">
    <xsl:param name="align" />
    <xsl:choose>
        <xsl:when test="$align='justify'">
            <xsl:text></xsl:text>
        </xsl:when>
        <xsl:when test="$align='left'">
            <xsl:text>\raggedright</xsl:text>
        </xsl:when>
        <xsl:when test="$align='center'">
            <xsl:text>\centering</xsl:text>
        </xsl:when>
        <xsl:when test="$align='right'">
            <xsl:text>\raggedleft</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING: horizontal alignment attribute not recognized: use left, center, right, justify</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate vertical rule width to a LaTeX "new" column specification -->
<xsl:template name="vrule-specification">
    <xsl:param name="width" />
    <xsl:choose>
        <xsl:when test="$width='none'">
            <xsl:text></xsl:text>
        </xsl:when>
        <xsl:when test="$width='minor'">
            <xsl:text>A</xsl:text>
        </xsl:when>
        <xsl:when test="$width='medium'">
            <xsl:text>B</xsl:text>
        </xsl:when>
        <xsl:when test="$width='major'">
            <xsl:text>C</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING: tabular left or right attribute not recognized: use none, minor, medium, major</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate horizontal rule width to hrule terms -->
<xsl:template name="hrule-specification">
    <xsl:param name="width" />
    <xsl:choose>
        <xsl:when test="$width='none'">
            <xsl:text></xsl:text>
        </xsl:when>
        <xsl:when test="$width='minor'">
            <xsl:text>\hrulethin</xsl:text>
        </xsl:when>
        <xsl:when test="$width='medium'">
            <xsl:text>\hrulemedium</xsl:text>
        </xsl:when>
        <xsl:when test="$width='major'">
            <xsl:text>\hrulethick</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING: tabular top or bottom attribute not recognized: use none, minor, medium, major</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate abbreviated horizontal rules to cline specifications -->
<xsl:template name="crule-specification">
    <xsl:param name="width" />
    <xsl:param name="start" />
    <xsl:param name="finish" />
    <!-- style. thickness -->
    <xsl:choose>
        <xsl:when test="$width='none'">
            <xsl:text></xsl:text>
        </xsl:when>
        <xsl:when test="$width='minor'">
            <xsl:text>\crulethin</xsl:text>
        </xsl:when>
        <xsl:when test="$width='medium'">
            <xsl:text>\crulemedium</xsl:text>
        </xsl:when>
        <xsl:when test="$width='major'">
            <xsl:text>\crulethick</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING: tabular top or bottom attribute not recognized: use none, minor, medium, major</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <!-- span -->
    <xsl:if test="not($width='none')">
        <xsl:text>{</xsl:text>
        <xsl:value-of select="$start" />
        <xsl:text>-</xsl:text>
        <xsl:value-of select="$finish" />
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="cell" mode="table-cell-wrapper">
    <xsl:param name="the-cell" />
    <xsl:param name="halign" />
    <xsl:param name="valign" />

    <!-- a cell of a header row needs to be bold -->
    <xsl:variable name="b-header-row" select="(parent::row/@header = 'yes') or (parent::row/@header = 'vertical')"/>
    <!-- and vertical text is a refinement -->
    <xsl:variable name="b-vertical-header" select="parent::row/@header = 'vertical'"/>

    <xsl:variable name="b-row-headers" select="(parent::row/parent::tabular[@row-headers = 'yes'])"/>
    <xsl:variable name="b-first-cell" select="not(preceding-sibling::cell)"/>

    <xsl:variable name="b-bold-face-cell" select="$b-header-row or ($b-row-headers and $b-first-cell)"/>

    <xsl:choose>
        <xsl:when test="p">
            <!-- paragraph-halign-specification differs from halign-specification -->
            <xsl:call-template name="paragraph-halign-specification">
                <xsl:with-param name="align" select="$halign" />
            </xsl:call-template>
            <!-- styling choice for interparagraph spacing within a table cell    -->
            <xsl:if test="count(p) > 1">
                <xsl:text>\setlength{\parskip}{0.5\baselineskip}</xsl:text>
            </xsl:if>
            <xsl:text>%&#xa;</xsl:text>
            <xsl:apply-templates select="p" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:if test="$b-bold-face-cell">
                <xsl:text>{\bfseries{}</xsl:text>
            </xsl:if>
            <xsl:if test="$b-vertical-header">
                <xsl:text>\rotatebox{90}{</xsl:text>
            </xsl:if>
            <xsl:apply-templates select="." mode="table-cell-content">
                <xsl:with-param name="halign" select="$halign" />
                <xsl:with-param name="valign" select="$valign" />
            </xsl:apply-templates>
            <!-- a little space keeps text off a top rule -->
            <xsl:if test="$b-vertical-header">
                <xsl:text>\space}</xsl:text>
            </xsl:if>
            <xsl:if test="$b-bold-face-cell">
                <xsl:text>}</xsl:text>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="cell" mode="table-cell-content">
    <xsl:param name="halign" />
    <xsl:param name="valign" />
    <xsl:choose>
        <xsl:when test="line">
            <!-- macro for multiline cell -->
            <xsl:text>\tablecelllines{</xsl:text>
            <xsl:call-template name="halign-specification">
                <xsl:with-param name="align" select="$halign" />
            </xsl:call-template>
            <xsl:text>}{</xsl:text>
            <xsl:call-template name="valign-specification">
                <xsl:with-param name="align" select="$valign" />
            </xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>{</xsl:text>
            <!-- adding \textbf, \bfseries not 100% effective here -->
            <xsl:apply-templates select="line" />
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <!-- the content of unstructured cell -->
            <xsl:apply-templates/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ########################### -->
<!-- Labels and Cross-References -->
<!-- ########################### -->


<!-- We have two schemes in place for marking, number-generation, and       -->
<!-- cross-referencing of objects.  Our use of the  hyperref  package       -->
<!-- allows for more expressive links which allow us to duplicate LaTeX     -->
<!-- packages like "cleverref" and the base functionality of HTML.  We      -->
<!-- could accomplish (nearly) all of this with the second scheme only, but -->
<!-- we are following LaTeX's rules for numbering PreTeXt-wide, so the      -->
<!-- first scheme provides good checks.                                     -->
<!--                                                                        -->
<!-- 1.  Traditional LaTeX \label{}, \ref{}                                 -->
<!-- \label marks a location.  If inside an item/object which LaTeX numbers -->
<!-- \naturally, then ref{} will generate that number.  In order to make an -->
<!-- \electronic PDF, we use the  hyperref  package, and specifically, the  -->
<!-- \hyperref[]{} command.  The string that associates these comes from    -->
<!-- \our "unique-id" template, often the @xml:id.  Example:              -->
<!--                                                                        -->
<!--   \begin{theorem}\label{foo}                                           -->
<!--                                                                        -->
<!--   \hyperref[foo]{Theorem~\ref{foo}}                                    -->
<!--                                                                        -->
<!-- Note: for print, we could use "Theorem~\ref{foo}" just as easily and   -->
<!-- not utilize  hyperref (presently, we use a hyperref "hidelinks" key)   -->
<!--                                                                        -->
<!-- 2.  Hyperref                                                           -->
<!-- Some items are not numbered naturally by LaTeX, like a "proof".  Other -->
<!-- items we number in different ways, such as a solo "exercises" division -->
<!-- whose number is that of its containing division.  Some items are not   -->
<!-- numbered at all, like a "preface".  Here we use \hypertarget{}{} as    -->
<!-- the marker, and \hyperlink{}{} with custom text (title, hard-coded     -->
<!-- number, etc) as the visual, clickable link.  The "unique-id" is used -->
<!-- as before to link the two commands.  The second argument of            -->
<!-- \hypertarget can be text, but we uniformly leave it empty (a \null     -->
<!-- target text was unnecessary and visible, 2015-12-12).  Example:        -->
<!--                                                                        -->
<!--   \begin{proof}\hypertarget{foo}{}                                     -->
<!--                                                                        -->
<!--   \hyperlink{foo}{Proof~2.4.17}                                        -->
<!--                                                                        -->
<!-- Note: for print, we could use "Proof~2.4.17" just as easily and not    -->
<!-- not utilize  hyperref (presently, we use a hyperref "hidelinks" key)   -->
<!--                                                                        -->
<!-- Note: footnotes, "fn" are exceptional, see notes below                 -->

<!-- ################## -->
<!-- Unique Identifiers -->
<!-- ################## -->

<!-- We use the universal "unique-id" template to create strings -->
<!-- identifying items in LaTeX output, as names and as pointers.  -->

<!-- ################################ -->
<!-- Labels (cross-reference targets) -->
<!-- ################################ -->

<!-- We assume traditional LaTeX  label/ref  system as the default, so      -->
<!-- anything that we allow to be the target of a cross-reference AND LaTeX -->
<!-- does not number automatically, we need to list in the "false"          -->
<!-- template. Anything in this latter list, which can be cross-referenced  -->
<!-- (by number or by title) will get a  \hypertarget  via the "label"      -->
<!-- template. Exceptions - "book" and "article" are carefully marked in    -->
<!-- special ways, so inclusion here is not ever exercised, unless we made  -->
<!-- some edits to employ this template in those special places. This list  -->
<!-- here is everything numbered by PreTeXt, followed by targets that are   -->
<!-- not numbered.                                                          -->

<xsl:template match="*" mode="xref-as-ref">
    <xsl:value-of select="true()" />
</xsl:template>

<!-- Any target of a PreTeXt cross-reference, which is not naturally -->
<!-- numbered by a LaTeX \label{} command, needs to go here.         -->
<xsl:template match="exercises//exercise|worksheet//exercise|reading-questions//exercise|biblio|biblio/note|&PROOF-LIKE;|case|ol/li|dl/li|&SOLUTION-LIKE;|subexercises|exercisegroup|p|paragraphs|blockquote|contributor|colophon|book|article" mode="xref-as-ref">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- A specialized division in an unstructured division may  -->
<!-- not be numbered correctly via LaTeX's label/ref system, -->
<!-- so we will use the hypertarget/hyperlink system         -->
<!-- NB: template returns strings "true" or "false"          -->
<xsl:template  match="exercises|reading-questions|glossary|references|worksheet|handout|solutions" mode="xref-as-ref">
    <xsl:apply-templates select="." mode="is-specialized-own-number"/>
</xsl:template>

<xsl:template match="*" mode="label">
    <xsl:variable name="xref-as-ref">
        <xsl:apply-templates select="." mode="xref-as-ref" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$xref-as-ref = 'true'">
            <xsl:text>\label{</xsl:text>
            <xsl:apply-templates select="." mode="unique-id" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- Objects cross-referenced outside of LaTeX's usual     -->
        <!-- scheme need a \hypertarget, but for page numbers      -->
        <!-- in cross-references, we need a traditional label.     -->
        <xsl:otherwise>
            <xsl:if test="$b-pageref">
                <xsl:text>\label{</xsl:text>
                <xsl:apply-templates select="." mode="unique-id" />
                <xsl:text>}{}</xsl:text>
            </xsl:if>
            <xsl:text>\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="unique-id" />
            <xsl:text>}{}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- We sometimes use the presence of @xml:id to indicate that an     -->
<!-- author intends an element to be the target of a cross-reference, -->
<!-- and then *elect* to place a label.                               -->
<xsl:template match="*" mode="optional-label">
    <xsl:if test="@xml:id">
        <xsl:apply-templates select="." mode="label"/>
    </xsl:if>
</xsl:template>

<!-- An extraordinary template produces labels for exercise components -->
<!-- (hint, answer, solution) displayed in solution lists (via the     -->
<!-- "solutions" element).  The purpose is to allow the original       -->
<!-- version of an exercise to point to solutions elsewhere.           -->
<!-- The suffix is general-purpose, but is intended now to be          -->
<!-- "main" or "back", depending on where the solution is located.     -->
<xsl:template match="&SOLUTION-LIKE;" mode="unique-id-duplicate">
    <xsl:param name="suffix" select="'bad-suffix'"/>
    <xsl:apply-templates select="." mode="unique-id" />
    <xsl:text>-</xsl:text>
    <xsl:value-of select="$suffix"/>
</xsl:template>


<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- Much of the cross-reference mechanism is implemented in the common     -->
<!-- routines, here we need to implement two abstract templates which are   -->
<!-- called from those routines. First we generate a number, which for      -->
<!-- LaTeX may be the abstract representation of a \ref{} with a string     -->
<!-- identifier.  This goes back to the common routines and is used to      -->
<!-- fashion the entire link text.  This is the $content variable below.    -->
<!-- From this the actual \hyperref or \hypertarget is made. Almost always, -->
<!-- across PreTeXt, the "xref-number" template will return the number of   -->
<!-- an item as computed in the -common routines.  However, to maintain     -->
<!-- fidelity with LaTeX's automatic numbering system, we create  \ref{}    -->
<!-- as often as possible. -->
<!--                                                                        -->
<!-- This is the implementation of an abstract template, creating \ref{} by -->
<!-- default. We check if a part number is needed to prevent ambiguity. The -->
<!-- exceptions above should be either (a) not numbered, or (b) numbered in -->
<!-- ways LaTeX cannot, so the union of the match critera here should be    -->
<!-- the list above.  Or said differently, a new object needs to preserve   -->
<!-- this union property across the various "xref-number" templates.        -->
<!-- See xsl/pretext-common.xsl for more info.                             -->

<xsl:template match="*" mode="xref-number">
    <xsl:param name="xref" select="/.." />

    <xsl:apply-templates select="." mode="xref-number-latex">
        <xsl:with-param name="xref" select="$xref"/>
    </xsl:apply-templates>
</xsl:template>

<!-- Tasks have a structure number from the enclosing project   -->
<!-- and a serial number from the enumitem package on the lists -->
<!-- We compose the two LaTeX \ref{}                            -->
<xsl:template match="task" mode="xref-number">
    <!-- ancestors, strip tasks, get number of next enclosure -->
    <xsl:apply-templates select="ancestor::*[not(self::task)][1]" mode="xref-number" />
    <xsl:text>.</xsl:text>
    <!-- task always gets a number, but we have to avoid recursion -->
    <!-- that would result by just getting a \ref from xref-number -->
    <xsl:text>{\xreffont\ref{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id" />
    <xsl:text>}}</xsl:text>
</xsl:template>

<!-- Straightforward exception, simple implementation,  -->
<!-- when an "mrow" of display mathematics is tagged    -->
<!-- with symbols not numbers                           -->
<xsl:template match="mrow[@tag]" mode="xref-number">
    <xsl:text>{\xreffont\ref{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id" />
    <xsl:text>}}</xsl:text>
</xsl:template>

<!-- These exceptions are unnumbered, and are just handled explicitly, -->
<!-- along with a check, the template produces *nothing*               -->
<xsl:template match="p|paragraphs|blockquote|contributor|colophon|book|article" mode="xref-number">
    <xsl:param name="xref" select="/.." />

    <!-- number is necessary only for a checking mechanism -->
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:if test="not($the-number = '')">
        <xsl:message>PTX:BUG:     LaTeX conversion thinks an item is not numbered, but common routines do produce a number.  The "xref" is</xsl:message>
        <xsl:apply-templates select="$xref" mode="location-report" />
        <xsl:message>             The target is</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
</xsl:template>

<!-- Now we have items that PreTeXt numbers itself, in ways LaTeX does not. -->
<!-- "fn" is exceptional - the \label\ref mechanism works well, providing   -->
<!-- local numbers where born (both on the same page), but we need to       -->
<!-- inlude "fn" at the end of this template so that cross-references get   -->
<!-- fully-qualified numbers in the link text.                              -->
<!--                                                                        -->
<!-- Note: objectives are one-per-subdivision, and precede the              -->
<!-- introduction, so the LaTeX \ref{} mechanism assigns the correct        -->
<!-- number - that of the enclosing subdivision                             -->
<xsl:template match="exercises//exercise|worksheet//exercise|reading-questions//exercise|biblio|biblio/note|&PROOF-LIKE;|case|ol/li|dl/li|&SOLUTION-LIKE;|&DISCUSSION-LIKE;|exercisegroup|fn" mode="xref-number">
    <xsl:param name="xref" select="/.." />

    <xsl:apply-templates select="." mode="xref-number-hardcoded">
        <xsl:with-param name="xref" select="$xref"/>
    </xsl:apply-templates>
</xsl:template>

<!-- A specialized division in an unstructured division may  -->
<!-- not be numbered correctly via LaTeX's label/ref system, -->
<!-- so we will use the hypertarget/hyperlink system         -->
<!-- This template just copies the gut of two above, perhaps -->
<!-- there should be two utility templates that each get     -->
<!-- called twice overall.                                   -->
<xsl:template  match="exercises|reading-questions|glossary|references|worksheet|handout|solutions" mode="xref-number">
    <xsl:param name="xref" select="/.." />

    <xsl:variable name="is-numbered">
        <xsl:apply-templates select="." mode="is-specialized-own-number"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$is-numbered = 'true'">
            <xsl:apply-templates select="." mode="xref-number-latex">
                <xsl:with-param name="xref" select="$xref"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="xref-number-hardcoded">
                <xsl:with-param name="xref" select="$xref"/>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Two utility routines generate an "xref number" in a   -->
<!-- traditional way or in a hyperref way.  These are used -->
<!-- above in at least two places each.                    -->

<!-- A hardcoded number respecting the necessity of parts -->
<xsl:template  match="*" mode="xref-number-hardcoded">
    <xsl:param name="xref" select="/.." />

    <xsl:variable name="needs-part-prefix">
        <xsl:apply-templates select="." mode="crosses-part-boundary">
            <xsl:with-param name="xref" select="$xref" />
        </xsl:apply-templates>
    </xsl:variable>
    <!-- Hard-coded can use a space that LaTeX gobbles up -->
    <xsl:text>{\xreffont </xsl:text>
    <xsl:if test="$needs-part-prefix = 'true'">
        <xsl:apply-templates select="ancestor::part" mode="serial-number" />
        <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- A LaTeX \ref (number) respecting the necessity of parts -->
<xsl:template  match="*" mode="xref-number-latex">
    <xsl:param name="xref" select="/.." />

    <!-- number is necessary only for a checking mechanism -->
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="not($the-number = '')">
            <!-- no matter the "if" a \ref follows -->
            <xsl:text>{\xreffont</xsl:text>
            <!-- check if part prefix is needed -->
            <xsl:variable name="needs-part-prefix">
                <xsl:apply-templates select="." mode="crosses-part-boundary">
                    <xsl:with-param name="xref" select="$xref" />
                </xsl:apply-templates>
            </xsl:variable>
            <!-- if so, append prefix with separator -->
            <xsl:if test="$needs-part-prefix = 'true'">
                <xsl:text>\ref{</xsl:text>
                <xsl:apply-templates select="ancestor::part" mode="unique-id" />
                <xsl:text>}</xsl:text>
                <xsl:text>.</xsl:text>
            </xsl:if>
            <!-- and always, a representation for the text of the xref -->
            <xsl:text>\ref{</xsl:text>
            <xsl:apply-templates select="." mode="unique-id" />
            <xsl:text>}</xsl:text>
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING: there appears to be an "xref" by number to an item (of type "<xsl:value-of select="local-name(.)" />") without a number (or there is a bug).  The "xref" is</xsl:message>
            <xsl:apply-templates select="$xref" mode="location-report" />
            <xsl:message>             The target is</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- This template actually manufactures the link.  When the link lives in  -->
<!-- a title, the link text is just reproduced.  If the number is hard-     -->
<!-- coded, fine.  If the number is obtained by a \ref, we use the starred  -->
<!-- form to prevent some link-inside-a-link confusion.  Some internet      -->
<!-- sites suggest maybe we should just use the *-form universally, though  -->
<!-- that would make the LaTex source a bit less portable?  This is where   -->
<!-- we could use "latex.print" to output the $content variable with no     -->
<!-- linking, perhaps making a better PDF?                                  -->
<!--                                                                        -->
<!-- Note that the "xref-as-ref" template is needed here to accomodate the  -->
<!-- $target's characteristics.  Also, this template then does not need to  -->
<!-- be edited.                                                             -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="target" select="/.." />
    <xsl:param name="content" select="'MISSING LINK CONTENT'"/>

    <xsl:variable name="xref-as-ref">
        <xsl:apply-templates select="$target" mode="xref-as-ref" />
    </xsl:variable>
    <xsl:choose>
        <!-- inactive in titles, just text               -->
        <!-- With protection against incorrect, sloppy   -->
        <!-- matches, we sneak in the starred version    -->
        <!-- of \ref{} so as to get a number for a label -->
        <!-- in a cross-references, not an active link   -->
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:variable name="active-ref">
                <xsl:text>\ref{</xsl:text>
                <xsl:apply-templates select="$target" mode="unique-id" />
                <xsl:text>}</xsl:text>
            </xsl:variable>
            <xsl:variable name="inactive-ref">
                <xsl:text>\ref*{</xsl:text>
                <xsl:apply-templates select="$target" mode="unique-id" />
                <xsl:text>}</xsl:text>
            </xsl:variable>
            <xsl:value-of select="str:replace($content, $active-ref, $inactive-ref)" />
        </xsl:when>
        <xsl:when test="$xref-as-ref='true'">
            <xsl:text>\hyperref[</xsl:text>
            <xsl:apply-templates select="$target" mode="unique-id" />
            <xsl:text>]</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="$content" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\hyperlink{</xsl:text>
            <xsl:apply-templates select="$target" mode="unique-id" />
            <xsl:text>}</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="$content" />
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="xref|&PROOF-LIKE;" mode="latex-page-number">
    <xsl:param name="target"/>

    <xsl:choose>
        <!-- looks bad when bibliographic number gets wrapped in [] -->
        <!-- and the number should suffice on its own               -->
        <xsl:when test="$target/self::biblio"/>
        <!-- and trailing a () for an equation number is overkill -->
        <xsl:when test="$target/self::mrow|$target/self::men"/>
        <!-- and it is really bad for an xref inside a title -->
        <xsl:when test="ancestor::title"/>
        <!-- off by default electronic PDF, -->
        <!-- or on by default for print PDF -->
        <xsl:when test="not($b-pageref)"/>
        <!-- OK, requested and helps, let's add it -->
        <xsl:otherwise>
            <xsl:text>, p.\,\pageref{</xsl:text>
            <xsl:apply-templates select="$target" mode="unique-id"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ################## -->
<!-- Languages, Scripts -->
<!-- ################## -->

<!-- TODO: the @xml:lang attribute serves more than one purpose. -->
<!-- For LaTeX it is both localization of terms ("Theorem"),     -->
<!-- especially in multilingual documents or translations, but   -->
<!-- also a selection of necessary fonts/glyphs/scripts.  We     -->
<!-- might wish for a more robust method of determing which      -->
<!-- languages have supported fonts than just an empty return    -->
<!-- from the "country-to-language" template.                    -->
<!-- TODO: these would be more XSLT-ish if there were wrapper    -->
<!-- templates rather than a begin template and an end template. -->

<!-- Absent @xml:lang, do nothing -->
<xsl:template match="*" mode="begin-language" />
<xsl:template match="*" mode="end-language" />

<!-- More specifically, change language                -->
<!-- This assumes element is enabled for this behavior -->
<xsl:template match="*[@xml:lang]" mode="begin-language">
    <xsl:variable name="language">
        <xsl:apply-templates select="." mode="country-to-language"/>
    </xsl:variable>
    <xsl:if test="not($language = '')">
        <xsl:text>\begin{</xsl:text>
        <xsl:value-of select="$language"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="*[@xml:lang]" mode="end-language">
    <xsl:variable name="language">
        <xsl:apply-templates select="." mode="country-to-language"/>
    </xsl:variable>
    <xsl:if test="not($language = '')">
        <xsl:text>\end{</xsl:text>
        <xsl:value-of select="$language"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Even more specifically, we provide an inline version -->
<!-- This should be more readable in LaTex source         -->
<xsl:template match="foreign[@xml:lang]" mode="begin-language">
    <xsl:variable name="language">
        <xsl:apply-templates select="." mode="country-to-language"/>
    </xsl:variable>
    <xsl:if test="not($language = '')">
        <xsl:text>\text</xsl:text>
        <xsl:value-of select="$language"/>
        <xsl:text>{</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="foreign[@xml:lang]" mode="end-language">
    <xsl:variable name="language">
        <xsl:apply-templates select="." mode="country-to-language"/>
    </xsl:variable>
    <xsl:if test="not($language = '')">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Assumes element has an xml:lang attribute      -->
<!-- Translates a country-region code to a language -->
<xsl:template match="*[@xml:lang]" mode="country-to-language">
    <xsl:choose>
        <xsl:when test="@xml:lang='el'">
            <xsl:text>greek</xsl:text>
        </xsl:when>
        <xsl:when test="@xml:lang='ko-KR'">
            <xsl:text>korean</xsl:text>
        </xsl:when>
        <xsl:when test="@xml:lang='hu-HU'">
            <xsl:text>magyar</xsl:text>
        </xsl:when>
        <xsl:when test="@xml:lang='ru-RU'">
            <xsl:text>russian</xsl:text>
        </xsl:when>
        <xsl:when test="@xml:lang='es-ES'">
            <xsl:text>spanish</xsl:text>
        </xsl:when>
        <xsl:when test="@xml:lang='vi-VN'">
            <xsl:text>vietnamese</xsl:text>
        </xsl:when>
        <!-- no supported language, return nothing -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:template>

<!-- ################### -->
<!-- Structured by Lines -->
<!-- ################### -->

<!-- The LaTeX-specific line separator for use by  -->
<!-- the abstract template for a "line" elent used -->
<!-- to (optionally) structure certain elements.   -->

<xsl:template name="line-separator">
    <xsl:text>\\&#xa;</xsl:text>
</xsl:template>

<!-- ###### -->
<!-- Poetry -->
<!-- ###### -->

<xsl:template match="poem">
    <xsl:text>\begin{poem}</xsl:text>
    <xsl:apply-templates select="." mode="optional-label"/>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\poemTitle{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="stanza|idx"/>
    <xsl:apply-templates select="author" />
    <xsl:text>\end{poem}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="poem/author">
    <xsl:variable name="alignment">
        <xsl:apply-templates select="." mode="poem-halign"/>
    </xsl:variable>
    <xsl:text>\poemauthor</xsl:text>
    <xsl:value-of select="$alignment"/>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="stanza">
    <xsl:if test="title">
        <xsl:text>\stanzaTitle{</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{stanza}&#xa;</xsl:text>
    <xsl:apply-templates select="line|idx"/>
    <xsl:text>\end{stanza}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="stanza/line">
    <!-- Find Alignment -->
    <xsl:variable name="alignment">
        <xsl:apply-templates select="." mode="poem-halign"/>
    </xsl:variable>
    <!-- Find Indentation -->
    <xsl:variable name="indentation">
        <xsl:apply-templates select="." mode="poem-indent"/>
    </xsl:variable>
    <!-- Apply Alignment and Indentation -->
    <xsl:text>\poemline</xsl:text>
    <xsl:value-of select="$alignment"/>
    <xsl:text>{</xsl:text>
    <xsl:if test="$alignment='left'"><!-- Left Alignment: Indent from Left -->
        <xsl:call-template name="poem-line-indenting">
            <xsl:with-param name="count"><xsl:value-of select="$indentation"/></xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <xsl:apply-templates/><!-- Center Alignment: Ignore Indentation -->
    <xsl:if test="$alignment='right'"><!-- Right Alignment: Indent from Right -->
        <xsl:call-template name="poem-line-indenting">
            <xsl:with-param name="count"><xsl:value-of select="$indentation"/></xsl:with-param>
        </xsl:call-template>
        <!-- Latex seems to "eat" one indentation while right aligned, so we add one extra -->
        <xsl:text>\poemIndent{}</xsl:text>
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<xsl:template name="poem-line-indenting">
    <xsl:param name="count"/>
    <xsl:choose>
        <xsl:when test="(0 >= $count)"/>
        <xsl:otherwise>
            <xsl:text>\poemIndent{}</xsl:text>
            <xsl:call-template name="poem-line-indenting">
                <xsl:with-param name="count" select="$count - 1"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!--       -->
<!-- Music -->
<!--       -->

<!--                 -->
<!-- Musical Symbols -->
<!--                 -->

<!-- Accidentals -->

<!-- TODO: If requested, add semi- and sesqui- versions of sharp and flat -->

<!-- These "choose" should really be separate match -->
<!-- templates on title//*, but the use of named    -->
<!-- templates would require a big re-write, so we  -->
<!-- have some technical debt here                  -->

<!-- Our macros need protection in titles and typeout commands -->

<!-- Double Sharp -->
<xsl:template name="doublesharp">
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:text>\protect\doublesharp</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{\doublesharp}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Sharp -->
<xsl:template name="sharp">
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:text>\protect\sharp</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{\sharp}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Natural -->
<xsl:template name="natural">
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:text>\protect\natural</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{\natural}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Flat -->
<xsl:template name="flat">
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:text>\protect\flat</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{\flat}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Double Flat -->
<xsl:template name="doubleflat">
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:text>\protect\doubleflat</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{\doubleflat}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Footnotes -->
<!-- For blocks implemented as "tcolorbox" we need to manage -->
<!-- footnotes more carefully.  Also for captions since they -->
<!-- migrate to list of figures.  At the location, we just   -->
<!-- drop a mark, with no text.  Testing with the "footmisc" -->
<!-- package, and its "\mpfootnotemark" alternative works    -->
<!-- worse than simple default LaTeX (though the numbers     -->
<!-- could be hard-coded if necessary).                      -->
<!-- NB: (2020-11-15) New environments may mean there is no  -->
<!-- migration to the *.aux file, hence the \protect may not -->
<!-- be necessary.                                           -->
<!-- 2023-06-03: one of REMARK-LIKE is a "note", but we also -->
<!-- have, from long ago, a biblio/note.  So a footnote      -->
<!-- inside a  biblio/note  was being caught here and        -->
<!-- producing a \footnotemark{}.  However, there was no     -->
<!-- matching  \footnotetext  since "biblio" is not yet a    -->
<!-- tcolorbox and the "pop-footnote-text" template was not  -->
<!-- present as part of processing  biblio/note.             -->
<xsl:template match="fn">
    <xsl:choose>
        <xsl:when test="ancestor::*[&ASIDE-FILTER; or &THEOREM-FILTER; or &AXIOM-FILTER;  or &DEFINITION-FILTER; or &REMARK-FILTER; or &COMPUTATION-FILTER; or &OPENPROBLEM-FILTER; or &EXAMPLE-FILTER; or &PROJECT-FILTER; or &GOAL-FILTER; or &FIGURE-FILTER; or self::tabular or self::list or self::sidebyside or self::gi or self::colophon/parent::backmatter or self::assemblage or self::exercise or (self::li and parent::dl)] and not(ancestor::note/parent::biblio)">
            <!-- a footnote in the text of a caption will migrate to -->
            <!-- the auxiliary file for use in the "list of figures" -->
            <!-- and there is some confusion of braces and the use   -->
            <!-- of \footnote and \footnotemark, hence a \protect    -->
            <!-- https://tex.stackexchange.com/questions/10181       -->
            <xsl:if test="ancestor::*[&FIGURE-FILTER;]">
                <xsl:text>\protect</xsl:text>
            </xsl:if>
            <xsl:text>\footnotemark{}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\footnote{</xsl:text>
            <xsl:apply-templates/>
            <xsl:apply-templates select="." mode="label" />
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Part 2: for items implemented as "tcolorbox", and other       -->
<!-- environments that could harbor a footnote, such as            -->
<!-- "figure", "table", "tabular", etc., we scan back              -->
<!-- through the contents, formulating the text of footnotes,      -->
<!-- in order.  It is necessary to hard-code the (serial) number   -->
<!-- of the footnote since otherwise the numbering gets confused   -->
<!-- by an intervening "tcolorbox".  The template should be placed -->
<!-- immediately after the "\end{}" of affected environments.      -->
<!-- It will format as one footnote text per output line.          -->
<!--                                                               -->
<!-- We need to pop all interior footnotes iff we are free of      -->
<!-- enclosing blocks implemented with tcolorbox.  So this         -->
<!-- template is called at the end of a template for a block,      -->
<!-- but after the tcolorbox closes.  So we are in the clear when  -->
<!-- no ancestors are implmented by tcolorbox.  Otherwise, we      -->
<!-- "wait" and pop all interior footnotes later.                  -->
<!-- NB: these templates could be improved with an entity          -->
<xsl:template match="&ASIDE-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&DEFINITION-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&OPENPROBLEM-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&FIGURE-LIKE;|tabular|list|sidebyside|gi|&GOAL-LIKE;|backmatter/colophon|assemblage|exercise|dl/li" mode="pop-footnote-text">
    <xsl:if test="count(ancestor::*[&ASIDE-FILTER; or &THEOREM-FILTER; or &AXIOM-FILTER;  or &DEFINITION-FILTER; or &REMARK-FILTER; or &COMPUTATION-FILTER; or &EXAMPLE-FILTER; or &PROJECT-FILTER; or &GOAL-FILTER; or &FIGURE-FILTER; or self::tabular or self::list or self::sidebyside or self::gi or self::colophon/parent::backmatter or self::assemblage or self::exercise or (self::li and parent::dl)]) = 0">
        <xsl:for-each select=".//fn">
            <xsl:text>\footnotetext[</xsl:text>
            <xsl:apply-templates select="." mode="serial-number"/>
            <xsl:text>]</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:apply-templates/>
            <xsl:apply-templates select="." mode="label" />
            <xsl:text>}%&#xa;</xsl:text>
        </xsl:for-each>
    </xsl:if>
</xsl:template>

<!-- TEMPORARILY: render a glossary "headnote" as an "introduction" -->
<xsl:template match="glossary/headnote">
    <xsl:text>%% this should be a new (isomorphic) "headnote" environment&#xa;</xsl:text>
    <xsl:text>\begin{introduction}{}%&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>\end{introduction}%&#xa;</xsl:text>
</xsl:template>

<!-- Defined Terms, in a Glossary -->
<xsl:template match="gi">
    <xsl:text>\begin{glossaryitem}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id"/>
    <xsl:text>}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>\end{glossaryitem}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- ############################ -->
<!-- Literate Programming Support -->
<!-- ############################ -->

<!-- A fragment has contents, and may also be a root (file) node -->
<xsl:template match="fragment">
    <xsl:text>\par\medskip%&#xa;</xsl:text>
    <!-- always possible to label (universal PTX capability) -->
    <xsl:text>\noindent\phantomsection</xsl:text>
    <xsl:apply-templates select="." mode="label"/>
    <xsl:call-template name="langle-character"/>
    <xsl:apply-templates select="." mode="number"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:call-template name="rangle-character"/>
    <xsl:text> </xsl:text>
    <xsl:call-template name="inline-math-wrapper">
        <xsl:with-param name="math" select="'\equiv'"/>
    </xsl:call-template>
    <!-- sortby first, @ separator, then tt version -->
    <xsl:text>\index{</xsl:text>
    <xsl:value-of select="@xml:id" />
    <xsl:text>@</xsl:text>
    <xsl:value-of select="@xml:id" />
    <xsl:text>}</xsl:text>
    <xsl:text>\\&#xa;</xsl:text>
    <!-- special case, root node with filename -->
    <xsl:if test="@filename">
        <xsl:text>Root of file: </xsl:text>
        <xsl:text>\mono{</xsl:text>
        <xsl:value-of select="@filename" />
        <xsl:text>}</xsl:text>
        <xsl:text>\index{file root!\mono{</xsl:text>
        <xsl:value-of select="@filename" />
        <xsl:text>}}</xsl:text>
        <xsl:text>\\&#xa;</xsl:text>
    </xsl:if>
    <!-- now the guts, two different types of pieces -->
    <xsl:apply-templates select="code|fragref"/>
</xsl:template>

<!-- wrap code in a Verbatim environment, though perhaps another -->
<!-- LaTeX environment or a tcolor box would work better         -->
<!-- Simple \mono{} needs escapes, won't line break              -->
<!-- Drop whitespace only text() nodes                           -->
<xsl:template match="fragment/code">
    <xsl:variable name="normalized-frag" select="normalize-space(.)"/>
    <xsl:if test="not($normalized-frag = '')">
        <xsl:text>\begin{preformatted}</xsl:text>
        <xsl:text>&#xa;</xsl:text>  <!-- required by fancyvrb -->
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
        <xsl:text>\end{preformatted}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- A "fragref" has a @ref that is simply a pointer to another fragment, -->
<!-- so convert to a visual representation of a pointer to a target,      -->
<!-- with a hyperlink to the target (as a page number for print)          -->
<xsl:template match="fragref">
    <xsl:variable name="target" select="id(@ref)"/>
    <xsl:call-template name="langle-character"/>
    <xsl:apply-templates select="$target" mode="title-full"/>
    <xsl:text> </xsl:text>
    <xsl:text>{\scriptsize </xsl:text>
    <xsl:apply-templates select="$target" mode="number"/>
    <xsl:text>\space[\pageref{</xsl:text>
    <xsl:apply-templates select="$target" mode="unique-id"/>
    <xsl:text>}]</xsl:text>
    <xsl:text>}</xsl:text>
    <xsl:call-template name="rangle-character"/>
    <xsl:text>\\&#xa;</xsl:text>
</xsl:template>

<!-- ################### -->
<!-- References Sections -->
<!-- ################### -->

<!-- We use description lists to manage bibliographies,  -->
<!-- and \bibitem seems comfortable there, so our source -->
<!-- is nearly compatible with the usual usage           -->

<!-- We open and close a single "referencelist" environment,    -->
<!-- which we create in the preamble.  It opens right after     -->
<!-- a "references" division, or after optional "introduction". -->
<!-- It closes right before the "references" division closes,   -->
<!-- or right before the "conclusion" begins.  The templates    -->
<!-- below ensure consistency, and help with overrides.  You    -->
<!-- can search on them to see the two pairs of scenarios       -->
<!-- just described.                                            -->

<xsl:template name="open-reference-list">
    <xsl:text>%% If this is a top-level references&#xa;</xsl:text>
    <xsl:text>%%   you can replace the "referencelist" environment&#xa;</xsl:text>
    <xsl:text>%%   with a standard "thebibliography" environment&#xa;</xsl:text>
    <xsl:text>\begin{referencelist}&#xa;</xsl:text>
</xsl:template>

<xsl:template name="close-reference-list">
    <xsl:text>\end{referencelist}&#xa;</xsl:text>
</xsl:template>

<!-- As an item of a description list, but compatible        -->
<!-- with the  thebibliography  environment.                 -->
<!-- Note: matching "bibentry" happens within the common     -->
<!-- templates, which in turn employs this wrapper template. -->
<xsl:template match="biblio" mode="bibentry-wrapper">
    <xsl:param name="content"/>

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
    <xsl:copy-of select="$content"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Implement abstract templates to support      -->
<!-- formatting of bibliographic entries in HTML. -->

<xsl:template match="*" mode="italic">
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="*" mode="bold">
    <xsl:text>\textbf{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- \mono{} macro *always* defined in preamble -->
<xsl:template match="*" mode="monospace">
    <xsl:text>\mono{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template name="biblio-period">
    <xsl:text>.\@</xsl:text>
</xsl:template>

<!-- Annotated Bibliography Items -->
<!--   Presumably just paragraphs, nothing too complicated -->
<!--   We first close off the citation itself -->
<xsl:template match="biblio/note">
    <xsl:text>\par</xsl:text>
    <xsl:apply-templates select="." mode="optional-label"/>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates/>
</xsl:template>

<!-- ############### -->
<!-- Text Processing -->
<!-- ############### -->

<!-- The general template for matching "text()" nodes will     -->
<!-- apply this template (there is a hook there).  Verbatim    -->
<!-- text should be manipulated in templates with              -->
<!-- "xsl:value-of" and so not come through here.  Conversely, -->
<!-- when "xsl:apply-templates" is applied, the template will  -->
<!-- have effect.                                              -->
<!--                                                           -->
<!-- Our emphasis originally is on escaping characters that    -->
<!-- LaTeX has hijacked for special purposes.  First we define -->
<!-- some variables globally, so it is only necessary once.    -->

<!-- Following for disruption of "TeX ligatures"           -->
<!-- Second two are necessary to avoid XML quote confusion -->
<xsl:variable name="double-hyphen">
    <text>--</text>
</xsl:variable>
<xsl:variable name="double-hyphen-replacement">
    <text>-{}-{}</text>
</xsl:variable>

<xsl:variable name="double-apostrophe">
    <text>''</text>
</xsl:variable>
<xsl:variable name="double-apostrophe-replacement">
    <text>'{}'{}</text>
</xsl:variable>

<xsl:template name="text-processing">
    <xsl:param name="text"/>
    <!-- LaTeX's 10 reserved characters:  # $ % ^ & _ { } ~ \          -->
    <!-- We allow these in source, but must *always* escape them       -->
    <!--                                                               -->
    <!-- Strategy: replacements for backslash and braces use all       -->
    <!-- three characters, so it can be circular to just plow through  -->
    <!-- them.  We replace the backslash, then do replacements for the -->
    <!-- braces.  But we leave off the ending empty-group protection.  -->
    <!-- A second pass will never accidentally match remaining source  -->
    <!-- text due to the backslash replacements, so we safely place    -->
    <!-- the groups as pairs of braces.                                -->
    <!--                                                               -->
    <!-- This involves just one more search/replace than a previous    -->
    <!-- strategy that used a risky "unique string" strategy.          -->
    <!-- (Discussion referenced in "escape-text-to-latex" template)    -->

    <xsl:variable name="bs-one" select="str:replace($text,   '\', '\textbackslash')"/>
    <xsl:variable name="lb-one" select="str:replace($bs-one, '{', '\textbraceleft')"/>
    <xsl:variable name="rb-one" select="str:replace($lb-one, '}', '\textbraceright')"/>

    <xsl:variable name="bs-two" select="str:replace($rb-one, '\textbackslash',  '\textbackslash{}')"/>
    <xsl:variable name="lb-two" select="str:replace($bs-two, '\textbraceleft',  '\textbraceleft{}')"/>
    <xsl:variable name="rb-two" select="str:replace($lb-two, '\textbraceright', '\textbraceright{}')"/>

    <xsl:variable name="amp-fixed"        select="str:replace($rb-two,           '&amp;', '\&amp;')"/>
    <xsl:variable name="hash-fixed"       select="str:replace($amp-fixed,        '#',     '\#')"/>
    <xsl:variable name="dollar-fixed"     select="str:replace($hash-fixed,       '$',     '\textdollar{}')"/>
    <xsl:variable name="percent-fixed"    select="str:replace($dollar-fixed,     '%',     '\%')"/>
    <xsl:variable name="circumflex-fixed" select="str:replace($percent-fixed,    '^',     '\textasciicircum{}')"/>
    <xsl:variable name="underscore-fixed" select="str:replace($circumflex-fixed, '_',     '\textunderscore{}')"/>
    <xsl:variable name="tilde-fixed"      select="str:replace($underscore-fixed, '~',     '\textasciitilde{}')"/>

    <!-- These are characters improved by LaTeX versions (mostly from textcomp)                 -->
    <!-- \slash is important since it allows line-breaking, contrary to a bare "forward "slash" -->
    <xsl:variable name="less-fixed"     select="str:replace($tilde-fixed,    '&lt;', '\textless{}')"/>
    <xsl:variable name="greater-fixed"  select="str:replace($less-fixed,      '&gt;', '\textgreater{}')"/>
    <xsl:variable name="backtick-fixed" select="str:replace($greater-fixed,   '`',    '\textasciigrave{}')"/>
    <xsl:variable name="bar-fixed"      select="str:replace($backtick-fixed,  '|',    '\textbar{}')"/>
    <xsl:variable name="slash-fixed"    select="str:replace($bar-fixed,       '/',    '\slash{}')"/>
    <xsl:variable name="asterisk-fixed" select="str:replace($slash-fixed,     '*',    '\textasteriskcentered{}')"/>

    <!-- We disrupt certain "TeX ligatures" - combinations of keyboard -->
    <!-- characters which result in a single glyph in output           -->

    <!-- Hyphens -->
    <!-- An even number of hyphens will earn the same number of disrupting {} -->
    <!-- An odd number of hyphens will earn one less disrupting {} -->
    <!-- In particular, a single hyphen gets none -->
    <xsl:variable name="hyphen-fixed"    select="str:replace($asterisk-fixed, $double-hyphen, $double-hyphen-replacement)"/>

    <!-- Apostrophes -->
    <!-- Should not be combined in pairs to become a single right -->
    <!-- smart quote. Strategy is the same as for hyphens         -->
    <xsl:variable name="apostrophe-fixed" select="str:replace($hyphen-fixed, $double-apostrophe, $double-apostrophe-replacement)"/>

    <!-- Backticks -->
    <!-- Should not be combined in pairs to become a single left smart -->
    <!-- quote.  Replacement above by a macro will prevent this.       -->

    <!-- Currency -->
    <!-- Dollar is processed above.  13 other currencies seem to     -->
    <!-- behave just fine with our defaults, when simply entered     -->
    <!-- by their Unicode numbers, though each could be replaced     -->
    <!-- by a textcomp version, which we have elected to skirt until -->
    <!-- necessary.  The one exception is the Paraguayan guarani.    -->

    <!-- Paraguayan guarani -->
    <xsl:variable name="guarani-fixed" select="str:replace($apostrophe-fixed, '&#x20b2;', '\textguarani')"/>

    <xsl:value-of select="$guarani-fixed"/>
</xsl:template>


<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->

<!-- "escape-latex-special-chars"                          -->
<!-- Escape for the Latex 10 special characters            -->
<!-- First define the replacements. These must be in       -->
<!-- order as search + replace pairs                       -->
<xsl:variable name="latex-replacements">
    <search>\</search>
    <replace>\\</replace>
    <search>&amp;</search>
    <replace>\&amp;</replace>
    <search>%</search>
    <replace>\%</replace>
    <search>$</search>
    <replace>\$</replace>
    <search>#</search>
    <replace>\#</replace>
    <search>_</search>
    <replace>\_</replace>
    <search>{</search>
    <replace>\{</replace>
    <search>}</search>
    <replace>\}</replace>
    <search>~</search>
    <replace>\~</replace>
    <search>^</search>
    <replace>\^</replace>
</xsl:variable>
<xsl:variable name="latex-replacements-search-set" select="exsl:node-set($latex-replacements)/search" />
<xsl:variable name="latex-replacements-replace-set" select="exsl:node-set($latex-replacements)/replace" />
<xsl:template name="escape-latex-special-chars">
    <xsl:param name="text"/>
    <xsl:value-of select="str:replace($text, $latex-replacements-search-set, $latex-replacements-replace-set)" />
</xsl:template>

<!-- Escape URL Text as LaTeX -->
<!-- Slash first, so don't clobber later additions    -->
<!-- Double-quote is problematic in LaTeX, and also   -->
<!-- in strings below, so use &#x22; it's hex Unicode -->
<!--     \ & # % ~ { } "                              -->
<!-- no problem yet with math underscore or caret     -->
<!-- (a text-only template, but LaTeX-specific)       -->
<!-- This is a subset of following utility, certain   -->
<!-- substitutions (such as \textsinglequote) will    -->
<!-- foul up the applications of this cleaner.        -->
<xsl:template name="escape-url-to-latex">
    <xsl:param    name="text" />

    <xsl:variable name="sans-slash" select="str:replace($text,       '\',      '\\'      )" />
    <xsl:variable name="sans-amp"   select="str:replace($sans-slash, '&amp;',  '\&amp;'  )" />
    <xsl:variable name="sans-hash"  select="str:replace($sans-amp,   '#',      '\#'      )" />
    <xsl:variable name="sans-per"   select="str:replace($sans-hash,  '%',      '\%'      )" />
    <xsl:variable name="sans-tilde" select="str:replace($sans-per,   '~',      '\~'      )" />
    <xsl:variable name="sans-open"  select="str:replace($sans-tilde, '{',      '\{'      )" />
    <xsl:variable name="sans-close" select="str:replace($sans-open,  '}',      '\}'      )" />
    <xsl:variable name="sans-quote" select="str:replace($sans-close, '&#x22;', '\&#x22;' )" />
    <xsl:value-of select="$sans-quote" />
</xsl:template>

<!-- Necessary for next template, defined globally -->
<xsl:variable name="sq">
    <xsl:text>'</xsl:text>
</xsl:variable>
<xsl:variable name="dq">
    <xsl:text>"</xsl:text>
</xsl:variable>

<!-- Author's Inline Verbatim to Escaped LaTeX -->
<!-- 10 wicked LaTeX characters:   & % $ # _ { } ~ ^ \.    -->
<!-- Plus single quote, double quote, and backtick.        -->
<!-- \, {, } all need replacement, and also occur in some  -->
<!-- replacements.  So order, and some care, is necessary. -->
<!-- Generally this is a "cleaner" template , prior  to    -->
<!--wrapping in our \mono macro, implemented with \texttt. -->
<!-- http://tex.stackexchange.com/questions/34580/         -->
<xsl:template name="escape-text-to-latex">
    <xsl:param    name="text" />

    <!-- See "text-processing" for discussion of a very similar strategy -->

    <xsl:variable name="bs-one" select="str:replace($text,   '\', '\textbackslash')"/>
    <xsl:variable name="lb-one" select="str:replace($bs-one, '{', '\textbraceleft')"/>
    <xsl:variable name="rb-one" select="str:replace($lb-one, '}', '\textbraceright')"/>

    <xsl:variable name="bs-two" select="str:replace($rb-one, '\textbackslash',  '\textbackslash{}')"/>
    <xsl:variable name="lb-two" select="str:replace($bs-two, '\textbraceleft',  '\{')"/>
    <xsl:variable name="rb-two" select="str:replace($lb-two, '\textbraceright', '\}')"/>

    <xsl:variable name="sans-amp"   select="str:replace($rb-two,      '&amp;', '\&amp;'  )" />
    <xsl:variable name="sans-hash"  select="str:replace($sans-amp,    '#',     '\#'      )" />
    <xsl:variable name="sans-per"   select="str:replace($sans-hash,   '%',     '\%'      )" />
    <xsl:variable name="sans-tilde" select="str:replace($sans-per,    '~',     '\textasciitilde{}')" />
    <xsl:variable name="sans-dollar" select="str:replace($sans-tilde, '$',     '\$' )" />
    <xsl:variable name="sans-under" select="str:replace($sans-dollar, '_',     '\_'      )" />
    <xsl:variable name="sans-caret" select="str:replace($sans-under,  '^',     '\textasciicircum{}')" />
    <xsl:variable name="sans-quote" select="str:replace($sans-caret,  $sq,     '\textquotesingle{}')" />
    <xsl:variable name="sans-dblqt" select="str:replace($sans-quote,  $dq,     '\textquotedbl{}')" />
    <xsl:value-of select="str:replace($sans-dblqt,  '`',     '\textasciigrave{}')" />
</xsl:template>

<!-- Escape Console Input to Latex -->
<!-- The entire input string is bolded, but now we have escaped     -->
<!-- into LaTeX for the entire string.  So we need to               -->
<!--   (1) Escape the usual problematic characters into their LaTeX -->
<!--       text equivalents.                                        -->
<!--   (2) Convert the "listings" escape sequence into something    -->
<!--       isomorphic, but not equal, in LaTeX.  We do this by      -->
<!--       adding an empty group to the escape sequences.           -->
<xsl:template name="escape-console-input-to-latex">
    <xsl:param name="text" />

    <xsl:variable name="all-latex">
        <xsl:call-template name="escape-text-to-latex">
            <xsl:with-param name="text" select="$text"/>
        </xsl:call-template>
    </xsl:variable>
    <!-- A trailing group seems necessary on the opening escape -->
    <!-- sequence, otherwise a trailing spce goes missing.      -->
    <!-- We add this to the closing sequence just in case.      -->
    <xsl:variable name="left-escape"  select="str:replace($all-latex, '(*', '({}*{}' )"/>
    <xsl:variable name="right-escape" select="str:replace($left-escape, '*)', '*{}){}' )"/>
    <xsl:value-of select="$right-escape"/>
</xsl:template>

<!-- Escape Console Text -->
<!-- The prefix and output for a "console" are handled capably by the   -->
<!-- "listings" package.  Except we need to break the escape characters -->
<!-- we use to accomodate bold text for the input.  So...we escape into -->
<!-- LaTeX mode, duplicate the desired sequence, and break it with an   -->
<!-- empty group.  Presumably no additional empty groups are necessary. -->
<!-- The usual three-step in necessary to not clobber earlier edits,    -->
<!-- we did not figure out a clever way to avoid a "unique" string.     -->
<xsl:template name="escape-console-prefix-output">
    <xsl:param name="text" />

    <xsl:variable name="left-escape-temp"  select="str:replace($text, '(*', 'XXvVY4DtfemxHkcXX' )"/>
    <xsl:variable name="right-escape" select="str:replace($left-escape-temp, '*)', '(**{})*)' )"/>
    <xsl:variable name="left-escape" select="str:replace($right-escape, 'XXvVY4DtfemxHkcXX', '(*({}**)' )"/>
    <xsl:value-of select="$left-escape"/>
</xsl:template>

<!-- Issue check and warning, under xelatex engine, -->
<!-- for a font missing from a system               -->
<xsl:template name="xelatex-font-check">
    <xsl:param name="font-name"/>

    <xsl:text>\IfFontExistsTF{</xsl:text>
    <xsl:value-of select="$font-name"/>
    <xsl:text>}{}{\GenericError{}{The font "</xsl:text>
    <xsl:value-of select="$font-name"/>
    <xsl:text>" requested by PreTeXt output processed by the  xelatex  executable is not available.  Either a file cannot be located in default locations via a filename, or a font is not known by its name as part of your system.}{Consult the PreTeXt Guide for help with LaTeX fonts, or perhaps try using  pdflatex  as a test.}{}}&#xa;</xsl:text>
</xsl:template>

<!-- Miscellaneous -->

<!-- Inline warnings go into text, no matter what -->
<!-- They are colored for an author's report      -->
<!-- A bad xml:id might have underscores, so we   -->
<!-- sanitize the entire warning text for LaTeX   -->
<xsl:template name="inline-warning">
    <xsl:param name="warning" />
    <!-- Color for author tools version -->
    <xsl:if test="$author-tools-new = 'yes'" >
        <xsl:text>\textcolor{red}</xsl:text>
    </xsl:if>
    <xsl:text>{</xsl:text>
    <xsl:text>(((</xsl:text>
    <xsl:value-of select="str:replace($warning, '_', '\_')" />
    <xsl:text>)))</xsl:text>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Marginal notes are only for author's report          -->
<!-- and are always colored red                           -->
<!-- Marginpar's from http://www.f.kth.se/~ante/latex.php -->
<xsl:template name="margin-warning">
    <xsl:param name="warning" />
    <xsl:if test="$author-tools-new = 'yes'" >
        <xsl:text>\marginpar[\raggedleft\footnotesize\textcolor{red}{</xsl:text>
        <xsl:value-of select="$warning" />
        <xsl:text>}]{\raggedright\footnotesize\textcolor{red}{</xsl:text>
        <xsl:value-of select="$warning" />
        <xsl:text>}}</xsl:text>
    </xsl:if>
</xsl:template>


</xsl:stylesheet>
