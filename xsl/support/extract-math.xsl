<?xml version='1.0'?>

<!--********************************************************************
Copyright 2020 Robert A. Beezer

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

<!-- We build a very basic HTML page intended for MathJax    -->
<!-- to process with its *-page tools                        -->
<!--                                                         -->
<!-- Pro: faster than a new system call for each and         -->
<!--      every math element                                 -->
<!-- Pro: if MathJax produces output that is not XHTML       -->
<!--      any defects will be minimal and controllable       -->
<!-- Con: one massive cache of font info, which could be     -->
<!--      much more than an eventual chunked page might need -->
<!--                                                         -->
<!-- The result is meant to be processed by the              -->
<!-- package-math.xsl  stylesheet for eventual use           -->

<!-- NB: string functions can leave if latex macros get fixed elsewhere -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="str"
>

<!-- Get internal ID's for filenames, etc -->
<!-- Plus variables post-assembly         -->
<xsl:import href="../pretext-common.xsl" />
<!-- Process to enhanced source before relying on IDs -->
<!-- So we expect the publisher file, which might for -->
<!-- example point to (static) representations of     -->
<!-- WeBWorK problems with math elements              -->
<xsl:import href="../pretext-assembly.xsl"/>
<!-- Use the HTML variants, as we are making input for MathJax -->
<xsl:import href="../pretext-html.xsl" />

<!-- Write XML, since 'output="html"' creates things  -->
<!-- like unclosed "meta" and these get replicated by  -->
<!-- the MathJax tools, producing a non-XML file. -->

<!-- Output an HTML for MathJax to consume page -->
<xsl:output method="xml" omit-xml-declaration="yes" doctype-system="about:legacy-compat"/>

<!-- This stylesheet is parameterized by how trailing punctuation       -->
<!-- is handled by math elements.  An  xsl:param  immediately overrides -->
<!-- the global cross-stylesheet variable, to counteract how the HTML   -->
<!-- routinely incorporates trailing punctuation into the LaTeX math.   -->
<!-- The param default is the same as the variable default.             -->
<!-- NB: a stylesheet that eventually consumes this math will need to   -->
<!-- use the modal "get-clause-punctuation" template to coordinate with -->
<!-- what happens here.  Give the global varible the same value and     -->
<!-- then the "get-clause-punctuation" used at the end of the           -->
<!-- construction of the math element should produce the right action.  -->
<xsl:param name="math.punctuation" select="'none'"/>
<xsl:variable name="math.punctuation.include" select="$math.punctuation"/>

<!-- We import the HTML stylesheet since we want HTML versions of -->
<!-- the math bits, but we don't need all the chunking machinery  -->
<!-- for extracting math, since we are building a single file,    -->
<!-- so we set the level to control associated templates          -->
<xsl:variable name="chunk-level" select="number(0)"/>

<!-- No special wrapping needed, so just copy the content -->
<xsl:template match="me|men|md|mdn" mode="display-math-wrapper">
    <xsl:param name="content" />
    <xsl:copy-of select="$content" />
</xsl:template>

<!-- Build a super-simple HTML page, whose only -->
<!-- purpose is to serve as input to a MathJax  -->
<!-- *-page routine.                            -->
<!-- "cruise" mode wanders the tree, so when    -->
<!-- we get to an item of interest we can hit   -->
<!-- it with "regular" templates and not cruise -->
<!-- down into components.                      -->
<xsl:template match="/">
    <html>
        <!-- no "head" at all -->
        <body>
            <!-- MathJax predefines \lt and \gt to avoid XML's <, >      -->
            <!-- We therefore define these for LaTeX use to be           -->
            <!-- universal.  Usually no harm having them in HTML output, -->
            <!-- BUT MathJax puts raw LaTeX into the @alttext attribute, -->
            <!-- where our definitions with unescaped version of <, >    -->
            <!-- are a syntax violation.  So we scrub them.              -->
            <!-- TODO: move this and make two $latex-macros,             -->
            <!-- one for HTML and one for LaTeX                          -->
            <xsl:variable name="no-less-than"      select="str:replace($latex-macros, '\newcommand{\lt}{&lt;}&#xa;', '')"/>
            <xsl:variable name="latex-macros-html" select="str:replace($no-less-than, '\newcommand{\gt}{&gt;}&#xa;', '')"/>
            <!-- put macros and packages early for MJ to find         -->
            <!-- give the div an @id so we can trash it as a leftover -->
            <div id="latex-macros">
                <xsl:call-template name="begin-inline-math"/>
                <xsl:value-of select="$latex-packages-mathjax"/>
                <xsl:value-of select="$latex-macros-html"/>
                <xsl:call-template name="end-inline-math"/>
            </div>
            <!-- modal template to bypass everything but math -->
            <xsl:apply-templates select="$root" mode="cruise"/>
        </body>
    </html>
</xsl:template>

<!-- Associate IDs with the LaTeX so we -->
<!-- know where the results belong      -->
<xsl:template match="m|me|men|md|mdn" mode="cruise">
    <div context="{local-name(.)}">
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="visible-id"/>
        </xsl:attribute>
        <xsl:apply-templates select="."/>
    </div>
</xsl:template>

<!-- We want the hard-coded "tags" (numbered equations) that PreTeXt -->
<!-- supplies, but we do not want the "\label{}" that comes along as -->
<!-- part of MathJax's semi-automatic linking mechanism.  Since we   -->
<!-- disassociate the math from its surroundings, any sort of        -->
<!-- cross-referencing of equations should be handled another way.   -->
<!-- But we do need to "name" equations.                             -->
<!--                                                                 -->
<!-- These are stripped-down versions from the (imported) -html      -->
<!-- conversion.  It is possible they will become identical some     -->
<!-- day and then these versions can go away.                        -->

<xsl:template match="men|mrow" mode="tag">
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="mrow[@tag]" mode="tag">
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="@tag" mode="tag-symbol" />
    <xsl:text>}</xsl:text>
</xsl:template>


<!-- An "xref" inside of math is a delicate matter.                                   -->
<!--                                                                                  -->
<!--   1.  A number is computed based on various numbering switches so this           -->
<!--       sort of information needs to be available to this conversion.              -->
<!--                                                                                  -->
<!--   2.  A \href{} is recognized by MathJax and puts an "a" element into            -->
<!--       an output SVG.  But Calibre (for example) does not seem to recognize this. -->
<!--       See "xLinks" section of https://wiki.mobileread.com/wiki/SVG (2020-03-25), -->
<!--       perhaps the MathJax version does not have enough namespace info, etc.      -->
<!--       The \knowl{} extension of the conversion to HTML is not understood at all. -->
<!--       A knowl requires https://pretextbook.org/js/lib/mathjaxknowl.js            -->
<!--       loaded as a MathJax extension for knowls to possibly render                -->
<!--                                                                                  -->
<!--   3.  Our links' base filename will depend on chunking level, and the file       -->
<!--       extension may need to ".xhtml" (not ".html") if the destination is EPUB.   -->
<!--       And the lxml parser complains when a global XSL variable is redefined      -->
<!--       in an override/import.                                                     -->
<!--                                                                                  -->
<!-- We are going to punt right now and just drop in text, so (1) is  important,      -->
<!-- but (2) and (3) are no longer issues. This override just plops in text, which    -->
<!-- automatically comes wrapped in a LaTeX \text{}                                   -->
<xsl:template match="*" mode="xref-link-display-math">
    <xsl:param name="target"/>
    <xsl:param name="content"/>
    <!-- <xsl:text>\text{</xsl:text> -->
    <xsl:value-of select="$content"/>
    <!-- <xsl:text>}</xsl:text> -->
</xsl:template>

<!-- Knowls -->
<!-- No cross-reference should be a knowl      -->
<!-- Turn off knowls so SVG production goes OK -->
<!-- TODO: Need to know desired chunk level for links to be -->
<!-- correct, possibly in the publisher file once revisited -->
<xsl:template match="*" mode="xref-as-knowl">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- Traverse the tree,       -->
<!-- looking for things to do -->
<!-- http://stackoverflow.com/questions/3776333/stripping-all-elements-except-one-in-xml-using-xslt -->
<xsl:template match="@*|node()" mode="cruise">
    <xsl:apply-templates select="@*|node()" mode="cruise"/>
</xsl:template>

</xsl:stylesheet>