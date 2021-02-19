size (3 inch,0);
import three ;
currentprojection = perspective (21,25,15);
currentlight = White;
real phi = (1+ sqrt (5))/2;
// Vertices of the icosahedron are of the form
// (0, \pm 1, \pm\ phi ), (\ pm\phi , 0, \pm 1),
// (\ pm 1, \pm\phi , 0)
triple [] Pts = {
  (0,1,phi), (0,-1,phi), (phi,0,1),
  (1,phi,0), (-1,phi,0), (-phi,0,1),
  (phi,0,-1), (0,1,-phi), (-phi,0,-1),
  (-1,-phi,0), (1,-phi,0), (0,-1,-phi)
  };
// Faces listed as triples (i,j,k) corresponding
// to the face through Pts [i], Pts [j] and Pts [k].
triple [] faces = {
  (0,1,2), (0,2,3), (0,3,4), (0,4,5), (0,5,1),
  (11,6,7), (11,7,8), (11,8,9), (11,9,10), (11,10,6),
  (10,1,2), (6,2,3), (7,3,4), (8,4,5), (9,5,1),
  (3,6,7), (4,7,8), (5,8,9), (1,9,10), (2,10,6)
  };
for(triple T: Pts) draw(shift(T)*scale3(.08)*unitsphere,lightyellow);
real t =2.5; // Scaling for stellation height
// Function to compute the stellation point
triple stell_point (triple u, triple v, triple w) {return t/3*( u+v+w);}
void stellate ( triple Face ) {
  int i= round ( Face .x),
  j= round ( Face .y),
  k= round ( Face .z);
  triple S= stell_point ( Pts [i], Pts [j], Pts [k ]);
  draw ( shift (S)* scale3 (.08)* unitsphere , yellow );
  draw (S--Pts[i], red );
  draw (S--Pts[j], red );
  draw (S--Pts[k], red );
  draw ( surface (S-- Pts [i]-- Pts [j]-- cycle ), lightgreen );
  draw ( surface (S-- Pts [i]-- Pts [k]-- cycle ), lightgreen );
  draw ( surface (S-- Pts [j]-- Pts [k]-- cycle ), lightgreen );
  draw (Pts[i]--Pts[j]--Pts[k]--cycle, red );
  }
for ( triple Face : faces ) stellate ( Face );
