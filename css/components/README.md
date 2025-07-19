# Notes on components folder

Components contains pieces shared by all modern scss themes. They are divided into:

## chunks

Grouping elements that are generally PreTeXt specific - exercises, knowls, etc...

Generally all these will be included by a `chunks-XXXX` file like `_chunks-default.scss`.

## elements

Small, relatively self contained pieces of content.

These are all included from `components/_pretext.scss`

## helpers

Mixins used to help build multiple other components

## interactives

Interactive widgets like Runestone, Sage, etc...

`interactives/extras` contains optional modifications that a theme can use.

## page-parts

Macro structures of the page - TOC, navbar, etc...

`page-parts/extras` contains optional modifications that a theme can use.
