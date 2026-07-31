/*******************************************************************************
 * highlighter.js — sentence-level highlight + auto-scroll for read-aloud
 *******************************************************************************
 * Text spans are highlighted with the CSS Custom Highlight API
 * (::highlight(ptx-read-aloud) — no DOM mutation, so MathJax layout is never
 * disturbed).  Math is always highlighted by toggling a class on its
 * mjx-container: CHTML internals don't expose reliable text nodes for Range
 * highlighting.  Browsers without CSS.highlights (older Firefox) fall back to
 * a class on the whole block.
 *
 * Auto-scroll centers the current block, but a wheel/touch/keyboard scroll by
 * the reader suppresses it until the next explicit player action — the reader
 * looking elsewhere must always win over the machine.
 ******************************************************************************/

const HIGHLIGHT_NAME = "ptx-read-aloud";
const MATH_CLASS = "ptx-read-aloud-current-math";
const BLOCK_CLASS = "ptx-read-aloud-current-block";

export class Highlighter {
    constructor() {
        this.supportsRanges =
            typeof CSS !== "undefined" && "highlights" in CSS;
        this.markedElements = [];
        this.autoScroll = true;
        this.scrollSuppressed = false;

        // Any manual scroll gesture suppresses auto-scroll.
        for (const evt of ["wheel", "touchmove"]) {
            window.addEventListener(evt, () => {
                this.scrollSuppressed = true;
            }, { passive: true });
        }
    }

    /** Call from explicit player actions (play/skip/click-to-start). */
    resetScrollSuppression() {
        this.scrollSuppressed = false;
    }

    show(planItem, blocks) {
        this.clear();
        const block = blocks[planItem.blockIndex];
        if (!block) return;

        const ranges = [];
        for (const r of planItem.ranges) {
            const token = block.tokens[r.tokenIndex];
            if (!token) continue;
            if (token.kind === "math") {
                token.el.classList.add(MATH_CLASS);
                this.markedElements.push({ el: token.el, cls: MATH_CLASS });
            } else if (
                this.supportsRanges &&
                token.kind === "text" &&
                token.node &&
                token.node.isConnected
            ) {
                try {
                    const range = new Range();
                    range.setStart(token.node, r.start);
                    range.setEnd(token.node, r.end);
                    ranges.push(range);
                } catch (e) {
                    // Offsets can go stale if the DOM changed mid-read; the
                    // block-level fallback below still shows position.
                }
            }
        }

        if (this.supportsRanges && ranges.length) {
            CSS.highlights.set(HIGHLIGHT_NAME, new Highlight(...ranges));
        } else if (block.el && block.el.isConnected) {
            // No range support (or nothing rangeable): mark the whole block.
            block.el.classList.add(BLOCK_CLASS);
            this.markedElements.push({ el: block.el, cls: BLOCK_CLASS });
        }

        if (this.autoScroll && !this.scrollSuppressed) {
            const target =
                (block.el && block.el.isConnected && block.el) ||
                (ranges.length && ranges[0].startContainer.parentElement);
            if (target && typeof target.scrollIntoView === "function") {
                target.scrollIntoView({ block: "center", behavior: "smooth" });
            }
        }
    }

    clear() {
        if (this.supportsRanges) {
            CSS.highlights.delete(HIGHLIGHT_NAME);
        }
        for (const { el, cls } of this.markedElements) {
            el.classList.remove(cls);
        }
        this.markedElements = [];
    }
}
