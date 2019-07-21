<?xml version='1.0'?>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
>


<xsl:import href="../pretext/xsl/mathbook-html.xsl" />

<xsl:output method="html" encoding="utf-8"/>

<xsl:template match="pretext">
  <xsl:apply-templates select="article" />
</xsl:template>

<xsl:template match="article|book">
  <xsl:apply-templates select="slideshow" />
</xsl:template>

<xsl:template match="slideshow" mode="is-structural">
    <xsl:value-of select="true()" />
</xsl:template>

<xsl:variable name="chunk-level">
    <xsl:text>0</xsl:text>
</xsl:variable>


<xsl:output method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat"/>

<xsl:template match="slideshow">
	<html>
	<head>
	<title><xsl:apply-templates select="." mode="title-full" /></title>
	<!-- metadata -->
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=yes"></meta>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.8.0/css/reset.min.css" rel="stylesheet"></link>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.8.0/css/reveal.min.css" rel="stylesheet"></link>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.8.0/css/theme/simple.min.css" rel="stylesheet"></link>

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
  </style>

	</head>

	<body>
    <xsl:apply-templates select="/pretext/docinfo/macros"/>

    <div class="reveal">
      <div class="slides">
      <xsl:apply-templates select="." mode="title-slide" />
      <xsl:apply-templates select="section"/>
    </div>
  </div>
	</body>

  <script src="https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.8.0/js/reveal.min.js"></script>

  <script>
    Reveal.initialize({
    				controls: false,
    				progress: false,
    				hash: true,
    				transition: 'fade',
            width: "80%",
            height: "90%",
    				dependencies: [
              { src: 'https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.8.0/plugin/math/math.min.js', async: true },
              ]
            });
  </script>

	</html>

</xsl:template>

<xsl:template match="pretext/docinfo/macros">
  <div style="display: none;">
    <xsl:call-template name="begin-inline-math"/>
    <xsl:value-of select="."/>
    <xsl:call-template name="end-inline-math"/>
  </div>
</xsl:template>

<xsl:template match="section">
  <section>
    <xsl:apply-templates select="slide"/>
  </section>
</xsl:template>

<xsl:template match="slideshow" mode="title-slide">
	<section>
		<h1>
      <xsl:apply-templates select="." mode="title-full" />
    </h1>
		<h2>
      <xsl:apply-templates select="." mode="subtitle" />
    </h2>

    <xsl:apply-templates select="." mode="author-list"/>

	</section>
</xsl:template>

<xsl:template match="slideshow" mode="author-list">
  <table>
  <tr>
  <xsl:for-each select="frontmatter/titlepage/author">
    <th align="center" style="border-bottom: 0px;"><xsl:value-of select="personname"/></th>
  </xsl:for-each>
</tr>
  <tr>
  <xsl:for-each select="frontmatter/titlepage/author">
    <td align="center" style="border-bottom: 0px;"><xsl:value-of select="affiliation|institution"/></td>
  </xsl:for-each>
</tr>
<tr>
  <xsl:for-each select="frontmatter/titlepage/author">
    <td align="center"><xsl:apply-templates select="logo" /></td>
  </xsl:for-each>
  </tr>
</table>
</xsl:template>

<xsl:template match="slide">
	<section>
		<h2>
<xsl:if test="@source-number">
  <xsl:value-of select="@source-label"/>
  <xsl:text> </xsl:text>
  <xsl:value-of select="@source-number"/>:
</xsl:if>
			<xsl:apply-templates select="." mode="title-full" />
		</h2>
		<div align="left">
			<xsl:apply-templates/>
		</div>
	</section>
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

<xsl:template match="li">
  <li>
    <xsl:if test="parent::*/@slide-step = 'true'">
      <xsl:attribute name="class">
        <xsl:text>fragment</xsl:text>
      </xsl:attribute>
    </xsl:if>
    <xsl:apply-templates/>
  </li>
</xsl:template>


<xsl:template match="p">
  <p>
    <xsl:if test="@slide-step = 'true'">
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
    <xsl:if test="@slide-step = 'true'">
      <xsl:attribute name="class">
        <xsl:text>fragment</xsl:text>
      </xsl:attribute>
    </xsl:if>
    <xsl:apply-templates/>
  </img>
</xsl:template>

<xsl:template match="sidebyside">
<div style="display: table;">
  <xsl:for-each select="*">
    <div>
      <xsl:if test="parent::*/@slide-step = 'true'">
        <xsl:attribute name="class">
          <xsl:text>fragment</xsl:text>
        </xsl:attribute>
      </xsl:if>

      <xsl:attribute name="style">
        <xsl:text>display:table-cell; vertical-align:top; width: </xsl:text>
          <xsl:value-of select="../@width" />
          <xsl:text>;</xsl:text>
      </xsl:attribute>
      <xsl:apply-templates select="."/>
    </div>
  </xsl:for-each>
</div>
</xsl:template>

<xsl:template match="subslide">
  <div class="fragment">
    <xsl:apply-templates/>
  </div>
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
