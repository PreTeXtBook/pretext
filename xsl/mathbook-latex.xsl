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
<!-- LaTeX executable, "engine"                       -->
<!-- pdflatex is default, xelatex for Unicode support -->
<!-- N.B. This has no effect, and may never.  xelatex support is automatic -->
<xsl:param name="latex.engine" select="'pdflatex'" />
<!--  -->
<!-- Fontsize: 10pt, 11pt, or 12pt           -->
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
<!-- Print Option                                     -->
<!-- For a non-electronic copy, mostly links in black -->
<xsl:param name="latex.print" select="'no'"/>
<!--  -->
<!-- Preamble insertions                    -->
<!-- Insert packages, options into preamble -->
<!-- early or late                          -->
<xsl:param name="latex.preamble.early" select="''" />
<xsl:param name="latex.preamble.late" select="''" />
<!--  -->
<!-- LaTeX ToC levels always have sections at level "1"     -->
<!-- MBX has level "0" as the root, and gives "no contents" -->
<!-- So we translate MBX level to LaTeX-speak for books     -->
<xsl:param name="latex-toc-level">
    <xsl:choose>
        <xsl:when test="/mathbook/book">
            <xsl:value-of select="$toc-level - 1" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$toc-level" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:param>
<!-- A LaTeX "section depth" is *always* 1 for a section        -->
<!-- But our numbering begins at the root, we need to decrement -->
<!-- for a <book> due to intervening chapters, etc.             -->
<xsl:param name="latex-numbering-maxlevel">
    <xsl:choose>
        <xsl:when test="/mathbook/book">
            <xsl:value-of select="$numbering-maxlevel - 1" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$numbering-maxlevel" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:param>

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
    <xsl:if test="title or frontmatter/titlepage">
        <xsl:text>\maketitle&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <!-- Likely only an abstract found in frontmatter -->
    <xsl:apply-templates select="frontmatter" />
    <xsl:if test="$latex-toc-level > 0">
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
    <xsl:apply-templates select="*[not(self::frontmatter or self::title or self::subtitle)]"/>
    <!-- TODO: backmatter in an article? -->
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
    <xsl:if test="$latex-toc-level > -1">
        <xsl:text>\setcounter{tocdepth}{</xsl:text>
        <xsl:value-of select="$latex-toc-level" />
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\renewcommand*\contentsname{</xsl:text>
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'toc'" />
        </xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\tableofcontents&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="frontmatter" />
    <xsl:text>\mainmatter&#xa;</xsl:text>
    <xsl:apply-templates select="chapter" />
    <xsl:if test="appendix">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>\appendix&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
        <xsl:apply-templates select="appendix" />
    </xsl:if>
    <!-- TODO: condition on backmatter, once bibliography set, move out postamble -->
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\backmatter&#xa;</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates select="backmatter" />
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
    <xsl:text>%% Inline math delimiters, \(, \), made robust with next package&#xa;</xsl:text>
    <xsl:text>\usepackage{fixltx2e}&#xa;</xsl:text>
    <xsl:text>%% Page Layout Adjustments (latex.geometry)&#xa;</xsl:text>
    <xsl:if test="$latex.geometry != ''">
        <xsl:text>\geometry{</xsl:text>
        <xsl:value-of select="$latex.geometry" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% For unicode character support, use the "xelatex" executable&#xa;</xsl:text>
    <xsl:text>%% If never using xelatex, the next three lines can be removed&#xa;</xsl:text>
    <xsl:text>\usepackage{ifxetex}&#xa;</xsl:text>
    <!-- latex ifthen package, with \boolean{xetex} is option -->
    <xsl:text>\ifxetex\usepackage{xltxtra}\fi&#xa;</xsl:text>
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
    <xsl:if test="//m[contains(text(),'sfrac')] or //md[contains(text(),'sfrac')] or //me[contains(text(),'sfrac')] or //mrow[contains(text(),'sfrac')]">
        <xsl:text>%% xfrac package for 'beveled fractions': http://tex.stackexchange.com/questions/3372/how-do-i-typeset-arbitrary-fractions-like-the-standard-symbol-for-5-%C2%BD&#xa;</xsl:text>
        <xsl:text>\usepackage{xfrac}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Semantic Macros&#xa;</xsl:text>
    <xsl:text>%% To preserve meaning in a LaTeX file&#xa;</xsl:text>
    <xsl:text>%% Only defined here if required in this document&#xa;</xsl:text>
    <xsl:if test="/mathbook//term">
        <xsl:text>%% Used for inline definitions of terms&#xa;</xsl:text>
        <xsl:text>\newcommand{\terminology}[1]{\textbf{#1}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="/mathbook//acro">
        <xsl:text>%% Used to markup acronyms, defaults is no effect&#xa;</xsl:text>
        <xsl:text>\newcommand{\acronym}[1]{#1}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//quantity">
        <xsl:text>%% Used for units and number formatting&#xa;</xsl:text>
        <xsl:text>\usepackage[per-mode=fraction]{siunitx}&#xa;</xsl:text>
        <xsl:text>\ifxetex\sisetup{math-micro=\text{µ},text-micro=µ}\fi</xsl:text>
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
    <xsl:text>%% Theorem-like enviroments in "plain" style, with or without proof&#xa;</xsl:text>
    <xsl:text>\usepackage{amsthm}&#xa;</xsl:text>
    <xsl:text>\theoremstyle{plain}&#xa;</xsl:text>
    <xsl:text>%% Numbering for Theorems, Conjectures, Examples, Figures, etc&#xa;</xsl:text>
    <xsl:text>%% Controlled by  numbering.theorems.level  processing parameter&#xa;</xsl:text>
    <xsl:text>%% Always need a theorem environment to set base numbering scheme&#xa;</xsl:text>
    <xsl:text>%% even if document has no theorems (but has other environments)&#xa;</xsl:text>
    <xsl:text>\newtheorem{theorem}{</xsl:text>
    <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'theorem'" /></xsl:call-template>
    <xsl:text>}</xsl:text>
    <!-- See numbering-theorems variable being set in mathbook-common.xsl -->
    <xsl:text>[</xsl:text>
    <xsl:call-template name="level-number-to-latex-name">
        <xsl:with-param name="level" select="$numbering-theorems" />
    </xsl:call-template>
    <xsl:text>]&#xa;</xsl:text>
    <!-- Localize "Proof" environment -->
    <!-- http://tex.stackexchange.com/questions/62020/how-to-change-the-word-proof-in-the-proof-environment -->
    <xsl:text>\renewcommand*{\proofname}{</xsl:text>
    <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'proof'" /></xsl:call-template>
    <xsl:text>}</xsl:text>
    <xsl:text>%% Only variants actually used in document appear here&#xa;</xsl:text>
    <xsl:text>%% Numbering: all theorem-like numbered consecutively&#xa;</xsl:text>
    <xsl:text>%% i.e. Corollary 4.3 follows Theorem 4.2&#xa;</xsl:text>
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
    <xsl:if test="//conjecture">
        <xsl:text>\newtheorem{conjecture}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'conjecture'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//axiom">
        <xsl:text>\newtheorem{axiom}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'axiom'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//principle">
        <xsl:text>\newtheorem{principle}[theorem]{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'principle'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//definition or //example or //exercise or //remark">
        <xsl:text>%% Definition-like environments, normal text&#xa;</xsl:text>
        <xsl:text>%% Numbering for definition, examples is in sync with theorems, etc&#xa;</xsl:text>
        <xsl:text>%% also for free-form exercises, not in exercise sections&#xa;</xsl:text>
        <xsl:text>\theoremstyle{definition}&#xa;</xsl:text>
        <xsl:if test="//definition">
            <xsl:text>\newtheorem{definition}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'definition'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//example">
            <xsl:text>\newtheorem{example}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'example'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//exercise">
            <xsl:text>\newtheorem{exercise}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'exercise'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//remark">
            <xsl:text>\newtheorem{remark}[theorem]{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'remark'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- Numbering Equations -->
    <!-- See numbering-equations variable being set in mathbook-common.xsl -->
    <xsl:if test="//men|//md">
        <xsl:text>%% Equation Numbering&#xa;</xsl:text>
        <xsl:text>%% Controlled by  numbering.equations.level  processing parameter&#xa;</xsl:text>
        <xsl:text>\numberwithin{equation}{</xsl:text>
        <xsl:call-template name="level-number-to-latex-name">
            <xsl:with-param name="level" select="$numbering-equations" />
        </xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
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
        <!-- http://tex.stackexchange.com/questions/24549/horizontal-rule-with-adjustable-height-behaving-like-clinen-m -->
        <!-- Could preserve/restore \arrayrulewidth on entry/exit to tabular -->
        <!-- But we'll get cleaner source with this built into macros        -->
        <!-- Could condition \setlength debacle on the use of extpfeil       -->
        <!-- arrows (see discussion below)                                   -->
        <xsl:text>%% We preserve a copy of the \setlength package before other&#xa;</xsl:text>
        <xsl:text>%% packages (extpfeil) get a change to load packages that redefine it&#xa;</xsl:text>
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
    <!-- Float package allows for placment [H]ere                    -->
    <!-- Numbering happens along with theorem counter above,         -->
    <!-- but could be done with caption package hook, see both       -->
    <!-- New names are necessary to make "within" numbering possible -->
    <!-- http://tex.stackexchange.com/questions/127914/custom-counter-steps-twice-when-invoked-from-caption-using-caption-package -->
    <!-- http://tex.stackexchange.com/questions/160207/side-effect-of-caption-package-with-custom-counter                         -->
    <xsl:if test="//figure or //table">
        <xsl:text>%% Figures, Tables, Floats&#xa;</xsl:text>
        <xsl:text>%% The [H]ere option of the float package fixes floats in-place,&#xa;</xsl:text>
        <xsl:text>%% in deference to web usage, where floats are totally irrelevant&#xa;</xsl:text>
        <xsl:text>%% We redefine the figure and table environments, if used&#xa;</xsl:text>
        <xsl:text>%%   1) New mbxfigure and/or mbxtable environments are defined with float package&#xa;</xsl:text>
        <xsl:text>%%   2) Standard LaTeX environments redefined to use new environments&#xa;</xsl:text>
        <xsl:text>%%   3) Standard LaTeX environments redefined to step theorem counter&#xa;</xsl:text>
        <xsl:text>%%   4) Counter for new enviroments is set to the theorem counter before caption&#xa;</xsl:text>
        <xsl:text>%% You can remove all this figure/table setup, to restore standard LaTeX behavior&#xa;</xsl:text>
        <xsl:text>%% HOWEVER, numbering of figures/tables AND theorems/examples/remarks, etc&#xa;</xsl:text>
        <xsl:text>%% WILL ALL de-synchronize with the numbering in the HTML version&#xa;</xsl:text>
        <xsl:text>%% You can remove the [H] argument of the \newfloat command, to allow flotation and &#xa;</xsl:text>
        <xsl:text>%% preserve numbering, BUT the numbering may then appear "out-of-order"&#xa;</xsl:text>
        <xsl:text>\usepackage{float}&#xa;</xsl:text>
        <xsl:text>\usepackage[bf]{caption} % http://tex.stackexchange.com/questions/95631/defining-a-new-type-of-floating-environment &#xa;</xsl:text>
        <xsl:text>\usepackage{newfloat}&#xa;</xsl:text>
        <xsl:if test="//sidebyside/caption">
            <xsl:text>\usepackage{subcaption}&#xa;</xsl:text>
            <xsl:text>\captionsetup[subfigure]{labelformat=simple}&#xa;</xsl:text>
            <xsl:text>\captionsetup[subtable]{labelformat=simple}&#xa;</xsl:text>
            <xsl:text>\renewcommand\thesubfigure{(\alph{subfigure})}&#xa;</xsl:text>
            <xsl:text>\makeatletter&#xa;</xsl:text>
            <xsl:text>% we plan to use subtables within figure environments, so they need to reset accordingly&#xa;</xsl:text>
            <xsl:text>\@addtoreset{subtable}{figure}&#xa;</xsl:text>
            <xsl:text>\makeatother&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//sidebyside">
          <xsl:text>% Side-by-side elements need careful treatement for aligning captions, see: &#xa;</xsl:text>
          <xsl:text>% http://tex.stackexchange.com/questions/230335/vertically-aligning-minipages-subfigures-and-subtables-not-with-baseline &#xa;</xsl:text>
          <xsl:text>\usepackage{stackengine,ifthen}&#xa;</xsl:text>
          <xsl:text>\newcounter{figstack}&#xa;</xsl:text>
          <xsl:text>\newcounter{figindex}&#xa;</xsl:text>
          <xsl:text>\newlength\fight&#xa;</xsl:text>
          <xsl:text>\newcommand\pushValignCaptionBottom[5][b]{%&#xa;</xsl:text>
          <xsl:text>\stepcounter{figstack}%&#xa;</xsl:text>
          <xsl:text>\expandafter\def\csname %&#xa;</xsl:text>
          <xsl:text>figalign\romannumeral\value{figstack}\endcsname{#1}%&#xa;</xsl:text>
          <xsl:text>\expandafter\def\csname %&#xa;</xsl:text>
          <xsl:text>figtype\romannumeral\value{figstack}\endcsname{#2}%&#xa;</xsl:text>
          <xsl:text>\expandafter\def\csname %&#xa;</xsl:text>
          <xsl:text>figwd\romannumeral\value{figstack}\endcsname{#3}%&#xa;</xsl:text>
          <xsl:text>\expandafter\def\csname %&#xa;</xsl:text>
          <xsl:text>figcontent\romannumeral\value{figstack}\endcsname{#4}%&#xa;</xsl:text>
          <xsl:text>\expandafter\def\csname %&#xa;</xsl:text>
          <xsl:text>figcap\romannumeral\value{figstack}\endcsname{#5}%&#xa;</xsl:text>
          <xsl:text>\setbox0=\hbox{%&#xa;</xsl:text>
          <xsl:text>\begin{#2}{#3}#4\end{#2}}%&#xa;</xsl:text>
          <xsl:text>\ifdim\dimexpr\ht0+\dp0\relax&gt;\fight\global\setlength{\fight}{%&#xa;</xsl:text>
          <xsl:text>\dimexpr\ht0+\dp0\relax}\fi%&#xa;</xsl:text>
          <xsl:text>}&#xa;</xsl:text>
          <xsl:text>\newcommand\popValignCaptionBottom{%&#xa;</xsl:text>
          <xsl:text>\setcounter{figindex}{0}%&#xa;</xsl:text>
          <xsl:text>\hfill%&#xa;</xsl:text>
          <xsl:text>\whiledo{\value{figindex}&lt;\value{figstack}}{%&#xa;</xsl:text>
          <xsl:text>\stepcounter{figindex}%&#xa;</xsl:text>
          <xsl:text>\def\tmp{\csname figwd\romannumeral\value{figindex}\endcsname}%&#xa;</xsl:text>
          <xsl:text>\begin{\csname figtype\romannumeral\value{figindex}\endcsname}[t]{\tmp}%&#xa;</xsl:text>
          <xsl:text>\centering%&#xa;</xsl:text>
          <xsl:text>\stackinset{c}{}%&#xa;</xsl:text>
          <xsl:text>{\csname figalign\romannumeral\value{figindex}\endcsname}{}%&#xa;</xsl:text>
          <xsl:text>{\csname figcontent\romannumeral\value{figindex}\endcsname}%&#xa;</xsl:text>
          <xsl:text>{\rule{0pt}{\fight}}\par%&#xa;</xsl:text>
          <xsl:text>\csname figcap\romannumeral\value{figindex}\endcsname%&#xa;</xsl:text>
          <xsl:text>\end{\csname figtype\romannumeral\value{figindex}\endcsname}%&#xa;</xsl:text>
          <xsl:text>\hfill%&#xa;</xsl:text>
          <xsl:text>}%&#xa;</xsl:text>
          <xsl:text>\setcounter{figstack}{0}%&#xa;</xsl:text>
          <xsl:text>\setlength{\fight}{0pt}%&#xa;</xsl:text>
          <xsl:text>\hfill%&#xa;</xsl:text>
          <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//figure">
            <xsl:text>% Figure environment setup so that it no longer floats&#xa;</xsl:text>
            <xsl:text>\SetupFloatingEnvironment{figure}{fileext=lof,placement={H},within=</xsl:text>
            <!-- See numbering-theorems variable being set in mathbook-common.xsl -->
            <xsl:call-template name="level-number-to-latex-name">
                <xsl:with-param name="level" select="$numbering-theorems" />
            </xsl:call-template>
            <xsl:text>,name=</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'figure'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>% figures have the same number as theorems: http://tex.stackexchange.com/questions/16195/how-to-make-equations-figures-and-theorems-use-the-same-numbering-scheme &#xa;</xsl:text>
            <xsl:text>\makeatletter&#xa;</xsl:text>
            <xsl:text>\let\c@figure\c@theorem&#xa;</xsl:text>
            <xsl:text>\makeatother&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//table">
            <xsl:text>% Table environment setup so that it no longer floats&#xa;</xsl:text>
            <xsl:text>\SetupFloatingEnvironment{table}{fileext=lot,placement={H},within=</xsl:text>
            <!-- See numbering-theorems variable being set in mathbook-common.xsl -->
            <xsl:call-template name="level-number-to-latex-name">
                <xsl:with-param name="level" select="$numbering-theorems" />
            </xsl:call-template>
            <xsl:text>,name=</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'table'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>% tables have the same number as theorems: http://tex.stackexchange.com/questions/16195/how-to-make-equations-figures-and-theorems-use-the-same-numbering-scheme &#xa;</xsl:text>
            <xsl:text>\makeatletter&#xa;</xsl:text>
            <xsl:text>\let\c@table\c@theorem&#xa;</xsl:text>
            <xsl:text>\makeatother&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:text>%% Raster graphics inclusion, wrapped figures in paragraphs&#xa;</xsl:text>
    <xsl:text>\usepackage{graphicx}&#xa;</xsl:text>
    <xsl:text>%% Colors for Sage boxes and author tools (red hilites)&#xa;</xsl:text>
    <xsl:text>\usepackage[usenames,dvipsnames,svgnames,table]{xcolor}&#xa;</xsl:text>
    <!-- Inconsolata font, sponsored by TUG: http://levien.com/type/myfonts/inconsolata.html            -->
    <!-- As seen on: http://tex.stackexchange.com/questions/50810/good-monospace-font-for-code-in-latex -->
    <!-- "Fonts for Displaying Program Code in LaTeX":  http://nepsweb.co.uk/docs%/progfonts.pdf        -->
    <!-- Fonts and xelatex:  http://tex.stackexchange.com/questions/102525/use-type-1-fonts-with-xelatex -->
    <!--   http://tex.stackexchange.com/questions/179448/beramono-in-xetex -->
    <!-- http://tex.stackexchange.com/questions/25249/how-do-i-use-a-particular-font-for-a-small-section-of-text-in-my-document -->
    <!-- Coloring listings: http://tex.stackexchange.com/questions/18376/beautiful-listing-for-csharp -->
    <xsl:if test="//c or //sage or //program">
        <xsl:text>%% Program listing support, for inline code, Sage code or otherwise&#xa;</xsl:text>
        <xsl:text>\usepackage{listings}&#xa;</xsl:text>
        <xsl:text>%% We define \listingsfont to provide Bitstream Vera Mono font&#xa;</xsl:text>
        <xsl:text>%% for program listings, under both pdflatex and xelatex&#xa;</xsl:text>
        <xsl:text>%% If you remove this, define \listingsfont to be \ttfamily perhaps&#xa;</xsl:text>
        <xsl:text>\ifxetex&#xa;</xsl:text>
        <xsl:text>\usepackage{fontspec}\newfontface\listingsfont[Path]{fvmr8a.pfb}&#xa;</xsl:text>
        <xsl:text>\else&#xa;</xsl:text>
        <xsl:text>\edef\oldtt{\ttdefault}\usepackage[scaled]{beramono}\usepackage[T1]{fontenc}&#xa;</xsl:text>
        <xsl:text>\renewcommand*\ttdefault{\oldtt}\newcommand{\listingsfont}{\fontfamily{fvm}\selectfont}&#xa;</xsl:text>
        <xsl:text>\fi&#xa;</xsl:text>
        <xsl:text>%% To fix hyphens/dashes rendered in PDF as fancy minus signs by listing&#xa;</xsl:text>
        <xsl:text>%% http://tex.stackexchange.com/questions/33185/listings-package-changes-hyphens-to-minus-signs&#xa;</xsl:text>
        <xsl:text>\makeatletter&#xa;</xsl:text>
        <xsl:text>\lst@CCPutMacro\lst@ProcessOther {"2D}{\lst@ttfamily{-{}}{-{}}}&#xa;</xsl:text>
        <xsl:text>\@empty\z@\@empty&#xa;</xsl:text>
        <xsl:text>\makeatother&#xa;</xsl:text>
        <xsl:text>%% End of program listing font definition&#xa;</xsl:text>
        <xsl:if test="//c">
            <xsl:text>%% Inline code, typically from "c" element&#xa;</xsl:text>
            <xsl:text>%% Global, document-wide options apply to \lstinline&#xa;</xsl:text>
            <xsl:text>%% Search/replace \lstinline by \verb to remove this dependency&#xa;</xsl:text>
            <xsl:text>%% (redefining \lstinline with \verb is unlikely to work)&#xa;</xsl:text>
            <xsl:text>\lstset{basicstyle=\footnotesize\listingsfont,breaklines=true}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//program">
            <xsl:text>%% Generic input, listings package: boxed, white, line breaking, language per instance&#xa;</xsl:text>
            <xsl:if test="$latex.print='no'" >
                <xsl:text>%% Colors match a subset of Google prettify "Default" style&#xa;</xsl:text>
                <xsl:text>%% Set latex.print='yes" to get all black&#xa;</xsl:text>
                <xsl:text>%% http://code.google.com/p/google-code-prettify/source/browse/trunk/src/prettify.css&#xa;</xsl:text>
                <xsl:text>\definecolor{identifiers}{rgb}{0.375,0,0.375}&#xa;</xsl:text>
                <xsl:text>\definecolor{comments}{rgb}{0.5,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{strings}{rgb}{0,0.5,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{keywords}{rgb}{0,0,0.5}&#xa;</xsl:text>
            </xsl:if>
            <xsl:if test="$latex.print='yes'" >
                <xsl:text>%% All-black colors&#xa;</xsl:text>
                <xsl:text>\definecolor{identifiers}{rgb}{0,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{comments}{rgb}{0,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{strings}{rgb}{0,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{keywords}{rgb}{0,0,0}&#xa;</xsl:text>
            </xsl:if>
            <xsl:text>\lstdefinestyle{genericinput}{breaklines=true,breakatwhitespace=true,columns=fixed,frame=single,xleftmargin=4ex,xrightmargin=4ex,&#xa;</xsl:text>
            <xsl:text>basicstyle=\footnotesize\listingsfont,identifierstyle=\color{identifiers},commentstyle=\color{comments},stringstyle=\color{strings},keywordstyle=\color{keywords}}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//sage">
            <xsl:text>%% Sage's blue is 50%, we go way lighter (blue!05 would work)&#xa;</xsl:text>
            <xsl:text>\definecolor{sageblue}{rgb}{0.95,0.95,1}&#xa;</xsl:text>
            <xsl:text>%% Sage input, listings package: Python syntax, boxed, colored, line breaking&#xa;</xsl:text>
            <xsl:text>\lstdefinestyle{sageinput}{language=Python,breaklines=true,breakatwhitespace=true,basicstyle=\footnotesize\listingsfont,columns=fixed,frame=single,backgroundcolor=\color{sageblue},xleftmargin=4ex,xrightmargin=4ex}&#xa;</xsl:text>
            <xsl:text>%% Sage output, similar, but not boxed, not colored&#xa;</xsl:text>
            <xsl:text>\lstdefinestyle{sageoutput}{language=Python,breaklines=true,breakatwhitespace=true,basicstyle=\footnotesize\listingsfont,columns=fixed,xleftmargin=8ex,xrightmargin=4ex}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="//tikz">
        <xsl:message>MBX:WARNING: the "tikz" element is deprecated (2015/16/10), use "latex-image-code" tag inside an "image" tag, and include the tikz package and relevant libraries in docinfo/latex-image-preamble</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
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
        <xsl:text>%% But also for specifying labels (ie custom order) on nested lists&#xa;</xsl:text>
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
                <xsl:text>\setlist[exerciselist]{leftmargin=0pt,itemsep=-1.0ex,topsep=1.0ex,partopsep=0pt,parsep=0pt}&#xa;</xsl:text>
            </xsl:if>
            <xsl:if test="//exercisegroup">
                <xsl:text>%% Indented groups of exercises within an exercise section, maximum depth 4&#xa;</xsl:text>
                <xsl:text>\newlist{exercisegroup}{description}{4}&#xa;</xsl:text>
                <xsl:text>\setlist[exercisegroup]{leftmargin=2em,labelindent=2em,itemsep=-1.0ex,topsep=1.0ex,partopsep=0pt,parsep=0pt}&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
    </xsl:if>
    <xsl:if test="//index">
        <xsl:text>%% Support for index creation&#xa;</xsl:text>
        <xsl:if test="$author-tools='no'">
            <xsl:text>%% Requires doing $ makeindex &lt;filename&gt;&#xa;</xsl:text>
            <xsl:text>%% prior to second LaTeX pass&#xa;</xsl:text>
            <xsl:text>%% We provide language support for the "see" phrase&#xa;</xsl:text>
            <xsl:text>%% and for the title of the "Index" section&#xa;</xsl:text>
            <xsl:text>\usepackage{makeidx}&#xa;</xsl:text>
            <xsl:text>\renewcommand{\seename}{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'see'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>\renewcommand{\indexname}{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'indexsection'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>\makeindex&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$author-tools='yes'">
            <xsl:text>%% author-tools = 'yes' activates marginal notes about index&#xa;</xsl:text>
            <xsl:text>%% and supresses the actual creation of the index itself&#xa;</xsl:text>
            <xsl:text>\usepackage{showidx}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="//logo">
        <xsl:text>%% Package for precise image placement (for logos on pages)&#xa;</xsl:text>
        <xsl:text>\usepackage{eso-pic}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//notation">
        <xsl:text>%% Package for tables spanning several pages&#xa;</xsl:text>
        <xsl:text>\usepackage{longtable}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% hyperref driver does not need to be specified&#xa;</xsl:text>
    <xsl:text>\usepackage{hyperref}&#xa;</xsl:text>
    <xsl:if test="$latex.print='no'">
        <xsl:text>%% Hyperlinking active in PDFs, all links solid and blue&#xa;</xsl:text>
        <xsl:text>\hypersetup{colorlinks=true,linkcolor=blue,citecolor=blue,filecolor=blue,urlcolor=blue}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$latex.print='yes'">
        <xsl:text>%% latex.print parameter set to 'yes', all hyperlinks black&#xa;</xsl:text>
        <xsl:text>\hypersetup{hidelinks}&#xa;</xsl:text>
    </xsl:if>
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
    <xsl:if test="$author-tools='yes'" >
        <xsl:text>%% Collected author tools options (author-tools='yes')&#xa;</xsl:text>
        <xsl:text>%% others need to be elsewhere, these are simply package additions&#xa;</xsl:text>
        <xsl:text>\usepackage{showkeys}&#xa;</xsl:text>
        <xsl:text>\usepackage[letter,cam,center,pdflatex]{crop}&#xa;</xsl:text>
    </xsl:if>
    <!-- upquote package should come as late as possible -->
    <!-- we fix minus signs in listings package above    -->
    <xsl:if test="//c or //pre or //program or //sage"> <!-- verbatim elements (others?) -->
        <xsl:text>%% Use upright quotes rather than LaTeX's curly quotes&#xa;</xsl:text>
        <xsl:text>%% If custom font substitutions follow, this might be ineffective&#xa;</xsl:text>
        <xsl:text>%% If fonts lack upright quotes, the textcomp package is employed&#xa;</xsl:text>
        <xsl:text>\usepackage{upquote}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Graphics Preamble Entries&#xa;</xsl:text>
    <xsl:if test="/mathbook/docinfo/latex-image-preamble">
        <xsl:call-template name="sanitize-sage">
            <xsl:with-param name="raw-sage-code" select="/mathbook/docinfo/latex-image-preamble" />
        </xsl:call-template>
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
    <xsl:text>%% Convenience macros&#xa;</xsl:text>
    <xsl:if test="/mathbook/docinfo/macros">
        <xsl:call-template name="sanitize-sage">
            <xsl:with-param name="raw-sage-code" select="/mathbook/docinfo/macros" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- LaTeX postamble is common for books, articles and letters      -->
<!-- No index if in draft mode                                      -->
<!-- Maybe make this elective as a backmatter item (HTML effect?)   -->
<xsl:template name="latex-postamble">
    <xsl:if test="//index and $author-tools='no'">
        <xsl:text>%% Index goes here at very end&#xa;</xsl:text>
        <xsl:text>\clearpage&#xa;</xsl:text>
        <xsl:text>%% Help hyperref point to the right place&#xa;</xsl:text>
        <xsl:text>\phantomsection&#xa;</xsl:text>
        <xsl:if test="/mathbook/book">
            <xsl:text>\addcontentsline{toc}{chapter}{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'indexsection'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="/mathbook/article">
            <xsl:text>\addcontentsline{toc}{section}{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'indexsection'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:text>\printindex&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template name="title-page-info-book">
    <xsl:text>%% Title page information for book&#xa;</xsl:text>
    <xsl:text>\title{</xsl:text>
    <xsl:apply-templates select="title" />
    <xsl:if test="subtitle">
        <xsl:text>\\&#xa;</xsl:text>
        <!-- Trying to match author fontsize -->
        <xsl:text>{\large </xsl:text>
        <xsl:apply-templates select="subtitle" />
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
    <xsl:apply-templates select="title" />
    <xsl:if test="subtitle">
        <xsl:text>\\&#xa;</xsl:text>
        <!-- Trying to match author fontsize -->
        <xsl:text>{\large </xsl:text>
        <xsl:apply-templates select="subtitle" />
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:if test="/mathbook/docinfo/event">
        <xsl:if test="title">
            <xsl:text>\\</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="/mathbook/docinfo/event" />
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\author{</xsl:text><xsl:apply-templates select="frontmatter/titlepage/author" /><xsl:apply-templates select="frontmatter/titlepage/editor" /><xsl:text>}&#xa;</xsl:text>
    <xsl:text>\date{</xsl:text><xsl:apply-templates select="frontmatter/titlepage/date" /><xsl:text>}&#xa;</xsl:text>
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
    <xsl:text>\begin{center}&#xa;</xsl:text>
    <xsl:text>{\Huge </xsl:text>
    <xsl:apply-templates select="title" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:if test="subtitle">
        <xsl:text>\\[2\baselineskip]{\Large </xsl:text>
        <xsl:apply-templates select="subtitle" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
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
    <xsl:if test="frontmatter/biography" >
        <!-- We kill the title, presuming placement is indicative enough -->
        <xsl:text>{\setlength{\parindent}{0pt}\setlength{\parskip}{4pt}</xsl:text>
        <xsl:apply-templates select="frontmatter/biography/*[not(self::title)]" />}
        <xsl:text>\par\vspace*{\stretch{2}}</xsl:text>
    </xsl:if>
    <xsl:text>\vspace*{\stretch{2}}&#xa;</xsl:text>
    <xsl:if test="frontmatter/colophon/edition" >
        <xsl:text>\noindent{\bf Edition}: </xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/edition" />}
        <xsl:text>\par&#xa;</xsl:text>
    </xsl:if>
    <!-- TODO: split out copyright section as template -->
    <xsl:if test="frontmatter/colophon/copyright" >
        <xsl:text>\noindent\copyright\ </xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/copyright/year" />
        <xsl:text>\quad{}</xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/copyright/holder" />
        <xsl:if test="frontmatter/colophon/copyright/shortlicense">
            <xsl:text>\\[0.5\baselineskip]&#xa;</xsl:text>
            <xsl:apply-templates select="frontmatter/colophon/copyright/shortlicense" />
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
        <xsl:with-param name="string-id" select="'editor'" />
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

<!-- ############ -->
<!-- Front Matter -->
<!-- ############ -->

<!-- The "titlepage" and "colophon" portions of  -->
<!-- frontmatter generally gets mined to migrate -->
<!-- various places, so we kill it as part of    -->
<!-- processing the front matter element.        -->
<xsl:template match="titlepage|colophon" />

<!-- We process the frontmatter piece-by-piece -->
<!-- A DTD should enforce the proper order     -->
<xsl:template match="frontmatter">
    <xsl:apply-templates />
</xsl:template>

<!-- Preface, etc within \frontmatter is usually handled correctly by LaTeX -->
<!-- Allow alternative titles, like "Preface to 2nd Edition"                -->
<!-- But we use starred version anyway, so chapter headings react properly  -->
<!-- TODO: add dedication, other frontmatter, move in title handling        -->
<!-- TODO: add to headers, currently just CONTENTS, check backmatter        -->
<xsl:template match="preface|acknowledgement">
    <xsl:variable name="preface-title">
        <xsl:choose>
            <xsl:when test="title">
                <xsl:apply-templates select="title" /> <!-- footnotes dangerous here -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="type-name" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>\chapter*{</xsl:text>
    <xsl:value-of select="$preface-title" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\addcontentsline{toc}{chapter}{</xsl:text>
    <xsl:value-of select="$preface-title" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Articles may have an abstract in the frontmatter -->
<xsl:template match="abstract">
    <xsl:text>\begin{abstract}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{abstract}&#xa;</xsl:text>
</xsl:template>

<!-- ############ -->
<!-- Back Matter -->
<!-- ############ -->

<!-- We process the backmatter piece-by-piece -->
<!-- No real sectioning happens, so kill title-->
<xsl:template match="backmatter">
    <xsl:apply-templates select="*[not(self::title)]"/>
</xsl:template>

<!-- At location, we just drop a page marker -->
<xsl:template match="notation">
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>


<!-- Notation list -->
<!-- TODO: Localize/Internationalize header row -->
<xsl:template match="notation-list">
    <xsl:text>\begin{longtable}[l]{llr}&#xa;</xsl:text>
    <xsl:text>\textbf{Symbol}&amp;\textbf{Description}&amp;\textbf{Page}\\[1em]&#xa;</xsl:text>
    <xsl:text>\endfirsthead&#xa;</xsl:text>
    <xsl:text>\textbf{Symbol}&amp;\textbf{Description}&amp;\textbf{Page}\\[1em]&#xa;</xsl:text>
    <xsl:text>\endhead&#xa;</xsl:text>
    <xsl:text>\multicolumn{3}{r}{(Continued on next page)}\\&#xa;</xsl:text>
    <xsl:text>\endfoot&#xa;</xsl:text>
    <xsl:text>\endlastfoot&#xa;</xsl:text>
    <xsl:apply-templates select="//notation" mode="backmatter" />
    <xsl:text>\end{longtable}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="notation" mode="backmatter">
    <xsl:text>$</xsl:text>
    <xsl:value-of select="usage" />
    <xsl:text>$</xsl:text>
    <xsl:text>&amp;</xsl:text>
    <xsl:apply-templates select="description" />
    <xsl:text>&amp;</xsl:text>
    <xsl:text>\pageref{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>\\&#xa;</xsl:text>
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
<xsl:template match="chapter|appendix|section|subsection|subsubsection|paragraphs|paragraph|exercises|references">
    <xsl:variable name="level">
        <xsl:choose>
            <!-- TODO: appendix handling is only right for books, expand to articles -->
            <!-- http://www.tex.ac.uk/cgi-bin/texfaq2html?label=appendix -->
            <xsl:when test="local-name(.)='appendix'">
                <xsl:text>chapter</xsl:text>
            </xsl:when>
            <!-- We implement the pseudo-structural paragraphs with LaTeX's paragraph       -->
            <!-- Presuming we never go below susubsection in a hierarchy and bump into this -->
            <xsl:when test="local-name(.)='paragraphs'">
                <xsl:text>paragraph</xsl:text>
            </xsl:when>
            <!-- Collections of exercises and reference can happen at any level, so need correct LaTeX name -->
            <xsl:when test="local-name(.)='exercises' or local-name(.)='references'">
                <xsl:apply-templates select="." mode="subdivision-name" />
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
    <!-- Warn about paragraph deprecation -->
    <xsl:if test="local-name(.)='paragraph'">
        <xsl:message>MBX:WARNING: the "paragraph" element is deprecated (2015/03/13), use "paragraphs" instead</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <!-- Construct the header of the subdivision -->
    <xsl:text>\</xsl:text>
    <xsl:value-of select="$level" />
    <!-- Handle section titles carefully.  Sanitized versions    -->
    <!-- as optional argument to table of contents, headers.     -->
    <!-- Starred sections for backmatter principal subdivisions. -->
    <!-- http://www.tex.ac.uk/cgi-bin/texfaq2html?label=ftnsect  -->
    <!-- TODO: get non-footnote title from "simple" title routines -->
    <!-- TODO: let author specify short versions (ToC, header) -->
    <xsl:choose>
        <xsl:when test="ancestor::backmatter and
            ((/mathbook/book and self::chapter) or (/mathbook/article and self::section))" >
            <xsl:text>*</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:apply-templates select="title" />
            <xsl:text>}</xsl:text>
            <xsl:apply-templates select="." mode="label" />
            <xsl:text>&#xa;</xsl:text>
            <xsl:text>\addcontentsline{toc}{</xsl:text>
            <xsl:value-of select="local-name(.)" />
            <xsl:text>}{</xsl:text>
            <xsl:apply-templates select="title/node()[not(self::fn)]" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[</xsl:text>
            <xsl:apply-templates select="title/node()[not(self::fn)]" />
            <xsl:text>]</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:apply-templates select="title" />
            <xsl:text>}</xsl:text>
            <xsl:apply-templates select="." mode="label" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#xa;</xsl:text>
    <!-- List the author of this division, if present -->
    <xsl:if test="author">
        <xsl:text>\noindent{\Large\textbf{</xsl:text>
        <xsl:apply-templates select="author" mode="name-list"/>
        <xsl:text>}}\par\bigskip&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="introduction" />
    <!-- Process the remaining contents -->
    <xsl:apply-templates select="*[not(self::title or self::author or self::introduction or self::conclusion)]"/>
    <xsl:apply-templates select="conclusion" />
</xsl:template>

<!-- Introductions and Conclusions -->
<!-- Simple containers, allowed before and after       -->
<!-- explicit subdivisions, to introduce or summarize  -->
<!-- No title allowed, typically just a few paragraphs -->
<xsl:template match="introduction|conclusion">
    <xsl:apply-templates />
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

<xsl:template match="theorem|corollary|lemma|algorithm|proposition|claim|fact">
    <xsl:apply-templates select="statement|proof" />
</xsl:template>

<!-- It is natural to place notation within a definition    -->
<!-- We might take advantage of that, but are not currently -->
<xsl:template match="definition">
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="notation" />
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

<!-- Exercise Group -->
<!-- We interrupt a description list with short commentary, -->
<!-- typically instructions for a list of similar exercises -->
<!-- Commentary goes in an introduction and/or conclusion   -->
<xsl:template match="exercisegroup">
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
            <xsl:text>\begin{exercisegroup}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="not(preceding-sibling::exercise) and parent::exercises">
            <xsl:text>\begin{exerciselist}&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>\item[</xsl:text>
    <xsl:apply-templates select="." mode="origin-id" />
    <xsl:text>.]</xsl:text>
    <xsl:apply-templates select="." mode="label"/>
    <xsl:if test="title">
        <xsl:text>(</xsl:text>
        <xsl:apply-templates select="title" />
        <xsl:text>)\space\space{}</xsl:text>
    </xsl:if>
    <!-- Order enforced: statement, hint, answer, solution -->
    <xsl:if test="$exercise.text.statement='yes'">
        <xsl:apply-templates select="statement" />
        <xsl:text>\par\smallskip&#xa;</xsl:text>
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

<!-- An exercise statement is just a container -->
<xsl:template match="exercise/statement">
    <xsl:apply-templates />
</xsl:template>

<!-- Assume various solution-types with non-blank line and newline -->
<xsl:template match="exercise/hint|exercise/answer|exercise/solution">
    <xsl:text>\par\smallskip&#xa;\noindent\textbf{</xsl:text>
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text>.}\quad&#xa;</xsl:text>
    <xsl:apply-templates />
</xsl:template>

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
        <xsl:apply-templates select="." mode="subdivision-name" />
        <xsl:text>*{</xsl:text>
        <xsl:apply-templates select="." mode="number" />
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="title" />
        <xsl:text>}&#xa;</xsl:text>
        <xsl:apply-templates select="*[not(self::title)]" mode="backmatter" />
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
        <xsl:apply-templates select="." mode="origin-id" />
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

<!-- Theorem Environments/Statements -->
<!-- Statements are the place to generate environment -->
<!-- Most information comes from parent               -->
<!-- Proofs are written outside of environment        -->
<xsl:template match="theorem/statement|corollary/statement|lemma/statement|algorithm/statement|proposition/statement|claim/statement|fact/statement|conjecture/statement|axiom/statement|principle/statement">
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
<!-- LaTeX only, no companion for other conversions -->
<xsl:template match="index">
    <xsl:text>\index{</xsl:text>
    <xsl:apply-templates select="main" />
    <xsl:apply-templates select="sub" />
    <xsl:apply-templates select="see" />
    <xsl:apply-templates select="@finish" />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="index/sub">
    <xsl:text>!</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="index/see">
    <xsl:text>|see{</xsl:text>
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

<xsl:template match="index[@start]">
    <xsl:variable name="start" select="id(@start)" />
    <xsl:text>\index{</xsl:text>
    <xsl:apply-templates select="$start/main" />
    <xsl:apply-templates select="$start/sub" />
    <xsl:apply-templates select="$start/see" />
    <xsl:apply-templates select="@start" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- #### -->
<!-- Math -->
<!-- #### -->

<!-- We do not "tag" numbered equations in LaTeX output, -->
<!-- and instead let the preamble configuration control  -->
<!-- the way numbers are generated and assigned          -->
<xsl:template match="men|mrow" mode="tag" />

<!-- Intertext -->
<!-- A pure LaTeX construct, so we just do the right thing        -->
<!-- An <mrow> will provide trailing newline, so do the same here -->
<xsl:template match="md/intertext|mdn/intertext">
    <xsl:text>\intertext{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Lists -->
<!-- Good match between basic HTML types and basic LaTeX types -->

<!-- Utility templates to translate MBX @label specification -->
<!-- for use with LaTeX enumitem package's label keyword     -->
<xsl:template match="*" mode="latex-ordered-list-label">
    <xsl:variable name="code">
        <xsl:choose>
            <xsl:when test="contains(@label,'1')">1</xsl:when>
            <xsl:when test="contains(@label,'a')">a</xsl:when>
            <xsl:when test="contains(@label,'A')">A</xsl:when>
            <xsl:when test="contains(@label,'i')">i</xsl:when>
            <xsl:when test="contains(@label,'I')">I</xsl:when>
            <xsl:when test="@label=''"></xsl:when>
            <xsl:otherwise>
                <xsl:message>MBX:ERROR: ordered list label not found or not recognized</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- deconstruct the left, middle, right portions of code   -->
    <!-- MBX codes translate to codes from the enumitem package -->
    <xsl:value-of select="substring-before(@label, $code)" />
    <xsl:choose>
        <xsl:when test="$code='1'">\arabic*</xsl:when>
        <xsl:when test="$code='a'">\alph*</xsl:when>
        <xsl:when test="$code='A'">\Alph*</xsl:when>
        <xsl:when test="$code='i'">\roman*</xsl:when>
        <xsl:when test="$code='I'">\Roman*</xsl:when>
        <xsl:when test="$code=''"></xsl:when>
    </xsl:choose>
    <xsl:value-of select="substring-after(@label, $code)" />
</xsl:template>

<xsl:template match="*" mode="latex-unordered-list-label">
   <xsl:choose>
        <xsl:when test="@label='disc'">\textbullet</xsl:when>
        <xsl:when test="@label='circle'">$\circ$</xsl:when>
        <xsl:when test="@label='square'">$\blacksquare$</xsl:when>
        <xsl:when test="@label=''">none</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: unordered list label not found or not recognized</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Utility template to translate ordered list    -->
<!-- level to HTML list-style-type                 -->
<!-- This mimics LaTeX's choice and order:         -->
<!-- arabic, lower alpha, lower roman, upper alpha -->
<!-- NB: we need this for sublists in exercises, reference annotations -->
<!-- othrwise, we try to avoid it, in hopes of cleaner LaTeX source    -->
<xsl:template match="*" mode="latex-ordered-list-label-default">
    <xsl:variable name="level">
        <xsl:apply-templates select="." mode="ordered-list-level" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$level='0'">\arabic*.</xsl:when>
        <xsl:when test="$level='1'">(\alph*)</xsl:when>
        <xsl:when test="$level='2'">\roman*.</xsl:when>
        <xsl:when test="$level='3'">\Alph*.</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: ordered list is more than 4 levels deep (<xsl:value-of select="$level" /> levels)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Utility template to translate unordered    -->
<!-- list level to HTML list-style-type         -->
<!-- This is similar to Firefox default choices -->
<!-- but different in the fourth slot           -->
<!-- disc, circle, square, disc                 -->
<!-- TODO: cannot find text mode filled black square symbol -->
<!-- TODO: textcomp package has \textopenbullet (unexamined) -->
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
<xsl:template match="ol">
    <xsl:if test="@cols">
        <xsl:text>\begin{multicols}{</xsl:text>
        <xsl:value-of select="@cols" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{enumerate}</xsl:text>
    <xsl:choose>
        <xsl:when test="@label">
            <xsl:text>[label=</xsl:text>
            <xsl:apply-templates select="." mode="latex-ordered-list-label" />
            <xsl:text>]</xsl:text>
        </xsl:when>
        <xsl:when test="ancestor::exercises or ancestor::references">
            <xsl:text>[label=</xsl:text>
            <xsl:apply-templates select="." mode="latex-ordered-list-label-default" />
            <xsl:text>]</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <!-- No-op: Allow LaTeX (or a style) to determine -->
        </xsl:otherwise>
    </xsl:choose>
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
    <xsl:if test="@cols">
        <xsl:text>\begin{multicols}{</xsl:text>
        <xsl:value-of select="@cols" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{itemize}[label=</xsl:text>
    <xsl:choose>
        <xsl:when test="@label">
            <xsl:apply-templates select="." mode="latex-unordered-list-label" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="latex-unordered-list-label-default" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>]&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{itemize}&#xa;</xsl:text>
    <xsl:if test="@cols">
        <xsl:text>\end{multicols}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="dl">
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
<!-- We assume content of list items  -->
<!-- (typically paragraphs), end with -->
<!-- non-blank line and a newline     -->
<xsl:template match="ol/li|ul/li">
    <xsl:text>\item{}</xsl:text>
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
    <xsl:text>]{}</xsl:text>
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
<!-- \terminology{} defined in preamble as semantic macro -->
<xsl:template match="term">
    <xsl:text>\terminology{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Acronyms (no-op) -->
<!-- \acronym{} defined in preamble as semantic macro -->
<xsl:template match="acro">
    <xsl:text>\acronym{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Code, inline -->
<!-- A question mark is invalid Python, so a useful separator    -->
<!-- The latexsep attribute allows specifying a different symbol -->
<!-- The lstinline macro is more robust than \verb,              -->
<!-- for example when used in \multicolumn in a tabular          -->
<xsl:template match="c">
    <xsl:variable name="separator">
        <xsl:choose>
            <xsl:when test="@latexsep">
                <xsl:value-of select="@latexsep" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>?</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>\lstinline</xsl:text>
    <xsl:value-of select="$separator" />
    <xsl:value-of select="." />
    <xsl:value-of select="$separator" />
</xsl:template>

<!-- External URLs, Email        -->
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

<!-- Chunks of Pre-Formatted Text                -->
<!-- 100% analogue of LaTeX's verbatim           -->
<!-- environment or HTML's <pre> element         -->
<!-- Text is massaged just like Sage input code  -->
<xsl:template match="pre">
    <xsl:text>\begin{verbatim}&#xa;</xsl:text>
        <xsl:call-template name="sanitize-sage">
            <xsl:with-param name="raw-sage-code" select="." />
        </xsl:call-template>
    <xsl:text>\end{verbatim}&#xa;</xsl:text>
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
<!-- 2015/01/28: there was a mismatch between HTML and LaTeX names -->
<xsl:template match="circum">
    <xsl:text>\textasciicircum{}</xsl:text>
    <xsl:message>MBX:WARNING: the "circum" element is deprecated (2015/01/28), use "circumflex"</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
</xsl:template>

<xsl:template match="circumflex">
    <xsl:text>\textasciicircum{}</xsl:text>
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
    <xsl:text>\textasciitilde{}</xsl:text>
</xsl:template>

<!-- Backslash -->
<!-- See url element for comprehensive approach -->
<xsl:template match="backslash">
    <xsl:text>\textbackslash{}</xsl:text>
</xsl:template>

<!-- Other Miscellaneous Symbols, Constructions -->

<!-- Ellipsis (dots), for text, not math -->
<xsl:template match="ellipsis">
    <xsl:text>\dots{}</xsl:text>
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
<xsl:template match="copyright">
    <xsl:text>\copyright{}</xsl:text>
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
<!-- but \\ is definitley better for multi-line main titles     -->
<!-- Use sparingly, e.g. for poetry, *not* in math environments -->
<!-- Must be in TeX's paragraph mode                            -->
<xsl:template match="br">
    <xsl:text>\newline{}</xsl:text>
</xsl:template>
<xsl:template match="title/br|subtitle/br">
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

<!-- Sage Cells -->

<!-- An abstract named template accepts input text and               -->
<!-- output text, then wraps it for print, including output          -->
<!-- But we do not write an environment if there isn't any content   -->
<!-- So conceivably, this template can do nothing (ie an empty cell) -->
<xsl:template name="sage-active-markup">
    <xsl:param name="in" />
    <xsl:param name="out" />
    <xsl:if test="$in!=''">
        <xsl:text>\begin{lstlisting}[style=sageinput]&#xa;</xsl:text>
        <xsl:value-of select="$in" />
        <xsl:text>\end{lstlisting}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$out!=''">
        <xsl:text>\begin{lstlisting}[style=sageoutput]&#xa;</xsl:text>
        <xsl:value-of select="$out" />
        <xsl:text>\end{lstlisting}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- An abstract named template accepts input text -->
<!-- and wraps it, untouchable by default in print -->
<xsl:template name="sage-display-markup">
    <xsl:param name="in" />
    <xsl:if test="$in!=''">
        <xsl:text>\begin{lstlisting}[style=sageinput]&#xa;</xsl:text>
        <xsl:value-of select="$in" />
        <xsl:text>\end{lstlisting}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Type: "practice"; not much point to show to a print reader  -->
<!-- This overrides the default, which is a small annotated cell -->
<xsl:template match="sage[@type='practice']" />


<!-- Program Listings -->
<!-- The "listings-language" template is in the common file -->
<xsl:template match="program">
    <xsl:variable name="language"><xsl:apply-templates select="." mode="listings-language" /></xsl:variable>
    <xsl:text>\begin{lstlisting}[style=genericinput</xsl:text>
    <xsl:if test="$language!=''">
        <xsl:text>, language=</xsl:text>
        <xsl:value-of select="$language" />
    </xsl:if>
    <xsl:text>]&#xa;</xsl:text>
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
    <xsl:choose>
      <xsl:when test="ancestor::sidebyside and ancestor::table and not(ancestor::sidebyside/caption)">
            <xsl:text>\captionof{table}{</xsl:text>
      </xsl:when>
      <xsl:when test="ancestor::sidebyside and ancestor::figure and not(ancestor::sidebyside/caption)">
            <xsl:text>\captionof{figure}{</xsl:text>
      </xsl:when>
      <xsl:otherwise>
          <xsl:text>\caption{</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates />
    <xsl:apply-templates select=".." mode="label" />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Figures -->
<!-- Standard LaTeX figure environment redefined, see preamble comments -->
<xsl:template match="figure">
    <xsl:text>\begin{figure}&#xa;</xsl:text>
    <xsl:text>\centering&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::caption)]"/>
    <xsl:apply-templates select="caption" />
    <xsl:text>\end{figure}&#xa;</xsl:text>
</xsl:template>

<!-- The sidebyside template 'wrapping' environment will always be a figure; 
     captions will be accounted for appropriately using \captionof{<name/>}{<CAPTION/>}. 
     See the caption template for details. 

     Each sidebyside element is put through a measuring routine,
     which allows us to align captions correctly;
     see: http://tex.stackexchange.com/questions/230335/vertically-aligning-minipages-subfigures-and-subtables-not-with-baseline
     for details.

     The following elements are supported:

     sidebyside/figure 
     sidebyside/table 
     sidebyside/paragraphs 
     sidebyside/p 
     sidebyside/image 
     sidebyside/tabular 
     
     -->
<xsl:template match="sidebyside">
    <xsl:text>\begin{figure}&#xa;</xsl:text>
    <xsl:text>\centering&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::caption)]" mode="sidebyside"/>
    <!-- output the child nodes -->
    <xsl:text>\popValignCaptionBottom&#xa;</xsl:text>
    <!-- global caption -->
    <xsl:apply-templates select="caption" />
    <xsl:text>\end{figure}&#xa;</xsl:text>
</xsl:template>

<!-- vertical alignment of objects inside sidebyside -->
<xsl:template match="*" mode="sidebyside-subitem-valign">
    <!-- process the width attritbute -->
    <xsl:variable name="width">
        <!-- the width of a <object/> inside a sidebyside is translated into 
             a fraction of \textwidth 
             we do this by stripping the % sign, and 
             adding a leading .
             for example 50% is turned into .50\textwith
               -->
        <xsl:choose>
            <xsl:when test="@width">
                <xsl:value-of select="substring-before(@width,'%')" />
            </xsl:when>
            <xsl:otherwise>
              <!-- default width is calculated by computing 100/(number of figures)
                   for example, if there are 4 figures, the default width will be 25% -->
              <xsl:call-template name="printWidth" select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="length" select="string-length($width)"/>
    <!-- capture each element -->
    <xsl:text>\pushValignCaptionBottom</xsl:text>
    <!-- specify the vertical alignment -->
    <xsl:choose>
        <xsl:when test="@valign='top'">
            <xsl:text>[t]</xsl:text>
        </xsl:when>
        <xsl:when test="@valign='middle'">
            <xsl:text>[c]</xsl:text>
        </xsl:when>
        <!-- default value -->
        <xsl:otherwise>
            <xsl:text>[b]</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- specify minipage, subfigure, or subtable -->
    <xsl:text>{</xsl:text>
    <xsl:choose>
      <xsl:when test="self::figure and ancestor::sidebyside/caption">
            <xsl:text>subfigure</xsl:text>
      </xsl:when>
      <xsl:when test="self::table and ancestor::sidebyside/caption">
            <xsl:text>subtable</xsl:text>
      </xsl:when>
      <xsl:otherwise>
            <xsl:text>minipage</xsl:text>
      </xsl:otherwise> 
    </xsl:choose>
    <xsl:text>}</xsl:text>
    <!-- specify the text width -->
    <xsl:text>{.</xsl:text>
    <xsl:choose>
        <!-- @width can contain a decimal, e.g 25.56%, in which 
           case we need to remove the decimal -->
        <xsl:when test="contains($width,'.')">
            <xsl:value-of select="substring-before($width,'.')"/>
            <xsl:value-of select="substring-after($width,'.')"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$width"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\textwidth}{%&#xa;</xsl:text>
</xsl:template>

<!-- horizontal alignment of objects inside sidebyside -->
<xsl:template match="*" mode="sidebyside-subitem-halign">
    <!-- horizontal alignment -->
    <xsl:choose>
        <xsl:when test="@halign='right'">
            <xsl:text>\raggedleft</xsl:text>
        </xsl:when>
        <xsl:when test="@halign='left'">
            <xsl:text>\raggedright</xsl:text>
        </xsl:when>
        <xsl:when test="@halign='center'">
            <xsl:text>\centering</xsl:text>
        </xsl:when>
        <!-- default value -->
        <xsl:otherwise>
              <!-- anything except a paragraph gets centering by default -->
              <xsl:if test="not(self::paragraphs or self::p)">
                    <xsl:text>\centering</xsl:text>
              </xsl:if> 
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>% horizontal alignment &#xa;</xsl:text>
</xsl:template>

<xsl:template match="figure" mode="sidebyside">
    <!-- vertical alignment -->
    <xsl:apply-templates select="." mode="sidebyside-subitem-valign"/>
    <!-- horizontal alignment -->
    <xsl:apply-templates select="." mode="sidebyside-subitem-halign"/>
    <!-- body of the figure -->
    <xsl:apply-templates select="*[not(self::caption)]" />
    <!-- end the body of the figure -->
    <xsl:text>}% end body &#xa;{</xsl:text>
    <!-- add caption -->
    <xsl:apply-templates select="caption" />
    <xsl:text>}% caption &#xa;</xsl:text>
</xsl:template>

<xsl:template match="table" mode="sidebyside">
    <!-- vertical alignment -->
    <xsl:apply-templates select="." mode="sidebyside-subitem-valign"/>
    <!-- horizontal alignment -->
    <xsl:apply-templates select="." mode="sidebyside-subitem-halign"/>
    <!-- body of the table -->
    <xsl:apply-templates select="*[not(self::caption)]" />
    <!-- end the body of the table -->
    <xsl:text>}% end body &#xa;{</xsl:text>
    <!-- add caption -->
    <xsl:apply-templates select="caption" />
    <xsl:text>}% caption &#xa;</xsl:text>
</xsl:template>

<xsl:template match="image" mode="sidebyside">
    <!-- vertical alignment -->
    <xsl:apply-templates select="." mode="sidebyside-subitem-valign"/>
    <!-- horizontal alignment -->
    <xsl:apply-templates select="." mode="sidebyside-subitem-halign"/>
    <!-- images need to have their width and height processed -->
    <xsl:if test="@source">
        <xsl:text>\includegraphics[</xsl:text>
        <xsl:text>width=\textwidth,</xsl:text>
        <xsl:if test="@height">
            <xsl:text>height=</xsl:text><xsl:value-of select="@height" /><xsl:text>pt,</xsl:text>
        </xsl:if>
        <xsl:text>]</xsl:text>
        <xsl:text>{</xsl:text><xsl:value-of select="@source" /><xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="tikz|asymptote|sageplot|latex-image-code" />
    <!-- end the body of the image -->
    <xsl:text>}% end body &#xa;{</xsl:text>
    <!-- add empty caption -->
    <xsl:text>}% caption &#xa;</xsl:text>
</xsl:template>

<xsl:template match="paragraphs" mode="sidebyside">
    <!-- vertical alignment -->
    <xsl:apply-templates select="." mode="sidebyside-subitem-valign"/>
    <!-- horizontal alignment -->
    <xsl:apply-templates select="." mode="sidebyside-subitem-halign"/>
    <!-- paragraphs and p elements need wrapping in a parbox -->
    <xsl:text>\parbox{\textwidth}{%&#xa;</xsl:text>
    <!-- horizontal alignment (inside the parbox) -->
    <xsl:apply-templates select="." mode="sidebyside-subitem-halign"/>
    <xsl:apply-templates />
    <!-- \parbox needs closing-->
    <xsl:text>}&#xa;</xsl:text>
    <!-- end the body of the paragraph -->
    <xsl:text>}% end body &#xa;{</xsl:text>
    <!-- add empty caption -->
    <xsl:text>}% caption &#xa;</xsl:text>
</xsl:template>

<xsl:template match="p" mode="sidebyside">
    <!-- vertical alignment -->
    <xsl:apply-templates select="." mode="sidebyside-subitem-valign"/>
    <!-- paragraphs and p elements need wrapping in a parbox -->
    <xsl:text>\parbox{\textwidth}{%&#xa;</xsl:text>
    <!-- horizontal alignment (inside the parbox) -->
    <xsl:apply-templates select="." mode="sidebyside-subitem-halign"/>
    <xsl:apply-templates />
    <!-- \parbox needs closing-->
    <xsl:text>}&#xa;</xsl:text>
    <!-- end the body of the paragraph -->
    <xsl:text>}% end body &#xa;{</xsl:text>
    <!-- add empty caption -->
    <xsl:text>}% caption &#xa;</xsl:text>
</xsl:template>

<xsl:template match="tabular" mode="sidebyside">
    <!-- vertical alignment -->
    <xsl:apply-templates select="." mode="sidebyside-subitem-valign"/>
    <!-- horizontal alignment -->
    <xsl:apply-templates select="." mode="sidebyside-subitem-halign"/>
    <!-- body of the tabular -->
    <xsl:call-template name="tabular" select="self()" />
    <!-- end the body of the tabular -->
    <xsl:text>}% end body &#xa;{</xsl:text>
    <!-- add empty caption -->
    <xsl:text>}% caption &#xa;</xsl:text>
</xsl:template>

<xsl:template match="sidebyside/paragraphs/title">
  <xsl:text>\paragraph{</xsl:text>
    <xsl:apply-templates />
  <xsl:text>}</xsl:text>
</xsl:template>

<!-- Images -->
<xsl:template match="image" >
    <xsl:if test="@source">
        <xsl:text>\includegraphics[</xsl:text>
        <xsl:choose>
          <xsl:when test="ancestor::sidebyside">
            <xsl:text>width=\textwidth,</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="@width">
                <xsl:text>width=</xsl:text><xsl:value-of select="@width" /><xsl:text>pt,</xsl:text>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
         <xsl:if test="@height">
             <xsl:text>height=</xsl:text><xsl:value-of select="@height" /><xsl:text>pt,</xsl:text>
         </xsl:if>
        <xsl:text>]</xsl:text>
        <xsl:text>{</xsl:text><xsl:value-of select="@source" /><xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="tikz|asymptote|sageplot|latex-image-code" />
</xsl:template>

<!-- Asymptote graphics language  -->
<!-- EPS's produced by mbx script -->
<xsl:template match="image/asymptote">
    <xsl:text>\includegraphics[width=0.80\textwidth]{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select=".." mode="internal-id" />
    <xsl:text>.pdf}&#xa;</xsl:text>
</xsl:template>

<!-- Sage graphics plots          -->
<!-- EPS's produced by mbx script -->
<!-- PNGs are fallback for 3D     -->
<xsl:template match="image/sageplot">
    <xsl:text>\IfFileExists{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select=".." mode="internal-id" />
    <xsl:text>.pdf}%&#xa;</xsl:text>
    <xsl:text>{\includegraphics[width=0.80\textwidth]{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select=".." mode="internal-id" />
    <xsl:text>.pdf}}%&#xa;</xsl:text>
    <xsl:text>{\includegraphics[width=0.80\textwidth]{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select=".." mode="internal-id" />
    <xsl:text>.png}}&#xa;</xsl:text>
</xsl:template>

<!-- LaTeX graphics (tikz, pgfplots, pstricks, etc) -->
<xsl:template match="latex-image-code">
    <xsl:if test="not(parent::image)">
        <xsl:message>MBX:WARNING: latex-image-code element should be enclosed by an image element</xsl:message>
    </xsl:if>
    <!-- outer braces rein in the scope of any local graphics settings -->
    <xsl:text>{&#xa;</xsl:text>
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="." />
    </xsl:call-template>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>


<!-- ################################## -->
<!-- Deprecated Graphics Code Templates -->
<!-- ################################## -->
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="tikz">
    <xsl:message>MBX:WARNING: tikz element superceded by latex-image-code element</xsl:message>
    <xsl:message>MBX:WARNING: tikz package and necessary libraries should be included in docinfo/latex-image-preamble</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="." />
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
    <xsl:text>\begin{table}&#xa;</xsl:text>
    <xsl:text>\centering&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::caption)]" />
    <xsl:apply-templates select="caption" />
    <xsl:text>\end{table}&#xa;</xsl:text>
</xsl:template>

<!-- A tabular layout -->
<xsl:template match="tabular" name="tabular">
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
        <!-- All columns specified identically so far   -->
        <!--   so can repeat global, table-wide values  -->
        <!--   use first row to determine number        -->
        <!--   write alignment (mandatory)              -->
        <!--   follow with right border (optional)      -->
        <xsl:otherwise>
            <xsl:for-each select="row[1]/cell">
                <xsl:call-template name="halign-specification">
                    <xsl:with-param name="align" select="$table-halign" />
                </xsl:call-template>
                <xsl:call-template name="vrule-specification">
                    <xsl:with-param name="width" select="$table-right" />
                </xsl:call-template>
            </xsl:for-each>
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
                <xsl:when test="not($next-col) and ($start-run = 1)">
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
    <!-- Look ahead to next cell, anticipating recursion   -->
    <!-- but also probing for end of row (no more cells),  -->
    <!-- which is needed when flushing cline specification -->
    <!-- Also advance to next col element from right one   -->
    <xsl:variable name="next-cell" select="$the-cell/following-sibling::cell[1]" /> <!-- possibly empty -->
    <xsl:variable name="next-col"  select="$right-col/following-sibling::col[1]" />
    <!-- Write the cell's contents -->
    <!-- if the left border, alignment or right border        -->
    <!-- conflict with the column specification, then we      -->
    <!-- wrap in a multicolumn to specify the overrides.      -->
    <!-- Or if we have a colspan, then we use a multicolumn   -->
    <!-- $table-left and $row-left *can* differ on first use, -->
    <!-- but row-left is subsequently set to $table-left     -->
    <xsl:if test="$the-cell">
        <xsl:choose>
            <xsl:when test="not($table-left = $row-left) or not($column-halign = $cell-halign) or not($column-right = $cell-right) or ($column-span > 1)">
                <xsl:text>\multicolumn{</xsl:text>
                <xsl:value-of select="$column-span" />
                <xsl:text>}{</xsl:text>
                <!-- only place latex allows/needs a left border -->
                <xsl:if test="$left-column-number = 1">
                    <xsl:call-template name="vrule-specification">
                        <xsl:with-param name="width" select="$row-left" />
                    </xsl:call-template>
                </xsl:if>
                <xsl:call-template name="halign-specification">
                    <xsl:with-param name="align" select="$cell-halign" />
                </xsl:call-template>
                <xsl:call-template name="vrule-specification">
                    <xsl:with-param name="width" select="$cell-right" />
                </xsl:call-template>
                <xsl:text>}{</xsl:text>
                <xsl:apply-templates select="$the-cell" />
                <xsl:text>}</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$the-cell" />
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
                <xsl:when test="not($next-cell) and ($start-run = 1)">
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
            <xsl:if test="not($updated-cline='') or not($last-row)">
                <xsl:text>\\</xsl:text>
            </xsl:if>
            <xsl:value-of select="$updated-cline" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############################ -->
<!-- Table construction utilities -->
<!-- ############################ -->

<!-- Mostly translating MBX terms to LaTeX terms         -->
<!-- Typically use these at the last moment,             -->
<!-- while outputting, and thus use MBX terms internally -->

<!-- Translate horizontal alignment to standard LaTeX column specification -->
<xsl:template name="halign-specification">
    <xsl:param name="align" />
    <xsl:choose>
        <xsl:when test="$align='left'">
            <xsl:text>l</xsl:text>
        </xsl:when>
        <xsl:when test="$align='center'">
            <xsl:text>c</xsl:text>
        </xsl:when>
        <xsl:when test="$align='right'">
            <xsl:text>r</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: tabular horizontal alignment attribute not recognized: use left, center, right</xsl:message>
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


<!-- Visual Identifiers for Cross-References -->
<!-- Format of visual identifiers, peculiar to LaTeX              -->
<!-- This is complete LaTeX code to make visual reference         -->
<!-- LaTeX does the numbering and visual formatting automatically -->
<!-- Many components are built from common routines               -->

<!-- Almost always, a \ref is good enough       -->
<!-- Hyperref construction:                     -->
<!-- \hyperref[a-label]{Section~\ref*{a-label}} -->
<xsl:template match="*" mode="ref-id">
    <xsl:param name="autoname" />
    <xsl:variable name="prefix">
        <xsl:apply-templates select="." mode="ref-prefix">
            <xsl:with-param name="local" select="$autoname" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
        <!-- No autonaming prefix: generic LaTeX cross-reference -->
        <xsl:when test="$prefix=''">
            <xsl:text>\ref{</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- Autonaming prefix: hyperref enhanced cross-reference -->
        <xsl:otherwise>
            <xsl:text>\hyperref[</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>]{</xsl:text>
            <xsl:value-of select="$prefix" />
            <xsl:text>~</xsl:text>
            <xsl:text>\ref*{</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>}}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Referencing a biblio is a cite in LaTeX                     -->
<!-- A cross-reference to a biblio may have "detail",            -->
<!-- extra information about the location in the referenced work -->
<xsl:template match="biblio" mode="ref-id">
    <xsl:param name="detail" />
    <xsl:text>\cite</xsl:text>
    <xsl:if test="$detail != ''">
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="$detail" />
        <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Referencing an AMSmath equation (resp. MathJax) is a \eqref{} -->
<!-- TODO: will we allow me's to be numbered, or not?              -->
<xsl:template match="me|men|mrow" mode="ref-id">
    <xsl:text>\eqref{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- We do links to exercises manually since they may be hard-coded -->
<!-- Show the fully-qualified number as a reference                 -->
<xsl:template match="exercises//exercise" mode="ref-id">
    <xsl:if test="$autoname='yes'" >
        <xsl:apply-templates select="." mode="type-name" />
        <xsl:text>~</xsl:text>
    </xsl:if>
    <xsl:text>\hyperlink{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- In some cases we supply our own cross-referencing via       -->
<!-- hyperref's hypertarget mechanism, specifically for          -->
<!-- exercises, which may have hard-coded numbers in the source  -->
<!-- The target being null is necessary, up hard to environments -->
<xsl:template match="exercises//exercise" mode="label">
    <xsl:text>\phantomsection\hypertarget{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}{\null}</xsl:text>
</xsl:template>

<!-- Footnotes               -->
<!--   with no customization -->
<xsl:template match="fn">
    <xsl:text>\footnote{</xsl:text>
    <xsl:apply-templates />
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
    <xsl:apply-templates select="." mode="origin-id" />
    <xsl:text>]</xsl:text>
    <!-- "key" for cross-referencing -->
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id"/>
    <xsl:text>}</xsl:text>
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
    <xsl:text>\par </xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Miscellaneous -->

<!-- Inline warnings go into text, no matter what -->
<!-- They are colored for an author's report -->
<xsl:template name="inline-warning">
    <xsl:param name="warning" />
    <!-- Color for author tools version -->
    <xsl:if test="$author-tools='yes'" >
        <xsl:text>\textcolor{red}</xsl:text>
    </xsl:if>
    <xsl:text>{</xsl:text>
    <xsl:text>$\langle\langle$</xsl:text>
    <xsl:value-of select="$warning"/>
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
