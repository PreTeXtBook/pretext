/* From David Austin, 2018-04-05 */

var matrix = new Canvas("sliders", [0,0, 2,2]);
var canvas = new Canvas("eigenvectors", [-4,-4,4,4]);

matrix.margins = [20,5,20,5];
matrix.setUpCoordinates();
canvas.margins = [5,5,5,5];
canvas.setUpCoordinates();

var dx = 0.05;
var mkslider = function(xr, y) {
    var s = new Slider(xr, y, [-2,2], update);
    s.ticks = [-2,1,2]
    s.labels = [-2,1,2]
    s.point.style = "box";
    s.point.fillColor = "blue"
    s.point.size = 4;
    matrix.addPlotable(s);
    matrix.addMoveable(s);
    return s;
}

var update = function() {
    var ma = a.coordinate();
    var mb = b.coordinate();
    var mc = c.coordinate();
    var md = d.coordinate();
    var x = v.head[0];
    var y = v.head[1];
    Av.head = [ma*x + mb*y, mc*x + md*y];
    matrix.draw();
    canvas.draw();
}

var a = mkslider([dx, 1-2*dx], 1.5);
var b = mkslider([1+2*dx, 2-dx], 1.5);
var c = mkslider([dx, 1-2*dx], 0.5);
var d = mkslider([1+2*dx, 2-dx], 0.5);
a.init(1);
b.init(0);
c.init(0);
d.init(1);

var grid = new Grid([-4,1,4], [-4,1,4]);
canvas.addPlotable(grid);

var axes = new Axes();
canvas.addPlotable(axes);

var v = new Vector([1,0]);
v.move = function(p) {
    v.head = p;
    update();
}
v.fillColor = "red";

var Av = new Vector([1,0]);
Av.fillColor = "gray";
canvas.addPlotable(Av);
canvas.addPlotable(v);
canvas.addMoveable(v);

update();


