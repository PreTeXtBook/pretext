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
