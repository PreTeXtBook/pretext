/*******************************************************************************
 * Unit tests for the read-aloud segmenter (pure IR → utterance plan).
 *
 * Run from the repository root (or anywhere) with:
 *     node --test js/src/read-aloud/test/
 *
 * These are the first JavaScript unit tests in core PreTeXt; they use Node's
 * built-in test runner so there is no framework dependency.
 ******************************************************************************/

import { test } from "node:test";
import assert from "node:assert/strict";
import {
    buildPlan,
    collapseWhitespace,
    sentenceBoundaries,
} from "../segmenter.js";
import { cleanMathSpeech } from "../collector.js";

// Convenience IR constructors
const text = (value) => ({ kind: "text", value });
const math = (speech, display = false) => ({ kind: "math", speech, display });
const announce = (stringId) => ({ kind: "announce", stringId });
const block = (...tokens) => ({ tokens });

//------------------------------------------------------------------
// collapseWhitespace

test("collapseWhitespace collapses runs and maps back to original offsets", () => {
    const { text: t, map } = collapseWhitespace("a  b\n\tc");
    assert.equal(t, "a b c");
    // 'c' in collapsed position 4 came from original position 6
    assert.equal(map[4], 6);
    assert.equal("a  b\n\tc"[map[2]], "b");
});

//------------------------------------------------------------------
// Sentence splitting

test("two plain sentences become two utterances", () => {
    const plan = buildPlan(
        [block(text("The dog barks. The cat meows."))],
        { locale: "en" }
    );
    assert.equal(plan.length, 2);
    assert.equal(plan[0].text, "The dog barks.");
    assert.equal(plan[1].text, "The cat meows.");
});

test("common abbreviations do not split sentences (Intl.Segmenter)", () => {
    const plan = buildPlan(
        [block(text("See Dr. Smith for details. Then rest."))],
        { locale: "en" }
    );
    assert.equal(plan.length, 2);
    assert.equal(plan[0].text, "See Dr. Smith for details.");
});

test("dotted initialisms do not split sentences", () => {
    // The final period of "e.g." is preceded by a lone letter, not by a word
    // in the abbreviation list, so it needs the shape rule to survive.
    for (const abbr of ["e.g.", "i.e.", "U.S."]) {
        const plan = buildPlan(
            [block(text(`As in ${abbr} Theorem 3.2, we are done. Then rest.`))],
            { locale: "en" }
        );
        assert.equal(plan.length, 2, `split inside ${abbr}`);
        assert.equal(plan[0].text, `As in ${abbr} Theorem 3.2, we are done.`);
    }
});

test("abbreviations after an opening bracket do not split sentences", () => {
    const plan = buildPlan(
        [block(text("A result (e.g. Theorem 3.2) holds. Then rest."))],
        { locale: "en" }
    );
    assert.equal(plan.length, 2);
    assert.equal(plan[0].text, "A result (e.g. Theorem 3.2) holds.");
});

test("the read-aloud demo abbreviation sentence stays whole", () => {
    const sentence =
        "The abbreviations in this one: see Dr. Smith, or e.g. Theorem 3.2, " +
        "or cf. Fig. 4 for details.";
    const plan = buildPlan([block(text(sentence))], { locale: "en" });
    assert.equal(plan.length, 1);
    assert.equal(plan[0].text, sentence);
});

test("suppression does not swallow ordinary sentence ends", () => {
    // A single letter plus period is an ordinary end, not an initialism.
    const plan = buildPlan(
        [block(text("The unknown is x. Then we solve for y."))],
        { locale: "en" }
    );
    assert.equal(plan.length, 2);
    assert.equal(plan[0].text, "The unknown is x.");
});

test("regex fallback boundaries look reasonable", () => {
    // Exercise the fallback path directly (as if Intl.Segmenter were absent)
    const boundaries = sentenceBoundaries("One two. Three four! Five?", "en");
    // Either engine should find at least the two obvious boundaries
    assert.ok(boundaries.includes(9));
    assert.ok(boundaries.includes(21));
});

//------------------------------------------------------------------
// Math splicing

test("inline math mid-sentence yields a single spliced utterance", () => {
    const plan = buildPlan(
        [
            block(
                text("Consider the function "),
                math("f of x equals x squared"),
                text(" which opens upward.")
            ),
        ],
        { locale: "en" }
    );
    assert.equal(plan.length, 1);
    assert.equal(
        plan[0].text,
        "Consider the function f of x equals x squared which opens upward."
    );
    // The math token participates in the range map
    assert.ok(plan[0].ranges.some((r) => r.tokenIndex === 1 && r.start === undefined));
});

test("punctuation directly after math hugs the math speech", () => {
    const plan = buildPlan(
        [block(text("We define "), math("f of x"), text(". Then we continue."))],
        { locale: "en" }
    );
    assert.equal(plan[0].text, "We define f of x.");
    assert.equal(plan[1].text, "Then we continue.");
});

test("math at sentence start and end", () => {
    const plan = buildPlan(
        [block(math("x"), text(" is small but "), math("y"))],
        { locale: "en" }
    );
    assert.equal(plan.length, 1);
    assert.equal(plan[0].text, "x is small but y");
});

test("adjacent math tokens are separated by a space", () => {
    const plan = buildPlan(
        [block(math("alpha"), math("beta"))],
        { locale: "en" }
    );
    assert.equal(plan[0].text, "alpha beta");
});

test("periods inside math speech never split the sentence", () => {
    const plan = buildPlan(
        [
            block(
                text("The answer "),
                math("x equals 3.2. approximately"),
                text(" is small.")
            ),
        ],
        { locale: "en" }
    );
    assert.equal(plan.length, 1);
});

test("display math becomes its own utterance from its own block", () => {
    const plan = buildPlan(
        [
            block(text("We compute the following.")),
            block(math("integral from 0 to 1 of x squared d x", true)),
            block(text("The result is one third.")),
        ],
        { locale: "en" }
    );
    assert.equal(plan.length, 3);
    assert.equal(plan[1].text, "integral from 0 to 1 of x squared d x");
    assert.deepEqual(plan[1].ranges, [{ tokenIndex: 0 }]);
});

//------------------------------------------------------------------
// Announcements

test("announce tokens become localized announcement utterances", () => {
    const plan = buildPlan(
        [block(announce("read-aloud-skip-table"))],
        { strings: { "read-aloud-skip-table": "Table. Skipping." } }
    );
    assert.equal(plan.length, 1);
    assert.equal(plan[0].kind, "announce");
    assert.equal(plan[0].text, "Table. Skipping.");
});

test("announce token without a string falls back to its id", () => {
    const plan = buildPlan([block(announce("read-aloud-skip-code"))], {});
    assert.equal(plan[0].text, "read-aloud-skip-code");
});

test("announce token splits a mixed block", () => {
    const plan = buildPlan(
        [block(text("Before."), announce("read-aloud-skip-code"), text("After."))],
        { locale: "en", strings: { "read-aloud-skip-code": "Code. Skipping." } }
    );
    assert.deepEqual(
        plan.map((u) => u.text),
        ["Before.", "Code. Skipping.", "After."]
    );
});

//------------------------------------------------------------------
// Length clamping

test("over-long sentences are clamped at clause boundaries", () => {
    const clause = "we continue the argument with great care and patience";
    const long = Array(8).fill(clause).join(", ") + ".";
    assert.ok(long.length > 250);
    const plan = buildPlan([block(text(long))], { locale: "en" });
    assert.ok(plan.length > 1, "long sentence should be split");
    for (const u of plan) {
        assert.ok(u.text.length <= 250, `chunk too long: ${u.text.length}`);
    }
    // Chunks reassemble the original (modulo the collapsed join spaces)
    assert.equal(plan.map((u) => u.text).join(" "), long);
});

test("clamping never bisects a math span", () => {
    const mathSpeech = "a very long spoken form of an expression " +
        "that goes on and on and on for quite a while indeed";
    const plan = buildPlan(
        [
            block(
                text("Start of a sentence that runs long "),
                math(mathSpeech),
                text(" and then keeps going with more prose after the mathematics ".repeat(4))
            ),
        ],
        { locale: "en", maxLength: 80 }
    );
    // The full math speech text must appear intact in exactly one utterance
    const containing = plan.filter((u) => u.text.includes(mathSpeech));
    assert.equal(containing.length, 1);
});

//------------------------------------------------------------------
// Range-map integrity

test("text ranges index real substrings of the original token values", () => {
    const tokens = [
        text("First sentence here.  Second\n sentence, with  a clause."),
        math("x plus y"),
        text(" Tail text."),
    ];
    const plan = buildPlan([block(...tokens)], { locale: "en" });
    for (const u of plan) {
        for (const r of u.ranges) {
            if (r.start === undefined) continue;
            const original = tokens[r.tokenIndex].value;
            const slice = original.slice(r.start, r.end);
            // Every mapped slice must appear in the utterance text once
            // whitespace is normalized the same way.
            const normalized = slice.replace(/\s+/g, " ").trim();
            assert.ok(
                u.text.includes(normalized),
                `range slice "${normalized}" not in utterance "${u.text}"`
            );
        }
    }
});

test("ranges of one utterance stay within its sentence", () => {
    const t = text("Alpha beta. Gamma delta.");
    const plan = buildPlan([block(t)], { locale: "en" });
    assert.equal(plan.length, 2);
    const [u1, u2] = plan;
    const slice1 = t.value.slice(u1.ranges[0].start, u1.ranges[0].end);
    const slice2 = t.value.slice(u2.ranges[0].start, u2.ranges[0].end);
    assert.equal(slice1.trim(), "Alpha beta.");
    assert.equal(slice2.trim(), "Gamma delta.");
});

//------------------------------------------------------------------
// Math speech cleanup (SRE's screen-reader region marker)

test("trailing math region marker is stripped", () => {
    assert.equal(
        cleanMathSpeech("f of x equals x squared, math"),
        "f of x equals x squared"
    );
    assert.equal(cleanMathSpeech("x plus y math"), "x plus y");
    assert.equal(cleanMathSpeech("x plus y, Math."), "x plus y");
});

test("cleanup leaves ordinary speech untouched", () => {
    assert.equal(cleanMathSpeech("a squared plus b squared"), "a squared plus b squared");
    // "mathematics" must not be mistaken for the marker
    assert.equal(cleanMathSpeech("the set of all mathematics"), "the set of all mathematics");
});

test("cleanup never empties a speech string", () => {
    assert.equal(cleanMathSpeech("math"), "math");
});

test("cleanup normalizes whitespace and handles empties", () => {
    assert.equal(cleanMathSpeech("x  plus\n y, math"), "x plus y");
    assert.equal(cleanMathSpeech(""), null);
    assert.equal(cleanMathSpeech(null), null);
});

test("SSML markup is reduced to the text it wraps", () => {
    // speechSynthesis has no SSML support and would read the tags aloud.
    const ssml =
        '<mark name="0"/> <say-as interpret-as="character">f</say-as> ' +
        '<mark name="9"/> of <mark name="2"/> ' +
        '<say-as interpret-as="character">x</say-as> <break time="250ms"/> ' +
        '<mark name="4"/> equals <mark name="5"/> ' +
        '<say-as interpret-as="character">x</say-as> <mark name="6"/> squared';
    assert.equal(cleanMathSpeech(ssml), "f of x equals x squared");
});

test("markup-only speech yields null rather than an empty utterance", () => {
    assert.equal(cleanMathSpeech('<mark name="0"/> <break time="250ms"/>'), null);
});

test("spoken trailing punctuation becomes real punctuation", () => {
    // PreTeXt absorbs the punctuation after inline math into the expression,
    // so SRE says the word; the voice should pause instead.
    assert.equal(
        cleanMathSpeech("f of x equals x squared comma, math"),
        "f of x equals x squared,"
    );
    assert.equal(cleanMathSpeech("x period"), "x.");
    assert.equal(cleanMathSpeech("y semicolon"), "y;");
});

test("punctuation words inside an expression are left alone", () => {
    // Only a trailing word is PreTeXt's absorbed punctuation; "comma" in the
    // middle is how SRE reads a genuine separator.
    assert.equal(cleanMathSpeech("1 comma 2 comma 3"), "1 comma 2 comma 3");
});

test("non-English locales keep their own rendering", () => {
    assert.equal(cleanMathSpeech("f de x égale x carré virgule"), "f de x égale x carré virgule");
});

//------------------------------------------------------------------
// Degenerate input

test("empty and whitespace-only blocks yield no utterances", () => {
    const plan = buildPlan(
        [block(text("   \n  ")), block(), block(text(""))],
        { locale: "en" }
    );
    assert.deepEqual(plan, []);
});

test("math with empty speech is dropped rather than spoken as garbage", () => {
    const plan = buildPlan(
        [block(text("Before "), math(""), text(" after."))],
        { locale: "en" }
    );
    assert.equal(plan.length, 1);
    assert.equal(plan[0].text, "Before after.");
});
