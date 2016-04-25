<?xml version='1.0'?>

<!-- This file is part of the book                 -->
<!--                                               -->
<!--   Abstract Algebra: Theory and Applications   -->
<!--                                               -->
<!-- Copyright (C) 1997-2014  Thomas W. Judson     -->
<!-- See the file COPYING for copying conditions.  -->

<!-- AATA customizations for ALL LaTeX runs of any type -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Assumes current file is in mathbook/user, so it must be copied there -->
<xsl:import href="../xsl/mathbook-latex.xsl" />
<!-- Assumes next file can be found in mathbook/user, so it must be copied there -->
<xsl:import href="aata-common.xsl" />

<!-- List Chapters and Sections in printed Table of Contents -->
<xsl:param name="toc.level" select="'2'" />

<!-- Exercises have "hint" and "solution"s -->
<!--   Hints: for a backmatter section     -->
<!--   Solutions: should not see them in   -->
<!--              any public print version -->
<xsl:param name="exercise.text.statement" select="'yes'" />
<xsl:param name="exercise.text.hint" select="'no'" />
<xsl:param name="exercise.backmatter.statement" select="'no'" />
<xsl:param name="exercise.backmatter.hint" select="'yes'" />

<!-- Formatting adjustments and overrides     -->
<!-- Named templates in case we want to       -->
<!-- change up preamble easily in an override -->

<!-- Bold and italic for terminology macro -->
<!-- http://tex.stackexchange.com/questions/46690/standard-order-for-bolditalic -->
<xsl:template name="aata-terminology">
	<xsl:text>% Definitions to bold italics&#xa;</xsl:text>
	<xsl:text>\renewcommand{\terminology}[1]%&#xa;</xsl:text>
	<xsl:text>{{\fontshape{\itdefault}\fontseries{\bfdefault}\selectfont #1\/}}&#xa;</xsl:text>
</xsl:template>

<!-- Proof to small caps -->
<!-- http://tex.stackexchange.com/questions/8089/changing-style-of-proof -->
<xsl:template name="aata-proof-heading">
	<xsl:text>% Proof environment with heading in small caps&#xa;</xsl:text>
	<xsl:text>\expandafter\let\expandafter\oldproof\csname\string\proof\endcsname&#xa;</xsl:text>
	<xsl:text>\let\oldendproof\endproof&#xa;</xsl:text>
	<xsl:text>\renewenvironment{proof}[1][\proofname]{\oldproof[\scshape #1]}{\oldendproof}&#xa;</xsl:text>
</xsl:template>

<xsl:template name="aata-historical-environment">
	<xsl:text>% Environment for Historical Notes&#xa;</xsl:text>
	<xsl:text>\setlength{\fboxrule}{0.5pt}&#xa;</xsl:text>
	<xsl:text>\newcommand{\drawbox}{\raisebox{3pt}{\framebox[0.3\textwidth]{\hspace*{1in}}}}</xsl:text>
	<xsl:text>\newenvironment{historicalnote}%&#xa;</xsl:text>
	<xsl:text>{\vskip 3ex \noindent \drawbox \hfill \hspace*{4pt}%&#xa;</xsl:text>
	<xsl:text>{\fontshape{\itdefault}\fontseries{\bfdefault}\selectfont{Historical Note}}&#xa;</xsl:text>
	<xsl:text>\hfill \drawbox \vskip 2ex}{}&#xa;</xsl:text>
</xsl:template>

<xsl:template name="aata-chapter-heading">
	<xsl:text>% RAB, 2010/06/17, 2014/10/14&#xa;</xsl:text>
	<xsl:text>% Slightly modified chapter heading adjustments&#xa;</xsl:text>
	<xsl:text>% makeSchapterhead is for starred version of \chapter&#xa;</xsl:text>
	<xsl:text>%&#xa;</xsl:text>
	<xsl:text>\makeatletter&#xa;</xsl:text>
	<xsl:text>%&#xa;</xsl:text>
	<xsl:text>\font\bigbolditalic=cmsl10 scaled\magstep5&#xa;</xsl:text>
	<xsl:text>\def\@makechapterhead#1{%\vspace*{50pt}&#xa;</xsl:text>
	<xsl:text>{ \parindent 0pt \centering% was\raggedright&#xa;</xsl:text>
	<xsl:text>\ifnum \c@secnumdepth >\m@ne\rule{0.4\textwidth}{.5pt}\hfill%&#xa;</xsl:text>
	<xsl:text>\raisebox{-.1in}{\fbox{\fbox{\bigbolditalic\thechapter\/}}}%&#xa;</xsl:text>
	<xsl:text>\hfill\rule{0.4\textwidth}{.5pt}\par%&#xa;</xsl:text>
	<xsl:text>%&#xa;</xsl:text>
	<xsl:text>\vskip 20pt \fi \Huge \bf #1\par%&#xa;</xsl:text>
	<xsl:text>\nobreak \vskip 40pt \framebox[\hsize]{\hspace*{1in}}}%&#xa;</xsl:text>
	<xsl:text>\vskip 36pt plus 12pt minus 6pt }%&#xa;</xsl:text>
	<xsl:text>%&#xa;</xsl:text>
	<xsl:text>\def\@makeschapterhead#1{%\vspace*{50pt}&#xa;</xsl:text>
	<xsl:text>{ \parindent 0pt \centering% was \raggedright&#xa;</xsl:text>
	<xsl:text>\hrule height .5pt\vspace{40pt}%&#xa;</xsl:text>
	<xsl:text>\huge \bf #1\par%&#xa;</xsl:text>
	<xsl:text>\nobreak \vskip 40pt \framebox[\hsize]{\hspace*{1in}}}%&#xa;</xsl:text>
	<xsl:text>\vskip 36pt plus 12pt minus 6pt }%&#xa;</xsl:text>
	<xsl:text>%&#xa;</xsl:text>
	<xsl:text>% \clearpage below was \cleardoublepage&#xa;</xsl:text>
	<xsl:text>\def\chapter{\clearpage \thispagestyle{plain} \global\@topnum\z@%&#xa;</xsl:text>
	<xsl:text>\@afterindentfalse \secdef\@chapter\@schapter}&#xa;</xsl:text>
	<xsl:text>%&#xa;</xsl:text>
	<xsl:text>\makeatother&#xa;</xsl:text>
	<xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- Stuff them into the preamble at the end -->
<xsl:param name="latex.preamble.late">
	<xsl:call-template name="aata-terminology" />
	<xsl:call-template name="aata-proof-heading" />
	<xsl:call-template name="aata-historical-environment" />
	<xsl:call-template name="aata-chapter-heading" />
</xsl:param>

<!-- We assume a common title so the template matches.       -->
<!-- These MUST be subsections and they must be the last     -->
<!-- subsection of a section, or else the numbering of other -->
<!-- subsections will be different when LaTeX auto-numbers   -->
<!-- NB: a call to "console-typeout" might be welcome here -->
<xsl:template match="subsection[title='Historical Note']" mode="content-wrap">
	<xsl:param name="content" />
	<xsl:text>\begin{historicalnote}&#xa;</xsl:text>
	<xsl:copy-of select="$content" />
	<xsl:text>\end{historicalnote}&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
