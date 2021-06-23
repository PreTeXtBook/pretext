/* From David Austin, 2018-04-05 */

function Canvas(id, bbox) {
    this.id = id
    var element = document.getElementById(id);
    this.elem = element;
    this.ctx = element.getContext("2d");

    this.plotables = []
    element.moveables = []
    element.moving = null;
    element.container = this;

    this.addPlotable = function(p) {
	if (!Array.isArray(p)) {
	    var p = [p];
	}
	for (i in p) {
	    this.plotables.push(p[i]);
	    p[i].setContext(this.transform, this.ctx, this.bbox);
	}
    }
    this.addMoveable = function(m) {
	if (!Array.isArray(m)) {
	    m = [m];
	}
	for (i in m) {
	    element.moveables.push(m[i]);
	}
    }

    this.resetPlotables = function() {
	for (var i = 0; i < this.plotables.length; i++) {
	    this.plotables[i].setContext(this.transform, this.ctx, this.bbox);
	}
    }

    this.draw = function() {
	this.ctx.clearRect(0,0,element.width,element.height);
	for (i in this.plotables) {
	    var p = this.plotables[i];
	    p.draw();
	}
    }

    this.margins = [0,0,0,0]
    this.transform = new AffineTransform();

    this.setUpCoordinates = function(bbox) {
	this.transform = new AffineTransform();
	var sx = (element.width-this.margins[0]-this.margins[2]) /
	    (this.bbox[2] - this.bbox[0]);
	var sy = (element.height-this.margins[1]-this.margins[3]) /
	    (this.bbox[3] - this.bbox[1]);
	this.transform.translate([this.margins[0],
				  element.height-this.margins[1]]);
	this.transform.scale([sx, -sy]);
	this.transform.translate([-this.bbox[0], -this.bbox[1]]);
    }

    this.bbox = bbox;
    this.setUpCoordinates(bbox);

    element.onmousedown = function(event) {
	var x = event.offsetX;
	var y = event.offsetY;
	for (i in this.moveables) {
	    if (this.moveables[i].hit(x,y)) {
		this.moving = this.moveables[i];
		var p = this.container.transform.inverseTransformPoint([x,y]);
		this.moving.move(p);
		return;
	    }
	}

    }
    element.onmousemove = function(event) {
	if (this.moving == null) return;
	var x = event.offsetX;
	var y = event.offsetY;
	var p = this.container.transform.inverseTransformPoint([x,y]);
	this.moving.move(p);

    }
    element.onmouseup = function(event) {
	if (this.moving == null) return;
	var x = event.offsetX;
	var y = event.offsetY;
	var p = this.container.transform.inverseTransformPoint([x,y]);
	this.moving.move(p);
	this.moving = null;

    }
    element.onmouseout = function(event) {
	this.moving = null;
    }
}

function AffineTransform() {
    this.matrix = [[1,0,0], [0,1,0], [0,0,1]]
    this.inverse = [[1,0,0], [0,1,0], [0,0,1]]
    var multiply = function(m1, m2) {
	r = [[0,0,0], [0,0,0], [0,0,0]]
	for (var i = 0; i < m1.length; i++) {
	    for (var j = 0; j < m2[0].length; j++) {
		for (var k = 0; k < m2.length; k++) {
		    r[i][j] += m1[i][k] * m2[k][j]
		}
	    }
	}
	return r;
    }
    var multiplyVector = function(m, v) {
	var p = [0, 0, 0];
	for (var i = 0; i < m.length; i++) {
	    for (var j = 0; j < v.length; j++) {
		p[i] += m[i][j] * v[j];
	    }
	}
	return p.slice(0, v.length);
    }
    this.printMatrix = function() {
	console.log(this.matrix[0]);
	console.log(this.matrix[1]);
    }
    this.compose = function(transform) {
	this.matrix = multiply(this.matrix, transform.matrix);
	this.inverse = multiply(transform.inverse, this.inverse);
    }
    this.scale = function(s) {
	var sx = s[0];
	var sy = s[0];
	if (s.length == 2) sy = s[1];
	var af = new AffineTransform();
	af.matrix = [[sx, 0, 0], [0, sy, 0], [0,0,1]];
	af.inverse = [[1.0/sx, 0, 0], [0, 1.0/sy, 0], [0,0,1]];
	this.compose(af);
    }
    this.translate = function(t) {
	var tx = t[0];
	var ty = t[1];
	var af = new AffineTransform();
	af.matrix = [[1, 0, tx], [0, 1, ty], [0,0,1]];
	af.inverse = [[1, 0, -tx], [0, 1.0, -ty], [0,0,1]];
	this.compose(af);
    }
    this.rotate = function(angle) {
	var af = new AffineTransform();
	af.matrix = [[Math.cos(angle), -Math.sin(angle), 0],
		     [Math.sin(angle), Math.cos(angle), 0],
		     [0,0,1]];
	af.inverse = [[Math.cos(angle), Math.sin(angle), 0],
		     [-Math.sin(angle), Math.cos(angle), 0],
		     [0,0,1]];
	this.compose(af);
    }
    this.rotateDeg = function(angle) {
	this.rotate(angle * Math.PI / 180.0);
    }
    this.transformPoint = function(p) {
	p = p.slice(0);
	p.push(1);
	p = multiplyVector(this.matrix, p)
	return p.slice(0,2);
    }
    this.inverseTransformPoint = function(p) {
	p = p.slice(0);
	p.push(1);
	p = multiplyVector(this.inverse, p);
	return p.slice(0,2);
    }
}

function Plotable() {
    this.fillColor = "black";
    this.strokeColor = "black";
    this.lineWidth = 1;
    this.lineDash = null;
    this.transform = null;
    this.ctx = null;
    this.bbox = null;
    this.fontsize = 14;
    this.font = this.fontsize + "px Arial";
    this.setContext = function(t, c, b) {
	this.transform = t;
	this.ctx = c;
	this.bbox = b;
    }
    this.moveTo = function(p) {
	p = this.transform.transformPoint(p);
	this.ctx.moveTo(p[0], p[1]);
    }
    this.lineTo = function(p) {
	p = this.transform.transformPoint(p);
	this.ctx.lineTo(p[0], p[1]);
    }
    this.textAt = function(s, p, offset, align) {
	this.ctx.save();
	p = this.transform.transformPoint(p);
	this.ctx.translate(p[0], p[1]);
	this.ctx.translate(offset[0], offset[1]);
	this.ctx.font = this.font;
	this.ctx.textAlign = align;
	this.ctx.fillText(s, 0, 0);
	this.ctx.restore();
    }
    this.fill = function() {
	if (this.fillColor != null) {
	    this.ctx.fillStyle = this.fillColor;
	    this.ctx.fill();
	}
    }
    this.stroke = function() {
	if (this.strokeColor != null) {
	    this.ctx.lineWidth = this.lineWidth;
	    this.ctx.strokeStyle = this.strokeColor;
	    if (this.lineDash != null) this.ctx.setLineDash(this.lineDash);
	    this.ctx.stroke();
	}
    }
}

function Label(s, p) {
    this.s = s;
    this.p = p;
    this.offset = [0,0];
    this.align = "center"
    this.font = "italic 14px arial";
    this.draw = function() {
	this.ctx.save();
	p = this.transform.transformPoint(this.p);
	this.ctx.translate(p[0], p[1]);
	this.ctx.translate(this.offset[0], -this.offset[1]);
	this.ctx.font = this.font;
	this.ctx.textAlign = this.align;
	this.ctx.fillText(s, 0, 0);
	this.ctx.restore();
    }
}
Label.prototype = new Plotable();

function Grid(rx, ry) {
    this.rx = rx;
    this.ry = ry;
    this.strokeColor = "lightgray";
    this.draw = function() {
	this.ctx.save();
	this.ctx.strokeStyle = this.strokeColor;
	this.ctx.lineWidth = this.lineWidth;
	this.ctx.beginPath();
	for (var x = this.rx[0]; x <= this.rx[2]; x += this.rx[1]) {
	    this.moveTo([x, this.bbox[1]]);
	    this.lineTo([x, this.bbox[3]]);
	}
	for (var y = this.ry[0]; y <= this.ry[2]; y += this.ry[1]) {
	    this.moveTo([this.bbox[0], y]);
	    this.lineTo([this.bbox[2], y]);
	}
	this.ctx.stroke();
	this.ctx.restore();
    }
}

Grid.prototype = new Plotable();

function TGrid(a1, a2) {
    this.a1 = a1;
    this.a2 = a2;
    this.strokeColor = "lightgray";
    this.draw = function() {
	this.ctx.save();
	this.ctx.strokeStyle = this.strokeColor;
	this.ctx.lineWidth = this.lineWidth;

	this.ctx.beginPath()
	this.moveTo([this.bbox[0], this.bbox[1]]);
	this.lineTo([this.bbox[2], this.bbox[1]]);
	this.lineTo([this.bbox[2], this.bbox[3]]);
	this.lineTo([this.bbox[0], this.bbox[3]]);
	this.ctx.closePath();
	this.ctx.clip();

	this.ctx.beginPath();
	var num = 100;
	for (var i = -num; i <= num; i++) {
	    this.moveTo(vadd(smult(i, this.a1), smult(-num,this.a2)));
	    this.lineTo(vadd(smult(i, this.a1), smult(num,this.a2)));
	}
	for (var i = -num; i <= num; i++) {
	    this.moveTo(vadd(smult(i, this.a2), smult(-num,this.a1)));
	    this.lineTo(vadd(smult(i, this.a2), smult(num,this.a1)));
	}

	this.ctx.stroke();
	this.ctx.restore();
    }
}
TGrid.prototype = new Plotable();

function Axes() {
    this.ticks = null;
    this.labels = null;
    this.draw = function() {
	this.ctx.save();
	this.ctx.strokeStyle = this.strokeColor;
	this.ctx.beginPath();
	this.moveTo([this.bbox[0], 0]);
	this.lineTo([this.bbox[2], 0]);
	this.moveTo([0, this.bbox[1]]);
	this.lineTo([0, this.bbox[3]]);
	this.ctx.stroke();

	if (this.ticks != null) {
	    if (this.ticks[0] != null) this.drawHTicks();
	    if (this.ticks[1] != null) this.drawVTicks();
	}
	if (this.labels != null) {
	    if (this.labels[0] != null) this.drawHLabels();
	    if (this.labels[1] != null) this.drawVLabels();
	}
	this.ctx.restore();
    }

    var ticksize = 4;
    this.drawHTicks = function() {
	for (var x = this.ticks[0][0]; x <= this.ticks[0][2];
	     x += this.ticks[0][1]) {
	    if (Math.abs(x) < 1e-10) continue;
	    this.ctx.save();
	    var p = this.transform.transformPoint([x, 0]);
	    this.ctx.translate(p[0], p[1]);
	    this.ctx.lineWidth = 2;
	    this.ctx.beginPath();
	    this.ctx.moveTo(0, -ticksize);
	    this.ctx.lineTo(0, ticksize);
	    this.ctx.stroke();
	    this.ctx.restore();
	}
    }
    this.drawVTicks = function() {
	for (var y = this.ticks[1][0]; y <= this.ticks[1][2];
	     y += this.ticks[1][1]) {
	    if (Math.abs(y) < 1e-10) continue;
	    this.ctx.save();
	    var p = this.transform.transformPoint([0, y]);
	    this.ctx.translate(p[0], p[1]);
	    this.ctx.lineWidth = 2;
	    this.ctx.beginPath();
	    this.ctx.moveTo(-ticksize,0);
	    this.ctx.lineTo(ticksize,0);
	    this.ctx.stroke();
	    this.ctx.restore();
	}
    }
    this.drawHLabels = function() {
	for (var x = this.labels[0][0]; x <= this.labels[0][2];
	     x += this.labels[0][1]) {
	    if (Math.abs(x) < 1e-10) continue;
	    this.textAt(x, [x,0], [0, ticksize + this.fontsize], "center");
	}
    }
    this.drawVLabels = function() {
	for (var y = this.labels[1][0]; y <= this.labels[1][2];
	     y += this.labels[1][1]) {
	    if (Math.abs(y) < 1e-10) continue;
	    this.textAt(y, [0,y], [-ticksize-2,this.fontsize/2.0-2], "right");
	}

    }
}
Axes.prototype = new Plotable();

function Slider(rx, y, sx, update) {
    this.rx = rx; // coordinates in canvas
    this.y = y;
    this.sx = sx; // coordinates of slider
    this.ratioPerPix = (sx[1]-sx[0])/(rx[1]-rx[0])
    this.point = new Point([rx[0], y]);
    this.update = update;
    this.init = function(x) {
	this.point.point = [this.toPix(x),this.y];
    }
    this.toPix = function(x) {
	return (x-this.sx[0])/this.ratioPerPix + this.rx[0];
    }
    this.fromPix = function(x) {
	return (x-this.rx[0])*this.ratioPerPix + this.sx[0];
    }
    this.draw = function() {
	this.ctx.save();
	this.ctx.beginPath();
	this.moveTo([this.rx[0], this.y]);
	this.lineTo([this.rx[1], this.y]);
	this.stroke();
	if (this.ticks != null) this.drawTicks();
	if (this.labels != null) this.drawLabels();
	this.point.ctx = this.ctx;
	this.point.transform = this.transform;
	this.point.draw();
	this.ctx.restore();
    }
    this.hit = function(x, y) {
	return this.point.hit(x,y);
    }
    this.move = function(p) {
	var x = p[0];
	if (x < this.rx[0] || x > this.rx[1]) return;
	this.point.point = [x, this.y]
	this.update();
    }
    this.coordinate = function() {
	return this.fromPix(this.point.point[0]);
    }
    var ticksize = 4;
    this.drawTicks = function() {
	for (var x = this.ticks[0]; x <= this.ticks[2];
	     x += this.ticks[1]) {
	    this.ctx.save();
	    var p = this.transform.transformPoint([this.toPix(x), this.y]);
	    this.ctx.translate(p[0], p[1]);
	    this.ctx.lineWidth = 2;
	    this.ctx.beginPath();
	    this.ctx.moveTo(0, -ticksize);
	    this.ctx.lineTo(0, ticksize);
	    this.ctx.stroke();
	    this.ctx.restore();
	}
    }
    this.drawLabels = function() {
	for (var x = this.labels[0]; x <= this.labels[2];
	     x += this.labels[1]) {
	    this.textAt(x, [this.toPix(x),this.y],
			[0, ticksize + this.fontsize], "center");
	}
    }
}
Slider.prototype = new Plotable();
    
function VSlider(x, ry, sy, update) {
    this.x = x;
    this.ry = ry; // coordinates in canvas
    this.sy = sy; // coordinates of slider
    this.ratioPerPix = (sy[1]-sy[0])/(ry[1]-ry[0])
    this.point = new Point([x, ry[0]]);
    this.update = update;
    this.init = function(y) {
	this.point.point = [this.x, this.toPix(y)];
    }
    this.toPix = function(y) {
	return (y-this.sy[0])/this.ratioPerPix + this.ry[0];
    }
    this.fromPix = function(y) {
	return (y-this.ry[0])*this.ratioPerPix + this.sy[0];
    }
    this.draw = function() {
	this.ctx.save();
	this.ctx.beginPath();
	this.moveTo([this.x, this.ry[0]]);
	this.lineTo([this.x, this.ry[1]]);
	this.stroke();
	if (this.ticks != null) this.drawTicks();
	if (this.labels != null) this.drawLabels();
	this.point.ctx = this.ctx;
	this.point.transform = this.transform;
	this.point.draw();
	this.ctx.restore();
    }
    this.hit = function(x, y) {
	return this.point.hit(x,y);
    }
    this.move = function(p) {
	var y = p[1];
	if (y < this.ry[0] || y > this.ry[1]) return;
	this.point.point = [this.x, y]
	this.update();
    }
    this.coordinate = function() {
	return this.fromPix(this.point.point[1]);
    }
    var ticksize = 4;
    this.drawTicks = function() {
	for (var y = this.ticks[0]; y <= this.ticks[2];
	     y += this.ticks[1]) {
	    this.ctx.save();
	    var p = this.transform.transformPoint([this.x, this.toPix(y)]);
	    this.ctx.translate(p[0], p[1]);
	    this.ctx.lineWidth = 2;
	    this.ctx.beginPath();
	    this.ctx.moveTo(-ticksize, 0);
	    this.ctx.lineTo(ticksize, 0);
	    this.ctx.stroke();
	    this.ctx.restore();
	}
    }
    this.drawLabels = function() {
	for (var y = this.labels[0]; y <= this.labels[2];
	     y += this.labels[1]) {
	    this.textAt(y, [this.x, this.toPix(y)],
			[-10, 5], "center");
	}
    }
}
VSlider.prototype = new Plotable();
    
function Function(f) {
    this.f = f;
    this.dx = 0.0001;
    this.value = function(x) {
	return this.f(x);
    }
    this.derivative = function(x) {
	return (this.f(x+this.dx) - this.f(x-this.dx)) / (2*this.dx);
    }
    this.secondDerivative = function(x) {
	return (this.f(x+this.dx) - 2*this.f(x) + this.f(x-this.dx))/
	    (this.dx*this.dx)
    }
    this.integral = function(x, a) {
	var N = 64;
	var h = (x - a)/N;
	var x = a;
	var sum = 0;
	for (var i = 0; i < N/2; i++ ) {
	    sum += this.f(x) + 4*this.f(x+h) + this.f(x+2*h);
	    x += 2*h;
	}
	return sum*h/3.0;
    }
}
function Antiderivative(f, a) {
    this.f = f;
    this.a = a;
    this.value = function(x) {
	return this.f.integral(x, this.a);
    }
}
Antiderivative.prototype = new Function();

function Graph(f) {
    this.f = f;
    this.domain = null;
    this.N = 100;
    this.draw = function() {
	if (this.domain == null) {
	    this.domain = [this.bbox[0], this.bbox[2]];
	}
	var x = this.domain[0];
	var dx = (this.domain[1] - this.domain[0])/this.N;
	this.ctx.save();
	this.ctx.beginPath();
	this.moveTo([x, this.f.value(x)]);
	for (var i = 0; i < this.N; i++) {
	    x += dx;
	    this.lineTo([x,this.f.value(x)]);
	}
	this.ctx.lineWidth = this.lineWidth;
	this.ctx.strokeStyle = this.strokeColor;
	if (this.lineDash != null) this.ctx.setLineDash(this.lineDash);
	this.ctx.stroke();
	this.ctx.restore();
    }
}
Graph.prototype = new Plotable();

function ParametricCurve(x, y, domain) {
    this.x = x;
    this.y = y;
    this.N = 100;
    this.domain = domain;
    this.draw = function() {
	var t = this.domain[0];
	var dt = (this.domain[1]-this.domain[0])/this.N;
	this.ctx.save();
	this.ctx.beginPath();
	this.moveTo([this.x(t), this.y(t)]);
	for (var i = 0; i < this.N; i++) {
	    t += dt
	    this.lineTo([this.x(t), this.y(t)]);
	}
	this.stroke();
	this.ctx.restore();
    }
}
ParametricCurve.prototype = new Plotable();

function Rectangle(ll, dims) {
    this.ll = ll;
    this.dims = dims;
    this.draw = function() {
	var ur = vadd(this.ll, this.dims);
	this.ctx.save();
	this.ctx.beginPath();
	this.moveTo(this.ll);
	this.lineTo([ur[0], this.ll[1]]);
	this.lineTo(ur);
	this.lineTo([this.ll[0], ur[1]]);
	this.ctx.closePath();
	this.fill();
	this.stroke();
	this.ctx.restore();
    }
}
Rectangle.prototype = new Plotable();

function Polygon(points) {
    this.points = points;
    this.draw = function() {
	this.ctx.save();
	this.ctx.beginPath();
	this.moveTo(this.points[0]);
	for (var i = 1; i < this.points.length; i++) {
	    this.lineTo(this.points[i]);
	}
	this.ctx.closePath();
	this.fill();
	this.stroke();
	this.ctx.restore();
    }
}
Polygon.prototype = new Plotable();

function AreaBetweenCurves(f) {
    this.f = f;
    this.g = function(x) {return 0};
    this.N = 100;
    this.domain = null;
    this.draw = function() {
	if (this.domain == null) {
	    this.domain = [this.bbox[0], this.bbox[2]];
	}
	if (this.domain[1] == this.domain[0]) return;
	var x = this.domain[0];
	var dx = (this.domain[1] - this.domain[0])/this.N;
	this.ctx.save();
	this.ctx.beginPath();
	this.moveTo([x, this.f(x)]);
	for (var i = 0; i < this.N; i++) {
	    x += dx;
	    this.lineTo([x,this.f(x)]);
	}
	this.lineTo([x, this.g(x)]);
	for (var i = 0; i < this.N; i++) {
	    x -= dx;
	    this.lineTo([x,this.g(x)]);
	}
	this.ctx.closePath();
	if (this.fillColor != null) {
	    this.ctx.fillStyle = this.fillColor;
	    this.ctx.fill();
	}
	if (this.strokeColor != null) {
	    this.ctx.lineWidth = this.lineWidth;
	    this.ctx.strokeStyle = this.strokeColor;
	    this.ctx.stroke();
	}
	this.ctx.restore();
    }
}
AreaBetweenCurves.prototype = new Plotable();

var vadd = function(u,v) {
    var r = []
    for (var i = 0; i < u.length; i++) {
	r.push(u[i] + v[i]);
    }
    return r
}
var vdiff = function(u,v) {
    var r = []
    for (var i = 0; i < u.length; i++) {
	r.push(u[i] - v[i]);
    }
    return r
}
var smult = function(s,u) {
    var r = []
    for (var i = 0; i < u.length; i++) {
	r.push(s*u[i]);
    }
    return r
}
var dot = function(u,v) {
    var dot = 0;
    for (var i = 0; i < u.length; i++) {
	dot += u[i]*v[i];
    }
    return dot;
}
var length = function(u) {
    return Math.sqrt(dot(u,u));
}
var midpoint = function(u,v) {
    return smult(0.5, vadd(u,v));
}

var pointOnLine = function(p, t, q) {
    d = vdiff(q, p);
    return vadd(p, smult(t, d));
}
var isInBbox = function(p, bbox) {
    if (p[0] < bbox[0] || p[0] > bbox[2] || p[1] < bbox[1] || p[1] > bbox[3])
	return false;
    return true;
}
function Line(p0, p1) {
    this.p0 = p0;
    this.p1 = p1;
    this.infinite = false;
    this.draw = function() {
	var t0 = 0;
	var t1 = 1;
	if (this.infinite) {
	    while (isInBbox(pointOnLine(this.p0, t1, this.p1), this.bbox)) {
		t1++;
	    }
	    while (isInBbox(pointOnLine(this.p0, t0, this.p1), this.bbox)) {
		t0--;
	    }
	}
	this.ctx.save();
	this.ctx.lineWidth = this.lineWidth;
	this.ctx.strokeStyle = this.strokeColor;
	if (this.lineDash != null) this.ctx.setLineDash(this.lineDash);
	this.ctx.beginPath();
	this.moveTo(pointOnLine(this.p0, t0, this.p1));
	this.lineTo(pointOnLine(this.p0, t1, this.p1));
	this.ctx.stroke();
	this.ctx.restore();
    }
}
Line.prototype = new Plotable();

function Point(p) {
    this.point = p;
    this.size = 3;
    this.style = "circle"
    this.draw = function() {
	var p = this.transform.transformPoint(this.point);
	this.ctx.save();
	this.ctx.translate(p[0], p[1]);
	this.ctx.beginPath();
	if (this.style == "circle") {
	    this.ctx.arc(0,0,this.size, 0, 2*Math.PI);
	    this.ctx.closePath();
	} else if (this.style == "box") {
	    this.ctx.moveTo(-this.size, -this.size);
	    this.ctx.lineTo(this.size, -this.size);
	    this.ctx.lineTo(this.size, this.size);
	    this.ctx.lineTo(-this.size, this.size);
	    this.ctx.closePath();
	} else if (this.style == "rect") {
	    this.ctx.moveTo(-this.width, -this.height);
	    this.ctx.lineTo(this.width, -this.height);
	    this.ctx.lineTo(this.width, this.height);
	    this.ctx.lineTo(-this.width, this.height);
	    this.ctx.closePath();
	}
	if (this.fillColor != null) {
	    this.ctx.fillStyle = this.fillColor;
	    this.ctx.fill();
	}
	if (this.strokeColor != null) {
	    this.ctx.strokeStyle = this.strokeColor;
	    this.ctx.lineWidth = this.lineWidth;
	    this.ctx.stroke();
	}
	if (this.style == "rect" && this.centerLine) {
	    this.ctx.beginPath();
	    this.ctx.moveTo(0, this.height);
	    this.ctx.lineTo(0, -this.height);
	    this.ctx.stroke();
	}
	this.ctx.restore();
    }
    this.hit = function(x,y) {
	var p = this.transform.transformPoint(this.point);
	var dx = x-p[0];
	var dy = y-p[1]
	if (this.style == "circle") {
	    return Math.sqrt(dx*dx + dy*dy) <= this.size;
	} else if (this.style == "box") {
	    return Math.abs(dx) <= this.size && Math.abs(dy) <= this.size;
	} else if (this.style == "rect") {
	    return Math.abs(dx) <= this.width && Math.abs(dy) <= this.height;
	}
	return false;
	if (this.fillColor != null) {
	    this.ctx.fillStyle = this.fillColor;
	    this.ctx.fill();
	}
	if (this.strokeColor != null) {
	    this.ctx.strokeStyle = this.strokeColor;
	    this.ctx.stroke();
	}
    }
}
Point.prototype = new Plotable();

function Ellipse(center, a, b) {
    this.center = center;
    this.a = a;
    this.b = b;
    this.N = 100;
    this.draw = function() {
	this.ctx.save();
	this.ctx.beginPath();
	var theta = 0;
	var dtheta = 2*Math.PI/this.N;
	this.moveTo(vadd(this.center,
		    [this.a*Math.cos(theta) , this.b*Math.sin(theta)]))
	for (var i = 0; i < this.N; i++) {
	    theta += dtheta;
	    this.lineTo(vadd(this.center,
			[this.a*Math.cos(theta) , this.b*Math.sin(theta)]))
	}
	this.ctx.closePath();
	this.fill();
	this.stroke();
	this.ctx.restore();
    }
}
Ellipse.prototype = new Plotable()
function Circle(center, radius) {
    this.center = center;
    this.a = radius;
    this.b = radius;
}
Circle.prototype = new Ellipse();
function QuadTree(corners, depth) {
    this.corners = corners;
    this.depth = depth;
    this.subdivide = function() {
	var bottom = midpoint(this.corners[0], this.corners[1]);
	var top = midpoint(this.corners[2], this.corners[3]);
	var left = midpoint(this.corners[0], this.corners[3]);
	var right = midpoint(this.corners[1], this.corners[2]);
	var mid = midpoint(bottom, top);
	var quad = []
	quad.push(new QuadTree([this.corners[0], bottom, mid, left],
			       this.depth-1));
	quad.push(new QuadTree([bottom, this.corners[1], right, mid],
			       this.depth-1));
	quad.push(new QuadTree([left, mid, top, this.corners[3]],
			       this.depth-1));
	quad.push(new QuadTree([mid, right, this.corners[2], top],
			       this.depth-1));
	return quad;
    }
    this.intersects = function(ctx) {
	var sign = ctx.g(this.corners[3]);
	for (var i = 0; i < 4; i++) {
	    var nextsign = ctx.g(this.corners[i]);
	    if (sign * nextsign <= 0) return true;
	    sign = nextsign;
	}
	return false;
    }
    this.findzero = function(p1, p2, ctx) {
	var dx = p2[0] - p1[0];
	var dy = p2[1] - p1[1];
	var dt;
	var nextp
	change = 0.00001
	if (dx != 0) {
	    dx = change * Math.abs(dx) / dx;
	    dy = 0;
	    dt = dx
	} else {
	    dy = change * Math.abs(dy) / dy;
	    dx = 0;
	    dt = dy;
	}
	var p = p1;
	var diff = 1;
	var N = 0;
	while (Math.abs(diff) > 0.000001 && N < 50) {
	    var f = ctx.g(p);
	    if (f == 0) break;
	    var df = (ctx.g(vadd(p, [dx,dy]))-f)/dt;
	    diff = f/df;
	    if (dx != 0) {
		nextp = vdiff(p, [diff,0]);
	    } else {
		nextp = vdiff(p, [0, diff]);
	    }
	    N ++;
	    p = nextp;
	}
	return p
    }
    this.draw = function(ctx) {
	var corner = this.corners[3];
	var sign = ctx.g(corner);
	var lastZero = null;
	for (var i = 0; i < 4; i++) {
	    var nextcorner = this.corners[i];
	    var nextsign = ctx.g(nextcorner);
	    if (sign == 0 && nextsign == 0) {
		ctx.moveTo(corner);
		ctx.lineTo(nextcorner);
	    } else if (sign * nextsign <= 0) {
		if (lastZero == null) {
		    lastZero = this.findzero(corner, nextcorner, ctx);
		} else {
		    var thisZero = this.findzero(corner, nextcorner, ctx);
		    ctx.moveTo(lastZero);
		    ctx.lineTo(thisZero);
		    lastZero = thisZero;
		}
	    }
	    corner = nextcorner;
	    sign = nextsign;

	}
    }
}

function Implicit(f) {
    this.initialdepth = 4;
    this.depth = 8;
    this.f = f;
    this.box = null;
    this.draw = function() {
	if (this.box == null) {
	    this.box = this.bbox;
	}
	this.g = function(p) {
	    return this.f(p) - this.k;
	}
	this.ctx.save();
	this.ctx.lineWidth = this.lineWidth;
	this.ctx.strokeStyle = this.strokeColor;
	this.ctx.beginPath();
	var root = new QuadTree([[this.box[0], this.box[1]],
				 [this.box[2], this.box[1]],
				 [this.box[2], this.box[2]],
				 [this.box[0], this.box[2]]], this.depth);
	var tree = [root]
	for (var i = 0; i < this.initialdepth; i++) {
	    var newtree = []
	    for (var j = 0; j < tree.length; j++) {
		var quad = tree[j].subdivide();
		newtree = newtree.concat(tree[j].subdivide());
	    }
	    tree = newtree;
	}
	while (tree.length > 0) {
	    var node = tree[0];
	    tree.splice(0, 1);
	    if (node.depth == 0) {
		node.draw(this);
	    } else if (node.intersects(this)) {
		tree = tree.concat(node.subdivide());
	    }

	}
	this.ctx.stroke();
	this.ctx.restore();
    }
}
Implicit.prototype = new Plotable();

function Vector(head) {
    this.head = head
    this.tail = [0,0];
    this.arrowWidth = 2;
    this.sw = 5
    this.hw = 2.5*this.sw; // was 3.6
    this.A = 24*Math.PI/180.0;
    this.B = 60*Math.PI/180.0; // was 60
    this.draw = function() {
	this.ctx.save();
	this.ctx.beginPath();

	var p0 = this.transform.transformPoint(this.tail);
	var p1 = this.transform.transformPoint(this.head);
	var dx = p1[0] - p0[0];
	var dy = p1[1] - p0[1];
	var L = Math.sqrt(dx*dx + dy*dy);
	var xA = L - 0.5*this.hw/Math.tan(this.A);
	var xB = xA + 0.5*(this.hw - this.sw)/Math.tan(this.B);
	this.ctx.translate(p0[0], p0[1]);
	this.ctx.rotate(Math.atan2(dy, dx));

	this.ctx.moveTo(0, -0.5*this.sw);
	this.ctx.lineTo(xB,-0.5*this.sw);
	this.ctx.lineTo(xA,-0.5*this.hw);
	this.ctx.lineTo(L, 0);
	this.ctx.lineTo(xA, 0.5*this.hw);
	this.ctx.lineTo(xB, 0.5*this.sw);
	this.ctx.lineTo(0, 0.5*this.sw);
	this.ctx.closePath();
	this.fill();
	this.stroke();
	this.ctx.restore();
    }

    this.hit = function(x,y) {
	var tail = this.transform.transformPoint(this.tail);
	var head = this.transform.transformPoint(this.head);
	var dy = head[1] - tail[1];
	var dx = head[0] - tail[0];
	var af = new AffineTransform();
	af.translate(tail);
	af.rotate(Math.atan2(dy, dx));
	var p = af.inverseTransformPoint([x,y]);
	var L = Math.sqrt(dx*dx + dy*dy);
	var xA = L - 0.5*this.hw/Math.tan(this.A);
	var maxY = Math.tan(this.A)*(L-p[0]);
	if (p[0] > L || p[0] < xA) return false;
	if (Math.abs(p[1]) > maxY) return false;
	return true;
    }
}
Vector.prototype = new Plotable();

var getColor = function(r,g,b) {
    return 'rgb(' + Math.floor(r) + ',' +
        Math.floor(g) + ',' +
	Math.floor(b) + ')';
}

var timer = null;
var startAnimation = function(update, interval) {
    if (timer != null) return;
    timer = setInterval(update, interval);
}
var stopAnimation = function() {
    if (timer != null) {
	clearTimeout(timer);
    }
    timer = null;
}
    


	
