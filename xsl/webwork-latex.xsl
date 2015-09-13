<?xml version="1.0" encoding="UTF-8" ?>

<!-- ********************************************************************* -->
<!-- Copyright 2015                                                        -->
<!-- Robert A. Beezer, Michael Gage, Geoff Goehle, Alex Jordan             -->
<!--                                                                       -->
<!-- This file is part of MathBook XML.                                    -->
<!--                                                                       -->
<!-- MathBook XML is free software: you can redistribute it and/or modify  -->
<!-- it under the terms of the GNU General Public License as published by  -->
<!-- the Free Software Foundation, either version 2 or version 3 of the    -->
<!-- License (at your option).                                             -->
<!--                                                                       -->
<!-- MathBook XML is distributed in the hope that it will be useful,       -->
<!-- but WITHOUT ANY WARRANTY; without even the implied warranty of        -->
<!-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         -->
<!-- GNU General Public License for more details.                          -->
<!--                                                                       -->
<!-- You should have received a copy of the GNU General Public License     -->
<!-- along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>. -->
<!-- ********************************************************************* -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<!-- path assumes we place  webwork-latex.xsl  in mathbook "user" directory -->
<xsl:import href="../xsl/mathbook-latex.xsl" />

<!-- Intend output to be a LaTeX source -->
<xsl:output method="text" />

<!-- Removing whitespace: http://stackoverflow.com/questions/1468984/xslt-remove-whitespace-from-template -->
<xsl:strip-space elements="li" />


<!-- ################## -->
<!-- Top-Down Structure -->
<!-- ################## -->

<!-- Assume the "exercise/webwork" structure -->
<!-- and get LaTeX header without body       -->
<!-- TODO: need to change MBX to accomodate WW problems -->
<!-- TODO: Much of below copied verbatim from MBX -->
<xsl:template match="exercise">
    <xsl:text>\begin{exercise}</xsl:text>
    <xsl:apply-templates select="title" mode="environment-option" />
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="webwork" />
    <!-- <xsl:apply-templates select="statement"/> -->
    <!-- <xsl:apply-templates select="hint"/> -->
    <!-- <xsl:apply-templates select="solution"/> -->
    <xsl:text>\end{exercise}&#xa;</xsl:text>
</xsl:template>

<!-- Basic outline of a simple problem -->
<xsl:template match="webwork">
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
                        <xsl:text> or </xsl:text>
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
            <xsl:text>\rule[-.3\baselineskip]{</xsl:text>
            <xsl:choose>
                <xsl:when test="@width">
                    <xsl:value-of select="@width" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>5</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>em}{0.1ex}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- An essay answer has no associated variable              -->
<!-- We simply indicate that this is an essay answer problem -->
<xsl:template match="answer[@format='essay']">
    <xsl:text>\quad\lbrack Essay Answer\rbrack</xsl:text>
</xsl:template>

<!-- PGML suggests we allow the "var" element as a child -->
<xsl:template match= "webwork//m">
    <xsl:text>\(</xsl:text>
    <xsl:apply-templates select="text()|var" />
    <xsl:text>\)</xsl:text>
</xsl:template>
<xsl:template match= "webwork//me">
    <xsl:text>\[</xsl:text>
    <xsl:apply-templates select="text()|var" />
    <xsl:text>\]</xsl:text>
</xsl:template>



<!-- KILLED -->
<xsl:template match="macros" />
<xsl:template match="setup" />

<!-- Unimplemented, currently killed -->
<xsl:template match="webwork/title" />


<!-- ####################### -->
<!-- Static, Named Templates -->
<!-- ####################### -->


<!-- Since we use XSLT 1.0, this is how we create -->
<!-- "width" underscores for a PGML answer blank  -->
<xsl:template name="underscore">
    <xsl:param name="width" select="5" />
    <xsl:if test="not($width = 0)">
        <xsl:text>_</xsl:text>
        <xsl:call-template name="underscore">
            <xsl:with-param name="width" select="$width - 1" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->

</xsl:stylesheet>
