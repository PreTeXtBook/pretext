<?xml version='1.0'?>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
>
<xsl:import href="./mathbook-latex.xsl" />

<xsl:output method="text"/>

<xsl:template match="/">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Conversion to Beamer presentations/slideshows is experimental and needs improvements&#xa;Requests for additional specific constructions welcome&#xa;Additional PreTeXt elements are subject to change</xsl:with-param>
      </xsl:call-template>
  <xsl:apply-templates select="pretext"/>
</xsl:template>

<xsl:template match="/pretext">
  <xsl:apply-templates select="slideshow" />
</xsl:template>

<xsl:template match="slideshow">
  <xsl:call-template name="preamble" />
  <xsl:call-template name="body" />
</xsl:template>

<xsl:template name="preamble">
  <xsl:text>\documentclass[11pt, compress]{beamer}&#xa;</xsl:text>
  <xsl:text>\usepackage{amsmath}&#xa;</xsl:text>

  <xsl:text>\usetheme{Boadilla}&#xa;</xsl:text>
  <xsl:text>\usepackage[xparse, raster]{tcolorbox}&#xa;</xsl:text>
  <xsl:text>\tcbset{colback=white, colframe=white}&#xa;</xsl:text>
  <xsl:text>\NewTColorBox{image}{mmm}{boxrule=0.25pt, colframe=gray, left skip=#1\linewidth,width=#2\linewidth}&#xa;</xsl:text>
  <xsl:text>\RenewTColorBox{definition}{m}{colback=teal!30!white, colbacktitle=teal!30!white, coltitle=black, colframe=gray, boxrule=0.5pt, sharp corners=downhill, titlerule = 0.25pt, title={#1}}&#xa;</xsl:text>
  <xsl:text>\RenewTColorBox{theorem}{m}{colback=pink!30!white, colbacktitle=pink!30!white, coltitle=black, colframe=gray, boxrule=0.5pt, sharp corners=downhill, titlerule = 0.25pt, title={#1}}&#xa;</xsl:text>
  <xsl:text>\RenewTColorBox{proof}{}{boxrule=0.25pt, colframe=gray, colback=white, before upper={Proof:}, after upper={\qed}}&#xa;</xsl:text>

  <xsl:text>\newcommand{\terminology}[1]{\textbf{#1}}</xsl:text>
  <xsl:text>\newcommand{\lt}{&lt;}&#xa;</xsl:text>
  <xsl:text>\newcommand{\gt}{&gt;}&#xa;</xsl:text>
  <xsl:text>\newcommand{\amp}{&amp;}&#xa;</xsl:text>


  <xsl:apply-templates select="/pretext/docinfo/macros"/>
</xsl:template>

<xsl:template match="pretext/docinfo/macros">
    <xsl:value-of select="."/>
</xsl:template>

<xsl:template name="body">
  <xsl:text>\title{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
  <xsl:text>}&#xa;</xsl:text>
  <xsl:text>\subtitle{</xsl:text>
    <xsl:apply-templates select="." mode="subtitle" />
  <xsl:text>}&#xa;</xsl:text>

  <xsl:text>\begin{document}&#xa;</xsl:text>
  <xsl:call-template name="titlepage"/>
  <xsl:call-template name="beamertoc"/>

  <xsl:apply-templates select="section"/>
  <xsl:text>\end{document}&#xa;</xsl:text>
</xsl:template>

<xsl:template name="titlepage">
  <xsl:text>\begin{frame}&#xa;</xsl:text>
  <xsl:text>\maketitle &#xa;</xsl:text>
  <xsl:text>\end{frame}&#xa; &#xa;</xsl:text>
</xsl:template>
<xsl:template name="beamertoc">
  <xsl:text>\begin{frame}&#xa;</xsl:text>
  <xsl:text>\frametitle{Overview}&#xa;</xsl:text>
  <xsl:text>\tableofcontents &#xa;</xsl:text>
  <xsl:text>\end{frame}&#xa; &#xa;</xsl:text>
</xsl:template>

<xsl:template match="section">
  <xsl:text>&#xa;\section{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
  <xsl:text>}&#xa;</xsl:text>
  <xsl:apply-templates select="slide"/>
  <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="slide">
  <xsl:text>\begin{frame}&#xa;</xsl:text>
    <xsl:text>\frametitle{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates/>
  <xsl:text>\end{frame}&#xa; &#xa;</xsl:text>
</xsl:template>


<xsl:template match="p">
  <xsl:text>&#xa;</xsl:text>
    <xsl:if test="@slide-step = 'true'">
        <xsl:text>\pause &#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="ul">
  <xsl:if test="@slide-step = 'true'">
    <xsl:text>\pause &#xa;</xsl:text>
  </xsl:if>
  <xsl:text>\begin{itemize}</xsl:text>
  <xsl:if test="@slide-step = 'true'">
    <xsl:text>[&lt;+-&gt;]</xsl:text>
  </xsl:if>
  <xsl:apply-templates/>
  <xsl:text>\end{itemize}</xsl:text>
</xsl:template>

<xsl:template match="ol">
  <xsl:if test="@slide-step = 'true'">
    <xsl:text>\pause &#xa;</xsl:text>
  </xsl:if>
  <xsl:text>\begin{enumerate}</xsl:text>
  <xsl:if test="@slide-step = 'true'">
    <xsl:text>[&lt;+-&gt;]</xsl:text>
  </xsl:if>
  <xsl:apply-templates/>
  <xsl:text>\end{enumerate}</xsl:text>
</xsl:template>

<xsl:template match="li">
  <xsl:text>&#xa;\item{}</xsl:text>
  <xsl:apply-templates/>
  <xsl:text>&#xa;</xsl:text>
</xsl:template>


<xsl:template match="sidebyside">
  <xsl:text>\begin{tcbraster}[arc=0pt, raster columns=</xsl:text>
  <xsl:value-of select="count(*)"/>
  <xsl:text>, raster equal height=rows, raster force size=false, raster column skip=0ex] &#xa;</xsl:text>

  <xsl:variable name="columnCount">
    <xsl:value-of select="count(*)"/>
  </xsl:variable>
  <xsl:variable name="widthFraction">
    <xsl:value-of select="1 div $columnCount" />
  </xsl:variable>

  <xsl:for-each select="*">
    <xsl:if test="parent::*/@slide-step = 'true'">
      <xsl:text>\pause &#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{tcolorbox}[valign=top, width=</xsl:text>
      <xsl:value-of select="$widthFraction" />
    <xsl:text>\textwidth]&#xa;</xsl:text>
      <xsl:apply-templates select="."/>
    <xsl:text>\end{tcolorbox}&#xa; </xsl:text>
  </xsl:for-each>
  <xsl:text>\end{tcbraster} &#xa;</xsl:text>
</xsl:template>

<xsl:template match="proof">
  <xsl:text>\begin{proof}</xsl:text>
  <xsl:apply-templates/>
  <xsl:text>\end{proof}</xsl:text>
</xsl:template>

<xsl:template match="xref">
  [REF=TODO]
<!--  Look up this in some xsl files -->
<!-- <xsl:template match="*" mode="xref-link">
    <xsl:param name="target" />
    <xsl:param name="content" />

    <xsl:copy-of select="$content"/>
</xsl:template> -->
</xsl:template>


<xsl:template match="definition" mode="type-name">
  <xsl:text>Definition</xsl:text>
</xsl:template>
<xsl:template match="definition">
  <xsl:text>\begin{definition}{</xsl:text>
  <xsl:apply-templates select="." mode="type-name" />
  <xsl:choose>
  <xsl:when test="@source-number">
    (<xsl:value-of select="@source-number"/>)
  </xsl:when>
</xsl:choose>
<xsl:text>: </xsl:text>
  <xsl:apply-templates select="." mode="title-full" />
<xsl:text>}</xsl:text>
    <xsl:apply-templates/>
<xsl:text>\end{definition}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="theorem" mode="type-name">
  <xsl:text>Theorem</xsl:text>
</xsl:template>
<xsl:template match="corollary" mode="type-name">
  <xsl:text>Corollary</xsl:text>
</xsl:template>
<xsl:template match="theorem|corollary">
  <xsl:text>\begin{theorem}{</xsl:text>
  <xsl:apply-templates select="." mode="type-name" />
  <xsl:choose>
  <xsl:when test="@source-number">
     (<xsl:value-of select="@source-number"/>)
  </xsl:when>
</xsl:choose>
<xsl:text>: </xsl:text>
  <xsl:apply-templates select="." mode="title-full" />
<xsl:text>}</xsl:text>
    <xsl:apply-templates select="statement"/>
<xsl:text>\end{theorem}&#xa;</xsl:text>
<xsl:apply-templates select="proof"/>
</xsl:template>

</xsl:stylesheet>
