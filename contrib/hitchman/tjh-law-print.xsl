<?xml version='1.0'?> <!-- As XML file -->

<!-- For TJ Hitchman's Linear Algebra Workbook     -->
<!-- 2014/09/04  R. Beezer, page break at sections -->

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Import the usual LaTeX conversion templates           -->
<!-- EDIT ME to point the right place, maybe use full path -->
<xsl:import href="/Users/hitchman/github/mathbook/xsl/mathbook-latex.xsl" />

<!-- Examples of items you usually set as "stringparam" on the command line -->
<xsl:param name="latex.font.size" select="'10pt'" />

<!-- Makes hyperlinks, program listings, etc. black & white -->
<xsl:param name="latex.print">
	<xsl:text>yes</xsl:text>
</xsl:param>

<!-- custom numbering flags -->
<xsl:param name="numbering.maximum.level">
	<xsl:text>2</xsl:text>
</xsl:param>
<xsl:param name="numbering.theorems.level">
	<xsl:text>1</xsl:text>
</xsl:param>

<!-- Enhance processing of sections    -->
<!-- Add a \clearpage to the end, plus -->
<!-- a newline for very clean source   -->
<xsl:template match="section">
	<xsl:apply-imports />
	<xsl:text>\clearpage&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
