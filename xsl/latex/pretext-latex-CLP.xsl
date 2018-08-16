<?xml version='1.0'?>

<!--********************************************************************
Copyright 2018 Andrew Rechnitzer

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

<!-- Conveniences for classes of similar elements -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "../entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<!-- Override specific tenplates of the standard conversion -->
<xsl:import href="../mathbook-latex.xsl" />

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="text" />

<!-- "commentary" -->
<!-- Green and ugly -->
<xsl:template match="commentary" mode="tcb-style">
    <xsl:text>size=minimal, attach title to upper, after title={\space}, fonttitle=\bfseries, coltitle=black, colback=green</xsl:text>
</xsl:template>

<!-- "objectives", "outcomes" -->
<!-- Default tcb, identically -->
<xsl:template match="objectives|outcomes" mode="tcb-style">
    <xsl:text/>
</xsl:template>

</xsl:stylesheet>

