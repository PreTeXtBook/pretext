<?xml version='1.0'?>

<!--********************************************************************
Copyright 2026 Robert A. Beezer

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

<!-- Conversion of PreTeXt source to XSL Formatting Objects (XSL-FO),  -->
<!-- a LaTeX-free route to a PDF.  A formatter, such as Apache FOP,    -->
<!-- renders the resulting *.fo file as a PDF.  This conversion is     -->
<!-- experimental and very incomplete; see  doc/pretext-fo-roadmap.md  -->
<!-- for the development plan, and see the coverage harness at the end -->
<!-- of this stylesheet for the development workflow.                  -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    exclude-result-prefixes="pi"
>

<!-- Standard conversion groundwork -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>

<!-- The "indent" attribute is deliberately absent.  Indentation makes -->
<!-- the *.fo file much easier to study, but introduces whitespace     -->
<!-- into mixed content that we cannot control for: an isolated,       -->
<!-- entirely inline, "segment" of a paragraph would render with       -->
<!-- spurious spaces.  Add @indent="yes" temporarily when debugging.   -->
<xsl:output method="xml" encoding="UTF-8"/>

<!-- This variable controls representations of interactive exercises  -->
<!-- built in  pretext-assembly.xsl.  A PDF is a static format, so we -->
<!-- use the "standard" PreTeXt exercise versions.                    -->
<xsl:variable name="exercise-style" select="'static'"/>

<!-- Math will arrive as SVG produced by  mathjax_latex(..., 'svg'),  -->
<!-- which absorbs clause-ending punctuation into display math only.  -->
<!-- This override of the adjacent-text-node behavior must match; see -->
<!-- pretext-epub.xsl  for the full discussion.                       -->
<xsl:variable name="math.punctuation.include" select="'display'"/>

<!-- ############################## -->
<!-- Incorporate (Meld) Mathematics -->
<!-- ############################## -->

<!-- Mathematics will be rendered by MathJax as SVG images, exactly as -->
<!-- the EPUB conversion does (see  pretext-epub.xsl  and the  epub()  -->
<!-- routine in  pretext/lib/pretext.py).  The  mathjax_latex()        -->
<!-- routine produces a file of  pi:math-representations  elements,    -->
<!-- passed in here as the  $mathfile  string parameter.  Eventually   -->
<!-- (roadmap step 5) each math placeholder template below becomes a   -->
<!-- lookup in  $math-repr, keyed on the "visible-id" of the math      -->
<!-- element, whose SVG payload lands in an                            -->
<!-- fo:instream-foreign-object.                                       -->
<xsl:param name="mathfile" select="''"/>
<xsl:variable name="math-repr" select="document($mathfile)/pi:math-representations"/>

<!-- ########### -->
<!-- Page Layout -->
<!-- ########### -->

<!-- Publisher variables for LaTeX output are honored when they map    -->
<!-- cleanly onto page-layout concepts:  $font-size  arrives with the  -->
<!-- unit attached ("11pt"), ready for use, and  $latex-sides  selects -->
<!-- mirrored margins.  The raw  $latex-page-geometry  string is input -->
<!-- for the LaTeX "geometry" package, so we do not parse it; instead  -->
<!-- we will map the *intent* of such requests as this conversion      -->
<!-- matures.                                                          -->

<!-- US Letter, matching the LaTeX conversion default -->
<xsl:variable name="page-width" select="'8.5in'"/>
<xsl:variable name="page-height" select="'11in'"/>

<!-- Mirrored margins for a two-sided document: the inner (binding) -->
<!-- margin is larger.  Equal margins for a one-sided document.     -->
<xsl:variable name="margin-inner">
    <xsl:choose>
        <xsl:when test="$b-latex-two-sides">
            <xsl:text>1.25in</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>1in</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="margin-outer">
    <xsl:choose>
        <xsl:when test="$b-latex-two-sides">
            <xsl:text>0.75in</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>1in</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- ##### -->
<!-- Entry -->
<!-- ##### -->

<!-- Deprecation warnings are universal, so issued here on the        -->
<!-- original source, before attention turns to the assembled source. -->
<!-- The "DejaVu Serif" font family is Unicode-capable and is located -->
<!-- by the font auto-detection enabled in the  fop.xconf             -->
<!-- configuration; generic "serif" is the fallback.                  -->
<xsl:template match="/">
    <xsl:apply-templates select="$original" mode="generic-warnings"/>
    <xsl:apply-templates select="$original" mode="element-deprecation-warnings"/>
    <xsl:apply-templates select="$original" mode="parameter-deprecation-warnings"/>
    <fo:root font-family="DejaVu Serif, serif" font-size="{$font-size}">
        <fo:layout-master-set>
            <fo:simple-page-master master-name="page-odd"
                                   page-width="{$page-width}"
                                   page-height="{$page-height}"
                                   margin-top="1in"
                                   margin-bottom="1in"
                                   margin-left="{$margin-inner}"
                                   margin-right="{$margin-outer}">
                <fo:region-body/>
            </fo:simple-page-master>
            <fo:simple-page-master master-name="page-even"
                                   page-width="{$page-width}"
                                   page-height="{$page-height}"
                                   margin-top="1in"
                                   margin-bottom="1in"
                                   margin-left="{$margin-outer}"
                                   margin-right="{$margin-inner}">
                <fo:region-body/>
            </fo:simple-page-master>
            <fo:page-sequence-master master-name="pages">
                <fo:repeatable-page-master-alternatives>
                    <fo:conditional-page-master-reference master-reference="page-odd" odd-or-even="odd"/>
                    <fo:conditional-page-master-reference master-reference="page-even" odd-or-even="even"/>
                </fo:repeatable-page-master-alternatives>
            </fo:page-sequence-master>
        </fo:layout-master-set>
        <fo:page-sequence master-reference="pages">
            <fo:flow flow-name="xsl-region-body">
                <xsl:apply-templates select="$document-root"/>
            </fo:flow>
        </fo:page-sequence>
    </fo:root>
</xsl:template>

<!-- ########## -->
<!-- Paragraphs -->
<!-- ########## -->

<!-- A first approximation: a real implementation must handle -->
<!-- interruptions by displayed items (math, lists), titled   -->
<!-- paragraphs, and the full complement of inline markup     -->
<!-- (roadmap step 2).                                        -->
<xsl:template match="p">
    <fo:block text-align="justify" space-after="0.5em">
        <xsl:apply-templates/>
    </fo:block>
</xsl:template>

<!-- ########################## -->
<!-- Mathematics (Placeholders) -->
<!-- ########################## -->

<!-- Placeholders: the authored LaTeX, visibly boxed, in a monospace -->
<!-- font.  To be replaced by MathJax-produced SVG images via the    -->
<!-- $math-repr  variable above (roadmap step 5).                    -->
<xsl:template match="m">
    <fo:inline font-family="monospace" border="0.5pt solid #888888" padding="0pt 2pt">
        <xsl:value-of select="."/>
    </fo:inline>
</xsl:template>

<xsl:template match="me|men|md|mdn">
    <fo:block font-family="monospace"
              border="0.5pt solid #888888"
              padding="2pt"
              space-before="0.5em"
              space-after="0.5em"
              text-align="center">
        <xsl:value-of select="."/>
        <!-- reclaim any clause-ending punctuation absorbed by display math -->
        <xsl:if test="self::md">
            <xsl:apply-templates select="." mode="get-clause-punctuation-mark"/>
        </xsl:if>
    </fo:block>
</xsl:template>

<!-- ################ -->
<!-- Coverage Harness -->
<!-- ################ -->

<!-- *Every* element needs an implementation, or it lands here and is  -->
<!-- reported as unimplemented.  This template has the lowest priority -->
<!-- but the highest import precedence, so it also shadows the         -->
<!-- default-mode templates of the imported stylesheets: an element is -->
<!-- only "done" once *this* stylesheet handles it.  We recurse        -->
<!-- through element children, and drop interior text, so the output   -->
<!-- is always legal XSL-FO.  Survey what remains to implement, as a   -->
<!-- counted summary, with something like                              -->
<!--     pretext/pretext -v ... 2>&1 | grep 'PTX:FO-TODO' \            -->
<!--         | sort | uniq -c | sort -rn                               -->
<xsl:template match="*">
    <xsl:message>PTX:FO-TODO: <xsl:value-of select="local-name()"/></xsl:message>
    <xsl:apply-templates select="*"/>
</xsl:template>

</xsl:stylesheet>
