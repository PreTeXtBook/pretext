<?xml version='1.0'?>

<!--********************************************************************
Copyright 2015 Robert A. Beezer

This file is part of MathBook XML.

MathBook XML is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

MathBook XML is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Copy current file (sample-book-solution-manual.xsl) into mathbook/user -->
<!-- Then other imports are all relative to that directory                  -->

<!-- This relative import will get XSL for building all the  -->
<!-- solutions of a book that live anywhere inside a chapter. -->
<xsl:import href="../xsl/pretext-solution-manual-latex.xsl" />

<!-- PDF Watermarking of Personal Copies    -->
<!-- Non-empty string makes it happen       -->
<!-- 36in parbox just fits "DO NOT" string  -->
<!-- 0.30 scale fits most of width of page  -->
<!-- http://tex.stackexchange.com/questions/125882/                        -->
<!-- how-to-write-multiple-lines-as-watermark-and-images-with-transparency -->
<xsl:param name="latex.watermark" select="'\parbox{36in}{\centering Issued to: David Hilbert\\DO NOT COPY, POST, REDISTRIBUTE}'"/>
<xsl:param name="latex.watermark.scale" select="0.30"/>

<xsl:param name="latex.font.size" select="'11pt'" />

<!-- These switches default to "yes" if not set, so -->
<!-- we explicitly set most to "no" and only set    -->
<!-- "divisional hint and solution" to "yes".       -->
<xsl:param name="exercise.inline.statement" select="'no'" />
<xsl:param name="exercise.inline.hint" select="'no'" />
<xsl:param name="exercise.inline.answer" select="'no'" />
<xsl:param name="exercise.inline.solution" select="'no'" />

<xsl:param name="exercise.divisional.statement" select="'yes'" />
<xsl:param name="exercise.divisional.hint" select="'yes'" />
<xsl:param name="exercise.divisional.answer" select="'yes'" />
<xsl:param name="exercise.divisional.solution" select="'no'" />

<xsl:param name="exercise.worksheet.statement" select="'yes'" />
<xsl:param name="exercise.worksheet.hint" select="'no'" />
<xsl:param name="exercise.worksheet.answer" select="'no'" />
<xsl:param name="exercise.worksheet.solution" select="'no'" />

<xsl:param name="exercise.reading.statement" select="'yes'" />
<xsl:param name="exercise.reading.hint" select="'no'" />
<xsl:param name="exercise.reading.answer" select="'no'" />
<xsl:param name="exercise.reading.solution" select="'no'" />

<xsl:param name="project.statement" select="'no'" />
<xsl:param name="project.hint" select="'no'" />
<xsl:param name="project.answer" select="'no'" />
<xsl:param name="project.solution" select="'no'" />

<!-- Print edition is 4 3/8 inches wide for body -->
<!-- PDF only is wider, eg better for Sage material -->
<!-- Default is "letterpaper", we could fine-tune margins if desired   -->
<!-- 1.25 inch side margins, 0.75 inch top/bottom -->
<xsl:param name="latex.geometry">
	<xsl:text>left=1.25in,right=1.25in,top=0.75in,bottom=0.75in,headsep=0.25in</xsl:text>
</xsl:param>


</xsl:stylesheet>