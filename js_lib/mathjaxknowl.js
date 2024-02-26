/****************************************************
 *
 *  mathjaxknowl.js
 *  
 *  Implements \knowl{url}{math} macro for MathJax.  Knowls are
 *  described at
 *  
 *    http://www.aimath.org/knowlepedia/
 *  
 *  Be sure to change the loadComplete() address to the URL
 *  of the location of this file on your server. 
 *  
 *  You can load it via the config=file parameter on the script
 *  tag that loads MathJax.js, or by including it in the extensions
 *  array in your configuration.
 *  
 *  Based on an approach developed by Tom Leathrum.  See
 *  
 *    http://groups.google.com/group/mathjax-users/browse_thread/thread/d8a8d081b8e63242
 *  
 *  for details.
 */

MathJax.Extension.Knowl = {
  version: "1.0",

  //
  //  Reveal or hide a MathJax knowl
  //
  Show: function (url,id) {
    var oid = "MathJax-knowl-output-"+id,
        uid = "MathJax-kuid-"+id;
    if ($("#"+oid).length) {
      $("#"+uid).slideToggle("fast");
    } else {
      var the_content = "<div class='knowl-output' id='"+uid+"'>" +
          "<div class='knowl'>" +
             "<div class='knowl-content' id='"+oid+"'>" +
               "loading '"+url+"'" +
             "</div>" +
          "</div>" +
        "</div>";

      var the_parent = $("#MathJax-knowl-"+id).closest("p, article, .displaymath");

      if(the_parent.length == 0) {
         the_parent = $("#MathJax-knowl-"+id).closest(".MJXc-display").next();
         if(the_parent.length == 0) {
            the_parent = $("#MathJax-knowl-"+id).parent().parent().parent().parent();
         }
      }

      the_parent.after(the_content);

      $("#"+oid).load(url,function () {
        MathJax.Hub.Queue(["Typeset",MathJax.Hub,uid]);
      });
      $("#"+uid).slideDown("slow");
    }
 },

  //
  //  Get a unique ID for the knowl
  //
  id: 0,
  GetID: function () {return this.id++}
};


MathJax.Callback.Queue(
  MathJax.Hub.Register.StartupHook("TeX Jax Ready",function () {
    var TEX = MathJax.InputJax.TeX,
        TEXDEF = TEX.Definitions,
        KNOWL = MathJax.Extension.Knowl;

    TEXDEF.macros.knowl = "Knowl";

    TEX.Parse.Augment({
      //
      //  Implements \knowl{url}{math}
      //
      Knowl: function (name) {
        var url = this.GetArgument(name), math = this.ParseArg(name);
        if (math.inferred && math.data.length == 1)
          {math = math.data[0]} else {delete math.inferred}
        var id = KNOWL.GetID();
        this.Push(math.With({
          "class": "MathJax_knowl",
          href: "javascript:MathJax.Extension.Knowl.Show('"+url+"','"+id+"')",
          id: "MathJax-knowl-"+id,
          // border and padding will only work properly if given explicitly on the element
          style: "color:blue; border-bottom: 1px dotted #00A; padding-bottom: 1px"
        }));
      }
    });
  
  }),
  MathJax.Hub.Register.StartupHook("onLoad",function () {
    MathJax.Ajax.Styles({
      ".MathJax_knowl:hover": {"background-color": "#DDF"}
    });
  }),
  ["Post",MathJax.Hub.Startup.signal,"TeX knowl ready"]
);

MathJax.Ajax.loadComplete("http://pretextbook.org/js/lib/mathjaxknowl.js");
MathJax.Ajax.loadComplete("https://pretextbook.org/js/lib/mathjaxknowl.js");


