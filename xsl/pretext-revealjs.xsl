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

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
>

<!-- Necessary to get some HTML constructions, -->
<!-- but want to be sure to override the entry -->
<!-- template to avoid chunking, etc.          -->
<xsl:import href="pretext-html.xsl" />

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
    <xsl:apply-templates select="pretext"/>
</xsl:template>

<xsl:template match="/pretext">
  <xsl:apply-templates select="slideshow" />
</xsl:template>

<!-- Kill creation of the index page from the -html -->
<!-- conversion (we just build one monolithic page) -->
<xsl:variable name="html-index-page" select="/.."/>

<!-- Kill knowl-ing of various environments -->
<xsl:template match="&THEOREM-LIKE;|proof|&DEFINITION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|task|&FIGURE-LIKE;|&REMARK-LIKE;|&GOAL-LIKE;|exercise" mode="is-hidden">
    <xsl:text>no</xsl:text>
</xsl:template>

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

            <!-- load reveal.js resources             -->
            <xsl:choose>
                <xsl:when test="$b-reveal-minified">
                    <link href="{$reveal-root}/css/reset.min.css" rel="stylesheet"></link>
                    <link href="{$reveal-root}/css/reveal.min.css" rel="stylesheet"></link>
                    <link href="{$reveal-root}/css/theme/{$reveal-theme}.min.css" rel="stylesheet"></link>
                    <script src="{$reveal-root}/js/reveal.min.js"></script>
                </xsl:when>
                <xsl:otherwise>
                    <link href="{$reveal-root}/css/reset.css" rel="stylesheet"></link>
                    <link href="{$reveal-root}/css/reveal.css" rel="stylesheet"></link>
                    <link href="{$reveal-root}/css/theme/{$reveal-theme}.css" rel="stylesheet"></link>
                    <script src="{$reveal-root}/js/reveal.js"></script>
                </xsl:otherwise>
            </xsl:choose>

            <!-- Explicitly enable AMS-style inline \(...\),      -->
            <!-- and explicitly disable TeX-style inline $...$    -->
            <!-- The main HTML conversion does not do anything    -->
            <!-- special for display math, so we disable any such -->
            <!-- markup, since we use environments exclusively.   -->
            <!-- N.B. default HTML adds a "zero-width" space into -->
            <!-- a \( authored in a non-math context.             -->
            <!-- N.B. This may need to be changed for MathJax 3   -->
            <xsl:comment> Coordinate control of MathJax delimiters </xsl:comment>
            <script type="text/x-mathjax-config">
                <xsl:text>    MathJax.Hub.Config({&#xa;</xsl:text>
                <xsl:text>        tex2jax: {&#xa;</xsl:text>
                <xsl:text>            inlineMath:  [['\\(','\\)']],&#xa;</xsl:text>
                <xsl:text>            displayMath: [],&#xa;</xsl:text>
                <xsl:text>        }&#xa;</xsl:text>
                <xsl:text>    });&#xa;</xsl:text>
            </script>

          <!--  Some style changes from regular pretext-html -->
          <style>
ul {
  display: block !important;
}
.reveal img {
  border: 0.5px !important;
  border-radius: 2px 10px 2px;
  padding: 4px;
}
.definition,.theorem,.activity {
  border-width: 0.5px;
  border-style: solid;
  border-radius: 2px 10px 2px;
  padding: 1%;
  margin-bottom: 2em;
}
.definition {
  background: #00608010;
}
.theorem {
  background: #ff000010;
}
.proof {
  background: #ffffff90;
}
.activity {
  background: #60800010;
}
dfn {
  font-weight: bold;
}
.pretext-content ol.no-marker,
.pretext-content ul.no-marker,
.pretext-content li.no-marker {
    list-style-type: none;
}

.pretext-content ol.decimal {
    list-style-type: decimal;
}
.pretext-content ol.lower-alpha {
    list-style-type: lower-alpha;
}
.pretext-content ol.upper-alpha {
    list-style-type: upper-alpha;
}
.pretext-content ol.lower-roman {
    list-style-type: lower-roman;
}
.pretext-content ol.upper-roman {
    list-style-type: upper-roman;
}
.pretext-content ul.disc {
    list-style-type: disc;
}
.pretext-content ul.square {
    list-style-type: square;
}
.pretext-content ul.circle {
    list-style-type: circle;
}
.pretext-content ol.no-marker,
.pretext-content ul.no-marker {
    list-style-type: none;
}
.pretext-content .cols1 li,
.pretext-content .cols2 li,
.pretext-content .cols3 li,
.pretext-content .cols4 li,
.pretext-content .cols5 li,
.pretext-content .cols6 li {
    float: left;
    padding-right:2em;
}
          </style>

        </head>

        <body>
            <!-- For mathematics/MathJax -->
            <xsl:call-template name="latex-macros"/>

            <div class="reveal pretext-content">
                <div class="slides">
                     <xsl:apply-templates select="frontmatter"/>
                    <xsl:apply-templates select="section|slide"/>
                </div>
            </div>
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
            <xsl:text>  dependencies: [&#xa;</xsl:text>
            <xsl:text>    { src: '</xsl:text>
                <xsl:value-of select="$reveal-root"/><xsl:text>/plugin/math/math.min.js</xsl:text>
            <xsl:text>', async: true },&#xa;</xsl:text>
            <xsl:text>    ]&#xa;</xsl:text>
            <xsl:text>  });&#xa;</xsl:text>
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
                    <h1>
                        <xsl:apply-templates select="." mode="title-full"/>
                    </h1>
                </section>
                <xsl:apply-templates select="slide"/>
            </section>
        </xsl:when>
        <xsl:when test="$reveal-navigation-mode = 'linear'">
            <section>
                <h1>
                    <xsl:apply-templates select="." mode="title-full"/>
                </h1>
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
            <xsl:apply-templates select="/pretext/slideshow" mode="title-full" />
        </h1>
        <!-- subtitle would be optional, subsidary -->
        <xsl:if test="/pretext/slideshow/subtitle">
            <h2>
                <xsl:apply-templates select="/pretext/slideshow" mode="subtitle" />
            </h2>
        </xsl:if>
        <!-- we assume at least one author, these are in a table -->
        <xsl:apply-templates select="titlepage" mode="author-list"/>
        <!-- optional "event" -->
        <xsl:if test="titlepage/event">
            <h4>
                <xsl:apply-templates select="titlepage/event"/>
            </h4>
        </xsl:if>
        <!-- optional "date" -->
        <xsl:if test="titlepage/date">
            <h4>
                <xsl:apply-templates select="titlepage/date"/>
            </h4>
        </xsl:if>
    </section>
    <xsl:apply-templates select="abstract"/>
  </section>
</xsl:template>

<xsl:template match="titlepage" mode="author-list">
  <table>
  <tr>
  <xsl:for-each select="author">
    <th align="center" style="border-bottom: 0px;"><xsl:value-of select="personname"/></th>
  </xsl:for-each>
</tr>
  <tr>
  <xsl:for-each select="author">
    <td align="center" style="border-bottom: 0px;"><xsl:value-of select="affiliation|institution"/></td>
  </xsl:for-each>
</tr>
<tr>
  <xsl:for-each select="author">
    <td align="center"><xsl:apply-templates select="logo" /></td>
  </xsl:for-each>
  </tr>
</table>
</xsl:template>

<xsl:template match="abstract">
    <section>
          <h3>Abstract</h3>
          <div align="left">
              <xsl:apply-templates/>
          </div>
    </section>
</xsl:template>

<xsl:template match="slide">
    <section>
          <h3>
              <xsl:if test="@source-number">
                <xsl:value-of select="@source-label"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="@source-number"/>:
              </xsl:if>
              <xsl:apply-templates select="." mode="title-full" />
          </h3>
          <div align="left">
              <xsl:apply-templates/>
          </div>
      </section>
</xsl:template>

<xsl:template match="subslide">
  <div class="fragment">
    <xsl:apply-templates/>
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


<xsl:template match="image">
  <img>
    <xsl:attribute name="src">
        <xsl:value-of select="@source" />
    </xsl:attribute>
    <xsl:if test="@pause = 'yes'">
      <xsl:attribute name="class">
        <xsl:text>fragment</xsl:text>
      </xsl:attribute>
    </xsl:if>
    <xsl:apply-templates/>
  </img>
</xsl:template>

<!-- Side-By-Side -->
<!-- Built by implementing two abstract   -->
<!-- templates from the -common templates -->

<!-- Overall wrapper of a sidebyside  -->
<xsl:template match="sidebyside" mode="compose-panels">
    <xsl:param name="layout" />
    <xsl:param name="panels" />

    <xsl:variable name="left-margin"  select="$layout/left-margin" />
    <xsl:variable name="right-margin" select="$layout/right-margin" />

    <div style="display: table;">
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

<xsl:template match="definition" mode="type-name">
  <xsl:text>Definition</xsl:text>
</xsl:template>
<xsl:template match="definition">
  <div class="boxed definition">
    <h3>
      <xsl:apply-templates select="." mode="type-name" /> (<xsl:value-of select="@source-number"/>):
      <xsl:apply-templates select="." mode="title-full" />
    </h3>
    <xsl:apply-templates select="statement"/>
</div>
</xsl:template>


<xsl:template match="theorem" mode="type-name">
  <xsl:text>Theorem</xsl:text>
</xsl:template>
<xsl:template match="corollary" mode="type-name">
  <xsl:text>Corollary</xsl:text>
</xsl:template>
<xsl:template match="lemma" mode="type-name">
  <xsl:text>Lemma</xsl:text>
</xsl:template>
<xsl:template match="proposition" mode="type-name">
  <xsl:text>Proposition</xsl:text>
</xsl:template>
<xsl:template match="theorem|corollary|lemma|proposition">
  <div class="theorem">
  <div>
    <h3>
      <xsl:choose>
      <xsl:when test="@source-number">
        <xsl:apply-templates select="." mode="type-name" /> (<xsl:value-of select="@source-number"/>):
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="type-name" />:
      </xsl:otherwise>
    </xsl:choose>
      <xsl:apply-templates select="." mode="title-full" />
    </h3>
      <xsl:apply-templates select="statement"/>
  </div>
  <xsl:if test="proof">
  <div class="proof">
    <xsl:apply-templates select="proof"/>
  </div>
</xsl:if>
</div>
</xsl:template>

<xsl:template match="example" mode="type-name">
  <xsl:text>Example</xsl:text>
</xsl:template>
<xsl:template match="activity" mode="type-name">
  <xsl:text>Activity</xsl:text>
</xsl:template>
<xsl:template match="note" mode="type-name">
  <xsl:text>Note</xsl:text>
</xsl:template>
<xsl:template match="example|activity|note">
  <div class="activity">
    <h3>
      <xsl:apply-templates select="." mode="type-name" /> (<xsl:value-of select="@source-number"/>):
      <xsl:apply-templates select="." mode="title-full" />
    </h3>
      <xsl:apply-templates />
  </div>
</xsl:template>

<xsl:template match="fact" mode="type-name">
  <xsl:text>Fact</xsl:text>
</xsl:template>
<xsl:template match="fact">
  <div class="definition">
    <h3>
      <xsl:apply-templates select="." mode="type-name" /> (<xsl:value-of select="@source-number"/>):
      <xsl:apply-templates select="." mode="title-full" />
    </h3>
      <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="xref">
  [REF=TODO]
</xsl:template>

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
        <xsl:message >PTX:WARNING: the temporary "theme" stringparam is deprecated and is being ignored by the conversion to a Reveal.js slideshow.  Please switch to using a publisher file to set this option, see documentation in The Guide.  The default theme is "simple".</xsl:message>
        <xsl:text>simple</xsl:text>
    </xsl:if>
    <xsl:if test="not($local = '')">
        <xsl:message >PTX:WARNING: the temporary "local" stringparam is deprecated and is being ignored.  Please switch to using a publisher file to set this option, see documentation in The Guide.  The default behavior is to get resources from a CDN.</xsl:message>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>
