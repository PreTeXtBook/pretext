size(4cm,6cm);
pen euflagblue=rgb(31/256,68/256,186/256);
pen euflagyellow=rgb(254/256,203/256,11/256);
real flagheight=2.0, flagwidth=3;
path flag_outline=shift(-flagwidth/2,-flagheight/2)*scale(flagwidth,flagheight)*unitsquare;
filldraw(flag_outline,euflagblue);
path unitstar=dir(90)--dir(234)--dir(18)--dir(162)--dir(306)--cycle;
path star=scale(1/9)*unitstar;
for(int k: sequence(12)) {fill(shift(2/3*dir(k*30))*star,euflagyellow);}

