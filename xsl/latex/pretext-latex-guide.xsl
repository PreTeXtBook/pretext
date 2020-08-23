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

<!-- This file isolates customizations for the PreText documentation,  -->
<!-- The PreTeXt Guide, when produced as a PDF via LaTeX.  It is meant -->
<!-- to be used only with the PreTeXt "book" element.  At inception,   -->
<!-- 2019-11-07, it is not meant to yet be a general-purpose style.    -->

<!-- Conveniences for classes of similar elements -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "../entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<!-- We override specific templates of the standard conversion -->
<!-- There is a relative path here, which bounces up a level   -->
<!-- from the file you are reading to be in the directory of   -->
<!-- principal stylesheets.  (Also for entities.ent above)     -->
<xsl:import href="../pretext-latex.xsl" />

<!-- Intend output for rendering by xelatex -->
<xsl:output method="text" />

<!-- ##### -->
<!-- Fonts -->
<!-- ##### -->

<!-- Old Style figures for the body, but reversed to Lining many  -->
<!-- other places. "Old Style" is a lowercase style, "Lining" is  -->
<!-- a (now traditional) uppercase style.  Ornamentation for page -->
<!-- header happens to be specific Unicode characters of the same -->
<!-- font used for the text.  Relevant font table here:           -->
<!-- http://mirrors.ctan.org/fonts/libertinus-fonts/documentation/LibertinusSerif-Regular-Table.pdf -->
<xsl:template name="font-xelatex-main">
    <xsl:text>%% XeLaTeX font configuration from PreTeXt Guide style&#xa;</xsl:text>
    <xsl:text>%% We rely on a font installed at the system level,&#xa;</xsl:text>
    <xsl:text>%% so that we can exercise specific font features&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:call-template name="xelatex-font-check">
        <xsl:with-param name="font-name" select="'Libertinus Serif'"/>
    </xsl:call-template>
    <xsl:text>\setmainfont{Libertinus Serif}[Numbers=OldStyle]&#xa;</xsl:text>
</xsl:template>

<!-- Libertinus Mono is serifed (and ugly?) so by doing nothing the   -->
<!-- default Inconsolata font will be employed, which is much more    -->
<!-- typewriter-like.  Using an empty template would kill Inconsolata -->
<!-- and yield whatever default Latin Modern provides.  Both these    -->
<!-- options have trouble with \textpilcrow and \textrbrackdbl        -->

<xsl:template name="font-xelatex-style">
    <xsl:call-template name="xelatex-font-check">
        <xsl:with-param name="font-name" select="'Libertinus Sans'"/>
    </xsl:call-template>
    <xsl:text>\renewfontfamily{\divisionfont}{Libertinus Sans}[Numbers=Lining]&#xa;</xsl:text>
    <xsl:text>\renewfontfamily{\contentsfont}{Libertinus Sans}[Numbers=Lining]&#xa;</xsl:text>
    <xsl:text>\renewfontfamily{\pagefont}{Libertinus Sans}[Numbers=Lining]&#xa;</xsl:text>
    <xsl:text>\renewfontfamily{\blocktitlefont}{Libertinus Serif}[Numbers=Lining]&#xa;</xsl:text>
    <xsl:text>\renewfontfamily{\tabularfont}{Libertinus Serif}[Numbers={Monospaced,Lining}]&#xa;</xsl:text>
    <xsl:text>\renewfontfamily{\xreffont}{Libertinus Serif}[Numbers=Lining]&#xa;</xsl:text>
    <xsl:text>\renewfontfamily{\titlepagefont}{Libertinus Serif}[Numbers=Lining]&#xa;</xsl:text>
    <xsl:text>\newfontfamily{\ornamental}{Libertinus Serif}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="book" mode="titleps-style">
    <xsl:text>%% Page style configuration from PreTeXt Guide style&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% Plain pages should have the same font for page numbers&#xa;</xsl:text>
    <xsl:text>\renewpagestyle{plain}{%&#xa;</xsl:text>
    <xsl:text>\setfoot{}{\pagefont\thepage}{}%&#xa;</xsl:text>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:text>\renewpagestyle{headings}{%&#xa;</xsl:text>
    <xsl:text>\pagefont\headrule%&#xa;</xsl:text>
    <xsl:text>\sethead%&#xa;</xsl:text>
    <xsl:text>{\ifthesection{\pagefont\thesection}{\ifthechapter{\pagefont\thechapter}{}}}%&#xa;</xsl:text>
    <xsl:text>{{\ornamental &#x2619;}{\pagefont\space\ifthesection{\sectiontitle}{\chaptertitle}\space}{\ornamental &#x2767;}}
    {\pagefont\thepage}}%&#xa;</xsl:text>
    <xsl:text>\pagestyle{headings}&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
