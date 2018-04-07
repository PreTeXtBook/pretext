/* From David Austin, 2018-04-05 */

var canvas = new Canvas("eigenvector", [-4,-4,4,4]);

canvas.margins = [5,5,5,5];
canvas.setUpCoordinates();

var update = function() {
    var ma = 1;
    var mb = 2;
    var mc = 2;
    var md = 1;
    var x = v.head[0];
    var y = v.head[1];
    Av.head = [ma*x + mb*y, mc*x + md*y];
    canvas.draw();
}

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


