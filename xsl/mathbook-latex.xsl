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
    extension-element-prefixes="exsl date str"
>

<xsl:import href="./mathbook-common.xsl" />

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="text" />

<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!--  -->
<!-- LaTeX executable, "engine"                       -->
<!-- pdflatex is default, xelatex or lualatex for Unicode support -->
<!-- N.B. This has no effect, and may never.  xelatex and lualatex support is automatic -->
<xsl:param name="latex.engine" select="'pdflatex'" />
<!--  -->
<!-- Standard fontsizes: 10pt, 11pt, or 12pt       -->
<!-- extsizes package: 8pt, 9pt, 14pt, 17pt, 20pt  -->
<!-- memoir class offers more, but maybe other changes? -->
<xsl:param name="latex.font.size" select="'10pt'" />
<!--  -->
<!-- Geometry: page shape, margins, etc            -->
<!-- Pass a string with any of geometry's options  -->
<!-- Default is empty and thus ineffective         -->
<!-- Otherwise, happens early in preamble template -->
<xsl:param name="latex.geometry" select="''"/>
<!--  -->
<!-- PDF Watermarking                    -->
<!-- Non-empty string makes it happen    -->
<!-- Scale works well for "CONFIDENTIAL" -->
<!-- or  for "DRAFT YYYY/MM/DD"          -->
<xsl:param name="latex.watermark" select="''"/>
<xsl:param name="latex.watermark.scale" select="2.0"/>
<!--  -->
<!-- Author's Tools                                            -->
<!-- Set the author-tools parameter to 'yes'                   -->
<!-- (Documented in mathbook-common.xsl)                       -->
<!-- Installs some LaTeX-specific behavior                     -->
<!-- (1) Index entries in margin of the page                   -->
<!--      where defined, on single pass (no real index)        -->
<!-- (2) LaTeX labels near definition and use                  -->
<!--     N.B. Some are author-defined; others are internal,    -->
<!--     and CANNOT be used as xml:id's (will raise a warning) -->
<!--  -->
<!-- Draft Copies                                              -->
<!-- Various options for working copies for authors            -->
<!-- (1) LaTeX's draft mode                                    -->
<!-- (2) Crop marks on letter paper, centered                  -->
<!--     presuming geometry sets smaller page size             -->
<!--     with paperheight, paperwidth                          -->
<xsl:param name="latex.draft" select="'no'"/>
<!--  -->
<!-- Print Option                                         -->
<!-- For a non-electronic copy, inactive links in black   -->
<!-- Any color options go to black and white, as possible -->
<xsl:param name="latex.print" select="'no'"/>
<!--  -->
<!-- Preamble insertions                    -->
<!-- Insert packages, options into preamble -->
<!-- early or late                          -->
<xsl:param name="latex.preamble.early" select="''" />
<xsl:param name="latex.preamble.late" select="''" />
<!--  -->
<!-- DEPRECATED: 2017-12-18, do not use, any value -->
<!-- besides an empty string will raise a warning  -->
<xsl:param name="latex.console.macro-char" select="''" />
<xsl:param name="latex.console.begin-char" select="''" />
<xsl:param name="latex.console.end-char" select="''" />

<!-- We have to identify snippets of LaTeX from the server,   -->
<!-- which we have stored in a directory, because XSLT 1.0    -->
<!-- is unable/unwilling to figure out where the source file  -->
<!-- lives (paths are relative to the stylesheet).  When this -->
<!-- is needed a fatal message will warn if it is not set.    -->
<!-- Path ends with a slash, anticipating appended filename   -->
<!-- This could be overridden in a compatibility layer        -->
<xsl:param name="webwork.server.latex" select="''" />


<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<!-- Variables that affect LaTeX creation -->
<!-- More in the common file              -->

<!-- LaTeX is handled natively, so we flip a  -->
<!-- switch here to signal the general text() -->
<!-- handler in xsl/mathbook-common.xsl to    -->
<!-- not dress-up clause-ending punctuation   -->
<xsl:variable name="latex-processing" select="'native'" />

<!-- We generally want one large complete LaTeX file -->
<xsl:variable name="chunk-level">
    <xsl:choose>
        <xsl:when test="$chunk.level != ''">
            <xsl:message terminate="yes">MBX:ERROR:   chunking of LaTeX output is deprecated as of 2016-06-10, remove the "chunk.level" stringparam</xsl:message>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>0</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

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
<xsl:variable name="toc-level">
    <xsl:choose>
        <xsl:when test="$toc.level != ''">
            <xsl:value-of select="$toc.level" />
        </xsl:when>
        <xsl:when test="$root/book/article">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Table of Contents level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- font-size also dictates document class for -->
<!-- those provided by extsizes, but we can get -->
<!-- these by just inserting the "ext" prefix   -->
<!-- We don't load the package, the classes     -->
<!-- are incorporated in the documentclass[]{}  -->
<!-- and only if we need the extreme values     -->

<!-- Default is 10pt above, this stupid template     -->
<!-- provides an error message and also sets a value -->
<!-- we can condition on for the extsizes package.   -->
<!-- In predicted order, sort of, so fall out early  -->
<xsl:variable name="font-size">
    <xsl:choose>
        <xsl:when test="$latex.font.size='10pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='12pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='11pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='8pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='9pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='14pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='17pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='20pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="yes">MBX:ERROR   the latex.font.size parameter must be 8pt, 9pt, 10pt, 11pt, 12pt, 14pt, 17pt, or 20pt, not "<xsl:value-of select="$latex.font.size" />"</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

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

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:apply-templates select="mathbook|pretext" mode="generic-warnings" />
    <xsl:apply-templates select="mathbook|pretext" mode="deprecation-warnings" />
    <xsl:apply-templates select="mathbook|pretext" mode="deprecation-warnings-latex" />
    <xsl:apply-templates />
</xsl:template>

<!-- We will have just one of the following -->
<!-- and totally ignore docinfo             -->
<xsl:template match="/mathbook|/pretext">
    <xsl:variable name="filename">
        <xsl:apply-templates select="article|book|letter|memo" mode="internal-id" />
        <xsl:text>.tex</xsl:text>
    </xsl:variable>
    <exsl:document href="{$filename}" method="text">
        <xsl:apply-templates select="article|book|letter|memo"/>
    </exsl:document>
</xsl:template>

<!-- TODO: combine article, book, letter, templates -->
<!-- with abstract templates for latex classes, page sizes -->

<!-- An article, LaTeX structure -->
<!--     One page, full of sections (with abstract, references)                    -->
<!--     Or, one page, totally unstructured, just lots of paragraphs, widgets, etc -->
<xsl:template match="article">
    <xsl:call-template name="converter-blurb-latex" />
    <xsl:text>\documentclass[</xsl:text>
    <xsl:value-of select="$font-size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$latex.draft='yes'" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$document-class-prefix" />
    <xsl:text>article}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <!-- parameterize preamble template with "page-geometry" template conditioned on self::article etc -->
    <xsl:call-template name="title-page-info-article" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <!-- Target for xref to top-level element -->
    <!-- immediately, or first in ToC         -->
    <xsl:choose>
        <xsl:when test="$b-has-toc">
            <xsl:text>%% Target for xref to top-level element is ToC&#xa;</xsl:text>
            <xsl:text>\addtocontents{toc}{\protect\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>}{}}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>%% Target for xref to top-level element is document start&#xa;</xsl:text>
            <xsl:text>\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
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
    <xsl:apply-templates />
   <xsl:text>\end{document}</xsl:text>
</xsl:template>

<!-- A book, LaTeX structure -->
<!-- The ordering of the frontmatter is from             -->
<!-- "Bookmaking", 3rd Edition, Marshall Lee, Chapter 27 -->
<xsl:template match="book">
    <xsl:call-template name="converter-blurb-latex" />
    <xsl:text>\documentclass[</xsl:text>
    <xsl:value-of select="$font-size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$latex.draft='yes'" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$document-class-prefix" />
    <xsl:text>book}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:call-template name="title-page-info-book" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{document}</xsl:text>
</xsl:template>

<!-- A letter, LaTeX structure -->
<xsl:template match="letter">
    <xsl:call-template name="converter-blurb-latex" />
    <xsl:text>\documentclass[</xsl:text>
    <xsl:value-of select="$font-size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$latex.draft='yes'" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$document-class-prefix" />
    <xsl:text>article}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{document}</xsl:text>
</xsl:template>

<!-- A memo, LaTeX structure -->
<xsl:template match="memo">
    <xsl:call-template name="converter-blurb-latex" />
    <xsl:text>\documentclass[</xsl:text>
    <xsl:value-of select="$font-size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$latex.draft='yes'" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$document-class-prefix" />
    <xsl:text>article}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:text>\begin{document}&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{document}&#xa;</xsl:text>
</xsl:template>

<!-- LaTeX preamble is common for both books, articles, memos and letters -->
<!-- Except: title info allows an "event" for an article (presentation)   -->
<xsl:template name="latex-preamble">
    <xsl:text>%% Custom Preamble Entries, early (use latex.preamble.early)&#xa;</xsl:text>
    <xsl:if test="$latex.preamble.early != ''">
        <xsl:value-of select="$latex.preamble.early" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <!-- Following need to be mature, robust, powerful, flexible, well-maintained -->
    <xsl:text>%% Default LaTeX packages&#xa;</xsl:text>
    <xsl:text>%%   1.  always employed (or nearly so) for some purpose, or&#xa;</xsl:text>
    <xsl:text>%%   2.  a stylewriter may assume their presence&#xa;</xsl:text>
    <xsl:text>\usepackage{geometry}&#xa;</xsl:text>
    <xsl:text>%% Some aspects of the preamble are conditional,&#xa;</xsl:text>
    <xsl:text>%% the LaTeX engine is one such determinant&#xa;</xsl:text>
    <xsl:text>\usepackage{ifthen}&#xa;</xsl:text>
    <xsl:text>\usepackage{ifxetex,ifluatex}&#xa;</xsl:text>
    <xsl:text>%% Raster graphics inclusion&#xa;</xsl:text>
    <xsl:text>\usepackage{graphicx}&#xa;</xsl:text>
    <xsl:text>%% Colored boxes, and much more, though mostly styling&#xa;</xsl:text>
    <xsl:text>%% skins library provides "enhanced" skin, employing tikzpicture&#xa;</xsl:text>
    <xsl:text>%% boxes may be configured as "breakable" or "unbreakable"&#xa;</xsl:text>
    <xsl:text>\usepackage{tcolorbox}&#xa;</xsl:text>
    <xsl:text>\tcbuselibrary{skins}&#xa;</xsl:text>
    <xsl:text>\tcbuselibrary{breakable}&#xa;</xsl:text>
    <xsl:text>%% Hyperref should be here, but likes to be loaded late&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% Inline math delimiters, \(, \), need to be robust&#xa;</xsl:text>
    <xsl:text>%% 2016-01-31:  latexrelease.sty  supersedes  fixltx2e.sty&#xa;</xsl:text>
    <xsl:text>%% If  latexrelease.sty  exists, bugfix is in kernel&#xa;</xsl:text>
    <xsl:text>%% If not, bugfix is in  fixltx2e.sty&#xa;</xsl:text>
    <xsl:text>%% See:  https://tug.org/TUGboat/tb36-3/tb114ltnews22.pdf&#xa;</xsl:text>
    <xsl:text>%% and read "Fewer fragile commands" in distribution's  latexchanges.pdf&#xa;</xsl:text>
    <xsl:text>\IfFileExists{latexrelease.sty}{}{\usepackage{fixltx2e}}&#xa;</xsl:text>
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
    <xsl:text>%% Custom Page Layout Adjustments (use latex.geometry)&#xa;</xsl:text>
    <xsl:if test="$latex.geometry != ''">
        <xsl:text>\geometry{</xsl:text>
        <xsl:value-of select="$latex.geometry" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% This LaTeX file may be compiled with pdflatex, xelatex, or lualatex&#xa;</xsl:text>
    <xsl:text>%% The following provides engine-specific capabilities&#xa;</xsl:text>
    <xsl:text>%% Generally, xelatex and lualatex will do better languages other than US English&#xa;</xsl:text>
    <xsl:text>%% You can pick from the conditional if you will only ever use one engine&#xa;</xsl:text>
    <xsl:text>\ifthenelse{\boolean{xetex} \or \boolean{luatex}}{%&#xa;</xsl:text>
    <xsl:text>%% begin: xelatex and lualatex-specific configuration&#xa;</xsl:text>
    <xsl:text>%% fontspec package will make Latin Modern (lmodern) the default font&#xa;</xsl:text>
    <!-- http://tex.stackexchange.com/questions/115321/how-to-optimize-latin-modern-font-with-xelatex -->
    <xsl:text>\ifxetex\usepackage{xltxtra}\fi&#xa;</xsl:text>
    <xsl:text>\usepackage{fontspec}&#xa;</xsl:text>
    <xsl:text>%% realscripts is the only part of xltxtra relevant to lualatex &#xa;</xsl:text>
    <xsl:text>\ifluatex\usepackage{realscripts}\fi&#xa;</xsl:text>
    <!-- TODO: put a xelatex/lualatex font package hook here? -->
    <xsl:text>%% &#xa;</xsl:text>
    <!-- language tags appear in docinfo in renames, so be careful -->
    <xsl:text>%% Extensive support for other languages&#xa;</xsl:text>
    <xsl:text>\usepackage{polyglossia}&#xa;</xsl:text>
    <!--  -->
    <!-- US English -->
    <!-- switch to positive test once ready -->
    <xsl:if test="not($document-language = 'hu-HU')">
        <xsl:text>%% Main document language is US English&#xa;</xsl:text>
        <xsl:text>\setdefaultlanguage{english}&#xa;</xsl:text>
    </xsl:if>
    <!-- does this need a font family? -->
    <xsl:if test="$document-root//@xml:lang='en-US'">
        <xsl:text>%% Document language contains parts in US English&#xa;</xsl:text>
        <xsl:text>\setotherlanguage{english}&#xa;</xsl:text>
    </xsl:if>
    <!--  -->
    <xsl:if test="$document-root//@xml:lang='el'">
        <xsl:text>%% Greek (Modern) specified by 'el' language tag&#xa;</xsl:text>
        <xsl:text>%% Font families: CMU Serif (fonts-cmu package), Linux Libertine O, GFS Artemisia&#xa;</xsl:text>
        <!-- <xsl:text>\setotherlanguage[variant=ancient,numerals=greek]{greek}&#xa;</xsl:text> -->
        <xsl:text>\setotherlanguage{greek}&#xa;</xsl:text>
        <xsl:text>\newfontfamily\greekfont[Script=Greek]{CMU Serif}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//@xml:lang='ko-KR'">
        <xsl:text>%% Korean specified by 'ko-KR' language tag&#xa;</xsl:text>
        <xsl:text>%% Debian/Ubuntu "fonts-nanum" package&#xa;</xsl:text>
        <xsl:text>\setotherlanguage{korean}&#xa;</xsl:text>
        <xsl:text>\newfontfamily\koreanfont{NanumMyeongjo}&#xa;</xsl:text>
    </xsl:if>
    <!--  -->
    <!-- Magyar (Hungarian) -->
    <xsl:if test="$document-language = 'hu-HU'">
        <xsl:text>%% Main document language is Magyar (Hungarian)&#xa;</xsl:text>
        <xsl:text>\setdefaultlanguage{magyar}&#xa;</xsl:text>
    </xsl:if>
    <!-- does this need a font family -->
    <xsl:if test="$document-root//@xml:lang='hu-HU'">
        <xsl:text>%% Document contains parts in Magyar (Hungarian)&#xa;</xsl:text>
        <xsl:text>\setotherlanguage{magyar}&#xa;</xsl:text>
    </xsl:if>
    <!--  -->
    <xsl:if test="$document-root//@xml:lang='ru-RU'">
        <xsl:text>%% Russian specified by 'ru-RU' language tag&#xa;</xsl:text>
        <xsl:text>%% Font families: CMU Serif, Linux Libertine O&#xa;</xsl:text>
        <xsl:text>\setotherlanguage{russian}&#xa;</xsl:text>
        <xsl:text>\newfontfamily\cyrillicfont[Script=Cyrillic]{CMU Serif}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Spanish&#xa;</xsl:text>
    <xsl:text>\setotherlanguage{spanish}&#xa;</xsl:text>
    <xsl:text>%% Vietnamese&#xa;</xsl:text>
    <xsl:text>\setotherlanguage{vietnamese}&#xa;</xsl:text>
    <!-- Korean gloss file may appear soon, 2016-07-25 -->
    <!-- <xsl:text>%% Korean&#xa;</xsl:text> -->
    <!-- <xsl:text>\setotherlanguage{korean}&#xa;</xsl:text> -->
    <!-- <xsl:text>\newfontfamily\koreanfont{NanumMyeongjo}&#xa;</xsl:text> -->
    <!-- <xsl:text>\newfontfamily\koreanfont[Script=Hangul]{UnBatang}&#xa;</xsl:text> -->
    <xsl:text>%% end: xelatex and lualatex-specific configuration&#xa;</xsl:text>
    <xsl:text>}{%&#xa;</xsl:text>
    <xsl:text>%% begin: pdflatex-specific configuration&#xa;</xsl:text>
    <xsl:text>%% translate common Unicode to their LaTeX equivalents&#xa;</xsl:text>
    <xsl:text>%% Also, fontenc with T1 makes CM-Super the default font&#xa;</xsl:text>
    <!-- https://tex.stackexchange.com/questions/664/why-should-i-use-usepackaget1fontenc -->
    <!-- http://tex.stackexchange.com/questions/88368/how-do-i-invoke-cm-super -->
    <xsl:text>%% (\input{ix-utf8enc.dfu} from the "inputenx" package is possible addition (broken?)&#xa;</xsl:text>
    <xsl:text>\usepackage[T1]{fontenc}&#xa;</xsl:text>
    <xsl:text>\usepackage[utf8]{inputenc}&#xa;</xsl:text>
    <!-- TODO: put a pdflatex font package hook here? -->
    <xsl:text>%% end: pdflatex-specific configuration&#xa;</xsl:text>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:if test="$document-root//c or $document-root//cd or $document-root//pre or $document-root//program or $document-root//console or $document-root//sage">
        <xsl:text>%% Monospace font: Inconsolata (zi4)&#xa;</xsl:text>
        <xsl:text>%% Sponsored by TUG: http://levien.com/type/myfonts/inconsolata.html&#xa;</xsl:text>
        <xsl:text>%% See package documentation for excellent instructions&#xa;</xsl:text>
        <xsl:text>%% One caveat, seem to need full file name to locate OTF files&#xa;</xsl:text>
        <xsl:text>%% Loads the "upquote" package as needed, so we don't have to&#xa;</xsl:text>
        <xsl:text>%% Upright quotes might come from the  textcomp  package, which we also use&#xa;</xsl:text>
        <xsl:text>%% We employ the shapely \ell to match Google Font version&#xa;</xsl:text>
        <xsl:text>%% pdflatex: "varqu" option produces best upright quotes&#xa;</xsl:text>
        <xsl:text>%% xelatex,lualatex: add StylisticSet 1 for shapely \ell&#xa;</xsl:text>
        <xsl:text>%% xelatex,lualatex: add StylisticSet 2 for plain zero&#xa;</xsl:text>
        <xsl:text>%% xelatex,lualatex: we add StylisticSet 3 for upright quotes&#xa;</xsl:text>
        <xsl:text>%% &#xa;</xsl:text>
        <xsl:text>\ifthenelse{\boolean{xetex} \or \boolean{luatex}}{%&#xa;</xsl:text>
        <xsl:text>%% begin: xelatex and lualatex-specific monospace font&#xa;</xsl:text>
        <xsl:text>\usepackage{zi4}&#xa;</xsl:text>
        <xsl:text>\setmonofont[BoldFont=Inconsolatazi4-Bold.otf,StylisticSet={1,3}]{Inconsolatazi4-Regular.otf}&#xa;</xsl:text>
        <!-- <xsl:text>%% Mono spacing with \texttt, no extra space after period&#xa;</xsl:text> -->
        <!-- <xsl:text>\usepackage[mono,extrasp=0em]{zi4}&#xa;</xsl:text> -->
        <!-- TODO: put a xelatex/lualatex monospace font package hook here? -->
        <xsl:text>%% end: xelatex and lualatex-specific monospace font&#xa;</xsl:text>
        <xsl:text>}{%&#xa;</xsl:text>
        <xsl:text>%% begin: pdflatex-specific monospace font&#xa;</xsl:text>
        <xsl:text>%% "varqu" option provides textcomp \textquotedbl glyph&#xa;</xsl:text>
        <xsl:text>%% "varl"  option provides shapely "ell"&#xa;</xsl:text>
        <xsl:text>\usepackage[varqu,varl]{zi4}&#xa;</xsl:text>
        <!-- \@ifpackagelater: https://tex.stackexchange.com/questions/33806/is-it-possible-to-abort-loading-a-package-if-its-too-old -->
        <!-- <xsl:text>%% Mono spacing with \texttt, no extra space after period&#xa;</xsl:text> -->
        <!-- <xsl:text>\usepackage[mono,extrasp=0em]{zi4}&#xa;</xsl:text> -->
        <xsl:text>%% end: pdflatex-specific monospace font&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
        <!-- https://tex.stackexchange.com/questions/2790/when-should-one-use-verb-and-when-texttt/235917 -->
        <xsl:if test="$document-root//c">
            <xsl:text>%% \mono macro for content of "c" element only&#xa;</xsl:text>
            <xsl:text>\newcommand{\mono}[1]{\texttt{#1}}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:text>%% Symbols, align environment, bracket-matrix&#xa;</xsl:text>
    <xsl:text>\usepackage{amsmath}&#xa;</xsl:text>
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
    <xsl:if test="//m[contains(text(),'sfrac')] or //md[contains(text(),'sfrac')] or //me[contains(text(),'sfrac')] or //mrow[contains(text(),'sfrac')]">
        <xsl:text>%% xfrac package for 'beveled fractions': http://tex.stackexchange.com/questions/3372/how-do-i-typeset-arbitrary-fractions-like-the-standard-symbol-for-5-%C2%BD&#xa;</xsl:text>
        <xsl:text>\usepackage{xfrac}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%%&#xa;</xsl:text>
    <!-- load following conditionally if it presents problems -->
    <xsl:text>%% Color support, xcolor package&#xa;</xsl:text>
    <xsl:text>%% Always loaded, for: add/delete text, author tools&#xa;</xsl:text>
    <!-- Avoid option conflicts causing errors: -->
    <!-- http://tex.stackexchange.com/questions/57364/option-clash-for-package-xcolor -->
    <xsl:text>\PassOptionsToPackage{usenames,dvipsnames,svgnames,table}{xcolor}&#xa;</xsl:text>
    <xsl:text>\usepackage{xcolor}&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% Semantic Macros&#xa;</xsl:text>
    <xsl:text>%% To preserve meaning in a LaTeX file&#xa;</xsl:text>
    <xsl:text>%% Only defined here if required in this document&#xa;</xsl:text>
    <xsl:if test="$document-root//alert">
        <xsl:text>%% Used for warnings, typically bold and italic&#xa;</xsl:text>
        <xsl:text>\newcommand{\alert}[1]{\textbf{\textit{#1}}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//term">
        <xsl:text>%% Used for inline definitions of terms&#xa;</xsl:text>
        <xsl:text>\newcommand{\terminology}[1]{\textbf{#1}}&#xa;</xsl:text>
    </xsl:if>
    <!-- http://tex.stackexchange.com/questions/23711/strikethrough-text -->
    <!-- http://tex.stackexchange.com/questions/287599/thickness-for-sout-strikethrough-command-from-ulem-package -->
    <xsl:if test="$document-root//insert or $document-root//delete or $document-root//stale">
        <xsl:text>%% Edits (insert, delete), stale (irrelevant, obsolete)&#xa;</xsl:text>
        <xsl:text>%% Package: underlines and strikethroughs, no change to \emph{}&#xa;</xsl:text>
        <xsl:text>\usepackage[normalem]{ulem}&#xa;</xsl:text>
        <xsl:text>%% Rules in this package reset proportional to fontsize&#xa;</xsl:text>
        <xsl:text>%% NB: *never* reset to package default (0.4pt?) after use&#xa;</xsl:text>
        <xsl:text>%% Macros will use colors if  latex.print='no'  (the default)&#xa;</xsl:text>
        <xsl:if test="$document-root//insert">
            <xsl:text>%% Used for an edit that is an addition&#xa;</xsl:text>
            <xsl:text>\newcommand{\insertthick}{.1ex}&#xa;</xsl:text>
            <xsl:choose>
                <xsl:when test="$latex.print='yes'">
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
                <xsl:when test="$latex.print='yes'">
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
    <xsl:if test="$document-root//fillin">
        <xsl:text>%% Used for fillin answer blank&#xa;</xsl:text>
        <xsl:text>%% Argument is length in em&#xa;</xsl:text>
        <xsl:text>\newcommand{\fillin}[1]{\underline{\hspace{#1em}}}&#xa;</xsl:text>
    </xsl:if>
    <!-- lower-casing macro from: http://tex.stackexchange.com/questions/114592/force-all-small-caps -->
    <!-- Letter-spacing LaTeX: http://tex.stackexchange.com/questions/114578/tufte-running-headers-not-using-full-width-of-page -->
    <!-- PDF navigation panels has titles as simple strings,    -->
    <!-- devoid of any formatting, so we just give up, as any   -->
    <!-- attempt to use title-specific macros, \texorpdfstring, -->
    <!-- \protect, \DeclareRobustCommand does not help get      -->
    <!-- ToC, PDF navigation panel, text heading all correct    -->
    <!-- Obstacle is that sc shape does not come in bold,       -->
    <!-- http://tex.stackexchange.com/questions/17830/using-textsc-within-section -->
    <xsl:if test="$document-root//abbr">
        <xsl:text>%% Used to markup abbreviations, text or titles&#xa;</xsl:text>
        <xsl:text>%% default is small caps (Bringhurst, 4e, 3.2.2, p. 48)&#xa;</xsl:text>
        <xsl:text>%% Titles are no-ops now, see comments in XSL source&#xa;</xsl:text>
        <xsl:text>\newcommand{\abbreviation}[1]{\textsc{\MakeLowercase{#1}}}&#xa;</xsl:text>
        <xsl:text>\DeclareRobustCommand{\abbreviationintitle}[1]{\texorpdfstring{#1}{#1}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//acro">
        <xsl:text>%% Used to markup acronyms, text or titles&#xa;</xsl:text>
        <xsl:text>%% default is small caps (Bringhurst, 4e, 3.2.2, p. 48)&#xa;</xsl:text>
        <xsl:text>%% Titles are no-ops now, see comments in XSL source&#xa;</xsl:text>
        <xsl:text>\newcommand{\acronym}[1]{\textsc{\MakeLowercase{#1}}}&#xa;</xsl:text>
        <xsl:text>\DeclareRobustCommand{\acronymintitle}[1]{\texorpdfstring{#1}{#1}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//init">
        <xsl:text>%% Used to markup initialisms, text or titles&#xa;</xsl:text>
        <xsl:text>%% default is small caps (Bringhurst, 4e, 3.2.2, p. 48)&#xa;</xsl:text>
        <xsl:text>%% Titles are no-ops now, see comments in XSL source&#xa;</xsl:text>
        <xsl:text>\newcommand{\initialism}[1]{\textsc{\MakeLowercase{#1}}}&#xa;</xsl:text>
        <xsl:text>\DeclareRobustCommand{\initialismintitle}[1]{\texorpdfstring{#1}{#1}}&#xa;</xsl:text>
    </xsl:if>
    <!-- http://andrewmccarthy.ie/2014/11/06/swung-dash-in-latex/ -->
    <xsl:if test="$document-root//swungdash">
        <xsl:text>%% A character like a tilde, but different&#xa;</xsl:text>
        <xsl:text>\newcommand{\swungdash}{\raisebox{-2.25ex}{\scalebox{2}{\~{}}}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//quantity">
        <xsl:text>%% Used for units and number formatting&#xa;</xsl:text>
        <xsl:text>\usepackage[per-mode=fraction]{siunitx}&#xa;</xsl:text>
        <xsl:text>\ifxetex\sisetup{math-micro=\text{µ},text-micro=µ}\fi</xsl:text>
        <xsl:text>\ifluatex\sisetup{math-micro=\text{µ},text-micro=µ}\fi</xsl:text>
        <xsl:text>%% Common non-SI units&#xa;</xsl:text>
        <xsl:for-each select="document('mathbook-units.xsl')//base[@siunitx]">
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
    <xsl:if test="$document-root//case[@direction]">
        <xsl:text>%% Arrows for iff proofs, with trailing space&#xa;</xsl:text>
        <xsl:text>\newcommand{\forwardimplication}{($\Rightarrow$)\space\space}&#xa;</xsl:text>
        <xsl:text>\newcommand{\backwardimplication}{($\Leftarrow$)\space\space}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Subdivision Numbering, Chapters, Sections, Subsections, etc&#xa;</xsl:text>
    <xsl:text>%% Subdivision numbers may be turned off at some level ("depth")&#xa;</xsl:text>
    <xsl:text>%% A section *always* has depth 1, contrary to us counting from the document root&#xa;</xsl:text>
    <xsl:text>%% The latex default is 3.  If a larger number is present here, then&#xa;</xsl:text>
    <xsl:text>%% removing this command may make some cross-references ambiguous&#xa;</xsl:text>
    <xsl:text>%% The precursor variable $numbering-maxlevel is checked for consistency in the common XSL file&#xa;</xsl:text>
    <xsl:text>\setcounter{secnumdepth}{</xsl:text>
        <xsl:value-of select="$latex-numbering-maxlevel" />
    <xsl:text>}&#xa;</xsl:text>
    <!-- Could condition following on existence of any amsthm environment -->
    <xsl:text>%% Environments with amsthm package&#xa;</xsl:text>
    <xsl:text>%% Theorem-like environments in "plain" style, with or without proof&#xa;</xsl:text>
    <xsl:text>\usepackage{amsthm}&#xa;</xsl:text>
    <xsl:text>\theoremstyle{plain}&#xa;</xsl:text>
    <xsl:text>%% Numbering for Theorems, Conjectures, Examples, Figures, etc&#xa;</xsl:text>
    <xsl:text>%% Controlled by  numbering.theorems.level  processing parameter&#xa;</xsl:text>
    <xsl:text>%% Always need a theorem environment to set base numbering scheme&#xa;</xsl:text>
    <xsl:text>%% even if document has no theorems (but has other environments)&#xa;</xsl:text>
    <!-- http://tex.stackexchange.com/questions/155710/understanding-the-arguments-in-newtheorem-e-g-newtheoremtheoremtheoremsec/155714#155714 -->
    <xsl:text>\newtheorem{theorem}{</xsl:text>
    <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'theorem'" /></xsl:call-template>
    <xsl:text>}</xsl:text>
    <!-- See numbering-theorems variable being set in mathbook-common.xsl -->
    <xsl:if test="not($numbering-theorems = 0)">
        <xsl:text>[</xsl:text>
        <xsl:call-template name="level-to-name">
            <xsl:with-param name="level" select="$numbering-theorems" />
        </xsl:call-template>
        <xsl:text>]&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Only variants actually used in document appear here&#xa;</xsl:text>
    <xsl:text>%% Style is like a theorem, and for statements without proofs&#xa;</xsl:text>
    <xsl:text>%% Numbering: all theorem-like numbered consecutively&#xa;</xsl:text>
    <xsl:text>%% i.e. Corollary 4.3 follows Theorem 4.2&#xa;</xsl:text>
    <!-- THEOREM-LIKE blocks, environments -->
    <xsl:if test="//corollary">
        <xsl:text>\newtheorem{corollary}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'corollary'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//lemma">
        <xsl:text>\newtheorem{lemma}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'lemma'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//algorithm">
        <xsl:text>\newtheorem{algorithm}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'algorithm'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//proposition">
        <xsl:text>\newtheorem{proposition}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'proposition'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//claim">
        <xsl:text>\newtheorem{claim}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'claim'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//fact">
        <xsl:text>\newtheorem{fact}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'fact'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//identity">
        <xsl:text>\newtheorem{identity}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'identity'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <!-- AXIOM-LIKE blocks, environments -->
    <xsl:if test="//axiom">
        <xsl:text>\newtheorem{axiom}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'axiom'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//conjecture">
        <xsl:text>\newtheorem{conjecture}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'conjecture'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//principle">
        <xsl:text>\newtheorem{principle}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'principle'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//heuristic">
        <xsl:text>\newtheorem{heuristic}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'heuristic'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//hypothesis">
        <xsl:text>\newtheorem{hypothesis}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'hypothesis'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//assumption">
        <xsl:text>\newtheorem{assumption}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'assumption'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <!-- DEFINITION-LIKE blocks, environments -->
    <xsl:if test="//definition">
        <xsl:text>%% Definition-like environments, normal text&#xa;</xsl:text>
        <xsl:text>%% Numbering is in sync with theorems, etc&#xa;</xsl:text>
        <xsl:text>\theoremstyle{definition}&#xa;</xsl:text>
        <xsl:if test="//definition">
            <xsl:text>\newtheorem{definition}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'definition'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- REMARK-LIKE blocks, environments -->
    <xsl:if test="//remark or //convention or //note or //observation or //warning or //insight">
        <xsl:text>%% Remark-like environments, normal text&#xa;</xsl:text>
        <xsl:text>%% Numbering is in sync with theorems, etc&#xa;</xsl:text>
        <xsl:text>\theoremstyle{definition}&#xa;</xsl:text>
        <xsl:if test="//remark">
            <xsl:text>\newtheorem{remark}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'remark'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//convention">
            <xsl:text>\newtheorem{convention}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'convention'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//note">
            <xsl:text>\newtheorem{note}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'note'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//observation">
            <xsl:text>\newtheorem{observation}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'observation'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//warning">
            <xsl:text>\newtheorem{warning}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'warning'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//insight">
            <xsl:text>\newtheorem{insight}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'insight'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- COMPUTATION-LIKE blocks, environments -->
    <xsl:if test="//computation or //technology">
        <xsl:text>%% Computation-like environments, normal text&#xa;</xsl:text>
        <xsl:text>%% Numbering is in sync with theorems, etc&#xa;</xsl:text>
        <xsl:text>\theoremstyle{definition}&#xa;</xsl:text>
        <xsl:if test="//computation">
            <xsl:text>\newtheorem{computation}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'computation'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//technology">
            <xsl:text>\newtheorem{technology}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'technology'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- EXAMPLE-LIKE blocks, environments -->
    <xsl:if test="//example or //question or //problem">
        <xsl:text>%% Example-like environments, normal text&#xa;</xsl:text>
        <xsl:text>%% Numbering is in sync with theorems, etc&#xa;</xsl:text>
        <xsl:text>\theoremstyle{definition}&#xa;</xsl:text>
        <xsl:if test="//example">
            <xsl:text>\newtheorem{example}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'example'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//question">
            <xsl:text>\newtheorem{question}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'question'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//problem">
            <xsl:text>\newtheorem{problem}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'problem'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- PROJECT-LIKE blocks -->
    <xsl:if test="//project or //activity or //exploration or //investigation">
        <xsl:text>%% Numbering for Projects (independent of others)&#xa;</xsl:text>
        <xsl:text>%% Controlled by  numbering.projects.level  processing parameter&#xa;</xsl:text>
        <xsl:text>%% Always need a project environment to set base numbering scheme&#xa;</xsl:text>
        <xsl:text>%% even if document has no projectss (but has other blocks)&#xa;</xsl:text>
        <!-- http://tex.stackexchange.com/questions/155710/understanding-the-arguments-in-newtheorem-e-g-newtheoremtheoremtheoremsec/155714#155714 -->
        <xsl:text>\newtheorem{project}{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'project'" /></xsl:call-template>
        <xsl:text>}</xsl:text>
        <!-- See numbering-theorems variable being set in mathbook-common.xsl -->
        <xsl:if test="not($numbering-projects = 0)">
            <xsl:text>[</xsl:text>
            <xsl:call-template name="level-to-name">
                <xsl:with-param name="level" select="$numbering-projects" />
            </xsl:call-template>
            <xsl:text>]&#xa;</xsl:text>
        </xsl:if>
        <xsl:text>%% Project-like environments, normal text&#xa;</xsl:text>
        <xsl:text>\theoremstyle{definition}&#xa;</xsl:text>
        <xsl:if test="//activity">
            <xsl:text>\newtheorem{activity}[project]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'activity'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//exploration">
            <xsl:text>\newtheorem{exploration}[project]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'exploration'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//investigation">
            <xsl:text>\newtheorem{investigation}[project]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'investigation'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$document-root//assemblage">
        <xsl:text>%% begin: assemblage&#xa;</xsl:text>
        <xsl:text>%% minimally structured content, high visibility presentation&#xa;</xsl:text>
        <xsl:text>%% One optional argument (title) with default value blank&#xa;</xsl:text>
        <xsl:text>%% 3mm space below dropped title is increase over 2mm default&#xa;</xsl:text>
        <xsl:text>\newtcolorbox{assemblage}[1][]&#xa;</xsl:text>
        <xsl:text>  {breakable, skin=enhanced, arc=2ex, colback=blue!5, colframe=blue!75!black,&#xa;</xsl:text>
        <xsl:text>   colbacktitle=blue!20, coltitle=black, boxed title style={sharp corners, frame hidden},&#xa;</xsl:text>
        <xsl:text>   fonttitle=\bfseries, attach boxed title to top left={xshift=4mm,yshift=-3mm}, top=3mm, title=#1}&#xa;</xsl:text>
        <xsl:text>%% end: assemblage&#xa;</xsl:text>
    </xsl:if>
    <!-- Following chould be duplicated as three environments, perhaps with  \tcbset{}   -->
    <!-- See https://tex.stackexchange.com/questions/180898/                             -->
    <!-- (is-it-possible-to-reuse-tcolorbox-definitions-in-another-tcolorbox-definition) -->
    <xsl:if test="$document-root//aside|$document-root//historical|$document-root//biographical">
        <xsl:text>%% aside, biographical, historical environments and style&#xa;</xsl:text>
        <xsl:text>\newtcolorbox{aside}[1]&#xa;</xsl:text>
        <xsl:text>  {breakable, skin=enhanced, sharp corners, colback=blue!3, colframe=blue!50!black,&#xa;</xsl:text>
        <xsl:text>   add to width=-1ex, shadow={1ex}{-1ex}{0ex}{black!50!white},&#xa;</xsl:text>
        <xsl:text>   coltitle=black, fonttitle=\bfseries, title=#1, detach title, before upper={\tcbtitle\ \ }}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//objectives">
        <xsl:text>%% objectives: early in a subdivision, introduction/list/conclusion&#xa;</xsl:text>
        <xsl:text>%% objectives environment and style&#xa;</xsl:text>
        <xsl:text>\newenvironment{objectives}[1]{\noindent\rule{\linewidth}{0.1ex}\newline{\textbf{{\large#1}}\par\smallskip}}{\par\noindent\rule{\linewidth}{0.1ex}\par\smallskip}&#xa;</xsl:text>
    </xsl:if>
    <!-- miscellaneous, not categorized yet -->
    <xsl:if test="$document-root//exercise">
        <xsl:text>%% Numbering for inline exercises is in sync with theorems, normal text&#xa;</xsl:text>
        <xsl:text>\theoremstyle{definition}&#xa;</xsl:text>
        <xsl:text>\newtheorem{exercise}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'exercise'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//list">
        <xsl:text>%% named list environment and style&#xa;</xsl:text>
        <xsl:text>\newtcolorbox{namedlistcontent}&#xa;</xsl:text>
        <xsl:text>  {breakable, skin=enhanced, sharp corners, colback=white, colframe=black,&#xa;</xsl:text>
        <xsl:text>   boxrule=0.15ex, left skip=3ex, right skip=3ex}&#xa;</xsl:text>
    </xsl:if>
    <!-- Localize various standard names in use         -->
    <!-- Many environments addressed upon creation above -->
    <!-- Figure and Table addressed elsewhere           -->
    <!-- Index, table of contents done elsewhere        -->
    <!-- http://www.tex.ac.uk/FAQ-fixnam.html           -->
    <!-- http://tex.stackexchange.com/questions/62020/how-to-change-the-word-proof-in-the-proof-environment -->
    <xsl:text>%% Localize LaTeX supplied names (possibly none)&#xa;</xsl:text>
    <!-- Localize AMS "proof" environment -->
    <xsl:if test="//proof">
        <xsl:text>\renewcommand*{\proofname}{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'proof'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//appendix">
        <xsl:text>\renewcommand*{\appendixname}{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'appendix'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$root/book">
        <xsl:if test="//part">
            <xsl:text>\renewcommand*{\partname}{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'part'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//chapter">
            <xsl:text>\renewcommand*{\chaptername}{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'chapter'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$root/article">
        <xsl:if test="//abstract">
            <xsl:text>\renewcommand*{\abstractname}{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'abstract'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- Numbering Equations -->
    <!-- See numbering-equations variable being set in mathbook-common.xsl         -->
    <!-- With number="yes|no" on mrow, we must allow for the possibility of an md  -->
    <!-- variant having numbers (we could be more careful, but it is not critical) -->
    <xsl:if test="//men|//mdn|//md">
        <xsl:text>%% Equation Numbering&#xa;</xsl:text>
        <xsl:text>%% Controlled by  numbering.equations.level  processing parameter&#xa;</xsl:text>
        <xsl:text>\numberwithin{equation}{</xsl:text>
        <xsl:call-template name="level-to-name">
            <xsl:with-param name="level" select="$numbering-equations" />
        </xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <!-- Tables -->
    <xsl:if test="//tabular">
        <xsl:text>%% For improved tables&#xa;</xsl:text>
        <xsl:text>\usepackage{array}&#xa;</xsl:text>
        <xsl:text>%% Some extra height on each row is desirable, especially with horizontal rules&#xa;</xsl:text>
        <xsl:text>%% Increment determined experimentally&#xa;</xsl:text>
        <xsl:text>\setlength{\extrarowheight}{0.2ex}&#xa;</xsl:text>
        <xsl:text>%% Define variable thickness horizontal rules, full and partial&#xa;</xsl:text>
        <xsl:text>%% Thicknesses are 0.03, 0.05, 0.08 in the  booktabs  package&#xa;</xsl:text>
        <xsl:text>\makeatletter&#xa;</xsl:text>
        <!-- http://tex.stackexchange.com/questions/119153/table-with-different-rule-widths -->
        <xsl:text>\newcommand{\hrulethin}  {\noalign{\hrule height 0.04em}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\hrulemedium}{\noalign{\hrule height 0.07em}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\hrulethick} {\noalign{\hrule height 0.11em}}&#xa;</xsl:text>
        <!-- TeX produced by a WeBWorK server may contain these booktabs table rule commands  -->
        <xsl:if test="//webwork[@source]">
            <xsl:text>% TeX imported from a WeBWorK server might use booktabs rule commands&#xa;</xsl:text>
            <xsl:text>% Replace/delete these three approximations if booktabs is loaded&#xa;</xsl:text>
            <xsl:text>\newcommand{\toprule}{\hrulethick}&#xa;</xsl:text>
            <xsl:text>\newcommand{\midrule}{\hrulemedium}&#xa;</xsl:text>
            <xsl:text>\newcommand{\bottomrule}{\hrulethick}&#xa;</xsl:text>
        </xsl:if>
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
        <xsl:text>\makeatother&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//cell/line">
        <xsl:text>\newcommand{\tablecelllines}[3]%&#xa;</xsl:text>
        <xsl:text>{\begin{tabular}[#2]{@{}#1@{}}#3\end{tabular}}&#xa;</xsl:text>
    </xsl:if>
    <!-- Float package allows for placment [H]ere                    -->
    <!-- Numbering happens along with theorem counter above,         -->
    <!-- but could be done with caption package hook, see both       -->
    <!-- New names are necessary to make "within" numbering possible -->
    <!-- http://tex.stackexchange.com/questions/127914/custom-counter-steps-twice-when-invoked-from-caption-using-caption-package -->
    <!-- http://tex.stackexchange.com/questions/160207/side-effect-of-caption-package-with-custom-counter                         -->
    <xsl:if test="$document-root//figure | $document-root//table | $document-root//listing | $document-root//list">
        <xsl:text>%% Figures, Tables, Listings, Named Lists, Floats&#xa;</xsl:text>
        <xsl:text>%% The [H]ere option of the float package fixes floats in-place,&#xa;</xsl:text>
        <xsl:text>%% in deference to web usage, where floats are totally irrelevant&#xa;</xsl:text>
        <xsl:text>%% You can remove some of this setup, to restore standard LaTeX behavior&#xa;</xsl:text>
        <xsl:text>%% HOWEVER, numbering of figures/tables AND theorems/examples/remarks, etc&#xa;</xsl:text>
        <xsl:text>%% may de-synchronize with the numbering in the HTML version&#xa;</xsl:text>
        <xsl:text>%% You can remove the "placement={H}" option to allow flotation and&#xa;</xsl:text>
        <xsl:text>%% preserve numbering, BUT the numbering may then appear "out-of-order"&#xa;</xsl:text>
        <xsl:text>%% Floating environments: http://tex.stackexchange.com/questions/95631/&#xa;</xsl:text>
        <!-- Float package defines the "H" specifier                       -->
        <!-- TODO: could conditionally load  float  for tables and figures -->
        <xsl:text>\usepackage{float}&#xa;</xsl:text>
        <!-- newfloat  package has \SetupFloatingEnvironment                -->
        <!-- \DeclareCaptionType is an undocumented command,                -->
        <!-- available in the  caption  package, by the same author         -->
        <!-- and also in the  subcaption  package, again by the same author -->
        <!-- See comment by this author, Axel Sommerfeldt in                -->
        <!-- https://tex.stackexchange.com/questions/115193/                -->
        <!-- (continuous-numbering-of-custom-float-with-caption-package)    -->
        <!-- capt-of  sounds appealing, but then can't bold-face labels (?) -->
        <xsl:text>\usepackage{newfloat}&#xa;</xsl:text>
        <xsl:text>\usepackage{caption}</xsl:text>
        <!-- First, captioned items subsidiary to a captioned figure -->
        <!-- Seem to be bold face without extra effort               -->
        <xsl:if test="$document-root//figure/sidebyside/*[caption]">
            <xsl:text>%% Captioned items inside side-by-side within captioned figure&#xa;</xsl:text>
            <xsl:text>\usepackage{subcaption}&#xa;</xsl:text>
            <xsl:text>\captionsetup[subfigure]{labelformat=simple}&#xa;</xsl:text>
            <xsl:text>\renewcommand\thesubfigure{(\alph{subfigure})}&#xa;</xsl:text>
        </xsl:if>
        <!-- if figures are numbered distinct from theorems, -->
        <!-- then we need to inquire about its level         -->
        <!-- $numbering-theorems from mathbook-common.xsl    -->
        <xsl:variable name="figure-levels">
            <xsl:choose>
                <xsl:when test="$b-number-figure-distinct">
                    <xsl:value-of select="$docinfo/numbering/figures/@level" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$numbering-theorems" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- The "figure" counter is the lead for captioned items, -->
        <!-- so if these are distinct, we make this environment    -->
        <!-- just to make the counter, even if not explicitly used -->
        <xsl:if test="$document-root//figure or $b-number-figure-distinct">
            <xsl:text>%% Adjust stock figure environment so that it no longer floats&#xa;</xsl:text>
            <xsl:text>\SetupFloatingEnvironment{figure}{fileext=lof,placement={H},within=</xsl:text>
            <xsl:choose>
                <xsl:when test="$figure-levels = 0">
                    <xsl:text>none</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="level-to-name">
                        <xsl:with-param name="level" select="$figure-levels" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>,name=</xsl:text>
            <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'figure'" />
            </xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>\captionsetup[figure]{labelfont=bf}&#xa;</xsl:text>
            <xsl:if test="not($b-number-figure-distinct)">
                <xsl:text>%% http://tex.stackexchange.com/questions/16195&#xa;</xsl:text>
                <xsl:text>\makeatletter&#xa;</xsl:text>
                <xsl:text>\let\c@figure\c@theorem&#xa;</xsl:text>
                <xsl:text>\makeatother&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
        <xsl:if test="$document-root//table">
            <xsl:text>%% Adjust stock table environment so that it no longer floats&#xa;</xsl:text>
            <xsl:text>\SetupFloatingEnvironment{table}{fileext=lot,placement={H},within=</xsl:text>
            <xsl:choose>
                <xsl:when test="$figure-levels = 0">
                    <xsl:text>none</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="level-to-name">
                        <xsl:with-param name="level" select="$figure-levels" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>,name=</xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'table'" />
            </xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>\captionsetup[table]{labelfont=bf}&#xa;</xsl:text>
            <!-- associate counter                  -->
            <!--   if independent, then with figure -->
            <!--   if grouped, then with theorem    -->
            <xsl:text>%% http://tex.stackexchange.com/questions/16195&#xa;</xsl:text>
            <xsl:text>\makeatletter&#xa;</xsl:text>
            <xsl:choose>
                <xsl:when test="$b-number-figure-distinct">
                    <xsl:text>\let\c@table\c@figure&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\let\c@table\c@theorem&#xa;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>\makeatother&#xa;</xsl:text>
        </xsl:if>
        <!-- Listings do not float yet have semantic captions -->
        <!-- New environment, new captiontype:                -->
        <!-- http://tex.stackexchange.com/questions/7210      -->
        <!-- Within numbering argument:                       -->
        <!-- http://tex.stackexchange.com/questions/115193    -->
        <!-- Caption formatting/style possibilities:          -->
        <!-- http://tex.stackexchange.com/questions/117531    -->
        <xsl:if test="$document-root//listing">
            <xsl:text>%% Create "listing" environment to hold program listings&#xa;</xsl:text>
            <xsl:text>%% The "lstlisting" environment defaults to allowing page-breaking,&#xa;</xsl:text>
            <xsl:text>%% so we do not use a floating environment, which would break this&#xa;</xsl:text>
            <!-- TODO: optionally force no-page-break with [float] on lstlisting? -->
            <xsl:text>\newenvironment{listing}{\par\bigskip\noindent}{}&#xa;</xsl:text>
            <xsl:text>%% New caption type for numbering, style, etc.&#xa;</xsl:text>
            <xsl:text>\DeclareCaptionType[within=</xsl:text>
            <xsl:choose>
                <xsl:when test="$figure-levels = 0">
                    <xsl:text>none</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="level-to-name">
                        <xsl:with-param name="level" select="$figure-levels" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>]{listingcap}[</xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'listing'" />
            </xsl:call-template>
            <xsl:text>]&#xa;</xsl:text>
            <xsl:text>\captionsetup[listingcap]{labelfont=bf,aboveskip=1.0ex,belowskip=\baselineskip}&#xa;</xsl:text>
            <!-- associate counter                  -->
            <!--   if independent, then with figure -->
            <!--   if grouped, then with theorem    -->
            <xsl:text>%% http://tex.stackexchange.com/questions/16195&#xa;</xsl:text>
            <xsl:text>\makeatletter&#xa;</xsl:text>
            <xsl:choose>
                <xsl:when test="$b-number-figure-distinct">
                    <xsl:text>\let\c@listingcap\c@figure&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\let\c@listingcap\c@theorem&#xa;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>\makeatother&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$document-root//list">
            <xsl:text>%% Create "named list" environment to hold lists with captions&#xa;</xsl:text>
            <xsl:text>%% We do not use a floating environment, so list can page-break&#xa;</xsl:text>
            <xsl:text>\newenvironment{namedlist}{\par\bigskip\noindent}{}&#xa;</xsl:text>
            <xsl:text>%% New caption type for numbering, style, etc.&#xa;</xsl:text>
            <xsl:text>\DeclareCaptionType[within=</xsl:text>
            <xsl:choose>
                <xsl:when test="$figure-levels = 0">
                    <xsl:text>none</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="level-to-name">
                        <xsl:with-param name="level" select="$figure-levels" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>]{namedlistcap}[</xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'list'" />
            </xsl:call-template>
            <xsl:text>]&#xa;</xsl:text>
            <xsl:text>\captionsetup[namedlistcap]{labelfont=bf,aboveskip=1.0ex,belowskip=\baselineskip}&#xa;</xsl:text>
            <!-- associate counter                  -->
            <!--   if independent, then with figure -->
            <!--   if grouped, then with theorem    -->
            <xsl:text>%% http://tex.stackexchange.com/questions/16195&#xa;</xsl:text>
            <xsl:text>\makeatletter&#xa;</xsl:text>
            <xsl:choose>
                <xsl:when test="$b-number-figure-distinct">
                    <xsl:text>\let\c@namedlistcap\c@figure&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\let\c@namedlistcap\c@theorem&#xa;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>\makeatother&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- Numbering Footnotes -->
    <xsl:if test="($numbering-footnotes != 0) and //fn">
        <xsl:text>%% Footnote Numbering&#xa;</xsl:text>
        <xsl:text>%% We reset the footnote counter, as given by numbering.footnotes.level&#xa;</xsl:text>
        <xsl:text>\makeatletter\@addtoreset{footnote}{</xsl:text>
        <xsl:call-template name="level-to-name">
            <xsl:with-param name="level" select="$numbering-footnotes" />
        </xsl:call-template>
        <xsl:text>}\makeatother&#xa;</xsl:text>
    </xsl:if>
    <!-- Poetry -->
    <xsl:if test="//poem">
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
    <!-- Music -->
    <xsl:if test="//n or //scaledeg or //chord">
        <xsl:text>%% Musical Symbol Support&#xa;</xsl:text>
        <xsl:text>\ifthenelse{\boolean{xetex}}{&#xa;</xsl:text>
        <xsl:text>%% begin: xelatex-specific configuration&#xa;</xsl:text>
        <xsl:text>%% lilyglyphs.sty in Ubuntu/Debian texlive-music&#xa;</xsl:text>
        <xsl:text>\usepackage{lilyglyphs}&#xa;</xsl:text>
        <xsl:text>\lilyGlobalOptions{scale=0.8}&#xa;</xsl:text>
        <!-- Create alias to lilyglyphs command with common name -->
        <xsl:text>\newcommand*{\doubleflat}{\flatflat}&#xa;</xsl:text>
        <xsl:text>%% end: xelatex-specific configuration&#xa;</xsl:text>
        <xsl:text>}{&#xa;</xsl:text>
        <xsl:text>%% begin: pdflatex-specific configuration&#xa;</xsl:text>
        <!-- Pulling accidentals from "musixtex" font -->
        <!-- http://tex.stackexchange.com/questions/207261/how-do-i-produce-a-double-flat-symbol-edit -->
        <xsl:text>\DeclareFontFamily{U}{musix}{}%&#xa;</xsl:text>
        <xsl:text>\DeclareFontShape{U}{musix}{m}{n}{%&#xa;</xsl:text>
        <xsl:text>&lt;-12&gt;   musix11&#xa;</xsl:text>
        <xsl:text>&lt;12-15&gt; musix13&#xa;</xsl:text>
        <xsl:text>&lt;15-18&gt; musix16&#xa;</xsl:text>
        <xsl:text>&lt;18-23&gt; musix20&#xa;</xsl:text>
        <xsl:text>&lt;23-&gt;   musix29&#xa;</xsl:text>
        <xsl:text>}{}%&#xa;</xsl:text>
        <xsl:text>%% We grab all five accidentals from the musix font so they are usable in both math and text mode&#xa;</xsl:text>
        <xsl:text>\renewcommand*\flat{\raisebox{0.5ex}{\usefont{U}{musix}{m}{n}\selectfont{2}}}&#xa;</xsl:text>
        <xsl:text>\newcommand*\doubleflat{\raisebox{0.5ex}{\usefont{U}{musix}{m}{n}\selectfont{3}}}&#xa;</xsl:text>
        <xsl:text>\renewcommand*\sharp{\raisebox{0.5ex}{\usefont{U}{musix}{m}{n}\selectfont{4}}}&#xa;</xsl:text>
        <xsl:text>\newcommand*\doublesharp{\raisebox{0.5ex}{\usefont{U}{musix}{m}{n}\selectfont{5}}}&#xa;</xsl:text>
        <xsl:text>\renewcommand*\natural{\raisebox{0.5ex}{\usefont{U}{musix}{m}{n}\selectfont{6}}}&#xa;</xsl:text>
        <xsl:text>%% end: pdflatex-specific configuration&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <!-- Inconsolata font, sponsored by TUG: http://levien.com/type/myfonts/inconsolata.html            -->
    <!-- As seen on: http://tex.stackexchange.com/questions/50810/good-monospace-font-for-code-in-latex -->
    <!-- "Fonts for Displaying Program Code in LaTeX":  http://nepsweb.co.uk/docs%/progfonts.pdf        -->
    <!-- Fonts and xelatex:  http://tex.stackexchange.com/questions/102525/use-type-1-fonts-with-xelatex -->
    <!--   http://tex.stackexchange.com/questions/179448/beramono-in-xetex -->
    <!-- http://tex.stackexchange.com/questions/25249/how-do-i-use-a-particular-font-for-a-small-section-of-text-in-my-document -->
    <!-- Bitstream Vera Font names within: https://github.com/timfel/texmf/blob/master/fonts/map/vtex/bera.ali -->
    <!-- Coloring listings: http://tex.stackexchange.com/questions/18376/beautiful-listing-for-csharp -->
    <!-- Song and Dance for font changes: http://jevopi.blogspot.com/2010/03/nicely-formatted-listings-in-latex-with.html -->
     <xsl:if test="$document-root//sage or $document-root//program">
        <xsl:text>%% Program listing support: for listings, programs, and Sage code&#xa;</xsl:text>
        <xsl:text>\usepackage{listings}&#xa;</xsl:text>
        <xsl:text>%% We define the listings font style to be the default "ttfamily"&#xa;</xsl:text>
        <xsl:text>%% To fix hyphens/dashes rendered in PDF as fancy minus signs by listing&#xa;</xsl:text>
        <xsl:text>%% http://tex.stackexchange.com/questions/33185/listings-package-changes-hyphens-to-minus-signs&#xa;</xsl:text>
        <xsl:text>\makeatletter&#xa;</xsl:text>
        <xsl:text>\lst@CCPutMacro\lst@ProcessOther {"2D}{\lst@ttfamily{-{}}{-{}}}&#xa;</xsl:text>
        <xsl:text>\@empty\z@\@empty&#xa;</xsl:text>
        <xsl:text>\makeatother&#xa;</xsl:text>
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
        <xsl:if test="$document-root//program">
            <xsl:text>%% Program listings via the listings package&#xa;</xsl:text>
            <xsl:text>%% Line breaking, language per instance, frames, boxes&#xa;</xsl:text>
            <xsl:text>%% First a universal color scheme for parts of any language&#xa;</xsl:text>
            <xsl:if test="$latex.print='no'" >
                <xsl:text>%% Colors match a subset of Google prettify "Default" style&#xa;</xsl:text>
                <xsl:text>%% Set latex.print='yes' to get all black&#xa;</xsl:text>
                <xsl:text>%% http://code.google.com/p/google-code-prettify/source/browse/trunk/src/prettify.css&#xa;</xsl:text>
                <xsl:text>\definecolor{identifiers}{rgb}{0.375,0,0.375}&#xa;</xsl:text>
                <xsl:text>\definecolor{comments}{rgb}{0.5,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{strings}{rgb}{0,0.5,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{keywords}{rgb}{0,0,0.5}&#xa;</xsl:text>
            </xsl:if>
            <xsl:if test="$latex.print='yes'" >
                <xsl:text>%% All-black colors&#xa;</xsl:text>
                <xsl:text>%% Set latex.print='no' to get colors&#xa;</xsl:text>
                <xsl:text>\definecolor{identifiers}{rgb}{0,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{comments}{rgb}{0,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{strings}{rgb}{0,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{keywords}{rgb}{0,0,0}&#xa;</xsl:text>
            </xsl:if>
            <xsl:text>%% We define a null language, free of any formatting or style&#xa;</xsl:text>
            <xsl:text>%% for use when a language is not supported, or pseudo-code&#xa;</xsl:text>
            <xsl:text>\lstdefinelanguage{none}{identifierstyle=,commentstyle=,stringstyle=,keywordstyle=}&#xa;</xsl:text>
            <xsl:text>%% A style, both text behavior and decorations all at once&#xa;</xsl:text>
            <xsl:text>\lstdefinestyle{programstyle}{breaklines=true,breakatwhitespace=true,columns=fixed,frame=leftline,framesep=3ex, xleftmargin=3ex,&#xa;</xsl:text>
            <xsl:text>basicstyle=\small\ttfamily,identifierstyle=\color{identifiers},commentstyle=\color{comments},stringstyle=\color{strings},keywordstyle=\color{keywords}}&#xa;</xsl:text>
            <xsl:text>%% The environments manufactured by the listings package&#xa;</xsl:text>
            <xsl:text>%% Two environments, one full-width, the other boxed for side-by-sides&#xa;</xsl:text>
            <xsl:text>%% "program" expects a language argument only&#xa;</xsl:text>
            <xsl:text>%% "programbox" expects a language and a linewidth&#xa;</xsl:text>
            <xsl:text>\lstnewenvironment{program}[1][]&#xa;</xsl:text>
            <xsl:text>  {\lstset{style=programstyle,#1}}&#xa;</xsl:text>
            <xsl:text>  {}&#xa;</xsl:text>
            <xsl:text>\lstnewenvironment{programbox}[1][]&#xa;</xsl:text>
            <xsl:text>  {\lstset{style=programstyle,#1}}&#xa;</xsl:text>
            <xsl:text>  {}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$document-root//sage">
            <xsl:text>%% Sage's blue is 50%, we go way lighter (blue!05 would work)&#xa;</xsl:text>
            <xsl:text>\definecolor{sageblue}{rgb}{0.95,0.95,1}&#xa;</xsl:text>
            <xsl:text>%% Sage input, listings package: Python syntax, boxed, colored, line breaking&#xa;</xsl:text>
            <xsl:text>%% To be flush with surrounding text's margins, set&#xa;</xsl:text>
            <xsl:text>%% xmargins to be sum of framerule, framesep, and epsilon (~0.25pt)&#xa;</xsl:text>
            <xsl:text>%% space between input/output comes from input style "belowskip",&#xa;</xsl:text>
            <xsl:text>%% by giving output an aboveskip of zero&#xa;</xsl:text>
            <xsl:text>\lstdefinestyle{sageinputstyle}{language=Python,breaklines=true,breakatwhitespace=true,%&#xa;</xsl:text>
            <xsl:text>basicstyle=\small\ttfamily,columns=fixed,frame=single,backgroundcolor=\color{sageblue},%&#xa;</xsl:text>
            <xsl:text>framerule=0.5pt,framesep=4pt,xleftmargin=4.75pt,xrightmargin=4.75pt}&#xa;</xsl:text>
            <xsl:text>%% Sage output, similar, but not boxed, not colored&#xa;</xsl:text>
            <xsl:text>\lstdefinestyle{sageoutputstyle}{language=Python,breaklines=true,%&#xa;</xsl:text>
            <xsl:text>breakatwhitespace=true,basicstyle=\small\ttfamily,columns=fixed,aboveskip=0pt}&#xa;</xsl:text>
            <xsl:text>%% The environments manufactured by the listings package&#xa;</xsl:text>
            <xsl:text>\lstnewenvironment{sageinput}&#xa;</xsl:text>
            <xsl:text>  {\lstset{style=sageinputstyle}}&#xa;</xsl:text>
            <xsl:text>  {}&#xa;</xsl:text>
            <xsl:text>\lstnewenvironment{sageoutput}&#xa;</xsl:text>
            <xsl:text>  {\lstset{style=sageoutputstyle}}&#xa;</xsl:text>
            <xsl:text>  {}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$document-root//console or $document-root//pre or $document-root//cd">
        <xsl:text>%% Fancy Verbatim for consoles, preformatted, code display&#xa;</xsl:text>
        <xsl:text>\usepackage{fancyvrb}&#xa;</xsl:text>
        <xsl:if test="//pre">
            <xsl:text>%% Pre-formatted text, a peer of paragraphs&#xa;</xsl:text>
            <xsl:text>\DefineVerbatimEnvironment{preformatted}{Verbatim}{}&#xa;</xsl:text>
            <xsl:text>%% Pre-formatted text, as panel of a sidebyside&#xa;</xsl:text>
            <xsl:text>%% Default alignment is the bottom of the box on the baseline&#xa;</xsl:text>
            <xsl:text>\DefineVerbatimEnvironment{preformattedbox}{BVerbatim}{}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$document-root//cd">
            <xsl:text>%% code display (cd), by analogy with math display (md)&#xa;</xsl:text>
            <xsl:text>%% savebox, lrbox, etc to achieve centering&#xa;</xsl:text>
            <!-- https://tex.stackexchange.com/questions/182476/how-do-i-center-a-boxed-verbatim -->
            <!-- trying "\centering" here was a disaster -->
            <xsl:text>\newsavebox{\codedisplaybox}&#xa;</xsl:text>
            <xsl:text>\newenvironment{codedisplay}&#xa;</xsl:text>
            <xsl:text>{\VerbatimEnvironment\begin{center}\begin{lrbox}{\codedisplaybox}\begin{BVerbatim}}&#xa;</xsl:text>
            <xsl:text>{\end{BVerbatim}\end{lrbox}\usebox{\codedisplaybox}\end{center}}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$document-root//console">
            <xsl:text>%% Console session with prompt, input, output&#xa;</xsl:text>
            <xsl:text>%% Make a console environment from fancyvrb BVerbatim environment&#xa;</xsl:text>
            <xsl:text>%% Specify usual escape, begin group, end group characters&#xa;</xsl:text>
            <xsl:text>%% (boxed variant is useful for constructing sidebyside panels)&#xa;</xsl:text>
            <xsl:text>%% (BVerbatim environment allows for line numbers, make feature request?)&#xa;</xsl:text>
            <!-- "box verbatim" since could be used in a sidebyside panel, additional options are        -->
            <!-- trivial: numbers=left, stepnumber=5 (can mimic in HTML with counting recursive routine) -->
            <xsl:text>\DefineVerbatimEnvironment{console}{BVerbatim}{fontsize=\small,commandchars=\\\{\}}&#xa;</xsl:text>
            <xsl:text>%% A semantic macro for the user input portion&#xa;</xsl:text>
            <xsl:text>%% We define this in the traditional way,&#xa;</xsl:text>
            <xsl:text>%% but may realize it with different LaTeX escape characters&#xa;</xsl:text>
            <xsl:text>\newcommand{\consoleprompt}[1]{#1}&#xa;</xsl:text>
            <xsl:text>\newcommand{\consoleinput}[1]{\textbf{#1}}&#xa;</xsl:text>
            <xsl:text>\newcommand{\consoleoutput}[1]{#1}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="//tikz">
        <xsl:message>MBX:WARNING: the "tikz" element is deprecated (2015-10-16), use "latex-image-code" tag inside an "image" tag, and include the tikz package and relevant libraries in docinfo/latex-image-preamble</xsl:message>
        <xsl:text>%% Tikz graphics&#xa;</xsl:text>
        <xsl:text>\usepackage{tikz}&#xa;</xsl:text>
        <xsl:text>\usetikzlibrary{backgrounds}&#xa;</xsl:text>
        <xsl:text>\usetikzlibrary{arrows,matrix}&#xa;</xsl:text>
    </xsl:if>
    <!-- TODO:  \showidx package as part of a draft mode, prints entries in margin -->
     <xsl:if test="//ol[@cols] or //ul[@cols] or //dl[@cols]">
        <xsl:text>%% Multiple column, column-major lists&#xa;</xsl:text>
        <xsl:text>\usepackage{multicol}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//ol or //ul or //dl or //exercises or //references">
        <xsl:text>%% More flexible list management, esp. for references and exercises&#xa;</xsl:text>
        <xsl:text>%% But also for specifying labels (i.e. custom order) on nested lists&#xa;</xsl:text>
        <xsl:text>\usepackage{enumitem}&#xa;</xsl:text>
        <xsl:if test="//exercises or //references">
            <xsl:if test="//references">
                <xsl:text>%% Lists of references in their own section, maximum depth 1&#xa;</xsl:text>
                <xsl:text>\newlist{referencelist}{description}{4}&#xa;</xsl:text>
                <!-- labelindent defaults to 0, ! means computed -->
                <xsl:text>\setlist[referencelist]{leftmargin=!,labelwidth=!,labelsep=0ex,itemsep=1.0ex,topsep=1.0ex,partopsep=0pt,parsep=0pt}&#xa;</xsl:text>
            </xsl:if>
            <xsl:if test="//exercises">
                <xsl:text>%% Lists of exercises in their own section, maximum depth 4&#xa;</xsl:text>
                <xsl:text>\newlist{exerciselist}{description}{4}&#xa;</xsl:text>
                <xsl:text>\setlist[exerciselist]{leftmargin=0pt,itemsep=1.0ex,topsep=1.0ex,partopsep=0pt,parsep=0pt}&#xa;</xsl:text>
            </xsl:if>
            <xsl:if test="//exercisegroup">
                <xsl:text>%% Indented groups of exercises within an exercise section&#xa;</xsl:text>
                <xsl:text>%% Add  debug=true  option to see boxes around contents&#xa;</xsl:text>
                <xsl:text>\usepackage{tasks}&#xa;</xsl:text>
                <xsl:text>\NewTasks[label-format=\bfseries,item-indent=3.3em,label-offset=0.4em,label-width=1.7em,label-align=right,after-item-skip=\smallskipamount,after-skip=\smallskipamount]{exercisegroup}[\exercise]&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$document-root/backmatter/index-part | $document-root//index-list">
        <!-- See http://tex.blogoverflow.com/2012/09/dont-forget-to-run-makeindex/ for "imakeidx" usage -->
        <xsl:text>%% Support for index creation&#xa;</xsl:text>
        <xsl:if test="$author-tools='no'">
            <xsl:text>%% imakeidx package does not require extra pass (as with makeidx)&#xa;</xsl:text>
            <xsl:text>%% Title of the "Index" section set via a keyword&#xa;</xsl:text>
            <xsl:text>%% Language support for the "see" and "see also" phrases&#xa;</xsl:text>
            <xsl:text>\usepackage{imakeidx}&#xa;</xsl:text>
            <xsl:text>\makeindex[title=</xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'index'" />
            </xsl:call-template>
            <xsl:text>, intoc=true]&#xa;</xsl:text>
            <xsl:text>\renewcommand{\seename}{</xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'see'" />
            </xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>\renewcommand{\alsoname}{</xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'also'" />
            </xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$author-tools='yes'">
            <xsl:text>%% author-tools = 'yes' activates marginal notes about index&#xa;</xsl:text>
            <xsl:text>%% and supresses the actual creation of the index itself&#xa;</xsl:text>
            <xsl:text>\usepackage{showidx}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="//webwork[@source]">
        <xsl:text>%% Package for breakable boxes on WeBWorK problems from server LaTeX&#xa;</xsl:text>
        <xsl:text>\usepackage{mdframed}&#xa;</xsl:text>
        <xsl:text>%% WeBWorK problem style&#xa;</xsl:text>
        <xsl:text>\mdfdefinestyle{webwork-server}{framemethod=default, linewidth=2pt}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//docinfo/logo">
        <xsl:text>%% Package for precise image placement (for logos on pages)&#xa;</xsl:text>
        <xsl:text>\usepackage{eso-pic}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//notation or //list-of">
        <xsl:text>%% Package for tables spanning several pages&#xa;</xsl:text>
        <xsl:text>\usepackage{longtable}&#xa;</xsl:text>
    </xsl:if>
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
    <!-- http://tex.stackexchange.com/questions/106159/why-i-shouldnt-load-pdftex-option-with-hyperref -->
    <xsl:text>%% hyperref driver does not need to be specified, it will be detected&#xa;</xsl:text>
    <xsl:text>\usepackage{hyperref}&#xa;</xsl:text>
    <!-- http://tex.stackexchange.com/questions/79051/how-to-style-text-in-hyperref-url -->
    <xsl:if test="//url">
    <xsl:text>%% configure hyperref's  \url  to match listings' inline verbatim&#xa;</xsl:text>
        <xsl:text>\renewcommand\UrlFont{\small\ttfamily}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$latex.print='no'">
        <xsl:text>%% Hyperlinking active in PDFs, all links solid and blue&#xa;</xsl:text>
        <xsl:text>\hypersetup{colorlinks=true,linkcolor=blue,citecolor=blue,filecolor=blue,urlcolor=blue}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$latex.print='yes'">
        <xsl:text>%% latex.print parameter set to 'yes', all hyperlinks black and inactive&#xa;</xsl:text>
        <xsl:text>\hypersetup{draft}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\hypersetup{pdftitle={</xsl:text>
    <xsl:apply-templates select="." mode="title-simple" />
    <xsl:text>}}&#xa;</xsl:text>
    <!-- http://tex.stackexchange.com/questions/44088/when-do-i-need-to-invoke-phantomsection -->
    <xsl:text>%% If you manually remove hyperref, leave in this next command&#xa;</xsl:text>
    <xsl:text>\providecommand\phantomsection{}&#xa;</xsl:text>
    <!-- Later comment advises @addtoreset *after* hyperref -->
    <!-- https://tex.stackexchange.com/questions/35782      -->
    <xsl:if test="$parts = 'structural'">  <!-- implies book/part -->
        <xsl:text>%% Structural chapter numbers reset within parts&#xa;</xsl:text>
        <xsl:text>\makeatletter&#xa;</xsl:text>
        <xsl:text>\@addtoreset{chapter}{part}&#xa;</xsl:text>
        <xsl:text>\makeatother&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$latex.watermark">
        <xsl:text>\usepackage{draftwatermark}&#xa;</xsl:text>
        <xsl:text>\SetWatermarkText{</xsl:text>
        <xsl:value-of select="$latex.watermark" />
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\SetWatermarkScale{</xsl:text>
        <xsl:value-of select="$latex.watermark.scale" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$author-tools='yes'" >
        <xsl:text>%% Collected author tools options (author-tools='yes')&#xa;</xsl:text>
        <xsl:text>%% others need to be elsewhere, these are simply package additions&#xa;</xsl:text>
        <xsl:text>\usepackage{showkeys}&#xa;</xsl:text>
        <xsl:text>\usepackage[letter,cam,center,pdflatex]{crop}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$docinfo/latex-image-preamble">
        <xsl:text>%% Graphics Preamble Entries&#xa;</xsl:text>
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="$docinfo/latex-image-preamble" />
        </xsl:call-template>
    </xsl:if>
    <xsl:text>%% If tikz has been loaded, replace ampersand with \amp macro&#xa;</xsl:text>
    <xsl:if test="$document-root//latex-image-code|$document-root//latex-image">
        <xsl:text>\ifdefined\tikzset&#xa;</xsl:text>
        <xsl:text>    \tikzset{ampersand replacement = \amp}&#xa;</xsl:text>
        <xsl:text>\fi&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//sidebyside">
        <xsl:text>%% NB: calc redefines \setlength&#xa;</xsl:text>
        <xsl:text>\usepackage{calc}&#xa;</xsl:text>
        <xsl:text>%% used repeatedly for vertical dimensions of sidebyside panels&#xa;</xsl:text>
        <xsl:text>\newlength{\panelmax}&#xa;</xsl:text>
    </xsl:if>
    <!-- We could use contains() on the 5 types of arrows  -->
    <!-- to really defend against this problematic package -->
    <xsl:if test="//m or //md or //mrow">
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
    </xsl:if>

    <xsl:text>%% Custom Preamble Entries, late (use latex.preamble.late)&#xa;</xsl:text>
    <xsl:if test="$latex.preamble.late != ''">
        <xsl:value-of select="$latex.preamble.late" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Begin: Author-provided packages&#xa;</xsl:text>
    <xsl:text>%% (From  docinfo/latex-preamble/package  elements)&#xa;</xsl:text>
    <xsl:value-of select="$latex-packages" />
    <xsl:text>%% End: Author-provided packages&#xa;</xsl:text>
    <xsl:text>%% Begin: Author-provided macros&#xa;</xsl:text>
    <xsl:text>%% (From  docinfo/macros  element)&#xa;</xsl:text>
    <xsl:text>%% Plus three from MBX for XML characters&#xa;</xsl:text>
    <xsl:value-of select="$latex-macros" />
    <xsl:text>%% End: Author-provided macros&#xa;</xsl:text>

    <!-- Easter Egg -->
    <xsl:if test="$sbsdebug">
        <xsl:text>\setlength{\fboxrule}{1pt}&#xa;</xsl:text>
        <xsl:text>\setlength{\fboxsep}{-1pt}&#xa;</xsl:text>
    </xsl:if>

    <!-- PGML definitions. What follows is the PGML problem preamble in its entirety, taken from  -->
    <!-- https://github.com/openwebwork/pg/blob/master/macros/PGML.pl. However some lines are     -->
    <!-- commented out, as they clash with MBX LaTeX.                                             -->
    <xsl:if test="//webwork[@source]">
        <xsl:text>%% PGML macros&#xa;</xsl:text>
        <xsl:text>%% formatted to exactly match output from PGML.pl as of 11/22/2016&#xa;</xsl:text>
        <xsl:text>%% but with some lines commented out&#xa;</xsl:text>
        <xsl:text>%\ifx\pgmlMarker\undefined&#xa;</xsl:text>
        <xsl:text>%  \newdimen\pgmlMarker \pgmlMarker=0.00314159pt  % hack to tell if \newline was used&#xa;</xsl:text>
        <xsl:text>%\fi&#xa;</xsl:text>
        <xsl:text>%\ifx\oldnewline\undefined \let\oldnewline=\newline \fi&#xa;</xsl:text>
        <xsl:text>%\def\newline{\oldnewline\hskip-\pgmlMarker\hskip\pgmlMarker\relax}%&#xa;</xsl:text>
        <xsl:text>%\parindent=0pt&#xa;</xsl:text>
        <xsl:text>%\catcode`\^^M=\active&#xa;</xsl:text>
        <xsl:text>%\def^^M{\ifmmode\else\fi\ignorespaces}%  skip paragraph breaks in the preamble&#xa;</xsl:text>
        <xsl:text>%\def\par{\ifmmode\else\endgraf\fi\ignorespaces}%&#xa;</xsl:text>
        <xsl:text>%\ifdim\lastskip=\pgmlMarker&#xa;</xsl:text>
        <xsl:text>%  \let\pgmlPar=\relax&#xa;</xsl:text>
        <xsl:text>% \else&#xa;</xsl:text>
        <xsl:text>  \let\pgmlPar=\par&#xa;</xsl:text>
        <xsl:text>%  \vadjust{\kern3pt}%&#xa;</xsl:text>
        <xsl:text>%\fi&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%%    definitions for PGML&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>%\ifx\pgmlCount\undefined  % do not redefine if multiple files load PGML.pl&#xa;</xsl:text>
        <xsl:text>  \newcount\pgmlCount&#xa;</xsl:text>
        <xsl:text>  \newdimen\pgmlPercent&#xa;</xsl:text>
        <xsl:text>  \newdimen\pgmlPixels  \pgmlPixels=.5pt&#xa;</xsl:text>
        <xsl:text>%\fi&#xa;</xsl:text>
        <xsl:text>%\pgmlPercent=.01\hsize&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>\def\pgmlSetup{%&#xa;</xsl:text>
        <xsl:text>  \parskip=0pt \parindent=0pt&#xa;</xsl:text>
        <xsl:text>%  \ifdim\lastskip=\pgmlMarker\else\par\fi&#xa;</xsl:text>
        <xsl:text>  \pgmlPar&#xa;</xsl:text>
        <xsl:text>}%&#xa;</xsl:text>
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>\def\pgmlIndent{\par\advance\leftskip by 2em \advance\pgmlPercent by .02em \pgmlCount=0}%&#xa;</xsl:text>
        <xsl:text>\def\pgmlbulletItem{\par\indent\llap{$\bullet$ }\ignorespaces}%&#xa;</xsl:text>
        <xsl:text>\def\pgmlcircleItem{\par\indent\llap{$\circ$ }\ignorespaces}%&#xa;</xsl:text>
        <xsl:text>\def\pgmlsquareItem{\par\indent\llap{\vrule height 1ex width .75ex depth -.25ex\ }\ignorespaces}%&#xa;</xsl:text>
        <xsl:text>\def\pgmlnumericItem{\par\indent\advance\pgmlCount by 1 \llap{\the\pgmlCount. }\ignorespaces}%&#xa;</xsl:text>
        <xsl:text>\def\pgmlalphaItem{\par\indent{\advance\pgmlCount by `\a \llap{\char\pgmlCount. }}\advance\pgmlCount by 1\ignorespaces}%&#xa;</xsl:text>
        <xsl:text>\def\pgmlAlphaItem{\par\indent{\advance\pgmlCount by `\A \llap{\char\pgmlCount. }}\advance\pgmlCount by 1\ignorespaces}%&#xa;</xsl:text>
        <xsl:text>\def\pgmlromanItem{\par\indent\advance\pgmlCount by 1 \llap{\romannumeral\pgmlCount. }\ignorespaces}%&#xa;</xsl:text>
        <xsl:text>\def\pgmlRomanItem{\par\indent\advance\pgmlCount by 1 \llap{\uppercase\expandafter{\romannumeral\pgmlCount}. }\ignorespaces}%&#xa;</xsl:text>
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>\def\pgmlCenter{%&#xa;</xsl:text>
        <xsl:text>  \par \parfillskip=0pt&#xa;</xsl:text>
        <xsl:text>  \advance\leftskip by 0pt plus .5\hsize&#xa;</xsl:text>
        <xsl:text>  \advance\rightskip by 0pt plus .5\hsize&#xa;</xsl:text>
        <xsl:text>  \def\pgmlBreak{\break}%&#xa;</xsl:text>
        <xsl:text>}%&#xa;</xsl:text>
        <xsl:text>\def\pgmlRight{%&#xa;</xsl:text>
        <xsl:text>  \par \parfillskip=0pt&#xa;</xsl:text>
        <xsl:text>  \advance\leftskip by 0pt plus \hsize&#xa;</xsl:text>
        <xsl:text>  \def\pgmlBreak{\break}%&#xa;</xsl:text>
        <xsl:text>}%&#xa;</xsl:text>
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>\def\pgmlBreak{\\}%&#xa;</xsl:text>
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>\def\pgmlHeading#1{%&#xa;</xsl:text>
        <xsl:text>  \par\bfseries&#xa;</xsl:text>
        <xsl:text>  \ifcase#1 \or\huge \or\LARGE \or\large \or\normalsize \or\footnotesize \or\scriptsize \fi&#xa;</xsl:text>
        <xsl:text>}%&#xa;</xsl:text>
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>\def\pgmlRule#1#2{%&#xa;</xsl:text>
        <xsl:text>  \par\noindent&#xa;</xsl:text>
        <xsl:text>  \hbox{%&#xa;</xsl:text>
        <xsl:text>    \strut%&#xa;</xsl:text>
        <xsl:text>    \dimen1=\ht\strutbox%&#xa;</xsl:text>
        <xsl:text>    \advance\dimen1 by -#2%&#xa;</xsl:text>
        <xsl:text>    \divide\dimen1 by 2%&#xa;</xsl:text>
        <xsl:text>    \advance\dimen2 by -\dp\strutbox%&#xa;</xsl:text>
        <xsl:text>    \raise\dimen1\hbox{\vrule width #1 height #2 depth 0pt}%&#xa;</xsl:text>
        <xsl:text>  }%&#xa;</xsl:text>
        <xsl:text>  \par&#xa;</xsl:text>
        <xsl:text>}%&#xa;</xsl:text>
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>\def\pgmlIC#1{\futurelet\pgmlNext\pgmlCheckIC}%&#xa;</xsl:text>
        <xsl:text>\def\pgmlCheckIC{\ifx\pgmlNext\pgmlSpace \/\fi}%&#xa;</xsl:text>
        <xsl:text>{\def\getSpace#1{\global\let\pgmlSpace= }\getSpace{} }%&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>%{\catcode`\ =12\global\let\pgmlSpaceChar= }%&#xa;</xsl:text>
        <xsl:text>%{\obeylines\gdef\pgmlPreformatted{\par\small\ttfamily\hsize=10\hsize\obeyspaces\obeylines\let^^M=\pgmlNL\pgmlNL}}%&#xa;</xsl:text>
        <xsl:text>%\def\pgmlNL{\par\bgroup\catcode`\ =12\pgmlTestSpace}%&#xa;</xsl:text>
        <xsl:text>%\def\pgmlTestSpace{\futurelet\next\pgmlTestChar}%&#xa;</xsl:text>
        <xsl:text>%\def\pgmlTestChar{\ifx\next\pgmlSpaceChar\ \pgmlTestNext\fi\egroup}%&#xa;</xsl:text>
        <xsl:text>%\def\pgmlTestNext\fi\egroup#1{\fi\pgmlTestSpace}%&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>%\def^^M{\ifmmode\else\space\fi\ignorespaces}%&#xa;</xsl:text>
        <xsl:text>%% END PGML macros&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//contributors">
        <xsl:text>%% Semantic macros for contributor list&#xa;</xsl:text>
        <xsl:text>\newcommand{\contributor}[1]{\parbox{\linewidth}{#1}\par\bigskip}&#xa;</xsl:text>
        <xsl:text>\newcommand{\contributorname}[1]{\textsc{#1}\\[0.25\baselineskip]}&#xa;</xsl:text>
        <xsl:text>\newcommand{\contributorinfo}[1]{\hspace*{0.05\linewidth}\parbox{0.95\linewidth}{\textsl{#1}}}&#xa;</xsl:text>
    </xsl:if>

</xsl:template>

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

<xsl:template name="title-page-info-book">
    <xsl:text>%% Title page information for book&#xa;</xsl:text>
    <xsl:text>\title{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:if test="subtitle">
        <xsl:text>\\&#xa;</xsl:text>
        <!-- Trying to match author fontsize -->
        <xsl:text>{\large </xsl:text>
        <xsl:apply-templates select="." mode="subtitle" />
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\author{</xsl:text><xsl:apply-templates select="frontmatter/titlepage/author" /><xsl:apply-templates select="frontmatter/titlepage/editor" /><xsl:text>}&#xa;</xsl:text>
    <xsl:text>\date{</xsl:text><xsl:apply-templates select="frontmatter/titlepage/date" /><xsl:text>}&#xa;</xsl:text>
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
    <xsl:text>}&#xa;</xsl:text>
    <xsl:if test="frontmatter/titlepage/author or frontmatter/titlepage/editor">
        <xsl:text>\author{</xsl:text>
        <xsl:apply-templates select="frontmatter/titlepage/author" />
        <xsl:apply-templates select="frontmatter/titlepage/editor" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\date{</xsl:text><xsl:apply-templates select="frontmatter/titlepage/date" /><xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- "half-title" is leading page with -->
<!-- title only, at about 1:2 split    -->
<xsl:template match="book" mode="half-title" >
    <xsl:text>%% begin: half-title&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:text>{\centering&#xa;</xsl:text>
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
    <xsl:text>}&#xa;</xsl:text> <!-- finish centering -->
    <xsl:text>\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   half-title&#xa;</xsl:text>
</xsl:template>

<!-- Ad card may contain list of other books        -->
<!-- Or may be overridden to make title page spread -->
<!-- Obverse of half-title                          -->
<xsl:template match="book" mode="ad-card">
    <xsl:text>%% begin: adcard&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:text>\null%&#xa;</xsl:text>
    <xsl:text>\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   adcard&#xa;</xsl:text>
</xsl:template>

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
    <xsl:text>{\centering&#xa;</xsl:text>
    <xsl:text>\vspace*{0.14\textheight}&#xa;</xsl:text>
    <!-- Target for xref to top-level element -->
    <!-- immediately, or first in ToC         -->
    <xsl:choose>
        <xsl:when test="$b-has-toc">
            <xsl:text>%% Target for xref to top-level element is ToC&#xa;</xsl:text>
            <xsl:text>\addtocontents{toc}{\protect\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>}{}}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>%% Target for xref to top-level element is document start&#xa;</xsl:text>
            <xsl:text>\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
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
    <xsl:apply-templates select="frontmatter/titlepage/author" mode="title-page"/>
    <xsl:apply-templates select="frontmatter/titlepage/editor" mode="title-page" />
    <xsl:apply-templates select="frontmatter/titlepage/credit" mode="title-page" />
    <xsl:apply-templates select="frontmatter/titlepage/date"   mode="title-page" />
    <xsl:text>}&#xa;</xsl:text> <!-- finish centering -->
    <xsl:text>\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   title page&#xa;</xsl:text>
</xsl:template>

<xsl:template match="author|editor" mode="title-page">
    <xsl:text>[3\baselineskip]&#xa;</xsl:text>
    <xsl:text>{\Large </xsl:text>
    <xsl:apply-templates select="personname" />
    <xsl:if test="self::editor">
        <xsl:text>, </xsl:text>
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'editor'" />
        </xsl:call-template>
    </xsl:if>
    <xsl:text>}\\</xsl:text>
    <xsl:if test="institution">
        <xsl:text>[0.5\baselineskip]&#xa;</xsl:text>
        <xsl:text>{\Large </xsl:text>
        <xsl:apply-templates select="institution" />
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
        <xsl:if test="institution">
            <xsl:text>[0.25\baselineskip]&#xa;</xsl:text>
            <xsl:apply-templates select="institution" />
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
    <xsl:apply-templates />
    <xsl:text>}\\</xsl:text>
</xsl:template>

<!-- Copyright page is obverse of title page  -->
<!-- Lots of stuff here, much of it optional  -->
<!-- But we always write something            -->
<!-- as the obverse of title page             -->
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

    <xsl:if test="frontmatter/colophon/credit">
        <xsl:text>\par\noindent&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="frontmatter/colophon/credit">
        <xsl:text>\textbf{</xsl:text>
        <xsl:apply-templates select="role" />
        <xsl:text>}:\ \ </xsl:text>
        <xsl:apply-templates select="entity" />
        <xsl:if test="following-sibling::credit">
            <xsl:text>\\</xsl:text>
        </xsl:if>
        <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>
    <xsl:if test="frontmatter/colophon/credit">
        <xsl:text>\par\vspace*{\stretch{2}}&#xa;</xsl:text>
    </xsl:if>

    <xsl:if test="frontmatter/colophon/edition" >
        <xsl:text>\noindent{\bfseries </xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/edition" mode="type-name" />
        <xsl:text>}: </xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/edition" />
        <xsl:text>\par\medskip&#xa;</xsl:text>
    </xsl:if>

    <xsl:if test="frontmatter/colophon/website" >
        <xsl:text>\noindent{\bfseries </xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/website" mode="type-name" />
        <xsl:text>}: </xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/website" />
        <xsl:text>\par\medskip&#xa;</xsl:text>
    </xsl:if>

    <xsl:if test="frontmatter/colophon/copyright" >
        <xsl:text>\noindent\textcopyright\ </xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/copyright/year" />
        <xsl:text>\quad{}</xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/copyright/holder" />
        <xsl:if test="frontmatter/colophon/copyright/shortlicense">
            <xsl:text>\\[0.5\baselineskip]&#xa;</xsl:text>
            <xsl:apply-templates select="frontmatter/colophon/copyright/shortlicense" />
        </xsl:if>
        <xsl:text>\par\medskip&#xa;</xsl:text>
    </xsl:if>

    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <!-- Something so page is not totally nothing -->
    <xsl:text>\null\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   copyright-page&#xa;</xsl:text>
</xsl:template>

<!-- URL for canonical project website -->
<xsl:template match="frontmatter/colophon/website" >
    <xsl:text>\href{</xsl:text>
    <xsl:apply-templates select="address" />
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="name" />
    <xsl:text>}</xsl:text>
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
    <xsl:apply-templates select="*" />
    <!-- drop a par, for next bio, or for big vspace -->
    <xsl:text>\par&#xa;</xsl:text>
</xsl:template>

<!-- Authors, editors, full info for titlepage -->
<!-- http://stackoverflow.com/questions/2817664/xsl-how-to-tell-if-element-is-last-in-series -->
<xsl:template match="author">
    <xsl:apply-templates select="personname" />
    <xsl:if test="department">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="department" />
    </xsl:if>
    <xsl:if test="institution">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="institution" />
    </xsl:if>
    <xsl:if test="email">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="email" />
    </xsl:if>
    <xsl:if test="position() != last()" >
        <xsl:text>&#xa;\and</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>
<xsl:template match="editor">
    <xsl:apply-templates select="personname" />
    <xsl:text>, </xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'editor'" />
    </xsl:call-template>
    <xsl:if test="department">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="department" />
    </xsl:if>
    <xsl:if test="institution">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="institution" />
    </xsl:if>
    <xsl:if test="email">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="email" />
    </xsl:if>
    <xsl:if test="position() != last()" >
        <xsl:text>&#xa;\and</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Departments and Institutions are free-form, or sequences of lines -->
<!-- Line breaks are inserted above, due to \and, etc,                 -->
<!-- so do not end last line here                                      -->
<xsl:template match="department|institution">
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="department[line]|institution[line]">
    <xsl:apply-templates select="line" />
</xsl:template>

<xsl:template match="department/line|institution/line">
    <xsl:apply-templates />
    <!-- is there a next line to separate? -->
    <xsl:if test="following-sibling::*">
        <xsl:text>\\&#xa;</xsl:text>
    </xsl:if>
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
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'toc'" />
        </xsl:call-template>
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

<!-- Articles may have an abstract in the frontmatter -->
<xsl:template match="article/frontmatter/abstract">
    <xsl:text>\begin{abstract}&#xa;</xsl:text>
    <xsl:apply-templates />
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
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'toc'" />
        </xsl:call-template>
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
    <!-- first page, title only -->
    <xsl:apply-templates select="../.." mode="half-title" />
    <!-- Obverse of half-title is adcard -->
    <xsl:apply-templates select="../.." mode="ad-card" />
    <!-- title page -->
    <xsl:apply-templates select="../.." mode="title-page" />
    <!-- title page obverse is copyright, possibly empty -->
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
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'about-authors'" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'about-author'" />
                </xsl:call-template>
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
    <xsl:apply-templates select="*" />
</xsl:template>

<!-- Preface, etc within \frontmatter is usually handled correctly by LaTeX -->
<!-- Allow alternative titles, like "Preface to 2nd Edition"                -->
<!-- But we use starred version anyway, so chapter headings react properly  -->
<!-- DTD: enforce order: dedication, acknowledgements, forewords, prefaces -->
<!-- TODO: add other frontmatter, move in title handling        -->
<!-- TODO: add to headers, currently just CONTENTS, check backmatter        -->
<xsl:template match="acknowledgement|foreword|preface">
    <xsl:text>%% begin: </xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\chapter*{</xsl:text>
    <xsl:apply-templates  select="." mode="title-full" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\addcontentsline{toc}{chapter}{</xsl:text>
    <xsl:apply-templates select="." mode="title-simple" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>%% end:   </xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>&#xa;</xsl:text>
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
    <xsl:text>%% begin: obverse-dedication-page (empty)&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:text>\null%&#xa;</xsl:text>
    <xsl:text>\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   obverse-dedication-page&#xa;</xsl:text>
</xsl:template>

<!-- Dedications are meant to be very short      -->
<!-- so are each a single paragraph and          -->
<!-- are centered on a page of their own         -->
<!-- The center environment provides good        -->
<!-- vertical break between multiple instances   -->
<!-- The p[1] elsewhere is the default,          -->
<!-- hence we use the priority mechanism (>0.5)  -->
<xsl:template match="dedication/p|dedication/p[1]" priority="1">
    <xsl:text>\begin{center}\Large%&#xa;</xsl:text>
        <xsl:apply-templates />
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\end{center}&#xa;</xsl:text>
</xsl:template>

<!-- General line of a dedication -->
<xsl:template match="dedication/p/line">
    <xsl:apply-templates />
    <!-- is there a next line to separate? -->
    <xsl:if test="following-sibling::*">
        <xsl:text>\\</xsl:text>
    </xsl:if>
    <!-- always format source visually -->
    <xsl:text>&#xa;</xsl:text>
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
    <xsl:apply-templates />
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
    <xsl:apply-templates />
    <!-- part of a big block, use newline everywhere -->
    <xsl:text>\\&#xa;</xsl:text>
</xsl:template>

<!-- ############ -->
<!-- Back Matter -->
<!-- ############ -->

<!-- <backmatter> is structural -->
<!-- Noted in an book           -->
<!-- But not in an article      -->
<xsl:template match="article/backmatter">
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="book/backmatter">
    <!-- If no appendices, go straight to book backmatter,      -->
    <!-- which automatically produces divisions with no numbers -->
    <!-- Otherwise \appendix,...\backmatter is handled in the   -->
    <!-- template for general subdivisions                      -->
    <xsl:if test="ancestor::book and not(appendix)">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>\backmatter&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
    <!-- Some vertical separation into backmatter contents is useful -->
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>%% A lineskip in table of contents as transition to appendices, backmatter&#xa;</xsl:text>
    <xsl:text>\addtocontents{toc}{\vspace{\normalbaselineskip}}&#xa;</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- The back colophon of a book goes on its own recto page     -->
<!-- the centering is on the assumption it is a simple sentence -->
<!-- Maybe a parbox, centered, etc is necessary                 -->
<xsl:template match="book/backmatter/colophon">
    <xsl:text>\cleardoublepage&#xa;</xsl:text>
    <xsl:text>\pagestyle{empty}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <xsl:text>\centerline{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\vspace*{\stretch{2}}&#xa;</xsl:text>
</xsl:template>

<!-- The back colophon of an article is an -->
<!-- unnumbered section, not centered, etc -->
<!-- but it is titled (not to ToC, though) -->
<xsl:template match="article/backmatter/colophon">
    <xsl:text>\section*{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'colophon'" />
    </xsl:call-template>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:apply-templates />
</xsl:template>

<!-- Appendices are handled in the general subdivision template -->

<!-- The index itself needs special handling    -->
<!-- The "index-part" element signals an index, -->
<!-- and the content is just an optional title  -->
<!-- and a compulsory "index-list"              -->
<!-- LaTeX does sectioning via \printindex      -->
<!-- TODO: multiple indices, with different titles -->
<xsl:template match="index-part|index[index-list]">
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="index-list">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>%% The index is here, setup is all in preamble&#xa;</xsl:text>
    <xsl:text>\printindex&#xa;</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!--               -->
<!-- Notation List -->
<!--               -->

<!-- At location, we just drop a page marker -->
<xsl:template match="notation">
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Deccription column is "p" to enable word-wrapping  -->
<!-- The 60% width is arbitrary, could see improvements -->
<xsl:template match="notation-list">
    <xsl:text>\begin{longtable}[l]{lp{0.60\textwidth}r}&#xa;</xsl:text>
    <xsl:text>\textbf{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'symbol'" />
    </xsl:call-template>
    <xsl:text>}&amp;\textbf{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'description'" />
    </xsl:call-template>
    <xsl:text>}&amp;\textbf{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'page'" />
    </xsl:call-template>
    <xsl:text>}\\[1em]&#xa;</xsl:text>
    <xsl:text>\endfirsthead&#xa;</xsl:text>
    <xsl:text>\textbf{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'symbol'" />
    </xsl:call-template>
    <xsl:text>}&amp;\textbf{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'description'" />
    </xsl:call-template>
    <xsl:text>}&amp;\textbf{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'page'" />
    </xsl:call-template>
    <xsl:text>}\\[1em]&#xa;</xsl:text>
    <xsl:text>\endhead&#xa;</xsl:text>
    <xsl:text>\multicolumn{3}{r}{(</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'continued'" />
    </xsl:call-template>
    <xsl:text>)}\\&#xa;</xsl:text>
    <xsl:text>\endfoot&#xa;</xsl:text>
    <xsl:text>\endlastfoot&#xa;</xsl:text>
    <xsl:apply-templates select="$document-root//notation" mode="backmatter" />
    <xsl:text>\end{longtable}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="notation" mode="backmatter">
    <xsl:text>\(</xsl:text>
    <xsl:apply-templates select="usage" />
    <xsl:text>\)</xsl:text>
    <xsl:text>&amp;</xsl:text>
    <xsl:apply-templates select="description" />
    <xsl:text>&amp;</xsl:text>
    <xsl:text>\pageref{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>\\&#xa;</xsl:text>
</xsl:template>

<!-- ############### -->
<!-- Arbitrary Lists -->
<!-- ############### -->

<!-- See general routine in  xsl/mathbook-common.xsl -->
<!-- which expects the two named templates and the  -->
<!-- two division'al and element'al templates below,  -->
<!-- it contains the logic of constructing such a list -->

<!-- List-of entry/exit hooks   -->
<!-- Long table, two columns    -->
<!-- Just "continued" adornment -->
<xsl:template name="list-of-begin">
    <xsl:text>\noindent&#xa;</xsl:text>
    <xsl:text>\begin{longtable}[l]{ll}&#xa;</xsl:text>
    <xsl:text>\endfirsthead&#xa;</xsl:text>
    <xsl:text>\endhead&#xa;</xsl:text>
    <xsl:text>\multicolumn{2}{r}{(</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'continued'" />
    </xsl:call-template>
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
<xsl:template match="*" mode="list-of-header">
    <xsl:text>\multicolumn{2}{l}{\null}\\[1.5ex] </xsl:text>
    <xsl:text>\multicolumn{2}{l}{\large </xsl:text>
    <xsl:apply-templates select="." mode="type-name" />
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
            <xsl:apply-templates select="." mode="type-name" />
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="number" />
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- title plain, separated -->
    <xsl:text>&amp;</xsl:text>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
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
    <xsl:if test="department|institution|email">
        <xsl:text>\contributorinfo{</xsl:text>
        <xsl:if test="department">
            <xsl:apply-templates select="department" />
            <xsl:if test="department/following-sibling::*">
                <xsl:text>\\&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
        <xsl:if test="institution">
            <xsl:apply-templates select="institution" />
            <xsl:if test="institution/following-sibling::*">
                <xsl:text>\\&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
        <xsl:if test="location">
            <xsl:apply-templates select="location" />
            <xsl:if test="location/following-sibling::*">
                <xsl:text>\\&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
        <xsl:if test="email">
            <xsl:text>\texttt{</xsl:text>
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
    <xsl:apply-templates />
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

<!-- TODO: split out an appendix-specific version of following? -->

<!-- Subdivisions, Parts down to Subsubsections               -->
<!-- Mostly relies on element names echoing latex names       -->
<!-- (1) appendices are just chapters after \appendix macro -->
<!-- (2) exercises, references can appear at any depth,       -->
<!--     so compute the subdivision name                      -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|exercises|references">
    <!-- appendices are peers of chapters (book) or sections (article)  -->
    <!-- so we need to slip this in first, with book's \backmatter later-->
    <!-- NB: if no appendices, the backmatter template does \backmatter -->
    <xsl:if test="self::appendix and not(preceding-sibling::appendix)">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>\appendix&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="console-typeout" />
    <xsl:apply-templates select="." mode="begin-language" />
    <!-- Construct the header of the subdivision -->
    <xsl:text>\</xsl:text>
    <xsl:apply-templates select="." mode="division-name" />
    <!-- Handle section titles carefully.  Sanitized versions    -->
    <!-- as optional argument to table of contents, headers.     -->
    <!-- http://www.tex.ac.uk/cgi-bin/texfaq2html?label=ftnsect  -->
    <!-- TODO: get non-footnote title from "simple" title routines -->
    <!-- TODO: let author specify short versions (ToC, header) -->
    <!--                                                                   -->
    <!-- There is no \backmatter macro for the article class               -->
    <!-- A final references section and a back colophon need to have their -->
    <!-- number suppressed and a table of contents entry manufactured      -->
    <!-- This ad-hoc treatment seems preferable to a more general scheme,  -->
    <!-- but maybe someday numbering will be on/off and this will be easy  -->
    <!--                                                              -->
    <!-- LaTeX's *optional* arguments are counter to TeX's arguments  -->
    <!-- So text in an optional argument should always be in a group, -->
    <!-- especially if it contains a closing bracket                  -->
    <!-- We have such protection below, and elsewhere without comment -->
    <!-- See http://tex.stackexchange.com/questions/99495             -->
    <!-- LaTeX3e with the xparse package might make this unnecessary  -->
    <xsl:choose>
        <!-- No numbering of article/backmatter/references-->
        <xsl:when test="ancestor::article and parent::backmatter and self::references">
            <xsl:text>*</xsl:text>
        </xsl:when>
    </xsl:choose>
    <!-- Short versions of titles get used in ToC (unless starred just above) -->
    <xsl:text>[{</xsl:text>
    <xsl:apply-templates select="." mode="title-simple"/>
    <xsl:text>}]</xsl:text>
    <!-- The real title and a label -->
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;</xsl:text>
    <!-- references need a ToC entry, maybe if a real Bibliography, this won't be needed -->
    <!-- We choose not to send the Colophon to the ToC of an article                     -->
    <!-- TODO: maybe colophon should not be in ToC for book either (need to star it?)    -->
    <xsl:if test="ancestor::article and parent::backmatter and self::references">
        <xsl:text>\addcontentsline{toc}{</xsl:text>
        <xsl:apply-templates select="." mode="division-name" />
        <xsl:text>}{</xsl:text>
        <xsl:apply-templates select="." mode="title-simple" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <!-- List the author of this division, if present -->
    <xsl:if test="author">
        <xsl:text>\noindent{\Large\textbf{</xsl:text>
        <xsl:apply-templates select="author" mode="name-list"/>
        <xsl:text>}}\par\bigskip&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="*[not(self::author)]" />
    <xsl:apply-templates select="." mode="end-language" />
    <!-- transition to book backmatter, if done with last appendix -->
    <xsl:if test="ancestor::book and self::appendix and not(following-sibling::appendix)">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>\backmatter&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Information to console for latex run -->
<xsl:template match="*" mode="console-typeout">
    <xsl:text>\typeout{************************************************}&#xa;</xsl:text>
    <xsl:text>\typeout{</xsl:text>
    <xsl:apply-templates select="." mode="long-name" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\typeout{************************************************}&#xa;</xsl:text>
</xsl:template>


<!-- Introductions and Conclusions -->
<!-- Simple containers, allowed before and after      -->
<!-- explicit subdivisions, to introduce or summarize -->
<!-- Title optional (and discouraged),                -->
<!-- typically just a few paragraphs                  -->
<!-- TOD0: design a LaTeX environment to make this more semantic -->
<xsl:template match="introduction[title]|conclusion[title]">
    <xsl:if test="self::*[&STRUCTURAL-FILTER;]">
        <xsl:apply-templates select="." mode="console-typeout" />
    </xsl:if>
    <xsl:text>\</xsl:text>
    <xsl:apply-templates select="." mode="division-name" />
    <xsl:text>*{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="*" />
</xsl:template>

<!-- Spacing comes from division header above, subdivision header below -->
<xsl:template match="introduction">
    <xsl:if test="self::*[&STRUCTURAL-FILTER;]">
        <xsl:apply-templates select="." mode="console-typeout" />
    </xsl:if>
    <xsl:apply-templates select="*" />
</xsl:template>

<!-- Most introductions are followed by other sectioning blocks (e.g. subsection) -->
<!-- And then there is a resetting of the carriage. An introduction preceding a   -->
<!-- webwork needs an additional \par at the end (if there even was an intro)     -->
<xsl:template match="introduction[following-sibling::webwork]">
    <xsl:apply-templates select="*" />
    <xsl:text>\par\medskip&#xa;</xsl:text>
</xsl:template>

<xsl:template match="exercisegroup/introduction">
    <xsl:text>\par\noindent </xsl:text>
    <xsl:apply-templates select="*" />
</xsl:template>

<!-- Last subdivision just ends, presumably a \par is order -->
<!-- Some visual separation is a necessity, with no title   -->
<!-- "break" command is like also using a \par and encourages a page break     -->
<!-- http://tex.stackexchange.com/questions/41476/lengths-and-when-to-use-them -->
<xsl:template match="conclusion">
    <xsl:if test="self::*[&STRUCTURAL-FILTER;]">
        <xsl:apply-templates select="." mode="console-typeout" />
    </xsl:if>
    <xsl:text>\bigbreak&#xa;</xsl:text>
    <xsl:apply-templates select="*" />
</xsl:template>

<!-- webwork conclusions forego the \bigbreak  -->
<!-- To stand apart, a medskip and noindent    -->
<xsl:template match="conclusion[preceding-sibling::webwork]">
    <xsl:text>\medskip\noindent </xsl:text>
    <xsl:apply-templates select="*" />
    <xsl:text>\par&#xa;</xsl:text>
</xsl:template>

<xsl:template match="exercisegroup/conclusion">
    <xsl:apply-templates select="*" />
</xsl:template>

<!-- Statement -->
<!-- Simple containier for blocks with structured contents -->
<!-- Consumers are responsible for surrounding breaks      -->
<xsl:template match="statement">
    <xsl:apply-templates select="*" />
</xsl:template>

<!-- Prelude, Interlude, Postlude -->
<!-- Very simple containiers, to help with movement, use -->
<xsl:template match="prelude|interlude|postlude">
    <xsl:text>\par&#xa;</xsl:text>
    <xsl:apply-templates select="*" />
</xsl:template>


<!-- Paragraphs -->
<!-- Non-structural, even if they appear to be -->
<!-- Note: Presumes we never go below subsubsection  -->
<!-- in our MBX hierarchy and bump into this level   -->
<!-- Maybe then migrate to "subparagraph"?           -->
<xsl:template match="paragraphs">
    <!-- Warn about paragraph deprecation -->
    <xsl:apply-templates select="." mode="console-typeout" />
    <xsl:text>\paragraph</xsl:text>
    <!-- keep optional title if LaTeX source is re-purposed -->
    <xsl:text>[{</xsl:text>
    <xsl:apply-templates select="." mode="title-simple" />
    <xsl:text>}]</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="*" />
</xsl:template>

<!-- Theorems, Proofs, Definitions, Examples, Exercises -->

<!-- Theorems have statement/proof structure                    -->
<!-- Definitions have notation, which is handled elsewhere      -->
<!-- Examples have no structure, or have statement and solution -->
<!-- Exercises have hints, answers and solutions                -->

<!-- Titles are passed as options to environments -->
<!-- TODO: trash and incorporate into templates below -->
<xsl:template match="title" mode="environment-option">
    <xsl:text>[{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}]</xsl:text>
</xsl:template>

<!-- Theorems, Axioms, Definitions -->
<!-- Statement structure should be relaxed,       -->
<!-- especially for axioms, definitions, style is -->
<!-- controlled in the premable by the theorem    -->
<!-- style parameters in effect when LaTeX        -->
<!-- environments are declared                    -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;">
    <xsl:text>\begin{</xsl:text>
        <xsl:value-of select="local-name(.)" />
    <xsl:text>}</xsl:text>
    <!-- optional argument to environment -->
    <!-- TODO: and/or credit              -->
    <xsl:text>[{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}]</xsl:text>
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- statement is required now, to be relaxed in DTD      -->
    <!-- explicitly ignore proof and pickup just for theorems -->
    <xsl:apply-templates select="*[not(self::proof)]" />
    <xsl:text>\end{</xsl:text>
        <xsl:value-of select="local-name(.)" />
    <xsl:text>}&#xa;</xsl:text>
    <!-- proof is optional, so may not match at  -->
    <!-- all, make sure proof is not possible    -->
    <!-- for AXIOM-LIKE and DEFINITION-LIKE      -->
    <xsl:if test="&THEOREM-FILTER;">
        <xsl:apply-templates select="proof" />
    </xsl:if>
</xsl:template>

<!-- Proofs -->
<!-- Subsidary to THEOREM-LIKE, or standalone -->
<xsl:template match="proof">
    <xsl:text>\begin{proof}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="*" />
    <xsl:text>\end{proof}&#xa;</xsl:text>
</xsl:template>

<!-- cases in proofs -->
<!-- No newline after macros, so inline to text      -->
<!-- A proof gets no metadata in DTD                 -->
<!-- but if that changes, ignore in "preceding" test -->
<xsl:template match="case">
    <xsl:if test="preceding-sibling::*">
        <xsl:text>\par\medskip\noindent&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="label" />
    <xsl:choose>
        <xsl:when test="@direction='forward'">
            <xsl:text>\forwardimplication{}</xsl:text>
        </xsl:when>
        <xsl:when test="@direction='backward'">
            <xsl:text>\backwardimplication{}</xsl:text>
        </xsl:when>
        <!-- DTD will catch wrong values -->
        <xsl:otherwise />
    </xsl:choose>
    <!-- arrows should provide trailing space here -->
    <xsl:if test="title">
        <xsl:text>\textit{</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>}. </xsl:text>
    </xsl:if>
    <!-- period should provide trailing space -->
    <xsl:apply-templates select="*" />
</xsl:template>

<!-- ######### -->
<!-- Exercises -->
<!-- ######### -->

<!-- Free-range exercises go into environments -->
<!-- TODO: Be more careful about notation, todo -->
<xsl:template match="exercise">
    <xsl:text>\begin{exercise}</xsl:text>
    <xsl:apply-templates select="title" mode="environment-option" />
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="statement"/>
    <xsl:apply-templates select="hint"/>
    <xsl:apply-templates select="answer"/>
    <xsl:apply-templates select="solution"/>
    <xsl:text>\end{exercise}&#xa;</xsl:text>
</xsl:template>

<!-- Variant for free-range enclosing a WeBWorK problem -->
<!-- TODO: Be more careful about notation, todo -->
<xsl:template match="exercise[webwork]">
    <xsl:text>\begin{exercise}</xsl:text>
    <xsl:apply-templates select="title" mode="environment-option" />
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- Allow an exercise to introduce/connect a problem     -->
    <!-- (especially from server) to the text in various ways -->
    <xsl:apply-templates select="introduction"/>
    <xsl:apply-templates select="webwork" />
    <xsl:apply-templates select="conclusion"/>
    <xsl:text>\end{exercise}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="exercise[myopenmath]">
    <xsl:text>\begin{exercise}</xsl:text>
    <xsl:apply-templates select="title" mode="environment-option" />
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="introduction"/>
    <xsl:apply-templates select="myopenmath" />
    <xsl:apply-templates select="conclusion"/>
    <xsl:text>\end{exercise}&#xa;</xsl:text>
</xsl:template>

<!-- Exercise Group -->
<!-- We interrupt a description list with short commentary, -->
<!-- typically instructions for a list of similar exercises -->
<!-- Commentary goes in an introduction and/or conclusion   -->
<!-- When we point to these, we use custom hypertarget, etc -->
<xsl:template match="exercisegroup">
    <xsl:apply-templates select="." mode="label" />
    <xsl:apply-templates select="introduction" />
    <xsl:apply-templates select="exercise"/>
    <xsl:apply-templates select="conclusion" />
    <xsl:text>\par\smallskip\noindent&#xa;</xsl:text>
</xsl:template>

<!-- An exercise in an "exercises" subdivision             -->
<!-- is a list item in a description list                  -->
<!-- TODO: parameterize as a backmatter item, new switches -->
<!-- TODO: would an "exercisegrouplist" allow parameters to move to preamble? -->
<xsl:template match="exercises/exercise|exercisegroup/exercise">
    <!-- Start a list right before first exercise of subdivision, or of exercise group -->
    <xsl:choose>
        <xsl:when test="not(preceding-sibling::exercise) and parent::exercisegroup">
            <xsl:text>\begin{exercisegroup}(</xsl:text>
            <xsl:choose>
                <xsl:when test="not(../@cols)">
                    <xsl:text>1</xsl:text>
                </xsl:when>
                <xsl:when test="../@cols = 1 or ../@cols = 2 or ../@cols = 3 or ../@cols = 4 or ../@cols = 5 or ../@cols = 6">
                    <xsl:value-of select="../@cols"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">MBX:ERROR: invalid value <xsl:value-of select="../@cols" /> for cols attribute of exercisegroup</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>)&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="not(preceding-sibling::exercise) and parent::exercises">
            <xsl:text>\begin{exerciselist}&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:choose>
        <xsl:when test="parent::exercises">
            <xsl:text>\item[</xsl:text>
        </xsl:when>
        <xsl:when test="parent::exercisegroup">
            <xsl:text>\exercise[</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:apply-templates select="." mode="serial-number" />
    <xsl:text>.]</xsl:text>
    <xsl:apply-templates select="." mode="label"/>
    <xsl:if test="title">
        <xsl:text>(</xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>)\space\space{}</xsl:text>
    </xsl:if>
    <!-- condition on webwork wrapper or not -->
    <xsl:choose>
        <xsl:when test="webwork|myopenmath">
            <xsl:apply-templates select="introduction" />
            <xsl:apply-templates select="webwork|myopenmath" />
            <xsl:apply-templates select="conclusion" />
        </xsl:when>
        <xsl:otherwise>
        <!-- Order enforced: statement, hint, answer, solution -->
            <xsl:if test="$exercise.text.statement='yes'">
                <xsl:apply-templates select="statement" />
                <xsl:if test="not(parent::exercisegroup)">
                    <xsl:text>\par\smallskip&#xa;</xsl:text>
                </xsl:if>
            </xsl:if>
            <xsl:if test="hint and $exercise.text.hint='yes'">
                <xsl:apply-templates select="hint" />
            </xsl:if>
            <xsl:if test="answer and $exercise.text.answer='yes'">
                <xsl:apply-templates select="answer" />
            </xsl:if>
            <xsl:if test="solution and $exercise.text.solution='yes'">
                <xsl:apply-templates select="solution" />
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
    <!-- close list if no more exercise in subdivision or in exercise group -->
    <xsl:choose>
        <xsl:when test="not(following-sibling::exercise) and parent::exercisegroup">
            <xsl:text>\end{exercisegroup}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="not(following-sibling::exercise) and parent::exercises">
            <xsl:text>\end{exerciselist}&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Assume various solution-types with non-blank line and newline -->
<!-- Heading template is elsewhere and should come closer on a reorganization -->
<xsl:template match="exercise/hint|exercise/answer|exercise/solution">
    <xsl:apply-templates select="." mode="solution-heading" />
    <xsl:apply-templates />
</xsl:template>

<!-- This is a hack that should go away when backmatter exercises are rethought -->
<xsl:template match="title" mode="backmatter" />

<xsl:template match="solution-list">
    <!-- TODO: check here once for backmatter switches set to "knowl", which is unrealizable -->
    <xsl:apply-templates select="//exercises" mode="backmatter" />
</xsl:template>

<!-- Create a heading for each non-empty collection of solutions -->
<!-- Format as appropriate LaTeX subdivision for this level      -->
<!-- But number according to the actual Exercises section        -->
<xsl:template match="exercises" mode="backmatter">
    <xsl:variable name="nonempty" select="(.//hint and $exercise.backmatter.hint='yes') or (.//answer and $exercise.backmatter.answer='yes') or (.//solution and $exercise.backmatter.solution='yes')" />
    <xsl:if test="$nonempty='true'">
        <xsl:text>\</xsl:text>
        <xsl:apply-templates select="." mode="division-name" />
        <xsl:text>*{</xsl:text>
        <xsl:apply-templates select="." mode="number" />
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>}&#xa;</xsl:text>
        <xsl:apply-templates select="*" mode="backmatter" />
    </xsl:if>
</xsl:template>

<!-- We kill the introduction and conclusion for -->
<!-- the exercises and for the exercisegroups    -->
<xsl:template match="exercises//introduction|exercises//conclusion" mode="backmatter" />

<!-- Print exercises with some solution component -->
<!-- Respect switches about visibility ("knowl" is assumed to be 'no') -->
<xsl:template match="exercise" mode="backmatter">
    <xsl:if test="hint or answer or solution">
        <!-- Lead with the problem number and some space -->
        <xsl:text>\noindent\textbf{</xsl:text>
        <xsl:apply-templates select="." mode="serial-number" />
        <xsl:text>.}\quad{}</xsl:text>
        <xsl:if test="$exercise.backmatter.statement='yes'">
            <!-- TODO: not a "backmatter" template - make one possibly? Or not necessary -->
            <xsl:apply-templates select="statement" />
            <xsl:text>\par\smallskip&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="hint and $exercise.backmatter.hint='yes'">
            <xsl:apply-templates select="hint" mode="backmatter" />
        </xsl:if>
        <xsl:if test="answer and $exercise.backmatter.answer='yes'">
            <xsl:apply-templates select="answer" mode="backmatter" />
        </xsl:if>
        <xsl:if test="solution and $exercise.backmatter.solution='yes'">
            <xsl:apply-templates select="solution" mode="backmatter" />
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- We print hints, answers, solutions with no heading. -->
<!-- TODO: make heading on solution components configurable -->
<xsl:template match="exercise/hint|exercise/answer|exercise/solution" mode="backmatter">
    <xsl:apply-templates />
    <xsl:text>\par\smallskip&#xa;</xsl:text>
</xsl:template>


<!-- WeBWorK exercises, LaTeX representation -->
<!-- Conversion of MBX-authored parts of a   -->
<!-- WW problem, with usual MBX elements     -->
<!-- mixed in, to LaTeX representations      -->

<!-- Top-down structure -->
<!-- Basic outline of a simple problem -->
<xsl:template match="webwork[child::statement]">
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="hint" />
    <xsl:apply-templates select="solution" />
</xsl:template>

<!-- Basic outline of a multistage problem    -->
<!-- Known in WeBWorK as a "scaffold" problem -->
<xsl:template match="webwork[child::stage]">
    <xsl:apply-templates select="stage" />
</xsl:template>

<!-- A stage is a subproblem in a multistage problem -->
<!-- Implemented as as "section" in WeBWorK          -->
<xsl:template match="webwork/stage">
    <!-- employ title here to identify different stages -->
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="hint" />
    <xsl:apply-templates select="solution" />
</xsl:template>

<!-- WW macros and setup do not need processing,  -->
<!-- though we do examine static values of "var"s -->
<xsl:template match="webwork/macros" />
<xsl:template match="webwork/setup" />

<!-- default template for problem statement -->
<xsl:template match="webwork//statement">
    <xsl:text>\noindent%&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\par&#xa;</xsl:text>
</xsl:template>

<!-- For statements inside a "stage" of a problem -->
<!-- TODO: internationalize Part                  -->
<xsl:template match="webwork//statement[parent::stage]">
    <xsl:choose>
        <xsl:when test="not(parent::stage/preceding-sibling::stage)">
            <xsl:text>\par</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\medskip</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\noindent%&#xa;</xsl:text>
    <xsl:text>\textbf{Part </xsl:text>
    <xsl:apply-templates select="parent::stage" mode="serial-number" />
    <xsl:text>.}\quad </xsl:text>
    <xsl:apply-templates />
    <xsl:text>\par&#xa;</xsl:text>
</xsl:template>

<!-- default template, for solution -->
<xsl:template match="webwork//solution">
    <xsl:text>\medskip\noindent%&#xa;</xsl:text>
    <xsl:text>\textbf{Solution.}\quad </xsl:text>
    <xsl:apply-templates />
    <xsl:text>\par&#xa;</xsl:text>
</xsl:template>

<!-- default template, for hint -->
<xsl:template match="webwork//hint">
    <xsl:text>\medskip\noindent%&#xa;</xsl:text>
    <xsl:text>\textbf{Hint.}\quad </xsl:text>
    <xsl:apply-templates />
    <xsl:text>\par&#xa;</xsl:text>
</xsl:template>

<!-- A "var" in setup will never be processed,  -->
<!-- since we kill "setup" and do not descend  -->
<!-- into it, so this match should be sufficient -->
<xsl:template match="webwork//var">
    <xsl:variable name="problem" select="ancestor::webwork" />
    <xsl:variable name="varname" select="@name" />
    <xsl:choose>
        <xsl:when test="$problem/setup/var[@name=$varname]/set">
        <xsl:for-each select="$problem/setup/var[@name=$varname]/set/member[@correct='yes']">
            <xsl:apply-templates select='.' />
            <xsl:choose>
                <xsl:when test="count(following-sibling::member[@correct='yes']) &gt; 1">
                    <xsl:text>, </xsl:text>
                </xsl:when>
                <xsl:when test="(count(following-sibling::member[@correct='yes']) = 1) and preceding-sibling::member[@correct='yes']">
                    <xsl:text>, and </xsl:text>
                </xsl:when>
                <xsl:when test="(count(following-sibling::member[@correct='yes']) = 1) and not(preceding-sibling::member[@correct='yes'])">
                    <xsl:text> and </xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$problem/setup/var[@name=$varname]/static" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- PGML answer blank               -->
<!-- Example: [_____]{$ans}          -->
<xsl:template match="webwork//statement//var[@width|@form]">
    <xsl:variable name="problem" select="ancestor::webwork" />
    <xsl:variable name="varname" select="@name" />
    <xsl:choose>
        <xsl:when test="@form='popup'" >
            <xsl:text>(Choose one: </xsl:text>
            <xsl:for-each select="$problem/setup/var[@name=$varname]/set/member">
                <xsl:apply-templates select='.' />
                <xsl:choose>
                    <xsl:when test="count(following-sibling::member) &gt; 1">
                        <xsl:text>, </xsl:text>
                    </xsl:when>
                    <xsl:when test="(count(following-sibling::member) = 1) and preceding-sibling::member">
                        <xsl:text>, or </xsl:text>
                    </xsl:when>
                    <xsl:when test="(count(following-sibling::member) = 1) and not(preceding-sibling::member)">
                        <xsl:text> / </xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
            <xsl:text>)</xsl:text>
        </xsl:when>
        <!-- TODO: make semantic list style in preamble -->
        <xsl:when test="@form='buttons'" >
            <xsl:text>\par&#xa;</xsl:text>
            <xsl:text>\begin{itemize}[label=$\odot$,leftmargin=3em,]&#xa;</xsl:text>
            <xsl:for-each select="$problem/setup/var[@name=$varname]/set/member">
                <xsl:text>\item{}</xsl:text>
                <xsl:apply-templates select='.' />
                <xsl:text>&#xa;</xsl:text>
            </xsl:for-each>
            <xsl:text>\end{itemize}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="@form='checkboxes'" >
            <xsl:text>\par&#xa;</xsl:text>
            <xsl:text>\begin{itemize}[label=$\square$,leftmargin=3em,]&#xa;</xsl:text>
            <xsl:for-each select="$problem/setup/var[@name=$varname]/set/member">
                <xsl:text>\item{}</xsl:text>
                <xsl:apply-templates select='.' />
                <xsl:text>&#xa;</xsl:text>
            </xsl:for-each>
            <xsl:text>\end{itemize}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text> \framebox[</xsl:text>
            <xsl:choose>
                <xsl:when test="@width">
                    <xsl:value-of select="@width" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>5</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>em]</xsl:text>
            <!-- on baseline, height proportional to font -->
            <xsl:text>{\raisebox{1ex}{}}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- An essay answer has no variable associated with the textbox,  -->
<!-- so we simply indicate that this problem has an essay answer   -->
<xsl:template match="webwork//var[@form='essay']">
    <xsl:text>\quad\lbrack Essay Answer\rbrack</xsl:text>
</xsl:template>

<!-- ############################# -->
<!-- WeBWorK Problems from Servers -->
<!-- ############################# -->

<!-- @source, in an otherwise empty "webwork" element,     -->
<!-- indicates the problem lives on a server.  HTML        -->
<!-- output has no problem with that (it is easier than    -->
<!-- locally authored).  For LaTeX, the  mbx  script       -->
<!-- fetches a LaTeX rendering and associated image files. -->
<!-- Here, we just provide a light wrapper, and drop an    -->
<!-- include, since the basename for the filenames has     -->
<!-- been managed by the  mbx  script to be predictable.   -->
<xsl:template match="webwork[@source]">
    <!-- directory of server LaTeX must be specified -->
    <xsl:if test="$webwork.server.latex = ''">
        <xsl:message terminate="yes">MBX:ERROR   For LaTeX versions of WeBWorK problems on a server, the mbx script will collect the LaTeX source and then this conversion must specify the location through the "webwork.server.latex" command line stringparam.  Quitting...</xsl:message>
    </xsl:if>
    <xsl:variable name="xml-filename">
        <!-- assumes path has trailing slash -->
        <xsl:value-of select="$webwork.server.latex" />
        <xsl:apply-templates select="." mode="internal-id" />
        <xsl:text>.xml</xsl:text>
    </xsl:variable>
    <xsl:variable name="server-tex" select="document($xml-filename)/webwork-tex" />
    <!-- An enclosing exercise may introduce/connect the server-version problem. -->
    <!-- Then formatting is OK.  Otherwise we need a faux sentence instead.      -->
    <xsl:text>\mbox{}\\ % hack to move box after heading&#xa;</xsl:text>
    <xsl:apply-templates select="introduction" /> <!-- before boxed problem -->
    <xsl:text>\begin{mdframed}&#xa;</xsl:text>
    <xsl:text>{</xsl:text> <!-- prophylactic wrapper -->
    <!-- mbx script collects problem preamble, but we do not use it here -->
    <!-- process in the order server produces them, may be several -->
    <xsl:apply-templates select="$server-tex/statement|$server-tex/solution|$server-tex/hint" />
    <xsl:text>}</xsl:text>
    <xsl:text>\par\vspace*{2ex}%&#xa;</xsl:text>
    <xsl:text>{\tiny\ttfamily\noindent\url{</xsl:text>
    <xsl:value-of select="@source" />
    <xsl:text>}\\</xsl:text>
    <!-- seed will round-trip through mbx script, default -->
    <!-- is hard-coded there.  It comes back as an        -->
    <!-- attribute of the overall "webwork-tex" element   -->
    <xsl:text>Seed: </xsl:text>
    <xsl:value-of select="$server-tex/@seed" />
    <xsl:text>\hfill</xsl:text>
    <xsl:text>}</xsl:text>  <!-- end: \tiny\ttfamily -->
    <xsl:text>\end{mdframed}&#xa;</xsl:text>
    <xsl:apply-templates select="conclusion" /> <!-- after boxed problem -->
</xsl:template>

<!-- We respect switches by implementing templates     -->
<!-- for each part of the problem that use the switch. -->
<!-- This allows processing above in document order    -->
<xsl:template match="webwork-tex/statement">
    <xsl:if test="$exercise.text.statement = 'yes'">
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>
<xsl:template match="webwork-tex/solution">
    <xsl:if test="$exercise.text.solution = 'yes'">
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>
<xsl:template match="webwork-tex/hint">
    <xsl:if test="$exercise.text.hint = 'yes'">
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>

<!-- ############################# -->
<!-- WeBWorK Images   from Servers -->
<!-- ############################# -->

<!-- When a webwork exercise is written in MBX source, but -->
<!-- uses an image with an @pg-name, we make the exercise  -->
<!-- in the usual way but include an image which has been  -->
<!-- created by the mbx script with a predictable name     -->
<!-- For such images, width and height are pixel counts    -->
<!-- sent to the PG image creator, intended to define the  -->
<!-- width of HTML output. A separate tex-size is intended -->
<!-- to define width of LaTeX output. tex-size of say 800  -->
<!-- means 0.800\linewidth. We use 400px for the default   -->
<!-- width in mathbook-webwork-pg. Since 600px is the      -->
<!-- default design width in html, we use 667 as the       -->
<!-- default for tex-size                                  -->

<xsl:template match="webwork//image[@pg-name]">
    <xsl:variable name="width">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:text>\includegraphics[width=</xsl:text>
    <xsl:value-of select="substring-before($width,'%') div 100" />
    <xsl:text>\linewidth]</xsl:text>
    <xsl:text>{</xsl:text>
    <!-- assumes path has trailing slash -->
    <xsl:value-of select="$webwork.server.latex" />
    <xsl:apply-templates select="ancestor::webwork" mode="internal-id" />
    <xsl:text>-image-</xsl:text>
    <xsl:number count="image[@pg-name]" from="webwork" level="any" />
    <xsl:text>.png</xsl:text>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- ################### -->
<!-- MyOpenMath Problems -->
<!-- ################### -->


<!-- Static MyOpenMath Exercises -->
<!-- We only try to open an external file when the source -->
<!-- has a MOM problem (with an id number).  The second   -->
<!-- argument of the "document()" function is a node and  -->
<!-- causes the relative file name to resolve according   -->
<!-- to the location of the XML.   Experiments with the   -->
<!-- empty node "/.." are interesting.                    -->
<!-- https://ajwelch.blogspot.co.za/2008/04/relative-paths-and-document-function.html -->
<!-- http://www.dpawson.co.uk/xsl/sect2/N2602.html#d3862e73 (Point 4) -->

<xsl:template match="myopenmath">
    <xsl:variable name="filename" select="concat(concat('problems/mom-', @problem), '.xml')" />
    <xsl:apply-templates select="document($filename, .)/myopenmath/*" />
</xsl:template>

<xsl:template match="myopenmath/solution">
    <xsl:apply-templates select="." mode="solution-heading" />
    <xsl:apply-templates />
</xsl:template>


<!-- Remark Like, Computation Like Example Like, Project Like -->
<!-- Simpler than theorems, definitions, etc            -->
<!-- Information comes from self, so slightly different -->
<xsl:template match="&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;">
    <xsl:if test="statement or ((&PROJECT-FILTER;) and task)">
        <xsl:apply-templates select="prelude" />
    </xsl:if>
    <xsl:text>\begin{</xsl:text>
        <xsl:value-of select="local-name(.)" />
    <xsl:text>}</xsl:text>
    <!-- optional argument to environment -->
    <!-- TODO: and/or credit              -->
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>]</xsl:text>
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:choose>
        <!-- structured versions first      -->
        <!-- prelude?, introduction?, task+,   -->
        <!-- conclusion?, postlude? -->
        <xsl:when test="(&PROJECT-FILTER;) and task">
            <xsl:apply-templates select="introduction"/>
            <!-- careful right after project heading -->
            <xsl:if test="not(introduction)">
                <xsl:call-template name="leave-vertical-mode" />
            </xsl:if>
            <xsl:apply-templates select="task"/>
            <xsl:apply-templates select="conclusion"/>
        </xsl:when>
        <!-- Now no project/task possibility -->
        <!-- prelude?, statement, hint*,   -->
        <!-- answer*, solution*, postlude? -->
        <xsl:when test="statement">
            <xsl:apply-templates select="statement"/>
            <xsl:apply-templates select="hint"/>
            <xsl:apply-templates select="answer"/>
            <xsl:apply-templates select="solution"/>
        </xsl:when>
        <!-- Potential common mistake, no content results-->
        <xsl:when test="prelude|hint|answer|solution|postlude">
            <xsl:message>MBX:WARNING: a &lt;prelude&gt;, &lt;hint&gt;, &lt;answer&gt;, &lt;solution&gt;, or &lt;postlude&gt; in a remark-like, computation-like, example-like, or project-like block will need to also be structured with a &lt;statement&gt;.  Content will be missing from output.</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
        <!-- unstructured, no need to avoid dangerous misunderstandings -->
        <xsl:otherwise>
            <xsl:apply-templates select="*"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\end{</xsl:text>
        <xsl:value-of select="local-name(.)" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:if test="statement or ((&PROJECT-FILTER;) and task)">
        <xsl:apply-templates select="postlude" />
    </xsl:if>
</xsl:template>

<!-- Task (a part of a project) -->
<xsl:template match="task">
    <!-- if first at its level, start the list environment -->
    <xsl:if test="not(preceding-sibling::task)">
        <!-- set the label style of this list       -->
        <!-- using features of the enumitem package -->
        <xsl:text>\begin{enumerate}[font=\bfseries,label=</xsl:text>
        <xsl:choose>
            <!-- three deep -->
            <xsl:when test="parent::task/parent::task">
                <xsl:text>(\Alph*),ref=\theenumi.\theenumii.\Alph*</xsl:text>
            </xsl:when>
            <!-- two deep -->
            <xsl:when test="parent::task">
                <xsl:text>(\roman*),ref=\theenumi.\roman*</xsl:text>
            </xsl:when>
            <!-- one deep -->
            <xsl:otherwise>
                <xsl:text>(\alph*),ref=\alph*</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>]&#xa;</xsl:text>
    </xsl:if>
    <!-- always a list item, note space -->
    <xsl:text>\item</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text> </xsl:text>
    <!-- more structured versions first -->
    <xsl:choose>
        <!-- introduction?, task+, conclusion? -->
        <xsl:when test="task">
            <xsl:apply-templates select="introduction"/>
            <xsl:apply-templates select="task"/>
            <xsl:apply-templates select="conclusion"/>
        </xsl:when>
        <!-- statement, hint*, answer*, solution* -->
        <xsl:when test="statement">
            <xsl:apply-templates select="statement"/>
            <xsl:apply-templates select="hint"/>
            <xsl:apply-templates select="answer"/>
            <xsl:apply-templates select="solution"/>
        </xsl:when>
        <!-- unstructured -->
        <xsl:otherwise>
            <xsl:apply-templates />
        </xsl:otherwise>
    </xsl:choose>
    <!-- if last at its level, end the list environment -->
    <xsl:if test="not(following-sibling::task)">
        <xsl:text>\end{enumerate}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- An aside goes into a framed box             -->
<!-- We do not distinguish biographical or       -->
<!-- historical semantically, but perhaps should -->
<!-- title is inline, boldface in mdframe setup  -->
<xsl:template match="&ASIDE-LIKE;">
    <xsl:text>\begin{aside}{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="p|&FIGURE-LIKE;|sidebyside" />
    <xsl:text>\end{aside}&#xa;</xsl:text>
</xsl:template>

<!-- Assemblages -->
<!-- Low-structure content, high-visibility presentation -->
<!-- Title is optional, keep remainders coordinated      -->

<xsl:template match="assemblage">
    <xsl:text>\begin{assemblage}</xsl:text>
    <xsl:if test="title">
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="p|blockquote|pre|sidebyside|sbsgroup" />
    <xsl:text>\end{assemblage}&#xa;</xsl:text>
</xsl:template>

<!-- An objectives element holds a list, surrounded by introduction and conclusion -->
<xsl:template match="objectives">
    <xsl:text>\begin{objectives}{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'objectives'" />
    </xsl:call-template>
    <xsl:if test="title">
        <xsl:text>: </xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
    </xsl:if>
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="introduction" />
    <xsl:apply-templates select="ol|ul|dl" />
    <xsl:apply-templates select="conclusion" />
    <xsl:text>\end{objectives}&#xa;</xsl:text>
</xsl:template>

<!-- Examples can have hints, answers or solutions, -->
<!-- but as examples we don't turn them on or off   -->
<xsl:template match="hint[parent::*[&EXAMPLE-FILTER;]]|answer[parent::*[&EXAMPLE-FILTER;]]|solution[parent::*[&EXAMPLE-FILTER;]]|">
    <xsl:apply-templates select="." mode="solution-heading" />
    <xsl:apply-templates />
</xsl:template>

<!-- TODO: consolidate three tests twice,      -->
<!-- and use modal template (ala EXAMPLE-LIKE) -->
<!-- and/or make a template to check if visible or not -->

<!-- A project may have a hint, with switch control -->
<xsl:template match="hint[parent::*[&PROJECT-FILTER;]]">
    <xsl:if test="$project.text.hint = 'yes'">
        <xsl:apply-templates select="." mode="solution-heading" />
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>

<!-- A project may have an answer, with switch control-->
<xsl:template match="answer[parent::*[&PROJECT-FILTER;]]">
    <xsl:if test="$project.text.answer = 'yes'">
        <xsl:apply-templates select="." mode="solution-heading" />
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>

<!-- A project may have a solution, with switch control -->
<xsl:template match="solution[parent::*[&PROJECT-FILTER;]]">
    <xsl:if test="$project.text.solution = 'yes'">
        <xsl:apply-templates select="." mode="solution-heading" />
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>

<!-- A task may have a hint, with switch control -->
<xsl:template match="hint[parent::task]">
    <xsl:if test="$task.text.hint = 'yes'">
        <xsl:apply-templates select="." mode="solution-heading" />
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>

<!-- A task may have an answer, with switch control -->
<xsl:template match="answer[parent::task]">
    <xsl:if test="$task.text.answer = 'yes'">
        <xsl:apply-templates select="." mode="solution-heading" />
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>

<!-- A task may have a solution, with switch control -->
<xsl:template match="solution[parent::task]">
    <xsl:if test="$task.text.solution = 'yes'">
        <xsl:apply-templates select="." mode="solution-heading" />
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>

<!-- move this someplace where exercise routines are consolidated -->
<xsl:template match="hint|answer|solution" mode="solution-heading">
    <xsl:text>\par\smallskip%&#xa;</xsl:text>
    <xsl:text>\noindent\textbf{</xsl:text>
    <xsl:apply-templates select="." mode="type-name" />
    <!-- An empty value means element is a singleton -->
    <!-- else the serial number comes through        -->
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="non-singleton-number" />
    </xsl:variable>
    <xsl:if test="not($the-number = '')">
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="serial-number" />
    </xsl:if>
    <xsl:if test="title">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:text>.}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>\quad%&#xa;</xsl:text>
</xsl:template>

<!-- Named Lists -->
<xsl:template match="list">
    <xsl:text>\begin{namedlist}&#xa;</xsl:text>
    <xsl:text>\begin{namedlistcontent}&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::caption)]"/>
    <xsl:text>\end{namedlistcontent}&#xa;</xsl:text>
    <!-- Titled/environment version deprecated 2017-08-25   -->
    <!-- Title only is converted on the fly here            -->
    <!-- Schema requires a caption, so this is OK long-term -->
    <!-- (There is a template for all captions elsewhere)   -->
    <xsl:if test="title and not(caption)">
        <xsl:text>\captionof{namedlistcap}{</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:apply-templates select="." mode="label" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="caption" />
    <xsl:text>\end{namedlist}&#xa;</xsl:text>
</xsl:template>

<!-- Paragraphs -->
<!-- \par *separates* paragraphs So look backward for          -->
<!-- cases where a paragraph would have been the previous      -->
<!-- thing in the output Not: "notation", "todo", index, etc   -->
<!-- Guarantee: Never a blank line, always finish with newline -->
<!--                                                           -->
<!-- Note: a paragraph could end with an item we want          -->
<!-- to look good in teh source, like a list or display        -->
<!-- math and we already have a newline so any subsequent      -->
<!-- content from the paragraph will start anwew.  But         -->
<!-- there might not be anything more to output.  So we        -->
<!-- always end with a %-newline combo.                        -->

<!-- TODO: maybe we could look backward at the end of a paragraph       -->
<!-- to see if the above scenario happens, and we could end gracefully. -->
<xsl:template match="p">
    <xsl:if test="preceding-sibling::*[not(&SUBDIVISION-METADATA-FILTER;)][1][self::p or self::paragraphs or self::sidebyside]">
        <xsl:text>\par&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- For a memo, not indenting the first paragraph helps -->
<!-- with alignment and the to/from/subject/date block   -->
<!-- TODO: maybe memo header should set this up          -->
<xsl:template match="memo/p[1]">
    <xsl:text>\noindent{}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates />
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

<!-- Inline Mathematics ("m") -->
<!-- We use the asymmetric LaTeX delimiters \( and \).     -->
<!-- For LaTeX these are not "robust", hence break moving  -->
<!-- items (titles, index), so use the "fixltx2e" package, -->
<!-- which declares \MakeRobust\( and \MakeRobust\)        -->
<!-- Note: LaTeX, unlike HTML, needs no help with          -->
<!-- clause-ending punctuation trailing inline math,       -->
<!-- it always does the right thing.  So when the general  -->
<!-- template for text nodes in -common goes to drop this  -->
<!-- punctuation, it also checks the $latex-processing     -->
<!-- global variable                                       -->
<!-- NB: we should be able to use templates to make this   -->
<!-- happen without the global variable                    -->

<!-- These two templates provide the delimiters for -->
<!-- inline math, implementing abstract templates.  -->
<xsl:template name="begin-inline-math">
    <xsl:text>\(</xsl:text>
</xsl:template>

<xsl:template name="end-inline-math">
    <xsl:text>\)</xsl:text>
</xsl:template>

<!-- This is the override for LaTeX processing,        -->
<!-- since punctuation following inline math is        -->
<!-- not a problem for traditional TeX's line-breaking -->
<xsl:template match="m" mode="get-clause-punctuation" />


<!-- Displayed Single-Line Math ("me", "men") -->

<!-- All displayed mathematics gets wrapped by  -->
<!-- an abstract template, a necessity for HTML -->
<!-- output.  It is unnecessary for LaTeX, and  -->
<!-- so just a copy machine.                    -->
<xsl:template match="me|men|md|mdn" mode="display-math-wrapper">
    <xsl:param name="content" />
    <xsl:value-of select="$content" />
</xsl:template>


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

<!-- "me" is not numbered, not a cross-reference target -->
<xsl:template match="me" mode="tag" />

<!-- Identical to the modal "label" template,  -->
<!-- but a different name as abstract template -->
<!-- related to equation numbering             -->
<xsl:template match="men|mrow" mode="tag">
    <xsl:text>\label{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}</xsl:text>
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
    <xsl:text>\label{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- QED Here -->
<!-- Analyze a final "mrow" or any "me"                            -->
<!-- Strictly LaTeX/amsthm, not a MathJax feature (yet? ever?)     -->
<!--   (1) Locate enclosing proof, quit if no such thing           -->
<!--   (2) Check an mrow for being numbered, do not clobber that   -->
<!--   (3) Locate all trailing element, text nodes                 -->
<!--       strip-space: between "mrow" and "md" or "mdn"           -->
<!--       strip-space: between final "p" and "proof"              -->
<!--   (4) Form nodes interior to proof, and trailing ("remnants") -->
<!--   (5) At very end of proof                                    -->
<!--      (a) if no more nodes, or                                 -->
<!--      (b) one node, totally whitespace and punctuation         -->
<!--          (we don't differentiate whitespace policy here)      -->
<!--   (6) Having survived all this write a \qedhere               -->
<!-- TODO: \qedhere also functions at the end of a list            -->
<xsl:template match="men" mode="qed-here" />

<xsl:template match="mrow|me" mode="qed-here">
    <!-- <xsl:message>here</xsl:message> -->
    <xsl:variable name="enclosing-proof" select="ancestor::proof" />
    <xsl:if test="$enclosing-proof and not(self::mrow and parent::md and @number='yes') and not(self::mrow and parent::mdn and not(@number='no'))">
        <xsl:variable name="proof-nodes" select="$enclosing-proof/descendant-or-self::node()[self::* or self::text()]" />
        <xsl:variable name="trailing-nodes" select="./following::node()[self::* or self::text()]" />
        <xsl:variable name="proof-remnants" select="$proof-nodes[count(.|$trailing-nodes) = count($trailing-nodes)]" />
        <xsl:choose>
            <xsl:when test="count($proof-remnants) = 0">
                <xsl:text>\qedhere</xsl:text>
            </xsl:when>
            <xsl:when test="(count($proof-remnants) = 1) and (translate(normalize-space($proof-remnants), $clause-ending-marks, '') = '')">
                <xsl:text>\qedhere</xsl:text>
            </xsl:when>
            <xsl:otherwise />
        </xsl:choose>
    </xsl:if>
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
<!-- (2) "qed-here"                                            -->

<!-- Page Breaks within Display Math -->
<!-- \allowdisplaybreaks is on globally always          -->
<!-- If parent has  break="no"  then surpress with a *  -->
<!-- Unless "mrow" has  break="yes" then leave alone    -->
<!-- no-op for the HTML version, where it is irrelevant -->

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
    <xsl:apply-templates />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>


<!-- ##### -->
<!-- Index -->
<!-- ##### -->

<!-- Excellent built-in LaTeX support, HTML may lag -->

<!-- Unstructured                       -->
<!-- simple and quick, minimal features -->
<!-- Only supports  @sortby  attribute  -->
<xsl:template match="index[not(main) and not(index-list)] | idx[not(h)]">
    <xsl:text>\index{</xsl:text>
    <xsl:apply-templates select="@sortby" />
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Structured                                      -->
<!--   main - one only, optional @sortby             -->
<!--   sub - up two, optional, with optional @sortby -->
<!--   see, seealso - one total                      -->
<!--   @start, @finish support page ranges for print -->
<xsl:template match="index[main] | idx[h]">
    <xsl:text>\index{</xsl:text>
    <xsl:apply-templates select="h" />
    <xsl:apply-templates select="main" />
    <xsl:apply-templates select="sub" />
    <xsl:apply-templates select="see" />
    <xsl:apply-templates select="seealso" />
    <xsl:apply-templates select="@finish" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Page Range, Finish Variant              -->
<!-- @start is a marker for END of a range   -->
<!-- End of page range duplicates it's start -->
<xsl:template match="index[@start] | idx[@start]">
    <xsl:variable name="start" select="id(@start)" />
    <xsl:text>\index{</xsl:text>
    <xsl:apply-templates select="$start/h" />
    <xsl:apply-templates select="$start/main" />
    <xsl:apply-templates select="$start/sub" />
    <xsl:apply-templates select="$start/see" />
    <xsl:apply-templates select="$start/seealso" />
    <xsl:apply-templates select="@start" />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="index/main">
    <xsl:apply-templates select="@sortby" />
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="index/@sortby|main/@sortby|sub/@sortby|idx/@sortby|h/@sortby">
    <xsl:value-of select="." />
    <xsl:text>@</xsl:text>
</xsl:template>

<xsl:template match="index/sub">
    <xsl:text>!</xsl:text>
    <xsl:apply-templates select="@sortby" />
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="idx/h">
    <xsl:if test="preceding-sibling::h">
        <xsl:text>!</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="@sortby" />
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="index/see|idx/see">
    <xsl:text>|see{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="index/seealso|idx/seealso">
    <xsl:text>|seealso{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- finish  attribute suggests range (only) -->
<xsl:template match="@finish">
    <xsl:text>|(</xsl:text>
</xsl:template>

<!-- start  attribute marks end of range  -->
<xsl:template match="@start">
    <xsl:text>|)</xsl:text>
</xsl:template>

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Good match between basic HTML types and basic LaTeX types -->

<!-- Utility templates to translate MBX @label specification -->
<!-- for use with LaTeX enumitem package's label keyword     -->
<xsl:template match="ol" mode="latex-list-label">
    <xsl:variable name="mbx-format-code">
        <xsl:apply-templates select="." mode="format-code" />
    </xsl:variable>
    <!-- deconstruct the left and right adornments of the label   -->
    <!-- or provide the default adornments, consistent with LaTeX -->
    <!-- in the middle, translate MBX codes for enumitem package  -->
    <xsl:choose>
        <xsl:when test="@label">
            <xsl:value-of select="substring-before(@label, $mbx-format-code)" />
        </xsl:when>
        <xsl:when test="$mbx-format-code='a'">
            <xsl:text>(</xsl:text>
        </xsl:when>
        <xsl:otherwise />
    </xsl:choose>
    <xsl:choose>
        <xsl:when test="$mbx-format-code = '1'">\arabic*</xsl:when>
        <xsl:when test="$mbx-format-code = 'a'">\alph*</xsl:when>
        <xsl:when test="$mbx-format-code = 'A'">\Alph*</xsl:when>
        <xsl:when test="$mbx-format-code = 'i'">\roman*</xsl:when>
        <xsl:when test="$mbx-format-code = 'I'">\Roman*</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: bad MBX ordered list label format code in LaTeX conversion</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
        <xsl:when test="@label">
            <xsl:value-of select="substring-after(@label, $mbx-format-code)" />
        </xsl:when>
        <xsl:when test="$mbx-format-code='a'">
            <xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:when test="($mbx-format-code='a') or ($mbx-format-code='i') or ($mbx-format-code='A')">
            <xsl:text>.</xsl:text>
        </xsl:when>
        <xsl:otherwise />
    </xsl:choose>
</xsl:template>

<xsl:template match="ul" mode="latex-list-label">
    <xsl:variable name="mbx-format-code">
        <xsl:apply-templates select="." mode="format-code" />
    </xsl:variable>
   <xsl:choose>
        <xsl:when test="$mbx-format-code = 'disc'">\textbullet</xsl:when>
        <xsl:when test="$mbx-format-code = 'circle'">$\circ$</xsl:when>
        <xsl:when test="$mbx-format-code = 'square'">$\blacksquare$</xsl:when>
        <xsl:when test="$mbx-format-code = 'none'"></xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: bad MBX unordered list label format code in LaTeX conversion</xsl:message>
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
            <xsl:message>MBX:ERROR: unordered list is more than 4 levels deep</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Lists themselves -->
<!-- If columns are specified, we        -->
<!-- wrap in the multicolumn environment -->
<!-- TODO: fewer \leavevmode might be possible.      -->
<!-- Test for first node of "p", then test for the   -->
<!-- "p" being first node of some sectioning element -->
<!-- The \leavevmode seems to introduce too much     -->
<!-- vertical space when an "objectives" has no      -->
<!-- introduction, and its absence does not seem      -->
<!-- to cause any problems.                           -->
<xsl:template match="ol">
    <xsl:choose>
        <xsl:when test="not(ancestor::ol or ancestor::ul or ancestor::dl or parent::objectives)">
            <xsl:call-template name="leave-vertical-mode" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>%&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="@cols">
        <xsl:text>\begin{multicols}{</xsl:text>
        <xsl:value-of select="@cols" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{enumerate}</xsl:text>
    <!-- override LaTeX defaults as indicated -->
    <xsl:if test="@label or ancestor::exercises or ancestor::references">
        <xsl:text>[label=</xsl:text>
        <xsl:apply-templates select="." mode="latex-list-label" />
        <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
     <xsl:apply-templates />
    <xsl:text>\end{enumerate}&#xa;</xsl:text>
    <xsl:if test="@cols">
        <xsl:text>\end{multicols}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- MBX unordered list scheme is distinct -->
<!-- from LaTeX's so we write out a label  -->
<!-- choice for each such list             -->
<xsl:template match="ul">
    <xsl:choose>
        <xsl:when test="not(ancestor::ol or ancestor::ul or ancestor::dl or parent::objectives)">
            <xsl:call-template name="leave-vertical-mode" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>%&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="@cols">
        <xsl:text>\begin{multicols}{</xsl:text>
        <xsl:value-of select="@cols" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{itemize}[label=</xsl:text>
    <xsl:apply-templates select="." mode="latex-list-label" />
    <xsl:text>]&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{itemize}&#xa;</xsl:text>
    <xsl:if test="@cols">
        <xsl:text>\end{multicols}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="dl">
    <xsl:choose>
        <xsl:when test="not(ancestor::ol or ancestor::ul or ancestor::dl or parent::objectives)">
            <xsl:call-template name="leave-vertical-mode" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>%&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="@cols">
        <xsl:text>\begin{multicols}{</xsl:text>
        <xsl:value-of select="@cols" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{description}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{description}&#xa;</xsl:text>
    <xsl:if test="@cols">
        <xsl:text>\end{multicols}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- List Items -->
<!-- If the content is structured, we presume the last  -->
<!-- element ends the line with a newline of some sort. -->
<!-- If the content is unstructured, we end the line    -->
<!-- with at least some content (%) and a newline.      -->
<!-- Keep the tests here in sync with DTD.              -->

<!-- In an ordered list, an item can be a target -->
<xsl:template match="ol/li">
    <xsl:text>\item</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:apply-templates />
    <xsl:if test="not(p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- In an unordered list, an item cannot be a target -->
<!-- So we use an empty group to end the \item        -->
<xsl:template match="ul/li">
    <xsl:text>\item{}</xsl:text>
    <xsl:apply-templates />
    <xsl:if test="not(p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Description lists get title as additional argument -->
<xsl:template match="dl/li">
    <xsl:text>\item[{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}]</xsl:text>
    <!-- label will protect content, so no {} -->
    <xsl:apply-templates select="." mode="label" />
    <xsl:apply-templates />
</xsl:template>

<!-- Hosted Video -->
<!-- not implemented, perhaps we'll use <static> -->
<xsl:template match="video[@source]">
    <xsl:text>[video]</xsl:text>
</xsl:template>

<!-- YouTube Video -->
<!-- Assuming thumbnails have been scraped with the    -->
<!-- mbx script, we make a short static display, using -->
<!-- a title of an enclosing figure, if available      -->
<xsl:template match="video[@youtube]">
    <!-- we analyze width to figure out -->
    <!-- how long a link to write       -->
    <xsl:variable name="width">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:variable name="youtube-url-visible">
        <xsl:choose>
            <xsl:when test="substring-before($width,'%') &lt; 50">
                <xsl:text>YouTube: </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>www.youtube.com/watch?v=</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="@youtube" />
    </xsl:variable>
    <xsl:variable name="youtube-url-link">
        <xsl:text>https://www.youtube.com/watch?v=</xsl:text>
        <xsl:value-of select="@youtube" />
        <xsl:if test="@start">
            <xsl:text>\&amp;start=</xsl:text>
            <xsl:value-of select="@start" />
        </xsl:if>
        <xsl:if test="@end">
            <xsl:text>\&amp;end=</xsl:text>
            <xsl:value-of select="@end" />
        </xsl:if>
    </xsl:variable>
    <xsl:text>\begin{tabular}{m{.2\linewidth}m{.6\linewidth}}&#xa;</xsl:text>
    <xsl:text>\includegraphics[width=\linewidth]{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>.jpg}&amp;%&#xa;</xsl:text>
    <xsl:if test="parent::*[title]">
        <xsl:apply-templates select="parent::*" mode="title-full" />
        <xsl:text>\newline%&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\href{</xsl:text>
    <xsl:value-of select="$youtube-url-link" />
    <xsl:text>}{\texttt{\nolinkurl{</xsl:text>
    <xsl:value-of select="$youtube-url-visible" />
    <xsl:text>}}}&#xa;</xsl:text>
    <!-- join spaces in string so cell wraps nicely, perhaps -->
    <xsl:if test="@start or @end">
        <xsl:text> (</xsl:text>
        <xsl:if test="@start">
            <xsl:text>Start:~</xsl:text>
            <xsl:value-of select="@start" />
            <xsl:text>s</xsl:text>
        </xsl:if>
        <xsl:if test="@start and @end">
            <xsl:text>,~</xsl:text>
        </xsl:if>
        <xsl:if test="@end">
            <xsl:text>End:~</xsl:text>
            <xsl:value-of select="@end" />
            <xsl:text>s</xsl:text>
        </xsl:if>
        <xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:text>\end{tabular}&#xa;</xsl:text>
</xsl:template>

<!-- ############ -->
<!-- Music Scores -->
<!-- ############ -->

<!-- Embed an interactive score from MuseScore                          -->
<!-- Flag: score element has two MuseScore-specific attributes          -->
<!-- https://musescore.org/user/{usernumber}/scores/{scorenumber}/embed -->
<!-- into an iframe with width and height (todo)                        -->
<xsl:template match="score[@musescoreuser and @musescore]">
    <xsl:text>[\texttt{\nolinkurl{https://musescore.org/user/</xsl:text>
    <xsl:value-of select="@musescoreuser" />
    <xsl:text>/scores/</xsl:text>
    <xsl:value-of select="@musescore" />
    <xsl:text>}} not yet realized in \LaTeX]&#xa;</xsl:text>
</xsl:template>

<!-- Numbers, units, quantities                     -->
<!-- quantity                                       -->
<xsl:template match="quantity">
    <!-- warning if there is no content -->
    <xsl:if test="not(descendant::unit) and not(descendant::per) and not(descendant::mag)">
        <xsl:message terminate="no">
        <xsl:text>MBX:WARNING: magnitude or units needed</xsl:text>
        </xsl:message>
    </xsl:if>
    <!-- if it's just a number with no units -->
    <xsl:if test="not(descendant::unit) and not(descendant::per) and (descendant::mag)">
        <xsl:text>\num{</xsl:text>
        <xsl:apply-templates select="mag"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <!-- if it has a magnitude and units -->
    <xsl:if test="((descendant::unit) or (descendant::per)) and descendant::mag">
        <xsl:text>\SI{</xsl:text>
        <xsl:apply-templates select="mag"/>
        <xsl:text>}{</xsl:text>
        <xsl:apply-templates select="unit"/>
        <xsl:apply-templates select="per"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <!-- if it is just units with no magnitude -->
    <xsl:if test="((descendant::unit) or (descendant::per)) and not(descendant::mag)">
        <xsl:text>\si{</xsl:text>
        <xsl:apply-templates select="unit"/>
        <xsl:apply-templates select="per"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Magnitude                                      -->
<xsl:template match="mag">
    <xsl:if test="not(parent::quantity)">
        <xsl:message>MBX:WARNING: mag element should have parent quantity element</xsl:message>
    </xsl:if>
    <xsl:apply-templates />
</xsl:template>

<!-- Units                                          -->
<xsl:template match="unit|per">
    <xsl:if test="not(parent::quantity)">
        <xsl:message>MBX:WARNING: unit or per element should have parent quantity element</xsl:message>
    </xsl:if>
    <!-- if we're in a 'per' node -->
    <xsl:if test="self::per">
        <xsl:text>\per</xsl:text>
    </xsl:if>
    <!-- prefix is optional -->
    <xsl:if test="@prefix">
        <xsl:text>\</xsl:text>
        <xsl:value-of select="@prefix"/>
    </xsl:if>
    <!-- base unit is *mandatory* so check to see if it has been provided -->
    <xsl:choose>
        <xsl:when test="@base">
            <xsl:text>\</xsl:text>
            <xsl:value-of select="@base"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="no">
                <xsl:text>MBX:WARNING: base unit needed</xsl:text>
            </xsl:message>
        </xsl:otherwise>
    </xsl:choose>
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
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{quote}&#xa;</xsl:text>
</xsl:template>

<!-- ############ -->
<!-- Attributions -->
<!-- ############ -->

<!-- At end of: blockquote, preface, foreword       -->
<!-- free-form for one line, or structured as lines -->
<!-- LaTeX lacks a quotation dash, emdash instead   -->

<!-- Single line, mixed-content                     -->
<!-- Quotation dash if within blockquote            -->
<!-- A table, pushed right, with left-justification -->
<xsl:template match="attribution">
    <xsl:text>\par\hfill\begin{tabular}{l@{}}&#xa;</xsl:text>
    <xsl:if test="parent::blockquote">
        <xsl:text>\textemdash{}</xsl:text>
    </xsl:if>
    <xsl:apply-templates />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\end{tabular}\\\par&#xa;</xsl:text>
</xsl:template>

<!-- Multiple lines, structured by lines -->
<xsl:template match="attribution[line]">
    <xsl:text>\par\hfill\begin{tabular}{l@{}}&#xa;</xsl:text>
    <xsl:apply-templates select="line" />
    <xsl:text>\end{tabular}\\\par&#xa;</xsl:text>
</xsl:template>

<!-- General line of an attribution -->
<xsl:template match="attribution/line">
    <xsl:if test="parent::attribution/parent::blockquote and not(preceding-sibling::*)">
        <xsl:text>\textemdash{}</xsl:text>
    </xsl:if>
    <xsl:apply-templates />
    <!-- is there a next line to separate? -->
    <xsl:if test="following-sibling::*">
        <xsl:text>\\</xsl:text>
    </xsl:if>
    <!-- always format source visually -->
    <xsl:text>&#xa;</xsl:text>
</xsl:template>


<!-- Emphasis -->
<xsl:template match="em">
    <xsl:text>\emph{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Alert -->
<!-- \alert{} defined in preamble as semantic macro -->
<xsl:template match="alert">
    <xsl:text>\alert{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Insert (an edit) -->
<!-- \inserted{} defined in preamble as semantic macro -->
<xsl:template match="insert">
    <xsl:text>\inserted{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Delete (an edit) -->
<!-- \deleted{} defined in preamble as semantic macro -->
<xsl:template match="delete">
    <xsl:text>\deleted{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Stale (no longer relevant) -->
<!-- \stale{} defined in preamble as semantic macro -->
<xsl:template match="stale">
    <xsl:text>\stale{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Term (defined terms) -->
<!-- \terminology{} defined in preamble as semantic macro -->
<xsl:template match="term">
    <xsl:text>\terminology{</xsl:text>
    <xsl:apply-templates />
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
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="acro">
    <xsl:text>\acronym{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="init">
    <xsl:text>\initialism{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Titles migrate to PDF bookmarks/ToC and need to be handled  -->
<!-- differently, even if we haven't quite figured out how       -->
<xsl:template match="title//abbr">
    <xsl:text>\abbreviationintitle{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="title//acro">
    <xsl:text>\acronymintitle{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="title//init">
    <xsl:text>\initialismintitle{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>


<!-- ############# -->
<!-- External URLs -->
<!-- ############# -->

<!-- We escape all the problem LaTeX characters      -->
<!-- when given in the @href attribute, the \url{}   -->
<!-- and \href{}{} seem to do the right thing        -->
<!-- and they do better in footnotes and table cells -->
<!-- Within titles, we just produce (formatted)      -->
<!-- text, but nothing active                        -->

<xsl:template match="url">
    <!-- choose a macro, font change, or active link -->
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:text>\mono{</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\url{</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- sanitize the URL for LaTeX output -->
    <xsl:call-template name="escape-url-to-latex">
        <xsl:with-param name="text">
            <xsl:value-of select="@href" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Checking for "content-less" form           -->
<!-- http://stackoverflow.com/questions/9782021 -->
<xsl:template match="url[* or normalize-space()]">
    <xsl:choose>
        <!-- just the content, ignore the actual URL -->
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:apply-templates />
        </xsl:when>
        <!-- the functional version, usually -->
        <xsl:otherwise>
            <xsl:text>\href{</xsl:text>
            <xsl:call-template name="escape-url-to-latex">
                <xsl:with-param name="text">
                    <xsl:value-of select="@href" />
                </xsl:with-param>
            </xsl:call-template>
            <xsl:text>}{</xsl:text>
            <xsl:apply-templates />
            <xsl:text>}</xsl:text>
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
<xsl:template match="c">
    <xsl:text>\mono{</xsl:text>
    <xsl:call-template name="escape-text-to-latex">
        <xsl:with-param name="text" select="." />
    </xsl:call-template>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- 100% analogue of LaTeX's verbatim            -->
<!-- environment or HTML's <pre> element          -->
<!-- TODO: center on page with fancyvrb/BVerbatim -->
<!-- and \centering in a custom semantic macro?   -->

<!-- cd is for use in paragraphs, inline            -->
<!-- One line is mixed content, and should be tight -->
<!-- Formatted for visual appeal in LaTeX source    -->
<!-- "cd" could be first in a paragraph, so do not  -->
<!-- drop an empty line                             -->
<xsl:template match="cd">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\begin{codedisplay}&#xa;</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\end{codedisplay}&#xa;</xsl:text>
</xsl:template>

<!-- With a "cline" element present, we assume   -->
<!-- that is the entire structure (see the cline -->
<!-- template in the mathbook-common.xsl file)   -->
<xsl:template match="cd[cline]">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\begin{codedisplay}&#xa;</xsl:text>
    <xsl:apply-templates select="cline" />
    <xsl:text>\end{codedisplay}&#xa;</xsl:text>
</xsl:template>

<!-- "pre" is analogous to the HTML tag of the same name -->
<!-- The "interior" templates decide between two styles  -->
<!--   (a) clean up raw text, just like for Sage code    -->
<!--   (b) interpret cline as line-by-line structure     -->
<!-- (See templates in xsl/mathbook-common.xsl file)     -->
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


<!-- ################### -->
<!-- Reserved Characters -->
<!-- ################### -->

<!-- Across all possibilities                     -->
<!-- See mathbook-common.xsl for discussion       -->
<!-- See default LaTeX2e textcomp symbols at:     -->
<!-- http://hevea.inria.fr/examples/test/sym.html -->

<!--           -->
<!-- XML, HTML -->
<!--           -->

<!-- & < > -->

<!-- Ampersand -->
<xsl:template match="ampersand">
    <xsl:text>\&amp;</xsl:text>
</xsl:template>

<!-- Less Than -->
<xsl:template match="less">
    <xsl:text>\textless{}</xsl:text>
</xsl:template>

<!-- Greater Than -->
<xsl:template match="greater">
    <xsl:text>\textgreater{}</xsl:text>
</xsl:template>

<!--       -->
<!-- LaTeX -->
<!--       -->

<!-- # $ % ^ & _ { } ~ \ -->

<!-- Number Sign, Hash, Octothorpe -->
<xsl:template match="hash">
    <xsl:text>\#</xsl:text>
</xsl:template>

<!-- Dollar sign -->
<xsl:template match="dollar">
    <xsl:text>\textdollar{}</xsl:text>
</xsl:template>

<!-- Percent sign -->
<xsl:template match="percent">
    <xsl:text>\%</xsl:text>
</xsl:template>

<!-- Circumflex  -->
<xsl:template match="circumflex">
    <xsl:text>\textasciicircum{}</xsl:text>
</xsl:template>

<!-- Ampersand -->
<!-- Handled above -->

<!-- Underscore -->
<xsl:template match="underscore">
    <xsl:text>\textunderscore{}</xsl:text>
</xsl:template>

<!-- Left Brace -->
<xsl:template match="lbrace">
    <xsl:text>\textbraceleft{}</xsl:text>
</xsl:template>

<!-- Right  Brace -->
<xsl:template match="rbrace">
    <xsl:text>\textbraceright{}</xsl:text>
</xsl:template>

<!-- Tilde -->
<xsl:template match="tilde">
    <xsl:text>\textasciitilde{}</xsl:text>
</xsl:template>

<!-- Backslash -->
<xsl:template match="backslash">
    <xsl:text>\textbackslash{}</xsl:text>
</xsl:template>

<!-- Other characters -->

<!-- Asterisk -->
<!-- Centered as a character, not an exponent -->
<xsl:template match="asterisk">
    <xsl:text>\textasteriskcentered{}</xsl:text>
</xsl:template>

<!-- Left Single Quote -->
<xsl:template match="lsq">
    <xsl:text>`</xsl:text>
</xsl:template>

<!-- Right Single Quote -->
<xsl:template match="rsq">
    <xsl:text>'</xsl:text>
</xsl:template>

<!-- Left (Double) Quote -->
<xsl:template match="lq">
    <xsl:text>``</xsl:text>
</xsl:template>

<!-- Right (Double) Quote -->
<xsl:template match="rq">
    <xsl:text>''</xsl:text>
</xsl:template>

<!-- Left Bracket -->
<xsl:template match="lbracket">
    <xsl:text>[</xsl:text>
</xsl:template>

<!-- Right Bracket -->
<xsl:template match="rbracket">
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- Left Double Bracket -->
<xsl:template match="ldblbracket">
    <xsl:text>\textlbrackdbl{}</xsl:text>
</xsl:template>

<!-- Right Double Bracket -->
<xsl:template match="rdblbracket">
    <xsl:text>\textrbrackdbl{}</xsl:text>
</xsl:template>

<!-- Left Angle Bracket -->
<xsl:template match="langle">
    <xsl:text>\textlangle{}</xsl:text>
</xsl:template>

<!-- Right Angle Bracket -->
<xsl:template match="rangle">
    <xsl:text>\textrangle{}</xsl:text>
</xsl:template>

<!-- Other Miscellaneous Symbols, Constructions -->

<!-- Ellipsis (dots), for text, not math -->
<xsl:template match="ellipsis">
    <xsl:text>\textellipsis{}</xsl:text>
</xsl:template>

<!-- Midpoint -->
<!-- A centered dot used sometimes like a decorative dash -->
<!-- http://tex.stackexchange.com/questions/19180/which-dot-character-to-use-in-which-context -->
<xsl:template match="midpoint">
    <xsl:text>\textperiodcentered{}</xsl:text>
</xsl:template>

<!-- Swung Dash -->
<!-- A decorative dash, like a tilde, but bigger, and centered -->
<!-- http://andrewmccarthy.ie/2014/11/06/swung-dash-in-latex/  -->
<xsl:template match="swungdash">
    <xsl:text>\swungdash{}</xsl:text>
</xsl:template>

<!-- Per Mille -->
<!-- Or, per thousand, like a percent sign -->
<xsl:template match="permille">
    <xsl:text>\textperthousand{}</xsl:text>
</xsl:template>

<!-- Pilcrow -->
<!-- Often used to mark the start of a paragraph -->
<xsl:template match="pilcrow">
    <xsl:text>\textpilcrow{}</xsl:text>
</xsl:template>

<!-- Section Mark -->
<!-- The stylized double-S to indicate section numbers -->
<xsl:template match="section-mark">
    <xsl:text>\textsection{}</xsl:text>
</xsl:template>

<!-- Times -->
<!-- A "multiplication sign" symbol for use in text -->
<xsl:template match="times">
    <xsl:text>\texttimes{}</xsl:text>
</xsl:template>

<!-- Slash -->
<!-- Forward slash, or virgule (see solidus)   -->
<!-- This should allow a linebreak, not tested -->
<xsl:template match="slash">
    <xsl:text>\slash{}</xsl:text>
</xsl:template>

<!-- Solidus -->
<!-- Fraction bar, not as steep as a forward slash -->
<!-- This should not allow a linebreak, not tested -->
<xsl:template match="solidus">
    <xsl:text>\textfractionsolidus{}</xsl:text>
</xsl:template>

<!-- Backtick -->
<!-- This is the "accent grave" character.                 -->
<!-- Unicode Character 'GRAVE ACCENT' (U+0060)             -->
<!-- Really it is a modifier.  But as an ASCII character   -->
<!-- on most keyboards it gets used in computer languages. -->
<!-- Normally you would use this in verbatim contexts.     -->
<!-- It is not a left-quote (see <lsq />0, nor is it a     -->
<!-- modifier.  If you really want this character in a     -->
<!-- text context use this empty element.  For example,    -->
<!-- this is a character Markdown uses, so we want to      -->
<!-- provide this safety valve.                            -->
<xsl:template match="backtick">
    <xsl:text>\textasciigrave</xsl:text>
</xsl:template>

<!-- \@ following a period makes it an abbreviation, not the end of a sentence -->
<!-- So use it for abbreviations which will not end a sentence                 -->
<!-- Best: \makeatletter\newcommand\etc{etc\@ifnextchar.{}{.\@}}\makeatother   -->
<!-- http://latex-alive.tumblr.com/post/827168808/correct-punctuation-spaces   -->

<!-- exempli gratia, for example -->
<xsl:template match="eg">
    <xsl:text>e.g.\@</xsl:text>
</xsl:template>

<!-- id est, in other words -->
<xsl:template match="ie">
    <xsl:text>i.e.\@</xsl:text>
</xsl:template>

<!-- et cetera -->
<xsl:template match="etc">
    <xsl:text>etc.\@</xsl:text>
</xsl:template>

<!-- circa -->
<xsl:template match="circa">
    <xsl:text>c.\@</xsl:text>
</xsl:template>

<!-- Copyright symbol -->
<!-- http://tex.stackexchange.com/questions/1676/how-to-get-good-looking-copyright-and-registered-symbols -->
<xsl:template match="copyright">
    <xsl:text>\textcopyright{}</xsl:text>
</xsl:template>

<!-- Registered symbol          -->
<!-- \textsuperscript can raise -->
<xsl:template match="registered">
    <xsl:text>\textregistered{}</xsl:text>
</xsl:template>

<!-- Trademark symbol -->
<xsl:template match="trademark">
    <xsl:text>\texttrademark{}</xsl:text>
</xsl:template>

<!-- Fill-in blank -->
<!-- \fillin{} defined in preamble as semantic macro       -->
<!-- argument is number of "em", Bringhurst suggests 5/11  -->
<!-- \rule works in text and in math (unlike HTML/MathJax) -->
<xsl:template match="fillin">
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
    <xsl:text>\fillin{</xsl:text>
    <xsl:value-of select="5 * $characters div 11" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Implication Symbols -->
<!-- TODO: better names! -->
<xsl:template match="imply">
    <xsl:text>$\Rightarrow$</xsl:text>
</xsl:template>
<xsl:template match="implyreverse">
    <xsl:text>$\Leftarrow$</xsl:text>
</xsl:template>

<!-- TeX, LaTeX -->
<!-- PreTeXt is in -common -->
<xsl:template match="latex">
    <xsl:text>\LaTeX{}</xsl:text>
</xsl:template>
<xsl:template match="tex">
    <xsl:text>\TeX{}</xsl:text>
</xsl:template>

<!-- Foreign words/idioms        -->
<!-- Matches HTML5 specification -->
<xsl:template match="foreign">
    <xsl:apply-templates select="." mode="begin-language" />
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="end-language" />
</xsl:template>

<!-- Non-breaking space, which "joins" two words as a unit -->
<xsl:template match="nbsp">
    <xsl:text>~</xsl:text>
</xsl:template>


<!-- Dashes, Hyphen -->
<!-- http://www.public.asu.edu/~arrows/tidbits/dashes.html -->
<!-- NB: global $emdash-space-char could go local to "mdash" template -->
<xsl:variable name="emdash-space-char">
    <xsl:choose>
        <xsl:when test="$emdash-space='none'">
            <xsl:text />
        </xsl:when>
        <xsl:when test="$emdash-space='thin'">
            <xsl:text>\,</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:variable>
<xsl:template match="mdash">
    <xsl:value-of select="$emdash-space-char" />
    <xsl:text>\textemdash{}</xsl:text>
    <xsl:value-of select="$emdash-space-char" />
</xsl:template>
<xsl:template match="ndash">
    <xsl:text>\textendash{}</xsl:text>
</xsl:template>
<!-- A "hyphen" element was a bad idea, very cumbersome -->
<xsl:template match="hyphen">
    <xsl:message>MBX:WARNING: the "hyphen" element is deprecated (2017-02-05), use the "hyphen-minus" character instead (aka the "ASCII hyphen")</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:text>-</xsl:text>
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
    <xsl:apply-templates />
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
        <xsl:when test="child::node()[not(self::comment()) and not(self::processing-instruction())][1][self::q or self::sq]">
            <xsl:text>{`}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>`</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- content -->
    <xsl:apply-templates />
    <!-- right quote, possibly protected in a group -->
    <xsl:choose>
        <xsl:when test="(parent::q or parent::sq) and not(following-sibling::*) and not(following-sibling::text())">
            <xsl:text>{'}</xsl:text>
        </xsl:when>
        <xsl:when test="child::node()[not(self::comment()) and not(self::processing-instruction())][last()][self::q or self::sq]">
            <xsl:text>{'}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>'</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################ -->
<!-- Biological Names -->
<!-- ################ -->

<xsl:template match="taxon[not(genus) and not(species)]">
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates />
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
<xsl:template match="pubtitle|booktitle">
    <xsl:text>\textsl{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="articletitle">
    <xsl:text>``</xsl:text>
    <xsl:apply-templates />
    <xsl:text>''</xsl:text>
</xsl:template>

<!-- ################## -->
<!-- Special Characters -->
<!-- ################## -->

<!-- These are specific instances of abstract templates        -->
<!-- See the similar section of  mathbook-common.xsl  for more -->

<xsl:template match="*" mode="nbsp">
    <xsl:text>~</xsl:text>
</xsl:template>

<xsl:template match="*" mode="ndash">
    <xsl:text>--</xsl:text>
</xsl:template>

<xsl:template match="*" mode="mdash">
    <xsl:text>---</xsl:text>
</xsl:template>


<!-- Sage Cells -->

<!-- An abstract named template accepts input text and               -->
<!-- output text, then wraps it for print, including output          -->
<!-- But we do not write an environment if there isn't any content   -->
<!-- So conceivably, this template can do nothing (ie an empty cell) -->
<!-- As a named template, the context is a calling sage element,     -->
<!-- this could be reworked and many of the parameters inferred      -->
<xsl:template name="sage-active-markup">
    <xsl:param name="in" />
    <xsl:param name="out" />
    <!-- Surrounding box gets clobbered if it is the first -->
    <!-- thing after a heading.  This could be excessive   -->
    <!-- if the cell is empty, but should not be harmful.  -->
    <!-- NB: maybe this should not even be called if all empty -->
    <xsl:if test="not(preceding-sibling::*[not(&SUBDIVISION-METADATA-FILTER;)])">
        <xsl:call-template name="leave-vertical-mode" />
    </xsl:if>
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


<!-- Program Listings -->
<!-- The "listings-language" template is in the common file -->
<xsl:template match="program">
    <xsl:param name="width" select="''" />
    <xsl:variable name="language">
        <xsl:apply-templates select="." mode="listings-language" />
    </xsl:variable>
    <xsl:variable name="b-has-language" select="not($language = '')" />
    <xsl:variable name="b-has-width" select="not($width = '')" />
    <xsl:choose>
        <xsl:when test="$b-has-width">
            <xsl:text>\begin{programbox}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\begin{program}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>[</xsl:text>
    <!-- inserted into "listing options", after style option -->
    <xsl:text>language=</xsl:text>
    <xsl:choose>
        <xsl:when test="$b-has-language">
            <xsl:value-of select="$language" />
        </xsl:when>
        <!-- null language defined in preamble -->
        <xsl:otherwise>
            <xsl:text>none</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="$b-has-width">
        <xsl:text>,linewidth=</xsl:text>
        <xsl:value-of select="$width" />
    </xsl:if>
    <xsl:text>]</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="input" />
    </xsl:call-template>
    <xsl:choose>
        <xsl:when test="$b-has-width">
            <xsl:text>\end{programbox}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\end{program}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Console Session -->
<!-- An interactive command-line session with a prompt, input and output -->
<!-- The width parameter supports use in a sidebyside panel              -->
<xsl:template match="console">
    <xsl:param name="width" select="''" />
    <!-- ignore prompt, and pick it up in trailing input  -->
    <!-- optional width override is supported by fancyvrb -->
    <xsl:text>\begin{console}</xsl:text>
    <xsl:if test="not($width='')">
        <xsl:text>[boxwidth=</xsl:text>
        <xsl:value-of select="$width" />
        <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="input|output" />
    <xsl:text>\end{console}&#xa;</xsl:text>
</xsl:template>

<!-- match immediately preceding, only if a prompt:                   -->
<!-- https://www.oxygenxml.com/archives/xsl-list/199910/msg00541.html -->
<xsl:template match="console/input">
    <!-- Assumes prompt does not exceed one line -->
    <!-- Wrap with semantic \consoleprompt macro -->
    <xsl:text>\consoleprompt{</xsl:text>
    <xsl:call-template name="escape-console-to-latex">
        <xsl:with-param name="text"  select="preceding-sibling::*[1][self::prompt]"/>
    </xsl:call-template>
    <xsl:text>}</xsl:text>
    <!-- sanitize left-margin, etc                    -->
    <!-- then employ \consoleinput macro on each line -->
    <xsl:call-template name="wrap-console-input">
        <xsl:with-param name="text">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text">
                    <xsl:call-template name="escape-console-to-latex">
                        <xsl:with-param name="text"  select="."/>
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Output code gets massaged to remove a left margin, -->
<!-- leading blank lines, etc., then wrap as above-->
<xsl:template match="console/output">
    <xsl:call-template name="wrap-console-output">
        <xsl:with-param name="text">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text">
                    <xsl:call-template name="escape-console-to-latex">
                        <xsl:with-param name="text"  select="."/>
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- TODO: consolidate/generalize next two templates -->

<!-- Line-by-line, apply \consoleinput macro defined in preamble -->
<xsl:template name="wrap-console-input">
    <xsl:param name="text" />
    <xsl:choose>
        <xsl:when test="$text=''" />
        <xsl:otherwise>
            <xsl:text>\consoleinput{</xsl:text>
            <xsl:value-of select="substring-before($text, '&#xa;')" />
            <xsl:text>}&#xa;</xsl:text>
            <xsl:call-template name="wrap-console-input">
                <xsl:with-param name="text" select="substring-after($text, '&#xa;')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Line-by-line, apply \consoleoutput macro defined in preamble -->
<xsl:template name="wrap-console-output">
    <xsl:param name="text" />
    <xsl:choose>
        <xsl:when test="$text=''" />
        <xsl:otherwise>
            <xsl:text>\consoleoutput{</xsl:text>
            <xsl:value-of select="substring-before($text, '&#xa;')" />
            <xsl:text>}&#xa;</xsl:text>
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
<xsl:template match="interactive[@calcplot3d]" mode="info-text">
    <xsl:text>CalcPlot3D: \href{https://www.monroecc.edu/faculty/paulseeburger/calcnsf/CalcPlot3D/?</xsl:text>
    <xsl:value-of select="code" />
    <xsl:text>}{\mono{www.monroecc.edu/faculty/paulseeburger/calcnsf/CalcPlot3D}}&#xa;</xsl:text>
</xsl:template>


<!-- Static interactives -->
<!-- Contents of "static" element, plus    -->
<!-- a line of information below, per type -->
<xsl:template match="interactive[@geogebra]|interactive[@geogebra]|interactive[@calcplot3d]">
    <xsl:apply-templates select="static/*" />
    <xsl:text>\centerline{</xsl:text>
    <xsl:apply-templates select="." mode="info-text" />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- JSXGraph -->
<xsl:template match="jsxgraph">
    <xsl:text>\par\smallskip\centerline{A JSXGraph interactive demonstration goes here in interactive output.}\smallskip&#xa;</xsl:text>
</xsl:template>

<!-- Captions for Figures, Tables, Listings, Lists -->
<!-- xml:id is on parent, but LaTeX generates number with caption -->
<xsl:template match="caption">
    <xsl:choose>
      <xsl:when test="parent::table/parent::sidebyside">
            <xsl:text>\captionof{table}{</xsl:text>
      </xsl:when>
      <xsl:when test="parent::figure/parent::sidebyside">
            <xsl:text>\captionof{figure}{</xsl:text>
      </xsl:when>
      <xsl:when test="parent::listing">
            <xsl:text>\captionof{listingcap}{</xsl:text>
        </xsl:when>
      <xsl:when test="parent::list">
            <xsl:text>\captionof{namedlistcap}{</xsl:text>
        </xsl:when>
      <xsl:otherwise>
          <xsl:text>\caption{</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates />
    <xsl:apply-templates select="parent::*" mode="label" />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Subcaptions showup in side-by-side -->
<xsl:template match="caption" mode="subcaption">
    <xsl:text>\subcaption{</xsl:text>
    <xsl:apply-templates />
    <xsl:apply-templates select="parent::*" mode="label" />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>


<!-- Figures, Tables and Listings are floats                          -->
<!-- We try to fix their location with the [H] specifier, but         -->
<!-- if the first item of an AMS environment, they may float up       -->
<!-- Seems LaTeX is stacking boxes vertically, and we need to go to   -->
<!-- horizontal mode before doing these floating layout-type elements -->
<!-- Necessary before a "lstlisting" environment with surrounding box -->
<!-- http://tex.stackexchange.com/questions/22852/function-and-usage-of-leavevmode                       -->
<!-- Potential alternate solution: write a leading "empty" \mbox{}                                       -->
<!-- http://tex.stackexchange.com/questions/171220/include-non-floating-graphic-in-a-theorem-environment -->
<xsl:template name="leave-vertical-mode">
    <xsl:text>\leavevmode%&#xa;</xsl:text>
</xsl:template>

<!-- Figures -->
<!-- Standard LaTeX figure environment redefined, see preamble comments -->
<xsl:template match="figure">
    <xsl:if test="not(preceding-sibling::*[not(&SUBDIVISION-METADATA-FILTER;)])">
        <xsl:call-template name="leave-vertical-mode" />
    </xsl:if>
    <xsl:text>\begin{figure}&#xa;</xsl:text>
    <xsl:text>\centering&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::caption)]"/>
    <xsl:apply-templates select="caption" />
    <xsl:text>\end{figure}&#xa;</xsl:text>
</xsl:template>

<!-- Listings -->
<!-- Simple non-float environment            -->
<!-- \captionof for numbering, style, etc    -->
<!-- not centering the interior environments -->
<!-- since it is not straightforward, maybe  -->
<!-- requires a savebox and a minipage       -->
<xsl:template match="listing">
    <xsl:if test="not(preceding-sibling::*[not(&SUBDIVISION-METADATA-FILTER;)])">
        <xsl:call-template name="leave-vertical-mode" />
    </xsl:if>
    <xsl:text>\begin{listing}&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::caption)]"/>
    <xsl:text>\par&#xa;</xsl:text>
    <xsl:apply-templates select="caption" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\end{listing}&#xa;</xsl:text>
</xsl:template>


<!-- ################## -->
<!-- SideBySide Layouts -->
<!-- ################## -->

<!-- See xsl/mathbook-common.xsl for descriptions of the  -->
<!-- five modal templates which must be implemented here  -->
<!-- The main templates for "sidebyside" and "sbsgroup"   -->
<!-- are in xsl/mathbook-common.xsl, as befits containers -->

<!-- cut/paste, remove fbox end/begin in dual placement
    <xsl:if test="$sbsdebug">
        <xsl:text>\fbox{</xsl:text>
        <xsl:text>\hspace*{-0.5ex}x\hspace*{-0.5ex}</xsl:text>
        <xsl:text>}</xsl:text>
    </xsl:if>
 -->

<!-- Utility template to make a name for a LaTeX box -->
<!-- Unique (element + count), all letters for LaTeX -->
<!-- Alphabetic numbers are like base 26 notation    -->
<xsl:template match="*" mode="panel-id">
    <!-- with no "count", will only count same element name -->
    <!-- with count="*" even cells of a table contribute    -->
    <!-- level="single" will not account for figure hack    -->
    <!-- sanitize any dashes in local names? -->
    <xsl:number from="sidebyside" level="any" format="A" />
    <xsl:value-of select="local-name(.)" />
</xsl:template>

<!-- We build a TeX box (by whatever means), name and      -->
<!-- save the box, measure its height, and update the      -->
<!-- maximum height seen so far (to size minipages later). -->
<!-- For the panel, we just stuff the (predictably) named  -->
<!-- box into a minipage.  So the call here to the modal   -->
<!-- "panel-latex-box" is where individual objects get     -->
<!-- handled appropriately.                                -->
<!-- Be sure to compute height plus depth of the panel box -->
<!-- http://tex.stackexchange.com/questions/11943/         -->
<xsl:template match="*" mode="panel-setup">
    <xsl:param name="width" />
    <xsl:text>\ifdefined\panelbox</xsl:text>
    <xsl:apply-templates select="." mode="panel-id" />
    <xsl:text>\else</xsl:text>
    <xsl:text>\newsavebox{\panelbox</xsl:text>
    <xsl:apply-templates select="." mode="panel-id" />
    <xsl:text>}\fi%&#xa;</xsl:text>
    <!-- If the "panel-latex-box" creates something actually  -->
    <!-- in a box of predictable overall width (such as a     -->
    <!-- BVerbatim, or an \includegraphics), then an "lrbox"  -->
    <!-- *environment* will strip any leading and trailing    -->
    <!-- whitespace that creeps in.  Otherwise, content is    -->
    <!-- packed into a box of predictable width via \savebox. -->
    <!-- Moving images (bare, or from figures) into "lrbox"   -->
    <!-- cut down on spurious minor overfull-hboxes           -->
    <!-- See: http://tex.loria.fr/ctan-doc/macros/latex/doc/html/usrguide/node19.html -->
    <!-- TODO: maybe we can use "lrbox" exclusively?          -->
    <xsl:choose>
        <xsl:when test="self::pre or self::console or self::program or self::listing or self::image or self::figure/image">
            <xsl:text>\begin{lrbox}{\panelbox</xsl:text>
            <xsl:apply-templates select="." mode="panel-id" />
            <xsl:text>}&#xa;</xsl:text>
            <xsl:apply-templates select="." mode="panel-latex-box">
                <xsl:with-param name="width" select="$width" />
            </xsl:apply-templates>
            <xsl:text>\end{lrbox}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\savebox{\panelbox</xsl:text>
            <xsl:apply-templates select="." mode="panel-id" />
            <xsl:text>}{%&#xa;</xsl:text>
            <xsl:apply-templates select="." mode="panel-latex-box">
                <xsl:with-param name="width" select="$width" />
            </xsl:apply-templates>
            <xsl:text>}</xsl:text>
            <xsl:text>&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\ifdefined\ph</xsl:text>
    <xsl:apply-templates select="." mode="panel-id" />
    <xsl:text>\else</xsl:text>
    <xsl:text>\newlength{\ph</xsl:text>
    <xsl:apply-templates select="." mode="panel-id" />
    <xsl:text>}\fi%&#xa;</xsl:text>
    <xsl:text>\setlength{\ph</xsl:text>
    <xsl:apply-templates select="." mode="panel-id" />
    <xsl:text>}{\ht\panelbox</xsl:text>
    <xsl:apply-templates select="." mode="panel-id" />
    <xsl:text>+\dp\panelbox</xsl:text>
    <xsl:apply-templates select="." mode="panel-id" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\settototalheight{\ph</xsl:text>
    <xsl:apply-templates select="." mode="panel-id" />
    <xsl:text>}{\usebox{\panelbox</xsl:text>
    <xsl:apply-templates select="." mode="panel-id" />
    <xsl:text>}}&#xa;</xsl:text>
    <!-- update maximum panel height, compose-panels initializes to zero -->
    <xsl:text>\setlength{\panelmax}{\maxof{\panelmax}{\ph</xsl:text>
    <xsl:apply-templates select="." mode="panel-id" />
    <xsl:text>}}&#xa;</xsl:text>
</xsl:template>

<!-- If an object carries a title, we add it to the -->
<!-- row of titles across the top of the table      -->
<!-- Bold, but not with a font-size increase, given -->
<!-- width is constrained for panels                -->
<xsl:template match="*" mode="panel-heading">
    <xsl:param name="width" />
    <xsl:if test="title">
        <xsl:if test="$sbsdebug">
            <xsl:text>\fbox{</xsl:text>
            <xsl:text>\hspace*{-0.5ex}x\hspace*{-0.5ex}</xsl:text>
        </xsl:if>
        <xsl:text>\parbox[t]{</xsl:text>
        <xsl:value-of select="substring-before($width,'%') div 100" />
        <xsl:text>\linewidth}{\centering{}\textbf{</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>}}</xsl:text>
        <xsl:if test="$sbsdebug">
            <xsl:text>\hspace*{-0.5ex}x\hspace*{-0.5ex}</xsl:text>
            <xsl:text>}</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="following-sibling::*">
        <xsl:text>&amp;&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- generic "panel-panel" template          -->
<!-- simply references the box made in setup -->
<xsl:template match="*" mode="panel-panel">
    <xsl:param name="width" />
    <xsl:param name="valign" />
    <xsl:if test="$sbsdebug">
        <xsl:text>\fbox{</xsl:text>
        <xsl:text>\hspace*{-0.5ex}x\hspace*{-0.5ex}</xsl:text>
    </xsl:if>
    <xsl:text>\begin{minipage}[c][\panelmax]</xsl:text>
    <!-- vertical alignment within minipage -->
    <xsl:text>[</xsl:text>
    <xsl:choose>
        <xsl:when test="$valign = 'bottom'">
            <xsl:text>b</xsl:text>
        </xsl:when>
        <!-- minipage anomalous, halfway is "c" -->
        <xsl:when test="$valign = 'middle'">
            <xsl:text>c</xsl:text>
        </xsl:when>
        <xsl:when test="$valign = 'top'">
            <xsl:text>t</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>]</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="substring-before($width,'%') div 100" />
    <xsl:text>\linewidth}</xsl:text>
    <xsl:text>\usebox{\panelbox</xsl:text>
    <xsl:apply-templates select="." mode="panel-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>\end{minipage}</xsl:text>
    <xsl:if test="$sbsdebug">
        <xsl:text>\hspace*{-0.5ex}x\hspace*{-0.5ex}</xsl:text>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:if test="following-sibling::*">
        <xsl:text>&amp;&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- a figure or table must have a caption,         -->
<!-- and is a subcaption if sbs parent is captioned -->
<xsl:template match="figure|table|listing|list" mode="panel-caption">
    <xsl:param name="width" />
    <xsl:if test="$sbsdebug">
        <xsl:text>\fbox{</xsl:text>
        <xsl:text>\hspace*{-0.5ex}x\hspace*{-0.5ex}</xsl:text>
    </xsl:if>
    <xsl:text>\parbox[t]{</xsl:text>
    <xsl:value-of select="substring-before($width,'%') div 100" />
    <xsl:text>\linewidth}{</xsl:text>
    <xsl:choose>
        <!-- Exceptional situation for backward-compatibility -->
        <!-- Titled/environment version deprecated 2017-08-25 -->
        <xsl:when test="self::list and title and not(caption)">
            <xsl:choose>
                <xsl:when test="parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure">
                    <xsl:text>\subcaption{</xsl:text>
                    <xsl:apply-templates select="." mode="title-full" />
                    <xsl:apply-templates select="parent::*" mode="label" />
                    <xsl:text>}&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\captionof{namedlist}{</xsl:text>
                    <xsl:apply-templates select="." mode="title-full" />
                    <xsl:apply-templates select="parent::*" mode="label" />
                    <xsl:text>}&#xa;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure">
            <xsl:apply-templates select="caption" mode="subcaption" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="caption" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}</xsl:text>
    <xsl:if test="$sbsdebug">
        <xsl:text>\hspace*{-0.5ex}x\hspace*{-0.5ex}</xsl:text>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:if test="following-sibling::*">
        <xsl:text>&amp;&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- no caption if not figure or table -->
<!-- but do include a column separator -->
<xsl:template match="*" mode="panel-caption">
    <xsl:if test="following-sibling::*">
        <xsl:text>&amp;&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- We take in all three rows of a LaTeX    -->
<!-- table and package them up appropriately -->
<xsl:template match="sidebyside" mode="compose-panels">
    <xsl:param name="layout" />
    <xsl:param name="has-headings" />
    <xsl:param name="has-captions" />
    <xsl:param name="setup" />
    <xsl:param name="headings" />
    <xsl:param name="panels" />
    <xsl:param name="captions" />

    <xsl:variable name="number-panels" select="$layout/number-panels" />
    <xsl:variable name="left-margin" select="$layout/left-margin" />
    <xsl:variable name="space-width" select="$layout/space-width" />

    <!-- protect a single side-by-side -->
    <!-- Local/global newsavebox: http://tex.stackexchange.com/questions/18170 -->
    <xsl:text>% group protects changes to lengths, releases boxes (?)&#xa;</xsl:text>
    <xsl:text>{% begin: group for a single side-by-side&#xa;</xsl:text>
    <xsl:text>% set panel max height to practical minimum, created in preamble&#xa;</xsl:text>
    <xsl:text>\setlength{\panelmax}{0pt}&#xa;</xsl:text>
    <xsl:value-of select="$setup" />

    <xsl:call-template name="leave-vertical-mode" />
    <xsl:text>% begin: side-by-side as tabular&#xa;</xsl:text>
    <xsl:text>% \tabcolsep change local to group&#xa;</xsl:text>
    <xsl:text>\setlength{\tabcolsep}{</xsl:text>
    <xsl:value-of select="0.5 * substring-before($space-width, '%') div 100" />
    <xsl:text>\linewidth}&#xa;</xsl:text>
    <xsl:text>% @{} suppress \tabcolsep at extremes, so margins behave as intended&#xa;</xsl:text>
    <!-- set spacing, centering provide half at each end -->
    <!-- LaTeX parameter is half of the column space     -->
    <xsl:if test="not(parent::figure) or not(parent::sbsgroup and preceding-sibling::sidebyside)">
        <xsl:text>\par\medskip\noindent&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="not($left-margin = '0%')">
        <xsl:text>\hspace*{</xsl:text>
        <xsl:value-of select="substring-before($left-margin, '%') div 100" />
        <xsl:text>\linewidth}%&#xa;</xsl:text>
    </xsl:if>
    <!-- @{} strips extreme left, right colsep and -->
    <!-- allows us to get flush left (zero margin) -->
    <xsl:text>\begin{tabular}{@{}*{</xsl:text>
    <xsl:value-of select="$number-panels" />
    <xsl:text>}{c}@{}}&#xa;</xsl:text>
    <!-- Headings as a table row, if extant -->
    <xsl:if test="$has-headings">
        <xsl:value-of select="$headings" />
        <xsl:text>\tabularnewline&#xa;</xsl:text>
    </xsl:if>
    <!-- actual panels in second row, always -->
    <xsl:value-of select="$panels" />
    <!-- Captions as a table row, if extant -->
    <xsl:if test="$has-captions">
        <xsl:text>\tabularnewline&#xa;</xsl:text>
        <xsl:value-of select="$captions" />
    </xsl:if>
    <!-- end on a newline, ready for resumption of text  -->
    <!-- or perhaps a follow-on sidebyside in a sbsgroup -->
    <xsl:text>\end{tabular}\\&#xa;</xsl:text>
    <xsl:text>% end: side-by-side as tabular&#xa;</xsl:text>
    <xsl:text>}% end: group for a single side-by-side&#xa;</xsl:text>
</xsl:template>


<!-- ############################ -->
<!-- Object by Object LaTeX Boxes -->
<!-- ############################ -->

<!-- Implement modal "panel-latex-box" for various MBX elements -->
<!-- Baseline is consistently at bottom, so vertical alignment  -->
<!-- behaves in minipages.                                      -->
<!-- Called in -setup and saved results recycled in -panel      -->

<xsl:template match="p|paragraphs|tabular|video[@youtube]|ol|ul|dl|list|poem" mode="panel-latex-box">
    <xsl:param name="width" />
    <xsl:variable name="percent" select="substring-before($width,'%') div 100" />
    <xsl:if test="$sbsdebug">
        <xsl:text>\fbox{\hspace*{-0.5ex}x\hspace*{-0.5ex}</xsl:text>
    </xsl:if>
    <xsl:text>\raisebox{\depth}{\parbox{</xsl:text>
    <xsl:value-of select="substring-before($width,'%') div 100" />
    <xsl:text>\linewidth}{</xsl:text>
    <!-- center tables here or below -->
    <xsl:choose>
        <xsl:when test="self::p">
            <xsl:apply-templates select="*|text()" />
        </xsl:when>
        <xsl:when test="self::paragraphs">
            <xsl:apply-templates select="p|blockquote" />
        </xsl:when>
        <xsl:when test="self::tabular or self::video[@youtube]">
            <xsl:text>\centering</xsl:text>
            <xsl:apply-templates select="." />
        </xsl:when>
        <xsl:when test="self::ol or self::ul or self::dl">
            <xsl:apply-templates select="." />
        </xsl:when>
        <xsl:when test="self::list">
            <!-- For a named list we just process the contents, -->
            <!-- while ignoring the title (implicitly) and the  -->
            <!-- caption (explicitly).  As a panel, we do not   -->
            <!-- provide any visual style/separation            -->
            <xsl:apply-templates select="*[not(self::caption)]" />
        </xsl:when>
        <!-- like main "poem" template, but sans title -->
        <xsl:when test="self::poem">
            <xsl:text>\begin{poem}</xsl:text>
            <xsl:apply-templates select="." mode="label" />
            <xsl:text>&#xa;</xsl:text>
            <xsl:apply-templates select="stanza"/>
            <xsl:apply-templates select="author" />
            <xsl:text>\end{poem}&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>}}</xsl:text>
    <xsl:if test="$sbsdebug">
        <xsl:text>\hspace*{-0.5ex}x\hspace*{-0.5ex}</xsl:text>
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Verbatim text from the content of a "pre" element       -->
<!-- is made into a LaTeX box with the  fancyvrb "BVerbatim" -->
<!-- environment, which is then saved in an LR box above     -->
<!-- We cannot see an easy way to get the debugging wrapper  -->
<!-- Default alignment places bottom ont the baseline        -->
<!-- NOTE: adjust panel-setup to produce an LR box           -->
<xsl:template match="pre" mode="panel-latex-box">
    <xsl:param name="width" />
    <xsl:variable name="percent" select="substring-before($width,'%') div 100" />
    <xsl:text>\begin{preformattedbox}</xsl:text>
    <xsl:text>[boxwidth=</xsl:text>
    <xsl:value-of select="$percent" />
    <xsl:text>\linewidth]</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="interior"/>
    <xsl:text>\end{preformattedbox}&#xa;</xsl:text>
</xsl:template>

<!-- A "console" is handled differently than a "pre"     -->
<!-- (and it may be a superior approach).  The fancyvrb  -->
<!-- "BVerbatim" environment produces a TeX box that may -->
<!-- be digested by an lrbox where panels get measured,  -->
<!-- then the PTX "console" enviroment is defined via a  -->
<!-- fancyvrb mechanism, which allows an override of the -->
<!-- width of the box.                                   -->
<!-- width parameter enters as a percentage              -->
<!-- TODO: make enviroments for "pre" and consolidate    -->
<xsl:template match="console" mode="panel-latex-box">
    <xsl:param name="width" />
    <xsl:apply-templates select=".">
        <xsl:with-param name="width">
            <xsl:value-of select="substring-before($width,'%') div 100" />
            <xsl:text>\linewidth</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="program" mode="panel-latex-box">
    <xsl:param name="width" />
    <xsl:apply-templates select=".">
        <xsl:with-param name="width">
            <xsl:value-of select="substring-before($width,'%') div 100" />
            <xsl:text>\linewidth</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- The image "knows" how to size itself for a panel   -->
<!-- Baseline is automatically at the bottom of the box -->
<xsl:template match="image" mode="panel-latex-box">
    <xsl:param name="width" />
    <xsl:if test="$sbsdebug">
        <xsl:text>\fbox{</xsl:text>
        <xsl:text>\hspace*{-0.5ex}x\hspace*{-0.5ex}</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." />
    <xsl:if test="$sbsdebug">
        <xsl:text>\hspace*{-0.5ex}x\hspace*{-0.5ex}</xsl:text>
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- With raw LaTeX code, we use a \resizebox from the graphicx -->
<!-- package to scale the image to the panel width, and then    -->
<!-- we do not pass the width to the image template             -->
<xsl:template match="image[latex-image-code]|image[latex-image]" mode="panel-latex-box">
    <xsl:param name="width" />
    <xsl:variable name="percent" select="substring-before($width,'%') div 100" />
    <xsl:if test="$sbsdebug">
        <xsl:text>\fbox{</xsl:text>
        <xsl:text>\hspace*{-0.5ex}x\hspace*{-0.5ex}</xsl:text>
    </xsl:if>
    <xsl:text>\resizebox{</xsl:text>
    <xsl:value-of select="$percent" />
    <xsl:text>\linewidth}{!}{</xsl:text>
    <xsl:apply-templates select="." />
    <xsl:text>}</xsl:text>
    <xsl:if test="$sbsdebug">
        <xsl:text>\hspace*{-0.5ex}x\hspace*{-0.5ex}</xsl:text>
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- A figure, table, or listing is just a container -->
<!-- to hold a title and/or caption, plus perhaps an -->
<!-- xml:id, so we just pawn off the contents        -->
<!-- (one only!) to the other routines               -->
<!-- NB: sync with "panel-id" hack below             -->
<!-- NB: "list" is handled with \parbox above        -->
<xsl:template match="figure|table|listing" mode="panel-latex-box">
    <xsl:param name="width" />
    <xsl:apply-templates select="*[not(&METADATA-FILTER;)][1]" mode="panel-latex-box">
        <xsl:with-param name="width" select="$width" />
    </xsl:apply-templates>
</xsl:template>

<!-- We need to do identically for the panel-id -->
<xsl:template match="figure|table|listing" mode="panel-id">
    <xsl:apply-templates select="*[not(&METADATA-FILTER;)][1]" mode="panel-id" />
</xsl:template>

<!-- Just temporary markers of unimplemented stuff -->
<xsl:template match="*" mode="panel-latex-box">
    <xsl:text>\parbox{70pt}{[</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>]}</xsl:text>
</xsl:template>


<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- With full source specified, default to PDF format -->
<xsl:template match="image[@source]" >
    <xsl:variable name="width">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:variable name="extension">
        <xsl:call-template name="file-extension">
            <xsl:with-param name="filename" select="@source" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:text>\includegraphics[width=</xsl:text>
    <xsl:value-of select="substring-before($width,'%') div 100" />
    <xsl:text>\linewidth]</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="@source" mode="internal-id" />
    <xsl:if test="not($extension)">
        <xsl:text>.pdf&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Asymptote graphics language  -->
<!-- PDF's produced by mbx script -->
<xsl:template match="image[asymptote]">
    <xsl:variable name="width">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:text>\includegraphics[width=</xsl:text>
    <xsl:value-of select="substring-before($width,'%') div 100" />
    <xsl:text>\linewidth]</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>.pdf}&#xa;</xsl:text>
</xsl:template>

<!-- Sage graphics plots          -->
<!-- PDF's produced by mbx script -->
<!-- PNGs are fallback for 3D     -->
<xsl:template match="image[sageplot]">
    <xsl:variable name="width">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:text>\IfFileExists{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>.pdf}%&#xa;</xsl:text>
    <xsl:text>{\includegraphics[width=</xsl:text>
    <xsl:value-of select="substring-before($width,'%') div 100" />
    <xsl:text>\linewidth]</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>.pdf}}%&#xa;</xsl:text>
    <xsl:text>{\includegraphics[width=</xsl:text>
    <xsl:value-of select="substring-before($width,'%') div 100" />
    <xsl:text>\linewidth]</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>.png}}&#xa;</xsl:text>
</xsl:template>

<!-- LaTeX Image Code (tikz, pgfplots, pstricks, etc) -->
<!-- Clean indentation, drop into LaTeX               -->
<!-- See "latex-image-preamble" for critical parts    -->
<!-- Side-By-Side scaling happens there, could be here -->
<xsl:template match="image[latex-image-code]|image[latex-image]">
    <!-- outer braces rein in the scope of any local graphics settings -->
    <xsl:text>{&#xa;</xsl:text>
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="latex-image-code|latex-image" />
    </xsl:call-template>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- was once direct-descendant of subdivision, this catches that -->
<xsl:template match="latex-image-code[not(parent::image)]">
    <xsl:message>MBX:WARNING: latex-image-code element should be enclosed by an image element</xsl:message>
</xsl:template>

<!-- ################################## -->
<!-- Deprecated Graphics Code Templates -->
<!-- ################################## -->
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="tikz">
    <xsl:message>MBX:WARNING: tikz element superceded by latex-image-code element</xsl:message>
    <xsl:message>MBX:WARNING: tikz package and necessary libraries should be included in docinfo/latex-image-preamble</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="." />
    </xsl:call-template>
</xsl:template>
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="asymptote">
    <xsl:message>MBX:WARNING: asymptote element must be enclosed by an image element - deprecation (2015/02/08)</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:text>\includegraphics[width=0.80\textwidth]{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>.pdf}&#xa;</xsl:text>
</xsl:template>
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="sageplot">
    <xsl:message>MBX:WARNING: sageplot element must be enclosed by an image element - deprecation (2015/02/08)</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:text>\IfFileExists{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>.pdf}%&#xa;</xsl:text>
    <xsl:text>{\includegraphics[width=0.80\textwidth]{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>.pdf}}%&#xa;</xsl:text>
    <xsl:text>{\includegraphics[width=0.80\textwidth]{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>.png}}&#xa;</xsl:text>
</xsl:template>
<!-- ################################## -->
<!-- Deprecated Graphics Code Templates -->
<!-- ################################## -->


<!-- Tables -->

<!-- Top-down organization -->

<!-- A table is like a figure, centered, captioned  -->
<!-- The meat of the table is given by a tabular    -->
<!-- element, which may be used outside of a table  -->
<!-- Standard LaTeX table environment is redefined, -->
<!-- see preamble comments for details              -->
<xsl:template match="table">
    <xsl:if test="not(preceding-sibling::*[not(&SUBDIVISION-METADATA-FILTER;)])">
        <xsl:call-template name="leave-vertical-mode" />
    </xsl:if>
    <xsl:text>\begin{table}&#xa;</xsl:text>
    <xsl:text>\centering&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::caption)]" />
    <xsl:apply-templates select="caption" />
    <xsl:text>\end{table}&#xa;</xsl:text>
</xsl:template>

<!-- A tabular layout -->
<xsl:template match="tabular" name="tabular">
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
    <!-- Build latex column specification                         -->
    <!--   vertical borders (left side, right side, three widths) -->
    <!--   horizontal alignment (left, center, right)             -->
    <xsl:text>\begin{tabular}{</xsl:text>
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
        <xsl:when test="col/@top">
            <xsl:call-template name="column-cols">
                <xsl:with-param name="the-col" select="col[1]" />
                <xsl:with-param name="col-number" select="1" />
                <xsl:with-param name="clines" select="''" />
                <xsl:with-param name="table-top" select="$table-top"/>
                <xsl:with-param name="prior-top" select="'undefined'" />
                <xsl:with-param name="start-run" select="1" />
            </xsl:call-template>
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
    <xsl:apply-templates select="row">
        <xsl:with-param name="table-left" select="$table-left" />
        <xsl:with-param name="table-bottom" select="$table-bottom" />
        <xsl:with-param name="table-right" select="$table-right" />
        <xsl:with-param name="table-halign" select="$table-halign" />
        <xsl:with-param name="table-valign" select="$table-valign" />
    </xsl:apply-templates>
    <!-- mandatory finish, exclusive of any final row specifications -->
    <xsl:text>\end{tabular}&#xa;</xsl:text>
</xsl:template>


<!-- We recursively traverse the "col" elements of the "column" group         -->
<!-- The cline specification is accumulated in the clines variable            -->
<!-- A similar strategy is used to traverse the "cell" elements of each "row" -->
<!-- but becomes much more involved, see the "row-cells" template             -->
<xsl:template name="column-cols">
    <xsl:param name="the-col" />
    <xsl:param name="col-number" />
    <xsl:param name="clines" />
    <xsl:param name="table-top" />
    <xsl:param name="prior-top" />
    <xsl:param name="start-run" />
    <!-- Look ahead one column, anticipating recursion           -->
    <!-- but also probing for end of column group (no more cols) -->
    <xsl:variable name="next-col"  select="$the-col/following-sibling::col[1]" /> <!-- possibly empty -->
    <!-- The desired top border style for this column   -->
    <!-- Considered, but also paid forward as prior-top -->
    <xsl:variable name="current-top">
        <xsl:choose>
            <!-- cell specification -->
            <xsl:when test="$the-col/@top">
                <xsl:value-of select="$the-col/@top" />
            </xsl:when>
            <!-- inherited specification for top -->
            <xsl:otherwise>
                <xsl:value-of select="$table-top" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Formulate any necessary update to cline  -->
    <!-- information for the top border -->
    <xsl:variable name="updated-cline">
        <!-- write current cline information -->
        <xsl:value-of select="$clines" />
        <!-- is there a change, or end of column group, indicating need to flush -->
        <xsl:if test="not($the-col) or not($prior-top = $current-top)">
            <xsl:choose>
                <!-- end of column group and have never flushed -->
                <!-- hence a uniform top border                 -->
                <xsl:when test="not($the-col) and ($start-run = 1)">
                    <xsl:call-template name="hrule-specification">
                        <xsl:with-param name="width" select="$prior-top" />
                    </xsl:call-template>
                </xsl:when>
                <!-- write cline for up-to, and including, prior col   -->
                <!-- prior-top always lags, so never operate on col #1 -->
                <xsl:when test="($col-number != 1) and not($prior-top = 'none')">
                    <xsl:call-template name="crule-specification">
                        <xsl:with-param name="width" select="$prior-top" />
                        <xsl:with-param name="start" select="$start-run" />
                        <xsl:with-param name="finish" select="$col-number - 1" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <!-- no update -->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="new-start-run">
        <xsl:choose>
            <xsl:when test="$col-number = 1 or $prior-top = $current-top">
                <xsl:value-of select="$start-run" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$col-number" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <!-- Call this template on next cell              -->
        <!-- Possibly passing an empty node (as sentinel) -->
        <xsl:when test="$the-col">
            <xsl:call-template name="column-cols">
                <xsl:with-param name="the-col" select="$next-col" />
                <xsl:with-param name="col-number" select="$col-number + 1" />
                <xsl:with-param name="clines" select="$updated-cline" />
                <xsl:with-param name="table-top" select="$table-top" />
                <xsl:with-param name="prior-top" select="$current-top" />
                <xsl:with-param name="start-run" select="$new-start-run" />
            </xsl:call-template>
        </xsl:when>
        <!-- At non-col, done with column group -->
        <!-- conclude line, dump cline info     -->
        <xsl:otherwise>
            <xsl:value-of select="$updated-cline" />
        </xsl:otherwise>
    </xsl:choose>
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
    <!-- End of the row is too late to see if we have the last one -->
    <!-- so we get it here and just kick it down the road          -->
    <xsl:variable name="last-row" select="not(following-sibling::row)" />
    <!-- Walking the row's cells, write contents and bottom borders -->
    <xsl:call-template name="row-cells">
        <xsl:with-param name="the-cell" select="cell[1]" />
        <xsl:with-param name="left-col" select="../col[1]" /> <!-- possibly empty -->
        <xsl:with-param name="left-column-number" select="1" />
        <xsl:with-param name="last-row" select="$last-row" />
        <xsl:with-param name="clines" select="''" />
        <xsl:with-param name="table-left" select="$table-left"/>
        <xsl:with-param name="table-bottom" select="$table-bottom"/>
        <xsl:with-param name="table-right" select="$table-right" />
        <xsl:with-param name="table-halign" select="$table-halign" />
        <xsl:with-param name="table-valign" select="$table-valign" />
        <xsl:with-param name="row-left" select="$row-left" />
        <xsl:with-param name="row-bottom" select="$row-bottom" />
        <xsl:with-param name="prior-bottom" select="'undefined'" />
        <xsl:with-param name="start-run" select="1" />
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Recursively traverse the "cell"'s of a "row" while simultaneously     -->
<!-- traversing the "col" elements of the column group, if present.        -->
<!-- Inspect the (previously) built column specifications to see if        -->
<!-- a \multicolumn is necessary for an override on a table entry          -->
<!-- Accumulate cline information to write at the end of the line/row.     -->
<!-- Study the "column-cols" template for a less-involved template         -->
<!-- that uses an identical strategy, if you want to see something simpler -->
<xsl:template name="row-cells">
    <xsl:param name="the-cell" />
    <xsl:param name="left-col" />
    <xsl:param name="left-column-number" />
    <xsl:param name="last-row" />
    <xsl:param name="clines" />
    <xsl:param name="table-left" />
    <xsl:param name="table-bottom" />
    <xsl:param name="table-right" />
    <xsl:param name="table-halign" />
    <xsl:param name="table-valign" />
    <xsl:param name="row-left" />
    <xsl:param name="row-bottom" />
    <xsl:param name="prior-bottom" />
    <xsl:param name="start-run" />
    <!-- A cell may span several columns, or default to just 1              -->
    <!-- When colspan is not trivial, we identify the left and right ends   -->
    <!-- of the span, both as col elements and as column numbers            -->
    <!-- When colspan is trivial, the left and right versions are identical -->
    <!-- Left is used for left border and for horizontal alignment          -->
    <!-- Right is used for right border                                     -->
    <!-- Left (less 1) is used for lagging cline flushes                    -->
    <xsl:variable name="column-span">
        <xsl:choose>
            <xsl:when test="$the-cell/@colspan">
                <xsl:value-of select="$the-cell/@colspan" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- For a "normal" 1-column cell these variables effectively make copies -->
    <xsl:variable name="right-column-number" select="$left-column-number + $column-span - 1" />
    <xsl:variable name="right-col" select="($left-col/self::*|$left-col/following-sibling::col)[position()=$column-span]" />
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
            <xsl:when test="$the-cell/@right">
                <xsl:value-of select="$the-cell/@right" />
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
            <xsl:when test="$the-cell/@halign">
                <xsl:value-of select="$the-cell/@halign" />
            </xsl:when>
            <!-- look to the row -->
            <xsl:when test="$the-cell/parent::*[1]/@halign">
                <xsl:value-of select="$the-cell/parent::*[1]/@halign" />
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
            <xsl:when test="$the-cell/parent::*[1]/@valign">
                <xsl:value-of select="$the-cell/parent::*[1]/@valign" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$table-valign" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Look ahead to next cell, anticipating recursion   -->
    <!-- but also probing for end of row (no more cells),  -->
    <!-- which is needed when flushing cline specification -->
    <!-- Also advance to next col element from right one   -->
    <xsl:variable name="next-cell" select="$the-cell/following-sibling::cell[1]" /> <!-- possibly empty -->
    <xsl:variable name="next-col"  select="$right-col/following-sibling::col[1]" />
    <!-- Write the cell's contents -->
    <!-- Wrap in a multicolumn in any of the following situations for    -->
    <!-- the purposes of vertical boundary rules or content formatting:  -->
    <!--    -if the left border, horizontal alignment or right border    -->
    <!--         conflict with the column specification                  -->
    <!--    -if we have a colspan                                        -->
    <!--    -if there are paragraphs in the cell                         -->
    <!-- $table-left and $row-left *can* differ on first use,            -->
    <!-- but row-left is subsequently set to $table-left.                -->
    <xsl:if test="$the-cell">
        <xsl:choose>
            <xsl:when test="not($table-left = $row-left) or not($column-halign = $cell-halign) or not($column-right = $cell-right) or ($column-span > 1) or $the-cell/p">
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
                    <xsl:when test="$the-cell/p">
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
                            <!-- If there is no $left-col/@width, terminate -->
                            <xsl:otherwise>
                                <xsl:message terminate="yes">MBX:ERROR:   cell with p element has no corresponding col element with width attribute</xsl:message>
                                <xsl:apply-templates select="." mode="location-report" />
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
                <xsl:call-template name="table-cell-content">
                    <xsl:with-param name="the-cell" select="$the-cell" />
                    <xsl:with-param name="halign" select="$cell-halign" />
                    <xsl:with-param name="valign" select="$row-valign" />
                </xsl:call-template>
                <xsl:text>}</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="table-cell-content">
                    <xsl:with-param name="the-cell" select="$the-cell" />
                    <xsl:with-param name="halign" select="$cell-halign" />
                    <xsl:with-param name="valign" select="$row-valign" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$the-cell/following-sibling::cell">
            <xsl:text>&amp;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- The desired bottom border style for this cell     -->
    <!-- Considered, but also paid forward as prior-bottom -->
    <xsl:variable name="current-bottom">
        <xsl:choose>
            <!-- cell specification -->
            <xsl:when test="$the-cell/@bottom">
                <xsl:value-of select="$the-cell/@bottom" />
            </xsl:when>
            <!-- inherited specification for row -->
            <xsl:otherwise>
                <xsl:value-of select="$row-bottom" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Formulate any necessary update to cline  -->
    <!-- information for the bottom border -->
    <xsl:variable name="updated-cline">
        <!-- write current cline information -->
        <xsl:value-of select="$clines" />
        <!-- is there a change, or end of row, indicating need to flush -->
        <xsl:if test="not($the-cell) or not($prior-bottom = $current-bottom)">
            <xsl:choose>
                <!-- end of row and have never flushed -->
                <!-- hence a uniform bottom border     -->
                <xsl:when test="not($the-cell) and ($start-run = 1)">
                    <xsl:call-template name="hrule-specification">
                        <xsl:with-param name="width" select="$prior-bottom" />
                    </xsl:call-template>
                </xsl:when>
                <!-- write cline for up-to, and including, prior cell      -->
                <!-- prior-bottom always lags, so never operate on cell #1 -->
                <xsl:when test="($left-column-number != 1) and not($prior-bottom = 'none')">
                    <xsl:call-template name="crule-specification">
                        <xsl:with-param name="width" select="$prior-bottom" />
                        <xsl:with-param name="start" select="$start-run" />
                        <xsl:with-param name="finish" select="$left-column-number - 1" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <!-- no update -->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>
    <!-- update start of consecutive run of styles -->
    <xsl:variable name="new-start-run">
        <xsl:choose>
            <xsl:when test="$left-column-number = 1 or $prior-bottom = $current-bottom">
                <xsl:value-of select="$start-run" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$left-column-number" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <!-- Call this template on next cell              -->
        <!-- Possibly passing an empty node (as sentinel) -->
        <xsl:when test="$the-cell">
            <xsl:call-template name="row-cells">
                <xsl:with-param name="the-cell" select="$next-cell" />
                <xsl:with-param name="left-col" select="$next-col" /> <!-- possibly empty -->
                <xsl:with-param name="left-column-number" select="$right-column-number + 1" />
                <xsl:with-param name="last-row" select="$last-row" />
                <xsl:with-param name="clines" select="$updated-cline" />
                <xsl:with-param name="table-left" select="$table-left" />
                <xsl:with-param name="table-bottom" select="$table-bottom" />
                <xsl:with-param name="table-right" select="$table-right" />
                <xsl:with-param name="table-halign" select="$table-halign" />
                <xsl:with-param name="table-valign" select="$table-valign" />
                <!-- next line correct, only allow discrepancy on first use -->
                <xsl:with-param name="row-left" select="$table-left" />
                <xsl:with-param name="row-bottom" select="$row-bottom" />
                <xsl:with-param name="prior-bottom" select="$current-bottom" />
                <xsl:with-param name="start-run" select="$new-start-run" />
            </xsl:call-template>
        </xsl:when>
        <!-- At non-cell, done with row          -->
        <!-- conclude line, dump cline info, etc -->
        <xsl:otherwise>
            <!-- \tabularnewline is unambiguous, better than \\    -->
            <!-- also at a final line with end-of-line decoration  -->
            <xsl:if test="not($updated-cline='') or not($last-row)">
                <xsl:text>\tabularnewline</xsl:text>
            </xsl:if>
            <!-- no harm if end-of-line decoration is empty -->
            <xsl:value-of select="$updated-cline" />
            <!-- next row could begin with bare [ and LaTeX sees -->
            <!-- the start of \tabularnewline[] which would      -->
            <!-- indicate space, so we just appease the macro    -->
            <!-- https://github.com/rbeezer/mathbook/issues/300  -->
            <xsl:if test="$updated-cline='' and not($last-row)">
                <xsl:text>[0pt]</xsl:text>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############################ -->
<!-- Table construction utilities -->
<!-- ############################ -->

<!-- Mostly translating MBX terms to LaTeX terms         -->
<!-- Typically use these at the last moment,             -->
<!-- while outputting, and thus use MBX terms internally -->

<!-- Some utilities are defined in xsl/mathbook-common.xsl -->

<!-- "halign-specification" : param "align" -->
<!--     left, right, center -> l, c, r     -->

<!-- "valign-specification" : param "align" -->
<!--     top, middle, bottom -> t, m, b     -->

<!-- paragraph valign-specifications (p, m, b) are  -->
<!-- different from (t, m, b) in mathbook-common    -->

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
            <xsl:message>MBX:WARNING: vertical alignment attribute not recognized: use top, middle, bottom</xsl:message>
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
            <xsl:message>MBX:WARNING: horizontal alignment attribute not recognized: use left, center, right, justify</xsl:message>
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
            <xsl:message>MBX:WARNING: tabular left or right attribute not recognized: use none, minor, medium, major</xsl:message>
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
            <xsl:message>MBX:WARNING: tabular top or bottom attribute not recognized: use none, minor, medium, major</xsl:message>
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
            <xsl:message>MBX:WARNING: tabular top or bottom attribute not recognized: use none, minor, medium, major</xsl:message>
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

<xsl:template name="table-cell-content">
    <xsl:param name="the-cell" />
    <xsl:param name="halign" />
    <xsl:param name="valign" />
    <xsl:choose>
        <xsl:when test="$the-cell/p">
            <!-- paragraph-halign-specification differs from halign-specification -->
            <xsl:call-template name="paragraph-halign-specification">
                <xsl:with-param name="align" select="$halign" />
            </xsl:call-template>
            <!-- styling choice for interparagraph spacing within a table cell    -->
            <xsl:if test="$the-cell[count(p) &gt; 1]">
                <xsl:text>\setlength{\parskip}{0.5\baselineskip}</xsl:text>
            </xsl:if>
            <xsl:text>%&#xa;</xsl:text>
            <xsl:apply-templates select="$the-cell/p" />
        </xsl:when>
        <xsl:when test="$the-cell/line">
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
            <xsl:apply-templates select="$the-cell/line" />
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="$the-cell" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="cell/line">
    <xsl:apply-templates />
    <!-- is there a next line to separate? -->
    <xsl:if test="following-sibling::*">
        <xsl:text>\\&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- Most cross-references use the traditional LaTeX  -->
<!-- \label, \ref scheme.  But we use \hyperref to    -->
<!-- achieve this, so we get active links in an       -->
<!-- electronic PDF.  We can squelch their electronic -->
<!-- character (and color) for a print version        -->
<!-- with a switch. The flexibility of the hyperref   -->
<!-- package allows us to make our own link text in   -->
<!-- a variety of different ways, duplicating         -->
<!-- functionality of a package like  cleverref.      -->
<!--                                                  -->
<!-- Some objects LaTeX will not number (ie a         -->
<!-- \label{} is ineffective), and others we may not  -->
<!-- want to number.  But we want to cross-reference  -->
<!-- to them anyway (generally, PreTeXt-wide), so we  -->
<!-- use the \hypertarget, \hyperref scheme.          -->
<!--                                                  -->
<!-- The next modal template encodes this distinction -->

<!-- Unless exceptional, traditional LaTeX -->
<xsl:template match="*" mode="xref-as-ref">
    <xsl:value-of select="true()" />
</xsl:template>

<!-- Exceptions -->
<!-- We hard-code some numbers (sectional exercises) and      -->
<!-- we institute some numberings that LaTeX does not do      -->
<!-- naturally - references in extra sections, proofs,        -->
<!-- items in ordered lists (alone or in an exercise),        -->
<!-- hints, answers, solutions. A xref to the very top level  -->
<!-- will land at the table of contents or at the             -->
<!-- title/titlepage. For an exercise group we point to       -->
<!-- the introduction.                                        -->
<xsl:template match="p|paragraphs|blockquote|exercises//exercise|biblio|biblio/note|proof|case|ol/li|dl/li|hint|answer|solution|exercisegroup|book|article|contributor" mode="xref-as-ref">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- Labels  (cross-reference target)-->

<!-- Insert an identifier as a LaTeX label on anything       -->
<!-- Calls to this template need come from where LaTeX likes -->
<!-- a \label, generally someplace that can be numbered      -->
<xsl:template match="*" mode="label">
    <xsl:text>\label{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- We hard-code some numbers (sectional exercises) and          -->
<!-- we institute some numberings that LaTeX does not do          -->
<!-- naturally (references in extra sections, proofs,             -->
<!-- items in ordered lists (alone or in an exercise),            -->
<!-- hints, answers, solutions).  We also point to                -->
<!-- items without numbers, like a "p". For a "label"             -->
<!-- hyperref's hypertarget mechanism fits the bill.              -->
<!-- \null target text was unnecessary and visible (2015-12-12)   -->
<!-- (See also modal templates for "xref-link" and "xref-number") -->
<xsl:template match="p|paragraphs|blockquote|exercises//exercise|biblio|biblio/note|proof|exercisegroup|case|ol/li|dl/li|hint|answer|solution|contributor|colophon" mode="label">
    <xsl:text>\hypertarget{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}{}</xsl:text>
</xsl:template>

<!-- Much of the cross-reference mechanism is -->
<!-- implemented in the common routines,      -->
<!-- here we implement two abstract templates -->
<!-- which are called from those routines     -->

<!-- The "text" of a cross-reference typically includes  -->
<!-- a number and for LaTeX we try as hard as possible   -->
<!-- to use the automatic numbering system.  So the text -->
<!-- is usually a command, "\ref{}".                     -->

<!-- We do not use \cite{} since we allow for multiple     -->
<!-- bibliographies and we do not use AMSmath's \eqref{}.  -->
<!-- Instead, we universally supply the enclosing brackets -->
<!-- and parentheses provided by these LaTeX mechanisms.   -->
<!-- Presumably, careful use of sed would allow these      -->
<!-- distinctions to be recognized in the LaTeX output.    -->

<!-- NB: see extensive discussion of a parallel numbering system -->
<!-- with the hyperref package's hypertarget/hyperlink mechanism -->

<!-- This is the implementation of an abstract template,  -->
<!-- using the LaTeX \ref and \label mechanism.           -->
<!-- We check that the item is numbered or is a displayed -->
<!-- equation with a local tag, before dropping a \ref as -->
<!-- part of the cross-reference                          -->
<xsl:template match="*" mode="xref-number">
    <xsl:param name="xref" select="/.." />
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:if test="not($the-number = '')">
        <!-- check if part prefix is needed -->
        <xsl:variable name="needs-part-prefix">
            <xsl:apply-templates select="." mode="crosses-part-boundary">
                <xsl:with-param name="xref" select="$xref" />
            </xsl:apply-templates>
        </xsl:variable>
        <!-- if so, append prefix with separator -->
        <xsl:if test="$needs-part-prefix = 'true'">
            <xsl:text>\ref{</xsl:text>
            <xsl:apply-templates select="ancestor::part" mode="internal-id" />
            <xsl:text>}</xsl:text>
            <xsl:text>.</xsl:text>
        </xsl:if>
        <!-- and always, a representation for the text of the xref -->
        <xsl:text>\ref{</xsl:text>
        <xsl:apply-templates select="." mode="internal-id" />
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Straightforward exception, simple implementation -->
<xsl:template match="mrow[@tag]" mode="xref-number">
    <xsl:text>\ref{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- We hard-code some numbers (sectional exercises) and    -->
<!-- we institute some numberings that LaTeX does not do    -->
<!-- naturally (references in extra sections, proofs,       -->
<!-- items in ordered lists (alone or in an exercise),      -->
<!-- hints, answers, solutions).  So for the text of a      -->
<!-- cross-reference we use the actual number, not a \ref.  -->
<!-- (See also modal templates for "label" and "xref-link") -->
<!-- Exercises in sets may have hard-coded numbers, -->
<!-- so we provide a hard-coded number              -->
<!-- Footnotes print serial-numbers only, but   -->
<!-- as knowls/references we desire a fully     -->
<!-- qualified number.  So we just override the -->
<!-- visual version in a cross-reference,       -->
<!-- leaving the label/ref mechanism in place.  -->
<xsl:template match="exercises//exercise|biblio|biblio/note|proof|exercisegroup|ol/li|hint|answer|solution|fn" mode="xref-number">
    <xsl:param name="xref" select="/.." />
    <xsl:variable name="needs-part-prefix">
        <xsl:apply-templates select="." mode="crosses-part-boundary">
            <xsl:with-param name="xref" select="$xref" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$needs-part-prefix = 'true'">
        <xsl:apply-templates select="ancestor::part" mode="serial-number" />
        <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<!-- Note: objectives are one-per-subdivision,  -->
<!-- and precede the introduction, so the LaTeX -->
<!-- \ref{} mechanism assigns the correct       -->
<!-- number - that of the enclosing subdivision -->

<!-- Tasks have a structure number from the enclosing project   -->
<!-- and a serial number from the enumitem package on the lists -->
<!-- We compose the two LaTeX \ref{}                            -->
<xsl:template match="task" mode="xref-number">
    <!-- ancestors, strip tasks, get number of next enclosure -->
    <xsl:apply-templates select="ancestor::*[not(self::task)][1]" mode="xref-number" />
    <xsl:text>.</xsl:text>
    <!-- task always gets a number, but we have to avoid recursion -->
    <!-- that would result by just getting a \ref from xref-number -->
    <xsl:text>\ref{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- This is the second abstract template                -->
<!-- We implement every cross-reference with hyperref.   -->
<!-- For pure print, we can turn off the actual links    -->
<!-- in the PDF (and/or control color etc)               -->
<!-- Mostly this is for consistency in the source        -->
<!-- LaTeX linking is not sensitive to being located     -->
<!-- in display mathematics, and so $location is ignored -->
<!-- See xsl/mathbook-common.xsl for more info           -->
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
                <xsl:apply-templates select="$target" mode="internal-id" />
                <xsl:text>}</xsl:text>
            </xsl:variable>
            <xsl:variable name="inactive-ref">
                <xsl:text>\ref*{</xsl:text>
                <xsl:apply-templates select="$target" mode="internal-id" />
                <xsl:text>}</xsl:text>
            </xsl:variable>
            <xsl:value-of select="str:replace($content, $active-ref, $inactive-ref)" />
        </xsl:when>
        <xsl:when test="$xref-as-ref='true'">
            <xsl:text>\hyperref[</xsl:text>
            <xsl:apply-templates select="$target" mode="internal-id" />
            <xsl:text>]</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="$content" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\hyperlink{</xsl:text>
            <xsl:apply-templates select="$target" mode="internal-id" />
            <xsl:text>}</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="$content" />
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################## -->
<!-- Languages, Scripts -->
<!-- ################## -->

<!-- Absent @xml:lang, do nothing -->
<xsl:template match="*" mode="begin-language" />
<xsl:template match="*" mode="end-language" />

<!-- More specifically, change language                -->
<!-- This assumes element is enabled for this behavior -->
<xsl:template match="*[@xml:lang]" mode="begin-language">
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="." mode="country-to-language" />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="*[@xml:lang]" mode="end-language">
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="." mode="country-to-language" />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Even more specifically, we provide an inline version -->
<!-- This should be more readable in LaTex source         -->
<xsl:template match="foreign[@xml:lang]" mode="begin-language">
    <xsl:text>\text</xsl:text>
    <xsl:apply-templates select="." mode="country-to-language" />
    <xsl:text>{</xsl:text>
</xsl:template>

<xsl:template match="foreign[@xml:lang]" mode="end-language">
    <xsl:text>}</xsl:text>
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
    </xsl:choose>
</xsl:template>

<!--        -->
<!-- Poetry -->
<!--        -->

<xsl:template match="poem">
    <xsl:text>\begin{poem}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\poemTitle{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="stanza"/>
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
    <xsl:apply-templates select="line" />
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

<!-- Double Sharp -->
<xsl:template name="doublesharp">
    <xsl:text>{\doublesharp}</xsl:text>
</xsl:template>

<!-- Sharp -->
<xsl:template name="sharp">
    <xsl:text>{\sharp}</xsl:text>
</xsl:template>

<!-- Natural -->
<xsl:template name="natural">
    <xsl:text>{\natural}</xsl:text>
</xsl:template>

<!-- Flat -->
<xsl:template name="flat">
    <xsl:text>{\flat}</xsl:text>
</xsl:template>

<!-- Double Flat -->
<xsl:template name="doubleflat">
    <xsl:text>{\doubleflat}</xsl:text>
</xsl:template>

<!-- Footnotes               -->
<!--   with no customization -->
<xsl:template match="fn">
    <xsl:text>\footnote{</xsl:text>
    <xsl:apply-templates />
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- References Sections -->
<!-- We use description lists to manage bibliographies,  -->
<!-- and \bibitem seems comfortable there, so our source -->
<!-- is nearly compatible with the usual usage           -->

<!-- As an item of a description list, but       -->
<!-- compatible with thebibliography environment -->
<xsl:template match="biblio[@type='raw']">
    <!-- begin the list with first item -->
    <xsl:if test="not(preceding-sibling::biblio)">
        <xsl:text>%% If this is a top-level references&#xa;</xsl:text>
        <xsl:text>%%   you can replace with "thebibliography" environment&#xa;</xsl:text>
        <xsl:text>\begin{referencelist}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\bibitem</xsl:text>
    <!-- "label" (e.g. Jud99), or by default serial number -->
    <!-- LaTeX's bibitem will provide the visual brackets  -->
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="." mode="serial-number" />
    <xsl:text>]</xsl:text>
    <!-- "key" for cross-referencing -->
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id"/>
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:apply-templates />
    <xsl:text>&#xa;</xsl:text>
    <!-- end the list after last item -->
    <xsl:if test="not(following-sibling::biblio)">
        <xsl:text>\end{referencelist}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Raw Bibliographic Entry Formatting              -->
<!-- Markup really, not full-blown data preservation -->

<!-- Title in italics -->
<xsl:template match="biblio[@type='raw']/title">
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- No treatment for journal -->
<xsl:template match="biblio[@type='raw']/journal">
    <xsl:apply-templates />
</xsl:template>

<!-- Volume in bold -->
<xsl:template match="biblio[@type='raw']/volume">
    <xsl:text>\textbf{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Year in parentheses -->
<xsl:template match="biblio[@type='raw']/year">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates />
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- Number, handle TeX period idosyncracy -->
<xsl:template match="biblio[@type='raw']/number">
    <xsl:text>no.\@\,</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Ibid, nee ibidem, handle TeX period idosyncracy, empty element -->
<xsl:template match="biblio[@type='raw']/ibid">
    <xsl:text>Ibid.\@\,</xsl:text>
</xsl:template>


<!-- Annotated Bibliography Items -->
<!--   Presumably just paragraphs, nothing too complicated -->
<!--   We first close off the citation itself -->
<xsl:template match="biblio/note">
    <xsl:text>\par</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->

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

<!-- Author's Inline Verbatim to Escaped LaTeX -->
<!-- 10 wicked LaTeX characters:   & % $ # _ { } ~ ^ \.        -->
<!-- Plus single quote, double quote, and backtick.            -->
<!-- \, {, } all need replacement, and also occur in some      -->
<!-- replacements.  So order, and some care, is necessary.     -->
<!-- In particular, backslash, backtick and groupings can get  -->
<!-- circular, so we use unlikely markers from "mkpasswd" to   -->
<!-- manage replacements.  Generally this is a cleaner, prior  -->
<!-- to wrapping in our \mono macro, implemented with \texttt. -->
<!-- http://tex.stackexchange.com/questions/34580/             -->
<xsl:template name="escape-text-to-latex">
    <xsl:param    name="text" />

    <xsl:variable name="sq">
        <xsl:text>'</xsl:text>
    </xsl:variable>
    <xsl:variable name="dq">
        <xsl:text>"</xsl:text>
    </xsl:variable>
    <xsl:variable name="temp-backslash" select="'[[TlWvKovNykSRI]]'" />
    <xsl:variable name="temp-backtick"  select="'[[ZKEKcAelcqRpk]]'" />

    <xsl:variable name="mark-slash" select="str:replace($text,        '\',     $temp-backslash)" />
    <xsl:variable name="mark-tick"  select="str:replace($mark-slash,  '`',     $temp-backtick)" />
    <xsl:variable name="sans-open"  select="str:replace($mark-tick,   '{',     '\char`\{'      )" />
    <xsl:variable name="sans-close" select="str:replace($sans-open,   '}',     '\char`\}'      )" />
    <xsl:variable name="sans-amp"   select="str:replace($sans-close,  '&amp;', '\&amp;'  )" />
    <xsl:variable name="sans-hash"  select="str:replace($sans-amp,    '#',     '\#'      )" />
    <xsl:variable name="sans-per"   select="str:replace($sans-hash,   '%',     '\%'      )" />
    <xsl:variable name="sans-tilde" select="str:replace($sans-per,    '~',     '\textasciitilde{}')" />
    <xsl:variable name="sans-dollar" select="str:replace($sans-tilde, '$',     '\$' )" />
    <xsl:variable name="sans-under" select="str:replace($sans-dollar, '_',     '\_'      )" />
    <xsl:variable name="sans-caret" select="str:replace($sans-under,  '^',     '\textasciicircum{}')" />
    <xsl:variable name="sans-quote" select="str:replace($sans-caret,  $sq,     '\textquotesingle{}')" />
    <xsl:variable name="sans-dblqt" select="str:replace($sans-quote,  $dq,     '\textquotedbl{}')" />
    <xsl:variable name="sans-tick"  select="str:replace($sans-dblqt,  $temp-backtick,     '\textasciigrave{}')" />
    <xsl:value-of select="str:replace($sans-tick, $temp-backslash, '\textbackslash{}')" />
</xsl:template>

<!-- Escape Console Text to Latex -->
<!-- Similar to above, but fancyvrb BVerbatim only needs -->
<!-- to avoid Latex escape (backslash), begin group ({), -->
<!-- and end group (}) to permit LaTeX macros, such as   -->
<!-- \textbf{} for the bolding of user input.            -->
<xsl:template name="escape-console-to-latex">
    <xsl:param    name="text" />
    <xsl:variable name="temp-backslash" select="'[[TlWvKovNykSRI]]'" />

    <xsl:variable name="mark-slash" select="str:replace($text,       '\', $temp-backslash   )" />
    <xsl:variable name="sans-left"  select="str:replace($mark-slash, '{', '\{'              )" />
    <xsl:variable name="sans-right" select="str:replace($sans-left,  '}', '\}'              )" />
    <xsl:value-of select="str:replace($sans-right, $temp-backslash, '\textbackslash{}')" />
</xsl:template>

<!-- Miscellaneous -->

<!-- Inline warnings go into text, no matter what -->
<!-- They are colored for an author's report      -->
<!-- A bad xml:id might have underscores, so we   -->
<!-- sanitize the entire warning text for LaTeX   -->
<xsl:template name="inline-warning">
    <xsl:param name="warning" />
    <!-- Color for author tools version -->
    <xsl:if test="$author-tools='yes'" >
        <xsl:text>\textcolor{red}</xsl:text>
    </xsl:if>
    <xsl:text>{</xsl:text>
    <xsl:text>$\langle\langle$</xsl:text>
    <xsl:value-of select="str:replace($warning, '_', '\_')" />
    <xsl:text>$\rangle\rangle$</xsl:text>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Marginal notes are only for author's report          -->
<!-- and are always colored red                           -->
<!-- Marginpar's from http://www.f.kth.se/~ante/latex.php -->
<xsl:template name="margin-warning">
    <xsl:param name="warning" />
    <xsl:if test="$author-tools='yes'" >
        <xsl:text>\marginpar[\raggedleft\footnotesize\textcolor{red}{</xsl:text>
        <xsl:value-of select="$warning" />
        <xsl:text>}]{\raggedright\footnotesize\textcolor{red}{</xsl:text>
        <xsl:value-of select="$warning" />
        <xsl:text>}}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Deprecations -->
<!-- These are global, LaTeX-only warnings which are not source -->
<!-- related and not possible in a template once executed       -->
<xsl:template match="mathbook|pretext" mode="deprecation-warnings-latex">
    <!-- 2017-12-18  deprecate console macro characters -->
    <xsl:if test="not($latex.console.macro-char = '')">
        <xsl:call-template name="parameter-deprecation-message">
            <xsl:with-param name="date-string" select="'2017-12-18'" />
            <xsl:with-param name="message" select="'the  latex.console.macro-char  parameter is deprecated, and there is no longer a need to be careful about the backslash (\) character in a console'" />
                <xsl:with-param name="incorrect-use" select="not($latex.console.macro-char = '')" />
        </xsl:call-template>
    </xsl:if>
    <xsl:if test="not($latex.console.begin-char = '')">
        <xsl:call-template name="parameter-deprecation-message">
            <xsl:with-param name="date-string" select="'2017-12-18'" />
            <xsl:with-param name="message" select="'the  latex.console.begin-char  parameter is deprecated, and there is no longer a need to be careful about the begin group ({) character in a console'" />
                <xsl:with-param name="incorrect-use" select="not($latex.console.begin-char = '')" />
        </xsl:call-template>
    </xsl:if>
    <xsl:if test="not($latex.console.end-char = '')">
        <xsl:call-template name="parameter-deprecation-message">
            <xsl:with-param name="date-string" select="'2017-12-18'" />
            <xsl:with-param name="message" select="'the  latex.console.end-char  parameter is deprecated, and there is no longer a need to be careful about the end group (}) character in a console'" />
                <xsl:with-param name="incorrect-use" select="not($latex.console.end-char = '')" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
</xsl:template>

<!-- Uninteresting Code, aka the Bad Bank                    -->
<!-- Deprecated, unmaintained, etc, parked here out of sight -->

<!-- Legacy code: not maintained                  -->
<!-- Banish to common file when removed, as error -->
<!-- 2014/06/25:  All functionality here is replicated -->
<xsl:template match="cite[@ref]">
    <xsl:message>MBX:WARNING: &lt;cite ref="<xsl:value-of select="@ref" />"&gt; is deprecated, convert to &lt;xref ref="<xsl:value-of select="@ref" />"&gt;</xsl:message>
    <xsl:variable name="target" select="id(@ref)" />
        <xsl:text>\cite</xsl:text>
        <xsl:if test="@detail">
            <xsl:text>[</xsl:text>
            <xsl:apply-templates select="@detail" />
            <xsl:text>]</xsl:text>
        </xsl:if>
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="$target" mode="internal-id" />
        <xsl:text>}</xsl:text>
</xsl:template>

</xsl:stylesheet>
