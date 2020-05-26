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
<!-- The $publication variable comes from -common and is the result -->
<!-- of a command-line string parameter pointing to an XML file of  -->
<!-- various options.                                               -->
<!-- Elements and attributes of this file are meant to influence    -->
<!-- decisions taken *after* an author is completed writing.        -->
<!-- A couple of temporary command-line stringparam will just be    -->
<!-- ignored as this stylesheet was first released about the time   -->
<!-- the publisher file came into exoistence.                       -->

<!-- 2020-02-09: Stopped using a temporary "theme" stringparam    -->
<!-- NB: change $theme2 back to $theme once this param is deleted -->
<xsl:param name="theme" select="''"/>

<xsl:variable name="theme2">
    <xsl:choose>
        <!-- if stringparam is set, warn and ignore -->
        <xsl:when test="not($theme = '')">
            <xsl:message >PTX:WARNING: the temporary "theme" stringparam is deprecated and is being ignored, so the "simple" theme will be used as long as this stringparam is present.  Please switch to using a publisher file to set this option, see documentation in The Guide.</xsl:message>
            <xsl:text>simple</xsl:text>
        </xsl:when>
        <!-- if publisher.xml file has theme specified, use it -->
        <xsl:when test="$publication/revealjs/appearance/@theme">
            <xsl:value-of select="$publication/revealjs/appearance/@theme"/>
        </xsl:when>
        <!-- otherwise use "simple" as the default -->
        <xsl:otherwise>
            <xsl:text>simple</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- CSS/JS resources that make up reveal.js -->

<!-- 2020-02-09: Stopped using a temporary "local" stringparam    -->
<xsl:param name="local" select="''"/>

<!-- String to prefix  reveal.js  resources -->
<xsl:variable name="reveal-root">
    <!-- CDN is used twice, so just edit here -->
    <!-- NB: deprecation is frozen -->
    <xsl:variable name="cdn-url">
        <xsl:text>https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.8.0</xsl:text>
    </xsl:variable>

    <xsl:choose>
        <xsl:when test="not($local = '')">
            <xsl:message >PTX:WARNING: the temporary "local" stringparam is deprecated and is being ignored, so the reveal.js rsources will come from a CDN and are frozen at version 3.8.0 which is not supported by the PreTeXt conversion.  Please switch to using a publisher file to set this option, see documentation in The Guide.</xsl:message>
            <xsl:text>https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.8.0</xsl:text>
        </xsl:when>
        <!-- if publisher.xml file has CDN option specified, use it       -->
        <!-- keep this URL updated, but not for the deprecation situation -->
        <xsl:when test="$publication/revealjs/resources/@host = 'cdn'">
            <xsl:value-of select="$cdn-url"/>
        </xsl:when>
        <!-- if publisher.xml file has the local option specified, use it -->
        <xsl:when test="$publication/revealjs/resources/@host = 'local'">
            <xsl:text>.</xsl:text>
        </xsl:when>
        <!-- Experimental - just some file path/url -->
        <xsl:when test="$publication/revealjs/resources/@host">
            <xsl:value-of select="$publication/revealjs/resources/@host"/>
        </xsl:when>
        <!-- default to the CDN if no specification -->
        <xsl:otherwise>
            <xsl:value-of select="$cdn-url"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Minified CSS/JS -->
<!-- Resources from a CDN come in a minified version typically.    -->
<!-- But a local version does not have these files available.      -->
<!-- So we provide sensible defaults and let a publisher override. -->

<xsl:variable name="minified">
    <xsl:choose>
        <!-- explict is recognized first, only "yes" activates minified -->
        <xsl:when test="$publication/revealjs/resources/@minified">
            <xsl:choose>
                <xsl:when test="$publication/revealjs/resources/@minified = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>no</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- for PTX-supplied CDN, assume minified is best -->
        <xsl:when test="$publication/revealjs/resources/@host = 'cdn'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <!-- and for a local copy, assume no minified copy exists -->
        <xsl:when test="$publication/revealjs/resources/@host = 'local'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- else some host, but we don't have any idea -->
        <!-- so don't get fancy, and go without minified -->
        <xsl:when test="$publication/revealjs/resources/@host">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- no @minified, and no @host, so we have     -->
        <!-- defaulted to CDN and minified is suggested -->
        <xsl:otherwise>
            <xsl:text>yes</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- Convert "yes"/"no" to a boolean variable -->
<xsl:variable name="b-minified" select="$minified = 'yes'"/>


<!-- ################ -->
<!-- # Entry Template -->
<!-- ################ -->

<!-- We override the entry template, so as to avoid the "chunking"    -->
<!-- procedure, since we are going to *always* produce one monolithic -->
<!-- HTML file as the output/slideshow                                -->
<xsl:template match="/">
    <xsl:apply-templates select="pretext"/>
</xsl:template>

<xsl:template match="/pretext">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Conversion to reveal.js presentations/slideshows is experimental&#xa;Requests for additional specific constructions welcome&#xa;Additional PreTeXt elements are subject to change</xsl:with-param>
    </xsl:call-template>
    <!--  -->
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
                <xsl:when test="$b-minified">
                    <link href="{$reveal-root}/css/reset.min.css" rel="stylesheet"></link>
                    <link href="{$reveal-root}/css/reveal.min.css" rel="stylesheet"></link>
                    <link href="{$reveal-root}/css/theme/{$theme2}.min.css" rel="stylesheet"></link>
                    <script src="{$reveal-root}/js/reveal.min.js"></script>
                </xsl:when>
                <xsl:otherwise>
                    <link href="{$reveal-root}/css/reset.css" rel="stylesheet"></link>
                    <link href="{$reveal-root}/css/reveal.css" rel="stylesheet"></link>
                    <link href="{$reveal-root}/css/theme/{$theme2}.css" rel="stylesheet"></link>
                    <script src="{$reveal-root}/js/reveal.js"></script>
                </xsl:otherwise>
            </xsl:choose>

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
          </style>

        </head>

        <body>
            <!-- For mathematics/MathJax -->
            <xsl:call-template name="latex-macros"/>

            <div class="reveal">
                <div class="slides">
                     <xsl:apply-templates select="frontmatter"/>
                    <xsl:apply-templates select="section|slide"/>
                </div>
            </div>
        </body>

        <script>
Reveal.initialize({
  controls: false,
  progress: false,
  center: false,
  hash: true,
  transition: 'fade',
  width: "100%",
  height: "100%",
  margin: "0.025",
  dependencies: [
    { src: '<xsl:value-of select="$reveal-root"/>/plugin/math/math.min.js', async: true },
    ]
  });
        </script>
    </html>
</xsl:template>

<!-- A "section" contains multiple "slide", which we process,   -->
<!-- but first we make a special slide announcing the "section" -->
<xsl:template match="section">
    <section>
        <section>
            <h1>
                <xsl:apply-templates select="." mode="title-full"/>
            </h1>
        </section>
        <xsl:apply-templates select="slide"/>
    </section>
    <!--  -->
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
        <!-- optional "event" -->
        <xsl:if test="event">
            <h4>
                <xsl:apply-templates select="event"/>
            </h4>
        </xsl:if>
        <!-- optional "date" -->
        <xsl:if test="date">
            <h4>
                <xsl:apply-templates select="date"/>
            </h4>
        </xsl:if>
        <!-- we assume at least one author, these are in a table -->
        <xsl:apply-templates select="titlepage" mode="author-list"/>
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

<xsl:template match="ul">
  <ul>
    <xsl:apply-templates/>
  </ul>
</xsl:template>

<xsl:template match="ol">
  <ol>
    <xsl:apply-templates/>
  </ol>
</xsl:template>

<xsl:template match="dl">
  <dl>
    <xsl:apply-templates select="li"/>
  </dl>
</xsl:template>


<xsl:template match="ul/li|ol/li">
  <li>
    <xsl:if test="parent::*/@pause = 'yes'">
      <xsl:attribute name="class">
        <xsl:text>fragment</xsl:text>
      </xsl:attribute>
    </xsl:if>
    <!-- content may be structured, or not -->
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

</xsl:stylesheet>
