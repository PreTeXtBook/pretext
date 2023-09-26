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
  generate permalink description
*/
function permalinkDescription(elem) {
    var retStr;
    var typeStr = "";
    var nodeName = elem.nodeName;
    if (elem.classList.contains("para")) {
        if (elem.parentElement.nodeName == "LI") { nodeName = 'LI' }
        else { nodeName = 'P' }
    }
    var isExerciseGroup = false;
    if ((nodeName == 'P') && (elem.parentElement.parentElement.classList.contains("exercisegroup"))) {
        isExerciseGroup = true;
    }
    // the data we need will be either in an element with class .heading or in a figcaption element
    // but for:
    //   exercisegroup            -- the heading element will be further up the tree
    //   hidden knowl             -- the heading element will be further down the tree (this is the 'a > .heading' selector)
    //   figcaption (figure-like) -- we are already in the figcaption node
    var headerNode;
    if (isExerciseGroup)  {
        headerNode = elem.parentElement.parentElement.querySelector(':scope > .heading');
    } else if (nodeName == 'FIGCAPTION') {
        headerNode = elem;
    } else {
        headerNode = elem.querySelector(':scope > .heading, :scope > figcaption, :scope > a > .heading');
    }
    var numberStr = "";
    var numberSep = " ";
    var titleStr = "";
    var typeStr = "";
    var resultNodes;
    if (nodeName == 'P') {
        if (isExerciseGroup) {
            typeStr = "Exercise Group";
        } else {
            typeStr = "Paragraph";
        }
    } else if (nodeName == 'LI') {
        typeStr = "List item";

    } else if (!headerNode) {
        // handles assemblages with no title
        var className = elem.className.split(' ')[0]
        typeStr = className.charAt(0).toUpperCase() + className.slice(1);
    } else {
        if ((nodeName == 'ARTICLE') && (elem.classList.contains('exercise')) ) {
            typeStr = "Exercise";
        } else if ((nodeName == 'ARTICLE') && (elem.classList.contains('task')) ) {
            typeStr = elem.parentElement.firstElementChild.getAttribute('data-description');
            numberSep = "";
        } else {
            resultNodes = headerNode.getElementsByClassName("type");
            if (resultNodes.length > 0) {
                typeStr = resultNodes[0].innerText;
            }
        }
    }
    typeStr = typeStr || "";  // hack because of error from https://pretextbook.org/examples/sample-article/html/interesting-corollary.html#p-206
    if (headerNode) {
        if (typeStr.length > 0) {
            resultNodes = headerNode.getElementsByClassName("codenumber");
            if (resultNodes.length > 0) {
                numberStr = resultNodes[0].innerText;
            }
        }
        resultNodes = headerNode.getElementsByClassName("title");
        if (resultNodes.length > 0) {
            titleStr = resultNodes[0].innerText;
        }
    }
    retStr = typeStr;
    if ((typeStr.length > 0) && (numberStr.length > 0)) {
        retStr += numberSep + numberStr;
    }
    if (titleStr.length > 0) {
        if (retStr.length > 0) {
            if (typeStr != titleStr) {
                retStr += ": " + titleStr;
            }
        } else {
            retStr = titleStr;
        }
    }
    var lastChr = retStr.charAt(retStr.length - 1);
    if ((lastChr == '.') || (lastChr == ':'))  {
        retStr = retStr.slice(0,retStr.length - 1);
    }
    return retStr;
}

/*
  copy permalink address to clipboard
  requires browser support, otherwise does nothing
*/
async function copyPermalink(elem) {
    // structure borrowed from https://flaviocopes.com/clipboard-api/
//    elem.preventDefault();
    if (!navigator.clipboard) {
        // Clipboard API not available
        console.log("Error: Clipboard API not available");
        return
    }
    console.log("copying permalink for", elem);
    var linkNode = elem.querySelector(':scope > a');
    if (!linkNode) {
        console.log("Error: Something went wrong finding permalink URL")
        return
    }
    const this_permalink_url = linkNode.getAttribute('href');
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

window.addEventListener("load",function(event) {
    $(".aside-like").click(function(){
       $(this).toggleClass("front");
    });
/* if you click a knowl in an aside, the 'front' stays the
   same because it toggles twice.  A more elegant solution is welcome */
    $(".aside-like a").click(function(){
       $(this).closest(".aside-like").toggleClass("front");
    });

/* temporary, so that aside-like knowls open in the body of the document */
/* later the addafter will be inserted by PTX? */
    $("a").each(function() {
        if($(this).parents('.aside-like').length) {
            $(this).attr("addafter", "#" + $(this).closest('.aside-like').attr('id') );
            $(this).closest('.aside-like').attr("tabindex", "0");
        }
    });

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

    if (document.querySelector('body.standalone')) {
        console.log("no permalinks on standalone pages")
    } else {
        console.log("                       adding permalinks");
        /* add permalinks to all sections and articles */
        /* the main section p is just for legacy pre div.para html */
        items_needing_permalinks = document.querySelectorAll('main section:not(.introduction), main section .para, main section p, main section article, main section > figure.table-like, main section > figure.figure-like > figcaption, main section  .exercisegroup article, main section  .exercisegroup, main section article.exercise, main section .discussion-like,  main section article.paragraphs > figure.table-like, main section article.paragraphs > figure.figure-like, section > details');
        //   items_needing_permalinks = document.querySelectorAll('body section article');
        this_url = window.location.href.split('#')[0];
        permalink_word = "&#x1F517;";
        for (var i = 0; i < items_needing_permalinks.length; i++) {
            this_item = items_needing_permalinks[i];
            var this_anchor = this_item.id;
            if (Boolean(this_item.closest(".parsons"))) { continue }  /* parsons block */
            if (Boolean(this_item.closest("details"))) { continue }  /* hidden in details */
            if (this_item.parentElement.classList.contains("lines")) { continue }  /* parsons block */
            if (getComputedStyle(this_item).display == "inline") { continue }  /* inline paragraph at start of article, for example*/
            try {
                if(this_item.closest(".hidden-content")) {continue}
            } catch {
                // do nothing, because we are just avoiding permalinks on born-hidden knowls
            }
            if (this_item.tagName == "FIGCAPTION") { this_anchor  = this_item.parentElement.id }
            if (this_item.classList.contains("para")) {
               if (this_item.id == "") {
                   // should be .para inside .para.logical 
                   this_anchor  = this_item.parentElement.id;
                   if(this_item.parentElement.parentElement.nodeName == "LI") {
                   // we actually had a para inside a para.logical inside an li
                       this_anchor  = "" //this_item.parentElement.parentElement.id;
                   }
               } else if (this_item.parentElement.nodeName == "LI") {
               //    this_anchor  = this_item.parentElement.id;
                   this_anchor  = "";
               }
            }
            if(this_anchor) {
                this_permalink_url = this_url + "#" + this_anchor;
                const this_permalink_description = permalinkDescription(this_item);
                this_permalink_container = document.createElement('div');
                this_permalink_container.setAttribute('class', 'autopermalink');
                this_permalink_container.setAttribute('onclick', 'copyPermalink(this)');
                this_permalink_container.setAttribute('data-description', this_permalink_description);
    //         this_permalink_container.innerHTML = '<span href="' + this_permalink_url + '">' + permalink_word + '</span>';
                this_permalink_container.innerHTML = '<a href="' + this_permalink_url + '" title="Copy permalink for ' + this_permalink_description + '">' + permalink_word + '</a>';
                this_item.insertAdjacentElement("afterbegin", this_permalink_container)
            } else {
/*
                console.log("      no permalink, because no id", this_item)
*/
            }
        }
    }

  // first of these is for pre-overhaul html.  Delete when possible
    $(".pretext-content .autopermalink a").on("click", function(event){
        event.preventDefault();
    });
    $(".ptx-content .autopermalink a").on("click", function(event){
        event.preventDefault();
    });

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

window.addEventListener("load",function(event) {
       if(window.location.href.includes("/preview/")) {
           console.log("            found preview", window.location.href);
           $("main p[id], main article[id], main li[id], main section[id], main a[data-knowl]").each(function() {
               var thisid = $(this).attr('id');
               if( thisid && ( (thisid.length > 3 && !thisid.includes("-part") && !thisid.startsWith("fn-")) || thisid.startsWith("p-") ) ) {
                 $( this ).addClass("newstuff");
                 console.log("           found new", this)
               }
           })
       } else {
           console.log("not preview", window.location.href);
       }
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
                 if($(document.activeElement).hasClass("aside-like")) {
                    $(document.activeElement).toggleClass("front")
                 } else if ($(document.activeElement).hasClass("workspace")) {
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

/* .onepage  worksheets  adjust workspace to fit printed page length */

function scaleWorkspaceIn(obj, subobj, scale, tmporfinal) {
    console.log("initial height", obj.clientHeight);
    these_workspaces = subobj.querySelectorAll('.workspace');
    if (obj != subobj) {
        console.log("distinct subobj", obj, subobj);
        console.log("these_workspaces", these_workspaces);
        /* this is starting to look like a hack */
        if (subobj.classList.contains("workspace")) {  //we were given one workspace
            console.log("we were handed a workspace");
            these_workspaces = [subobj]
        }
        console.log("now these_workspaces", these_workspaces);
    }
    for (var j=0; j<these_workspaces.length; ++j) {
        this_work = these_workspaces[j];
        this_proportion = this_work.getAttribute("data-space");
        if (!this_proportion) { this_proportion = "1.00" }
        this_proportion_number = parseFloat(this_proportion.slice(0, -2));
        if (this_proportion.endsWith("in")) {
            this_proportion_number *= 10.0;
        } else if (this_proportion.endsWith("cm")) {
            this_proportion_number *= 3.94;  /* 10/2.54 */
        } else {
            console.log("No units on workspace size:  interpreting as mm", this_work)
            this_proportion_number = this_proportion * 40;
        }
        this_proportion_scaled = scale * this_proportion_number;
        this_work.setAttribute('style', 'height: ' + this_proportion_scaled + 'px');
        if (tmporfinal == "final" && scale < 11) {
            this_work.classList.add("squashed")
        } else {
            this_work.classList.remove("squashed")
        }
        if (tmporfinal == "final" && scale > 13) {
            console.log("showing extra space");
            var this_proportion_scaledX = 12*this_proportion_number;
            this_work.style.background = "linear-gradient( #eef 0px, #eef " + this_proportion_scaledX + "px, #eef " + this_proportion_scaledX + "px, #99f " + (this_proportion_scaledX + 5) + "px, #99f " + (this_proportion_scaledX + 5) + "px, #99f 100%)";
  //          this_work.style.background = "linear-gradient( #eef 0px, #eef 200px, #eef 200px, #99f 205px, #99f 205px, #99f 100%)";
        } else {
             this_work.style.background = null;
        }
        if (tmporfinal == "final") {
            var enclosingspace = this_work.parentElement.parentElement;
            console.log("enclosingspace was", enclosingspace)
            if (enclosingspace.tagName == "ARTICLE") {
                enclosingspace = enclosingspace.parentElement;
                console.log("enclosingspace is now", enclosingspace)
            }
            var enclosingspacebottom =  enclosingspace.getBoundingClientRect()["bottom"];
            /* there should be an easier way to do this */
            /* when the enclosing parent has padding, we want to ignore that */
            enclosingspacepadding = parseFloat(getComputedStyle(enclosingspace)["padding-bottom"].slice(0, -2));
            enclosingspacebottom = enclosingspacebottom - enclosingspacepadding;
            console.log(enclosingspace, "enclosingspace padding-bottom", getComputedStyle(enclosingspace)["padding-bottom"]);
            var lastsibling = enclosingspace.lastElementChild;
            var lastworkspacebottom = lastsibling.getBoundingClientRect()["bottom"];
            console.log("XX", this_work, "oo", enclosingspace, "pp", enclosingspacebottom, "xx", lastworkspacebottom, "diff", enclosingspacebottom - lastworkspacebottom);
            if (enclosingspacebottom - lastworkspacebottom < 5) {
                this_work.classList.add("tight")
            } else {
                this_work.classList.remove("tight")
            }
/*
            console.log(this_work.parentElement, "iparent rectangle", this_work.parentElement.getBoundingClientRect())
            console.log(this_work.parentElement.parentElement, "parent parent rectangle", this_work.parentElement.parentElement.getBoundingClientRect())
*/
        }
    }
    return obj.clientHeight
}

function adjustWorkspace() {

    console.log("adjusting workspace");
    $(".workspace").attr("contenteditable", "true");
    document.execCommand("defaultParagraphSeparator", false, "br");

    var all_pages = document.querySelectorAll('body .worksheet .onepage');
    var a = 14.0;
    var b = 10.0;
    var heightA, heightB, this_item;

    var pagelayout = "letter";
    if (document.body.classList.contains("a4")) { pagelayout = "a4" } 

    var pageheight = [];

    for (var i = 0; i < all_pages.length; i++) {
        /* for assigning page height later */
        if (pagelayout == "a4") { pageheight.push(1320) }
        else { pageheight.push(1243) }

        this_item = all_pages[i];
        if (i == 0) { this_item.classList.add("firstpage") }
            /* not else if: could be one-page worksheet */
        if (i == all_pages.length - 1) { this_item.classList.add("lastpage") }
        console.log(this_item.getBoundingClientRect(), "ccc", this_item);
        console.log(this_item.parentElement.getBoundingClientRect(), "ddd", this_item.parentElement);
    }
    for (var i = 0; i < all_pages.length; i++) {
       this_item = all_pages[i];

       /* not sure if this is the place to do it, but the first page might
          have items before it, and the last page mught have items after it */
       var worksheetData = this_item.parentElement.getBoundingClientRect();
       var pageData = this_item.getBoundingClientRect();
       console.log("worksheetData", worksheetData, "pageData", pageData);
       var pageExtraHeight = 0;
       if (this_item.classList.contains("firstpage")) {
           console.log("this_item",this_item.getBoundingClientRect(),this_item.getBoundingClientRect()["y"]);
           console.log("this_item parent",this_item.parentElement.getBoundingClientRect(),this_item.parentElement.getBoundingClientRect()["y"]);
           pageExtraHeight += pageData["top"] - worksheetData["top"];  /* 45 for padding */
       }
       if (this_item.classList.contains("lastpage")) {
           pageExtraHeight += worksheetData["bottom"] - pageData["bottom"];
       }
  //     pageExtraHeight += 150;
       pageheight[i] -= pageExtraHeight
       console.log("worksheetData", worksheetData, "pageData", pageData);
       console.log(i, "i", pageExtraHeight, "pageExtraHeight");

       heightA = scaleWorkspaceIn(this_item, this_item, a, "tmp");
       heightB = scaleWorkspaceIn(this_item, this_item, b, "tmp");
       console.log("heights", heightA, " xx ", heightB, "oo", this_item);
       console.log(i, "goal height", pageheight[i]);
       /* a magicscale makes the output the height of the minimum specified input */
       var magicscale = 12;

/*
       heightA += pageExtraHeight;
       heightB += pageExtraHeight;
*/

       if (heightA != heightB) {
/*
         magicscale = (1328 - 2*height10 + 1*height20)/(height20 - height10)
         magicscale = (1324 - 2*height10 + 1*height20)/(height20 - height10)
*/
         magicscale = (pageheight[i]*(a - b) + b*heightA - a*heightB)/(heightA - heightB);
/*
         if (pagelayout == "a4") {
             magicscale = (1413*(a - b) + b*heightA - a*heightB)/(heightA - heightB)
         } else if (pagelayout == "letter") {
             magicscale = (1324*(a - b) + b*heightA - a*heightB)/(heightA - heightB)
         } else {
             console.log("Error: unknown pagelayout", pagelayout)
         }
*/
         
       }
       console.log("magicscale", magicscale, "of", this_item);
       scaleWorkspaceIn(this_item, this_item, magicscale, "final");
       all_pages[i].setAttribute("style", 'height: ' + pageheight[i].toString() + 'px');

       var this_height = this_item.clientHeight;
       console.log(this_height, "ttt", this_item);
       console.log(this_item.getBoundingClientRect(), "222ccc", this_item);
       console.log(this_item.parentElement.getBoundingClientRect(), "222ddd", this_item.parentElement);


//   alert("part of one page");
       /* now go back and see if any of the squashed non-tight items can be expanded */
       var these_squashed = this_item.querySelectorAll('.squashed:not(.tight)');
       console.log("these_squashed", these_squashed);
       console.log('are squashed by', magicscale);
       for (var j=0; j < these_squashed.length; ++j) {
           var this_q = these_squashed[j];
           heightA = scaleWorkspaceIn(this_item, this_q, 12, "tmp");
           console.log("heightA", heightA);
           if (heightA <= this_height) {
               scaleWorkspaceIn(this_item, this_q, 12, "final");
           } else {
               scaleWorkspaceIn(this_item, this_q, magicscale, "final");
           }
       }
    }
    console.log("finished adjusting workspace");
}

function urlattribute() {
        var this_urlstub = window.location.hostname;
        document.body.setAttribute("data-urlstub", this_urlstub);
}

window.addEventListener("load",function(event) {

  if (document.body.classList.contains("worksheet")) {
      console.log("begin adjusting workspace");

      var born_hidden_knowls = document.querySelectorAll('article > a[data-knowl]');
      console.log("born_hidden_knowls", born_hidden_knowls);
      for (var j=0; j < born_hidden_knowls.length; ++j) {
          born_hidden_knowls[j].click()
      }
  /* not the right way:  need to figure out what this needs to wait for */
      window.setTimeout(adjustWorkspace, 1000);

      window.setTimeout(urlattribute, 1500);
  }
//  console.log("done adjusting workspace");

});

/*
window.setInterval(function(){
    console.log('$(":focus")', $(":focus"));
}, 5000);
*/

