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
    let ptxSidebar = document.getElementById("ptx-sidebar");
    let sideBarIsHidden = ptxSidebar.classList.contains("hidden") || (!ptxSidebar.classList.contains("visible") && ptxSidebar.offsetParent === null);

    if (sideBarIsHidden) {
        ptxSidebar.classList.add("visible");
        ptxSidebar.classList.remove("hidden");
    } else {
        ptxSidebar.classList.remove("visible");
        ptxSidebar.classList.add("hidden");
    }
    sideBarIsHidden = !sideBarIsHidden; //toggled value for aria-expanded

    let ptxTocButton = document.getElementById("ptx-toc-toggle");
    ptxTocButton.setAttribute("aria-expanded", !sideBarIsHidden);

    if (!sideBarIsHidden) {
        scrollTocToActive();
        // Focus the TOC for accessibility
        document.querySelector("#ptx-toc").focus();
    } else {
        // Focus the TOC toggle button for accessibility
        ptxTocButton.focus();
    }
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
    let tocButton = document.getElementById("ptx-toc-toggle");

    tocButton.addEventListener("click", (e) => {
        toggletoc();
        e.stopPropagation(); // keep global click handler from immediately toggling it back
    });

    // determine if toc starts off hidden or not, use that to set aria-expanded
    let ptxSidebar = document.getElementById("ptx-sidebar");
    let sideBarIsHidden = ptxSidebar.classList.contains("hidden") || (!ptxSidebar.classList.contains("visible") && ptxSidebar.offsetParent === null);
    tocButton.setAttribute("aria-expanded", !sideBarIsHidden);

    // For themes that want it, install click handlers to auto close the toc
    // when the reader clicks anywhere outside it or selects a subsection.
    // (Selecting other sections or chapters navigates away from the page so
    // effectively closes the TOC.)
    const autoCollapseToc = getComputedStyle(document.documentElement).getPropertyValue('--auto-collapse-toc') == "yes";
    if (autoCollapseToc) {
        // Handle all clicks outside the sidebar
        window.addEventListener("click", function(event) {
            if (ptxSidebar.classList.contains("visible")) {
                if (!event.composedPath().includes(ptxSidebar)) {
                    toggletoc();
                }
            }
        });

        // Handle clicks inside the sidebar but on link within a subsection.
        ptxSidebar.addEventListener("click", function (event) {
            if (samePageLink(event.target.closest('a'))) {
                toggletoc();
            }
        });

        // Handle persistent sidebar if the page is restored from cache on back/forward buttons.
        window.addEventListener('pageshow', (e) => {
            if (e.persisted) {
                ptxSidebar.classList.remove('visible');
                ptxSidebar.classList.add('hidden');
                tocButton.setAttribute("aria-expanded", "false");
            }
        });

    }

    // Handle Escape key to close the sidebar when it is presented as a mobile overlay
    // or at any size if autoCollapseToc is enabled
    window.addEventListener("keydown", function(event) {
        if (
            event.key === "Escape"
            && ptxSidebar.classList.contains("visible")
            && (
                getComputedStyle(ptxSidebar).position === "fixed"
                || autoCollapseToc
            )
        ) {
            toggletoc();
        }
    });
});


//-----------------------------------------------------------------------------
// Dynamic TOC logic
//-----------------------------------------------------------------------------

//item is assumed to be expander in toc-item
function toggleTOCItem(expander, event = null) {
    let listItem = expander.closest(".toc-item");
    listItem.classList.toggle("expanded");
    let expanded = listItem.classList.contains("expanded");

    let groupName = listItem.querySelector(".toc-title-box").innerText;
    if(expanded) {
        expander.title = "Close " + groupName;
        expander.setAttribute("aria-expanded", "true");
    } else {
        expander.title = "Expand " + groupName;
        expander.setAttribute("aria-expanded", "false");
    }
    expander.setAttribute("aria-label", expander.title);

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

    // if opened by keyboard, focus on the first child item, if any
    if (expanded && expander === document.activeElement && event && event instanceof KeyboardEvent) {
        const firstChildItem = listItem.querySelector(":scope > ul.toc-item-list > li.toc-item");
        if (firstChildItem) {
            const firstChildLink = firstChildItem.querySelector("a");
            if (firstChildLink) {
                firstChildLink.focus();
            }
        }
    }
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
            expander.type = "button";
            expander.classList.add('toc-expander');
            expander.classList.add('toc-chevron-surround');
            expander.title = 'toc-expander';
            // content of span is set by CSS :before rule.
            expander.innerHTML = '<span class="icon material-symbols-outlined" aria-hidden="true"></span>';
            const subList = tocItem.querySelector('.toc-item-list');
            expander.controlledGroup = subList.id;
            expander.setAttribute('aria-controls', subList.id);
            expander.setAttribute("aria-expanded", "false");
            tocItem.querySelector(".toc-title-box").append(expander);
            expander.addEventListener('click', (e) => {
                toggleTOCItem(expander, e);
            });

            let isActive = tocItem.classList.contains("contains-active") || tocItem.classList.contains("active");
            let preExpanded = isActive || depth < preexpandedLevels;
            if(preExpanded) {
                toggleTOCItem(expander);
            } else {
                let groupName = tocItem.querySelector(".toc-title-box").innerText;
                expander.title = "Expand " + groupName;
                expander.setAttribute("aria-label", expander.title);
            }
        }
    }

    //Do we have a hash in the URL? If so, we need to identify up to make sure
    // all parents of that item are expanded
    if(window.location.hash) {
        let hash = window.location.hash;
        // find the link in the TOC that has an href ending in this hash
        let hashLink = document.querySelector(`.ptx-toc a[href$="${hash}"]`);
        if(hashLink) {
            let parentTocItem = hashLink.closest(".toc-item");
            while(parentTocItem && !parentTocItem.classList.contains("contains-active")) {
                parentTocItem.classList.add("contains-active");
                let expander = parentTocItem.querySelector(".toc-expander");
                if(expander) {
                    //make sure it is expanded
                    if(!parentTocItem.classList.contains("expanded")) {
                        toggleTOCItem(expander);
                    }
                }
                parentTocItem = parentTocItem.parentElement.closest(".toc-item");
            }
        }
    }

});

// This needs to be after the TOC's geometry is settled
window.addEventListener("DOMContentLoaded",function(event) {
    scrollTocToActive();
});

window.onhashchange = scrollTocToActive;
