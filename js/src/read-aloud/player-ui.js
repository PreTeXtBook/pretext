/*******************************************************************************
 * player-ui.js — in-navbar player, click-to-start, MediaSession, continue flow
 *******************************************************************************
 * The markup (button #ptx-read-aloud-button, player #ptx-read-aloud-player)
 * is emitted by the XSL only when the publication option is on.  Words this
 * file speaks or writes into tooltips come from strings.js; the XSL's own
 * labels are literal text there.  Read-aloud is HTML-only, so neither side
 * goes through xsl/localizations.
 *
 * DOM contract with the XSL:
 *   #ptx-read-aloud-button     toolbar button; a disclosure toggle for the
 *                              player, and the only way to dismiss it
 *   #ptx-read-aloud-player     navbar strip; data-state attr drives CSS
 *     #ptx-read-aloud-prev / -toggle / -next            control buttons
 *     #ptx-read-aloud-continue                          next-section link
 *     #ptx-read-aloud-settings-button                   opens the dialog below
 *   #ptx-read-aloud-settings-popup   voice / rate / asides / auto-scroll /
 *                                    auto-continue
 *     #ptx-read-aloud-settings-close-button
 ******************************************************************************/

import { collect } from "./collector.js";
import { buildPlan } from "./segmenter.js";
import { SpeechQueue } from "./speech-queue.js";
import { Highlighter } from "./highlighter.js";
import { enclosingBlock } from "./navigation.js";
import { STRINGS } from "./strings.js";
import {
    initSettingsControls,
    getSavedVoice,
    getSavedRate,
    getSavedAutoScroll,
    getSavedAutoContinue,
    getSavedAsideMode,
    whenVoicesReady,
    documentLang,
} from "./settings.js";

// Set as one page hands off to the next.  Two values, because the next page
// has to behave differently: "true" is the reader clicking Continue, which
// only asks for a player ready to play; "auto" is the auto-continue setting,
// which asks the new page to start reading by itself if the browser lets it.
const CONTINUE_FLAG = "ptxReadAloudContinue";
const CONTINUE_AUTO = "auto";

// How long to let a continued page prove it is actually speaking before
// giving up and asking for a click.  Generous, because the first utterance
// on a fresh page can wait on voice loading; a browser that refuses outright
// usually fires its error well inside this.
const AUTOPLAY_GRACE_MS = 3000;

// How many times to explain the open key before trusting the reader to know.
const OPEN_HINT_KEY = "readAloudOpenHintShown";
const OPEN_HINT_LIMIT = 3;

// Clicks on (or inside) these are navigation/interaction, not click-to-start.
const INTERACTIVE_SELECTOR =
    "a, button, input, select, textarea, summary, label, iframe, " +
    "audio, video, [data-knowl], .knowl__link, .sagecell";

export class ReadAloudPlayer {
    constructor(button, player) {
        this.button = button;
        this.player = player;
        this.strings = STRINGS;
        this.content = document.getElementById("ptx-content");
        this.blocks = [];
        // Whether the current reading has produced any actual sound.  Guards
        // both auto-continue and the autoplay fallback; see _shouldAutoContinue.
        this.hasSpoken = false;

        this.highlighter = new Highlighter();
        this.highlighter.autoScroll = getSavedAutoScroll();

        this.queue = new SpeechQueue({
            onUtterance: (i, item) => this._onUtterance(i, item),
            onState: (state) => this._onState(state),
            onEnded: () => this._onEnded(),
            mode: getSavedAsideMode(),
            describeBlock: (blockIndex) => this._describeBlock(blockIndex),
        });
        this.queue.setLang(documentLang());

        initSettingsControls(({ voice, rate, autoScroll, asideMode }) => {
            this.queue.setVoice(voice);
            this.queue.setRate(rate);
            // Takes effect at the next block boundary — no recollection, so
            // the listener can change their mind mid-page.
            this.queue.setMode(asideMode);
            this.highlighter.autoScroll = autoScroll;
        });

        this._wireControls();
        this._wireSettingsDialog();
        this._wireClickToStart();
        this._wireMediaSession();
    }

    /**
     * The settings dialog, opened from the player's own settings button.
     *
     * These controls used to sit in the readability-options dialog, but they
     * are only meaningful while something is being read, and burying them
     * behind a general typography menu made them hard to find at the moment
     * they mattered.  PTXDialog comes from pretext-core.js, which the XSL
     * always loads first; guard anyway so a missing bundle costs the settings
     * button rather than the whole player.
     */
    _wireSettingsDialog() {
        const popup = document.getElementById("ptx-read-aloud-settings-popup");
        const button = document.getElementById("ptx-read-aloud-settings-button");
        if (!popup || !button || !window.PTXDialog) return;
        this.settingsPopup = popup;
        // "light-close": a click anywhere outside dismisses it.  Settings are
        // a detour from listening, so getting back should not require aiming
        // at the close button.
        this.settingsDialog = new window.PTXDialog(popup, button, {
            kind: "light-close",
            closeButton: document.getElementById(
                "ptx-read-aloud-settings-close-button"
            ),
        });
    }

    //------------------------------------------------------------------
    // Opening and closing

    open() {
        this.player.hidden = false;
        this._setButtonState(true);
        // Continuation from the previous page (decision #10): don't fight
        // the browser's activation rules — present a ready-to-play player.
        sessionStorage.removeItem(CONTINUE_FLAG);
    }

    close() {
        this.queue.stop();
        this.highlighter.clear();
        // The settings dialog belongs to the player; leaving it open over a
        // navbar that no longer shows a player is orphaned UI.  Only when it
        // is actually open — PTXDialog.close() also moves focus to its own
        // trigger, which would yank focus on every ordinary player close.
        if (this.settingsPopup && this.settingsPopup.open) {
            this.settingsDialog.close();
        }
        // Hand focus back before hiding, but only if it is ours to hand back:
        // closing the settings dialog above leaves focus on its trigger,
        // which is inside the player and about to disappear.
        const focusWasInside = this.player.contains(document.activeElement);
        this.player.hidden = true;
        this._setButtonState(false);
        if (focusWasInside) this.button.focus();
        if (navigator.mediaSession) {
            navigator.mediaSession.playbackState = "none";
        }
    }

    /**
     * Keep the toolbar button reading as the disclosure toggle it now is.
     *
     * With the player's own close button gone, this button is the only way
     * back, so its tooltip has to name the action rather than the feature —
     * "Read aloud" on a control that hides the read-aloud player is worse
     * than no tooltip at all.
     */
    _setButtonState(open) {
        this.button.setAttribute("aria-expanded", String(open));
        const title = open
            ? this.strings["read-aloud-hide"]
            : this.strings["read-aloud-show"];
        if (title) this.button.title = title;
    }

    get isOpen() {
        return !this.player.hidden;
    }

    //------------------------------------------------------------------
    // Playback

    async _ensurePlan() {
        // Collect from the live DOM so opened knowls are included.  (collect
        // waits for MathJax itself: an untypeset page has no math to find.)
        this.blocks = await collect(this.content, { strings: this.strings });
        const plan = buildPlan(this.blocks, {
            locale: documentLang(),
            strings: this.strings,
        });
        // The engine reports no voices until it is ready, and an unset voice
        // silently means "system default" — so asking too early discards the
        // reader's saved choice without any error to notice.
        await whenVoicesReady();
        this.queue.setVoice(getSavedVoice());
        this.queue.setRate(getSavedRate());
        this.queue.setPlan(plan, this.blocks);
    }

    async playFromTop() {
        this.highlighter.resetScrollSuppression();
        // Reset per-reading, not per-page: it answers "did this run actually
        // produce sound?", which is what both the autoplay watchdog and the
        // auto-continue guard need.
        this.hasSpoken = false;
        await this._ensurePlan();
        this.queue.playFrom(0);
    }

    /**
     * Start a page that the previous one handed off to via auto-continue.
     *
     * Speech is gated behind user activation in Chrome and Safari, and
     * whether a navigation carries that activation into the new document
     * varies by browser and by how the navigation was made — so this tries,
     * and is built to be refused.  If nothing has actually spoken by the end
     * of the grace period, it drops into exactly the state the manual
     * Continue link produces: player open, play button pulsing, one click
     * away from reading.  The listener is never left in silence with no
     * visible next step.
     */
    async resumeContinuation() {
        await this.playFromTop();
        setTimeout(() => {
            if (this.hasSpoken) return;
            this.queue.stop();
            this.highlighter.clear();
            this.player.dataset.state = "continue-ready";
        }, AUTOPLAY_GRACE_MS);
    }

    async toggle() {
        this.highlighter.resetScrollSuppression();
        if (this.queue.state === "idle" || this.queue.state === "ended") {
            await this.playFromTop();
        } else {
            this.queue.toggle();
        }
    }

    //------------------------------------------------------------------
    // Queue callbacks

    _onUtterance(index, item) {
        this.hasSpoken = true;
        this._reveal(this.blocks[item.blockIndex]);
        this.highlighter.show(item, this.blocks);
    }

    /**
     * Open any collapsed <details> around the block about to be spoken.
     *
     * Collection deliberately reaches inside closed knowls, so playback can
     * arrive somewhere the reader cannot see.  Opening on arrival keeps the
     * page in step with the audio — and the highlighter needs the text
     * rendered to highlight it at all.
     *
     * A title is the exception: reading "Theorem 3.2" is not a reason to
     * expand the theorem, since in skip mode the body is never read and a
     * sighted reader would still be looking at a closed knowl.
     */
    _reveal(block) {
        if (!block || !block.el) return;
        let details = block.el.closest("details");
        // Skip the aside this title belongs to; ancestors still open, so a
        // knowl nested in an opened knowl stays visible.
        if (block.summary && details) {
            details = details.parentElement
                ? details.parentElement.closest("details")
                : null;
        }
        while (details) {
            if (!details.open) details.open = true;
            details = details.parentElement
                ? details.parentElement.closest("details")
                : null;
        }
    }

    /**
     * What kind of block the arrow keys have landed on, for the spoken
     * announcement.  PreTeXt already renders localized type names into the
     * page — in a knowl's heading and in every permalink's @data-description
     * — so they are read back out of the DOM rather than duplicated as new
     * localization strings that could drift out of step.
     */
    _describeBlock(blockIndex) {
        const block = this.blocks[blockIndex];
        if (!block || !block.el) return null;
        const node = enclosingBlock(this.blocks, blockIndex);

        // A title names its block; anything else names *itself*.  Without the
        // split, every paragraph of a proof announces as "Proof" — the block
        // it happens to sit in rather than what the listener landed on.
        const name = block.summary
            ? this._typeName(node)
            : this._selfName(block) || this._typeName(node);
        if (!name) return null;

        const hint = this._openableAside(blockIndex) ? this._openHint() : null;
        return hint ? `${name} ${hint}` : name;
    }

    /** The type name PreTeXt rendered for a node, e.g. "Theorem", "Proof.". */
    _typeName(node) {
        if (!node || !node.el || !node.el.querySelector) return null;
        const typeSpan = node.el.querySelector(
            ":scope > summary .type, :scope > .heading .type, " +
            ":scope > h1 .type, :scope > h2 .type, :scope > h3 .type, " +
            ":scope > h4 .type, :scope > h5 .type, :scope > h6 .type"
        );
        const name = typeSpan && typeSpan.textContent.trim();
        if (name) return name;

        // A footnote's name *and number* are in its tooltip ("Footnote 3.1"),
        // which beats the bare "Footnote" below: on a page of footnotes the
        // number is the only thing telling one announcement from the next.
        // Read only the footnote's tooltip — an image description's says the
        // untranslated literal "details".
        const tooltip = node.el.querySelector(
            ":scope > summary.ptx-footnote__number[title]"
        );
        if (tooltip) {
            const label = tooltip.getAttribute("title").trim();
            if (label) return label;
        }

        // Footnotes and image descriptions render no type name at all — just
        // a superscript number or an icon — so they are the two blocks whose
        // names have to be supplied rather than read back out of the page.
        return this.strings[node.type] || null;
    }

    /** What a non-title block calls itself, from its own permalink. */
    _selfName(block) {
        if (!block.el.querySelector) return null;
        const permalink = block.el.querySelector(":scope > [data-description]");
        return (permalink && permalink.getAttribute("data-description")) || null;
    }

    /** The aside this block titles, if it is one and it is still closed. */
    _openableAside(blockIndex) {
        const block = this.blocks[blockIndex];
        if (!block || !block.summary) return null;
        const asides = block.path.filter((n) => n.aside);
        const own = asides[asides.length - 1];
        return own && !this.queue.entered.has(own.el) ? own : null;
    }

    /**
     * "Press space to open", for the first few knowls a reader meets.
     *
     * An audio interface has no affordances to look at, so the only way to
     * learn the key is to be told — but being told every time, on a page with
     * forty knowls, is unbearable.  The count persists across pages so the
     * hint fades over a session rather than restarting with every navigation.
     */
    _openHint() {
        const hint = this.strings["read-aloud-open-hint"];
        if (!hint) return null;
        const shown = Number(localStorage.getItem(OPEN_HINT_KEY)) || 0;
        if (shown >= OPEN_HINT_LIMIT) return null;
        localStorage.setItem(OPEN_HINT_KEY, String(shown + 1));
        return hint;
    }

    _onState(state) {
        this.player.dataset.state = state;
        const toggleButton = document.getElementById("ptx-read-aloud-toggle");
        if (toggleButton) {
            const speaking = state === "speaking";
            toggleButton.title = speaking
                ? this.strings["read-aloud-pause"]
                : this.strings["read-aloud-play"];
            toggleButton.setAttribute("aria-pressed", String(speaking));
        }
        if (navigator.mediaSession) {
            navigator.mediaSession.playbackState =
                state === "speaking" ? "playing"
                : state === "paused" ? "paused"
                : "none";
        }
    }

    /** Where the page's own "next" navigation button points, or null. */
    _nextPageHref() {
        const nextLink = document.querySelector(".next-button:not(.disabled)");
        const href = nextLink && nextLink.getAttribute("href");
        return href || null;
    }

    /**
     * May the reading carry itself on to the next page?
     *
     * The setting is necessary but not sufficient.  `hasSpoken` is the guard
     * that matters: an engine that refuses to speak reports an error per
     * utterance, and the queue's own error handling would otherwise reach
     * this same "finished the page" callback in a few milliseconds without a
     * word having been heard.  Auto-continuing from there would do it again
     * on the next page, and the one after — a silent runaway through the
     * whole book.  Requiring that something was actually spoken keeps a
     * refused page from ever handing off.
     */
    _shouldAutoContinue() {
        return getSavedAutoContinue() && this.hasSpoken;
    }

    _onEnded() {
        this.highlighter.clear();
        const href = this._nextPageHref();
        if (!href) return;

        // Offer the manual link either way: if auto-continue is refused or
        // the announcement is cut short, this is the fallback in place.
        const continueLink = document.getElementById("ptx-read-aloud-continue");
        if (continueLink) {
            continueLink.href = href;
            continueLink.hidden = false;
        }

        if (this._shouldAutoContinue()) {
            sessionStorage.setItem(CONTINUE_FLAG, CONTINUE_AUTO);
            this.queue.speakOnce(this.strings["read-aloud-continuing"], () => {
                window.location.href = href;
            });
        }
    }

    //------------------------------------------------------------------
    // Wiring

    _wireControls() {
        const on = (id, handler) => {
            const el = document.getElementById(id);
            if (el) el.addEventListener("click", handler);
        };
        on("ptx-read-aloud-toggle", () => this.toggle());
        on("ptx-read-aloud-next", () => {
            this.highlighter.resetScrollSuppression();
            this.queue.next();
        });
        on("ptx-read-aloud-prev", () => {
            this.highlighter.resetScrollSuppression();
            this.queue.prev();
        });

        const continueLink = document.getElementById("ptx-read-aloud-continue");
        if (continueLink) {
            continueLink.addEventListener("click", () => {
                // Ask the next page to present the player ready to play.
                sessionStorage.setItem(CONTINUE_FLAG, "true");
            });
        }

        // Two axes: horizontal moves along the reading line, vertical moves
        // through the document tree.  Horizontal works whenever the player has
        // focus; vertical is bound document-wide, since the whole point is to
        // steer asides while listening rather than while pointing at buttons.
        this.player.addEventListener("keydown", (e) => {
            if (e.key === "ArrowRight") {
                e.preventDefault();
                this.queue.next();
            } else if (e.key === "ArrowLeft") {
                e.preventDefault();
                this.queue.prev();
            }
        });

        document.addEventListener("keydown", (e) => {
            // Only while actually reading, or the page cannot be scrolled and
            // arrow keys are stolen from every form control on it.
            if (this.queue.state !== "speaking" && this.queue.state !== "paused") {
                return;
            }
            if (e.altKey || e.ctrlKey || e.metaKey) return;
            if (e.target.closest("input, textarea, select, [contenteditable]")) {
                return;
            }
            if (e.key === "ArrowDown") {
                e.preventDefault();
                this.queue.nextBlock();
            } else if (e.key === "ArrowUp") {
                e.preventDefault();
                this.queue.previousBlock();
            } else if (e.key === " " || e.key === "ArrowRight") {
                // Accept the block the arrow keys landed on and read it.
                if (this.queue.pendingStart) {
                    e.preventDefault();
                    this.queue.resume();
                }
            }
        });
    }

    _wireClickToStart() {
        if (!this.content) return;
        this.content.addEventListener("click", (e) => {
            if (!this.isOpen) return;
            if (e.target.closest(INTERACTIVE_SELECTOR)) return;
            // Find the deepest collected block containing the click.
            let blockIndex = -1;
            this.blocks.forEach((b, i) => {
                if (b.el && b.el.contains(e.target)) blockIndex = i;
            });
            if (blockIndex < 0) return;
            const planIndex = this._planIndexForClick(blockIndex, e.target);
            if (planIndex >= 0) {
                this.highlighter.resetScrollSuppression();
                this.queue.playFrom(planIndex);
            }
        });
    }

    /**
     * The utterance a click landed on, falling back to the head of the block.
     *
     * Clicking the fourth sentence of a paragraph should start there, not
     * restart the paragraph, so this matches the clicked text node against
     * the plan's range map (segmenter.js keeps ranges pointing at the
     * original DOM text nodes precisely so this is possible).
     */
    _planIndexForClick(blockIndex, target) {
        const block = this.blocks[blockIndex];
        const fallback = this.queue.indexForBlock(blockIndex);
        if (!block || !target) return fallback;

        // The clicked text nodes, in the element the reader actually hit.
        const clicked = new Set();
        const walk = (el) => {
            for (const child of el.childNodes) {
                if (child.nodeType === Node.TEXT_NODE) clicked.add(child);
                else if (child.nodeType === Node.ELEMENT_NODE) walk(child);
            }
        };
        if (target.nodeType === Node.ELEMENT_NODE) walk(target);

        for (let i = 0; i < this.queue.plan.length; i++) {
            const item = this.queue.plan[i];
            if (item.blockIndex !== blockIndex) continue;
            for (const range of item.ranges) {
                const token = block.tokens[range.tokenIndex];
                if (!token) continue;
                if (token.node && clicked.has(token.node)) return i;
                if (token.el && (token.el === target || token.el.contains(target))) {
                    return i;
                }
            }
        }
        return fallback;
    }

    _wireMediaSession() {
        if (!("mediaSession" in navigator)) return;
        try {
            navigator.mediaSession.metadata = new MediaMetadata({
                title: document.title,
            });
            navigator.mediaSession.setActionHandler("play", () => this.toggle());
            navigator.mediaSession.setActionHandler("pause", () => this.queue.pause());
            navigator.mediaSession.setActionHandler("previoustrack", () => this.queue.prev());
            navigator.mediaSession.setActionHandler("nexttrack", () => this.queue.next());
        } catch (e) {
            // MediaSession is progressive enhancement; never let it break playback.
        }
    }
}

/**
 * How the previous page's reading session asked this one to carry on:
 * "auto" to start reading unprompted, "manual" to present a ready player,
 * or null when the reader simply navigated here themselves.
 */
export function continuationMode() {
    const flag = sessionStorage.getItem(CONTINUE_FLAG);
    if (flag === CONTINUE_AUTO) return "auto";
    return flag === "true" ? "manual" : null;
}
