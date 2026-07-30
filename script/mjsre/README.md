<!--********************************************************************
Copyright (C) 2020-2026  Robert A. Beezer

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

# MathJax (MJ) and Speech Rule Engine (SRE)

Offline support for conversions to EPUB, Kindle, braille,
and the XSL-FO PDF.

Requires installations of MathJax (version 4, npm package
"@mathjax/src") and Speech Rule Engine (version 5),
presumably via the node package manager, `npm`.

### `mj-sre-page`
A `node` Javascript program to generate representations of
mathematics as MathML, SVG, braille, and speech.

### `update-sre`
bash script to refresh the npm installation: discards
`node_modules` and reinstalls the versions pinned by
`package.json`.

### `package.json`
Manages dependencies for npm installs.
