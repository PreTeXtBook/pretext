/*******************************************************************************
 * pretext_add_on.js
 *******************************************************************************
 * Javascript for supplementary material in PreTeXt documents.
 *
 * Homepage: pretextbook.org
 * Repository: https://github.com/PreTeXtBook/JS_core
 *
 * Authors: David Farmer, Rob Beezer, Alex Jordan
 *
 *******************************************************************************
 */

/*
console.log("thisbrowser.userAgent", window.navigator.userAgent);
*/

var minivers = "0";
if (typeof miniversion !== 'undefined') {
  console.log("typeof miniversion", typeof miniversion, "dddd", typeof miniversion == 'undefined');
  minivers = miniversion.toString();
}
console.log("               minivers", minivers);

/* scrollbar width from https://stackoverflow.com/questions/13382516/getting-scroll-bar-width-using-javascript */
function getScrollbarWidth() {
    var outer = document.createElement("div");
    outer.style.visibility = "hidden";
    outer.style.width = "100px";
    outer.style.msOverflowStyle = "scrollbar"; // needed for WinJS apps

    document.body.appendChild(outer);

    var widthNoScroll = outer.offsetWidth;
    // force scrollbars
    outer.style.overflow = "scroll";

    // add innerdiv
    var inner = document.createElement("div");
    inner.style.width = "100%";
    outer.appendChild(inner);

    var widthWithScroll = inner.offsetWidth;

    // remove divs
    outer.parentNode.removeChild(outer);

    return widthNoScroll - widthWithScroll;
}

/*
  copy permalink address to clipboard
  requires browser support, otherwise does nothing
*/
async function copyPermalink(linkNode) {
    // structure borrowed from https://flaviocopes.com/clipboard-api/
    if (!navigator.clipboard) {
        // Clipboard API not available
        console.log("Error: Clipboard API not available");
        return
    }
    console.log("copying permalink for", linkNode);
    var elem = linkNode.parentElement
    if (!linkNode) {
        console.log("Error: Something went wrong finding permalink URL")
        return
    }
    const this_permalink_url = linkNode.href;
    const this_permalink_description = elem.getAttribute('data-description');
    var link     = "<a href=\""                    + this_permalink_url + "\">" + this_permalink_description + "</a>";
    var msg_link = "<a class=\"internal\" href=\"" + this_permalink_url + "\">" + this_permalink_description + "</a>";
    var text_fallback = this_permalink_description + " \r\n" + this_permalink_url;
    var copy_success = true;
    try {
        // NOTE: this method will only work in Firefox if the user has
        //    dom.events.asyncClipboard.clipboardItem
        // set to true in their about:config.
        // Annoyingly, this setting is turned off by default.
        // If that setting is off, this try block will fail and we'll use the
        // fallback method lower down instead.
        await navigator.clipboard.write([
            new ClipboardItem({
                'text/html': new Blob([link], { type: 'text/html' }),
                'text/plain': new Blob([text_fallback], { type: 'text/plain' }),
            })
        ]);
    } catch (err) {
        console.log('Permalink-to-clipboard using ClipboardItem failed, falling back to clipboard.writeText', err);
        copy_success = false;
    }
    if (! copy_success) {
        try {
            await navigator.clipboard.writeText(text_fallback);
        } catch (err) {
            console.log('Permalink-to-clipboard using clipboard.writeText failed', err);
            console.error('Failed to copy link to clipboard!');
            return
        }
    }

    console.log(`copied '${this_permalink_url}' to clipboard`);
    // temporary element to alert user that link was copied
    let copied_msg = document.createElement('p');
    copied_msg.setAttribute('role', 'alert');
    copied_msg.className = "permalink-alert";
    copied_msg.innerHTML = "Link to " + msg_link  + " copied to clipboard";
    elem.parentElement.insertBefore(copied_msg, elem);
    // show confirmation for a couple seconds
    await new Promise((resolve, reject) => setTimeout(resolve, 1500));
    copied_msg.remove();

}

// Add event listener to add onClick handler for permalinks
window.addEventListener("DOMContentLoaded", function() {
    const permalinks = document.querySelectorAll('.autopermalink > a');
    permalinks.forEach(link => {
        link.addEventListener('click', function(event) {
            event.preventDefault(); // Prevent default anchor behavior
            copyPermalink(link);
        });
    });
});


window.addEventListener("load",function(event) {


    /* click an image to magnify */
    $('body').on('click','.image-box > img:not(.draw_on_me):not(.mag_popup), .sbspanel > img:not(.draw_on_me):not(.mag_popup), figure > img:not(.draw_on_me):not(.mag_popup), figure > div > img:not(.draw_on_me):not(.mag_popup)', function(){
        var img_big = document.createElement('div');
        img_big.setAttribute('style', 'background:#fff;');
        img_big.setAttribute('class', 'mag_popup_container');
        img_big.innerHTML = '<img src="' + $(this).attr("src") + '" style="width:100%" class="mag_popup"/>';
 // place_to_put_big_img = $(this).parents(".sbsrow, figure, li").last();
        place_to_put_big_img = $(this).parents(".image-box, .sbsrow, figure, li, .cols2 article:nth-of-type(2n)").last();
  // for .cols2, the even ones have to go inside the previous odd one
        if (place_to_put_big_img.prop("tagName") == "ARTICLE") {
           place_to_put_big_img = place_to_put_big_img.prev().children().first();
        }
        $(img_big).insertBefore(place_to_put_big_img);
    });

    /* click the big image to make it go away */
    $('body').on('click','img.mag_popup', function(){
        this.parentNode.remove();
    });

    /* add ids to p that have none */
    p_no_id = document.querySelectorAll('.main p:not([id])');
    for (var n=p_no_id.length - 1; n >= 0; --n) {
        e = p_no_id[n];
        if (e.hasAttribute('id')) {
/*
            console.log(e, "was id'd in a previous round");
*/
            continue
        }
/*
console.log("this is e", e);
*/
        if (e.classList.contains('watermark')) {
            console.log(e, "skipping the watermark");
            continue
        }
/*
        console.log("\n                    XXXXXXXXX  p with no id", e);
*/
        prev_p = $(e).prevAll("p");
        console.log("prev_p", prev_p, "xx");
        if(prev_p.length == 0) {
            console.log("   PPP   problem: prev_p has no length:", prev_p);
            continue
        }
        console.log("which has id", prev_p[0].id);
        var parts_found = 1;
        var parts_to_id = [e];
        for (var i=0; i < prev_p.length; ++i) {
            this_previous = prev_p[i];
            console.log("i", i, "this_previous", this_previous, "id", this_previous.id, "???", this_previous.hasAttribute('id'))
            if (!this_previous.hasAttribute('id')) {
                parts_to_id.unshift(this_previous)
            }
            else {
                base_id = this_previous.id;
                console.log("base_id", base_id);
                console.log("ready to add id to", parts_to_id);
                for (var j=0; j < parts_to_id.length; ++j) {
                    ++parts_found;
                    var next_id = base_id + "-part" + parts_found.toString();
                    console.log("parts_found", parts_found, "next_id", next_id);
                    parts_to_id[j].setAttribute("id", next_id);
                }
                break // because we found the id that is the base for the missing ids
            }
        }
    }

    console.log("adding video popouts");
    all_iframes = document.querySelectorAll('body iframeXXXX');
    // for now, we just want the iframes that hace youtube in the src
    for (var i = 0; i < all_iframes.length; i++) {
      this_item = all_iframes[i];
      this_item_src = this_item.src;
 //     console.log("this_item_src", this_item_src);
      if(this_item_src.includes("youtube")) {
        this_item_id = this_item.id;
        this_item_width = this_item.width;
        this_item_height = this_item.height;
        if(this_item_height < 150) { continue }
        console.log("found a youtube video on", this_item_id);
        var empty_div = document.createElement('div');
        var this_videomag_container = document.createElement('div');
       parent_tag = this_item.parentElement.tagName;
       if(parent_tag == "FIGURE") {
         this_videomag_container.setAttribute("class", "videobig");
       } else {
         this_videomag_container.setAttribute("class", "videobig nofigure");
       }
/*
        this_videomag_container.setAttribute('class', 'videobig');
*/
        this_videomag_container.setAttribute('video-id', this_item_id);
        this_videomag_container.setAttribute('data-width', this_item_width);
        this_videomag_container.setAttribute('data-height', this_item_height);
        this_videomag_container.innerHTML = 'fit width';

/* replace this with a surrounding div, for placement, containing a inline-block so the background looks right */
        this_item.insertAdjacentElement("beforebegin", empty_div); // because of hard-coded permalinks being inline-block */
        this_item.insertAdjacentElement("beforebegin", this_videomag_container);
        this_item.insertAdjacentElement("beforebegin", empty_div); // because of hard-coded permalinks being inline-block */
      }
    }

/* replace this with a single class fo rthe button, with supplementary classes that say to shrink or grow */
    $(".videobig").click(function(){
       parent_video_id = this.getAttribute("video-id");
       console.log("clicked videobig for", parent_video_id);
       this_video = document.getElementById(parent_video_id);
       console.log("make big: ", this_video);
       original_width =  this.getAttribute("data-width");
       original_height =  this.getAttribute("data-height");

       browser_width = $(window).width();
       width_ratio = browser_width/original_width;
       console.log("the browser is wider by a factor of",width_ratio);
       this_video.setAttribute("width", width_ratio*original_width);
       this_video.setAttribute("height", width_ratio*original_height);
       this_video.setAttribute("style", "position:relative; left:-260px; z-index:1000");

       this.setAttribute("class", "videosmall");
       this.innerHTML = "make small";
      $(".videosmall").click(function(){
         console.log("clicked videosmall");
         parent_video_id = this.getAttribute("video-id");
         this_video = document.getElementById(parent_video_id);
         original_width =  this.getAttribute("data-width");
         original_height =  this.getAttribute("data-height");

         this_video.removeAttribute("style");
         this_video.setAttribute("width", original_width);
         this_video.setAttribute("height", original_height);
         this.setAttribute("class", "videobig");
         this.innerHTML = "fit width";
      });
    });

},
false);

/* for the random WW problems */

function updateURLParameter(url, param, paramVal){
  var newAdditionalURL = "";
  var tempArray = url.split("?");
  var baseURL = tempArray[0];
  var additionalURL = tempArray[1];
  var temp = "";
  if (additionalURL) {
    tempArray = additionalURL.split("&");
    for (var i=0; i<tempArray.length; i++){
      if(tempArray[i].split('=')[0] != param){
        newAdditionalURL += temp + tempArray[i];
        temp = "&";
      }
    }
  }
  var rows_txt = temp + "" + param + "=" + paramVal;
  return baseURL + "?" + newAdditionalURL + rows_txt;
}

function WWiframeReseed(iframe, seed) {
  var this_problem = document.getElementsByName(iframe)[0];
  var this_problem_url = this_problem.src;
  if (seed === undefined){seed = Number(this_problem.getAttribute('data-seed')) + 80 + 84 + 88;}
  this_problem.setAttribute('data-seed', seed);
  this_problem_url = updateURLParameter(this_problem_url, "problemSeed", seed);
  this_problem.src = this_problem_url;
}

function process_workspace() {
    console.log("processing workspace");
// next does not work, because the cursor does back to the beginning
// so:  need to handle the cursor
//    the_text = document.activeElement.innerHTML;
//    the_text = the_text.replace(/(^|\s)\$([^\$]+)\$(\s|$|[.,!?;:])/g, "\1\\(\2\\)\3")
//    document.activeElement.innerHTML = the_text
    MathJax.typesetPromise();
}
/* for the GeoGebra calculator */

function pretext_geogebra_calculator_onload() {
    $("#calculator-toggle").focus();
    var inputfield = $("input.gwt-SuggestBox.TextField")[0];
    console.log("inputfield", inputfield);
    inputfield.focus();
}
window.addEventListener("load",function(event) {

   /* scrolling on GG plot should scale, not move browser body */
//     var scrollWidth = 15;  //currently correct for FF, Ch, and Saf, but would be better to calculate
     var scrollWidth = getScrollbarWidth();
     if ( (navigator.userAgent.match(/Mozilla/i) != null) ) {
        // scrollWidth += 0.5
     }
     console.log("scrollWidth", scrollWidth);
     calcoffsetR = 5;
     calcoffsetB = 5;
     $('body').on('mouseover','#geogebra-calculator canvas', function(){
         $('body').css('overflow', 'hidden');
         $('html').css('margin-right', '15px');
         $('#calculator-container').css('right', (calcoffsetR+scrollWidth).toString() + 'px');
         $('#calculator-container').css('bottom', (calcoffsetB+scrollWidth).toString() + 'px');
     });

     $('body').on('mouseout','#geogebra-calculator canvas', function(){
         $('body').css('overflow', 'scroll')
         $('html').css('margin-right', '0');
         $('#calculator-container').css('right', calcoffsetR.toString() + 'px');
         $('#calculator-container').css('bottom', calcoffsetB.toString() + 'px');
     });

     $('body').on('click', '#calculator-toggle', function() {
         if ($('#calculator-container').css('display') == 'none') {
             $('#calculator-container').css('display', 'block');
             $('#calculator-toggle').addClass('open');
             $('#calculator-toggle').attr('title', 'Hide calculator');
             $('#calculator-toggle').attr('aria-expanded', 'true');
             create_calc_script = document.getElementById("create_ggb_calc");
             if (!create_calc_script) {
                 var ggbscript = document.createElement("script");
                 ggbscript.id = "create_ggb_calc";
                 ggbscript.innerHTML = "ggbApp.inject('geogebra-calculator')";
                 document.body.appendChild(ggbscript);
//                 setTimeout( function() {
//                     $("#calculator-toggle").focus();
//                     var inputfield = $("input.gwt-SuggestBox.TextField")[0];
//                     console.log("inputfield", inputfield);
//                     inputfield.focus();
//                 }, 4000);
             } else {
                 pretext_geogebra_calculator_onload();
//                 var inputfield = $("input.gwt-SuggestBox.TextField")[0];
//                 console.log("inputfield", inputfield);
//                 inputfield.focus();
             }
         } else {
             $('#calculator-container').css('display', 'none');
             $('#calculator-toggle').removeClass('open');
             $('#calculator-toggle').attr('title', 'Show calculator');
             $('#calculator-toggle').attr('aria-expanded', 'false');
         }
     });
});


/*
window.addEventListener("load",function(event) {
//    setTimeout( function() {
       console.log("changein play color");
       $('figure > div.onclick > svg > path').attr('fill', '#0000aa');
       $('path').attr('fill', '#0000aa')
//    }, 5000)
});
*/

window.addEventListener("load",function(event) {
    document.onkeyup = function(event)
    {
        var e = (!event) ? window.event : event;
        switch(e.keyCode)
        {
            case 13:  //CR
                 just_hit_escape = false;
                 if ($(document.activeElement).hasClass("workspace")) {
                    process_workspace()
                 }
            case 27: //esc
         //       var parent_sage_cell = $(this).closest(".sagecell_editor");
                var parent_sage_cell = document.activeElement.closest(".sagecell_editor");
                if (parent_sage_cell && !just_hit_escape) {
                    console.log("staying in the sage cell", parent_sage_cell, document.activeElement)
                    just_hit_escape = true;
                    setTimeout(function(){ just_hit_escape = false }, 1000);
     //           console.log("parent_sage_cell", parent_sage_cell);
     //           if ($(parent_sage_cell).hasClass('sagecell_editor')) {
     //              console.log("I am trapped in a sage cell", $(document.activeElement).closest(".sagecell_editor"));
     //              console.log($(document.activeElement));
     //              var this_sage_cell = $(document.activeElement).closest(".sagecell_editor");
     //              this_sage_cell.next().focus;
     //           }
     //           else
                } else
                if(knowl_focus_stack.length > 0 ) {
                   most_recently_opened = knowl_focus_stack.pop();
                   knowl_focus_stack_uid.pop();
                   most_recently_opened.focus();
                   console.log("moved back one knowl");
                } else {
                   console.log("no open knowls being tracked");
                   break;
                }
            break;
        }
};
},
false);

// a hack for hosted tracking

window.addEventListener("load",function(event) {
       if($('body').attr('id') == "judson-AATA") {
           console.log("            found AATA");
           console.log(" looking for id");
           if (typeof eBookConfig !== 'undefined') {
             if(eBookConfig['username']) {
                aa_id = "run" + eBookConfig['username'];
                ut_id = eBookConfig['username'];
             console.log(" done looking for id", ut_id);
var newscript = document.createElement('script');
  newscript.type = 'text/javascript';
  newscript.async = true;
  newscript.src = 'https://pretextbook.org/js/' + '0.13' + '/' + 'trails' + '.js';
  var allscripts = document.getElementsByTagName('script');
  var s = allscripts[allscripts.length - 1];
  console.log('s',s);
  console.log("adding a script", newscript);
  s.parentNode.insertBefore(newscript, s.nextSibling);
  trail = true;
             console.log(" done adding script");
             } else {
             console.log(" did not find username");
             }
           }  else {
             console.log(" did not find eBookConfig")
           }
       }
});

function loadResource(type, file) {
  /* type should be js or css */
  if (typeof js_version === 'undefined') { js_version = '0.2' }
  if (typeof css_version === 'undefined') { css_version = '0.6' }
  var newresource, allresources, s;
  var linktype = "script";
  if (type == "css") { linktype = "link" }
  newresource = document.createElement(linktype);

  if (type == "css") {
      newresource.type = 'text/css';
      newresource.rel = 'stylesheet';
      newresource.href = 'https://pretextbook.org/css/' + css_version + '/' + file + '.css';
      newresource.href += '?minivers=' + minivers;
  } else if (type == "js") {
      newresource.type = 'text/javascript';
//  newscript.async = true;
      newresource.src = 'https://pretextbook.org/js/' + js_version + '/' + file + '.js';
      newresource.src += '?minivers=' + minivers;
  } else {
      console.log("unknown resource type", type, "for", file);
      return
  }

  allresources = document.getElementsByTagName(linktype);
  s = allresources[allresources.length - 1];
  console.log('s',s);
  console.log("adding a resource", newresource);
  s.parentNode.insertBefore(newresource, s.nextSibling);
}


window.addEventListener("load",function(event) {
       if(false && $('body').attr('id') == "pretext-SA") {
           console.log("            found DMOI");
           if (typeof uname === "undefined") { uname = "" }
           console.log("aaaa", uname, "  uname");
           if(uname == "editor") {
                loadResource('js', 'edit');
           } else {
                console.log("not enabling editing")
           }
 /*       } else if ($('body').attr('id') == "pugetsound-SW") { */
        } else if (false && window.location.href.includes("soundwriting.pugetsound")) {
/* a bunch of temporary exploration for a Sound Writing survey */
            console.log("please take our survey");
            console.log(window.location.href);
            console.log(window.location.href.includes("soundwriting.pugetsound"));

            loadResource("js", "login");
            loadResource("css", "features");
            setTimeout( loadResource("js", "survey"), 1000);  /* I know: sloppy */

  //      } else if ((typeof online_editable !== 'undefined') &&  online_editable) {
        } else if (false && $('body').attr('id') == "pretext-SA") {
            loadResource('css', 'features');
            loadResource('js', 'login')
            loadResource('js', 'edit');
        } else {
            var this_source_txt;
            var source_url = window.location.href;
            source_url = source_url.replace(/(#|\?).*/, "");
            source_url = source_url.replace(/html$/, "ptx");
            if (typeof sourceeditable !== 'undefined') {
              fetch(source_url).then(
                  function(u){ return u.text();}
                ).then(
                  function(text){
                      this_source_txt = text;
                      if (this_source_txt.includes("404 Not")) {
                          console.log("Editing not enabled: source unavailable")
                      } else {
                        loadResource('css', 'features');
                        loadResource('css', 'edit');
                        loadResource('js', 'login')
                        loadResource('js', 'edit');
                      }
                  }
                );
              } else {
                   console.log("Source file unavailable: editing not possible")
              }
        }

});

// this is to open every knowl on a page
// (this code is not actually used anywhere)
window.addEventListener("load",function(event) {
   if($('body').hasClass("braillesample")) {
       var knowl_id_counterX = 0;
       console.log("            found braillesample");
       var all_knowls = $('[data-knowl]');
       console.log("found", all_knowls.length, "knowls");
       console.log("which are", all_knowls);
       for (var j=1; j < all_knowls.length; ++j) {
           console.log(j, "un-knowling", all_knowls[j]);
           console.log("attr", $(all_knowls[j]).attr("data-knowl"));
           $knowl = $(all_knowls[j]);
           if(!$knowl.attr("data-knowl-uid")) {
              $knowl.attr("data-knowl-uid", knowl_id_counterX);
              knowl_id_counterX++;
            }
            knowl_click_handler($knowl);
          // knowl_click_handler($(all_knowls[j]))
       }
}});

// when the anchor is a knowl, open it
window.addEventListener("load",function(event) {
   if (window.location.hash.length) {
       let id = window.location.hash.substring(1);
       var the_anchor = document.getElementById(id);
       console.log("id", id, "the_anchor", the_anchor);
       if (the_anchor.tagName == "ARTICLE") {
         var contained_knowl = the_anchor.querySelector("a[data-knowl]");
         if (contained_knowl && contained_knowl.parentElement == the_anchor) {
           console.log("found a knowl", contained_knowl);
       //    knowl_click_handler($(contained_knowl))
           contained_knowl.click()
         }
       } else if (the_anchor.hasAttribute("data-knowl")) {
           the_anchor.click()
       } else {
           // if it is a hidden knowl, find the knowl and open it
           var this_hidden_content = the_anchor.closest(".hidden-content");
           if (this_hidden_content) {
               console.log("linked to a hidden knowl with this_hidden_content", this_hidden_content);
               var the_refid = this_hidden_content.id;
               var this_knowl = document.querySelector('[data-refid="' + the_refid + '"]');
               this_knowl.click()
           }
       }
   }
});


// What purpose does this serve?
function urlattribute() {
        var this_urlstub = window.location.hostname;
        document.body.setAttribute("data-urlstub", this_urlstub);
}


// The new method for creating pages and adjusting workspace //

// This is used multiple places to set height of workspace divs to their author-provided heights
function setInitialWorkspaceHeights() {
    const workspaces = document.querySelectorAll('.workspace');
    workspaces.forEach(ws => {
        ws.style.height = ws.getAttribute('data-space') || '0px';
        ws.setAttribute("contenteditable", "true");
    });
}

// If a printout (worksheet or handout) includes authored pages, we only need to put content before the first page and after the last page into the first and last pages, respectively.
function adjustPrintoutPages() {
    const printout = document.querySelector('section.worksheet, section.handout');
    if (!printout) {
        console.warn("No printout found, exiting adjustPrintoutPages.");
        return;
    }
    const pages = printout.querySelectorAll('.onepage');
    if (pages.length === 0) {
        console.warn("No pages found in printout, exiting adjustPrintoutPages.");
        return;
    }
    // Find all children before the first .onepage element:
    const firstPage = pages[0];
    const lastPage = pages[pages.length - 1];
    // Move all children before the first page into the first page
    const pageFirstChild = firstPage.firstChild;
    let currentChild = printout.firstChild;
    while (currentChild && currentChild !== firstPage) {
        const nextChild = currentChild.nextSibling; // Save the next sibling before removing
        firstPage.insertBefore(currentChild, pageFirstChild); // Move to the first page
        currentChild = nextChild; // Move to the next child
    }
    // Now find all children after the last .onepage element:
    let nextChild = lastPage.nextSibling;
    while (nextChild) {
        const tempChild = nextChild;
        nextChild = nextChild.nextSibling;
        lastPage.appendChild(tempChild);
    }
    console.log("Moved all content before the first page and after the last page into the respective pages.");
}

// This is the main function we will call then a printout does not come from the XSL with pages already defined (for now, the XSL will keep the <page> behavior as an option).
function createPrintoutPages(margins) {

    // Assumptions: needs to work for both letter (8.5in x 11in) and a4 (210mm x 297mm) paper sizes.  We will work in pixels (96/in): those are 816px x 1056px and 794px x 1122.5px respectively (1 inch = 96 px, 1 cm = 37.8 px).  We assume that the printing interface of the browser will do the right thing with these.

    // For purposes of finding page breaks, we will use 794 as our width and 1056 as our height (so A4 width and letter height).  Then we will rescale workspace on each page to fit the actual paper size selected.

    const conservativeContentHeight = 1056 - (margins.top + margins.bottom); // in pixels
    const conservativeContentWidth = 794 - (margins.left + margins.right); // in pixels

    const printout = document.querySelector('section.worksheet, section.handout');
    if (!printout) {
        console.warn("No printout found, exiting createPrintoutPages.");
        return;
    }
    printout.style.width = toString(conservativeContentWidth + margins.left + margins.right) + 'px';
    // Set the height of each workspace based on its data-space attribute
    setInitialWorkspaceHeights(printout);

    // We want to consider each "block" of the printout.  Some of these will be direct children of the printout, some will be nested inside these children.  So first create a list of the elements that we consider blocks.
    let rows = [];
    for (const child of printout.children) {
        if (child.classList.contains('sidebyside')) {
            // sidebyside could have tasks, but we don't want to dive further into them.
            rows.push(child);
        } else if (child.querySelector('.task')) {
            // Keep the child as a block, but put each task after the first one as its own row:
            rows.push(child);
            const tasks = child.querySelectorAll('.task');
            for (let i = 1; i < tasks.length; i++) {
                rows.push(tasks[i]);
            }
        // Skipping separate treatment of exercisegroups for now.
        //} else if (child.classList.contains('exercisegroup')) {
        //    for (const subChild of child.children) {
        //        if (subChild.classList.contains('exercisegroup-exercises')){
        //            for (const row of subChild.children){
        //                rows.push(row);
        //            }
        //        } else {
        //            rows.push(child);
        //        }
        //    }
        } else {
            rows.push(child);
        }
    }
    // Loop through the blocks and create a list of objects including the block, its height, and its workspace height.  Only include blocks that have height (this will remove autopermalinks, as desired).
    let blockList = [];
    for (const row of rows) {
        let blockHeight = getElementTotalHeight(row);
        if (blockHeight === 0) {
            console.log("Skipping row with zero height:", row);
            continue;
        }
        let totalWorkspaceHeight = 0;
        if (row.querySelector('.workspace')) {
            // Workspace height is not just sum of workspace heights; we need to be careful with sidebyside and columns
            totalWorkspaceHeight = getElemWorkspaceHeight(row);
        }
        blockList.push({elem: row, height: blockHeight, workspaceHeight: totalWorkspaceHeight});
    }

    // Now find pageBreaks so that extra workspace is as uniform as possible.
    const pageBreaks = findPageBreaks(blockList, conservativeContentHeight);

    // Create page divs and insert rows into them
    for (let i = 0; i < pageBreaks.length; i++) {
        const pageDiv = document.createElement('section');
        pageDiv.classList.add('onepage');
        if (i === 0) {
            pageDiv.classList.add('firstpage');
        }
        // A single page will be both first and last
        if (i === pageBreaks.length - 1) {
            pageDiv.classList.add('lastpage');
        }
        // The pageBreaks array gives the indices of blocks that should start a page.
        // So we will want to look for go through the blocks selecting those starting with the previous index (or 0) up to but not including the current index.
        const start = pageBreaks[i-1] || 0;
        const end = pageBreaks[i];
        for (let j = start; j < end; j++) {
            const row = blockList[j].elem;
            pageDiv.appendChild(row);
        }
        printout.appendChild(pageDiv);
    }

    // remove any old content that is not in a page
    for (const child of printout.children) {
        if (!child.classList.contains('onepage')) {
            console.log("Removing old child not in a page:", child);
            printout.removeChild(child);
        }
    }
}


    // We look at each page and adjust the heights of the workspaces to fit it nicely into the page.
    // The width and height of the page will now depend on the letter or a4 setting.
function adjustWorkspaceToFitPage({paperSize, margins}) {
    let paperWidth, paperHeight;
    if (paperSize === 'a4' || document.body.classList.contains('a4')) {
        console.log("Setting page size to A4");
        paperWidth = 794; // 210mm in px
        paperHeight = 1122.5; // 297mm in px 794px x 1122.5px
    } else {
        console.log("Setting page size to Letter");
        paperWidth = 816; // 8.5in in px
        paperHeight = 1056; // 11in in px
    }
    const paperContentHeight = paperHeight - (margins.top + margins.bottom);

    // Reset the heights of workspace divs to their author-provided heights
    setInitialWorkspaceHeights();

    const pages = document.querySelectorAll('.onepage');
    pages.forEach(page => {
        console.log("Adjusting workspace height for page:", page);
        // Set width to get accurate calculations
        page.style.width = paperWidth + 'px';
        const rows = page.children;
        let totalContentHeight = 0;
        let totalWorkspaceHeight = 0;
        for (const row of rows) {
            totalContentHeight += getElementTotalHeight(row);
            totalWorkspaceHeight += getElemWorkspaceHeight(row);
        }
        if (totalWorkspaceHeight === 0) {
            console.log("No workspaces on this page, skipping workspace adjustment.");
            // Reset the style for the page
            page.style.width = "";
            return;
        }
        const extraHeight = paperContentHeight - totalContentHeight;
        console.log("Extra height to distribute across workspaces:", extraHeight, "px.");
        // Determine the factor by which to multiply each workspace to make the total height fit the paperContentHeight
        const workspaceAdjustmentFactor = (totalWorkspaceHeight + extraHeight) / totalWorkspaceHeight;
        console.log("Workspace adjustment factor for page:", workspaceAdjustmentFactor);
        // Now adjust each workspace in the page by this factor
        const pageWorkspaces = page.querySelectorAll('.workspace');
        pageWorkspaces.forEach(ws => {
            const originalHeight = ws.offsetHeight;
            const newHeight = originalHeight * workspaceAdjustmentFactor;
            ws.style.height = newHeight + "px";
        });
        // Reset the style for the page
        page.style.width = "";
    });
    console.log("Set page sizes to content area of paper size.");
}

// Helper functions for calculating heights and workspace sizes
function getElementTotalHeight(elem) {
    // Calculate the total height of the element, including padding, border, and top margin.
    const style = getComputedStyle(elem);
    const marginTop = parseFloat(style.marginTop);
    const marginBottom = parseFloat(style.marginBottom);
    const height = elem.offsetHeight;
    return height + marginTop + marginBottom;
}

function getElemWorkspaceHeight(elem) {
    // Calculate the total height of all workspaces in the element.
    // This is easy for elements stacked vertically, but we must be careful for side-by-side workspaces.  Since we will multiply each workspace by a factor to fit the page, taking the largest workspace height should give us an upper bound for the amount of vertical space that is workspace.
    // Note that this won't work well if we need to reduce the workspace, since there we would want to take the minimum heights.
    if (elem.classList.contains('sidebyside')) {
        const sbspanels = elem.querySelectorAll('.sbspanel');
        let max = 0;
        sbspanels.forEach(panel => {
            const workspaces = panel.querySelectorAll('.workspace');
            let totalHeight = 0;
            workspaces.forEach(workspace => {
                const workspaceHeight = workspace.offsetHeight;
                if (workspaceHeight) {
                    totalHeight += workspaceHeight;
                }
            });
            if (totalHeight > max) {
                max = totalHeight; // Take the maximum height of workspaces in sidebyside
            }
        });
        return max; // Return the maximum height of workspaces in sidebyside
    }
    // We can take care of exercisegroups and single colomn regular layout together.
    let columns = 1;
    if (elem.classList.contains('exercisegroup')) {
        // Check for column classes and set columns accordingly
        for (let i = 2; i <= 6; i++) {
            if (elem.querySelector(`.cols${i}`)) {
            columns = i;
            console.log("Found exercisegroup with columns:", columns);
            break;
            }
        }
    }
    const workspaces = elem.querySelectorAll('.workspace');
    let totalHeight = 0;
    workspaces.forEach(ws => {
        const workspaceHeight = ws.offsetHeight;
        if (workspaceHeight) {
            totalHeight += workspaceHeight;
        }
    });
    return totalHeight / columns; // Divide by columns if sidebyside to get average height per column
}

// Functions for finding the optimal page breaks
function findPageBreaks(rows, pageHeight) {
    // An array for the page breaks.  The nth element will be the index of the last row on page n.
    let pageBreaks = [];
    // An array for the minimum cost possible for rows i to the end.
    let minCost = Array(rows.length).fill(Infinity);
    minCost[rows.length] = 0; // No cost for no rows
    // An array to keep track of the next row to start a new page after i in minCost.
    let nextPageBreak = Array(rows.length).fill(-1);

    // Now loop through the rows in reverse order to find the optimal page breaks.
    for (let i = rows.length - 1; i >= 0; i--) {
        let cumulativeHeight = 0;
        let cumulativeWorkspaceHeight = 0;
        // Loop through the rows starting from i to find the best page break
        for (let j = i; j < rows.length; j++) {
            cumulativeHeight += rows[j].height;
            cumulativeWorkspaceHeight += rows[j].workspaceHeight;
            if (cumulativeHeight > pageHeight) {
                if (j === i) {
                    // The page height is too big for a single row.  We make this row its own page and move on.
                    console.log("Row", i, "exceeds page height by itself, setting as its own page.");
                    minCost[i] = 0; // No cost for a single row
                    nextPageBreak[i] = i + 1; // The next page break is after this row
                    break; // Move to the next row
                } else {
                    // We have already set minCost and NextPageBreak at an earlier point in the loop.  This means we have done the best we can for this row so we stop and move to the next earlier row.
                    break; // Stop if we exceed the page height
                }
            }

            const cost = (pageHeight - cumulativeHeight)**2 + minCost[j+1]; // Cost is how much space is left on the page, plus the cost of the following pages.
            if (cost < minCost[i]) {
                minCost[i] = cost;
                nextPageBreak[i] = j+1; // Set the next page break to be after row j
            }
        }
    }
    // Backtrack to find the actual page breaks based on nextPageBreak
    // Note: the nextPage = 1 is not an indexing mistake; we always assume that row 0 is a title and will go on the same page as row 1.
    let nextPage = 1;
    while (nextPage < rows.length) {
        pageBreaks.push(nextPageBreak[nextPage]);
        nextPage = nextPageBreak[nextPage];
    }
    return pageBreaks;
}

function setPageGeometryCSS({paperSize, margins}) {
    // Remove any existing geometry CSS to avoid duplicates
    const existingStyle = document.getElementById("page-geometry-css");
    if (existingStyle) {
        existingStyle.remove();
    }
    let wsWidth = paperSize === "letter" ? "816px" : "794px"; // 8.5in for Letter, 210mm for A4
    let wsHeight = paperSize === "letter" ? "1056px" : "1123px"; // 11in for Letter, 297mm for A4
    // Create a new style element for geometry CSS
    const style = document.createElement("style");
    // Add an identifier to the style element to avoid conflicts
    style.id = "page-geometry-css";
    // NB we need to add the fallback values for the margins in @page because some browsers do not support CSS variables in @page rules.
    style.textContent = `
        :root {
            --ws-width: ${wsWidth};
            --ws-height: ${wsHeight};
            --ws-top-margin: ${margins.top}px;
            --ws-right-margin: ${margins.right}px;
            --ws-bottom-margin: ${margins.bottom}px;
            --ws-left-margin: ${margins.left}px;
        }
        @page {
            margin: var(--ws-top-margin, ${margins.top}px) var(--ws-right-margin, ${margins.right}px) var(--ws-bottom-margin, ${margins.bottom}px) var(--ws-left-margin, ${margins.left}px);
        }
    `;
    document.head.appendChild(style);
}

function toggleWorkspaceHighlight(isChecked) {
    if (isChecked) {
        // Toggle the highlight class on the body based on the checkbox state
        document.body.classList.add("highlight-workspace");
        // If we haven't already inserted divs to show the original workspace heights, do that now
        if (!document.querySelector('.workspace-container')) {
            console.log("adding original workspace divs");
            // Insert divs to show the original workspace
            document.querySelectorAll('.workspace').forEach(workspace => {
                // Create a container div to hold the workspace div and the original div
                const container = document.createElement('div');
                container.classList.add('workspace-container');
                // Set the container height to the current workspace height
                container.style.height = window.getComputedStyle(workspace).height;
                const original = document.createElement('div');
                original.classList.add('original-workspace');
                const originalHeight = workspace.getAttribute('data-space') || '0px';
                original.setAttribute('title', 'Author-specified workspace height (' + originalHeight + ')');
                console.log("setting original workspace height for", workspace);
                // Use the data-space attribute for height of original workspace
                original.style.height = originalHeight;
                // insert original div before the workspace content
                container.appendChild(original);
                // Add a warning class if the original height is greater than the current height
                if (original.offsetHeight > workspace.offsetHeight) {
                    original.classList.add('warning');
                }
                // Move the workspace into the container
                workspace.parentNode.insertBefore(container, workspace);
                container.appendChild(workspace);
            });
        }
    } else {
        document.body.classList.remove("highlight-workspace");
    }
}

// Printout print preview and page setup
window.addEventListener("load",function(event) {
  // We condition on the existence of the papersize radio buttons, which only appear in the printout print preview.
  if (document.querySelector('input[name="papersize"]')) {
    // First, get the margins for pages to be passed around as needed.
    const marginList = document.querySelector('section.worksheet, section.handout').getAttribute('data-margins').split(' ');
    // Convert margin values to pixels if they are not already numbers
    function toPixels(value) {
        if (typeof value === "number") return value;
        if (typeof value !== "string") return 0;
        value = value.trim();
        if (value.endsWith("px")) {
            return parseFloat(value);
        } else if (value.endsWith("in")) {
            return Math.floor(parseFloat(value) * 96);
        } else if (value.endsWith("cm")) {
            return Math.floor(parseFloat(value) * 37.8);
        } else if (value.endsWith("mm")) {
            return Math.floor(parseFloat(value) * 3.78);
        } else if (value.endsWith("pt")) {
            return Math.floor(parseFloat(value) * (96 / 72));
        } else {
            // fallback: try to parse as px
            return parseFloat(value) || 0;
        }
    }
    const margins = {
        top: toPixels(marginList[0] || "0.75in"), // Default to 0.75in if not specified
        right: toPixels(marginList[1] || "0.75in"),
        bottom: toPixels(marginList[2] || "0.75in"),
        left: toPixels(marginList[3] || "0.75in")
    }
    // Get the papersize from localStorage or set it based on user's geographic region
    let paperSize = localStorage.getItem("papersize");
    if (paperSize) {
      const radio = document.querySelector(`input[name="papersize"][value="${paperSize}"]`);
      if (radio) {
        radio.checked = true;
      }
      // Set the papersize class on body
      document.body.classList.remove("a4", "letter");
      document.body.classList.add(paperSize);
      setPageGeometryCSS({paperSize: paperSize, margins: margins});
    } else {
      // Try to set papersize based on user's geographic region
      // Default to 'letter' for North and South America, 'a4' elsewhere
        try {
          fetch('https://ipapi.co/json/')
            .then(response => response.json())
            .then(data => {
          let continent = data && data.continent_code ? data.continent_code : "";
          paperSize = (continent === "NA" || continent === "SA") ? "letter" : "a4";
          const radio = document.querySelector(`input[name="papersize"][value="${paperSize}"]`);
          if (radio) {
            radio.checked = true;
            localStorage.setItem("papersize", paperSize);
          }
          document.body.classList.remove("a4", "letter");
          document.body.classList.add(paperSize);
          console.log("Setting papersize to", paperSize);
            })
            .catch((err) => {
            // rethrow to be caught by the outer catch
            throw err;
            });
        } catch (e) {
          // fallback: default to letter
          const radio = document.querySelector(`input[name="papersize"][value="letter"]`);
          if (radio) radio.checked = true;
        }
      //NB: the default papersize is set to 'letter' in the body class list.
    }
    const papersizeRadios = document.querySelectorAll('input[name="papersize"]');
    papersizeRadios.forEach(radio => {
      radio.addEventListener('change', function() {
        if (this.checked) {
          document.body.classList.remove("a4", "letter");
          document.body.classList.add(this.value);
          localStorage.setItem("papersize", this.value);
          console.log("Setting papersize to", this.value);

          // If the "highlight workspace" checkbox was already checked, then we should restart the process by reloading the page.  Specifically, we run into issues when there are .workspace-container divs already present.
          if (document.querySelector(".workspace-container")) {
            console.log("Reloading page to apply new papersize with workspace highlight enabled.");
            window.location.reload();
            return;
          } else {
            // Otherwise, we can just adjust the workspace heights to fit the new paper size.
            console.log("Adjusting workspace heights to fit new papersize.");
            adjustWorkspaceToFitPage({paperSize: this.value, margins: margins});
            setPageGeometryCSS({paperSize: this.value, margins: margins});
          }
        }
      });
    });

    // Open all details elements (knowls) on the page
    var born_hidden_knowls = document.querySelectorAll('details');
    console.log("born_hidden_knowls", born_hidden_knowls);
    born_hidden_knowls.forEach(function(detail) {
        detail.open = true;
    });
    // If the printout has authored pages, there will be at least one .onepage element.
    if (document.querySelector('.onepage')) {
        adjustPrintoutPages();
        /* not the right way:  need to figure out what this needs to wait for */
        //window.setTimeout(adjustPrintoutPages, 1000);
    } else {
        createPrintoutPages(margins);
    }
    // After pages are set up, we adjust the workspace heights to fit the page (based on the paper size).
    adjustWorkspaceToFitPage({paperSize: paperSize, margins: margins});

    console.log("finished adjusting workspace");


    // Get the 'highlight workspace' checkbox state from localStorage or set it to false by default
    const highlightWorkspaceCheckbox = document.getElementById("highlight-workspace-checkbox");
    if (highlightWorkspaceCheckbox) {
        highlightWorkspaceCheckbox.checked = localStorage.getItem("highlightWorkspace") === "true";
        highlightWorkspaceCheckbox.addEventListener("change", function() {
            localStorage.setItem("highlightWorkspace", this.checked);
            toggleWorkspaceHighlight(this.checked);
        });
        // Initial toggle to apply the highlight class if checked
        toggleWorkspaceHighlight(highlightWorkspaceCheckbox.checked);
    }



        // Not sure why this is here:
      window.setTimeout(urlattribute, 1500);
  }
});



//-----------------------------------------------------------------
// Dark/Light mode swiching

function isDarkMode() {
    if (document.documentElement.dataset.darkmode === 'disabled')
        return false;

    const currentTheme = localStorage.getItem("theme");
    if (currentTheme === "dark")
        return true;
    else if (currentTheme === "light")
        return false;

    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
}

function setDarkMode(isDark) {
    if(document.documentElement.dataset.darkmode === 'disabled')
        return;

    const parentHtml = document.documentElement;
    const iframes = document.querySelectorAll("iframe[data-dark-mode-enabled]");

    // Update the parent document
    if (isDark) {
        parentHtml.classList.add("dark-mode");
    } else {
        parentHtml.classList.remove("dark-mode");
    }

    // Sync each iframe's <html> class with the parent
    for (const iframe of iframes) {
        try {
            const iframeHtml = iframe.contentWindow.document.documentElement;
            if (isDark) {
              iframeHtml.classList.add("dark-mode")
            } else {
              iframeHtml.classList.remove("dark-mode")
            }
        } catch (err) {
            console.warn("Dark mode sync to iframe failed:", err);
        }
    }

    const modeButton = document.getElementById("light-dark-button");
    if (modeButton) {
        modeButton.querySelector('.icon').innerText = isDark ? "light_mode" : "dark_mode";
        modeButton.querySelector('.name').innerText = isDark ? "Light Mode" : "Dark Mode";
    }
}

// Run this as soon as possible to avoid flicker
setDarkMode(isDarkMode());

// Rest of dark mode setup logic waits until after load
window.addEventListener("DOMContentLoaded", function(event) {
    // Rerun setDarkMode now that it can update buttons
    const isDark = isDarkMode();
    setDarkMode(isDark);

    const modeButton = document.getElementById("light-dark-button");
    modeButton.addEventListener("click", function() {
        const wasDark = isDarkMode();
        setDarkMode(!wasDark);
        localStorage.setItem("theme", wasDark ? "light" : "dark");
    });
});

// Share button and embed in LMS code
window.addEventListener("DOMContentLoaded", function(event) {
    const shareButton = document.getElementById("embed-button");
    if (shareButton) {
        const sharePopup = document.getElementById("embed-popup");
        const embedCode = "<iframe src='" + window.location.href + "?embed' width='100%' height='1000px' frameborder='0'></iframe>";
        const embedTextbox = document.getElementById("embed-code-textbox");
        if (embedTextbox) {
            embedTextbox.value = embedCode;
        }
        shareButton.addEventListener("click", function() {
            sharePopup.classList.toggle("hidden");
        });
        const copyButton = document.getElementById("copy-embed-button");
        if (copyButton) {
            copyButton.addEventListener("click", function() {
                const embedTextbox = document.getElementById("embed-code-textbox");
                if (embedTextbox) {
                    navigator.clipboard.writeText(embedCode).then(() => {
                        console.log("Embed code copied to clipboard!");
                    }).catch(err => {
                        console.error("Failed to copy embed code: ", err);
                    });
                    //copyButton.innerHTML = "✓✓";
                    // show confirmation for 2 seconds:
                    copyButton.querySelector('.icon').innerText = "library_add_check";
                    setTimeout(function() {
                        copyButton.querySelector('.icon').innerText = "content_copy";
                        sharePopup.classList.add("hidden");
                    }, 450);
                }
            });
        }
    }
});

// Hide everything except the content when the URL has "embed" in it
window.addEventListener("DOMContentLoaded", function(event) {
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has("embed")) {
        // Set dark mode based on value of param
        if (urlParams.get("embed") === "dark") {
            setDarkMode(true);
        } else {
            setDarkMode(false);
        }
        const elemsToHide = [
            "ptx-navbar",
            "ptx-masthead",
            "ptx-page-footer",
            "ptx-sidebar",
            "ptx-content-footer"
        ];
        for (let id of elemsToHide) {
            const elem = document.getElementById(id);
            if (elem) {
                elem.classList.add("hidden");
            }
        }
    }
});

// START Support for code-copy button functionality
document.addEventListener("click", (ev) => {
    const codeBox = ev.target.closest(".clipboardable");
    if (!navigator.clipboard || !codeBox) return;
    const button = ev.target.closest(".code-copy");
    const preContent = codeBox.querySelector("pre").textContent;
    navigator.clipboard.writeText(preContent);
    button.classList.toggle("copied")
    setTimeout(() => button.classList.toggle("copied"), 1000);
});

document.addEventListener("DOMContentLoaded", () => {
    const elements = document.querySelectorAll(".clipboardable");
    for (el of elements) {
        const div = document.createElement("div");
        div.classList.add("clipboardable");
        el.classList.remove("clipboardable");
        el.replaceWith(div);
        div.insertAdjacentElement("afterbegin", el);
        div.insertAdjacentHTML("beforeend", `
    <button class="code-copy" title="Copy code" role="button" aria-label="Copy code" >
        <span class="copyicon material-symbols-outlined">content_copy</span>
        <span class="checkmark material-symbols-outlined">check</span>
    </button>
            `.trim());
    }
});
// END Support for code-copy button functionality
