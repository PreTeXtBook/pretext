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

# CSS

- Read the [CSS architecture](README.md) and [component layout](components/README.md). Files under a target folder are owned by that target (see the README's ownership section); components are shared and require testing across every target that uses them; colors supply reusable palettes.
- Legacy themes are hand-maintained CSS in `legacy/`. Modern themes use Sassy CSS (SCSS) in `targets/html/<name>/`; follow the [city naming convention](targets/html/README.md).
- `dist/` is committed build output. Never edit it by hand; rebuild it from `../script/cssbuilder/` and include its diff with the source change.
- Theme names and their accepted options are enumerated in the `html-theme-option-list` table in `../xsl/publisher-variables.xsl`; `$html-theme-name` reads the publication file's `html/css/@theme`. A new theme or option updates that table and the Guide. Check whether `../schema/publication-schema.xml` describes the option before relying on validation: the committed publication schema does not yet accept every option that the publication files in `../examples/custom-theming/publication/` use.
- Use Node.js 18 or newer with the Node package manager (npm): the builder's `package.json` states 14, but its locked `esbuild` dependency requires 18. Rebuild with `(cd ../script/cssbuilder && npm install && npm run build)`.
- Smoke-test themes in [`examples/custom-theming`](../examples/custom-theming/README.md). Its PreTeXt command-line interface (CLI) target can rebuild only custom theme CSS with `pretext build web-custom-theme -t` (with the CLI linked to your checkout).
