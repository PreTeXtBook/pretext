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

Arguments:

- `--input` (`-i`) the JSON file written by `xsl/extract-dynamic.xsl`.
- `--output` (`-o`) the XML substitutions file to write.
- `--basedir` (`-b`) the directory that project-local library paths are
  resolved against. Those paths are recorded the same way they are for HTML,
  led by the `external/` directory, so this is whichever directory the
  project's external tree was copied into for the build. Defaults to the
  directory holding the input file.

Each substitution is recorded in two forms:

```xml
<eval-subst obj="baseMatrix"><latex>\begin{bmatrix}...</latex><plain>[[1, 3], [2, 4]]</plain></eval-subst>
```

A single object is commonly referenced more than once and not always the same
way, so the choice between them belongs to the point of use rather than here.
`xsl/pretext-assembly.xsl` picks the one its context calls for. Files written
before this distinction existed hold text and no children, and that text is
still accepted for either request.

An exercise whose libraries will not load, or whose setup throws, is reported
as a `PTX:ERROR` and recorded with its substitutions present but empty. The
run continues, so one broken exercise does not cost the rest of the document
its static content. The exit code is nonzero only when nothing usable could be
produced at all.

### Libraries imported by an exercise

The imports are the same list the Runestone component receives, and are
resolved the same way: the literal `"BTM"` means the installed
`btm-expressions` package, and anything else is a path or a URL. The exports
of every module are merged into one object whose keys become names in scope
for the setup, which is what lets a setup script call an imported function
without qualification. A name exported by two libraries resolves to the one
imported later, silently, matching the component.

A library reached by URL is fetched and written to disk as `.mjs` before being
imported. Importing the source as a `data:` URL would be simpler, but a
`data:` URL has no position in a filesystem, so a library that imports
anything of its own could not resolve it. The `.mjs` extension forces Node to
parse the file as an ES module, so a bundle that is not an ES module fails
here just as it would in a browser, rather than loading quietly as CommonJS
and offering no named exports.

Remote libraries are only fetched when the publication file has approved them
individually, under `dynamics/remote-libraries`. The gate exists because a
static build runs this code under `node` as whoever is building, which is a
different proposition from the same code running sandboxed in a reader's
browser. Nothing is cached between runs; within a run, a library shared by
several exercises is fetched once.

### `package.json`
Manages dependencies for npm installs of libraries used in the dynamic definitions.
