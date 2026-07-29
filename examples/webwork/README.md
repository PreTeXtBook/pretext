<!--********************************************************************
Copyright (C) 2016-2026  Robert A. Beezer

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
*****************************************************************-->

# WeBWorK examples

These examples demonstrate how to author, and process, [WeBWorK](http://webwork.maa.org/) automated homework problems for inclusion in a [PreTeXt](https://pretextbook.org) document.

Because the process can be a bit more involved when your document includes a WW problem, we provide a makefile to process the examples and as concrete documentation of how to process your own document.

* copy `Makefile.paths.original` and populate the variables as shown in the `.example` version
* use the `make` command to build various outputs
* read comments in `Makefile` to understand the various scenarios
