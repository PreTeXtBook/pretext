/* http://jsxgraph.uni-bayreuth.de/showcase/infinity.html */
/* Accessed January 2017                                  */

JXG.Options.renderer = 'canvas';
var board = JXG.JSXGraph.initBoard('jsxgraph-infinity', {
        boundingbox: [-9, 8, 9, -10],
        keepaspectreatio: true,
        axis: false,
        grid: false,
        shownavigation: false
    });

// construction
board.suspendUpdate();
var S = board.create('slider', [[-5,-6],[5,-6],[0,0.85,1]], {
    name:'Whirl'
});
var hue = board.create('slider', [[-5,-7],[5,-7],[0,20.5,36]], {
    name:'Colors'
});

var points = new Array();
points[0] = board.create('point',[5, 5], {name:' '});
points[1] = board.create('point',[-5, 5], {name:' '});
points[2] = board.create('point',[-5, -5], {name:' '});
points[3] = board.create('point',[5, -5], {name:' '});

function quadrangle(pt, n) {
    var col;
    var arr = new Array();
    for(var i = 0; i < 4; i++) {
        arr[i] = board.create('point',
            [function(t) {
                return function () {var x = pt[t].X();
                        var x1 = pt[(t+1)%4].X();
                        var s = S.Value();
                        return x+(x1-x)*s;
                 }}(i),
            function(t) {
                return function () {var y = pt[t].Y();
                        var y1 = pt[(t+1)%4].Y();
                        var s = S.Value();
                        return y+(y1-y)*s;
                 }}(i)
            ],
        {size:1, name: "", withLabel: false, visible: false});
    }
    col =  function(){return JXG.hsv2rgb(hue.Value()*n,0.7,0.9);};
    board.create('polygon',pt, {fillColor:col});
    if(n>0)
        quadrangle(arr, --n);
}
quadrangle(points,30);

board.unsuspendUpdate();
