# ww-mbx: WeBWork-MathBook XML Bridge

XSL templates and supporting infrastructure to describe [WeBWorK](http://webwork.maa.org/) automated homework problems for inclusion in a [MathBook XML](http://mathbook.pugetsound.edu) document.

# Quickstart (as of 2015/08/31)

1. Clone the [MathBook XML repository](https://github.com/rbeezer/mathbook)
1. `cd mathbook; git checkout dev`
1. Clone this repository (anywhere you like, independent of (1))
1. `cd ww-mbx; git checkout dev`
1. Read about configuring the makefile in the `script` directory
1. `cd script; make minimal`
1. Look in the `pg` subdirectory of wherever you configured your `SCRATCH` directory
1. `make chapter`, `make templates` (requires `xelatex` executable)
1. Look in `SCRATCH/pg`, `SCRATCH/html`, `SCRATCH/pdf`
