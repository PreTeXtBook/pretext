<?xml version='1.0'?> <!-- As XML file -->

<!-- For TJ Hitchman's Linear Algebra Workbook     -->
<!-- 2014/09/04  R. Beezer, page break at sections -->
<!-- 2014/09/09  R. Beezer, implemented "tasks"    -->
<!-- 2017/08/04  R. Beezer, removed "tasks"        -->

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Import the usual LaTeX conversion templates            -->
<!-- Place this file in  mathbook/user  (mkdir if necessary)-->
<xsl:import href="../xsl/mathbook-latex.xsl" />

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="text" />

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
