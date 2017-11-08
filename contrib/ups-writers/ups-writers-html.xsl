<?xml version='1.0'?> <!-- As XML file -->

<!-- For University of Puget Sound, Writer's Handbook      -->
<!-- 2016/07/29  R. Beezer, rough underline styles         -->

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Import the usual HTML conversion templates          -->
<!-- Place ups-writers-html.xsl file into  mathbook/user -->
<xsl:import href="../xsl/mathbook-html.xsl" />

<xsl:output method="html" />

<xsl:param name="html.css.file" select="'mathbook-ups.css'"/>
<xsl:param name="html.knowl.example" select="'no'"/>

<xsl:param name="chunk.level" select="'3'" />

<!-- Make marked <p>s hanging indented for citiation chapter. -->
<xsl:template match="p[@indent='hanging']" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:if test="$block-type = 'xref'">
        <xsl:apply-templates select="." mode="heading-xref-knowl" />
    </xsl:if>
    <xsl:element name="p">
        <!-- Beginning of customization -->
        <xsl:attribute name="style">
            <xsl:text>padding-left: 2em; text-indent: -2em;</xsl:text>
        </xsl:attribute>
        <!-- End of customization -->
        <xsl:if test="$b-original">
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="internal-id" />
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="*|text()">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

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

<!-- .mathbook-content .underline-wavy { -->
<!-- border-bottom:2px dotted black; -->
<!-- display: inline; -->
<!-- position: relative; -->
<!-- } -->
<!--  -->
<!-- .underline-wavy:after { -->
<!-- content: ''; -->
<!-- height: 5px; -->
<!-- width: 100%; -->
<!-- border-bottom:2px dotted black; -->
<!-- position: absolute; -->
<!-- bottom: -3px; -->
<!-- left: -2px; -->
<!-- } -->

<!-- Ellipsis (dots), for text, not math -->
<xsl:template match="ellipsis">
    <xsl:text>.&#xa0;.&#xa0;.</xsl:text>
</xsl:template>

<!-- Bibliography Formatting -->
<xsl:template match="i">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>font-style: italic;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>

<!-- Bibliography Colors -->
<xsl:template match="black">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: black;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="red">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: red;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="lightblue">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: lightblue;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="lightgreen">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: lightgreen;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="lightpurple">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: violet;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="maroon">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: maroon;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="pink">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: pink;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="darkred">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: darkred;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="blue">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: blue;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="orange">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: orange;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="teal">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: teal;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="darkpurple">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: darkviolet;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="lightpink">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: lightpink;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="green">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: green;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="darkgreen">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: darkgreen;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="navy">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: navy;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>
<xsl:template match="gray">
    <xsl:element name="span">
        <xsl:attribute name="style">
            <xsl:text>color: gray;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>

</xsl:stylesheet>
