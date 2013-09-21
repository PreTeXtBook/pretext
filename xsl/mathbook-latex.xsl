<?xml version='1.0'?> <!-- As XML file -->
<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace" >

<xsl:import href="./mathbook-common.xsl" />

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="text" />


<!-- Strip whitespace text nodes from container elements -->
<xsl:strip-space elements="article chapter section subsection" />

<!-- Whitespace control in text output mode-->
<!-- Forcing newlines with &#xa; : http://stackoverflow.com/questions/723226/producing-a-new-line-in-xslt -->
<!-- Avoiding extra whitespace: http://stackoverflow.com/questions/1468984/xslt-remove-whitespace-from-template -->

<xsl:template match="/" >
    <xsl:apply-templates />
</xsl:template>

<!-- An article, LaTeX structure -->
<xsl:template match="article">
    <xsl:text>\documentclass{article}&#xa;%&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:text>\begin{document}&#xa;%&#xa;</xsl:text>
    <xsl:text>\maketitle&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{document}&#xa;</xsl:text>
</xsl:template>

<!-- A book, LaTeX structure -->
<xsl:template match="book">
    <xsl:text>\documentclass{book}&#xa;%&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:text>\begin{document}&#xa;%&#xa;</xsl:text>
    <xsl:text>\frontmatter&#xa;%&#xa;</xsl:text>
    <xsl:call-template name="half-title" />
    <xsl:text>\maketitle&#xa;%&#xa;</xsl:text>
    <xsl:text>\tableofcontents&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates select="preface" />
    <xsl:text>\mainmatter&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates select="chapter" />
    <xsl:text>\backmatter&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates select="bibliography" />
    <xsl:text>\end{document}&#xa;</xsl:text>
</xsl:template>

<!-- LaTeX preamble is common for both books and articles-->
<xsl:template name="latex-preamble">
<xsl:text>%% Page layout
\usepackage{geometry}
\geometry{letterpaper,total={5.0in,9.0in}}
%% Symbols, align environment, bracket-matrix
\usepackage{amsmath}
\usepackage{amssymb}
%% Theorem-like environments
\usepackage{amsthm}
% theorem-like, italicized text
\theoremstyle{plain}
\newtheorem{theorem}{Theorem}
\newtheorem{corollary}{Corollary}
\newtheorem{lemma}{Lemma}
% definition-like, normal text
\theoremstyle{definition}
\newtheorem{definition}{Definition}
\newtheorem{example}{Example}
%% Sage input: boxed, colored
\usepackage{mdframed}
\usepackage[usenames,dvipsnames,svgnames,table]{xcolor}
%% Raster graphics inclusion, wapped figures in paragraphs
\usepackage{graphicx}
%% Hyperlinking in PDFs, all links solid and blue
\usepackage{hyperref}
\hypersetup{colorlinks=true,linkcolor=blue,citecolor=blue,filecolor=blue,urlcolor=blue}&#xa;</xsl:text>
<xsl:text>\hypersetup{pdftitle={</xsl:text>
<xsl:apply-templates select="title/node()" />
<xsl:text>}}</xsl:text>
<!--  -->
<xsl:text>%%
%% Convenience macros
</xsl:text>
<xsl:value-of select="docinfo/macros" /><xsl:text>&#xa;</xsl:text>
<!--  -->
<xsl:text>%% Title information&#xa;</xsl:text>
<xsl:text>\title{</xsl:text><xsl:apply-templates select="title/node()" /><xsl:text>}&#xa;</xsl:text>
<xsl:text>\author{</xsl:text><xsl:apply-templates select="docinfo/author" /><xsl:text>}&#xa;</xsl:text>
<xsl:text>\date{</xsl:text><xsl:apply-templates select="docinfo/date" /><xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- "half-title is leading page with title only          -->
<!-- at about 1:2 split, presumes in a book               -->
<!-- Series information could go on obverse               -->
<!-- and then do "thispagestyle" on both                  -->
<!-- These two pages contribute to frontmatter page count -->
<xsl:template name="half-title" >
    <xsl:text>% half-title&#xa;</xsl:text>
    <xsl:text>\pagestyle{empty}&#xa;</xsl:text>
    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <xsl:text>\begin{center}\Huge&#xa;</xsl:text>
    <xsl:apply-templates select="/book/title/node()" />
    <xsl:text>\end{center}\par&#xa;</xsl:text>
    <xsl:text>\vspace*{\stretch{2}}&#xa;</xsl:text>
    <xsl:text>\cleardoublepage&#xa;</xsl:text>
</xsl:template>


<!-- Author, one at titlepage -->
<!-- http://stackoverflow.com/questions/2817664/xsl-how-to-tell-if-element-is-last-in-series -->
<xsl:template match="author">
    <xsl:apply-templates select="personname" /><xsl:text>\\&#xa;</xsl:text>
    <xsl:apply-templates select="department" /><xsl:text>\\&#xa;</xsl:text>
    <xsl:apply-templates select="institution" /><xsl:text>\\&#xa;</xsl:text>
    <!-- TODO: Replace and test generic email template -->
    <xsl:text>\href{mailto:</xsl:text>
    <xsl:value-of select="email" />
    <xsl:text>}{\nolinkurl{</xsl:text>
    <xsl:value-of select="email" />
    <xsl:text>}}&#xa;</xsl:text>
    <xsl:if test="position() != last()" >
        <xsl:text>\and&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Preface, within \frontmatter is handled correctly by LaTeX-->
<xsl:template match="preface">
    <xsl:text>\chapter{Preface}&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Titles are handled specially                     -->
<!-- so get killed via apply-templates                -->
<!-- When needed, get content with XPath title/node() -->
<xsl:template match="title">
</xsl:template>
    
<!-- Chapters -->
<xsl:template match="chapter">
    <xsl:text>\typeout{************************************************}&#xa;</xsl:text>
    <xsl:text>\typeout{</xsl:text>
    <xsl:apply-templates select="." mode="long-name" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\typeout{************************************************}&#xa;</xsl:text>
    <xsl:text>\chapter{</xsl:text>
    <xsl:apply-templates select="title/node()" />
    <xsl:text>}&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Sections -->
<xsl:template match="section">
    <xsl:text>\typeout{++++++++++++++++++++++++++++++++++++++++++++++++}&#xa;</xsl:text>
    <xsl:text>\typeout{</xsl:text>
    <xsl:apply-templates select="." mode="basename" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\typeout{</xsl:text>
    <xsl:apply-templates select="." mode="long-name" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\typeout{++++++++++++++++++++++++++++++++++++++++++++++++}&#xa;</xsl:text>
    <xsl:text>\section{</xsl:text>
    <xsl:apply-templates select="title/node()" />
    <xsl:text>}&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates  />
</xsl:template>

<!-- Subsections -->
<xsl:template match="subsection">
    <xsl:text>\typeout{------------------------------------------------}&#xa;</xsl:text>
    <xsl:text>\typeout{</xsl:text>
    <xsl:apply-templates select="." mode="basename" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\typeout{</xsl:text>
    <xsl:apply-templates select="." mode="long-name" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\typeout{------------------------------------------------}&#xa;</xsl:text>
    <xsl:text>\subsection{</xsl:text>
    <xsl:apply-templates select="title/node()" />
    <xsl:text>}&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates />
</xsl:template>


<!-- Theorems, Proofs, Definitions, Examples -->

<!-- Theorems have statement/proof structure               -->
<!-- Definitions have notation, which is handled elsewhere -->
<!-- Examples have no additional structure                 -->
<!-- TODO: consider optional titles -->

<xsl:template match="theorem|corollary|lemma">
    <xsl:apply-templates select="statement|proof" />
</xsl:template>

<xsl:template match="definition">
    <xsl:apply-templates select="statement" />
</xsl:template>


<!-- Reorg?, consolidate following with local-namr() -->

<xsl:template match="theorem/statement">
    <xsl:text>\begin{theorem}</xsl:text>
    <xsl:apply-templates select=".." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="p"/>
    <xsl:text>\end{theorem}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="corollary/statement">
    <xsl:text>\begin{corollary}</xsl:text>
    <xsl:apply-templates select=".." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="p"/>
    <xsl:text>\end{corollary}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="lemma/statement">
    <xsl:text>\begin{lemma}</xsl:text>
    <xsl:apply-templates select=".." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="p"/>
    <xsl:text>\end{lemma}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="definition/statement">
    <xsl:text>\begin{definition}</xsl:text>
    <xsl:apply-templates select=".." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="p"/>
    <xsl:text>\end{definition}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="example">
    <xsl:text>\begin{example}</xsl:text>
    <xsl:apply-templates select=".." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="p|figure"/>
    <xsl:text>\end{example}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="notation">
    <xsl:text>Sample notation (in a master list eventually): \(</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\)\par&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="proof">
    <xsl:text>\begin{proof}&#xa;</xsl:text>
    <xsl:apply-templates select="p"/>
    <xsl:text>\end{proof}&#xa;%&#xa;</xsl:text>
</xsl:template>

<!-- Paragraphs  -->
<xsl:template match="p">
    <xsl:apply-templates />
    <xsl:text>\par&#xa;%&#xa;</xsl:text>
</xsl:template>


<!-- Math  -->
<!--       -->

<!-- Inline snippets -->
<xsl:template match= "m">
    <xsl:text>\(</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\)</xsl:text>
</xsl:template>

<!-- Unnumbered, single displayed equation -->
<xsl:template match="me">
    <xsl:text>\begin{displaymath}</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\end{displaymath}</xsl:text>
</xsl:template>

<!-- Numbered, single displayed equation -->
<!-- Possibly given a label              -->
<xsl:template match="men">
    <xsl:text>\begin{equation}</xsl:text>
    <xsl:value-of select="." />
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>\end{equation}</xsl:text>
</xsl:template>

<!-- Multi-line displayed equations container, globally unnumbered or numbered   -->
<!-- mrow logic controls numbering, based on variant here, and per-row overrides -->
<xsl:template match="md|mdn">
    <xsl:text>&#xa;%&#xa;\begin{align}</xsl:text>
    <xsl:apply-templates select="mrow" />
    <xsl:text>\end{align}&#xa;%&#xa;</xsl:text>
</xsl:template>

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
    <xsl:text>&#xa;\begin{enumerate}&#xa;</xsl:text>
    <xsl:apply-templates select="li" />
    <xsl:text>\end{enumerate}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="ul">
    <xsl:text>&#xa;\begin{itemize}&#xa;</xsl:text>
    <xsl:apply-templates select="li" />
    <xsl:text>\end{itemize}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="dl">
    <xsl:text>&#xa;\begin{description}&#xa;</xsl:text>
    <xsl:apply-templates select="li" />
    <xsl:text>\end{description}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="li">
    <xsl:text>\item </xsl:text>
    <xsl:apply-templates />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="dl/li">
    <xsl:text>\item</xsl:text>
    <xsl:apply-templates />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>
    
<!-- Description lists have titled elements -->
<!-- so no space after \item above          -->
<!-- and title must be first inside li      -->
<xsl:template match="dl/li/title">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates />
    <xsl:text>] </xsl:text>
</xsl:template>

<!-- Markup, typically within paragraphs -->
<!-- Quotes, regular or block -->
<xsl:template match="q">
    <xsl:text>``</xsl:text>
    <xsl:apply-templates />
    <xsl:text>''</xsl:text>
</xsl:template>

<xsl:template match="blockquote">
    <xsl:text>\begin{quote}</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{quote}</xsl:text>
</xsl:template>

<!-- Use at the end of a blockquote -->
<xsl:template match="blockquote/attribution">
    <xsl:text>\\\hspace*{\stretch{1}}{}---\ </xsl:text>
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
    <xsl:text>e.g.\ </xsl:text>
</xsl:template>

<!-- in other words -->
<xsl:template match="ie">
    <xsl:text>i.e.\ </xsl:text>
</xsl:template>

<!-- Implication Symbols -->
<!-- TODO: better names! -->
<xsl:template match="imply">
    <xsl:text>\(\Rightarrow\)</xsl:text>
</xsl:template>
<xsl:template match="implyreverse">
    <xsl:text>\(\Leftarrow\)</xsl:text>
</xsl:template>

<!-- TeX, LaTeX -->
<xsl:template match="latex">
    <xsl:text>\LaTeX{}</xsl:text>
</xsl:template>
<xsl:template match="tex">
    <xsl:text>\TeX{}</xsl:text>
</xsl:template>


<!-- Line Breaks -->
<!-- use sparingly, e.g. for poetry, not in math environments-->
<xsl:template match="br">
    <xsl:text>\\</xsl:text>
</xsl:template>    


<!-- Dashes -->
<!-- http://www.public.asu.edu/~arrows/tidbits/dashes.html -->
<xsl:template match="mdash">
    <xsl:text>---</xsl:text>
</xsl:template>
<xsl:template match="ndash">
    <xsl:text>--</xsl:text>
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
    <xsl:text>\begin{mdframed}[backgroundcolor=blue!10,skipabove=2ex,skipbelow=2ex]&#xa;</xsl:text>
    <xsl:text>\begin{verbatim}</xsl:text>
    <xsl:call-template name="trim-sage">
        <xsl:with-param name="sagecode" select="." />
    </xsl:call-template>
    <xsl:text>\end{verbatim}&#xa;</xsl:text>
    <xsl:text>\end{mdframed}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="output">
    <xsl:text>\begin{mdframed}[linecolor=white,leftmargin=4ex,skipbelow=2ex]&#xa;</xsl:text>
    <xsl:text>\begin{verbatim}</xsl:text>
    <xsl:call-template name="trim-sage">
        <xsl:with-param name="sagecode" select="." />
    </xsl:call-template>
    <xsl:text>\end{verbatim}&#xa;</xsl:text>
    <xsl:text>\end{mdframed}&#xa;%&#xa;</xsl:text>
</xsl:template>


<!-- Figures and Captions -->
<!-- http://tex.stackexchange.com/questions/2275/keeping-tables-figures-close-to-where-they-are-mentioned -->
<xsl:template match="figure">
    <xsl:text>\begin{figure}[!htbp]&#xa;</xsl:text>
    <xsl:text>\begin{center}&#xa;</xsl:text>
    <xsl:apply-templates select="p|image"/><xsl:text>&#xa;</xsl:text>
    <xsl:text>\end{center}&#xa;</xsl:text>
    <xsl:apply-templates select="caption" /><xsl:text>&#xa;</xsl:text>
    <xsl:text>\end{figure}&#xa;%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="caption">
    <xsl:text>\caption{</xsl:text>
    <xsl:apply-templates />
    <xsl:apply-templates select=".." mode="label"/>
    <xsl:text>}</xsl:text>
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


<!-- Cross-References -->
<!-- Point to bibliographic entries with cite -->
<!-- TODO: make citation references blue (not green box) in hyperref -->
<xsl:template match="cite">
    <xsl:text>\cite{</xsl:text><xsl:value-of select="@label" /><xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="xref">\ref{<xsl:value-of select="@label" />}</xsl:template>

<xsl:template match="*" mode="label">
    <xsl:if test="@xml:id">
        <xsl:text>\label{</xsl:text>
        <xsl:value-of select="@xml:id" />
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>


<!-- Bibliography -->

<!-- Enclosing structure of bibliography -->
<!-- TODO: Get number of last bibitem node for width parameter -->
<xsl:template match="bibliography">
    <xsl:text>\begin{thebibliography}{99}&#xa;%&#xa;</xsl:text>
    <xsl:apply-templates select="book|article" />
    <xsl:text>\end{thebibliography}&#xa;%&#xa;</xsl:text>
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

<xsl:template match="bibliography//pages">
    <xsl:text>, </xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Miscellaneous -->

<!-- TODO's get killed for finished work            -->
<!-- Highlight in a draft mode, or just grep source -->
<xsl:template match="todo"></xsl:template>


</xsl:stylesheet>