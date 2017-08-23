<?xml version='1.0'?> <!-- As XML file -->

<!-- For University of Puget Sound, Writer's Handbook      -->
<!-- 2016/07/29  R. Beezer, rough underline styles         -->

<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "../xsl/entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Import the usual LaTeX conversion templates          -->
<!-- Place ups-writers-latex.xsl file into  mathbook/user -->
<xsl:import href="../xsl/mathbook-latex.xsl" />

<xsl:output method="text" />

<!-- Make marked <p>s hanging indented for citiation chapter. -->
<xsl:template match="p[@indent='hanging']">
    <xsl:if test="preceding-sibling::*[not(&SUBDIVISION-METADATA-FILTER;)][1][self::p or self::paragraphs or self::sidebyside]">
        <xsl:text>\par&#xa;</xsl:text>
    </xsl:if>
    <!-- Beginning of customization -->
    <xsl:text>\hangindent=\parindent{}\hangafter=1{}\noindent{}</xsl:text>
    <!-- End of customization -->
    <xsl:apply-templates/>
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- If also loaded for insert, delete, stale,       -->
<!-- presumably not a problem to attempt second load -->
<xsl:param name="latex.preamble.late">
    <xsl:text>\usepackage{ulem}&#xa;</xsl:text>
    <xsl:text>\normalem&#xa;</xsl:text>
    <xsl:text>\raggedbottom&#xa;</xsl:text>
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
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{black}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="red">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{red}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="lightblue">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{LightBlue}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="lightgreen">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{LightGreen}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="lightpurple">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{Lavender}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="maroon">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{Maroon}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="pink">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{pink}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="darkred">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{DarkRed}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="blue">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{blue}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="orange">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{orange}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="teal">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{teal}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="darkpurple">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{DarkViolet}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="lightpink">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{LightPink}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="green">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{green}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="darkgreen">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{DarkGreen}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="navy">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{Navy}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
<xsl:template match="gray">
    <xsl:if test="$latex.print='no'">
        <xsl:text>\textcolor{gray}{</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="$latex.print='no'">
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>
</xsl:stylesheet>
