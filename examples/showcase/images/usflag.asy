size(4cm,6cm);
pen usflagred=rgb(178/256,34/256,52/256);
pen usflagblue=rgb(60/256,59/256,110/256);
currentpen=linewidth(0.2pt);
real flagheight=2.0, flagwidth=3.8,
     unionheight=7/13*flagheight, unionwidth=2/5*flagwidth;
path flag_outline=scale(flagwidth,flagheight)*unitsquare;
path union_outline=scale(unionwidth,unionheight)*unitsquare;
path stripe=scale(flagwidth,1/13*flagheight)*unitsquare;
path unitstar=dir(90)--dir(234)--dir(18)--dir(162)--dir(306)--cycle;
path star=scale(0.0616)*unitstar;
pair union_origin=(0,6/13*flagheight);
real starhshift=unionwidth/12, starvshift=unionheight/10;
for (int k: sequence(13))
   if (k%2==0) fill(shift(0,k/13*flagheight)*stripe,usflagred);
fill(shift(union_origin)*union_outline, usflagblue);
for (int i: sequence(1,11))
   for (int j: sequence(1,9))
      if ((i+j)%2==0)
         fill(shift(union_origin+(i*starhshift,j*starvshift))*star,white);
draw(flag_outline);
