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

- Edit sources. Rebuild `dist/` locally to check your work with the Node package manager (npm), using `(cd ../script/jsbuilder && npm install && npm run build)`. Maintainers regenerate it when merging, so do not commit its changes.
- Treat `diagcess/diagcess.js` (a pre-built npm package) and `jquery.min.js` (loaded from the `js/` root, not `dist/`) as vendored; do not edit them. `prism/gdscript-prism.js` is maintained source that the builder compiles.
- `src/pretext-core.js` is the core bundle entry. Preserve its deliberate import order when adding an always-loaded script.
- Other tools, such as the PreTeXt command-line interface (CLI) in the `pretext-cli` repository, copy `js/` and serve the committed `dist/` files as-is; see the [JavaScript builder notes](../script/jsbuilder/README.md).
- Use the Node.js version in `../script/jsbuilder/package.json` `engines` field.
