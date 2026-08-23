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


    /* click an image to magnify */
    $('body').on('click','.image-box > img:not(.draw_on_me):not(.mag_popup), .sbspanel > img:not(.draw_on_me):not(.mag_popup), figure > img:not(.draw_on_me):not(.mag_popup), figure > div > img:not(.draw_on_me):not(.mag_popup)', function(){
        var img_big = document.createElement('div');
        const content_element = document.getElementById('ptx-content');
        img_big.setAttribute('class', 'mag_popup_container');
        img_big.innerHTML = `<img src="${$(this).attr("src")}" style="width:100%;" class="mag_popup"/>`;
 // place_to_put_big_img = $(this).parents(".sbsrow, figure, li").last();
        place_to_put_big_img = $(this).parents(".image-box, .sbsrow, figure, li, .cols2 article:nth-of-type(2n)").last();
  // for .cols2, the even ones have to go inside the previous odd one
        if (place_to_put_big_img.prop("tagName") == "ARTICLE") {
           place_to_put_big_img = place_to_put_big_img.prev().children().first();
        }

        // find ancestor so that place_to_put_big_img's position is relative to that ancestor
        var img_big_parent = place_to_put_big_img[0].parentElement;
        while (img_big_parent.id !== "ptx-content") {
           const computed_position = getComputedStyle(img_big_parent).position;
           if (computed_position !== "static") {
              break;
           }
           img_big_parent = img_big_parent.parentElement;
        }

        const content_element_computed_style = getComputedStyle(content_element);
        const content_padding_left  = parseFloat(content_element_computed_style.paddingLeft );
        const content_padding_right = parseFloat(content_element_computed_style.paddingRight);
        const img_big_offset = content_element.getBoundingClientRect().left - img_big_parent.getBoundingClientRect().left + content_padding_left;
        const doc_width = content_element.offsetWidth - content_padding_left - content_padding_right;
        img_big.setAttribute('style', `width:${doc_width.toString()}px; left:${img_big_offset.toString()}px;`);

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


// The new method for creating pages and adjusting workspace //

// The element being previewed.  Usually a worksheet or handout section, but a
// project-like block with workspace that lives outside any worksheet/handout
// is previewed as a printout in its own right, in which case this is the
// project's <article>.  loadPrintout() tags whichever it is with "printout",
// which is also the hook the print stylesheet keys on, so nothing downstream
// has to care which kind of element it got.
function getPrintout() {
    return document.querySelector('.printout');
}

// Unwrap section.paragraphs containers so their children flow directly
// into the parent, enabling CSS page breaks between the inner elements.
function flattenParagraphsSections(printout) {
    const paragraphsSections = printout.querySelectorAll('section.paragraphs');
    paragraphsSections.forEach(section => {
        const parent = section.parentNode;
        // Move all children out of the section wrapper and into the parent
        while (section.firstChild) {
            parent.insertBefore(section.firstChild, section);
        }
        // Remove the now-empty section wrapper
        parent.removeChild(section);
    });
}

// Wait for all images inside a container to finish loading.
// Returns a promise that resolves when every <img> has loaded (or on timeout).
function waitForImages(container, timeoutMs = 5000) {
    const images = container.querySelectorAll('img');
    const promises = [];
    for (const img of images) {
        if (!img.complete) {
            promises.push(new Promise(resolve => {
                img.addEventListener('load', resolve, { once: true });
                img.addEventListener('error', resolve, { once: true });
            }));
        }
    }
    if (promises.length === 0) return Promise.resolve();
    // Race all image loads against a timeout so broken images don't block forever
    return Promise.race([
        Promise.all(promises),
        new Promise(resolve => setTimeout(resolve, timeoutMs))
    ]);
}

// Moving a row between .onepage containers makes any <iframe> inside it
// (e.g. a YouTube video or GeoGebra applet) reload, even when it lands back
// in the same parent.  A single settle loop (repagination/spillover-collapse
// running repeatedly until layout stabilizes) can move a row several times,
// so detach every iframe -- swapped for a same-sized placeholder, to keep
// height measurements accurate -- before a batch of repagination work and
// reattach afterward, capping each toggle at reloading a video once instead
// of once per move.
async function withIframesDetached(fn) {
    const printout = getPrintout();
    const parked = [];
    if (printout) {
        printout.querySelectorAll('iframe').forEach(iframe => {
            const rect = iframe.getBoundingClientRect();
            const placeholder = document.createElement('div');
            placeholder.className = 'iframe-placeholder';
            placeholder.style.width = rect.width + 'px';
            placeholder.style.height = rect.height + 'px';
            placeholder.style.display = getComputedStyle(iframe).display;
            iframe.parentNode.insertBefore(placeholder, iframe);
            iframe.remove();
            parked.push({iframe, placeholder});
        });
    }
    try {
        return await fn();
    } finally {
        parked.forEach(({iframe, placeholder}) => {
            placeholder.parentNode.insertBefore(iframe, placeholder);
            placeholder.remove();
        });
    }
}

// The workspace divs in, or at, an element.  In a worksheet a workspace is
// always nested inside an exercise or task, but a project-like standalone
// printout can carry @workspace on itself, and then the block *is* the
// workspace div -- which querySelectorAll, looking only at descendants, misses.
// Whether a top-level row *is* blank writing space, in either of the two
// shapes it can take.  The "highlight workspace" overlay wraps every
// `.workspace` in a `.workspace-container` (see toggleWorkspaceHighlight()),
// and since flattenSolutionsIn() has by then made the workspace a row in its
// own right, that wrapper becomes the row.  The wrapper carries neither the
// `workspace` class nor the group stamp, so testing for `.workspace` alone
// means every workspace rule below -- never opening a page with writing
// space, keeping a question with its own workspace, suppressing a stranded
// one -- silently stops applying the moment the reader ticks that checkbox.
function isWorkspaceRow(elem) {
    return elem.classList.contains('workspace') || elem.classList.contains('workspace-container');
}

// A workspace row that is *actually* blank writing space on the page.  Both
// pagination paths refuse to open a page with writing space -- findPageBreaks()
// when it plans from scratch, addSpilloverPages() when it splits at runtime --
// because a slab of empty space above the question it belongs to reads as a
// mistake.  A row suppressed by hideWidowedWorkspaces() carries `hidden` and
// occupies nothing, so there is no slab to protect the reader from, and
// applying the rule to it only retreats to an earlier break and pushes real
// content onto a later page to make room for something invisible.
function isVisibleWorkspaceRow(elem) {
    return isWorkspaceRow(elem) && !elem.classList.contains('hidden');
}

function workspaceDivsIn(elem) {
    if (elem.classList.contains('workspace')) {
        return [elem];
    }
    return [...elem.querySelectorAll('.workspace')];
}

// Split .task (and .conclusion) elements out of an .exercise -- or out of an
// enclosing .task, for sub-tasks -- so each becomes its own top-level child
// of `container`, positioned immediately after the block that used to hold
// it. This is what lets both pagination paths treat a single task as an
// independently placeable/movable unit: for computed pagination it lets
// findPageBreaks() weigh each task on its own, and for authored pagination
// it lets addSpilloverPages() push just the oversized task (and whatever
// follows it on that page) onto a spillover page, instead of being stuck
// with the whole exercise as one atomic block that can't be split when a
// solution inside it grows too long.
function flattenTasksIn(container) {
    for (const child of [...container.children]) {
        if (child.classList.contains('sidebyside')) {
            continue; // sidebyside could have tasks, but we don't split into it
        }
        // A sidebyside nested deeper than `child` itself (e.g. a diagram next
        // to a task's text) is excluded the same way: its tasks stay put.
        const tasks = [...child.querySelectorAll('.task, .conclusion')].filter(el => !el.closest('.sidebyside'));
        if (tasks.length === 0) continue;
        // Tag nesting depth so CSS can indent appropriately once an element
        // is pulled out of its parent .task/.exercise: if its parent (or
        // grandparent) is itself a .task, it was a sub-(sub-)task.
        for (const task of tasks) {
            const parent = task.parentElement;
            const grandparent = parent.parentElement;
            if (grandparent && grandparent.classList.contains('task')) {
                task.classList.add('subsubtask');
            } else if (parent.classList.contains('task')) {
                task.classList.add('subtask');
            }
        }
        // Move every task out, including the first one, in reverse order, so
        // they land in their original order immediately after `child`.
        for (let i = tasks.length - 1; i >= 0; i--) {
            container.insertBefore(tasks[i], child.nextSibling);
        }
    }
}

// Split a long `.introduction` block up so its paragraphs/tables/etc. become
// independent top-level children of `container`, the same way flattenTasksIn
// splits out `.task`/`.conclusion`. Otherwise an introduction is one atomic
// row for pagination purposes, and overflows the page whenever it alone is
// taller than a page, regardless of how the task(s) after it are split.
//
// The print stylesheet displays a heading inline with its first paragraph
// (`article>.heading:first-child+:is(.para,.para.logical,.introduction)`),
// so the introduction's first child is left in place -- replacing the
// .introduction wrapper right where it was -- rather than extracted, and
// only the rest is moved out to become independent top-level rows.
//
// Must run after flattenTasksIn(), since the reverse insertion here also
// targets `child.nextSibling`, and running after keeps reading order correct
// (introduction paragraphs end up before the task, not after it).
//
// A `.introduction` can appear nested inside a top-level child (e.g. an
// exercise's own introduction) or as a top-level child itself (e.g. a
// project-like printout's own opening section). Both are handled: for the
// nested case the wrapper is unwrapped in place and its later children
// extracted to be `child`'s top-level siblings; for the top-level case the
// wrapper *is* `child`, so the first paragraph becomes the new top-level row
// in its place, and later children are extracted as its siblings instead.
function flattenIntroductionsIn(container) {
    for (const child of [...container.children]) {
        if (child.classList.contains('sidebyside')) {
            continue; // sidebyside could have introductions, but we don't split into it
        }
        const isTopLevelIntroduction = child.classList.contains('introduction');
        // A sidebyside nested deeper than `child` itself (e.g. a project
        // description next to a figure) is excluded the same way as above:
        // its introduction stays put.
        const introductions = isTopLevelIntroduction
            ? [child]
            : [...child.querySelectorAll('.introduction')].filter(intro => !intro.closest('.sidebyside'));
        // Where the next introduction's extracted content gets inserted.
        // Starts at `child` and advances to the last row placed by each
        // introduction in turn, so that when `child` contains more than one
        // (e.g. an exercisegroup whose member exercises each carry their own),
        // a later introduction's paragraphs land after an earlier one's
        // instead of before it -- inserting every one of them relative to the
        // same fixed `child` would put the last-processed introduction first.
        let insertionAnchor = child;
        introductions.forEach(intro => {
            const introParent = intro.parentNode;
            const introChildren = [...intro.children];
            if (introChildren.length === 0) {
                intro.remove();
                return;
            }
            // Leave the first paragraph in place, right where .introduction was,
            // so it stays adjacent to whatever precedes it (typically the heading).
            introParent.insertBefore(introChildren[0], intro);
            // When `intro` was itself the top-level child, `child` no longer
            // occupies a slot in `container` -- the first paragraph just placed
            // above does instead -- so anchor off that rather than insertionAnchor.
            const anchor = intro === child ? introChildren[0] : insertionAnchor;
            for (let i = introChildren.length - 1; i >= 1; i--) {
                container.insertBefore(introChildren[i], anchor.nextSibling);
            }
            intro.remove();
            insertionAnchor = introChildren[introChildren.length - 1];
        });
    }
}

// The classes flattenTasksIn() and flattenSolutionsIn() stamp on a row before
// hoisting it, so the print stylesheet can re-create the indentation the hoist
// destroys.  Ordered shallowest first.
const DEPTH_CLASSES = ['subtask', 'subsubtask', 'subsubsubtask'];

// The depth class a row hoisted out of `owner` needs to keep lining up with
// it.  Read off `owner`'s own classes rather than its ancestry: flattenTasksIn()
// has already run, so the nesting that would have said how deep `owner` sat is
// gone, and the class it stamped on the way out is the only record left.
//
// The names mean the same thing here as they do there -- "subtask" is "I came
// out of a task" -- so a row out of a plain task takes `subtask`, one out of a
// task that was itself a subtask takes `subsubtask`, and so on.  A row belongs
// at its owner's own level, not one step further in, exactly as a `.conclusion`
// does; the print stylesheet is what turns that into the matching margin.
function depthClassForRowOut(owner) {
    if (owner.classList.contains('subsubtask')) return 'subsubsubtask';
    if (owner.classList.contains('subtask')) return 'subsubtask';
    if (owner.classList.contains('task')) return 'subtask';
    return null;
}

// Move whichever depth class `from` carries onto `to`.  Used when the
// "highlight workspace" overlay wraps a workspace, since the wrapper then
// stands in as the row: the indent has to move with that role.  A margin left
// on the workspace itself would not do -- it is `width: 100%` of the wrapper,
// so a margin widens it past the wrapper's right edge instead of shifting it
// over, and with both elements carrying the class the indent would double.
function moveDepthClass(from, to) {
    for (const cls of DEPTH_CLASSES) {
        if (from.classList.contains(cls)) {
            from.classList.remove(cls);
            to.classList.add(cls);
        }
    }
}

// Serial number behind the `data-block-group` stamps below.  Module-level and
// monotonic, deliberately: an id has to be unique among every row that could
// ever share a page, and a counter local to the call does not achieve that.
// adjustPrintoutPages() runs flattenSolutionsIn() once per authored page, so a
// call-local counter hands every page its own `bg-0` -- and hideWidowedWorkspaces(),
// which decides whether a workspace still has its question by looking that id
// up among the page's rows, would accept a completely unrelated group's
// question as the answer if two such pages were ever merged onto one.  Nothing
// merges them today (a full recompute only runs when there are no authored
// pages, and collapseSpilloverPages() folds a spillover page back only into
// the page it was split from), but nothing declares that they cannot be.
//
// Surviving a repagination costs nothing, because the ids are meant to persist
// anyway: a second createPrintoutPages() finds the `.solutions` wrappers
// already consumed by the first pass, reissues nothing, and the stamps left
// behind by that first pass are what keep the groups intact.  It is the
// stamping *not* being redone that makes the scheme work.
let blockGroupSeq = 0;

// Split a `.solutions` block up so each hint/answer/solution knowl becomes
// an independent top-level row, the same way flattenTasksIn splits out
// `.task` and flattenIntroductionsIn splits out `.introduction`. Otherwise
// a task or exercise with a large solution is one atomic row that overflows
// the page whenever its prompt plus its solution content together are
// taller than a page, even if the prompt alone would fit comfortably.
//
// Unlike `.introduction`, `.solutions` has no adjacent-heading display rule
// to preserve, so every child is extracted -- none needs to stay behind.
//
// Must run after flattenTasksIn() so that, when the `.solutions` belongs to
// a task rather than directly to an exercise, `child` is already that task
// (a top-level row in its own right) -- keeping the extracted solution
// content ordered right after its own task instead of after a sibling task.
//
// The block's `.workspace` is hoisted out along with the solutions, and
// lands after them.  The XSL emits an exercise as statement, then
// `div.solutions`, then `div.workspace` (the workspace is applied after
// "wrapped-content" and so is the block's last real child).  Extracting only
// the solutions would leave the workspace behind *inside* the block, which
// renders it before the rows just hoisted out -- so a revealed hint or
// solution would appear below a slab of blank writing space instead of
// directly under its question.  Moving the workspace out too, after the
// solution rows, restores the authored reading order and makes the blank
// space an independently placeable row like every other.
//
// Rows split out of one block are stamped with a shared `data-block-group`
// so pagination can try to keep a question with its solutions and workspace
// (see findPageBreaks(), which will not start a page with a workspace row,
// and hideWidowedWorkspaces(), which suppresses writing space stranded away
// from its question).
function flattenSolutionsIn(container) {
    for (const child of [...container.children]) {
        if (child.classList.contains('sidebyside') || child.classList.contains('solutions')) {
            continue;
        }
        // Nested sidebyside excluded, same reasoning as flattenTasksIn/
        // flattenIntroductionsIn.
        const solutionsBlocks = [...child.querySelectorAll('.solutions')].filter(solutions => !solutions.closest('.sidebyside'));
        // Advances after each block, same reasoning as flattenIntroductionsIn:
        // when `child` has more than one solutions block (e.g. an
        // exercisegroup whose member exercises each have their own), a later
        // block's content must land after an earlier block's, not before it.
        let insertionAnchor = child;
        solutionsBlocks.forEach(solutions => {
            // Captured before the block is removed below.  This is the
            // exercise or task the solutions belong to -- after
            // flattenTasksIn() that is usually `child` itself, but for an
            // exercisegroup `child` holds several such owners, each with
            // its own solutions and its own workspace to keep together.
            const owner = solutions.parentElement;
            // Captured for the same reason, and before the rows move for the
            // same reason: once they are top-level children of `container`
            // nothing about them says they came out of a task.  See
            // depthClassForRowOut().
            const depthClass = depthClassForRowOut(owner);
            const group = `bg-${blockGroupSeq++}`;
            const solChildren = [...solutions.children];
            for (let i = solChildren.length - 1; i >= 0; i--) {
                container.insertBefore(solChildren[i], insertionAnchor.nextSibling);
                if (depthClass) {
                    solChildren[i].classList.add(depthClass);
                }
            }
            solutions.remove();
            if (solChildren.length > 0) {
                insertionAnchor = solChildren[solChildren.length - 1];
            }
            // Follow the solutions out, so reading order stays
            // statement -> hint/answer/solution -> blank writing space.
            const workspace = owner.querySelector(':scope > .workspace');
            if (workspace) {
                container.insertBefore(workspace, insertionAnchor.nextSibling);
                // Indented along with them: a task's writing space is only
                // hoisted when that task has solutions, so leaving it flush
                // left would set it apart from the workspace of every sibling
                // task that has none and so stayed put, indented, inside.
                if (depthClass) {
                    workspace.classList.add(depthClass);
                }
                insertionAnchor = workspace;
            }
            // Tag the whole set, including the question row that stayed put,
            // so the group can be kept together (or deliberately broken)
            // later.  When `owner` is nested deeper than `child` (the
            // exercisegroup case) the question row is the whole group and
            // is shared by several owners, so it is left untagged rather
            // than bound to whichever owner happened to be processed last.
            const questionRow = owner === child ? child : null;
            const anchors = [questionRow, ...solChildren].filter(el => el && el.parentElement === container);
            // A group needs at least one row that is not the workspace for it
            // to be anchored to; otherwise (an empty `.solutions` inside an
            // exercisegroup, say) hideWidowedWorkspaces() would find no
            // question on the page and suppress perfectly good writing space.
            if (anchors.length === 0) return;
            for (const el of [...anchors, workspace]) {
                if (el && el.parentElement === container) {
                    el.dataset.blockGroup = group;
                }
            }
        });
    }
}

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
    console.log("*** Adjusting printout pages.");
    const printout = getPrintout();
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
    // Split nested tasks out to be top-level children of their page (see
    // flattenTasksIn), so overflowing solutions inside a single task can be
    // spilled onto a new page instead of dragging the whole exercise along
    // as one unsplittable block. Then do the same for introductions (see
    // flattenIntroductionsIn); must run second so reading order stays correct.
    pages.forEach(page => {
        flattenTasksIn(page);
        flattenIntroductionsIn(page);
        flattenSolutionsIn(page);
    });
    console.log("Moved all content before the first page and after the last page into the respective pages, and split nested tasks, introductions, and solutions for independent repagination.");
}

// This is the main function we will call then a printout does not come from the XSL with pages already defined (for now, the XSL will keep the <page> behavior as an option).
function createPrintoutPages(margins) {
    console.log("*** Creating printout pages with margins:", margins);

    // Assumptions: needs to work for both letter (8.5in x 11in) and a4 (210mm x 297mm) paper sizes.  We will work in pixels (96/in): those are 816px x 1056px and 794px x 1122.5px respectively (1 inch = 96 px, 1 cm = 37.8 px).  We assume that the printing interface of the browser will do the right thing with these.

    // For purposes of finding page breaks, we will use 794 as our width and 1056 as our height (so A4 width and letter height).  Then we will rescale workspace on each page to fit the actual paper size selected.

    const conservativeContentHeight = 1056 - (margins.top + margins.bottom); // in pixels
    const conservativeContentWidth = 794 - (margins.left + margins.right); // in pixels

    const printout = getPrintout();
    if (!printout) {
        console.warn("No printout found, exiting createPrintoutPages.");
        return;
    }
    // Narrow the printout to our conservative width while we measure row
    // heights below, so text wraps at least as much as it will once placed
    // in the real, narrower, padded .onepage box -- otherwise rows measure
    // shorter than their actual rendered height and pagination overflows.
    printout.style.width = conservativeContentWidth + 'px';
    // Set the height of each workspace based on its data-space attribute
    setInitialWorkspaceHeights(printout);

    // We want to consider each "block" of the printout.  Some of these will be direct children of the printout, some will be nested inside these children (e.g. tasks inside an exercise).  Split those out into their own top-level blocks first (see flattenTasksIn), then every block we care about is simply a direct child of the printout.
    // Skipping separate treatment of exercisegroups for now.
    flattenTasksIn(printout);
    // Same treatment for introductions (see flattenIntroductionsIn) and for
    // task solutions (see flattenSolutionsIn); both must run after
    // flattenTasksIn so reading order comes out right.
    flattenIntroductionsIn(printout);
    flattenSolutionsIn(printout);
    let rows = [...printout.children];
    // Measure the rows in the context they will actually be rendered in.
    //
    // The print stylesheet scopes a good deal to `.onepage` -- most sharply
    // `.onepage .instructions { display: none }`, which suppresses tool chrome
    // such as diagcess's "Diagram Exploration Keyboard Controls" panel. Taking
    // heights while the rows are still children of the printout means none of
    // those rules are in force, so such a row measures as real content, is
    // given space in the page-break plan, and then renders as nothing once it
    // lands in a `.onepage` -- which is how a worksheet ends up with a
    // completely blank sheet in the middle of it.
    //
    // So park the rows in a throwaway `.onepage` for the duration of the
    // measuring loop. Its width is pinned to the conservative content width
    // for the same reason the printout's was: so text wraps at least as much
    // as it will in the real, narrower page box.
    const measuringPage = document.createElement('section');
    measuringPage.classList.add('onepage');
    measuringPage.style.width = conservativeContentWidth + 'px';
    // The real page box is a fixed height; this one has to grow with whatever
    // it holds, or every row past the first page's worth would measure clipped.
    measuringPage.style.height = 'auto';
    printout.appendChild(measuringPage);
    rows.forEach(row => measuringPage.appendChild(row));
    // Loop through the blocks and create a list of objects including the block, its height, and its workspace height.  Only include blocks that have height (this will remove autopermalinks, as desired).
    let blockList = [];
    for (const row of rows) {
        let blockHeight = getElementTotalHeight(row);
        // A currently-hidden hint/answer/solution row also measures zero
        // height, but unlike an autopermalink it's meaningful content that
        // may be revealed later -- it still needs a page to call home. Rows
        // never added to blockList never get moved into a .onepage below,
        // and then get deleted outright by the "remove old content not in a
        // page" cleanup at the end of this function, which is correct for a
        // genuinely-empty row but was silently destroying hidden solution
        // content (and, since printout.children is a live collection there,
        // corrupting the position of whatever survived that by accident).
        // Keeping it in blockList with height 0 costs nothing towards
        // findPageBreaks()'s page-height budget -- it just rides along onto
        // whichever page its neighbors land on, ready to be revealed in place.
        // Tested against the row's own rendered box rather than blockHeight,
        // which adds the margins on: an autopermalink has no box at all
        // (offsetHeight 0) but does carry vertical margin, so measured the
        // margin-inclusive way it looks like a ~22px row and survives this
        // filter -- defeating the "remove autopermalinks" intent above. It
        // then goes on to claim a page of its own whenever its neighbour is a
        // block too tall to share with (findPageBreaks() gives such a block a
        // page to itself), and the reader gets a completely blank sheet.
        if (row.offsetHeight === 0 && !row.classList.contains('hidden')) {
            console.log("Skipping row with zero height:", row);
            continue;
        }
        let totalWorkspaceHeight = 0;
        if (workspaceDivsIn(row).length > 0) {
            // Workspace height is not just sum of workspace heights; we need to be careful with sidebyside and columns
            totalWorkspaceHeight = getElemWorkspaceHeight(row);
        }
        blockList.push({
            elem: row,
            height: blockHeight,
            workspaceHeight: totalWorkspaceHeight,
            // Set by flattenSolutionsIn() on the rows split out of a single
            // exercise or task, so findPageBreaks() can tell which rows want
            // to stay together on one page.  Undefined for rows that were
            // never split out of anything.
            group: row.dataset.blockGroup,
            // A row that *is* a hoisted workspace, as opposed to one that
            // merely contains a workspace nested inside it.  Such a row is
            // pure blank writing space, so it must never be what a page
            // opens with -- see findPageBreaks().  Suppressed writing space
            // does not count; see isVisibleWorkspaceRow().
            isWorkspace: isVisibleWorkspaceRow(row),
        });
    }

    // Done measuring: return the rows to the printout and drop the scaffold,
    // so the page-building loop below distributes them as it always has.
    rows.forEach(row => printout.appendChild(row));
    measuringPage.remove();

    // Now find pageBreaks so that extra workspace is as uniform as possible.
    // Squeezing blank writing space below its authored height is only on the
    // table once something is revealed that needs the room (see pageCost()).
    const pageBreaks = findPageBreaks(blockList, conservativeContentHeight, {
        allowSqueeze: anySolutionShown(),
    });

    // Done measuring; let the printout go back to its normal width so the
    // .onepage sections built below render at their real page size.
    printout.style.width = "";

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
    // Snapshot the children first: `printout.children` is a live collection,
    // so removing through its own iterator shifts every later element down one
    // and skips the next candidate.  A row that survives this loop by accident
    // is left outside every page -- and now that rows carry group stamps that
    // pagination relies on, one going missing takes its group's cohesion with
    // it.
    for (const child of [...printout.children]) {
        if (!child.classList.contains('onepage')) {
            console.log("Removing old child not in a page:", child);
            printout.removeChild(child);
        }
    }
}

function getPageContentBottom(page) {
    // The page element's own bottom edge includes its bottom padding, which
    // corresponds to the print margin. Content that lands in that padding
    // area still fits within the page's outer box, but real printing
    // respects the margin strictly and will push it to the next page.
    // So overflow must be measured against the content area, not the raw box.
    const pRect = page.getBoundingClientRect();
    const paddingBottom = parseFloat(getComputedStyle(page).paddingBottom) || 0;
    return pRect.bottom - paddingBottom;
}

function pageOverflows() {
    const pages = document.querySelectorAll('.onepage');
    for (const page of pages) {
        for (const child of page.children) {
            const r = child.getBoundingClientRect();
            if (r.bottom > getPageContentBottom(page) + 1) {
                return true;
            }
        }
    }
    return false;
}

// Blank writing space only means something directly beneath the question it
// was authored for.  findPageBreaks() will not plan a page that opens with a
// workspace row, but a group can still be pulled apart afterwards -- most
// often by addSpilloverPages(), which pushes whatever overflows onto a fresh
// page at runtime.  When that leaves a workspace on a page without the
// question it belongs to, a slab of blank space with no prompt above it is
// worse than no writing space at all, so it is suppressed.
//
// Hidden rather than removed, and recomputed from scratch on every call, so
// that a later toggle which brings the group back onto one page brings the
// writing space back with it.  Suppressing a workspace only ever frees
// vertical space, so this can never introduce a new overflow.
// Only applies while something is revealed, for the same reason pageCost()
// will not squeeze: with nothing shown, the authored writing space is what the
// reader is meant to get, and suppressing it would quietly take that away.
//
// Suppression is the `hidden` class, not an inline `display`, and every pass
// clears it from every workspace and wrapper in the printout before deciding
// again.  Clearing everything first is what makes "recomputed from scratch"
// above actually true: a workspace is the row only until the reader ticks
// "highlight workspace", after which toggleWorkspaceHighlight() wraps it and
// the `.workspace-container` is the row instead (see isWorkspaceRow()).
// Writing only to whichever element holds that role at the time leaves the
// suppression stranded on the other one -- hide a workspace while unwrapped,
// tick the box, and un-hiding restores the container while the `.workspace`
// inside it stays suppressed for the rest of the session.
//
// The class rather than an inline style because createPrintoutPages() skips
// zero-height rows and then deletes whatever never landed in a `.onepage`,
// exempting only `.hidden`.  A workspace suppressed with `display:none`
// measures zero, carries no such exemption, and would be destroyed outright
// by the next full recompute instead of restored by it.  Nothing reaches that
// today -- every recompute is chained ahead of the first reveal, so nothing is
// ever suppressed while one runs -- but that is an accident of ordering, not
// an invariant.  `.hidden` also measures 0 in getElemWorkspaceHeight(), which
// reads offsetHeight, so pagination correctly stops reserving room for writing
// space the reader cannot see.
function hideWidowedWorkspaces() {
    const printout = getPrintout();
    if (!printout) return;
    const stranding = anySolutionShown();
    // Start from a clean slate, so no earlier pass's decision can survive on an
    // element that is no longer the row.  Safe to own the class outright here:
    // nothing else in the printout ever hides a workspace -- solutions and
    // headers/footers carry `hidden` on their own elements.
    printout.querySelectorAll('.workspace, .workspace-container').forEach(ws => ws.classList.remove('hidden'));
    printout.querySelectorAll(':scope > .onepage').forEach(page => {
        const rows = [...page.children].filter(c => !isHeaderFooterEl(c));
        const questionGroupsOnPage = new Set(
            rows.filter(r => !isWorkspaceRow(r))
                .map(r => r.dataset.blockGroup)
                .filter(Boolean)
        );
        for (const row of rows) {
            if (!isWorkspaceRow(row) || !row.dataset.blockGroup) continue;
            if (stranding && !questionGroupsOnPage.has(row.dataset.blockGroup)) {
                console.log("Hiding workspace stranded from its question:", row);
                row.classList.add('hidden');
            }
        }
    });
}

function adjustWorkspaceOrRepaginate({paperSize, margins, fullRecompute = false}) {
    adjustWorkspaceToFitPage({paperSize, margins});
    if (pageOverflows()) {
        if (fullRecompute) {
            resetPrintoutPagination(margins);
        } else {
            addSpilloverPages(margins);
        }
        adjustWorkspaceToFitPage({paperSize, margins});
    }
    // After the layout has settled, drop writing space that ended up separated
    // from its question by whichever repagination path ran above.
    hideWidowedWorkspaces();
}

function unwrapOnepages() {
    const printout = getPrintout();
    if (!printout) return;
    const pages = [...printout.querySelectorAll(':scope > .onepage')];
    pages.forEach(page => {
        page.querySelectorAll(':scope > .first-page-header, :scope > .running-header, :scope > .first-page-footer, :scope > .running-footer').forEach(hf => hf.remove());
        while (page.firstChild) {
            printout.insertBefore(page.firstChild, page);
        }
        printout.removeChild(page);
    });
}

function resetPrintoutPagination(margins) {
    unwrapOnepages();
    createPrintoutPages(margins);
    addHeadersAndFootersToPrintout();
}

function isHeaderFooterEl(el) {
  return el.classList.contains('first-page-header') || el.classList.contains('running-header') ||
         el.classList.contains('first-page-footer') || el.classList.contains('running-footer');
}

function addSpilloverPages(margins) {
  const printout = getPrintout();
  if (!printout) return;
  let pages = [...printout.querySelectorAll(':scope > .onepage')];

  for (let i = 0; i < pages.length; i++) {
    const page = pages[i];
    const contentChildren = [...page.children].filter(c => !isHeaderFooterEl(c));

    let overflowStartIndex = -1;
    for (let j = 0; j < contentChildren.length; j++) {
      const r = contentChildren[j].getBoundingClientRect();
      if (r.bottom > getPageContentBottom(page) + 1) {
        overflowStartIndex = j;
        break;
      }
    }
    if (overflowStartIndex === -1) continue; // this page fits fine, leave it completely alone
    if (overflowStartIndex === 0) {
      // The very first row alone is already too tall to fit on any page —
      // nothing we can do about that specific row. But if there are other
      // rows after it, they shouldn't be trapped here too: move everything
      // after the oversized first row onto a fresh page.
      if (contentChildren.length <= 1) continue; // truly nothing else to move
      overflowStartIndex = 1;
    }
    // This is the runtime counterpart of the rules findPageBreaks() applies
    // when it plans pages from scratch, and it has to enforce them too: a
    // reveal goes through here (applySolutionVisibility() repaginates with
    // fullRecompute false), so without this a revealed solution can push its
    // own workspace onto the next page and open that page with a slab of
    // blank writing space, or tear a question away from its solutions.
    // Both are fixed the same way -- retreat to an earlier, legal split.
    while (overflowStartIndex > 1) {
      const row = contentChildren[overflowStartIndex];
      const prev = contentChildren[overflowStartIndex - 1];
      const opensWithWorkspace = isVisibleWorkspaceRow(row);
      const splitsGroup = !!(row.dataset.blockGroup &&
                             row.dataset.blockGroup === prev.dataset.blockGroup);
      if (!opensWithWorkspace && !splitsGroup) break;
      overflowStartIndex--;
    }

    const overflowElems = contentChildren.slice(overflowStartIndex);
    const newPage = document.createElement('section');
    newPage.classList.add('onepage', 'spillover');
    if (page.classList.contains('lastpage')) {
      page.classList.remove('lastpage');
      newPage.classList.add('lastpage');
    }
    overflowElems.forEach(el => newPage.appendChild(el));
    page.parentNode.insertBefore(newPage, page.nextSibling);

    [...page.children].filter(isHeaderFooterEl).forEach(hf => hf.remove());

    pages.splice(i + 1, 0, newPage); // let the loop also check the new page for cascading overflow
  }

  printout.querySelectorAll(':scope > .onepage').forEach(p => {
    [...p.children].filter(isHeaderFooterEl).forEach(hf => hf.remove());
  });
  addHeadersAndFootersToPrintout();
}

// Append `children` onto the end of a page's *content*, i.e. before its
// running/first-page footer if one is already attached. Pages being merged
// in collapseSpilloverPages() still have their old footer in place (footers
// aren't stripped until after the whole merge pass finishes), so a plain
// appendChild would land new content after the footer -- corrupting both
// the reading order and the overflow measurement used to judge the merge.
function appendPageContent(page, children) {
    const footer = [...page.children].find(c => c.classList.contains('first-page-footer') || c.classList.contains('running-footer'));
    children.forEach(c => page.insertBefore(c, footer || null));
}

// Eagerly fold every spillover page's content back into the page before it,
// unconditionally -- i.e. without checking whether the merged page fits yet.
// That check is intentionally left to the caller (via adjustWorkspaceOrRepaginate,
// which shrinks workspace boxes to fit before measuring overflow, then
// re-splits with addSpilloverPages() if something still doesn't fit).
// Deciding here, before workspace has a chance to shrink back down from
// whatever size it was left at by the previous, more spread-out layout,
// is unreliable: a page can measure as overflowing purely because its
// workspace boxes are still sized for the old layout, when shrinking them
// would actually make room.
//
// Processing pages highest-index-first guarantees that a spillover page's
// merge target (the page right before it) hasn't itself already been
// removed by an earlier step in this same pass, so chains of cascaded
// spillover pages collapse correctly in a single pass.
function collapseSpilloverPages(margins) {
  const printout = getPrintout();
  if (!printout) return;
  const pages = [...printout.querySelectorAll(':scope > .onepage')];

  for (let i = pages.length - 1; i >= 1; i--) {
    const page = pages[i];
    if (!page.classList.contains('spillover')) continue;
    const prevPage = pages[i - 1];

    const contentChildren = [...page.children].filter(c => !isHeaderFooterEl(c));
    appendPageContent(prevPage, contentChildren);
    if (page.classList.contains('lastpage')) {
      prevPage.classList.add('lastpage');
    }
    page.remove();
  }

  printout.querySelectorAll(':scope > .onepage').forEach(p => {
    [...p.children].filter(isHeaderFooterEl).forEach(hf => hf.remove());
  });
  addHeadersAndFootersToPrintout();
}

// Add headers and footers to all pages in a printout.  Start with this set to be hidden by default; a toggle later will show/hide them.
function addHeadersAndFootersToPrintout() {
    const printout = getPrintout();
    if (!printout) {
        console.warn("No printout found, exiting addHeadersAndFootersToPrintout.");
        return;
    }
    const pages = printout.querySelectorAll('.onepage');
    // Loop through pages and add header and footer divs. This function gets
    // called every time pagination is rebuilt (resetPrintoutPagination(),
    // addSpilloverPages(), collapseSpilloverPages(), ...), not just once at
    // initial load, so the hidden/visible state has to be decided here from
    // localStorage directly -- not left hidden for some later one-time setup
    // step to correct, which would only ever apply to the *first* build and
    // leave every rebuild after it hidden regardless of the checkbox state.
    pages.forEach((page, index) => {
        const isFirstPage = index === 0;
        const headerClass = isFirstPage ? 'first-page-header' : 'running-header';
        const footerClass = isFirstPage ? 'first-page-footer' : 'running-footer';
        // Add header
        const headerDiv = document.createElement('div');
        headerDiv.classList.add(headerClass);
        if (localStorage.getItem(`print-${headerClass}`) !== "true") {
            headerDiv.classList.add('hidden');
        }
        headerDiv.innerHTML = `<div class="header-left" contenteditable="true"></div><div class="header-center" contenteditable="true"></div><div class="header-right" contenteditable="true"></div>`;
        page.insertBefore(headerDiv, page.firstChild);
        // Add footer
        const footerDiv = document.createElement('div');
        footerDiv.classList.add(footerClass);
        if (localStorage.getItem(`print-${footerClass}`) !== "true") {
            footerDiv.classList.add('hidden');
        }
        footerDiv.innerHTML = `<div class="footer-left" contenteditable="true"></div><div class="footer-center" contenteditable="true"></div><div class="footer-right" contenteditable="true"></div>`;
        page.appendChild(footerDiv);
    });
    // Add content based on local storage if available, otherwise from data-attributes on the printout
    const headerFooterKeys = ['header-first-left', 'header-first-center', 'header-first-right', 'footer-first-left', 'footer-first-center', 'footer-first-right', 'header-running-left', 'header-running-center', 'header-running-right', 'footer-running-left', 'footer-running-center', 'footer-running-right'];
    const headerFooterContent = {};
    headerFooterKeys.forEach(key => {
        headerFooterContent[key] = localStorage.getItem(key) || printout.getAttribute(`data-${key}`) || '';
    });
    // First page header and footer
    document.querySelector('.first-page-header').querySelector('.header-left').innerHTML = headerFooterContent['header-first-left'];
    document.querySelector('.first-page-header').querySelector('.header-center').innerHTML = headerFooterContent['header-first-center'];
    document.querySelector('.first-page-header').querySelector('.header-right').innerHTML = headerFooterContent['header-first-right'];
    document.querySelector('.first-page-footer').querySelector('.footer-left').innerHTML = headerFooterContent['footer-first-left'];
    document.querySelector('.first-page-footer').querySelector('.footer-center').innerHTML = headerFooterContent['footer-first-center'];
    document.querySelector('.first-page-footer').querySelector('.footer-right').innerHTML = headerFooterContent['footer-first-right'];
    // Running headers and footers
    document.querySelectorAll('.running-header').forEach(headerDiv => {
        headerDiv.querySelector('.header-left').innerHTML = headerFooterContent['header-running-left'];
        headerDiv.querySelector('.header-center').innerHTML = headerFooterContent['header-running-center'];
        headerDiv.querySelector('.header-right').innerHTML = headerFooterContent['header-running-right'];
    });
    document.querySelectorAll('.running-footer').forEach(footerDiv => {
        footerDiv.querySelector('.footer-left').innerHTML = headerFooterContent['footer-running-left'];
        footerDiv.querySelector('.footer-center').innerHTML = headerFooterContent['footer-running-center'];
        footerDiv.querySelector('.footer-right').innerHTML = headerFooterContent['footer-running-right'];
    });
    // Add event listeners to update local storage when content is edited
    headerFooterKeys.forEach(key => {
        const selectorMap = {
            'header-first-left': '.first-page-header .header-left',
            'header-first-center': '.first-page-header .header-center',
            'header-first-right': '.first-page-header .header-right',
            'footer-first-left': '.first-page-footer .footer-left',
            'footer-first-center': '.first-page-footer .footer-center',
            'footer-first-right': '.first-page-footer .footer-right',
            'header-running-left': '.running-header .header-left',
            'header-running-center': '.running-header .header-center',
            'header-running-right': '.running-header .header-right',
            'footer-running-left': '.running-footer .footer-left',
            'footer-running-center': '.running-footer .footer-center',
            'footer-running-right': '.running-footer .footer-right'
        };
        const elements = document.querySelectorAll(selectorMap[key]);
        elements.forEach(elem => {
            elem.addEventListener('input', () => {
                localStorage.setItem(key, elem.innerHTML);
            });
        });
    });
}


// We look at each page and adjust the heights of the workspaces to fit it nicely into the page.
// The width and height of the page will now depend on the letter or a4 setting.
function adjustWorkspaceToFitPage({paperSize, margins}) {
    console.log("*** Adjusting workspace to fit page size:", paperSize, "with margins:", margins);

    // Toggle off workspace highlight if it is on, so it doesn't interfere with resizing
    const highlightWorkspaceCheckbox = document.getElementById("highlight-workspace-checkbox");
    const wasHighlighted = highlightWorkspaceCheckbox && highlightWorkspaceCheckbox.checked;
    if (wasHighlighted) {
        toggleWorkspaceHighlight(false);
    }

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

    // Reset the highlight workspace checkbox state
    if (wasHighlighted) {
        toggleWorkspaceHighlight(true);
    }
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
    const workspaces = workspaceDivsIn(elem);
    let totalHeight = 0;
    workspaces.forEach(ws => {
        const workspaceHeight = ws.offsetHeight;
        if (workspaceHeight) {
            totalHeight += workspaceHeight;
        }
    });
    return totalHeight / columns; // Divide by columns if sidebyside to get average height per column
}

// Cost of one candidate page holding rows [i..j], in the same units as the
// original objective: (px of wasted space)^2, so that the penalties below
// trade off directly against blank space -- a penalty of P is "worth" about
// sqrt(P) px of waste at the foot of a page.
//
//   naturalHeight   total height with every workspace at its authored size
//   workspaceHeight how much of that is blank writing space, i.e. how much
//                   can be given back by squeezing (adjustWorkspaceToFitPage()
//                   scales workspaces by a factor below 1 when a page is over
//                   budget, so a page may legitimately be planned as "fits
//                   only once squeezed")
//   splitsGroup     true when the break after row j separates a question from
//                   its own solutions or workspace
//
// Returns Infinity for a page that cannot be made to fit at all.
//
// NB the two constants are the tuning knobs for "keep an exercise with its
// solutions and workspace together, and only spill over if absolutely
// necessary": raising GROUP_BREAK_PENALTY_PAGES buys cohesion at the price of
// more blank space, and lowering SQUEEZE_COST_SCALE makes the layout more
// willing to eat into writing space before it gives up and splits.
//
// The group penalty is expressed in whole wasted pages rather than as a raw
// number so that it scales with paper size instead of being tuned for one:
// at 1, separating a question from its own solutions or workspace is judged
// exactly as costly as leaving a whole page blank, which is what makes the
// optimiser exhaust every other option -- including squeezing away all the
// writing space, and pushing the whole group to the next page -- first.
const GROUP_BREAK_PENALTY_PAGES = 1;
const SQUEEZE_COST_SCALE = 0.25;        // squeezing s px of workspace costs 0.25*s^2

// Whether any hint/answer/solution is currently revealed in the printout.
// Checks effective visibility -- the element and every ancestor free of
// "hidden" -- because rewriteSolutions() puts the "hidden" class on the
// wrapper it builds, while the original `.knowl__content` div inside it never
// carries the class itself.
function anySolutionShown() {
    const printout = getPrintout();
    if (!printout) return false;
    return [...printout.querySelectorAll('.hint, .answer, .solution')].some(el => !el.closest('.hidden'));
}

function pageCost({ pageHeight, naturalHeight, workspaceHeight, splitsGroup, allowSqueeze, squeezeIsForced }) {
    const groupPenalty = splitsGroup ? GROUP_BREAK_PENALTY_PAGES * pageHeight ** 2 : 0;
    if (naturalHeight <= pageHeight) {
        // Fits as authored; the classic objective, minimise wasted space.
        return (pageHeight - naturalHeight) ** 2 + groupPenalty;
    }
    // Over budget at the authored workspace sizes.  Blank writing space is
    // compressible, but eating into it to merely pack pages tighter is only
    // acceptable once a hint/answer/solution is on the page taking up the
    // room -- with nothing revealed, the author asked for that much space to
    // write in and must get at least that much, even at the cost of extra
    // pages.
    //
    // The exception is a page holding a row that is taller than the page all
    // by itself.  There, squeezing is not an optimisation, it is the only way
    // that row is ever going to fit, and refusing it does not preserve any
    // writing space -- it just strands the row on a page of its own and, worse,
    // leaves whatever small thing preceded it (a worksheet title, typically)
    // alone on the page before.  So allow it whenever it is forced.
    if (!allowSqueeze && !squeezeIsForced) {
        return Infinity;
    }
    const squeeze = naturalHeight - pageHeight;
    if (squeeze > workspaceHeight) {
        return Infinity; // no amount of squeezing saves this page
    }
    // Nothing is wasted (the page is exactly full), but squeezing writing
    // space has its own cost, so a merely-tight page still loses to a roomy one.
    return SQUEEZE_COST_SCALE * squeeze ** 2 + groupPenalty;
}

// Functions for finding the optimal page breaks.
//
// `allowSqueeze` permits planning a page that only fits once its blank
// writing space is compressed.  It is off unless a hint/answer/solution is
// actually being shown: a worksheet with nothing revealed must honour the
// authored workspace heights in full.
function findPageBreaks(rows, pageHeight, { allowSqueeze = false } = {}) {
    console.log("*** Finding page breaks for", rows.length, "rows with page height:", pageHeight);
    // An array for the page breaks.  The nth element will be the index of the first row on page n+1.
    let pageBreaks = [];
    // An array for the minimum cost possible for rows i to the end.
    let minCost = Array(rows.length + 1).fill(Infinity);
    minCost[rows.length] = 0; // No cost for no rows
    // An array to keep track of the next row to start a new page after i in minCost.
    let nextPageBreak = Array(rows.length).fill(-1);

    // Now loop through the rows in reverse order to find the optimal page breaks.
    for (let i = rows.length - 1; i >= 0; i--) {
        let cumulativeHeight = 0;
        let cumulativeWorkspaceHeight = 0;
        let tallestRow = 0;
        // Loop through the rows starting from i to find the best page break
        for (let j = i; j < rows.length; j++) {
            cumulativeHeight += rows[j].height;
            cumulativeWorkspaceHeight += rows[j].workspaceHeight;
            // A row taller than a whole page cannot be placed at its authored
            // size no matter how the breaks fall, so squeezing is forced for
            // any page that has to hold it -- see pageCost().
            tallestRow = Math.max(tallestRow, rows[j].height);
            const next = rows[j + 1];

            const thisPage = pageCost({
                pageHeight,
                naturalHeight: cumulativeHeight,
                workspaceHeight: cumulativeWorkspaceHeight,
                splitsGroup: !!(next && rows[j].group && rows[j].group === next.group),
                allowSqueeze,
                squeezeIsForced: tallestRow > pageHeight,
            });
            if (thisPage === Infinity) {
                // This page overflows even with all its writing space squeezed
                // away, and every longer page would too, so stop extending it.
                if (j === i) {
                    // The page height is too big for a single row.  We make this row its own page and move on.
                    console.log("Row", i, "exceeds page height by itself, setting as its own page.");
                    minCost[i] = 0; // No cost for a single row
                    nextPageBreak[i] = i + 1; // The next page break is after this row
                }
                break;
            }
            // A page must never open with blank writing space: a workspace
            // row belongs under the question it was authored for, so breaking
            // right before one is simply not a legal break.  (When the group
            // genuinely cannot be held together, the workspace is suppressed
            // later instead -- see hideWidowedWorkspaces().)
            if (next && next.isWorkspace) continue;

            const cost = thisPage + minCost[j + 1]; // plus the cost of the following pages
            if (cost < minCost[i]) {
                minCost[i] = cost;
                nextPageBreak[i] = j + 1; // Set the next page break to be after row j
            }
        }
        // Every candidate break was illegal (e.g. the only places to break
        // were immediately before a workspace row).  Fall back to giving row i
        // a page of its own so backtracking below always makes progress
        // rather than looping on nextPageBreak === -1.
        if (nextPageBreak[i] === -1) {
            nextPageBreak[i] = i + 1;
            minCost[i] = minCost[i + 1];
        }
    }
    // Backtrack to find the actual page breaks based on nextPageBreak
    // Note: nextPage used to be set to 1.
    // This meant the very first page's title height was never counted against that page's budget during optimization, even though it still occupied real space once pages were built.
    // This caused the first page to sometimes exceed capacity, and the resulting correction to cascade into large wasted-space gaps on later pages.
    let nextPage = 0;
    while (nextPage < rows.length) {
        pageBreaks.push(nextPageBreak[nextPage]);
        nextPage = nextPageBreak[nextPage];
    }
    return pageBreaks;
}

// Function to set CSS variables and @page rules for page geometry.  This will be called whenever the paper size or margins change (in practice, only when page size changes, since margins are fixed for now).
function setPageGeometryCSS({paperSize, margins}) {
    console.log("*** Setting page geometry CSS for paper size:", paperSize, "with margins:", margins);
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
                // Deliberately no fixed height on the container.
                //
                // A height snapshotted here goes stale the moment
                // adjustWorkspaceToFitPage() resizes the workspace -- and
                // because flattenSolutionsIn() has already hoisted the
                // workspace out to be a top-level row, this container *is*
                // that row, so the stale value is what createPrintoutPages()
                // measures.  setInitialWorkspaceHeights() resets the
                // `.workspace` back to its authored height but knows nothing
                // about the wrapper, so pagination would plan against the
                // previous, stretched size, hand each page more slack than it
                // really has, and stretch the workspaces again -- a feedback
                // loop that made the whole layout depend on whether the
                // "highlight workspace" box happened to be ticked.
                //
                // Letting the container size to its content keeps it exactly
                // as tall as the workspace at all times, with no value to
                // synchronise.  The marker below is taken out of flow so that
                // it cannot contribute height either.
                container.style.position = 'relative';
                const original = document.createElement('div');
                original.classList.add('original-workspace');
                const originalHeight = workspace.getAttribute('data-space') || '0px';
                original.setAttribute('title', 'Author-specified workspace height (' + originalHeight + ')');
                // Use the data-space attribute for height of original workspace
                original.style.height = originalHeight;
                // Overlaid rather than laid out beside the workspace: it still
                // shows the authored height (overflowing visibly when that is
                // taller than what the workspace was squeezed to, which is the
                // point of the marker) without affecting the row's own height.
                original.style.position = 'absolute';
                original.style.top = '0';
                original.style.left = '0';
                // insert original div before the workspace content
                container.appendChild(original);
                // The container stands in for the workspace as a pagination
                // row while the overlay is on, so it has to carry the group
                // stamp too -- otherwise the question and its writing space
                // stop being seen as one unit.  See isWorkspaceRow().
                if (workspace.dataset.blockGroup) {
                    container.dataset.blockGroup = workspace.dataset.blockGroup;
                }
                // ...and, for the same reason, the indent that keeps a hoisted
                // workspace lined up with its task.  See moveDepthClass().
                moveDepthClass(workspace, container);
                // Move the workspace into the container
                workspace.parentNode.insertBefore(container, workspace);
                container.appendChild(workspace);
                // Flag the marker when the author asked for more room than the
                // workspace was ultimately given.  Measured only now that both
                // elements are actually in the document -- offsetHeight on a
                // detached node is always 0, so checking this before the insert
                // above (as this did previously) could never be true, and the
                // warning never appeared.
                if (original.offsetHeight > workspace.offsetHeight) {
                    original.classList.add('warning');
                }
            });
        }
    } else {
        document.body.classList.remove("highlight-workspace");
        // Remove the original workspace divs.  We don't want to keep these in, as they interfere with changing page sizes and workspace heights.
        document.querySelectorAll('.workspace-container').forEach(container => {
            const workspace = container.querySelector('.workspace');
            // The workspace is about to be the row again, so it takes the
            // indent back with the role.
            moveDepthClass(container, workspace);
            // Move the workspace out of the container
            container.parentNode.insertBefore(workspace, container);
            // Remove the container
            container.remove();
        });
    }
}

function getPaperSize() {
    let paperSize = localStorage.getItem("papersize");
    if (paperSize) {
      return paperSize;
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
    }
    return paperSize || "letter";
}

// A project-like born hidden as a knowl (the publisher's knowl-project) renders
// as
//   <details id="..."><summary><h2 class="heading"/><div class="print-links"/></summary>
//     <article class="knowl__content">...</article></details>
// so the id lands on the <details>, the title sits in the <summary>, and the
// content is a separate article with no title of its own.  Rebuild it as the
// single block a visible project would have produced, title first, so the rest
// of the preview needs to know nothing about knowls.  Returns the block to
// preview, or the <details> unchanged if it is not shaped as expected.
function flattenKnowledPrintout(details) {
    const content = details.querySelector(':scope > .knowl__content');
    if (!content) {
        console.warn("Born-hidden printout has no knowl content; previewing as-is:", details);
        return details;
    }
    const heading = details.querySelector(':scope > summary > .heading');
    if (heading) {
        content.insertBefore(heading, content.firstChild);
    }
    // It is the page now, not knowl content.  Carry the id over so the preview
    // keeps the identity named in the URL.
    content.classList.remove('knowl__content');
    content.id = details.id;
    // Moves content out of details, then drops the details (and its summary).
    details.replaceWith(content);
    return content;
}

// The print icon has to live inside the <summary> of a born-hidden knowl to be
// visible while the knowl is closed, but a click in a <summary> is the knowl's
// own open/close toggle.  So follow the link ourselves and swallow the toggle.
document.addEventListener("click", (ev) => {
    const link = ev.target.closest("a.print-link");
    if (!link || !link.closest("summary")) return;
    ev.preventDefault();
    ev.stopPropagation();
    window.location.assign(link.href);
});

// Function to load the printout section and switch to print stylesheet.  This will run whenever a user clicks on a print preview link (which adds ?printpreview=sectionID to the URL).
async function loadPrintout(printableSectionID) {

    // Switch to print-worksheet.css for print preview
    const themeStylesheetLink = document.querySelector('link[rel="stylesheet"][href*="theme"]');
    // get the href of the theme stylesheet link
    const themeStylesheetHref = themeStylesheetLink ? themeStylesheetLink.getAttribute('href') : null;
    if (themeStylesheetHref) {
        // replace 'theme.css' with 'print-worksheet.css' in the href
        const printStylesheetHref = themeStylesheetHref.replace(/theme.*\.css/, 'print-worksheet.css');
        // update the href of the theme stylesheet link
        themeStylesheetLink.setAttribute('href', printStylesheetHref);
        // Wait for the new stylesheet to load.  This is important to ensure the styles are applied before the calling function tries to compute workspace sizes.
        await new Promise((resolve) => {
            themeStylesheetLink.addEventListener('load', resolve, { once: true });
        });
    }

    // Find the element with this ID.  For a worksheet or handout this is the
    // division's section; for a standalone project-like printout it is the
    // project's article, nested somewhere inside a division section, or a
    // <details> if the project is born hidden as a knowl.
    let printableSection = document.getElementById(printableSectionID);
    if (!printableSection) {
        console.error("No printable element found with ID:", printableSectionID);
        return;
    }
    if (printableSection.tagName === "DETAILS") {
        printableSection = flattenKnowledPrintout(printableSection);
    }
    // Mark it as the printout so the stylesheet and the pagination code below
    // can find it without knowing which kind of element it is.
    printableSection.classList.add("printout");
    // Remove any existing sections from .ptx-content and add only the printable
    // section.  Removing a section that contains the printout is harmless: we
    // still hold a reference to it, and re-attach it on the next line.
    const ptxContent = document.querySelector('.ptx-content');
    const existingSections = ptxContent.querySelectorAll(':scope > section');
    existingSections.forEach(sec => ptxContent.removeChild(sec));
    ptxContent.appendChild(printableSection);
}

// Whether hint/answer/solution divs of `solutionType` should be hidden: the
// user's stored choice if there is one, otherwise the default (answers and
// solutions start hidden, hints don't). Single source of truth for that
// default so rewriteSolutions() (which needs it immediately, before the
// checkbox that owns it has even been set up) and the checkbox setup loop
// below can't drift apart.
function solutionTypeHidden(solutionType) {
    const stored = localStorage.getItem(`hide-${solutionType}`);
    if (stored !== null) {
        return stored === "true";
    }
    return solutionType === "answer" || solutionType === "solution";
}

// Function to redo solutions details to divs with summary as title
async function rewriteSolutions() {
    var born_hidden_knowls = document.querySelectorAll('.printout details');
    born_hidden_knowls.forEach(function(detail) {
        const summary = detail.querySelector('summary');
        const content = detail.innerHTML.replace(summary.outerHTML, '');
        const div = document.createElement('div');
        div.classList = detail.classList;
        // Unconditionally hidden here, regardless of the stored/default
        // preference for this solutionType: the very first pagination pass
        // needs one single, reproducible "everything hidden" starting point
        // to lay pages out against (see the DOMContentLoaded handler below,
        // where whichever types should actually start visible get revealed
        // afterward, through the same incremental show/hide path a checkbox
        // toggle uses). Basing initial layout on the *actual* visibility
        // instead would make that layout as reachable only from that one
        // specific combination of shown/hidden types, instead of from the
        // one common base every hide always returns to.
        for (const solutionType of ["hint", "answer", "solution"]) {
            if (div.classList.contains(solutionType)) {
                div.classList.add("hidden");
                break;
            }
        }
        if (summary) {
            const title = document.createElement('h5');
            title.innerHTML = summary.innerHTML;
            div.appendChild(title);
        }
        const body = document.createElement('div');
        body.innerHTML = content;
        div.appendChild(body);
        detail.parentNode.replaceChild(div, detail);
    });
    if (typeof MathJax !== "undefined" && MathJax.typesetPromise) {
        await MathJax.typesetPromise();
    }
}

// Utility to convert various CSS length units to pixels
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

// A cheap fingerprint of the current page layout: how many pages there are
// and each one's height. Good enough to tell "still changing" from "settled"
// without needing to know *why* something might still be resizing (MathJax,
// an image, a browser reflow after a class toggle, etc).
function pageLayoutSignature() {
    return [...document.querySelectorAll('.onepage')]
        .map(page => Math.round(page.getBoundingClientRect().height))
        .join(',');
}

// Repeatedly call `settle` (a synchronous pagination/layout pass) on an
// interval, stopping as soon as the page layout looks the same for
// `stableTicks` ticks in a row -- i.e. nothing is left to settle -- rather
// than always running for the full `timeoutMs` window. `timeoutMs` is a hard
// cap for content that can never fully converge (e.g. a single block
// permanently too tall for one page -- see addSpilloverPages()); without it,
// content still actively resizing (a solution knowl settling into its final
// size, a late-typesetting equation) could stop being watched too early.
//
// Without the early stop, `settle` -- which can call
// addHeadersAndFootersToPrintout(), destroying and recreating every
// header/footer contenteditable div -- would otherwise run unconditionally
// on every tick for the whole window, on every checkbox toggle, even long
// after nothing is actually still changing: wasted layout work at best, and
// at worst it yanks the cursor out from under someone mid-edit in a header
// or footer field.
async function pollUntilSettled(settle, {timeoutMs = 2000, intervalMs = 100, stableTicks = 3} = {}) {
    const deadline = Date.now() + timeoutMs;
    let lastSignature = null;
    let stableCount = 0;
    while (Date.now() < deadline) {
        await new Promise(r => setTimeout(r, intervalMs));
        settle();
        const signature = pageLayoutSignature();
        if (signature === lastSignature) {
            if (++stableCount >= stableTicks) return;
        } else {
            stableCount = 0;
            lastSignature = signature;
        }
    }
}

// Show or hide every div of `solutionType` and adjust pagination to match.
// Shared by the checkbox change handler and by the initial application of
// stored/default visibility right after the base layout is built, so both
// paths are guaranteed to behave identically.
//
// Always incremental -- addSpilloverPages()/collapseSpilloverPages() acting
// on the existing .onepage structure -- never a full recompute
// (resetPrintoutPagination()/createPrintoutPages()). The base layout (built
// with every hint/answer/solution hidden -- see rewriteSolutions()) assigns
// each row to a page exactly once; a full recompute after that would
// re-derive page breaks from whatever happens to be visible at the time,
// which depends on which other types happen to be shown, so a show/hide
// round trip on one type wasn't guaranteed to land back on the same layout
// it started from. Collapsing always folds back toward that one base, and
// showing only ever pushes overflow forward onto a new page, so hiding
// reliably undoes exactly what showing did.
//
// Runs under withIframesDetached() since the repagination and collapse work
// below can move a row -- and any iframe inside it -- several times over the
// course of one toggle.
async function applySolutionVisibility(solutionType, hidden, {paperSize, margins}) {
    document.querySelectorAll(`div.${solutionType}`).forEach(elem => {
        if (hidden) { elem.classList.add("hidden"); }
        else { elem.classList.remove("hidden"); }
    });
    await withIframesDetached(async () => {
        if (hidden) {
            collapseSpilloverPages(margins);
            adjustWorkspaceOrRepaginate({paperSize, margins, fullRecompute: false});
            // Content just hidden (e.g. a long solution) can take a moment to
            // finish settling into its final, compact size, so an immediate
            // measurement can miss a page that's actually able to collapse.
            await pollUntilSettled(() => {
                collapseSpilloverPages(margins);
                adjustWorkspaceOrRepaginate({paperSize, margins, fullRecompute: false});
            });
        } else {
            adjustWorkspaceOrRepaginate({paperSize, margins, fullRecompute: false});
            await pollUntilSettled(() => {
                if (pageOverflows()) {
                    addSpilloverPages(margins);
                    adjustWorkspaceToFitPage({paperSize, margins});
                }
            });
        }
    });
}

// Event listener for page load to handle print preview setup
window.addEventListener("DOMContentLoaded", async function(event) {
    const urlParams = new URLSearchParams(window.location.search);
    let pendingSettle = Promise.resolve();
    // We condition on the existence of the papersize radio buttons, which only appear in the printout print preview.
    if (urlParams.has("printpreview")) {
        const printableSectionID = urlParams.get("printpreview");
        await loadPrintout(printableSectionID);

        // loadPrintout bails out if the id names nothing printable (a stale or
        // hand-edited URL), so there may be no printout to lay out.
        const printout = getPrintout();
        if (!printout) {
            console.warn("Nothing to preview for printpreview=" + printableSectionID + "; leaving the page as it is.");
            return;
        }

        // If the printout has authored pages, there will be at least one .onepage
        // element. That's purely a property of the source HTML, so it's safe to
        // read this early, before anything below has a chance to touch the DOM.
        // Declared up here (rather than right before its first use, closer to
        // adjustPrintoutPages()) because the hide/reveal checkbox handlers set
        // up below close over it too, and a forward reference to a `const`
        // declared later in this same function only happens to work today
        // because those handlers can't fire before this function finishes
        // running -- moving it here removes that fragility outright.
        const hasAuthoredPages = document.querySelectorAll('.onepage').length > 0;

        // First, get the margins for pages to be passed around as needed.
        const marginList = (printout.getAttribute('data-margins') || "").split(' ');
        // Convert margin values to pixels if they are not already numbers
        const margins = {
            top: toPixels(marginList[0] || "0.75in"), // Default to 0.75in if not specified
            right: toPixels(marginList[1] || "0.75in"),
            bottom: toPixels(marginList[2] || "0.75in"),
            left: toPixels(marginList[3] || "0.75in")
        }

        // Transform all solutions details elements to divs with the summary as a title
        await rewriteSolutions();

        // Get the papersize from localStorage or set it based on user's geographic region.  This will always return a value (defaulting to 'letter' if all else fails).
        let paperSize = getPaperSize();
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
            console.warn("Bug: paperSize should always have a value here.");
        }
        // Add event listeners to the papersize radio buttons to handle changes
        const papersizeRadios = document.querySelectorAll('input[name="papersize"]');
        papersizeRadios.forEach(radio => {
            radio.addEventListener('change', function() {
                if (this.checked) {
                    document.body.classList.remove("a4", "letter");
                    document.body.classList.add(this.value);
                    localStorage.setItem("papersize", this.value);
                    setPageGeometryCSS({paperSize: this.value, margins: margins});
                    adjustWorkspaceToFitPage({paperSize: this.value, margins: margins});
                }
            });
        });

        // Set up (but don't yet apply) the hide hints/answers/solutions
        // checkboxes. Actually showing whichever types should start visible
        // happens later, in one place, after the base layout (built with
        // everything hidden -- see rewriteSolutions()) is fully settled;
        // see the applySolutionVisibility() call near the end of this handler.
        for (const solutionType of ["hint", "answer", "solution"]) {
            const checkbox = document.getElementById(`hide-${solutionType}-checkbox`);
            if (!checkbox) continue;
            // The XSL only generates this checkbox at all if *some* worksheet
            // on the page has this type of content, since one print-preview
            // control panel can be shared by several worksheets (the one
            // actually shown is picked at runtime via ?printpreview=<id>).
            // Whether it applies to *this* worksheet specifically can only be
            // decided here, against the printout that actually got loaded --
            // if not, hide the whole row rather than leave a checkbox with
            // nothing for it to toggle.
            if (!printout.querySelector(`.${solutionType}`)) {
                const row = checkbox.closest('.hide-option');
                if (row) row.classList.add('hidden');
                continue;
            }
            const storageKey = `hide-${solutionType}`;
            checkbox.checked = solutionTypeHidden(solutionType);
            // Persist the default immediately (not just once the user
            // makes an explicit choice), so it's already on record the
            // next time anything -- e.g. rewriteSolutions() -- needs it.
            if (localStorage.getItem(storageKey) === null) {
                localStorage.setItem(storageKey, checkbox.checked ? "true" : "false");
            }
            checkbox.addEventListener("change", async function() {
                await pendingSettle;
                localStorage.setItem(storageKey, this.checked);
                pendingSettle = applySolutionVisibility(solutionType, this.checked, {paperSize, margins});
            });
        }
        // If none of the three applied to this worksheet, every row above
        // just got hidden -- also hide the now-empty group container so it
        // doesn't leave a stray gap in the print-options panel.
        const hideSolutionsOptions = document.querySelector('.hide-solutions-options');
        if (hideSolutionsOptions && !hideSolutionsOptions.querySelector('.hide-option:not(.hidden)')) {
            hideSolutionsOptions.classList.add('hidden');
        }

        // Finally, with everything set up, we create or adjust the printout pages as needed.

        // Flatten paragraphs sections so page breaks can occur inside them.
        const printoutSection = getPrintout();
        if (printoutSection) {
            flattenParagraphsSections(printoutSection);
        }

        // Wait for all images to load so height measurements are accurate.
        if (printoutSection) {
            await waitForImages(printoutSection);
        }

        // Add explicit await before initial pagination step so all math is settled before measuring content height.
        if (typeof MathJax !== "undefined" && MathJax.typesetPromise) {
            await MathJax.typesetPromise([getPrintout()]);
        }

        // hasAuthoredPages (computed above) picks the right strategy here:
        // preserve authored structure vs. safely recompute a computed layout.
        if (hasAuthoredPages) {
            adjustPrintoutPages();
        } else {
            createPrintoutPages(margins);
            // Safety net: content heights (e.g. proof knowls, large matrices) can
            // still be settling into their final size at this point, which can
            // cause createPrintoutPages to make suboptimal page-break decisions
            // that don't overflow but leave large amounts of wasted space. Since
            // that failure mode isn't detectable via pageOverflows(), just
            // unconditionally re-run pagination once more after a brief settle delay.
            // Tracked via pendingSettle so any checkbox toggle that happens in the
            // meantime waits for this to finish first, instead of racing it.
            pendingSettle = (async () => {
                await new Promise(r => setTimeout(r, 300));
                unwrapOnepages();
                createPrintoutPages(margins);
                addHeadersAndFootersToPrintout();
                adjustWorkspaceToFitPage({paperSize: paperSize, margins: margins});
            })();
        }

        // Add headers and footers to all pages in the printout
        addHeadersAndFootersToPrintout();

        // Add event listeners to the print header/footer checkboxes
        for (const hf of ["first-page-header", "running-header", "first-page-footer", "running-footer"]) {
            const checkbox = document.getElementById(`print-${hf}-checkbox`);
            if (checkbox) {
                // set visibility based on current checkbox state
                checkbox.checked = localStorage.getItem(`print-${hf}`) === "true";
                document.querySelectorAll(`.${hf}`).forEach(elem => {
                    // add hidden to class list
                    if (checkbox.checked) {
                        elem.classList.remove("hidden");
                    } else {
                        elem.classList.add("hidden");
                    }
                });
                // Add event listener to toggle visibility
                checkbox.addEventListener("change", function() {
                    localStorage.setItem(`print-${hf}`, this.checked);
                    // toggle visibility of header/footer divs
                    document.querySelectorAll(`.${hf}`).forEach(elem => {
                        if (checkbox.checked) {
                            elem.classList.remove("hidden");
                        } else {
                            elem.classList.add("hidden");
                        }
                    });
                    // Recompute layout once, after all elements of this type have been toggled
                    adjustWorkspaceToFitPage({paperSize: paperSize, margins: margins});
                });
            }
        }

        // After pages are set up, we adjust the workspace heights to fit the page (based on the paper size),
        // falling back to a spillover page if content still overflows even with workspace at zero.
        adjustWorkspaceOrRepaginate({paperSize: paperSize, margins: margins, fullRecompute: !hasAuthoredPages});
        // Chain onto pendingSettle (rather than overwrite it) so this loop waits
        // for the non-authored-pages safety net scheduled above, if one was
        // scheduled, to finish first. Overwriting it would silently orphan that
        // safety net's promise -- it would still fire on its own timer and mutate
        // the printout unsynchronized with this loop and with whatever a checkbox
        // toggled in the meantime is doing, despite the whole point of
        // pendingSettle being to let a checkbox toggle await "settling in
        // progress" as a single, serialized thing.
        pendingSettle = pendingSettle.then(() => pollUntilSettled(() => {
            if (hasAuthoredPages) {
                // Content still settling into its final size right after
                // load (e.g. a solution knowl, an embedded matrix) can make
                // the very first pass above split content onto a spillover
                // page it doesn't actually need once things settle down.
                // Eagerly try collapsing spillover pages back on every tick
                // and let addSpilloverPages() re-split only what still
                // doesn't fit -- see collapseSpilloverPages()'s comment for
                // why collapsing first, unconditionally, is the reliable order.
                collapseSpilloverPages(margins);
                adjustWorkspaceOrRepaginate({paperSize: paperSize, margins: margins, fullRecompute: false});
            } else if (pageOverflows()) {
                resetPrintoutPagination(margins);
                adjustWorkspaceToFitPage({paperSize: paperSize, margins: margins});
            }
        }));

        // Now that the base layout (built with every hint/answer/solution
        // hidden -- see rewriteSolutions()) has fully settled, reveal
        // whichever types should actually start visible per their stored/
        // default preference, through the same incremental path a checkbox
        // toggle uses. Chained onto pendingSettle so this waits for that
        // settling to finish first -- revealing against a layout that's
        // still being rebuilt out from under it would be measuring against
        // a moving target -- and so a checkbox click in the meantime waits
        // for this in turn, rather than raced against it.
        pendingSettle = pendingSettle.then(async () => {
            for (const solutionType of ["hint", "answer", "solution"]) {
                if (printout.querySelector(`.${solutionType}`) && !solutionTypeHidden(solutionType)) {
                    await applySolutionVisibility(solutionType, false, {paperSize, margins});
                }
            }
        });

        // Get the 'highlight workspace' checkbox state from localStorage or set it to false by default
        // NB we need to do this after the adjustment of workspace heights so that the additional original workspace divs don't throw off the calculations when the page is reloaded.
        const highlightWorkspaceCheckbox = document.getElementById("highlight-workspace-checkbox");
        if (highlightWorkspaceCheckbox) {
            // Same reasoning as the hide-hint/answer/solution rows above: this
            // control panel can be shared by several worksheets on the same
            // page, so whether this worksheet actually has any workspace to
            // highlight can only be decided here, against the printout that
            // actually got loaded.
            if (workspaceDivsIn(printout).length === 0) {
                const row = highlightWorkspaceCheckbox.closest('.highlight-workspace-option');
                if (row) row.classList.add('hidden');
            } else {
                highlightWorkspaceCheckbox.checked = localStorage.getItem("highlightWorkspace") === "true";
                highlightWorkspaceCheckbox.addEventListener("change", function() {
                    localStorage.setItem("highlightWorkspace", this.checked);
                    toggleWorkspaceHighlight(this.checked);
                });
                // Initial toggle to apply the highlight class if checked
                toggleWorkspaceHighlight(highlightWorkspaceCheckbox.checked);
            }
        }

        console.log("finished adjusting workspace");
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
