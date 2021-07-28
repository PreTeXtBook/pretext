<?xml version='1.0'?> <!-- As XML file -->
<!-- http://stackoverflow.com/questions/10173139/empty-blank-namespace-declarations-being-generated-within-result-document -->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- Building XHTML for the EPUB spec, which requires the    -->
<!-- XHTML namespace on elements.  But since we import the   -->
<!-- base HTML conversion, no amount of messing around can   -->
<!-- make it happen correctly.  So we write literal elements -->
<!-- as XML and after-the-fact we stich-up the necessary     -->
<!-- namespace on the output files with regular expressions  -->
<!-- in Python.  So...we have no namespace at all.           -->
<xsl:stylesheet xmlns:pi="http://pretextbook.org/2020/pretext/internal"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:svg="http://www.w3.org/2000/svg"
                xmlns:math="http://www.w3.org/1998/Math/MathML"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xmlns:exsl="http://exslt.org/common"
                xmlns:date="http://exslt.org/dates-and-times"
                extension-element-prefixes="exsl date">

<!-- Trade on HTML markup, numbering, chunking, etc. -->
<!-- Override as pecularities of EPUB conversion arise -->
<xsl:import href="./pretext-common.xsl" />
<xsl:import href="./pretext-assembly.xsl" />
<xsl:import href="./pretext-html.xsl" />

<!-- TODO: free chunking level -->
<!-- TODO: liberate GeoGebra, videos -->
<!-- TODO: style Sage display-only code in a similar padded box -->

<!-- Output as well-formed xhtml -->
<!-- This may have no practical effect -->
<xsl:output method="xml" encoding="UTF-8" doctype-system="about:legacy-compat" indent="no" />

<!-- Content will go into EPUB directory           -->
<!-- package.opf is main metadata file             -->
<!-- (META-INF/container.xml will point to it)     -->
<!-- Unlikely to need to change this, but we could -->
<xsl:variable name="content-dir">
    <xsl:text>EPUB</xsl:text>
</xsl:variable>
<xsl:variable name="css-dir">
    <xsl:text>css</xsl:text>
</xsl:variable>
<xsl:variable name="xhtml-dir">
    <xsl:text>xhtml</xsl:text>
</xsl:variable>
<xsl:variable name="package-file">
    <xsl:text>package.opf</xsl:text>
</xsl:variable>
<xsl:variable name="endnote-file">
    <xsl:text>endnotes.xhtml</xsl:text>
</xsl:variable>

<!-- A publisher file can set HTML styling which will apply  -->
<!-- here since EPUB is just packaged-up XHTML.  We get two  -->
<!-- values set free of charge in the -html converter, and   -->
<!-- we later pass them on to the packaging step.  These     -->
<!-- are complete filenames, with no path information.       -->
<!--   $html-css-colorfile                                   -->
<!--   $html-css-stylefile                                   -->

<!-- The value of the unique-identifier attribute of -->
<!-- the package element of the container file must  -->
<!-- match the value of the id attribute of the      -->
<!-- dc:identifier element in the metadata section   -->
<!-- So we fix it here for uniformity                -->
<!-- TODO: determine a better way to provide this    -->
<xsl:variable name="uid-string">
    <xsl:text>pub-id</xsl:text>
</xsl:variable>
<xsl:variable name="mock-UUID">mock-123456789-0-987654321</xsl:variable>

<!-- We hard-code the chunking level.  Level 2 is the  -->
<!-- default for books, which we presume throughout.   -->
<!-- Specialized divisions, to the spine, assume this. -->
<xsl:variable name="chunk-level">
    <xsl:choose>
        <xsl:when test="$root/book/part">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
    </xsl:choose>
</xsl:variable>

<!-- We disable the ToC level to avoid any conflicts with chunk level -->
<xsl:variable name="toc-level" select="number(0)" />

<!-- XHTML files as output -->
<xsl:variable name="file-extension" select="'.xhtml'" />

<xsl:param name="tmpdir"/>
<xsl:param name="mathfile"/>
<xsl:variable name="math-repr" select="document($mathfile)/pi:math-representations"/>

<!-- One of 'svg", 'mml', 'kindle', or 'speech', always     -->
<!-- Also 'kindle' dictates MathML output, but is primarily -->
<!-- responsible for integrating PNG images in place of SVG -->
<xsl:param name="math.format"/>

<!-- The  mathjax_latex()  routine in  pretext.py  is parameterized    -->
<!-- by the format of the math being generated:                        -->
<!--     'svg', 'mml', 'nemeth', 'speech', 'kindle'                    -->
<!-- In turn, this dictates if clause-ending punctuation is absorbed   -->
<!-- into the math or not:                                             -->
<!--     'svg', 'mml', 'kindle' -> absorbed into display math only     -->
<!--     'nemeth', 'speech'     -> never absorbed                      -->
<!-- For this stylesheet, which consumes this math, we need to set     -->
<!-- the matching behavior for the adjacent text nodes via an override -->
<!-- of the global  math.punctuation.include  variable.                -->
<xsl:variable name="math.punctuation.include">
    <xsl:choose>
        <xsl:when test="($math.format = 'svg') or ($math.format = 'mml') or ($math.format = 'kindle')">
            <xsl:text>display</xsl:text>
        </xsl:when>
        <xsl:when test="($math.format = 'speech')">
            <xsl:text>none</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:variable>

<!-- Cover image filename, once -->
<xsl:variable name="cover-filename">
    <xsl:value-of select="$publication/epub/@cover"/>
</xsl:variable>

<!-- Kindle needs various tweaks, way beyond just math as MathML -->
<!-- and PNG images.  So a misnomer to call it a "math format",  -->
<!-- but a a boolean sure helps                                  -->
<xsl:variable name="b-kindle" select="$math.format = 'kindle'"/>

<!-- If there are footnotes, we'll build and package a "endnotes.xhtml" file -->
<xsl:variable name="b-has-endnotes" select="boolean($document-root//fn|$document-root//aside|$document-root//biographical|$document-root//historical|$document-root//hint)"/>

<xsl:variable name="endnotes-have-math">
    <xsl:if test="$b-has-endnotes">
        <xsl:choose>
            <xsl:when test="$document-root//fn//m">
                <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:when test="$document-root//aside//m or
                            $document-root//aside//me or
                            $document-root//aside//men or
                            $document-root//aside//md or
                            $document-root//aside//mdn">
                <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:when test="$document-root//biographical//m or
                            $document-root//biographical//me or
                            $document-root//biographical//men or
                            $document-root//biographical//md or
                            $document-root//biographical//mdn">
                <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:when test="$document-root//historical//m or
                            $document-root//historical//me or
                            $document-root//historical//men or
                            $document-root//historical//md or
                            $document-root//historical//mdn">
                <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:when test="$document-root//hint//m or
                            $document-root//hint//me or
                            $document-root//hint//men or
                            $document-root//hint//md or
                            $document-root//hint//mdn">
                <xsl:text>true</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:if>
</xsl:variable>

<xsl:variable name="b-endnotes-have-math" select="$endnotes-have-math = 'true'"/>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the root element,     -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">EPUB conversion is experimental and not supported.  In particular,&#xa;creating an EPUB requires the pretext/pretext script.</xsl:with-param>
    </xsl:call-template>
    <!-- analyze authored source, which will repair "mathbook" -->
    <xsl:apply-templates select="pretext|mathbook" mode="deprecation-warnings" />
    <!-- Following should use $root or $document-root as defined -->
    <!-- by the "assembly" template.  Checked 2020-07-16.        -->
    <xsl:call-template name="setup" />
    <xsl:apply-templates select="$root"/>
    <xsl:call-template name="package-document" />
    <xsl:call-template name="packaging-info"/>
</xsl:template>

<!-- First, we use the frontmatter element to trigger various necessary files     -->
<!-- We process structural nodes via chunking routine in  xsl/mathbook-common.xsl -->
<!-- This in turn calls specific modal templates defined elsewhere in this file   -->
<xsl:template match="/pretext">
    <xsl:apply-templates select="$document-root//frontmatter" mode="epub" />
    <xsl:call-template name="endnotes"/>
    <xsl:apply-templates mode="chunking" />
</xsl:template>

<!-- ################ -->
<!-- Structural Nodes -->
<!-- ################ -->

<!-- Read the code and documentation for "chunking" in xsl/mathbook-common.xsl -->

<!-- Normally a "conclusion" would be on a "summary" page, or a -->
<!-- component of the page for its containing division.  In the -->
<!-- EPUB conversion with "chapter" having "section" it gets an -->
<!-- HTML page of its own as part of the "summary" hack.  Ditto -->
<!-- for "outcomes" which might appear in a different order.    -->
<xsl:template match="&STRUCTURAL;|chapter/conclusion|chapter/outcomes[preceding-sibling::section]" mode="file-wrap">
    <xsl:param name="content" />
    <xsl:variable name="file">
        <xsl:value-of select="$content-dir" />
        <xsl:text>/</xsl:text>
        <xsl:value-of select="$xhtml-dir" />
        <xsl:text>/</xsl:text>
        <xsl:apply-templates select="." mode="containing-filename" />
    </xsl:variable>
    <!-- do not use "doctype-system" here        -->
    <!-- do not create faux <!DOCTYPE html> here -->
    <!-- NB:  If we add  xmlns="http://www.w3.org/1999/xhtml"  to <html> here, -->
    <!-- then we get plenty of top-level-ish  xmlns="" which do not validate   -->
    <!-- Any XML declaration seems to get scrubbed by the MathJax processing   -->
    <!-- (converted to a comment), so we explicitly suppress it here, and in   -->
    <!-- other exsl:document uses.                                             -->
    <exsl:document href="{$file}" method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="no">
        <html>
            <head>
                <xsl:text>&#xa;</xsl:text> <!-- a little formatting help -->
                <xsl:call-template name="converter-blurb-html" />
                <link href="../{$css-dir}/pretext_add_on.css"    rel="stylesheet" type="text/css"/>
                <link href="../{$css-dir}/{$html-css-stylefile}" rel="stylesheet" type="text/css"/>
                <link href="../{$css-dir}/{$html-css-colorfile}" rel="stylesheet" type="text/css"/>
                <link href="../{$css-dir}/setcolors.css"         rel="stylesheet" type="text/css"/>
                <xsl:call-template name="mathjax-css"/>
                <xsl:call-template name="epub-kindle-css"/>
                <title>
                    <xsl:apply-templates select="." mode="type-name-number" />
                </title>
            </head>
            <!-- use class to repurpose HTML CSS work -->
            <body class="pretext-content epub">
                <xsl:copy-of select="$content" />
                <!-- Copy MathJax's font information to the bottom -->
                <xsl:copy-of select="document($mathfile)/pi:math-representations/svg:svg[@id='font-data']"/>
            </body>
        </html>
    </exsl:document>
</xsl:template>

<!-- The book element gets mined in various ways,            -->
<!-- but the "usual" HTML treatment can/should be thrown out -->
<!-- At fixed level 2, this is a summary page                -->
<!-- Later gives precedence?  So overrides above             -->
<xsl:template match="book" mode="file-wrap" />

<!-- This seems a bit dangerous, but this content is fairly small -->
<!-- and they are going into their own files.  So it seems the    -->
<!-- right thing to do, while making minimal changes elsewhere.   -->
<xsl:template match="chapter/conclusion|chapter/outcomes[preceding-sibling::section]" mode="containing-filename">
    <xsl:apply-templates select="." mode="visible-id"/>
    <xsl:text>.xhtml</xsl:text>
</xsl:template>

<!-- If a "book" has some "chapter" subdivided by "section" then -->
<!-- at a chunking level of 2, the "chapter" is an intermediate  -->
<!-- node and will produce a "summary" page.  We implement that  -->
<!-- to produce content that is a faux chapter that is just the  -->
<!-- heading and the lead-in material.  Anything after the last  -->
<!-- division (conclusion, outcomes) will create s of their own, -->
<!-- which will appear as a continuation/ending of the chapter.  -->
<!-- NB: copied from pretext-html.xsl, sans the summary links    -->
<!-- and the conclusion                                          -->
<xsl:template match="frontmatter|chapter|appendix" mode="summary">
    <!-- location info for debugging efforts -->
    <xsl:apply-templates select="." mode="debug-location" />
    <!-- Heading, div for this structural subdivision -->
    <xsl:variable name="hid">
        <xsl:apply-templates select="." mode="html-id" />
    </xsl:variable>
    <section class="{local-name(.)}" id="{$hid}">
        <xsl:apply-templates select="." mode="section-header" />
        <xsl:apply-templates select="author|objectives|introduction|titlepage|abstract" />
        <!-- deleted "nav" and summary links here -->
    </section>
    <xsl:if test="conclusion">
        <xsl:apply-templates select="conclusion" mode="file-wrap">
            <xsl:with-param name="content">
                <xsl:apply-templates select="conclusion"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="outcomes">
        <xsl:apply-templates select="outcomes" mode="file-wrap">
            <xsl:with-param name="content">
                <xsl:apply-templates select="outcomes"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- At level 2, the backmatter summary is useless, -->
<!-- since it is all links, so just kill the file,  -->
<!-- and do not include in the manifest or spine    -->
<xsl:template match="backmatter" mode="file-wrap" />



<!-- ##################### -->
<!-- Setup, Infrastructure -->
<!-- ##################### -->

<!-- The two fixed files of any EPUB                        -->
<!-- (1) mimetype at top-level with prescribed content      -->
<!-- (2) META-INF/container.xml with one variable attribute -->
<xsl:template name="setup">
    <!-- No carriage return at the end (20 byte file) -->
    <exsl:document href="mimetype" method="text">
        <xsl:text>application/epub+zip</xsl:text>
    </exsl:document>
    <!-- Do not use "doctype-system" here                            -->
    <!-- Automatically writes XML header at version 1.0, no encoding -->
    <!-- Points to OPF metadata file (in two variables)              -->
    <exsl:document href="META-INF/container.xml" method="xml" omit-xml-declaration="yes" indent="no">
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
            <rootfiles>
                <rootfile full-path="{$content-dir}/{$package-file}" media-type="application/oebps-package+xml" />
            </rootfiles>
        </container>
    </exsl:document>
</xsl:template>

<!-- ############################## -->
<!-- EPUB 3.0 Package Document file -->
<!-- ############################## -->

<!-- The primary index into various files -->
<xsl:template name="package-document">
    <!-- Must be XML, UTF-8/16            -->
    <!-- Required on package: version, id -->
    <!-- Trying with no encoding, Gitden rejects? -->
    <exsl:document href="{$content-dir}/{$package-file}" method="xml" omit-xml-declaration="yes" indent="no">
        <package xmlns="http://www.idpf.org/2007/opf"
                 unique-identifier="{$uid-string}" version="3.0">
            <xsl:call-template name="package-metadata" />
            <xsl:call-template name="package-manifest" />
            <xsl:call-template name="package-spine" />
        </package>
    </exsl:document>
</xsl:template>

<!-- Honest to goodness metadata, no attributes     -->
<!-- Required first child of  package  element      -->
<!-- Required: dc:identifier, dc:title, dc:language -->
<!-- TODO: add publisher etc from Dublin Core           -->
<!-- TODO: see rights info handling in FCLA EPUB sample -->
<xsl:template name="package-metadata">
    <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns="http://www.idpf.org/2007/opf">
        <!-- Optional in EPUB 3.0.1 spec -->
        <xsl:for-each select="$document-root//frontmatter/titlepage/author|$document-root//frontmatter/titlepage/editor">
            <xsl:element name="dc:creator">
                <xsl:apply-templates select="personname"/>
            </xsl:element>
        </xsl:for-each>
        <!-- Required in EPUB 3.0.1 spec       -->
        <!-- TODO: title-types can refine this -->
        <xsl:element name="dc:title">
            <xsl:apply-templates select="$document-root" mode="title-full" />
        </xsl:element>
        <!-- Required in EPUB 3.0.1 spec                -->
        <!-- Repeatable and more complicated, see spec  -->
        <!-- id must match attribute on package element -->
        <xsl:element name="dc:identifier">
            <xsl:attribute name="id">
                <xsl:value-of select="$uid-string" />
            </xsl:attribute>
            <xsl:value-of select="$mock-UUID" />
        </xsl:element>
        <!-- Required in EPUB 3.0.1 spec         -->
        <!-- Also needed for Kindle conversion   -->
        <!-- Codes according to RFC5646,         -->
        <!-- our double form, eg en-US, seems OK -->
        <xsl:element name="dc:language">
            <xsl:value-of select="$document-language" />
        </xsl:element>
        <!-- Required in EPUB 3.0.1 spec    -->
        <!-- Drop time zone, replace with Z -->
        <!-- This is then a mild fiction    -->
        <xsl:element name="meta">
            <xsl:attribute name="property">
                <xsl:text>dcterms:modified</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="substring(date:date-time(),1,19)" />
            <xsl:text>Z</xsl:text>
        </xsl:element>
    </metadata>
</xsl:template>

<!-- manifest element required as second element of package    -->
<!-- a list of empty  item  elements (order unimportant),      -->
<!-- Each item has                                             -->
<!--    Required: id, for spine ordering                       -->
<!--    Required: href, absolute or relative                   -->
<!--    Required: media-type, critical (see PNG/JPG for cover) -->
<!-- Exactly one item has the "nav" property                   -->
<xsl:template name="package-manifest">
    <!-- cruise all objects within source via modal template -->
    <!-- relevant objects report themselves and then recurse -->
    <!-- create as a legitimate node-set for post-filtering  -->
    <xsl:variable name="discovery">
        <xsl:apply-templates select="$document-root" mode="manifest"/>
    </xsl:variable>
    <xsl:variable name="discovery-manifest" select="exsl:node-set($discovery)"/>
    <!-- start "manifest" with one-off items -->
    <manifest xmlns="http://www.idpf.org/2007/opf">
        <item id="css-addon"  href="{$css-dir}/pretext_add_on.css"    media-type="text/css"/>
        <item id="css-style"  href="{$css-dir}/{$html-css-stylefile}" media-type="text/css"/>
        <item id="css-color"  href="{$css-dir}/{$html-css-colorfile}" media-type="text/css"/>
        <item id="css-setclr" href="{$css-dir}/setcolors.css"         media-type="text/css"/>
        <xsl:choose>
            <xsl:when test="$b-kindle">
                <item id="css-kindle" href="{$css-dir}/kindle.css"            media-type="text/css"/>
            </xsl:when>
            <xsl:otherwise>
                <item id="css-epub" href="{$css-dir}/epub.css"            media-type="text/css"/>
            </xsl:otherwise>
        </xsl:choose>
        <item id="cover-page" href="{$xhtml-dir}/cover-page.xhtml" media-type="application/xhtml+xml"/>
        <item id="table-contents"
              href="{$xhtml-dir}/table-contents.xhtml"
              media-type="application/xhtml+xml">
            <!-- TODO: If the TOC expands to include more than -->
            <!-- chapter and appendix, this will need revision. -->
            <xsl:attribute name="properties">
                <xsl:choose>
                    <xsl:when test="$document-root//chapter/title/m or
                                    $document-root//appendix/title/m">
                        <xsl:choose>
                            <xsl:when test="$math.format = 'mml' or
                                            $math.format = 'kindle'">
                                <xsl:text>nav mathml</xsl:text>
                            </xsl:when>
                            <xsl:when test="$math.format = 'svg'">
                                <xsl:text>nav svg</xsl:text>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>nav</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </item>
        <item id="cover-image" href="{$xhtml-dir}/{$cover-filename}" properties="cover-image">
            <xsl:attribute name="media-type">
                <xsl:variable name="extension">
                    <xsl:call-template name="file-extension">
                        <xsl:with-param name="filename" select="$cover-filename" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$extension='png'">
                        <xsl:text>image/png</xsl:text>
                    </xsl:when>
                    <xsl:when test="$extension='jpeg' or $extension='jpg'">
                        <xsl:text>image/jpeg</xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:attribute>
        </item>
        <!-- cruise found objects, including comments we generate to help debug       -->
        <!-- NB: * could be just "item", but we generally want all elements           -->
        <!-- Strategy: compare @href of each candidate item with the @href of each    -->
        <!-- preceding item, and only copy into the result tree if the @href is "new" -->
        <!-- Duplication removal inspired by:                                         -->
        <!-- XSLT Cookbook, 2nd Edition, Copyright 2006, O'Reilly Media, Inc.         -->
        <!-- Recipe 5.1, Ignoring Duplicate Elements                                  -->
        <!-- www.oreilly.com/library/view/xslt-cookbook/0596003722/ch04s03.html       -->
        <xsl:for-each select="($discovery-manifest/*|$discovery-manifest/comment())[not(@href = preceding::*/@href)]">
            <xsl:copy-of select="."/>
        </xsl:for-each>
        <xsl:if test="$b-has-endnotes">
            <item id="endnotes" href="{$xhtml-dir}/{$endnote-file}"
                  media-type="application/xhtml+xml">
                <xsl:if test="$b-endnotes-have-math">
                    <xsl:attribute name="properties">
                        <xsl:choose>
                            <xsl:when test="$math.format = 'mml' or
                                            $math.format = 'kindle'">
                                <xsl:text>mathml</xsl:text>
                            </xsl:when>
                            <xsl:when test="$math.format = 'svg'">
                                <xsl:text>svg</xsl:text>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:attribute>
                </xsl:if>
            </item>
        </xsl:if>
    </manifest>
</xsl:template>

<!-- Traverse elements only in subtree, looking for   -->
<!-- items that will be files to list in the manifest -->
<xsl:template match="*" mode="manifest">
    <xsl:apply-templates select="*" mode="manifest" />
</xsl:template>

<!-- Build an empty item element for each CHAPTER, -->
<!-- FRONTMATTER, BACKMATTER, -->
<!-- Don't include "backmatter", all summary       -->
<!-- recurse into contents for image files, etc    -->
<!-- See "Core Media Type Resources"               -->
<!-- Add to spine identically                      -->
<!-- Specialized divisions are terminal in back    -->
<!-- matter, and only a seperate file when within  -->
<!-- a "chapter", at level 2                       -->
<xsl:template match="frontmatter|colophon|biography|dedication|acknowledgement|preface|chapter|chapter/conclusion|chapter/outcomes[preceding-sibling::section]|appendix|index|section|exercises|chapter/solutions|appendix/solutions|backmatter/solutions|chapter/references|appendix/references|backmatter/references" mode="manifest">
    <!-- Annotate manifest entries -->
    <xsl:comment>
        <xsl:apply-templates select="." mode="long-name" />
    </xsl:comment>
    <!-- one  item  element per chapter -->
    <xsl:element name="item" xmlns="http://www.idpf.org/2007/opf">
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="html-id" />
        </xsl:attribute>
        <!-- properties are iff, so validator complains if extra -->
        <!-- condition on math presence for svg/mathml property  -->
        <!-- TODO: use a parameter switch for output style       -->
        <!-- Study: https://github.com/w3c/epubcheck/issues/420  -->
        <!-- Processing with page2svg makes it appear SVG images exist -->
        <!-- Set properties="svg" or properties="mathml" when a -->
        <!-- file contains math in one of thse formats. -->
        <!-- There are simply too many edge cases to do this -->
        <!-- based on document structure alone, so read the actual -->
        <!-- XHTML files we've already written and look for svg -->
        <!-- or math tags in them. -->
        <xsl:variable name="has-math">
            <xsl:variable name="contents-filename">
                <xsl:value-of select="$tmpdir" />
                <xsl:text>/</xsl:text>
                <xsl:value-of select="$content-dir" />
                <xsl:text>/</xsl:text>
                <xsl:value-of select="$xhtml-dir" />
                <xsl:text>/</xsl:text>
                <xsl:apply-templates select="."
                                     mode="containing-filename"/>
            </xsl:variable>
            <xsl:variable name="filedata"
                          select="document($contents-filename)"/>
            <xsl:choose>
                <xsl:when test="$filedata//svg:svg|$filedata//math:math">
                    <xsl:text>true</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>false</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="b-has-math" select="$has-math = 'true'" />
        <xsl:if test="$b-has-math">
            <xsl:attribute name="properties">
                <xsl:choose>
                    <xsl:when test="$math.format = 'mml' or $math.format = 'kindle'">
                        <xsl:text>mathml</xsl:text>
                    </xsl:when>
                    <xsl:when test="$math.format = 'svg'">
                        <xsl:text>svg</xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:attribute>
        </xsl:if>
        <!-- TODO: coordinate with manifest/script on xhtml extension -->
        <xsl:attribute name="href">
            <xsl:value-of select="$xhtml-dir" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select="." mode="containing-filename" />
        </xsl:attribute>
        <xsl:attribute name="media-type">
            <xsl:text>application/xhtml+xml</xsl:text>
        </xsl:attribute>
    </xsl:element>
    <!-- recurse, eg from chapter down into a section -->
    <xsl:apply-templates select="*" mode="manifest" />
</xsl:template>

<!-- How the files are organized into the spine  -->
<!-- Book opens to first time linear="no"        -->
<!-- Each must reference an id in the manifest   -->
<xsl:template name="package-spine">
    <spine xmlns="http://www.idpf.org/2007/opf">
        <itemref idref="table-contents" linear="yes"/>
        <itemref idref="cover-page" linear="yes" />
        <xsl:apply-templates select="$document-root" mode="spine" />
        <itemref idref="endnotes" linear="no" />
    </spine>
</xsl:template>

<!-- Traverse subtree, looking for items to include  -->
<xsl:template match="*" mode="spine">
    <xsl:apply-templates select="*" mode="spine" />
</xsl:template>

<!-- Simplest scenario is spine matches manifest, all with @linear="yes" -->
<!-- Specialized divisions will only become files in the manifest at     -->
<!-- chunk level 2, in other words, peers of chapters or sections        -->
<!-- (book or chapter/appendix as parent, respectively)                  -->
<xsl:template match="frontmatter|colophon|acknowledgement|biography|dedication|preface|chapter|appendix|index|section|exercises[parent::book|parent::chapter|parent::appendix]|reading-questions[parent::book|parent::chapter|parent::appendix]|chapter/solutions|appendix/solutions|backmatter/solutions|chapter/references|appendix/references|backmatter/references|glossary[parent::book|parent::chapter|parent::appendix]|conclusion[parent::chapter]|outcomes[preceding-sibling::section]" mode="spine">
    <xsl:element name="itemref" xmlns="http://www.idpf.org/2007/opf">
        <xsl:attribute name="idref">
            <xsl:apply-templates select="." mode="html-id" />
        </xsl:attribute>
        <xsl:attribute name="linear">
            <xsl:text>yes</xsl:text>
        </xsl:attribute>
    </xsl:element>
    <xsl:apply-templates select="*" mode="spine" />
</xsl:template>

<!-- This template writes out some information necessary     -->
<!-- for successful organization of the necessary files to   -->
<!-- make a complete package for the eventual EPUB.  This is -->
<!-- the actual output of the stylesheet itself.  There is   -->
<!-- no namespace information, so when the Python script     -->
<!-- gets this, there is no need for any namespace           -->
<!-- provisions with the  lxml  library.                     -->
<!--                                                         -->
<!-- Each image filename is a legitimate image in use in the -->
<!-- EPUB XHTML, but the filename may be duplicated is used  -->
<!-- more than once.  That is OK, the only inefficiency is   -->
<!-- that it will simply be copied onto itself.              -->
<xsl:template name="packaging-info">
    <packaging>
        <filename>
            <!-- for actual EPUB file eventually output -->
            <xsl:apply-templates select="$document-root" mode="title-filesafe"/>
        </filename>
        <cover filename="{$cover-filename}"/>
        <css stylefile="{$html-css-stylefile}" colorfile="{$html-css-colorfile}"/>
        <!-- Decide what to do with preview images, etc. -->
        <images>
            <xsl:for-each select="$document-root//image">
                <image>
                    <!-- filename begins with directories from publisher file -->
                    <xsl:attribute name="sourcename">
                        <xsl:apply-templates select="." mode="epub-base-filename">
                            <xsl:with-param name="purpose" select="'read'"/>
                        </xsl:apply-templates>
                    </xsl:attribute>
                    <xsl:attribute name="filename">
                        <xsl:apply-templates select="." mode="epub-base-filename">
                            <xsl:with-param name="purpose" select="'write'"/>
                        </xsl:apply-templates>
                    </xsl:attribute>
                </image>
            </xsl:for-each>
        </images>
    </packaging>
</xsl:template>

<!-- MathJax CSS, which is placed on enclosing span elements      -->
<!--   mjpage:        for all math, so only class on online math  -->
<!--   mjpage__block: for display math, so additional on "md" etc -->
<!-- Removed as EPUB 3.0 violation: .mjpage direction: ltr;       -->
<xsl:template name="mathjax-css">
<style type="text/css">
.mjpage .MJX-monospace {
font-family: monospace
}

.mjpage .MJX-sans-serif {
font-family: sans-serif
}

.mjpage {
display: inline;
font-style: normal;
font-weight: normal;
line-height: normal;
font-size: 100%;
font-size-adjust: none;
text-indent: 0;
text-align: left;
text-transform: none;
letter-spacing: normal;
word-spacing: normal;
word-wrap: normal;
white-space: nowrap;
float: none;
max-width: none;
max-height: none;
min-width: 0;
min-height: 0;
border: 0;
padding: 0;
margin: 0
}

.mjpage * {
transition: none;
-webkit-transition: none;
-moz-transition: none;
-ms-transition: none;
-o-transition: none
}

.mjx-svg-href {
fill: blue;
stroke: blue
}

.MathJax_SVG_LineBox {
display: table!important
}

.MathJax_SVG_LineBox span {
display: table-cell!important;
width: 10000em!important;
min-width: 0;
max-width: none;
padding: 0;
border: 0;
margin: 0
}

.mjpage__block {
text-align: center;
margin: 1em 0em;
position: relative;
display: block!important;
text-indent: 0;
max-width: none;
max-height: none;
min-width: 0;
min-height: 0;
width: 100%
}
</style>
</xsl:template>

<!-- Include the appropriate CSS file depending on output -->
<xsl:template name="epub-kindle-css">
    <xsl:choose>
        <xsl:when test="$b-kindle">
            <link href="../{$css-dir}/kindle.css" rel="stylesheet" type="text/css"/>
        </xsl:when>
        <xsl:otherwise>
            <link href="../{$css-dir}/epub.css" rel="stylesheet" type="text/css"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############# -->
<!-- Content files -->
<!-- ############# -->

<xsl:template match="frontmatter" mode="epub">
    <exsl:document href="{$content-dir}/{$xhtml-dir}/cover-page.xhtml" method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="no">
        <html>
            <!-- head element should not be empty -->
            <head>
                <meta charset="utf-8"/>
                <title>
                    <xsl:apply-templates select="$document-root" mode="title-full"/>
                </title>
                <xsl:call-template name="mathjax-css"/>
            </head>
            <body class="pretext-content epub">
                <!-- https://www.opticalauthoring.com/inside-the-epub-format-the-cover-image/   -->
                <!-- says the "figure" is necessary, and does not seem to hurt (CSS could style)-->
                <figure>
                    <img src="{$cover-filename}"/>
                </figure>
            </body>
        </html>
    </exsl:document>
    <exsl:document href="{$content-dir}/{$xhtml-dir}/table-contents.xhtml" method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="no">
        <html xmlns:epub="http://www.idpf.org/2007/ops">
            <head>
                <meta charset="utf-8"/>
                <link href="../{$css-dir}/pretext_add_on.css"    rel="stylesheet" type="text/css"/>
                <link href="../{$css-dir}/{$html-css-stylefile}" rel="stylesheet" type="text/css"/>
                <link href="../{$css-dir}/{$html-css-colorfile}" rel="stylesheet" type="text/css"/>
                <link href="../{$css-dir}/setcolors.css"         rel="stylesheet" type="text/css"/>
                <xsl:call-template name="mathjax-css"/>
                <xsl:call-template name="epub-kindle-css"/>
                <title>Table of Contents</title>
            </head>
            <body class="pretext-content epub" epub:type="frontmatter">
                <nav epub:type="toc" id="toc">
                    <h1>Table of Contents</h1>
                    <ol>
                        <xsl:for-each select="$document-root/chapter">
                            <li>
                                <xsl:element name="a">
                                    <xsl:attribute name="href">
                                        <xsl:apply-templates select="." mode="containing-filename" />
                                    </xsl:attribute>
                                    <xsl:apply-templates select="." mode="title-simple" />
                                </xsl:element>
                            </li>
                        </xsl:for-each>
                        <xsl:if test="$document-root/backmatter/appendix|$document-root/backmatter/solutions">
                            <li class="no-marker">
                                <span>Appendices</span>
                                <ol type="A">
                                    <xsl:for-each select="$document-root/backmatter/appendix|$document-root/backmatter/solutions">
                                        <li>
                                            <xsl:element name="a">
                                                <xsl:attribute name="href">
                                                    <xsl:apply-templates select="." mode="containing-filename" />
                                                </xsl:attribute>
                                                <xsl:apply-templates select="." mode="title-simple" />
                                            </xsl:element>
                                        </li>
                                    </xsl:for-each>
                                </ol>
                            </li>
                        </xsl:if>
                        <xsl:for-each select="$document-root/backmatter/references|$document-root/backmatter/index">
                            <li class="no-marker">
                                <xsl:element name="a">
                                    <xsl:attribute name="href">
                                        <xsl:apply-templates select="." mode="containing-filename" />
                                    </xsl:attribute>
                                    <xsl:apply-templates select="." mode="title-simple" />
                                </xsl:element>
                            </li>
                        </xsl:for-each>
                    </ol>
                </nav>
            </body>
        </html>
    </exsl:document>
</xsl:template>

<!-- An abstract named template accepts input text and   -->
<!-- output text, then wraps it for the Sage Cell Server -->
<xsl:template match="sage" mode="sage-active-markup">
    <xsl:param name="in" />
    <xsl:param name="out" />
    <xsl:if test="$in!=''">
        <pre class="code input">
            <xsl:value-of select="$in" />
        </pre>
    </xsl:if>
    <xsl:if test="$out!=''">
        <pre class="code output">
            <xsl:value-of select="$out" />
        </pre>
    </xsl:if>
</xsl:template>

<!-- An abstract named template accepts input text   -->
<!-- and provides the display class, so untouchable  -->
<xsl:template name="sage-display-markup">
    <xsl:param name="in" />
    <xsl:if test="$in!=''">
        <pre>
            <xsl:value-of select="$in" />
        </pre>
    </xsl:if>
</xsl:template>

<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- We assume each image is a raster image or an SVG -->
<!-- Raster:      @source has an extension (eg PNG)   -->
<!-- Vector/SVG:  @source, no extension               -->
<!-- Code:        eg image/asymptote                  -->
<!-- Need to add to manifest accurately,              -->
<!-- and also include into source                     -->

<!-- Base filename for an image,  -->
<!-- mostly handling the @source case -->

<!-- Parametrized by "read": -->
<!-- 'read' produces path to source file in input folder tree -->
<!-- 'write' produces path to file in output folder tree      -->
<xsl:template match="image" mode="epub-base-filename">
    <xsl:param name="purpose"/>

    <xsl:choose>
        <xsl:when test="@source">
            <xsl:variable name="extension">
                <xsl:call-template name="file-extension">
                    <xsl:with-param name="filename" select="@source" />
                </xsl:call-template>
            </xsl:variable>
            <!-- PDF LaTeX, SVG HTML, PNG Kindle if not indicated -->
            <xsl:choose>
                <xsl:when test="$purpose = 'read'">
                    <xsl:value-of select="$external-directory-source"/>
                </xsl:when>
                <xsl:when test="$purpose = 'write'">
                    <xsl:value-of select="$external-directory"/>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="@source" />
            <xsl:if test="$extension=''">
                <xsl:choose>
                    <xsl:when test="$b-kindle">
                        <xsl:text>.png</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>.svg</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:when>
        <xsl:when test="latex-image|sageplot|asymptote">
            <xsl:choose>
                <xsl:when test="$purpose = 'read'">
                    <xsl:value-of select="$generated-directory-source"/>
                </xsl:when>
                <xsl:when test="$purpose = 'write'">
                    <xsl:value-of select="$generated-directory"/>
                </xsl:when>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="latex-image">
                    <xsl:text>latex-image</xsl:text>
                </xsl:when>
                <xsl:when test="sageplot">
                    <xsl:text>sageplot</xsl:text>
                </xsl:when>
                <xsl:when test="asymptote">
                    <xsl:text>asymptote</xsl:text>
                </xsl:when>
            </xsl:choose>
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select="." mode="visible-id" />
            <xsl:choose>
                <xsl:when test="$b-kindle">
                    <xsl:text>.png</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>.svg</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG:     image filename not determined in EPUB conversion</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Manifest entry with image file information -->
<!-- For each "image" we record basic information in the form the  -->
<!-- manifest expects (an "item").  Later, duplicate files will be -->
<!-- scrubbed from this list based on the @href value, so a given  -->
<!-- file is not referenced twice in the manifest.                 -->
<!-- TODO: Missing video posters, interactive screenshots, QR codes -->
<xsl:template match="image" mode="manifest">
    <xsl:variable name="extension">
        <xsl:call-template name="file-extension">
            <xsl:with-param name="filename" select="@source" />
        </xsl:call-template>
    </xsl:variable>
    <!-- item  element for manifest -->
    <xsl:element name="item" namespace="http://www.idpf.org/2007/opf">
        <!-- internal id of the image -->
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="html-id" />
        </xsl:attribute>
        <!-- filename relative to EPUB directory -->
        <xsl:attribute name="href">
            <xsl:value-of select="$xhtml-dir" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select="." mode="epub-base-filename">
                <xsl:with-param name="purpose" select="'write'"/>
            </xsl:apply-templates>
        </xsl:attribute>
        <!-- media attribute -->
        <xsl:attribute name="media-type">
            <xsl:choose>
                <xsl:when test="@source and $extension='png'">
                    <xsl:text>image/png</xsl:text>
                </xsl:when>
                <xsl:when test="@source and ($extension='jpeg' or $extension='jpg')">
                    <xsl:text>image/jpeg</xsl:text>
                </xsl:when>
                <xsl:when test="@source and ($extension='svg' or $extension='')">
                    <xsl:text>image/svg+xml</xsl:text>
                </xsl:when>
                <xsl:when test="latex-image|sageplot|asymptote">
                    <xsl:text>image/svg+xml</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:BUG:     EPUB image media-type not determined</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:element>
    <!-- likely a dead-end here, but we examine children anyway -->
    <xsl:apply-templates select="*" mode="manifest" />
</xsl:template>

<!-- Now the actual image inclusion where born -->
<xsl:template match="image">
    <xsl:element name="img">
        <xsl:attribute name="src">
            <xsl:apply-templates select="." mode="epub-base-filename">
                <xsl:with-param name="purpose" select="'write'"/>
            </xsl:apply-templates>
        </xsl:attribute>
        <xsl:if test="@width">
            <xsl:attribute name="style">
                <xsl:text>width: </xsl:text>
                <xsl:value-of select="@width" />
                <xsl:text>; margin: 0 auto;</xsl:text>
            </xsl:attribute>
        </xsl:if>
    </xsl:element>
</xsl:template>

<!-- ######### -->
<!-- OverRides -->
<!-- ######### -->

<!-- Knowls -->
<!-- Nothing should be knowled, since we do not have Javascript for it -->
<!-- We kill both cross-reference and born-hidden knowls by overriding -->
<!-- templates designed partially for this purpose                     -->
<xsl:template match="*" mode="xref-as-knowl">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- Everything configurable by author, 2020-01-02         -->
<!-- Roughly in the order of old  html.knowl.*  switches   -->
<!-- Similar HTML templates return string for boolean test -->
<xsl:template match="&THEOREM-LIKE;|proof|&DEFINITION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|task|&FIGURE-LIKE;|&REMARK-LIKE;|&GOAL-LIKE;|exercise" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>


<!-- ######## -->
<!-- Endnotes -->
<!-- ######## -->

<!-- Use "EPUB 3 Structural Semantics Vocabulary" -->
<!-- to get desired behavior from e-reader system -->
<!-- https://help.apple.com/itc/booksassetguide/en.lproj/itccf8ecf5c8.html -->

<!-- Note: Kindle wants "bidirectional" links, so you can "go back" -->
<!-- from the content to the source location.  These HTML ids are   -->
<!-- recognizable by their "-kindle-return" suffix.  See 10.3.12:   -->
<!-- https://kindlegen.s3.amazonaws.com/AmazonKindlePublishingGuidelines.pdf -->

<!-- Asides and hints -->
<!-- EPUB has a semi-natural mechanism for this, though -->
<!-- the text we drop could use some work. The marker,  -->
<!-- a simple title/paragraph, tostyle minimally        -->
<xsl:template match="&ASIDE-LIKE;|hint">
    <xsl:variable name="hid">
        <xsl:apply-templates select="." mode="html-id" />
    </xsl:variable>
    <p>
        <a class="url" epub:type="noteref" href="{$endnote-file}#{$hid}">
            <!-- Older Kindles don't always support pop-ups, so -->
            <!-- create infrastructure for endnotes to jump back-->
            <xsl:if test="$b-kindle">
                <xsl:attribute name="id">
                    <xsl:value-of select="$hid"/>
                    <xsl:text>-kindle-return</xsl:text>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="." mode="heading-simple" />
        </a>
    </p>
</xsl:template>

<!-- The content, unwrapped from HTML infrastructure -->
<xsl:template match="&ASIDE-LIKE;|hint" mode="endnote-content">
    <xsl:variable name="hid">
        <xsl:apply-templates select="." mode="html-id" />
    </xsl:variable>
    <!-- Older Kindles don't always support pop-ups, so -->
    <!-- create infrastructure for endnotes to jump back-->
    <xsl:if test="$b-kindle">
        <a epub:type="noteref">
            <xsl:attribute name="href">
                <xsl:apply-templates select="." mode="containing-filename"/>
                <xsl:text>#</xsl:text>
                <xsl:value-of select="$hid"/>
                <xsl:text>-kindle-return</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates select="." mode="heading-full"/>
        </a>
    </xsl:if>
    <aside epub:type="footnote" id="{$hid}">
        <!-- mode="body" gets too much CSS -->
        <xsl:apply-templates select="." mode="wrapped-content"/>
    </aside>
</xsl:template>

<!-- Footnotes -->
<!-- First disable the "footnote" popping routine used to -->
<!-- move the content out of HTML structures where it is  -->
<!-- not welcome (e.g a "p" inside a "p").                -->
<xsl:template match="*" mode="pop-footnote-text"/>

<!-- Drop a marker as a superscript -->
<xsl:template match="fn">
    <xsl:variable name="hid">
        <xsl:apply-templates select="." mode="html-id" />
    </xsl:variable>
    <!-- drop cross-reference, super-scripted, spaced -->
    <xsl:element name="sup">
        <a epub:type="noteref" href="{$endnote-file}#{$hid}">
            <xsl:if test="$b-kindle">
                <xsl:attribute name="id">
                    <xsl:value-of select="$hid"/>
                    <xsl:text>-kindle-return</xsl:text>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="." mode="serial-number" />
        </a>
    </xsl:element>
</xsl:template>

<!-- The content. -->
<xsl:template match="fn" mode="endnote-content">
    <xsl:variable name="hid">
        <xsl:apply-templates select="." mode="html-id" />
    </xsl:variable>
    <aside epub:type="footnote" id="{$hid}">
        <xsl:choose>
            <xsl:when test="$b-kindle">
                <a epub:type="noteref">
                    <xsl:attribute name="href">
                        <xsl:apply-templates select="." mode="containing-filename"/>
                        <xsl:text>#</xsl:text>
                        <xsl:value-of select="$hid"/>
                        <xsl:text>-kindle-return</xsl:text>
                    </xsl:attribute>
                    <xsl:apply-templates select="." mode="serial-number"/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="serial-number"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>. </xsl:text>
        <!-- process as mixed-content, don't yet allow paragraphs -->
        <xsl:apply-templates select="node()" />
    </aside>
</xsl:template>

<!-- BackMatter Endnotes page -->
<xsl:template name="endnotes">
    <!-- No footnotes or asides, don't bother -->
    <xsl:if test="$b-has-endnotes">
        <!-- cribbed from "file-wrap" elsewhere -->
        <exsl:document href="{$content-dir}/{$xhtml-dir}/{$endnote-file}" method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="no">
            <html>
                <head>
                    <xsl:text>&#xa;</xsl:text> <!-- a little formatting help -->
                    <xsl:call-template name="converter-blurb-html" />
                    <link href="../{$css-dir}/pretext_add_on.css"    rel="stylesheet" type="text/css"/>
                    <link href="../{$css-dir}/{$html-css-stylefile}" rel="stylesheet" type="text/css"/>
                    <link href="../{$css-dir}/{$html-css-colorfile}" rel="stylesheet" type="text/css"/>
                    <link href="../{$css-dir}/setcolors.css"         rel="stylesheet" type="text/css"/>
                    <xsl:call-template name="mathjax-css"/>
                    <xsl:call-template name="epub-kindle-css"/>
                    <title>Endnotes</title>
                </head>
                <!-- use class to repurpose HTML CSS work -->
                <body class="pretext-content epub">
                    <h4>Endnotes</h4>
                    <!-- structure according to footnote level -->
                    <xsl:apply-templates select="$document-root//fn|$document-root//aside|$document-root//biographical|$document-root//historical|$document-root//hint" mode="endnote-content"/>
                </body>
            </html>
        </exsl:document>
    </xsl:if>
</xsl:template>


<!-- ################ -->
<!-- Subsidiary Items -->
<!-- ################ -->

<!-- These tend to "hang" off other structures and/or are routinely -->
<!-- rendered as knowls.  So we turn off automatic knowlization     -->
<xsl:template match="&SOLUTION-LIKE;" mode="is-hidden">
    <xsl:text>false</xsl:text>
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

<!-- #### -->
<!-- Math -->
<!-- #### -->

<!-- Pluck SVGs from the file full of them, with matching IDs -->
<xsl:template match="m|me|men|md|mdn">
    <xsl:variable name="id">
        <xsl:apply-templates select="." mode="html-id"/>
    </xsl:variable>
    <xsl:variable name="math" select="$math-repr/pi:math[@id = $id]"/>
    <xsl:variable name="context" select="string($math/@context)"/>
    <!-- <xsl:message>C:<xsl:value-of select="$math/@context"/>:C</xsl:message> -->
    <!-- <xsl:copy-of select="$math-repr[../@id = $id]"/> -->
    <span>
        <xsl:attribute name="class">
            <xsl:choose>
                <xsl:when test="$context = 'm'">
                    <xsl:text>mjpage</xsl:text>
                </xsl:when>
                <xsl:when test="($context = 'me') or ($context = 'men') or ($context = 'md') or ($context = 'mdn')">
                    <xsl:text>mjpage mjpage__block</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:attribute>
        <!-- Can only "xref" to an "men" or an "md/mrow" or an "mdn/mrow" -->
        <xsl:if test="$context = 'men' or $context = 'md' or $context = 'mdn'">
            <xsl:attribute name="id">
              <xsl:text>mjx-eqn:</xsl:text><xsl:value-of select="$id"
              />
            </xsl:attribute>
        </xsl:if>
        <!-- Finally, drop a "svg" element, "math" element, or ASCII speech -->
        <xsl:choose>
            <xsl:when test="$math.format = 'svg'">
                <xsl:apply-templates select="$math/div[@class = 'svg']/svg:svg" mode="svg-edit"/>
            </xsl:when>
            <xsl:when test="$math.format = 'mml'">
                <xsl:copy-of select="$math/div[@class = 'mathml']/math:math"/>
            </xsl:when>
            <!-- Kindle does best with MathML format -->
            <xsl:when test="$b-kindle">
                <xsl:copy-of select="$math/div[@class = 'mathml']/math:math"/>
            </xsl:when>
            <!-- 2020-07-17: reprs needed a new "span.speech" wrapper -->
            <xsl:when test="$math.format = 'speech'">
                <xsl:value-of select="$math/div[@class = 'speech']"/>
            </xsl:when>
        </xsl:choose>
    </span>
</xsl:template>

<!-- This is copied from pretext-html.xsl where it has    -->
<!-- match="*". We just need to contend with mrow in EPUB -->
<!-- since we can't control the ID MathJax returns.       -->
<xsl:template match="mrow" mode="url">
    <!-- An enclosing "md" or "mdn" is never a division, so     -->
    <!-- there will always be a containing file and a fragment  -->
    <!-- identifier (unlike teh more general version in -html). -->
    <xsl:apply-templates select="." mode="containing-filename" />
    <xsl:text>#</xsl:text>
    <!-- the ids on equations are manufactured -->
    <!-- by MathJax to look this way -->
    <xsl:text>mjx-eqn:</xsl:text>
    <!-- This is the main difference from the * template in      -->
    <!-- -html. We can only control the HTML id on the enclosing -->
    <!-- md or mdn, so we get its ID for the hyperlink.          -->
    <xsl:apply-templates select="parent::*" mode="html-id" />
</xsl:template>

<!-- Simple text representations of structural elements for -->
<!-- head/title, which is really restrictive.               -->
<xsl:template match="*" mode="type-name-number">
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<!-- Identity template as a mode coursing through SVGs  -->
<!-- We are stream editing to satisfy the EPUB standard -->
<!-- Mostly killing attrributes                         -->
<xsl:template match="node()|@*" mode="svg-edit">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="svg-edit"/>
    </xsl:copy>
</xsl:template>

<!-- SVG attributes to remove -->
<!-- epubcheck 4.0.2 complains about these for EPUB 3.0.1 -->
<!-- Each match appears to be once per math-SVG           -->
<xsl:template match="svg:svg/@focusable|svg:svg/@role|svg:svg/@aria-labelledby" mode="svg-edit"/>
<!-- Per-image, when fonts are included -->
<xsl:template match="svg:svg/svg:defs/@aria-hidden" mode="svg-edit"/>
<!-- Per-font-cache, when fonts are consolidated -->
<xsl:template match="svg:svg/svg:g/@aria-hidden" mode="svg-edit"/>

<!-- Uncomment to test inline image behavior -->
<!-- 
<xsl:template match="img">
    <img src="{@src}" style="width:8ex;"/>
</xsl:template>
 -->
</xsl:stylesheet>
