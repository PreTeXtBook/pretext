<?xml version='1.0'?> <!-- As XML file -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Thin layer on MathBook XML -->
<xsl:import href="/home/rob/mathbook/mathbook/xsl/mathbook-latex.xsl" />

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="text" />

<xsl:param name="latex.geometry">letterpaper,total={6.5in,9in}</xsl:param>

<!-- XML elements -->
<!-- Writing about a lnguage in its own
language is hard, the escape characters
become impossible -->

<xsl:template match="tag">
    <xsl:text>\(\langle\)</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\(\rangle\)</xsl:text>
</xsl:template>


</xsl:stylesheet>