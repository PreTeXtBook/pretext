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

- Use the [examples index](README.md) to choose the right fixture.
- `sample-article` is the kitchen sink and gains an example for each new feature. `showcase` demonstrates features, authoring practices, and documentation for authors who learn from examples; elaborate examples belong there (see [its README](showcase/README.md)), while `sample-article` exercises everything. `sample-book` demonstrates book structure. Preserve its content notices exactly as recorded in [the copyright registry](../legal/copyright-holders.md).
- `minimal` isolates bugs and stays small; [CONTRIBUTING.md](../CONTRIBUTING.md) asks bug reports to add a focused case there. `hello-world` is the bare minimum.
- [`custom-theming`](custom-theming/README.md) is the CSS smoke test. Treat [`numbering`](numbering/README.md) as a machine-oriented regression fixture.
- `webwork` uses its `Makefile` plus a local `Makefile.paths`; `pug` uses the Node package manager (npm); `sample-book/gdpractice` contains Godot assets and source. Respect each toolchain when changing those examples.
- Generated assets belong in an example's configured `generated` or `generated-assets` tree and come from `pretext` script components. Do not edit them by hand; see the [generated-asset example](pdf-fo-development/generated/README.md).
- Build the relevant target named in its `project.ptx` with `pretext build <target>`, using the PreTeXt command-line interface (CLI), which exercises its bundled core unless linked to this checkout.
- Validate with `jing`, `pretext.rng` for `minimal` and `pretext-dev.rng` for `sample-article`, using the commands in the [root Verification section](../AGENTS.md).
