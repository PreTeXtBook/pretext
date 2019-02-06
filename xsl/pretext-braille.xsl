<?xml version='1.0'?>

<!--********************************************************************
Copyright 2019 Robert A. Beezer

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

<!-- A conversion to "stock" PreTeXt HTML, but optimized as an     -->
<!-- eventual input for teh liblouis system to produce Grade 2     -->
<!-- and Nemeth Braille into BRF format with ASCII Braille         -->
<!-- (encoding the 6-dot-patterns of cells with 64 well-behaved    -->
<!-- ASCII characters).  By itself theis conversion is not useful. -->
<!-- The math bits (as LaTeX) need to be converted to Braille by   -->
<!-- MathJax and Speech Rules Engine, and then fed to              -->
<!-- liblouisutdml's  file2brl  program.                           -->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
    >

<xsl:import href="mathbook-html.xsl" />

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- These two templates are similar to those of  mathbook-html.xsl. -->
<!-- Primarily the production of cross-reference ("xref") knowls     -->
<!-- has been removed.                                               -->

<xsl:template match="/">
    <xsl:apply-templates/>
</xsl:template>

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<!-- We process structural nodes via chunking routine in xsl/mathbook-common.xsl    -->
<!-- This in turn calls specific modal templates defined elsewhere in this file     -->
<xsl:template match="/mathbook|/pretext">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">This template is under development.&#xa;It will not produce Braille directly, just a precursor.</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="$root" mode="generic-warnings" />
    <xsl:apply-templates select="$root" mode="deprecation-warnings" />
    <xsl:apply-templates mode="chunking" />
</xsl:template>


<!-- An individual page:                                   -->
<!-- Inputs:                                               -->
<!-- * page content (exclusive of banners, navigation etc) -->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="containing-filename" />
    </xsl:variable>
    <exsl:document href="{$filename}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
    <xsl:call-template name="converter-blurb-html" />
    <html lang="{$document-language}"> <!-- dir="rtl" here -->
        <head>
            <title>
                <!-- Leading with initials is useful for small tabs -->
                <xsl:if test="//docinfo/initialism">
                    <xsl:apply-templates select="//docinfo/initialism" />
                    <xsl:text> </xsl:text>
                </xsl:if>
            <xsl:apply-templates select="." mode="title-short" />
            </title>
            <meta name="Keywords" content="Authored in PreTeXt" />
            <!-- http://webdesignerwall.com/tutorials/responsive-design-in-3-steps -->
            <meta name="viewport" content="width=device-width,  initial-scale=1.0, user-scalable=0, minimum-scale=1.0, maximum-scale=1.0" />
            <!-- favicon -->
            <xsl:call-template name="favicon"/>
            <!-- jquery used by sage, webwork, knowls -->
            <xsl:call-template name="jquery-sagecell" />
            <xsl:call-template name="mathjax" />
            <!-- webwork's iframeResizer needs to come before sage -->
            <xsl:if test="$document-root//webwork-reps">
                <xsl:call-template name="webwork" />
            </xsl:if>
            <xsl:apply-templates select="." mode="sagecell" />
            <xsl:if test="$document-root//program">
                <xsl:call-template name="goggle-code-prettifier" />
            </xsl:if>
            <xsl:call-template name="google-search-box-js" />
            <xsl:call-template name="knowl" />
            <xsl:call-template name="mathbook-js" />
            <xsl:call-template name="fonts" />
            <xsl:call-template name="hypothesis-annotation" />
            <xsl:call-template name="geogebra" />
            <xsl:call-template name="jsxgraph" />
            <xsl:call-template name="css" />
            <xsl:call-template name="login-header" />
            <xsl:call-template name="pytutor-header" />
            <xsl:call-template name="font-awesome" />
        </head>
        <body>
            <!-- potential document-id per-page -->
            <xsl:call-template name="document-id"/>
            <!-- the first class controls the default icon -->
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="$root/book">mathbook-book</xsl:when>
                    <xsl:when test="$root/article">mathbook-article</xsl:when>
                </xsl:choose>
                <xsl:if test="$b-has-toc">
                    <xsl:text> has-toc has-sidebar-left</xsl:text> <!-- note space, later add right -->
                </xsl:if>
            </xsl:attribute>
            <!-- assistive "Skip to main content" link    -->
            <!-- this *must* be first for maximum utility -->
            <xsl:call-template name="skip-to-content-link" />
            <xsl:call-template name="latex-macros" />
            <!-- HTML5 body/header will be a "banner" landmark automatically -->
            <header id="masthead" class="smallbuttons">
                <div class="banner">
                    <div class="container">
                        <xsl:call-template name="google-search-box" />
                        <xsl:call-template name="brand-logo" />
                        <div class="title-container">
                            <h1 class="heading">
                                <xsl:element name="a">
                                    <xsl:attribute name="href">
                                        <xsl:apply-templates select="$document-root" mode="containing-filename" />
                                    </xsl:attribute>
                                    <span>
                                        <xsl:apply-templates select="." mode="title-attributes" />
                                        <!-- Do not use shorttitle in masthead,  -->
                                        <!-- which is much like cover of a book  -->
                                        <xsl:apply-templates select="$document-root" mode="title-simple" />
                                    </span>
                                    <xsl:if test="normalize-space($document-root/subtitle)">
                                        <span class="subtitle">
                                            <xsl:apply-templates select="$document-root" mode="subtitle" />
                                        </span>
                                    </xsl:if>
                                </xsl:element>
                            </h1>
                            <!-- Serial list of authors/editors -->
                            <p class="byline">
                                <xsl:apply-templates select="$document-root/frontmatter/titlepage/author" mode="name-list"/>
                                <xsl:apply-templates select="$document-root/frontmatter/titlepage/editor" mode="name-list"/>
                            </p>
                        </div>  <!-- title-container -->
                    </div>  <!-- container -->
                </div>  <!-- banner -->
            <xsl:apply-templates select="." mode="primary-navigation" />
            </header>  <!-- masthead -->
            <div class="page">
                <xsl:apply-templates select="." mode="sidebars" />
                <!-- HTML5 main will be a "main" landmark automatically -->
                <main class="main">
                    <div id="content" class="mathbook-content">
                        <xsl:copy-of select="$content" />
                    </div>
                </main>
            </div>
            <xsl:apply-templates select="$docinfo/analytics" />
            <xsl:call-template name="pytutor-footer" />
            <xsl:call-template name="login-footer" />
        </body>
    </html>
    </exsl:document>
</xsl:template>

</xsl:stylesheet>