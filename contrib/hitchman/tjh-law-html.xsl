<?xml version='1.0'?> <!-- As XML file -->

<!-- For TJ Hitchman's Linear Algebra Workbook     -->
<!-- 2014/09/09  R. Beezer, implemented "tasks"    -->

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

<!-- ##### -->
<!-- Tasks -->
<!-- ##### -->

<!-- Number tasks globally, serially -->
<xsl:template match="task" mode="number">
	<xsl:number count="task" from="mathbook" level="any" />
</xsl:template>

<xsl:template match="task">
	<xsl:element name="article">
		<xsl:attribute name="class">example-like</xsl:attribute>
		<xsl:attribute name="id">
			<xsl:apply-templates select="." mode="internal-id" />
		</xsl:attribute>
		<h5 class="heading">
			<span class="type">Task</span>
			<span class="codenumber"><xsl:apply-templates select="." mode="number" /></span>
			<span class="title"><xsl:apply-templates select="title" /></span>
		</h5>
		<!-- Title is handled otherwise in heading-->
		<xsl:apply-templates select="*[not(self::title)]"/>
	</xsl:element>
</xsl:template>

</xsl:stylesheet>
