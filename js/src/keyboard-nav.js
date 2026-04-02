/**
 * Keyboard navigation handlers.
 *
 * - ENTER in a `.workspace` triggers MathJax typesetting.
 * - ESC navigates back through Sage cell focus, then up the knowl stack,
 *   or does nothing if no interactive context is active.
 * - Hash-based anchor navigation: opens knowls linked via URL hash.
 */

let justHitEscape = false;

function processWorkspace() {
    if (typeof MathJax !== "undefined" && MathJax.typesetPromise) {
        MathJax.typesetPromise();
    }
}

export function initKeyboardNav() {
    document.onkeyup = function (event) {
        const e = event || window.event;
        switch (e.keyCode) {
            case 13: // ENTER
                justHitEscape = false;
                if (
                    document.activeElement.classList.contains("workspace")
                ) {
                    processWorkspace();
                }
                break; // Fixed: was missing, caused fallthrough to ESC handler

            case 27: // ESC
            {
                const parentSageCell =
                    document.activeElement.closest(".sagecell_editor");
                if (parentSageCell && !justHitEscape) {
                    justHitEscape = true;
                    setTimeout(function () {
                        justHitEscape = false;
                    }, 1000);
                }
                // knowl_focus_stack is defined in knowl.js and may not exist
                // in all contexts — guard against ReferenceError
                else if (
                    typeof knowl_focus_stack !== "undefined" &&
                    knowl_focus_stack.length > 0
                ) {
                    const mostRecentlyOpened = knowl_focus_stack.pop();
                    if (typeof knowl_focus_stack_uid !== "undefined") {
                        knowl_focus_stack_uid.pop();
                    }
                    mostRecentlyOpened.focus();
                } else {
                    break;
                }
                break;
            }
        }
    };
}

export function initAnchorKnowl() {
    if (!window.location.hash.length) return;

    const id = window.location.hash.substring(1);
    const anchor = document.getElementById(id);
    if (!anchor) return;

    if (anchor.tagName === "ARTICLE") {
        const containedKnowl = anchor.querySelector("a[data-knowl]");
        if (containedKnowl && containedKnowl.parentElement === anchor) {
            containedKnowl.click();
        }
    } else if (anchor.hasAttribute("data-knowl")) {
        anchor.click();
    } else {
        // If it is a hidden knowl, find the knowl and open it
        const hiddenContent = anchor.closest(".hidden-content");
        if (hiddenContent) {
            const refId = hiddenContent.id;
            const knowl = document.querySelector(
                '[data-refid="' + refId + '"]'
            );
            if (knowl) knowl.click();
        }
    }
}
