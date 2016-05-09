<?xml version='1.0'?>

<!-- This file is part of the book                 -->
<!--                                               -->
<!--   Abstract Algebra: Theory and Applications   -->
<!--                                               -->
<!-- Copyright (C) 1997-2014  Thomas W. Judson     -->
<!-- See the file COPYING for copying conditions.  -->

<!-- For a PDF version of the book, everything electronic -->
<!-- Includes Sage material, but not remarks about Sage   -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Assumes this file is in mathbook/user, so it must be copied there -->
<xsl:import href="aata-latex.xsl" />

<xsl:param name="latex.font.size" select="'11pt'" />

<!-- Print edition is 4 3/8 inches wide for body -->
<!-- PDF only is wider, eg better for Sage material -->
<!-- Default is "letterpaper", we could fine-tune margins if desired   -->
<!-- 1.25 inch side margins, 0.75 inch top/bottom -->
<xsl:param name="latex.geometry">
	<xsl:text>left=1.25in,right=1.25in,top=0.75in,bottom=0.75in,headsep=0.25in</xsl:text>
</xsl:param>

<!-- Makes hyperlinks, program listings, etc. active and colored -->
<!-- (This is the default, but set here just to be explicit)     -->
<xsl:param name="latex.print" select="'no'" />

<!-- Each Chapter has a <paragraphs> about Sage, -->
<!-- which will be included by default           -->
<!-- The PDF version contains the two            -->
<!-- Sage sections (discussions and exercises)   -->
<!-- so we kill the duplicative remarks here     -->
<!-- Note: since "paragraphs" are unnumbered,    -->
<!-- removing them from the LaTeX version has    -->
<!-- no effect on the numbering.                 -->
<!-- These could be unnumbered "remark" once     -->
<!-- that is implemented.                        -->
<xsl:template match="paragraphs[title='Sage']" />

</xsl:stylesheet>