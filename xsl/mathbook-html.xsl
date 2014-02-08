<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2013 Robert A. Beezer

This file is part of MathBook XML.

MathBook XML is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

MathBook XML is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<!-- Identify as a stylesheet -->
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
>

<xsl:import href="./mathbook-common.xsl" />

<!-- Intend output for rendering by a web browser -->
<xsl:output method="html" encoding="utf-8" indent="yes"/>

<xsl:template match="/mathbook">
    <xsl:apply-templates />
</xsl:template>

<!-- Kill docinfo, handle pieces on ad-hoc basis -->
<!-- Save in a global variable for easy access   -->
<xsl:template match="/mathbook/docinfo"></xsl:template>
<xsl:variable name="docinfo" select="/mathbook/docinfo" />

<!-- Titles are handled specially                     -->
<!-- so get killed via apply-templates                -->
<!-- When needed, get content with XPath title/node() -->
<xsl:template match="title"></xsl:template>

<!-- Article                                                    -->
<!--     One page, full of sections (with abstract, references) -->
<xsl:template match="mathbook/article">
    <xsl:call-template name="page-wrapper">
        <xsl:with-param name="filebase">
            <xsl:value-of select="@filebase" />
        </xsl:with-param>
        <xsl:with-param name="title">
            <xsl:value-of select="title/node()" />
        </xsl:with-param>
        <xsl:with-param name="content">
            <div style="display:none;">
            \(<xsl:value-of select="/mathbook/docinfo/macros" />\)
            </div>
            <div class="article">
                <div class="heading">
                    <div class="title"><xsl:apply-templates select="title/node()" /></div>
                    <div class="event"><xsl:apply-templates select="/mathbook/docinfo/event" /></div>
                    <div class="authorgroup"><xsl:apply-templates select="/mathbook/docinfo/author" /></div>
                    <div class="date"><xsl:apply-templates select="/mathbook/docinfo/date" /></div>
                </div>
            <!-- TODO: an abstract here, from docinfo, or like preface? -->
            <xsl:apply-templates />
            </div>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Book                                                                           -->
<!--     A sequence of chapters and appendices (with table of contents, index, etc) -->
<xsl:template match="mathbook/book">
    <xsl:call-template name="page-wrapper">
        <xsl:with-param name="filebase">
            <xsl:value-of select="@filebase" />
        </xsl:with-param>
        <xsl:with-param name="title">
            <xsl:value-of select="title/node()" />
        </xsl:with-param>
        <xsl:with-param name="content">
            <div style="display:none;">
            \(<xsl:value-of select="/mathbook/docinfo/macros" />\)
            </div>
            <div class="book" >
                <div class="heading">
                    <div class="title"><xsl:apply-templates select="title/node()" /></div>
                    <div class="authorgroup"><xsl:apply-templates select="/mathbook/docinfo/author" /></div>
                    <div class="date"><xsl:apply-templates select="/mathbook/docinfo/date" /></div>
                    <xsl:if test="/mathbook/docinfo/copyright">
                        <div class="copyright"><xsl:text>&#169; </xsl:text>
                            <xsl:apply-templates select="/mathbook/docinfo/copyright/year" />
                            <xsl:text> </xsl:text>
                            <xsl:apply-templates select="/mathbook/docinfo/copyright/holder" />
                                <xsl:if test="/mathbook/docinfo/copyright/shortlicense">
                                    <br />
                                    <xsl:apply-templates select="/mathbook/docinfo/copyright/shortlicense" />
                                </xsl:if>
                        </div>
                    </xsl:if>
                </div>
            </div>
            <xsl:call-template name="toc" />
            <xsl:apply-templates />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Table of contents for front page -->
<!-- TODO: Appendices -->
<xsl:template name="toc">
    <div class="toc">
        <div class="heading">Table of Contents</div>
        <xsl:for-each select="//chapter|//appendix">
            <!-- Move div/class into "a" element with display block attribute? -->
            <!-- TODO: move "Chapter" string into CSS -->
            <div class="toc-entry">
                <a href="{@filebase}.html">
                <xsl:text>Chapter </xsl:text>
                <xsl:apply-templates select="." mode="number" />
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="title/node()" />
                </a>
            </div>
        </xsl:for-each>
    </div>
</xsl:template>

<!-- Author, single one at titlepage -->
<xsl:template match="author">
    <div class="author-info">
        <div class="author-name"><xsl:apply-templates select="personname" /></div>
        <div class="author-department"><xsl:apply-templates select="department" /></div>
        <div class="author-institution"><xsl:apply-templates select="institution" /></div>
        <div class="author-email"><xsl:apply-templates select="email" /></div>
    </div>
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

<!-- Chapters, Appendices                                    -->
<!--     Primary subdivision of a book, each to its own page -->
<!-- TODO: adjust for appendices            -->
<xsl:template match="chapter|appendix">
    <xsl:call-template name="page-wrapper">
        <xsl:with-param name="filebase">
            <xsl:value-of select="@filebase" />
        </xsl:with-param>
        <xsl:with-param name="title">
            <xsl:value-of select="title/node()" />
        </xsl:with-param>
        <xsl:with-param name="content">
            <div style="display:none;">
            \(<xsl:value-of select="/mathbook/docinfo/macros" />\)
            </div>
            <xsl:call-template name="page-navigation-bar" />
            <xsl:element name="div">
                <xsl:attribute name="class">chapter</xsl:attribute>
                <xsl:element name="div">
                    <xsl:attribute name="class">heading</xsl:attribute>
                    <xsl:element name="span">
                        <xsl:attribute name="class">number</xsl:attribute>
                        <xsl:apply-templates select="." mode="number" />
                    </xsl:element>
                    <xsl:element name="span">
                        <xsl:attribute name="class">title</xsl:attribute>
                        <xsl:apply-templates select="title/node()" />
                    </xsl:element>
                </xsl:element>
                <xsl:apply-templates />
            </xsl:element>
            <xsl:call-template name="page-navigation-bar" />
        </xsl:with-param>
    </xsl:call-template>
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

<!-- Sectioning -->
<!-- Sections, subsections, subsubsections          -->
<!-- TODO: meld in chapters, configurable chunking -->
<xsl:template match="section|subsection|subsubsection|paragraph">
    <xsl:variable name="level" select="local-name(.)" />
    <div class="{$level}">
        <div class="heading">
            <span class="number"><xsl:apply-templates select="." mode="number" /></span>
            <xsl:text> </xsl:text>
            <span class="title"><xsl:apply-templates select="title/node()" /></span>
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


<xsl:template match="example">
    <div class="example">
        <xsl:apply-templates select="." mode="label" />
        <xsl:apply-templates />
    </div>
</xsl:template>

<!-- Ignore solutions for now, could be knowls -->
<xsl:template match="exercise">
    <div class="exercise">
        <xsl:apply-templates select="." mode="label" />
        <xsl:apply-templates />
    </div>
</xsl:template>
<xsl:template match="exercise/solution"></xsl:template>

<!--Decide how to handle "Theorem 4.3 (A result of Beezer)"
as a lead-in to paragraph one, or a title div
preferably with CSS so can adjust style, language-->
<!-- And consolidate numbering -->
<!-- CSS: div for title, span for paragraph lead-in?  visible, invisible -->



<xsl:template match="theorem/statement/p[1]">
    <p>
        <span class="theorem-header">
        <xsl:apply-templates select="../.." mode="type-name" />
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="../.." mode="number" />
        <xsl:text> </xsl:text>
        </span>
        <xsl:apply-templates />
    </p>
</xsl:template>

<xsl:template match="lemma/statement/p[1]">
    <p>
        <span class="lemma-header">
        <xsl:apply-templates select="../.." mode="type-name" />
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="../.." mode="number" />
        <xsl:text> </xsl:text>
        </span>
        <xsl:apply-templates />
    </p>
</xsl:template>

<xsl:template match="corollary/statement/p[1]">
    <p>
        <span class="corollary-header">
        <xsl:apply-templates select="../.." mode="type-name" />
        <xsl:text> </xsl:text>
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

<xsl:template match="example/p[1]">
    <p>
    <span class="example-header">Example <xsl:apply-templates select=".." mode="number" />
    <xsl:text> </xsl:text>
    </span>
    <xsl:apply-templates />
    </p>
</xsl:template>

<xsl:template match="exercise/statement/p[1]">
    <p>
        <span class="exercise-header">
        <xsl:text>Exercise </xsl:text>
        <xsl:apply-templates select="../.." mode="number" />
        <xsl:text> </xsl:text>
        </span>
        <xsl:apply-templates />
    </p>
</xsl:template>


<xsl:template match="notation">
<p>Sample notation (in a master list eventually): \(<xsl:value-of select="." />\)</p>
</xsl:template>

<!-- First paragraph gets a leader -->
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

<!-- Figures and their captions -->
<xsl:template match="figure">
    <div class="figure">
        <xsl:apply-templates select="image|table|p" />
        <xsl:apply-templates select="caption" />
    </div>
</xsl:template>

<!-- Caption of a figure                           -->
<!-- All the relevant information is in the parent -->
<xsl:template match="figure/caption">
    <figcaption>
        <xsl:apply-templates select=".." mode="type-name"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select=".." mode="number"/>
        <xsl:text>: </xsl:text>
        <xsl:apply-templates />
        <xsl:apply-templates select=".." mode="label" />
    </figcaption>
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

<!-- Asymptote graphics language -->
<!-- unimplemented               -->
<xsl:template match="asymptote">
    <p style="margin:auto">&lt;Asymptote graphics migration to HTML not implemented, but is planned&gt;</p>
</xsl:template>


<!-- Tables -->
<!-- Follow XML Exchange Table Model" which is a subset of the failed "CALS Table Model" -->
<!-- Should be able to replace this by extant XSLT for this conversion -->
<xsl:template match="table"><table class="plain-table"><xsl:apply-templates /></table></xsl:template>
<xsl:template match="tgroup"><xsl:apply-templates /></xsl:template>
<xsl:template match="thead"><thead><xsl:apply-templates /></thead></xsl:template>
<xsl:template match="tbody"><tbody><xsl:apply-templates /></tbody></xsl:template>
<xsl:template match="row"><tr><xsl:apply-templates /></tr></xsl:template>
<!-- With a parent axis, get overrides easily? -->
<xsl:template match="thead/row/entry"><th align="{../../../@align}"><xsl:apply-templates /></th></xsl:template>
<xsl:template match="tbody/row/entry"><td align="{../../../@align}"><xsl:apply-templates /></td></xsl:template>

<!-- Caption of a table                            -->
<!-- All the relevant information is in the parent -->
<xsl:template match="table/caption">
    <caption>
        <xsl:apply-templates select=".." mode="type-name"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select=".." mode="number"/>
        <xsl:text>: </xsl:text>
        <xsl:apply-templates />
        <xsl:apply-templates select=".." mode="label" />
    </caption>
</xsl:template>



<!-- Citations, Cross-References -->
<!-- Each a bit different in style of link (eg knowl), or content of link (eg "here") -->
<!-- Warnings at command-line for mess-ups are in common file -->

<!-- Bring up bibliographic entries as knowls with cite -->
<!-- Style the bare number with CSS, eg [6]             -->
<!-- A citation can be "provisional"   -->
<!-- as a tool for drafts, otherwise "ref" to -->
<!-- an xml:id in bibliography                     -->
<!-- TODO: tokenize a list of labels? -->

<!-- Point to any numbered item with link, content is number only -->
<!-- Displayed equations have targets manufactured by MathJax,    -->
<!-- which we ensure are consistent with our scheme here          -->
<!-- A cross-reference can be "provisional"   -->
<!-- as a tool for drafts, otherwise "ref" to -->
<!-- an xml:id elsewhere                      -->
<!-- TODO: need to take into account chunking for href manufacture -->
<!-- need to use basename for targetnode's file        -->
<!-- or knowl these references, with "in context link" -->
<xsl:template match="cite[@ref]">
    <xsl:call-template name="knowl-link-factory">
        <xsl:with-param name="css-class">cite</xsl:with-param>
        <xsl:with-param name="identifier"><xsl:value-of select="@ref" /></xsl:with-param>
        <xsl:with-param name="content">
            <xsl:text>[</xsl:text>
            <xsl:apply-templates select="id(@ref)" mode="number" />
            <xsl:text>]</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="xref[@ref]">
    <xsl:variable name="target-node" select="id(@ref)" />
    <xsl:element name ="a">
        <!-- http://stackoverflow.com/questions/585261/is-there-an-xslt-name-of-element -->
        <!-- Sans namespace (would be name(.)) -->
        <xsl:attribute name="class">
            <xsl:value-of select="local-name($target-node)" />
        </xsl:attribute>
        <xsl:attribute name="href">
            <xsl:text>#</xsl:text>
            <xsl:value-of select="@ref" />
        </xsl:attribute>
    <xsl:apply-templates select="$target-node" mode="number" />
    </xsl:element>
</xsl:template>

<xsl:template match="cite[@provisional]|xref[@provisional]">
    <xsl:element name="span">
        <xsl:if test="$author-tools='yes'" >
            <xsl:attribute name="style">color:red</xsl:attribute>
        </xsl:if>
        <xsl:text>&lt;&lt;</xsl:text>
        <xsl:value-of select="@provisional" />
        <xsl:text>&gt;&gt;</xsl:text>
    </xsl:element>
</xsl:template>


<!-- Footnotes                                             -->
<!-- Mimicking basic LaTeX, but as knowls                  -->
<!-- Put content into knowl, then make a knowl link for it -->
<!-- The knowl link gets placed into a superscript         -->
<xsl:template match="fn">
    <xsl:variable name="ident">
        <xsl:text>footnote-</xsl:text>
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <!-- -->
    <xsl:call-template name="knowl-factory">
        <xsl:with-param name="identifier" select="$ident" />
        <xsl:with-param name="content">
            <xsl:apply-templates />
        </xsl:with-param>
    </xsl:call-template>
    <!-- -->
    <sup>
    <xsl:call-template name="knowl-link-factory">
        <xsl:with-param name="css-class">footnote</xsl:with-param>
        <xsl:with-param name="identifier" select="$ident" />
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="number" />
        </xsl:with-param>
    </xsl:call-template>
    </sup>
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


<!-- Markup, typically within paragraphs            -->
<!-- Quotes, double or single, see quotations below -->
<!-- HTML5 wants actual characters here -->
<xsl:template match="q">
    <xsl:text>&#x201c;</xsl:text><xsl:apply-templates /><xsl:text>&#x201d;</xsl:text>
</xsl:template>

<xsl:template match="sq">
    <xsl:text>&#x2018;</xsl:text><xsl:apply-templates /><xsl:text>&#x2019;</xsl:text>
</xsl:template>

<!-- Actual Quotations                -->
<!-- TODO: <quote> element for inline to be <q> in HTML-->
<xsl:template match="blockquote">
    <blockquote><xsl:apply-templates /></blockquote>
</xsl:template>

<!-- Use at the end of a blockquote -->
<xsl:template match="blockquote/attribution">
    <br /><span class="attribution"><xsl:apply-templates /></span>
</xsl:template>

<!-- Defined terms (bold) -->
<xsl:template match="term">
    <em class="terminology"><xsl:apply-templates /></em>
</xsl:template>

<!-- Emphasis -->
<xsl:template match="em">
    <em><xsl:apply-templates /></em>
</xsl:template>

<!-- Copyright symbol -->
<xsl:template match="copyright">
    <xsl:text>&#169;</xsl:text>
</xsl:template>

<!-- for example -->
<xsl:template match="eg">
    <xsl:text>e.g.</xsl:text>
</xsl:template>

<!-- in other words -->
<xsl:template match="ie">
    <xsl:text>i.e.</xsl:text>
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

<!-- Number Sign, Hash, Octothorpe -->
<xsl:template match="hash">
    <xsl:text>&#x23;</xsl:text>
</xsl:template>

<!-- Foreign words/idioms        -->
<!-- Matches HTML5 specification -->
<xsl:template match="foreign">
    <i class="foreign"><xsl:apply-templates /></i>
</xsl:template>


<!-- Dashes, Hyphen -->
<!-- http://www.cs.tut.fi/~jkorpela/dashes.html -->
<!-- HTML Tidy does not like these characters, but they seem to be OK -->
<!-- Could do this in CSS, perhaps? -->
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


<!-- TODO: deduplicate actual entry and knowl content -->
<xsl:template match="bibliography//article">
    <li id="{@xmlid}" class="article">
        <xsl:apply-templates select="author" />
        <xsl:apply-templates select="title" />
        <xsl:apply-templates select="journal" />
        <xsl:apply-templates select="volume" />
        <xsl:apply-templates select="pages" />
        <xsl:text>.</xsl:text>
    </li>
    <xsl:call-template name="knowl-factory">
        <xsl:with-param name="identifier"><xsl:value-of select="@xml:id" /></xsl:with-param>
        <xsl:with-param name="content">
            <span class="article">
                <xsl:apply-templates select="author" />
                <xsl:apply-templates select="title" />
                <xsl:apply-templates select="journal" />
                <xsl:apply-templates select="volume" />
                <xsl:apply-templates select="pages" />
                <xsl:text>.</xsl:text>
            </span>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="bibliography//book">
    <li id="{@xmlid}" class="book">
        <xsl:apply-templates select="author" />
        <xsl:apply-templates select="title" />
        <xsl:apply-templates select="publisher" />
        <xsl:text>.</xsl:text>
    </li>
    <xsl:call-template name="knowl-factory">
        <xsl:with-param name="identifier"><xsl:value-of select="@xml:id" /></xsl:with-param>
        <xsl:with-param name="content">
            <span class="book">
                <xsl:apply-templates select="author" />
                <xsl:apply-templates select="title" />
                <xsl:apply-templates select="publisher" />
                <xsl:text>.</xsl:text>
            </span>
        </xsl:with-param>
    </xsl:call-template>
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
<!-- Output follows source line breaks     -->
<xsl:template match="me">
    <xsl:text>\[</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\]</xsl:text>
</xsl:template>

<!-- Numbered, single displayed equation -->
<!-- Output follows source line breaks   -->
<xsl:template match="men">
    <xsl:text>\[</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
    <xsl:if test="@xml:id">
        <xsl:text>\label{</xsl:text>
        <xsl:value-of select="@xml:id" />
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>\]</xsl:text>
</xsl:template>

<!-- md, mdn containers are generic gather/align environments, so in common xsl -->

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

<!-- Manufacturing Knowls              -->
<!-- "knowl" subdirectory is hardcoded -->
<!-- First, make actual content in predictable location -->
<xsl:template name="knowl-factory">
    <xsl:param name="identifier"/>
    <xsl:param name="content"/>
    <exsl:document href="./knowl/{$identifier}.knowl" method="html">
        <xsl:call-template name="converter-blurb" />
        <xsl:value-of select="$content" />
    </exsl:document>
</xsl:template>
<!-- Second, make a clickable knowl link -->
<xsl:template name="knowl-link-factory">
    <xsl:param name="css-class"/>
    <xsl:param name="identifier"/>
    <xsl:param name="content"/>
    <xsl:element name ="a">
        <xsl:attribute name="class">
            <xsl:value-of select="$css-class" />
        </xsl:attribute>
        <xsl:attribute name="knowl">
            <xsl:text>./knowl/</xsl:text>
            <xsl:value-of select="$identifier" />
            <xsl:text>.knowl</xsl:text>
        </xsl:attribute>
        <xsl:value-of select="$content" />
    </xsl:element>
</xsl:template>

<!-- Sage -->
<xsl:template match="sage">
    <div class="sage-compute">
    <script type="text/x-sage">
    <xsl:call-template name="sanitize-sage">
        <xsl:with-param name="raw-sage-code" select="input" />
    </xsl:call-template>
    </script>
    </div>
</xsl:template>
<!-- Bare sage element means an empty cell to scribble in -->
<xsl:template match="sage[not(input) and not(output)]">
    <div class="sage-compute"><script type="text/x-sage">
    <xsl:text>&#xa;</xsl:text>
    </script></div>
</xsl:template>

<!--                         -->
<!-- Web Page Infrastructure -->
<!--                         -->

<!-- An individual page:                       -->
<!-- Inputs:                                   -->
<!--     * basename for file name              -->
<!--     * string for page title               -->
<!--     * content (exclusive of banners, etc) -->
<xsl:template name="page-wrapper">
    <xsl:param name="filebase" />
    <xsl:param name="title" />
    <xsl:param name="content" />
    <exsl:document href="{$filebase}.html" method="html">
    <!-- Need to be careful for format of this initial string     -->
    <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html>&#xa;</xsl:text>
    <html> <!-- lang="", and/or dir="rtl" here -->
        <head>
            <xsl:call-template name="converter-blurb" />
            <!-- http://webdesignerwall.com/tutorials/responsive-design-in-3-steps -->
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title><xsl:value-of select="$title" /></title>
            <xsl:call-template name="mathjax" />
            <xsl:call-template name="sagecell" />
            <xsl:call-template name="knowl" />
            <xsl:call-template name="fonts" />
            <link rel="stylesheet" type="text/css" href="mathbook.css" />
        </head>
        <body>
        <xsl:copy-of select="$content" />
        <xsl:apply-templates select="$docinfo/analytics" />
        </body>
    </html>
    </exsl:document>
</xsl:template>

<!-- Converter information for header -->
<!-- TODO: add date, URL -->
<xsl:template name="converter-blurb">
    <xsl:comment>*                                    *</xsl:comment><xsl:text>&#xa;</xsl:text>
    <xsl:comment>* Generated from MathBook XML source *</xsl:comment><xsl:text>&#xa;</xsl:text>
    <xsl:comment>
        <xsl:text>*    on </xsl:text>
        <xsl:value-of select="date:date-time()" />
        <xsl:text>    *</xsl:text>
    </xsl:comment><xsl:text>&#xa;</xsl:text>
    <xsl:comment>*                                    *</xsl:comment><xsl:text>&#xa;</xsl:text>
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

<!-- Font header -->
<!-- Google Fonts -->
<!-- Text: Istok Web font, regular and italic (400), bold (700) -->
<!-- Code: Source Code Pro, regular (400) -->
<xsl:template name="fonts">
    <link href='http://fonts.googleapis.com/css?family=Istok+Web:400,400italic,700|Source+Code+Pro:400' rel='stylesheet' type='text/css' />
</xsl:template>

<!-- Analytics Footers -->

<!-- Google Analytics                     -->
<!-- "Classic", not compared to Universal -->
<xsl:template match="google">
<xsl:comment>Start: Google code</xsl:comment>
<script type="text/javascript">
var _gaq = _gaq || [];
_gaq.push(['_setAccount', '<xsl:value-of select="./tracking" />']);
_gaq.push(['_trackPageview']);

(function() {
var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
})();
</script>
<xsl:comment>End: Google code</xsl:comment>
</xsl:template>

<!-- StatCounter                                -->
<!-- Set sc_invisible to 1                      -->
<!-- In noscript URL, final 1 is an edit from 0 -->
<xsl:template match="statcounter">
<xsl:comment>Start: StatCounter code</xsl:comment>
<script type="text/javascript">
var sc_project=<xsl:value-of select="./project" />;
var sc_invisible=1;
var sc_security="<xsl:value-of select="./security" />";
var scJsHost = (("https:" == document.location.protocol) ? "https://secure." : "http://www.");
<![CDATA[document.write("<sc"+"ript type='text/javascript' src='" + scJsHost+ "statcounter.com/counter/counter.js'></"+"script>");]]>
</script>
<xsl:variable name="noscript_url">
    <xsl:text>http://c.statcounter.com/</xsl:text>
    <xsl:value-of select="./project" />
    <xsl:text>/0/</xsl:text>
    <xsl:value-of select="./security" />
    <xsl:text>/1/</xsl:text>
</xsl:variable>
<noscript>
<div class="statcounter">
<a title="web analytics" href="http://statcounter.com/" target="_blank">
<img class="statcounter" src="{$noscript_url}" alt="web analytics" /></a>
</div>
</noscript>
<xsl:comment>End: StatCounter code</xsl:comment>
</xsl:template>


<!-- Miscellaneous -->


<!-- ToDo's are silent unless asked for -->
<!-- Can also grep across the source    -->
<xsl:template match="todo">
    <xsl:if test="$author-tools='yes'" >
        <xsl:element name="p">
            <xsl:attribute name="style">color:red</xsl:attribute>
            <xsl:apply-templates select="." mode="type-name" />
            <xsl:text>: </xsl:text>
            <xsl:apply-templates />
        </xsl:element>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>