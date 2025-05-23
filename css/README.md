# Notes on CSS structure and development

PreTeXt books expect to use a `theme.css` file for its styling. SCSS is used to build that CSS file.

A few themes (the default-modern one and legacy ones that predate SCSS overhaul) are provided "prerolled" in `css/dist`. These can be used without rebuilding from SCSS and even gently modified via the appending of CSS `variables` to customize things like `primary-color`.

Other themes, or using `options` to more substantially change a "prerolled" theme, require that the theme is rebuilt.

## Building

If a book's theme requires building, the pretext script or CLI should handle all of the build details. If you are using the CLI, it should handle installing the build tools as well. If you are using the pretext script, you will need to [install Node and the build script dependencies manually](../script/cssbuilder/README.md#installing-node-and-dependencies)

For more advanced use, including rebuilding themes by hand, see the [CSS Builder script README](../script/cssbuilder/README.md)

### Installing NPM

You will need to [install node](https://nodejs.org/en/download/package-manager).

Install the needed dependencies by switching to the `pretext/script/cssbuilder` and doing `npm install`.

Run `npm run build` to build all the default targets to the output directory (default is `pretext/css/dist`). You can change the directory the build product is produced into with `-o PATH`. If using a relative path, make sure to specify it from the `cssbuilder` folder.

## Folders

### colors

Color palettes that ideally can be used across multiple themes, though it is not expected every palette will be available in every theme. These are all designed to produce a variable `$colors` containing a map of variable definitions. The theme is responsible for turning that map into CSS variables via the `scss-to-css` function.

If a shared palette needs slight modifications by a given theme, the theme can simply override the individual variables (or add new ones). See the comment in `theme-default-modern` for an example.

### components

Shared files that are (or are expected to be) used across many **targets**.

Some of these files are in need of refactoring and modularization.

See README.md in subfolders of `components/` for tips on organization of subcomponents.

### dist

Built CSS ready for inclusion by pretext.

Files in the directory **should not be modified by hand**. The CSS build script in `script/cssbuilder` will produce these files from the items in the `targets` directory.

### fonts

Mechanisms for selection of fonts by a theme

### legacy

Files only used by legacy (pre scss) styles

### targets

Root targets that produce a CSS file. Anything that represents a self-contained final product belongs here.

Any files that are designed only to be used in one target also belong here, grouped with the target they belong to. For example, if `foo.scss` is only intended to be used by the `reveal` target, that file should be placed in the `revealjs` folder.

### other

CSS that is not a part of producing PreTeXt volumes and is not bundled into any target in `dist/` e.g. CSS related to the PreTeXt catalog.

## File "ownership", @use, and copy/paste

Files in the `target` folder are considered "owned" by the folder they are in. When making changes to those files you are encouraged to think about other targets in the same "family" that may @use the files, but are not expected to go out of your way to fix issues in those other targets that result from the changes.

Files in `components` are "shared". Changes to them should consider (and test) all targets that @use the component.

There is a balancing act between the complexity of the include tree for targets and avoiding duplication of effort. Avoid coping/pasting large numbers of rules from one target to another. If you want to reuse some of the rules from another target, consider factoring out those rules into a `component` that the old file and your new one can both @use. But doing so to reuse a small number of CSS rules likely creates more complexity than simply duplicating those rules in your target.

## Tips on differentiating theme code

1) In cases of significantly different CSS, we try to provide different scss files that themes can choose to import (see `_toc-default` vs `_toc-overlay`). As any given theme will only (hopefully) import one of the options, we don't have to worry about cross talk between the CSS. Common features of the two can be factored out into a sheet they both import (`_toc-basics`).

2) In cases of more minor variations, especially those that end up affecting multiple rules (e.g. how much margin to apply, whether or not to round off border corners) we try to pass in a variable to the scss file to control that aspect. Those variables can have defaults that are applied if a theme does not specify a default. The downside here is that variables need to be passed all the way down through any stylesheets that are between the theme and the target sheet. So in this case a theme file like `theme-default-modern` would have to pass $toc-expander-style to  `_toc-default` as it imports that and `_to-default` would then have to pass it to `_toc-basics` where it is applied.

3) Differences that are only value differences in CSS properties can be set as cssvaraibles. We use that for lots of the colors. A low level file can set `border-right: 1px solid var(--toc-border-color);`. Then a theme can change --toc-border-color` and the new color is used.

4) The last approach is to just define CSS in the theme SCSS file that adds to or overrides what is produced in the import. This works well if the change only makes sense in the context of a particular theme AND if they are extending what is already there instead of undoing all of the defaults to replace them with something new.  We do this for things like Salem making a bunch of the RS elements wider. If the same logic needs to be applied to multiple themes, consider making a mixin file that they can opt into (see `toc-expand-chevrons`).