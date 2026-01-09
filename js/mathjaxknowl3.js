
      const { Configuration } = MathJax._.input.tex.Configuration;
      const { CommandMap } = MathJax._.input.tex.SymbolMap;
      const NodeUtil = MathJax._.input.tex.NodeUtil.default;

      var GetArgumentMML = function (parser, name) {
        var arg = parser.ParseArg(name);
        if (!NodeUtil.isInferred(arg)) {
          return arg;
        }
        var children = NodeUtil.getChildren(arg);
        if (children.length === 1) {
          return children[0];
        }
        var mrow = parser.create("node", "mrow");
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
        var url = parser.GetArgument(name);
        var arg = GetArgumentMML(parser, name);
        var mrow = parser.create("node", "mrow", [arg], {
            tabindex: '0',
            "data-knowl": url
        });
        parser.Push(mrow);
      };

      new CommandMap(
        "knowl",
        {
          knowl: ["Knowl"]
        },
        mathjaxKnowl
      );
      const configuration = Configuration.create("knowl", {
        handler: {
          macro: ["knowl"]
        }
      });
