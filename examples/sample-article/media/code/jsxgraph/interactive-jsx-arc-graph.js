JXG.Options.text.useMathJax = true;

var board = JXG.JSXGraph.initBoard('jsx_1_5_arc_graph_fig', {
    boundingbox: [-4, 4, 4, -4],
    axis: true,
    showCopyright: false
});

const fx = (x) => -(x - 1) * (x - 1) + 3;

// small separation to enforce a < b
const eps = 8e-2;

var f = board.create('functiongraph', [
    function (x) { return fx(x); }
]);

var xptx = board.create('glider', [0, 0, f], {
    withLabel: false,
    color: 'red',
    size: 3
});

var bptx = board.create('glider', [2, 2, f], {
    withLabel: false,
    color: 'red',
    size: 3
});

var xlabel = board.create('text', [0.12, 0.12, 'a'], {
    anchor: xptx,
    // useMathJax: true,
    parse: false,
    // display: 'html',
    fixed: true,
    fontSize: 14
});

var blabel = board.create('text', [0.12, 0.12, 'b'], {
    anchor: bptx,
    // useMathJax: true,
    parse: false,
    // display: 'html',
    fixed: true,
    fontSize: 14
});


// enforce strict ordering a < b with epsilon separation
xptx.on('drag', function () {
    let a = xptx.X();
    let b = bptx.X();

    if (a >= b - eps) {
        a = b - eps;
        xptx.moveTo([a, fx(a)]);
    }
});

bptx.on('drag', function () {
    let a = xptx.X();
    let b = bptx.X();

    if (b <= a + eps) {
        b = a + eps;
        bptx.moveTo([b, fx(b)]);
    }
});

var arcline = board.create('line', [xptx, bptx], {
    straightFirst: false,
    straightLast: false
});

var arcfun = function () {
    const a = xptx.X();
    const b = bptx.X();
    const arc = (fx(b) - fx(a)) / (b - a);
    const arcround= arc.toFixed(2);
    return `\\(\\text{ARC} = \\frac{f(b)-f(a)}{b-a} = ${arcround}\\)`;
};

var arcformula = board.create('text', [-4, 3, arcfun
], {
    parse: false,
    fixed: true,
    fontSize: 14,
cssStyle: 'background-color: rgb(255,255,255)'
});