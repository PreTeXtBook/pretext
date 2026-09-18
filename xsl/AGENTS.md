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

# Stylesheets

- Use Extensible Stylesheet Language Transformations (XSLT) 1.0 with Extensions to XSLT (EXSLT) only. Declare each EXSLT namespace you use; list a prefix in `extension-element-prefixes` only when you use its extension elements, such as `exsl:document`, not for functions (`pretext-common.xsl` declares `exsl`, `date`, `str`, and `dyn`; `pretext-text-utilities.xsl` also uses `math` and `set` functions). `xsltproc`, backed by libxslt, is the reference processor.
- PreTeXt entry stylesheets load `entities.ent` as an external parameter entity in a `DOCTYPE` (document type declaration). Add shared `-LIKE` and `-FILTER` unions there; its comments identify lists that mirror the schema or require a Guide update.
- Project stylesheets import one format entry point, and every entry point reaches `pretext-common.xsl` through its imports. `pretext-html.xsl` directly imports `publisher-variables.xsl`, `pretext-assembly.xsl`, and `pretext-common.xsl`; publisher variables and assembly are designed to travel together. Treat `-common` stylesheets as libraries rather than entry points.
- Prefix internal logic defects with `PTX:BUG:`. Use `PTX:WARNING:`, `PTX:ERROR:`, and `PTX:FATAL:` according to the [coding chapter](../doc/guide/developer/coding.xml).
- A publisher option change pairs the implementing stylesheet with `../schema/publication-schema.xml`, regenerated schemas, a Guide entry, and an example. A theme option also updates `html-theme-option-list` in `publisher-variables.xsl`.
- Follow the [localization contract](localizations/README.md): add new string identifiers to `en-US.xml`, and register each new language file in `localizations.xml`. Verify localization changes manually.
- Follow the [support-file procedure](support/README.md) when updating Runestone Services versions.
- Copy the copyright header from a sibling onto every new `.xsl` file.
- Run `(cd tests && xsltproc pretext-text-utilities-test.xsl null.xml)`. Add tests there for new low-level text utilities.
