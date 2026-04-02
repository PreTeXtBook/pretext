/**
 * TOC, sidebar, and navigation (from pretext.js).
 *
 * Manages the table-of-contents sidebar: scroll-to-active, toggle
 * visibility, auto-collapse, focused/expandable TOC items, and
 * hash-based navigation.
 */

function getOffsetTop(e) {
    if (!e) return 0;
    return getOffsetTop(e.offsetParent) + e.offsetTop;
}

function scrollTocToActive() {
    let fileNameWHash = window.location.href.split("/").pop();
    let fileName = fileNameWHash.split("#")[0];

    let tocEntry = document.querySelector(
        '#ptx-toc a[href="' + fileName + '"]'
    );
    if (!tocEntry) return;

    let tocEntryTop = 0;
    if (fileNameWHash.includes("#")) {
        let tocEntryWHash = document.querySelector(
            '#ptx-toc a[href="' + fileNameWHash + '"]'
        );
        if (tocEntryWHash) {
            tocEntry
                .closest("li")
                .querySelectorAll("li")
                .forEach((li) => {
                    li.classList.remove("active");
                });
            tocEntryWHash.closest("li").classList.add("active");
            tocEntryTop = getOffsetTop(tocEntryWHash);
        }
    }
    if (!tocEntryTop) {
        tocEntryTop = getOffsetTop(tocEntry);
    }

    tocEntry.closest("li").classList.add("active");
    let toc = document.querySelector("#ptx-toc");
    let tocTop = getOffsetTop(toc);
    toc.scrollTop = tocEntryTop - tocTop - 0.4 * self.innerHeight;
}

function toggletoc() {
    const thesidebar = document.getElementById("ptx-sidebar");
    if (
        thesidebar.classList.contains("hidden") ||
        thesidebar.classList.contains("visible")
    ) {
        thesidebar.classList.toggle("hidden");
        thesidebar.classList.toggle("visible");
    } else if (thesidebar.offsetParent === null) {
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
        return false;
    }
}

function getTOCItemType(item) {
    for (let className of item.classList) {
        if (
            className !== "toc-item" &&
            className.length > 3 &&
            className.slice(0, 4) === "toc-"
        )
            return className.slice(4);
    }
    return "";
}

function getTOCItemDepth(item) {
    let depth = 0;
    let curParent = item.closest(".toc-item-list");
    while (curParent !== null) {
        depth++;
        curParent = curParent.parentElement.closest(".toc-item-list");
    }
    return depth;
}

function toggleTOCItem(expander) {
    let listItem = expander.closest(".toc-item");
    listItem.classList.toggle("expanded");
    let expanded = listItem.classList.contains("expanded");
    let itemType = getTOCItemType(listItem);

    if (expanded) {
        expander.title = "Close" + (itemType !== "" ? " " + itemType : "");
    } else {
        expander.title = "Expand" + (itemType !== "" ? " " + itemType : "");
    }

    for (const childUL of listItem.querySelectorAll(
        ":scope > ul.toc-item-list"
    )) {
        for (const childItem of childUL.querySelectorAll(
            ":scope > li.toc-item"
        )) {
            if (expanded) {
                childItem.classList.add("visible");
                childItem.classList.remove("hidden");
            } else {
                childItem.classList.remove("visible");
                childItem.classList.add("hidden");
            }
        }
    }
}

export function initToc() {
    const thetocbutton = document.getElementsByClassName("toc-toggle")[0];
    if (thetocbutton) {
        thetocbutton.addEventListener("click", (e) => {
            toggletoc();
            e.stopPropagation();
        });
    }

    // Auto-collapse TOC when clicking outside
    if (
        getComputedStyle(document.documentElement).getPropertyValue(
            "--auto-collapse-toc"
        ) == "yes"
    ) {
        const sidebar = document.getElementById("ptx-sidebar");

        window.addEventListener("click", function (event) {
            if (sidebar.classList.contains("visible")) {
                if (!event.composedPath().includes(sidebar)) {
                    toggletoc();
                }
            }
        });

        sidebar.addEventListener("click", function (event) {
            if (samePageLink(event.target.closest("a"))) {
                toggletoc();
            }
        });

        window.addEventListener("pageshow", (e) => {
            if (e.persisted) {
                sidebar.classList.remove("visible");
                sidebar.classList.add("hidden");
            }
        });
    }
}

export function initFocusedToc() {
    if (document.querySelector(".ptx-toc.focused") === null) return;

    let maxDepth = 1000;
    for (let className of document.querySelector(".ptx-toc").classList)
        if (className.length > 5 && className.slice(0, 5) === "depth")
            maxDepth = Number(className.slice(5));

    let preexpandedLevels = 1;
    let tocDataSet = document.querySelector(".ptx-toc").dataset;
    if (typeof tocDataSet.preexpandedLevels !== "undefined")
        preexpandedLevels = Number(tocDataSet.preexpandedLevels);

    let tocItems = document.querySelectorAll(
        ".ptx-toc ul.structural > .toc-item"
    );
    for (const tocItem of tocItems) {
        let hasChildren =
            tocItem.querySelector("ul.structural") !== null;
        let depth = getTOCItemDepth(tocItem);

        if (hasChildren && depth < maxDepth) {
            let expander = document.createElement("button");
            expander.classList.add("toc-expander");
            expander.classList.add("toc-chevron-surround");
            expander.title = "toc-expander";
            expander.innerHTML =
                '<span class="icon material-symbols-outlined" aria-hidden="true"></span>';
            tocItem.querySelector(".toc-title-box").append(expander);
            expander.addEventListener("click", () => {
                toggleTOCItem(expander);
            });

            let isActive =
                tocItem.classList.contains("contains-active") ||
                tocItem.classList.contains("active");
            let preExpanded = isActive || depth < preexpandedLevels;
            let itemType = getTOCItemType(tocItem);
            if (preExpanded) {
                toggleTOCItem(expander);
            } else {
                expander.title =
                    "Expand" + (itemType !== "" ? " " + itemType : "");
            }
        }
    }

    // Expand parents of hash-linked TOC item
    if (window.location.hash) {
        let hash = window.location.hash;
        let hashLink = document.querySelector(
            `.ptx-toc a[href$="${hash}"]`
        );
        if (hashLink) {
            let parentTocItem = hashLink.closest(".toc-item");
            while (
                parentTocItem &&
                !parentTocItem.classList.contains("contains-active")
            ) {
                parentTocItem.classList.add("contains-active");
                let expander =
                    parentTocItem.querySelector(".toc-expander");
                if (expander) {
                    if (!parentTocItem.classList.contains("expanded")) {
                        toggleTOCItem(expander);
                    }
                }
                parentTocItem =
                    parentTocItem.parentElement.closest(".toc-item");
            }
        }
    }
}

export function initScrollToc() {
    scrollTocToActive();
    window.onhashchange = scrollTocToActive;
}
