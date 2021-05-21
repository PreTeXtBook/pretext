#!/bin/bash
#
# ********************************************************************
# Copyright 2017-2019 Robert A. Beezer
#
# This file is part of PreTeXt.
#
# PreTeXt is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 or version 3 of the
# License (at your option).
#
# PreTeXt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>.
# *********************************************************************
#
# Schema build script
#
# History
#
#  2017-06-19  Initiated
#  2017-07-21  For release
#  2019-05-24  Updates as DocFlex becomes FlexDoc (and v1.12.3)
#  2020-11-11  FlexDoc v1.12.5

#  This is designed for use in distributing derived products
#  from the PreTeXt schema.  So make a copy and adjust paths
#  to suit your particular purposes.

shopt -s -o nounset

# ***********
# Local paths
# ***********

# PreTeXt distribution
declare MB=${HOME}/mathbook/mathbook
# FlexDoc installation
declare FDH=/opt/flexdoc/flexdoc-xml-1.12.5

# DocFlex output directory
declare FDOUTDIR=${HOME}/mathbook/website/pretextbook.org/doc/schema
# Java root to locate executables
# (if not set by system: uncomment and set)
declare JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/

# *************
# Derived paths
# *************

# XSL for literate programming tool
declare MBXSL=${MB}/xsl
# Java particulars for documentation generation
# Quotes to protect spaces (use on filenames?)
declare JAVA_OPTIONS="-Xms512m -Xmx1024m"
declare CLASS_PATH="${FDH}/lib/xml-apis.jar:${FDH}/lib/xercesImpl.jar:${FDH}/lib/resolver.jar:${FDH}/lib/flexdoc-xml.jar:/usr/share/openjfx/lib/*"

# ******************
# Grammar generation
# ******************

# PreTeXt extraction of RELAX-NG compact schema
xsltproc ${MBXSL}/pretext-litprog.xsl pretext.xml

# System trang conversion to RELAX-NG XML schema
trang -I rnc -O rng pretext.rnc pretext.rng

# System trang conversion to W3C XSD schema
# "abstract groups" make schema browser too obtuse
trang -o disable-abstract-elements -I rnc -O xsd pretext.rnc pretext.xsd

# ************************
# Documentation Generation
# ************************
#
# We use DocFlex/XML - XSDDoc - XML Schema Documentation Generator
#
# http://www.filigris.com/docflex-xml/xsddoc/
#
# Execution and options cribbed from DocFlex distribution
#
# -docflexconfig specifies a DocFlex Linux-specific configuration
#  v1.12 config now in bin directory
#  v1.12 requires Oracle Java (ie OpenJDK lacks "javafx")

${JAVA_HOME}/bin/java ${JAVA_OPTIONS} -cp ${CLASS_PATH} xyz.flexdoc.xml.Generator \
    -flexdocconfig ${FDH}/bin/linux/flexdoc.config -quiet \
    -nodialog -launchviewer=false -d ${FDOUTDIR} pretext.xsd

# exit cleanly
exit 0