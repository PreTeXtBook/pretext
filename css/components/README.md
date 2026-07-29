<!--********************************************************************
Copyright (C) 2024-2026  Robert A. Beezer

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
