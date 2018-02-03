<?xml version='1.0'?> <!-- As XML file -->

<!-- For TJ Hitchman's Linear Algebra Workbook     -->
<!-- 2014/09/09  R. Beezer, implemented "tasks"    -->
<!-- 2017/08/04  R. Beezer, removed "tasks"        -->

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Import the usual LaTeX conversion templates            -->
<!-- Place this file in  mathbook/user  (mkdir if necessary)-->
<xsl:import href="../xsl/mathbook-html.xsl" />

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="html" />

<!-- Style code output to have red text -->
<!-- And pump up the font size          -->
<xsl:template match="c">
	<tt class="code-inline" style="color: red; font-size: 120%">
		<xsl:apply-templates />
	</tt>
</xsl:template>

<!-- custom numbering flags -->
<xsl:param name="numbering.maximum.level">
	<xsl:text>2</xsl:text>
</xsl:param>
<xsl:param name="numbering.theorems.level">
	<xsl:text>1</xsl:text>
</xsl:param>

</xsl:stylesheet>
