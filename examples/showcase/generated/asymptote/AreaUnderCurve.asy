usepackage("amsmath");

texpreamble("
\newcommand{\order}[1]{\left\lvert#1\right\rvert}
\newcommand{\lt}{<}
\newcommand{\gt}{>}
\newcommand{\amp}{&}
");


        import graph;
        size (3 inch,0);
        real f(real x) {return exp(-x^2);}
        real xmin=-2, xmax=2;
        real ymin=-.3, ymax=1.3;
        path g=graph(f,xmin,xmax, operator ..);
        path h=(xmax,f(xmax))--(xmax,0)--(xmin,0);
        fill(g--h--cycle,lightyellow);
        draw(g);
        label("$f(x)=e^{-x^2}$", (xmin,.7),.5*N);
        draw((xmin,.7){SSE}..{SE}(-.8,f(-.8)),Arrow);
        label("Area $=\sqrt\pi$",(xmax,.7),.5*N);
        draw((xmax,.7){S}..{W}(.3,.3),Arrow);
        draw((xmin,0)--(xmax,0));
        draw((0,ymin)--(0,ymax));
        