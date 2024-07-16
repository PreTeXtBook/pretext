/***************************************************************
 * Implements startup of MathJax v4
 ***************************************************************/

// Base config options. Will be supplemented by optional parts later
let mathJaxOpts = {
  "tex": {
    "inlineMath": [
      [
        "\\(",
        "\\)"
      ]
    ],
    "tags": "none",
    "tagSide": "right",
    "tagIndent": ".8em",
    "packages": {
      "[+]": [
        "base",
        "ams",
        "amscd",
        "color",
        "newcommand",
        "knowl"
      ]
    }
  },
  "options": {
    "ignoreHtmlClass": "tex2jax_ignore|ignore-math",
    "processHtmlClass": "process-math",
  },
  "chtml": {
    "scale": 0.98,
    "mtextInheritFont": true
  },
  "loader": {
    "load": [
      //"ui/lazy", // Vastly speeds up time to visible content. But breaks embedded knowl parsing
      "input/asciimath",
      "[tex]/extpfeil",
      "[tex]/amscd",
      "[tex]/color",
      "[tex]/newcommand",
    ],
    "paths": {
      "pretext": "_static/pretext/js/lib"
    }
  }
};


export function startMathJax(opts) {
  if(opts.hasWebworkReps || opts.hasSage) {
    mathJaxOpts['renderActions'] = {
      "findScript": [
        10,
        function (doc) {
          document.querySelectorAll('script[type^="math/tex"]').forEach(function (node) {
            var display = !!node.type.match(/; *mode=display/);
            var math = new doc.options.MathItem(node.textContent, doc.inputJax[0], display);
            var text = document.createTextNode('');
            node.parentNode.replaceChild(text, node);
            math.start = { node: text, delim: '', n: 0 };
            math.end = { node: text, delim: '', n: 0 };
            doc.math.push(math);
          });
        },
        ""
      ]
    }
  }

  if(opts.isReact) {
    mathJaxOpts['startup'] = {
      typeset: false,
    }
  } else {
    mathJaxOpts['startup'] = {
      ready() {
        const { Configuration } = MathJax._.input.tex.Configuration;
        const configuration = Configuration.create("knowl", {
          handler: {
            macro: ["knowl"]
          }
        });
  
        function GetArgumentMML(parser, name) {
          const NodeUtil = MathJax._.input.tex.NodeUtil.default;
          const arg = parser.ParseArg(name);
          if (!NodeUtil.isInferred(arg)) {
            return arg;
          }
          const children = NodeUtil.getChildren(arg);
          if (children.length === 1) {
            return children[0];
          }
          const mrow = parser.create("node", "mrow");
          NodeUtil.copyChildren(arg, mrow);
          NodeUtil.copyAttributes(arg, mrow);
          return mrow;
        };
  
        let mathjaxKnowl = {};
        /**
         * Implements \knowl{url}{math}
         * @param {TexParser} parser The calling parser.
         * @param {string} name The TeX string
         */
        mathjaxKnowl.Knowl = function (parser, name) {
          const url = parser.GetArgument(name);
          const arg = GetArgumentMML(parser, name);
          const mrow = parser.create("node", "mrow", [arg], { tabindex: '0', "data-knowl": url });
          parser.Push(mrow);
        };
  
        const CommandMap = MathJax._.input.tex.TokenMap.CommandMap;
        new CommandMap(
          "knowl",
          {
            knowl: ["Knowl"]
          },
          mathjaxKnowl
        );
  
        MathJax.startup.defaultReady();
      },
      pageReady() {
        return MathJax.startup.defaultPageReady().then(function () {
          rsMathReady();
        }
        )
      },
    }
  }
  
  if(opts.htmlPresentation) {
    mathJaxOpts['options']['menuOptions'] = {
      "settings": {
        "zoom": "Click",
        "zscale": "300%"
      }
    }
  }
  
  // Apply the options
  window.MathJax = mathJaxOpts;

  // Lets Runestone know that MathJax is ready
  const runestoneMathReady = new Promise((resolve) => window.rsMathReady = resolve);
  window.runestoneMathReady = runestoneMathReady;
}





