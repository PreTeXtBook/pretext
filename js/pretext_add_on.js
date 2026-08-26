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

// stub for i18next to future-proof the code. We don't actually use it for
// anything right now, but it will be needed if we want to localize the
// accessibility search status messages.
window.i18next = window.i18next || {
    t(key, params = {}) {
        for (const param in params) {
            key = key.replace(`{{${param}}}`, params[param]);
        }
        return key;
    }
};

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

function process_workspace() {
    console.log("processing workspace");
    MathJax.typesetPromise();
}

window.addEventListener("load",function(event) {
    const calcDialogElement = document.getElementById('ptx-calculator-container');
    const calcButtonElement = document.getElementById('ptx-calculator-toggle');
    if (!calcDialogElement || !calcButtonElement) {
        return;
    }
    const calcDialog = new PTXDialog(calcDialogElement, calcButtonElement, {"kind": "non-modal"});

    const focusCalcInput = function() {
        const inputField = document.querySelector("#ptx-geogebra-calculator input.gwt-SuggestBox.TextField");
        if (inputField) {
            inputField.focus();
        }
    }
    function initGeogebra() {
        // Some paramaters are fixed here, others are set by publisher options in the HTML source
        // and stored in ggbParams. Merge those here.
        const fixedParams = {
            showToolBar: true,
            showAlgebraInput: true,
            perspective: "G/A",
            algebraInputPosition: "bottom",
            appletOnLoad: focusCalcInput,
            scaleContainerClass: "ptx-calculator-container",
            allowUpscale: false,
            autoHeight: false,
        }
        const generatedParams = (typeof ggbParams === "object" && ggbParams) ? ggbParams : {};
        const params = {...generatedParams, ...fixedParams};
        let applet = new GGBApplet(params, true);
        applet.inject('ptx-geogebra-calculator');
        return applet;
    }

    let applet;
    calcButtonElement.addEventListener('click', function() {
        if (calcDialog.dialog.open) {
            let initialized = calcDialogElement.dataset.initialized || false;
            if (!initialized) {
                applet = initGeogebra();
                calcDialogElement.dataset.initialized = true;
            } else {
                focusCalcInput();
            }
        }
    });

    //add resize observer for dialog
    const resizeObserver = new ResizeObserver(entries => {
        for (let entry of entries) {
            if (entry.target === calcDialogElement && applet && applet.getAppletObject()) {
                const width = entry.contentRect.width;
                const height = entry.contentRect.height;
                const topBarHeight = calcDialogElement.querySelector('.ptx-dialog-topbar').clientHeight || 0;
                applet.getAppletObject().setSize(width, height - topBarHeight);
                applet.getAppletObject().recalculateEnvironments();
            }
        }
    });
    resizeObserver.observe(calcDialogElement);
});


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

// START Support for code-copy button functionality
document.addEventListener("click", (ev) => {
    const codeBox = ev.target.closest(".clipboardable");
    if (!navigator.clipboard || !codeBox) return;
    const button = ev.target.closest(".code-copy");
    // Copy a clone with "unselectable" content removed (e.g. a console prompt),
    // so the copied text matches what a manual selection would capture.
    const pre = codeBox.querySelector("pre").cloneNode(true);
    pre.querySelectorAll(".unselectable").forEach((el) => el.remove());
    const preContent = pre.textContent;
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


window.addEventListener("DOMContentLoaded", () => {
    const userDropdownButton = document.getElementById("ptx-user-dropdown-button");
    const userDropdownContent = document.getElementById("ptx-user-dropdown-content");
    if (userDropdownButton && userDropdownContent) {
        new PTXDropdown(userDropdownContent, userDropdownButton);
    }
});
