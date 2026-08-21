#############################################################################
# This macro library supports WeBWorK problems from the PreTeXt project named
# PreTeXt Showcase
#############################################################################


TEXT(
    MODES(
        HTML => '<div style="display:none;">' . general_math_ev3(<<'EOF') . '</div>',
\newcommand{\order}[1]{\left\lvert#1\right\rvert}
\newcommand{\amp}{&}
EOF
        TeX => '\ifdefined\ptxmacros\else ' . <<'EOF'
\newcommand{\order}[1]{\left\lvert#1\right\rvert}
\newcommand{\amp}{&}
\def\ptxmacros{}
EOF
. '\fi',
        PTX => ''
    )
);

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

1;
