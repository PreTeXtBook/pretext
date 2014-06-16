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

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace" 
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
>

<xsl:import href="./mathbook-common.xsl" />

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="text" />

<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!--  -->
<!-- Fontsize: 10pt, 11pt, or 12pt -->
<!-- extsizes, memoir class offer more sizes -->
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
<!-- Draft Copies                                  -->
<!-- Various options for working copies            -->
<!-- (1) LaTeX's draft mode                        -->
<!-- (2) Crop marks on letter paper, centered      -->
<!--     presuming geometry sets smaller page size -->
<xsl:param name="latex.draft" select="'no'"/>
<!--  -->
<!-- Preamble insertions                    -->
<!-- Insert packages, options into preamble -->
<!-- early or late                          -->
<xsl:param name="latex.preamble.early" select="''" />
<xsl:param name="latex.preamble.late" select="''" />

<!-- Entry template is in mathbook-common file -->

<!-- An article, LaTeX structure -->
<!--     One page, full of sections (with abstract, references)                    -->
<!--     Or, one page, totally unstructured, just lots of paragraphs, widgets, etc -->
<xsl:template match="article">
    <xsl:call-template name="converter-blurb" />
    <xsl:text>\documentclass[</xsl:text>
    <xsl:value-of select="$latex.font.size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$latex.draft='yes'" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{article}&#xa;</xsl:text>
    <xsl:text>%% Load geometry package to allow page margin adjustments&#xa;</xsl:text>
    <xsl:text>\usepackage{geometry}&#xa;</xsl:text>
    <xsl:text>\geometry{letterpaper,total={5.0in,9.0in}}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:call-template name="title-page-info-article" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:if test="/mathbook/article/title or /mathbook/docinfo/event or /mathbook/docinfo/author or/mathbook/docinfo/editor or /mathbook/docinfo/date">
        <xsl:text>\maketitle&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:apply-templates select="abstract"/>
    <xsl:if test="$toc-level > 0">
        <xsl:text>\setcounter{tocdepth}{</xsl:text>
        <xsl:value-of select="$toc-level" />
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\renewcommand*\contentsname{</xsl:text>
        <xsl:call-template name="type-name">
            <xsl:with-param name="generic" select="'toc'" />
        </xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\tableofcontents&#xa;</xsl:text>
        <xsl:text>\clearpage&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="*[not(self::abstract or self::title or self::bibliography)]"/>
    <xsl:apply-templates select="bibliography"/>
    <xsl:call-template name="latex-postamble" />
   <xsl:text>\end{document}</xsl:text>
</xsl:template>

<!-- A book, LaTeX structure -->
<xsl:template match="book">
    <xsl:call-template name="converter-blurb" />
    <xsl:text>\documentclass[</xsl:text>
    <xsl:value-of select="$latex.font.size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$latex.draft='yes'" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{book}&#xa;</xsl:text>
    <xsl:text>%% Load geometry package to allow page margin adjustments&#xa;</xsl:text>
    <xsl:text>\usepackage{geometry}&#xa;</xsl:text>
    <xsl:text>\geometry{letterpaper,total={5.0in,9.0in}}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:call-template name="title-page-info-book" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:text>\frontmatter&#xa;</xsl:text>
    <xsl:call-template name="half-title" />
    <xsl:text>\maketitle&#xa;</xsl:text>
    <xsl:text>\clearpage&#xa;</xsl:text>
    <xsl:call-template name="copyright-page" />
    <xsl:if test="$toc-level > 0">
        <xsl:text>\setcounter{tocdepth}{</xsl:text>
        <xsl:value-of select="$toc-level" />
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\renewcommand*\contentsname{</xsl:text>
        <xsl:call-template name="type-name">
            <xsl:with-param name="generic" select="'toc'" />
        </xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\tableofcontents&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="preface" />
    <xsl:text>\mainmatter&#xa;</xsl:text>
    <xsl:apply-templates select="chapter" />
    <xsl:text>\appendix&#xa;</xsl:text>
    <xsl:apply-templates select="appendix" />
    <xsl:text>\backmatter&#xa;</xsl:text>
    <xsl:apply-templates select="bibliography" />
    <xsl:call-template name="latex-postamble" />
    <xsl:text>\end{document}</xsl:text>
</xsl:template>

<!-- A letter, LaTeX structure -->
<xsl:template match="letter">
    <xsl:call-template name="converter-blurb" />
    <xsl:text>\documentclass[</xsl:text>
    <xsl:value-of select="$latex.font.size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$latex.draft='yes'" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{article}&#xa;</xsl:text>
    <xsl:text>%% Load geometry package to allow page margin adjustments&#xa;</xsl:text>
    <xsl:text>\usepackage{geometry}&#xa;</xsl:text>
    <xsl:text>\geometry{letterpaper,total={6.0in,9.0in}}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <!-- Logos (letterhead images) to first page -->
    <xsl:apply-templates select="/mathbook/docinfo/logo" />
    <xsl:text>\vspace*{0.75in}&#xa;</xsl:text>
    <!-- Sender's address, sans name typically -->
    <!-- and if not already on letterhead -->
    <!-- http://tex.stackexchange.com/questions/13542/flush-a-left-flushed-box-right -->
    <xsl:if test="/mathbook/docinfo/from or /mathbook/docinfo/date">
        <xsl:text>\hfill\begin{tabular}{l@{}}&#xa;</xsl:text>
        <xsl:if test="/mathbook/docinfo/from">
            <xsl:apply-templates select="/mathbook/docinfo/from" />
            <xsl:if test="/mathbook/docinfo/date">
                <xsl:text>\\\ &#xa;</xsl:text>
                <xsl:text>\\&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
        <!-- Date -->
        <xsl:if test="/mathbook/docinfo/date">
            <xsl:apply-templates select="/mathbook/docinfo/date" />
        </xsl:if>
        <xsl:text>&#xa;\end{tabular}\\\par&#xa;</xsl:text>
    </xsl:if>
    <!-- Destination address, flush left -->
    <xsl:if test="/mathbook/docinfo/to">
        <xsl:text>\noindent{}</xsl:text>
        <xsl:apply-templates select="/mathbook/docinfo/to" />
        <xsl:text>\\\par</xsl:text>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <!-- Salutation, flush left -->
    <xsl:if test="/mathbook/docinfo/salutation">
        <xsl:text>\noindent{}</xsl:text>
        <xsl:apply-templates select="/mathbook/docinfo/salutation" />
        <xsl:text>,\\\par</xsl:text>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <!-- process the body -->
    <xsl:apply-templates />
    <!-- Closing block -->
    <xsl:if test="/mathbook/docinfo/closing">
        <xsl:text>\par\vspace*{1.5\baselineskip}\noindent&#xa;</xsl:text>
        <xsl:text>\hspace{\stretch{2}}\begin{tabular}{l@{}}&#xa;</xsl:text>
            <xsl:apply-templates select="/mathbook/docinfo/closing" />
            <!-- TODO: no comma if closing is empty, or make closing a block -->
            <xsl:text>,</xsl:text>
            <xsl:choose>
                <xsl:when test="/mathbook/docinfo/graphic-signature">
                    <xsl:text>\\[1ex]&#xa;</xsl:text>
                    <xsl:text>\includegraphics[height=</xsl:text>
                    <xsl:choose>
                        <xsl:when test="/mathbook/docinfo/graphic-signature/@scale">
                            <xsl:value-of select="/mathbook/docinfo/graphic-signature/@scale" />
                        </xsl:when>
                        <xsl:otherwise>4</xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>ex]{</xsl:text>
                    <xsl:value-of select="/mathbook/docinfo/graphic-signature/@source" />
                    <xsl:text>}\\[0.5ex]&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <!-- About two blank lines for written signature -->
                    <xsl:text>\\[5.5ex]&#xa;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="/mathbook/docinfo/signature" />
        <xsl:text>&#xa;\end{tabular}\hspace{\stretch{1}}&#xa;</xsl:text>
    </xsl:if>
    <!-- Stretchy vertical space, useful if still on page 1 -->
    <xsl:text>\par\vspace*{\stretch{2}}&#xa;</xsl:text>
    <xsl:call-template name="latex-postamble" />
    <xsl:text>\end{document}</xsl:text>
</xsl:template>

<!-- LaTeX preamble is common for both books, articles and letters      -->
<!-- Except: title info allows an "event" for an article (presentation) -->
<xsl:template name="latex-preamble">
    <xsl:text>%% Custom Preamble Entries, early (use latex.preamble.early)&#xa;</xsl:text>
    <xsl:if test="$latex.preamble.early != ''">
        <xsl:value-of select="$latex.preamble.early" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Page Layout Adjustments (latex.geometry)&#xa;</xsl:text>
    <xsl:if test="$latex.geometry != ''">
        <xsl:text>\geometry{</xsl:text>
        <xsl:value-of select="$latex.geometry" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Symbols, align environment, bracket-matrix&#xa;</xsl:text>
    <xsl:text>\usepackage{amsmath}&#xa;</xsl:text>
    <xsl:text>\usepackage{amssymb}&#xa;</xsl:text>
    <xsl:text>%% allow more columns to a matrix&#xa;</xsl:text>
    <xsl:text>%% can make this even bigger by overiding with  latex.preamble.late  processing option&#xa;</xsl:text>
    <xsl:text>\setcounter{MaxMatrixCols}{30}&#xa;</xsl:text>
    <xsl:text>%% XML, MathJax Conflict Macros&#xa;</xsl:text>
    <xsl:text>%% Two nonstandard macros that MathJax supports automatically&#xa;</xsl:text>
    <xsl:text>%% so we always define them in order to allow their use and&#xa;</xsl:text>
    <xsl:text>%% maintain source level compatibility&#xa;</xsl:text>
    <xsl:text>%% This avoids using two XML entities in source mathematics&#xa;</xsl:text>
    <!-- Need CDATA here to protect inequalities as part of an XML file -->
    <xsl:text><![CDATA[\newcommand{\lt}{<}]]>&#xa;</xsl:text>
    <xsl:text><![CDATA[\newcommand{\gt}{>}]]>&#xa;</xsl:text>
    <xsl:text>%% Semantic Macros&#xa;</xsl:text>
    <xsl:text>%% To preserve meaning in a LaTeX file&#xa;</xsl:text>
    <xsl:text>%% Only defined here if required in this document&#xa;</xsl:text>
    <xsl:if test="/mathbook//term">
        <xsl:text>\newcommand{\terminology}[1]{\textbf{#1}}&#xa;</xsl:text>
    </xsl:if>
    <!-- Could condition following on existence of any amsthm environment -->
    <xsl:text>%% Environments with amsthm package&#xa;</xsl:text>
    <xsl:text>\usepackage{amsthm}&#xa;</xsl:text>
    <xsl:text>%% Theorem-like enviroments, italicized statement, proof, etc&#xa;</xsl:text>
    <xsl:text>%% Numbering: X.Y numbering scheme&#xa;</xsl:text>
    <xsl:text>%%   i.e. Corollary 4.3 is third item in Chapter 4 of a book&#xa;</xsl:text>
    <xsl:text>%%   i.e. Lemma 5.6 is sixth item in Section 5 of an article&#xa;</xsl:text>
    <xsl:text>\theoremstyle{plain}&#xa;</xsl:text>
    <xsl:text>%% Always need a theorem environment to set base numbering scheme&#xa;</xsl:text>
    <xsl:text>%% even if document has no theorems (but has other environments)&#xa;</xsl:text>
    <xsl:text>\newtheorem{theorem}{</xsl:text>
    <xsl:call-template name="type-name"><xsl:with-param name="generic" select="'theorem'" /></xsl:call-template>
    <xsl:text>}</xsl:text>
    <xsl:choose>
        <xsl:when test="/mathbook/article"><xsl:text>[section]</xsl:text></xsl:when>
        <xsl:when test="/mathbook/book"><xsl:text>[chapter]</xsl:text></xsl:when>
    </xsl:choose>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>%% Only variants actually used in document appear here&#xa;</xsl:text>
    <xsl:text>%% Numbering: all theorem-like numbered consecutively&#xa;</xsl:text>
    <xsl:text>%%   i.e. Corollary 4.3 follows Theorem 4.2&#xa;</xsl:text>
    <xsl:if test="//corollary">
        <xsl:text>\newtheorem{corollary}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="generic" select="'corollary'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//lemma">
        <xsl:text>\newtheorem{lemma}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="generic" select="'lemma'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//proposition">
        <xsl:text>\newtheorem{proposition}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="generic" select="'proposition'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//claim">
        <xsl:text>\newtheorem{claim}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="generic" select="'claim'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//fact">
        <xsl:text>\newtheorem{fact}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="generic" select="'fact'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//conjecture">
        <xsl:text>\newtheorem{conjecture}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="generic" select="'conjecture'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//axiom">
        <xsl:text>\newtheorem{axiom}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="generic" select="'axiom'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//principle">
        <xsl:text>\newtheorem{principle}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="generic" select="'principle'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//definition or //example or //exercise or //remark">
        <xsl:text>%% Definition-like environments, normal text&#xa;</xsl:text>
        <xsl:text>%% Numbering for definition, examples is in sync with theorems, etc&#xa;</xsl:text>
        <xsl:text>%% also for free-form exercises, not in exercise sections&#xa;</xsl:text>
        <xsl:text>\theoremstyle{definition}&#xa;</xsl:text>
        <xsl:if test="//definition">
            <xsl:text>\newtheorem{definition}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="generic" select="'definition'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//example">
            <xsl:text>\newtheorem{example}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="generic" select="'example'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//exercise">
            <xsl:text>\newtheorem{exercise}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="generic" select="'exercise'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//remark">
            <xsl:text>\newtheorem{remark}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="generic" select="'remark'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:text>%% Raster graphics inclusion, wrapped figures in paragraphs&#xa;</xsl:text>
    <xsl:text>\usepackage{graphicx}&#xa;</xsl:text>
    <xsl:text>%% Colors for Sage boxes and author tools (red hilites)&#xa;</xsl:text>
    <xsl:text>\usepackage[usenames,dvipsnames,svgnames,table]{xcolor}&#xa;</xsl:text>
    <!-- TODO: incorporate global listing options here -->
    <xsl:if test="//sage">
        <xsl:text>%% Sage input, listings package: boxed, colored, line breaking&#xa;</xsl:text>
        <xsl:text>\usepackage{listings}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//tikz">
        <xsl:text>%% Tikz graphics&#xa;</xsl:text>
        <xsl:text>\usepackage{tikz}&#xa;</xsl:text>
        <xsl:text>\usetikzlibrary{backgrounds}&#xa;</xsl:text>
        <xsl:text>\usetikzlibrary{arrows,matrix}&#xa;</xsl:text>
    </xsl:if>
    <!-- Asymptote package just does external processing -->
    <!-- 
    <xsl:if test="//asymptote">
        <xsl:text>%% Asymptote graphics&#xa;</xsl:text>
        <xsl:text>\usepackage[inline]{asymptote}&#xa;</xsl:text>
    </xsl:if>
     -->
    <!-- TODO:  \showidx package as part of a draft mode, prints entries in margin -->
    <xsl:if test="//index">
        <xsl:text>%% Support for index creation&#xa;</xsl:text>
        <xsl:text>%% Requires $ makeindex &lt;filename&gt;&#xa;</xsl:text>
        <xsl:text>%% prior to second LaTeX pass&#xa;</xsl:text>
        <xsl:text>\usepackage{makeidx}&#xa;</xsl:text>
        <xsl:text>\makeindex&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//logo">
        <xsl:text>%% Package for precise image placement (for logos on pages)&#xa;</xsl:text>
        <xsl:text>\usepackage{eso-pic}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Hyperlinking in PDFs, all links solid and blue&#xa;</xsl:text>
    <xsl:text>\usepackage[pdftex]{hyperref}&#xa;</xsl:text>
    <xsl:text>\hypersetup{colorlinks=true,linkcolor=blue,citecolor=blue,filecolor=blue,urlcolor=blue}&#xa;</xsl:text>
    <xsl:text>\hypersetup{pdftitle={</xsl:text>
    <xsl:apply-templates select="title" />
    <xsl:text>}}&#xa;</xsl:text>
    <!-- http://tex.stackexchange.com/questions/44088/when-do-i-need-to-invoke-phantomsection -->
    <xsl:text>%% If you manually remove hyperref, leave in this next command&#xa;</xsl:text>
    <xsl:text>\providecommand\phantomsection{}&#xa;</xsl:text>
    <xsl:if test="$latex.watermark">
        <xsl:text>\usepackage{draftwatermark}&#xa;</xsl:text>
        <xsl:text>\SetWatermarkText{</xsl:text>
        <xsl:value-of select="$latex.watermark" />
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\SetWatermarkScale{</xsl:text>
        <xsl:value-of select="$latex.watermark.scale" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$latex.draft='yes'" >
        <xsl:text>\usepackage[letter,cam,center,pdflatex]{crop}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Custom Preamble Entries, late (use latex.preamble.late)&#xa;</xsl:text>
    <xsl:if test="$latex.preamble.late != ''">
        <xsl:value-of select="$latex.preamble.late" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Convenience macros&#xa;</xsl:text>
    <xsl:if test="/mathbook/docinfo/macros">
        <xsl:call-template name="sanitize-sage">
            <xsl:with-param name="raw-sage-code" select="/mathbook/docinfo/macros" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- LaTeX postamble is common for books, articles and letters      -->
<xsl:template name="latex-postamble">
    <xsl:if test="//index">
        <xsl:text>%% Index goes here at very end&#xa;</xsl:text>
        <xsl:text>\clearpage&#xa;</xsl:text>
        <xsl:text>%% Help hyperref point to the right place&#xa;</xsl:text>
        <xsl:text>\phantomsection&#xa;</xsl:text>
        <xsl:if test="/mathbook/book">
            <xsl:text>\addcontentsline{toc}{chapter}{Index}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="/mathbook/article">
            <xsl:text>\addcontentsline{toc}{section}{Index}&#xa;</xsl:text>
        </xsl:if>
        <xsl:text>\printindex&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template name="title-page-info-book">
    <xsl:text>%% Title page information for book&#xa;</xsl:text>
    <xsl:text>\title{</xsl:text><xsl:apply-templates select="title" /><xsl:text>}&#xa;</xsl:text>
    <xsl:text>\author{</xsl:text><xsl:apply-templates select="/mathbook/docinfo/author" /><xsl:apply-templates select="/mathbook/docinfo/editor" /><xsl:text>}&#xa;</xsl:text>
    <xsl:text>\date{</xsl:text><xsl:apply-templates select="/mathbook/docinfo/date" /><xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Includes an "event" for presentations -->
<xsl:template name="title-page-info-article">
    <xsl:text>%% Title page information for article&#xa;</xsl:text>
    <xsl:text>\title{</xsl:text>
    <xsl:apply-templates select="title" />
    <xsl:if test="/mathbook/docinfo/event">
        <xsl:if test="title">
            <xsl:text>\\</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="/mathbook/docinfo/event" />
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\author{</xsl:text><xsl:apply-templates select="/mathbook/docinfo/author" /><xsl:apply-templates select="/mathbook/docinfo/editor" /><xsl:text>}&#xa;</xsl:text>
    <xsl:text>\date{</xsl:text><xsl:apply-templates select="/mathbook/docinfo/date" /><xsl:text>}&#xa;</xsl:text>
</xsl:template>


<!-- "half-title" is leading page with title only          -->
<!-- at about 1:2 split, presumes in a book               -->
<!-- Series information could go on obverse               -->
<!-- and then do "thispagestyle" on both                  -->
<!-- These two pages contribute to frontmatter page count -->
<xsl:template name="half-title" >
    <xsl:text>%% half-title&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <xsl:text>\begin{center}\Huge&#xa;</xsl:text>
    <xsl:apply-templates select="/mathbook/book/title" />
    <xsl:text>\end{center}\par&#xa;</xsl:text>
    <xsl:text>\vspace*{\stretch{2}}&#xa;</xsl:text>
    <xsl:text>\clearpage&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:text>\clearpage&#xa;</xsl:text>
</xsl:template>

<!-- Copyright page is obverse of title page  -->
<!-- Lots of stuff here, much of it optional  -->
<xsl:template name="copyright-page" >
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:if test="/mathbook/docinfo/author/biography" >
        <xsl:text>{\setlength{\parindent}{0pt}\setlength{\parskip}{4pt}</xsl:text>
        <xsl:apply-templates select="/mathbook/docinfo/author/biography" />}
        <xsl:text>\par\vspace*{\stretch{2}}</xsl:text>
    </xsl:if>
    <xsl:text>\vspace*{\stretch{2}}&#xa;</xsl:text>
    <xsl:if test="/mathbook/docinfo/edition" >
        <xsl:text>\noindent{\bf Edition}: </xsl:text>
        <xsl:apply-templates select="/mathbook/docinfo/edition" />}
        <xsl:text>\par&#xa;</xsl:text>
    </xsl:if>

    <!-- TODO: split out copyright section as template -->
    <xsl:if test="/mathbook/docinfo/copyright" >
        <xsl:text>\noindent\copyright\ </xsl:text>
        <xsl:apply-templates select="/mathbook/docinfo/copyright/year" />
        <xsl:text>\quad </xsl:text>
        <xsl:apply-templates select="/mathbook/docinfo/copyright/holder" />
        <xsl:if test="/mathbook/docinfo/copyright/shortlicense">
            <xsl:text>\\[0.5\baselineskip]&#xa;</xsl:text>
            <xsl:apply-templates select="/mathbook/docinfo/copyright/shortlicense" />
        </xsl:if>
        <xsl:text>\par&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <xsl:text>\clearpage&#xa;</xsl:text>

    <!--ISBN, Cover Design, Publisher, canonicalsite -->

</xsl:template>


<!-- Authors, editors, full info for titlepage -->
<!-- http://stackoverflow.com/questions/2817664/xsl-how-to-tell-if-element-is-last-in-series -->
<xsl:template match="author">
    <xsl:apply-templates select="personname" />
    <xsl:if test = "department">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="department" />
    </xsl:if>
    <xsl:if test = "institution">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="institution" />
    </xsl:if>
    <xsl:if test = "email">
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
        <xsl:with-param name="generic" select="'editor'" />
    </xsl:call-template>
    <xsl:if test = "department">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="department" />
    </xsl:if>
    <xsl:if test = "institution">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="institution" />
    </xsl:if>
    <xsl:if test = "email">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="email" />
    </xsl:if>
    <xsl:if test="position() != last()" >
        <xsl:text>&#xa;\and</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Preface, within \frontmatter is handled correctly by LaTeX-->
<xsl:template match="preface">
    <xsl:text>\chapter{Preface}&#xa;</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Articles may have an abstract at the top level -->
<xsl:template match="abstract">
    <xsl:text>\begin{abstract}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{abstract}&#xa;</xsl:text>
</xsl:template>

<!-- Logos (images) -->
<!-- Fine-grained placement of graphics files on pages      -->
<!-- May be placed anywhere on current page                 -->
<!-- Page coordinates are measured in points                -->
<!-- (0,0) is the lower left corner of the page             -->
<!-- llx, lly: places lower-left corner of graphic          -->
<!-- at the specified coordinates of the page               -->
<!-- Use width, in fixed units (eg cm), to optionally scale -->
<!-- everypage='yes' will place image on every page         -->
<xsl:template match="logo" >
    <xsl:text>\AddToShipoutPicture</xsl:text>
    <xsl:if test="not(@everypage='yes')">
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

<!-- Sectioning -->
<!-- Subdivisions, Chapters down to Paragraphs                -->
<!-- Mostly relies on element names echoing latex names       -->
<!-- (1) appendices are just chapters after \backmatter macro -->
<!-- (2) exercises, references can appear at any depth,       -->
<!--     so compute the subdivision name                      -->
<xsl:template match="chapter|appendix|section|subsection|subsubsection|paragraph|exercises|references">
    <xsl:variable name="level">
        <xsl:choose>
            <!-- TODO: appendix handling is only right for books, expand to articles -->
            <!-- http://www.tex.ac.uk/cgi-bin/texfaq2html?label=appendix -->
            <xsl:when test="local-name(.)='appendix'">
                <xsl:text>chapter</xsl:text>
            </xsl:when>
            <xsl:when test="local-name(.)='exercises' or local-name(.)='references'">
                <xsl:apply-templates select="." mode="latex-level" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="local-name(.)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Information to console for latex run -->
    <xsl:text>\typeout{************************************************}&#xa;</xsl:text>
    <xsl:text>\typeout{</xsl:text>
    <xsl:apply-templates select="." mode="long-name" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\typeout{************************************************}&#xa;</xsl:text>
    <!-- Construct the header of the subdivision -->
    <xsl:text>\</xsl:text>
    <xsl:value-of select="$level" />
    <!-- Optional argument gets used for ToC and headers, identical but with no footnotes -->
    <!-- http://www.tex.ac.uk/cgi-bin/texfaq2html?label=ftnsect -->
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="title/node()[not(self::fn)]" />
    <xsl:text>]</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="title" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;</xsl:text>
    <!-- List the author of this division, if present -->
    <xsl:if test="author">
        <xsl:text>\noindent\Large{\textbf{</xsl:text>
        <xsl:apply-templates select="author" mode="name-list"/>
        <xsl:text>}\par\bigskip&#xa;</xsl:text>
    </xsl:if>
    <!-- Exercises, references are in a numbered list -->
    <xsl:if test="local-name(.)='exercises' or local-name(.)='references'">
        <xsl:text>\begin{enumerate}&#xa;</xsl:text>
    </xsl:if>
    <!-- Process the contents -->
    <xsl:apply-templates select="*[not(self::title or self::author)]"/>
    <!-- Exercises, references are in a list -->
    <xsl:if test="local-name(.)='exercises' or local-name(.)='references'">
        <xsl:text>\end{enumerate}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Theorems, Proofs, Definitions, Examples, Exercises -->

<!-- Theorems have statement/proof structure               -->
<!-- Definitions have notation, which is handled elsewhere -->
<!-- Examples have no additional structure                 -->
<!-- Exercises have solutions                              -->

<!-- Titles are passed as options to environments -->
<xsl:template match="title" mode="environment-option">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates />
    <xsl:text>]</xsl:text>
</xsl:template>

<xsl:template match="theorem|corollary|lemma|proposition|claim|fact">
    <xsl:apply-templates select="statement|proof" />
</xsl:template>

<xsl:template match="definition">
    <xsl:apply-templates select="statement" />
</xsl:template>

<xsl:template match="conjecture|axiom|principle">
    <xsl:apply-templates select="statement" />
</xsl:template>

<!-- Exercises -->
<!-- Free-range exercises go into environments -->
<xsl:template match="exercise">
    <xsl:text>\begin{exercise}</xsl:text>
    <xsl:apply-templates select="title" mode="environment-option" />
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="statement"/>
    <xsl:apply-templates select="hint"/>
    <xsl:apply-templates select="solution"/>
    <xsl:text>\end{exercise}&#xa;</xsl:text>
</xsl:template>

<!-- An exercise in an "exercises" subdivision            -->
<!-- is a list item in an enumerated list                 -->
<!-- Assume solution ends with non-blank-line and newline -->
<!-- TODO: Solution and hint, switches-->
<xsl:template match="exercises//exercise">
    <xsl:text>\item</xsl:text>
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="statement"/>
    <xsl:apply-templates select="hint"/>
    <xsl:apply-templates select="solution"/>
</xsl:template>

<!-- An exercise statement is just a container -->
<xsl:template match="exercise/statement">
    <xsl:apply-templates />
</xsl:template>

<!-- A hint continues the previous paragraph of the statement -->
<xsl:template match="exercise/hint">
    <xsl:if test="$hints.included='yes'">
        <xsl:text>\space&#xa;</xsl:text>
        <xsl:apply-templates select="." mode="type-name" />
        <xsl:text>: </xsl:text>
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>

<!-- Assume pargraphs of solution end with non-blank line and newline -->
<xsl:template match="exercise/solution">
    <xsl:if test="$solutions.included='yes'">
        <xsl:text>\par\smallskip&#xa;\noindent\textbf{</xsl:text>
        <xsl:apply-templates select="." mode="type-name" />
        <xsl:text>.}\quad&#xa;</xsl:text>
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>

<!-- Theorem Environments/Statements -->
<!-- Statements are the place to generate environment -->
<!-- Most information comes from parent               -->
<!-- Proofs are written outside of environment        -->
<xsl:template match="theorem/statement|corollary/statement|lemma/statement|proposition/statement|claim/statement|fact/statement|conjecture/statement|axiom/statement|principle/statement">
    <xsl:text>\begin{</xsl:text>
        <xsl:value-of select="local-name(..)" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="../title" mode="environment-option" />
    <xsl:apply-templates select=".." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{</xsl:text>
        <xsl:value-of select="local-name(..)" />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Proofs -->
<!-- Conjectures, axioms, principles do not have proofs -->
<xsl:template match="proof">
    <xsl:text>\begin{proof}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{proof}&#xa;</xsl:text>
</xsl:template>

<!-- Definition Statement -->
<!-- Definitions are unique, perhaps coulds consolidate into theorem structure -->
<xsl:template match="definition/statement">
    <xsl:text>\begin{definition}</xsl:text>
    <xsl:apply-templates select="../title" mode="environment-option" />
    <xsl:apply-templates select=".." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{definition}&#xa;</xsl:text>
</xsl:template>

<!-- Examples and Remarks -->
<!-- Simpler than theorems, definitions, etc            -->
<!-- Information comes from self, so slightly different -->
<xsl:template match="example|remark">
    <xsl:text>\begin{</xsl:text>
        <xsl:value-of select="local-name(.)" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="title" mode="environment-option" />
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::title)]"/>
    <xsl:text>\end{</xsl:text>
        <xsl:value-of select="local-name(.)" />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="notation">
    <xsl:text>Sample notation (in a master list eventually): $</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>$\par&#xa;</xsl:text>
</xsl:template>

<!-- Paragraphs                         -->
<!-- \par separates paragraphs          -->
<!-- So prior to second, and subsequent -->
<!-- Guarantee: Never a blank line,     -->
<!-- always finish with newline         -->
<xsl:template match="p[1]">
    <xsl:apply-templates />
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="p">
    <xsl:text>\par&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- Index -->
<xsl:template match="index">
    <xsl:text>\index{</xsl:text>
    <xsl:apply-templates select="main" />
    <xsl:apply-templates select="sub" />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="index/sub">
    <xsl:text>!</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Math  -->
<!--       -->

<!-- Inline snippets -->
<!-- It would be nice to produce source          -->
<!-- with \( and \) as delimiters, ala amsmath   -->
<!-- But these break section titles moving to    -->
<!-- the table of contents, for example.         -->
<!-- So we have $ instead.                       -->
<!-- The  fixltx2e  package could be a solution. -->
<xsl:template match= "m">
    <xsl:text>$</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>$</xsl:text>
</xsl:template>

<!-- Unnumbered, single displayed equation -->
<!-- Output follows source line breaks     -->
<xsl:template match="me">
    <xsl:text>\begin{displaymath}</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\end{displaymath}</xsl:text>
</xsl:template>

<!-- Numbered, single displayed equation -->
<!-- Possibly given a label              -->
<!-- Output follows source line breaks   -->
<xsl:template match="men">
    <xsl:text>\begin{equation}</xsl:text>
    <xsl:value-of select="." />
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>\end{equation}</xsl:text>
</xsl:template>

<!-- md, mdn containers are generic gather/align environments, so in common xsl -->

<!-- Rows of a multi-line math display                         -->
<!-- (1) Numbered by align environment, supress as appropriate -->
<!-- (2) Optionally label if numbered                          -->
<!-- (3) Last row special, has no line-break marker            -->
<xsl:template match="mrow">
    <xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="." />
    <xsl:choose>
        <xsl:when test="(local-name(parent::*)='mdn') and (@number='no')">
            <xsl:text>\notag</xsl:text>
        </xsl:when>
        <xsl:when test="(local-name(parent::*)='md') and not(@number='yes')">
            <xsl:text>\notag</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="label"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
        <xsl:when test="position()=last()">
            <xsl:text>&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\\</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Intertext -->
<!-- A LaTeX construct really, so we just do the right thing -->
<xsl:template match="md/intertext|mdn/intertext">
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\intertext{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Lists -->
<xsl:template match="ol">
    <xsl:text>\begin{enumerate}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{enumerate}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="ul">
    <xsl:text>\begin{itemize}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{itemize}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="dl">
    <xsl:text>\begin{description}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{description}&#xa;</xsl:text>
</xsl:template>

<!-- We assume content of list items  -->
<!-- (typically paragraphs), end with -->
<!-- non-blank line and a newline     -->
<xsl:template match="ol/li|ul/li">
    <xsl:text>\item </xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Description lists get additional argument next -->
<xsl:template match="dl/li">
    <xsl:text>\item</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Description lists *must* have titled elements -->
<!-- Leave space before start of content           -->
<xsl:template match="dl/li/title">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates />
    <xsl:text>] </xsl:text>
</xsl:template>


<!-- Markup, typically within paragraphs            -->
<!-- Quotes, double or single, see quotations below -->
<xsl:template match="q">
    <xsl:text>``</xsl:text>
    <xsl:apply-templates />
    <xsl:text>''</xsl:text>
</xsl:template>

<xsl:template match="sq">
    <xsl:text>`</xsl:text>
    <xsl:apply-templates />
    <xsl:text>'</xsl:text>
</xsl:template>

<!-- Actual Quotations                -->
<!-- TODO: <quote> element for inline -->
<xsl:template match="blockquote">
    <xsl:text>\begin{quote}</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{quote}</xsl:text>
</xsl:template>

<!-- Use at the end of a blockquote -->
<xsl:template match="blockquote/attribution">
    <xsl:text>\\\hspace*{\stretch{1}}\textemdash\space </xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Emphasis -->
<xsl:template match="em">
    <xsl:text>\emph{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Defined terms (bold) -->
<!-- Need to write definition of \terminology -->
<!-- into preamble as semantic macro          -->
<xsl:template match="term">
    <xsl:text>\terminology{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Code, inline -->
<!-- A question mark is invalid Python, but may need to be more general here? -->
<xsl:template match="c">
    <xsl:text>\verb?</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>?</xsl:text>
</xsl:template>

<!-- External URLs, and email addresses -->
<!-- URL itself, if content-less -->
<!-- http://stackoverflow.com/questions/9782021/check-for-empty-xml-element-using-xslt -->
<xsl:template match="url">
    <xsl:choose>
        <xsl:when test="not(*) and not(normalize-space())">
            <xsl:text>\url{</xsl:text>
            <xsl:value-of select="@href" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\href{</xsl:text>
            <xsl:value-of select="@href" />
            <xsl:text>}{</xsl:text>
            <xsl:apply-templates />
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="email">
    <xsl:text>\href{mailto:</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>}{\nolinkurl{</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>}}</xsl:text>
</xsl:template>    

<!-- Special Characters from TeX -->
<!--    # $ % ^ & _ { } ~ \      -->
<!-- These need special treatment, elements     -->
<!-- here are for text mode, and are not for    -->
<!-- use inside mathematics elements, e.g. <m>. -->

<!-- Number Sign, Hash, Octothorpe -->
<xsl:template match="hash">
    <xsl:text>\#</xsl:text>
</xsl:template>

<!-- Dollar sign -->
<xsl:template match="dollar">
    <xsl:text>\$</xsl:text>
</xsl:template>

<!-- Percent sign -->
<xsl:template match="percent">
    <xsl:text>\%</xsl:text>
</xsl:template>

<!-- Circumflex  -->
<xsl:template match="circum">
    <xsl:text>\textasciicircum </xsl:text>
</xsl:template>

<!-- Ampersand -->
<!-- Not for controlling mathematics -->
<!-- or table formatting             -->
<xsl:template match="ampersand">
    <xsl:text>\&amp;</xsl:text>
</xsl:template>

<!-- Text underscore -->
<xsl:template match="underscore">
    <xsl:text>\_</xsl:text>
</xsl:template>

<!-- Braces -->
<!-- Individually, or matched -->
<xsl:template match="lbrace">
    <xsl:text>\{</xsl:text>
</xsl:template>
<xsl:template match="rbrace">
    <xsl:text>\}</xsl:text>
</xsl:template>
<xsl:template match="braces">
    <xsl:text>\{</xsl:text>
    <xsl:apply-templates />>
    <xsl:text>\}</xsl:text>
</xsl:template>

<!-- Tilde -->
<xsl:template match="tilde">
    <xsl:text>\textasciitilde </xsl:text>
</xsl:template>

<!-- Backslash -->
<!-- See url element for comprehensive approach -->
<xsl:template match="backslash">
    <xsl:text>\textbackslash </xsl:text>
</xsl:template>

<!-- Other Miscellaneous Symbols, Constructions -->

<!-- Ellipsis (dots), for text, not math -->
<xsl:template match="ellipsis">
    <xsl:text>\dots </xsl:text>
</xsl:template>

<!-- \@ following a period makes it an abbreviation, not the end of a sentence -->
<!-- So use it for abbreviations which will not end a sentence                 -->
<!-- Best: \makeatletter\newcommand\etc{etc\@ifnextchar.{}{.\@}}\makeatother   -->
<!-- http://latex-alive.tumblr.com/post/827168808/correct-punctuation-spaces   -->

<!-- for example -->
<xsl:template match="eg">
    <xsl:text>e.g.\@</xsl:text>
</xsl:template>

<!-- Copyright symbol -->
<xsl:template match="copyright">
    <xsl:text>\copyright </xsl:text>
</xsl:template>


<!-- in other words -->
<xsl:template match="ie">
    <xsl:text>i.e.\@</xsl:text>
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
<xsl:template match="latex">
    <xsl:text>\LaTeX </xsl:text>
</xsl:template>
<xsl:template match="tex">
    <xsl:text>\TeX </xsl:text>
</xsl:template>

<!-- Foreign words/idioms        -->
<!-- Matches HTML5 specification -->
<xsl:template match="foreign">
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Line Breaks -->
<!-- \newline works best in table cells in paragraph mode       -->
<!-- so as to not be confused with \\ at the end of a table row -->
<!-- use sparingly, e.g. for poetry, *not* in math environments -->
<!-- Must be in TeX's paragraph mode                            -->
<xsl:template match="br">
    <xsl:text>\newline </xsl:text>
</xsl:template>

<!-- Non-breaking space, which "joins" two words as a unit -->
<xsl:template match="nbsp">
    <xsl:text>~</xsl:text>
</xsl:template>


<!-- Dashes -->
<!-- http://www.public.asu.edu/~arrows/tidbits/dashes.html -->
<xsl:template match="mdash">
    <xsl:text>\textemdash </xsl:text>
</xsl:template>
<xsl:template match="ndash">
    <xsl:text>\textendash </xsl:text>
</xsl:template>
<xsl:template match="hyphen">
    <xsl:text>-</xsl:text>
</xsl:template>

<!-- Titles of Books and Articles -->
<xsl:template match="booktitle">
    <xsl:text>\textsl{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="articletitle">
    <xsl:text>``</xsl:text>
    <xsl:apply-templates />
    <xsl:text>''</xsl:text>
</xsl:template>

<!-- Sage -->
<xsl:template match="sage">
    <xsl:apply-templates select="input" />
    <xsl:if test="output">
        <xsl:apply-templates select="output" />
    </xsl:if>
</xsl:template>

<xsl:template match="input">
    <xsl:text>\begin{lstlisting}[language=Python,breaklines=true,breakatwhitespace=true,basicstyle=\small\ttfamily,columns=fixed,frame=single,frameround=tttt,backgroundcolor=\color{blue!10},xleftmargin=4ex,xrightmargin=4ex]&#xa;</xsl:text>
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="." />
    </xsl:call-template>
    <xsl:text>\end{lstlisting}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="output">
    <xsl:text>\begin{lstlisting}[language=Python,breaklines=true,breakatwhitespace=true,basicstyle=\small\ttfamily,columns=fixed,xleftmargin=8ex,xrightmargin=4ex]&#xa;</xsl:text>
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="." />
    </xsl:call-template>
    <xsl:text>\end{lstlisting}&#xa;</xsl:text>
</xsl:template>

<!-- Geogebra                                     -->
<!-- Stock warning, or possible figure processing -->
<xsl:template match="geogebra-applet[not(ggbBase64)]">
    <xsl:text>\par\smallskip\centerline{Blank GeoGebra canvas is here in Web version.}\smallskip</xsl:text>
</xsl:template>

<xsl:template match="geogebra-applet[ggbBase64]">
    <xsl:choose>
        <xsl:when test="figure">
            <xsl:apply-templates select="figure" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\par\smallskip\centerline{A GeoGebra demonstration is here in Web version.}\smallskip</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Captions for Figures and Tables -->
<!-- xml:id is on parent, but LaTeX generates number with caption -->
<xsl:template match="caption">
    <xsl:text>\caption{</xsl:text>
    <xsl:apply-templates />
    <xsl:apply-templates select=".." mode="label" />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Figures -->
<!-- For floatation advice see                                                                            -->
<!-- http://tex.stackexchange.com/questions/2275/keeping-tables-figures-close-to-where-they-are-mentioned -->
<xsl:template match="figure">
    <xsl:text>\begin{figure}[!htbp]&#xa;</xsl:text>
    <xsl:text>\centering&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::caption)]"/>
    <xsl:apply-templates select="caption" />
    <xsl:text>\end{figure}&#xa;</xsl:text>
</xsl:template>

<!-- Images -->
<xsl:template match="image" >
    <xsl:text>\includegraphics[</xsl:text>
        <xsl:if test="@width">
            <xsl:text>width=</xsl:text><xsl:value-of select="@width" /><xsl:text>pt,</xsl:text>
        </xsl:if>
        <xsl:if test="@height">
            <xsl:text>height=</xsl:text><xsl:value-of select="@height" /><xsl:text>pt,</xsl:text>
        </xsl:if>
    <xsl:text>]</xsl:text>
    <xsl:text>{</xsl:text><xsl:value-of select="@source" /><xsl:text>}</xsl:text>
</xsl:template>

<!-- tikz graphics language -->
<!-- preliminary (cursory) support -->
<!-- http://tex.stackexchange.com/questions/4338/correctly-scaling-a-tikzpicture -->
<!-- Resize entire tikzpicture with \resizebox{0.75\textwidth}{!}{....}          -->
<xsl:template match="tikz">
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="." />
    </xsl:call-template>
</xsl:template>

<!-- Asymptote graphics language -->
<!-- preliminary (cursory) support -->
<!-- http://asymptote.sourceforge.net/doc/LaTeX-usage.html -->
<!-- TODO: better to just process this externally               -->
 <!--      since this is all the asympotote package does anyway -->
<xsl:template match="asymptote">
<!--     <xsl:text>\begin{asy}&#xa;</xsl:text>
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="." />
    </xsl:call-template>
    <xsl:text>\end{asy}&#xa;</xsl:text> -->
</xsl:template>

<!-- Tables -->
<!-- Follow "XML Exchange Table Model"           -->
<!-- A subset of the (failed) "CALS Table Model" -->
<!-- Should be able to replace this by extant XSLT for this conversion -->
<!-- See http://stackoverflow.com/questions/19716449/converting-xhtml-table-to-latex-using-xslt -->
<xsl:template match="table">
    <xsl:text>\begin{table}[thb]\centering&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::caption)]" />
    <xsl:apply-templates select="caption" />
    <xsl:text>\end{table}&#xa;</xsl:text>
    </xsl:template>

<!-- Unclear how to handle *multiple* tgroups in latex -->
<xsl:template match="tgroup">
    <xsl:text>\begin{tabular}</xsl:text>
    <xsl:text>{*{</xsl:text>
    <xsl:value-of select="@cols" />
    <xsl:text>}{</xsl:text>
    <xsl:choose>
        <xsl:when test="@align='left'">  <xsl:text>l</xsl:text></xsl:when>
        <xsl:when test="@align='center'"><xsl:text>c</xsl:text></xsl:when>
        <xsl:when test="@align='right'"> <xsl:text>r</xsl:text></xsl:when>
        <xsl:otherwise>                  <xsl:text>c</xsl:text></xsl:otherwise>
    </xsl:choose>
    <xsl:text>}}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{tabular}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="thead">
    <xsl:text>\hline\hline </xsl:text>
    <xsl:apply-templates />
    <xsl:text>\\\hline\hline </xsl:text>
</xsl:template>

<xsl:template match="tbody">
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="row">
    <xsl:apply-templates />
    <xsl:text>\\&#xa;</xsl:text>
</xsl:template>

<xsl:template match="entry[1]">
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="entry">
    <xsl:text>&amp;</xsl:text>
    <xsl:apply-templates />
</xsl:template>


<!-- Cross-References, Citations -->

<!-- Point to bibliographic entries with cite -->
<!-- Point to other items with xref           -->
<!-- These can be "provisional"          -->
<!-- as a tool for drafts, otherwise "ref" to -->
<!-- an xml:id elsewhere                      -->
<!-- Warnings at command-line for mess-ups are in common file -->
<!-- TODO: make citation references blue (not green box) in hyperref -->
<!-- TODO: make citations work like xrefs                            -->
<xsl:template match="cite[@ref]">
    <xsl:variable name="target" select="id(@ref)" />
    <xsl:if test="$target/parent::bibliography">
        <xsl:text>\cite{</xsl:text>
        <xsl:apply-templates select="$target" mode="xref-identifier" />
        <xsl:text>}</xsl:text>
    </xsl:if>
    <!-- We allow biblio items in ordered lists, other than bibliography -->
    <!-- So we have to roll our own citations as \ref (cross-references) -->
    <xsl:if test="$target/parent::ol">
        <xsl:text>[\ref{</xsl:text>
        <xsl:apply-templates select="$target" mode="xref-identifier" />
        <xsl:text>}]</xsl:text>
    </xsl:if>
</xsl:template>

<!-- LaTeX references equations differently than theorems, etc -->
<xsl:template match="xref[@ref]">
    <xsl:variable name="target" select="id(@ref)" />
    <!-- Check to see if the ref is any good -->
    <!-- http://www.stylusstudio.com/xsllist/200412/post20720.html -->
    <xsl:if test="not(exsl:node-set($target)/*)">
        <xsl:message>MBX:WARNING: unresolved xref due to ref="<xsl:value-of select="@ref"/>"</xsl:message>
    </xsl:if>
    <xsl:choose>
        <xsl:when test="$target/self::mrow or $target/self::me or $target/self::men">
            <xsl:text>\eqref{</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\ref{</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="$target" mode="internal-id" />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="cite[@provisional]|xref[@provisional]">
    <xsl:if test="$author-tools='yes'" >
        <xsl:text>\textcolor{red}{</xsl:text>
    </xsl:if>
    <xsl:text>$\langle\langle$</xsl:text>
    <xsl:value-of select="@provisional" />
    <xsl:text>$\rangle\rangle$</xsl:text>
    <xsl:if test="$author-tools='yes'" >
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>


<!-- Insert a xref identifier as a LaTeX label on anything   -->
<!-- Calls to this template need come from where LaTeX likes -->
<!-- a \label, generally someplace that can be numbered      -->
<!-- Could do optionally: <xsl:value-of select="@xml:id" />  -->
<xsl:template match="*" mode="label">
    <xsl:text>\label{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Footnotes               -->
<!--   with no customization -->
<xsl:template match="fn">
    <xsl:text>\footnote{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- References/Bibliography -->

<!-- Enclosing structure of main bibliography                      -->
<!-- Use LaTeX structure for top-level, to make compatible output  -->
<!-- thebibliography environment needs count of bibitem's          -->
<!-- to set width for numbering                                    -->
<!-- We overide LaTeX's "References" to support other languages    -->
<!-- http://www.latex-community.org/forum/viewtopic.php?f=5&t=4089 -->
<!-- http://www.tex.ac.uk/cgi-bin/texfaq2html?label=fixnam         -->
<xsl:template match="book/references">
    <xsl:text>\renewcommand{\bibname}{</xsl:text>
    <xsl:apply-templates select="title"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\begin{thebibliography}{</xsl:text>
    <xsl:value-of select="count(biblio)"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::title)]"/>
    <xsl:text>\end{thebibliography}&#xa;</xsl:text>
</xsl:template>
<!-- Entirely similar, but for renew'ed command name -->
<xsl:template match="article/references">
    <xsl:text>\renewcommand{\refname}{</xsl:text>
    <xsl:apply-templates select="title"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\begin{thebibliography}{</xsl:text>
    <xsl:value-of select="count(biblio)"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::title)]"/>
    <xsl:text>\end{thebibliography}&#xa;</xsl:text>
</xsl:template>
<!-- References at other levels are just ordered lists in a subdivision     -->
<!-- This gets handled in the generic sectioning code, just like exercises  -->

<!-- Raw Bibliographic Entry Formatting              -->
<!-- Markup really, not full-blown data preservation -->

<!-- As a TeX \bibitem in top-level bibliography-->
<xsl:template match="book/references/biblio[@type='raw']|article/references/biblio[@type='raw']">
    <xsl:text>\bibitem{</xsl:text>
    <xsl:apply-templates select="." mode="xref-identifier"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- As an item of a plain numbered list, for subsidiary references -->
<xsl:template match="biblio[@type='raw']">
    <xsl:text>\item</xsl:text>
    <xsl:apply-templates select="." mode="label"/>
    <xsl:apply-templates />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Bibliographic items can have annotations            -->
<!-- Presumably just paragraphs, nothing too complicated -->
<!-- We first close off the citation itself -->
<xsl:template match="biblio/note">
    <xsl:text>\par </xsl:text>
    <xsl:apply-templates />
</xsl:template>

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

<!-- Number, handle TeX period idosyncracy -->
<xsl:template match="biblio[@type='raw']/number">
    <xsl:text>no.\@\,</xsl:text>
    <xsl:apply-templates />
</xsl:template>



<!-- Level names in LaTeX -->

<xsl:template match="*" mode="latex-level">
    <xsl:variable name="level">
        <xsl:apply-templates select="." mode="level" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="/mathbook/book">
            <xsl:choose>
                <xsl:when test="$level=0">book</xsl:when>
                <xsl:when test="$level=1">chapter</xsl:when>
                <xsl:when test="$level=2">section</xsl:when>
                <xsl:when test="$level=3">subsection</xsl:when>
                <xsl:when test="$level=4">subsubsection</xsl:when>
                <xsl:otherwise>
                    <xsl:message>ERROR: Level computation is out-of-bounds (<xsl:value-of select="$level" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="/mathbook/article">
            <xsl:choose>
                <xsl:when test="$level=0">article</xsl:when>
                <xsl:when test="$level=1">section</xsl:when>
                <xsl:when test="$level=2">subsection</xsl:when>
                <xsl:when test="$level=3">subsubsection</xsl:when>
                <xsl:otherwise>
                    <xsl:message>ERROR: Level computation is out-of-bounds (<xsl:value-of select="$level" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>ERROR: Level computation only for books, articles</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Miscellaneous -->

<!-- ToDo's are silent unless asked for                   -->
<!-- Can also grep across the source                      -->
<!-- Marginpar's from http://www.f.kth.se/~ante/latex.php -->
<xsl:template match="todo">
    <xsl:if test="$author-tools='yes'" >
        <xsl:text>\marginpar[\raggedleft\footnotesize\textcolor{red}{</xsl:text>
        <xsl:apply-templates select="." mode="type-name" />
        <xsl:text>: </xsl:text>
        <xsl:apply-templates />
        <xsl:text>}]{\raggedright\footnotesize\textcolor{red}{</xsl:text>
        <xsl:apply-templates select="." mode="type-name" />
        <xsl:text>: </xsl:text>
        <xsl:apply-templates />
        <xsl:text>}}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Converter information for header -->
<!-- TODO: add date, URL -->
<xsl:template name="converter-blurb">
    <xsl:text>%%                                    %%&#xa;</xsl:text>
    <xsl:text>%% Generated from MathBook XML source %%&#xa;</xsl:text>
    <xsl:text>%%    on </xsl:text>
    <xsl:value-of select="date:date-time()" />
    <xsl:text>    %%&#xa;</xsl:text>
    <xsl:text>%%                                    %%&#xa;</xsl:text>
    <xsl:text>%%   http://mathbook.pugetsound.edu   %%&#xa;</xsl:text>
    <xsl:text>%%                                    %%&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
