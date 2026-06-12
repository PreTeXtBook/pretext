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
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:exsl="http://exslt.org/common"
    xmlns:pf="https://prefigure.org"
    extension-element-prefixes="exsl"
    exclude-result-prefixes="pi svg pf"
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

<!-- A second file of speech representations of the mathematics, -->
<!-- by MathJax and the Speech Rule Engine, becomes alternate    -->
<!-- text ("fox:alt-text") on each SVG image, as PDF/UA requires -->
<!-- of any figure.                                              -->
<xsl:param name="speechfile" select="''"/>
<xsl:variable name="speech-repr" select="document($speechfile)/pi:math-representations"/>

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

<!-- PDF/UA (ISO 14289) requires every font to be embedded, so    -->
<!-- each font family must name a real, available font: a generic -->
<!-- family (serif, monospace) would fall back to a base-14 PDF   -->
<!-- font, which is never embedded.  The choices are centralized  -->
<!-- here, on the way to becoming publisher-configurable.         -->
<xsl:variable name="font-family-main" select="'DejaVu Serif'"/>
<xsl:variable name="font-family-monospace" select="'DejaVu Sans Mono'"/>
<!-- for symbols absent from the main font (e.g. the tombstone) -->
<xsl:variable name="font-family-symbol" select="'DejaVu Sans'"/>

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

<!-- Deprecation warnings are universal, so issued here on the         -->
<!-- original source, before attention turns to the assembled source.  -->
<!-- The font families are Unicode-capable, and declared, fully        -->
<!-- embedded, in the  fop.xconf  configuration.                       -->
<!-- The document language (via @xml:lang) and the document title (in  -->
<!-- the XMP metadata of  fo:declarations) propagate to the PDF,       -->
<!-- where PDF/UA (ISO 14289) and WCAG require them.                   -->
<xsl:template match="/">
    <xsl:apply-templates select="$original" mode="generic-warnings"/>
    <xsl:apply-templates select="$original" mode="element-deprecation-warnings"/>
    <xsl:apply-templates select="$original" mode="parameter-deprecation-warnings"/>
    <fo:root font-family="{$font-family-main}" font-size="{$font-size}" xml:lang="{$document-language}">
        <fo:layout-master-set>
            <fo:simple-page-master master-name="page-odd"
                                   page-width="{$page-width}"
                                   page-height="{$page-height}"
                                   margin-top="1in"
                                   margin-bottom="0.6in"
                                   margin-left="{$margin-inner}"
                                   margin-right="{$margin-outer}">
                <fo:region-body margin-bottom="0.4in"/>
                <fo:region-after extent="0.4in"/>
            </fo:simple-page-master>
            <fo:simple-page-master master-name="page-even"
                                   page-width="{$page-width}"
                                   page-height="{$page-height}"
                                   margin-top="1in"
                                   margin-bottom="0.6in"
                                   margin-left="{$margin-outer}"
                                   margin-right="{$margin-inner}">
                <fo:region-body margin-bottom="0.4in"/>
                <fo:region-after extent="0.4in"/>
            </fo:simple-page-master>
            <fo:page-sequence-master master-name="pages">
                <fo:repeatable-page-master-alternatives>
                    <fo:conditional-page-master-reference master-reference="page-odd" odd-or-even="odd"/>
                    <fo:conditional-page-master-reference master-reference="page-even" odd-or-even="even"/>
                </fo:repeatable-page-master-alternatives>
            </fo:page-sequence-master>
        </fo:layout-master-set>
        <fo:declarations>
            <x:xmpmeta xmlns:x="adobe:ns:meta/">
                <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                    <rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">
                        <!-- The XMP specification requires "dc:title" to be a   -->
                        <!-- language-alternative array, never bare text, and    -->
                        <!-- PDF/UA validators check the structure (ISO 14289-1, -->
                        <!-- clause 7.1).                                        -->
                        <dc:title>
                            <rdf:Alt>
                                <rdf:li xml:lang="x-default">
                                    <xsl:variable name="document-title">
                                        <xsl:apply-templates select="$document-root" mode="title-simple"/>
                                    </xsl:variable>
                                    <xsl:value-of select="normalize-space($document-title)"/>
                                </rdf:li>
                            </rdf:Alt>
                        </dc:title>
                    </rdf:Description>
                </rdf:RDF>
            </x:xmpmeta>
        </fo:declarations>
        <fo:bookmark-tree>
            <xsl:apply-templates select="$document-root/*" mode="bookmark"/>
        </fo:bookmark-tree>
        <fo:page-sequence master-reference="pages">
            <fo:static-content flow-name="xsl-region-after">
                <fo:block text-align="center" font-size="90%">
                    <fo:page-number/>
                </fo:block>
            </fo:static-content>
            <fo:static-content flow-name="xsl-footnote-separator">
                <fo:block end-indent="70%" space-before="4pt" space-after="4pt">
                    <fo:leader leader-pattern="rule" leader-length="100%" rule-thickness="0.5pt"/>
                </fo:block>
            </fo:static-content>
            <fo:flow flow-name="xsl-region-body">
                <xsl:apply-templates select="$document-root"/>
            </fo:flow>
        </fo:page-sequence>
    </fo:root>
</xsl:template>

<!-- ############# -->
<!-- PDF Bookmarks -->
<!-- ############# -->

<!-- The bookmark tree (the PDF "outline") mirrors the division   -->
<!-- structure, each entry an internal link to its heading's @id. -->
<!-- Titles must be plain text, so the simple/plain title modes.  -->
<xsl:template match="*" mode="bookmark"/>

<!-- pure containers: recurse to the divisions inside -->
<xsl:template match="frontmatter|backmatter" mode="bookmark">
    <xsl:apply-templates select="*" mode="bookmark"/>
</xsl:template>

<xsl:template match="chapter|section|subsection|subsubsection|appendix|exercises|worksheet|reading-questions|solutions|references|glossary|preface|acknowledgement|foreword|dedication|biography|colophon|index" mode="bookmark">
    <fo:bookmark>
        <xsl:attribute name="internal-destination">
            <xsl:apply-templates select="." mode="unique-id"/>
        </xsl:attribute>
        <fo:bookmark-title>
            <xsl:variable name="the-number">
                <xsl:apply-templates select="." mode="number"/>
            </xsl:variable>
            <xsl:if test="not($the-number = '')">
                <xsl:value-of select="$the-number"/>
                <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:variable name="the-title">
                <xsl:apply-templates select="." mode="title-simple"/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($the-title)"/>
        </fo:bookmark-title>
        <xsl:apply-templates select="*" mode="bookmark"/>
    </fo:bookmark>
</xsl:template>

<!-- ###################### -->
<!-- Front and Back Matter  -->
<!-- ###################### -->

<!-- The "frontmatter" flows: the title page, an abstract, and any -->
<!-- front divisions (preface, foreword, ...) in order.  The       -->
<!-- "bibinfo" is pure metadata, consumed from the $bibinfo        -->
<!-- variable by the title page.                                   -->
<xsl:template match="frontmatter">
    <xsl:apply-templates select="*"/>
</xsl:template>

<xsl:template match="bibinfo"/>

<!-- The "titlepage-items" element is the hook requesting the  -->
<!-- default sequence: authors and editors, credits, the date. -->
<!-- (The document title itself renders at the document root.) -->
<xsl:template match="titlepage">
    <xsl:apply-templates select="titlepage-items"/>
</xsl:template>

<xsl:template match="titlepage-items">
    <xsl:apply-templates select="$bibinfo/author|$bibinfo/editor" mode="full-info"/>
    <xsl:apply-templates select="$bibinfo/credit[title]"/>
    <xsl:apply-templates select="$bibinfo/date" mode="titlepage-date"/>
</xsl:template>

<!-- One author or editor, centered: name, affiliation, -->
<!-- electronic address, support acknowledgement.       -->
<xsl:template match="author|editor" mode="full-info">
    <fo:block text-align="center" space-after="1em">
        <fo:block font-size="120%">
            <xsl:apply-templates select="personname"/>
            <xsl:if test="self::editor">
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="." mode="type-name"/>
            </xsl:if>
        </fo:block>
        <xsl:apply-templates select="affiliation"/>
        <xsl:if test="email">
            <fo:block>
                <xsl:apply-templates select="email"/>
            </fo:block>
        </xsl:if>
        <xsl:if test="support">
            <fo:block font-size="90%">
                <xsl:apply-templates select="support/node()"/>
            </fo:block>
        </xsl:if>
    </fo:block>
</xsl:template>

<xsl:template match="personname">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="affiliation">
    <xsl:apply-templates select="department|institution|location"/>
</xsl:template>

<!-- each is a line, or authored "line"s, of the address block -->
<xsl:template match="department|institution|location">
    <xsl:choose>
        <xsl:when test="line">
            <xsl:apply-templates select="line"/>
        </xsl:when>
        <xsl:otherwise>
            <fo:block>
                <xsl:apply-templates/>
            </fo:block>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A "credit" is a lesser contribution, with a title -->
<xsl:template match="bibinfo/credit[title]">
    <fo:block text-align="center" space-after="1em">
        <fo:block font-style="italic">
            <xsl:apply-templates select="." mode="title-full"/>
        </fo:block>
        <xsl:apply-templates select="author" mode="full-info"/>
    </fo:block>
</xsl:template>

<xsl:template match="bibinfo/date" mode="titlepage-date">
    <fo:block text-align="center" space-after="1em">
        <xsl:apply-templates/>
    </fo:block>
</xsl:template>

<!-- The "abstract", indented, with a run-in localized heading. -->
<xsl:template match="abstract">
    <fo:block margin-left="2.5em" margin-right="2.5em" space-before="1em" space-after="1em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:variable name="heading">
            <fo:inline font-weight="bold" font-style="normal">
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

<!-- The "backmatter" also just flows -->
<xsl:template match="backmatter">
    <xsl:apply-templates select="*"/>
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
<!-- The @role attributes here and below become PDF structure    -->
<!-- tags (H1, H2, ...) in FOP's Tagged PDF output, the heading  -->
<!-- outline PDF/UA and WCAG call for; division nesting means    -->
<!-- levels are never skipped.                                   -->
<xsl:template match="article|book">
    <fo:block font-size="200%"
              font-weight="bold"
              text-align="center"
              space-after="2em"
              role="H1">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:apply-templates select="." mode="title-full"/>
    </fo:block>
    <xsl:apply-templates/>
</xsl:template>

<!-- A heading: optional localized "type-name number", then the     -->
<!-- title.  An unnumbered division (perhaps numbering is limited   -->
<!-- by the publisher's numbering level) gets a title-only heading. -->
<!-- The specialized divisions ("exercises", "references", ...)     -->
<!-- take the very same heading; their specialized *contents* are   -->
<!-- implemented (or not, yet) elsewhere.                           -->
<xsl:template match="chapter|section|subsection|subsubsection|appendix|exercises|worksheet|reading-questions|solutions|references|glossary|preface|acknowledgement|foreword|dedication|biography|colophon|index">
    <xsl:variable name="heading-size">
        <xsl:choose>
            <xsl:when test="self::chapter">170%</xsl:when>
            <xsl:when test="self::section">140%</xsl:when>
            <xsl:when test="self::subsection">120%</xsl:when>
            <xsl:when test="self::subsubsection">100%</xsl:when>
            <!-- a specialized division sizes by its depth -->
            <xsl:otherwise>
                <xsl:variable name="depth" select="count(ancestor::*[&STRUCTURAL-FILTER;])"/>
                <xsl:choose>
                    <xsl:when test="$depth &lt;= 1">140%</xsl:when>
                    <xsl:when test="$depth = 2">120%</xsl:when>
                    <xsl:otherwise>100%</xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number"/>
    </xsl:variable>
    <fo:block font-size="{$heading-size}"
              font-weight="bold"
              space-before="1.5em"
              space-after="0.75em"
              keep-with-next.within-page="always"
              role="H{count(ancestor::*[&STRUCTURAL-FILTER;]) + 1}">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:if test="not($the-number = '')">
            <xsl:apply-templates select="." mode="type-name"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$the-number"/>
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="title-full"/>
    </fo:block>
    <xsl:choose>
        <!-- a "solutions" division is empty; its content is mined -->
        <!-- from its scope by the generator in pretext-common.xsl -->
        <xsl:when test="self::solutions">
            <xsl:apply-templates select="." mode="solutions">
                <xsl:with-param name="heading-level" select="count(ancestor::*[&STRUCTURAL-FILTER;]) + 1"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A worksheet "page" is a pagination request; its contents    -->
<!-- just flow, and real page-break control is a refinement.     -->
<xsl:template match="worksheet/page">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- An "introduction" or "conclusion" of a division is mostly a -->
<!-- transparent container, but any title runs in, bold, to the  -->
<!-- leading paragraph.                                          -->
<xsl:template match="introduction|conclusion">
    <xsl:choose>
        <xsl:when test="title">
            <fo:block space-before="1em" space-after="1em">
                <xsl:variable name="heading">
                    <fo:inline font-weight="bold" font-style="normal">
                        <xsl:apply-templates select="." mode="title-full"/>
                    </fo:inline>
                    <xsl:text> </xsl:text>
                </xsl:variable>
                <xsl:call-template name="heading-then-content">
                    <xsl:with-param name="heading" select="$heading"/>
                </xsl:call-template>
            </fo:block>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="*"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A "paragraphs" is the lightweight, unnumbered division: just -->
<!-- its title, bold, run in to the leading paragraph (exactly    -->
<!-- the LaTeX treatment).                                        -->
<xsl:template match="paragraphs">
    <fo:block space-before="1em" space-after="1em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:variable name="heading">
            <fo:inline font-weight="bold" font-style="normal">
                <xsl:apply-templates select="." mode="title-full"/>
            </fo:inline>
            <xsl:text> </xsl:text>
        </xsl:variable>
        <xsl:call-template name="heading-then-content">
            <xsl:with-param name="heading" select="$heading"/>
        </xsl:call-template>
    </fo:block>
</xsl:template>

<!-- A glossary item ("gi") reads as a description list entry:   -->
<!-- its title, bold, run in to the explanation.                 -->
<xsl:template match="gi">
    <fo:block space-after="0.5em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:variable name="heading">
            <fo:inline font-weight="bold" font-style="normal">
                <xsl:apply-templates select="." mode="title-full"/>
            </fo:inline>
            <xsl:text> </xsl:text>
        </xsl:variable>
        <xsl:call-template name="heading-then-content">
            <xsl:with-param name="heading" select="$heading"/>
        </xsl:call-template>
    </fo:block>
</xsl:template>

<!-- A "title" is consumed by modal templates reached from the     -->
<!-- parent element, and is never traversed as content, so it is   -->
<!-- killed in the default mode.  Likewise the other metadata:     -->
<!-- "idx" (index entries), "notation", and image descriptions all -->
<!-- render elsewhere (or not yet), never as in-place content.     -->
<xsl:template match="title|subtitle|shorttitle|caption|idx|notation|shortdescription|description"/>

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
<!-- An "exercise" matching here is the *inline* flavor; a       -->
<!-- divisional one matches a more specific pattern in the       -->
<!-- "Exercises" section.  PROJECT-LIKE blocks may also be       -->
<!-- structured by "task", arriving among the contents.          -->
<xsl:template match="&REMARK-LIKE;|&THEOREM-LIKE;|&EXAMPLE-LIKE;|&DEFINITION-LIKE;|&AXIOM-LIKE;|&OPENPROBLEM-LIKE;|&COMPUTATION-LIKE;|&ASIDE-LIKE;|assemblage|objectives|outcomes">
    <fo:block space-before="1em" space-after="1em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
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
        <xsl:apply-templates select="." mode="link-id-attribute"/>
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
            <!-- the main (serif) font lacks END OF PROOF, the symbol font has it -->
            <fo:inline font-family="{$font-family-symbol}">
                <xsl:text>&#x220e;</xsl:text>
            </fo:inline>
        </fo:block>
    </fo:block>
</xsl:template>

<!-- A "case" of a proof: an italic run-in heading built from the -->
<!-- direction arrow and/or the title (an untitled, undirected    -->
<!-- case earns the default title, "Case."), as in the HTML       -->
<!-- conversion.                                                  -->
<xsl:template match="case">
    <fo:block space-before="0.75em" space-after="0.5em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:variable name="heading">
            <fo:inline font-style="italic">
                <xsl:apply-templates select="." mode="case-direction"/>
                <xsl:if test="boolean(title) or not(@direction)">
                    <xsl:apply-templates select="." mode="title-full"/>
                </xsl:if>
            </fo:inline>
            <xsl:text> </xsl:text>
        </xsl:variable>
        <xsl:call-template name="heading-then-content">
            <xsl:with-param name="heading" select="$heading"/>
        </xsl:call-template>
    </fo:block>
</xsl:template>

<!-- The implication arrows of a "case" direction, and the spacing -->
<!-- inside a "cycle" decoration, expected by pretext-common.xsl.  -->
<xsl:template name="double-right-arrow-symbol">
    <!-- RIGHTWARDS DOUBLE ARROW -->
    <xsl:text>&#x21d2;</xsl:text>
</xsl:template>
<xsl:template name="double-left-arrow-symbol">
    <!-- LEFTWARDS DOUBLE ARROW -->
    <xsl:text>&#x21d0;</xsl:text>
</xsl:template>
<xsl:template name="case-cycle-delimiter-space">
    <!-- THIN SPACE -->
    <xsl:text>&#x2009;</xsl:text>
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

<!-- ######### -->
<!-- Exercises -->
<!-- ######### -->

<!-- All the EXERCISE-LIKE and PROJECT-LIKE render through the     -->
<!-- "exercise-components" machinery below, honoring the publisher -->
<!-- file's visibility switches for the matching collection (e.g.  -->
<!-- divisional hints in the main text).  Headings: an *inline*    -->
<!-- exercise ("Checkpoint") or project carries full type-name and -->
<!-- number; a *divisional* one (in an "exercises" division, a     -->
<!-- "worksheet", or "reading-questions") a compact serial number. -->
<xsl:template match="exercise|&PROJECT-LIKE;">
    <fo:block space-before="1em" space-after="1em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:variable name="heading">
            <fo:inline font-weight="bold" font-style="normal">
                <xsl:choose>
                    <xsl:when test="self::exercise and (ancestor::exercises or ancestor::worksheet or ancestor::reading-questions)">
                        <xsl:apply-templates select="." mode="serial-number"/>
                        <xsl:text>.</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="." mode="block-heading-text"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="title">
                    <xsl:text> </xsl:text>
                    <xsl:apply-templates select="." mode="title-full"/>
                </xsl:if>
            </fo:inline>
            <xsl:text> </xsl:text>
        </xsl:variable>
        <xsl:apply-templates select="." mode="exercise-components">
            <xsl:with-param name="b-has-statement" select="true()"/>
            <xsl:with-param name="b-has-hint">
                <xsl:apply-templates select="." mode="b-main-text-component">
                    <xsl:with-param name="component" select="'hint'"/>
                </xsl:apply-templates>
            </xsl:with-param>
            <xsl:with-param name="b-has-answer">
                <xsl:apply-templates select="." mode="b-main-text-component">
                    <xsl:with-param name="component" select="'answer'"/>
                </xsl:apply-templates>
            </xsl:with-param>
            <xsl:with-param name="b-has-solution">
                <xsl:apply-templates select="." mode="b-main-text-component">
                    <xsl:with-param name="component" select="'solution'"/>
                </xsl:apply-templates>
            </xsl:with-param>
            <xsl:with-param name="run-in-heading" select="$heading"/>
        </xsl:apply-templates>
    </fo:block>
</xsl:template>

<!-- A "task" reached in document order (e.g. structuring an     -->
<!-- EXAMPLE-LIKE): its label and all its components.            -->
<xsl:template match="task">
    <fo:block space-before="0.75em" space-after="0.75em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:variable name="heading">
            <fo:inline font-weight="bold" font-style="normal">
                <xsl:text>(</xsl:text>
                <xsl:apply-templates select="." mode="list-number"/>
                <xsl:text>)</xsl:text>
                <xsl:if test="title">
                    <xsl:text> </xsl:text>
                    <xsl:apply-templates select="." mode="title-full"/>
                </xsl:if>
            </fo:inline>
            <xsl:text> </xsl:text>
        </xsl:variable>
        <xsl:apply-templates select="." mode="exercise-components">
            <xsl:with-param name="run-in-heading" select="$heading"/>
        </xsl:apply-templates>
    </fo:block>
</xsl:template>

<!-- the type-name and number of a block heading, sans title -->
<xsl:template match="*" mode="block-heading-text">
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number"/>
    </xsl:variable>
    <xsl:if test="not($the-number = '')">
        <xsl:text> </xsl:text>
        <xsl:value-of select="$the-number"/>
    </xsl:if>
    <xsl:text>.</xsl:text>
</xsl:template>

<!-- The publisher's main-text visibility switch for one component -->
<!-- of this exercise, by the collection it sits in.  (XSLT 1.0    -->
<!-- carries the boolean home as the string "true" or "false".)    -->
<xsl:template match="*" mode="b-main-text-component">
    <xsl:param name="component"/>
    <xsl:choose>
        <xsl:when test="self::exercise and ancestor::exercises">
            <xsl:choose>
                <xsl:when test="$component = 'hint'">
                    <xsl:value-of select="$b-has-divisional-hint"/>
                </xsl:when>
                <xsl:when test="$component = 'answer'">
                    <xsl:value-of select="$b-has-divisional-answer"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$b-has-divisional-solution"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="self::exercise and ancestor::worksheet">
            <xsl:choose>
                <xsl:when test="$component = 'hint'">
                    <xsl:value-of select="$b-has-worksheet-hint"/>
                </xsl:when>
                <xsl:when test="$component = 'answer'">
                    <xsl:value-of select="$b-has-worksheet-answer"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$b-has-worksheet-solution"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="self::exercise and ancestor::reading-questions">
            <xsl:choose>
                <xsl:when test="$component = 'hint'">
                    <xsl:value-of select="$b-has-reading-hint"/>
                </xsl:when>
                <xsl:when test="$component = 'answer'">
                    <xsl:value-of select="$b-has-reading-answer"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$b-has-reading-solution"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="self::exercise">
            <xsl:choose>
                <xsl:when test="$component = 'hint'">
                    <xsl:value-of select="$b-has-inline-hint"/>
                </xsl:when>
                <xsl:when test="$component = 'answer'">
                    <xsl:value-of select="$b-has-inline-answer"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$b-has-inline-solution"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- PROJECT-LIKE -->
        <xsl:otherwise>
            <xsl:choose>
                <xsl:when test="$component = 'hint'">
                    <xsl:value-of select="$b-has-project-hint"/>
                </xsl:when>
                <xsl:when test="$component = 'answer'">
                    <xsl:value-of select="$b-has-project-answer"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$b-has-project-solution"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A "prelude", "interlude", or "postlude" decorates a project -->
<!-- or listing with surrounding prose; the contents just flow.  -->
<xsl:template match="prelude|interlude|postlude">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- A "subexercises" groups exercises under an interior heading. -->
<xsl:template match="subexercises">
    <xsl:if test="title">
        <fo:block font-weight="bold"
                  space-before="1em"
                  space-after="0.5em"
                  keep-with-next.within-page="always">
            <xsl:apply-templates select="." mode="title-full"/>
        </fo:block>
    </xsl:if>
    <xsl:apply-templates select="*[not(self::title)]"/>
</xsl:template>

<!-- An "exercisegroup" supplies common context for consecutive -->
<!-- exercises; numbering just continues through it.  The @cols -->
<!-- layout request is a refinement for later.                  -->
<xsl:template match="exercisegroup">
    <xsl:apply-templates select="introduction"/>
    <xsl:apply-templates select="exercise"/>
    <xsl:apply-templates select="conclusion"/>
</xsl:template>

<!-- Components of an Exercise  -->
<!-- ########################## -->

<!-- The components of EXERCISE-LIKE and PROJECT-LIKE: a statement -->
<!-- and SOLUTION-LIKE appendages, each rendered only when the     -->
<!-- collection at hand wants it (the $b-has-* parameters: the     -->
<!-- publisher's main-text switches, or the configuration of a     -->
<!-- "solutions" division).  The "run-in-heading" travels into a   -->
<!-- displayed statement, exactly as in "heading-then-content".    -->

<!-- structured by "task": optional introduction and conclusion -->
<!-- sandwich the tasks, each with its label and own components -->
<xsl:template match="exercise[task]|project[task]|activity[task]|exploration[task]|investigation[task]|task[task]" mode="exercise-components">
    <xsl:param name="b-original" select="true()"/>
    <xsl:param name="b-has-statement" select="true()"/>
    <xsl:param name="b-has-hint" select="true()"/>
    <xsl:param name="b-has-answer" select="true()"/>
    <xsl:param name="b-has-solution" select="true()"/>
    <xsl:param name="run-in-heading"/>
    <xsl:if test="$b-has-statement">
        <xsl:apply-templates select="introduction">
            <xsl:with-param name="run-in-heading" select="$run-in-heading"/>
        </xsl:apply-templates>
    </xsl:if>
    <xsl:for-each select="task">
        <xsl:variable name="dry-run">
            <xsl:apply-templates select="." mode="dry-run">
                <xsl:with-param name="b-has-statement" select="$b-has-statement"/>
                <xsl:with-param name="b-has-hint" select="$b-has-hint"/>
                <xsl:with-param name="b-has-answer" select="$b-has-answer"/>
                <xsl:with-param name="b-has-solution" select="$b-has-solution"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:if test="not($dry-run = '')">
            <fo:block space-before="0.75em" space-after="0.75em">
                <!-- a duplicate (in a solutions division) cannot -->
                <!-- reuse the @id of the original                -->
                <xsl:if test="$b-original">
                    <xsl:apply-templates select="." mode="link-id-attribute"/>
                </xsl:if>
                <xsl:variable name="heading">
                    <fo:inline font-weight="bold" font-style="normal">
                        <xsl:text>(</xsl:text>
                        <xsl:apply-templates select="." mode="list-number"/>
                        <xsl:text>)</xsl:text>
                        <xsl:if test="title">
                            <xsl:text> </xsl:text>
                            <xsl:apply-templates select="." mode="title-full"/>
                        </xsl:if>
                    </fo:inline>
                    <xsl:text> </xsl:text>
                </xsl:variable>
                <xsl:apply-templates select="." mode="exercise-components">
                    <xsl:with-param name="b-original" select="$b-original"/>
                    <xsl:with-param name="b-has-statement" select="$b-has-statement"/>
                    <xsl:with-param name="b-has-hint" select="$b-has-hint"/>
                    <xsl:with-param name="b-has-answer" select="$b-has-answer"/>
                    <xsl:with-param name="b-has-solution" select="$b-has-solution"/>
                    <xsl:with-param name="run-in-heading" select="$heading"/>
                </xsl:apply-templates>
            </fo:block>
        </xsl:if>
    </xsl:for-each>
    <xsl:if test="$b-has-statement">
        <xsl:apply-templates select="conclusion"/>
    </xsl:if>
</xsl:template>

<!-- the leaf form: a statement, then chosen appendages -->
<xsl:template match="exercise|&PROJECT-LIKE;|task[not(task)]" mode="exercise-components">
    <xsl:param name="b-original" select="true()"/>
    <xsl:param name="b-has-statement" select="true()"/>
    <xsl:param name="b-has-hint" select="true()"/>
    <xsl:param name="b-has-answer" select="true()"/>
    <xsl:param name="b-has-solution" select="true()"/>
    <xsl:param name="run-in-heading"/>
    <xsl:choose>
        <xsl:when test="statement">
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="statement">
                    <xsl:with-param name="run-in-heading" select="$run-in-heading"/>
                </xsl:apply-templates>
                <!-- a coding exercise's program rides with the statement -->
                <xsl:apply-templates select="program"/>
            </xsl:if>
            <!-- a heading with no statement to carry it stands alone -->
            <xsl:if test="not($b-has-statement)">
                <fo:block keep-with-next.within-page="always">
                    <xsl:copy-of select="$run-in-heading"/>
                </fo:block>
            </xsl:if>
            <xsl:if test="$b-has-hint">
                <xsl:apply-templates select="hint"/>
            </xsl:if>
            <xsl:if test="$b-has-answer">
                <xsl:apply-templates select="answer"/>
            </xsl:if>
            <xsl:if test="$b-has-solution">
                <xsl:apply-templates select="solution"/>
            </xsl:if>
        </xsl:when>
        <!-- unstructured, a bare statement -->
        <xsl:otherwise>
            <xsl:if test="$b-has-statement">
                <xsl:call-template name="heading-then-content">
                    <xsl:with-param name="heading" select="$run-in-heading"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################### -->
<!-- Solutions Divisions -->
<!-- ################### -->

<!-- A "solutions" division has no children of its own: the       -->
<!-- solutions-generator of pretext-common.xsl mines content from -->
<!-- the scoped divisions and calls back to the modal templates   -->
<!-- here.  A division visited along the way repeats its heading; -->
<!-- the generator supplies a stack of divisions needing mention. -->
<xsl:template match="*" mode="duplicate-heading">
    <xsl:param name="heading-stack" select="."/>
    <fo:block font-weight="bold"
              font-size="120%"
              space-before="1.5em"
              space-after="0.75em"
              keep-with-next.within-page="always">
        <xsl:for-each select="$heading-stack">
            <xsl:if test="position() &gt; 1">
                <xsl:text>, </xsl:text>
            </xsl:if>
            <xsl:apply-templates select="." mode="type-name"/>
            <xsl:variable name="the-number">
                <xsl:apply-templates select="." mode="number"/>
            </xsl:variable>
            <xsl:if test="not($the-number = '')">
                <xsl:text> </xsl:text>
                <xsl:value-of select="$the-number"/>
            </xsl:if>
            <xsl:variable name="the-title">
                <xsl:apply-templates select="." mode="title-simple"/>
            </xsl:variable>
            <xsl:if test="not(normalize-space($the-title) = '')">
                <xsl:text> </xsl:text>
                <xsl:value-of select="normalize-space($the-title)"/>
            </xsl:if>
        </xsl:for-each>
    </fo:block>
</xsl:template>

<!-- One exercise (or project) in a solutions collection: gated -->
<!-- by a dry run, since the switches may yield nothing; then a -->
<!-- run-in heading and the chosen components.                  -->
<xsl:template match="exercise[boolean(&INLINE-EXERCISE-FILTER;)]|&PROJECT-LIKE;|exercises//exercise|worksheet//exercise|reading-questions//exercise" mode="solutions">
    <xsl:param name="purpose"/>
    <xsl:param name="admit"/>
    <xsl:param name="b-component-heading"/>
    <xsl:param name="heading-level"/>
    <xsl:param name="b-has-statement"/>
    <xsl:param name="b-has-hint"/>
    <xsl:param name="b-has-answer"/>
    <xsl:param name="b-has-solution"/>
    <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement"/>
            <xsl:with-param name="b-has-hint" select="$b-has-hint"/>
            <xsl:with-param name="b-has-answer" select="$b-has-answer"/>
            <xsl:with-param name="b-has-solution" select="$b-has-solution"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="not($dry-run = '')">
        <fo:block space-before="1em" space-after="1em">
            <xsl:variable name="heading">
                <fo:inline font-weight="bold" font-style="normal">
                    <xsl:choose>
                        <!-- divisional flavors: just the serial number -->
                        <xsl:when test="self::exercise and (ancestor::exercises or ancestor::worksheet or ancestor::reading-questions)">
                            <xsl:apply-templates select="." mode="serial-number"/>
                            <xsl:text>.</xsl:text>
                        </xsl:when>
                        <!-- inline exercises and projects carry full identification -->
                        <xsl:otherwise>
                            <xsl:apply-templates select="." mode="type-name"/>
                            <xsl:text> </xsl:text>
                            <xsl:apply-templates select="." mode="number"/>
                            <xsl:text>.</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="title">
                        <xsl:text> </xsl:text>
                        <xsl:apply-templates select="." mode="title-full"/>
                    </xsl:if>
                </fo:inline>
                <xsl:text> </xsl:text>
            </xsl:variable>
            <!-- The duplicate's interior may contain objects (a    -->
            <!-- "proof" in a "solution", display mathematics) that -->
            <!-- emit the same @id as their original rendering, and -->
            <!-- duplicated @ids are fatal to FOP.  So the content  -->
            <!-- is built as a fragment, then copied with every @id -->
            <!-- stripped; interior cross-references still target   -->
            <!-- the originals.                                     -->
            <xsl:variable name="duplicate-content">
                <xsl:apply-templates select="." mode="exercise-components">
                    <xsl:with-param name="b-original" select="false()"/>
                    <xsl:with-param name="b-has-statement" select="$b-has-statement"/>
                    <xsl:with-param name="b-has-hint" select="$b-has-hint"/>
                    <xsl:with-param name="b-has-answer" select="$b-has-answer"/>
                    <xsl:with-param name="b-has-solution" select="$b-has-solution"/>
                    <xsl:with-param name="run-in-heading" select="$heading"/>
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:apply-templates select="exsl:node-set($duplicate-content)" mode="strip-id-attributes"/>
        </fo:block>
    </xsl:if>
</xsl:template>

<!-- the identity copy, with @id attributes withheld -->
<xsl:template match="node()|@*" mode="strip-id-attributes">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="strip-id-attributes"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="@id" mode="strip-id-attributes"/>

<!-- the wrappers pass everything through, with their prose -->
<!-- gated on statements being shown                        -->
<xsl:template match="exercisegroup" mode="solutions">
    <xsl:param name="purpose"/>
    <xsl:param name="admit"/>
    <xsl:param name="b-component-heading"/>
    <xsl:param name="heading-level"/>
    <xsl:param name="b-has-statement"/>
    <xsl:param name="b-has-hint"/>
    <xsl:param name="b-has-answer"/>
    <xsl:param name="b-has-solution"/>
    <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement"/>
            <xsl:with-param name="b-has-hint" select="$b-has-hint"/>
            <xsl:with-param name="b-has-answer" select="$b-has-answer"/>
            <xsl:with-param name="b-has-solution" select="$b-has-solution"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="not($dry-run = '')">
        <xsl:if test="$b-has-statement">
            <xsl:apply-templates select="introduction"/>
        </xsl:if>
        <xsl:apply-templates select="exercise" mode="solutions">
            <xsl:with-param name="purpose" select="$purpose"/>
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
            <xsl:with-param name="heading-level" select="$heading-level"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement"/>
            <xsl:with-param name="b-has-hint" select="$b-has-hint"/>
            <xsl:with-param name="b-has-answer" select="$b-has-answer"/>
            <xsl:with-param name="b-has-solution" select="$b-has-solution"/>
        </xsl:apply-templates>
        <xsl:if test="$b-has-statement">
            <xsl:apply-templates select="conclusion"/>
        </xsl:if>
    </xsl:if>
</xsl:template>

<xsl:template match="subexercises" mode="solutions">
    <xsl:param name="purpose"/>
    <xsl:param name="admit"/>
    <xsl:param name="b-component-heading"/>
    <xsl:param name="heading-level"/>
    <xsl:param name="b-has-statement"/>
    <xsl:param name="b-has-hint"/>
    <xsl:param name="b-has-answer"/>
    <xsl:param name="b-has-solution"/>
    <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement"/>
            <xsl:with-param name="b-has-hint" select="$b-has-hint"/>
            <xsl:with-param name="b-has-answer" select="$b-has-answer"/>
            <xsl:with-param name="b-has-solution" select="$b-has-solution"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="not($dry-run = '')">
        <xsl:if test="title">
            <fo:block font-weight="bold"
                      space-before="1em"
                      space-after="0.5em"
                      keep-with-next.within-page="always">
                <xsl:apply-templates select="." mode="title-full"/>
            </fo:block>
        </xsl:if>
        <xsl:if test="$b-has-statement">
            <xsl:apply-templates select="introduction"/>
        </xsl:if>
        <xsl:apply-templates select="exercise|exercisegroup" mode="solutions">
            <xsl:with-param name="purpose" select="$purpose"/>
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
            <xsl:with-param name="heading-level" select="$heading-level"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement"/>
            <xsl:with-param name="b-has-hint" select="$b-has-hint"/>
            <xsl:with-param name="b-has-answer" select="$b-has-answer"/>
            <xsl:with-param name="b-has-solution" select="$b-has-solution"/>
        </xsl:apply-templates>
        <xsl:if test="$b-has-statement">
            <xsl:apply-templates select="conclusion"/>
        </xsl:if>
    </xsl:if>
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

<!-- An image is a centered block, with the authored @width      -->
<!-- percentage (or the documented defaults) honored by the      -->
<!-- common machinery, which makes an image fill its panel when  -->
<!-- inside a "sidebyside".  The percentage width of the graphic -->
<!-- is relative to the available width, and the image scales to -->
<!-- it, preserving the aspect ratio.  Restricted to externally  -->
<!-- provided and pre-generated images; the harness reports the  -->
<!-- born-in-source kinds (e.g. "latex-image"), which need       -->
<!-- companion image-generation components.  N.B. an SVG file    -->
<!-- must carry its intrinsic @width and @height: with only a    -->
<!-- @viewBox, FOP assumes a square, and the drawing floats in   -->
<!-- extra vertical space.                                       -->
<xsl:template match="image[@source|@pi:generated]|image[latex-image]|image[sageplot]|image[asymptote]|image[pf:prefigure]|image[mermaid]">
    <xsl:variable name="width">
        <xsl:apply-templates select="." mode="get-width-percentage"/>
    </xsl:variable>
    <fo:block text-align="center" space-before="0.5em" space-after="0.5em">
        <fo:external-graphic width="{$width}"
                             content-width="scale-to-fit"
                             scaling="uniform">
            <xsl:choose>
                <!-- a decorative image wants to be a PDF "artifact", -->
                <!-- invisible to assistive technology; FOP has no    -->
                <!-- mechanism yet, so it gets empty alternate text   -->
                <xsl:when test="@decorative = 'yes'">
                    <xsl:attribute name="fox:alt-text"/>
                </xsl:when>
                <!-- authored alternate text, as PDF/UA requires of -->
                <!-- any figure; absent it, FOP will complain       -->
                <xsl:when test="shortdescription">
                    <xsl:attribute name="fox:alt-text">
                        <xsl:value-of select="normalize-space(shortdescription)"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
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

<!-- Born-in-source images live in kind-specific subdirectories  -->
<!-- of the generated directory, with filenames decided by the   -->
<!-- "image-source-basename" machinery, as manufactured SVG;     -->
<!-- companion generation components produce the files.  (A 3-D  -->
<!-- "sageplot" has no useful print representation yet.)         -->
<xsl:template match="image[latex-image]|image[sageplot]|image[asymptote]|image[pf:prefigure]|image[mermaid]" mode="image-filename">
    <xsl:value-of select="$generated-directory"/>
    <xsl:if test="$b-managed-directories">
        <xsl:choose>
            <xsl:when test="latex-image">
                <xsl:text>latex-image/</xsl:text>
            </xsl:when>
            <xsl:when test="sageplot">
                <xsl:text>sageplot/</xsl:text>
            </xsl:when>
            <xsl:when test="asymptote">
                <xsl:text>asymptote/</xsl:text>
            </xsl:when>
            <xsl:when test="pf:prefigure">
                <xsl:text>prefigure/</xsl:text>
            </xsl:when>
            <xsl:when test="mermaid">
                <xsl:text>mermaid/</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:if>
    <xsl:apply-templates select="latex-image|sageplot|asymptote|pf:prefigure|mermaid" mode="image-source-basename"/>
    <xsl:text>.svg</xsl:text>
</xsl:template>

<!-- ###### -->
<!-- Tables -->
<!-- ###### -->

<!-- A PreTeXt "tabular" is an fo:table.  FOP only implements the -->
<!-- fixed table layout, so the table spans the available width   -->
<!-- and authored "col" percentage widths become proportional     -->
<!-- column widths (a natural-width, centered table awaits a      -->
<!-- smarter layout).  Header rows land in an fo:table-header,    -->
<!-- which FOP tags as "TH" cells in the PDF structure tree, as   -->
<!-- PDF/UA requires.  Not yet implemented: @header='vertical',   -->
<!-- @row-headers (column-of-row-headers), and a @colspan in the  -->
<!-- first row of a column-less tabular.                          -->
<xsl:template match="tabular">
    <fo:table table-layout="fixed" width="100%">
        <xsl:call-template name="rule-attribute">
            <xsl:with-param name="side" select="'top'"/>
            <xsl:with-param name="thickness" select="@top"/>
        </xsl:call-template>
        <xsl:call-template name="rule-attribute">
            <xsl:with-param name="side" select="'bottom'"/>
            <xsl:with-param name="thickness" select="@bottom"/>
        </xsl:call-template>
        <xsl:call-template name="rule-attribute">
            <xsl:with-param name="side" select="'left'"/>
            <xsl:with-param name="thickness" select="@left"/>
        </xsl:call-template>
        <xsl:call-template name="rule-attribute">
            <xsl:with-param name="side" select="'right'"/>
            <xsl:with-param name="thickness" select="@right"/>
        </xsl:call-template>
        <xsl:choose>
            <xsl:when test="col">
                <xsl:apply-templates select="col"/>
            </xsl:when>
            <!-- no authored columns: equal widths, as many as the -->
            <!-- widest row, with any @colspan unrolled            -->
            <xsl:otherwise>
                <xsl:variable name="column-count">
                    <xsl:for-each select="row">
                        <xsl:sort select="count(cell[not(@colspan)]) + sum(cell/@colspan)" data-type="number" order="descending"/>
                        <xsl:if test="position() = 1">
                            <xsl:value-of select="count(cell[not(@colspan)]) + sum(cell/@colspan)"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:call-template name="equal-table-columns">
                    <xsl:with-param name="remaining" select="$column-count"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="row[@header = 'yes']">
            <fo:table-header>
                <xsl:apply-templates select="row[@header = 'yes']"/>
            </fo:table-header>
        </xsl:if>
        <fo:table-body>
            <xsl:apply-templates select="row[not(@header = 'yes')]"/>
        </fo:table-body>
    </fo:table>
</xsl:template>

<xsl:template name="equal-table-columns">
    <xsl:param name="remaining"/>
    <xsl:if test="$remaining &gt; 0">
        <fo:table-column column-width="proportional-column-width(1)"/>
        <xsl:call-template name="equal-table-columns">
            <xsl:with-param name="remaining" select="$remaining - 1"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<xsl:template match="tabular/col">
    <fo:table-column>
        <xsl:attribute name="column-width">
            <xsl:text>proportional-column-width(</xsl:text>
            <xsl:choose>
                <xsl:when test="@width">
                    <xsl:value-of select="substring-before(@width, '%')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>1</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>)</xsl:text>
        </xsl:attribute>
    </fo:table-column>
</xsl:template>

<xsl:template match="tabular/row">
    <fo:table-row>
        <xsl:apply-templates select="cell"/>
    </fo:table-row>
</xsl:template>

<!-- A header row is bold, a visual echo of its structural role. -->
<xsl:template match="row/cell">
    <fo:table-cell padding="2pt">
        <xsl:if test="@colspan">
            <xsl:attribute name="number-columns-spanned">
                <xsl:value-of select="@colspan"/>
            </xsl:attribute>
        </xsl:if>
        <!-- vertical alignment: row, else tabular, else the top -->
        <xsl:attribute name="display-align">
            <xsl:choose>
                <xsl:when test="parent::row/@valign = 'middle' or (not(parent::row/@valign) and ancestor::tabular/@valign = 'middle')">
                    <xsl:text>center</xsl:text>
                </xsl:when>
                <xsl:when test="parent::row/@valign = 'bottom' or (not(parent::row/@valign) and ancestor::tabular/@valign = 'bottom')">
                    <xsl:text>after</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>before</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:call-template name="rule-attribute">
            <xsl:with-param name="side" select="'bottom'"/>
            <xsl:with-param name="thickness">
                <xsl:choose>
                    <xsl:when test="@bottom">
                        <xsl:value-of select="@bottom"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="parent::row/@bottom"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="rule-attribute">
            <xsl:with-param name="side" select="'right'"/>
            <xsl:with-param name="thickness">
                <xsl:choose>
                    <xsl:when test="@right">
                        <xsl:value-of select="@right"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="the-position" select="count(preceding-sibling::cell[not(@colspan)]) + sum(preceding-sibling::cell/@colspan) + 1"/>
                        <xsl:value-of select="ancestor::tabular/col[position() = $the-position]/@right"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
        <fo:block>
            <xsl:attribute name="text-align">
                <xsl:apply-templates select="." mode="cell-halign"/>
            </xsl:attribute>
            <xsl:if test="parent::row/@header = 'yes'">
                <xsl:attribute name="font-weight">
                    <xsl:text>bold</xsl:text>
                </xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <!-- structured: paragraphs or lines as blocks -->
                <xsl:when test="p|line">
                    <xsl:apply-templates select="*"/>
                </xsl:when>
                <!-- mixed content, right here -->
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </fo:block>
    </fo:table-cell>
</xsl:template>

<!-- Horizontal alignment: the cell, else its row, else its -->
<!-- column, else the tabular, else flush left.  ("justify" -->
<!-- passes through with the same meaning in XSL-FO.)       -->
<xsl:template match="row/cell" mode="cell-halign">
    <xsl:variable name="the-position" select="count(preceding-sibling::cell[not(@colspan)]) + sum(preceding-sibling::cell/@colspan) + 1"/>
    <xsl:choose>
        <xsl:when test="@halign">
            <xsl:value-of select="@halign"/>
        </xsl:when>
        <xsl:when test="parent::row/@halign">
            <xsl:value-of select="parent::row/@halign"/>
        </xsl:when>
        <xsl:when test="ancestor::tabular/col[position() = $the-position]/@halign">
            <xsl:value-of select="ancestor::tabular/col[position() = $the-position]/@halign"/>
        </xsl:when>
        <xsl:when test="ancestor::tabular/@halign">
            <xsl:value-of select="ancestor::tabular/@halign"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>left</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- The schema's rule thicknesses, emitted as a border on the -->
<!-- given side; "none", or no specification, means no border. -->
<xsl:template name="rule-attribute">
    <xsl:param name="side"/>
    <xsl:param name="thickness"/>
    <xsl:variable name="width">
        <xsl:choose>
            <xsl:when test="$thickness = 'minor'">
                <xsl:text>0.5pt</xsl:text>
            </xsl:when>
            <xsl:when test="$thickness = 'medium'">
                <xsl:text>1pt</xsl:text>
            </xsl:when>
            <xsl:when test="$thickness = 'major'">
                <xsl:text>2pt</xsl:text>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="not($width = '')">
        <xsl:attribute name="border-{$side}">
            <xsl:text>solid </xsl:text>
            <xsl:value-of select="$width"/>
            <xsl:text> #000000</xsl:text>
        </xsl:attribute>
    </xsl:if>
</xsl:template>

<!-- A "line" is one line of several, in a cell, an address, an   -->
<!-- attribution: its own block, alignment from the surroundings. -->
<xsl:template match="line">
    <fo:block>
        <xsl:apply-templates/>
    </fo:block>
</xsl:template>

<!-- ############ -->
<!-- Bibliography -->
<!-- ############ -->

<!-- pretext-common.xsl implements "biblio" entries (raw, BibTeX,  -->
<!-- and CSL flavors) and the typography of their fields, via the  -->
<!-- abstract font modes implemented in "Inline Markup".  Here:    -->
<!-- the entry wrapper, a hanging "[N]" label, and the unshadowing -->
<!-- of the imported templates.  (A field common does not style    -->
<!-- falls through apply-imports to the built-in rules, i.e. its   -->
<!-- text, which is right for raw mixed content.)                  -->
<xsl:template match="biblio|biblio/*">
    <xsl:apply-imports/>
</xsl:template>

<!-- pretext-common.xsl kills "author" and "editor" globally, as -->
<!-- metadata, and styles them only in a BibTeX-flavored entry;  -->
<!-- in a raw entry they are authored display text, passing      -->
<!-- through (and so shadowing the kill reached by the           -->
<!-- apply-imports above).                                       -->
<xsl:template match="biblio[@type = 'raw']/author|biblio[@type = 'raw']/editor">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="biblio" mode="bibentry-wrapper">
    <xsl:param name="content"/>
    <fo:list-block provisional-distance-between-starts="2.5em"
                   provisional-label-separation="0.5em"
                   space-after="0.5em">
        <fo:list-item>
            <fo:list-item-label end-indent="label-end()">
                <fo:block text-align="end">
                    <xsl:apply-templates select="." mode="link-id-attribute"/>
                    <xsl:text>[</xsl:text>
                    <xsl:apply-templates select="." mode="serial-number"/>
                    <xsl:text>]</xsl:text>
                </fo:block>
            </fo:list-item-label>
            <fo:list-item-body start-indent="body-start()">
                <fo:block text-align="justify">
                    <xsl:copy-of select="$content"/>
                </fo:block>
            </fo:list-item-body>
        </fo:list-item>
    </fo:list-block>
</xsl:template>

<!-- the period finishing a structured entry -->
<xsl:template name="biblio-period">
    <xsl:text>.</xsl:text>
</xsl:template>

<!-- ###### -->
<!-- Units  -->
<!-- ###### -->

<!-- A "quantity" is a magnitude and/or units, in the manner of   -->
<!-- the LaTeX "siunitx" package: prefixes and bases become their -->
<!-- abbreviations (the lookup tables of pretext-units.xsl), with -->
<!-- superscript exponents, and a solidus before "per" units.     -->
<xsl:key name="prefix-key" match="prefix" use="concat(../@name, @full)"/>
<xsl:key name="base-key" match="base" use="concat(../@name, @full)"/>

<xsl:template match="quantity">
    <xsl:apply-templates select="mag"/>
    <xsl:if test="mag and (unit or per)">
        <!-- a thin space, as siunitx -->
        <xsl:text>&#x2009;</xsl:text>
    </xsl:if>
    <xsl:if test="not(unit) and per">
        <xsl:text>1</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="unit"/>
    <xsl:if test="per">
        <xsl:text>/</xsl:text>
        <xsl:apply-templates select="per"/>
    </xsl:if>
</xsl:template>

<!-- magnitudes are typically numbers; authored LaTeX macros -->
<!-- (e.g. "\pi") will await the math machinery              -->
<xsl:template match="quantity/mag">
    <xsl:value-of select="."/>
</xsl:template>

<xsl:template match="quantity/unit|quantity/per">
    <!-- multiple units separated by a thin space -->
    <xsl:if test="(self::unit and preceding-sibling::unit) or (self::per and preceding-sibling::per)">
        <xsl:text>&#x2009;</xsl:text>
    </xsl:if>
    <xsl:variable name="the-prefix" select="@prefix"/>
    <xsl:if test="@prefix">
        <xsl:for-each select="document('pretext-units.xsl')">
            <xsl:value-of select="key('prefix-key', concat('prefixes', $the-prefix))/@short"/>
        </xsl:for-each>
    </xsl:if>
    <xsl:variable name="the-base" select="@base"/>
    <xsl:for-each select="document('pretext-units.xsl')">
        <xsl:value-of select="key('base-key', concat('bases', $the-base))/@short"/>
    </xsl:for-each>
    <xsl:if test="@exp">
        <fo:inline baseline-shift="super" font-size="70%">
            <xsl:value-of select="@exp"/>
        </fo:inline>
    </xsl:if>
</xsl:template>

<!-- ################ -->
<!-- Quoted and Lined -->
<!-- ################ -->

<!-- A "blockquote" indents on both sides; any "attribution" -->
<!-- finishes it, right-aligned, introduced by an em-dash.   -->
<xsl:template match="blockquote">
    <fo:block margin-left="2.5em" margin-right="2.5em" space-before="0.75em" space-after="0.75em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:apply-templates select="*"/>
    </fo:block>
</xsl:template>

<xsl:template match="attribution">
    <fo:block text-align="end">
        <xsl:call-template name="mdash-character"/>
        <xsl:choose>
            <xsl:when test="line">
                <xsl:apply-templates select="line"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </fo:block>
</xsl:template>

<!-- A "poem": title centered, stanzas of lines, a right-aligned -->
<!-- author.  Fancy authored alignment/indentation of individual -->
<!-- lines is a refinement for later.                            -->
<xsl:template match="poem">
    <fo:block margin-left="2.5em" margin-right="2.5em" space-before="0.75em" space-after="0.75em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:if test="title">
            <fo:block font-weight="bold" text-align="center" space-after="0.5em">
                <xsl:apply-templates select="." mode="title-full"/>
            </fo:block>
        </xsl:if>
        <xsl:apply-templates select="stanza|line"/>
        <xsl:apply-templates select="author" mode="poem-author"/>
    </fo:block>
</xsl:template>

<xsl:template match="stanza">
    <fo:block space-after="0.75em">
        <xsl:apply-templates select="line"/>
    </fo:block>
</xsl:template>

<!-- "author" is metadata, killed in the default mode by -->
<!-- pretext-common.xsl, so a modal template places it   -->
<xsl:template match="poem/author" mode="poem-author">
    <fo:block text-align="end" font-style="italic">
        <xsl:apply-templates/>
    </fo:block>
</xsl:template>

<!-- A "fillin" blank: an underline rule sized by @characters  -->
<!-- (ten if unspecified).  Fill-ins inside mathematics travel -->
<!-- with the LaTeX, where MathJax renders them.               -->
<xsl:template match="fillin[not(parent::m or parent::mrow)]">
    <fo:leader leader-pattern="rule"
               rule-thickness="0.5pt"
               rule-style="solid"
               leader-length="{format-number(0.55 * 10, '0.##')}em">
        <xsl:if test="@characters">
            <xsl:attribute name="leader-length">
                <xsl:value-of select="format-number(0.55 * @characters, '0.##')"/>
                <xsl:text>em</xsl:text>
            </xsl:attribute>
        </xsl:if>
    </fo:leader>
</xsl:template>

<!-- ######## -->
<!-- Verbatim -->
<!-- ######## -->

<!-- The workhorse: one block of literal text in a monospace font,  -->
<!-- slightly reduced, with every space and linefeed preserved, and -->
<!-- no line-wrapping.  Optionally boxed (e.g. Sage input).         -->
<xsl:template name="verbatim-block">
    <xsl:param name="content"/>
    <xsl:param name="boxed" select="false()"/>
    <fo:block font-family="{$font-family-monospace}"
              font-size="90%"
              white-space-collapse="false"
              white-space-treatment="preserve"
              linefeed-treatment="preserve"
              wrap-option="no-wrap"
              text-align="start"
              space-before="0.5em"
              space-after="0.5em">
        <xsl:if test="$boxed">
            <xsl:attribute name="border">
                <xsl:text>solid 0.5pt #888888</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="padding">
                <xsl:text>3pt</xsl:text>
            </xsl:attribute>
        </xsl:if>
        <xsl:copy-of select="$content"/>
    </fo:block>
</xsl:template>

<!-- "pre" is the pure display of literal text; the "interior" -->
<!-- machinery of pretext-common.xsl scrubs the indentation,   -->
<!-- handling text or "cline" structure alike.                 -->
<xsl:template match="pre">
    <xsl:call-template name="verbatim-block">
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="interior"/>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- A "cd" (code display) interrupts a paragraph with a short -->
<!-- hunk of verbatim text, either mixed content or "cline"s.  -->
<xsl:template match="cd">
    <xsl:call-template name="verbatim-block">
        <xsl:with-param name="content">
            <xsl:choose>
                <xsl:when test="cline">
                    <xsl:apply-templates select="cline"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- A "program" renders its visible source code; line numbers, -->
<!-- line highlighting, and visible preambles/postambles are    -->
<!-- refinements for later.                                     -->
<xsl:template match="program">
    <xsl:call-template name="verbatim-block">
        <xsl:with-param name="content">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text">
                    <xsl:choose>
                        <xsl:when test="code">
                            <xsl:value-of select="code"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- A "console" session: each "input" line carries its prompt   -->
<!-- (resolved by pretext-common.xsl) and is bold, distinct from -->
<!-- plain "output".  Continuation lines are a refinement.       -->
<xsl:template match="console">
    <xsl:call-template name="verbatim-block">
        <xsl:with-param name="content">
            <xsl:apply-templates select="input|output"/>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="console/input">
    <fo:inline font-weight="bold">
        <xsl:apply-templates select="." mode="determine-console-prompt"/>
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="."/>
        </xsl:call-template>
    </fo:inline>
</xsl:template>

<xsl:template match="console/output">
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="."/>
    </xsl:call-template>
</xsl:template>

<!-- A "sage" cell: the input boxed, any output following plain.   -->
<!-- An empty cell is an interactive invitation, nothing on paper. -->
<xsl:template match="sage">
    <xsl:if test="input">
        <xsl:call-template name="verbatim-block">
            <xsl:with-param name="boxed" select="true()"/>
            <xsl:with-param name="content">
                <xsl:call-template name="sanitize-text">
                    <xsl:with-param name="text" select="input"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <xsl:if test="output">
        <xsl:call-template name="verbatim-block">
            <xsl:with-param name="content">
                <xsl:call-template name="sanitize-text">
                    <xsl:with-param name="text" select="output"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- ############ -->
<!-- Side-by-Side -->
<!-- ############ -->

<!-- A "sidebyside" lays out its panels horizontally, as an        -->
<!-- fo:table with a single row.  pretext-common.xsl computes the  -->
<!-- whole layout from the authored attributes: per-panel widths   -->
<!-- and vertical alignments, outer margins, and the uniform space -->
<!-- between panels.  Margins and inter-panel spaces become empty  -->
<!-- columns.  The panel element list mirrors the one in the       -->
<!-- "sidebyside" main template of pretext-common.xsl.             -->
<xsl:template match="sidebyside">
    <xsl:variable name="panels" select="p|pre|ol|ul|dl|program|console|poem|audio|video|interactive|slate|exercise|image|figure|table|listing|list|tabular|stack|jsxgraph|paragraphs"/>
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters"/>
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)"/>
    <xsl:variable name="has-left-margin" select="number(substring-before($layout/left-margin, '%')) &gt; 0"/>
    <xsl:variable name="has-right-margin" select="number(substring-before($layout/right-margin, '%')) &gt; 0"/>
    <xsl:variable name="has-gaps" select="number(substring-before($layout/space-width, '%')) &gt; 0"/>
    <!-- a row without cells is fatal to FOP, so no panels, no table -->
    <xsl:if test="$panels">
    <fo:table table-layout="fixed" width="100%" space-before="0.5em" space-after="0.5em">
        <xsl:if test="$has-left-margin">
            <fo:table-column column-width="proportional-column-width({substring-before($layout/left-margin, '%')})"/>
        </xsl:if>
        <xsl:for-each select="$layout/width">
            <xsl:if test="(position() &gt; 1) and $has-gaps">
                <fo:table-column column-width="proportional-column-width({substring-before($layout/space-width, '%')})"/>
            </xsl:if>
            <fo:table-column column-width="proportional-column-width({substring-before(., '%')})"/>
        </xsl:for-each>
        <xsl:if test="$has-right-margin">
            <fo:table-column column-width="proportional-column-width({substring-before($layout/right-margin, '%')})"/>
        </xsl:if>
        <fo:table-body>
            <fo:table-row>
                <xsl:if test="$has-left-margin">
                    <fo:table-cell>
                        <fo:block/>
                    </fo:table-cell>
                </xsl:if>
                <xsl:for-each select="$panels">
                    <xsl:variable name="panel-number" select="position()"/>
                    <xsl:if test="($panel-number &gt; 1) and $has-gaps">
                        <fo:table-cell>
                            <fo:block/>
                        </fo:table-cell>
                    </xsl:if>
                    <fo:table-cell>
                        <xsl:attribute name="display-align">
                            <xsl:choose>
                                <xsl:when test="$layout/valign[$panel-number] = 'middle'">
                                    <xsl:text>center</xsl:text>
                                </xsl:when>
                                <xsl:when test="$layout/valign[$panel-number] = 'bottom'">
                                    <xsl:text>after</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>before</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:apply-templates select="."/>
                    </fo:table-cell>
                </xsl:for-each>
            </fo:table-row>
        </fo:table-body>
    </fo:table>
    </xsl:if>
</xsl:template>

<!-- A "stack" stacks several items vertically within one panel; -->
<!-- the child list again mirrors pretext-common.xsl.            -->
<xsl:template match="sidebyside/stack">
    <xsl:apply-templates select="tabular|image|p|pre|ol|ul|dl|audio|video|interactive|slate|program|console|exercise"/>
</xsl:template>

<!-- A "sbsgroup" is as pure a container as there can be: the -->
<!-- "sidebyside" children just pile up vertically.  (Common  -->
<!-- layout attributes on the group are consulted by each     -->
<!-- "sidebyside" via the layout machinery.)                  -->
<xsl:template match="sbsgroup">
    <xsl:apply-templates select="sidebyside"/>
</xsl:template>

<!-- ################### -->
<!-- Figures and Caption -->
<!-- ################### -->

<!-- The FIGURE-LIKE blocks (a captioned "figure"; and "table",   -->
<!-- "listing", "list", each titled) wrap their contents and      -->
<!-- finish with a centered caption line; all share one counter.  -->
<!-- The "caption" element is consumed here, so it is killed in   -->
<!-- the default mode, with the other metadata.                   -->
<xsl:template match="&FIGURE-LIKE;">
    <fo:block space-before="1em" space-after="1em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:apply-templates select="*"/>
        <fo:block text-align="center" space-before="0.5em" keep-with-previous.within-page="always">
            <fo:inline font-weight="bold">
                <xsl:apply-templates select="." mode="type-name"/>
                <xsl:variable name="the-number">
                    <xsl:apply-templates select="." mode="number"/>
                </xsl:variable>
                <xsl:if test="not($the-number = '')">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$the-number"/>
                </xsl:if>
                <xsl:text>.</xsl:text>
            </fo:inline>
            <xsl:text> </xsl:text>
            <xsl:choose>
                <xsl:when test="self::figure">
                    <xsl:apply-templates select="caption/node()"/>
                </xsl:when>
                <!-- "table", "listing", "list" are titled -->
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="title-full"/>
                </xsl:otherwise>
            </xsl:choose>
        </fo:block>
    </fo:block>
</xsl:template>

<!-- ############# -->
<!-- Inline Markup -->
<!-- ############# -->

<!-- Semantic inline markup, mostly by font change.  An "alert" -->
<!-- gets both weight and style, distinct from "em" and "term". -->
<xsl:template match="em|pubtitle|taxon|taxon/genus|taxon/species">
    <fo:inline font-style="italic">
        <xsl:apply-templates/>
    </fo:inline>
</xsl:template>

<!-- A "foreign" phrase carries its language into the PDF -->
<!-- structure (WCAG 3.1.2, Language of Parts).           -->
<xsl:template match="foreign">
    <fo:inline font-style="italic">
        <xsl:if test="@xml:lang">
            <xsl:attribute name="xml:lang">
                <xsl:value-of select="@xml:lang"/>
            </xsl:attribute>
        </xsl:if>
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
    <fo:inline font-family="{$font-family-monospace}" border="solid 0.5pt #888888" padding-left="2pt" padding-right="2pt">
        <xsl:value-of select="."/>
    </fo:inline>
</xsl:template>

<!-- Symbol keys set in the symbol font, which covers the arrows. -->
<!-- The official "enter" code point (U+2BA0) is in no DejaVu     -->
<!-- face, so the classic return symbol (U+21B5) stands in.       -->
<xsl:template match="kbd[@name]">
    <xsl:variable name="kbdkey-name" select="@name"/>
    <fo:inline font-family="{$font-family-symbol}" border="solid 0.5pt #888888" padding-left="2pt" padding-right="2pt">
        <xsl:choose>
            <xsl:when test="@name = 'enter'">
                <xsl:text>&#x21b5;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!-- for-each is just one node, but sets context for key() -->
                <xsl:for-each select="$kbdkey-table">
                    <xsl:value-of select="key('kbdkey-key', $kbdkey-name)/@unicode"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </fo:inline>
</xsl:template>

<!-- Implementations of abstract templates from  pretext-common.xsl. -->
<!-- The generic machinery there (inline verbatim text, bibliography -->
<!-- entries, internal markup) calls on these for output-specific    -->
<!-- font changes.                                                   -->
<xsl:template name="code-wrapper">
    <xsl:param name="content"/>
    <fo:inline font-family="{$font-family-monospace}">
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
    <fo:inline font-family="{$font-family-monospace}">
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
<xsl:template match="pretext|prefigure[not(node())]|xetex|xelatex|ad|am|bc|ca|eg|etal|etc|ie|nb|pm|ps|vs|viz|nbsp|ndash|mdash|lsq|rsq|lq|rq|ldblbracket|rdblbracket|langle|rangle|ellipsis|midpoint|swungdash|permille|pilcrow|section-mark|minus|times|solidus|obelus|plusminus|copyright|phonomark|copyleft|registered|trademark|servicemark|degree|prime|dblprime|q|sq|dblbrackets|angles|c|cline|tag|tage|attr|icon|today|timeofday|pi:localize">
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

<!-- The adornments of manually-tagged equations -->
<xsl:template name="tag-star">
    <xsl:text>&#x2736;</xsl:text>
</xsl:template>
<xsl:template name="tag-dagger">
    <xsl:text>&#x2020;</xsl:text>
</xsl:template>
<xsl:template name="tag-daggerdbl">
    <xsl:text>&#x2021;</xsl:text>
</xsl:template>
<xsl:template name="tag-hash">
    <xsl:text>#</xsl:text>
</xsl:template>
<xsl:template name="tag-maltese">
    <xsl:text>&#x2720;</xsl:text>
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

<!-- ######### -->
<!-- Footnotes -->
<!-- ######### -->

<!-- A "fn" is a native fo:footnote: a superscript mark in the    -->
<!-- text, and the body, marked again, collected at the bottom of -->
<!-- the page above the separator rule defined in the entry       -->
<!-- template.  The footnote number is the serial machinery's.    -->
<xsl:template match="fn">
    <xsl:variable name="the-mark">
        <xsl:apply-templates select="." mode="serial-number"/>
    </xsl:variable>
    <fo:footnote>
        <fo:inline baseline-shift="super" font-size="70%">
            <xsl:value-of select="$the-mark"/>
        </fo:inline>
        <fo:footnote-body>
            <fo:block font-size="80%" text-align="justify" space-before="0.25em">
                <xsl:apply-templates select="." mode="link-id-attribute"/>
                <fo:inline baseline-shift="super" font-size="70%">
                    <xsl:value-of select="$the-mark"/>
                </fo:inline>
                <xsl:text> </xsl:text>
                <xsl:apply-templates/>
            </fo:block>
        </fo:footnote-body>
    </fo:footnote>
</xsl:template>

<!-- ########## -->
<!-- Hyperlinks -->
<!-- ########## -->

<!-- Each object an "xref" can target gets an @id, the landing   -->
<!-- spot of an internal link, from the same "unique-id" used to -->
<!-- key the mathematics files.  (N.B. the natural mode name     -->
<!-- "id-attribute" belongs to a whole pass of the assembly      -->
<!-- stylesheet; shadowing it destroys the assembled tree.)      -->
<xsl:template match="*" mode="link-id-attribute">
    <xsl:attribute name="id">
        <xsl:apply-templates select="." mode="unique-id"/>
    </xsl:attribute>
</xsl:template>

<!-- Active links are a conservative dark blue (well above the -->
<!-- WCAG contrast threshold on white paper), and underlining  -->
<!-- honors the publisher's LaTeX link-highlight choice.       -->
<xsl:template name="link-attributes">
    <xsl:attribute name="color">
        <xsl:text>#000080</xsl:text>
    </xsl:attribute>
    <xsl:if test="$latex-link-highlight = 'underline'">
        <xsl:attribute name="text-decoration">
            <xsl:text>underline</xsl:text>
        </xsl:attribute>
    </xsl:if>
</xsl:template>

<!-- A "url" (or "dataurl") is an active external link.  Visible -->
<!-- text is the element's content, or else the "visual" URL     -->
<!-- (authored, or manufactured during assembly) in a monospace  -->
<!-- font.  Inside a title the link is inactive, as in the HTML  -->
<!-- conversion.                                                 -->
<xsl:template match="url|dataurl">
    <xsl:variable name="uri">
        <xsl:choose>
            <!-- "url" and "dataurl" both support external @href -->
            <xsl:when test="@href">
                <xsl:value-of select="@href"/>
            </xsl:when>
            <!-- a "dataurl" might be local, @source is      -->
            <!-- indication, so prefix with a local path/URI -->
            <xsl:when test="self::dataurl and @source">
                <xsl:value-of select="$external-directory"/>
                <xsl:value-of select="@source"/>
            </xsl:when>
            <!-- empty will be non-functional -->
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="visible-text">
        <xsl:choose>
            <xsl:when test="node()">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <fo:inline font-family="{$font-family-monospace}">
                    <xsl:choose>
                        <xsl:when test="@visual">
                            <xsl:value-of select="@visual"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$uri"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </fo:inline>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::shorttitle|ancestor::subtitle">
            <xsl:copy-of select="$visible-text"/>
        </xsl:when>
        <!-- an empty destination is fatal to FOP -->
        <xsl:when test="$uri = ''">
            <xsl:copy-of select="$visible-text"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- the description PDF/UA requires of a link annotation -->
            <fo:basic-link external-destination="url({$uri})" fox:alt-text="{$uri}">
                <xsl:call-template name="link-attributes"/>
                <xsl:copy-of select="$visible-text"/>
            </fo:basic-link>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- An "email" address is an active "mailto:" link. -->
<xsl:template match="email">
    <fo:basic-link external-destination="url(mailto:{normalize-space(.)})" fox:alt-text="mailto:{normalize-space(.)}">
        <xsl:call-template name="link-attributes"/>
        <fo:inline font-family="{$font-family-monospace}">
            <xsl:value-of select="normalize-space(.)"/>
        </fo:inline>
    </fo:basic-link>
</xsl:template>

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- pretext-common.xsl implements all of "xref" processing:      -->
<!-- target identification, error checking, and generation of the -->
<!-- visible text.  It finishes in the abstract modal "xref-link" -->
<!-- template: an active internal link to the @id of the target.  -->
<!-- A not-yet-implemented target has no @id in the output, and   -->
<!-- the link is simply dead until its element joins up.          -->
<xsl:template match="xref">
    <xsl:apply-imports/>
</xsl:template>

<xsl:template match="*" mode="xref-link">
    <xsl:param name="target"/>
    <xsl:param name="origin"/>
    <xsl:param name="content"/>
    <xsl:variable name="the-id">
        <xsl:apply-templates select="$target" mode="unique-id"/>
    </xsl:variable>
    <xsl:choose>
        <!-- an empty destination is fatal to FOP -->
        <xsl:when test="$the-id = ''">
            <xsl:copy-of select="$content"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- the link text doubles as the description PDF/UA requires -->
            <fo:basic-link internal-destination="{$the-id}" fox:alt-text="{normalize-space(string($content))}">
                <xsl:call-template name="link-attributes"/>
                <xsl:copy-of select="$content"/>
            </fo:basic-link>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Hard-coded numbers, as in the HTML conversion: the number of -->
<!-- the target, prefixed by a part number when the reference     -->
<!-- crosses a part boundary under "structural" part numbering.   -->
<xsl:template match="*" mode="xref-number">
    <xsl:param name="xref" select="/.."/>
    <xsl:variable name="needs-part-prefix">
        <xsl:apply-templates select="." mode="crosses-part-boundary">
            <xsl:with-param name="xref" select="$xref"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$needs-part-prefix = 'true'">
        <xsl:apply-templates select="ancestor::part" mode="serial-number"/>
        <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="number"/>
</xsl:template>

<!-- The exception: a local @tag on display mathematics -->
<xsl:template match="mrow[@tag]" mode="xref-number">
    <xsl:apply-templates select="@tag" mode="tag-symbol"/>
</xsl:template>

<xsl:template match="md[@pi:authored-one-line and mrow/@tag]" mode="xref-number">
    <xsl:apply-templates select="mrow/@tag" mode="tag-symbol"/>
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
    <xsl:variable name="speech" select="normalize-space($speech-repr/pi:math[@id = $id]/div[@class = 'speech'])"/>
    <xsl:variable name="width-points">
        <xsl:choose>
            <xsl:when test="contains($svg/@width, 'ex')">
                <xsl:value-of select="number(substring-before($svg/@width, 'ex')) * $math-points-per-ex"/>
            </xsl:when>
            <!-- a wide, aligned display gets width="100%" from   -->
            <!-- MathJax, with the true width as a "min-width" in -->
            <!-- the @style                                       -->
            <xsl:when test="contains($svg/@style, 'min-width:')">
                <xsl:value-of select="number(substring-before(substring-after($svg/@style, 'min-width:'), 'ex')) * $math-points-per-ex"/>
            </xsl:when>
            <!-- last resort: the third entry of the @viewBox, in -->
            <!-- thousandths of an em                             -->
            <xsl:otherwise>
                <xsl:variable name="past-origin" select="substring-after(substring-after(normalize-space($svg/@viewBox), ' '), ' ')"/>
                <xsl:value-of select="(number(substring-before($past-origin, ' ')) div 1000) * number(substring-before($font-size, 'pt'))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="height-points"
                  select="number(substring-before($svg/@height, 'ex')) * $math-points-per-ex"/>
    <xsl:choose>
        <xsl:when test="$svg and self::m">
            <!-- for math sitting on the baseline (e.g. a lone digit),  -->
            <!-- MathJax writes "vertical-align: 0;", unitless, and the -->
            <!-- parse of the "ex" quantity comes up empty, not zero    -->
            <xsl:variable name="drop-raw" select="substring-before(substring-after($svg/@style, 'vertical-align:'), 'ex')"/>
            <xsl:variable name="drop-ex">
                <xsl:choose>
                    <xsl:when test="contains($svg/@style, 'vertical-align:') and not(string(number($drop-raw)) = 'NaN')">
                        <xsl:value-of select="number($drop-raw)"/>
                    </xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <fo:instream-foreign-object alignment-adjust="{format-number($drop-ex * $math-points-per-ex, '0.####')}pt">
                <xsl:if test="not($speech = '')">
                    <xsl:attribute name="fox:alt-text">
                        <xsl:value-of select="$speech"/>
                    </xsl:attribute>
                </xsl:if>
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
                <xsl:apply-templates select="." mode="link-id-attribute"/>
                <fo:instream-foreign-object>
                    <xsl:if test="not($speech = '')">
                        <xsl:attribute name="fox:alt-text">
                            <xsl:value-of select="$speech"/>
                        </xsl:attribute>
                    </xsl:if>
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

<!-- Assembly hoists an "intertext" out of its "md", to sit among -->
<!-- the children of the paragraph, between two displays; its     -->
<!-- prose just continues the paragraph.                          -->
<xsl:template match="pi:intertext">
    <xsl:apply-templates/>
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
    <fo:inline font-family="{$font-family-monospace}" border="solid 0.5pt #888888" padding-left="2pt" padding-right="2pt">
        <xsl:value-of select="."/>
    </fo:inline>
</xsl:template>

<xsl:template match="me|men|md|mdn" mode="math-placeholder">
    <fo:block font-family="{$font-family-monospace}"
              border="solid 0.5pt #888888"
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

<!-- ############ -->
<!-- Author Tools -->
<!-- ############ -->

<!-- An author-tools warning, placed in the margin by the HTML  -->
<!-- conversion.  Quietly dropped here, for now: margin notes   -->
<!-- await a layout treatment.  The named template must exist,  -->
<!-- since a missing named template is a *fatal* runtime error. -->
<xsl:template name="margin-warning">
    <xsl:param name="warning"/>
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
