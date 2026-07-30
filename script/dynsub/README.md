<!--********************************************************************
Copyright (C) 2025-2026  Robert A. Beezer

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

# Dynamic Substitutions Extraction

Static formats of documents that contain exercises with dynamically-defined content
require a method to substitute constant, static values for that content.
In order to do this, a script must run the setup for those exercises using
a static seed value.

The library defining randomized content needs to be made available to this
script, which needs to be installed via the node package manager, `npm`.

### `dynamic_extract.mjs`
A `node` Javascript program that takes a JSON input file containing
definitions the setup of each exercise with dynamically-defined content.
For each such exercise, runs the setup and extracts the value of the
necessary substitutions.
Saves the result in an XML output file that will be made available as
a generated file.

### `package.json`
Manages dependencies for npm installs of libraries used in the dynamic definitions.
