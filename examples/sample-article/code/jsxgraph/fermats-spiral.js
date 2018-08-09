/* https://jsxgraph.uni-bayreuth.de/wiki/index.php/Fermat%27s_spiral */
/* Accessed August 2017                                              */

var board = JXG.JSXGraph.initBoard('jsxgraph-fermats-spiral', {boundingbox: [-10, 10, 10, -10]});
var aa = board.create('slider', [[1,9], [5,9], [0,1,4]], {name:'a'});
var c1 = board.create('curve', 
                      [function(phi){ return  aa.Value()*Math.sqrt(phi); }, [0, 0], 0, 8*Math.PI],
                      {curveType:'polar', strokewidth:4});
var c2 = board.create('curve', 
                      [function(phi){ return -aa.Value()*Math.sqrt(phi); }, [0, 0], 0, 8*Math.PI],
                      {curveType:'polar', strokewidth:4});
