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
    xmlns:svg="http://www.w3.org/2000/svg"
    exclude-result-prefixes="pi svg"
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

<!-- Mathematics is rendered by MathJax as SVG images, exactly as the -->
<!-- EPUB conversion does (see  pretext-epub.xsl  and the  epub()     -->
<!-- routine in  pretext/lib/pretext.py).  The  mathjax_latex()       -->
<!-- routine produces a file of  pi:math-representations  elements,   -->
<!-- passed in here as the  $mathfile  string parameter by the        -->
<!-- pdf_fo()  routine.  Absent the parameter (e.g. a bare "-f fo"    -->
<!-- build), mathematics renders as boxed placeholders; see the       -->
<!-- "Mathematics" section below for both.                            -->
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

<!-- A "title" is consumed by modal templates reached from the     -->
<!-- parent element, and is never traversed as content, so it is   -->
<!-- killed in the default mode.  Likewise the other metadata:     -->
<!-- "idx" (index entries), "notation", and image descriptions all -->
<!-- render elsewhere (or not yet), never as in-place content.     -->
<xsl:template match="title|subtitle|idx|notation|shortdescription|description"/>

<!-- ########## -->
<!-- Paragraphs -->
<!-- ########## -->

<!-- The "run-in-heading" parameter carries the heading of a      -->
<!-- surrounding block (theorem, proof, ...) for a paragraph that -->
<!-- leads off that block's content; see "heading-then-content".  -->
<xsl:template match="p">
    <xsl:param name="run-in-heading"/>
    <fo:block text-align="justify" space-after="0.5em">
        <xsl:copy-of select="$run-in-heading"/>
        <xsl:apply-templates/>
    </fo:block>
</xsl:template>

<!-- ############ -->
<!-- Basic Blocks -->
<!-- ############ -->

<!-- The basic titled blocks: a bold heading from the localized  -->
<!-- type-name, the number, and any title, run in to the leading -->
<!-- paragraph of the contents.                                  -->

<!-- The heading, as an inline.  The font style is reset, since    -->
<!-- the heading may land inside an italic THEOREM-LIKE statement. -->
<xsl:template match="*" mode="block-heading">
    <fo:inline font-weight="bold" font-style="normal">
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
    </fo:inline>
</xsl:template>

<!-- XSL-FO has no run-in display, so a heading is passed as the  -->
<!-- "run-in-heading" parameter to the leading paragraph, which   -->
<!-- prepends it ("statement" forwards the parameter through).    -->
<!-- When the content does not lead with a paragraph, the heading -->
<!-- falls back to a standalone block.  The context node is the   -->
<!-- block whose children are the content; "title" is metadata,   -->
<!-- consumed by the heading, and so not content.                 -->
<xsl:template name="heading-then-content">
    <xsl:param name="heading"/>
    <xsl:variable name="content" select="*[not(self::title)]"/>
    <xsl:choose>
        <xsl:when test="$content[1][self::p] or $content[1][self::statement and *[1][self::p]]">
            <xsl:apply-templates select="$content[1]">
                <xsl:with-param name="run-in-heading" select="$heading"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="$content[position() &gt; 1]"/>
        </xsl:when>
        <xsl:otherwise>
            <fo:block keep-with-next.within-page="always">
                <xsl:copy-of select="$heading"/>
            </fo:block>
            <xsl:apply-templates select="$content"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- The block families are identical in structure; the contents -->
<!-- process in document order, so a "statement" leads and       -->
<!-- PROOF-LIKE or SOLUTION-LIKE follow.  (Only a THEOREM-LIKE   -->
<!-- statement is italic, so a "definition" stays upright.)      -->
<xsl:template match="&REMARK-LIKE;|&THEOREM-LIKE;|&EXAMPLE-LIKE;|&DEFINITION-LIKE;">
    <fo:block space-before="1em" space-after="1em">
        <xsl:variable name="heading">
            <xsl:apply-templates select="." mode="block-heading"/>
            <xsl:text> </xsl:text>
        </xsl:variable>
        <xsl:call-template name="heading-then-content">
            <xsl:with-param name="heading" select="$heading"/>
        </xsl:call-template>
    </fo:block>
</xsl:template>

<!-- A general-purpose container, otherwise transparent, though -->
<!-- the statement of a THEOREM-LIKE is italic, by mathematical -->
<!-- tradition.                                                 -->
<xsl:template match="statement">
    <xsl:param name="run-in-heading"/>
    <xsl:choose>
        <xsl:when test="parent::*[&THEOREM-FILTER;]">
            <fo:block font-style="italic">
                <xsl:apply-templates select="*[1]">
                    <xsl:with-param name="run-in-heading" select="$run-in-heading"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="*[position() &gt; 1]"/>
            </fo:block>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="*[1]">
                <xsl:with-param name="run-in-heading" select="$run-in-heading"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="*[position() &gt; 1]"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- An italic run-in heading, the contents, and a right-aligned -->
<!-- tombstone to finish.  The tombstone occupies its own line;  -->
<!-- attaching it to the final line of the final paragraph is a  -->
<!-- refinement for later.                                       -->
<xsl:template match="&PROOF-LIKE;">
    <fo:block space-before="1em" space-after="1em">
        <xsl:variable name="heading">
            <fo:inline font-style="italic">
                <xsl:apply-templates select="." mode="type-name"/>
                <xsl:text>.</xsl:text>
            </fo:inline>
            <xsl:text> </xsl:text>
        </xsl:variable>
        <xsl:call-template name="heading-then-content">
            <xsl:with-param name="heading" select="$heading"/>
        </xsl:call-template>
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
        <xsl:variable name="heading">
            <fo:inline font-style="italic">
                <xsl:apply-templates select="." mode="type-name"/>
                <xsl:text>.</xsl:text>
            </fo:inline>
            <xsl:text> </xsl:text>
        </xsl:variable>
        <xsl:call-template name="heading-then-content">
            <xsl:with-param name="heading" select="$heading"/>
        </xsl:call-template>
    </fo:block>
</xsl:template>

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Ordered and unordered lists are fo:list-block constructions. -->
<!-- The provisional label width is fixed, and generous; deep or  -->
<!-- wide markers (e.g. "xviii.") may eventually warrant a width  -->
<!-- computed from the actual labels.                             -->
<xsl:template match="ol|ul">
    <fo:list-block provisional-distance-between-starts="2em"
                   provisional-label-separation="0.25em"
                   space-before="0.5em"
                   space-after="0.5em">
        <xsl:apply-templates select="li"/>
    </fo:list-block>
</xsl:template>

<xsl:template match="ol/li|ul/li">
    <fo:list-item>
        <fo:list-item-label end-indent="label-end()">
            <fo:block text-align="end">
                <xsl:apply-templates select="." mode="list-label"/>
            </fo:block>
        </fo:list-item-label>
        <fo:list-item-body start-indent="body-start()">
            <xsl:apply-templates select="." mode="list-item-content"/>
        </fo:list-item-body>
    </fo:list-item>
</xsl:template>

<!-- The assembly stylesheet stamps every "ol" with @format-code  -->
<!-- ('1', 'a', 'A', 'i', 'I', or '0' for a zero-based list), and -->
<!-- with @marker-prefix and @marker-suffix adornments, all       -->
<!-- deconstructed from any authored @marker.                     -->
<xsl:template match="ol/li" mode="list-label">
    <xsl:variable name="the-position" select="count(preceding-sibling::li) + 1"/>
    <xsl:value-of select="parent::ol/@marker-prefix"/>
    <xsl:choose>
        <!-- a zero-based list counts from zero, in arabic numerals -->
        <xsl:when test="parent::ol/@format-code = '0'">
            <xsl:number value="$the-position - 1" format="1"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:number value="$the-position" format="{parent::ol/@format-code}"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="parent::ol/@marker-suffix"/>
</xsl:template>

<!-- Bullets via the "format-code" machinery of pretext-common.xsl, -->
<!-- which cycles disc, circle, square by level, and honors an      -->
<!-- authored @marker (the empty @marker giving no bullet at all).  -->
<xsl:template match="ul/li" mode="list-label">
    <xsl:variable name="format-code">
        <xsl:apply-templates select="parent::ul" mode="format-code"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$format-code = 'disc'">
            <xsl:text>&#x2022;</xsl:text>
        </xsl:when>
        <xsl:when test="$format-code = 'circle'">
            <xsl:text>&#x25e6;</xsl:text>
        </xsl:when>
        <xsl:when test="$format-code = 'square'">
            <xsl:text>&#x25aa;</xsl:text>
        </xsl:when>
        <!-- 'none' -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:template>

<!-- Any of these children indicates a structured list item,  -->
<!-- per the schema; otherwise the item is mixed content, set -->
<!-- as a single paragraph.                                   -->
<xsl:template match="li" mode="list-item-content">
    <xsl:choose>
        <xsl:when test="p|blockquote|pre|image|video|program|console|tabular|&FIGURE-LIKE;|&ASIDE-LIKE;|sidebyside|sbsgroup|sage">
            <xsl:apply-templates select="*"/>
        </xsl:when>
        <xsl:otherwise>
            <fo:block text-align="justify" space-after="0.5em">
                <xsl:apply-templates/>
            </fo:block>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A description list is a sequence of blocks, each with the -->
<!-- (required) title of the item as a bold run-in heading.  A -->
<!-- "dl/li" is always structured.                             -->
<xsl:template match="dl">
    <fo:block space-before="0.5em" space-after="0.5em">
        <xsl:apply-templates select="li"/>
    </fo:block>
</xsl:template>

<xsl:template match="dl/li">
    <xsl:variable name="heading">
        <fo:inline font-weight="bold" font-style="normal">
            <xsl:apply-templates select="." mode="title-full"/>
        </fo:inline>
        <xsl:text> </xsl:text>
    </xsl:variable>
    <xsl:call-template name="heading-then-content">
        <xsl:with-param name="heading" select="$heading"/>
    </xsl:call-template>
</xsl:template>

<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- An image is a centered block, with the authored @width     -->
<!-- percentage (or the documented defaults) honored by the     -->
<!-- common machinery.  The percentage width of the graphic is  -->
<!-- relative to the available width, and the image scales to   -->
<!-- it, preserving the aspect ratio.  Restricted to externally -->
<!-- provided and pre-generated images; the harness reports the -->
<!-- born-in-source kinds (e.g. "latex-image"), which need      -->
<!-- companion image-generation components.                     -->
<xsl:template match="image[@source|@pi:generated][not(ancestor::sidebyside)]">
    <xsl:variable name="width">
        <xsl:apply-templates select="." mode="get-width-percentage"/>
    </xsl:variable>
    <fo:block text-align="center" space-before="0.5em" space-after="0.5em">
        <fo:external-graphic width="{$width}"
                             content-width="scale-to-fit"
                             scaling="uniform">
            <xsl:attribute name="src">
                <xsl:text>url(</xsl:text>
                <xsl:apply-templates select="." mode="image-filename"/>
                <xsl:text>)</xsl:text>
            </xsl:attribute>
        </fo:external-graphic>
    </fo:block>
</xsl:template>

<!-- The filename, relative to the directory where FOP runs: the  -->
<!-- managed external or generated directory, the indicated file, -->
<!-- and an absent extension means a manufactured SVG (all the    -->
<!-- HTML conversion model).                                      -->
<xsl:template match="image[@source|@pi:generated]" mode="image-filename">
    <xsl:variable name="location">
        <xsl:choose>
            <xsl:when test="@pi:generated">
                <xsl:value-of select="$generated-directory"/>
                <xsl:value-of select="@pi:generated"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$external-directory"/>
                <xsl:value-of select="@source"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="extension">
        <xsl:call-template name="file-extension">
            <xsl:with-param name="filename" select="$location"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="$location"/>
    <xsl:if test="$extension = ''">
        <xsl:text>.svg</xsl:text>
    </xsl:if>
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

<!-- Keyboard keys, visibly boxed.  A @name indexes the Unicode -->
<!-- column of the key table in  pretext-common.xsl.            -->
<xsl:template match="kbd[not(@name)]">
    <fo:inline font-family="monospace" border="0.5pt solid #888888" padding="0pt 2pt">
        <xsl:value-of select="."/>
    </fo:inline>
</xsl:template>

<xsl:template match="kbd[@name]">
    <xsl:variable name="kbdkey-name" select="@name"/>
    <fo:inline font-family="monospace" border="0.5pt solid #888888" padding="0pt 2pt">
        <!-- for-each is just one node, but sets context for key() -->
        <xsl:for-each select="$kbdkey-table">
            <xsl:value-of select="key('kbdkey-key', $kbdkey-name)/@unicode"/>
        </xsl:for-each>
    </fo:inline>
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
<xsl:template match="pretext|prefigure[not(node())]|xetex|xelatex|ad|am|bc|ca|eg|etal|etc|ie|nb|pm|ps|vs|viz|nbsp|ndash|mdash|lsq|rsq|lq|rq|ldblbracket|rdblbracket|langle|rangle|ellipsis|midpoint|swungdash|permille|pilcrow|section-mark|minus|times|solidus|obelus|plusminus|copyright|phonomark|copyleft|registered|trademark|servicemark|degree|prime|dblprime|q|sq|dblbrackets|angles|c|tag|tage|attr|icon|pi:localize">
    <xsl:apply-imports/>
</xsl:template>

<!-- The TeX-family logos have no implementation in the imported -->
<!-- stylesheets (the HTML conversion styles them with CSS), so  -->
<!-- they are plain text here.                                   -->
<xsl:template match="tex">
    <xsl:text>TeX</xsl:text>
</xsl:template>
<xsl:template match="latex">
    <xsl:text>LaTeX</xsl:text>
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

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- pretext-common.xsl implements all of "xref" processing:      -->
<!-- target identification, error checking, and generation of the -->
<!-- visible text.  It finishes in the abstract modal "xref-link" -->
<!-- template, which here passes the text through undecorated.    -->
<!-- Live internal links (fo:basic-link) require @id decorations  -->
<!-- on the rendered objects first, a refinement for later.       -->
<xsl:template match="xref">
    <xsl:apply-imports/>
</xsl:template>

<xsl:template match="*" mode="xref-link">
    <xsl:param name="target"/>
    <xsl:param name="origin"/>
    <xsl:param name="content"/>
    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- ########### -->
<!-- Mathematics -->
<!-- ########### -->

<!-- Each math element looks up its MathJax-produced SVG in the    -->
<!-- $math-repr file by its "unique-id" (the EPUB model), and the  -->
<!-- SVG embeds in the page as an fo:instream-foreign-object.      -->
<!-- MathJax sizes its SVG in "ex" units of its TeX fonts, where   -->
<!-- one "ex" is 0.442em (visible in any "viewBox", which uses     -->
<!-- thousandths of an em).  Batik, FOP's SVG engine, cannot use   -->
<!-- "ex" lengths, nor does FOP scale an SVG to a "content-width", -->
<!-- so all measurements convert to points, via the body font      -->
<!-- size, and are written directly onto the SVG element.          -->
<xsl:variable name="mathjax-em-per-ex" select="0.442"/>
<!-- $font-size is a number with "pt" attached -->
<xsl:variable name="math-points-per-ex"
              select="$mathjax-em-per-ex * number(substring-before($font-size, 'pt'))"/>

<!-- For inline math, the CSS "vertical-align" drop below the     -->
<!-- baseline (on the SVG's @style) carries over directly as the  -->
<!-- FO "alignment-adjust": FOP raises the object by the length,  -->
<!-- so the (negative) drop lowers it below the baseline, exactly -->
<!-- as in CSS (verified empirically, 2026-06-11).                -->
<xsl:template match="m|me|men|md|mdn">
    <xsl:variable name="id">
        <xsl:apply-templates select="." mode="unique-id"/>
    </xsl:variable>
    <xsl:variable name="svg" select="$math-repr/pi:math[@id = $id]/div[@class = 'svg']/svg:svg"/>
    <xsl:variable name="width-points"
                  select="number(substring-before($svg/@width, 'ex')) * $math-points-per-ex"/>
    <xsl:variable name="height-points"
                  select="number(substring-before($svg/@height, 'ex')) * $math-points-per-ex"/>
    <xsl:choose>
        <xsl:when test="$svg and self::m">
            <xsl:variable name="drop-ex">
                <xsl:choose>
                    <xsl:when test="contains($svg/@style, 'vertical-align:')">
                        <xsl:value-of select="number(substring-before(substring-after($svg/@style, 'vertical-align:'), 'ex'))"/>
                    </xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <fo:instream-foreign-object alignment-adjust="{format-number($drop-ex * $math-points-per-ex, '0.####')}pt">
                <xsl:apply-templates select="$svg" mode="svg-meld">
                    <xsl:with-param name="width-points" select="$width-points"/>
                    <xsl:with-param name="height-points" select="$height-points"/>
                </xsl:apply-templates>
            </fo:instream-foreign-object>
        </xsl:when>
        <!-- display mathematics, in a centered block; absorbed -->
        <!-- clause-ending punctuation is already in the SVG    -->
        <xsl:when test="$svg">
            <fo:block text-align="center" space-before="0.5em" space-after="0.5em">
                <fo:instream-foreign-object>
                    <xsl:apply-templates select="$svg" mode="svg-meld">
                        <xsl:with-param name="width-points" select="$width-points"/>
                        <xsl:with-param name="height-points" select="$height-points"/>
                    </xsl:apply-templates>
                </fo:instream-foreign-object>
            </fo:block>
        </xsl:when>
        <!-- absent a math representations file (a bare "-f fo" -->
        <!-- build, with no $mathfile), a placeholder           -->
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="math-placeholder"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A copy of the SVG with computed sizes: the "ex" lengths of   -->
<!-- @width, @height, and @style drop, replaced by point lengths; -->
<!-- the retained @viewBox supplies the aspect ratio.             -->
<xsl:template match="svg:svg" mode="svg-meld">
    <xsl:param name="width-points"/>
    <xsl:param name="height-points"/>
    <xsl:copy>
        <xsl:copy-of select="@*[not(name() = 'style') and not(name() = 'width') and not(name() = 'height')]"/>
        <xsl:attribute name="width">
            <xsl:value-of select="format-number($width-points, '0.####')"/>
            <xsl:text>pt</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="height">
            <xsl:value-of select="format-number($height-points, '0.####')"/>
            <xsl:text>pt</xsl:text>
        </xsl:attribute>
        <xsl:copy-of select="node()"/>
    </xsl:copy>
</xsl:template>

<!-- Placeholders: the authored LaTeX, visibly boxed, in a -->
<!-- monospace font.                                       -->
<xsl:template match="m" mode="math-placeholder">
    <fo:inline font-family="monospace" border="0.5pt solid #888888" padding="0pt 2pt">
        <xsl:value-of select="."/>
    </fo:inline>
</xsl:template>

<xsl:template match="me|men|md|mdn" mode="math-placeholder">
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
