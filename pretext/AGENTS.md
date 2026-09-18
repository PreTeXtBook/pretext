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

# Python package

- Use Python 3.10 or newer and install `requirements.txt`; see [README.md](README.md). `module-test.py` is a manual demonstration rather than an automated test suite.
- Keep the import graph one-way: `pretext.py`, `webwork.py`, and `stack.py` import `common.py`; `common.py` imports none of those siblings.
- Transformations run through `lxml` in `common.xsltproc()`, not the `xsltproc` executable.
- The separate PreTeXt command-line interface (CLI) vendors this layer, so its public function signatures are an interface; preserve them.
- A new generated-asset type normally adds `../xsl/extract-<name>.xsl` and a function in `lib/pretext.py`. The function builds string parameters, calls `common.xsltproc()`, and invokes external tools through `common.get_executable_cmd()`.
- Register the asset's destination in `component_dirs` inside `get_destination_directory()` in `pretext`, then add its `-c` or `--component` entry to `component_info` inside `get_cli_arguments()`.
- Configure external programs in the `[executables]` section. Copy `pretext.cfg` to `../user/pretext.cfg`; never edit the distributed file.
- Use the `ptxlogger` logger and the `PTX:<LEVEL>: message` console format. At debug verbosity, `release_temporary_directories()` preserves temporary directories for inspection.
- Run `python3 pretext/pretext -h` from the checkout root with the declared dependencies installed. For a build check use the raw processor command in the root guidance; the installed CLI runs its own bundled copy of this layer.
