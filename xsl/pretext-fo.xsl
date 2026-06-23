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
    xmlns:str="http://exslt.org/strings"
    xmlns:pf="https://prefigure.org"
    extension-element-prefixes="exsl str"
    exclude-result-prefixes="pi svg pf str"
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
<!-- font, which is never embedded.  Each named family must have a -->
<!-- matching declaration in  pretext/fop.xconf.  The body and     -->
<!-- monospace faces follow the  pdf/@font  publication key; the    -->
<!-- symbol family is "PreTeXt Symbols", the bundled FreeSerif      -->
<!-- subset (see  fonts/README.md ), which carries the currency     -->
<!-- signs, primes, geometric end-marks, and dingbats that Latin    -->
<!-- Modern lacks.  It is named after the body font on  fo:root ,   -->
<!-- so FOP falls back to it for any glyph the body font is         -->
<!-- missing, and named outright where a specific symbol is drawn.  -->
<xsl:variable name="font-family-main" select="'Latin Modern Roman'"/>
<xsl:variable name="font-family-monospace" select="'Latin Modern Mono'"/>
<!-- for symbols absent from the main font (e.g. the end-marks) -->
<xsl:variable name="font-family-symbol" select="'PreTeXt Symbols'"/>
<!-- the <icon> faces, declared in fop.xconf: FontAwesome 5 Solid   -->
<!-- for the "classic" icons, Brands for the Creative Commons marks -->
<xsl:variable name="font-family-icon" select="'Font Awesome 5 Free Solid'"/>
<xsl:variable name="font-family-icon-brands" select="'Font Awesome 5 Brands'"/>

<!-- US Letter, matching the LaTeX conversion default -->
<xsl:variable name="page-width" select="'8.5in'"/>
<xsl:variable name="page-height" select="'11in'"/>

<!-- The body text width, in points, matches the LaTeX conversion:  -->
<!-- Bringhurst's measure of 34 times the point size (close to 75   -->
<!-- characters per line), so 340pt at a 10pt size.  A "tabular"    -->
<!-- estimates its natural width in points, then claims that as a   -->
<!-- percentage of this reference (see the table code).             -->
<xsl:variable name="text-width-points" select="34 * number(substring-before($font-size, 'pt'))"/>

<!-- The LaTeX "\geometry{...total=...}" centers the text block on   -->
<!-- the page, so the side margins are equal (no binding offset)    -->
<!-- and the block is identical to the LaTeX route.  The 8.5in page -->
<!-- is 612pt wide; the leftover splits evenly between the margins.  -->
<xsl:variable name="margin-side" select="concat((612 - $text-width-points) div 2, 'pt')"/>

<!-- The publisher's right-alignment choice: text justified to both -->
<!-- margins ("flush", the default), or an even word space and a    -->
<!-- ragged right margin.                                           -->
<xsl:variable name="text-alignment">
    <xsl:choose>
        <xsl:when test="$latex-right-alignment = 'ragged'">
            <xsl:text>start</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>justify</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Page numbers within cross-references, via the publisher's      -->
<!-- "pageref" choice: explicitly "yes" or "no", or else defaulting -->
<!-- by utility, on for a print PDF (chase a reference by flipping  -->
<!-- pages) and off for an electronic PDF (just follow the link).   -->
<!-- The same logic as the LaTeX conversion.                        -->
<xsl:variable name="b-pageref"
              select="($latex-pageref = 'yes') or (($latex-pageref = '') and $b-latex-print)"/>

<!-- The publisher's watermark ($watermark-text, with a scale       -->
<!-- factor) becomes light gray text, rotated diagonally and        -->
<!-- centered behind every page's content.  The implementation is   -->
<!-- a small SVG image, written as  watermark.svg  beside the .fo   -->
<!-- file (FOP reads a "data" URI only in base64 form, beyond XSLT  -->
<!-- 1.0), and painted as the background of the body region; a      -->
<!-- background is never content, so the structure tree of the      -->
<!-- tagged PDF is undisturbed.  The historical default font is     -->
<!-- 5cm (141.73pt), tamed by the scale factor, exactly as in the   -->
<!-- LaTeX conversion.                                              -->
<xsl:template name="watermark-attributes">
    <xsl:if test="not($watermark-text = '')">
        <xsl:attribute name="background-image">
            <xsl:text>url('watermark.svg')</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="background-repeat">
            <xsl:text>no-repeat</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="background-position-horizontal">
            <xsl:text>center</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="background-position-vertical">
            <xsl:text>center</xsl:text>
        </xsl:attribute>
    </xsl:if>
</xsl:template>

<!-- The image itself: sized to sit within the body region of the -->
<!-- default page (6.5in by 9in, expressed in points), the text   -->
<!-- rotated about the center.                                    -->
<xsl:template name="watermark-image-file">
    <xsl:if test="not($watermark-text = '')">
        <exsl:document href="watermark.svg" method="xml" indent="no">
            <svg:svg width="468pt" height="648pt" viewBox="0 0 468 648">
                <svg:text x="234" y="324"
                          font-family="DejaVu Sans"
                          font-size="{format-number(141.73 * $watermark-scale, '0.##')}"
                          fill="#CCCCCC"
                          text-anchor="middle"
                          transform="rotate(-45 234 324)">
                    <xsl:value-of select="$watermark-text"/>
                </svg:text>
            </svg:svg>
        </exsl:document>
    </xsl:if>
</xsl:template>

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
    <xsl:call-template name="watermark-image-file"/>
    <!-- The body font-family is a list: the main face, then the symbol  -->
    <!-- face.  FOP selects per glyph, so any character missing from the  -->
    <!-- main font (a currency sign, a prime, a list-marker square) is    -->
    <!-- drawn from "PreTeXt Symbols" without any per-character markup.   -->
    <fo:root font-family="{$font-family-main}, {$font-family-symbol}" font-size="{$font-size}" xml:lang="{$document-language}">
        <fo:layout-master-set>
            <fo:simple-page-master master-name="page-odd"
                                   page-width="{$page-width}"
                                   page-height="{$page-height}"
                                   margin-top="1in"
                                   margin-bottom="0.6in"
                                   margin-left="{$margin-side}"
                                   margin-right="{$margin-side}">
                <fo:region-body margin-bottom="0.4in">
                    <xsl:call-template name="watermark-attributes"/>
                </fo:region-body>
                <fo:region-after extent="0.4in"/>
            </fo:simple-page-master>
            <fo:simple-page-master master-name="page-even"
                                   page-width="{$page-width}"
                                   page-height="{$page-height}"
                                   margin-top="1in"
                                   margin-bottom="0.6in"
                                   margin-left="{$margin-side}"
                                   margin-right="{$margin-side}">
                <fo:region-body margin-bottom="0.4in">
                    <xsl:call-template name="watermark-attributes"/>
                </fo:region-body>
                <fo:region-after extent="0.4in"/>
            </fo:simple-page-master>
            <!-- the pages of a back-of-the-book index set in two columns -->
            <fo:simple-page-master master-name="page-index-odd"
                                   page-width="{$page-width}"
                                   page-height="{$page-height}"
                                   margin-top="1in"
                                   margin-bottom="0.6in"
                                   margin-left="{$margin-side}"
                                   margin-right="{$margin-side}">
                <fo:region-body margin-bottom="0.4in" column-count="2" column-gap="2em">
                    <xsl:call-template name="watermark-attributes"/>
                </fo:region-body>
                <fo:region-after extent="0.4in"/>
            </fo:simple-page-master>
            <fo:simple-page-master master-name="page-index-even"
                                   page-width="{$page-width}"
                                   page-height="{$page-height}"
                                   margin-top="1in"
                                   margin-bottom="0.6in"
                                   margin-left="{$margin-side}"
                                   margin-right="{$margin-side}">
                <fo:region-body margin-bottom="0.4in" column-count="2" column-gap="2em">
                    <xsl:call-template name="watermark-attributes"/>
                </fo:region-body>
                <fo:region-after extent="0.4in"/>
            </fo:simple-page-master>
            <fo:page-sequence-master master-name="pages">
                <fo:repeatable-page-master-alternatives>
                    <fo:conditional-page-master-reference master-reference="page-odd" odd-or-even="odd"/>
                    <fo:conditional-page-master-reference master-reference="page-even" odd-or-even="even"/>
                </fo:repeatable-page-master-alternatives>
            </fo:page-sequence-master>
            <fo:page-sequence-master master-name="pages-index">
                <fo:repeatable-page-master-alternatives>
                    <fo:conditional-page-master-reference master-reference="page-index-odd" odd-or-even="odd"/>
                    <fo:conditional-page-master-reference master-reference="page-index-even" odd-or-even="even"/>
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
            <xsl:call-template name="math-cross-reference-destinations"/>
        </fo:declarations>
        <fo:bookmark-tree>
            <xsl:apply-templates select="$document-root/*" mode="bookmark"/>
        </fo:bookmark-tree>
        <!-- A back-of-the-book index earns a page sequence of its    -->
        <!-- own, with a two-column body region, so the document       -->
        <!-- partitions around it (page numbering just continues), and -->
        <!-- back matter following the index gets a third, ordinary    -->
        <!-- sequence.  Without an index, one sequence carries all.    -->
        <xsl:variable name="the-index" select="$document-root/backmatter/index[index-list]"/>
        <xsl:choose>
            <xsl:when test="$the-index">
                <xsl:call-template name="content-page-sequence">
                    <xsl:with-param name="master" select="'pages'"/>
                    <xsl:with-param name="content">
                        <xsl:apply-templates select="$document-root" mode="document-title-block"/>
                        <xsl:apply-templates select="$document-root/*[not(self::backmatter)]"/>
                        <xsl:apply-templates select="$document-root/backmatter/*[not(self::index[index-list]) and not(preceding-sibling::index[index-list])]"/>
                    </xsl:with-param>
                </xsl:call-template>
                <xsl:call-template name="content-page-sequence">
                    <xsl:with-param name="master" select="'pages-index'"/>
                    <xsl:with-param name="content">
                        <xsl:apply-templates select="$the-index" mode="division-heading"/>
                        <xsl:apply-templates select="$the-index/*[not(self::title)]"/>
                    </xsl:with-param>
                </xsl:call-template>
                <xsl:if test="$the-index/following-sibling::*">
                    <xsl:call-template name="content-page-sequence">
                        <xsl:with-param name="master" select="'pages'"/>
                        <xsl:with-param name="content">
                            <xsl:apply-templates select="$the-index/following-sibling::*"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="content-page-sequence">
                    <xsl:with-param name="master" select="'pages'"/>
                    <xsl:with-param name="content">
                        <xsl:apply-templates select="$document-root"/>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </fo:root>
</xsl:template>

<!-- One page sequence: the folio in the footer, the footnote   -->
<!-- separator rule, and the supplied content in the body.      -->
<xsl:template name="content-page-sequence">
    <xsl:param name="master"/>
    <xsl:param name="content"/>
    <fo:page-sequence master-reference="{$master}">
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
            <xsl:copy-of select="$content"/>
        </fo:flow>
    </fo:page-sequence>
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

<xsl:template match="chapter|section|subsection|subsubsection|appendix|exercises|worksheet|handout|reading-questions|solutions|references|glossary|preface|acknowledgement|foreword|dedication|biography|colophon|index" mode="bookmark">
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
    <xsl:apply-templates select="." mode="document-title-block"/>
    <xsl:apply-templates/>
</xsl:template>

<!-- factored out, so the partitioned page sequences of a -->
<!-- document with a two-column index can also lead with  -->
<!-- the document title                                   -->
<xsl:template match="article|book" mode="document-title-block">
    <fo:block font-size="200%"
              font-weight="bold"
              text-align="center"
              space-after="2em"
              role="H1">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:apply-templates select="." mode="title-full"/>
    </fo:block>
</xsl:template>

<!-- A heading: optional localized "type-name number", then the     -->
<!-- title.  An unnumbered division (perhaps numbering is limited   -->
<!-- by the publisher's numbering level) gets a title-only heading. -->
<!-- The specialized divisions ("exercises", "references", ...)     -->
<!-- take the very same heading; their specialized *contents* are   -->
<!-- implemented (or not, yet) elsewhere.                           -->
<xsl:template match="chapter|section|subsection|subsubsection|appendix|exercises|worksheet|handout|reading-questions|solutions|references|glossary|preface|acknowledgement|foreword|dedication|biography|colophon|index">
    <xsl:apply-templates select="." mode="division-heading"/>
    <xsl:choose>
        <!-- a "solutions" division is empty; its content is mined -->
        <!-- from its scope by the generator in pretext-common.xsl -->
        <xsl:when test="self::solutions">
            <xsl:apply-templates select="idx"/>
            <xsl:apply-templates select="." mode="solutions">
                <xsl:with-param name="heading-level" select="count(ancestor::*[&STRUCTURAL-FILTER;]) + 1"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates/>
        </xsl:otherwise>
    </xsl:choose>
    <!-- material following a formatted printout begins a fresh page; -->
    <!-- a conclusion, when present, carries that break itself         -->
    <xsl:if test="(self::worksheet or self::handout) and $b-latex-worksheet-formatted and not(conclusion)">
        <fo:block break-after="page"/>
    </xsl:if>
</xsl:template>

<!-- The back colophon is centered with side margins like the LaTeX  -->
<!-- "backcolophonstyle": centered "large" bold title, centered body. -->
<xsl:template match="backmatter/colophon">
    <fo:block start-indent="15%" end-indent="15%" text-align="center">
        <fo:block font-size="109%"
                  font-weight="bold"
                  space-before="2.5em"
                  space-after="1em"
                  keep-with-next.within-page="always"
                  role="H{count(ancestor::*[&STRUCTURAL-FILTER;]) + 1}">
            <xsl:apply-templates select="." mode="link-id-attribute"/>
            <xsl:apply-templates select="." mode="title-full"/>
        </fo:block>
        <xsl:apply-templates>
            <xsl:with-param name="alignment" select="'center'"/>
        </xsl:apply-templates>
    </fo:block>
</xsl:template>

<!-- The heading of a division, factored out so the two-column      -->
<!-- index (its own page sequence) can reuse it.  Shape and sizes    -->
<!-- follow the LaTeX conversion's "titlesec" styling: "part" and    -->
<!-- "chapter" use a "display" shape, the type-name and number on    -->
<!-- their own line above the title (centered for a "part"), while   -->
<!-- "section" down to "paragraph" level use a "hang" shape, the     -->
<!-- number run into the title on one line, with no type-name.       -->
<xsl:template match="*" mode="division-heading">
    <xsl:variable name="level">
        <xsl:apply-templates select="." mode="division-name"/>
    </xsl:variable>
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number"/>
    </xsl:variable>
    <xsl:variable name="page-break">
        <xsl:apply-templates select="." mode="division-break"/>
    </xsl:variable>
    <xsl:variable name="hN" select="count(ancestor::*[&STRUCTURAL-FILTER;]) + 1"/>
    <xsl:choose>
        <!-- "display" shape: "part" and "chapter" -->
        <xsl:when test="($level = 'part') or ($level = 'chapter')">
            <!-- "part" is grander and centered, its label at title size -->
            <xsl:variable name="label-size">
                <xsl:choose>
                    <xsl:when test="$level = 'part'">227%</xsl:when>
                    <xsl:otherwise>182%</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="label-gap">
                <xsl:choose>
                    <xsl:when test="$level = 'part'">30pt</xsl:when>
                    <xsl:otherwise>20pt</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <fo:block font-weight="bold"
                      space-before="50pt"
                      space-after="40pt"
                      keep-with-next.within-page="always"
                      role="H{$hN}">
                <xsl:if test="$level = 'part'">
                    <xsl:attribute name="text-align">center</xsl:attribute>
                </xsl:if>
                <xsl:if test="not($page-break = '')">
                    <xsl:attribute name="break-before">
                        <xsl:value-of select="$page-break"/>
                    </xsl:attribute>
                </xsl:if>
                <xsl:apply-templates select="." mode="link-id-attribute"/>
                <!-- "Type N" on its own line, dropped when numberless -->
                <xsl:if test="not($the-number = '')">
                    <fo:block font-size="{$label-size}" space-after="{$label-gap}">
                        <xsl:apply-templates select="." mode="type-name"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$the-number"/>
                    </fo:block>
                </xsl:if>
                <fo:block font-size="227%">
                    <xsl:apply-templates select="." mode="title-full"/>
                </fo:block>
            </fo:block>
        </xsl:when>
        <!-- "hang" shape: "section" through "paragraph" level -->
        <xsl:otherwise>
            <xsl:variable name="hang-size">
                <xsl:choose>
                    <xsl:when test="$level = 'section'">127%</xsl:when>
                    <xsl:when test="$level = 'subsection'">109%</xsl:when>
                    <xsl:otherwise>100%</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="gap-before">
                <xsl:choose>
                    <xsl:when test="$level = 'section'">1.75em</xsl:when>
                    <xsl:otherwise>1.6em</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="gap-after">
                <xsl:choose>
                    <xsl:when test="$level = 'section'">1.15em</xsl:when>
                    <xsl:when test="$level = 'paragraph'">1.5em</xsl:when>
                    <xsl:otherwise>0.75em</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <fo:block font-size="{$hang-size}"
                      font-weight="bold"
                      space-before="{$gap-before}"
                      space-after="{$gap-after}"
                      keep-with-next.within-page="always"
                      role="H{$hN}">
                <xsl:if test="not($page-break = '')">
                    <xsl:attribute name="break-before">
                        <xsl:value-of select="$page-break"/>
                    </xsl:attribute>
                </xsl:if>
                <xsl:apply-templates select="." mode="link-id-attribute"/>
                <xsl:if test="not($the-number = '')">
                    <xsl:value-of select="$the-number"/>
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:apply-templates select="." mode="title-full"/>
            </fo:block>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- The page break, if any, opening a division.  A chapter-level   -->
<!-- division of a book begins a fresh page: the odd (recto) page   -->
<!-- of a spread for a two-sided layout, and also for one-sided     -->
<!-- when the publisher elects "open-odd" pagination to match a     -->
<!-- two-sided copy page-for-page.  (The publisher's "skip-pages"   -->
<!-- flavor of open-odd asks for a *omitted* page number instead of -->
<!-- a blank page, which a single XSL-FO page-sequence cannot       -->
<!-- express; it degrades to the blank page.)  And a formatted      -->
<!-- printout (worksheet, handout) occupies pages of its own.       -->
<xsl:template match="*" mode="division-break">
    <xsl:choose>
        <xsl:when test="parent::book or parent::part or (ancestor::book and (parent::frontmatter or parent::backmatter))">
            <xsl:choose>
                <xsl:when test="$b-latex-two-sides or not($latex-open-odd = 'no')">
                    <xsl:text>odd-page</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>page</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- the publisher names this division for a forced break -->
        <xsl:when test="@xml:id = str:tokenize($latex-pagebreaks-string)">
            <xsl:text>page</xsl:text>
        </xsl:when>
        <xsl:when test="(self::worksheet or self::handout) and $b-latex-worksheet-formatted">
            <xsl:text>page</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- The publisher's "insertions" entries name elements, by their   -->
<!-- @xml:id, that should begin a fresh page, a tool for the final  -->
<!-- massage of a print run.  An empty block carries the break, so  -->
<!-- this hook works wherever block content is legal; it is         -->
<!-- consulted by the same sort of elements as honor a request in   -->
<!-- the LaTeX conversion (divisions just above, via the heading's  -->
<!-- own break attribute).                                          -->
<xsl:template match="*" mode="forced-pagebreak">
    <xsl:if test="@xml:id = str:tokenize($latex-pagebreaks-string)">
        <fo:block break-after="page"/>
    </xsl:if>
</xsl:template>

<!-- A worksheet or handout "page" is a pagination request, -->
<!-- honored whenever the printout is formatted as such.    -->
<xsl:template match="worksheet/page|handout/page">
    <fo:block>
        <xsl:if test="$b-latex-worksheet-formatted and preceding-sibling::page">
            <xsl:attribute name="break-before">
                <xsl:text>page</xsl:text>
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="*"/>
    </fo:block>
</xsl:template>

<!-- A "headnote" introduces a glossary or a structured       -->
<!-- bibliography with explanatory prose; contents just flow. -->
<xsl:template match="headnote">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- An "introduction" or "conclusion" of a division is mostly a -->
<!-- transparent container, but any title runs in, bold, to the  -->
<!-- leading paragraph.                                          -->
<!-- A task-structured block passes its heading the same way.    -->
<xsl:template match="introduction|conclusion">
    <xsl:param name="run-in-heading"/>
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
        <xsl:when test="$run-in-heading">
            <xsl:call-template name="heading-then-content">
                <xsl:with-param name="heading" select="$run-in-heading"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="*"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A worksheet or handout conclusion is pinned to the foot of  -->
<!-- the last page: an overestimated, fully shrinkable space      -->
<!-- overflows the page, and FOP (which shrinks but never grows   -->
<!-- a space) pulls it back to the slack.  Else it simply flows.  -->
<xsl:template match="worksheet/conclusion|handout/conclusion">
    <xsl:choose>
        <xsl:when test="$b-latex-worksheet-formatted">
            <!-- "break-after" here, rather than a trailing empty block -->
            <!-- in the division, so a conclusion that fills the page   -->
            <!-- does not spill the break onto a blank page             -->
            <fo:block space-before.minimum="0pt"
                      space-before.optimum="1000pt"
                      space-before.maximum="1000pt"
                      space-before.conditionality="discard"
                      break-after="page">
                <xsl:apply-templates select="*"/>
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
    <xsl:apply-templates select="." mode="forced-pagebreak"/>
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
<!-- "notation" and image descriptions render elsewhere (or not    -->
<!-- yet), never as in-place content.                              -->
<xsl:template match="title|subtitle|shorttitle|caption|plaintitle|notation|shortdescription|description|creator"/>

<!-- An "idx" is invisible at its location, but the location is   -->
<!-- the whole point: an empty wrapper carries an id, the target  -->
<!-- of the page-number locators of the generated index.  Killed  -->
<!-- inside a title, which is rendered repeatedly (the heading,   -->
<!-- the bookmark outline), where the ids would then duplicate.   -->
<xsl:template match="idx">
    <fo:wrapper>
        <xsl:apply-templates select="." mode="link-id-attribute"/>
    </fo:wrapper>
</xsl:template>

<xsl:template match="idx[ancestor::title or ancestor::subtitle or ancestor::shorttitle]"/>

<!-- The pieces of an "idx" are processed by the index-construction -->
<!-- machinery of pretext-common.xsl, which expects the contents to -->
<!-- pass through (the XSLT built-in rules); the coverage harness   -->
<!-- would otherwise swallow them.                                  -->
<xsl:template match="idx/h|idx/see|idx/seealso">
    <xsl:apply-templates/>
</xsl:template>

<!-- The "type-name" machinery of pretext-common.xsl applies the -->
<!-- matching "rename" of an author's "docinfo", expecting its   -->
<!-- text to pass through; the coverage harness would otherwise  -->
<!-- swallow it, and every renamed type would go blank.          -->
<xsl:template match="docinfo/rename">
    <xsl:apply-templates/>
</xsl:template>

<!-- ########## -->
<!-- Paragraphs -->
<!-- ########## -->

<!-- The "run-in-heading" parameter carries the heading of a      -->
<!-- surrounding block (theorem, proof, ...) for a paragraph that -->
<!-- leads off that block's content; see "heading-then-content".  -->
<xsl:template match="p">
    <xsl:param name="run-in-heading"/>
    <xsl:param name="trailing-tombstone"/>
    <xsl:param name="alignment" select="$text-alignment"/>
    <xsl:apply-templates select="." mode="forced-pagebreak"/>
    <fo:block text-align="{$alignment}">
        <!-- A new paragraph is set off by indenting its first line      -->
        <!-- rather than by vertical space, so consecutive paragraphs    -->
        <!-- share the body leading (no "space-after").  Indent a "p"     -->
        <!-- exactly when another "p" precedes it among its siblings.     -->
        <!-- The opening paragraph of a division or block (after a        -->
        <!-- heading, or a figure's "caption") then stays flush, having   -->
        <!-- no earlier paragraph to break from, while a paragraph that   -->
        <!-- follows an interruption between paragraphs (a figure, a      -->
        <!-- list) is the next paragraph in the prose and indents.  Using -->
        <!-- "preceding-sibling::p" (not the immediate predecessor) keeps -->
        <!-- an invisible "idx" or "notation" marker between paragraphs   -->
        <!-- from masking the earlier one.  Text resuming after an        -->
        <!-- in-paragraph display stays flush: FOP indents only a         -->
        <!-- block's first line, not a line that follows a nested block.  -->
        <!-- Bringhurst (The Elements of Typographic Style, 4th ed.)     -->
        <!-- makes the case for both. Sec. 2.3.2: "In continuous text    -->
        <!-- mark all paragraphs after the first with an indent of at    -->
        <!-- least one en" (the 1.5em here, the LaTeX article default,   -->
        <!-- exceeds that minimum). Sec. 2.3.1, on the flush opener:     -->
        <!-- "The function of a paragraph indent is to mark a pause,     -->
        <!-- setting the paragraph apart from what precedes it. If a     -->
        <!-- paragraph is preceded by a title or subhead, the indent is  -->
        <!-- superfluous and can therefore be omitted, as it is here."   -->
        <xsl:if test="preceding-sibling::p">
            <xsl:attribute name="text-indent">
                <xsl:value-of select="$paragraph-indentation"/>
                <xsl:text>em</xsl:text>
            </xsl:attribute>
        </xsl:if>
        <!-- a tombstone arriving from an enclosing PROOF-LIKE rides -->
        <!-- the final line, whose elastic leader needs the line     -->
        <!-- justified to push the tombstone to the right margin     -->
        <xsl:if test="not(string($trailing-tombstone) = '')">
            <xsl:attribute name="text-align-last">
                <xsl:text>justify</xsl:text>
            </xsl:attribute>
        </xsl:if>
        <!-- a top-level paragraph can enclose a "notation", whose   -->
        <!-- generated list then links here, so every "p" carries an -->
        <!-- id (and becomes a cross-reference target generally)     -->
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:copy-of select="$run-in-heading"/>
        <xsl:apply-templates/>
        <xsl:copy-of select="$trailing-tombstone"/>
    </fo:block>
</xsl:template>

<!-- ############ -->
<!-- Basic Blocks -->
<!-- ############ -->

<!-- The basic titled blocks: a bold heading from the localized  -->
<!-- type-name, the number, and any title, run in to the leading -->
<!-- paragraph of the contents.                                  -->

<!-- A run-in heading is a bold inline, built by one of a few modes -->
<!-- that vary in the number they show.  The font style is reset,   -->
<!-- since the heading may land inside an italic THEOREM-LIKE       -->
<!-- statement.  Each ends with a period and an optional title.     -->

<!-- "heading-full": type-name, full number, and (for a THEOREM or  -->
<!-- AXIOM) the attributing creator.  Basic blocks and inline       -->
<!-- exercises and projects.                                        -->
<xsl:template match="*" mode="heading-full">
    <fo:inline font-weight="bold" font-style="normal">
        <xsl:apply-templates select="." mode="type-name"/>
        <xsl:variable name="the-number">
            <xsl:apply-templates select="." mode="number"/>
        </xsl:variable>
        <xsl:if test="not($the-number = '')">
            <xsl:text> </xsl:text>
            <xsl:value-of select="$the-number"/>
        </xsl:if>
        <!-- attribution of a theorem or axiom, as in the HTML conversion -->
        <xsl:if test="creator and (&THEOREM-FILTER; or &AXIOM-FILTER;)">
            <xsl:text> (</xsl:text>
            <xsl:apply-templates select="." mode="creator-full"/>
            <xsl:text>)</xsl:text>
        </xsl:if>
        <xsl:text>.</xsl:text>
        <xsl:if test="title">
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="title-full"/>
        </xsl:if>
    </fo:inline>
</xsl:template>

<!-- "heading-serial": just the compact serial number, no type-name. -->
<!-- A divisional exercise (in "exercises", a "worksheet", or         -->
<!-- "reading-questions").                                            -->
<xsl:template match="*" mode="heading-serial">
    <fo:inline font-weight="bold" font-style="normal">
        <xsl:apply-templates select="." mode="serial-number"/>
        <xsl:text>.</xsl:text>
        <xsl:if test="title">
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="title-full"/>
        </xsl:if>
    </fo:inline>
</xsl:template>

<!-- "heading-list-number": a parenthesized list number, no type-name. -->
<!-- A "task".                                                         -->
<xsl:template match="*" mode="heading-list-number">
    <fo:inline font-weight="bold" font-style="normal">
        <xsl:text>(</xsl:text>
        <xsl:apply-templates select="." mode="list-number"/>
        <xsl:text>)</xsl:text>
        <xsl:if test="title">
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="title-full"/>
        </xsl:if>
    </fo:inline>
</xsl:template>

<!-- An exercise or project run-in heading.  The assembly stamps    -->
<!-- "@exercise-customization" with the exercise's category; the     -->
<!-- divisional kinds (divisional, worksheet, reading) show a bare   -->
<!-- serial number, while an inline exercise or a project carries    -->
<!-- the full type-name and number.                                  -->
<xsl:template match="*" mode="exercise-heading">
    <xsl:choose>
        <xsl:when test="@exercise-customization = 'inline' or @exercise-customization = 'project'">
            <xsl:apply-templates select="." mode="heading-full"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="heading-serial"/>
        </xsl:otherwise>
    </xsl:choose>
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
    <!-- "idx" and "notation" are invisible markers, not content;     -->
    <!-- render them for their side effects, but do not let them take  -->
    <!-- the heading or block its run-in into a leading paragraph.     -->
    <xsl:apply-templates select="idx | notation"/>
    <xsl:variable name="content" select="*[not(self::title) and not(self::idx) and not(self::notation)]"/>
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
<!-- DEFINITION-LIKE and EXAMPLE-LIKE are exceptions, closing    -->
<!-- with an end-mark, and so match a more specific pattern.     -->
<xsl:template match="&REMARK-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&OPENPROBLEM-LIKE;|&COMPUTATION-LIKE;|&ASIDE-LIKE;|objectives|outcomes">
    <xsl:apply-templates select="." mode="forced-pagebreak"/>
    <fo:block space-before="1em" space-after="1em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:variable name="heading">
            <xsl:apply-templates select="." mode="heading-full"/>
            <xsl:text> </xsl:text>
        </xsl:variable>
        <xsl:call-template name="heading-then-content">
            <xsl:with-param name="heading" select="$heading"/>
        </xsl:call-template>
    </fo:block>
</xsl:template>

<!-- DEFINITION-LIKE and EXAMPLE-LIKE close with an end-mark, as  -->
<!-- in the LaTeX conversion: a filled diamond for a definition,  -->
<!-- a filled triangle for an example (the family of the          -->
<!-- PROOF-LIKE square).  Otherwise these are ordinary run-in     -->
<!-- titled blocks; "block-with-end-mark" supplies the heading    -->
<!-- run-in, the contents, and the riding-or-own-line mark.       -->
<xsl:template match="&DEFINITION-LIKE;|&EXAMPLE-LIKE;">
    <xsl:apply-templates select="." mode="forced-pagebreak"/>
    <fo:block space-before="1em" space-after="1em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:variable name="heading">
            <xsl:apply-templates select="." mode="heading-full"/>
            <xsl:text> </xsl:text>
        </xsl:variable>
        <xsl:call-template name="block-with-end-mark">
            <xsl:with-param name="heading" select="$heading"/>
            <xsl:with-param name="mark">
                <xsl:choose>
                    <!-- BLACK DIAMOND -->
                    <xsl:when test="&DEFINITION-FILTER;">
                        <xsl:text>&#x25c6;</xsl:text>
                    </xsl:when>
                    <!-- BLACK UP-POINTING TRIANGLE -->
                    <xsl:otherwise>
                        <xsl:text>&#x25b2;</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </fo:block>
</xsl:template>

<!-- An "assemblage" is an informal, decorative box.  Unlike the    -->
<!-- run-in headings of the theorem-like families, its optional     -->
<!-- title is a centered heading above the content, as in the HTML  -->
<!-- and LaTeX conversions; an untitled assemblage has no heading.  -->
<xsl:template match="assemblage">
    <xsl:apply-templates select="." mode="forced-pagebreak"/>
    <!-- A prominent enclosing box, matching the LaTeX conversion's   -->
    <!-- tcolorbox: a thin black frame (0.5mm, the tcolorbox default)  -->
    <!-- on the white page, with padding between frame and content.    -->
    <!-- XSL-FO/FOP has no rounded corners, so the box is square; a    -->
    <!-- finite keep prefers the box whole on a page but yields if it  -->
    <!-- is too tall, rather than clip it.                             -->
    <fo:block space-before="1em" space-after="1em" border="0.5mm solid black" padding="0.5em" keep-together.within-page="5">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:if test="title">
            <fo:block font-weight="bold" text-align="center" space-after="0.5em" keep-with-next.within-page="always">
                <xsl:apply-templates select="." mode="title-full"/>
            </fo:block>
        </xsl:if>
        <xsl:apply-templates select="*[not(self::title)]"/>
    </fo:block>
</xsl:template>

<!-- A general-purpose container, otherwise transparent, though -->
<!-- the statement of a THEOREM-LIKE is italic, by mathematical -->
<!-- tradition.                                                 -->
<!-- A "statement" is transparent, but threads a run-in heading to    -->
<!-- its first child and an end-mark to its last, so a block whose     -->
<!-- content is wrapped in a "statement" (a "definition", say) still   -->
<!-- runs its heading in and rides its closing mark.                   -->
<xsl:template match="statement">
    <xsl:param name="run-in-heading"/>
    <xsl:param name="trailing-tombstone"/>
    <xsl:variable name="body">
        <xsl:choose>
            <xsl:when test="count(*) = 1">
                <xsl:apply-templates select="*[1]">
                    <xsl:with-param name="run-in-heading" select="$run-in-heading"/>
                    <xsl:with-param name="trailing-tombstone" select="$trailing-tombstone"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="*[1]">
                    <xsl:with-param name="run-in-heading" select="$run-in-heading"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="*[(position() &gt; 1) and (position() &lt; last())]"/>
                <xsl:apply-templates select="*[last()]">
                    <xsl:with-param name="trailing-tombstone" select="$trailing-tombstone"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="parent::*[&THEOREM-FILTER;]">
            <fo:block font-style="italic">
                <xsl:copy-of select="$body"/>
            </fo:block>
        </xsl:when>
        <xsl:otherwise>
            <xsl:copy-of select="$body"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A titled block whose family closes with an end-mark: the      -->
<!-- PROOF-LIKE tombstone, or the DEFINITION-LIKE / EXAMPLE-LIKE    -->
<!-- mark.  When the block ends in a paragraph the mark rides its   -->
<!-- final line, an elastic leader pushing it to the right margin;  -->
<!-- the closing paragraph may be wrapped in a "statement" (the     -->
<!-- usual shape of a "definition"), which threads the mark on      -->
<!-- through.  Otherwise (a closing display, list, "case", or       -->
<!-- "solution") the mark takes a line of its own, kept on the page -->
<!-- where the content ended so it never leads an orphaned page;    -->
<!-- chasing the mark down into those would be heroics.  The        -->
<!-- heading runs into a leading paragraph, directly or within a    -->
<!-- "statement", as in "heading-then-content".  The mark glyph     -->
<!-- (passed as a code point) comes from the symbol font.           -->
<xsl:template name="block-with-end-mark">
    <xsl:param name="heading"/>
    <xsl:param name="mark"/>
    <xsl:variable name="end-mark">
        <fo:leader leader-pattern="space"/>
        <fo:inline font-family="{$font-family-symbol}">
            <xsl:value-of select="$mark"/>
        </fo:inline>
    </xsl:variable>
    <!-- "idx" and "notation" are invisible markers (an index entry,  -->
    <!-- the notation list), not content: render them for those side  -->
    <!-- effects, but keep them from taking the heading or the mark,   -->
    <!-- or blocking the heading's run-in (a "definition" often leads  -->
    <!-- with them).                                                   -->
    <xsl:apply-templates select="idx | notation"/>
    <xsl:variable name="content" select="*[not(self::title) and not(self::idx) and not(self::notation)]"/>
    <xsl:variable name="last" select="$content[last()]"/>
    <!-- The mark rides a closing paragraph only when that paragraph   -->
    <!-- holds running text alone.  A paragraph that carries a display  -->
    <!-- ("...written as <md/>") would otherwise have its line          -->
    <!-- justified (to push the mark to the margin), spreading the text -->
    <!-- around the display; such a block takes the mark on its own     -->
    <!-- line instead.                                                  -->
    <xsl:variable name="b-mark-rides" select="boolean(($last[self::p] and not($last/md)) or ($last[self::statement] and $last/*[last()][self::p] and not($last/*[last()]/md)))"/>
    <!-- the heading runs in to a leading paragraph, plain or in a "statement" -->
    <xsl:choose>
        <xsl:when test="$content[1][self::p] or ($content[1][self::statement] and $content[1]/*[1][self::p])">
            <xsl:apply-templates select="$content[1]">
                <xsl:with-param name="run-in-heading" select="$heading"/>
                <xsl:with-param name="trailing-tombstone">
                    <xsl:if test="(count($content) = 1) and $b-mark-rides">
                        <xsl:copy-of select="$end-mark"/>
                    </xsl:if>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <fo:block keep-with-next.within-page="always">
                <xsl:copy-of select="$heading"/>
            </fo:block>
            <xsl:apply-templates select="$content[1]"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="$content[(position() &gt; 1) and (position() &lt; last())]"/>
    <xsl:if test="count($content) &gt; 1">
        <xsl:apply-templates select="$content[last()]">
            <xsl:with-param name="trailing-tombstone">
                <xsl:if test="$b-mark-rides">
                    <xsl:copy-of select="$end-mark"/>
                </xsl:if>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="not($b-mark-rides)">
        <fo:block text-align-last="justify" keep-with-previous.within-page="always">
            <xsl:copy-of select="$end-mark"/>
        </fo:block>
    </xsl:if>
</xsl:template>

<!-- An italic run-in heading, the contents, and a filled square -->
<!-- (QED, Halmos) to finish, matching the LaTeX conversion.     -->
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
        <xsl:call-template name="block-with-end-mark">
            <xsl:with-param name="heading" select="$heading"/>
            <!-- BLACK SQUARE -->
            <xsl:with-param name="mark" select="'&#x25a0;'"/>
        </xsl:call-template>
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

<!-- The implication arrows of a "case" direction, and the spacing  -->
<!-- inside a "cycle" decoration, expected by pretext-common.xsl.    -->
<!-- The double arrows are taken from the symbol font: the main body -->
<!-- font (e.g. Latin Modern Roman) need not carry them.             -->
<xsl:template name="double-right-arrow-symbol">
    <fo:inline font-family="{$font-family-symbol}">
        <!-- RIGHTWARDS DOUBLE ARROW -->
        <xsl:text>&#x21d2;</xsl:text>
    </fo:inline>
</xsl:template>
<xsl:template name="double-left-arrow-symbol">
    <fo:inline font-family="{$font-family-symbol}">
        <!-- LEFTWARDS DOUBLE ARROW -->
        <xsl:text>&#x21d0;</xsl:text>
    </fo:inline>
</xsl:template>
<xsl:template name="case-cycle-delimiter-space">
    <!-- THIN SPACE -->
    <xsl:text>&#x2009;</xsl:text>
</xsl:template>

<!-- A hint, answer, or solution appends an exercise or example; a  -->
<!-- context, discussion, opinion, status, or suggestion appends an -->
<!-- open problem.  All render alike: a bold run-in type-name, a    -->
<!-- serial number, an optional parenthesized title, and a period,  -->
<!-- rendered run-in via heading-then-content as for any block.     -->
<xsl:template match="&SOLUTION-LIKE;|&DISCUSSION-LIKE;">
    <fo:block space-before="1em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:variable name="heading">
            <xsl:apply-templates select="." mode="appendage-heading"/>
            <xsl:text> </xsl:text>
        </xsl:variable>
        <xsl:call-template name="heading-then-content">
            <xsl:with-param name="heading" select="$heading"/>
        </xsl:call-template>
    </fo:block>
</xsl:template>

<!-- The run-in heading of an appendage: a bold type-name and a  -->
<!-- serial number, with an optional parenthesized title and a   -->
<!-- period.  A hint, answer, or solution shows its number only  -->
<!-- with same-kind siblings ("Hint" alone, else "Hint 1", ...); -->
<!-- open-problem appendages are always numbered, as in LaTeX.   -->
<xsl:template match="*" mode="appendage-heading">
    <xsl:variable name="the-number">
        <xsl:choose>
            <xsl:when test="self::hint or self::answer or self::solution">
                <xsl:apply-templates select="." mode="non-singleton-number"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="serial-number"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <fo:inline font-weight="bold" font-style="normal">
        <xsl:apply-templates select="." mode="type-name"/>
        <xsl:if test="not($the-number = '')">
            <xsl:text> </xsl:text>
            <xsl:value-of select="$the-number"/>
        </xsl:if>
    </fo:inline>
    <xsl:if test="title">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:text>.</xsl:text>
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
    <xsl:apply-templates select="." mode="forced-pagebreak"/>
    <fo:block space-before="1em" space-after="1em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <!-- index anchors; the components machinery below will not visit them -->
        <xsl:apply-templates select="idx"/>
        <xsl:variable name="heading">
            <xsl:apply-templates select="." mode="exercise-heading"/>
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
        <!-- writing space below, in a printout, when requested -->
        <xsl:apply-templates select="." mode="workspace"/>
    </fo:block>
</xsl:template>

<!-- A "task" reached in document order (e.g. structuring an     -->
<!-- EXAMPLE-LIKE): its label and all its components.            -->
<xsl:template match="task">
    <fo:block space-before="0.75em" space-after="0.75em">
        <!-- a sub-task indents one step deeper than its parent -->
        <xsl:attribute name="start-indent">
            <xsl:value-of select="count(ancestor-or-self::task) * $task-indentation"/>
            <xsl:text>em</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:apply-templates select="idx"/>
        <xsl:variable name="heading">
            <xsl:apply-templates select="." mode="heading-list-number"/>
            <xsl:text> </xsl:text>
        </xsl:variable>
        <xsl:apply-templates select="." mode="exercise-components">
            <xsl:with-param name="run-in-heading" select="$heading"/>
        </xsl:apply-templates>
        <!-- writing space below a terminal task, in a printout -->
        <xsl:apply-templates select="." mode="workspace"/>
    </fo:block>
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
    <fo:block>
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:if test="title">
            <fo:block font-weight="bold"
                      space-before="1em"
                      space-after="0.5em"
                      keep-with-next.within-page="always">
                <xsl:apply-templates select="." mode="title-full"/>
            </fo:block>
        </xsl:if>
        <xsl:apply-templates select="*[not(self::title)]"/>
    </fo:block>
</xsl:template>

<!-- An "exercisegroup" supplies common context for consecutive  -->
<!-- exercises; numbering just continues through it.  An author's -->
<!-- @cols request (2 to 6, by the schema) arranges the exercises -->
<!-- in that many equal columns, progressing across each row; a   -->
<!-- final short row pads with empty cells, since the rows of a   -->
<!-- tagged table must share a common width (ISO 14289-1).        -->
<xsl:template match="exercisegroup">
    <!-- the exercises shift right to show the scope of the group, by -->
    <!-- the shared fraction of the text measure (LaTeX's \egindent); -->
    <!-- the introduction and conclusion stay at the left margin      -->
    <xsl:variable name="group-indent" select="format-number($exercisegroup-indentation * $text-width-points, '0.##')"/>
    <fo:block>
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:apply-templates select="idx"/>
        <xsl:apply-templates select="introduction"/>
        <fo:block start-indent="{$group-indent}pt">
            <xsl:choose>
                <xsl:when test="@cols">
                    <xsl:variable name="cols" select="@cols"/>
                    <fo:table table-layout="fixed" width="100%">
                        <xsl:call-template name="equal-table-columns">
                            <xsl:with-param name="remaining" select="$cols"/>
                        </xsl:call-template>
                        <fo:table-body>
                            <xsl:for-each select="exercise[(position() mod $cols) = 1]">
                                <fo:table-row>
                                    <xsl:variable name="row-exercises" select=".|following-sibling::exercise[position() &lt; $cols]"/>
                                    <xsl:for-each select="$row-exercises">
                                        <fo:table-cell padding-right="6pt">
                                            <xsl:apply-templates select="."/>
                                        </fo:table-cell>
                                    </xsl:for-each>
                                    <xsl:call-template name="empty-table-cells">
                                        <xsl:with-param name="remaining" select="$cols - count($row-exercises)"/>
                                    </xsl:call-template>
                                </fo:table-row>
                            </xsl:for-each>
                        </fo:table-body>
                    </fo:table>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="exercise"/>
                </xsl:otherwise>
            </xsl:choose>
        </fo:block>
        <xsl:apply-templates select="conclusion"/>
    </fo:block>
</xsl:template>

<!-- Workspace in a Printout -->
<!-- ####################### -->

<!-- A worksheet or handout is a printout, and an author may request -->
<!-- blank space below an exercise (or terminal task) where a reader -->
<!-- works: "sanitize-workspace" (pretext-common.xsl) reduces the    -->
<!-- @workspace in effect to an absolute length, or to nothing.  The -->
<!-- space is elastic, in the manner of the LaTeX conversion's       -->
<!-- "vfill": the request is the natural size, a minimum in spirit;  -->
<!-- the space may surrender a quarter on a crowded page, and it can -->
<!-- grow severalfold, so the workspace of a page's final exercise   -->
<!-- expands to fill the remainder of the printout's page.  The      -->
<!-- "retain" sends a space interrupted by a page break wholly onto  -->
<!-- the next page, rather than quietly discarding it.               -->
<xsl:template match="*" mode="workspace">
    <xsl:variable name="vertical-space">
        <xsl:apply-templates select="." mode="sanitize-workspace"/>
    </xsl:variable>
    <xsl:if test="not($vertical-space = '')">
        <xsl:variable name="magnitude" select="substring($vertical-space, 1, string-length($vertical-space) - 2)"/>
        <xsl:variable name="unit" select="substring($vertical-space, string-length($vertical-space) - 1)"/>
        <fo:block space-before.minimum="{format-number(0.75 * $magnitude, '0.##')}{$unit}"
                  space-before.optimum="{$vertical-space}"
                  space-before.maximum="{format-number(4 * $magnitude, '0.##')}{$unit}"
                  space-before.conditionality="retain">
            <!-- The publisher's draft mode makes the workspace visible -->
            <!-- with a faint hairline along its bottom edge, akin to   -->
            <!-- the visible strut of the LaTeX conversion.             -->
            <xsl:if test="$b-latex-draft-mode">
                <fo:leader leader-pattern="rule"
                           leader-length.optimum="100%"
                           rule-thickness="0.5pt"
                           color="#999999"/>
            </xsl:if>
        </fo:block>
    </xsl:if>
</xsl:template>

<!-- The publisher may decline printout formatting wholesale     -->
<!-- (pagination, workspace); then workspace requests evaporate, -->
<!-- exactly as in the LaTeX conversion.                         -->
<xsl:template match="*" mode="sanitize-workspace">
    <xsl:if test="$b-latex-worksheet-formatted">
        <xsl:apply-imports/>
    </xsl:if>
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
    <!-- the block heading: run in to the introduction, else alone -->
    <xsl:choose>
        <xsl:when test="$b-has-statement and introduction">
            <xsl:apply-templates select="introduction">
                <xsl:with-param name="run-in-heading" select="$run-in-heading"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <fo:block keep-with-next.within-page="always">
                <xsl:copy-of select="$run-in-heading"/>
            </fo:block>
        </xsl:otherwise>
    </xsl:choose>
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
                <!-- a sub-task indents one step deeper than its parent -->
                <xsl:attribute name="start-indent">
                    <xsl:value-of select="count(ancestor-or-self::task) * $task-indentation"/>
                    <xsl:text>em</xsl:text>
                </xsl:attribute>
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
    <xsl:param name="heading-level"/>
    <xsl:param name="heading-stack" select="."/>
    <!-- Size by depth, matching the LaTeX "get-heading-text-size":  -->
    <!-- the 11pt-class ratios for Huge/huge/Large/large/normalsize. -->
    <xsl:variable name="heading-size">
        <xsl:choose>
            <xsl:when test="$heading-level = 1">227%</xsl:when>
            <xsl:when test="$heading-level = 2">182%</xsl:when>
            <xsl:when test="$heading-level = 3">127%</xsl:when>
            <xsl:when test="$heading-level = 4">109%</xsl:when>
            <xsl:when test="$heading-level = 5">100%</xsl:when>
            <xsl:otherwise>100%</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <fo:block font-weight="bold"
              font-size="{$heading-size}"
              space-before="1.5em"
              space-after="0.75em"
              keep-with-next.within-page="always">
        <!-- Each division of the stack on its own line, as in the LaTeX -->
        <!-- conversion: the number and title joined by a middle dot,     -->
        <!-- with no type-name.  An unnumbered (specialized) division     -->
        <!-- leads with the dot.                                          -->
        <xsl:for-each select="$heading-stack">
            <fo:block>
                <xsl:variable name="the-number">
                    <xsl:apply-templates select="." mode="number"/>
                </xsl:variable>
                <xsl:if test="not($the-number = '')">
                    <xsl:value-of select="$the-number"/>
                    <xsl:text> </xsl:text>
                </xsl:if>
                <!-- MIDDLE DOT -->
                <xsl:text>&#xB7; </xsl:text>
                <xsl:apply-templates select="." mode="title-full"/>
            </fo:block>
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
                <xsl:apply-templates select="." mode="exercise-heading"/>
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

<!-- The identity copy, with the @id of formatting objects         -->
<!-- withheld.  An @id interior to an SVG (a glyph definition, the -->
<!-- target of a "use") must survive, or the drawing collapses;    -->
<!-- FOP only polices uniqueness of formatting object ids.         -->
<xsl:template match="node()|@*" mode="strip-id-attributes">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="strip-id-attributes"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="fo:*/@id" mode="strip-id-attributes"/>

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
    <xsl:choose>
        <!-- A "cols" request (2 to 6) lays the items out in that many    -->
        <!-- equal columns.  XSL-FO has no block-level multicolumn (only  -->
        <!-- a page region carries "column-count"), so the columns are an -->
        <!-- fo:table, filled across each row, padding a short final row  -->
        <!-- for the equal-width rows a tagged table needs (ISO 14289-1). -->
        <!-- Each cell is a one-item fo:list-block, so the marker shows   -->
        <!-- and the item keeps "L"/"LI" structure for a screen reader    -->
        <!-- despite the table layout.                                    -->
        <xsl:when test="@cols">
            <xsl:variable name="cols" select="@cols"/>
            <fo:table table-layout="fixed" width="100%" space-before="0.5em" space-after="0.5em">
                <xsl:call-template name="equal-table-columns">
                    <xsl:with-param name="remaining" select="$cols"/>
                </xsl:call-template>
                <fo:table-body>
                    <xsl:for-each select="li[(position() mod $cols) = 1]">
                        <fo:table-row>
                            <xsl:variable name="row-items" select=".|following-sibling::li[position() &lt; $cols]"/>
                            <xsl:for-each select="$row-items">
                                <fo:table-cell padding-right="6pt">
                                    <fo:list-block provisional-distance-between-starts="2em"
                                                   provisional-label-separation="0.25em">
                                        <xsl:apply-templates select="."/>
                                    </fo:list-block>
                                </fo:table-cell>
                            </xsl:for-each>
                            <xsl:call-template name="empty-table-cells">
                                <xsl:with-param name="remaining" select="$cols - count($row-items)"/>
                            </xsl:call-template>
                        </fo:table-row>
                    </xsl:for-each>
                </fo:table-body>
            </fo:table>
        </xsl:when>
        <xsl:otherwise>
            <fo:list-block provisional-distance-between-starts="2em"
                           provisional-label-separation="0.25em"
                           space-before="0.5em"
                           space-after="0.5em">
                <xsl:apply-templates select="li"/>
            </fo:list-block>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="ol/li|ul/li">
    <fo:list-item>
        <xsl:apply-templates select="." mode="link-id-attribute"/>
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
    <!-- An optional title leads as an italic heading line, kept with the content that follows -->
    <xsl:if test="title">
        <fo:block font-style="italic" keep-with-next.within-page="always">
            <xsl:apply-templates select="." mode="title-full"/>
        </fo:block>
    </xsl:if>
    <xsl:choose>
        <xsl:when test="p|blockquote|pre|image|video|program|console|tabular|&FIGURE-LIKE;|&ASIDE-LIKE;|sidebyside|sbsgroup|sage">
            <xsl:apply-templates select="*[not(self::title)]"/>
        </xsl:when>
        <xsl:otherwise>
            <fo:block text-align="{$text-alignment}" space-after="0.5em">
                <xsl:apply-templates select="node()[not(self::title)]"/>
            </fo:block>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A description list lays out each item in two columns: a     -->
<!-- bold title in a label column, then its content.  The        -->
<!-- "@width" hint sizes that label column; a narrow one         -->
<!-- flush-lefts its title, the others flush-right.              -->
<xsl:template match="dl">
    <xsl:variable name="label-width">
        <xsl:choose>
            <xsl:when test="@width = 'narrow'">6em</xsl:when>
            <xsl:when test="@width = 'wide'">14em</xsl:when>
            <!-- 'medium', the default, and any typo (the schema checks) -->
            <xsl:otherwise>10em</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <fo:list-block provisional-distance-between-starts="{$label-width}"
                   provisional-label-separation="1em"
                   space-before="0.5em"
                   space-after="0.5em">
        <xsl:apply-templates select="li"/>
    </fo:list-block>
</xsl:template>

<xsl:template match="dl/li">
    <xsl:variable name="label-align">
        <xsl:choose>
            <xsl:when test="parent::dl/@width = 'narrow'">start</xsl:when>
            <xsl:otherwise>end</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <fo:list-item space-before="0.5em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <fo:list-item-label end-indent="label-end()">
            <fo:block font-weight="bold" text-align="{$label-align}">
                <xsl:apply-templates select="." mode="title-full"/>
            </fo:block>
        </fo:list-item-label>
        <fo:list-item-body start-indent="body-start()">
            <xsl:apply-templates select="*[not(self::title)]"/>
        </fo:list-item-body>
    </fo:list-item>
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

<!-- A PreTeXt "tabular" is an fo:table.  FOP only implements the   -->
<!-- fixed table layout, so it cannot size columns to content the   -->
<!-- way LaTeX does; instead the converter estimates a natural      -->
<!-- width for each column (see "tabular-column-widths"), sums them -->
<!-- to a natural table width, and claims that as a percentage of   -->
<!-- the text width, centering the result.  A table whose content   -->
<!-- needs the whole text width (or more) falls back to the full    -->
<!-- width.  The estimates also serve as the proportional column    -->
<!-- widths, so the columns keep their relative sizes.  Header rows, -->
<!-- horizontal or vertical (rotated), land in an fo:table-header,  -->
<!-- which FOP tags as "TH" cells in the PDF structure tree, as     -->
<!-- PDF/UA requires.  The @row-headers request bolds the leading   -->
<!-- column; FOP can mark only an fo:table-header as "TH", so those -->
<!-- cells stay "TD" in the structure tree, a known FOP limit.      -->
<xsl:template match="tabular">
    <xsl:variable name="column-count">
        <xsl:apply-templates select="." mode="column-count"/>
    </xsl:variable>
    <xsl:variable name="widths-rtf">
        <xsl:call-template name="tabular-column-widths">
            <xsl:with-param name="count" select="number($column-count)"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="widths" select="exsl:node-set($widths-rtf)/w"/>
    <xsl:variable name="natural-width" select="sum($widths)"/>
    <!-- the natural width as a percentage of the text width, but    -->
    <!-- never wider than the full text width.  A table in a          -->
    <!-- "sidebyside" panel fills the panel: the panel width, not the -->
    <!-- text width, is its reference, and it is unknown here, so the -->
    <!-- estimate only orders the columns (still proportional below). -->
    <xsl:variable name="table-percent">
        <xsl:choose>
            <xsl:when test="ancestor::sidebyside">
                <xsl:text>100</xsl:text>
            </xsl:when>
            <xsl:when test="$natural-width &gt;= $text-width-points">
                <xsl:text>100</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="round($natural-width * 100 div $text-width-points)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- center a less-than-full-width table by indenting both edges -->
    <!-- half of the leftover width each (FOP supports no "auto"      -->
    <!-- margin, and derives the width from the indents, so both are  -->
    <!-- set to keep the table centered rather than stretched right). -->
    <xsl:variable name="side-indent" select="round((100 - $table-percent) div 2)"/>
    <!-- Keep a "tabular" whole on a page when it fits there, so one  -->
    <!-- that would otherwise split at a page boundary moves forward  -->
    <!-- intact.  This matches LaTeX, where a tabular sits inside an  -->
    <!-- unbreakable tcolorbox.  A finite keep strength (not the      -->
    <!-- forcing "always") lets FOP override it and break a tabular   -->
    <!-- too tall for one page, rather than overflow and clip it as   -->
    <!-- "always" would.  Tune the strength if the keeping proves     -->
    <!-- too eager or too weak.                                       -->
    <fo:table table-layout="fixed" space-before="0.75em" space-after="0.75em" keep-together.within-page="5">
        <xsl:choose>
            <!-- In a "sidebyside" panel a table takes its natural width  -->
            <!-- (in points), so its rules stay coextensive with the      -->
            <!-- content instead of stretching to fill the panel and      -->
            <!-- trailing an over-long top rule.  Capped at the text      -->
            <!-- measure so it never overflows the page; a panel narrower -->
            <!-- than the natural width is uncommon and would only crowd   -->
            <!-- a neighbor, not run off the page.                        -->
            <xsl:when test="ancestor::sidebyside">
                <xsl:attribute name="width">
                    <xsl:choose>
                        <xsl:when test="$natural-width &gt; $text-width-points">
                            <xsl:value-of select="format-number($text-width-points, '0.##')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="format-number($natural-width, '0.##')"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>pt</xsl:text>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="width">
                    <xsl:value-of select="$table-percent"/>
                    <xsl:text>%</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="start-indent">
                    <xsl:value-of select="$side-indent"/>
                    <xsl:text>%</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="end-indent">
                    <xsl:value-of select="$side-indent"/>
                    <xsl:text>%</xsl:text>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
        <!-- The top edge is not a single table border: it rides the     -->
        <!-- first row's cells (see the "cell" template) so the top rule  -->
        <!-- can vary by column via "col/@top".  The other three frame    -->
        <!-- edges stay whole-tabular borders on the table.               -->
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
        <xsl:for-each select="$widths">
            <fo:table-column column-width="proportional-column-width({.})"/>
        </xsl:for-each>
        <xsl:if test="row[(@header = 'yes') or (@header = 'vertical')]">
            <fo:table-header>
                <xsl:apply-templates select="row[(@header = 'yes') or (@header = 'vertical')]"/>
            </fo:table-header>
        </xsl:if>
        <fo:table-body>
            <xsl:apply-templates select="row[not(@header = 'yes') and not(@header = 'vertical')]"/>
        </fo:table-body>
    </fo:table>
</xsl:template>

<!-- An estimated width, in points, for each of a tabular's columns, -->
<!-- emitted as a "w" element apiece.  A column whose cells hold     -->
<!-- paragraphs takes a fraction of the text width: its authored     -->
<!-- "col/@width", else a default fraction (mirroring the LaTeX      -->
<!-- converter, which a paragraph needs a settled width to wrap in). -->
<!-- Every other column is measured from its widest piece of content -->
<!-- among the rows that span no columns: the longest "line", the    -->
<!-- longest line-free cell, or the longest visual URL.  Seven points -->
<!-- per character plus padding is a deliberately generous estimate  -->
<!-- (a capital or digit in the serif font runs near that wide), so  -->
<!-- content is unlikely to overflow its column.                     -->
<xsl:template name="tabular-column-widths">
    <xsl:param name="count"/>
    <xsl:param name="index" select="1"/>
    <xsl:if test="$index &lt;= $count">
        <!-- Size from the cells in column "index" of rows that hold the -->
        <!-- full column-count (so cell position maps to column number),  -->
        <!-- skipping rows with a colspan.  When no row is that full (a   -->
        <!-- "tabular" with more "col" than cells in any row), fall back  -->
        <!-- to the same column of every colspan-free row, so the present -->
        <!-- columns still size from their content and only a genuinely   -->
        <!-- empty column is left with nothing.                          -->
        <xsl:variable name="full-row-cells" select="row[(count(cell) = $count) and not(cell/@colspan)]/cell[$index]"/>
        <xsl:variable name="column-cells" select="$full-row-cells | row[not($full-row-cells) and not(cell/@colspan)]/cell[$index]"/>
        <w>
            <xsl:choose>
                <!-- a paragraph column: a fraction of the text width -->
                <xsl:when test="$column-cells/p">
                    <xsl:variable name="fraction">
                        <xsl:choose>
                            <xsl:when test="col[$index]/@width">
                                <xsl:value-of select="substring-before(col[$index]/@width, '%') div 100"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>0.2</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:value-of select="round($fraction * $text-width-points)"/>
                </xsl:when>
                <!-- a natural column: measured from its widest content; -->
                <!-- a footnote's text is set elsewhere, not in the cell, -->
                <!-- so it does not count toward the column's width       -->
                <xsl:otherwise>
                    <!-- the character count of each candidate's displayed  -->
                    <!-- text (see "width-text"), gathered so the widest can -->
                    <!-- be taken; a template call cannot live in a sort key -->
                    <xsl:variable name="lengths-rtf">
                        <xsl:for-each select="$column-cells/line | $column-cells[not(line)] | $column-cells//url/@visual">
                            <xsl:variable name="displayed">
                                <xsl:apply-templates select="." mode="width-text"/>
                            </xsl:variable>
                            <length>
                                <xsl:value-of select="string-length(normalize-space($displayed))"/>
                            </length>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:variable name="longest">
                        <xsl:for-each select="exsl:node-set($lengths-rtf)/length">
                            <xsl:sort select="number(.)" data-type="number" order="descending"/>
                            <xsl:if test="position() = 1">
                                <xsl:value-of select="."/>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:choose>
                        <!-- a genuinely empty column (no cell of any row sits  -->
                        <!-- here, e.g. a "col" beyond the cells a row supplies) -->
                        <!-- takes only the padding, so a table-wide top or      -->
                        <!-- bottom rule does not trail past the real content;    -->
                        <!-- the value is the formula below at zero length.       -->
                        <xsl:when test="$longest = ''">
                            <xsl:value-of select="8"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="7 * $longest + 8"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </w>
        <xsl:call-template name="tabular-column-widths">
            <xsl:with-param name="count" select="$count"/>
            <xsl:with-param name="index" select="$index + 1"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- The text a table column is sized from.  By default this      -->
<!-- copy recurses, so wrapper elements, and the source text of   -->
<!-- an "m" (a fair proxy for the rendered math), are measured,   -->
<!-- while a footnote is dropped (its text is set outside the     -->
<!-- cell).  A generator, though, makes text the source lacks,    -->
<!-- so it is rendered to that text and the result measured: an   -->
<!-- "xref" (its reference text), the TeX-family and              -->
<!-- PreTeXt/WeBWorK logos, the date and time, the Latin          -->
<!-- abbreviations, a "url" (whose text may be an attribute),     -->
<!-- the tag-syntax elements, and the punctuation and symbol      -->
<!-- characters.  A "fillin" contributes its blank's character    -->
<!-- count.  Text and attribute nodes fall to the built-in        -->
<!-- rules, which copy their string value through.                -->
<xsl:template match="*" mode="width-text">
    <xsl:apply-templates select="node()" mode="width-text"/>
</xsl:template>

<xsl:template match="fn" mode="width-text"/>

<!-- A cross-reference's displayed text is generated, never in    -->
<!-- the source, so render it via the shared "xref-text" (driven  -->
<!-- by the resolved text style) rather than measure an empty     -->
<!-- string; "self-referential-tabular-xref" is the witness.      -->
<xsl:template match="xref" mode="width-text">
    <xsl:variable name="text-style">
        <xsl:apply-templates select="." mode="get-text-style"/>
    </xsl:variable>
    <xsl:apply-templates select="." mode="xref-text">
        <xsl:with-param name="target" select="id(@ref)"/>
        <xsl:with-param name="text-style" select="$text-style"/>
    </xsl:apply-templates>
</xsl:template>

<!-- The remaining generators have a normal template that already -->
<!-- emits their displayed text, so render each in place; their   -->
<!-- output is plain text (or text inside an inline), which the   -->
<!-- measurement counts.  The list tracks the dispatched          -->
<!-- character/text elements, less the wrappers (which recurse    -->
<!-- to their content), plus the logos and "url".                 -->
<xsl:template match="pretext|latex|tex|xetex|xelatex|webwork[not(* or @copy or @source)]|today|timeofday|ad|am|bc|ca|eg|etal|etc|ie|nb|pm|ps|vs|viz|url|dataurl|icon|kbd[@name]|tag|tage|attr|pi:localize|ndash|mdash|nbsp|lsq|rsq|lq|rq|ldblbracket|rdblbracket|langle|rangle|ellipsis|midpoint|swungdash|permille|pilcrow|section-mark|minus|times|solidus|obelus|plusminus|copyright|phonomark|copyleft|registered|trademark|servicemark|degree|prime|dblprime" mode="width-text">
    <xsl:apply-templates select="."/>
</xsl:template>

<!-- A fill-in blank renders as a rule or box of no characters,   -->
<!-- so it would measure as empty; count its "@characters" width  -->
<!-- (ten by default, matching the blank's own default length).   -->
<xsl:template match="fillin" mode="width-text">
    <xsl:variable name="characters">
        <xsl:choose>
            <xsl:when test="@characters">
                <xsl:value-of select="@characters"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>10</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="str:padding(number($characters), '0')"/>
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

<!-- The width of a "tabular", in columns: as authored, else the -->
<!-- widest row, with any @colspan unrolled.                     -->
<xsl:template match="tabular" mode="column-count">
    <xsl:choose>
        <xsl:when test="col">
            <xsl:value-of select="count(col)"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:for-each select="row">
                <xsl:sort select="count(cell[not(@colspan)]) + sum(cell/@colspan)" data-type="number" order="descending"/>
                <xsl:if test="position() = 1">
                    <xsl:value-of select="count(cell[not(@colspan)]) + sum(cell/@colspan)"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="tabular/row">
    <fo:table-row>
        <xsl:apply-templates select="cell"/>
        <!-- A row narrower than its table makes the tagged-table     -->
        <!-- structure tree irregular, failing PDF/UA-1 validation    -->
        <!-- (ISO 14289-1, via ISO 32000-1 Table 337); pad to width.  -->
        <xsl:variable name="table-width">
            <xsl:apply-templates select="parent::tabular" mode="column-count"/>
        </xsl:variable>
        <xsl:call-template name="empty-table-cells">
            <xsl:with-param name="remaining" select="$table-width - (count(cell[not(@colspan)]) + sum(cell/@colspan))"/>
        </xsl:call-template>
    </fo:table-row>
</xsl:template>

<xsl:template name="empty-table-cells">
    <xsl:param name="remaining"/>
    <xsl:if test="$remaining &gt; 0">
        <fo:table-cell padding="2pt" start-indent="0pt" end-indent="0pt">
            <fo:block/>
        </fo:table-cell>
        <xsl:call-template name="empty-table-cells">
            <xsl:with-param name="remaining" select="$remaining - 1"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- A header row is bold, a visual echo of its structural role. -->
<xsl:template match="row/cell">
    <!-- start-indent and end-indent are inherited; a centered table  -->
    <!-- sets them on the fo:table, so reset them here or FOP shifts   -->
    <!-- and narrows the cell content by the table's indent.           -->
    <fo:table-cell padding="2pt" start-indent="0pt" end-indent="0pt">
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
                        <!-- a right border comes from the last column the   -->
                        <!-- cell occupies, so a spanning cell reaches past  -->
                        <!-- its starting column to the end of its span      -->
                        <xsl:variable name="start-position" select="count(preceding-sibling::cell[not(@colspan)]) + sum(preceding-sibling::cell/@colspan) + 1"/>
                        <xsl:variable name="span">
                            <xsl:choose>
                                <xsl:when test="@colspan">
                                    <xsl:value-of select="@colspan"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>1</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:value-of select="ancestor::tabular/col[position() = $start-position + $span - 1]/@right"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
        <!-- The left edge of a row lives on its leading cell, taken    -->
        <!-- from the cell, else the row (mirroring the bottom edge's    -->
        <!-- fallback); the schema places a per-row left rule on "row",  -->
        <!-- and the whole-tabular left rule is on the "fo:table".  A    -->
        <!-- spanning leading cell still owns the single left edge.      -->
        <xsl:if test="not(preceding-sibling::cell)">
            <xsl:call-template name="rule-attribute">
                <xsl:with-param name="side" select="'left'"/>
                <xsl:with-param name="thickness">
                    <xsl:choose>
                        <xsl:when test="@left">
                            <xsl:value-of select="@left"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="parent::row/@left"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>
        <!-- The top edge of the table rides its first row, per column       -->
        <!-- ("col/@top"), so the top rule can vary across columns, or even  -->
        <!-- drop out where "@top" is "none"; a column with no "@top" of its -->
        <!-- own inherits the whole-tabular "@top".  A spanning leading cell -->
        <!-- takes the top of the column it starts in.                       -->
        <xsl:if test="not(parent::row/preceding-sibling::row)">
            <xsl:variable name="top-position" select="count(preceding-sibling::cell[not(@colspan)]) + sum(preceding-sibling::cell/@colspan) + 1"/>
            <xsl:call-template name="rule-attribute">
                <xsl:with-param name="side" select="'top'"/>
                <xsl:with-param name="thickness">
                    <xsl:choose>
                        <xsl:when test="ancestor::tabular/col[position() = $top-position]/@top">
                            <xsl:value-of select="ancestor::tabular/col[position() = $top-position]/@top"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="ancestor::tabular/@top"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>
        <xsl:variable name="the-block">
            <fo:block>
                <xsl:attribute name="text-align">
                    <xsl:apply-templates select="." mode="cell-halign"/>
                </xsl:attribute>
                <!-- headers are bold: a header row (horizontal or  -->
                <!-- vertical), or the leading cell of each row     -->
                <!-- when the tabular requests row headers          -->
                <xsl:if test="(parent::row/@header = 'yes') or (parent::row/@header = 'vertical') or ((ancestor::tabular/@row-headers = 'yes') and not(preceding-sibling::cell))">
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
        </xsl:variable>
        <xsl:choose>
            <!-- A vertical header rotates a quarter-turn, reading    -->
            <!-- bottom-up.  FOP wants the extent of the rotated text -->
            <!-- declared, so the longest text (or "line") among the  -->
            <!-- row's cells estimates a common height for the row.   -->
            <xsl:when test="parent::row/@header = 'vertical'">
                <xsl:variable name="longest-text">
                    <xsl:for-each select="parent::row/cell/line|parent::row/cell[not(line)]">
                        <xsl:sort select="string-length(normalize-space(.))" data-type="number" order="descending"/>
                        <xsl:if test="position() = 1">
                            <xsl:value-of select="string-length(normalize-space(.))"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <fo:block-container reference-orientation="90"
                                    inline-progression-dimension="{format-number(0.5 * $longest-text + 1.5, '0.#')}em">
                    <xsl:copy-of select="$the-block"/>
                </fo:block-container>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$the-block"/>
            </xsl:otherwise>
        </xsl:choose>
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

<!-- A "note" of a bibliography entry is annotation prose, and an  -->
<!-- "xref" target.                                                -->
<xsl:template match="biblio/note">
    <fo:inline>
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates/>
    </fo:inline>
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
                <fo:block text-align="{$text-alignment}">
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
        <!-- a raised exponent, shifted a fixed fraction of the line-height -->
        <fo:inline baseline-shift="35%" font-size="70%">
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
    <xsl:choose>
        <!-- several "line"s: each right-aligned, the dash leading the    -->
        <!-- first, since a bare "line" is its own block and would strand -->
        <!-- the dash on a line of its own                                -->
        <xsl:when test="line">
            <xsl:for-each select="line">
                <fo:block text-align="end">
                    <xsl:if test="position() = 1">
                        <xsl:call-template name="mdash-character"/>
                    </xsl:if>
                    <xsl:apply-templates/>
                </fo:block>
            </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
            <fo:block text-align="end">
                <xsl:call-template name="mdash-character"/>
                <xsl:apply-templates/>
            </fo:block>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A "poem": title centered, stanzas of lines, a flush-left   -->
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
        <xsl:apply-templates select="idx"/>
        <xsl:apply-templates select="stanza|line"/>
        <xsl:apply-templates select="author" mode="poem-author"/>
    </fo:block>
</xsl:template>

<xsl:template match="stanza">
    <fo:block space-after="0.75em">
        <xsl:apply-templates select="idx"/>
        <xsl:apply-templates select="line"/>
    </fo:block>
</xsl:template>

<!-- "author" is metadata, killed in the default mode by -->
<!-- pretext-common.xsl, so a modal template places it   -->
<xsl:template match="poem/author" mode="poem-author">
    <fo:block text-align="start" font-style="italic">
        <xsl:apply-templates/>
    </fo:block>
</xsl:template>

<!-- A "fillin" blank, sized by @characters (ten if unspecified), -->
<!-- in the publisher's chosen text style: an underline rule (the -->
<!-- default), an empty outlined box, or a shaded box.  Fill-ins  -->
<!-- inside mathematics travel with the LaTeX, where MathJax      -->
<!-- renders them in the publisher's math style.                  -->
<xsl:template match="fillin[not(parent::m or parent::mrow)]">
    <xsl:variable name="blank-length">
        <xsl:choose>
            <xsl:when test="@characters">
                <xsl:value-of select="format-number(0.55 * @characters, '0.##')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="format-number(0.55 * 10, '0.##')"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>em</xsl:text>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$fillin-text-style = 'box'">
            <fo:inline border-style="solid" border-width="0.5pt">
                <fo:leader leader-pattern="space" leader-length="{$blank-length}"/>
            </fo:inline>
        </xsl:when>
        <xsl:when test="$fillin-text-style = 'shade'">
            <fo:inline background-color="#D9D9D9">
                <fo:leader leader-pattern="space" leader-length="{$blank-length}"/>
            </fo:inline>
        </xsl:when>
        <!-- "underline", the default -->
        <xsl:otherwise>
            <fo:leader leader-pattern="rule"
                       rule-thickness="0.5pt"
                       rule-style="solid"
                       leader-length="{$blank-length}"/>
        </xsl:otherwise>
    </xsl:choose>
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
    <!-- a "cd" interrupting a paragraph must not inherit its first-line indent -->
    <fo:block font-family="{$font-family-monospace}"
              font-size="90%"
              white-space-collapse="false"
              white-space-treatment="preserve"
              linefeed-treatment="preserve"
              wrap-option="no-wrap"
              text-align="start"
              text-indent="0"
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

<!-- A "cd" (code display) interrupts a paragraph with a short    -->
<!-- hunk of verbatim text, either mixed content or "cline"s.     -->
<!-- With @showspaces="all" every space becomes a visible OPEN    -->
<!-- BOX, as in the HTML conversion (the monospace font carries    -->
<!-- the glyph); the "cline" flavor is handled in a variant below. -->
<xsl:template match="cd">
    <xsl:call-template name="verbatim-block">
        <xsl:with-param name="content">
            <xsl:choose>
                <xsl:when test="cline">
                    <xsl:apply-templates select="cline"/>
                </xsl:when>
                <xsl:when test="@showspaces = 'all'">
                    <xsl:value-of select="str:replace(., '&#x20;', '&#x2423;')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- A "cline" of a "cd" with visible spaces, as in the HTML -->
<!-- conversion: each space becomes the OPEN BOX glyph.      -->
<xsl:template match="cline[parent::cd/@showspaces = 'all']">
    <xsl:value-of select="str:replace(., '&#x20;', '&#x2423;')"/>
    <xsl:text>&#xa;</xsl:text>
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
    <xsl:apply-templates select="." mode="forced-pagebreak"/>
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
    <!-- Keep a "sidebyside" whole on a page when it fits, matching  -->
    <!-- LaTeX, where its panels are an unbreakable "tcbraster".  As -->
    <!-- for a "tabular", the finite strength lets FOP break one too -->
    <!-- tall for a page instead of clipping it; tune it if needed.  -->
    <fo:table table-layout="fixed" width="100%" space-before="0.5em" space-after="0.5em" keep-together.within-page="5">
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
    <xsl:apply-templates select="." mode="forced-pagebreak"/>
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
    <xsl:apply-templates select="." mode="forced-pagebreak"/>
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

<!-- Edits: an "insert" is underlined, a "delete" and a "stale"  -->
<!-- are struck through.  Mirroring the LaTeX conversion, an      -->
<!-- electronic PDF (the default) colors "insert" green and      -->
<!-- "delete" red; a print PDF, and "stale" always, stays black. -->
<xsl:template match="insert">
    <fo:inline text-decoration="underline">
        <xsl:if test="not($b-latex-print)">
            <xsl:attribute name="color">#00FF00</xsl:attribute>
        </xsl:if>
        <xsl:apply-templates/>
    </fo:inline>
</xsl:template>

<xsl:template match="delete">
    <fo:inline text-decoration="line-through">
        <xsl:if test="not($b-latex-print)">
            <xsl:attribute name="color">red</xsl:attribute>
        </xsl:if>
        <xsl:apply-templates/>
    </fo:inline>
</xsl:template>

<xsl:template match="stale">
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

<!-- Named keys.  Each key glyph stands alone, so the font-family   -->
<!-- list resolves per glyph: the ASCII keys (#, &amp;, ~, ...) come -->
<!-- from the monospace face, matching an unnamed boxed key, while   -->
<!-- the arrow and symbol keys fall back to the symbol font.  The    -->
<!-- official "enter" code point (U+2BA0) is in no embeddable face,  -->
<!-- so the classic return symbol (U+21B5) stands in.                -->
<xsl:template match="kbd[@name]">
    <xsl:variable name="kbdkey-name" select="@name"/>
    <fo:inline font-family="{$font-family-monospace}, {$font-family-symbol}" border="solid 0.5pt #888888" padding-left="2pt" padding-right="2pt">
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

<!-- An inline program fragment ("pf") is monospace, exactly as -->
<!-- "c"; syntax highlighting by @language is a refinement.     -->
<xsl:template match="pf">
    <xsl:call-template name="code-wrapper">
        <xsl:with-param name="content">
            <xsl:value-of select="."/>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- An "element" names an XML or HTML element in documentation  -->
<!-- prose; no other conversion decorates it (the built-in rules -->
<!-- apply), so the text just passes through.                    -->
<xsl:template match="element">
    <xsl:apply-templates/>
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
<xsl:template match="pretext|prefigure[not(node())]|webwork[not(* or @copy or @source)]|xetex|xelatex|ad|am|bc|ca|eg|etal|etc|ie|nb|pm|ps|vs|viz|nbsp|ndash|mdash|lsq|rsq|lq|rq|ldblbracket|rdblbracket|langle|rangle|ellipsis|midpoint|swungdash|permille|pilcrow|section-mark|minus|times|solidus|obelus|plusminus|copyright|phonomark|copyleft|registered|trademark|servicemark|degree|prime|dblprime|q|sq|dblbrackets|angles|c|cline|tag|tage|attr|today|timeofday|pi:localize">
    <xsl:apply-imports/>
</xsl:template>

<!-- An <icon> is a FontAwesome 5 glyph, as in the LaTeX route: the -->
<!-- face follows  iconinfo/@font-awesome-family  and the glyph is  -->
<!-- the Private-Use codepoint  iconinfo/@fa-codepoint.             -->
<xsl:template match="icon">
    <xsl:variable name="icon-name" select="string(@name)"/>
    <!-- for-each is one node, but sets the context for key() -->
    <xsl:for-each select="$icon-table">
        <xsl:variable name="info" select="key('icon-key', $icon-name)"/>
        <xsl:variable name="family">
            <xsl:choose>
                <xsl:when test="$info/@font-awesome-family = 'brands'">
                    <xsl:value-of select="$font-family-icon-brands"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$font-family-icon"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <fo:inline font-family="{$family}">
            <xsl:value-of select="$info/@fa-codepoint"/>
        </fo:inline>
    </xsl:for-each>
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

<!-- Quotation marks follow the document's language: each side  -->
<!-- resolves the ambient quotation style (primary for double,  -->
<!-- secondary for single) to its Unicode character, exactly as -->
<!-- the HTML conversion does, through the shared lookup.       -->
<xsl:template match="*" mode="lsq-character">
    <xsl:call-template name="fo-localized-quote-character">
        <xsl:with-param name="style">
            <xsl:apply-templates select="." mode="get-quote-secondary"/>
        </xsl:with-param>
        <xsl:with-param name="side" select="'left'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="*" mode="rsq-character">
    <xsl:call-template name="fo-localized-quote-character">
        <xsl:with-param name="style">
            <xsl:apply-templates select="." mode="get-quote-secondary"/>
        </xsl:with-param>
        <xsl:with-param name="side" select="'right'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="*" mode="lq-character">
    <xsl:call-template name="fo-localized-quote-character">
        <xsl:with-param name="style">
            <xsl:apply-templates select="." mode="get-quote-primary"/>
        </xsl:with-param>
        <xsl:with-param name="side" select="'left'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="*" mode="rq-character">
    <xsl:call-template name="fo-localized-quote-character">
        <xsl:with-param name="style">
            <xsl:apply-templates select="." mode="get-quote-primary"/>
        </xsl:with-param>
        <xsl:with-param name="side" select="'right'"/>
    </xsl:call-template>
</xsl:template>

<!-- Look a quotation mark up in the shared table, then emit it -->
<!-- with any narrow no-break space drawn from the symbol font: -->
<!-- Latin Modern lacks that glyph, so a literal U+202F would   -->
<!-- print as a missing-glyph box next to the guillemets.       -->
<xsl:template name="fo-localized-quote-character">
    <xsl:param name="style"/>
    <xsl:param name="side"/>
    <xsl:variable name="mark">
        <xsl:apply-templates select="." mode="quote-character-unicode">
            <xsl:with-param name="style" select="$style"/>
            <xsl:with-param name="side" select="$side"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:call-template name="isolate-narrow-no-break-space">
        <xsl:with-param name="text" select="$mark"/>
    </xsl:call-template>
</xsl:template>

<!-- Emit a string, drawing each narrow no-break space (U+202F) -->
<!-- from the symbol font, passing the rest unchanged.          -->
<xsl:template name="isolate-narrow-no-break-space">
    <xsl:param name="text"/>
    <xsl:choose>
        <xsl:when test="contains($text, '&#x202f;')">
            <xsl:value-of select="substring-before($text, '&#x202f;')"/>
            <xsl:call-template name="narrow-no-break-space-character"/>
            <xsl:call-template name="isolate-narrow-no-break-space">
                <xsl:with-param name="text" select="substring-after($text, '&#x202f;')"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$text"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- The adornments of manually-tagged equations.  The star and -->
<!-- the maltese cross are missing from the main (serif) face,  -->
<!-- so they borrow the symbol font.                            -->
<xsl:template name="tag-star">
    <fo:inline font-family="{$font-family-symbol}">
        <xsl:text>&#x2736;</xsl:text>
    </fo:inline>
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
    <fo:inline font-family="{$font-family-symbol}">
        <xsl:text>&#x2720;</xsl:text>
    </fo:inline>
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
<!-- the thin space is missing from the main (serif) face, so it -->
<!-- borrows the symbol font, as the narrow no-break space does   -->
<xsl:template name="thin-space-character">
    <fo:inline font-family="{$font-family-symbol}">
        <xsl:text>&#x2009;</xsl:text>
    </fo:inline>
</xsl:template>
<!-- the narrow no-break space is missing from the main (serif) -->
<!-- face, so it borrows the symbol font, as the tombstone does -->
<xsl:template name="narrow-no-break-space-character">
    <fo:inline font-family="{$font-family-symbol}">
        <xsl:text>&#x202f;</xsl:text>
    </fo:inline>
</xsl:template>
<!-- the white square brackets are missing from the main (serif)  -->
<!-- face, so they borrow the symbol font, as the tombstone does  -->
<xsl:template name="ldblbracket-character">
    <fo:inline font-family="{$font-family-symbol}">
        <xsl:text>&#x27e6;</xsl:text>
    </fo:inline>
</xsl:template>
<xsl:template name="rdblbracket-character">
    <fo:inline font-family="{$font-family-symbol}">
        <xsl:text>&#x27e7;</xsl:text>
    </fo:inline>
</xsl:template>
<!-- the *mathematical* angle brackets (U+27E8, U+27E9), missing  -->
<!-- from the main (serif) face, so they borrow the symbol font;  -->
<!-- the CJK pair (U+3008, U+3009) is in no embedded font at all   -->
<xsl:template name="langle-character">
    <fo:inline font-family="{$font-family-symbol}">
        <xsl:text>&#x27e8;</xsl:text>
    </fo:inline>
</xsl:template>
<xsl:template name="rangle-character">
    <fo:inline font-family="{$font-family-symbol}">
        <xsl:text>&#x27e9;</xsl:text>
    </fo:inline>
</xsl:template>
<xsl:template name="ellipsis-character">
    <xsl:text>&#x2026;</xsl:text>
</xsl:template>
<xsl:template name="midpoint-character">
    <xsl:text>&#xb7;</xsl:text>
</xsl:template>
<!-- the swung dash is missing from the main (serif) face, so it -->
<!-- borrows the symbol font, as the tombstone does              -->
<xsl:template name="swungdash-character">
    <fo:inline font-family="{$font-family-symbol}">
        <xsl:text>&#x2053;</xsl:text>
    </fo:inline>
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
<!-- the sound-recording and service marks borrow the symbol font -->
<xsl:template name="phonomark-character">
    <fo:inline font-family="{$font-family-symbol}">
        <xsl:text>&#x2117;</xsl:text>
    </fo:inline>
</xsl:template>
<!-- The copyleft symbol (U+1F12F) is in no embeddable font, so it  -->
<!-- is built, as in its name, from a reversed "c" (U+2184) set in  -->
<!-- parentheses.  The main font lacks the reversed "c", and it sits -->
<!-- between the parentheses with no surrounding space, so it is     -->
<!-- named from the symbol font explicitly, as the primes are.       -->
<xsl:template name="copyleft-character">
    <xsl:text>(</xsl:text>
    <fo:inline font-family="{$font-family-symbol}">
        <xsl:text>&#x2184;</xsl:text>
    </fo:inline>
    <xsl:text>)</xsl:text>
</xsl:template>
<xsl:template name="registered-character">
    <xsl:text>&#xae;</xsl:text>
</xsl:template>
<xsl:template name="trademark-character">
    <xsl:text>&#x2122;</xsl:text>
</xsl:template>
<xsl:template name="servicemark-character">
    <fo:inline font-family="{$font-family-symbol}">
        <xsl:text>&#x2120;</xsl:text>
    </fo:inline>
</xsl:template>
<xsl:template name="degree-character">
    <xsl:text>&#xb0;</xsl:text>
</xsl:template>
<!-- the prime and double prime (minutes and seconds, feet and       -->
<!-- inches) are missing from the main (serif) face; because they     -->
<!-- sit *within* a measurement, with no surrounding space, FOP's     -->
<!-- per-word font selection cannot reach the symbol font for them,   -->
<!-- so each is named explicitly, as the tombstone is.                -->
<xsl:template name="prime-character">
    <fo:inline font-family="{$font-family-symbol}">
        <xsl:text>&#x2032;</xsl:text>
    </fo:inline>
</xsl:template>
<xsl:template name="dblprime-character">
    <fo:inline font-family="{$font-family-symbol}">
        <xsl:text>&#x2033;</xsl:text>
    </fo:inline>
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
        <!-- A fixed fraction of the line-height raises the mark; FOP's -->
        <!-- "super" keyword shifts so far it inflates the line box and -->
        <!-- drops a list item's first line below its label.            -->
        <fo:inline baseline-shift="35%" font-size="70%">
            <xsl:value-of select="$the-mark"/>
        </fo:inline>
        <fo:footnote-body>
            <!-- "text-align-last" keeps the final line ragged: inside a -->
            <!-- "footnote-body" FOP justifies even the last line, which  -->
            <!-- stretches a one-line note across the whole measure       -->
            <fo:block font-size="80%" text-align="{$text-alignment}" text-align-last="start" space-before="0.25em">
                <xsl:apply-templates select="." mode="link-id-attribute"/>
                <fo:inline baseline-shift="35%" font-size="70%">
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

<!-- In an electronic PDF, active links are a conservative dark   -->
<!-- blue (well above the WCAG contrast threshold on white        -->
<!-- paper); in a print PDF the color would just be a distracting -->
<!-- reminder of links a reader cannot follow, so text stays      -->
<!-- black, as in the LaTeX conversion.  Underlining honors the   -->
<!-- publisher's link-highlight choice either way.                -->
<xsl:template name="link-attributes">
    <xsl:if test="not($b-latex-print)">
        <xsl:attribute name="color">
            <xsl:text>#000080</xsl:text>
        </xsl:attribute>
    </xsl:if>
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
            <!-- The link text doubles as the description PDF/UA      -->
            <!-- requires, taken from the string value of the content -->
            <!-- so it keeps a real non-breaking space for a reader,  -->
            <!-- before "fix-nbsp" rewrites those spaces for display. -->
            <fo:basic-link internal-destination="{$the-id}" fox:alt-text="{normalize-space(string($content))}">
                <xsl:call-template name="link-attributes"/>
                <xsl:apply-templates select="exsl:node-set($content)" mode="fix-nbsp"/>
            </fo:basic-link>
            <!-- Trail the link with the target's page number, when the     -->
            <!-- publisher wants them, via a native XSL-FO page-number      -->
            <!-- citation (no second pass needed).  Exceptions echo the     -->
            <!-- LaTeX conversion: a bibliographic citation or an equation  -->
            <!-- number stands alone, and a title is no place for either.   -->
            <xsl:if test="$b-pageref and not($target/self::biblio or $target/self::mrow or $target/self::md or ancestor::title)">
                <xsl:text>, p.&#xa0;</xsl:text>
                <fo:page-number-citation ref-id="{$the-id}"/>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A non-breaking space that ends a word inside an              -->
<!-- "fo:inline" or "fo:basic-link", with a glyph glued           -->
<!-- directly after the inline (no intervening space), trips      -->
<!-- an FOP layout bug: the following glyph is set about 1.8      -->
<!-- points too far left and overprints the inline's last         -->
<!-- character.  An "xref" hits this exactly: its text is         -->
<!-- "Theorem<nbsp>7.3" in a colored link, with an authored       -->
<!-- comma or period often glued on with no space.  Recasting     -->
<!-- the U+00A0 as an "fo:character" that is not a word space     -->
<!-- lets FOP advance normally, while the reference text still    -->
<!-- will not break across lines.  The copy is otherwise an       -->
<!-- identity transform; run it only on link text, where the      -->
<!-- inline boundary and the glued punctuation coincide.          -->
<xsl:template match="node()|@*" mode="fix-nbsp">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="fix-nbsp"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="text()" mode="fix-nbsp">
    <xsl:call-template name="nbsp-to-fo-character">
        <xsl:with-param name="text" select="."/>
    </xsl:call-template>
</xsl:template>

<!-- Emit text, but with each U+00A0 replaced by a non-word-space -->
<!-- "fo:character", recursing across every occurrence.           -->
<xsl:template name="nbsp-to-fo-character">
    <xsl:param name="text"/>
    <xsl:choose>
        <xsl:when test="contains($text, '&#xa0;')">
            <xsl:value-of select="substring-before($text, '&#xa0;')"/>
            <fo:character character="&#xa0;" treat-as-word-space="false"/>
            <xsl:call-template name="nbsp-to-fo-character">
                <xsl:with-param name="text" select="substring-after($text, '&#xa0;')"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$text"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- The cross-references that sit inside display mathematics (an  -->
<!-- "xref" is schema-allowed in an "md", through an "mrow" or a    -->
<!-- single-line "md", but never in an inline "m"), keyed by the    -->
<!-- "@ref" they carry, so a destination is named just once even    -->
<!-- when several references share a target.                        -->
<xsl:key name="math-cross-reference"
         match="xref[ancestor::md]"
         use="@ref"/>

<!-- FOP resolves its own internal links directly and creates no  -->
<!-- named destinations; but a cross-reference inside mathematics -->
<!-- becomes an SVG "a" (see "math.cross-references" in           -->
<!-- extract-math.xsl) that FOP compiles into a GoTo a *named*    -->
<!-- destination.  So, in "fo:declarations", name a destination   -->
<!-- for the target of each such reference, once per target;      -->
<!-- "fox:destination" aims at the element carrying that id,      -->
<!-- wherever it sits.                                            -->
<xsl:template name="math-cross-reference-destinations">
    <xsl:for-each select="$document-root//xref[ancestor::md and id(@ref)]">
        <xsl:if test="count(. | key('math-cross-reference', @ref)[1]) = 1">
            <xsl:variable name="dest-id">
                <xsl:apply-templates select="id(@ref)" mode="unique-id"/>
            </xsl:variable>
            <fox:destination internal-destination="{$dest-id}"/>
        </xsl:if>
    </xsl:for-each>
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
    <!-- A display fills the full text measure only when no     -->
    <!-- ancestor narrows the line: a "sidebyside" panel, an    -->
    <!-- "ol"/"ul"/"dl" list item, a "blockquote", a "tabular"  -->
    <!-- cell, a "task", or a multicolumn "exercisegroup" each  -->
    <!-- reduce the width (and a cell's width is not known here -->
    <!-- in points).                                            -->
    <xsl:variable name="b-full-measure" select="not(ancestor::sidebyside or ancestor::ol or ancestor::ul or ancestor::dl or ancestor::blockquote or ancestor::tabular or ancestor::task or ancestor::exercisegroup[@cols])"/>
    <xsl:variable name="width-points">
        <xsl:choose>
            <xsl:when test="contains($svg/@width, 'ex')">
                <xsl:value-of select="number(substring-before($svg/@width, 'ex')) * $math-points-per-ex"/>
            </xsl:when>
            <!-- a wide, aligned display arrives as width="100%" with    -->
            <!-- no viewBox and its true width as a "min-width" in the   -->
            <!-- @style; MathJax's own layout then centers the body and  -->
            <!-- drives any tag to the right edge of whatever width we   -->
            <!-- assign.  At the full text measure that reproduces the   -->
            <!-- LaTeX result (tag at the margin); in a narrower         -->
            <!-- container we cannot know the available width in points, -->
            <!-- so we fall back to the content (min-width) and let      -->
            <!-- "text-align-last" center it.                            -->
            <xsl:when test="contains($svg/@style, 'min-width:')">
                <xsl:variable name="content-width-points" select="number(substring-before(substring-after($svg/@style, 'min-width:'), 'ex')) * $math-points-per-ex"/>
                <xsl:choose>
                    <xsl:when test="$b-full-measure and ($content-width-points &lt; $text-width-points)">
                        <xsl:value-of select="$text-width-points"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$content-width-points"/>
                    </xsl:otherwise>
                </xsl:choose>
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
    <!-- a display is centered, but when it is wider than the -->
    <!-- text measure, flushing it left lets it overrun only  -->
    <!-- the right margin rather than both                    -->
    <xsl:variable name="display-align">
        <xsl:choose>
            <xsl:when test="$width-points &gt; $text-width-points">left</xsl:when>
            <xsl:otherwise>center</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- the number or symbol of the display's first numbered or -->
    <!-- tagged "mrow" (@pi:numbered="yes" or @tag); empty for   -->
    <!-- inline math (no "mrow") and fully unnumbered displays.  -->
    <xsl:variable name="numbered-row" select="mrow[@pi:numbered = 'yes' or @tag][1]"/>
    <xsl:variable name="eqn-number">
        <xsl:choose>
            <xsl:when test="$numbered-row/@tag">
                <xsl:apply-templates select="$numbered-row/@tag" mode="tag-symbol"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$numbered-row" mode="number"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
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
        <!-- display mathematics in its own block; absorbed         -->
        <!-- clause-ending punctuation is already in the SVG.       -->
        <!-- "text-align-last" repeats the choice because a         -->
        <!-- justified paragraph passes its own down to this lone   -->
        <!-- line, which would otherwise justify (left-pin) the SVG -->
        <xsl:when test="$svg">
            <!-- a display wider than the measure cannot be placed well;  -->
            <!-- warn the author, by number when there is one, and report -->
            <!-- its location                                             -->
            <xsl:if test="$width-points &gt; $text-width-points">
                <xsl:message>
                    <xsl:text>PTX:WARNING: a display </xsl:text>
                    <xsl:if test="not(normalize-space($eqn-number) = '')">
                        <xsl:text>(</xsl:text>
                        <xsl:value-of select="normalize-space($eqn-number)"/>
                        <xsl:text>) </xsl:text>
                    </xsl:if>
                    <xsl:text>is wider than the text and overruns the right margin in the XSL-FO output</xsl:text>
                </xsl:message>
                <xsl:apply-templates select="." mode="location-report"/>
            </xsl:if>
            <fo:block text-align="{$display-align}" text-align-last="{$display-align}" space-before="0.5em" space-after="0.5em">
                <!-- an over-wide numbered display is a centered body in a -->
                <!-- "min-width" SVG, so its body sits one number-width in -->
                <!-- from the left.  At the full measure (inherited        -->
                <!-- start-indent zero) pull left by a conservative under- -->
                <!-- estimate of that width, flushing the body toward the  -->
                <!-- margin without crossing it                            -->
                <xsl:if test="$b-full-measure and ($width-points &gt; $text-width-points) and contains($svg/@style, 'min-width:') and not(normalize-space($eqn-number) = '')">
                    <xsl:attribute name="start-indent">
                        <xsl:text>-</xsl:text>
                        <xsl:value-of select="format-number((string-length(normalize-space($eqn-number)) + 2) * 0.5 * number(substring-before($font-size, 'pt')), '0.##')"/>
                        <xsl:text>pt</xsl:text>
                    </xsl:attribute>
                </xsl:if>
                <xsl:apply-templates select="." mode="link-id-attribute"/>
                <!-- an "xref" targets a constituent "mrow", so each -->
                <!-- contributes an invisible anchor                 -->
                <xsl:for-each select="mrow">
                    <fo:inline>
                        <xsl:apply-templates select="." mode="link-id-attribute"/>
                    </fo:inline>
                </xsl:for-each>
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
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <xsl:for-each select="mrow">
            <fo:inline>
                <xsl:apply-templates select="." mode="link-id-attribute"/>
            </fo:inline>
        </xsl:for-each>
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

<!-- ################################### -->
<!-- Static Forms of Interactive Content -->
<!-- ################################### -->

<!-- The static representations built by pretext-runestone-static.xsl -->
<!-- (and by server-rendered problems, e.g. MyOpenMath and STACK) can -->
<!-- carry pieces of the original interactive markup.                 -->

<!-- In the generated solution of a cardsort or matching problem,   -->
<!-- "premise" and "response" are transparent wrappers within the   -->
<!-- list structure.                                                -->
<xsl:template match="premise|response">
    <xsl:apply-templates/>
</xsl:template>

<!-- A server-rendered problem's text-entry blank arrives as an   -->
<!-- XHTML-flavored "input" with a width in characters; on paper  -->
<!-- it is a fill-in blank of (about) the same width.             -->
<xsl:template match="input[@type = 'text']">
    <xsl:variable name="characters">
        <xsl:choose>
            <xsl:when test="starts-with(@style, 'width:') and contains(@style, 'ch')">
                <xsl:value-of select="substring-before(substring-after(@style, 'width:'), 'ch')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>10</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <fo:leader leader-pattern="rule"
               rule-thickness="0.5pt"
               rule-style="solid"
               leader-length="{format-number(0.55 * $characters, '0.##')}em"/>
</xsl:template>

<!-- more XHTML scraps: a "div" is a transparent grouping, -->
<!-- and a "br" abandons the current line                  -->
<xsl:template match="div">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="br">
    <fo:block/>
</xsl:template>

<!-- An author-supplied "static" representation is exactly what -->
<!-- the printed form of an "interactive" should show.          -->
<xsl:template match="static">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- #################### -->
<!-- Literate Programming -->
<!-- #################### -->

<!-- A "fragment" of a literate program: a heading line with the   -->
<!-- traditional angle-bracket name and defined-to-be symbol, then -->
<!-- verbatim "code" interleaved with "fragref" pointers to other  -->
<!-- fragments.                                                    -->
<xsl:template match="fragment">
    <fo:block space-before="1em" space-after="1em">
        <xsl:apply-templates select="." mode="link-id-attribute"/>
        <fo:block>
            <xsl:call-template name="langle-character"/>
            <xsl:apply-templates select="." mode="number"/>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="title-full"/>
            <xsl:call-template name="rangle-character"/>
            <xsl:text> </xsl:text>
            <xsl:text>&#x2261;</xsl:text>
        </fo:block>
        <xsl:if test="@filename">
            <fo:block>
                <xsl:text>Root of file: </xsl:text>
                <fo:inline font-family="{$font-family-monospace}">
                    <xsl:value-of select="@filename"/>
                </fo:inline>
            </fo:block>
        </xsl:if>
        <xsl:apply-templates select="code|fragref"/>
    </fo:block>
</xsl:template>

<!-- code of a fragment displays verbatim; whitespace-only chunks -->
<!-- (text between two adjacent "fragref") just disappear         -->
<xsl:template match="fragment/code">
    <xsl:if test="not(normalize-space(.) = '')">
        <xsl:call-template name="verbatim-block">
            <xsl:with-param name="content">
                <xsl:call-template name="sanitize-text">
                    <xsl:with-param name="text" select="."/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- A "fragref" points to another fragment: its angle-bracket -->
<!-- name, with the number and page of the target, linked.     -->
<xsl:template match="fragref">
    <xsl:variable name="target" select="id(@ref)"/>
    <xsl:variable name="the-id">
        <xsl:apply-templates select="$target" mode="unique-id"/>
    </xsl:variable>
    <fo:block start-indent="2em">
        <xsl:call-template name="langle-character"/>
        <xsl:apply-templates select="$target" mode="title-full"/>
        <xsl:text> </xsl:text>
        <fo:inline font-size="70%">
            <xsl:apply-templates select="$target" mode="number"/>
            <xsl:text> [</xsl:text>
            <fo:basic-link internal-destination="{$the-id}" fox:alt-text="page of this fragment">
                <xsl:call-template name="link-attributes"/>
                <fo:page-number-citation ref-id="{$the-id}"/>
            </fo:basic-link>
            <xsl:text>]</xsl:text>
        </fo:inline>
        <xsl:call-template name="rangle-character"/>
    </fo:block>
</xsl:template>

<!-- ############### -->
<!-- Generated Lists -->
<!-- ############### -->

<!-- The Index -->

<!-- pretext-common.xsl collects, sorts, and groups the "idx"      -->
<!-- elements when it encounters "index-list"; this conversion     -->
<!-- supplies the presentation through the abstract "present-*"    -->
<!-- named templates below.  A locator is the page number of the   -->
<!-- "idx" location (the anchors made in the default "idx"         -->
<!-- template), each a native XSL-FO page-number citation, so a    -->
<!-- complete back-of-the-book index emerges in a single pass:     -->
<!-- no  makeindex , no second run.                                -->

<!-- the harness would otherwise shadow the machinery -->
<xsl:template match="index-list">
    <xsl:apply-imports/>
</xsl:template>

<!-- the body of the index passes through -->
<xsl:template name="present-index">
    <xsl:param name="content"/>

    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- a vertical gap separates letter groups, in the manner -->
<!-- of the Chicago Manual of Style (and LaTeX defaults)   -->
<xsl:template name="present-letter-group">
    <xsl:param name="the-index-list"/>
    <xsl:param name="letter-group"/>
    <xsl:param name="current-letter"/>
    <xsl:param name="content"/>

    <fo:block space-after="1em">
        <xsl:copy-of select="$content"/>
    </fo:block>
</xsl:template>

<!-- One index entry: the heading at its level (12pt of indentation -->
<!-- per level), wrapped lines hanging a step further, and then the -->
<!-- locators, when this heading is the deepest of its entry.       -->
<xsl:template name="present-index-heading">
    <xsl:param name="the-index-list"/>
    <xsl:param name="heading-group"/>
    <xsl:param name="b-write-locators"/>
    <xsl:param name="heading-level"/>
    <xsl:param name="content"/>

    <fo:block start-indent="{12 * $heading-level}pt" text-indent="-12pt">
        <xsl:copy-of select="$content"/>
        <xsl:if test="$b-write-locators">
            <xsl:call-template name="locator-list">
                <xsl:with-param name="the-index-list" select="$the-index-list"/>
                <xsl:with-param name="heading-group" select="$heading-group"/>
                <xsl:with-param name="cross-reference-separator" select="', '"/>
            </xsl:call-template>
        </xsl:if>
    </fo:block>
</xsl:template>

<!-- the pieces of a locator: processed content suffices -->
<xsl:template name="present-index-locator">
    <xsl:param name="content"/>

    <xsl:copy-of select="$content"/>
</xsl:template>

<xsl:template name="present-index-see">
    <xsl:param name="content"/>

    <xsl:copy-of select="$content"/>
</xsl:template>

<xsl:template name="present-index-see-also">
    <xsl:param name="content"/>

    <xsl:copy-of select="$content"/>
</xsl:template>

<xsl:template name="present-index-italics">
    <xsl:param name="content"/>

    <fo:inline font-style="italic">
        <xsl:copy-of select="$content"/>
    </fo:inline>
</xsl:template>

<!-- One locator: the page number where the "idx" element sits, -->
<!-- which doubles as a live link in an electronic PDF.         -->
<xsl:template match="index-list" mode="index-enclosure">
    <xsl:param name="enclosure"/>

    <xsl:variable name="the-id">
        <xsl:apply-templates select="$enclosure" mode="unique-id"/>
    </xsl:variable>
    <fo:basic-link internal-destination="{$the-id}" fox:alt-text="page of this index entry">
        <xsl:call-template name="link-attributes"/>
        <fo:page-number-citation ref-id="{$the-id}"/>
    </fo:basic-link>
</xsl:template>

<!-- The Notation List -->

<!-- pretext-common.xsl walks every "notation" of the document, in -->
<!-- order, when it meets "notation-list"; here, a table of the    -->
<!-- sample usage (as mathematics), the narrative description, and -->
<!-- a cross-reference to the enclosing environment.               -->

<!-- the harness would otherwise shadow the machinery -->
<xsl:template match="notation-list">
    <xsl:apply-imports/>
</xsl:template>

<xsl:template name="present-notation-list">
    <xsl:param name="content"/>

    <fo:table table-layout="fixed" width="100%" space-before="1em" space-after="1em">
        <fo:table-column column-width="proportional-column-width(2)"/>
        <fo:table-column column-width="proportional-column-width(4)"/>
        <fo:table-column column-width="proportional-column-width(2)"/>
        <fo:table-header>
            <fo:table-row>
                <fo:table-cell padding="2pt" border-bottom-style="solid" border-bottom-width="0.7pt">
                    <fo:block font-weight="bold">
                        <xsl:apply-templates select="." mode="type-name">
                            <xsl:with-param name="string-id" select="'symbol'"/>
                        </xsl:apply-templates>
                    </fo:block>
                </fo:table-cell>
                <fo:table-cell padding="2pt" border-bottom-style="solid" border-bottom-width="0.7pt">
                    <fo:block font-weight="bold">
                        <xsl:apply-templates select="." mode="type-name">
                            <xsl:with-param name="string-id" select="'description'"/>
                        </xsl:apply-templates>
                    </fo:block>
                </fo:table-cell>
                <fo:table-cell padding="2pt" border-bottom-style="solid" border-bottom-width="0.7pt">
                    <fo:block font-weight="bold">
                        <xsl:apply-templates select="." mode="type-name">
                            <xsl:with-param name="string-id" select="'location'"/>
                        </xsl:apply-templates>
                    </fo:block>
                </fo:table-cell>
            </fo:table-row>
        </fo:table-header>
        <fo:table-body>
            <xsl:copy-of select="$content"/>
        </fo:table-body>
    </fo:table>
</xsl:template>

<!-- exactly one "m" of the usage; the description duplicated; -->
<!-- a cross-reference to the enclosure, with its page number  -->
<!-- in print (automatic, from "xref-link")                    -->
<xsl:template match="notation" mode="present-notation-item">
    <fo:table-row>
        <fo:table-cell padding="2pt" display-align="before">
            <fo:block>
                <xsl:apply-templates select="usage/m[1]"/>
            </fo:block>
        </fo:table-cell>
        <fo:table-cell padding="2pt" display-align="before">
            <fo:block>
                <xsl:apply-templates select="description/node()"/>
            </fo:block>
        </fo:table-cell>
        <fo:table-cell padding="2pt" display-align="before">
            <fo:block>
                <xsl:apply-templates select="." mode="enclosure-xref"/>
            </fo:block>
        </fo:table-cell>
    </fo:table-row>
</xsl:template>

<!-- Climb the tree to the first enclosure that is a block or is -->
<!-- structural, and make a cross-reference to it; recursion     -->
<!-- always halts, since the document root is structural.        -->
<xsl:template match="*" mode="enclosure-xref">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural"/>
    </xsl:variable>
    <xsl:variable name="block">
        <xsl:apply-templates select="." mode="is-block"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="($structural = 'true') or ($block = 'true')">
            <xsl:apply-templates select="." mode="xref-link">
                <xsl:with-param name="target" select="."/>
                <xsl:with-param name="origin" select="'notation'"/>
                <xsl:with-param name="content">
                    <xsl:apply-templates select="." mode="type-name"/>
                    <xsl:variable name="enclosure-number">
                        <xsl:apply-templates select="." mode="number"/>
                    </xsl:variable>
                    <xsl:if test="not($enclosure-number = '')">
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$enclosure-number"/>
                    </xsl:if>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="enclosure-xref"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Lists of Blocks ("list-of") -->

<!-- pretext-common.xsl ranges over a scope of the document when -->
<!-- it meets a "list-of", emitting division headings and the    -->
<!-- elements the author requested; here, each element is one    -->
<!-- line, a live cross-reference followed by any title.         -->

<!-- the harness would otherwise shadow the machinery -->
<xsl:template match="list-of">
    <xsl:apply-imports/>
</xsl:template>

<!-- no surrounding infrastructure necessary -->
<xsl:template name="list-of-begin"/>
<xsl:template name="list-of-end"/>

<!-- Subdivision headings within a "list-of": type-name, number, title. -->
<xsl:template match="*" mode="list-of-heading">
    <fo:block font-weight="bold"
              font-size="120%"
              space-before="1.5em"
              space-after="0.75em"
              keep-with-next.within-page="always">
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
    </fo:block>
</xsl:template>

<xsl:template match="*" mode="list-of-element">
    <fo:block>
        <xsl:apply-templates select="." mode="xref-link">
            <xsl:with-param name="target" select="."/>
            <xsl:with-param name="origin" select="'list-of'"/>
            <xsl:with-param name="content">
                <xsl:apply-templates select="." mode="type-name"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="." mode="number"/>
            </xsl:with-param>
        </xsl:apply-templates>
        <xsl:if test="title">
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="title-xref"/>
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
    <xsl:message>PTX:FO-TODO: <xsl:value-of select="local-name()"/> (child of "<xsl:value-of select="local-name(parent::*)"/>")</xsl:message>
    <xsl:apply-templates select="*"/>
</xsl:template>

</xsl:stylesheet>
