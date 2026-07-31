/*******************************************************************************
 * index.js — entry point for the pretext-read-aloud bundle
 *******************************************************************************
 * Feature-detects speechSynthesis, wires the toolbar button, and initializes
 * the player lazily on first press.  The XSL emits the markup and this
 * <script> only when the read-aloud publication option is enabled, so an
 * opted-out build ships zero read-aloud bytes.
 ******************************************************************************/

import { ReadAloudPlayer, continuationMode } from "./player-ui.js";
import { collect, readMathSpeech } from "./collector.js";
import { buildPlan, sentenceBoundaries } from "./segmenter.js";
import { SpeechQueue } from "./speech-queue.js";

window.addEventListener("DOMContentLoaded", () => {
    const button = document.getElementById("ptx-read-aloud-button");
    const playerElement = document.getElementById("ptx-read-aloud-player");
    if (!button || !playerElement) return;

    // No speech engine (or no voices ever): hide the feature entirely.
    if (!("speechSynthesis" in window)) {
        button.hidden = true;
        return;
    }

    let player = null;
    const ensurePlayer = () => {
        if (!player) {
            player = new ReadAloudPlayer(button, playerElement);
        }
        return player;
    };

    button.addEventListener("click", () => {
        const p = ensurePlayer();
        if (p.isOpen) {
            p.close();
        } else {
            p.open();
        }
    });

    // Cross-page continuation (decision #10): the previous page set a flag on
    // its way out.  Read the mode before open(), which clears the flag so a
    // later reload of this page is an ordinary visit.
    //
    //   "manual"  the reader clicked "Continue".  Browsers generally refuse
    //             speech without fresh user activation after navigation, so
    //             present the player open and ready — one click resumes.
    //   "auto"    the auto-continue setting is on, and the previous page
    //             finished by itself.  Try to start reading straight away;
    //             the player falls back to the "manual" presentation if the
    //             browser turns out to refuse.
    const continuation = continuationMode();
    if (continuation) {
        const p = ensurePlayer();
        p.open();
        playerElement.dataset.state = "continue-ready";
        if (continuation === "auto") p.resumeContinuation();
    }

    // Console access for debugging and by-ear experimentation during the
    // prototype phase: PTXReadAloud.speakPage() in devtools.
    window.PTXReadAloud = {
        collect,
        buildPlan,
        sentenceBoundaries,
        SpeechQueue,
        player: ensurePlayer,
        speakPage: () => ensurePlayer().playFromTop(),

        // Reports what MathJax actually produced for each expression, which
        // is the only way to tell a speech-generation problem apart from a
        // read-aloud one: if aria-label is null everywhere, the fault is in
        // MathJax's speech setup, not in this feature.
        debugMath: () => {
            const containers = document.querySelectorAll("mjx-container");
            console.log("MathJax version:", window.MathJax?.version);
            console.log("enableSpeech:", window.MathJax?.config?.options?.enableSpeech);
            console.log("sre options:", window.MathJax?.config?.options?.sre);
            console.log(`${containers.length} typeset expression(s):`);
            const inner = (el, attr) => {
                const node = el.querySelector(`[${attr}]`);
                return node && node.getAttribute(attr);
            };
            containers.forEach((el, i) => {
                console.log(i, {
                    resolved: readMathSpeech(el),
                    ownAriaLabel: el.getAttribute("aria-label"),
                    ownSemanticSpeech: el.getAttribute("data-semantic-speech"),
                    ownSpeechNone: el.getAttribute("data-semantic-speech-none"),
                    innerAriaLabel: inner(el, "aria-label"),
                    innerSemanticSpeech: inner(el, "data-semantic-speech"),
                    assistiveMml: !!el.querySelector("mjx-assistive-mml"),
                });
            });
        },
    };
});
