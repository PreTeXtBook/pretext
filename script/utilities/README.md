# Developer Utilities

Small helper scripts for developers working on the PreTeXt source.
Unlike the build tooling elsewhere in `script/`, nothing here is part of
producing a document; these are conveniences for preparing and tidying
contributions.

### `trim_changed_trailing_whitespace.py`

Removes trailing spaces and tabs, but only on lines that you have changed
on the current branch relative to a base commit.  Restricting the cleanup
to changed lines keeps unrelated whitespace churn out of your diffs and
avoids spurious merge conflicts.

```
script/utilities/trim_changed_trailing_whitespace.py [--base <ref>] [--check]
```

With no arguments it trims the changed lines in your working tree, using
the merge-base with your branch's upstream (or `origin/HEAD`) as the base.

- `--base <ref>` &mdash; diff against an explicit ref or commit instead.
- `--check` &mdash; report the offending files and line numbers without
  modifying anything, exiting non-zero if any are found (useful in CI).

To merely *detect* trailing whitespace on changed lines, git has this
built in: `git diff --check`.  This script complements that by also
*fixing* the lines it finds.
