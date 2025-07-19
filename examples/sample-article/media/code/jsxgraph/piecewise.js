/* From Lila Roberts (?), August 2017 */

var board_p3 = JXG.JSXGraph.initBoard('box_p3', {boundingbox: [-6, 8, 4, -8], axis: true,grid:true,showCopyright:false,showNavigation:false});

var board2_p3 = JXG.JSXGraph.initBoard('box2_p3', {boundingbox: [-6, 8, 4, -8],axis:true,grid:true,showCopyright:false,showNavigation:false});
var board3_p3 = JXG.JSXGraph.initBoard('box3_p3', {boundingbox: [-6, 8, 4, -8],axis:true,grid:true,showCopyright:false,showNavigation:false});
board_p3.renderer.container.style.backgroundColor = '#ffcc99';          // background color board
board2_p3.renderer.container.style.backgroundColor = '#ffcc99';
board3_p3.renderer.container.style.backgroundColor = '#ffcc99';
var xax1_p3 = board_p3.create('axis', [[0,0], [0,1]]);
var yax1_p3 = board_p3.create('axis', [[0,0], [1,0]]);
var xax2_p3 = board2_p3.create('axis', [[0,0], [0,1]]);
var yax2_p3 = board2_p3.create('axis',[[0,0],[1,0]]);
var xax3_p3 = board3_p3.create('axis',[[0,0], [0,1]]);
var yax3_p3 = board3_p3.create('axis',[[0,0],[1,0]]);
board_p3.create('ticks',[xax1_p3,[-6,-5,-4,-3,-2,-1,0,1,2,3,4]]);
board_p3.create('ticks',[yax1_p3,[-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8]]);
board2_p3.create('axis', [[0,0], [0,1]]);
board2_p3.create('ticks',[xax2_p3,[-6,-5,-4,-3,-2,-1,0,1,2,3,4]]);
board2_p3.create('ticks',[yax2_p3,[-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8]]);
board3_p3.create('axis',[[0,0],[0,1]]);
board3_p3.create('ticks',[xax3_p3,[-6,-5,-4,-3,-2,-1,0,1,2,3,4]]);
board3_p3.create('ticks',[yax3_p3,[-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8]]);

var f_p3 = function(x) {
    if (x >=-4 && x < 1) {
        return -(x+2)*(x+2) + 2;
    }
    else if (x >= 1 && x <= 3) {
        return x*x-x;
    }
    else {return -1000;
    }
};

var dfun_p3 = function(x) {
    if (x>=-4 && x<0.7) {
        return x;
    }
    else if (x> 1.3 && x <= 3) {
        return x;
    }
    else {return -1000;
    }
};

graph_p3=board_p3.create('functiongraph',[f_p3,-4,3],{strokeColor:'#000000'});
var ep1_p3=board_p3.create('point',[-4,-2],{strokeColor:'#000000',fillColor:'#000000',name:''});
var ep2_p3=board_p3.create('point',[1,-7],{strokeColor:'#000000',fillColor:'#FFFFFF',name:''});
var ep3_p3=board_p3.create('point',[1,0],{strokeColor:'#000000',fillColor:'#FFFFFF',name:''});
var ep4_p3=board_p3.create('point',[3,6],{strokeColor:'#000000',fillColor:'#000000',name:''});
ep1_p3.setAttribute({fixed:true});
ep2_p3.setAttribute({fixed:true});
ep3_p3.setAttribute({fixed:true});
ep4_p3.setAttribute({fixed:true});

var s_p3 = board_p3.create('slider',[[-4.5,-7],[-1,-7],[-4,-4,3]]);
var tracepoint_p3=board_p3.create('point',[function() {return dfun_p3(s_p3.Value());},function() {return f_p3(s_p3.Value());}],{name:''});
// domain:
var b2p1_p3 = board2_p3.create('point', [function(){return tracepoint_p3.X()},0], 
            {fixed: true, trace: true, strokeColor: '#ff0000', name: 'D'});
// cosine:
var b2p2_p3 = board3_p3.create('point', [
            0, function(){return tracepoint_p3.Y();}], 
            {fixed: true, trace: true, strokeColor: '#0000ff', fillColor:'#0000ff',name: 'R'});
// Dependencies (only necessary if b2p1 or b2p2 is deleted)

board_p3.addChild(board2_p3);
board_p3.addChild(board3_p3);

function clearTraces_p3() {
JXG.JSXGraph.freeBoard(board_p3);
JXG.JSXGraph.freeBoard(board2_p3);
JXG.JSXGraph.freeBoard(board3_p3);
board_p3 = JXG.JSXGraph.initBoard('box_p3', {boundingbox: [-6, 8, 4, -8],axis: true,grid:true,showCopyright:false,showNavigation:false});
board2_p3 = JXG.JSXGraph.initBoard('box2_p3', {boundingbox: [-6, 8, 4, -8],axis:true,grid:true,showCopyright:false,showNavigation:false});
board3_p3 = JXG.JSXGraph.initBoard('box3_p3', {boundingbox: [-6, 8, 4, -8],axis:true,grid:true,showCopyright:false,showNavigation:false});
xax1_p3 = board_p3.create('axis', [[0,0], [0,1]]);
yax1_p3 = board_p3.create('axis', [[0,0], [1,0]]);
xax2_p3 = board2_p3.create('axis', [[0,0], [0,1]]);
yax2_p3 = board2_p3.create('axis',[[0,0],[1,0]]);
xax3_p3 = board3_p3.create('axis',[[0,0], [0,1]]);
yax3_p3 = board3_p3.create('axis',[[0,0],[1,0]]);
board_p3.create('ticks',[xax1_p3,[-6,-5,-4,-3,-2,-1,0,1,2,3,4]]);
board_p3.create('ticks',[yax1_p3,[-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8]]);
board2_p3.create('axis', [[0,0], [0,1]]);
board2_p3.create('ticks',[xax2_p3,[-6,-5,-4,-3,-2,-1,0,1,2,3,4]]);
board2_p3.create('ticks',[yax2_p3,[-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8]]);
board3_p3.create('axis',[[0,0],[0,1]]);
board3_p3.create('ticks',[xax3_p3,[-6,-5,-4,-3,-2,-1,0,1,2,3,4]]);
board3_p3.create('ticks',[yax3_p3,[-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8]]);

f_p3 = function(x) {
    if (x >=-4 && x < 1) {
        return -(x+2)*(x+2) + 2;
    }
    else if (x >= 1 && x <= 3) {
        return x*x-x;
    }
    else {return -1000;
    }
};

dfun_p3 = function(x) {
    if (x>=-4 && x<0.7) {
        return x;
    }
    else if (x> 1.3 && x <= 3) {
        return x;
    }
    else {return -1000;
    }
};

graph_p3=board_p3.create('functiongraph',[f_p3,-4,3],{strokeColor:'#000000'});
ep1_p3=board_p3.create('point',[-4,-2],{strokeColor:'#000000',fillColor:'#000000',name:''});
ep2_p3=board_p3.create('point',[1,-7],{strokeColor:'#000000',fillColor:'#FFFFFF',name:''});
ep3_p3=board_p3.create('point',[1,0],{strokeColor:'#000000',fillColor:'#FFFFFF',name:''});
ep4_p3=board_p3.create('point',[3,6],{strokeColor:'#000000',fillColor:'#000000',name:''});
ep1_p3.setAttribute({fixed:true});
ep2_p3.setAttribute({fixed:true});
ep3_p3.setAttribute({fixed:true});
ep4_p3.setAttribute({fixed:true});
s_p3 = board_p3.create('slider',[[-4.5,-7],[-1,-7],[-4,-4,3]]);
tracepoint_p3=board_p3.create('point',[function() {return dfun_p3(s_p3.Value());},function() {return f_p3(s_p3.Value());}],{name:''});// domain:
b2p1_p3 = board2_p3.create('point', [function(){return tracepoint_p3.X()},0], 
             {fixed: true, trace: true, strokeColor: '#ff0000', name: 'D'});
// cosine:
b2p2_p3 = board3_p3.create('point', [
             0, function(){return tracepoint_p3.Y();}], 
             {fixed: true, trace: true, strokeColor: '#0000ff', fillColor:'#0000ff',name: 'R'});
// Dependencies (only necessary if b2p1 or b2p2 is deleted)

board_p3.addChild(board2_p3);
board_p3.addChild(board3_p3);
}
// Animation
var animated = false;
function animate_p3(point, direction, count) {
   if(animated) {
      point.stopAnimation();
      animated = false;
   } else {
      point.startAnimation(direction, count);
      animated = true;
   }
}
// Generic Hide/Show
function toggle(id) {
        var state = document.getElementById(id).style.display;
            if (state == 'block') {
                document.getElementById(id).style.display = 'none';
            } else {
                document.getElementById(id).style.display = 'block';
            }
        }
