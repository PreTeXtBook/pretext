<?xml version='1.0'?> <!-- As XML file -->

<!-- For University of Puget Sound, Writer's Handbook      -->
<!-- 2016/07/29  R. Beezer, rough underline styles         -->

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Import the usual LaTeX conversion templates          -->
<!-- Place ups-writers-latex.xsl file into  mathbook/user -->
<xsl:import href="../xsl/mathbook-latex.xsl" />

<xsl:output method="text" />

<!-- If also loaded for insert, delete, stale,       -->
<!-- presumably not a problem to attempt second load -->
<xsl:param name="latex.preamble.late">
    <xsl:text>\usepackage{ulem}&#xa;</xsl:text>
    <xsl:text>\normalem&#xa;</xsl:text>
</xsl:param>

<!-- General commands from the "ulem" package -->
<!-- Make semantic versions if made official  -->

<!-- single -->
<xsl:template match="un[@s='1']">
    <xsl:text>\uline{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- double -->
<xsl:template match="un[@s='2']">
    <xsl:text>\uuline{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- dashed -->
<xsl:template match="un[@s='3']">
    <xsl:text>\dashuline{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- dotted -->
<xsl:template match="un[@s='4']">
    <xsl:text>\dotuline{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- A wavy underline, potential '5': \uwave{} -->

<!-- Ellipsis (dots), for text, not math -->
<xsl:template match="ellipsis">
    <xsl:text>{.~.~.}</xsl:text>
</xsl:template>

<!-- Bibliography Formatting -->
<xsl:template match="i">
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Bibliography Colors -->
<xsl:template match="black">
    <xsl:text>\textcolor{black}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="red">
    <xsl:text>\textcolor{red}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="lightblue">
    <xsl:text>\textcolor{LightBlue}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="lightgreen">
    <xsl:text>\textcolor{LightGreen}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="lightpurple">
    <xsl:text>\textcolor{Lavender}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="maroon">
    <xsl:text>\textcolor{Maroon}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="pink">
    <xsl:text>\textcolor{pink}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="darkred">
    <xsl:text>\textcolor{DarkRed}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="blue">
    <xsl:text>\textcolor{blue}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="orange">
    <xsl:text>\textcolor{orange}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="teal">
    <xsl:text>\textcolor{teal}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="darkpurple">
    <xsl:text>\textcolor{DarkViolet}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="lightpink">
    <xsl:text>\textcolor{LightPink}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="green">
    <xsl:text>\textcolor{green}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="darkgreen">
    <xsl:text>\textcolor{DarkGreen}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="navy">
    <xsl:text>\textcolor{Navy}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="gray">
    <xsl:text>\textcolor{gray}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
</xsl:template>
</xsl:stylesheet>
