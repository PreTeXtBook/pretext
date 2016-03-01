<?xml version='1.0'?> <!-- As XML file -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Thin layer on MathBook XML -->
<xsl:import href="/home/rob/mathbook/mathbook/xsl/mathbook-html.xsl" />

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="html" />

<!-- XML elements -->
<!-- Writing about a lnguage in its own
language is hard, the escape characters
become impossible -->

<xsl:template match="tag">
    <xsl:text>&lt;</xsl:text><xsl:apply-templates /><xsl:text>&gt;</xsl:text>
</xsl:template>


</xsl:stylesheet>