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

- Use the Python version stated in [README.md](README.md) and install `requirements.txt`. `module-test.py` is a manual demonstration rather than an automated test suite.
- New code follows the style of the code around it, down to the usual way of writing a common construct: for example, a string is built with `str.format()`, and an import carries a comment naming what is used from it. The files should read as if one author wrote them. Use the standard library unless the package already depends on something else, and nothing that needs a newer Python than the README states.
- Keep the import graph one-way: `pretext.py`, `webwork.py`, and `stack.py` import `common.py`; `common.py` imports none of those siblings.
- Transformations run through `lxml` in `common.xsltproc()`, not the `xsltproc` executable.
- Other tools, such as the PreTeXt command-line interface (CLI) in the `pretext-cli` repository, import this package, so its public function signatures are an interface; preserve them. When a function must gain a parameter, add it as a required positional parameter with no default, and update every caller, so that other consumers learn of the change.
- A new generated-asset type normally adds `../xsl/extract-<name>.xsl` and a function in `lib/pretext.py`. The function builds string parameters, calls `common.xsltproc()`, and invokes external tools through `common.get_executable_cmd()`.
- Register the asset's destination in `component_dirs` inside `get_destination_directory()` in `pretext`, then add its `-c` or `--component` entry to `component_info` inside `get_cli_arguments()`.
- Configure external programs in the `[executables]` section. Copy `pretext.cfg` to `../user/pretext.cfg`; never edit the distributed file.
- Use the `ptxlogger` logger and the `PTX:<LEVEL>: message` console format. At debug verbosity, `release_temporary_directories()` preserves temporary directories for inspection.
- A log message that an author will read describes the outcome and does not name the `pretext/pretext` script, since the PreTeXt CLI calls the same functions.
- Run `python3 pretext/pretext -h` from the checkout root with the declared dependencies installed. For a build check, use the command in the root [Verification section](../AGENTS.md).
