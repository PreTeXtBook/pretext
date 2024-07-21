/***************
 *  kinematics.js
 * 
 *  a jsxgraph interactive demo for 1-dimensional kinematics with constant acceleration
 * 
 *  in this example, a ball is thrown upward with an initial velocity of 30 m/s
 * 
 *  the user can use the time slider in board_t to vary the vertical displacement, velocity 
 *  and acceleration in the other boards
 * 
 *  Rick Roesler
 *  San Diego, CA
 *  YourPhysicsCoach@gmail.com
 * 
 ****************/

const displacement = (v0, a, t) => v0*t + 0.5*a*t*t;
const velocity = (v0, a, t) => v0 + a*t;
const acceleration = (v0, a, t) => a;

// initialize the board; we'll create our own custom axes
const newboard = (name,title,yaxislabel,units,tmin,tmax,ymin,ymax,f) => {
	brd = JXG.JSXGraph.initBoard(name, {boundingbox: [tmin, ymax, tmax, ymin], 
                      axis:false,
                      grid:false,
                      showCopyright:false,
                      showNavigation:false
                 });
    
    // add a title to the board in the upper right corner
    brd.create('text',[5,ymax-0.05*(ymax-ymin),title]);
    
    // create the x-axis (time)
    xaxis = brd.create('axis', [[-0.5, 0], [1,0]], {name:'t (s)', withLabel:true, label: {position: 'rt', offset: [-15, -15]}});

    // R. Beezer, 2024-04-19: upgrading JSXGraph to 1.0.8 causes
    // errors when trying to adjust tick marks,  So we comment-out
    // the manipulations and live with the result, since we cannot
    // find an adequate way to remove the defaults.  In particular
    //
    //       xaxis.removeTicks(xaxis.defaultTicks);
    //
    // as suggested by the JSXGraph wiki does not seem to work.
    // The only downside is that there are some tickmarks
    // with negative values

    // remove default tickmarks
    // R. Beezer, 2024-04-19: commented-out next line
    //xaxis.removeAllTicks();
  
    // create custom tickmarks
    // TODO - these values should not be hard-coded
    // R. Beezer, 2024-04-19: commented-out next line
    // brd.create('ticks',[xaxis,[1,2,3,4,5,6]], {drawLabels:true,label: {offset: [-3, -15]}});
    
    // create the y-axis
    yaxis = brd.create('axis', [[0, 0], [0,1]], {name:yaxislabel + ' ' + units, withLabel:true, label: {position: 'rt', offset: [10, 0]}});
    
    // plot the function 
    brd.create('functiongraph',[t => f(initialVelocity,gravAcceleration,t),0,6],{strokeColor:'#000000'});
    
    // create a gliding point along the function curve
    const x = brd.create('point',[() => time.Value(), () =>	f(initialVelocity,gravAcceleration,time.Value())],{name:''});
    
    // create the vector
    brd.create('arrow',[[-2,0],[-2,() => x.Y()]]);

    // hide the left-most part of the x (t) axis; we should be able to use xaxis.setStraight(false,true), but it's not working
	brd.create('polygon',[[-3,-0.5],[-3,0.5],[-0.5,0.5],[-0.5,-0.5],[-3,-0.5]],{color:'white', withLines:false, fillOpacity:1,vertices: {visible:false}});

	return brd;
}

// initialize vertical velocity and gravitational acceleration ("g")
const initialVelocity = 30;
const gravAcceleration = -10;

// create the time slider board; this will be the parent of the other boards
// TODO - seems like all this should be delegated to a function
const board_t = JXG.JSXGraph.initBoard('box_t', {boundingbox:[-3, 1.5, 7, -1],axis:false,showCopyright:false,showNavigation:false});

// add a title to the time slider
board_t.create('text',[5,0.9,'Time']);

// create the custom t-axis
taxis = board_t.create('axis', [[-0.5, 0], [1,0]], {name:'t (s)',withLabel:true,label: {position: 'rt',offset: [-15, -15]}});
taxis.setStraight(false,true);
// R. Beezer, 2024-04-19: commented-out next two lines
// taxis.removeAllTicks();
// board_t.create('ticks',[taxis,[1,2,3,4,5,6]], {drawLabels:true,label: {offset: [-3, -15]}});

// create the actual slider; the 'time' variable will be used in the other boards
const time = board_t.create('slider',[[0,0],[6,0],[0,0,6]]);

// create the displacement board
const board_s = newboard('box_s','Displacement','s','(m)',-3,7,-5,50,displacement);
board_t.addChild(board_s);

// create the velocity board
const board_v = newboard('box_v','Velocity','v','(m &middot s<sup>-1)',-3,7,-35,35,velocity);
board_t.addChild(board_v);

// create the acceleration board
const board_a = newboard('box_a','Acceleration','a','(m &middot s<sup>-2)',-3,7,-15,5,acceleration);
board_t.addChild(board_a);
