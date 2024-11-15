<?xml version='1.0'?>

<!--********************************************************************
Copyright 2020 Robert A. Beezer

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


<!-- WARNING: this is an experimental conversion for LaTeX -->
<!-- Use `pretext-latex.xsl` for the standard conversion.  -->


<!-- Conveniences for classes of similar elements -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "./entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<!-- We override specific templates of the common conversion   -->

<xsl:import href="./pretext-latex-common.xsl" />

<!-- Note (2024-11-14): This is the start of a new "classic"    -->
<!-- latex conversion that can be used to create journal-ready  -->
<!-- latex documents.  Currently it does nothing different than -->
<!-- pretext-latex.xsl, but this will change in the future.     -->


<xsl:template match="/">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">You are using (a version of) the pretext-latex-classic conversion, which is still experimental and under development.</xsl:with-param>
      </xsl:call-template>
  <xsl:apply-imports />
</xsl:template>


</xsl:stylesheet>