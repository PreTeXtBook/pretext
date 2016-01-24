<?xml version='1.0'?> <!-- As XML file -->
<!-- Identify as a stylesheet -->
<!-- http://stackoverflow.com/questions/10173139/empty-blank-namespace-declarations-being-generated-within-result-document -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
				xmlns="http://www.w3.org/1999/xhtml"
                xmlns:exsl="http://exslt.org/common"
				xmlns:date="http://exslt.org/dates-and-times"
                extension-element-prefixes="exsl date">

<!-- Trade on HTML markup, numbering, chunking, etc. -->
<!-- Override as pecularities of Sage Notebook arise -->
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

<!-- Intend output for rendering by browsers-->
<xsl:output method="html" indent="yes"/>

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

<!-- The value of the unique-identiier attribute of    -->
<!-- the package element of the container file         -->
<!-- must match                                        -->
<!-- the value of the id attribute of                  -->
<!-- the dc:identifier element in the metadata section -->
<!-- So we fix it here                                 -->
<xsl:variable name="uid-string">
	<xsl:text>pub-uid</xsl:text>
</xsl:variable>
<!-- The identifier itself -->
<!-- TODO: determine a better way to provide this -->
<xsl:variable name="mock-UUID">123456789-0-987654321-temporary</xsl:variable>


<!-- We hard-code the chunking level, need to pass this  -->
<!-- through the mbx script or use a compatibility layer -->
<xsl:param name="html.chunk.level" select="1" />
<!-- We disable the ToC level to avoid any conflicts with chunk level -->
<xsl:param name="toc.level" select="0" />

<xsl:template match="/">
	<xsl:call-template name="setup" />
	<xsl:call-template name="package-document" />
	<!-- <xsl:call-template name="ncx-toc" /> -->
	<!-- <xsl:call-template name="test-content" /> -->
	<xsl:apply-templates select="/mathbook/book/frontmatter" />
	<xsl:apply-templates select="/mathbook" />
</xsl:template>

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
	<!-- Automatically writes XML header at version 1.0 -->
	<!-- Points to OPF metadata file (in two variables) -->
	<exsl:document href="META-INF/container.xml" method="xml" encoding="UTF-8" indent="yes">
		<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
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
	<exsl:document href="{$content-dir}/{$package-file}" method="xml" encoding="utf-8" indent="yes">
		<package xmlns="http://www.idpf.org/2007/opf"
                 unique-identifier="{$uid-string}" version="3.0">
			<xsl:call-template name="package-metadata" />
			<xsl:call-template name="package-manifest" />
			<xsl:call-template name="package-spine" />
	 	</package>
	</exsl:document>
</xsl:template>


<!-- Honest to goodness metadata            -->
<!-- TODO: add publisher etc from Dublin Core           -->
<!-- TODO: see rights info handling in FCLA EPUB sample -->
<xsl:template name="package-metadata">
	<metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns="http://www.idpf.org/2007/opf">
		<!-- Optional in EPUB 3.0 spec -->
		<xsl:element name="dc:creator">
            <xsl:apply-templates select="//frontmatter/titlepage/author" mode="name-list"/>
            <xsl:apply-templates select="//frontmatter/titlepage/editor" mode="name-list"/>
		</xsl:element>
		<!-- Required in EPUB 3.0 spec -->
		<!-- TODO: title-types can refine this -->
		<xsl:element name="dc:title">
			<xsl:attribute name="id">
				<xsl:text>title</xsl:text>
			</xsl:attribute>
			<xsl:apply-templates select="/mathbook/book/title" />
		</xsl:element>
		<!-- Required in EPUB 3.0 spec               -->
		<!-- Must match attribute on package element -->
		<xsl:element name="dc:identifier">
			<xsl:attribute name="id">
				<xsl:value-of select="$uid-string" />
			</xsl:attribute>
			<xsl:value-of select="$mock-UUID" />
		</xsl:element>
		<!-- Required in EPUB 3.0 spec         -->
		<!-- Also needed for Kindle conversion -->
		<xsl:element name="dc:language">
			<xsl:value-of select="$document-language" />
		</xsl:element>
		<!-- Required in EPUB 3.0 spec -->
		<!-- TODO: a mild fiction, drop time zone, replace with Z -->
		<xsl:element name="meta">
			<xsl:attribute name="property">
				<xsl:text>dcterms:modified</xsl:text>
			</xsl:attribute>
			<xsl:value-of select="substring(date:date-time(),1,19)" />
			<xsl:text>Z</xsl:text>
		</xsl:element>
	</metadata>
</xsl:template>


<!-- Every file gets listed in manifest, the id attributes -->
<!-- are employed on the spine for ordering contents       -->
<xsl:template name="package-manifest">
	<manifest xmlns="http://www.idpf.org/2007/opf">
		<item id="css" href="{$css-dir}/mathbook-content.css" media-type="text/css"/>
		<item id="cover" href="{$xhtml-dir}/cover.xhtml" media-type="application/xhtml+xml"/>
		<item id="title-page" href="{$xhtml-dir}/title-page.xhtml" media-type="application/xhtml+xml"/>
		<item id="table-contents" href="{$xhtml-dir}/table-contents.xhtml" properties="nav" media-type="application/xhtml+xml"/>
		<item id="cover-image" href="{$xhtml-dir}/images/cover.png" properties="cover-image" media-type="image/png"/>
		<xsl:apply-templates select="/" mode="manifest" />
	</manifest>
</xsl:template>

<!-- Traverse subtree, looking for items        -->
<!-- that will be files to list in the manifest -->
<xsl:template match="@*|node()" mode="manifest">
    <xsl:apply-templates select="@*|node()" mode="manifest" />
</xsl:template>

<!-- Build an empty item element for each chapter, -->
<!-- recurse into contents for image files, etc -->
<!-- TODO: modal template for filename returns *.html   -->
<!--       is it important to name these files *.xhtml? -->
<xsl:template match="chapter" mode="manifest">
	<xsl:comment><xsl:apply-templates select="." mode="long-name" /></xsl:comment>
	<xsl:element name="item" xmlns="http://www.idpf.org/2007/opf">
		<xsl:attribute name="id">
			<xsl:apply-templates select="." mode="internal-id" />
		</xsl:attribute>
		<!-- TODO: be smarter about math/svg presence -->
		<!-- TODo: use a parameter switch to drop svg as property -->
		<xsl:attribute name="properties">
			<!-- <xsl:text>mathml svg</xsl:text> -->
			<xsl:text>svg</xsl:text>
		</xsl:attribute>
		<!-- TODO: coordinate with manifest/script on xhtml extension -->
		<xsl:attribute name="href">
			<xsl:value-of select="$xhtml-dir" />
			<xsl:text>/</xsl:text>
			<xsl:apply-templates select="." mode="filename" />
		</xsl:attribute>
		<xsl:attribute name="media-type">
			<xsl:text>application/xhtml+xml</xsl:text>
		</xsl:attribute>
	</xsl:element>
	<xsl:apply-templates mode="manifest" />
</xsl:template>

<!-- TODO: plain old image files need to be rounded up     -->
<!-- eg Judson's bar code image, sageplots, asymptote, etc -->

<!-- tikz graphics file have predictable file names -->
<!-- We do not recurse into the tikz sections       -->
<xsl:template match="tikz" mode="manifest">
	<xsl:element name="item"  xmlns="http://www.idpf.org/2007/opf">
		<xsl:attribute name="id">
			<xsl:apply-templates select="." mode="internal-id" />
		</xsl:attribute>
		<xsl:attribute name="href">
			<xsl:value-of select="$xhtml-dir" />
			<xsl:text>/images/</xsl:text>
			<xsl:apply-templates select="." mode="internal-id" />
			<xsl:text>.svg</xsl:text>
		</xsl:attribute>
		<xsl:attribute name="media-type">
			<xsl:text>image/svg</xsl:text>
		</xsl:attribute>
	</xsl:element>
</xsl:template>

<!-- How the files are organized into the spine  -->
<!-- Book opens to first time linear="no"        -->
<!-- Each must reference an id in the manifest   -->
<xsl:template name="package-spine">
	<spine xmlns="http://www.idpf.org/2007/opf">
	  	<itemref idref="cover" linear="yes" />
	  	<itemref idref="title-page" linear="yes"/>
	  	<itemref idref="table-contents" linear="yes"/>
		<xsl:apply-templates select="/" mode="spine" />
	</spine>
</xsl:template>

<!-- Traverse subtree, looking for items to include  -->
<xsl:template match="@*|node()" mode="spine">
    <xsl:apply-templates select="@*|node()" mode="spine" />
</xsl:template>

<xsl:template match="chapter" mode="spine">
	<xsl:element name="itemref" xmlns="http://www.idpf.org/2007/opf">
		<xsl:attribute name="idref">
			<xsl:apply-templates select="." mode="internal-id" />
		</xsl:attribute>
		<xsl:attribute name="linear">
			<xsl:text>yes</xsl:text>
		</xsl:attribute>
	</xsl:element>
	<xsl:apply-templates mode="spine" />
</xsl:template>


<!-- ############# -->
<!-- Content files -->
<!-- ############# -->

<xsl:template match="frontmatter">
	<exsl:document href="{$content-dir}/{$xhtml-dir}/cover.xhtml" method="xml" omit-xml-declaration="yes" encoding="utf-8" indent="yes">
	    <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html>&#xa;</xsl:text>
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head></head>
			<body>
				<img src="images/cover.png" />
			</body>
		</html>
	</exsl:document>
	<exsl:document href="{$content-dir}/{$xhtml-dir}/title-page.xhtml" method="xml" omit-xml-declaration="yes" encoding="utf-8" indent="yes">
	    <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html>&#xa;</xsl:text>		
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head></head>
			<body>
				<h1>
					<xsl:apply-templates select="/mathbook/book/title" />
					<xsl:if test="/mathbook/book/subtitle">
						<br />
						<xsl:apply-templates select="/mathbook/book/subtitle" />
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
	<exsl:document href="{$content-dir}/{$xhtml-dir}/table-contents.xhtml" method="xml" encoding="utf-8" indent="yes">
		<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
		    <head>
		        <meta charset="utf-8"/>
		        <!-- <link rel="stylesheet" type="text/css" href="../css/epub.css"/> -->
		    </head>
		    <body epub:type="frontmatter">
		        <nav epub:type="toc" id="toc">
		            <h1>Table of Contents</h1>
		            <ol>
		            	<xsl:for-each select="/mathbook/book/chapter">
			                <li>
			                	<xsl:element name="a">
			                		<xsl:attribute name="href">
			                			<xsl:apply-templates select="." mode="filename" />
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

<!-- Non-breaking space, which "joins" two words as a unit -->
<!-- maybe &nbsp; can be enabled and this can be removed   -->
<xsl:template match="nbsp">
    <xsl:text>&#xa0;</xsl:text>
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




 <!-- ########################################################################## -->

<!-- NOT FINAL OR QUALITY BELOW -->

<!-- An individual page:                                     -->
<!-- Inputs:                                                 -->
<!--     * strings for page title, subtitle, authors/editors -->
<!--     * content (exclusive of banners, etc)               -->
<xsl:template match="*" mode="page-wrap">
    <xsl:param name="title" />
    <xsl:param name="subtitle" />
    <xsl:param name="credits" />
    <xsl:param name="content" />
    <xsl:variable name="file">
    	<xsl:value-of select="$content-dir" />
    	<xsl:text>/</xsl:text>
    	<xsl:value-of select="$xhtml-dir" />
    	<xsl:text>/</xsl:text>
    	<xsl:apply-templates select="." mode="filename" />
    </xsl:variable>
    <exsl:document href="{$file}" method="xml" indent="yes">
	    <!-- <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html>&#xa;</xsl:text> -->
	    <html xmlns="http://www.w3.org/1999/xhtml"> <!-- lang="", and/or dir="rtl" here -->
	    	<head>
		        <xsl:call-template name="converter-blurb-html" />
		        <!-- <xsl:call-template name="fonts" /> -->
		        <xsl:call-template name="css" />
		    </head>
		    <body>
		        <xsl:call-template name="latex-macros" />
		        <xsl:copy-of select="$content" />
		    </body>
		</html>
    </exsl:document>
</xsl:template>

<!-- CSS header -->
<!-- Override to point to the right place -->
<xsl:template name="css">
	<xsl:element name="link">
		<xsl:attribute name="href">
			<xsl:text>../</xsl:text>
			<xsl:value-of select="$css-dir" />
			<xsl:text>/mathbook-content.css</xsl:text>
		</xsl:attribute>
		<xsl:attribute name="rel">
			<xsl:text>stylesheet</xsl:text>
		</xsl:attribute>
		<xsl:attribute name="type">
			<xsl:text>text/css</xsl:text>
		</xsl:attribute>
	</xsl:element>
</xsl:template>

</xsl:stylesheet>