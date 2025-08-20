<?xml version='1.0'?>

<!--********************************************************************
Copyright 2022 Robert A. Beezer

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

<!-- "main" -->
<xsl:template match="/">
  <xsl:message>Tests complete!</xsl:message>
</xsl:template>

</xsl:stylesheet>