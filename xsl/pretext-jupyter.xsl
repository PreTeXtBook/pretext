<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2015 Robert A. Beezer

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

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    extension-element-prefixes="exsl str"
    exclude-result-prefixes="pi"
    >

<!-- Trade on HTML markup, numbering, chunking, etc.        -->
<!-- Override as pecularities of Jupytr/JSON arise          -->
<!-- NB: this will import -assembly and -common stylesheets -->
<xsl:import href="./pretext-html.xsl" />

<!-- Output is an XML description of a notebook: a "notebook"     -->
<!-- element containing a flat list of "cell" elements, whose      -->
<!-- content is serialized HTML (markdown cells) or program text  -->
<!-- (code cells).  The Python routine  jupyter()  converts each   -->
<!-- such file into the JSON of a Jupyter notebook via "nbformat", -->
<!-- which owns all JSON escaping and schema conformance.          -->
<xsl:output method="xml" encoding="UTF-8" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<!-- This variable controls representations of interactive exercises   -->
<!-- built in  pretext-assembly.xsl.  The imported  pretext-html.xsl   -->
<!-- stylesheet sets it to "dynamic".  But for this stylesheet we want -->
<!-- to utilize the "standard" PreTeXt exercise versions built with    -->
<!-- "static".  See both  pretext-assembly.xsl  and  pretext-html.xsl  -->
<!-- for more discussion. -->
<xsl:variable name="exercise-style" select="'static'"/>

<!-- iPython files as output -->
<xsl:variable name="file-extension" select="'.ipynb'" />

<xsl:param name="jupyter.kernel" select="''" />

<!-- Disable clipboardable -->
<xsl:template name="insert-clipboardable-class"/>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<xsl:template match="/">
    <xsl:apply-templates select="$root"/>
</xsl:template>

<!-- Deprecation warnings are universal analysis of source and parameters        -->
<!-- We process structural nodes via chunking routine in  xsl/pretext-common.xsl -->
<!-- This in turn calls specific modal templates defined elsewhere in this file  -->
<!-- There is always a "document root" directly under the mathbook element,      -->
<!-- and we process it with the chunking template called below                   -->
<!-- Note that "docinfo" is at the same level and not structural, so killed      -->
<xsl:template match="/pretext">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Jupyter notebook conversion is experimental and incomplete&#xa;Requests to fix/implement specific constructions welcome</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="$original" mode="generic-warnings"/>
    <xsl:apply-templates select="$original" mode="element-deprecation-warnings"/>
    <xsl:apply-templates select="$original" mode="parameter-deprecation-warnings"/>
    <xsl:apply-templates mode="chunking" />
</xsl:template>

<!-- ########### -->
<!-- Compromises -->
<!-- ########### -->

<!-- Knowls are not yet functional in Jupyter notebooks    -->
<!-- See:  https://github.com/jupyter/notebook/pull/2947   -->
<!-- So we kill them while we wait and get hyperlinks only -->
<xsl:template match="*" mode="xref-as-knowl">
    <xsl:value-of select="false()" />
</xsl:template>


<!-- ################ -->
<!-- Structural Nodes -->
<!-- ################ -->

<!-- Read the code and documentation for "chunking" in xsl/pretext-common.xsl -->
<!-- This will explain document structure (not XML structure) and has the       -->
<!-- routines which call the necessary realizations of two abstract templates.  -->

<!-- Divisions, and pseudo-divisions -->
<!-- A heading cell, then apply templates here to children -->
<xsl:template match="&STRUCTURAL;|paragraphs|introduction[parent::*[&STRUCTURAL-FILTER;]]|conclusion[parent::*[&STRUCTURAL-FILTER;]]">
    <!-- <xsl:message>S:<xsl:value-of select="local-name(.)" />:S</xsl:message> -->
    <xsl:apply-templates select="." mode="pretext-heading" />
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- Some structural nodes do not need their title,                -->
<!-- (or subtitle) so we don't put a section heading there         -->
<!-- Title(s) for an article are forced by a frontmatter/titlepage -->
<!-- TODO: incorporate in above by implementing null heading template? -->
<xsl:template match="article|frontmatter">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- We have entire cells for division headings. -->
<xsl:template match="&STRUCTURAL;" mode="pretext-heading">
    <xsl:variable name="html-rtf">
        <!-- each division heads its own notebook, and the document -->
        <!-- title is a level below the notebook's styling cell, so -->
        <!-- level 2 mirrors the HTML conversion's chunked pages    -->
        <xsl:apply-templates select="." mode="section-heading">
            <xsl:with-param name="heading-level" select="2"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="html-node-set" select="exsl:node-set($html-rtf)" />
    <xsl:call-template name="pretext-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
                <xsl:apply-templates select="$html-node-set" mode="xml-to-string" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="paragraphs|introduction|conclusion" mode="pretext-heading">
    <xsl:variable name="html-rtf">
        <!-- a level below a division heading (see above) -->
        <xsl:apply-templates select="." mode="heading-title">
            <xsl:with-param name="heading-level" select="3"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="html-node-set" select="exsl:node-set($html-rtf)" />
    <xsl:call-template name="pretext-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
                <xsl:apply-templates select="$html-node-set" mode="xml-to-string" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="*" mode="pretext-heading">
    <xsl:message>pretext-heading unmatched <xsl:value-of select="local-name(.)" /></xsl:message>
</xsl:template>

<!-- A division companion as its own notebook: a heading cell from -->
<!-- the localized type-name (titles ignored, pending deprecation) -->
<!-- and then the children as cells                                -->
<xsl:template match="introduction|conclusion" mode="division-companion-page">
    <xsl:variable name="html-rtf">
        <h1>
            <xsl:apply-templates select="." mode="division-companion-text"/>
        </h1>
    </xsl:variable>
    <xsl:variable name="html-node-set" select="exsl:node-set($html-rtf)" />
    <xsl:call-template name="pretext-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
                <xsl:apply-templates select="$html-node-set" mode="xml-to-string" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- The ordinary block realization is the whole notebook -->
<xsl:template match="objectives|outcomes" mode="division-companion-page">
    <xsl:apply-templates select="."/>
</xsl:template>

<!-- Three modal templates accomodate all document structure nodes -->
<!-- and all possibilities for chunking.  Read the description     -->
<!-- in  xsl/pretext-common.xsl  and  -html  to understand these.  -->
<!-- The  "file-wrap"  template is defined elsewhere in this file. -->

<!-- Content of a summary page is usual content,  -->
<!-- or link to subsidiary content, all from HTML -->
<!-- template with same mode, as one big cell     -->
<xsl:template match="&STRUCTURAL;" mode="intermediate">
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="content">
            <!-- should perhaps initialize/pass $heading-level = 2 here -->
            <!-- perhaps irrelevant since headings are done in markown? -->
            <xsl:variable name="html-rtf">
                <nav class="summary-links">
                    <xsl:apply-templates select="*" mode="summary-nav" />
                </nav>
            </xsl:variable>
            <xsl:variable name="html-node-set" select="exsl:node-set($html-rtf)" />
            <xsl:call-template name="pretext-cell">
                <xsl:with-param name="content">
                    <xsl:call-template name="begin-string" />
                        <xsl:apply-templates select="$html-node-set" mode="xml-to-string" />
                    <xsl:call-template name="end-string" />
                </xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="conclusion" />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- ########## -->
<!-- Worksheets -->
<!-- ########## -->

<!-- Worksheets are a great feature for a Jupyter notebook.  But we need -->
<!-- to adjust the page-oriented flavor of the base HTML (which exists   -->
<!-- as part of accommodating printing from a web browser). All children  -->
<!-- of a "page" get processed, and elsewhere get recognized as items    -->
<!-- deserving of their own cells.  A "handout" structures its content   -->
<!-- with "page" identically.                                            -->
<xsl:template match="worksheet/page|handout/page">
    <xsl:apply-templates select="*"/>
</xsl:template>


<!-- ############## -->
<!-- File Structure -->
<!-- ############## -->

<!-- Gross structure of a Jupyter notebook -->
<!-- TODO: need to make a "simple file wrap" template?  Or just call this?-->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />
    <xsl:param name="filename" select="''"/>
    <!--  -->
    <xsl:variable name="the-filename">
        <xsl:choose>
            <xsl:when test="not($filename = '')">
                <xsl:value-of select="$filename"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="containing-filename" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="cell-list">
        <!-- a code cell for reader to load CSS -->
        <!-- First, so already with focus       -->
        <xsl:call-template name="load-css" />
        <!-- load LaTeX macros for MathJax               -->
        <!-- Empty visually, so also provides separation -->
        <xsl:apply-templates select="." mode="latex-macros" />
        <!-- the real content of the page -->
        <xsl:copy-of select="$content" />
    </xsl:variable>
    <!-- The file written here is the *description* of a notebook,  -->
    <!-- so an "xml" suffix is appended to the eventual notebook    -->
    <!-- filename.  Hyperlinks within cell content are relative     -->
    <!-- references to the final "ipynb" filenames, so the Python   -->
    <!-- conversion must strip the suffix when writing final files. -->
    <exsl:document href="{$the-filename}.xml" method="xml" encoding="UTF-8">
        <notebook>
            <!-- The kernel is communicated to the Python routine, which  -->
            <!-- owns all remaining notebook-level metadata.  "sagemath"  -->
            <!-- as the kernel name will be the latest kernel in the Sage -->
            <!-- distribution Jupyter, and in CoCalc.                     -->
            <xsl:attribute name="kernel">
                <xsl:choose>
                    <xsl:when test="contains('|python3|Python3|python 3|Python 3|py|Py|python|Python|'
                        , concat('|', $jupyter.kernel, '|'))">
                        <xsl:text>python3</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>sagemath</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:copy-of select="$cell-list"/>
        </notebook>
    </exsl:document>
</xsl:template>

<!-- a code cell with HTML magic         -->
<!-- allows reader to activate styling   -->
<!-- Code first, so it begins with focus -->
<!-- The styling is deliberately self-contained: no network      -->
<!-- requests (a reader's activity is nobody's business), no     -->
<!-- scripts (host applications routinely remove them), and no   -->
<!-- colors that fight a host application's light or dark theme. -->
<!-- The notebook is fully readable if this cell is never run:   -->
<!-- styling is a progressive enhancement, never structural.     -->
<xsl:template name="load-css">
    <!-- HTML as one-off code cell   -->
    <!-- Serialize HTML by hand here -->
    <xsl:call-template name="code-cell">
        <xsl:with-param name="purpose" select="'styling'"/>
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>%%html&#xa;</xsl:text>
            <xsl:text>&lt;style&gt;&#xa;</xsl:text>
            <xsl:text>.mathbook-content {line-height: 1.4;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content .heading {margin-bottom: 0.5em;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content article .heading {font-size: 1em; margin: 0 0 0.5em;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content code.code-inline {padding: 0 0.2em; border: 0.05em solid #bbbbbb; border-radius: 0.2em;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content .heading .codenumber {margin-left: 0.25em;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content .heading .title {margin-left: 0.25em; font-style: italic;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content .subtitle {font-size: medium; display: block; font-weight: normal;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content article {border-left: 0.15em solid #888888; padding-left: 0.75em; margin: 0.75em 0;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content article .para:last-child {margin-bottom: 0;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content article.proof {border-left: 0.1em dotted #888888;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content article.fragment-first {margin-bottom: 0;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content article.fragment-interior, .mathbook-content article.fragment-last {margin-top: 0;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content .para {margin-top: 0.75em;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content pre.code-display {border: 0.05em solid #888888; padding: 0.5em; overflow-x: auto;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content figure {margin: 1em auto; text-align: center;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content .image-box {margin-left: auto; margin-right: auto;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content img.contained {width: 100%;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content figcaption {font-style: italic; margin-top: 0.25em;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content figcaption .type, .mathbook-content figcaption .codenumber {font-style: normal; font-weight: bold;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content .summary-links li {list-style: none;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content .summary-links a {display: block; margin: 0.5em 0; padding: 0.6em 0.9em; border: 0.05em solid #888888; border-radius: 0.5em; font-size: 1.2em; font-weight: bold; text-decoration: none;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content .summary-links a .codenumber {margin-right: 0.5em;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content .sbsrow {display: grid; grid-template-columns: repeat(auto-fit, minmax(0, 1fr)); column-gap: 3%; align-items: start;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content .sbspanel.middle, .mathbook-content .sbspanel--middle {align-self: center;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content .sbspanel.bottom, .mathbook-content .sbspanel--bottom {align-self: end;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content table {border-collapse: collapse;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content table td, .mathbook-content table th {padding: 0.2em 0.5em; border: 0 solid;}&#xa;</xsl:text>
            <!-- host themes stripe and highlight table rows; authored -->
            <!-- tables speak through their rules, never backgrounds.  -->
            <!-- The full "background" shorthand, explicit alternating -->
            <!-- selectors, and !important outrank any host theme.     -->
            <xsl:text>.mathbook-content table tr, .mathbook-content table td, .mathbook-content table th {background: transparent !important;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content table tbody tr:nth-child(odd), .mathbook-content table tbody tr:nth-child(even), .mathbook-content table tbody tr:hover {background: transparent !important;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.t1, .mathbook-content th.t1 {border-top-width: 1px;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.t2, .mathbook-content th.t2 {border-top-width: 2px;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.t3, .mathbook-content th.t3 {border-top-width: 3px;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.b1, .mathbook-content th.b1 {border-bottom-width: 1px;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.b2, .mathbook-content th.b2 {border-bottom-width: 2px;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.b3, .mathbook-content th.b3 {border-bottom-width: 3px;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.l1, .mathbook-content th.l1 {border-left-width: 1px;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.l2, .mathbook-content th.l2 {border-left-width: 2px;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.l3, .mathbook-content th.l3 {border-left-width: 3px;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.r1, .mathbook-content th.r1 {border-right-width: 1px;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.r2, .mathbook-content th.r2 {border-right-width: 2px;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.r3, .mathbook-content th.r3 {border-right-width: 3px;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.l {text-align: left;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.c {text-align: center;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content td.r {text-align: right;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content table tr.header-vertical th {writing-mode: vertical-rl; padding-left: 2em;}&#xa;</xsl:text>
            <xsl:text>.mathbook-content .sbspanel img {max-width: 100%;}&#xa;</xsl:text>
            <xsl:text>&lt;/style&gt;</xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
    <!-- instructions as Markdown cell        -->
    <!-- Use markdown, since no CSS yet (duh) -->
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>The collapsed code cell above adds some light styling, and in a trusted notebook it takes effect automatically.  If this page looks plain, run that cell once, with Shift-Enter or a Run button.  Everything below is fully readable either way, and nothing here requires an Internet connection.</xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- This will override the HTML version, but is patterned -->
<!-- after same.  Adjustments are: different overall       -->
<!-- delimiters, and no enclosing div to hide content      -->
<!-- (thereby avoiding the need for serialization).        -->
<!-- We *remove* our defintion of \lt since MathJax does   -->
<!-- it anyway and Jupyter adds it in as part of a         -->
<!-- conversion to LateX.  Bad practice?  Maybe better to  -->
<!-- go back to -common and rework the entire latex-macro  -->
<!-- generation scheme?                                    -->
<xsl:template match="*" mode="latex-macros">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:call-template name="inline-math-wrapper">
                <xsl:with-param name="math">
                    <xsl:value-of select="$latex-packages-mathjax" />
                    <!-- Sequence replacements if \gt and/or \amp need to go -->
                    <xsl:value-of select="str:replace($latex-macros,'\newcommand{\lt}{&lt;}&#xa;', '')"/>
                    <!-- "math support" macros, mirroring the base HTML template -->
                    <xsl:call-template name="fillin-math"/>
                    <!-- legacy built-in support for "slanted|beveled|nice" fractions -->
                    <xsl:if test="$b-has-sfrac">
                        <xsl:text>\newcommand{\sfrac}[2]{{#1}/{#2}}&#xa;</xsl:text>
                    </xsl:if>
                </xsl:with-param>
            </xsl:call-template>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- An override of the template in pretext-common.xsl.  The        -->
<!-- publisher's "shade" style needs \definecolor and \colorbox,    -->
<!-- from a MathJax extension a notebook's configuration does not   -->
<!-- load (and we cannot touch); an unknown macro renders literally -->
<!-- as mathematics.  So "shade" degrades to the visually closest   -->
<!-- style, "box", which is core TeX throughout.  The "underline"   -->
<!-- style is also safe, and is reproduced verbatim.                -->
<xsl:template name="fillin-math">
    <xsl:choose>
        <xsl:when test="$fillin-math-style = 'underline'">
            <xsl:text>\newcommand{\fillinmath}[1]{\mathchoice</xsl:text>
            <xsl:text>{\underline{\displaystyle     \phantom{\ \,#1\ \,}}}</xsl:text>
            <xsl:text>{\underline{\textstyle        \phantom{\ \,#1\ \,}}}</xsl:text>
            <xsl:text>{\underline{\scriptstyle      \phantom{\ \,#1\ \,}}}</xsl:text>
            <xsl:text>{\underline{\scriptscriptstyle\phantom{\ \,#1\ \,}}}}&#xa;</xsl:text>
        </xsl:when>
        <!-- "box", and "shade" degraded to "box" -->
        <xsl:otherwise>
            <xsl:text>\newcommand{\fillinmath}[1]{\mathchoice</xsl:text>
            <xsl:text>{\boxed{\displaystyle     \phantom{\,#1\,}}}</xsl:text>
            <xsl:text>{\boxed{\textstyle        \phantom{\,#1\,}}}</xsl:text>
            <xsl:text>{\boxed{\scriptstyle      \phantom{\,#1\,}}}</xsl:text>
            <xsl:text>{\boxed{\scriptscriptstyle\phantom{\,#1\,}}}}&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ################# -->
<!-- Block Level Items -->
<!-- ################# -->

<!-- Everything configurable by author, 2020-01-02         -->
<!-- Roughly in the order of old  html.knowl.*  switches   -->
<!-- Similar HTML templates return string for boolean test -->
<!-- Jupyter is hostile to knowls code, so we don't knowl  -->
<!-- anything and ignore any choice in a publisher file    -->
<!-- https://github.com/jupyter/notebook/pull/2947         -->
<xsl:template match="&THEOREM-LIKE;|&PROOF-LIKE;|&DEFINITION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|task|&FIGURE-LIKE;|&REMARK-LIKE;|&GOAL-LIKE;|exercise" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- These are "top-level" items, children of divisions    -->
<!-- and pseudo-divisions.  Normally they would get a high -->
<!-- priority, but we want them to have the same low       -->
<!-- priority as a generic (default) wilcard match         -->
<!-- TODO: remove filter on paragraphs once we add stack for sidebyside -->
<xsl:template match="*[parent::*[&STRUCTURAL-FILTER; or self::paragraphs[not(ancestor::sidebyside)] or self::introduction[parent::*[&STRUCTURAL-FILTER;]] or self::conclusion[parent::*[&STRUCTURAL-FILTER;]]]]|*[parent::page]" priority="-0.5">
    <!-- <xsl:message>G:<xsl:value-of select="local-name(.)" />:G</xsl:message> -->
    <xsl:choose>
        <!-- A block with executable "sage" anywhere within it cannot -->
        <!-- be one markdown cell: the code deserves genuine,         -->
        <!-- executable code cells.  Since cells never nest, the      -->
        <!-- block splits into *fragments* around its code: each      -->
        <!-- fragment is a complete, balanced rendering, and any      -->
        <!-- element spanning a split (the block itself, a            -->
        <!-- "statement", a "task") is re-opened in the next          -->
        <!-- fragment.  A fragment-position class lets styling draw   -->
        <!-- continuity (side borders) across the cells, and cell     -->
        <!-- metadata records the same structure durably.             -->
        <xsl:when test=".//sage[not(@type = 'display')]">
            <!-- NB: "apply-imports" honors the current mode, so the -->
            <!-- rendering must happen here, in the default mode     -->
            <xsl:variable name="html-rtf">
                <xsl:apply-imports/>
            </xsl:variable>
            <xsl:call-template name="fragmented-block">
                <xsl:with-param name="rendered" select="$html-rtf"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="html-rtf">
                <xsl:apply-imports />
            </xsl:variable>
            <xsl:variable name="demoted-rtf">
                <xsl:apply-templates select="exsl:node-set($html-rtf)" mode="demote-headings"/>
            </xsl:variable>
            <xsl:variable name="html-node-set" select="exsl:node-set($demoted-rtf)" />
            <xsl:call-template name="pretext-cell">
                <xsl:with-param name="content">
                    <xsl:call-template name="begin-string" />
                        <xsl:apply-templates select="$html-node-set" mode="xml-to-string" />
                    <xsl:call-template name="end-string" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- The HTML conversion threads a heading level to every block's  -->
<!-- heading, but "xsl:apply-imports" (necessary above, to reuse   -->
<!-- the entire HTML conversion for a block) cannot pass           -->
<!-- parameters, an XSLT 1.0 limitation.  So every block heading   -->
<!-- arrives at the default level, "h1".  The rendered HTML        -->
<!-- itself, though, records the true nesting: each block's        -->
<!-- wrapper element holds its heading as a child.  So the         -->
<!-- accurate level is recovered from the rendering.  A division   -->
<!-- heading (made elsewhere) is "h2"; a block directly below it   -->
<!-- is "h3"; a block within a block (a "task" of a "project",     -->
<!-- say) is "h4"; and so on, capped at "h6".  This is visual      -->
<!-- fidelity, but more importantly it is the heading outline      -->
<!-- that a screen reader's navigation presents.  Headings built   -->
<!-- by other routes (divisions, "paragraphs", companion pages)    -->
<!-- never pass through here, and keep their explicit levels.      -->
<xsl:template match="node()|@*" mode="demote-headings">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="demote-headings"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="h1[contains(concat(' ', normalize-space(@class), ' '), ' heading ')]" mode="demote-headings">
    <!-- each ancestor with a heading of its own is an enclosing -->
    <!-- block; this heading's block is the innermost of them    -->
    <xsl:variable name="enclosing-blocks" select="count(ancestor::*[*[starts-with(local-name(), 'h') and (string-length(local-name()) = 2) and contains(concat(' ', normalize-space(@class), ' '), ' heading ')]])"/>
    <xsl:variable name="level">
        <xsl:choose>
            <xsl:when test="2 + $enclosing-blocks &gt; 6">
                <xsl:text>6</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="2 + $enclosing-blocks"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:element name="h{$level}">
        <xsl:apply-templates select="node()|@*" mode="demote-headings"/>
    </xsl:element>
</xsl:template>

<!-- Split a block into markdown fragments around executable code  -->
<!-- cells.  The block renders exactly as usual, except each       -->
<!-- interior executable "sage" renders as an empty marker         -->
<!-- element.  The rendered tree is then *sliced* at the markers:  -->
<!-- slice k keeps the nodes that follow marker k (and precede     -->
<!-- marker k+1), while any element that spans a marker (the       -->
<!-- block's own wrapper, a "statement", a "task") is re-opened,   -->
<!-- shallowly, in every slice it spans<mdash/>so each fragment is -->
<!-- balanced HTML in the block's own dress, and the code may sit  -->
<!-- at any depth.  The block's heading is part of the rendering,  -->
<!-- so it lands in the first slice with no special treatment.     -->
<xsl:template name="fragmented-block">
    <!-- the block's ordinary rendering (markers included), made -->
    <!-- by the caller; the context node remains the block       -->
    <xsl:param name="rendered"/>
    <xsl:variable name="element-name" select="local-name(.)"/>
    <xsl:variable name="identifier">
        <xsl:apply-templates select="." mode="html-id"/>
    </xsl:variable>
    <!-- settle heading levels before slicing -->
    <xsl:variable name="demoted-rtf">
        <xsl:apply-templates select="exsl:node-set($rendered)" mode="demote-headings"/>
    </xsl:variable>
    <xsl:variable name="marked" select="exsl:node-set($demoted-rtf)"/>
    <!-- the code, in document order, mirroring the markers exactly -->
    <xsl:variable name="code" select=".//sage[not(@type = 'display')]"/>
    <xsl:variable name="code-count" select="count($code)"/>
    <!-- the opening fragment always appears: it carries the heading -->
    <xsl:call-template name="fragment-slice-cell">
        <xsl:with-param name="marked" select="$marked"/>
        <xsl:with-param name="slice-number" select="0"/>
        <xsl:with-param name="element" select="$element-name"/>
        <xsl:with-param name="identifier" select="$identifier"/>
        <xsl:with-param name="part" select="'first'"/>
    </xsl:call-template>
    <!-- alternate code cells with the slices that follow them -->
    <xsl:for-each select="$code">
        <xsl:variable name="place" select="position()"/>
        <!-- does any actual content trail the final marker? -->
        <xsl:variable name="last-slice-rtf">
            <xsl:if test="$place = $code-count">
                <xsl:apply-templates select="$marked/*" mode="fragment-slice">
                    <xsl:with-param name="slice-number" select="$code-count"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="b-code-is-last" select="($place = $code-count) and not(exsl:node-set($last-slice-rtf)//text()[normalize-space(.) != ''] or exsl:node-set($last-slice-rtf)//img)"/>
        <xsl:apply-templates select="." mode="sage-code-cell">
            <xsl:with-param name="element" select="$element-name"/>
            <xsl:with-param name="identifier" select="$identifier"/>
            <xsl:with-param name="part">
                <xsl:choose>
                    <xsl:when test="$b-code-is-last">
                        <xsl:text>last</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>interior</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:apply-templates>
        <xsl:if test="not($b-code-is-last)">
            <xsl:call-template name="fragment-slice-cell">
                <xsl:with-param name="marked" select="$marked"/>
                <xsl:with-param name="slice-number" select="$place"/>
                <xsl:with-param name="element" select="$element-name"/>
                <xsl:with-param name="identifier" select="$identifier"/>
                <xsl:with-param name="part">
                    <xsl:choose>
                        <xsl:when test="$place = $code-count">
                            <xsl:text>last</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>interior</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<!-- One slice of the marked rendering becomes one markdown cell, -->
<!-- unless the slice holds no genuine content (adjacent code, or -->
<!-- code that opens its block, leave gaps that nobody misses)    -->
<xsl:template name="fragment-slice-cell">
    <xsl:param name="marked"/>
    <xsl:param name="slice-number"/>
    <xsl:param name="element"/>
    <xsl:param name="identifier"/>
    <xsl:param name="part"/>
    <xsl:variable name="slice-rtf">
        <xsl:apply-templates select="$marked/*" mode="fragment-slice">
            <xsl:with-param name="slice-number" select="$slice-number"/>
            <xsl:with-param name="part" select="$part"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="slice" select="exsl:node-set($slice-rtf)"/>
    <xsl:if test="($part = 'first') or $slice//text()[normalize-space(.) != ''] or $slice//img">
        <xsl:call-template name="pretext-cell">
            <xsl:with-param name="content">
                <xsl:call-template name="begin-string" />
                    <xsl:apply-templates select="$slice" mode="xml-to-string" />
                <xsl:call-template name="end-string" />
            </xsl:with-param>
            <xsl:with-param name="element" select="$element"/>
            <xsl:with-param name="identifier" select="$identifier"/>
            <xsl:with-param name="part" select="$part"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Slice a marked rendering.  An element containing markers is  -->
<!-- re-opened (shallow copy) in every slice it spans; any other  -->
<!-- node belongs to exactly the slice numbered by the count of   -->
<!-- markers preceding it.  The markers themselves never survive. -->
<xsl:template match="*" mode="fragment-slice">
    <xsl:param name="slice-number"/>
    <xsl:param name="part" select="''"/>
    <xsl:choose>
        <xsl:when test=".//pi:sage-marker">
            <xsl:copy>
                <!-- an HTML id may appear only once, so it stays -->
                <!-- with the first slice of a spanning element   -->
                <xsl:copy-of select="@*[not(name() = 'id') or ($slice-number = 0)]"/>
                <!-- the outermost element of a slice advertises  -->
                <!-- its position, for styling continuity         -->
                <xsl:if test="not(parent::*) and not($part = '')">
                    <xsl:attribute name="class">
                        <xsl:value-of select="normalize-space(concat(@class, ' fragment-', $part))"/>
                    </xsl:attribute>
                </xsl:if>
                <xsl:apply-templates select="node()" mode="fragment-slice">
                    <xsl:with-param name="slice-number" select="$slice-number"/>
                </xsl:apply-templates>
            </xsl:copy>
        </xsl:when>
        <xsl:when test="count(preceding::pi:sage-marker) = $slice-number">
            <xsl:copy-of select="."/>
        </xsl:when>
        <!-- other slices claim this node -->
    </xsl:choose>
</xsl:template>

<xsl:template match="text()" mode="fragment-slice">
    <xsl:param name="slice-number"/>
    <xsl:if test="count(preceding::pi:sage-marker) = $slice-number">
        <xsl:copy-of select="."/>
    </xsl:if>
</xsl:template>

<xsl:template match="pi:sage-marker" mode="fragment-slice"/>

<!-- Kill some templates temporarily -->
<xsl:template name="inline-warning" />
<xsl:template name="margin-warning" />

<!-- Kill some metadata -->
<xsl:template match="title|idx|notation" />


<!-- Sage code -->
<!-- Should evolve to accomodate general template -->
<!-- A "sage" element whose parent produces cells (a division or   -->
<!-- pseudo-division) becomes a genuine executable code cell.  But -->
<!-- cells cannot nest, so a "sage" buried within a block (say an  -->
<!-- "example") that is mid-formation as a single markdown cell    -->
<!-- must not fire the cell machinery: it renders as a static      -->
<!-- "pre" element within the block's HTML.  (Splitting such a     -->
<!-- block into fragments around executable cells is the eventual  -->
<!-- goal; this static form is the fallback.)                      -->
<xsl:template match="sage">
    <!-- formulate lines of code -->
    <xsl:variable name="loc">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text">
                <xsl:value-of select="input" />
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
        <!-- contexts whose children each become top-level cells,   -->
        <!-- mirroring the block-level wildcard template            -->
        <xsl:when test="parent::*[&STRUCTURAL-FILTER;] or parent::paragraphs or parent::page or parent::introduction[parent::*[&STRUCTURAL-FILTER;]] or parent::conclusion[parent::*[&STRUCTURAL-FILTER;]]">
            <xsl:apply-templates select="." mode="sage-code-cell"/>
        </xsl:when>
        <!-- a display-only listing is never executable: a static -->
        <!-- rendering, as element nodes that serialize as part   -->
        <!-- of the enclosing cell                                -->
        <xsl:when test="@type = 'display'">
            <pre class="code-display">
                <xsl:value-of select="substring($loc, 1, string-length($loc)-1)" />
            </pre>
        </xsl:when>
        <!-- interior to a block being split into fragments: the -->
        <!-- rendering carries a marker where the code belongs,  -->
        <!-- and the block's template slices at the markers and  -->
        <!-- supplies the genuine code cells                     -->
        <xsl:otherwise>
            <pi:sage-marker/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- An executable cell from a "sage" element, with optional -->
<!-- structure metadata when it sits interior to a block     -->
<xsl:template match="sage" mode="sage-code-cell">
    <xsl:param name="element" select="''"/>
    <xsl:param name="identifier" select="''"/>
    <xsl:param name="part" select="''"/>
    <!-- formulate lines of code -->
    <xsl:variable name="loc">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text">
                <xsl:value-of select="input" />
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <!-- we trim a final trailing newline -->
    <!-- as we wrap into a single string  -->
    <xsl:call-template name="code-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
                <xsl:value-of select="substring($loc, 1, string-length($loc)-1)" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
        <xsl:with-param name="element" select="$element"/>
        <xsl:with-param name="identifier" select="$identifier"/>
        <xsl:with-param name="part" select="$part"/>
    </xsl:call-template>
</xsl:template>

<!-- #### -->
<!-- Math -->
<!-- #### -->

<!-- Our sanitization procedures will preserve author's line   -->
<!-- breaks within mathematics.  Even inline math might be a   -->
<!-- complicated construction, like a column vector, with line -->
<!-- breaks.  Replacements late in the conversion will make    -->
<!-- these the "\n" acceptable in JSON.                        -->

<!-- This template wraps inline math in delimiters                   -->
<!-- The Jupyter notebook appears to support the AMS-style for       -->
<!-- inline math ( \(, \) ).  But in doing so, it fails to prevent   -->
<!-- Markdown syntax from mucking up the math.  For example, two     -->
<!-- underscores in a Markdown cell will look like underlining       -->
<!-- and override the LaTeX meaning for subscripts.  They can        -->
<!-- be escaped, but easier to just deal with "plain text" dollar    -->
<!-- signs as a possibility.  There is no issue for display          -->
<!-- mathematics, presumably since we use environments, exclusively. -->
<xsl:template name="inline-math-wrapper">
    <xsl:param name="math"/>
    <xsl:text>$</xsl:text>
    <xsl:value-of select="$math"/>
    <xsl:text>$</xsl:text>
</xsl:template>

<!-- The "display-math-wrapper" in the base HTML conversion has an -->
<!-- additional "process-math" class, to be used with a MathJax 3  -->
<!-- configuration to limit the scope of MathJax's conversions.    -->
<!-- Rather than a hook or override to get this just right, we     -->
<!-- leave the additional class name in place, to no real effect.  -->
<!-- For it to be effective will require the overall "ignore-math" -->
<!-- class, and access to the MathJax configuration.               -->

<!-- The notebook's MathJax reads mathematics from the *raw*        -->
<!-- markdown source, before any HTML entity is decoded.  So        -->
<!-- entity-escaping inside mathematics arrives literally: an       -->
<!-- alignment ampersand serialized as "&amp;amp;" renders as a     -->
<!-- visible "amp;".  Text within a math wrapper (the               -->
<!-- "process-math" class) therefore serializes verbatim.  Bare     -->
<!-- markup characters are not a hazard: PreTeXt requires \lt for   -->
<!-- "less than" within mathematics, and MathJax lifts the math     -->
<!-- from the source before the remainder is parsed as HTML.        -->
<xsl:template match="text()[ancestor::*[contains(concat(' ', normalize-space(@class), ' '), ' process-math ')]]" mode="xml-to-string">
    <xsl:value-of select="."/>
</xsl:template>

<!-- Images -->

<!-- Jupyter seems to not allow an "object" tag.        -->
<!-- So we override the HTML wrapper with a simpler     -->
<!-- version.  Interface info copied from HTML version. -->

<!-- A named template creates the infrastructure for an SVG image -->
<!-- Parameters                                 -->
<!-- svg-filename: required, full relative path -->
<!-- png-fallback-filename: optional            -->
<!-- image-width: required                      -->
<!-- image-description: optional                -->
<xsl:template name="svg-wrapper">
    <xsl:param name="svg-filename" />
    <xsl:param name="png-fallback-filename" select="''" />
    <xsl:param name="image-width" />
    <xsl:param name="image-description" select="''" />
    <xsl:element name="img">
        <xsl:attribute name="src">
            <xsl:value-of select="$svg-filename" />
        </xsl:attribute>
        <xsl:attribute name="width">
            <xsl:value-of select="$image-width" />
        </xsl:attribute>
        <!-- alt attribute for accessibility -->
        <xsl:attribute name="alt">
            <xsl:value-of select="$image-description" />
        </xsl:attribute>
    </xsl:element>
</xsl:template>

<!-- ##### -->
<!-- Icons -->
<!-- ##### -->

<!-- Unicode characters will relieve necessity of        -->
<!-- Font Awesome CSS loading, $icon-table is in -common -->
<xsl:template match="icon">
    <!-- the name attribute of the "icon" in text as a string -->
    <xsl:variable name="icon-name">
        <xsl:value-of select="@name"/>
    </xsl:variable>

    <!-- for-each is just one node, but sets context for key() -->
    <xsl:for-each select="$icon-table">
        <xsl:value-of select="key('icon-key', $icon-name)/@unicode" />
    </xsl:for-each>
</xsl:template>

<!--
TODO: (overall)

1.  DONE: Interfere with left-angle bracket to make elements not evaporate in serialization.
2.  DONE: Escape $ so that pairs do not go MathJax on us.
3.  DONE: Do we need to protect a hash?  So not interpreted as a title?  Underscores, too.
4.  Update CSS, use add-on, make an output version to parse as text.
5.  ABANDON: Markup enclosed Sage cells (non-top-level) to allow dropout, dropin.
    Bad idea, breaks CSS begin/end across multiple cells
6.  Remove empty strings, empty anything, with search/replace step on null constructions.
7.  Maybe replace tabs (good for Sage code and/or JSON fidelity)?
8.  Hyperlinks within a file work better if not prefixed with file name.
    (General improvement, but not so important with knowls available.)
-->


<!-- ############### -->
<!-- Text Processing -->
<!-- ############### -->

<!-- The general template for matching "text()" nodes will     -->
<!-- apply this template (there is a hook there).  Verbatim    -->
<!-- text should be manipulated in templates with              -->
<!-- "xsl:value-of" and so not come through here.  Conversely, -->
<!-- when "xsl:apply-templates" is applied, the template will  -->
<!-- have effect.                                              -->
<!--                                                           -->
<!-- Our emphasis originally is on escaping characters that    -->
<!-- Markdown has hijacked for special purposes.               -->

<xsl:template name="text-processing">
    <xsl:param name="text"/>

    <!-- Backslash first, then clear to add more -->
    <xsl:variable name="backslash-fixed"  select="str:replace($text,            '\',  '\\')"/>
    <xsl:variable name="lbrace-fixed"     select="str:replace($backslash-fixed, '{',  '\{')"/>
    <xsl:variable name="rbrace-fixed"     select="str:replace($lbrace-fixed,    '}',  '\}')"/>
    <xsl:variable name="hash-fixed"       select="str:replace($rbrace-fixed,    '#',  '\#')"/>
    <xsl:variable name="dollar-fixed"     select="str:replace($hash-fixed,      '$',  '\$')"/>
    <xsl:variable name="underscore-fixed" select="str:replace($dollar-fixed,    '_',  '\_')"/>
    <xsl:variable name="asterisk-fixed"   select="str:replace($underscore-fixed,'*',  '\*')"/>
    <xsl:variable name="backtick-fixed"   select="str:replace($asterisk-fixed,  '`',  '\`')"/>

    <!-- We disrupt accidental MathJax formulations in running text.  MathJax     -->
    <!-- needs both begin *and* end markers, enclosed in a single HTML element,   -->
    <!-- before it will start injecting itself onto the page.  We leave a begin   -->
    <!-- marker alone, but disrupt an end marker with a superfluous minimal span. -->
    <!-- This is advice from David Cervone, JMM Baltimore, 2019-01-18.            -->
    <!-- Note: we serialize the necessary HTML by hand, and the brace and         -->
    <!-- backslash used in matching the leading portion of a LaTeX environment    -->
    <!-- were both escaped above.                                                 -->
    <xsl:variable name="inline-fixed"      select="str:replace($backtick-fixed, '\)',      '&lt;span&gt;\)&lt;/span&gt;' )"/>
    <xsl:variable name="environment-fixed" select="str:replace($inline-fixed,   '\\end\{', '&lt;span&gt;\\end\{&lt;/span&gt;' )"/>

    <xsl:value-of select="$environment-fixed"/>
</xsl:template>

<!-- ############### -->
<!-- Inline Verbatim -->
<!-- ############### -->

<!-- Jupyter does a very good (but incomplete) job with inline -->
<!-- verbatim text, requiring little care by authors.  So we   -->
<!-- override.  The wrapper builds a genuine "code" element    -->
<!-- whose content is plain text: the serialization step then  -->
<!-- escapes any markup characters exactly once, so an author  -->
<!-- may write about elements (like in the Author's Guide!)    -->
<!-- and they arrive as visible text, never as interior HTML.  -->
<xsl:template name="code-wrapper">
    <xsl:param name="content"/>
    <code class="code-inline tex2jax_ignore">
        <xsl:value-of select="$content"/>
    </code>
</xsl:template>

<!-- #### -->
<!-- URLs -->
<!-- #### -->

<!-- We encode some characters in href attributes, here   -->
<!-- just for the Jupyter conversion, as an override of   -->
<!-- part of the serialization.  This could instead be    -->
<!-- sanitization of the "url"element, in the general     -->
<!-- HTML conversion or here for just Jupyter.  So        -->
<!-- eventually this could migrate to another location    -->
<!-- in the pipeline.                                     -->
<!--                                                      -->
<!-- The problem seems to be characters, used in pairs,   -->
<!-- to delimit text for Markdown or MathJax:  underscore -->
<!-- is italics, asterisk is emphasis, and dollar signs   -->
<!-- delimit math.  This is a hunch based on similar      -->
<!-- experiences with inline verbatim text.  But here we  -->
<!-- are fortunate to be able to encode the dollar sign.  -->
<!-- NOTE: This was a hook into the old                   -->
<!-- "serialize" templates. Now intercepts xml-to-string  -->
<!-- but behavior with it is untested. Does it work?      -->
<!-- is it still necessary???                             -->
<!-- Tested: preserves old behavior, unclear if necessary -->
<xsl:template match="@href" mode="xml-to-string">
    <!-- sanitize value first -->
    <xsl:variable name="text">
        <xsl:value-of select="."/>
    </xsl:variable>
    <xsl:variable name="underscore-fixed" select="str:replace($text,             '_',  '%5F')"/>
    <xsl:variable name="asterisk-fixed"   select="str:replace($underscore-fixed, '*',  '%2A')"/>
    <xsl:variable name="dollar-fixed"     select="str:replace($asterisk-fixed,   '$',  '%24')"/>
    <!-- construct new attribute, spacing, name, value -->
    <xsl:text> </xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>="</xsl:text>
    <xsl:value-of select="$dollar-fixed"/>
    <xsl:text>"</xsl:text>
</xsl:template>

<!-- ################# -->
<!-- Cell Construction -->
<!-- ################# -->

<!-- A Jupyter notebook is a flat sequence of cells, of type either  -->
<!-- "markdown" or "code", each holding one string.  We describe     -->
<!-- each notebook as a "notebook" element holding a flat list of    -->
<!-- "cell" elements; the Python conversion routine turns each       -->
<!-- description into JSON with the "nbformat" library, which owns   -->
<!-- string escaping, cell boilerplate, and schema conformance.      -->
<!-- Cells cannot be nested, so cell-producing templates must never  -->
<!-- fire while another cell's content is under construction.        -->

<!-- The two templates immediately following are historical seams:  -->
<!-- every string destined for a cell was once delimited by markers -->
<!-- these templates produced.  A cell's content is now a single    -->
<!-- string, so they are no-ops, retained since callers throughout  -->
<!-- this stylesheet still frame content with them, and they mark   -->
<!-- exactly the boundaries a future refinement (say, a markdown    -->
<!-- flavor of cell content) might need to intercept.               -->

<xsl:template name="begin-string"/>

<xsl:template name="end-string"/>

<!-- A Jupyter markdown cell intended  -->
<!-- to hold markdown or unstyled HTML -->
<xsl:template name="markdown-cell">
    <xsl:param name="content" />
    <cell type="markdown">
        <xsl:value-of select="$content" />
    </cell>
</xsl:template>

<!-- A Jupyter markdown cell intended -->
<!-- to hold PreTeXt styled HTML      -->
<!-- Serialization here is "by hand"  -->
<!-- The three structure parameters describe a cell which is a  -->
<!-- *fragment* of a PreTeXt element split around code cells;   -->
<!-- they land in the notebook cell's metadata, preserving the  -->
<!-- hierarchy that the flat cell list cannot express directly. -->
<xsl:template name="pretext-cell">
    <xsl:param name="content" />
    <xsl:param name="element" select="''"/>
    <xsl:param name="identifier" select="''"/>
    <xsl:param name="part" select="''"/>
    <cell type="markdown">
        <xsl:if test="not($element = '')">
            <xsl:attribute name="element">
                <xsl:value-of select="$element"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="not($identifier = '')">
            <xsl:attribute name="identifier">
                <xsl:value-of select="$identifier"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="not($part = '')">
            <xsl:attribute name="part">
                <xsl:value-of select="$part"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:text>&lt;div class="mathbook-content"&gt;</xsl:text>
        <xsl:value-of select="$content" />
        <xsl:text>&lt;/div&gt;</xsl:text>
    </cell>
</xsl:template>

<!-- A Jupyter code cell intended -->
<!-- to hold raw text/code        -->
<xsl:template name="code-cell">
    <xsl:param name="content" />
    <xsl:param name="element" select="''"/>
    <xsl:param name="identifier" select="''"/>
    <xsl:param name="part" select="''"/>
    <!-- "purpose" flags special cells (only 'styling' so far) for -->
    <!-- extra treatment by the Python routine: the styling cell   -->
    <!-- collapses, and ships with its output pre-rendered         -->
    <xsl:param name="purpose" select="''"/>
    <cell type="code">
        <xsl:if test="not($purpose = '')">
            <xsl:attribute name="purpose">
                <xsl:value-of select="$purpose"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="not($element = '')">
            <xsl:attribute name="element">
                <xsl:value-of select="$element"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="not($identifier = '')">
            <xsl:attribute name="identifier">
                <xsl:value-of select="$identifier"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="not($part = '')">
            <xsl:attribute name="part">
                <xsl:value-of select="$part"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:value-of select="$content" />
    </cell>
</xsl:template>

<!-- We don't want any permalinks -->
<xsl:template match="*" mode="permalink"/>

</xsl:stylesheet>
