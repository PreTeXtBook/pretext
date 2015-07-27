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

<!-- path assumes we place  webwork-pg.xsl in mathbook "user" directory -->
<xsl:import href="../xsl/mathbook-common.xsl" />

<!-- Intend output to be a PGML problem -->
<xsl:output method="text" />

<!-- ################## -->
<!-- Top-Down Structure -->
<!-- ################## -->

<!-- Basic outline of a simple problem -->
<!-- TODO: Now extracted into its own file, this will be moved out -->
<xsl:template match="webwork">
    <xsl:call-template   name="begin-problem" />
    <xsl:call-template   name="macros" />
    <xsl:call-template   name="header" />
    <xsl:apply-templates select="setup" />
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="solution" />
    <xsl:call-template   name="end-problem" />
</xsl:template>

<xsl:template match="setup">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">PG Setup</xsl:with-param>
    </xsl:call-template>
    <!-- TODO: ignore var for now -->
    <!-- pg-code verbatim, but trim indentation -->
    <xsl:call-template name="sanitize-code">
        <xsl:with-param name="raw-code" select="pg-code" />
    </xsl:call-template>
</xsl:template>

<!-- default template, for complete presentation -->
<xsl:template match="statement">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Body</xsl:with-param>
    </xsl:call-template>
    <xsl:text>BEGIN_PGML&#xa;</xsl:text>
    <xsl:apply-templates />
    <!-- unless we guarantee line feed, a break is needed -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>END_PGML&#xa;</xsl:text>
</xsl:template>

<!-- default template, for solution -->
<xsl:template match="solution">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Solution</xsl:with-param>
    </xsl:call-template>
    <xsl:text>BEGIN_PGML_SOLUTION&#xa;</xsl:text>
    <xsl:apply-templates />
    <!-- unless we guarantee line feed, a break is needed -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>END_PGML_SOLUTION&#xa;</xsl:text>
</xsl:template>

<xsl:template match="statement//var|solution//var">
    <xsl:text>[</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- PGML answer blank               -->
<!-- Example: [_____]{$ans}          -->
<xsl:template match="statement//answer">
    <xsl:variable name="width">
        <xsl:choose>
            <xsl:when test="@width">
                 <xsl:value-of select="@width"/>
            </xsl:when>
            <xsl:otherwise>
                 <xsl:text>5</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>[</xsl:text>
    <xsl:call-template name="underscore">
        <xsl:with-param name="width">
            <xsl:value-of select="$width"/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="@var" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- PGML inline math uses its own delimiters -->
<xsl:template match= "m">
    <xsl:text>[`</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>`]</xsl:text>
</xsl:template>

<!-- Unimplemented, currently killed -->
<xsl:template match="title" />
<xsl:template match="hint" />


<!-- ####################### -->
<!-- Static, Named Templates -->
<!-- ####################### -->

<xsl:template name="begin-problem">
    <xsl:text>DOCUMENT();&#xa;</xsl:text>
</xsl:template>

<xsl:template name="header">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Header</xsl:with-param>
    </xsl:call-template>
    <xsl:text>TEXT(beginproblem());&#xa;</xsl:text>
</xsl:template>

<!-- We kill default processing of "macros" and use       -->
<!-- a named template.  This allows for there to be no    -->
<!-- "macros" element if no additional macros are needed. -->
<!-- Call from "webwork" context                          -->
<xsl:template match="macros" />
<xsl:template name="macros">
    <!-- three standard macro files, order and placement is critical -->
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Load Macros</xsl:with-param>
    </xsl:call-template>
    <xsl:text>loadMacros(&#xa;</xsl:text>
    <xsl:text>    "PGstandard.pl",&#xa;</xsl:text>
    <xsl:text>    "MathObjects.pl",&#xa;</xsl:text>
    <xsl:text>    "PGML.pl",&#xa;</xsl:text>
    <xsl:apply-templates select="macros/macro" />
    <xsl:text>    "PGcourse.pl",&#xa;</xsl:text>
    <xsl:text>);&#xa;</xsl:text>
</xsl:template>

<!-- NB: final trailing comma controlled by "PGcourse.pl" -->
<xsl:template match="macro">
    <xsl:text>    "</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>",&#xa;</xsl:text>
</xsl:template>

<xsl:template name="end-problem">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">End Problem</xsl:with-param>
    </xsl:call-template>
    <xsl:text>ENDDOCUMENT();&#xa;</xsl:text>
</xsl:template>

<xsl:template name="begin-block">
    <xsl:param name="title"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>############################################################&#xa;</xsl:text>
    <xsl:text># </xsl:text>
    <xsl:value-of select="$title"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>############################################################&#xa;</xsl:text>
</xsl:template>

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
