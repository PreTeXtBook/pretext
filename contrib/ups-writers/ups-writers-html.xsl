<?xml version='1.0'?> <!-- As XML file -->

<!-- For University of Puget Sound, Writer's Handbook      -->
<!-- 2016/07/29  R. Beezer, rough underline styles         -->

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Import the usual HTML conversion templates          -->
<!-- Place ups-writers-html.xsl file into  mathbook/user -->
<xsl:import href="../xsl/mathbook-html.xsl" />

<xsl:output method="html" />

<xsl:template match="un[@s='1']">
    <xsl:element name="span">
        <xsl:attribute name="class">
            <xsl:text>underline-single</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="style">
            <xsl:text>border-bottom: 1px solid;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates />
    </xsl:element>
</xsl:template>

<!-- http://stackoverflow.com/questions/15643614/double-underline-tag -->
<xsl:template match="un[@s='2']">
    <xsl:element name="span">
        <xsl:attribute name="class">
            <xsl:text>underline-double</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="style">
            <xsl:text>border-bottom: 3px double;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates />
    </xsl:element>
</xsl:template>

<xsl:template match="un[@s='3']">
    <xsl:element name="span">
        <xsl:attribute name="class">
            <xsl:text>underline-dashed</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="style">
            <xsl:text>border-bottom: 1px dashed;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates />
    </xsl:element>
</xsl:template>

<xsl:template match="un[@s='4']">
    <xsl:element name="span">
        <xsl:attribute name="class">
            <xsl:text>underline-dotted</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="style">
            <xsl:text>border-bottom: 1px dotted;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates />
    </xsl:element>
</xsl:template>

<!-- A wavy underline, potential '5':                               -->
<!--   (1) won't span lines (needs non-breaking space for snippets) -->
<!--   (2) must go into CSS, becaue of "after" pseudo-class         -->
<!-- http://stackoverflow.com/questions/28152175/a-wavy-underline-in-css -->
<!-- 
.mathbook-content .underline-wavy {
  border-bottom:2px dotted black;
  display: inline;
  position: relative;
}

.underline-wavy:after {
  content: '';
  height: 5px;
  width: 100%;
  border-bottom:2px dotted black;
  position: absolute;
  bottom: -3px;
  left: -2px;
  }
-->

</xsl:stylesheet>
