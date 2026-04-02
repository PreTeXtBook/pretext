/**
 * Image magnification (click-to-zoom).
 *
 * Clicking an eligible image creates a full-width popup; clicking the
 * popup dismisses it.  Uses event delegation on the document body.
 */

/**
 * Walk up from `el` through ancestors, collecting those that match `selector`.
 * Returns the *last* (outermost) match — equivalent to jQuery's
 * `.parents(selector).last()`.
 */
function outermostMatchingAncestor(el, selector) {
    let match = null;
    let current = el.parentElement;
    while (current) {
        if (current.matches(selector)) {
            match = current;
        }
        current = current.parentElement;
    }
    return match;
}

export function initImageMagnify() {
    const imgSelector =
        ".image-box > img:not(.draw_on_me):not(.mag_popup), " +
        ".sbspanel > img:not(.draw_on_me):not(.mag_popup), " +
        "figure > img:not(.draw_on_me):not(.mag_popup), " +
        "figure > div > img:not(.draw_on_me):not(.mag_popup)";

    // Click an image to magnify
    document.body.addEventListener("click", function (event) {
        const img = event.target.closest(imgSelector);
        if (!img) return;

        const container = document.createElement("div");
        container.setAttribute("style", "background:#fff;");
        container.setAttribute("class", "mag_popup_container");
        container.innerHTML =
            '<img src="' +
            img.src +
            '" style="width:100%" class="mag_popup"/>';

        let placement = outermostMatchingAncestor(
            img,
            ".image-box, .sbsrow, figure, li, .cols2 article:nth-of-type(2n)"
        );

        // For .cols2, even articles go inside the previous odd one
        if (placement && placement.tagName === "ARTICLE") {
            const prev = placement.previousElementSibling;
            if (prev) {
                placement = prev.firstElementChild || prev;
            }
        }

        if (placement) {
            placement.parentNode.insertBefore(container, placement);
        }
    });

    // Click the big image to dismiss it
    document.body.addEventListener("click", function (event) {
        if (event.target.classList.contains("mag_popup")) {
            event.target.parentNode.remove();
        }
    });
}
