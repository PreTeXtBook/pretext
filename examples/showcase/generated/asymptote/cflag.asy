usepackage("amsmath");

texpreamble("
\newcommand{\order}[1]{\left\lvert#1\right\rvert}
\newcommand{\lt}{<}
\newcommand{\gt}{>}
\newcommand{\amp}{&}
");


        size(4cm,6cm);
        pen canadared=rgb(235/256,45/256,55/256);
        real flagwidth=4, flagheight=2;
        path flag_outline=scale(flagwidth,flagheight)*unitsquare;
        path  cbar1=scale(1,2)*unitsquare, cbar2=shift(3,0)*cbar1;
        path mapleleafleft=
        (0,-102) --(-5,-102)--(-2,-56) {dir(87)}..{dir(190)}
        (-8,-53) --(-51,-61)--(-45,-45){dir(70)}..{dir(141)}
        (-46,-41)--(-94,-3) --(-82,1)  {dir(25)}..{dir(108)}
        (-81,6)  --(-90,34) --(-63,29) {dir(348)}..{dir(67)}
        (-59,30) --(-54,43) --(-33,20) {dir(313)}..{dir(101)}
        (-27,23) --(-38,76) --(-21,62) {dir(330)}..{dir(63)}
        (-16,67) --(0,100);
        path mapleleafright=reflect((0,0),(0,1))*reverse(mapleleafleft);
        path mapleleaf=mapleleafleft--mapleleafright--cycle;
        filldraw(flag_outline,white,black);
        fill(cbar1,canadared);
        fill(cbar2,canadared);
        fill(shift(2,1)*scale(.008)*mapleleaf,canadared);
        draw(flag_outline);
        