<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2013 Robert A. Beezer

This file is part of MathBook XML.

MathBook XML is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

MathBook XML is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<!-- English (en) language translation template -->

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace" 
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="date"
>

<!-- MathBook XML templates for language-specific phrases in headings, etc.      -->
<!-- Intended to be imported by mathbook-common.xsl for use in any output format -->

<!-- So output methods here are just text -->
<xsl:output method="text" />

<!-- This template translates an element name to an upper-case language-equivalent               -->
<!-- Sometimes must call this, but it is usually better to apply template to the node            -->
<!-- with mode="type-name", which exercises this routine, for whatever language file is imported -->
<xsl:template name="type-name">
    <xsl:param name="generic" />
    <xsl:choose>
        <xsl:when test="$generic='theorem'">       <xsl:text>Theorem</xsl:text></xsl:when>
        <xsl:when test="$generic='corollary'">     <xsl:text>Corollary</xsl:text></xsl:when>
        <xsl:when test="$generic='lemma'">         <xsl:text>Lemma</xsl:text></xsl:when>
        <xsl:when test="$generic='proposition'">   <xsl:text>Proposition</xsl:text></xsl:when>
        <xsl:when test="$generic='claim'">         <xsl:text>Claim</xsl:text></xsl:when>
        <xsl:when test="$generic='fact'">          <xsl:text>Fact</xsl:text></xsl:when>
        <xsl:when test="$generic='conjecture'">    <xsl:text>Conjecture</xsl:text></xsl:when>
        <xsl:when test="$generic='proof'">         <xsl:text>Proof</xsl:text></xsl:when>
        <!-- -->
        <xsl:when test="$generic='book'">          <xsl:text>Book</xsl:text></xsl:when>
        <xsl:when test="$generic='article'">       <xsl:text>Article</xsl:text></xsl:when>
        <xsl:when test="$generic='letter'">        <xsl:text>Letter</xsl:text></xsl:when>
        <!-- -->
        <xsl:when test="$generic='chapter'">       <xsl:text>Chapter</xsl:text></xsl:when>
        <xsl:when test="$generic='appendix'">      <xsl:text>Appendix</xsl:text></xsl:when>
        <xsl:when test="$generic='section'">       <xsl:text>Section</xsl:text></xsl:when>
        <xsl:when test="$generic='subsection'">    <xsl:text>Subsection</xsl:text></xsl:when>
        <xsl:when test="$generic='subsubsection'"> <xsl:text>Subsubsection</xsl:text></xsl:when>
        <xsl:when test="$generic='paragraph'">     <xsl:text>Paragraph</xsl:text></xsl:when>
        <xsl:when test="$generic='subparagraph'">  <xsl:text>Subparagraph</xsl:text></xsl:when>
        <!-- -->
        <xsl:when test="$generic='definition'">    <xsl:text>Definition</xsl:text></xsl:when>
        <xsl:when test="$generic='axiom'">         <xsl:text>Axiom</xsl:text></xsl:when>
        <!-- -->
        <xsl:when test="$generic='example'">       <xsl:text>Example</xsl:text></xsl:when>
        <xsl:when test="$generic='remark'">        <xsl:text>Remark</xsl:text></xsl:when>
        <!-- -->
        <xsl:when test="$generic='exercise'">      <xsl:text>Exercise</xsl:text></xsl:when>
        <xsl:when test="$generic='solution'">      <xsl:text>Solution</xsl:text></xsl:when>
        <xsl:when test="$generic='hint'">          <xsl:text>Hint</xsl:text></xsl:when>
        <!-- -->
        <xsl:when test="$generic='figure'">        <xsl:text>Figure</xsl:text></xsl:when>
        <xsl:when test="$generic='table'">         <xsl:text>Table</xsl:text></xsl:when>
        <xsl:when test="$generic='abstract'">      <xsl:text>Abstract</xsl:text></xsl:when>
        <xsl:when test="$generic='preface'">       <xsl:text>Preface</xsl:text></xsl:when>
        <xsl:when test="$generic='bibliography'">  <xsl:text>References</xsl:text></xsl:when>
        <!-- -->
        <xsl:when test="$generic='todo'">          <xsl:text>To Do</xsl:text></xsl:when>
        <xsl:when test="$generic='editor'">        <xsl:text>Editor</xsl:text></xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="no">Warning: Unable to translate <xsl:value-of select="$generic" />.&#xa;</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>