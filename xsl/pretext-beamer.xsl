<?xml version='1.0'?>

<!--********************************************************************
Copyright 2020 Oscar Levin, Andrew Rechnitzer, Steven Clontz, Robert A. Beezer

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

<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "./entities.ent">
    %entities;
]>

<!-- A "slideshow" realized as a LaTeX/Beamer presentation.            -->
<!--                                                                   -->
<!-- Modeled on the reveal.js conversion: import the full parent       -->
<!-- conversion (LaTeX), which supplies inline markup, mathematics,    -->
<!-- images, tables, programs, side-by-side, and so on.  Override      -->
<!-- the entry point and the structure ("slideshow", "section",        -->
<!-- "slide", "subslide"), pauses, and the block elements, which       -->
<!-- become native Beamer environments.                                -->
<!--                                                                   -->
<!-- Lists are implemented here, and NOT inherited: the LaTeX          -->
<!-- conversion's lists rely on the "enumitem" package, which          -->
<!-- interferes with Beamer's own list machinery (especially           -->
<!-- overlays); Beamer's native lists are used instead.                -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
>

<xsl:import href="./pretext-latex.xsl" />

<xsl:output method="text" indent="no" encoding="UTF-8"/>

<!-- The Beamer theme, an author/publisher choice.  A string parameter -->
<!-- until slideshow options mature in the publisher file.             -->
<xsl:param name="beamer.theme" select="'Boadilla'"/>

<!-- Blocks on slides never carry a LaTeX \label, so cross-reference -->
<!-- numbers are hard-coded rather than realized through \ref        -->
<xsl:variable name="b-latex-hardcode-numbers" select="true()"/>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Mirror the LaTeX conversion's entry template: warnings are     -->
<!-- computed on the original source, and we process the enhanced   -->
<!-- source produced by the assembly stylesheet (so generated       -->
<!-- images, WeBWorK representations, and their friends all exist). -->
<xsl:template match="/">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Conversion to Beamer presentations/slideshows is experimental&#xa;Requests for additional specific constructions welcome&#xa;Additional PreTeXt elements are subject to change</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="$original" mode="generic-warnings"/>
    <xsl:apply-templates select="$original" mode="element-deprecation-warnings"/>
    <xsl:apply-templates select="$original" mode="parameter-deprecation-warnings"/>
    <xsl:apply-templates select="$root"/>
</xsl:template>

<xsl:template match="/mathbook|/pretext">
    <xsl:apply-templates select="slideshow"/>
</xsl:template>

<!-- ################ -->
<!-- Document Shell   -->
<!-- ################ -->

<xsl:template match="slideshow">
    <xsl:call-template name="converter-blurb-latex" />
    <xsl:call-template name="beamer-preamble"/>
    <xsl:text>\begin{document}&#xa;&#xa;</xsl:text>
    <xsl:apply-templates select="frontmatter"/>
    <!-- an overview of the sections, when there are sections -->
    <xsl:if test="section">
        <xsl:text>\begin{frame}&#xa;</xsl:text>
        <xsl:text>\frametitle{</xsl:text>
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'toc'"/>
        </xsl:apply-templates>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\tableofcontents&#xa;</xsl:text>
        <xsl:text>\end{frame}&#xa;&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="section|slide"/>
    <xsl:text>\end{document}&#xa;</xsl:text>
</xsl:template>

<!-- ########### -->
<!-- Frontmatter -->
<!-- ########### -->

<!-- Title, subtitle, authors, event, date become Beamer's title -->
<!-- page material, on a plain frame.  An optional "abstract"    -->
<!-- follows on a frame of its own.                              -->
<xsl:template match="slideshow/frontmatter">
    <xsl:text>\title{</xsl:text>
    <xsl:apply-templates select="parent::slideshow" mode="title-full"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:if test="parent::slideshow/subtitle">
        <xsl:text>\subtitle{</xsl:text>
        <xsl:apply-templates select="parent::slideshow" mode="subtitle"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <!-- short form (names only) for theme footlines -->
    <xsl:text>\author[</xsl:text>
    <xsl:for-each select="$bibinfo/author">
        <xsl:apply-templates select="personname"/>
        <xsl:if test="following-sibling::author">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:for-each>
    <xsl:text>]{</xsl:text>
    <xsl:for-each select="$bibinfo/author">
        <xsl:apply-templates select="personname"/>
        <!-- assembly wraps a bare "institution" in an "affiliation" -->
        <xsl:if test="affiliation/institution|institution">
            <xsl:text>\\ {\small </xsl:text>
            <xsl:apply-templates select="(affiliation/institution|institution)[1]/node()"/>
            <xsl:text>}</xsl:text>
        </xsl:if>
        <xsl:if test="following-sibling::author">
            <xsl:text> \and </xsl:text>
        </xsl:if>
    </xsl:for-each>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\date{</xsl:text>
    <xsl:if test="$bibinfo/event">
        <xsl:apply-templates select="$bibinfo/event"/>
        <xsl:if test="$bibinfo/date">
            <xsl:text>\\ </xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$bibinfo/date">
        <xsl:apply-templates select="$bibinfo/date"/>
    </xsl:if>
    <xsl:text>}&#xa;&#xa;</xsl:text>
    <xsl:text>\begin{frame}[plain]&#xa;</xsl:text>
    <xsl:text>\titlepage&#xa;</xsl:text>
    <xsl:text>\end{frame}&#xa;&#xa;</xsl:text>
    <xsl:apply-templates select="abstract"/>
</xsl:template>

<xsl:template match="slideshow/frontmatter/abstract">
    <xsl:text>\begin{frame}&#xa;</xsl:text>
    <xsl:text>\frametitle{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{frame}&#xa;&#xa;</xsl:text>
</xsl:template>

<!-- ######################## -->
<!-- Sections, Slides, Pauses -->
<!-- ######################## -->

<!-- A "section" is a Beamer section (navigation, table of contents) -->
<!-- with a section-title frame, as in the reveal.js conversion.     -->
<xsl:template match="slideshow/section">
    <xsl:text>&#xa;\section{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\begin{frame}&#xa;</xsl:text>
    <xsl:text>\sectionpage&#xa;</xsl:text>
    <xsl:text>\end{frame}&#xa;&#xa;</xsl:text>
    <xsl:apply-templates select="slide"/>
</xsl:template>

<!-- A "slide" is a frame.  A frame whose content includes anything  -->
<!-- realized through the "listings" package (or other verbatim-like -->
<!-- material) must be marked "fragile".                             -->
<xsl:template match="slide">
    <xsl:text>\begin{frame}</xsl:text>
    <xsl:if test="descendant::program or descendant::console or descendant::sage or descendant::cd or descendant::pre">
        <xsl:text>[fragile]</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\frametitle{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{frame}&#xa;&#xa;</xsl:text>
</xsl:template>

<!-- A "subslide" is material that appears, as one group, after an   -->
<!-- advance of the slideshow.  Beamer's \pause would also suppress   -->
<!-- everything *after* the group, but material following a subslide  -->
<!-- is visible from the outset (as with reveal.js "fragments"), so   -->
<!-- we uncover the group on the next pause step and leave the        -->
<!-- surroundings alone.                                              -->
<xsl:template match="subslide">
    <xsl:text>\uncover&lt;+(1)-&gt;{%&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}%&#xa;</xsl:text>
</xsl:template>

<!-- A paragraph may pause before it appears; identical device -->
<xsl:template match="slide//p[@pause = 'yes']">
    <xsl:text>\uncover&lt;+(1)-&gt;{%&#xa;</xsl:text>
    <xsl:apply-imports/>
    <xsl:text>}%&#xa;</xsl:text>
</xsl:template>

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Beamer's native lists, since the inherited lists rely on the  -->
<!-- "enumitem" package, which fights Beamer.  A list with pauses  -->
<!-- gets the incremental default overlay specification, item by   -->
<!-- item, matching the reveal.js conversion's fragments.          -->

<!-- An "ol" marker passes through as a Beamer "mini-template",  -->
<!-- where the characters A, a, I, i, 1 are the counter formats, -->
<!-- consonant with PreTeXt marker conventions                   -->
<xsl:template match="slide//ol">
    <xsl:call-template name="begin-list-columns"/>
    <xsl:text>\begin{enumerate}</xsl:text>
    <xsl:if test="@pause = 'yes'">
        <xsl:text>[&lt;+-&gt;]</xsl:text>
    </xsl:if>
    <xsl:if test="@marker">
        <xsl:text>[</xsl:text>
        <xsl:value-of select="@marker"/>
        <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="li"/>
    <xsl:text>\end{enumerate}&#xa;</xsl:text>
    <xsl:call-template name="end-list-columns"/>
</xsl:template>

<xsl:template match="slide//ul">
    <xsl:call-template name="begin-list-columns"/>
    <xsl:text>\begin{itemize}</xsl:text>
    <xsl:if test="@pause = 'yes'">
        <xsl:text>[&lt;+-&gt;]</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="li"/>
    <xsl:text>\end{itemize}&#xa;</xsl:text>
    <xsl:call-template name="end-list-columns"/>
</xsl:template>

<xsl:template match="slide//dl">
    <xsl:text>\begin{description}</xsl:text>
    <xsl:if test="@pause = 'yes'">
        <xsl:text>[&lt;+-&gt;]</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="li"/>
    <xsl:text>\end{description}&#xa;</xsl:text>
</xsl:template>

<!-- Multiple columns via the "multicol" package (in the preamble) -->
<xsl:template name="begin-list-columns">
    <xsl:if test="@cols and (@cols != 1)">
        <xsl:text>\begin{multicols}{</xsl:text>
        <xsl:value-of select="@cols"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template name="end-list-columns">
    <xsl:if test="@cols and (@cols != 1)">
        <xsl:text>\end{multicols}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="slide//ol/li|slide//ul/li">
    <xsl:text>\item{}</xsl:text>
    <xsl:if test="title">
        <xsl:text> \ptxlititle{</xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>}\par</xsl:text>
    </xsl:if>
    <xsl:text> </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- The title becomes Beamer's description label -->
<xsl:template match="slide//dl/li">
    <xsl:text>\item[</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>] </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ###### -->
<!-- Blocks -->
<!-- ###### -->

<!-- Blocks become native Beamer environments, which the theme      -->
<!-- styles.  Beamer predefines "definition", "theorem",            -->
<!-- "corollary", "lemma", "fact", "example", "proof" and the       -->
<!-- generic titled "block".  Blocks are not numbered on slides.    -->

<xsl:template match="&DEFINITION-LIKE;" priority="1">
    <xsl:call-template name="beamer-environment">
        <xsl:with-param name="environment" select="'definition'"/>
    </xsl:call-template>
</xsl:template>

<xsl:template match="theorem|corollary|lemma|fact" priority="1">
    <xsl:call-template name="beamer-environment">
        <xsl:with-param name="environment" select="local-name(.)"/>
    </xsl:call-template>
</xsl:template>

<xsl:template match="&EXAMPLE-LIKE;" priority="1">
    <xsl:call-template name="beamer-environment">
        <xsl:with-param name="environment" select="'example'"/>
    </xsl:call-template>
</xsl:template>

<!-- Everything else theorem-ish, plus remarks and asides, is a -->
<!-- generic Beamer "block" headed by its type-name and title   -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&ASIDE-LIKE;|&GOAL-LIKE;|assemblage">
    <xsl:text>\begin{block}{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:if test="title">
        <xsl:text>: </xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(&PROOF-FILTER;)]"/>
    <xsl:text>\end{block}&#xa;</xsl:text>
    <xsl:apply-templates select="&PROOF-LIKE;"/>
</xsl:template>

<!-- The common core: the environment, an optional title in the   -->
<!-- optional argument, the guts, and any proof following outside -->
<xsl:template name="beamer-environment">
    <xsl:param name="environment"/>
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="$environment"/>
    <xsl:text>}</xsl:text>
    <xsl:if test="title">
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(&PROOF-FILTER;)]"/>
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="$environment"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="&PROOF-LIKE;"/>
</xsl:template>

<xsl:template match="&PROOF-LIKE;">
    <xsl:text>\begin{proof}&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{proof}&#xa;</xsl:text>
</xsl:template>

<!-- "statement" is a pure container in this context -->
<xsl:template match="statement">
    <xsl:apply-templates/>
</xsl:template>

<!-- Metadata of blocks, handled elsewhere or meaningless on a slide -->
<xsl:template match="notation"/>

<!-- ####### -->
<!-- Figures -->
<!-- ####### -->

<!-- The LaTeX conversion realizes captioned items through generated  -->
<!-- environments of its styling scheme, which Beamer does not carry. -->
<!-- On a slide there is no numbering, so a caption or title is just  -->
<!-- a small centered legend after the content.                       -->
<xsl:template match="&FIGURE-LIKE;" priority="1">
    <xsl:text>\begin{center}&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::caption)]"/>
    <xsl:choose>
        <xsl:when test="caption">
            <xsl:text>\par\smallskip{}{\small{}</xsl:text>
            <xsl:apply-templates select="caption/node()"/>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="title">
            <xsl:text>\par\smallskip{}{\small{}</xsl:text>
            <xsl:apply-templates select="." mode="title-full"/>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise/>
    </xsl:choose>
    <xsl:text>\end{center}&#xa;</xsl:text>
</xsl:template>

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- The content of a cross-reference is computed by the -common     -->
<!-- machinery; on a slide we do not make it a hyperlink, since the  -->
<!-- likely target is a nearby slide with no useful anchor in a PDF. -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="target"/>
    <xsl:param name="content"/>
    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- Every number in a cross-reference is hard-coded: no block on a  -->
<!-- slide carries a LaTeX \label, so \ref has nothing to resolve.   -->
<xsl:template match="*" mode="xref-number">
    <xsl:param name="xref" select="/.." />
    <xsl:apply-templates select="." mode="xref-number-hardcoded">
        <xsl:with-param name="xref" select="$xref"/>
    </xsl:apply-templates>
</xsl:template>

<!-- ######## -->
<!-- Preamble -->
<!-- ######## -->

<!-- N.B. Portions of this preamble duplicate fragments of the LaTeX -->
<!-- conversion's preamble, since the inherited content templates    -->
<!-- presume supporting macros and environments ("sidebyside" and    -->
<!-- "sbspanel", "program", "console", "sageinput"/"sageoutput",     -->
<!-- semantic macros).  The "image" and tabular support comes from   -->
<!-- the shared preamble pieces; the remaining fragments await       -->
<!-- pieces that do not presume the regular conversion's styling     -->
<!-- hooks (such as \blocktitlefont and \ptxsetparstyle).               -->
<xsl:template name="beamer-preamble">
    <xsl:text>\documentclass[11pt, compress]{beamer}&#xa;</xsl:text>
    <xsl:if test="$latex.preamble.early != ''">
        <xsl:text>%% Custom Preamble Entries, early (use latex.preamble.early)&#xa;</xsl:text>
        <xsl:value-of select="$latex.preamble.early" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\usetheme{</xsl:text>
    <xsl:value-of select="$beamer.theme"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\usefonttheme[onlymath]{serif}&#xa;</xsl:text>
    <xsl:text>%% quash navigation symbols&#xa;</xsl:text>
    <xsl:text>\setbeamertemplate{navigation symbols}{}&#xa;</xsl:text>
    <xsl:text>%% every "section" gets a section-title frame via \sectionpage&#xa;</xsl:text>
    <xsl:text>&#xa;%%%% Start PreTeXt generated preamble %%%%&#xa;&#xa;</xsl:text>
    <xsl:text>\usepackage{amsmath}&#xa;</xsl:text>
    <xsl:text>%% fonts: the inherited templates emit T1-encoded glyph names&#xa;</xsl:text>
    <xsl:text>%% (such as \textquotedbl), so match the LaTeX conversion's setup&#xa;</xsl:text>
    <xsl:text>\ifPDFTeX&#xa;</xsl:text>
    <xsl:text>\usepackage[T1]{fontenc}&#xa;</xsl:text>
    <xsl:text>\else&#xa;</xsl:text>
    <xsl:text>\usepackage{fontspec}&#xa;</xsl:text>
    <xsl:text>\fi&#xa;</xsl:text>
    <xsl:text>%% Some aspects of the preamble are conditional,&#xa;</xsl:text>
    <xsl:text>%% the LaTeX engine is one such determinant&#xa;</xsl:text>
    <xsl:text>\usepackage{ifthen}&#xa;</xsl:text>
    <xsl:text>\newcommand{\tabularfont}{}&#xa;</xsl:text>
    <xsl:text>\usepackage[xparse, raster]{tcolorbox}&#xa;</xsl:text>
    <xsl:text>\tcbset{colback=white, colframe=white}&#xa;</xsl:text>
    <xsl:text>%% tcolorbox styles used by images and side-by-side panels&#xa;</xsl:text>
    <xsl:text>\tcbset{ bwminimalstyle/.style={size=minimal, boxrule=-0.3pt, frame empty,&#xa;</xsl:text>
    <xsl:text>colback=white, colbacktitle=white, coltitle=black, opacityfill=0.0} }&#xa;</xsl:text>
    <!-- The shared "tcolorbox" environment for a single image -->
    <xsl:call-template name="image-tcolorbox"/>
    <xsl:if test="$document-root//ol[@cols]|$document-root//ul[@cols]">
        <xsl:text>%% Multiple column lists&#xa;</xsl:text>
        <xsl:text>\usepackage{multicol}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$b-has-program or $b-has-console or $b-has-sage">
        <xsl:text>%% Program listing support: for listings, programs, consoles, and Sage code&#xa;</xsl:text>
        <xsl:text>\ifthenelse{\boolean{xetex} \or \boolean{luatex}}%&#xa;</xsl:text>
        <xsl:text>  {\tcbuselibrary{listings}}%&#xa;</xsl:text>
        <xsl:text>  {\tcbuselibrary{listingsutf8}}%&#xa;</xsl:text>
        <xsl:text>%% A null language, free of any formatting or style&#xa;</xsl:text>
        <xsl:text>\lstdefinelanguage{none}{identifierstyle=,commentstyle=,stringstyle=,keywordstyle=}&#xa;</xsl:text>
        <xsl:if test="$b-has-program">
            <xsl:text>%% Colors match a subset of Google prettify "Default" style&#xa;</xsl:text>
            <xsl:text>\definecolor{identifiers}{rgb}{0.375,0,0.375}&#xa;</xsl:text>
            <xsl:text>\definecolor{comments}{rgb}{0.5,0,0}&#xa;</xsl:text>
            <xsl:text>\definecolor{strings}{rgb}{0,0.5,0}&#xa;</xsl:text>
            <xsl:text>\definecolor{keywords}{rgb}{0,0,0.5}&#xa;</xsl:text>
            <xsl:text>\lstdefinestyle{programcodestyle}{identifierstyle=\color{identifiers},commentstyle=\color{comments},stringstyle=\color{strings},keywordstyle=\color{keywords}, breaklines=true, breakatwhitespace=true, columns=fixed, extendedchars=true, aboveskip=0pt, belowskip=0pt}&#xa;</xsl:text>
            <xsl:text>\lstdefinestyle{programcodenumberedstyle}{style=programcodestyle, numbers=left}&#xa;</xsl:text>
            <xsl:text>\tcbset{ programboxstyle/.style={left=3ex, right=0pt, top=0ex, bottom=0ex, middle=0pt, toptitle=0pt, bottomtitle=0pt, boxsep=0pt, &#xa;</xsl:text>
            <xsl:text>listing only, fontupper=\small\ttfamily,&#xa;</xsl:text>
            <xsl:text>colback=white, sharp corners, boxrule=-0.3pt, leftrule=0.5pt,&#xa;</xsl:text>
            <xsl:text>parbox=false,&#xa;</xsl:text>
            <xsl:text>} }&#xa;</xsl:text>
            <xsl:text>\tcbset{ programboxnumberedstyle/.style={programboxstyle, left=6ex} }&#xa;</xsl:text>
            <xsl:text>%% Arguments: language, left margin, width, right margin (latter ignored)&#xa;</xsl:text>
            <xsl:text>\newtcblisting{program}[4]{programboxstyle, left skip=#2\linewidth, width=#3\linewidth, listing options={language=#1, style=programcodestyle}}&#xa;</xsl:text>
            <xsl:text>\newtcblisting{programnumbered}[4]{programboxnumberedstyle, left skip=#2\linewidth, width=#3\linewidth, listing options={language=#1, style=programcodenumberedstyle}}&#xa;</xsl:text>
            <xsl:text>\newcommand{\ptxprogramfragment}[2]{\lstinline[language=#1, style=programcodestyle, basicstyle=\ttfamily]#2}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$b-has-console">
            <xsl:text>%% Console session with prompt, input, output&#xa;</xsl:text>
            <xsl:text>\newcommand{\ptxconsoleinput}[1]{\textbf{#1}}&#xa;</xsl:text>
            <xsl:text>\lstdefinestyle{consolecodestyle}{language=none, escapeinside={(*}{*)}, identifierstyle=, commentstyle=, stringstyle=, keywordstyle=, breaklines=false, breakatwhitespace=false, columns=fixed, extendedchars=true, aboveskip=0pt, belowskip=0pt}&#xa;</xsl:text>
            <xsl:text>\tcbset{ consoleboxstyle/.style={left=0pt, right=0pt, top=0ex, bottom=0ex, middle=0pt, toptitle=0pt, bottomtitle=0pt, boxsep=0pt,&#xa;</xsl:text>
            <xsl:text>listing only, fontupper=\small\ttfamily,&#xa;</xsl:text>
            <xsl:text>colback=white, boxrule=-0.3pt,&#xa;</xsl:text>
            <xsl:text>parbox=false,&#xa;</xsl:text>
            <xsl:text>} }&#xa;</xsl:text>
            <xsl:text>%% Arguments: left margin, width, right margin (latter ignored)&#xa;</xsl:text>
            <xsl:text>\newtcblisting{console}[3]{consoleboxstyle, left skip=#1\linewidth, width=#2\linewidth, listing options={style=consolecodestyle}}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$b-has-sage">
            <xsl:text>%% The listings package as tcolorbox for Sage code&#xa;</xsl:text>
            <xsl:text>\definecolor{sageblue}{HTML}{</xsl:text><xsl:value-of select="$sage-input-background"/><xsl:text>}&#xa;</xsl:text>
            <xsl:text>\tcbset{ sagestyle/.style={left=0pt, right=0pt, top=0ex, bottom=0ex, middle=0pt, toptitle=0pt, bottomtitle=0pt,&#xa;</xsl:text>
            <xsl:text>boxsep=4pt, listing only, fontupper=\small\ttfamily,&#xa;</xsl:text>
            <xsl:text>parbox=false, &#xa;</xsl:text>
            <xsl:text>listing options={language=Python,breaklines=true,breakatwhitespace=true, extendedchars=true, aboveskip=0pt, belowskip=0pt}} }&#xa;</xsl:text>
            <xsl:text>\newtcblisting{sageinput}{sagestyle, colback=sageblue, sharp corners, boxrule=0.5pt, }&#xa;</xsl:text>
            <xsl:text>\newtcblisting{sageoutput}{sagestyle, colback=white, colframe=white, frame empty, before skip=0pt, after skip=0pt, }&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$document-root//sidebyside">
        <xsl:text>%% tcolorbox styles for sidebyside layout&#xa;</xsl:text>
        <xsl:text>\tcbset{ sbsstyle/.style={raster before skip=2.0ex, raster equal height=rows, raster force size=false} }&#xa;</xsl:text>
        <xsl:text>\tcbset{ sbspanelstyle/.style={bwminimalstyle} }&#xa;</xsl:text>
        <xsl:text>%% "xparse" environment for entire sidebyside&#xa;</xsl:text>
        <xsl:text>\NewDocumentEnvironment{sidebyside}{mmmm}&#xa;</xsl:text>
        <xsl:text>  {\begin{tcbraster}&#xa;</xsl:text>
        <xsl:text>    [sbsstyle,raster columns=#1,&#xa;</xsl:text>
        <xsl:text>    raster left skip=#2\linewidth,raster right skip=#3\linewidth,raster column skip=#4\linewidth]}&#xa;</xsl:text>
        <xsl:text>  {\end{tcbraster}}&#xa;</xsl:text>
        <xsl:text>%% "tcolorbox" environment for a panel of sidebyside&#xa;</xsl:text>
        <xsl:text>\NewTColorBox{sbspanel}{mO{top}}{sbspanelstyle,width=#1\linewidth,valign=#2}&#xa;</xsl:text>
    </xsl:if>
    <!-- The shared table support: rules, column types, and the       -->
    <!-- "tabularbox" that the inherited "tabular" templates rely on  -->
    <xsl:call-template name="tables"/>
    <xsl:text>\newcommand{\lt}{&lt;}&#xa;</xsl:text>
    <xsl:text>\newcommand{\gt}{&gt;}&#xa;</xsl:text>
    <xsl:text>\newcommand{\amp}{&amp;}&#xa;</xsl:text>
    <xsl:text>%% Begin: Semantic Macros&#xa;</xsl:text>
    <xsl:text>\newcommand{\ptxmono}[1]{\texttt{#1}}&#xa;</xsl:text>
    <xsl:variable name="one-line-reps" select="
        ($document-root//abbr)[1]|
        ($document-root//acro)[1]|
        ($document-root//init)[1]"/>
    <xsl:for-each select="$one-line-reps">
        <xsl:apply-templates select="." mode="tex-macro"/>
    </xsl:for-each>
    <xsl:if test="$document-root//alert">
        <!-- Beamer has its own theme-aware, overlay-capable \alert, -->
        <!-- so the PreTeXt semantic macro is realized through it    -->
        <xsl:text>\newcommand{\ptxalert}[1]{\alert{#1}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//term">
        <xsl:text>\newcommand{\ptxterminology}[1]{\textbf{#1}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//pubtitle">
        <xsl:text>\newcommand{\ptxpubtitle}[1]{\textsl{#1}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//fillin[not(parent::m or parent::me or parent::men or parent::mrow)]">
        <xsl:call-template name="fillin-text"/>
    </xsl:if>
    <xsl:if test="$document-root//m/fillin|$document-root//me/fillin|$document-root//men/fillin|$document-root//mrow/fillin">
        <xsl:call-template name="fillin-math"/>
    </xsl:if>
    <xsl:if test="$document-root//swungdash">
        <xsl:text>\newcommand{\ptxswungdash}{\raisebox{-2.25ex}{\scalebox{2}{\~{}}}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//quantity">
        <xsl:text>%% Used for units and number formatting&#xa;</xsl:text>
        <xsl:text>\usepackage[per-mode=fraction]{siunitx}&#xa;</xsl:text>
        <xsl:text>\sisetup{inter-unit-product=\cdot}&#xa;</xsl:text>
        <xsl:text>\ifxetex\sisetup{math-micro=\text{µ},text-micro=µ}\fi&#xa;</xsl:text>
        <xsl:text>\ifluatex\sisetup{math-micro=\text{µ},text-micro=µ}\fi&#xa;</xsl:text>
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
    <xsl:if test="$document-root//case[@direction]">
        <xsl:text>%% Arrows for iff proofs, with trailing space&#xa;</xsl:text>
        <xsl:text>\newcommand{\ptxforwardimplication}{($\Rightarrow$)}&#xa;</xsl:text>
        <xsl:text>\newcommand{\ptxbackwardimplication}{($\Leftarrow$)}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//ol/li/title|$document-root//ul/li/title">
        <xsl:text>%% Style of a title on a list item, for ordered and unordered lists&#xa;</xsl:text>
        <xsl:text>\newcommand{\ptxlititle}[1]{{\slshape#1}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//xref">
        <xsl:text>%% Font for cross-reference numbers, a no-op on slides&#xa;</xsl:text>
        <xsl:text>\newcommand{\xreffont}{}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% End: Semantic Macros&#xa;</xsl:text>
    <xsl:if test="$latex.preamble.late != ''">
        <xsl:text>%% Custom Preamble Entries, late (use latex.preamble.late)&#xa;</xsl:text>
        <xsl:value-of select="$latex.preamble.late" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$docinfo/macros">
        <xsl:text>%% Custom macros (docinfo/macros)&#xa;</xsl:text>
        <xsl:value-of select="$docinfo/macros"/>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$latex-image-preamble">
        <xsl:text>%% Graphics Preamble Entries&#xa;</xsl:text>
        <xsl:value-of select="$latex-image-preamble"/>
    </xsl:if>
    <xsl:text>&#xa;%%%% End of PreTeXt generated preamble %%%%&#xa;&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
