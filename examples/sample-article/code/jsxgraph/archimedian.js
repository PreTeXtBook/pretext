/* http://jsxgraph.uni-bayreuth.de/wiki/index.php/Archimedean_spiral */
/* Accessed January 2017                                             */

var board = JXG.JSXGraph.initBoard('jsxgraph-archimedian-spiral', {boundingbox: [-10, 10, 10, -10]});
var a = board.create('slider', [[1,8],[5,8],[0,1,4]], {name:'a'});
var b = board.create('slider', [[1,9],[5,9],[0,0.25,4]], {name:'b'});

var c = board.create('curve', 
                    [function(phi){ return a.Value()+b.Value()*phi; }, [0, 0], 0, 8*Math.PI],
                    {curveType:'polar', strokewidth:4}
);
var g = board.create('glider',  [c]);
var t = board.create('tangent', [g], {dash:2, strokeColor:'#a612a9'});
var n = board.create('normal',  [g], {dash:2, strokeColor:'#a612a9'});
