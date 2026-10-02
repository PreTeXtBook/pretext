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

# Schema

- Edit the literate sources `pretext.xml` and `publication-schema.xml`. The `.rnc` files are generated from them by `xsl/pretext-litprog.xsl` under `xsltproc`, and each `.rng` file by `trang` from its `.rnc`; the full recipe is below. See [README.md](README.md) and `build.sh`.
- `build.sh` contains a hard-coded PreTeXt root variable, `PTX`. Copy it and adapt that path, rather than running the committed script as-is.
- Keep `pretext-dev.rnc`, generated from `pretext.xml`, purely additive over the production schema: a bare include, new named patterns, and choice additions only.
- Put context-dependent checks that RELAX NG cannot express in `pretext-validation-plus.xsl`, whose header and sections describe this role.
- A new element or attribute usually pairs with a stylesheet change, a sample-article example, and documentation in the Guide as [doc/guide/AGENTS.md](../doc/guide/AGENTS.md) describes.
- From the checkout root, regenerate all schema products in a temporary copy and compare every resulting `.rnc` and `.rng` file with the committed version:

      schema_tmp=$(mktemp -d /tmp/pretext-schema-doc.XXXXXX)
      cp -a schema/. "$schema_tmp/"
      (cd "$schema_tmp" &&
       xsltproc "$OLDPWD/xsl/pretext-litprog.xsl" pretext.xml &&
       trang -I rnc -O rng pretext.rnc pretext.rng &&
       trang -I rnc -O rng pretext-dev.rnc pretext-dev.rng &&
       trang -I rnc -O rng pf-adapter.rnc pf-adapter.rng &&
       trang -I rnc -O rng pf-preamble-adapter.rnc pf-preamble-adapter.rng &&
       xsltproc "$OLDPWD/xsl/pretext-litprog.xsl" publication-schema.xml &&
       trang -I rnc -O rng publication-schema.rnc publication-schema.rng &&
       for schema_file in pretext.rnc pretext.rng pretext-dev.rnc pretext-dev.rng pf-adapter.rnc pf-adapter.rng pf-preamble-adapter.rnc pf-preamble-adapter.rng publication-schema.rnc publication-schema.rng; do
           diff -q "$OLDPWD/schema/$schema_file" "$schema_file"
       done)
- Validate the sample article against `pretext-dev.rng` and the minimal example against `pretext.rng` using the commands in the [root Verification section](../AGENTS.md).
