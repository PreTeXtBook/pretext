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

<!-- Below, we use a purpose-built attribute to match elements which    -->
<!-- have been through the pre-proccessor with their (nearly-)original  -->
<!-- progenitors.  So we need this id here, late in the game, but we    -->
<!-- don't want authors wondering if they should be authoring it in     -->
<!-- their source.  So at the last minute, while creating text versions -->
<!-- of source material, we kill it.  Any similar leakage could be      -->
<!-- handled the same way.                                              -->
<xsl:template match="@original-id" mode="xml-to-string"/>


<!-- N.B.: the -assembly stylesheet first construct a "version" which   -->
<!-- is the resolution of version support and customizations.  Then     -->
<!-- "original-id" are added in the next pass.  These are solely for    -->
<!-- the purpose of "going back" to this second pass to identify pieces -->
<!-- of a document before the assembly process perturbs them.  So the   -->
<!-- key tree this next template acts on is in the variable             -->
<!-- $original-labeled.  Just above we explain how these id's get       -->
<!-- scrubbed before presenting source to the reader.                   -->

<!-- The template to place into the HTML stylesheet, which is        -->
<!-- overriding a do-nothing stub in the HTML stylesheet.  This is   -->
<!-- a no-op unless the $b-view-source has been set to true()        -->
<!-- electively.  Not too much of a performance hit as bailing out   -->
<!-- is quick, and use is limited to divisions and blocks (roughly). -->
<xsl:template match="*" mode="view-source-widget">
    <!-- Footnotes are silly to annotate, and are also automatically -->
    <!-- generated for URLs and hence have no original source, so we -->
    <!-- kill them here.  Careful experiments suggest these are the  -->
    <!-- only elements without source.                               -->
    <xsl:variable name="b-banned" select="boolean(self::fn)"/>
    <!-- Allow for annotations of select elements                    -->
    <xsl:variable name="include-source" select="@include-source = 'yes'"/>
    <xsl:if test="($b-view-source and not($b-banned)) or $include-source">
        <!-- Part 1: Serialize the source -->
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
        <!--   (5) Run that through "sanitize-text" to deindent       -->
        <!-- NB: the $original-element is used *twice* below, in      -->
        <!-- order to have the right conteaxt for the manipulations   -->
        <xsl:variable name="serialized-html">
            <xsl:variable name="serialized-html-raw">
                <xsl:variable name="lead-in">
                    <xsl:apply-templates select="$original-element/preceding-sibling::node()[1]" mode="xml-to-string">
                        <xsl:with-param name="depth" select="1"/>
                    </xsl:apply-templates>
                </xsl:variable>
                <xsl:call-template name="substring-after-last">
                    <xsl:with-param name="input" select="$lead-in" />
                    <xsl:with-param name="substr" select="'&#xa;'" />
                </xsl:call-template>
                <xsl:apply-templates select="$original-element" mode="xml-to-string">
                    <xsl:with-param name="depth" select="1"/>
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text">
                    <xsl:value-of select="$serialized-html-raw"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>

        <!-- Part 2: drop the source into a details on the page -->
        <details class="source-view">
          <summary class="source-view__link" data-reveal-label="Open" data-close-label="Close">
              <!-- TODO: internationalize me? -->
              <xsl:text>View Source for </xsl:text><xsl:value-of select="name()"/>
          </summary>
          <!-- -->
          <article class="view-source-view__content" >
              <pre>
                  <code class="language-xml">
                      <xsl:value-of select="$serialized-html"/>
                  </code>
              </pre>
          </article>
      </details>

    </xsl:if>
</xsl:template>

</xsl:stylesheet>