# PreTeXt Basics Reference

This directory is the source code for the PreTeXt Basics Reference,
which is a example-heavy reference for the basic features of PreTeXt.
This is part of the PreTeXt documentation.

## Contributing

If you'd like to contribute to the PreTeXt Basics Reference, please
fork and clone this repository, setting your clone as `origin` and
this repository as `upstream`. After pushing your edits to a branch on
your repository, create a pull request here. We suggest you consult
[David Farmer's `git` checklists](https://github.com/BooksHTML/author-workflow)
for how to do this. The ones for forking and contributing a correction
should suffice.

## Compiling

This project comes with a primitive `Makefile` to function as its
build script. Start by following the instructions in
`Makefile.paths.original` on how to configure the necessary paths for
your computer. Because the project uses WeBWorK problems, you must
first run `make pbr-extraction`. Then you can use `make html` to
create the HTML output and `make pdf` to create PDF output via LaTeX.

While editing on your fork, you can just run `make html` and `make
pdf` unless you add, remove, or modify a WeBWorK exercise. If you make
an edit that impacts WeBWorK, run `make pbr-extraction` and then `make
html` and/or `make pdf`.