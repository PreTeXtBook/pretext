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

# The PreTeXt Guide

PDF and HTML versions of this guide are available at the [PreTeXt](https://pretextbook.org) site in the Documentation area.

If you wish to build from source, possibly as part of contributing improvements, follow these steps:

1.  To build LaTeX for input to `pdflatex`:
    cd /path/to/guide
    pretext build latex -d -w
1.  And for HTML output:
    cd /path/to/guide
    pretext build html -d -w
1.  The preceeding two steps will attempt to build all of the webwork representations and diagrams needed for your book. You may be missing some of the prerequisites, such as Sage that will need to be installed before a full build can be completed.

If you are contributing new material, note that there are three important elements in use. Please make use of them in your contribution.

-   `tag` - for element names
-   `tage` - for names of empty elements
-   `attr` - for names of attributes
