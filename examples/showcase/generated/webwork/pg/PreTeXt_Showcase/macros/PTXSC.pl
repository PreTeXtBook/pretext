#############################################################################
# This macro library supports WeBWorK problems from the PreTeXt project named
# PreTeXt Showcase
#############################################################################


# Return a string containing the latex-image-preamble contents.
# To be used by LaTeXImage objects as in:
# $image->addToPreamble(latexImagePreamble())

sub latexImagePreamble {
return <<'END_LATEX_IMAGE_PREAMBLE'
\usepackage{tikz}
\usepackage{pgfplots}
\usetikzlibrary{positioning} % for worksheet
\usepackage{pstricks}
\usepackage{phaistos}
\usepackage{xcolor}

END_LATEX_IMAGE_PREAMBLE
}
