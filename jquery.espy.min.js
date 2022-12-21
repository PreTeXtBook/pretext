
(function(b, u, v) {
    function x(b, f, e) {
        b = (b + "").match(/^(-?[0-9]+)(%)?$/);
        if (!b) return !1;
        var c = parseInt(b[1], 10);
        b[2] && (c *= f / 100);
        return 0 > c ? f + c + (e || 0) : c
    }

    function y(k, f) {
        function e() {
            function b() {
                g = +new Date;
                f.apply(e, t);
                c && (c = clearTimeout(c))
            }
            var e = this,
                q = +new Date - g,
                t = arguments;
            c && (c = clearTimeout(c));
            q > k ? b() : c = setTimeout(b, k - q)
        }
        var c, g = 0;
        b.guid && (e.guid = f.guid = f.guid || b.guid++);
        return e
    }
    b.Espy = function(k, f, e) {
        function c(a, d) {
            b.isPlainObject(a) && (d = a, a = null);
            b.extend(t.prototype, d);
            null !== a && (w = a)
        }

        function g(a) {
            if (a =
                q(a)) {
                var d = a.$el.offset()[a.settings.horizontal ? "left" : "top"] - p.offset[a.settings.horizontal ? "left" : "top"],
                    h = a.$el[a.settings.horizontal ? "outerWidth" : "outerHeight"]();
                b.extend(a, {
                    start: d,
                    elSize: h,
                    end: d + h
                })
            }
        }

        function r(a) {
   //         console.log("r(a) with a = ", a);
            if (a === v) b.each(m, r);
            else if (a = q(a)) {
                var d = p[a.settings.horizontal ? "width" : "height"],
                    h = x(a.settings.size, d),
                    d = p[a.settings.horizontal ? "left" : "top"] + x(a.settings.offset, d, -h),
                    c = d + h,
                    h = a.settings.contain ? d <= a.start && c >= a.end ? "inside" : d + h / 2 > a.start + a.elSize / 2 ? a.settings.horizontal ? "left" :
                    "up" : a.settings.horizontal ? "right" : "down" : d > a.start && d < a.end || c > a.start && c < a.end || d <= a.start && c >= a.start || d <= a.end && c >= a.end ? "inside" : d > a.end ? a.settings.horizontal ? "left" : "up" : a.settings.horizontal ? "right" : "down";
                a.state !== h && (a.state = h, "function" === typeof w && w.call(a.el, "inside" === h, h), "function" === typeof a.callback && a.callback.call(a.el, "inside" === h, h))
            }
        }

        function s(a) {
            if (m.hasOwnProperty(a)) return a;
            if (b.isPlainObject(a) && m.hasOwnProperty(a.id)) return a.id;
            a = b(a)[0];
            var d = !1;
            b.each(m, function(b,
                c) {
                c.el === a && (d = b)
            });
            return d
        }

   //     console.log("nothing yet");
        function q(a) {
            return (a = s(a)) ? m[a] : !1
        }
        "function" !== typeof f && (e = f, f = 0);
    //    console.log("k was", k);
        var t = function(a) {
                b.extend(this, a)
            },
            u = function(a, d, c, e) {
                this.id = a;
                this.el = d;
                this.$el = b(d);
                this.callback = c;
                this.settings = new t(e);
                this.configure = function(a, d) {
                    b.isPlainObject(a) && (d = a, a = null);
                    b.extend(this.settings, d);
                    null !== a && (this.callback = a)
                }
            },
            n = this,
            l = b(k);
 //       console.log("l", l, "l==window", l[0]==window);
        k = b.fn.espy.defaults;
 //       console.log("k is", k);
        var w, m = {},
            z = 0;
        // because window.offset() is not defined in jQuery 3 (why?!?!?!),
        // we have to treat that as a special case (DF 1/28/19)
        if (l[0]==window) { offSET = { top: 0, left: 0 } }
        else { offSET = l.offset() }
        var p = {
                top: l.scrollTop(),
                left: l.scrollLeft(),
                width: l.innerWidth(),
                height: l.innerHeight(),
                offset: offSET
/*
                offset: l.offset() || {
                    top: 0,
                    left: 0
                }
*/
            };
  //      console.log("p", p);
        c(f, b.extend({}, k, e));
        n.add = function(a, d, c) {
            b.isPlainObject(d) && (c = d, d = 0);
            b(a).each(function(a, b) {
                var e = s(b) || "s" + z++;
                m[e] = new u(e, b, d, c);
                g(e);
                r(e)
            })
        };
        n.configure = function(a, d, e) {
            "function" === typeof a ? (d = a, a = null, b.isPlainObject(d) && (e = d, d = null)) : b.isPlainObject(a) ? (e = a, d = a = null) : b.isPlainObject(d) && (e = d, d = null);
            null === a ? (c(d, e), b.each(m, function(a, b) {
                g(b)
            })) : b(a).each(function(a, b) {
                var c = q(b);
                c && (c.configure(d, e), g(b))
            })
        };
        n.reload = function(a) {
            a === v ? b.each(m, function() {
                    g(this.id)
                }) :
                b(a).each(function(a, b) {
                    var c = s(b);
                    c && (g(c), r(c))
                })
        };
        n.remove = function(a) {
            b(a).each(function(a, b) {
                var c = s(b);
                c && delete m[c]
            })
        };
        n.destroy = function() {
            l.off(".espy");
            m = {};
            n = v
        };
        n.resize = function() {
            b.each(m, function() {
                this.reloadOnResize && g(this)
            });
            p.width = l.innerWidth();
            p.height = l.innerHeight();
            r()
        };
        l.on("scroll.espy", y(k.delay, function() {
            p.top = l.scrollTop();
            p.left = l.scrollLeft();
            r()
        }));
        l.on("resize.espy", y(k.delay, function() {
            n.resize()
        }))
    };
    b.fn.espy = function(k, f) {
        var e, c;
        e = f && f.context || u;
        var g = b.data(e,
            "espy") || b.data(e, "espy", new b.Espy(e));
        "string" !== typeof k ? g.add(this, k, f) : (e = k, c = Array.prototype.slice.call(arguments), c[0] = this, "function" === typeof g[e] && g[e].apply(g, c));
        return this
    };
    b.fn.espy.defaults = {
        delay: 100,
        context: window,
        horizontal: 0,
        offset: 0,
        size: "100%",
        contain: 0,
        reloadOnResize: !0
    }
})(jQuery, window);


