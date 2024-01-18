/* 
 * Knowl - Feature Demo for Knowls
 * Copyright (C) 2011  Harald Schilly
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * 4/11/2012 Modified by David Guichard to allow inline knowl code.
 * Sample use:
 *      This is an <a data-knowl="" class="internal" 
 *      value="Hello World!">inline knowl.</a>
 */

/*  8/14/14  Modified by David Farmer to allow knowl content to be
 *  taken from the element with a given id.
 *
 * The syntax is <a data-knowl="" class="id-ref" data-refid="proofSS">Proof</a>
 */
 
/* javascript code for the knowl features 
 * global counter, used to uniquely identify each knowl-output element
 * that's necessary because the same knowl could be referenced several times
 * on the same page */
var knowl_id_counter = 0;

var knowl_focus_stack_uid = [];
var knowl_focus_stack = [];

var sagecellEvalName = "Evaluate";

var mjvers = 0;
if (window.MathJax !== undefined) {
  mjvers = MathJax.version;
  console.log("mjvers", mjvers);
  if (typeof mjvers == 'undefined') {
    mjvers = "2.14159";
  }
  mjvers = parseFloat(mjvers.substring(0,3));
}
console.log("               mjvers", mjvers);

 
function knowl_click_handler($el) {
  // the knowl attribute holds the id of the knowl
  var knowl_id = $el.attr("data-knowl");
  // the uid is necessary if we want to reference the same content several times
  var uid = $el.attr("data-knowl-uid");
  var output_id = '#knowl-output-' + uid; 
  var $output_id = $(output_id);
  // create the element for the content, insert it after the one where the 
  // knowl element is included (e.g. inside a <h1> tag) (sibling in DOM)
  var idtag = "id='"+output_id.substring(1) + "'";
  var kid   = "id='kuid-"+ uid + "'";
  // if we already have the content, toggle visibility

  // Note that for tracking knowls, this setup is not optimal
  // because it applies to open knowls and also knowls which
  // were opened and then closed.
  if ($output_id.length > 0) {
     thisknowlid = "kuid-"+uid
// when this is an entry in a table, then it is the parents parent we need to toggle
// also need to clean this up
     if($("#kuid-"+uid).parent().is("td.knowl-td")) {
         $("#kuid-"+uid).parent().parent().slideToggle("fast");
     }
     else {
         $("#kuid-"+uid).slideToggle("fast");
     }

     if($el.attr("replace")) {
       $($el.attr("replace")).slideToggle("fast");
     }

     this_knowl_focus_stack_uidindex = knowl_focus_stack_uid.indexOf(uid);
     
     if($el.hasClass("active")) {
       if(this_knowl_focus_stack_uidindex != -1) {
         knowl_focus_stack_uid.splice(this_knowl_focus_stack_uidindex, 1);
         knowl_focus_stack.splice(this_knowl_focus_stack_uidindex, 1);
       }
     }
     else {
         knowl_focus_stack_uid.push(uid);
         knowl_focus_stack.push($el);
         document.getElementById(thisknowlid).focus();
     }

     $el.toggleClass("active");
 
  // otherwise download it or get it from the cache
  } else { 
    // where_it_goes is the location the knowl will appear *after*
    // knowl is the variable that will hold the content of the output knowl
    var where_it_goes = $el;
    var knowl = "";
    if ($el.hasClass('original')) {  // knowls with original content can be styled differently from xref knowls
        knowl = "<div class='knowl-output original' "+kid+"><div class='knowl'><div class='knowl-content' " +idtag+ ">loading '"+knowl_id+"'</div><div class='knowl-footer'>"+knowl_id+"</div></div></div>";
    } else {
        knowl = "<div class='knowl-output' "+kid+"><div class='knowl'><div class='knowl-content' " +idtag+ ">loading '"+knowl_id+"'</div><div class='knowl-footer'>"+knowl_id+"</div></div></div>";
    }

    // addafter="#id" means to put the knowl after the element with that id
    if($el.attr("addafter")) {
        where_it_goes = $($el.attr("addafter"));
    } else if($el.attr("replace")) {
        where_it_goes = $($el.attr("replace"));
    } else if($el.hasClass("kohere")) {
        where_it_goes = $el;
    } else if($el.hasClass("original") && $el.parent().is("article")) {
        where_it_goes = $el.after();
    } else {
       // otherwise, typically put it after the nearest enclosing block element

      // check, if the knowl is inside a td or th in a table
      if($el.parent().is("td") || $el.parent().is("th") ) {
        // assume we are in a td or th tag, go 2 levels up
        where_it_goes = $el.parent().parent();
        var cols = $el.parent().parent().children().length;
        knowl = "<tr><td colspan='"+cols+"' class='knowl-td'>"+knowl+"</td></tr>";
      } else if ($el.parent().is("p") && $el.parent().parent().is("td")) {
        where_it_goes = $el.parent().parent().parent();
        var cols = $el.parent().parent().parent().children().length;
        knowl = "<tr><td colspan='"+cols+"' class='knowl-td'>"+knowl+"</td></tr>";
      } else if ($el.parent().is("li")) {
        where_it_goes = $el.parent();
      } 
      // not sure it is is worth making the following more elegant
      else if ($el.parent().parent().is("li")) {
        where_it_goes = $el.parent().parent();
        // the '.is("p")' is for the first paragraph of a theorem or proof
      } else if ($el.parent().prop("tagName").startsWith("MJX")) {
          where_it_goes = $el.closest("mjx-container")
      } else if ($el.parent().css('display') == "block" || $el.parent().is("p") || $el.parent().hasClass("para") || $el.parent().hasClass("hidden-knowl-wrapper") || $el.parent().hasClass("kohere")) {
        where_it_goes = $el.parent();
      } else if ($el.parent().parent().css('display') == "block" || $el.parent().parent().is("p") || $el.parent().parent().hasClass("hidden-knowl-wrapper") || $el.parent().parent().hasClass("kohere")) {
        where_it_goes = $el.parent().parent();
      } else {
        //  is this a reasonable last case?
        //  if we omit the else, then if goes after $el
        where_it_goes = $el.parent().parent().parent();
      }

    }

    // now that we know where the knowl goes, insert the knowl content
    if($el.attr("replace")) {
        where_it_goes.before(knowl);
    }
    else {
        where_it_goes.after(knowl);
    }
 
    // "select" where the output is and get a hold of it 
    var $output = $(output_id);
    var $knowl = $("#kuid-"+uid);
    $output.addClass("loading");
    $knowl.hide();

    // DRG: inline code
    if ($el.hasClass('internal')) {
      $output.html($el.attr("value"));
//    } else if ($el.attr("class") == 'id-ref') {
    } else if ($el.hasClass('id-ref')) {
     //get content from element with the given id
      $output.html($("#".concat($el.attr("data-refid"))).html());
    } else {
    // Get code from server.
    $output.load(knowl_id,
     function(response, status, xhr) { 
       $knowl.removeClass("loading");
       if (status == "error") {
         $el.removeClass("active");
         $output.html("<div class='knowl-output error'>ERROR: " + xhr.status + " " + xhr.statusText + '</div>');
         $output.show();
       } else if (status == "timeout") {
         $el.removeClass("active");
         $output.html("<div class='knowl-output error'>ERROR: timeout. " + xhr.status + " " + xhr.statusText + '</div>');
         $output.show();
       }
       else {
           // this is sloppy, because this is called again later.
         if (mjvers && mjvers < 3) {
              MathJax.Hub.Queue(['Typeset', MathJax.Hub, $output.get(0)]);
         } else if (mjvers > 3) {
              MathJax.typesetPromise([$output.get(0)]);
         }
// not sure of the use case for this,
// since the same code appears later:
 $(".knowl-output .hidden-content .hidden-sagecell-sage").attr("class", "doubly-hidden-sagecell-sage");
 $(".knowl-output .hidden-sagecell-sage").attr("class", "sagecell-sage");
 sagecell.makeSagecell({inputLocation: ".sagecell-sage",  linked: true, evalButtonText: sagecellEvalName });
 $(".knowl-output .hidden-content .doubly-hidden-sagecell-sage").attr("class", "hidden-sagecell-sage");
    }
     });
    };

   // we have the knowl content, and put it hidden in the right place,
   // so now we show it

   $knowl.hide();

   $el.addClass("active");
 // if we are using MathJax, then we reveal the knowl after it has finished rendering the contents
   if(window.MathJax == undefined) {
            $knowl.slideDown("slow");
   } else {
     if (mjvers < 3) {
       $knowl.addClass("processing");
       MathJax.Hub.Queue(['Typeset', MathJax.Hub, $output.get(0)]);
       MathJax.Hub.Queue([ function() {
       $knowl.removeClass("processing");
       $knowl.slideDown("slow");

       // if replacing, then need to hide what was there
       // (and also do some other things so that toggling works -- not implemented yet)
       if($el.attr("replace")) {
          var the_replaced_thing = $($el.attr("replace"));
          the_replaced_thing.hide("slow");
        }

        var thisknowlid = 'kuid-'.concat(uid)
        document.getElementById(thisknowlid).tabIndex=0;
        document.getElementById(thisknowlid).focus();
        knowl_focus_stack_uid.push(uid);
        knowl_focus_stack.push($el);
        $("a[data-knowl]").attr("href", "");
        }]);
     } else if (mjvers > 3) {
       console.log("processing for MJ3");
       $knowl.addClass("processing");
  //      MathJax.typesetPromise([$output.get(0)]);
  //      MathJax.typesetPromise([ function() {
        MathJax.typesetPromise([$output.get(0)]);
       $knowl.removeClass("processing");
       $knowl.slideDown("slow");

       console.log("just did slideDown");
       // if replacing, then need to hide what was there
       // (and also do some other things so that toggling works -- not implemented yet)
       if($el.attr("replace")) {
          var the_replaced_thing = $($el.attr("replace"));
          the_replaced_thing.hide("slow");
        }

        var thisknowlid = 'kuid-'.concat(uid)
        document.getElementById(thisknowlid).tabIndex=0;
        document.getElementById(thisknowlid).focus();
        knowl_focus_stack_uid.push(uid);
        knowl_focus_stack.push($el);
        $("a[data-knowl]").attr("href", "");
//        }]);
     } else {
        $knowl.slideDown("slow");
     }
// if this is before the MathJax, big problems
        $(".knowl-output .hidden-content .hidden-sagecell-sage").attr("class", "doubly-hidden-sagecell-sage");
        $(".knowl-output .hidden-sagecell-sage").attr("class", "sagecell-sage");
        try {
          sagecell.makeSagecell({inputLocation: ".sagecell-sage",  linked: true, evalButtonText: sagecellEvalName});
        } catch {
          console.log("sagecell is missing")
        }
        $(".knowl-output .hidden-content .doubly-hidden-sagecell-sage").attr("class", "hidden-sagecell-sage");
    }
  }
  return($knowl)
} //~~ end click handler for *[data-knowl] elements

/** register a click handler for each element with the knowl attribute 
 * @see jquery's doc about 'live'! the handler function does the 
 *  download/show/hide magic. also add a unique ID, 
 *  necessary when the same reference is used several times. */
$(function() {
    $("body").on("click", "*[data-knowl]", function(evt) {
      evt.preventDefault();
      var $knowl = $(this);
      if(!$knowl.attr("data-knowl-uid")) {
        $knowl.attr("data-knowl-uid", knowl_id_counter);
        knowl_id_counter++;
      }
      var knowlc = knowl_click_handler($knowl, evt);
      console.log("after click handler", knowlc);
      if (typeof knowlc !== "undefined") {
        setTimeout(function () {
          if (knowlc[0]["innerHTML"].includes("knowl-output error")) {
            console.log("seem to have a bad knowl")
            var missing_knowl_message = "<div style='padding: 0.5rem 1rem'>";
            missing_knowl_message += "<h2>This is not the knowl you are looking for!</h2>";
            missing_knowl_message += "<h3>Why is that?</h3>";
            missing_knowl_message += "<p>The knowl you wanted was empty, so this message was put in its place.</p>";
            missing_knowl_message += "<p>If you are viewing this file on your laptop, ";
            missing_knowl_message += "a security setting on your browser prevents ";
            missing_knowl_message += "the knowl file from opening, resulting in an empty knowl.  See the <a href='https://pretextbook.org/doc/guide/html/author-faq.html' style='text-decoration: underline; color:#00f'>PreTeXt FAQ</a>.</p>";
            missing_knowl_message += "<p>If you are viewing this page from a server, ";
            missing_knowl_message += "then something else went wrong.</p>";
            missing_knowl_message += "</div>";
            knowlc[0]["innerHTML"] = missing_knowl_message
          }
         }, 1000
        )
      }
  });
});


// change from jQuery 3
// $(window).load(function() {
$(window).on("load", function() {
   $("a[data-knowl]").attr("href", "");
});

//window.onload = function() {
/*
window.addEventListener("load",function(event) {
    document.onkeyup = function(event)
    {
        var e = (!event) ? window.event : event;
        switch(e.keyCode)
        {
            case 27: //esc
                if(knowl_focus_stack.length > 0 ) {
                   most_recently_opened = knowl_focus_stack.pop();
                   knowl_focus_stack_uid.pop();
                   most_recently_opened.focus();
                } else {
                   console.log("no open knowls being tracked");
                   break;
                }
        };
    };
},
false);

*/
