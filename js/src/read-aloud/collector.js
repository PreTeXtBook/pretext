/*******************************************************************************
 * collector.js — live DOM → IR stage of the read-aloud pipeline
 *******************************************************************************
 * Walks the main content region at *play time* and emits the intermediate
 * representation consumed by segmenter.js (see that file for the IR shape).
 * Because collection happens at play time, content revealed since page load
 * (opened knowls, unfolded solutions) is naturally included, and content
 * still hidden is naturally excluded.
 *
 * Content policy (decision #6 in the design doc): read what a sighted reader
 * would read aloud — headings, paragraphs, lists, display math, captions,
 * image alt text; announce-and-skip tables, code, and interactives; silently
 * skip anything hidden, including screen-reader-only text (read-aloud mimics
 * *visual* reading, so e.g. the assistive watermark is skipped).
 *
 * An interactive *exercise* is the one place that policy needs care.  A
 * Runestone component is not a black box like a video: its prompt and its
 * answer choices are prose, and skipping the whole widget threw away the
 * question along with the machinery.  So a component that Runestone has
 * finished building is entered — prose read, controls skipped, kind announced
 * first — while one it has not yet built is still announced and skipped,
 * because the authoring markup underneath holds the answers.
 *
 * Two exceptions to "hidden means skipped", both about <details>: content
 * inside a *closed* one is collected anyway, and each block records its
 * ancestry in the document tree.  Together those let the listener navigate
 * asides (see navigation.js) without re-collecting or re-fetching anything.
 * Collection is complete and static; the listening mode governs traversal,
 * and opening a <details> is a presentation side effect of arriving there.
 ******************************************************************************/

import { nodeDescriptor } from "./nodes.js";

// Blocks announced-and-skipped rather than read.  Order matters: the first
// matching selector wins, so put more specific selectors first.
const ANNOUNCE_SELECTORS = [
    { selector: ".table-like, table", stringId: "read-aloud-skip-table" },
    {
        selector:
            "pre, .code-box, .program, .console, .sage, .sagecell-practice, " +
            // Runestone's two code surfaces: the ActiveCode editor and the
            // scrambled blocks of a Parsons problem.  Both are code, and the
            // Parsons blocks are in a deliberately wrong order besides.
            ".ac_code_div, .sortable-code-container",
        stringId: "read-aloud-skip-code",
    },
    {
        selector:
            "iframe, audio, video, .video-box, .jxgbox, " +
            ".interactive-iframe-container, .exercise-interactive",
        stringId: "read-aloud-skip-interactive",
    },
];

// A Runestone component: an interactive exercise whose prompt and answer
// choices are ordinary prose worth reading, wrapped around machinery that is
// not.  PreTeXt emits the container; Runestone's own JavaScript rewrites what
// is inside it at page load and marks the result "ready".
const RUNESTONE_SELECTOR = ".ptx-runestone-container, .runestone";
const RUNESTONE_READY = ".runestone-component-ready";
const RUNESTONE_CAPTION = ".runestone_caption";

// Before Runestone rewrites it, a component is still the authoring markup:
// for a multiple-choice question that means every wrong answer *and its
// feedback*, in the DOM, waiting to be read out.  So an unrewritten component
// is announced and skipped, exactly as the whole category used to be.
const RUNESTONE_UNBUILT = "[data-component]";

// Machinery inside a rendered component.  A listener cannot press a button or
// fill a box by ear, and the labels on them ("Check me", "Reset") are chrome
// rather than content.  The caption is spoken up front instead (see
// runestoneKind), and PreTeXt's CSS hides it anyway.
const RUNESTONE_CONTROL_SELECTOR = [
    "button",
    "input",
    "textarea",
    "select",
    // ActiveCode's toolbar, whose history slider reads out as "Original - 1
    // of 1" — a control's state, not anything the exercise says.
    ".ac_actions",
    RUNESTONE_CAPTION,
].join(", ");

// Elements never entered at all: invisible-to-the-eye content, chrome, and
// duplicated assistive text.
const SKIP_SELECTOR = [
    "[aria-hidden='true']",
    "[hidden]",
    ".hidden-content",
    ".autopermalink",
    // Material Symbols draw their glyph from the element's *text*, so an icon
    // is literally the word "content_copy" or "expand_more" in the DOM.  Most
    // are marked aria-hidden already; the copy-code button's is not, and read
    // out as "content copy" beside every program listing.
    ".material-symbols-outlined",
    "mjx-assistive-mml",
    "script",
    "style",
    "noscript",
    ".ptx-content-footer",
    ".instructions", // WW instructor-only material
    // Runestone's drag-and-drop parks one off-screen live region per card
    // ("Incorrect drop zone for Monroe Doctrine") at the end of the page.
    // Positioned rather than hidden, so checkVisibility() reports it visible
    // and only naming it keeps it out of the reading.
    ".vh-dnd-error",
].join(", ");

// Elements whose children form their own paragraph-level blocks.  Reaching
// one of these flushes the inline token run in progress.
const CONTAINER_SELECTOR = [
    "div.para",
    "section",
    "article",
    "ul",
    "ol",
    "dl",
    "li",
    "dt",
    "dd",
    "blockquote",
    "figure",
    "details",
    // A <summary> must end its block, or an aside whose body is not itself a
    // block element (a footnote's contents div) gets appended to the title's
    // block and inherits its always-spoken status.
    "summary",
    ".exercise-statement",
    ".knowl__content",
    ".ptx-runestone-container",
    // Runestone writes real <p> for the prose it generates, where PreTeXt
    // uses div.para; without this every choice of a multiple-choice question
    // runs into the next as one block.  PreTeXt's own <p> (author bylines)
    // are standalone blocks too, so nothing else changes.
    "p",
    // One block per answer: a choice, a card to drag, a drop target.  Kept
    // separate so a listener hears them apart and can step between them.
    "label",
    "legend",
    ".draggable-drag",
    ".draggable-drop",
    ".matching-workspace .box",
].join(", ");

// Leaf-ish elements that start a fresh text block of their own.
const HEADING_SELECTOR = "h1, h2, h3, h4, h5, h6, figcaption, caption";

// Media elements carry no text but are certainly content, so they are never
// judged empty; anything else with no text in it has nothing to announce.
const MEDIA_SELECTOR = "img, svg, canvas, iframe, video, audio, object, embed";

export function isEmptyOfContent(el) {
    if (el.textContent.trim() !== "") return false;
    return !el.matches(MEDIA_SELECTOR) && !el.querySelector(MEDIA_SELECTOR);
}

/**
 * The child nodes of `el` in the order they should be *heard*.
 *
 * PreTeXt sets a figure's caption below the thing it captions, which is right
 * for the eye: a reader takes in the picture first and then reads what it was.
 * Heard in that order it inverts, because a listener has no picture to take
 * in — the alt text arrives with nothing yet to attach it to, and the caption
 * that would have framed it lands only once the description is over.  So a
 * caption is spoken ahead of its figure's contents wherever it sits in the
 * document.  Captions PreTeXt already places on top (tables, listings, named
 * lists) are untouched, since hoisting a first child moves nothing.
 */
export function readingOrder(el) {
    const children = Array.from(el.childNodes);
    // Direct child only: each panel of a "sidebyside" is its own figure with
    // its own caption, and those belong to the panels rather than the whole.
    const caption = el.querySelector(":scope > figcaption");
    if (!caption) return children;
    return [caption, ...children.filter((child) => child !== caption)];
}

/**
 * Name the kind of component `el` is, for the announcement that precedes it.
 *
 * Runestone labels each rendered component with its own name for it —
 * "Multiple Choice", "Fill in the Blank", "Drag-N-Drop", "Parsons" — so that
 * name is read back out of the page rather than duplicated here as a table of
 * component classes that would drift as Runestone grows new ones.  Components
 * that render no caption fall back to the generic announcement.
 */
export function runestoneKind(el, strings = {}) {
    const caption = el.querySelector(RUNESTONE_CAPTION);
    const name = caption && caption.textContent.trim().replace(/\s+/g, " ");
    if (!name) return strings["read-aloud-interactive"] || null;
    const template = strings["read-aloud-interactive-kind"];
    return template ? template.replace("{kind}", name) : name;
}

function isElementVisible(el) {
    if (typeof el.checkVisibility === "function") {
        return el.checkVisibility();
    }
    // Fallback for browsers without checkVisibility (Safari < 17.4)
    return !!(el.offsetParent || el.getClientRects().length);
}

// SRE builds its speech for screen readers, which identify the expression as
// a math region by appending the word "math".  Spliced into a spoken
// sentence that marker just interrupts the prose — "f of x equals x squared,
// math, which opens upward" — so drop it.  Never strip it down to nothing:
// an expression whose entire speech is "math" keeps that word.
const MATH_REGION_MARKER = /[,;.]?\s*\bmath\b[\s.]*$/i;

// PreTeXt pulls the punctuation that follows inline math *into* the math
// (`\(f(x) = x^2\text{,}\)`) so it sets and line-breaks correctly, and SRE
// duly speaks it as a word: "f of x equals x squared comma".  Put the
// character back so the voice renders it as a pause instead of saying it.
// The words are English, so other SRE locales simply do not match and keep
// their existing behaviour rather than getting it wrong.
const TRAILING_PUNCTUATION = {
    comma: ",",
    period: ".",
    "full stop": ".",
    semicolon: ";",
    colon: ":",
    "question mark": "?",
    "exclamation mark": "!",
};
const TRAILING_PUNCTUATION_RE = new RegExp(
    `[\\s,]*\\b(${Object.keys(TRAILING_PUNCTUATION).join("|")})\\s*$`,
    "i"
);

export function cleanMathSpeech(value) {
    if (!value) return null;
    // SRE also produces an SSML-marked-up rendering (<mark/>, <break/>,
    // <say-as>…</say-as>).  speechSynthesis takes plain text only — it would
    // read the tags — so reduce any markup to the text it wraps.
    const text = value.replace(/<[^>]*>/g, " ");
    const stripped = text.replace(MATH_REGION_MARKER, "").trim();
    const speech = (stripped || text).replace(/\s+/g, " ").trim();
    return (
        speech.replace(
            TRAILING_PUNCTUATION_RE,
            (match, word) => TRAILING_PUNCTUATION[word.toLowerCase()]
        ) || null
    );
}

// Attributes that can hold speech, in order of preference.  MathJax 4 puts
// the plain-text rendering in `aria-label` and an SSML-marked-up copy in
// `data-semantic-speech`, so the plain forms must win; `-none` is SRE's own
// markup-free variant.  The marked-up attribute stays as a last resort
// because stripped markup still beats announcing "equation".
const SPEECH_ATTRIBUTES = [
    "aria-label",
    "data-semantic-speech-none",
    "data-semantic-speech",
];

// The container's own value first, then the outermost descendant carrying
// the attribute.  querySelector walks in document order, so that descendant
// is the top of the expression rather than one of its sub-expressions.
function speechAttribute(el, attribute) {
    const own = el.getAttribute(attribute);
    if (own) return own;
    const node = el.querySelector(`[${attribute}]`);
    return (node && node.getAttribute(attribute)) || null;
}

/**
 * Read the speech text already present for one typeset expression.
 *
 * Where it lives varies by MathJax version and configuration; MathJax 4
 * attaches SRE's output to the mjx-container's subtree (alongside
 * `data-speech-attached`), while other builds use `aria-label` directly.
 * Assistive MathML is off by default in v4, so that branch usually finds
 * nothing.  Returns null when no speech exists yet.
 */
export function readMathSpeech(el) {
    for (const attribute of SPEECH_ATTRIBUTES) {
        const raw = speechAttribute(el, attribute);
        if (raw) return cleanMathSpeech(raw);
    }

    // Assistive MathML, when a publisher has turned it back on.  Only
    // @alttext is usable: the MathML text content is bare glyphs, which is
    // exactly the garbled reading this feature exists to avoid.
    const mml = el.querySelector("mjx-assistive-mml math");
    const alt = mml && mml.getAttribute("alttext");
    return alt ? cleanMathSpeech(alt) : null;
}

// Memoized so the wait is paid at most once per page: a page with no MathJax
// at all would otherwise poll out its full deadline on every play.
let mathTypeset = null;

/**
 * Resolve once MathJax has finished its initial typesetting — or immediately,
 * on a page that has no MathJax.
 *
 * Collection identifies math purely by the presence of mjx-container
 * elements, which do not exist before typesetting: run too early and every
 * expression is collected as ordinary text and read out as raw LaTeX.  A
 * reader clicking play is always late enough for this to be settled; the
 * auto-continue path, which starts at DOMContentLoaded, is not.
 *
 * MathJax is loaded asynchronously and the `window.MathJax` present at parse
 * time is only the configuration object — `startup` is grafted on later — so
 * the promise has to be waited *for* before it can be waited *on*.
 */
export function whenMathTypeset(timeoutMs = 10000) {
    if (mathTypeset) return mathTypeset;
    mathTypeset = (async () => {
        // No configuration object at all: this page never asked for MathJax.
        if (!window.MathJax) return;
        const deadline = Date.now() + timeoutMs;
        while (!(window.MathJax.startup && window.MathJax.startup.promise)) {
            if (Date.now() >= deadline) return;
            await new Promise((r) => setTimeout(r, 50));
        }
        // Never let a MathJax failure hang the reader: the collector degrades
        // to reading whatever is in the DOM, which is the old behaviour.
        await Promise.race([
            window.MathJax.startup.promise.catch(() => {}),
            new Promise((r) => setTimeout(r, Math.max(0, deadline - Date.now()))),
        ]);
    })();
    return mathTypeset;
}

/**
 * Resolve speech text for one mjx-container, waiting briefly if MathJax's
 * speech worker has not finished with this expression yet.  Resolves to null
 * if nothing arrives in time; the caller substitutes the localized
 * "equation" announcement so a reader hears something either way.
 */
function resolveMathSpeech(el, timeoutMs) {
    const direct = readMathSpeech(el);
    if (direct) {
        return Promise.resolve(direct);
    }
    return new Promise((resolve) => {
        let done = false;
        const finish = (value) => {
            if (done) return;
            done = true;
            observer.disconnect();
            clearTimeout(timer);
            resolve(value);
        };
        // Speech generation runs in a web worker and patches the container
        // after typesetting, so watch the whole subtree, not just the
        // container's own attributes.
        const observer = new MutationObserver(() => {
            const speech = readMathSpeech(el);
            if (speech) finish(speech);
        });
        observer.observe(el, {
            attributes: true,
            childList: true,
            subtree: true,
        });
        const timer = setTimeout(() => finish(readMathSpeech(el)), timeoutMs);
    });
}

/**
 * Collect the readable blocks of `root` (usually #ptx-content).
 *
 * opts:
 *   strings         stringId → localized text (for the equation fallback)
 *   mathTimeoutMs   how long to wait for a missing aria-label (default 3000)
 *
 * Returns a Promise of the blocks array; async only because math speech may
 * need a brief wait on freshly loaded pages.
 */
export async function collect(root, opts = {}) {
    const strings = opts.strings || {};
    const mathTimeoutMs = opts.mathTimeoutMs || 3000;
    // Before walking the DOM at all: an untypeset page has no math in it to
    // find.  Resolves instantly once MathJax has run, so this costs a reader
    // who clicks play nothing.
    await whenMathTypeset();
    const blocks = [];
    const pendingMath = [];

    // The block currently accumulating inline tokens, or null.
    let current = null;

    const flush = () => {
        if (current && current.tokens.some(isSpeakable)) {
            blocks.push(current);
        }
        current = null;
    };
    const isSpeakable = (t) =>
        t.kind !== "text" || t.value.trim() !== "";

    const ensureBlock = (el, ctx) => {
        if (!current) {
            current = { el, tokens: [], path: ctx.path, summary: ctx.summary };
        }
    };

    /**
     * ctx carries position in the tree down the walk:
     *   path      ancestry so far (nodes.js descriptors), root first
     *   summary   inside an aside's always-read title
     *   closed    inside a closed <details>, so the visibility gate is off
     *   runestone inside a rendered interactive exercise, so its controls
     *             are skipped and its nested containers announce nothing
     */
    const visit = (node, blockEl, ctx) => {
        if (node.nodeType === Node.TEXT_NODE) {
            if (node.nodeValue.trim() !== "") {
                ensureBlock(blockEl, ctx);
                current.tokens.push({ kind: "text", value: node.nodeValue, node });
            }
            return;
        }
        if (node.nodeType !== Node.ELEMENT_NODE) return;
        const el = node;

        if (el.matches(SKIP_SELECTOR)) return;
        // Content in a collapsed <details> is hidden only because the reader
        // has not clicked yet — exactly the content the aside modes exist to
        // reach — so the visibility gate is suspended below one.  Genuinely
        // hidden material is still excluded by SKIP_SELECTOR above.
        if (!ctx.closed && !isElementVisible(el)) return;

        const descriptor = nodeDescriptor(el);
        if (descriptor) {
            ctx = { ...ctx, path: ctx.path.concat(descriptor) };
        }
        if (el.tagName === "DETAILS" && !el.open) {
            ctx = { ...ctx, closed: true };
        }
        if (el.tagName === "SUMMARY") {
            ctx = { ...ctx, summary: true };
        }

        // A footnote's clickable summary is a bare superscript numeral, which
        // reads as a stray "one" in the middle of a sentence.  PreTeXt already
        // renders the localized, numbered name into the tooltip ("Footnote
        // 3.1"), so speak that instead of the numeral.
        if (el.matches(".ptx-footnote__number")) {
            const label = (el.getAttribute("title") || "").trim();
            if (label) {
                flush();
                ensureBlock(el, ctx);
                current.tokens.push({ kind: "text", value: label, node: null, el });
                flush();
                return;
            }
        }

        // Runestone interactive exercises.  Handled before the announce list
        // so a rendered component is *entered* for its prose; the code and
        // table rules below then still apply to what is found inside it.
        if (!ctx.runestone && el.matches(RUNESTONE_SELECTOR)) {
            if (el.matches(RUNESTONE_READY) || el.querySelector(RUNESTONE_READY)) {
                flush();
                const kind = runestoneKind(el, strings);
                if (kind) {
                    blocks.push({
                        el,
                        tokens: [{ kind: "text", value: kind, node: null, el }],
                        path: ctx.path,
                        summary: ctx.summary,
                    });
                }
                ctx = { ...ctx, runestone: true };
            } else if (
                el.matches(RUNESTONE_UNBUILT) ||
                el.querySelector(RUNESTONE_UNBUILT)
            ) {
                flush();
                blocks.push({
                    el,
                    tokens: [
                        {
                            kind: "announce",
                            stringId: "read-aloud-skip-interactive",
                            el,
                        },
                    ],
                    path: ctx.path,
                    summary: ctx.summary,
                });
                return;
            }
            // Neither: a container Runestone left empty of any component.
            // Nothing special to do, so fall through and walk it normally.
        }

        if (ctx.runestone && el.matches(RUNESTONE_CONTROL_SELECTOR)) return;

        // Announce-and-skip categories
        for (const { selector, stringId } of ANNOUNCE_SELECTORS) {
            if (el.matches(selector)) {
                // An empty one is a pane waiting to be filled, not content
                // being passed over — every ActiveCode ships with a blank
                // output <pre>, and saying "Code. Skipping." over it twice
                // per exercise is worse than saying nothing.
                if (isEmptyOfContent(el)) return;
                flush();
                blocks.push({
                    el,
                    tokens: [{ kind: "announce", stringId, el }],
                    path: ctx.path,
                    summary: ctx.summary,
                });
                return;
            }
        }

        // Typeset math: a token in the current block; display math becomes
        // its own block so it is spoken with a natural pause around it.
        if (el.tagName === "MJX-CONTAINER") {
            const display = el.getAttribute("display") === "true";
            if (display) flush();
            ensureBlock(display ? el : blockEl, ctx);
            const token = { kind: "math", speech: "", display, el };
            current.tokens.push(token);
            pendingMath.push(token);
            if (display) flush();
            return;
        }

        // Images speak their alt text (part of visual reading).  Alt text is
        // written to stand in for a picture, not to be read as prose, so it
        // is introduced rather than spliced silently into the sentence around
        // it — otherwise a listener cannot tell where the author's sentence
        // stopped and the description of the picture began.
        if (el.tagName === "IMG") {
            const alt = (el.getAttribute("alt") || "").trim();
            if (alt) {
                const label = strings["read-aloud-image-alt"];
                ensureBlock(blockEl, ctx);
                current.tokens.push({
                    kind: "text",
                    value: label ? `${label} ${alt}` : alt,
                    node: null,
                    el,
                });
            }
            return;
        }

        if (el.matches(HEADING_SELECTOR) || el.matches(CONTAINER_SELECTOR)) {
            flush();
            for (const child of readingOrder(el)) visit(child, el, ctx);
            flush();
            return;
        }

        // Anything else is treated as inline: descend with the same block.
        for (const child of el.childNodes) visit(child, blockEl, ctx);
    };

    visit(root, root, {
        path: [],
        summary: false,
        closed: false,
        runestone: false,
    });
    flush();

    // Resolve math speech in parallel under a shared deadline.
    let fallbackCount = 0;
    await Promise.all(
        pendingMath.map(async (token) => {
            const speech = await resolveMathSpeech(token.el, mathTimeoutMs);
            if (!speech) fallbackCount++;
            token.speech =
                speech ||
                strings["read-aloud-equation-fallback"] ||
                "equation";
        })
    );
    if (fallbackCount) {
        // Every expression reading as "equation" means MathJax produced no
        // speech at all — worth saying out loud, since the page otherwise
        // reads perfectly well and the cause is invisible.
        console.warn(
            `PreTeXt read-aloud: no MathJax speech text for ${fallbackCount} of ` +
            `${pendingMath.length} expression(s); reading the fallback instead. ` +
            `Run PTXReadAloud.debugMath() to see what MathJax produced.`
        );
    }

    return blocks;
}
