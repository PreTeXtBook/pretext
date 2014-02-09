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
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="date"
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
<xsl:param name="latex.geometry" select="'letterpaper,total={5.0in,9.0in}'"/>
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

<xsl:template match="/" >
    <xsl:apply-templates select="mathbook"/>
</xsl:template>

<!-- docinfo is handled specially                     -->
<!-- so gets killed via apply-templates                -->
<xsl:template match="docinfo"></xsl:template>


<!-- An article, LaTeX structure -->
<xsl:template match="article">
    <xsl:call-template name="converter-blurb" />
    <xsl:text>\documentclass[</xsl:text>
    <xsl:value-of select="$latex.font.size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$latex.draft='yes'" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{article}&#xa;%&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:call-template name="title-page-info-article" />
    <xsl:text>\begin{document}&#xa;%&#xa;</xsl:text>
    <xsl:if test="/mathbook/article/title or /mathbook/docinfo/event or /mathbook/docinfo/author or /mathbook/docinfo/date">
        <xsl:text>\maketitle&#xa;%&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\thispagestyle{empty}&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates select="/mathbook/docinfo/abstract" />
    <xsl:apply-templates />
    <xsl:text>\end{document}&#xa;</xsl:text>
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
    <xsl:text>]{book}&#xa;%&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:call-template name="title-page-info-book" />
    <xsl:text>\begin{document}&#xa;%&#xa;</xsl:text>
    <xsl:text>\frontmatter&#xa;%&#xa;</xsl:text>
    <xsl:call-template name="half-title" />
    <xsl:text>\maketitle&#xa;</xsl:text>
    <xsl:text>\clearpage&#xa;%&#xa;</xsl:text>
    <xsl:call-template name="copyright-page" />
    <xsl:text>\tableofcontents&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates select="preface" />
    <xsl:text>\mainmatter&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates select="chapter" />
    <xsl:text>\appendix&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates select="appendix" />
    <xsl:text>\backmatter&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates select="bibliography" />
    <xsl:text>\end{document}&#xa;</xsl:text>
</xsl:template>

<!-- LaTeX preamble is common for both books and articles               -->
<!-- Except: title info allows an "event" for an article (presentation) -->
<xsl:template name="latex-preamble">
    <xsl:text>%% Custom entries to preamble, early&#xa;</xsl:text>
    <xsl:value-of select="$latex.preamble.early" />
    <xsl:text>&#xa;</xsl:text>
<xsl:text>%% Page layout
\usepackage{geometry}&#xa;</xsl:text>
<xsl:text>\geometry{</xsl:text>
<xsl:value-of select="$latex.geometry" />
<xsl:text>}&#xa;</xsl:text>
<xsl:text>%% Symbols, align environment, bracket-matrix
\usepackage{amsmath}
%% allow more columns to a matrix
%% can make this even bigger by overiding with preamble addition
\setcounter{MaxMatrixCols}{30}
\usepackage{amssymb}
%% Two nonstandard macros that MathJax supports automatically
%% so we define them in order to allow their use and
%% maintain source level compatibility
%% This avoids using two XML entities in source mathematics&#xa;</xsl:text>
<!-- Need CDATA here to protect inequalities as part of an XML file -->
<xsl:text><![CDATA[\newcommand{\lt}{<}]]>&#xa;</xsl:text>
<xsl:text><![CDATA[\newcommand{\gt}{>}]]>&#xa;</xsl:text>
<xsl:text>%% Environments with amsthm package&#xa;</xsl:text>
<xsl:text>\usepackage{amsthm}&#xa;</xsl:text>
<xsl:text>% Theorem-like enviroments, italicized statement, proof, etc&#xa;</xsl:text>
<xsl:text>% Numbering: X.Y numbering scheme&#xa;</xsl:text>
<xsl:text>%   i.e. Corollary 4.3 is third item in Chapter 4 of a book&#xa;</xsl:text>
<xsl:text>%   i.e. Lemma 5.6 is sixth item in Section 5 of an article&#xa;</xsl:text>
<xsl:text>\theoremstyle{plain}&#xa;</xsl:text>
<xsl:if test="//theorem">
    <xsl:text>\newtheorem{theorem}{</xsl:text>
    <xsl:call-template name="type-name"><xsl:with-param name="generic" select="'theorem'" /></xsl:call-template>
    <xsl:text>}</xsl:text>
    <xsl:choose>
        <xsl:when test="/mathbook/article"><xsl:text>[section]</xsl:text></xsl:when>
        <xsl:when test="/mathbook/book"><xsl:text>[chapter]</xsl:text></xsl:when>
    </xsl:choose>
    <xsl:text>&#xa;</xsl:text>
</xsl:if>
<xsl:text>% Only variants actually used in document appear here&#xa;</xsl:text>
<xsl:text>% Numbering: all theorem-like numbered consecutively&#xa;</xsl:text>
<xsl:text>%   i.e. Corollary 4.3 follows Theorem 4.2&#xa;</xsl:text>
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
<xsl:text>% definition-like, normal text
\theoremstyle{definition}
\newtheorem{definition}{Definition}
\newtheorem{example}{Example}
\newtheorem{exercise}{Exercise}&#xa;</xsl:text>
<xsl:text>%% Raster graphics inclusion, wrapped figures in paragraphs&#xa;</xsl:text>
<xsl:text>\usepackage{graphicx}&#xa;</xsl:text>
<xsl:text>%% Colors for Sage boxes and author tools (red hilites)&#xa;</xsl:text>
<xsl:text>\usepackage[usenames,dvipsnames,svgnames,table]{xcolor}&#xa;</xsl:text>
<xsl:if test="//sage">
    <xsl:text>%% Sage input: boxed, colored&#xa;</xsl:text>
    <xsl:text>\usepackage{mdframed}&#xa;</xsl:text>
    <xsl:text>\mdfdefinestyle{sageinput}{backgroundcolor=blue!10,skipabove=2ex,skipbelow=2ex}&#xa;</xsl:text>
    <xsl:text>\mdfdefinestyle{sageoutput}{linecolor=white,leftmargin=4ex,skipbelow=2ex}&#xa;</xsl:text>
</xsl:if>
<xsl:if test="//tikz">
    <xsl:text>%% Tikz graphics&#xa;</xsl:text>
    <xsl:text>\usepackage{tikz}&#xa;</xsl:text>
    <xsl:text>\usetikzlibrary{backgrounds}&#xa;</xsl:text>
    <xsl:text>\usetikzlibrary{arrows,matrix}&#xa;</xsl:text>
</xsl:if>
<xsl:if test="//asymptote">
    <xsl:text>%% Asymptote graphics&#xa;</xsl:text>
    <xsl:text>\usepackage[inline]{asymptote}&#xa;</xsl:text>
</xsl:if>
<xsl:text>%% Hyperlinking in PDFs, all links solid and blue
\usepackage[pdftex]{hyperref}
\hypersetup{colorlinks=true,linkcolor=blue,citecolor=blue,filecolor=blue,urlcolor=blue}&#xa;</xsl:text>
<xsl:text>\hypersetup{pdftitle={</xsl:text>
<xsl:apply-templates select="title/node()" />
<xsl:text>}}&#xa;</xsl:text>
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
<xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% Custom entries to preamble, late&#xa;</xsl:text>
    <xsl:value-of select="$latex.preamble.late" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>%% Convenience macros&#xa;</xsl:text>
    <xsl:value-of select="/mathbook/docinfo/macros" /><xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template name="title-page-info-book">
    <xsl:text>%% Title page information for book&#xa;</xsl:text>
    <xsl:text>\title{</xsl:text><xsl:apply-templates select="title/node()" /><xsl:text>}&#xa;</xsl:text>
    <xsl:text>\author{</xsl:text><xsl:apply-templates select="/mathbook/docinfo/author" /><xsl:text>}&#xa;</xsl:text>
    <xsl:text>\date{</xsl:text><xsl:apply-templates select="/mathbook/docinfo/date" /><xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Includes an "event" for presentations -->
<xsl:template name="title-page-info-article">
    <xsl:text>%% Title page information for article&#xa;</xsl:text>
    <xsl:text>\title{</xsl:text>
    <xsl:apply-templates select="title/node()" />
    <xsl:if test="/mathbook/docinfo/event">
        <xsl:if test="title">
            <xsl:text>\\</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="/mathbook/docinfo/event" />
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\author{</xsl:text><xsl:apply-templates select="/mathbook/docinfo/author" /><xsl:text>}&#xa;</xsl:text>
    <xsl:text>\date{</xsl:text><xsl:apply-templates select="/mathbook/docinfo/date" /><xsl:text>}&#xa;</xsl:text>
</xsl:template>


<!-- "half-title" is leading page with title only          -->
<!-- at about 1:2 split, presumes in a book               -->
<!-- Series information could go on obverse               -->
<!-- and then do "thispagestyle" on both                  -->
<!-- These two pages contribute to frontmatter page count -->
<xsl:template name="half-title" >
    <xsl:text>% half-title&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <xsl:text>\begin{center}\Huge&#xa;</xsl:text>
    <xsl:apply-templates select="/mathbook/book/title/node()" />
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


<!-- Author, one at titlepage -->
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

<!-- Preface, within \frontmatter is handled correctly by LaTeX-->
<xsl:template match="preface">
    <xsl:text>\chapter{Preface}&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Articles may have an abstract in the docinfo -->
<xsl:template match="abstract">
    <xsl:text>\begin{abstract}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{abstract}&#xa;%&#xa;</xsl:text>
</xsl:template>

<!-- Titles, captions are handled specially               -->
<!-- so get killed via apply-templates                    -->
<!-- When needed, get content with XPath, eg title/node() -->
<xsl:template match="title"></xsl:template>
<xsl:template match="caption"></xsl:template>

<!-- Sectioning -->
<!-- Subdivisions, Chapters down to Paragraphs -->
<!-- Relies on element names echoing latex names   -->
<!-- But appendices are just chapters after \appendix macro -->
<xsl:template match="chapter|appendix|section|subsection|subsubsection|paragraph">
    <xsl:variable name="level">
        <xsl:choose>
            <xsl:when test="local-name(.)='appendix'">
                <xsl:text>chapter</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="local-name(.)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>\typeout{************************************************}&#xa;</xsl:text>
    <xsl:text>\typeout{</xsl:text>
    <xsl:apply-templates select="." mode="long-name" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\typeout{************************************************}&#xa;%&#xa;</xsl:text>
    <xsl:text>\</xsl:text>
    <xsl:value-of select="$level" />
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="title/node()" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates />
</xsl:template>



<!-- Theorems, Proofs, Definitions, Examples, Exercises -->

<!-- Theorems have statement/proof structure               -->
<!-- Definitions have notation, which is handled elsewhere -->
<!-- Examples have no additional structure                 -->
<!-- Exercises have solutions                              -->
<!-- TODO: consider optional titles -->

<xsl:template match="theorem|corollary|lemma">
    <xsl:apply-templates select="statement|proof" />
</xsl:template>

<xsl:template match="definition">
    <xsl:apply-templates select="statement" />
</xsl:template>

<!-- Include solutions to exercises by default value of switch-->
<xsl:template match="exercise">
    <xsl:text>\begin{exercise}</xsl:text>
    <xsl:apply-templates select=".." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="statement"/>
    <xsl:apply-templates select="solution"/>
    <xsl:text>\end{exercise}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="exercise/solution">
    <xsl:if test="$solutions.included='yes'">
        <xsl:text>\par\smallskip\noindent{}\textbf{</xsl:text>
        <xsl:apply-templates select="." mode="type-name" />
        <xsl:text>.}\ \ {}</xsl:text>
        <xsl:text>&#xa;</xsl:text>
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>

<!-- Reorg?, consolidate following with local-name() -->

<xsl:template match="theorem/statement">
    <xsl:text>\begin{theorem}</xsl:text>
    <xsl:apply-templates select=".." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{theorem}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="corollary/statement">
    <xsl:text>\begin{corollary}</xsl:text>
    <xsl:apply-templates select=".." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{corollary}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="lemma/statement">
    <xsl:text>\begin{lemma}</xsl:text>
    <xsl:apply-templates select=".." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{lemma}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="definition/statement">
    <xsl:text>\begin{definition}</xsl:text>
    <xsl:apply-templates select=".." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{definition}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="example">
    <xsl:text>\begin{example}</xsl:text>
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{example}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="notation">
    <xsl:text>Sample notation (in a master list eventually): $</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>$\par&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="proof">
    <xsl:text>\begin{proof}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{proof}&#xa;%&#xa;</xsl:text>
</xsl:template>

<!-- Paragraphs                              -->
<!-- \par marks the start of a new paragraph -->
<xsl:template match="p[1]">
    <xsl:apply-templates />
    <xsl:text>&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="p">
    <xsl:text>\par </xsl:text>
    <xsl:apply-templates />
    <xsl:text>&#xa;%&#xa;</xsl:text>
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


<!-- Lists -->
<xsl:template match="ol">
    <xsl:text>\begin{enumerate}&#xa;</xsl:text>
    <xsl:apply-templates select="li" />
    <xsl:text>\end{enumerate}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="ul">
    <xsl:text>\begin{itemize}&#xa;</xsl:text>
    <xsl:apply-templates select="li" />
    <xsl:text>\end{itemize}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="dl">
    <xsl:text>\begin{description}&#xa;</xsl:text>
    <xsl:apply-templates select="li" />
    <xsl:text>\end{description}&#xa;%&#xa;</xsl:text>
</xsl:template>

<!-- Sometimes a nested list ends as part of an item  -->
<!-- We output a % with each carriage return to avoid -->
<!-- getting extraneous blank lines in the source     -->
<xsl:template match="li">
    <xsl:text>\item </xsl:text>
    <xsl:apply-templates />
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="dl/li">
    <xsl:text>\item</xsl:text>
    <xsl:apply-templates />
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- Description lists have titled elements -->
<!-- so no space after \item above          -->
<!-- and title must be first inside li      -->
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
    <xsl:text>\\\hspace*{\stretch{1}}\textemdash\space{}</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Emphasis -->
<xsl:template match="em">
    <xsl:text>\emph{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Defined terms (bold) -->
<xsl:template match="term">
    <xsl:text>\textbf{</xsl:text>
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
            <xsl:value-of select="." />
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



<!-- Dollar sign -->
<xsl:template match="dollar">
    <xsl:text>\$</xsl:text>
</xsl:template>

<!-- Percent sign -->
<xsl:template match="percent">
    <xsl:text>\%</xsl:text>
</xsl:template>

<!-- Ampersand -->
<!-- Not for formatting control, but to see actual character -->
<xsl:template match="ampersand">
    <xsl:text>\&amp;</xsl:text>
</xsl:template>

<!-- Ellipsis (dots), for text, not math -->
<xsl:template match="ellipsis">
    <xsl:text>\dots{}</xsl:text>
</xsl:template>


<!-- for example -->
<xsl:template match="eg">
    <xsl:text>e.g.{}</xsl:text>
</xsl:template>

<!-- Copyright symbol -->
<xsl:template match="copyright">
    <xsl:text>\copyright{}</xsl:text>
</xsl:template>


<!-- in other words -->
<xsl:template match="ie">
    <xsl:text>i.e.{}</xsl:text>
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
    <xsl:text>\LaTeX{}</xsl:text>
</xsl:template>
<xsl:template match="tex">
    <xsl:text>\TeX{}</xsl:text>
</xsl:template>

<!-- Number Sign, Hash, Octothorpe -->
<xsl:template match="hash">
    <xsl:text>\#</xsl:text>
</xsl:template>

<!-- Foreign words/idioms        -->
<!-- Matches HTML5 specification -->
<xsl:template match="foreign">
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Line Breaks -->
<!-- use sparingly, e.g. for poetry, not in math environments-->
<xsl:template match="br">
    <xsl:text>\\</xsl:text>
</xsl:template>

<!-- Non-breaking space, which "joins" two words as a unit -->
<xsl:template match="nbsp">
    <xsl:text>~</xsl:text>
</xsl:template>


<!-- Dashes -->
<!-- http://www.public.asu.edu/~arrows/tidbits/dashes.html -->
<xsl:template match="mdash">
    <xsl:text>\textemdash{}</xsl:text>
</xsl:template>
<xsl:template match="ndash">
    <xsl:text>\textendash{}</xsl:text>
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
    <xsl:text>\begin{mdframed}[style=sageinput]&#xa;</xsl:text>
    <xsl:text>\begin{verbatim}</xsl:text>
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="." />
    </xsl:call-template>
    <xsl:text>\end{verbatim}&#xa;</xsl:text>
    <xsl:text>\end{mdframed}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="output">
    <xsl:text>\begin{mdframed}[style=sageoutput]&#xa;</xsl:text>
    <xsl:text>\begin{verbatim}</xsl:text>
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="." />
    </xsl:call-template>
    <xsl:text>\end{verbatim}&#xa;</xsl:text>
    <xsl:text>\end{mdframed}&#xa;%&#xa;</xsl:text>
</xsl:template>


<!-- Figures and Captions -->
<!-- http://tex.stackexchange.com/questions/2275/keeping-tables-figures-close-to-where-they-are-mentioned -->
<xsl:template match="figure">
    <xsl:text>\begin{figure}[!htbp]&#xa;</xsl:text>
    <xsl:text>\begin{center}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{center}&#xa;</xsl:text>
    <xsl:text>\caption{</xsl:text>
    <xsl:apply-templates select="caption/node()" />
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\end{figure}&#xa;%&#xa;</xsl:text>
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
<xsl:template match="tikz">
    <xsl:text>\resizebox{0.75\textwidth}{!}{&#xa;</xsl:text>
    <xsl:text>\begin{tikzpicture}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{tikzpicture}&#xa;</xsl:text>
    <xsl:text>} % end box resizing&#xa;%&#xa;</xsl:text>
</xsl:template>

<!-- Asymptote graphics language -->
<!-- preliminary (cursory) support -->
<!-- http://asymptote.sourceforge.net/doc/LaTeX-usage.html -->
<xsl:template match="asymptote">
    <xsl:text>\begin{asy}&#xa;</xsl:text>
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="." />
    </xsl:call-template>
    <xsl:text>\end{asy}&#xa;</xsl:text>
</xsl:template>

<!--<xsl:template match="table">
    <xsl:text>\centerline{\textbf{A table belongs here, but conversion is not yet implemented}}&#xa;</xsl:text>
</xsl:template>-->
<!-- Tables -->
<!-- Follow XML Exchange Table Model" which is a subset of the failed "CALS Table Model" -->
<!-- Should be able to replace this by extant XSLT for this conversion -->
<!-- See http://stackoverflow.com/questions/19716449/converting-xhtml-table-to-latex-using-xslt -->
<xsl:template match="table">
    <xsl:text>\begin{table}[thb]\begin{center}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:apply-templates />
    <xsl:text>\end{center}\end{table}&#xa;</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="table/caption">
    <xsl:text>\caption{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}&#xa;</xsl:text>
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
    <xsl:text>\hline\hline{}</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\\\hline\hline{}</xsl:text>
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
    <xsl:text>\cite{</xsl:text>
    <xsl:value-of select="@ref" />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="xref[@ref]">
    <xsl:text>\ref{</xsl:text>
    <xsl:apply-templates select="id(@ref)" mode="xref-identifier" />
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
    <xsl:apply-templates select="." mode="xref-identifier" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Footnotes               -->
<!--   with no customization -->
<xsl:template match="fn">
    <xsl:text>\footnote{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Bibliography -->

<!-- Enclosing structure of bibliography -->
<!-- TODO: Get number of last bibitem node for width parameter -->
<xsl:template match="bibliography">
    <xsl:text>\begin{thebibliography}{99}&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates select="book|article|biblio" />
    <xsl:text>\end{thebibliography}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="biblio[@type='raw']">
    <xsl:text>\bibitem{</xsl:text>
    <xsl:value-of select="@xml:id" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="biblio[@type='raw']/title">
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Trash eventually, but here allows next to have precedence -->
<xsl:template match="bibliography//volume">
    <xsl:text>, </xsl:text>
    <xsl:text> (</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>)</xsl:text>
    <xsl:if test="../number">
        <xsl:text> no. </xsl:text>
        <xsl:value-of select="../number" />
    </xsl:if>
</xsl:template>

<xsl:template match="biblio[@type='raw']/volume">
    <xsl:text>\textbf{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>



<!-- Individual bibliography entry leader-->
<xsl:template name="bibleader">
    <xsl:text>\bibitem{</xsl:text><xsl:value-of select="@xml:id" />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>



<xsl:template match="bibliography//article">
    <xsl:call-template name="bibleader" />
    <xsl:apply-templates select="author" />
    <xsl:apply-templates select="title" />
    <xsl:apply-templates select="journal" />
    <xsl:apply-templates select="volume" />
    <xsl:apply-templates select="pages" />
    <xsl:text>.&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="bibliography//book">
    <xsl:call-template name="bibleader" />
    <xsl:apply-templates select="author" />
    <xsl:apply-templates select="title" />
    <xsl:apply-templates select="publisher" />
    <xsl:text>.&#xa;%&#xa;</xsl:text>
</xsl:template>


<xsl:template match="bibliography//author">
    <span class="author"><xsl:apply-templates /></span>
</xsl:template>

<xsl:template match="bibliography/article/title">
    <xsl:text>, ``</xsl:text>
    <xsl:apply-templates />
    <xsl:text>''</xsl:text>
</xsl:template>

<xsl:template match="bibliography/book/title">
    <xsl:text>, \textsl{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="bibliography//journal">
    <xsl:text>, </xsl:text>
    <xsl:apply-templates />
    <xsl:text> (</xsl:text>
    <xsl:if test="../month">
        <xsl:value-of select="../month" />
        <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:value-of select="../year" />
    <xsl:text>)</xsl:text>
</xsl:template>

<xsl:template match="bibliography//publisher">
    <xsl:text>, </xsl:text>
    <xsl:text> (</xsl:text>
    <xsl:apply-templates />
    <xsl:text> </xsl:text>
    <xsl:value-of select="../year" />
    <xsl:text>)</xsl:text>
</xsl:template>


<xsl:template match="bibliography//pages">
    <xsl:text>, </xsl:text>
    <xsl:apply-templates />
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
</xsl:template>


</xsl:stylesheet>