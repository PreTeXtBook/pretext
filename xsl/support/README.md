<!--********************************************************************
Copyright (C) 2022-2026  Robert A. Beezer

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

# PreTeXt (Miscellaneous) Support Files

### Runestone Services

The `webpack_static_imports.xml` file contains the current version of the minimal set of JS and CSS files for providing "Runestone Services", either when hosted on a Runestone Server or when creating HTML for self-hosting.

As of 2024-07-31 the latest version can obtained with a `wget` from [https://runestone.academy/cdn/runestone/latest/webpack_static_imports.xml](https://runestone.academy/cdn/runestone/latest/webpack_static_imports.xml).

An outline of the procedure to update this file is:

```
cd xsl/support
wget -O webpack_static_imports.xml https://runestone.academy/cdn/runestone/latest/webpack_static_imports.xml
git diff
git st

<verify/obtain new version number in diff, use in commit message>

git commit -am "Runestone: update services file to vX.Y.Z"

<push new commit to PreTeXt repository>
```
