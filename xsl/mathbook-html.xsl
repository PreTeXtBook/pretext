<?xml version='1.0'?> <!-- As XML file -->
<!-- Identify as a stylesheet -->
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
>
    
<xsl:import href="./mathbook-common.xsl" />

<!-- Intend output for rendering by a web browser -->
<xsl:output method="html" indent="yes"/>


<xsl:template match="/">
<!-- doctype as text, normally in xsl:output above -->
<xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html></xsl:text>
<html>
    <head>
        <!-- http://webdesignerwall.com/tutorials/responsive-design-in-3-steps -->
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title><xsl:apply-templates select="//docinfo/title/node()" /></title>
        <xsl:call-template name="mathjax" />
        <xsl:call-template name="sagecell" />
        <xsl:call-template name="knowl" />
        <link rel="stylesheet" type="text/css" href="mathbook.css" />
    </head>
    <xsl:apply-templates />
</html>
</xsl:template>

<xsl:template match="article">
    <body class="article">
        \(<xsl:value-of select="docinfo/macros" />\)
        <div class="headerblock">
            <div class="title"><xsl:apply-templates select="docinfo/title/node()" /></div>
            <div class="authorgroup"><xsl:apply-templates select="docinfo/author" /></div>
            <div class="date"><xsl:apply-templates select="docinfo/date" /></div>
        </div>
        <xsl:apply-templates select="section|bibliography|p|sage|theorem|corollary|lemma|definition|figure" />
    </body>
</xsl:template>

<xsl:template match="book">
    <body class="book">
        \(<xsl:value-of select="docinfo/macros" />\)
        <div class="headerblock">
            <div class="title"><xsl:apply-templates select="docinfo/title/node()" /></div>
            <div class="authorgroup"><xsl:apply-templates select="docinfo/author" /></div>
            <div class="date"><xsl:apply-templates select="docinfo/date" /></div>
        </div>
        <xsl:call-template name="toc" />
        <xsl:apply-templates />
    </body>
</xsl:template>

<!-- Kill docinfo, so not done twice -->
<xsl:template match="docinfo"></xsl:template>


<!-- Author, single one at titlepage -->
<xsl:template match="author">
    <div class="author-name"><xsl:apply-templates select="personname" /></div>
    <div class="author-department"><xsl:apply-templates select="department" /></div>
    <div class="author-institution"><xsl:apply-templates select="institution" /></div>
    <div class="author-email">
    <!-- TODO: Replace and test generic email template, but keep enclosing div -->
        <xsl:element name="a">
            <xsl:attribute name="href">
                mailto:<xsl:apply-templates select="email" />
            </xsl:attribute>
            <xsl:apply-templates select="email" />
        </xsl:element>
    </div>
</xsl:template>

<!-- Table of contents for front page -->
<!-- TODO: Appendices -->
<xsl:template name="toc">
    <xsl:for-each select="//chapter">
    <!-- Move class into a with display block attribute? -->
        <div class="toc-entry">
            <a href="{@filebase}.html">
            Chapter <xsl:apply-templates select="." mode="number" /> <xsl:apply-templates select="title/node()" />
            </a><br />
        </div>
    </xsl:for-each>
</xsl:template>

<!-- Preface, automatic title, no subsections, etc         -->
<xsl:template match="preface">
    <div class="preface">
        <div class="title">
            <xsl:text>Preface</xsl:text>
        </div>
        <xsl:apply-templates />
    </div>
</xsl:template>

<!-- Titles are handled specially                     -->
<!-- so get killed via apply-templates                -->
<!-- When needed, get content with XPath title/node() -->
<xsl:template match="title"></xsl:template>

<!-- Titles are handled specially                     -->
<!-- so get killed via apply-templates                -->
<!-- When needed, get content with XPath title/node() -->
<xsl:template match="title">
</xsl:template>


<!-- Chapters, numbered, with title         -->
<!-- TODO: adjust for appendices -->
<xsl:template match="chapter|appendix">
    <exsl:document href="{@filebase}.html" method="html">
    <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html></xsl:text>
    <html>
        <head>
            <!-- http://webdesignerwall.com/tutorials/responsive-design-in-3-steps -->
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title><xsl:apply-templates select="//docinfo/title/node()" /></title>
            <xsl:call-template name="mathjax" />
            <xsl:call-template name="sagecell" />
            <xsl:call-template name="knowl" />
            <link rel="stylesheet" type="text/css" href="mathbook.css" />
        </head>
        <body>
        <xsl:call-template name="page-navigation-bar" />    
        <xsl:element name="div">
            <xsl:attribute name="class">chapter</xsl:attribute>
            <xsl:element name="div">
                <xsl:attribute name="class">heading</xsl:attribute>
                <xsl:element name="div">
                    <xsl:attribute name="class">number</xsl:attribute>
                    <xsl:apply-templates select="." mode="number" />
                </xsl:element>
                <xsl:element name="div">
                    <xsl:attribute name="class">title</xsl:attribute>
                    <xsl:apply-templates select="title/node()" />
                </xsl:element>
            </xsl:element>
            \(<xsl:value-of select="//docinfo/macros" />\)
            <xsl:apply-templates />
        </xsl:element>
        <xsl:call-template name="page-navigation-bar" />
        </body>
    </html>
    </exsl:document>
</xsl:template>

<!-- Page Navigation Bar -->
<!-- TODO: General enough for subsections? -->
<!-- http://stackoverflow.com/questions/12347412/concept-xml-xlst-preceding-sibling-and-ancestor -->
<!-- http://stackoverflow.com/questions/10367387/are-there-css-alternatives-to-the-deprecated-html-attributes-align-and-valign -->
<xsl:template name="page-navigation-bar">
    <table class="page-nav-bar">
        <tr>
        <td class="previous">
        <a href="{preceding-sibling::*[1]/@filebase}.html">
            <xsl:apply-templates select="preceding-sibling::*[1]/title/node()" />
        </a>
        </td>
        <td class="up">
        <a href="{parent::*/@filebase}.html">
            <xsl:apply-templates select="parent::*/title/node()" />
        </a>
        </td>
        <td class="next">
        <a href="{following-sibling::*[1]/@filebase}.html">
            <xsl:apply-templates select="following-sibling::*[1]/title/node()" />
        </a>
        </td>
        </tr>
    </table>
</xsl:template>

<!-- Sections, with titles and numbers         -->
<xsl:template match="section">
    <xsl:element name="div">
        <xsl:attribute name="class">section</xsl:attribute>
        <xsl:element name="div">
            <xsl:attribute name="class">heading</xsl:attribute>
            <xsl:element name="div">
                <xsl:attribute name="class">number</xsl:attribute>
                <xsl:apply-templates select="." mode="number" />
            </xsl:element>
            <xsl:element name="div">
                <xsl:attribute name="class">title</xsl:attribute>
                <xsl:apply-templates select="title/node()" />
            </xsl:element>
        </xsl:element>
        <xsl:apply-templates />
    </xsl:element>
</xsl:template>

<!-- Subsections, with titles and numbers         -->
<xsl:template match="subsection">
    <div class="subsection">
        <div class="title">
            <xsl:apply-templates select="." mode="number" />
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="title/node()" />
        </div>
        <xsl:apply-templates />
    </div>
</xsl:template>






<!-- Theorem-Like and Proofs                                             -->
<!-- <statement>s and <proof>s are sequences of paragraphs               -->
<!-- First paragreph includes header of sorts                            -->
<!-- Text should be moved to CSS as "content-before" and be overideable  -->
<!-- Theorems are numbered within sections, could be configurable        -->

<!-- Theorems, Proofs, Definitions, Examples -->

<!-- Theorems have statement/proof structure               -->
<!-- Definitions have notation, which is handled elsewhere -->
<!-- Examples have no additional structure                 -->
<!-- TODO: consider optional titles -->

<!-- Break this out into three and add enclosing divs? -->
<!-- Or use a type? -->
<xsl:template match="theorem|corollary|lemma|definition">
    <div class="{local-name()}"> 
        <xsl:apply-templates select="." mode="label" />
        <div class="statement">
            <xsl:apply-templates select="statement" />
        </div>
        <xsl:if test="proof">
            <div class="proof">
                <xsl:apply-templates select="proof" />
            </div>
        </xsl:if>
    </div>
</xsl:template>


<!--Decide how to handle "Theorem 4.3 (A result of Beezer)"
as a lead-in to paragraph one, or a title div
preferably with CSS so can adjust style, language-->

<!-- And consolidate numbering -->
<!-- CSS: div for title, span for paragraph lead-in?  visible, invisible -->



<xsl:template match="theorem/statement/p[1]">
    <p>
        <span class="theorem-header">
        <xsl:text>Theorem </xsl:text>
        <xsl:apply-templates select="../.." mode="number" />
        <xsl:text> </xsl:text>
        </span>
        <xsl:apply-templates />
    </p>
</xsl:template>

<xsl:template match="lemma/statement/p[1]">
    <p>
        <span class="lemma-header">
        <xsl:text>Lemma </xsl:text>
        <xsl:apply-templates select="../.." mode="number" />
        <xsl:text> </xsl:text>
        </span>
        <xsl:apply-templates />
    </p>
</xsl:template>

<xsl:template match="corollary/statement/p[1]">
    <p>
        <span class="corollary-header">
        <xsl:text>Corollary </xsl:text>
        <xsl:apply-templates select="../.." mode="number" />
        <xsl:text> </xsl:text>
        </span>
        <xsl:apply-templates />
    </p>
</xsl:template>

<!-- TODO:  Sync, or adjust, the following -->

<xsl:template match="definition/statement/p[1]">
<p><span class="definition-header">Definition <xsl:apply-templates select="../.." mode="number" /><xsl:text> </xsl:text></span><xsl:apply-templates /></p>
</xsl:template>

<xsl:template match="notation">
<p>Sample notation (in a master list eventually): \(<xsl:value-of select="." />\)</p>
</xsl:template>

<xsl:template match="proof/p[1]">
<p><span class="proof-header">Proof<xsl:text> </xsl:text></span><xsl:apply-templates /></p>
</xsl:template>


<!-- Wrap generic paragraphs in p tag -->
<xsl:template match="p">
<p><xsl:apply-templates /></p>
</xsl:template>


<!-- Pass-through stock HTML for lists-->
<xsl:template match="ol|ul|li">
    <xsl:copy>
        <xsl:apply-templates />
    </xsl:copy>
</xsl:template>




<!-- Figures and Captions -->
<xsl:template match="figure">
    <div class="figure">
        <xsl:apply-templates select="image|p" />
        <xsl:apply-templates select="caption" />
    </div>
</xsl:template>

<xsl:template match="caption">
    <div class="caption">
        <xsl:text>Figure </xsl:text>
        <xsl:apply-templates select="." mode="number"/>
        <xsl:text>: </xsl:text><xsl:apply-templates />
        <xsl:apply-templates select=".." mode="label" />
    </div>
</xsl:template>

<!-- Images -->
<xsl:template match="image" >
<xsl:element name="img">
    <xsl:if test="@width">
        <xsl:attribute name="width"><xsl:value-of select="@width" /></xsl:attribute>
    </xsl:if>
    <xsl:if test="@height">
        <xsl:attribute name="height"><xsl:value-of select="@height" /></xsl:attribute>
    </xsl:if>
    <xsl:attribute name="src"><xsl:value-of select="@source" /></xsl:attribute>
</xsl:element>
</xsl:template>

<!-- Numbering  -->

<!-- Figures:  chapter.x -->
<xsl:template match="caption" mode="number">
    <xsl:number level="single" count="chapter" />.<xsl:number level="any" from="chapter" />
</xsl:template>

<!-- Theorems:  x -->
<xsl:template match="theorem" mode="number">
    <xsl:number level="any" count="theorem" />
</xsl:template>

<!-- Lemmas:  x -->
<xsl:template match="lemma" mode="number">
    <xsl:number level="any" count="lemma" />
</xsl:template>

<!-- Corollaries:  x -->
<xsl:template match="corollary" mode="number">
    <xsl:number level="any" count="corollary" />
</xsl:template>

<!-- Definitions:  x -->
<xsl:template match="definition" mode="number">
    <xsl:number level="any" count="definition" />
</xsl:template>

<!-- Equations:  chapter.x -->
<xsl:template match="mrow|men" mode="number">
    <xsl:apply-templates select="ancestor::chapter" mode="number" />
    <xsl:text>.</xsl:text>
    <xsl:number from="chapter" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]" />
</xsl:template>

<!-- Bibliography items: x -->
<xsl:template match="bibliography//article|bibliography//book" mode="number">
    <xsl:number from="bibliography" level="single" count="article|book" />
</xsl:template>




<!-- Cross-References -->
<!-- Each a bit different in style of link (eg knowl), or content of link (eg "here") -->

<!-- Bring up bibliographic entries as knowls with cite -->
<!-- Style the bare number with CSS, eg [6]             -->
<!-- TODO: tokenize a list of labels? -->
<xsl:template match="cite">
    <xsl:variable name="target-node" select="id(@label)" />
    <!-- Could check local-name() against 'bibitem'     -->
    <xsl:element name ="a">
        <!-- http://stackoverflow.com/questions/585261/is-there-an-xslt-name-of-element -->
        <!-- Sans namespace (would be name(.)) -->
        <xsl:attribute name="class">
            <xsl:value-of select="'cite'" />
        </xsl:attribute>
        <xsl:attribute name="knowl">
            <xsl:value-of select="@label" /><xsl:text>.knowl</xsl:text>
        </xsl:attribute>
    [<xsl:apply-templates select="$target-node" mode="number" />]
    </xsl:element>
</xsl:template>

<!-- Point to any numbered item with link, content is number only -->
<!-- Displayed equations have targets manufactured by MathJax,    -->
<!-- which we ensure are consistent with our scheme here          -->
<!-- TODO: need to take into account chunking for href manufacture, need filebase for targetnode's file -->
<xsl:template match="xref">
    <xsl:variable name="target-node" select="id(@label)" />
    <xsl:element name ="a">
        <!-- http://stackoverflow.com/questions/585261/is-there-an-xslt-name-of-element -->
        <!-- Sans namespace (would be name(.)) -->
        <xsl:attribute name="class">
            <xsl:value-of select="local-name($target-node)" />
        </xsl:attribute>
        <xsl:attribute name="href">
            <xsl:text>#</xsl:text>
            <xsl:value-of select="@label" />
        </xsl:attribute>
    <xsl:apply-templates select="$target-node" mode="number" />
    </xsl:element>
</xsl:template>

<!-- Point to a "random" mark, with generic "this point" link -->
<xsl:template match="pageref">
    <xsl:variable name="target-node" select="id(@label)" />
    <xsl:element name ="a">
        <xsl:attribute name="class">
            <xsl:value-of select="'pageref'" />
        </xsl:attribute>
        <xsl:attribute name="href">
            <xsl:text>#</xsl:text><xsl:value-of select="@label" />
        </xsl:attribute>
    <xsl:text>this point</xsl:text>
    </xsl:element>
</xsl:template>




<!-- TODO: condition on id present!!!!!-->
<!-- TODO: perhaps back up a level on xml:id and regroup elsewhere, see latex version -->
<xsl:template match="*" mode="label">
    <xsl:element name="a">
        <xsl:attribute name="class">
            <xsl:value-of select="'label'" />
        </xsl:attribute>
        <xsl:attribute name="name">
            <xsl:value-of select="@xml:id" />
        </xsl:attribute>
    </xsl:element>
</xsl:template>


<!-- Miscellaneous -->

<!-- A marker we can point to -->
<xsl:template match="mark">
   <xsl:apply-templates select="." mode="label" />
</xsl:template>


<!-- Markup, typically within paragraphs -->

<!-- Quotes, regular or block -->
<xsl:template match="q">
    <q><xsl:apply-templates /></q>
</xsl:template>

<xsl:template match="blockquote">
    <div class="blockquote"><xsl:apply-templates /></div>
</xsl:template>

<!-- Use at the end of a blockquote -->
<xsl:template match="blockquote/attribution">
    <br /><span class="attribution"><xsl:apply-templates /></span>
</xsl:template>


<!-- Defined terms (bold) -->
<xsl:template match="term">
    <b class="term"><xsl:apply-templates /></b>
</xsl:template>

<!-- Emphasis -->
<xsl:template match="em">
    <em><xsl:apply-templates /></em>
</xsl:template>

<!-- for example -->
<xsl:template match="eg">
    <xsl:text>e.g. </xsl:text>
</xsl:template>

<!-- in other words -->
<xsl:template match="ie">
    <xsl:text>i.e. </xsl:text>
</xsl:template>

<!-- Implication Symbols -->
<!-- TODO: better names! -->
<xsl:template match="imply">
    <xsl:text>&#x21D2;</xsl:text>
</xsl:template>
<xsl:template match="implyreverse">
    <xsl:text>&#x21D0;</xsl:text>
</xsl:template>

<!-- TeX, LaTeX -->
<xsl:template match="latex">
    <xsl:text>\(\LaTeX\)</xsl:text>
</xsl:template>
<xsl:template match="tex">
    <xsl:text>\(\TeX\)</xsl:text>
</xsl:template>

<!-- Line Breaks -->
<!-- use sparingly, e.g. for poetry, not in math environments-->
<xsl:template match="br">
    <br />
</xsl:template>

<!-- Code, inline -->
<xsl:template match="c">
    <tt class="code"><xsl:apply-templates /></tt>
</xsl:template>

<!-- External URLs, Email        -->
<!-- Open in new windows         -->
<!-- URL itself, if content-less -->
<!-- http://stackoverflow.com/questions/9782021/check-for-empty-xml-element-using-xslt -->
<xsl:template match="url">
    <a class="external-url" href="{@href}" target="_blank">
    <xsl:choose>
        <xsl:when test="not(*) and not(normalize-space())">
            <xsl:value-of select="@href" />
        </xsl:when>
        <xsl:otherwise>         
            <xsl:value-of select="." />
        </xsl:otherwise>
    </xsl:choose>
    </a>
</xsl:template>

<xsl:template match="email">
    <xsl:element name="a">
        <xsl:attribute name="href">
            mailto:<xsl:value-of select="." />
        </xsl:attribute>
        <xsl:value-of select="." />
    </xsl:element>
</xsl:template>


<!-- Dollar sign -->
<xsl:template match="dollar">
    <xsl:text>$</xsl:text>
</xsl:template>

<!-- Percent sign -->
<xsl:template match="percent">
    <xsl:text>%</xsl:text>
</xsl:template>


<!-- Ellipsis (dots), for text, not math -->
<xsl:template match="ellipsis">
    <xsl:text>&#x2026;</xsl:text>
</xsl:template>


<!-- Ampersand -->
<!-- Not for formatting control, but to see actual character -->
<xsl:template match="ampersand">
    <xsl:text>&amp;</xsl:text>
</xsl:template>


<!-- Dashes, Hyphen -->
<!-- http://www.cs.tut.fi/~jkorpela/dashes.html -->
<xsl:template match="mdash">
    <xsl:text>&#8212;</xsl:text>
</xsl:template>
<xsl:template match="ndash">
    <xsl:text>&#8211;</xsl:text>
</xsl:template>
<!-- Unambiguous hyphen -->
<xsl:template match="hyphen">
    <xsl:text>&#8208;</xsl:text>
</xsl:template>

<!-- Titles of Books and Articles -->
<xsl:template match="booktitle">
    <span class="booktitle"><xsl:apply-templates /></span>
</xsl:template>
<xsl:template match="articletitle">
    <span class="articletitle"><xsl:apply-templates /></span>
</xsl:template>



<!-- Bibliography -->

<!-- Enclosing structure of bibliography -->
<xsl:template match="bibliography">
    <div class="bibliography">
    <div class="title">References</div>
        <ol>
            <xsl:apply-templates select="article|book" />
        </ol>
    </div>
</xsl:template>



<xsl:template match="bibliography//article">
    <li id="{@xmlid}" class="article">
        <xsl:apply-templates select="author" />
        <xsl:apply-templates select="title" />
        <xsl:apply-templates select="journal" />
        <xsl:apply-templates select="volume" />
        <xsl:apply-templates select="pages" />
        <xsl:text>.</xsl:text>
    </li>
    <exsl:document href="{@xml:id}.knowl" method="html">
        <span class="article">
            <xsl:apply-templates select="author" />
            <xsl:apply-templates select="title" />
            <xsl:apply-templates select="journal" />
            <xsl:apply-templates select="volume" />
            <xsl:apply-templates select="pages" />
            <xsl:text>.</xsl:text>
        </span>
    </exsl:document>
</xsl:template>

<xsl:template match="bibliography//book">
    <li id="{@xmlid}" class="book">
        <xsl:apply-templates select="author" />
        <xsl:apply-templates select="title" />
        <xsl:apply-templates select="publisher" />
        <xsl:text>.</xsl:text>
    </li>
    <exsl:document href="{@xml:id}.knowl" method="html">
        <span class="book">
            <xsl:apply-templates select="author" />
            <xsl:apply-templates select="title" />
            <xsl:apply-templates select="publisher" />
            <xsl:text>.</xsl:text>
        </span>
    </exsl:document>
</xsl:template>

<xsl:template match="bibliography//author">
    <span class="author"><xsl:apply-templates /></span>
</xsl:template>

<xsl:template match="bibliography/article/title">
    <xsl:text>, </xsl:text>
    <span class="title">
        <xsl:text>'</xsl:text>
        <xsl:apply-templates />
        <xsl:text>'</xsl:text>
    </span>
</xsl:template>

<xsl:template match="bibliography/book/title">
    <xsl:text>, </xsl:text>
    <span class="title">
        <xsl:apply-templates />
    </span>
</xsl:template>

<xsl:template match="bibliography//journal">
    <xsl:text>, </xsl:text>
    <span class="journal">
        <xsl:apply-templates />
        <xsl:text> (</xsl:text>
        <xsl:if test="../month">
            <xsl:value-of select="../month" />
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:value-of select="../year" />
        <xsl:text>)</xsl:text>
    </span>
</xsl:template>

<xsl:template match="bibliography//publisher">
    <xsl:text>, </xsl:text>
    <span class="publisher">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates />
        <xsl:text> </xsl:text>
        <xsl:value-of select="../year" />
        <xsl:text>)</xsl:text>
    </span>
</xsl:template>

<xsl:template match="bibliography//volume">
    <xsl:text>, </xsl:text>
    <span class="volume">
        <xsl:text> (</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>)</xsl:text>
        <xsl:if test="../number">
            <xsl:text> no. </xsl:text>
            <xsl:value-of select="../number" />
        </xsl:if>
    </span>
</xsl:template>

<xsl:template match="bibliography//pages">
    <xsl:text>, </xsl:text>
    <span class="pages"><xsl:apply-templates /></span>
</xsl:template>

<!-- Math  -->
<!-- Inline snippets -->
<xsl:template match= "m">
    <xsl:text>\(</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\)</xsl:text>
</xsl:template>

<!-- Unnumbered, single displayed equation -->
<xsl:template match="me">
    <xsl:text>&#xa;\[</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\]&#xa;</xsl:text>
</xsl:template>

<!-- Numbered, single displayed equation -->
<xsl:template match="men">
    <xsl:text>&#xa;\[</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
    <xsl:if test="@xml:id">
        <xsl:text>\label{</xsl:text>
        <xsl:value-of select="@xml:id" />
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>\]&#xa;</xsl:text>
</xsl:template>

<!-- Multi-line displayed equations container, globally unnumbered or numbered   -->
<!-- mrow logic controls numbering, based on variant here, and per-row overrides -->
<xsl:template match="md|mdn">
    <xsl:text>&#xa;\[\begin{align}</xsl:text>
    <xsl:apply-templates select="mrow" />
    <xsl:text>\end{align}\]&#xa;</xsl:text>
</xsl:template>

<!-- Rows of a multi-line math display                 -->
<!-- (1) MathJax config turns off all numbering        -->
<!-- (1) Numbering controlled here with \tag{}, \notag -->
<!-- (2) Labels are TeX-style, created by MathJax      -->
<!-- (2) MathJax config makes span id's predictable    -->
<!-- (3) Last row special, has no line-break marker    -->
<xsl:template match="mrow">
    <xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="." />
    <xsl:choose>
        <xsl:when test="(local-name(parent::*)='mdn') and (@number='no')">
            <xsl:text>\notag</xsl:text>
        </xsl:when>
        <xsl:when test="(local-name(parent::*)='md') and not(@number='yes')">
            <xsl:text>\notag</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\tag{</xsl:text>
            <xsl:apply-templates select="." mode="number" />
            <xsl:text>}</xsl:text>
            <xsl:if test="@xml:id">
                <xsl:text>\label{</xsl:text>
                <xsl:value-of select="@xml:id" />
                <xsl:text>}</xsl:text>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
        <xsl:when test="position()=last()">
            <xsl:text>&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\\</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


    
<!--Manual numbering example
<xsl:template match="mrow">
    <xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\tag{</xsl:text>
        <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
    <xsl:text>\\</xsl:text>
</xsl:template>-->



<!-- Sage -->
<xsl:template match="sage">
    <div class="sage-compute">
    <script type="text/x-sage">
    <xsl:call-template name="trim-sage">
        <xsl:with-param name="sagecode" select="input" />
    </xsl:call-template>
    </script>
    </div>
</xsl:template>

<!-- MathJax header                                     -->
<!-- XML manages equation numbers                       -->
<!-- Config MathJax to make link targets we can predict -->
<xsl:template name="mathjax">
<script type="text/x-mathjax-config">
MathJax.Hub.Config({
    tex2jax: {inlineMath: [['\\(','\\)']]},
    TeX: {
        extensions: ["AMSmath.js", "AMSsymbols.js"],
        equationNumbers: { autoNumber: "none",
                           useLabelIds: true,
                           formatID: function (n) {return String(n).replace(/[:'"&lt;&gt;&amp;]/g,"")},
                         },
        TagSide: "right",
        TagIndent: ".8em"
    },
});
</script>
<script type="text/javascript" src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML-full" />
</xsl:template>


<!-- Sage Cell header -->
<xsl:template name="sagecell">
    <script src="http://sagecell.sagemath.org/static/jquery.min.js"></script>
    <script src="http://sagecell.sagemath.org/embedded_sagecell.js"></script>
    <script>
$(function () {
    // Make *any* div with class 'sage-compute' a Sage cell
    sagecell.makeSagecell({inputLocation: 'div.sage-compute',
                           linked: true,
                           evalButtonText: 'Evaluate'});
});
    </script>
</xsl:template>

<!-- Knowl header -->
<xsl:template name="knowl">
<script type="text/javascript" src="http://code.jquery.com/jquery-latest.min.js"></script> 
<link href="http://aimath.org/knowlstyle.css" rel="stylesheet" type="text/css" /> 
<script type="text/javascript" src="http://aimath.org/knowl.js"></script>
</xsl:template>

<!-- Miscellaneous -->

<!-- TODO's get killed for finished work            -->
<!-- Highlight in a draft mode, or just grep source -->
<xsl:template match="todo"></xsl:template>


</xsl:stylesheet>