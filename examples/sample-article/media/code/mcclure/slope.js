/* From Mark McClure, 2018-06-24              */
/* https://marksmath.org/visualization/slope/ */
/* Changes:  body_width and SVG size          */

var body_width = 600;
$("body").css("width", body_width);
var svg_width = 600, svg_height = 400, graph_padding = 20;
$("#the_graph").css("margin-left", (body_width-svg_width)/2);
var svg = d3.select("#the_graph")
	.attr("width", svg_width)
	.attr("height", svg_height);


$("#f1").prop('checked',true);


// The action!
setup_scale_and_axes();
draw("first_time");


// The functions with global variables declared outside the scope of the function
var xmin, xmax, ymin, ymax, graph, f, fp;
var xScale, xScaleInverse, yScale, yScaleInverse, rScale, pts_to_path;
function setup_scale_and_axes() {
	"use strict";
	xmin = -2;
	xmax = 2;
	ymin = -0.5;
	ymax = 2;
	xScale = d3.scale.linear()
		.domain([xmin,xmax])
		.range([graph_padding, svg_width - graph_padding]);
	yScale = d3.scale.linear()
		.domain([ymin,ymax])
		.range([svg_height - graph_padding, graph_padding]);
	xScaleInverse = d3.scale.linear()
		.range([xmin,xmax])
		.domain([graph_padding, svg_width - graph_padding]);
	yScaleInverse = d3.scale.linear()
		.range([ymin,ymax])
		.domain([svg_height - graph_padding, graph_padding]);
	rScale = d3.scale.linear()
		.domain([0,xmax-xmin])
		.range([0, svg_width - graph_padding]);
	pts_to_path = d3.svg.line()
		.x(function(d) { return xScale(d[0]); })
		.y(function(d) { return yScale(d[1]); })
		.interpolate("linear");
	svg.append("g").append("path")
		.attr("d", pts_to_path([[xmin,0],[xmax,0]]))
		.attr("stroke", "#333")
		.attr("stroke-width", 1)
		.attr("fill", "none");			
	svg.append("g").append("path")
		.attr("d", pts_to_path([[0,ymin],[0,ymax]]))
		.attr("stroke", "#333")
		.attr("stroke-width", 1)
		.attr("fill", "none");
	var x_ticks = [];
	for(var i=xmin; i<=xmax; i=i+0.25){
		x_ticks.push([[i,0], [i,-0.05]])
 	}
	svg.append("g")
		.selectAll("path")
		.data(x_ticks)
		.enter().append("path")
		.attr("d", function(d) {return pts_to_path(d)})
		.attr("stroke", "black")
		.attr("stroke-width", 0.4)
		.attr("class", "ticks");
	var tick_labels = [-2,-1,1,2];
	svg.append("g")
		.selectAll("text")
		.data(tick_labels)
		.enter().append("text")
		.attr("text-anchor", "middle")
		.attr("x", function(d) {return xScale(d)})
		.attr("y", yScale(0.14))
		.attr("dy", "0.35em")
		.attr("font-size", "18px")
		.text(function(d) {return d});
	var y_ticks = [];
	for(var i=ymin; i<=ymax; i=i+0.25){
		y_ticks.push([[-0.03,i], [0,i]])
 	}
	svg.append("g")
		.selectAll("path")
		.data(y_ticks)
		.enter().append("path")
		.attr("d", function(d) {return pts_to_path(d)})
		.attr("stroke", "black")
		.attr("stroke-width", 0.4)
		.attr("class", "ticks");
	var tick_labels = [-1,1,2,3];
	svg.append("g")
		.selectAll("text")
		.data(tick_labels)
		.enter().append("text")
		.attr("text-anchor", "middle")
		.attr("x", xScale(-0.07))
		.attr("y", function(d) {return yScale(d)} )
		.attr("dy", "0.35em") 
		.attr("font-size", "18px")
		.text(function(d) {return d});
}

function draw() {
	"use strict";

	// Get and define the function
	define_function();
	var graph_points = [];
	var dx = 0.01;
	var x,y;
	for(x = xmin; x<=xmax+dx; x=x+dx) {
		y = f(x);
		graph_points.push([x,y]);	
	}
	graph = svg.append("g")
		.attr("class", "graph");
	graph.append("path")
		.attr("d", pts_to_path(graph_points))
		.attr("stroke", "black")
		.attr("stroke-width", 3)
		.attr("fill", "none");
}

function draw_transition() {

	svg.selectAll("circle").remove();
	svg.selectAll(".tangent_line_graph")
		.style("opacity",1)
		.transition().duration(400)
		.style("opacity",0);
	svg.selectAll(".secant_line_graph")
		.style("opacity",1)
		.transition().duration(400)
		.style("opacity",0);
	window.setTimeout(
		function() {
			svg.selectAll(".tangent_line_graph").remove();
			svg.selectAll(".secant_line_graph").remove();
		}, 200
	);
	var graph_points1 = [];
	var graph_points2 = [];
	var graph_points3 = [];
	var dx = 0.01;
	var f1 = f;
	define_function();
	var f2 = f;
	var x,y;
	for(x = xmin; x<=xmax+dx; x=x+dx) {
		y = f1(x);
		graph_points1.push([x,y]);	
	}
	for(x = xmin; x<=xmax+dx; x=x+dx) {
		graph_points2.push([x,0]);	
	}
	for(x = xmin; x<=xmax+dx; x=x+dx) {
		y = f2(x);
		graph_points3.push([x,y]);	
	}
	svg.selectAll(".graph").remove();
	svg.append("g")
		.attr("class", "graph")
		.append("path")
		.attr("stroke", "black")
		.attr("stroke-width", 3)
		.attr("fill", "none")
		.attr("d", pts_to_path(graph_points1))	
 		.transition().duration(600)
		.attr("d", pts_to_path(graph_points2))
 		.transition().duration(400)
		.attr("d", pts_to_path(graph_points3));

	window.setTimeout(function () {
		draw_tangent_line(x0);
		if($("#show_secant_checkbox").is(':checked')) {
			draw_secant_line(x0,h)
		}
	}, 1000);

	window.setTimeout(function () {
		add_xh_marker(x0, h, f1, f2)
	}, 1000);
}

function define_function() {
	var function_input = $("input:radio[name=function]:checked").val();
	if(function_input == "f1"){
		f = function(x) {
			return x*x;
		}
		fp = function(x) {
			return 2*x;
		}
	}
	else if(function_input == "f2"){
		f = function(x) {
			return Math.exp(x)/3;
		}
		fp = function(x) {
			return Math.exp(x)/3;
		}
	}
	else if(function_input == "f3"){
		f = function(x) {
			return Math.sin(2*x*x) + x/3;;
		}
		fp = function(x) {
			return 4*x*Math.cos(2*x*x) + 1/3;
		}
	}

}

$(".radio").click(draw_transition);

function add_xh_marker(x0_in, h, f1, f2) {

	svg.selectAll("circle").remove();
	
	var h_active = $("#show_secant_checkbox").is(':checked');

	if(f2) {
		var ff = f2;
	}
	else {
		var ff = f1;
	}
	x0=x0_in;
	x_marker_active = false;
	x_marker = svg.append("circle")
		.attr("class", "x_marker")
		.attr("cx", function(d) { return xScale(x0)})
		.attr("cy", function(d) {return yScale(ff(x0))})
		.attr("r", function(d) {return rScale(0.02)})
		.attr("fill", "lightgreen")
		.attr("stroke", "black")
		.attr("stroke-width", 1);
	if(h_active) {
		h_marker = svg.append("circle")
			.attr("class", "h_marker")
			.attr("cx", function(d) { return xScale(x0+h)})
			.attr("cy", function(d) {return yScale(ff(x0+h))})
			.attr("r", function(d) {return rScale(0.02)})
			.attr("fill", "red")
			.attr("stroke", "black")
			.attr("stroke-width", 1);
}
// 	x_marker
// 		.on("mouseenter", function() {
// 			x_marker.attr("fill", "black")
// 		})
// 		.on("mouseleave", function() {
// 			if(x_marker_active == false) {
// 				x_marker.attr("fill", "darkgreen")
// 			}
// 		});
	svg
		.on("mousedown", function() {
			x_marker_active = true;
			x_marker.attr("fill", "darkgreen");
			var pos = d3.mouse(this);
			x0=xScaleInverse(pos[0]);
			x_marker
				.attr("cx", pos[0])
				.attr("cy", yScale(ff(x0)));
//			h_marker.attr("fill", "black");
			if($("#show_secant_checkbox").is(':checked')) {
				h_marker
					.attr("cx", xScale(x0+h))
					.attr("cy", yScale(ff(x0+h)));
				draw_secant_line(x0,h);
			}
			draw_tangent_line(x0);
		})
		.on("mouseup", function() {
			x_marker_active = false;
			x_marker.attr("fill", "lightgreen");
//			h_marker.attr("fill", "lightred");
			add_xh_marker(x0, h, f);
		})
		.on("mousemove", function() {
			if(x_marker_active == true){
				var pos = d3.mouse(this);
				x0=xScaleInverse(pos[0]);
				x_marker
					.attr("cx", pos[0])
					.attr("cy", yScale(ff(x0)));
				$("#tangent_value_display")
					.text(math.format(fp(x0,h),{notation: 'fixed', precision: 2}));
				if($("#show_secant_checkbox").is(':checked')) {
					$("#secant_value_display")
						.text(math.format(secant_slope(x0,h),{notation: 'fixed', precision: 2}));
					h_marker
						.attr("cx", xScale(x0+h))
						.attr("cy", yScale(ff(x0+h)));
					draw_secant_line(x0,h);
				}
				draw_tangent_line(x0);
			}
		})
}

function tangent_line(x0, x) {
	return f(x0) + fp(x0)*(x-x0);
}
function draw_tangent_line(x0) {
	svg.selectAll(".tangent_line_graph").remove();
	var tangent_line_points = [];
	var dx = 0.1;
	var x,y;
	for(x = xmin; x<=xmax+dx; x=x+dx) {
		y = tangent_line(x0,x);
		tangent_line_points.push([x,y]);	
	}
	graph = svg.append("g")
		.attr("class", "tangent_line_graph");
	graph.append("path")
		.attr("d", pts_to_path(tangent_line_points))
		.attr("stroke", "black")
		.attr("stroke-width", 1)
		.attr("fill", "none");

}


function secant_slope(x0,h) {
	if(h != 0) {
		return	(f(x0+h)-f(x0))/h;
	}
	else {return "error!"}
}
function secant_line(x,x0,h) {
	if(h != 0) {
		return f(x0) + ((f(x0+h)-f(x0))/h)*(x-x0)
	}
}
function draw_secant_line(x0,h) {
	if(h != 0) {
		svg.selectAll(".secant_line_graph").remove();
		var secant_line_points = [];
		var dx = 0.1;
		var x,y;
		for(x = xmin; x<=xmax+dx; x=x+dx) {
			y = secant_line(x,x0,h);
			secant_line_points.push([x,y]);	
		}
		svg.append("g")
			.attr("class", "secant_line_graph")
			.append("path")
			.attr("d", pts_to_path(secant_line_points))
			.attr("stroke", "black")
			.attr("stroke-width", 1)
			.attr("fill", "none");
	}
}

var x0 = 0.4;
var h = 0.3;
$("#h_slider")
	.val(h)
	.attr("disabled", true)
	.on("input", function(event) {
		h = Number(this.value);
		draw_secant_line(x0,h);
		add_xh_marker(x0,h,f);
		$("#h_value_display").text(h);
		$("#secant_value_display")
			.text(math.format(secant_slope(x0,h),{notation: 'fixed', precision: 2}));
	});
$("#h_value_display").text();


//$("#show_secant_checkbox").is(':checked')
$("#show_secant_checkbox")
	.prop('checked', false)
	.on('click', function() {
		var is_checked = $("#show_secant_checkbox").is(':checked');
		if(is_checked) {
			draw_secant_line(x0,h);
			add_xh_marker(x0, h, f);
			$("#h_slider").attr("disabled", false);
			$("#h_value_display").text(h);
			$(".dimit").fadeTo(400,1);
			$("#secant_value_display")
				.text(math.format(secant_slope(x0,h),{notation: 'fixed', precision: 2}));
		}
		else {
			svg.selectAll(".secant_line_graph").remove();
			svg.selectAll(".h_marker").remove();
			$("#h_slider").attr("disabled", true);
			$("#h_value_display").text("");
			$(".dimit").fadeTo(300,0.2)
			$("#secant_value_display").text("");
		}
	});

draw_tangent_line(x0);
$("#tangent_value_display").text(math.format(fp(x0),{notation: 'fixed', precision: 2}));
// draw_secant_line(x0,h);
add_xh_marker(x0, h, f);
$(".dimit").fadeTo(0,0.2);
