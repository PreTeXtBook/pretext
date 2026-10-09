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
# Working on PreTeXt

PreTeXt is an authoring and publishing system for textbooks, research articles, and monographs. These instructions serve people and agents changing the toolchain, not authors writing books; start with the [project overview](README.md).

## Prerequisites

- Use the Python version stated in the [Python package README](pretext/README.md) and install its [requirements](pretext/requirements.txt); `pretext/pretext` warns at startup when your Python version is older.
- Install `jing` for validation, as described in the [schema notes](schema/README.md) and [schema chapter](doc/guide/author/schema.xml).
- Install `xsltproc` as described in the [developer processing chapter](doc/guide/developer/xsltproc.xml) and `trang` to regenerate the schemas.
- Use the Node.js version in each asset builder's `package.json` `engines` field, with the Node package manager (npm).

## Change contract

- A new publication option normally changes `schema/publication-schema.xml` and its generated schemas, `xsl/publisher-variables.xsl` or another implementing stylesheet, an example, and the Guide. Keep each surface in its own commit.
- Pull request (PR) #3148, for an SVG favicon, demonstrates the pattern with these commits:

      HTML: add SVG option for favicon-scheme
      Publisher variables: add svg favicon option
      Schema: add publisher option for SVG favicon
      Sample article: change favicon to SVG
      Guide: document SVG favicon option

- Before adding a configurable feature, decide whether its switch belongs in `docinfo` or the publication file by the principles in the [coding chapter](doc/guide/developer/coding.xml).
- [Careful documentation accompanies every new feature](doc/guide/developer/coding.xml).
- Commit subjects use `Area: lowercase description`, omit a trailing period, stay on one line, and stay within roughly 60 to 70 characters, per the [Git chapter](doc/guide/developer/git.xml). Put XML names in double quotes, such as `"@font-size"`. Bodies are rare.
- Current areas include Schema, Publication schema, Publisher variables, HTML, LaTeX, CSS, JavaScript, Guide, Sample article, Sample book, Assembly, Common, Validation, and Deprecate.
- Keep one logical change per commit and do not squash your own; maintainers may combine or redistribute commits when merging, as [CONTRIBUTING.md](CONTRIBUTING.md) says.
- Follow [CONTRIBUTING.md](CONTRIBUTING.md) and the [Git chapter](doc/guide/developer/git.xml): keep one topic per branch, rebase onto the default `master` branch, never merge `master` into a topic, and stop pushing while a PR is under review unless asked.
- Isolate formatting-only changes and add their commit hashes to `.git-blame-ignore-revs`.
- New files use the standard copyright header. Record any different holder or notice treatment in [the copyright registry](legal/copyright-holders.md).

## Generated files

- Edit `schema/pretext.xml` and `schema/publication-schema.xml`, not the generated RELAX NG (Regular Language for XML Next Generation) compact `.rnc` or `.rng` files. Regenerate those products and commit them with the schema change.
- Edit CSS and JavaScript sources. Rebuild `css/dist/` and `js/dist/` locally to check your work; maintainers regenerate these directories when merging, so do not commit their changes.
- Treat `doc/guide/generated/` as build output.
- Copy `pretext/pretext.cfg` to `user/pretext.cfg` for local executable settings; never edit the distributed file.
- Rules for `script/`, `journals/`, and `fonts/` live in their own READMEs: [script](script/README.md), [journals](journals/README.md), [fonts](fonts/README.md).

## Verification

- Validate a document with `python3 pretext/pretext -V full -M local -p <publication-file> -d <output-dir> <source-file>`. This assembles the source first, resolving `@component` markings selected by the publication file, validates against both `schema/pretext-dev.rng` and `schema/pretext.rng`, and writes `<name>-validation.txt` plus `<name>-assembled.xml` to the output directory. Use `-V terse` for one tab-separated message per line; experimental messages come from constructs accepted only by the development schema. For example:

      python3 pretext/pretext -V full -M local -p examples/sample-article/publication.xml -d /tmp/sa-check examples/sample-article/sample-article.xml

- Build a document with `python3 pretext/pretext -c doc -f html -p <publication-file> -d <output-dir> <source-file>`. For example:

      python3 pretext/pretext -c doc -f html -p examples/minimal/publication/publication.ptx -d /tmp/minimal-html examples/minimal/source/main.ptx

- Regenerate the schema products and compare them with the committed files as described in [schema/AGENTS.md](schema/AGENTS.md).
- Rebuild generated web assets locally to check source changes:

      (cd script/cssbuilder && npm install && npm run build)
      (cd script/jsbuilder && npm install && npm run build)

- There is no continuous integration (CI) here; run the checks above locally before opening a PR.
- Do not add CI configuration, and do not recreate `release-notes.md`; the git history is the release record. `script/mbx` is a retired stub; use `pretext/pretext`.
