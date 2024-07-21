/*******************************************************************************
 * pretext.js
 *******************************************************************************
 * The main front-end controller for PreTeXt documents.
 *
 * Homepage: pretextbook.org
 * Repository: https://github.com/PreTeXtBook/JS_core
 *
 * Authors: David Farmer, Rob Beezer
 *
 *******************************************************************************
 */

function scrollTocToActive() {
    //Try to figure out current TocItem from URL
    let fileNameWHash = window.location.href.split("/").pop();
    let fileName = fileNameWHash.split("#")[0];

    //Find just the filename in ToC
    let tocEntry = document.querySelector('#ptx-toc a[href="' + fileName + '"]');
    if (!tocEntry) {
        return; //complete failure, get out
    }

    //See if we can also match fileName#hash
    let tocEntryWHash = document.querySelector(
        '#ptx-toc a[href="' + fileNameWHash + '"]'
    );
    if (tocEntryWHash) {
        //Matched something below a subsection - activate the list item that contains it
        tocEntryWHash.closest("li").classList.add("active");
    }

    //Now activate ToC item for fileName and scroll to it
    //  Don't use scrollIntoView because it changes users tab position in Chrome
    //  and messes up keyboard navigation
    tocEntry.closest("li").classList.add("active");
    document.querySelector("#ptx-toc").scrollTop = tocEntry.offsetTop;
}

function toggletoc() {
   thesidebar = document.getElementById("ptx-sidebar");
   if (thesidebar.classList.contains("hidden") || thesidebar.classList.contains("visible")) {
       thesidebar.classList.toggle("hidden");
       thesidebar.classList.toggle("visible");
   } else if (thesidebar.offsetParent === null) {  /* not currently visible */
       thesidebar.classList.toggle("visible");
   } else {
       thesidebar.classList.toggle("hidden");
   }
   scrollTocToActive();
}

window.addEventListener("load",function(event) {
       thetocbutton = document.getElementsByClassName("toc-toggle")[0];
       thetocbutton.addEventListener('click', () => toggletoc() );
});

window.addEventListener("load",function(event) {
       scrollTocToActive();
});

/* jump to next page if reader tries to scroll past the bottom */
// var hitbottom = false;
// window.onscroll = function(ev) {
//   if ((window.innerHeight + window.scrollY) >= document.body.scrollHeight) {
//     // you're at the bottom of the page
//     console.log("Bottom of page");
//     if (hitbottom) {
//         console.log("hit bottom again");
//         thenextbutton = document.getElementsByClassName("next-button")[0];
//         thenextbutton.click();
//     } else {
//         hitbottom = true;
//         /* only jump to next page if hard scroll in quick succession */
//         window.scrollBy(0, -20);
//         setTimeout(function (){ hitbottom = false }, 1000);
//     }
//   }
// };


//-----------------------------------------------------------------------------
// Dynamic TOC logic 
//-----------------------------------------------------------------------------

//item is assumed to be expander in toc-item
function toggleTOCItem(expander) {
    let listItem = expander.closest(".toc-item");
    listItem.classList.toggle("expanded");
    let expanded = listItem.classList.contains("expanded");
    
    let itemType = getTOCItemType(listItem);
    if(expanded) {
        expander.title = "Close" + (itemType !== "" ? " " + itemType : "");
    } else {
        expander.title = "Expand" + (itemType !== "" ? " " + itemType : "");
    }

    //should be one of each... for/of for safety and built in null avoidance
    for (const childUL of listItem.querySelectorAll(":scope > ul.toc-item-list")) {
        for (const childItem of childUL.querySelectorAll(":scope > li.toc-item")) {
            if(expanded) {
                childItem.classList.add("visible");
                childItem.classList.remove("hidden");
            } else {
                childItem.classList.remove("visible");
                childItem.classList.add("hidden");
            }
        }
    }
}

//finds item type from classes or empty string on failure
function getTOCItemType(item) {
    //Type should be class that looks like toc-X where X is not item. Find it and return X
    for(let className of item.classList) {
        if(className !== "toc-item" && className.length > 3 && className.slice(0,4) === "toc-")
            return className.slice(4);
    }
    return "";
}

//finds depth of toc-item as defined by number .toc-item-lists it is in
function getTOCItemDepth(item) {
    let depth = 0;
    let curParent = item.closest(".toc-item-list");
    while(curParent !== null) {
        depth++;
        curParent = curParent.parentElement.closest(".toc-item-list");
    }
    return depth;
}

window.addEventListener("DOMContentLoaded", function(event) {
    if(document.querySelector(".ptx-toc.focused") === null)
        return;  //only in focused mode

    let maxDepth = 1000;  //how deep TOC goes
    //check toc for depth class and get value from there
    for(let className of document.querySelector(".ptx-toc").classList)
        if(className.length > 5 && className.slice(0,5) === "depth")
            maxDepth = Number(className.slice(5));

    let preexpandedLevels = 1; //how many levels to preexpand
    let tocDataSet = document.querySelector(".ptx-toc").dataset;
    if(typeof tocDataSet.preexpandedLevels !== 'undefined')
        preexpandedLevels = Number(tocDataSet.preexpandedLevels);

    let tocItems = document.querySelectorAll(".ptx-toc ul.structural > .toc-item");
    for (const tocItem of tocItems) {
        let hasChildren = tocItem.querySelector('ul.structural') !== null;
        let depth = getTOCItemDepth(tocItem);

        if(hasChildren && depth < maxDepth) {
            let expander = document.createElement("button");
            expander.classList.add('toc-expander');
            expander.classList.add('toc-chevron-surround');
            expander.title = 'toc-expander';
            expander.innerHTML = '<span class="icon material-symbols-outlined" aria-hidden="true">chevron_left</span>';
            tocItem.querySelector(".toc-title-box").append(expander);
            expander.addEventListener('click', () => {
                toggleTOCItem(expander);
            });

            let isActive = tocItem.classList.contains("contains-active") || tocItem.classList.contains("active");
            let preExpanded = isActive || depth < preexpandedLevels;
            let itemType = getTOCItemType(tocItem);
            if(preExpanded) {
                toggleTOCItem(expander);
            } else {
                expander.title = "Expand" + (itemType !== "" ? " " + itemType : "");
            }
        }
      }
});