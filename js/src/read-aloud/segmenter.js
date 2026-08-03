/*******************************************************************************
 * segmenter.js — pure IR → utterance-plan stage of the read-aloud pipeline
 *******************************************************************************
 * No DOM access here: input and output are plain data so this file can be
 * unit-tested with Node's built-in test runner (see test/segmenter.test.js).
 *
 * INPUT — blocks, as produced by collector.js:
 *   Block: { el?, tokens: Token[] }
 *   Token:
 *     { kind: "text",     value, node? }          one token per DOM text node
 *     { kind: "math",     speech, display, el? }  speech text from MathJax
 *     { kind: "announce", stringId, el? }         "Table. Skipping." etc.
 *
 * OUTPUT — plan, consumed by speech-queue.js and highlighter.js:
 *   Utterance: {
 *     kind: "speech" | "announce",
 *     text,                    what speechSynthesis will say
 *     blockIndex,              index into the input blocks array
 *     ranges: Range[]          source map for highlighting
 *   }
 *   Range:
 *     { tokenIndex, start, end }   char span in a text token's ORIGINAL value
 *     { tokenIndex }               a math or announce token, highlighted whole
 *
 * Sentence boundaries come from Intl.Segmenter when available (locale-aware),
 * with a regex fallback.  Two invariants the tests enforce:
 *   - a boundary never falls inside spliced math speech (which may contain
 *     periods, e.g. "equals 3.2"), and
 *   - utterances longer than maxLength are split at clause boundaries, never
 *     inside math.
 ******************************************************************************/

// Default maximum utterance length in characters.  Chrome's speech synthesis
// silently dies partway through very long utterances (notoriously ~15s with
// network voices), so outliers are clamped at clause boundaries.
const DEFAULT_MAX_LENGTH = 250;

/**
 * Collapse runs of whitespace to single spaces, keeping a map from each
 * collapsed-string index back to the index in the original string.  The map
 * is what lets highlight ranges refer to original DOM text-node offsets even
 * though sentence math is done on normalized text.
 */
export function collapseWhitespace(value) {
    let text = "";
    const map = [];
    let inSpace = false;
    for (let i = 0; i < value.length; i++) {
        if (/\s/.test(value[i])) {
            if (!inSpace && text.length > 0) {
                text += " ";
                map.push(i);
            }
            inSpace = true;
        } else {
            text += value[i];
            map.push(i);
            inSpace = false;
        }
    }
    // Drop a trailing space introduced by trailing whitespace
    if (text.endsWith(" ")) {
        text = text.slice(0, -1);
        map.pop();
    }
    return { text, map };
}

// ICU (via Intl.Segmenter) already keeps "e.g. when" and "Fig. 4" together
// because the continuation is lowercase or a digit; it only mis-splits when
// an abbreviation is followed by a capitalized word ("Dr. Smith",
// "e.g. Theorem").  Suppress boundaries preceded by either
//   - one of these common title/reference abbreviations, or
//   - a dotted initialism: two or more single letters each followed by a
//     period ("e.g.", "i.e.", "a.m.", "U.S.").  These need a shape rule
//     rather than a word list because the piece before the final period is
//     itself a lone letter, so no whitespace precedes it.
// The abbreviation may be preceded by an opening bracket or quote as well as
// by whitespace, so that "(e.g. Theorem 3.2)" is also handled.
const ABBREVIATION_RE =
    /(?:^|[\s(\[{"'“‘])(?:Dr|Mr|Mrs|Ms|Prof|St|Mt|Fig|Eq|Ex|Sec|Ch|Thm|Cor|Lem|Def|Rem|Prop|vs|cf|No|Vol|pp?|ed|eds|etc|al|Ph\.D|(?:[A-Za-z]\.)+[A-Za-z])\.\s*$/;

/**
 * Return sentence-start boundaries (indices > 0) for `text`.
 * Uses Intl.Segmenter when available; otherwise a conservative regex:
 * split after .!?… followed by space + capital/digit/quote.
 */
export function sentenceBoundaries(text, locale) {
    let boundaries = [];
    if (typeof Intl !== "undefined" && Intl.Segmenter) {
        const seg = new Intl.Segmenter(locale || undefined, { granularity: "sentence" });
        for (const s of seg.segment(text)) {
            if (s.index > 0) {
                boundaries.push(s.index);
            }
        }
    } else {
        const re = /[.!?…]["')\]]?\s+(?=["'([]?[A-Z0-9])/g;
        let m;
        while ((m = re.exec(text)) !== null) {
            boundaries.push(m.index + m[0].length);
        }
    }
    return boundaries.filter((b) => !ABBREVIATION_RE.test(text.slice(0, b)));
}

// Insert a joining space between two concatenated parts unless the next part
// begins with punctuation that should hug the previous word (e.g. the "."
// after inline math in "\(f(x)\).").
function needsJoinSpace(prev, next) {
    if (prev === "" || next === "") return false;
    if (/\s$/.test(prev)) return false;
    if (/^\s/.test(next)) return false;
    if (/^[.,;:!?…)\]}%]/.test(next)) return false;
    return true;
}

/**
 * Flatten a run of text/math tokens into one combined string plus spans.
 * Each span records which slice of the combined string came from which token
 * (and, for text tokens, the offset map back into the original value).
 */
function flattenRun(run) {
    let combined = "";
    const spans = [];
    for (const { token, tokenIndex } of run) {
        let part, map = null;
        if (token.kind === "text") {
            ({ text: part, map } = collapseWhitespace(token.value));
        } else {
            ({ text: part } = collapseWhitespace(token.speech || ""));
        }
        if (part === "") continue;
        if (needsJoinSpace(combined, part)) {
            combined += " ";
        }
        spans.push({
            start: combined.length,
            end: combined.length + part.length,
            tokenIndex,
            kind: token.kind,
            map,
        });
        combined += part;
    }
    return { combined, spans };
}

// True if position `pos` in the combined string falls strictly inside a
// math span — a place a sentence boundary or clamp split must never land.
function insideMath(pos, spans) {
    return spans.some(
        (s) => s.kind === "math" && pos > s.start && pos < s.end
    );
}

/**
 * Split an over-long sentence [start, end) at clause boundaries.  Prefers
 * ",;:—–" then a space, searching backward from the length limit; never
 * splits inside a math span.  Returns an array of [start, end) pairs.
 */
function clampChunks(combined, spans, start, end, maxLength) {
    const chunks = [];
    let s = start;
    while (end - s > maxLength) {
        const limit = s + maxLength;
        let cut = -1;
        // Prefer cutting just after clause punctuation, then at any space.
        const clauseCut = (i) => /[,;:—–]/.test(combined[i - 1]) && combined[i] === " ";
        const spaceCut = (i) => combined[i] === " ";
        for (const acceptable of [clauseCut, spaceCut]) {
            for (let i = limit; i > s + 1; i--) {
                if (insideMath(i, spans)) continue;
                if (acceptable(i)) {
                    cut = i;
                    break;
                }
            }
            if (cut >= 0) break;
        }
        if (cut < 0) {
            // No safe split point at all (one giant unbroken token): hard cut,
            // but step past any math span rather than bisect it.
            cut = limit;
            for (const sp of spans) {
                if (sp.kind === "math" && cut > sp.start && cut < sp.end) {
                    cut = sp.end;
                    break;
                }
            }
        }
        chunks.push([s, cut]);
        s = cut;
    }
    chunks.push([s, end]);
    return chunks;
}

// Build one utterance from a [start, end) slice of the combined string.
function makeUtterance(combined, spans, start, end, blockIndex) {
    // Trim surrounding whitespace off the slice.
    while (start < end && /\s/.test(combined[start])) start++;
    while (end > start && /\s/.test(combined[end - 1])) end--;
    if (start >= end) return null;

    const ranges = [];
    for (const span of spans) {
        const s = Math.max(start, span.start);
        const e = Math.min(end, span.end);
        if (s >= e) continue;
        if (span.kind === "text") {
            // Map combined-string offsets back to original token offsets.
            const localStart = s - span.start;
            const localEnd = e - span.start;
            ranges.push({
                tokenIndex: span.tokenIndex,
                start: span.map[localStart],
                end: span.map[localEnd - 1] + 1,
            });
        } else {
            ranges.push({ tokenIndex: span.tokenIndex });
        }
    }
    return {
        kind: "speech",
        text: combined.slice(start, end),
        blockIndex,
        ranges,
    };
}

/**
 * Main entry: blocks → utterance plan.
 *
 * opts:
 *   locale     BCP-47 tag for sentence segmentation (document language)
 *   maxLength  clamp limit in characters (default 250)
 *   strings    map stringId → localized text for announce tokens
 */
export function buildPlan(blocks, opts = {}) {
    const locale = opts.locale;
    const maxLength = opts.maxLength || DEFAULT_MAX_LENGTH;
    const strings = opts.strings || {};
    const plan = [];

    blocks.forEach((block, blockIndex) => {
        // Announce tokens split the block into runs of speakable tokens.
        let run = [];
        const flushRun = () => {
            if (run.length === 0) return;
            const { combined, spans } = flattenRun(run);
            run = [];
            if (combined.trim() === "") return;

            // Sentence boundaries, merged across math spans.
            const rawBoundaries = sentenceBoundaries(combined, locale);
            const boundaries = rawBoundaries.filter((b) => !insideMath(b, spans));

            const starts = [0, ...boundaries];
            starts.forEach((s, i) => {
                const e = i + 1 < starts.length ? starts[i + 1] : combined.length;
                for (const [cs, ce] of clampChunks(combined, spans, s, e, maxLength)) {
                    const utt = makeUtterance(combined, spans, cs, ce, blockIndex);
                    if (utt) plan.push(utt);
                }
            });
        };

        block.tokens.forEach((token, tokenIndex) => {
            if (token.kind === "announce") {
                flushRun();
                plan.push({
                    kind: "announce",
                    text: strings[token.stringId] || token.stringId,
                    blockIndex,
                    ranges: [{ tokenIndex }],
                });
            } else {
                run.push({ token, tokenIndex });
            }
        });
        flushRun();
    });

    return plan;
}
