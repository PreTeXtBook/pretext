<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2019 Robert A. Beezer

This file is part of PreTeXt.

PreTeXt is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

PreTeXt is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<!-- We choose to not include a default namespace       -->
<!-- (in particular  http://www.w3.org/1999/xhtml),     -->
<!-- even if this complicates adding namespaces onto    -->
<!-- derivatives, such as HTML destined for EPUB output -->
<!-- xmlns="http://www.w3.org/1999/xhtml"               -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
>

<!--                       IMPORTANT                         -->
<!-- The "sanitize-text" template can be called on sizeable  -->
<!-- chunks of text, in a recursive manner, and then looks   -->
<!-- like runaway recursion.  "xsltproc" has a "-maxdepth"   -->
<!-- argument.  For the sample article, we increased it from -->
<!-- 3000 to 6000 to prevent a spurious error.               -->

<!-- We assume the source is in great shape, typically having been -->
<!-- created by a pretty-printing tool.  So we keep all the        -->
<!-- whitespace as being of interest to human reader.   This is    -->
<!-- the beauty of a separate stylesheet here:                     -->
<!--   (a) we can override the strip-space declarations            -->
<!--       of the main HTML stylesheet                             -->
<!--   (b) the election of the addition of source annotations      -->
<!--       is made by simply using a different stylesheet          -->
<xsl:preserve-space elements="*"/>
<!-- But whitespace in the root element gets regurgitated          -->
<!-- outside/before/above any file writing and ends up on the      -->
<!-- terminal.  So we kill it with no loss.                        -->
<xsl:strip-space elements="pretext"/>

<!-- Consistent and unique filenames, in a directory of their own  -->
<xsl:template match="*" mode="annotation-knowl-filename">
    <xsl:text>annotate/</xsl:text>
    <xsl:apply-templates select="." mode="html-id"/>
    <xsl:text>.html</xsl:text>
</xsl:template>

<!-- Below, we use a purpose-built attribute to match elements which    -->
<!-- have been through the pre-proccessor with their (nearly-)original  -->
<!-- progenitors.  So we need this id here, late in the game, but we    -->
<!-- don't want authors wondering if they should be authoring it in     -->
<!-- their source.  So at the kast minute, while creating text versions -->
<!-- of source materil, we kill it.  Any similar leakage could be       -->
<!-- handled the same way.                                              -->
<xsl:template match="@original-id" mode="serialize"/>

<!-- The template to place into the HTML stylesheet, which is        -->
<!-- overriding a do-nothing stub in the HTML stylesheet.  This is   -->
<!-- a no-op unless the $b-view-source has been set to true()        -->
<!-- electively.  Not too much of a performance hit as bailing out   -->
<!-- is quick, and use is limited to divisions and blocks (roughly). -->
<xsl:template match="*" mode="view-source-knowl">
    <!-- Footnotes are silly to annotate, and are also automatically -->
    <!-- generated for URLs and hence have no original source, so we -->
    <!-- kill them here.  Careful experiments suggest these are the  -->
    <!-- only elements without source.                               -->
    <xsl:variable name="b-banned" select="boolean(self::fn)"/>
    <xsl:if test="$b-view-source and not($b-banned)">
        <!-- As a variable for consistency -->
        <xsl:variable name="filename">
            <xsl:apply-templates select="." mode="annotation-knowl-filename"/>
        </xsl:variable>

        <!-- Part 1: drop the clickable for the knowl via placement  -->
        <!-- of the application of the "view-source-knowl" template -->
        <div>
            <!-- A little weak on accessibility        -->
            <!-- No URL in href, always a modern knowl -->
            <!-- No localization of Reveal/Close text  -->
            <a href="" class="xref" data-knowl="{$filename}" data-reveal-label="Open" data-close-label="Close">
                <!-- TODO: internationalize me? -->
                <xsl:text>View Source</xsl:text>
            </a>
        </div>

        <!-- Part 2: Create the knowl's content file -->
        <!-- Save off the id of the element being annotated -->
        <xsl:variable name="the-element-id" select="@original-id"/>
        <!-- Locate the element with the same id, but in a very early -->
        <!-- pass of the assembly stylesheet, so with as little (no?) -->
        <!-- extraneous manufactured markup as possible.              -->
        <xsl:variable name="original-element" select="$original-labeled//*[@original-id = $the-element-id]"/>
        <!-- Just for convenience, capture highly sanitized text      -->
        <!-- version of the XML source within a variable.             -->
        <!--                                                          -->
        <!--   (1) Grab the node *just prior* to the element.         -->
        <!--   (2) This ends with a newline and then some             -->
        <!--       indentation, we grab this indentation.             -->
        <!--   (3) Serialize the element, a photocopy machine         -->
        <!--       which converts XML nodes into text (originally     -->
        <!--       built to put HTML into JSON for Jupyter).          -->
        <!--   (4) Run (2)+(3) through "sanitize-text" mainly to pull -->
        <!--       the whole stanza left, since it may have a lot of  -->
        <!--       common indentation (which is why we caught         -->
        <!--       the preceding indentation).                        -->
        <!-- NB: the $original-element is used *twice* below, in      -->
        <!-- order to have the right conteaxt for the manipulations   -->
        <xsl:variable name="serialized-html">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text">
                    <xsl:variable name="lead-in">
                        <xsl:apply-templates select="$original-element/preceding-sibling::node()[1]" mode="serialize">
                            <xsl:with-param name="as-authored-source" select="'yes'"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <xsl:call-template name="substring-after-last">
                        <xsl:with-param name="input" select="$lead-in" />
                        <xsl:with-param name="substr" select="'&#xa;'" />
                    </xsl:call-template>
                    <xsl:apply-templates select="$original-element" mode="serialize">
                        <xsl:with-param name="as-authored-source" select="'yes'"/>
                    </xsl:apply-templates>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <!--                                                      -->
        <!-- Useful for debugging any source manipulations, as it -->
        <!-- can be dropped right in the page for quick visual    -->
        <!-- examination/comparison.                              -->
        <!-- <pre><xsl:value-of select="$serialized-html"/></pre> -->
        <!--                                                      -->
        <!-- The file part of the knowl -->
        <exsl:document href="{$filename}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
            <html>
                <body>
                    <pre>
                        <xsl:value-of select="$serialized-html"/>
                    </pre>
                </body>
            </html>
        </exsl:document>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>