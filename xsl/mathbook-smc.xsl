<?xml version='1.0'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:math="http://exslt.org/math"
    extension-element-prefixes="exsl date math">

<xsl:import href="./mathbook-html.xsl" />

<!-- Intend output for rendering by browsers-->
<xsl:output method="html" indent="yes"/>

<!-- Entry point in mathbook-html.xsl is sufficient -->
<!-- Call "dispatch" mode on /mathbook and kills docinfo -->

<!-- Page-wrapping -->
<xsl:template match="*" mode="page-wrap">
    <xsl:param name="content" />
    <xsl:variable name="url"><xsl:apply-templates select="." mode="url" /></xsl:variable>
    <exsl:document href="{$url}" method="html">
        <!-- CSS to hidden executable cell -->
        <xsl:call-template name="css-load" />
        <!-- Start in HTML mode -->
        <xsl:apply-templates select="." mode="inputbegin-execute" />
        <xsl:text>%html&#xa;</xsl:text>
        <xsl:text>\(</xsl:text>
        <xsl:value-of select="/mathbook/docinfo/macros" />
        <xsl:text>\)</xsl:text>
        <xsl:copy-of select="$content" />
        <!-- Totally done, finish HTML mode -->
        <xsl:apply-templates select="." mode="inputoutput" />
        <xsl:apply-templates select="." mode="outputend" />
    </exsl:document>
</xsl:template>

<!-- Summary Page -->
<!-- A summary page has some initial decorations,  -->
<!-- such as title, author and introduction.  Then -->
<!-- the structural subnodes become links in a     -->
<!-- navigation section, followed by some final    -->
<!-- decorations like conclusions.                 -->
<!--                                               -->
<!-- Once concluded, we dispatch all the elements, -->
<!-- knowing some will get killed immediately.     -->
<xsl:template match="*" mode="summary">
    <xsl:apply-templates select="." mode="page-wrap">
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="crude-nav-bar" />
            <!-- Heading, div for subdivision that is this page     -->
            <!-- If a top-level page, titlepage will accomplish this -->
            <xsl:if test="not(/mathbook/article or /mathbook/book)">
                <xsl:variable name="ident"><xsl:apply-templates select="." mode="internal-id" /></xsl:variable>
                <section class="{local-name(.)}" id="{$ident}">
                    <xsl:apply-templates select="." mode="section-header" />
                </section>
            </xsl:if>
            <!-- Summarize elements of the node (which could be verbatim) -->
            <xsl:apply-templates select="*" mode="summary-prenav" />
            <nav class="summary-links">
                <xsl:apply-templates select="*" mode="summary-nav" />
            </nav>
            <xsl:apply-templates select="*" mode="summary-postnav"/>
            <xsl:apply-templates select="." mode="crude-nav-bar" />
         </xsl:with-param>
     </xsl:apply-templates>
     <!-- Summary-mode templates do not recurse, -->
     <!-- need to restart outside web page       -->
     <!-- wrapper and dispatch everything        -->
    <xsl:apply-templates mode="dispatch" />
</xsl:template>

<!-- Add some spacing between links of a summary page -->
<!-- This should be accomplished via CSS              -->
<xsl:template match="*" mode="summary-nav">
    <xsl:apply-imports select="."/><br /><br />
</xsl:template>

<!-- Web Page -->
<!-- When a structural node is the parent of an   -->
<!-- entire web page, we build it here as content -->
<!-- sent to the web page wrapping template       -->
<xsl:template match="*" mode="webpage">
    <xsl:apply-templates select="." mode="page-wrap">
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="crude-nav-bar" />
            <!-- Heading, div for subdivision that is this page     -->
            <!-- If a top-level page or frontmatter, titlepage will accomplish this -->
            <xsl:if test="not(/mathbook/article or /mathbook/book or //frontmatter)">
                <xsl:variable name="ident"><xsl:apply-templates select="." mode="internal-id" /></xsl:variable>
                <section class="{local-name(.)}" id="{$ident}">
                    <xsl:apply-templates select="." mode="section-header" />
                </section>
            </xsl:if>
            <!-- Recurse through contents inside enclosing section, ignore title, author -->
            <xsl:apply-templates select="./*[not(self::title or self::subtitle or self::author)]" />
            <xsl:apply-templates select="." mode="crude-nav-bar" />
         </xsl:with-param>
     </xsl:apply-templates>
</xsl:template>

<!-- Locate the containing file, need *.sagews here         -->
<!-- Maybe this could be parameterized in mathbook-html.xsl -->
<xsl:template match="*" mode="filename">
    <xsl:variable name="summary"><xsl:apply-templates select="." mode="is-summary" /></xsl:variable>
    <xsl:variable name="webpage"><xsl:apply-templates select="." mode="is-webpage" /></xsl:variable>
    <xsl:choose>
        <xsl:when test="$summary='true' or $webpage='true'">
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>.sagews</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select=".." mode="filename" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Could be improved by conditioning on empty URLs -->
<xsl:template match="*" mode="crude-nav-bar">
    <table width="90%">
        <tr>
            <td align="left">
                <xsl:element name="a">
                    <xsl:attribute name="href">
                        <xsl:apply-templates select="." mode="previous-tree-url" />
                    </xsl:attribute>
                    <xsl:attribute name="style">
                        <xsl:text>font-size: 200%;</xsl:text>
                    </xsl:attribute>
                    <xsl:text>Previous</xsl:text>
                </xsl:element>
            </td>
            <td align="center">
                <xsl:element name="a">
                    <xsl:attribute name="href">
                        <xsl:apply-templates select="." mode="up-url" />
                    </xsl:attribute>
                    <xsl:attribute name="style">
                        <xsl:text>font-size: 200%;</xsl:text>
                    </xsl:attribute>
                    <xsl:text>Up</xsl:text>
                </xsl:element>
            </td>
            <td align="right">
                <xsl:element name="a">
                    <xsl:attribute name="href">
                        <xsl:apply-templates select="." mode="next-tree-url" />
                    </xsl:attribute>
                    <xsl:attribute name="style">
                        <xsl:text>font-size: 200%;</xsl:text>
                    </xsl:attribute>
                    <xsl:text>Next</xsl:text>
                </xsl:element>
            </td>
        </tr>
    </table>
</xsl:template>

<!-- We presume entire page is inside a %html cell -->
<!-- In reality at the end of any subdivision,     -->
<!-- we suspend and immediately restart            -->
<xsl:template match="chapter|section|subsection|subsubsection|references|exercises">
    <!-- Section element needed for CSS, apply-templates moved out -->
    <xsl:variable name="ident"><xsl:apply-templates select="." mode="internal-id" /></xsl:variable>
    <section class="{local-name(.)}" id="{$ident}">
        <xsl:apply-templates select="." mode="section-header" />
    </section>
    <!-- Recurse through contents inside enclosing section, ignore title, author -->
    <xsl:apply-templates select="./*[not(self::title or self::subtitle or self::author)]" />
    <!-- <xsl:apply-imports select="." /> -->
    <!-- Hop out, back in, to HTML mode -->
    <xsl:apply-templates select="." mode="inputoutput" />
    <xsl:apply-templates select="." mode="outputend" />
    <xsl:apply-templates select="." mode="inputbegin-execute" />
    <xsl:text>%html&#xa;</xsl:text>    
</xsl:template>

<!-- An abstract named template accepts input text and output    -->
<!-- text, then wraps it in SMC syntax for an executable cell    -->
<!-- (But does not evaluate the cell, that is for the reader)    -->
<!-- [Next part seems broken, code remains to test later]        -->
<!-- We are careful not to hop in/out of HTML mode when there    -->
<!-- is a sequence of consecutive Sage elements (a likely event) -->
<xsl:template name="sage-active-markup">
    <xsl:param name="in" />
    <xsl:param name="out" />
    <!-- Drop out of HTML mode if first in a run (or first in subdivision) -->
    <!-- <xsl:if test="not(local-name(preceding-sibling::*[1]) = 'sage')"> -->
        <xsl:apply-templates select="." mode="inputoutput" />
        <xsl:apply-templates select="." mode="outputend" />
    <!-- </xsl:if> -->
    <!-- Create a complete Sage cell region -->
    <xsl:apply-templates select="." mode="inputbegin" />
        <xsl:value-of select="$in" />
    <xsl:apply-templates select="." mode="inputoutput" />
    <xsl:apply-templates select="." mode="outputend" />
    <!-- Start back in HTML mode, if last in a run (or last in subdivision) -->
    <!-- <xsl:if test="not(local-name(following-sibling::*[1]) = 'sage')"> -->
        <xsl:apply-templates select="." mode="inputbegin-execute" />
        <xsl:text>%html&#xa;</xsl:text>
    <!-- </xsl:if> -->
</xsl:template>

<!-- We bypass image creation and just let SMC -->
<!-- do the job with an executable cell        -->
<xsl:template match="image[child::sageplot]">
    <xsl:apply-templates select="sageplot" />
</xsl:template>

<xsl:template match="sageplot">
    <!-- Drop out of HTML mode -->
    <xsl:apply-templates select="." mode="inputoutput" />
    <xsl:apply-templates select="." mode="outputend" />
    <!-- Create a complete Sage cell region -->
    <xsl:apply-templates select="." mode="inputbegin-execute" />
    <xsl:text>%hide&#xa;</xsl:text>
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="." />
    </xsl:call-template>
    <xsl:apply-templates select="." mode="inputoutput" />
    <xsl:apply-templates select="." mode="outputend" />
    <!-- Start back in HTML mode -->
    <xsl:apply-templates select="." mode="inputbegin-execute" />
    <xsl:text>%html&#xa;</xsl:text>
</xsl:template>

<!-- TODO: sage-display-only abstract template needed -->

<!-- Override wrapper for SVG images        -->
<!-- SMC treates the object tag badly,      -->
<!-- so we just use an img tag (with alt)   -->
<!-- Template expects a fallback flag,      -->
<!-- but this is just to support Sage 3D    -->
<!-- and we just do "sageplot" straightaway -->
<xsl:template match="*" mode="svg-wrapper">
    <xsl:param name="png-fallback" />
    <xsl:element name="img">
        <xsl:attribute name="style">width:60%; margin:auto;</xsl:attribute>
        <xsl:attribute name="src">
            <xsl:value-of select="$directory.images" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select=".." mode="internal-id" />
            <xsl:text>.svg</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="../description" />
    </xsl:element>
</xsl:template>

<!-- CSS -->
<!-- A hidden cell, typically at the top of a page -->
<xsl:template name="css-load">
    <xsl:apply-templates select="." mode="inputbegin-execute" />
    <xsl:text>%hide&#xa;</xsl:text>
    <xsl:text>load("mathbook-content.css")&#xa;</xsl:text>
    <xsl:text>load("mathbook-add-on.css")&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="inputoutput" />
    <xsl:apply-templates select="." mode="outputend" />
</xsl:template>

<!-- ########################## -->
<!-- SageMathCloud Cell Markers -->
<!-- ########################## -->

<!-- Faux UUID -->
<!-- http://code.google.com/p/public-contracts-ontology/source/browse/transformers/GB-notices/uuid.xslt -->
<!-- Could use 14-digit random, 10-digit id, some low-order time, 14-digit random -->
<xsl:template match="*" mode="uuid">
    <!-- idpXXXXXXXX (universal format?) -->
    <xsl:value-of select="substring(generate-id(.), 4, 8)" />
    <!-- flag fauxness -->
    <xsl:text>-ffff-ffff-ffff-</xsl:text>
    <!-- 14 places, so only taking 12: 0.xxxxxxxxxxxxxx -->
    <xsl:value-of select="substring(math:random(), 3, 12)" />
</xsl:template>

<!-- SMC codes for blocking cells          -->
<!-- carriage returns are carefully placed -->
<!-- We are using %hide rather than i code -->
<xsl:template match="*" mode="inputbegin">
    <xsl:text>&#xFE20;</xsl:text>
    <xsl:apply-templates select="." mode="uuid" />
    <xsl:text>&#xFE20;&#xa;</xsl:text>
</xsl:template>

<!-- "x" code after UUID to execute   -->
<xsl:template match="*" mode="inputbegin-execute">
    <xsl:text>&#xFE20;</xsl:text>
    <xsl:apply-templates select="." mode="uuid" />
    <xsl:text>x</xsl:text>
    <xsl:text>&#xFE20;&#xa;</xsl:text>
</xsl:template>

<!-- "i" code after UUID to hide   -->
<xsl:template match="*" mode="inputbegin-hide">
    <xsl:text>&#xFE20;</xsl:text>
    <xsl:apply-templates select="." mode="uuid" />
    <xsl:text>i</xsl:text>
    <xsl:text>&#xFE20;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="*" mode="inputoutput">
    <xsl:text>&#xa;&#xFE21;</xsl:text>
    <xsl:apply-templates select="." mode="uuid" />
    <xsl:text>&#xFE21;</xsl:text>
</xsl:template>

<xsl:template match="*" mode="outputend">
    <xsl:text>&#xFE21;&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>