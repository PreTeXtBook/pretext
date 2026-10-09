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

- Use Extensible Stylesheet Language Transformations (XSLT) 1.0 with Extensions to XSLT (EXSLT) only. Declare each EXSLT namespace you use, and list its prefix in `extension-element-prefixes` whether you use its extension elements, such as `exsl:document`, or only its functions: a prefix that is declared but not listed is copied onto literal result elements as a namespace declaration (`pretext-common.xsl` declares and lists `exsl`, `date`, `str`, and `dyn`). libxslt is the reference processor, through `lxml` in `pretext/pretext`.
- PreTeXt entry stylesheets load `entities.ent` as an external parameter entity in a `DOCTYPE` (document type declaration). Add shared `-LIKE` and `-FILTER` unions there; its comments identify lists that mirror the schema or require a Guide update.
- Project stylesheets import one format entry point, and every entry point reaches `pretext-common.xsl` through its imports. `pretext-html.xsl` directly imports `publisher-variables.xsl`, `pretext-assembly.xsl`, and `pretext-common.xsl`; publisher variables and assembly are designed to travel together. Treat `-common` stylesheets as libraries rather than entry points.
- Obtain the identification value of an element by applying `mode="unique-id"` to it, never by reading the attribute that holds it; the template in `pretext-common.xsl` is the one place that knows how the value is stored. `mode="assembly-id"` yields a different value, which belongs to `pretext-assembly.xsl` and the `extract-*.xsl` stylesheets that feed it. A conversion never reads that one: the two values agree for most elements but not for all.
- Prefix internal logic defects with `PTX:BUG:`. Use `PTX:WARNING:`, `PTX:ERROR:`, and `PTX:FATAL:` according to the [coding chapter](../doc/guide/developer/coding.xml).
- A message that an author will read describes the outcome and does not name the `pretext/pretext` script, since the PreTeXt command-line interface (CLI) can do the same work. A comment may name the script freely.
- Write a comment of several lines as single-line comments, one `<!-- ... -->` per line, with every closing `-->` in the same column.
- A publisher option change pairs the implementing stylesheet with `../schema/publication-schema.xml`, regenerated schemas, a Guide entry, and an example. A theme option also updates `html-theme-option-list` in `publisher-variables.xsl`.
- Follow the [localization contract](localizations/README.md): add new string identifiers to `en-US.xml`, and register each new language file in `localizations.xml`. Verify localization changes manually.
- Follow the [support-file procedure](support/README.md) when updating Runestone Services versions.
- Copy the copyright header from a sibling onto every new `.xsl` file.
- Run `(cd tests && xsltproc pretext-text-utilities-test.xsl null.xml)`. Add tests there for new low-level text utilities.
