<!--********************************************************************
Copyright (C) 2026  Robert A. Beezer

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

# JavaScript

- `dist/` is committed generated output from the [JavaScript builder](../script/jsbuilder/README.md). Rebuild it with the Node package manager (npm), using `(cd ../script/jsbuilder && npm install && npm run build)`, and commit its diff with the source change. Full builds stay unminified for readable diffs.
- Treat `diagcess/diagcess.js` (a pre-built npm package) and `jquery.min.js` (loaded from the `js/` root, not `dist/`) as vendored; do not edit them. `prism/gdscript-prism.js` is maintained source that the builder compiles.
- `src/pretext-core.js` is the core bundle entry. Preserve its deliberate import order when adding an always-loaded script.
- The separate PreTeXt command-line interface (CLI) copies `js/` and serves the committed files in `dist/` as-is.
- Use Node.js 18 or newer, as required by `../script/jsbuilder/package.json`.
