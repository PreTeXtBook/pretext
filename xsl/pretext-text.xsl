<?xml version='1.0'?>

<!--********************************************************************
Copyright 2018 Robert A. Beezer

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

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<!-- We choose to not include a default namespace       -->
<!-- (in particular  http://www.w3.org/1999/xhtml),     -->
<!-- even if this complicates adding namespaces onto    -->
<!-- derivatives, such as HTML destined for EPUB output -->
<!-- xmlns="http://www.w3.org/1999/xhtml"               -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:b64="https://github.com/ilyakharlamov/xslt_base64"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    exclude-result-prefixes="b64"
    extension-element-prefixes="exsl date str"
>

<xsl:import href="./mathbook-common.xsl" />

<!-- This is a conversion to "plain" text.  Upon initiation it is mainly -->
<!-- meant as a foundation for various simple conversions to things like -->
<!-- doctests or JSON table-of-contents.  But it is designed as a "real" -->
<!-- conversion.  But obviously, there are many PreTeXt constructions    -->
<!-- which cannot be realized in text.                                   -->
<!--                                                                     -->
<!-- Goal is to make it so *no* conversion needs to import  -->
<!-- "mathbook-common.xsl" since some foundational conversion will.      -->
<!--                                                                     -->
<!-- Initial work might be to implement certain characters as 7-bit      -->
<!-- ASCII and as Unicode, under the control of a switch.  For example,  -->
<!-- the "q" element could have dumb generic quotes or smart left and    -->
<!-- right quotes.                                                       -->

<xsl:output method="text"/>

<!-- if chunking, this is the extension of the files produced -->
<xsl:variable name="file-extension" select="'.txt'"/>


</xsl:stylesheet>
