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

// from https://stackoverflow.com/questions/34422189/get-item-offset-from-the-top-of-page
function getOffsetTop(e) {
    // recursively walk up the DOM via offsetParent, accumulating offsetTop as we go
    if (!e) return 0;
    return getOffsetTop(e.offsetParent) + e.offsetTop;
};

function scrollTocToActive() {
    //Try to figure out current TocItem from URL
    let fileNameWHash = window.location.href.split("/").pop();
    let fileName = fileNameWHash.split("#")[0];

    //Find just the filename in ToC
    let tocEntry = document.querySelector('#ptx-toc a[href="' + fileName + '"]');
    if (!tocEntry) {
        return; //complete failure, get out
    }

    let tocEntryTop = 0;
    //See if we can also match fileName#hash (assuming there is a fragment)
    if (fileNameWHash.includes('#')) {
        let tocEntryWHash = document.querySelector(
            '#ptx-toc a[href="' + fileNameWHash + '"]'
        );
        if (tocEntryWHash) {
            //Matched something below a subsection - activate the list item that contains it
            tocEntry.closest("li").querySelectorAll("li").forEach(li => {
                li.classList.remove("active");
            });
            tocEntryWHash.closest("li").classList.add("active");
            tocEntryTop = getOffsetTop(tocEntryWHash);
        }
    }
    if (!tocEntryTop) {
        tocEntryTop = getOffsetTop(tocEntry);
    }

    //Now activate ToC item for fileName and scroll to it
    //  Don't use scrollIntoView because it changes users tab position in Chrome
    //  and messes up keyboard navigation
    tocEntry.closest("li").classList.add("active");
    // Scroll only if the tocEntry is below the bottom half of the window,
    // scrolling to that position.
    let toc = document.querySelector("#ptx-toc");
    let tocTop = getOffsetTop(toc);
    toc.scrollTop = tocEntryTop - tocTop - 0.4 * self.innerHeight;
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

function samePageLink(a) {
    if (!(a instanceof HTMLAnchorElement)) return false;

    try {
        const linkUrl = new URL(a.href, document.baseURI);
        const currentUrl = new URL(window.location.href);

        const sameDocument =
              linkUrl.origin === currentUrl.origin &&
              linkUrl.pathname === currentUrl.pathname &&
              linkUrl.search === currentUrl.search;

        return sameDocument && !!linkUrl.hash;
    } catch (e) {
        // Invalid URL
        return false;
    }
}


window.addEventListener("DOMContentLoaded",function(event) {
    thetocbutton = document.getElementsByClassName("toc-toggle")[0];
    thetocbutton.addEventListener("click", (e) => {
        toggletoc();
        e.stopPropagation(); // keep global click handler from immediately toggling it back
    });

    // For themes that want it, install click handlers to auto close the toc
    // when the reader clicks anywhere outside it or selects a subsection.
    // (Selecting other sections or chapters navigates away from the page so
    // effectively closes the TOC.)
    if (getComputedStyle(document.documentElement).getPropertyValue('--auto-collapse-toc') == "yes") {

        const sidebar = document.getElementById("ptx-sidebar");

        // Handle all clicks outside the sidebar
        window.addEventListener("click", function(event) {
            if (sidebar.classList.contains("visible")) {
                if (!event.composedPath().includes(sidebar)) {
                    toggletoc();
                }
            }
        });

        // Handle clicks inside the sidebar but on link within a subsection.
        sidebar.addEventListener("click", function (event) {
            if (samePageLink(event.target.closest('a'))) {
                toggletoc();
            }
        });

        // Handle persistent sidebar if the page is restored from cache on back/forward buttons.
        window.addEventListener('pageshow', (e) => {
            if (e.persisted) {
                sidebar.classList.remove('visible');
                sidebar.classList.add('hidden');
            }
        });
    }
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
            // content of span is set by CSS :before rule.
            expander.innerHTML = '<span class="icon material-symbols-outlined" aria-hidden="true"></span>';
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

// This needs to be after the TOC's geometry is settled
window.addEventListener("DOMContentLoaded",function(event) {
    scrollTocToActive();
});

window.onhashchange = scrollTocToActive;
