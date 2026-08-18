<?xml version='1.0'?>

<!--********************************************************************
Copyright (C) 2022-2026  Robert A. Beezer

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

<!-- Standalone testbed for pretext-text-utilities templates        -->
<!-- Invoke this stylesheet on null.xml in the same folder:         -->
<!-- xsltproc pretext-text-utilities-test.xsl null.xml              -->

<!-- There are &LOWERCASE; and &UPPERCASE; entities  -->
<!-- in the "file-extension" template (only?) -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "../entities.ent">
    %entities;
]>

<!-- EXSL needed for token list template (only?) -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:str="http://exslt.org/strings"
    xmlns:exsl="http://exslt.org/common"
    xmlns:math="http://exslt.org/math"
    xmlns:set="http://exslt.org/sets"
    extension-element-prefixes="pi str math"
>

<!-- Allow serialization of XML in various contexts     -->
<!-- See the XSL file for more info about Lenz' utility -->
<xsl:import href="../pretext-text-utilities.xsl"/>

<!-- Output helper -->
<xsl:variable name="verbose-output" select="false()"/>

<xsl:template name="assert-equal">
  <xsl:param name="expected"/>
  <xsl:param name="actual"/>
  <xsl:param name="test-name"/>
  <xsl:choose>
    <xsl:when test="$expected = $actual">
      <xsl:if test="$verbose-output">
        <xsl:message>Test <xsl:value-of select="$test-name"/> passed.</xsl:message>
      </xsl:if>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message>Test <xsl:value-of select="$test-name"/> failed: </xsl:message>
      <xsl:message>  expected = "<xsl:value-of select="$expected"/>"  (<xsl:value-of select="exsl:object-type($expected)"/>)</xsl:message>
      <xsl:message>  actual = "<xsl:value-of select="$actual"/>"  (<xsl:value-of select="exsl:object-type($actual)"/>)</xsl:message>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--========================================================================-->
<!-- test count-pad-length-->
<xsl:variable name="count-pad-length-0">
  <xsl:variable name="test-val">
    <xsl:call-template name="count-pad-length">
      <xsl:with-param name="text" select="'a'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="0"/>
    <xsl:with-param name="actual" select="number($test-val)"/>
    <xsl:with-param name="test-name" select="'count-pad-length-0'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="count-pad-length-2">
  <xsl:variable name="test-val">
    <xsl:call-template name="count-pad-length">
      <xsl:with-param name="text" select="'  a'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="2"/>
    <xsl:with-param name="actual" select="number($test-val)"/>
    <xsl:with-param name="test-name" select="'count-pad-length-2'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="count-pad-length-2-empty">
  <xsl:variable name="test-val">
    <xsl:call-template name="count-pad-length">
      <xsl:with-param name="text" select="'  '"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="2"/>
    <xsl:with-param name="actual" select="number($test-val)"/>
    <xsl:with-param name="test-name" select="'count-pad-length-2'"/>
  </xsl:call-template>
</xsl:variable>

<!--========================================================================-->
<!-- test substring-after-last-->
<xsl:variable name="substring-after-last-b1">
  <xsl:variable name="test-val">
    <xsl:call-template name="substring-after-last">
      <xsl:with-param name="input" select="'aabcc'"/>
      <xsl:with-param name="substr" select="'b'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="'cc'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'substring-after-last-b1'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="substring-after-last-b2">
  <xsl:variable name="test-val">
    <xsl:call-template name="substring-after-last">
      <xsl:with-param name="input" select="'aabccbcc'"/>
      <xsl:with-param name="substr" select="'b'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="'cc'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'substring-after-last-b2'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="substring-after-last-missing">
  <xsl:variable name="test-val">
    <xsl:call-template name="substring-after-last">
      <xsl:with-param name="input" select="'aacc'"/>
      <xsl:with-param name="substr" select="'b'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="''"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'substring-after-last-missing'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="substring-after-last-leading">
  <xsl:variable name="test-val">
    <xsl:call-template name="substring-after-last">
      <xsl:with-param name="input" select="'baacc'"/>
      <xsl:with-param name="substr" select="'b'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="'aacc'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'substring-after-last-leading'"/>
  </xsl:call-template>
</xsl:variable>


<!--========================================================================-->
<!-- test substring-before-last-->
<xsl:variable name="substring-before-last-b1">
  <xsl:variable name="test-val">
    <xsl:call-template name="substring-before-last">
      <xsl:with-param name="input" select="'aabcc'"/>
      <xsl:with-param name="substr" select="'b'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="'aa'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'substring-before-last-b1'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="substring-before-last-b2">
  <xsl:variable name="test-val">
    <xsl:call-template name="substring-before-last">
      <xsl:with-param name="input" select="'aabccbcc'"/>
      <xsl:with-param name="substr" select="'b'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="'aabcc'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'substring-before-last-b2'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="substring-before-last-missing">
  <xsl:variable name="test-val">
    <xsl:call-template name="substring-before-last">
      <xsl:with-param name="input" select="'aacc'"/>
      <xsl:with-param name="substr" select="'b'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="''"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'substring-before-last-missing'"/>
  </xsl:call-template>
</xsl:variable>

<!--========================================================================-->
<!-- test substring-after-preserve-->
<xsl:variable name="substring-after-preserve-b1">
  <xsl:variable name="test-val">
    <xsl:call-template name="substring-after-preserve">
      <xsl:with-param name="input" select="'aabcc'"/>
      <xsl:with-param name="substr" select="'b'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="'cc'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'substring-after-preserve-b1'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="substring-after-preserve-miss">
  <xsl:variable name="test-val">
    <xsl:call-template name="substring-after-preserve">
      <xsl:with-param name="input" select="'aacc'"/>
      <xsl:with-param name="substr" select="'b'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="'aacc'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'substring-after-preserve-miss'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="substring-after-preserve-empty">
  <xsl:variable name="test-val">
    <xsl:call-template name="substring-after-preserve">
      <xsl:with-param name="input" select="''"/>
      <xsl:with-param name="substr" select="'b'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="''"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'substring-after-preserve-empty'"/>
  </xsl:call-template>
</xsl:variable>


<!--========================================================================-->
<!-- test left-align-text -->
<xsl:variable name="align-left-first-line-shortest">
  <xsl:variable name="test-val">
    <xsl:call-template name="left-align-text">
      <xsl:with-param name="text" select="'  Line one&#10;   Line two&#10;    Line three'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <!-- 2/3/4 spaces should become 0/1/2 spaces -->
    <xsl:with-param name="expected" select="'Line one&#10; Line two&#10;  Line three'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'align-left-first-line-shortest'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="align-left-other-line-shortest">
  <xsl:variable name="test-val-rtf">
    <xsl:call-template name="left-align-text">
      <xsl:with-param name="text" select="'    Line one&#10; Line two&#10;  Line three'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="test-val">
    <xsl:value-of select="$test-val-rtf"/>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <!-- 4/1/2 spaces should become 3/0/1 spaces -->
    <xsl:with-param name="expected" select="'   Line one&#10;Line two&#10; Line three'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'align-left-other-line-shortest'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="align-left-no-indent">
  <xsl:variable name="test-val-rtf">
    <xsl:call-template name="left-align-text">
      <xsl:with-param name="text" select="'  Line one&#10;Line two&#10;  Line three'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="test-val">
    <xsl:value-of select="$test-val-rtf"/>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <!-- 2/0/2 spaces should become 2/0/2 spaces -->
    <xsl:with-param name="expected" select="'  Line one&#10;Line two&#10;  Line three'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'align-left-no-indent'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="align-left-trailing-empty-preserved">
  <xsl:variable name="test-val-rtf">
    <xsl:call-template name="left-align-text">
      <xsl:with-param name="text" select="'  Line one&#10;Line two&#10;  Line three&#10;'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="test-val">
    <xsl:value-of select="$test-val-rtf"/>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <!-- 2/0/2 spaces should become 2/0/2 spaces -->
    <xsl:with-param name="expected" select="'  Line one&#10;Line two&#10;  Line three&#10;'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'align-left-trailing-empty-preserved'"/>
  </xsl:call-template>
</xsl:variable>


<!--========================================================================-->
<!-- test file-extension -->
<xsl:variable name="file-extension-bare">
  <xsl:variable name="test-val">
    <xsl:call-template name="file-extension">
      <xsl:with-param name="filename" select="'movie.mp4'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="'mp4'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'file-extension-bare'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="file-extension-none">
  <xsl:variable name="test-val">
    <xsl:call-template name="file-extension">
      <xsl:with-param name="filename" select="'movie'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="''"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'file-extension-none'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="file-extension-uppercase">
  <xsl:variable name="test-val">
    <xsl:call-template name="file-extension">
      <xsl:with-param name="filename" select="'MOVIE.MP4'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="'mp4'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'file-extension-uppercase'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="file-extension-relative-path">
  <xsl:variable name="test-val">
    <xsl:call-template name="file-extension">
      <xsl:with-param name="filename" select="'video/movie.webm'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="'webm'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'file-extension-relative-path'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="file-extension-relative-none">
  <xsl:variable name="test-val">
    <xsl:call-template name="file-extension">
      <xsl:with-param name="filename" select="'video/ups-visitor-guide-360'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="''"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'file-extension-relative-none'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="file-extension-query-string">
  <xsl:variable name="test-val">
    <xsl:call-template name="file-extension">
      <xsl:with-param name="filename" select="'movie.mp4?start=16'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="'mp4'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'file-extension-query-string'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="file-extension-url">
  <xsl:variable name="test-val">
    <xsl:call-template name="file-extension">
      <xsl:with-param name="filename" select="'https://media.w3.org/2010/05/sintel/trailer.mp4'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="'mp4'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'file-extension-url'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="file-extension-url-none">
  <xsl:variable name="test-val">
    <xsl:call-template name="file-extension">
      <xsl:with-param name="filename" select="'https://media.w3.org/2010/05/sintel/trailer'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="''"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'file-extension-url-none'"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="file-extension-url-dotted-directory">
  <xsl:variable name="test-val">
    <xsl:call-template name="file-extension">
      <xsl:with-param name="filename" select="'https://example.org/v1.2/movie.webm'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="assert-equal">
    <xsl:with-param name="expected" select="'webm'"/>
    <xsl:with-param name="actual" select="$test-val"/>
    <xsl:with-param name="test-name" select="'file-extension-url-dotted-directory'"/>
  </xsl:call-template>
</xsl:variable>

<!--========================================================================-->

<!-- "main" -->
<xsl:template match="/">
  <xsl:message>Tests complete!</xsl:message>
</xsl:template>

</xsl:stylesheet>