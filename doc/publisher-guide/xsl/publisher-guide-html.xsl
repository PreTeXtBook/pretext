<?xml version='1.0'?>

<!--   This file is part of the documentation of PreTeXt      -->
<!--                                                          -->
<!--      PreTeXt Author's Guide                              -->
<!--                                                          -->
<!-- Copyright (C) 2013-2017  Robert A. Beezer, David Farmer  -->
<!-- See the file COPYING for copying conditions.             -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- Copy three author-guide-*.xsl to $MATHBOOK/user -->
<!-- Relative paths below assume this                -->
<xsl:import href="../xsl/mathbook-html.xsl" />
<xsl:import href="./publisher-guide-common.xsl" />

<!-- Go two levels deep in sidebar                  -->
<!-- But will open to list-of-chapters summary page -->
<xsl:param name="toc.level" select="'2'" />

</xsl:stylesheet>
