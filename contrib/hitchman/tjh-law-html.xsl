<?xml version='1.0'?> <!-- As XML file -->

<!-- For TJ Hitchman's Linear Algebra Workbook     -->
<!-- 2014/09/04  R. Beezer, page break at sections -->

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Import the usual LaTeX conversion templates           -->
<!-- EDIT ME to point the right place, maybe use full path -->
<xsl:import href="/Users/hitchman/github/mathbook/xsl/mathbook-html.xsl" />



<!-- Change styling of code output to have red text -->
<xsl:template match="c">
	<tt class="code=inline" style="color: red; font-size: 120%"><xsl:apply-imports /></tt>
</xsl:template>

<!-- custom numbering flags -->
<xsl:param name="numbering.maximum.level">
	<xsl:text>2</xsl:text>
</xsl:param>
<xsl:param name="numbering.theorems.level">
	<xsl:text>1</xsl:text>
</xsl:param>


</xsl:stylesheet>
