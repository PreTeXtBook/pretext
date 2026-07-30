<!--********************************************************************
Copyright (C) 2025-2026  Robert A. Beezer

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

# XSL Automated Tests

This folder contains testing utilities for XSL templates. The tests focus on function-like templates for tasks like string manipulation that are used as helpers throughout the XSL stylesheets. Most of these functions are otherwise only observable indirectly through their effects on the output of the main XSL stylesheets.

## Running Tests

To run the tests, you can use the `xsltproc` command-line tool. For example:

```
xsltproc pretext-text-utilities-test.xsl null.xml
```

A successfully run will just produce the output `Tests complete!`. If there are any issues, the output will include error messages indicating what went wrong.

## Writing Tests

Ideally, before making changes to any low-level utility XSL templates, a developer should document the intended behavior of the template in a set of tests. These tests can be submitted as part of a pull request as evidence the XSL works as intended and to prevent regressions in the future.

Refer to the existing tests in `pretext-text-utilities-test.xsl` for examples of how to do so.

## Files

- `pretext-text-utilities-test.xsl`: Contains tests for the text utilities templates.
- `null.xml`: A minimal XML file used as input for the tests.