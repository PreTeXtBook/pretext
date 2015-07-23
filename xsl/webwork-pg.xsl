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
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
>

<!-- path assumes we place  webwork-pg.xsl in mathbook "user" directory -->
<xsl:import href="../xsl/mathbook-common.xsl" />

<!-- Intend output to be a PG/PGML problem -->
<xsl:output method="text" />

<!-- ############## -->
<!-- Entry template -->
<!-- ############## -->

<!-- Override chunking routine from common file as entry template -->
<!-- We are assuming a simple file full of webwork problems only, -->
<!-- which we will need to generalize here eventually             -->
<xsl:template match = "/mathbook">
    <xsl:apply-templates select="webwork" />
</xsl:template>

<!-- ################## -->
<!-- Top-Down Structure -->
<!-- ################## -->

<!-- Basic outline of a simple problem -->
<!-- TODO: Now extracted into its own file, this will be moved out -->
<xsl:template match="webwork">
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="pg-filename" />
    </xsl:variable>
    <exsl:document href="{$filename}" method="text">
        <xsl:call-template   name="begin-problem" />
        <xsl:call-template   name="macros" />
        <xsl:apply-templates select="setup" />
        <xsl:apply-templates select="statement" />
        <xsl:apply-templates select="statement" mode="answer-evaluation" />
        <xsl:apply-templates select="solution" />
        <xsl:call-template   name="end-problem" />
    </exsl:document>
</xsl:template>

<xsl:template match="setup">
    <!-- ignore var for now -->
    <xsl:apply-templates select="pg-code" />
</xsl:template>

<xsl:template match="pg-code">
    <!-- no processing -->
    <!-- TODO: pump through indentation-cleaner -->
    <xsl:value-of select="." />
</xsl:template>

<!-- default template, for complete presentation -->
<xsl:template match="statement">
    <xsl:text>Context()->texStrings;&#xa;</xsl:text>
    <xsl:text>BEGIN_TEXT&#xa;</xsl:text>
    <xsl:apply-templates />
    <!-- unless we guarantee line feed, a break is needed -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>END_TEXT&#xa;</xsl:text>
</xsl:template>

<xsl:template match="statement//var">
    <xsl:value-of select="@name" />
</xsl:template>

<!-- simple scalar answer checker     -->
<!-- Example: \{$soln->ans_array(2)\} -->
<!-- TODO: use different6 templates for different types -->
<xsl:template match="answer">
    <xsl:text>\{</xsl:text>
    <xsl:value-of select="@var" />
    <xsl:text>->ans_array(</xsl:text>
    <xsl:value-of select="@width" />
    <xsl:text>)\}</xsl:text>
</xsl:template>

<!-- modal template, for answer-checks -->
<xsl:template match="statement" mode="answer-evaluation">
    <xsl:text>Context()->normalStrings;&#xa;</xsl:text>
    <xsl:apply-templates select=".//answer" mode="answer-evaluation" />
</xsl:template>

<!-- Exanple: ANS($soln->cmp()); -->
<xsl:template match="answer" mode="answer-evaluation">
    <xsl:text>ANS(</xsl:text>
    <xsl:value-of select="@var" />
    <xsl:text>->cmp());&#xa;</xsl:text>
</xsl:template>

<!-- Unimplemented, currently killed -->
<xsl:template match="title" />
<xsl:template match="solution" />


<!-- ####################### -->
<!-- Static, Named Templates -->
<!-- ####################### -->

<xsl:template name="begin-problem">
    <xsl:text>DOCUMENT();&#xa;</xsl:text>
</xsl:template>

<!-- We kill default processing of "macros" and use       -->
<!-- a named template.  This allows for their to be no    -->
<!-- "macros" element if no additional macros are needed. -->
<xsl:template name="macros">
    <!-- three standard macro files, order and placement is critical -->
    <xsl:text>loadMacros("PGstandard.pl", "MathObjects.pl"</xsl:text>
    <!-- TODO: add a for-each on macros/macro, lead with blank+space -->
    <!-- TODO: could use more carriage returns to format properly    -->
    <xsl:text>, "PGcourse.pl");&#xa;</xsl:text>
</xsl:template>

<xsl:template name="end-problem">
    <xsl:text>ENDDOCUMENT();&#xa;</xsl:text>
</xsl:template>


<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->

<!-- Construct a PG filename                -->
<!-- From xml:id, or will be "webwork-N.pg" -->
<xsl:template match="*" mode="pg-filename">
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>.pg</xsl:text>
</xsl:template>

</xsl:stylesheet>