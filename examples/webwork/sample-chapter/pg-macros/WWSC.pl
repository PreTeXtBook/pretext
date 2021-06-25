#############################################################################
# This macro library supports WeBWorK problems from the PreTeXt project named
# Integrating WeBWorK into Textbooks
#############################################################################


# Return a string containing the latex-image-preamble contents.
# To be used by TikZImage objects as in:
# $image->addToPreamble(latexImagePreamble())

sub latexImagePreamble {
return <<'END_LATEX_IMAGE_PREAMBLE'
\usepackage{pgfplots}
\pgfplotsset{
    every axis/.append style={
        axis lines=middle,
        xlabel={$x$},
        ylabel={$y$},
        grid = both,
    }
}

END_LATEX_IMAGE_PREAMBLE
}
