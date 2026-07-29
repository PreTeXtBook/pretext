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

#  Styling/Theming Samples for PreTeXt

This project has samples to illustrate how the HTML output of PreTeXt can be customized. The `projects.ptx` file defines the following build targets:

* `web` - Default styling
* `web-custom-colors` - Specifying custom colors for a theme
* `web-extra-css` - Adding extra CSS files with custom styles
* `web-salem` - Specifying the "salem" theme with a specific color palette
* `web-salem-extra-css` - Demonstrates additional tricks using extra CSS to use or modify the colors defined for a theme
* `web-custom-theme` - Demonstrates how to create a custom theme by providing an SCSS file as a build target

To build any of these targets using the PreTeXt CLI use a command like:

```bash
pretext build web-custom-colors
```

See the `project.ptx` file for more details about each target.

If you are experimenting with `web-custom-theme`, and want to just rebuild the theme, you can add the `-t` flag. Doing so will leave the HTML in place and just rebuild the `theme.css` file from your SCSS.

```bash
pretext build web-custom-theme -t
```
