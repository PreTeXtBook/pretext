<?xml version='1.0'?> <!-- As XML file -->
<!-- http://stackoverflow.com/questions/10173139/empty-blank-namespace-declarations-being-generated-within-result-document -->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xmlns:exsl="http://exslt.org/common"
                xmlns:date="http://exslt.org/dates-and-times"
                extension-element-prefixes="exsl date">

<!-- Trade on HTML markup, numbering, chunking, etc. -->
<!-- Override as pecularities of EPUB conversion arise -->
<xsl:import href="./mathbook-common.xsl" />
<xsl:import href="./mathbook-html.xsl" />

<!-- TODO: free chunking level -->
<!-- TODO: liberate GeoGebra, videos -->
<!-- TODO: style Sage display-only code in a similar padded box -->

<!-- Knowls do not function in an ePub,       -->
<!-- so no content should be born hidden      -->
<!-- TODO: enable turning off xrefs as knowls -->
<xsl:param name="html.knowl.theorem" select="'no'" />
<xsl:param name="html.knowl.proof" select="'no'" />
<xsl:param name="html.knowl.definition" select="'no'" />
<xsl:param name="html.knowl.example" select="'no'" />
<xsl:param name="html.knowl.remark" select="'no'" />
<xsl:param name="html.knowl.figure" select="'no'" />
<xsl:param name="html.knowl.table" select="'no'" />
<xsl:param name="html.knowl.exercise" select="'no'" />

<!-- Hints, solutions, etc are typically knowled   -->
<!-- We temporarily kill them all as a convenience -->
<xsl:param name="exercise.text.statement" select="'yes'" />
<xsl:param name="exercise.text.hint" select="'no'" />
<xsl:param name="exercise.text.answer" select="'no'" />
<xsl:param name="exercise.text.solution" select="'no'" />
<!-- Second, an exercise in a solutions list in backmatter.-->
<xsl:param name="exercise.backmatter.statement" select="'no'" />
<xsl:param name="exercise.backmatter.hint" select="'no'" />
<xsl:param name="exercise.backmatter.answer" select="'no'" />
<xsl:param name="exercise.backmatter.solution" select="'no'" />

<!-- We turn off permalinks on divisions, etc. -->
<xsl:param name="html.permalink"  select="'none'" />

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

<!-- We hard-code the chunking level.  Level 2 is       -->
<!-- the default for books, which we presume throughout -->
<xsl:variable name="chunk-level">
    <xsl:choose>
        <xsl:when test="$root/book/part">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
    </xsl:choose>
</xsl:variable>

<!-- We disable the ToC level to avoid any conflicts with chunk level -->
<xsl:param name="toc.level" select="0" />

<!-- XHTML files as output -->
<xsl:variable name="file-extension" select="'.xhtml'" />


<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">EPUB conversion is experimental and not supported.  In particular,&#xa;the XSL conversion alone is not sufficient to create an EPUB.&#xa;See mathbook/examples/epub/build.sh for more information.</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="mathbook" mode="deprecation-warnings" />
    <xsl:call-template name="setup" />
    <xsl:call-template name="build-image-list" />
    <xsl:call-template name="package-document" />
    <xsl:apply-templates />
</xsl:template>

<!-- First, we use the frontmatter element to trigger various necessary files     -->
<!-- We process structural nodes via chunking routine in  xsl/mathbook-common.xsl -->
<!-- This in turn calls specific modal templates defined elsewhere in this file   -->
<xsl:template match="mathbook">
    <xsl:apply-templates select="//frontmatter" mode="epub" />
    <xsl:apply-templates mode="chunking" />
</xsl:template>

<!-- ################ -->
<!-- Structural Nodes -->
<!-- ################ -->

<!-- Read the code and documentation for "chunking" in xsl/mathbook-common.xsl -->


<xsl:template match="&STRUCTURAL;" mode="file-wrap">
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
    <exsl:document href="{$file}" method="xml" encoding="UTF-8" indent="yes">
        <html>
            <head>
                <xsl:text>&#xa;</xsl:text> <!-- a little formatting help -->
                <xsl:call-template name="converter-blurb-html" />
                <link href="../{$css-dir}/pretext-epub.css" rel="stylesheet" type="text/css" />
            </head>
            <body>
                <!-- Keep div wrapper on macros or else indentation  -->
                <!-- blows up, so use sed to clean out               -->
                <xsl:call-template name="latex-macros" />
                <xsl:copy-of select="$content" />
            </body>
        </html>
    </exsl:document>
</xsl:template>

<!-- At level 1, we can just kill book's summary page -->

<!-- The book element gets mined in various ways,            -->
<!-- but the "usual" HTML treatment can/should be thrown out -->
<!-- At fixed level 1, this is a summary page                -->
<!-- Later gives precedence?  So overrides above             -->
<xsl:template match="book" mode="file-wrap" />

<!-- At level 2 we need to capture chapter and appendix -->
<!-- introductions from summary page that is at level 1 -->
<!-- NB: we are missing conclusions here                -->
<!-- NB: copied from mathbook-html.xsl, sans            -->
<!-- the summary links and the conclusion               -->
<xsl:template match="frontmatter|chapter|appendix" mode="summary">
    <!-- location info for debugging efforts -->
    <xsl:apply-templates select="." mode="debug-location" />
    <!-- Heading, div for this structural subdivision -->
    <xsl:variable name="ident">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <section class="{local-name(.)}" id="{$ident}">
        <xsl:apply-templates select="." mode="section-header" />
        <xsl:apply-templates select="author|objectives|introduction|titlepage|abstract" />
        <!-- deleted "nav" and summary links here -->
        <!-- "conclusion" is being missed here    -->
     </section>
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
    <exsl:document href="META-INF/container.xml" method="xml" indent="yes">
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
    <exsl:document href="{$content-dir}/{$package-file}" method="xml" indent="yes">
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
    <manifest xmlns="http://www.idpf.org/2007/opf">
        <item id="css" href="{$css-dir}/pretext-epub.css" media-type="text/css"/>
        <item id="cover" href="{$xhtml-dir}/cover.xhtml" media-type="application/xhtml+xml"/>
        <item id="title-page" href="{$xhtml-dir}/title-page.xhtml" media-type="application/xhtml+xml"/>
        <item id="table-contents" href="{$xhtml-dir}/table-contents.xhtml" properties="nav" media-type="application/xhtml+xml"/>
        <item id="cover-image" href="{$xhtml-dir}/images/cover.png" properties="cover-image" media-type="image/png"/>
        <!-- <item id="cover-image" href="{$xhtml-dir}/images/cover.jpg" properties="cover-image" media-type="image/jpeg"/> -->
        <xsl:apply-templates select="$document-root" mode="manifest" />
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
<xsl:template match="frontmatter|colophon|acknowledgements|preface|chapter|appendix|index|section|exercises|references" mode="manifest">
    <!-- Annotate manifest entries -->
    <xsl:comment>
        <xsl:apply-templates select="." mode="long-name" />
    </xsl:comment>
    <!-- one  item  element per chapter -->
    <xsl:element name="item" xmlns="http://www.idpf.org/2007/opf">
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:attribute>
        <!-- properties are iff, so validator complains if extra -->
        <!-- condition on math presence for svg/mathml property  -->
        <!-- TODO: use a parameter switch for output style       -->
        <!-- Processing with page2svg makes it appear SVG images exist -->
        <!-- <xsl:if test=".//m or .//me or .//men or .//md or .//mdn"> -->
             <xsl:attribute name="properties">
                <xsl:text>svg</xsl:text>
                <!-- <xsl:text>mathml</xsl:text> -->
            </xsl:attribute>
        <!-- </xsl:if> -->
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
    <xsl:apply-templates select="*" mode="manifest" />
</xsl:template>

<!-- How the files are organized into the spine  -->
<!-- Book opens to first time linear="no"        -->
<!-- Each must reference an id in the manifest   -->
<xsl:template name="package-spine">
    <spine xmlns="http://www.idpf.org/2007/opf">
        <itemref idref="cover" linear="yes" />
        <itemref idref="title-page" linear="yes"/>
        <itemref idref="table-contents" linear="yes"/>
        <xsl:apply-templates select="$document-root" mode="spine" />
    </spine>
</xsl:template>

<!-- Traverse subtree, looking for items to include  -->
<xsl:template match="*" mode="spine">
    <xsl:apply-templates select="*" mode="spine" />
</xsl:template>

<!-- Simplest scenario is spine matches manifest, all with @linear="yes" -->
<xsl:template match="frontmatter|colophon|acknowledgements|preface|chapter|appendix|index|section|exercises|references" mode="spine">
    <xsl:element name="itemref" xmlns="http://www.idpf.org/2007/opf">
        <xsl:attribute name="idref">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:attribute>
        <xsl:attribute name="linear">
            <xsl:text>yes</xsl:text>
        </xsl:attribute>
    </xsl:element>
    <xsl:apply-templates select="*" mode="spine" />
</xsl:template>


<!-- ############# -->
<!-- Content files -->
<!-- ############# -->

<xsl:template match="frontmatter" mode="epub">
    <exsl:document href="{$content-dir}/{$xhtml-dir}/cover.xhtml" method="xml" encoding="UTF-8" indent="yes">
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head></head>
            <body>
                <img src="images/cover.png" />
            </body>
        </html>
    </exsl:document>
    <exsl:document href="{$content-dir}/{$xhtml-dir}/title-page.xhtml" method="xml" encoding="UTF-8" indent="yes">
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head></head>
            <body>
                <h1>
                    <xsl:apply-templates select="$document-root" mode="title-full" />
                    <xsl:if test="$document-root/subtitle">
                        <br />
                        <xsl:apply-templates select="$document-root" mode="subtitle" />
                    </xsl:if>
                </h1>
                <h3>
                    <xsl:apply-templates select="titlepage/author/personname" />
                    <br />
                    <xsl:apply-templates select="titlepage/author/institution" />
                </h3>
            </body>
        </html>
    </exsl:document>
    <exsl:document href="{$content-dir}/{$xhtml-dir}/table-contents.xhtml" method="xml" encoding="UTF-8" indent="yes">
        <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
            <head>
                <meta charset="utf-8"/>
            </head>
            <body epub:type="frontmatter">
                <nav epub:type="toc" id="toc">
                    <h1>Table of Contents</h1>
                    <ol>
                        <xsl:for-each select="$document-root/chapter|$document-root/backmatter/appendix|$document-root/backmatter/index">
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
                </nav>
            </body>
        </html>
    </exsl:document>
</xsl:template>

<!-- An abstract named template accepts input text and   -->
<!-- output text, then wraps it for the Sage Cell Server -->
<xsl:template name="sage-active-markup">
    <xsl:param name="in" />
    <xsl:param name="out" />
    <xsl:if test="$in!=''">
        <pre>
            <xsl:value-of select="$in" />
        </pre>
    </xsl:if>
    <xsl:if test="$out!=''">
        <pre>
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
<xsl:template match="image" mode="epub-base-filename">
    <xsl:choose>
        <xsl:when test="@source">
            <xsl:variable name="extension">
                <xsl:call-template name="file-extension">
                    <xsl:with-param name="filename" select="@source" />
                </xsl:call-template>
            </xsl:variable>
            <!-- PDF LaTeX, SVG HTML, if not indicated -->
            <xsl:apply-templates select="@source" />
            <xsl:if test="$extension=''">
                <xsl:text>.svg</xsl:text>
            </xsl:if>
        </xsl:when>
        <xsl:when test="latex-image|latex-image-code|sageplot|asymptote">
            <xsl:value-of select="$directory.images" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>.svg</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG:     image filename not determined in EPUB conversion</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Output a list of filenames, for a production script  -->
<!-- to use to ensure that the image files made available -->
<!-- in the final zip file actually match the files       -->
<!-- described in the manifest section                    -->
<xsl:template name="build-image-list">
    <xsl:variable name="image-list-filename">
        <xsl:value-of select="$xhtml-dir" />
        <xsl:text>/image-list.txt</xsl:text>
    </xsl:variable>
    <exsl:document href="{$image-list-filename}" method="text" encoding="UTF-8">
        <xsl:for-each select="$document-root//image">
            <xsl:apply-templates select="." mode="epub-base-filename" />
            <xsl:text>&#xa;</xsl:text>
        </xsl:for-each>
    </exsl:document>
</xsl:template>

<!-- Manifest entry with image file information -->
<xsl:template match="image" mode="manifest">
    <xsl:variable name="extension">
        <xsl:call-template name="file-extension">
            <xsl:with-param name="filename" select="@source" />
        </xsl:call-template>
    </xsl:variable>
    <!-- item  element for manifest -->
    <xsl:element name="item" xmlns="http://www.idpf.org/2007/opf">
        <!-- internal id of the image -->
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:attribute>
        <!-- filename, or tack on .svg for vector graphics -->
        <xsl:attribute name="href">
            <xsl:value-of select="$xhtml-dir" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select="." mode="epub-base-filename" />
        </xsl:attribute>
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
                <xsl:when test="latex-image|latex-image-code|sageplot|asymptote">
                    <xsl:text>image/svg+xml</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:BUG:     EPUB image media-type not determined</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:element>
    <!-- dead-end on  mode="manifest"  descent, most likely -->
    <xsl:apply-templates select="*" mode="manifest" />
</xsl:template>

<!-- Now the actual image inclusion where born -->
<xsl:template match="image">
    <xsl:element name="img">
        <xsl:attribute name="src">
            <xsl:apply-templates select="." mode="epub-base-filename" />
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
<!-- No cross-reference should be a knowl -->
<xsl:template match="*" mode="xref-as-knowl">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- Footnotes -->
<!-- Use "EPUB 3 Structural Semantics Vocabulary" -->
<!-- to get desired behavior from e-reader system -->
<!-- http://www.pigsgourdsandwikis.com/2012/05/creating-pop-up-footnotes-in-epub-3-and.html -->
<xsl:template match="fn">
    <xsl:variable name="int-id">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <!-- drop cross-reference, super-scripted, spaced -->
    <xsl:element name="sup">
        <a epub:type="noteref" href="#{$int-id}">
            <xsl:apply-templates select="." mode="serial-number" />
        </a>
    </xsl:element>
    <!-- content to an "aside", should automatically be hidden -->
    <aside epub:type="footnote" id="{$int-id}">
        <!-- process as mixed-content, don't yet allow paragraphs -->
        <xsl:apply-templates select="*|text()" />
    </aside>
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

</xsl:stylesheet>
