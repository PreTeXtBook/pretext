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
//    p_no_id.forEach(function(e){
    for (var n=p_no_id.length - 1; n >= 0; --n) {
        e = p_no_id[n];
        if (e.hasAttribute('id')) {
            console.log(e, "was id'd in a previous round");
            continue
        }
console.log("this is e", e);
        if (e.classList.contains('watermark')) {
            console.log(e, "skipping the watermark");
            continue
        }
        console.log("\n                    XXXXXXXXX  p with no id", e);
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

    console.log("adding permalinks");
    /* add permalinks to all sections and articles */
    items_needing_permalinks = document.querySelectorAll('body section, body section > p, body section article, body section figure');
 //   items_needing_permalinks = document.querySelectorAll('body section article');
    this_url = window.location.href.split('#')[0];
    permalink_word = "permalink";
    for (var i = 0; i < items_needing_permalinks.length; i++) {
        this_item = items_needing_permalinks[i];
        if(this_item.id) {
            this_permalink_url = this_url + "#" + this_item.id;
            console.log("        needs permalink", this_permalink_url, "  xx ", this_item);
  //          this_permalink_container = document.createElement('div');
  //          this_permalink_container.setAttribute('style', "position: relative; width: 0; height: 0");
  //          this_permalink_container.innerHTML = '<span class="autopermalink">' + permalink_word + '</span>';
           this_permalink_container = document.createElement('span');
           this_permalink_container.setAttribute('class', 'autopermalink');
           this_permalink_container.innerHTML = '<a href="' + this_permalink_url + '">' + permalink_word + '</a>';

           this_item.insertAdjacentElement("afterbegin", this_permalink_container);
        } else {
            console.log("      no permalink, because no id", this_item) 
        }
    }
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
                 if($(document.activeElement).hasClass("aside-like")) {
                    $(document.activeElement).toggleClass("front")
                 }
            case 27: //esc
     //           var parent_sage_cell = $(this).closest(".sagecell_editor");
     //           console.log("parent_sage_cell", parent_sage_cell);
     //           if ($(parent_sage_cell).hasClass('sagecell_editor')) {
     //              console.log("I am trapped in a sage cell", $(document.activeElement).closest(".sagecell_editor"));
     //              console.log($(document.activeElement));
     //              var this_sage_cell = $(document.activeElement).closest(".sagecell_editor");
     //              this_sage_cell.next().focus;
     //           }
     //           else 
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

/*
window.setInterval(function(){
    console.log('$(":focus")', $(":focus"));
}, 5000);
*/
/*
window.onload = function()
{
    document.onkeyup = function(event)
    {                   
        var e = (!event) ? window.event : event;
        switch(e.keyCode)
        {                       
            case 80:  //p 
                window.location.href = document.getElementById('previousbutton').href;
                break;                  
            case 78: //n        
                window.location.href = document.getElementById('nextbutton').href;
                break;                  
            case 85: //u        
                window.location.href = document.getElementById('upbutton').href;
            break;                      
        }                   
};              
};      
*/

