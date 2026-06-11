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

<!-- ##################### -->
<!-- Traditional Divisions -->
<!-- ##################### -->

<!-- The traditional divisions: titled headings, then a recursion  -->
<!-- through the contents.  Numbers, localized type names, and     -->
<!-- titles all come from the machinery of  pretext-common.xsl.    -->
<!-- Specialized divisions, and front and back matter, come later. -->

<!-- The document root.  A real title page is far in the future, -->
<!-- so the document title renders as a large, centered heading. -->
<xsl:template match="article|book">
    <fo:block font-size="200%"
              font-weight="bold"
              text-align="center"
              space-after="2em">
        <xsl:apply-templates select="." mode="title-full"/>
    </fo:block>
    <xsl:apply-templates/>
</xsl:template>

<!-- A heading: optional localized "type-name number", then the     -->
<!-- title.  An unnumbered division (perhaps numbering is limited   -->
<!-- by the publisher's numbering level) gets a title-only heading. -->
<xsl:template match="chapter|section|subsection|subsubsection">
    <xsl:variable name="heading-size">
        <xsl:choose>
            <xsl:when test="self::chapter">170%</xsl:when>
            <xsl:when test="self::section">140%</xsl:when>
            <xsl:when test="self::subsection">120%</xsl:when>
            <xsl:when test="self::subsubsection">100%</xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number"/>
    </xsl:variable>
    <fo:block font-size="{$heading-size}"
              font-weight="bold"
              space-before="1.5em"
              space-after="0.75em"
              keep-with-next.within-page="always">
        <xsl:if test="not($the-number = '')">
            <xsl:apply-templates select="." mode="type-name"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$the-number"/>
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="title-full"/>
    </fo:block>
    <xsl:apply-templates/>
</xsl:template>

<!-- A "title" is consumed by modal templates reached from the   -->
<!-- parent element, and is never traversed as content, so it is -->
<!-- killed in the default mode ("subtitle" likewise).           -->
<xsl:template match="title|subtitle"/>

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

<!-- ############ -->
<!-- Basic Blocks -->
<!-- ############ -->

<!-- The basic titled blocks: a bold heading from the localized    -->
<!-- type-name, the number, and any title, then the contents.      -->
<!-- All three block families use the one "block-heading" pattern. -->
<xsl:template match="*" mode="block-heading">
    <fo:block font-weight="bold" keep-with-next.within-page="always">
        <xsl:apply-templates select="." mode="type-name"/>
        <xsl:variable name="the-number">
            <xsl:apply-templates select="." mode="number"/>
        </xsl:variable>
        <xsl:if test="not($the-number = '')">
            <xsl:text> </xsl:text>
            <xsl:value-of select="$the-number"/>
        </xsl:if>
        <xsl:text>.</xsl:text>
        <xsl:if test="title">
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="title-full"/>
        </xsl:if>
    </fo:block>
</xsl:template>

<xsl:template match="&REMARK-LIKE;">
    <fo:block space-before="1em" space-after="1em">
        <xsl:apply-templates select="." mode="block-heading"/>
        <xsl:apply-templates select="*"/>
    </fo:block>
</xsl:template>

<!-- The statement of a THEOREM-LIKE is italic, by mathematical -->
<!-- tradition, and any PROOF-LIKE follow it.                   -->
<xsl:template match="&THEOREM-LIKE;">
    <fo:block space-before="1em" space-after="1em">
        <xsl:apply-templates select="." mode="block-heading"/>
        <xsl:choose>
            <xsl:when test="statement">
                <fo:block font-style="italic">
                    <xsl:apply-templates select="statement"/>
                </fo:block>
                <xsl:apply-templates select="&PROOF-LIKE;"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="*"/>
            </xsl:otherwise>
        </xsl:choose>
    </fo:block>
</xsl:template>

<xsl:template match="&EXAMPLE-LIKE;">
    <fo:block space-before="1em" space-after="1em">
        <xsl:apply-templates select="." mode="block-heading"/>
        <xsl:choose>
            <xsl:when test="statement">
                <xsl:apply-templates select="statement"/>
                <xsl:apply-templates select="&SOLUTION-LIKE;"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="*"/>
            </xsl:otherwise>
        </xsl:choose>
    </fo:block>
</xsl:template>

<!-- A general-purpose container, no possibilities enforced. -->
<xsl:template match="statement">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- An italic run-in heading, the contents, and a right-aligned -->
<!-- tombstone to finish.  The tombstone occupies its own line;  -->
<!-- attaching it to the final line of the final paragraph is a  -->
<!-- refinement for later.                                       -->
<xsl:template match="&PROOF-LIKE;">
    <fo:block space-before="1em" space-after="1em">
        <fo:block font-style="italic" keep-with-next.within-page="always">
            <xsl:apply-templates select="." mode="type-name"/>
            <xsl:text>.</xsl:text>
        </fo:block>
        <xsl:apply-templates select="*"/>
        <fo:block text-align-last="justify">
            <fo:leader leader-pattern="space"/>
            <!-- "DejaVu Serif" lacks END OF PROOF, the sans variant has it -->
            <fo:inline font-family="DejaVu Sans, sans-serif">
                <xsl:text>&#x220e;</xsl:text>
            </fo:inline>
        </fo:block>
    </fo:block>
</xsl:template>

<!-- Solutions to EXAMPLE-LIKE, with an italic run-in heading. -->
<xsl:template match="&SOLUTION-LIKE;">
    <fo:block space-before="1em">
        <fo:block font-style="italic" keep-with-next.within-page="always">
            <xsl:apply-templates select="." mode="type-name"/>
            <xsl:text>.</xsl:text>
        </fo:block>
        <xsl:apply-templates select="*"/>
    </fo:block>
</xsl:template>

<!-- ############# -->
<!-- Inline Markup -->
<!-- ############# -->

<!-- Semantic inline markup, mostly by font change.  An "alert" -->
<!-- gets both weight and style, distinct from "em" and "term". -->
<xsl:template match="em|foreign|pubtitle|taxon">
    <fo:inline font-style="italic">
        <xsl:apply-templates/>
    </fo:inline>
</xsl:template>

<xsl:template match="term">
    <fo:inline font-weight="bold">
        <xsl:apply-templates/>
    </fo:inline>
</xsl:template>

<xsl:template match="alert">
    <fo:inline font-weight="bold" font-style="italic">
        <xsl:apply-templates/>
    </fo:inline>
</xsl:template>

<!-- An "articletitle" is quoted, in the style of CMOS. -->
<xsl:template match="articletitle">
    <xsl:apply-templates select="." mode="lq-character"/>
    <xsl:apply-templates/>
    <xsl:apply-templates select="." mode="rq-character"/>
</xsl:template>

<!-- Edits: additions, and two flavors of subtractions. -->
<xsl:template match="insert">
    <fo:inline text-decoration="underline">
        <xsl:apply-templates/>
    </fo:inline>
</xsl:template>

<xsl:template match="delete|stale">
    <fo:inline text-decoration="line-through">
        <xsl:apply-templates/>
    </fo:inline>
</xsl:template>

<!-- Abbreviations, acronyms, initialisms: no special typography. -->
<xsl:template match="abbr|acro|init">
    <xsl:apply-templates/>
</xsl:template>

<!-- Implementations of abstract templates from  pretext-common.xsl. -->
<!-- The generic machinery there (inline verbatim text, bibliography -->
<!-- entries, internal markup) calls on these for output-specific    -->
<!-- font changes.                                                   -->
<xsl:template name="code-wrapper">
    <xsl:param name="content"/>
    <fo:inline font-family="monospace">
        <xsl:value-of select="$content"/>
    </fo:inline>
</xsl:template>

<xsl:template match="*" mode="italic">
    <fo:inline font-style="italic">
        <xsl:apply-templates/>
    </fo:inline>
</xsl:template>

<xsl:template match="*" mode="bold">
    <fo:inline font-weight="bold">
        <xsl:apply-templates/>
    </fo:inline>
</xsl:template>

<xsl:template match="*" mode="monospace">
    <fo:inline font-family="monospace">
        <xsl:apply-templates/>
    </fo:inline>
</xsl:template>

<!-- ########## -->
<!-- Characters -->
<!-- ########## -->

<!-- pretext-common.xsl  implements the elements for special      -->
<!-- characters, Latin abbreviations, quotation constructions,    -->
<!-- verbatim snippets ("c", "tag", "tage", "attr"), and logos,   -->
<!-- in terms of abstract "*-character" templates which receive   -->
<!-- concrete Unicode values below.  The coverage harness shadows -->
<!-- those default-mode templates, so an  xsl:apply-imports       -->
<!-- reinstates each element here: an element leaves the harness  -->
<!-- report only by deliberately joining this list.               -->
<xsl:template match="pretext|prefigure[not(node())]|xetex|xelatex|ad|am|bc|ca|eg|etal|etc|ie|nb|pm|ps|vs|viz|nbsp|ndash|mdash|lsq|rsq|lq|rq|ldblbracket|rdblbracket|langle|rangle|ellipsis|midpoint|swungdash|permille|pilcrow|section-mark|minus|times|solidus|obelus|plusminus|copyright|phonomark|copyleft|registered|trademark|servicemark|degree|prime|dblprime|q|sq|dblbrackets|angles|c|tag|tage|attr">
    <xsl:apply-imports/>
</xsl:template>

<!-- Quotation marks: fixed Unicode for now.  The HTML conversion -->
<!-- localizes quotation style by language; port that here when   -->
<!-- localization becomes a focus.                                -->
<xsl:template match="*" mode="lsq-character">
    <xsl:text>&#x2018;</xsl:text>
</xsl:template>
<xsl:template match="*" mode="rsq-character">
    <xsl:text>&#x2019;</xsl:text>
</xsl:template>
<xsl:template match="*" mode="lq-character">
    <xsl:text>&#x201c;</xsl:text>
</xsl:template>
<xsl:template match="*" mode="rq-character">
    <xsl:text>&#x201d;</xsl:text>
</xsl:template>

<!-- The Unicode code points below match the HTML conversion. -->
<xsl:template name="nbsp-character">
    <xsl:text>&#xa0;</xsl:text>
</xsl:template>
<xsl:template name="ndash-character">
    <xsl:text>&#x2013;</xsl:text>
</xsl:template>
<xsl:template name="mdash-character">
    <xsl:text>&#x2014;</xsl:text>
</xsl:template>
<xsl:template name="thin-space-character">
    <xsl:text>&#x2009;</xsl:text>
</xsl:template>
<xsl:template name="ldblbracket-character">
    <xsl:text>&#x27e6;</xsl:text>
</xsl:template>
<xsl:template name="rdblbracket-character">
    <xsl:text>&#x27e7;</xsl:text>
</xsl:template>
<xsl:template name="langle-character">
    <xsl:text>&#x3008;</xsl:text>
</xsl:template>
<xsl:template name="rangle-character">
    <xsl:text>&#x3009;</xsl:text>
</xsl:template>
<xsl:template name="ellipsis-character">
    <xsl:text>&#x2026;</xsl:text>
</xsl:template>
<xsl:template name="midpoint-character">
    <xsl:text>&#xb7;</xsl:text>
</xsl:template>
<xsl:template name="swungdash-character">
    <xsl:text>&#x2053;</xsl:text>
</xsl:template>
<xsl:template name="permille-character">
    <xsl:text>&#x2030;</xsl:text>
</xsl:template>
<xsl:template name="pilcrow-character">
    <xsl:text>&#xb6;</xsl:text>
</xsl:template>
<xsl:template name="section-mark-character">
    <xsl:text>&#xa7;</xsl:text>
</xsl:template>
<xsl:template name="minus-character">
    <xsl:text>&#x2212;</xsl:text>
</xsl:template>
<xsl:template name="times-character">
    <xsl:text>&#xd7;</xsl:text>
</xsl:template>
<xsl:template name="solidus-character">
    <xsl:text>&#x2044;</xsl:text>
</xsl:template>
<xsl:template name="obelus-character">
    <xsl:text>&#xf7;</xsl:text>
</xsl:template>
<xsl:template name="plusminus-character">
    <xsl:text>&#xb1;</xsl:text>
</xsl:template>
<xsl:template name="copyright-character">
    <xsl:text>&#xa9;</xsl:text>
</xsl:template>
<xsl:template name="phonomark-character">
    <xsl:text>&#x2117;</xsl:text>
</xsl:template>
<xsl:template name="copyleft-character">
    <xsl:text>&#x1f12f;</xsl:text>
</xsl:template>
<xsl:template name="registered-character">
    <xsl:text>&#xae;</xsl:text>
</xsl:template>
<xsl:template name="trademark-character">
    <xsl:text>&#x2122;</xsl:text>
</xsl:template>
<xsl:template name="servicemark-character">
    <xsl:text>&#x2120;</xsl:text>
</xsl:template>
<xsl:template name="degree-character">
    <xsl:text>&#xb0;</xsl:text>
</xsl:template>
<xsl:template name="prime-character">
    <xsl:text>&#x2032;</xsl:text>
</xsl:template>
<xsl:template name="dblprime-character">
    <xsl:text>&#x2033;</xsl:text>
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
