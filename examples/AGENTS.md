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

# Examples

- Use the [examples index](README.md) to choose the right example. Source follows the conventions in the root [PreTeXt source section](../AGENTS.md).
- `sample-article` is the kitchen sink and gains an example for each new feature. `showcase` demonstrates features, authoring practices, and documentation for authors who learn from examples; elaborate examples belong there (see [its README](showcase/README.md)), while `sample-article` exercises everything. `sample-book` demonstrates book structure. Preserve its content notices exactly as recorded in [the copyright registry](../legal/copyright-holders.md).
- `minimal` isolates bugs and stays small; [CONTRIBUTING.md](../CONTRIBUTING.md) asks bug reports to add a focused case there. `hello-world` is the bare minimum.
- [`custom-theming`](custom-theming/README.md) is the CSS smoke test. [`numbering`](numbering/README.md) is a synthetic test document for the numbering system, built for comparing output and not as a model of authoring.
- `webwork` uses its `Makefile` plus a local `Makefile.paths`; `pug` uses the Node package manager (npm); `sample-book/gdpractice` contains Godot assets and source. Respect each toolchain when changing those examples.
- Generated assets belong in an example's configured `generated` or `generated-assets` tree and come from `pretext` script components. Do not edit them by hand; see the [generated-asset example](pdf-fo-development/generated/README.md). Examples track generated assets, unlike most projects; when adding or changing an example, generate its assets in every format used by its builds (for images, typically Scalable Vector Graphics (SVG), Portable Document Format (PDF), and Portable Network Graphics (PNG)) with `python3 pretext/pretext -c <component> -f all -p <publication-file> <source-file>` (Mermaid uses `-f svg` and `-f png` separately), then commit them.
- Build an example with `pretext/pretext`, passing its source file and a publication file, using the command in the root [Verification section](../AGENTS.md).
- Validate documents using the command in the root [Verification section](../AGENTS.md).
