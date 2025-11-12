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
#  2025-11-12  Removed FlexDoc in favor of Siefken's browser

#  This is designed for use in distributing derived products
#  from the PreTeXt schema.  So make a copy and adjust paths
#  to suit your particular purposes.

#  Prerequites
#
#  1.  PreTeXt repository (where this file lives)
#  2.  "trang" conversion tool, on your $PATH
#       a.  "trang" package for Debian
#       b.  "jing-trang" package for Ubuntu

# Usage
#
# 1.  Assumes  ${PTX}/schema  is current working directory
# 2.  No arguments, just "./build.sh"

shopt -s -o nounset

# ***********
# Local paths
# ***********

# PreTeXt distribution
# Likely "/path/to/pretext"
# RAB's path is historical
declare PTX=${HOME}/mathbook/mathbook

# *************
# Derived paths
# *************

# XSL for literate programming tool
declare XSL=${PTX}/xsl

# ******************
# Grammar generation
# ******************

# PreTeXt extraction of RELAX-NG compact schema
xsltproc ${XSL}/pretext-litprog.xsl pretext.xml

# System trang conversion to RELAX-NG XML schema
trang -I rnc -O rng pretext.rnc pretext.rng
trang -I rnc -O rng pretext-dev.rnc pretext-dev.rng

# System trang conversion to W3C XSD schema
# "abstract groups" make schema browser too obtuse
trang -o disable-abstract-elements -I rnc -O xsd pretext.rnc pretext.xsd

# And the same steps for the publication-schema
xsltproc ${XSL}/pretext-litprog.xsl publication-schema.xml
trang -I rnc -O rng publication-schema.rnc publication-schema.rng
trang -o disable-abstract-elements -I rnc -O xsd publication-schema.rnc publication-schema.xsd

# exit cleanly
exit 0
