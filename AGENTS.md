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

- Install `xsltproc` as described in the [developer processing chapter](doc/guide/developer/xsltproc.xml), and `trang` plus `jing` as described in the [schema notes](schema/README.md) and [schema chapter](doc/guide/author/schema.xml).
- The [Python package](pretext/README.md) requires Python 3.10 or newer and its `requirements.txt` dependencies.
- Use Node.js 18 or newer with the Node package manager (npm) for both asset builders; the locked `esbuild` dependency of each requires Node.js 18 even though the CSS builder's `package.json` states 14.
- Build examples with the `pretext` command-line interface (CLI) from the separate `pretext-cli` project.

## Change contract

- A new publication option normally changes `schema/publication-schema.xml` and its generated schemas, `xsl/publisher-variables.xsl` or another implementing stylesheet, an example, and the Guide. Keep each surface in its own commit.
- Pull request (PR) #3148, for an SVG favicon, demonstrates the pattern with these commits:

      HTML: add SVG option for favicon-scheme
      Publisher variables: add svg favicon option
      Schema: add publisher option for SVG favicon
      Sample article: change favicon to SVG
      Guide: document SVG favicon option

- [Careful documentation accompanies every new feature](doc/guide/developer/coding.xml).
- Commit subjects use `Area: lowercase description`, omit a trailing period, stay on one line, and stay within roughly 60 to 70 characters, per the [Git chapter](doc/guide/developer/git.xml). Put XML names in double quotes, such as `"@font-size"`. Bodies are rare.
- Current areas include Schema, Publication schema, Publisher variables, HTML, LaTeX, CSS, JavaScript, Guide, Sample article, Sample book, Assembly, Common, Validation, and Deprecate.
- Keep one logical change per commit and do not squash your own; maintainers may combine or redistribute commits when merging, as [CONTRIBUTING.md](CONTRIBUTING.md) says.
- Follow [CONTRIBUTING.md](CONTRIBUTING.md) and the [Git chapter](doc/guide/developer/git.xml): keep one topic per branch, rebase onto the default `master` branch, never merge `master` into a topic, and stop pushing while a PR is under review unless asked.
- Isolate formatting-only changes and add their commit hashes to `.git-blame-ignore-revs`.
- New files use the standard copyright header. Record any different holder or notice treatment in [the copyright registry](legal/copyright-holders.md).

## Generated files

- Edit `schema/pretext.xml` and `schema/publication-schema.xml`, not the generated RELAX NG (Regular Language for XML Next Generation) compact `.rnc` or `.rng` files.
- Edit CSS and JavaScript sources, not `css/dist/` or `js/dist/`; rebuild and commit their generated diffs with the source change.
- Treat `doc/guide/generated/` as build output.
- Copy `pretext/pretext.cfg` to `user/pretext.cfg` for local executable settings; never edit the distributed file.
- Rules for `script/`, `journals/`, and `fonts/` live in their own READMEs: [script](script/README.md), [journals](journals/README.md), [fonts](fonts/README.md).

## Verification

- Expand XML Inclusions (XInclude) directives with `xmllint --xinclude`, then validate the minimal example with `jing`. `xmllint` only expands the includes here; `jing` performs the validation, as the [schema chapter](doc/guide/author/schema.xml) recommends.

      xmllint --xinclude examples/minimal/source/main.ptx > /tmp/minimal.xml && jing schema/pretext.rng /tmp/minimal.xml

- Validate the sample article against the development schema:

      xmllint --xinclude examples/sample-article/sample-article.xml > /tmp/sa.xml && jing schema/pretext-dev.rng /tmp/sa.xml

- Run the Extensible Stylesheet Language Transformations (XSLT) unit test:

      (cd xsl/tests && xsltproc pretext-text-utilities-test.xsl null.xml)

- The installed CLI bundles a frozen copy of this repository's core, so `pretext build` and `pretext validate <target>` exercise the released core. [Link a source install of the CLI to this checkout](https://github.com/PreTeXtBook/pretext-cli/blob/main/docs/core_development.md).

- Build the minimal example with the raw processor, with `$REPO` as the checkout root:

      mkdir -p /tmp/minimal-html && cd /tmp/minimal-html && xsltproc --xinclude --stringparam publisher $REPO/examples/minimal/publication/publication.ptx $REPO/xsl/pretext-html.xsl $REPO/examples/minimal/source/main.ptx

- Regenerate the schema products and compare them with the committed files as described in [schema/AGENTS.md](schema/AGENTS.md).
- Rebuild generated web assets after their sources change:

      (cd script/cssbuilder && npm install && npm run build)
      (cd script/jsbuilder && npm install && npm run build)

- There is no continuous integration (CI) here; run the checks above locally before opening a PR.
- Do not add CI configuration, and do not recreate `release-notes.md`; the git history is the release record. `script/mbx` is a retired stub; use `pretext/pretext`.
