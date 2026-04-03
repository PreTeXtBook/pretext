/**
 * Print-preview page creation and adjustment.
 *
 * Handles flattening paragraph sections, waiting for images,
 * adjusting pre-existing pages, and algorithmically creating
 * new page divisions for printout content.
 */

import {
    getElementTotalHeight,
    getElemWorkspaceHeight,
} from "./geometry.js";
import { setInitialWorkspaceHeights } from "./workspace.js";
import { findPageBreaks } from "./page-breaks.js";

export function flattenParagraphsSections(printout) {
    const paragraphsSections = printout.querySelectorAll(
        "section.paragraphs"
    );
    paragraphsSections.forEach((section) => {
        const parent = section.parentNode;
        while (section.firstChild) {
            parent.insertBefore(section.firstChild, section);
        }
        parent.removeChild(section);
    });
}

export function waitForImages(container, timeoutMs = 5000) {
    const images = container.querySelectorAll("img");
    const promises = [];
    for (const img of images) {
        if (!img.complete) {
            promises.push(
                new Promise((resolve) => {
                    img.addEventListener("load", resolve, { once: true });
                    img.addEventListener("error", resolve, { once: true });
                })
            );
        }
    }
    if (promises.length === 0) return Promise.resolve();
    return Promise.race([
        Promise.all(promises),
        new Promise((resolve) => setTimeout(resolve, timeoutMs)),
    ]);
}

export function adjustPrintoutPages() {
    const printout = document.querySelector(
        "section.worksheet, section.handout"
    );
    if (!printout) return;

    const pages = printout.querySelectorAll(".onepage");
    if (pages.length === 0) return;

    const firstPage = pages[0];
    const lastPage = pages[pages.length - 1];

    // Move all children before the first page into the first page
    const pageFirstChild = firstPage.firstChild;
    let currentChild = printout.firstChild;
    while (currentChild && currentChild !== firstPage) {
        const nextChild = currentChild.nextSibling;
        firstPage.insertBefore(currentChild, pageFirstChild);
        currentChild = nextChild;
    }

    // Move all children after the last page into the last page
    let nextChild = lastPage.nextSibling;
    while (nextChild) {
        const tempChild = nextChild;
        nextChild = nextChild.nextSibling;
        lastPage.appendChild(tempChild);
    }
}

export function createPrintoutPages(margins) {
    const conservativeContentHeight = 1056 - (margins.top + margins.bottom);
    const conservativeContentWidth = 794 - (margins.left + margins.right);

    const printout = document.querySelector(
        "section.worksheet, section.handout"
    );
    if (!printout) return;

    printout.style.width =
        (conservativeContentWidth + margins.left + margins.right).toString() +
        "px";
    setInitialWorkspaceHeights(printout);

    // Build list of blocks, handling sidebyside and tasks
    let rows = [];
    for (const child of printout.children) {
        if (child.classList.contains("sidebyside")) {
            rows.push(child);
        } else if (child.querySelector(".task")) {
            rows.push(child);
            const tasks = child.querySelectorAll(".task, .conclusion");

            for (let i = 0; i < tasks.length; i++) {
                let parent = tasks[i].parentElement;
                let grandparent = parent.parentElement;
                if (grandparent.classList.contains("task")) {
                    tasks[i].classList.add("subsubtask");
                } else if (parent.classList.contains("task")) {
                    tasks[i].classList.add("subtask");
                }
            }
            for (let i = tasks.length - 1; i > 0; i--) {
                printout.insertBefore(tasks[i], child.nextSibling);
            }
        } else {
            rows.push(child);
        }
    }

    // Build block list with height info
    let blockList = [];
    for (const row of rows) {
        let blockHeight = getElementTotalHeight(row);
        if (blockHeight === 0) continue;

        let totalWorkspaceHeight = 0;
        if (row.querySelector(".workspace")) {
            totalWorkspaceHeight = getElemWorkspaceHeight(row);
        }
        blockList.push({
            elem: row,
            height: blockHeight,
            workspaceHeight: totalWorkspaceHeight,
        });
    }

    const pageBreaks = findPageBreaks(blockList, conservativeContentHeight);

    // Create page divs
    for (let i = 0; i < pageBreaks.length; i++) {
        const pageDiv = document.createElement("section");
        pageDiv.classList.add("onepage");
        if (i === 0) pageDiv.classList.add("firstpage");
        if (i === pageBreaks.length - 1) pageDiv.classList.add("lastpage");

        const start = pageBreaks[i - 1] || 0;
        const end = pageBreaks[i];
        for (let j = start; j < end; j++) {
            pageDiv.appendChild(blockList[j].elem);
        }
        printout.appendChild(pageDiv);
    }

    // Remove content not in a page
    for (const child of Array.from(printout.children)) {
        if (!child.classList.contains("onepage")) {
            printout.removeChild(child);
        }
    }
}
