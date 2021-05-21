size(6cm,5cm);
path [] P ;
path Ellipse = shift(1.2,.2)*scale(3.25,1.5)*unitcircle;
pen [] Colourpen = {
   rgb(.45,.05,.05), rgb(.05,.45,.05), rgb(.05,.05,.40),
   rgb(.30,.30,0), rgb(.30,0,.30)
   };
picture pic;
for (int k: sequence(5)) {
   P[k]=rotate(k*72)*Ellipse;
   fill(P[k],Colourpen[k]);
   for (int l: sequence(k)) {
      fill(pic, P[k], Colourpen[k]+Colourpen[l]);
      clip(pic,P[l]);
      add(pic);
      for (int m: sequence(l)) {
         fill(pic, P[k], Colourpen[k]+Colourpen[l]+Colourpen[m]);
         clip(pic,P[l]); clip(pic,P[m]);
         add(pic);
         for (int n: sequence(m)) {
            fill(pic, P[k], Colourpen[k]+Colourpen[l]+Colourpen[m]+Colourpen[n]);
            clip(pic,P[l]); clip(pic,P[m]); clip(pic,P[n]);
            add(pic);
         }
      }
   }

}
fill(pic, P[0], Colourpen[0]+Colourpen[1]+Colourpen[2]+Colourpen[3]+Colourpen[4]);
for (int k: sequence(5)) {clip(pic,P[k]);}
for (int k: sequence(5)) {draw(P[k],linewidth(0.4));}
add(pic);
