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
<!-- Console characters allow customization of how    -->
<!-- LaTeX macros are recognized in the fancyvrb      -->
<!-- package's Verbatim clone environment, "console"  -->
<!-- The defaults are traditional LaTeX, we let any   -->
<!-- other specification make a document-wide default -->
<xsl:param name="latex.console.macro-char" select="'\'" />
<xsl:param name="latex.console.begin-char" select="'{'" />
<xsl:param name="latex.console.end-char" select="'}'" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<!-- Variables that affect LaTeX creation -->
<!-- More in the common file              -->

<!-- We generally want one large complete LaTeX file -->
<xsl:variable name="chunk-level">
    <xsl:choose>
        <xsl:when test="$chunk.level != ''">
            <xsl:value-of select="$chunk.level" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>0</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- LaTeX always puts sections at level "1"            -->
<!-- MBX has sections at level "2", so off by one       -->
<!-- Furthermore, param's are relative to document root -->
<!-- So we translate MBX-speak to LaTeX-speak (twice)   -->
<xsl:variable name="latex-toc-level">
    <xsl:value-of select="$root-level + $toc-level - 1" />
</xsl:variable>
<xsl:variable name="latex-numbering-maxlevel">
    <xsl:value-of select="$root-level + $numbering-maxlevel - 1" />
</xsl:variable>

<!-- We override the default ToC structure    -->
<!-- just to kill the ToC always for articles -->
<xsl:variable name="toc-level">
    <xsl:choose>
        <xsl:when test="$toc.level != ''">
            <xsl:value-of select="$toc.level" />
        </xsl:when>
        <xsl:when test="/mathbook/book">2</xsl:when>
        <xsl:when test="/mathbook/article">0</xsl:when>
        <xsl:when test="/mathbook/letter">0</xsl:when>
        <xsl:when test="/mathbook/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Table of Contents level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Variables carry document-wide console LaTeX escape characters, -->
<!-- which an author may override on a per-console basis            -->
<xsl:variable name="console-macro" select="$latex.console.macro-char" />
<xsl:variable name="console-begin" select="$latex.console.begin-char" />
<xsl:variable name="console-end" select="$latex.console.end-char" />

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:apply-templates select="mathbook" mode="deprecation-warnings" />
    <xsl:apply-templates />
</xsl:template>

<!-- We process structural nodes via chunking routine in   xsl/mathbook-common.html -->
<!-- This in turn calls specific modal templates defined elsewhere in this file     -->
<xsl:template match="/mathbook">
    <xsl:apply-templates mode="chunk" />
</xsl:template>


<!-- TODO: combine article, book, letter, templates -->
<!-- with abstract templates for latex classes, page sizes -->

<!-- An article, LaTeX structure -->
<!--     One page, full of sections (with abstract, references)                    -->
<!--     Or, one page, totally unstructured, just lots of paragraphs, widgets, etc -->
<xsl:template match="article" mode="content-wrap">
    <xsl:param name="content" />
    <xsl:call-template name="converter-blurb-latex" />
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
    <!-- parameterize preamble template with "page-geometry" template conditioned on self::article etc -->
    <xsl:call-template name="title-page-info-article" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:copy-of select="$content" />
    <xsl:call-template name="latex-postamble" />
   <xsl:text>\end{document}</xsl:text>
</xsl:template>

<!-- A book, LaTeX structure -->
<!-- The ordering of the frontmatter is from             -->
<!-- "Bookmaking", 3rd Edition, Marshall Lee, Chapter 27 -->
<xsl:template match="book" mode="content-wrap">
    <xsl:param name="content" />
    <xsl:call-template name="converter-blurb-latex" />
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
    <xsl:copy-of select="$content" />
    <xsl:call-template name="latex-postamble" />
    <xsl:text>\end{document}</xsl:text>
</xsl:template>

<!-- A letter, LaTeX structure -->
<xsl:template match="letter" mode="content-wrap">
    <xsl:param name="content" />
    <xsl:call-template name="converter-blurb-latex" />
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
    <!-- the body -->
    <xsl:copy-of select="$content" />
    <xsl:call-template name="latex-postamble" />
    <xsl:text>\end{document}</xsl:text>
</xsl:template>

<!-- A memo, LaTeX structure -->
<xsl:template match="memo" mode="content-wrap">
    <xsl:param name="content" />
    <xsl:call-template name="converter-blurb-latex" />
    <xsl:text>\documentclass[</xsl:text>
    <xsl:value-of select="$latex.font.size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$latex.draft='yes'" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{article}&#xa;%&#xa;</xsl:text>
    <xsl:text>% Load geometry package to allow page margin adjustments&#xa;</xsl:text>
    <xsl:text>\usepackage{geometry}&#xa;</xsl:text>
    <xsl:text>\geometry{letterpaper,total={6.0in,9.0in}}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:text>\begin{document}&#xa;%&#xa;</xsl:text>
    <!-- process the body -->
    <xsl:copy-of select="$content" />
    <xsl:call-template name="latex-postamble" />
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
    <xsl:text>%% Inline math delimiters, \(, \), need to be robust&#xa;</xsl:text>
    <xsl:text>%% 2016-01-31:  latexrelease.sty  supersedes  fixltx2e.sty&#xa;</xsl:text>
    <xsl:text>%% If  latexrelease.sty  exists, bugfix is in kernel&#xa;</xsl:text>
    <xsl:text>%% If not, bugfix is in  fixltx2e.sty&#xa;</xsl:text>
    <xsl:text>%% See:  https://tug.org/TUGboat/tb36-3/tb114ltnews22.pdf&#xa;</xsl:text>
    <xsl:text>%% and read "Fewer fragile commands" in distribution's  latexchanges.pdf&#xa;</xsl:text>
    <xsl:text>\IfFileExists{latexrelease.sty}{}{\usepackage{fixltx2e}}&#xa;</xsl:text>
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
    <xsl:if test="//m[contains(text(),'sfrac')] or //md[contains(text(),'sfrac')] or //me[contains(text(),'sfrac')] or //mrow[contains(text(),'sfrac')]">
        <xsl:text>%% xfrac package for 'beveled fractions': http://tex.stackexchange.com/questions/3372/how-do-i-typeset-arbitrary-fractions-like-the-standard-symbol-for-5-%C2%BD&#xa;</xsl:text>
        <xsl:text>\usepackage{xfrac}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Semantic Macros&#xa;</xsl:text>
    <xsl:text>%% To preserve meaning in a LaTeX file&#xa;</xsl:text>
    <xsl:text>%% Only defined here if required in this document&#xa;</xsl:text>
    <xsl:if test="/mathbook//alert">
        <xsl:text>%% Used for warnings, typically bold and italic&#xa;</xsl:text>
        <xsl:text>\newcommand{\alert}[1]{\textbf{\textit{#1}}}&#xa;</xsl:text>
    </xsl:if>
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
    <!-- http://tex.stackexchange.com/questions/155710/understanding-the-arguments-in-newtheorem-e-g-newtheoremtheoremtheoremsec/155714#155714 -->
    <xsl:text>\newtheorem{theorem}{</xsl:text>
    <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'theorem'" /></xsl:call-template>
    <xsl:text>}</xsl:text>
    <!-- See numbering-theorems variable being set in mathbook-common.xsl -->
    <xsl:if test="not($numbering-theorems = 0)">
        <xsl:text>[</xsl:text>
        <xsl:call-template name="level-number-to-latex-name">
            <xsl:with-param name="level" select="$numbering-theorems + $root-level" />
        </xsl:call-template>
        <xsl:text>]&#xa;</xsl:text>
    </xsl:if>
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
    <!-- Localize various standard names in use         -->
    <!-- Many enviroments addressed upon creation above -->
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
    <xsl:if test="/mathbook/book">
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
    <xsl:if test="/mathbook/article">
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
        <xsl:call-template name="level-number-to-latex-name">
            <xsl:with-param name="level" select="$numbering-equations + $root-level" />
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
    <!-- Float package allows for placment [H]ere                    -->
    <!-- Numbering happens along with theorem counter above,         -->
    <!-- but could be done with caption package hook, see both       -->
    <!-- New names are necessary to make "within" numbering possible -->
    <!-- http://tex.stackexchange.com/questions/127914/custom-counter-steps-twice-when-invoked-from-caption-using-caption-package -->
    <!-- http://tex.stackexchange.com/questions/160207/side-effect-of-caption-package-with-custom-counter                         -->
    <xsl:if test="//figure or //table or //listing">
        <xsl:text>%% Figures, Tables, Listings, Floats&#xa;</xsl:text>
        <xsl:text>%% The [H]ere option of the float package fixes floats in-place,&#xa;</xsl:text>
        <xsl:text>%% in deference to web usage, where floats are totally irrelevant&#xa;</xsl:text>
        <xsl:text>%% We re/define the figure, table and listing environments, if used&#xa;</xsl:text>
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
            <xsl:choose>
                <xsl:when test="$numbering-theorems = 0">
                    <xsl:text>none</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="level-number-to-latex-name">
                        <xsl:with-param name="level" select="$numbering-theorems + $root-level" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
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
            <xsl:choose>
                <xsl:when test="$numbering-theorems = 0">
                    <xsl:text>none</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="level-number-to-latex-name">
                        <xsl:with-param name="level" select="$numbering-theorems + $root-level" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>,name=</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'table'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>% tables have the same number as theorems: http://tex.stackexchange.com/questions/16195/how-to-make-equations-figures-and-theorems-use-the-same-numbering-scheme &#xa;</xsl:text>
            <xsl:text>\makeatletter&#xa;</xsl:text>
            <xsl:text>\let\c@table\c@theorem&#xa;</xsl:text>
            <xsl:text>\makeatother&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//listing">
            <xsl:text>% Listing environment declared as new floating environment&#xa;</xsl:text>
            <xsl:text>\DeclareFloatingEnvironment[fileext=lol,placement={H},within=</xsl:text>
            <!-- See numbering-theorems variable being set in mathbook-common.xsl -->
            <xsl:choose>
                <xsl:when test="$numbering-theorems = 0">
                    <xsl:text>none</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="level-number-to-latex-name">
                        <xsl:with-param name="level" select="$numbering-theorems + $root-level" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>,name=</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'listing'" /></xsl:call-template>
            <xsl:text>]{listing}&#xa;</xsl:text>
            <xsl:text>% listings have the same number as theorems: http://tex.stackexchange.com/questions/16195/how-to-make-equations-figures-and-theorems-use-the-same-numbering-scheme &#xa;</xsl:text>
            <xsl:text>\makeatletter&#xa;</xsl:text>
            <xsl:text>\let\c@listing\c@theorem&#xa;</xsl:text>
            <xsl:text>\makeatother&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- Numbering Footnotes -->
    <xsl:if test="($numbering-footnotes != 0) and //fn">
        <xsl:text>%% Footnote Numbering&#xa;</xsl:text>
        <xsl:text>%% We reset the footnote counter, as given by numbering.footnotes.level&#xa;</xsl:text>
        <xsl:text>\makeatletter\@addtoreset{footnote}{</xsl:text>
        <xsl:call-template name="level-number-to-latex-name">
            <xsl:with-param name="level" select="$numbering-footnotes + $root-level" />
        </xsl:call-template>
        <xsl:text>}\makeatother&#xa;</xsl:text>
    </xsl:if>
    <!-- Poetry -->
    <xsl:if test="//poem">
        <xsl:text>%% Poetry support&#xa;</xsl:text>
        <xsl:text>\usepackage{verse}&#xa;</xsl:text>
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
    <!-- Bitstream Vera Font names within: https://github.com/timfel/texmf/blob/master/fonts/map/vtex/bera.ali -->
    <!-- Coloring listings: http://tex.stackexchange.com/questions/18376/beautiful-listing-for-csharp -->
    <!-- Song and Dance for font changes: http://jevopi.blogspot.com/2010/03/nicely-formatted-listings-in-latex-with.html -->
    <xsl:if test="//c or //pre or //sage or //program or //console">
        <xsl:text>%% New typewriter font if  c, sage, program, console, pre  tags present&#xa;</xsl:text>
        <xsl:text>%% If only  email, url  tags, no change from default&#xa;</xsl:text>
        <xsl:text>%% Needs a bit of scaling down to match text&#xa;</xsl:text>
        <xsl:text>\usepackage[scaled=.95]{sourcecodepro}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//c or //sage or //program">
        <xsl:text>%% Program listing support, for inline code, Sage code&#xa;</xsl:text>
        <xsl:text>\usepackage{listings}&#xa;</xsl:text>
        <xsl:text>%% We define the listings font style to be the default "ttfamily"&#xa;</xsl:text>
        <xsl:text>%% To fix hyphens/dashes rendered in PDF as fancy minus signs by listing&#xa;</xsl:text>
        <xsl:text>%% http://tex.stackexchange.com/questions/33185/listings-package-changes-hyphens-to-minus-signs&#xa;</xsl:text>
        <xsl:text>\makeatletter&#xa;</xsl:text>
        <xsl:text>\lst@CCPutMacro\lst@ProcessOther {"2D}{\lst@ttfamily{-{}}{-{}}}&#xa;</xsl:text>
        <xsl:text>\@empty\z@\@empty&#xa;</xsl:text>
        <xsl:text>\makeatother&#xa;</xsl:text>
        <xsl:text>%% End of generic listing adjustments&#xa;</xsl:text>
        <xsl:if test="//c">
            <xsl:text>%% Inline code, typically from "c" element&#xa;</xsl:text>
            <xsl:text>%% Global, document-wide options apply to \lstinline&#xa;</xsl:text>
            <xsl:text>%% Search/replace \lstinline by \verb to remove this dependency&#xa;</xsl:text>
            <xsl:text>%% (redefining \lstinline with \verb is unlikely to work)&#xa;</xsl:text>
            <!-- breakatwhitespace fixes commas moving to new lines, and other bad things       -->
            <!-- http://tex.stackexchange.com/questions/64750/avoid-line-breaks-after-lstinline -->
            <xsl:text>\lstset{basicstyle=\small\ttfamily,breaklines=true,breakatwhitespace=true}&#xa;</xsl:text>
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
            <xsl:text>basicstyle=\small\ttfamily,identifierstyle=\color{identifiers},commentstyle=\color{comments},stringstyle=\color{strings},keywordstyle=\color{keywords}}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="//sage">
            <xsl:text>%% Sage's blue is 50%, we go way lighter (blue!05 would work)&#xa;</xsl:text>
            <xsl:text>\definecolor{sageblue}{rgb}{0.95,0.95,1}&#xa;</xsl:text>
            <xsl:text>%% Sage input, listings package: Python syntax, boxed, colored, line breaking&#xa;</xsl:text>
            <xsl:text>%% Indent from left margin, flush at right margin&#xa;</xsl:text>
            <xsl:text>\lstdefinestyle{sageinput}{language=Python,breaklines=true,breakatwhitespace=true,basicstyle=\small\ttfamily,columns=fixed,frame=single,backgroundcolor=\color{sageblue},xleftmargin=4ex}&#xa;</xsl:text>
            <xsl:text>%% Sage output, similar, but not boxed, not colored&#xa;</xsl:text>
            <xsl:text>\lstdefinestyle{sageoutput}{language=Python,breaklines=true,breakatwhitespace=true,basicstyle=\small\ttfamily,columns=fixed,xleftmargin=4ex}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="//console">
        <xsl:text>%% Console session with prompt, input, output&#xa;</xsl:text>
        <xsl:text>%% Make a console environment from fancyvrb Verbatim environment&#xa;</xsl:text>
        <xsl:text>%% with three command characters, to allow boldfacing input&#xa;</xsl:text>
        <xsl:text>%% The command characters may be escaped here when specified&#xa;</xsl:text>
        <xsl:text>%% (Verbatim environment allows for line numbers, make feature request)&#xa;</xsl:text>
        <!-- perhaps use fancyverb more widely -->
        <xsl:text>\usepackage{fancyvrb}&#xa;</xsl:text>
        <xsl:text>\DefineVerbatimEnvironment{console}{Verbatim}%&#xa;</xsl:text>
        <xsl:text>{fontsize=\small,commandchars=</xsl:text>
        <xsl:variable name="latex-escaped" select="'&amp;%$#_{}~^\@'" />
        <xsl:if test="contains($latex-escaped, $console-macro)">
            <xsl:text>\</xsl:text>
        </xsl:if>
        <xsl:value-of select="$console-macro" />
        <xsl:if test="contains($latex-escaped, $console-begin)">
            <xsl:text>\</xsl:text>
        </xsl:if>
        <xsl:value-of select="$console-begin" />
        <xsl:if test="contains($latex-escaped, $console-end)">
            <xsl:text>\</xsl:text>
        </xsl:if>
        <xsl:value-of select="$console-end" />
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>%% A semantic macro for the user input portion&#xa;</xsl:text>
        <xsl:text>%% We define this in the traditional way,&#xa;</xsl:text>
        <xsl:text>%% but may realize it with different LaTeX escape characters&#xa;</xsl:text>
        <xsl:text>\newcommand{\consoleinput}[1]{\textbf{#1}}&#xa;</xsl:text>
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
                <xsl:text>\setlist[exerciselist]{leftmargin=0pt,itemsep=1.0ex,topsep=1.0ex,partopsep=0pt,parsep=0pt}&#xa;</xsl:text>
            </xsl:if>
            <xsl:if test="//exercisegroup">
                <xsl:text>%% Indented groups of exercises within an exercise section, maximum depth 4&#xa;</xsl:text>
                <xsl:text>\newlist{exercisegroup}{description}{4}&#xa;</xsl:text>
                <xsl:text>\setlist[exercisegroup]{leftmargin=2em,labelindent=2em,itemsep=1.0ex,topsep=1.0ex,partopsep=0pt,parsep=0pt}&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
    </xsl:if>
    <xsl:if test="//index">
        <xsl:text>%% Support for index creation&#xa;</xsl:text>
        <xsl:if test="$author-tools='no'">
            <xsl:text>%% Requires doing $ makeindex &lt;filename-base&gt;&#xa;</xsl:text>
            <xsl:text>%% (NB: do not provide an extension on the filename, eg no ".tex")&#xa;</xsl:text>
            <xsl:text>%% Do this prior to a second LaTeX pass&#xa;</xsl:text>
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
        <xsl:text>%% latex.print parameter set to 'yes', all hyperlinks black and inactive&#xa;</xsl:text>
        <xsl:text>\hypersetup{draft}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\hypersetup{pdftitle={</xsl:text>
    <xsl:apply-templates select="." mode="title-simple" />
    <xsl:text>}}&#xa;</xsl:text>
    <!-- http://tex.stackexchange.com/questions/44088/when-do-i-need-to-invoke-phantomsection -->
    <xsl:text>%% If you manually remove hyperref, leave in this next command&#xa;</xsl:text>
    <xsl:text>\providecommand\phantomsection{}&#xa;</xsl:text>
    <xsl:if test="//book/part">
        <xsl:text>%% To match HTML, chapters reset within parts&#xa;</xsl:text>
        <xsl:text>\makeatletter&#xa;</xsl:text>
        <xsl:text>\@addtoreset{chapter}{part}&#xa;</xsl:text>
        <xsl:text>\makeatother &#xa;</xsl:text>
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
        <xsl:call-template name="sanitize-code">
            <xsl:with-param name="raw-code" select="/mathbook/docinfo/latex-image-preamble" />
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
    <xsl:text>%% Begin: Author-provided macros&#xa;</xsl:text>
    <xsl:text>%% (From  docinfo/macros  element)&#xa;</xsl:text>
    <xsl:text>%% Plus three from MBX for XML characters&#xa;</xsl:text>
    <xsl:call-template name="latex-macro-list" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>%% End: Author-provided macros&#xa;</xsl:text>
</xsl:template>

<!-- LaTeX postamble is common for books, articles, memos and letters -->
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
    <xsl:apply-templates select="." mode="title-full" />
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
    <xsl:apply-templates select="/mathbook/book" mode="title-full"/>
    <xsl:text>}\\</xsl:text> <!-- always end line inside centering -->
    <xsl:if test="/mathbook/book/subtitle">
        <xsl:text>[2\baselineskip]&#xa;</xsl:text> <!-- extend line break if subtitle -->
        <xsl:text>{\LARGE </xsl:text>
        <xsl:apply-templates select="/mathbook/book/subtitle" />
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
<!-- Customize with an overide of this template in an imported stylesheet -->
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
    <xsl:text>{\Huge </xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}\\</xsl:text> <!-- end line inside centering -->
    <xsl:if test="subtitle">
        <xsl:text>[\baselineskip]&#xa;</xsl:text>  <!-- extend if subtitle -->
        <xsl:text>{\LARGE </xsl:text>
        <xsl:apply-templates select="subtitle" />
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

<xsl:template match="credit" mode="title-page">
    <xsl:text>[3\baselineskip]&#xa;</xsl:text>
    <xsl:text>{\Large </xsl:text>
    <xsl:apply-templates  select="." mode="title-full" />
    <xsl:text>}\\[0.5\baselineskip]&#xa;</xsl:text>
    <xsl:text>{\normalsize </xsl:text>
    <xsl:apply-templates select="author/personname" />
    <xsl:text>}\\</xsl:text>
    <xsl:if test="author/institution">
        <xsl:text>[0.25\baselineskip]&#xa;</xsl:text>
        <xsl:apply-templates select="author/institution" />
        <xsl:text>\\</xsl:text>
    </xsl:if>
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
    <xsl:if test="frontmatter/biography" >
        <!-- We kill the title, presuming placement is indicative enough -->
        <xsl:text>{\setlength{\parindent}{0pt}\setlength{\parskip}{4pt}</xsl:text>
        <xsl:apply-templates select="frontmatter/biography/*[not(self::title)]" />}
        <xsl:text>\par\vspace*{\stretch{2}}</xsl:text>
    </xsl:if>
    <xsl:text>\vspace*{\stretch{2}}&#xa;</xsl:text>
    <xsl:if test="frontmatter/colophon/edition" >
        <xsl:text>\noindent{\bf Edition}: </xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/edition" />
        <xsl:text>\par&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="frontmatter/colophon/website" />
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
    <!-- Something so page is not totally nothing -->
    <xsl:text>\null\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   copyright-page&#xa;</xsl:text>
</xsl:template>

<!-- Information about canonical project website -->
<xsl:template match="frontmatter/colophon/website" >
    <xsl:text>\noindent Website:\ \ \href{</xsl:text>
    <xsl:apply-templates select="address" />
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="name" />
    <xsl:text>}</xsl:text>
    <xsl:text>\par\medskip&#xa;</xsl:text>
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

<!-- ###################### -->
<!-- Front Matter, Articles -->
<!-- ###################### -->

<!-- The DTD should enforce order(titlepage|abstract) -->
<!-- An optional ToC follows and is final decoration  -->
<xsl:template match="article/frontmatter" mode="content-wrap">
    <xsl:param name="content" />
    <xsl:copy-of select="$content" />
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
</xsl:template>

<!-- Title information handling is a bit ad-hoc                        -->
<!-- We should perhaps roll-our-own here                               -->
<!-- Instead we assume the title-page-info-article has set *something* -->
<!-- NB: it is possible for there to be no article/title               -->
<xsl:template match="article/frontmatter/titlepage">
    <xsl:text>\maketitle&#xa;</xsl:text>
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

<xsl:template match="book/frontmatter" mode="content-wrap">
    <xsl:param name="content" />
    <!-- DTD: does the next line presume <frontmatter> is required? -->
    <xsl:text>\frontmatter&#xa;</xsl:text>
    <xsl:copy-of select="$content" />
    <xsl:text>%% begin: table of contents&#xa;</xsl:text>
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
    <xsl:param name="content" />
    <!-- first page, title only -->
    <xsl:apply-templates select="/mathbook/book" mode="half-title" />
    <!-- Obverse of half-title is adcard -->
    <xsl:apply-templates select="/mathbook/book" mode="ad-card" />
    <!-- title page -->
    <xsl:apply-templates select="/mathbook/book" mode="title-page" />
    <!-- title page obverse is copyright, possibly empty -->
    <xsl:apply-templates select="/mathbook/book" mode="copyright-page" />
</xsl:template>

<!-- The <colophon> portion of <frontmatter>  -->
<!-- generally gets mined to migrate          -->
<!-- various places, so we kill it as part of -->
<!-- processing the front matter element.     -->
<!-- See the summary being killed elsewhere   -->
<!-- NB: exsl:document() appears to not write -->
<!-- an empty file at all. We will not rely   -->
<!-- on this bad behavior, take no chances    -->
<!-- and thus kill the file-wrap also         -->
<xsl:template match="book/frontmatter/colophon" mode="content-wrap" />
<xsl:template match="book/frontmatter/colophon" mode="file-wrap" />

<!-- Preface, etc within \frontmatter is usually handled correctly by LaTeX -->
<!-- Allow alternative titles, like "Preface to 2nd Edition"                -->
<!-- But we use starred version anyway, so chapter headings react properly  -->
<!-- DTD: enforce order: dedication, acknowledgements, forewords, prefaces -->
<!-- TODO: add other frontmatter, move in title handling        -->
<!-- TODO: add to headers, currently just CONTENTS, check backmatter        -->
<xsl:template match="acknowledgement|foreword|preface" mode="content-wrap">
    <xsl:param name="content" />
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
    <xsl:copy-of select="$content" />
    <xsl:text>%% end:   </xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Dedication page is very plain, with a blank obverse     -->
<!-- Accomodates multiple recipient (eg if multiple authors) -->
<xsl:template match="dedication" mode="content-wrap">
    <xsl:param name="content" />
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
<!-- The "br" element may be used to break lines -->
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

<!-- Author biography migrates to the obverse of the   -->
<!-- copyright page in LaTeX, sans any provided title. -->
<!-- So we kill this part of the front matter as       -->
<!-- a section of its own.  (In HTML the material      -->
<!-- is its own titled division).                      -->
<xsl:template match="book/frontmatter/biography" mode="content-wrap" />
<xsl:template match="book/frontmatter/biography" mode="file-wrap" />

<!-- ##################### -->
<!-- Front Matter, Letters -->
<!-- ##################### -->

<xsl:template match="letter/frontmatter" mode="content-wrap">
    <xsl:param name="content" />
    <!-- Logos (letterhead images) immediately -->
    <xsl:apply-templates select="/mathbook/docinfo/logo" />
    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <!-- Push down some on first page to accomodate letterhead -->
    <xsl:text>\vspace*{0.75in}&#xa;</xsl:text>
    <!-- Stretchy vertical space if page 1 does not fill -->
    <xsl:text>\vspace*{\stretch{1}}&#xa;%&#xa;</xsl:text>
    <!-- Sender's address, sans name typically -->
    <!-- and if not already on letterhead -->
    <!-- http://tex.stackexchange.com/questions/13542/flush-a-left-flushed-box-right -->
    <xsl:if test="from or date">
        <xsl:text>\hfill\begin{tabular}{l@{}}&#xa;</xsl:text>
        <xsl:if test="from">
            <xsl:apply-templates select="from" />
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
    <xsl:if test="to">
        <xsl:text>\noindent{}</xsl:text>
        <xsl:apply-templates select="to" />
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

<!-- ################### -->
<!-- Front Matter, Memos -->
<!-- ################### -->

<xsl:template match="memo/frontmatter" mode="content-wrap">
    <xsl:param name="content" />
    <xsl:text>\thispagestyle{empty}&#xa;%&#xa;</xsl:text>
    <!-- Logos (letterhead images) to first page -->
    <xsl:apply-templates select="/mathbook/docinfo/logo" />
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
    <xsl:text>\textsf{To:}&amp;</xsl:text>
    <xsl:apply-templates select="to" /><xsl:text>\\&#xa;</xsl:text>
    <xsl:text>\textsf{From:}&amp;</xsl:text>
    <xsl:apply-templates select="from" /><xsl:text>\\&#xa;</xsl:text>
    <xsl:text>\textsf{Date:}&amp;</xsl:text>
    <xsl:apply-templates select="date" /><xsl:text>\\&#xa;</xsl:text>
    <xsl:text>\textsf{Subject:}&amp;</xsl:text>
    <xsl:apply-templates select="subject" /><xsl:text>&#xa;</xsl:text>
    <xsl:text>\end{tabular}%&#xa;</xsl:text>
    <xsl:text>}%&#xa;</xsl:text>
    <!-- And drop a bit -->
    <xsl:text>\par\bigskip&#xa;</xsl:text>
</xsl:template>

<!-- ############ -->
<!-- Back Matter -->
<!-- ############ -->

<!-- <backmatter> is structural -->
<!-- Noted in an book           -->
<!-- But not in an article      -->
<xsl:template match="article/backmatter" mode="content-wrap">
    <xsl:param name="content" />
    <xsl:copy-of select="$content" />
</xsl:template>

<xsl:template match="book/backmatter" mode="content-wrap">
    <xsl:param name="content" />
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\backmatter&#xa;</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:copy-of select="$content" />
</xsl:template>

<!--               -->
<!-- Notation List -->
<!--               -->

<!-- At location, we just drop a page marker -->
<xsl:template match="notation">
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="notation-list">
    <xsl:text>\begin{longtable}[l]{llr}&#xa;</xsl:text>
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

<!-- #################### -->
<!-- Back Matter, Letters -->
<!-- #################### -->

<xsl:template match="letter/backmatter" mode="content-wrap">
    <xsl:param name="content" />
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
        <xsl:apply-templates select="signature" />
        <xsl:text>&#xa;\end{tabular}&#xa;</xsl:text>
        <xsl:text>\hspace{\stretch{1}}&#xa;</xsl:text>
    </xsl:if>
    <!-- Stretchy vertical space, useful if still on page 1 -->
    <xsl:text>\par\vspace*{\stretch{2}}&#xa;%&#xa;</xsl:text>
</xsl:template>

<!-- ################## -->
<!-- Back Matter, Memos -->
<!-- ################## -->

<!-- TODO: add "cc" block like to/from -->
<xsl:template match="memo/backmatter" mode="content-wrap">
    <xsl:param name="content" />
</xsl:template>



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

<!-- Read the code and documentation for "chunking" in xsl/mathbook-common.html -->
<!-- This will explain document structure (not XML structure) and has the       -->
<!-- routines which call the necessary realizations of two abstract templates.  -->

<!-- Three modal templates accomodate all document structure nodes -->
<!-- and all possibilities for chunking.  Read the description     -->
<!-- in  xsl/mathbook-common.xsl to understand these.              -->

<xsl:template match="*" mode="structure-node-intermediate">
    <xsl:apply-templates select="*[not(self::title or self::subtitle or self::author)]" mode="structure-node-child-summary" />
</xsl:template>

<xsl:template match="*" mode="structure-node-child-summary">
    <xsl:variable name="structural"><xsl:apply-templates select="." mode="is-structural" /></xsl:variable>
    <xsl:choose>
        <xsl:when test="$structural='true'">
            <xsl:text>\input{</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>}</xsl:text>
            <!-- Annotate line with better information -->
            <xsl:text>  %% </xsl:text><xsl:apply-templates select="." mode="long-name" />
            <xsl:text>&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- <colophon> is structural, but never gets written directly -->
<!-- See empty "content-wrap" elsewhere                        -->
<xsl:template match="book/frontmatter/colophon" mode="structure-node-child-summary" />

<!-- Historically, latex processing writes to standard output as        -->
<!-- one entire file.  We can (and did briefly) define variants for     -->
<!-- top-level structural elements in order to preserve this behavior.  -->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="internal-id" />
        <xsl:text>.tex</xsl:text>
    </xsl:variable>
    <exsl:document href="{$filename}" method="text">
        <xsl:copy-of select="$content" />  <!-- below -->
    </exsl:document>
</xsl:template>

<!-- Subdivisions, Parts down to Subsubsections               -->
<!-- Mostly relies on element names echoing latex names       -->
<!-- (1) appendices are just chapters after \backmatter macro -->
<!-- (2) exercises, references can appear at any depth,       -->
<!--     so compute the subdivision name                      -->
<xsl:template match="*" mode="content-wrap">
    <xsl:param name="content" />
    <!-- appendices are peers of chapters (book) or sections (article) -->
    <!-- so we need to slip this in once when we can                   -->
    <xsl:if test="self::appendix and not(preceding-sibling::appendix)">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>\appendix&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="console-typeout" />
    <!-- Construct the header of the subdivision -->
    <xsl:text>\</xsl:text>
    <xsl:apply-templates select="." mode="subdivision-name" />
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
            <xsl:apply-templates select="." mode="title-full" />
            <xsl:text>}</xsl:text>
            <xsl:apply-templates select="." mode="label" />
            <xsl:text>&#xa;</xsl:text>
            <xsl:text>\addcontentsline{toc}{</xsl:text>
            <xsl:value-of select="local-name(.)" />
            <xsl:text>}{</xsl:text>
            <xsl:apply-templates select="." mode="title-simple" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[</xsl:text>
            <xsl:apply-templates select="." mode="title-simple"/>
            <xsl:text>]</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:apply-templates select="." mode="title-full"/>
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
    <xsl:copy-of select="$content" />
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
    <xsl:apply-templates select="." mode="console-typeout" />
    <xsl:text>\</xsl:text>
    <xsl:apply-templates select="." mode="subdivision-name" />
    <xsl:text>*{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::title)]" />
</xsl:template>

<!-- Spacing comes from division header above, subdivision header below -->
<xsl:template match="introduction">
    <xsl:apply-templates select="." mode="console-typeout" />
    <xsl:apply-templates select="*" />
</xsl:template>

<!-- Last subdivision just ends, presumably a \par is order -->
<!-- Some visual separation is a necessity, with no title   -->
<!-- "break" command is like also using a \par and encourages a page break     -->
<!-- http://tex.stackexchange.com/questions/41476/lengths-and-when-to-use-them -->
<xsl:template match="conclusion">
    <xsl:apply-templates select="." mode="console-typeout" />
    <xsl:text>\bigbreak&#xa;</xsl:text>
    <xsl:apply-templates select="*" />
</xsl:template>

<!-- Paragraphs -->
<!-- Non-structural, even if they appear to be -->
<!-- Note: Presumes we never go below subsubsection  -->
<!-- in our MBX hierarchy and bump into this level   -->
<!-- Maybe then migrate to "subparagraph"?           -->
<xsl:template match="paragraphs|paragraph">
    <!-- Warn about paragraph deprecation -->
    <xsl:if test="self::paragraph">
        <xsl:message>MBX:WARNING: the "paragraph" element is deprecated (2015/03/13), use "paragraphs" instead</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <xsl:apply-templates select="." mode="console-typeout" />
    <xsl:text>\paragraph</xsl:text>
    <!-- keep optional title if LaTeX source is re-purposed -->
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="." mode="title-simple" />
    <xsl:text>]</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::title)]" />
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

<!-- ######### -->
<!-- Exercises -->
<!-- ######### -->

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

<!-- Variant for free-range enclosing a WeBWorK problem -->
<xsl:template match="exercise[webwork]">
    <xsl:text>\begin{exercise}</xsl:text>
    <xsl:apply-templates select="title" mode="environment-option" />
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- Allow an exercise to introduce/connect a problem     -->
    <!-- (especially from server) to the text in various ways -->
    <!-- TODO: change statement to introduction, add conclusion -->
    <xsl:apply-templates select="statement"/>
    <xsl:apply-templates select="webwork" />
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
            <xsl:text>\begin{exercisegroup}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="not(preceding-sibling::exercise) and parent::exercises">
            <xsl:text>\begin{exerciselist}&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>\item[</xsl:text>
    <xsl:apply-templates select="." mode="serial-number" />
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
    <xsl:text>.}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>\quad&#xa;</xsl:text>
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


<!-- WeBWorK variants -->

<!-- Top-down structure -->
<!-- Basic outline of a simple problem -->
<xsl:template match="webwork">
    <xsl:text>\par&#xa;</xsl:text>
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="hint" />
    <xsl:apply-templates select="solution" />
</xsl:template>

<!-- Basic outline of a "scaffold" problem -->
<xsl:template match="webwork[@type='scaffold']">
    <xsl:apply-templates select="platform" />
</xsl:template>

<!-- A platform is part of a scaffold -->
<xsl:template match="platform">
    <!-- employ title here to identify different platforms -->
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="hint" />
    <xsl:apply-templates select="solution" />
</xsl:template>

<!-- KILLED -->
<xsl:template match="macros" />
<xsl:template match="setup" />

<!-- default template, for complete presentation -->
<xsl:template match="webwork//statement">
    <!-- <xsl:text>\textbf{Problem.}\quad </xsl:text> -->
    <xsl:apply-templates />
    <xsl:text>\par&#xa;</xsl:text>
</xsl:template>

<!-- default template, for solution -->
<xsl:template match="webwork//solution">
    <xsl:text>\par\noindent%&#xa;</xsl:text>
    <xsl:text>\textbf{Solution.}\quad </xsl:text>
    <xsl:apply-templates />
    <xsl:text>\par&#xa;</xsl:text>
</xsl:template>

<!-- default template, for hint -->
<xsl:template match="webwork//hint">
    <xsl:text>\par\noindent%&#xa;</xsl:text>
    <xsl:text>\textbf{Hint.}\quad </xsl:text>
    <xsl:apply-templates />
    <xsl:text>\par&#xa;</xsl:text>
</xsl:template>

<xsl:template match="statement//var|hint//var|solution//var">
    <xsl:variable name="problem" select="ancestor::webwork" />
    <xsl:variable name="varname" select="@name" />
    <xsl:choose>
        <xsl:when test="$problem/setup/var[@name=$varname]/elements">
        <xsl:for-each select="$problem/setup/var[@name=$varname]/elements/element[@correct='yes']">
            <xsl:apply-templates select='.' />
            <xsl:choose>
                <xsl:when test="count(following-sibling::element[@correct='yes']) &gt; 1">
                    <xsl:text>, </xsl:text>
                </xsl:when>
                <xsl:when test="(count(following-sibling::element[@correct='yes']) = 1) and preceding-sibling::element[@correct='yes']">
                    <xsl:text>, and </xsl:text>
                </xsl:when>
                <xsl:when test="(count(following-sibling::element[@correct='yes']) = 1) and not(preceding-sibling::element[@correct='yes'])">
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
<xsl:template match="statement//answer">
    <xsl:variable name="problem" select="ancestor::webwork" />
    <xsl:variable name="varname" select="@var" />
    <xsl:choose>
        <xsl:when test="@format='popup'" >
            <xsl:text>(Choose one: </xsl:text>
            <xsl:for-each select="$problem/setup/var[@name=$varname]/elements/element">
                <xsl:apply-templates select='.' />
                <xsl:choose>
                    <xsl:when test="count(following-sibling::element) &gt; 1">
                        <xsl:text>, </xsl:text>
                    </xsl:when>
                    <xsl:when test="(count(following-sibling::element) = 1) and preceding-sibling::element">
                        <xsl:text>, or </xsl:text>
                    </xsl:when>
                    <xsl:when test="(count(following-sibling::element) = 1) and not(preceding-sibling::element)">
                        <xsl:text> / </xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
            <xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:when test="@format='buttons'" >
            <xsl:text>\par&#xa;</xsl:text>
            <xsl:text>\begin{itemize}[label=$\bigcirc$,leftmargin=3em,]&#xa;</xsl:text>
            <xsl:for-each select="$problem/setup/var[@name=$varname]/elements/element">
                <xsl:text>\item{}</xsl:text>
                <xsl:apply-templates select='.' />
                <xsl:text>&#xa;</xsl:text>
            </xsl:for-each>
            <xsl:text>\end{itemize}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="@format='checkboxes'" >
            <xsl:text>\par&#xa;</xsl:text>
            <xsl:text>\begin{itemize}[label=$\square$,leftmargin=3em,]&#xa;</xsl:text>
            <xsl:for-each select="$problem/setup/var[@name=$varname]/elements/element">
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
            <xsl:text>em]{\strut}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- An essay answer has no associated variable              -->
<!-- We simply indicate that this is an essay answer problem -->
<xsl:template match="answer[@format='essay']">
    <xsl:text>\quad\lbrack Essay Answer\rbrack</xsl:text>
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
    <xsl:text>\begin{proof}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>&#xa;</xsl:text>
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

<!-- For a memo, not indenting the first paragraph helps -->
<!-- with alignment and the to/from/subject/date block   -->
<xsl:template match="memo/p[1]">
    <xsl:text>\noindent{}</xsl:text>
    <xsl:apply-templates />
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- ########################### -->
<!-- Mathematics (LaTeX/MathJax) -->
<!-- ########################### -->

<!-- Since MathJax interprets a large subset of LaTeX,   -->
<!-- there are only subtle differences between LaTeX     -->
<!-- and HTML output.  See LaTeX- and HTML-specific       -->
<!-- templates for intertext elements and the numbering   -->
<!-- of equations (automatic for LaTeX, managed for HTML) -->

<!-- Numbering -->
<!-- We do not tag equations with numbers in LaTeX output,               -->
<!-- but instead let the LaTeX preamble's configuration                  -->
<!-- options control the way numbers are generated and assigned.         -->
<!-- The combination of starred/un-starred LaTeX environments,            -->
<!-- and the presence of "\label{}", "\notag", or no such command,        -->
<!-- control the numbering in response to the number of levels specified. -->

<!-- NOTE -->
<!-- The remainder should look very similar to that  -->
<!-- of the HTML/MathJax version in terms of result. -->
<!-- Notably, "intertext" elements are implemented   -->
<!-- differently, and we need to be careful not to   -->
<!-- place LaTeX "\label{}" in know'ed content.      -->

<!-- Inline Math -->
<!-- See the common file for the universal "m" template -->

<!-- Displayed Math -->

<!-- Single displayed equation, unnumbered                         -->
<!-- Output follows source line breaks                             -->
<!-- MathJax: out-of-the-box support                               -->
<!-- LaTeX: with AMS-TeX, \[,\] tranlates to equation* environment -->
<!-- LaTeX: without AMS-TEX, it is improved version of $$, $$      -->
<!-- WeBWorK: allow for "var" element                              -->
<!-- See: http://tex.stackexchange.com/questions/40492/what-are-the-differences-between-align-equation-and-displaymath -->
<xsl:template match="me">
    <xsl:text>\[</xsl:text>
    <xsl:choose>
        <xsl:when test="ancestor::webwork">
            <xsl:apply-templates select="text()|var" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="text()" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\]</xsl:text>
</xsl:template>

<!-- Single displayed equation, numbered                  -->
<!-- MathJax: out-of-the-box support                      -->
<!-- LaTeX: with AMS-TeX, equation* environment supported -->
<!-- LaTeX: without AMS-TEX, $$ with equation numbering   -->
<!-- See link above, also.                                -->
<xsl:template match="men">
    <xsl:text>\begin{equation}</xsl:text>
    <xsl:value-of select="." />
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>\end{equation}</xsl:text>
</xsl:template>

<!-- Multi-Line Math -->
<!-- Multi-line displayed equations container, globally unnumbered or numbered   -->
<!-- mrow logic controls numbering, based on variant here, and per-row overrides -->
<!-- align environment if ampersands are present, gather environment otherwise   -->
<!-- Output follows source line breaks                                           -->
<xsl:template match="md">
    <xsl:choose>
        <xsl:when test="contains(., '&amp;') or contains(., '\amp')">
            <xsl:text>\begin{align*}&#xa;</xsl:text>
            <xsl:apply-templates select="mrow|intertext" />
            <xsl:text>\end{align*}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\begin{gather*}&#xa;</xsl:text>
            <xsl:apply-templates select="mrow|intertext" />
            <xsl:text>\end{gather*}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="mdn">
    <xsl:choose>
        <xsl:when test="contains(., '&amp;') or contains(., '\amp')">
            <xsl:text>\begin{align}&#xa;</xsl:text>
            <xsl:apply-templates select="mrow|intertext" />
            <xsl:text>\end{align}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\begin{gather}&#xa;</xsl:text>
            <xsl:apply-templates select="mrow|intertext" />
            <xsl:text>\end{gather}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Rows of a multi-line math display -->
<!-- Numbering controlled here with \label{}, \notag, or nothing -->
<!-- Last row different, has no line-break marker                -->
<!-- Limited exceptions to raw text only:                        -->
<!--     xref's allow for "reasons" in proofs                    -->
<!--     var is part of WeBWorK problems only                    -->
<xsl:template match="md/mrow">
    <xsl:choose>
        <xsl:when test="ancestor::webwork">
            <xsl:apply-templates select="text()|xref|var" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="text()|xref" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
        <xsl:when test="@number='yes'">
            <xsl:apply-templates select="." mode="label" />
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
    <xsl:if test="position()!=last()">
       <xsl:text>\\</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="mdn/mrow">
    <xsl:choose>
        <xsl:when test="ancestor::webwork">
            <xsl:apply-templates select="text()|xref|var" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="text()|xref" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
        <xsl:when test="@number='no'">
            <xsl:text>\notag</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="label" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="position()!=last()">
       <xsl:text>\\</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Intertext -->
<!-- An <mrow> will provide trailing newline, so do the same here -->
<xsl:template match="md/intertext|mdn/intertext">
    <xsl:text>\intertext{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>


<!-- ##### -->
<!-- Index -->
<!-- ##### -->

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

<!-- Lists -->
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
<xsl:template match="ol">
    <xsl:if test="not(ancestor::ol or ancestor::ul or ancestor::dl)">
        <xsl:apply-templates select="." mode="leave-vertical-mode" />
    </xsl:if>
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
    <xsl:if test="not(ancestor::ol or ancestor::ul or ancestor::dl)">
        <xsl:apply-templates select="." mode="leave-vertical-mode" />
    </xsl:if>
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
    <xsl:if test="not(ancestor::ol or ancestor::ul or ancestor::dl)">
        <xsl:apply-templates select="." mode="leave-vertical-mode" />
    </xsl:if>
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

<!-- In an ordered list, an item can be a target -->
<xsl:template match="ol/li">
    <xsl:text>\item</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:apply-templates />
</xsl:template>

<!-- We seperate the item from the content -->
<xsl:template match="ul/li">
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

<!-- Sometimes you need an "unbalanced" quotation make,    -->
<!-- maybe because you are crossing some other XML element -->
<!-- So here are left and right, single and double         -->
<xsl:template match="lsq">
    <xsl:text>`</xsl:text>
</xsl:template>

<xsl:template match="rsq">
    <xsl:text>'</xsl:text>
</xsl:template>

<xsl:template match="lq">
    <xsl:text>``</xsl:text>
</xsl:template>

<xsl:template match="rq">
    <xsl:text>''</xsl:text>
</xsl:template>

<!-- Actual Quotations                -->
<!-- TODO: <quote> element for inline -->
<xsl:template match="blockquote">
    <xsl:text>\begin{quote}</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{quote}</xsl:text>
</xsl:template>

<!-- Use at the end of a blockquote  -->
<!-- Single line, preceded by a dash -->
<xsl:template match="blockquote/attribution">
    <xsl:text>\\\hspace*{\stretch{1}}\textemdash\space{}</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- General-purpose attribution                           -->
<!-- At end of a preface or foreword, perhaps              -->
<!-- A table, pushed right, with left-justification        -->
<!-- <br> is overridden to be double-slash for tabular row -->
<xsl:template match="attribution">
    <xsl:text>\par\vspace{\baselineskip}&#xa;</xsl:text>
    <xsl:text>\hfill\begin{tabular}{l@{}}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>&#xa;\end{tabular}\\\par&#xa;</xsl:text>
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

<!-- Term (defined terms) -->
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

<!-- Chunks of Pre-Formatted Text                 -->
<!-- 100% analogue of LaTeX's verbatim            -->
<!-- environment or HTML's <pre> element          -->
<!-- Text is massaged just like Sage output code, -->
<!-- examining *all* lines to find left margin    -->
<xsl:template match="pre">
    <xsl:text>\begin{verbatim}&#xa;</xsl:text>
        <xsl:call-template name="sanitize-text-output">
            <xsl:with-param name="text" select="." />
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
    <xsl:text>\textless</xsl:text>
</xsl:template>

<!-- Greater Than -->
<xsl:template match="greater">
    <xsl:text>\textgreater</xsl:text>
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

<!-- Braces -->
<!-- Matched, as grouping -->
<xsl:template match="braces">
    <xsl:text>\{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\}</xsl:text>
</xsl:template>


<!-- Line Breaks -->
<!-- \newline works best in table cells in paragraph mode       -->
<!-- so as to not be confused with \\ at the end of a table row -->
<!-- but \\ is definitely better for multi-line main titles     -->
<!-- Use sparingly, e.g. for poetry, *not* in math environments -->
<!-- Must be in TeX's paragraph mode                            -->
<xsl:template match="br">
    <xsl:text>\newline{}</xsl:text>
</xsl:template>
<xsl:template match="title/br|subtitle/br|dedication/p/br|attribution/br">
    <xsl:text>\\</xsl:text>
</xsl:template>
<!-- Letters and memos use tabular to layout some blocks -->
<!-- these need a double-slash to cause a newline        -->
<xsl:template match="letter/frontmatter/from/br|letter/backmatter/signature/br">
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
    <xsl:call-template name="sanitize-code">
        <xsl:with-param name="raw-code" select="input" />
    </xsl:call-template>
    <xsl:text>\end{lstlisting}&#xa;</xsl:text>
</xsl:template>

<!-- Console Session -->
<!-- An interactive command-line session with a prompt, input and output -->
<xsl:template match="console">
    <!-- Grab all the characters, look for problems and warn -->
    <xsl:variable name="all-console-chars">
        <xsl:for-each select="prompt|input|output">
            <xsl:value-of select="." />
        </xsl:for-each>
    </xsl:variable>
    <!-- Look for problems and warn -->
    <xsl:if test="contains($all-console-chars, $console-macro)">
        <xsl:message>MBX:ERROR:   a console session contains the LaTeX character in use for starting a macro ("<xsl:value-of select="$console-macro" />") and your LaTeX is unlikely to compile.  So use the "latex.console.macro-char" parameter to set a different character, one not in use in any console session</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <xsl:if test="contains($all-console-chars, $console-begin)">
        <xsl:message>MBX:ERROR:   a console session contains the LaTeX character in use for starting a group ("<xsl:value-of select="$console-begin" />") and your LaTeX is unlikely to compile.  So use the "latex.console.begin-char" parameter to set a different character, one not in use in any console session</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <xsl:if test="contains($all-console-chars, $console-end)">
        <xsl:message>MBX:ERROR:   a console session contains the LaTeX character in use for ending a group ("<xsl:value-of select="$console-end" />") and your LaTeX is unlikely to compile.  So use the "latex.console.end-char" parameter to set a different character, one not in use in any console session</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <!-- ignore prompt, and pick it up in trailing input -->
    <xsl:text>\begin{console}&#xa;</xsl:text>
    <xsl:apply-templates select="input|output" />
    <xsl:text>\end{console}&#xa;</xsl:text>
</xsl:template>

<!-- match immediately preceding, only if a prompt:                   -->
<!-- https://www.oxygenxml.com/archives/xsl-list/199910/msg00541.html -->
<xsl:template match="console/input">
    <!-- newline after environment is necessary -->
    <!-- Assumes prompt does not exceed one line -->
    <xsl:apply-templates select="preceding-sibling::*[1][self::prompt]" />
    <!-- We substitute for the escape characters,    -->
    <!-- either within this input element, or within -->
    <!-- this console elemnet or document-wide       -->
    <!-- consoleinput macro defined in preamble      -->
    <xsl:value-of select="$console-macro" />
    <xsl:text>consoleinput</xsl:text>
    <xsl:value-of select="$console-begin" />
    <xsl:apply-templates />
    <xsl:value-of select="$console-end" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Output code gets massaged to remove a left margin, leading blank lines, etc. -->
<xsl:template match="console/output">
    <xsl:call-template name="sanitize-code">
        <xsl:with-param name="raw-code" select="." />
    </xsl:call-template>
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

<!-- Figures, (SideBySide), Tables and Listings are floats            -->
<!-- We try to fix their location with the [H] specifier, but         -->
<!-- if the first item of an AMS environment, they may float up       -->
<!-- Seems LaTeX is stacking boxes vertically, and we need to go to   -->
<!-- horizontal mode before doing these floating layout-type elements -->
<!-- http://tex.stackexchange.com/questions/22852/function-and-usage-of-leavevmode                       -->
<!-- Potential alternate solution: write a leading "empty" \mbox{}                                       -->
<!-- http://tex.stackexchange.com/questions/171220/include-non-floating-graphic-in-a-theorem-environment -->
<xsl:template match="*" mode="leave-vertical-mode">
    <xsl:text>\leavevmode%&#xa;</xsl:text>
</xsl:template>

<!-- Figures -->
<!-- Standard LaTeX figure environment redefined, see preamble comments -->
<xsl:template match="figure">
    <xsl:apply-templates select="." mode="leave-vertical-mode" />
    <xsl:text>\begin{figure}&#xa;</xsl:text>
    <xsl:text>\centering&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::caption)]"/>
    <xsl:apply-templates select="caption" />
    <xsl:text>\end{figure}&#xa;</xsl:text>
</xsl:template>

<!-- Listings -->
<!-- Standard LaTeX figure environment redefined, see preamble comments -->
<xsl:template match="listing">
    <xsl:apply-templates select="." mode="leave-vertical-mode" />
    <xsl:text>\begin{listing}&#xa;</xsl:text>
    <xsl:text>\centering&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::caption)]"/>
    <xsl:apply-templates select="caption" />
    <xsl:text>\end{listing}&#xa;</xsl:text>
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
    <xsl:apply-templates select="." mode="leave-vertical-mode" />
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
    <xsl:text>}%&#xa;</xsl:text>
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
    <xsl:text>}%&#xa;</xsl:text>
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
    <xsl:call-template name="sanitize-code">
        <xsl:with-param name="raw-code" select="." />
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
    <xsl:call-template name="sanitize-code">
        <xsl:with-param name="raw-code" select="." />
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
    <xsl:apply-templates select="." mode="leave-vertical-mode" />
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

<!-- Some utilities are defined in xsl/mathbook-common.xsl -->

<!-- "halign-specification" : param "width" -->
<!--     left, right, center -> l, c, r     -->

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


<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

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

<!-- This is the implementation of an abstract template, -->
<!-- using the LaTeX \ref and \label mechanism.          -->
<!-- We check that the item is numbered before dropping  -->
<!-- a \ref as part of the cross-reference               -->
<xsl:template match="*" mode="xref-number">
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:if test="not($the-number = '')">
        <xsl:text>\ref{</xsl:text>
        <xsl:apply-templates select="." mode="internal-id" />
        <xsl:text>}</xsl:text>
    </xsl:if>
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
<xsl:template match="exercises//exercise|biblio|note|proof|ol/li|hint|answer|solution" mode="xref-number">
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<!-- Footnotes print serial-numbers only, but   -->
<!-- as knowls/references we desire a fully     -->
<!-- qualified number.  So we just override the -->
<!-- visual version in a cross-reference,       -->
<!-- leaving the label/ref mechanism in place.  -->
<xsl:template match="fn" mode="xref-number">
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<!-- In common template, but have to point to it -->
<xsl:template match="exercisegroup" mode="xref-number">
    <xsl:apply-imports />
</xsl:template>


<!-- We implement every cross-reference with hyperref. -->
<!-- For pure print, we can turn off the actual links  -->
<!-- in the PDF (and/or control color etc)             -->
<!-- Mostly this is for consistency in the source      -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="content" />
    <xsl:text>\hyperref[</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$content" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- This is a nearly exact duplicate, which we could remove if we -->
<!-- reorganized xref-link to match on the xref and not its target -->
<!-- We wrap link text ($content) in \text{} since in math-mode    -->
<xsl:template match="*" mode="xref-link-md">
    <xsl:param name="content" />
    <xsl:text>\hyperref[</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>]{\text{</xsl:text>
    <xsl:value-of select="$content" />
    <xsl:text>}}</xsl:text>
</xsl:template>


<!-- We hard-code some numbers (sectional exercises) and      -->
<!-- we institute some numberings that LaTeX does not do      -->
<!-- naturally (references in extra sections, proofs,         -->
<!-- items in ordered lists (alone or in an exercise),        -->
<!-- hints, answers, solutions). For an exercise group we     -->
<!-- point to the introduction.  We make custom               -->
<!-- anchors/labels below and then we must point to           -->
<!-- them with \hyperlink{}{} (nee hyperref[]{}).             -->
<!-- (See also modal templates for "label" and "xref-number") -->
<xsl:template match="exercises//exercise|biblio|note|proof|ol/li|hint|answer|solution|exercisegroup" mode="xref-link">
    <xsl:param name="content" />
    <xsl:text>\hyperlink{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="$content" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Labels -->
<!-- The template to supply a LaTeX "\label{}" is provided -->
<!-- in the common file since it is employed in MathJax's  -->
<!-- equation labeling scheme, so find that there.         -->

<!-- We hard-code some numbers (sectional exercises) and          -->
<!-- we institute some numberings that LaTeX does not do          -->
<!-- naturally (references in extra sections, proofs,             -->
<!-- items in ordered lists (alone or in an exercise),            -->
<!-- hints, answers, solutions).  For a "label"                   -->
<!-- hyperref's hypertarget mechanism fits the bill.              -->
<!-- Removed the \null target text, as it was introducing         -->
<!-- vertical space when used in list items and it seems          -->
<!-- to now behave well without it  (2015-12-12)                  -->
<!-- (See also modal templates for "xref-link" and "xref-number") -->
<xsl:template match="exercises//exercise|biblio|note|proof|ol/li|hint|answer|solution" mode="label">
    <xsl:text>\hypertarget{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}{}</xsl:text>
</xsl:template>

<!-- Exercise groups are not even really numbered.   -->
<!-- (They inherit from their first/last exercises.) -->
<!-- We want to point to their introductions.        -->
<xsl:template match="exercisegroup" mode="label">
    <xsl:text>\hypertarget{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}{}</xsl:text>
</xsl:template>

<!--        -->
<!-- Poetry -->
<!--        -->
<!-- Basic support from the "verse" package -->

<!-- "poem" element loads verse package -->
<!-- width is percentage of text width -->
<!-- ie, "length" of longest line      -->
<xsl:template match="poem">
    <xsl:apply-templates select="title" />
    <xsl:text>\begin{verse}</xsl:text>
    <xsl:if test="@width">
        <xsl:text>[0.</xsl:text>
        <xsl:value-of select="@width" />
        <xsl:text>\linewidth]</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="stanza"/>
    <xsl:apply-templates select="author" />
    <xsl:text>\end{verse}&#xa;</xsl:text>
</xsl:template>

<!-- title *precedes* environment        -->
<!-- Starred versio suppresses ToC entry -->
<xsl:template match="poem/title">
    <xsl:text>\poemtitle*{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- End of a stanza is marked by last line   -->
<!-- We just add a visual break in the source -->
<xsl:template match="stanza">
    <xsl:apply-templates select="line" />
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- The last line of a stanza gets marked specially -->
<!-- Other lines are more normal                     -->
<xsl:template match="line">
    <xsl:apply-templates />
    <xsl:text>\\&#xa;</xsl:text>
</xsl:template>

<xsl:template match="line[not(following-sibling::*)]">
    <xsl:apply-templates />
    <xsl:text>\\!&#xa;</xsl:text>
</xsl:template>

<!-- attribution style for author at end -->
<!-- Abusing an extra stanza             -->
<xsl:template match="poem/author">
    <xsl:text>\nopagebreak{\hfill\footnotesize </xsl:text>
    <xsl:apply-templates />
    <xsl:text>}\\!&#xa;</xsl:text>
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
