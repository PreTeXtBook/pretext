#############################################################################
# This macro library supports WeBWorK problems from the PreTeXt project named
# Integrating WeBWorK into Textbooks
#############################################################################


TEXT(
    MODES(
        HTML => '<div style="display:none;">' . general_math_ev3(<<'EOF') . '</div>',
\newcommand{\definiteintegral}[4]{\int_{#1}^{#2}\,#3\,d#4}
\newcommand{\indefiniteintegral}[2]{\int#1\,d#2}
\newcommand{\amp}{&}
EOF
        TeX => '\ifdefined\ptxmacros\else ' . <<'EOF'
\newcommand{\definiteintegral}[4]{\int_{#1}^{#2}\,#3\,d#4}
\newcommand{\indefiniteintegral}[2]{\int#1\,d#2}
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
\usepackage{pgfplots}
\pgfplotsset{
    every axis/.append style={
        axis lines=middle,
        xlabel={\(x\)},
        ylabel={\(y\)},
        grid = both,
    }
}

END_LATEX_IMAGE_PREAMBLE
}

1;
