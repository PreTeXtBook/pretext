<?xml version='1.0'?>

<!--********************************************************************
Copyright 2019 Andrew Rechnitzer, Steven Clontz, Robert A. Beezer

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

<!-- "pi" necessary to trap "visual" URLs automatically being -->
<!-- added by "assembly" for with-content "url" elements      -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl date str"
    exclude-result-prefixes="svg"
>

<!-- Necessary to get some HTML constructions,    -->
<!-- but want to be sure to override the entry    -->
<!-- template to avoid chunking, etc.             -->
<!-- The pretext-assembly stylesheet is employed, -->
<!-- so be sure to use the right trees in the     -->
<!-- entry template                               -->
<xsl:import href="pretext-html.xsl" />

<!-- Disable clipboardable -->
<xsl:template name="insert-clipboardable-class"/>

<!-- Used to identify build target in templates shared with plain  -->
<!-- HTML conversion (preferably avoid using this).                -->
<xsl:variable name="b-reveal-build" select="true()" />

<!-- Embedded mathematics: files of per-equation SVG and speech     -->
<!-- representations, keyed by id, manufactured at build time by    -->
<!-- the "mathjax_latex()" routine and passed in here as string     -->
<!-- parameters.  Both are empty for online mathematics (the        -->
<!-- default), and then the derived variables are empty node-sets,  -->
<!-- never consulted.                                               -->
<xsl:param name="mathfile" select="''"/>
<xsl:param name="speechfile" select="''"/>
<xsl:variable name="math-repr" select="document($mathfile)/pi:math-representations"/>
<xsl:variable name="speech-repr" select="document($speechfile)/pi:math-representations"/>

<!-- Reveal.js output is one monolithic page, so heading levels are -->
<!-- threaded, not chunked.  The slideshow title (h1) and subtitle  -->
<!-- (h2) are fixed.  A "section" is always level 2 (sections never -->
<!-- nest in a slideshow), so a "slide" title is level 3 when there -->
<!-- are sections and level 2 when there are none; slide content    -->
<!-- begins one level deeper.                                       -->
<xsl:variable name="b-reveal-has-sections" select="boolean($root/slideshow/section)"/>
<xsl:variable name="reveal-slide-heading-level">
    <xsl:choose>
        <xsl:when test="$b-reveal-has-sections">
            <xsl:text>3</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>2</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- HTML5 format -->
<xsl:output method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat"/>

<!-- Publisher Switches -->
<!-- Various configuration options are set in the publisher file,  -->
<!-- which is analyzed by its own stylesheet, which is imported in -->
<!-- the process of importing the pretext-html.xsl stylesheet.     -->

<!-- ################ -->
<!-- # Entry Template -->
<!-- ################ -->

<!-- We override the entry template, so as to avoid the "chunking"    -->
<!-- procedure, since we are going to *always* produce one monolithic -->
<!-- HTML file as the output/slideshow                                -->
<xsl:template match="/">
    <xsl:call-template name="reveal-warnings"/>
    <xsl:apply-templates select="$original" mode="generic-warnings"/>
    <xsl:apply-templates select="$original" mode="element-deprecation-warnings"/>
    <xsl:apply-templates select="$original" mode="parameter-deprecation-warnings"/>
    <xsl:apply-templates select="$root"/>
</xsl:template>

<xsl:template match="/pretext">
  <xsl:apply-templates select="slideshow" />
</xsl:template>

<!-- Kill creation of the index page from the -html -->
<!-- conversion (we just build one monolithic page) -->
<xsl:variable name="html-index-page" select="/.."/>

<!-- Kill knowl-ing of various environments -->
<xsl:template match="&THEOREM-LIKE;|&PROOF-LIKE;|&DEFINITION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|task|&FIGURE-LIKE;|&REMARK-LIKE;|&GOAL-LIKE;|exercise" mode="is-hidden">
    <xsl:text>no</xsl:text>
</xsl:template>

<!-- The HTML conversion computes a global "universal" Table of    -->
<!-- Contents for the sidebar.  Then later, for each page it sees  -->
<!-- some customization.  So we reset the variable here, and that  -->
<!-- also means the work done in the "toc-items" template never    -->
<!-- occurs.  (And even better, doing the work was exposing that   -->
<!-- the "level" template wasn't working right for a "slideshow".) -->
<xsl:variable name="toc-cache-rtf" select="''"/>

<!-- Write the infrastructure for a page -->
<xsl:template match="slideshow">
    <xsl:call-template name="converter-blurb-html" />
    <html>
        <head>
            <title>
                <xsl:apply-templates select="." mode="title-simple" />
            </title>

            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=yes"></meta>

            <xsl:call-template name="sagecell-code" />
            <xsl:apply-templates select="." mode="sagecell" />
            <xsl:call-template name="syntax-highlight"/>

            <!-- load reveal.js resources; w/ v 6.x                 -->
            <!-- paths are relative to the distribution's "dist"    -->
            <!-- directory, whose layout a "local" resource host    -->
            <!-- must reproduce                                     -->
            <link href="{$reveal-root}/reset.css" rel="stylesheet"></link>
            <link href="{$reveal-root}/reveal.css" rel="stylesheet"></link>
            <link href="{$reveal-root}/theme/{$reveal-theme}.css" rel="stylesheet"></link>
            <script src="{$reveal-root}/reveal.js"></script>
            <!-- embedded mathematics needs no typesetting, so no math plugin -->
            <xsl:if test="not($b-reveal-embedded-math)">
                <script src="{$reveal-root}/plugin/math.js"></script>
            </xsl:if>

            <link href="_static/pretext/css/pretext-reveal.css" rel="stylesheet"></link>
          <style>
            <xsl:if test="$b-reveal-embedded-math">
                <!-- layout for build-time SVG images of mathematics; the -->
                <!-- class names are those of the EPUB conversion, which  -->
                <!-- pioneered this device                                -->
                <xsl:text>span.mjpage { display: inline; }&#xa;</xsl:text>
                <xsl:text>span.mjpage__block { display: block; text-align: center; margin: 0.5em 0; }&#xa;</xsl:text>
            </xsl:if>
          </style>
          <xsl:call-template name="diagcess-header"/>

          <!-- custom-css, if specified, should be last -->
          <xsl:if test="not($reveal-custom-css = '')">
              <xsl:variable name="csses" select="str:tokenize($reveal-custom-css, ', ')"/>
              <xsl:for-each select="$csses">
                  <link rel="stylesheet" type="text/css">
                      <xsl:attribute name="href">
                          <xsl:value-of select="." />
                      </xsl:attribute>
                  </link>
              </xsl:for-each>
          </xsl:if>
        </head>

        <body>
            <div class="reveal ptx-content">
                <!-- For mathematics/MathJax, must be located  -->
                <!-- within div.reveal to be effective.  With  -->
                <!-- embedded mathematics the macros are baked -->
                <!-- into the SVG images at build time, so the -->
                <!-- hidden macro division would be inert.     -->
                <xsl:if test="not($b-reveal-embedded-math)">
                    <xsl:apply-templates select="." mode="latex-macros"/>
                </xsl:if>
                <div class="slides">
                     <xsl:apply-templates select="frontmatter"/>
                    <xsl:apply-templates select="section|slide"/>
                </div>
            </div>
            <xsl:call-template name="diagcess-footer"/>
        </body>

        <script>
            <xsl:text>&#xa;</xsl:text>
            <xsl:text>Reveal.initialize({&#xa;</xsl:text>
            <xsl:text>  controls: </xsl:text>
                <xsl:choose>
                    <xsl:when test="$b-reveal-control-display">
                        <xsl:text>true</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>false</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            <xsl:text>,&#xa;</xsl:text>
            <xsl:text>  controlsTutorial: </xsl:text>
                <xsl:choose>
                    <xsl:when test="$b-reveal-control-tutorial">
                        <xsl:text>true</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>false</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            <xsl:text>,&#xa;</xsl:text>
            <xsl:text>  controlsLayout: '</xsl:text>
                <xsl:value-of select="$reveal-control-layout"/>
            <xsl:text>',&#xa;</xsl:text>
            <xsl:text>  controlsBackArrows: '</xsl:text>
                <xsl:value-of select="$reveal-control-backarrow"/>
            <xsl:text>',&#xa;</xsl:text>
            <xsl:text>  navigationMode: '</xsl:text>
                <xsl:value-of select="$reveal-navigation-mode"/>
            <xsl:text>',&#xa;</xsl:text>
            <xsl:text>  progress: false,&#xa;</xsl:text>
            <xsl:text>  center: false,&#xa;</xsl:text>
            <xsl:text>  hash: true,&#xa;</xsl:text>
            <xsl:text>  transition: 'fade',&#xa;</xsl:text>
            <xsl:text>  width: "100%",&#xa;</xsl:text>
            <xsl:text>  height: "100%",&#xa;</xsl:text>
            <xsl:text>  margin: "0.025",&#xa;</xsl:text>
            <xsl:choose>
                <!-- Embedded mathematics is finished SVG images: -->
                <!-- no math plugin, no typesetting configuration -->
                <xsl:when test="$b-reveal-embedded-math">
                    <xsl:text>  plugins: []&#xa;</xsl:text>
                </xsl:when>
                <!-- Explicitly enable AMS-style inline \(...\),      -->
                <!-- and explicitly disable TeX-style inline $...$    -->
                <!-- The main HTML conversion does not do anything    -->
                <!-- special for display math, so we disable any such -->
                <!-- markup, since we use environments exclusively.   -->
                <!-- N.B. default HTML adds a "zero-width" space into -->
                <!-- a \( authored in a non-math context.             -->
                <!-- The MathJax version matches the main HTML        -->
                <!-- conversion; the "mathjax4" adapter of the math   -->
                <!-- plugin loads it from the URL given and passes    -->
                <!-- the "tex" object into the MathJax configuration. -->
                <!-- Suggested by  https://revealjs.com/math/, 2026-07-22 -->
                <xsl:otherwise>
                    <xsl:text>  mathjax4: {&#xa;</xsl:text>
                    <xsl:text>    mathjax: 'https://cdn.jsdelivr.net/npm/mathjax@4/tex-mml-chtml.js',&#xa;</xsl:text>
                    <xsl:text>    tex: {&#xa;</xsl:text>
                    <xsl:text>      inlineMath:  [['\\(','\\)']],&#xa;</xsl:text>
                    <xsl:text>      displayMath: [],&#xa;</xsl:text>
                    <xsl:text>    }&#xa;</xsl:text>
                    <xsl:text>  },&#xa;</xsl:text>
                    <xsl:text>  plugins: [ RevealMath.MathJax4 ]&#xa;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>});&#xa;</xsl:text>
        </script>
    </html>
</xsl:template>

<!-- A "section" contains multiple "slide", which we process,   -->
<!-- but first we make a special slide announcing the "section" -->
<!-- With reveal.js navigationMode set to "default" or "grid"   -->
<!-- we organize title slides as the "horizontal" (or major)    -->
<!-- slides, with the slides within a section as the "vertical" -->
<!-- (or minor) slides.  But if the navigationMode is "linear"  -->
<!-- we do not even create this two-deep organization at all,   -->
<!-- in part because we think the linear mode is buggy for      -->
<!-- the last vertical set.                                     -->
<xsl:template match="section">
    <xsl:choose>
        <xsl:when test="($reveal-navigation-mode = 'default') or ($reveal-navigation-mode = 'grid')">
            <section>
                <section>
                    <h2>
                        <xsl:apply-templates select="." mode="title-full"/>
                    </h2>
                </section>
                <xsl:apply-templates select="slide"/>
            </section>
        </xsl:when>
        <xsl:when test="$reveal-navigation-mode = 'linear'">
            <section>
                <h2>
                    <xsl:apply-templates select="." mode="title-full"/>
                </h2>
            </section>
            <xsl:apply-templates select="slide"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:BUG: a reveal.js navigation mode ("<xsl:value-of select="$reveal-navigation-mode"/>") is implemented but the section construction is not prepared for that mode</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="frontmatter">
    <section>
      <section>
        <!-- we assume an overall title exists -->
        <h1>
            <xsl:apply-templates select="$root/slideshow" mode="title-full" />
        </h1>
        <!-- subtitle would be optional, subsidary -->
        <xsl:if test="$root/slideshow/subtitle">
            <h2>
                <xsl:apply-templates select="$root/slideshow" mode="subtitle" />
            </h2>
        </xsl:if>
        <!-- we assume at least one author, these are in a table -->
        <xsl:apply-templates select="titlepage" mode="author-list"/>
        <!-- optional "event" -->
        <xsl:if test="bibinfo/event">
            <h3>
                <xsl:apply-templates select="bibinfo/event"/>
            </h3>
        </xsl:if>
        <!-- optional "date" -->
        <xsl:if test="bibinfo/date">
            <h3>
                <xsl:apply-templates select="bibinfo/date"/>
            </h3>
        </xsl:if>
    </section>
    <xsl:apply-templates select="abstract"/>
  </section>
</xsl:template>

<xsl:template match="titlepage" mode="author-list">
  <table>
  <tr>
  <xsl:for-each select="$bibinfo/author">
    <th align="center" style="border-bottom: 0px;"><xsl:value-of select="personname"/></th>
  </xsl:for-each>
</tr>
  <tr>
  <xsl:for-each select="$bibinfo/author">
    <td align="center" style="border-bottom: 0px;"><xsl:value-of select="affiliation|institution"/></td>
  </xsl:for-each>
</tr>
<tr>
  <xsl:for-each select="$bibinfo/author">
    <td align="center"><xsl:apply-templates select="logo" /></td>
  </xsl:for-each>
  </tr>
</table>
</xsl:template>

<xsl:template match="abstract">
    <section>
          <h2>Abstract</h2>
          <div align="left">
              <xsl:apply-templates select="*"/>
          </div>
    </section>
</xsl:template>

<xsl:template match="slide">
    <section>
          <xsl:variable name="slide-hN">
              <xsl:apply-templates select="." mode="hN">
                  <xsl:with-param name="heading-level" select="$reveal-slide-heading-level"/>
              </xsl:apply-templates>
          </xsl:variable>
          <xsl:element name="{$slide-hN}">
              <xsl:apply-templates select="." mode="title-full" />
          </xsl:element>
          <div align="left">
              <!-- Single monolithic page: heading levels are threaded, not -->
              <!-- chunked.  The slide title is one level below a "section" -->
              <!-- (when present); slide content is one level below that.   -->
              <xsl:apply-templates select="*">
                  <xsl:with-param name="heading-level" select="$reveal-slide-heading-level + 1"/>
              </xsl:apply-templates>
          </div>
      </section>
</xsl:template>

<xsl:template match="subslide">
  <div class="fragment">
    <xsl:apply-templates select="*"/>
  </div>
</xsl:template>

<xsl:template match="ul/li|ol/li">
  <li>
    <xsl:if test="parent::*/@pause = 'yes'">
      <xsl:attribute name="class">
        <xsl:text>fragment</xsl:text>
      </xsl:attribute>
    </xsl:if>
    <!-- content may be structured, or not -->
    <xsl:if test="title">
        <h6 class="heading">
            <span class="title">
                <xsl:apply-templates select="." mode="title-xref"/>
            </span>
        </h6>
    </xsl:if>
    <xsl:apply-templates/>
  </li>
</xsl:template>

<!-- We group dt/dd pairs in a div so that fragments work properly -->
<!-- Yes, this seems to be legitimate HTML structure               -->
<!-- https://www.stefanjudis.com/today-i-learned/                  -->
<!-- divs-are-valid-elements-inside-of-a-definition-list/          -->
<xsl:template match="dl/li">
  <div>
    <xsl:if test="parent::*/@pause = 'yes'">
      <xsl:attribute name="class">
        <xsl:text>fragment</xsl:text>
      </xsl:attribute>
    </xsl:if>
    <dt>
      <xsl:apply-templates select="." mode="title-full"/>
    </dt>
    <dd>
      <!-- assumes content part is structured -->
      <!-- title gets killed on-sight         -->
      <xsl:apply-templates select="*"/>
    </dd>
  </div>
</xsl:template>

<xsl:template match="p">
  <p>
    <xsl:if test="@pause = 'yes'">
      <xsl:attribute name="class">
        <xsl:text>fragment</xsl:text>
      </xsl:attribute>
    </xsl:if>
    <xsl:apply-templates/>
  </p>
</xsl:template>

<!-- Images get wrapped in a div with @class="fragment" if they are  -->
<!-- paused                                                          -->
<xsl:template match="image[not(ancestor::sidebyside) and (@pause='yes')]">
    <div class="fragment">
      <xsl:apply-imports/>
    </div>
</xsl:template>

<!-- Side-By-Side -->
<!-- Same container-declared composition as HTML and LaTeX,        -->
<!-- realized here with CSS table display: margins are declared on -->
<!-- the wrapper div, and each panel div carries its width and     -->
<!-- vertical alignment.  Built by implementing the two abstract   -->
<!-- templates ("panel-panel", "compose-panels") of the -common    -->
<!-- machinery.                                                    -->

<!-- Overall wrapper of a sidebyside  -->
<xsl:template match="sidebyside" mode="compose-panels">
    <xsl:param name="layout" />
    <xsl:param name="panels" />

    <xsl:variable name="left-margin"  select="$layout/left-margin" />
    <xsl:variable name="right-margin" select="$layout/right-margin" />

    <div style="display: table;">
       <xsl:attribute name="class">
            <xsl:text>sidebyside</xsl:text>
       </xsl:attribute>
       <xsl:attribute name="style">
            <xsl:text>display:table;</xsl:text>
            <xsl:text>margin-left:</xsl:text>
            <xsl:value-of select="$left-margin" />
            <xsl:text>;</xsl:text>
            <xsl:text>margin-right:</xsl:text>
            <xsl:value-of select="$right-margin" />
            <xsl:text>;</xsl:text>
        </xsl:attribute>
        <xsl:copy-of select="$panels" />
    </div>
</xsl:template>

<!-- A single panel of the sidebyside -->
<xsl:template match="*" mode="panel-panel">
    <xsl:param name="width" />
    <xsl:param name="left-margin" />
    <xsl:param name="right-margin" />
    <xsl:param name="valign" />

    <xsl:element name="div">
        <xsl:if test="parent::sidebyside/@pause = 'yes'">
          <xsl:attribute name="class">
            <xsl:text>fragment</xsl:text>
          </xsl:attribute>
        </xsl:if>
        <xsl:attribute name="style">
            <xsl:text>display:table-cell;</xsl:text>
            <xsl:text>width:</xsl:text>
            <xsl:call-template name="relative-width">
                <xsl:with-param name="width" select="$width" />
                <xsl:with-param name="left-margin"  select="$left-margin" />
                <xsl:with-param name="right-margin" select="$right-margin" />
            </xsl:call-template>
            <xsl:text>;</xsl:text>
            <!-- top, middle, bottom -->
            <xsl:text>vertical-align:</xsl:text>
            <xsl:value-of select="$valign"/>
            <xsl:text>;</xsl:text>
        </xsl:attribute>
        <!-- Realize each panel's object -->
        <xsl:apply-templates select=".">
            <xsl:with-param name="width" select="$width" />
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

<!-- The content of a cross-reference is computed by the -common  -->
<!-- machinery; on a slide we do not make it a live link, since   -->
<!-- the likely target is a nearby slide and knowls do not exist. -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="target"/>
    <xsl:param name="content"/>
    <xsl:param name="origin"/>
    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- We don't want any permalinks -->
<xsl:template match="*" mode="permalink"/>

<!-- ######## -->
<!-- Bad Bank -->
<!-- ######## -->

<!-- Reveal.js specific, so best to place inside this stylesheet.  -->

<!-- A couple of temporary command-line stringparam will just be    -->
<!-- ignored as this stylesheet was first released about the time   -->
<!-- the publisher file came into existence.                        -->

<!-- 2020-02-09: Stopped using a temporary "theme" stringparam -->
<xsl:param name="theme" select="''"/>
<!-- 2020-02-09: Stopped using a temporary "local" stringparam -->
<xsl:param name="local" select="''"/>

<xsl:template name="reveal-warnings">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Conversion to reveal.js presentations/slideshows is experimental&#xa;Requests for additional specific constructions welcome&#xa;Additional PreTeXt elements are subject to change</xsl:with-param>
    </xsl:call-template>
    <xsl:if test="not($theme = '')">
        <xsl:message >PTX:DEPRECATE: the temporary "theme" stringparam is deprecated and is being ignored by the conversion to a Reveal.js slideshow.  Please switch to using a publisher file to set this option, see documentation in The Guide.  The default theme is "simple".</xsl:message>
        <xsl:text>simple</xsl:text>
    </xsl:if>
    <xsl:if test="not($local = '')">
        <xsl:message >PTX:DEPRECATE: the temporary "local" stringparam is deprecated and is being ignored.  Please switch to using a publisher file to set this option, see documentation in The Guide.  The default behavior is to get resources from a CDN.</xsl:message>
    </xsl:if>
</xsl:template>

<!-- #################### -->
<!-- Embedded Mathematics -->
<!-- #################### -->

<!-- Online mathematics (the default) is authored LaTeX passed      -->
<!-- through, inherited from the HTML conversion, for the math      -->
<!-- plugin and MathJax to typeset in the browser.  Embedded        -->
<!-- mathematics substitutes an SVG image and a speech string,      -->
<!-- both manufactured at build time, so the slideshow performs no  -->
<!-- typesetting at all: the same device as the EPUB conversion,    -->
<!-- whose templates these mirror.  Every "md" has "mrow" children  -->
<!-- once the assembly repairs an authored one-line "md", so the    -->
<!-- match covers all mathematics.  Slides never link to an         -->
<!-- equation (a cross-reference renders as its text), so no HTML   -->
<!-- id is placed, unlike EPUB.                                     -->
<xsl:template match="m|md[mrow]">
    <xsl:choose>
        <xsl:when test="$b-reveal-embedded-math">
            <!-- NB: math-representation file writes with "visible-id" -->
            <xsl:variable name="id">
                <xsl:apply-templates select="." mode="unique-id"/>
            </xsl:variable>
            <xsl:variable name="math" select="$math-repr/pi:math[@id = $id]"/>
            <xsl:variable name="speech" select="$speech-repr/pi:math[@id = $id]"/>
            <span>
                <xsl:attribute name="class">
                    <xsl:choose>
                        <xsl:when test="$math/@context = 'inline'">
                            <xsl:text>mjpage</xsl:text>
                        </xsl:when>
                        <xsl:when test="$math/@context = 'displaymath'">
                            <xsl:text>mjpage mjpage__block</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:apply-templates select="$math/div[@class = 'svg']/svg:svg" mode="svg-edit">
                    <xsl:with-param name="speech" select="$speech"/>
                    <xsl:with-param name="base-id" select="$id"/>
                </xsl:apply-templates>
            </span>
        </xsl:when>
        <!-- online: the usual LaTeX-within-delimiters construction -->
        <xsl:otherwise>
            <xsl:apply-imports/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- MathJax mints an HTML id from an equation's \tag for its own  -->
<!-- \eqref linking, which PreTeXt never uses; a tag used twice    -->
<!-- (symbols as tags invite this) would duplicate the id, so they -->
<!-- are dropped                                                   -->
<xsl:template match="@id[starts-with(., 'mjx-eqn')]" mode="svg-edit"/>

<!-- Identity for the SVG stream-edit -->
<xsl:template match="node()|@*" mode="svg-edit">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="svg-edit"/>
    </xsl:copy>
</xsl:template>

<!-- We enrich the main "svg" element with a speech string.      -->
<!--   1.  Since this is the "entry template" for this mode,     -->
<!--       this is the only place we accept the "speech" param.  -->
<!--   2.  MathJax seems to use SVGs inside of SVGs for placing  -->
<!--       numbers/tags of numbered equations, so we only enrich -->
<!--       "top-level" SVG - that is the point of the filter.    -->
<!--   3.  The id of the math element will be used as the base   -->
<!--       of (unique) ids necessary to point to the speech.     -->
<!--       Pattern 11 at:                                        -->
<!--       https://www.deque.com/blog/creating-accessible-svgs/  -->
<!--   4.  Seems                                                 -->
<!--           "title" + @aria-labelledby                        -->
<!--           "desc"  + @aria-describedby                       -->
<!--       cover all the bases.  It is suggested that the two    -->
<!--       elements alone would be recognized by screen readers. -->
<xsl:template match="svg:svg[not(ancestor::svg:svg)]" mode="svg-edit">
    <xsl:param name="speech"/>
    <xsl:param name="base-id"/>

    <!-- manufacture id values for consistency, uniqueness -->
    <xsl:variable name="title-id">
        <xsl:value-of select="$base-id"/>
        <xsl:text>-title</xsl:text>
    </xsl:variable>
    <xsl:variable name="desc-id">
        <xsl:value-of select="$base-id"/>
        <xsl:text>-desc</xsl:text>
    </xsl:variable>

    <xsl:copy>
        <!-- attributes first -->
        <xsl:apply-templates select="@*" mode="svg-edit"/>
        <xsl:attribute name="role">
            <xsl:text>img</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="aria-labelledby">
            <xsl:value-of select="$title-id"/>
        </xsl:attribute>
        <xsl:attribute name="aria-describedby">
            <xsl:value-of select="$desc-id"/>
        </xsl:attribute>
        <!-- now additional metadata, of sorts -->
        <xsl:element name="title" namespace="http://www.w3.org/2000/svg">
            <xsl:attribute name="id">
                <xsl:value-of select="$title-id"/>
            </xsl:attribute>
            <xsl:text>Math Expression</xsl:text>
        </xsl:element>
        <xsl:element name="desc" namespace="http://www.w3.org/2000/svg">
            <xsl:attribute name="id">
                <xsl:value-of select="$desc-id"/>
            </xsl:attribute>
            <xsl:value-of select="$speech"/>
        </xsl:element>
        <!-- and all the rest of the nodes -->
        <xsl:apply-templates select="node()" mode="svg-edit"/>
    </xsl:copy>
</xsl:template>

</xsl:stylesheet>
