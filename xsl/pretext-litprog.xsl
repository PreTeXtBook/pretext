<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2013-2020 Robert A. Beezer

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

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl date str"
>

<!-- Begin with PreTeXt source, locate "fragment" with @filename attribute, -->
<!-- and do a depth-first search through the "fragment" that are pointers   -->
<!-- to other "fragment".  Any given "fragment" will be a mix of source     -->
<!-- "code" (to emit) and other "fragment".  If your source code has & or < -->
<!-- as characters, author them as &amp; or &lt; (respectively).            -->

<!-- The assembly templates will define $root and $document-root -->
<xsl:import href="./pretext-common.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>

<!-- Intend output for rendering as source code for some language -->
<!-- An output in XML syntax, like XSL, might be tricky           -->
<xsl:output method="text"/>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters  -->
<!-- There is always a "document root" directly under the pretext element, -->
<!-- Note that "docinfo" is at the same level and not processed            -->
<xsl:template match="/">
    <xsl:apply-templates select="$root" mode="generic-warnings" />
    <xsl:apply-templates select="$root" mode="deprecation-warnings" />
    <xsl:apply-templates select="$root" />
</xsl:template>

<!-- Locate file roots by presence of the filename attribute -->
<xsl:template match="pretext">
    <xsl:apply-templates select="$document-root//fragment[@filename]"/>
</xsl:template>

<!-- Use filename as a root indicator, allowing multiple files as output -->
<!-- Otherwise process as a fragment.  No banner since we have no idea   -->
<!-- what the target language's comments look like. Maybe the target     -->
<!-- language's comment character could be a docinfo item utilized by    -->
<!-- the banner templates?                                               -->
<xsl:template match="fragment[@filename]">
    <exsl:document href="{@filename}" method="text">
        <xsl:apply-templates select="code|fragref"/>
    </exsl:document>
</xsl:template>

<!-- If not a root, process allowed children -->
<xsl:template match="fragment[not(@filename)]">
    <xsl:apply-templates select="code|fragref"/>
</xsl:template>

<!-- Duplicate code, rather than default sanitization, so author -->
<!-- needs to be cognizant of indentation in PreTeXt source and  -->
<!-- resulting indentation of output                             -->
<!-- TODO: indentation/relative indentation specification on a "fragment"? -->
<!--     In "indentation units" with global value in spaces (or tabs?)?    -->
<!-- TODO: or maybe a "mangle" attribute (newlines, and/or more)           -->
<!-- TODO: global switch to minify (remove indentation, remove newlines?)  -->
<xsl:template match="fragment/code">
    <xsl:value-of select="."/>
</xsl:template>

<!-- As we process a fragment, a mix of code and pointers, -->
<!-- we incorporate the referenced material referenced by  -->
<!-- pointers, a depth-first traversal                     -->
 <xsl:template match="fragref">
    <xsl:apply-templates select="id(@ref)"/>
</xsl:template>

</xsl:stylesheet>
