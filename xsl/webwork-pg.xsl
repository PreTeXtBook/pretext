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


<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!--  -->
<!-- Enable answer format syntax help links                       -->
<!-- Each variable has a "category", like "integer" or "formula". -->
<!-- When an answer blank is expecting a variable, use category   -->
<!-- to provide AnswerFormatHelp link.                            -->
<xsl:param name="pg.answer.format.help" select="'yes'" />


<!-- ################## -->
<!-- Top-Down Structure -->
<!-- ################## -->

<!-- Basic outline of a simple problem -->
<xsl:template match="webwork">
    <xsl:call-template   name="begin-problem" />
    <xsl:call-template   name="macros" />
    <xsl:call-template   name="header" />
    <xsl:apply-templates select="setup" />
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="solution" />
    <xsl:call-template   name="end-problem" />
</xsl:template>

<!-- Basic outline of a "scaffold" problem -->
<xsl:template match="webwork[@type='scaffold']">
    <xsl:call-template   name="begin-problem" />
    <xsl:call-template   name="macros" />
    <xsl:call-template   name="header" />
    <xsl:apply-templates select="setup" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Scaffold</xsl:with-param>
    </xsl:call-template>
    <xsl:text>Scaffold::Begin();&#xa;</xsl:text>
    <xsl:apply-templates select="platform" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>Scaffold::End();&#xa;</xsl:text>
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

<!-- A platform is part of a scaffold -->
<xsl:template match="platform">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Section</xsl:with-param>
    </xsl:call-template>
    <xsl:text>Section::Begin("</xsl:text>
    <xsl:apply-templates select="title" />
    <xsl:text>");&#xa;</xsl:text>
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="solution" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>Section::End();&#xa;</xsl:text>
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

<!-- In PGML, paragraph breaks are just blank lines -->
<xsl:template match="p">
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates />
</xsl:template>


<!-- PGML markup for Perl variable in LaTeX expression -->
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
    <xsl:if test="$pg.answer.format.help">
        <xsl:variable name="category">
            <xsl:choose>
                <xsl:when test="@category">
                    <xsl:value-of select="@category"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="varname" select="@var" />
                    <xsl:variable name="problem" select="ancestor::webwork" />
                    <xsl:for-each select="$problem/setup/var[@name=$varname]">
                        <xsl:value-of select="@category" />
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="format">
            <xsl:call-template name="category-to-format">
                <xsl:with-param name="category" select="$category"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:if test="not($format='none')">
            <xsl:text> [@ AnswerFormatHelp("</xsl:text>
                <xsl:value-of select="$format"/>
            <xsl:text>") @]*</xsl:text>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- PGML inline math uses its own delimiters  -->
<!-- NB: we allow the "var" element as a child -->
<xsl:template match= "m">
    <xsl:text>[`</xsl:text>
    <xsl:apply-templates select="text()|var" />
    <xsl:text>`]</xsl:text>
</xsl:template>
<xsl:template match="me">
    <xsl:text>&#xa;&#xa;&gt;&gt; [``</xsl:text>
    <xsl:apply-templates select="text()|var" />
    <xsl:text>``] &lt;&lt;&#xa;&#xa;</xsl:text>
</xsl:template>


<!-- re-activate, since MBX kills all titles -->
<xsl:template match="webwork//title">
    <xsl:apply-templates />
</xsl:template>


<!-- Unimplemented, currently killed -->
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
    <xsl:if test="@type='scaffold'">
        <xsl:text>    "scaffold.pl",&#xa;</xsl:text>
    </xsl:if>
    <!-- TODO: Make below check each <answer>'s var, to see if that var -->
    <!-- has an approved category                                       -->
    <xsl:if test="($pg.answer.format.help = 'yes')">
        <xsl:text>    "AnswerFormatHelp.pl",&#xa;</xsl:text>
    </xsl:if>
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

<!-- Convert a var's "category" to the right term for AnswerFormatHelp -->
<xsl:template name="category-to-format">
    <xsl:param name="category"/>
    <xsl:choose>
        <xsl:when test="$category='angle'">
            <xsl:text>angles</xsl:text>
        </xsl:when>
        <xsl:when test="$category='decimal'">
            <xsl:text>decimals</xsl:text>
        </xsl:when>
        <xsl:when test="$category='exponent'">
            <xsl:text>exponents</xsl:text>
        </xsl:when>
        <xsl:when test="$category='formula'">
            <xsl:text>formulas</xsl:text>
        </xsl:when>
        <xsl:when test="$category='fraction'">
            <xsl:text>fractions</xsl:text>
        </xsl:when>
        <xsl:when test="$category='inequality'">
            <xsl:text>inequalities</xsl:text>
        </xsl:when>
        <xsl:when test="$category='interval'">
            <xsl:text>intervals</xsl:text>
        </xsl:when>
        <xsl:when test="$category='logarithm'">
            <xsl:text>logarithms</xsl:text>
        </xsl:when>
        <xsl:when test="$category='limit'">
            <xsl:text>limits</xsl:text>
        </xsl:when>
        <xsl:when test="$category='number' or $category='integer'">
            <xsl:text>numbers</xsl:text>
        </xsl:when>
        <xsl:when test="$category='point'">
            <xsl:text>points</xsl:text>
        </xsl:when>
        <xsl:when test="$category='syntax'">
            <xsl:text>syntax</xsl:text>
        </xsl:when>
        <xsl:when test="$category='quantity'">
            <xsl:text>units</xsl:text>
        </xsl:when>
        <xsl:when test="$category='vector'">
            <xsl:text>vectors</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>none</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ###### -->
<!-- Markup -->
<!-- ###### -->

<!-- http://webwork.maa.org/wiki/Introduction_to_PGML#Basic_Formatting -->

<!-- two spaces at line-end is a newline -->
<xsl:template match="br">
    <xsl:text>  &#xa;</xsl:text>
</xsl:template>


<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->



</xsl:stylesheet>
