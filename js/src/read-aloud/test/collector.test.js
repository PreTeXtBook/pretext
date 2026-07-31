/*******************************************************************************
 * Unit tests for the collector's element-level decisions.
 *
 * Run from the repository root with:
 *     node --test js/src/read-aloud/test/*.test.js
 *
 * The full walk needs a live DOM (and, for Runestone components, Runestone's
 * own JavaScript to have rewritten the page), so it is exercised by hand
 * against the sample book rather than here.  What *is* testable without a
 * browser are the two per-element judgements the walk defers to, so those are
 * the ones pinned down below.  Plain objects stand in for elements, as in
 * nodes.test.js; the class names and captions are copied from real rendered
 * Runestone output.
 ******************************************************************************/

import { test } from "node:test";
import assert from "node:assert/strict";
import { isEmptyOfContent, readingOrder, runestoneKind } from "../collector.js";

const STRINGS = {
    "read-aloud-interactive-kind": "{kind} exercise.",
    "read-aloud-interactive": "Interactive exercise.",
};

// A stand-in element: `caption` is what querySelector(".runestone_caption")
// finds, if anything.
const component = (caption) => ({
    querySelector: (sel) =>
        sel === ".runestone_caption" && caption !== null
            ? { textContent: caption }
            : null,
});

test("a component announces the name Runestone rendered for it", () => {
    assert.equal(
        runestoneKind(component("Multiple Choice"), STRINGS),
        "Multiple Choice exercise."
    );
    assert.equal(
        runestoneKind(component("Fill in the Blank"), STRINGS),
        "Fill in the Blank exercise."
    );
});

test("the caption is trimmed and its whitespace collapsed", () => {
    // Runestone lays the caption out across several source lines.
    assert.equal(
        runestoneKind(component("\n  Drag-N-Drop\n"), STRINGS),
        "Drag-N-Drop exercise."
    );
});

test("a component with no caption falls back to the generic name", () => {
    // The newer <matching> component renders none.
    assert.equal(runestoneKind(component(null), STRINGS), "Interactive exercise.");
    assert.equal(runestoneKind(component("   "), STRINGS), "Interactive exercise.");
});

test("without strings the announcement is the bare caption, never a key", () => {
    assert.equal(runestoneKind(component("Parsons")), "Parsons");
    assert.equal(runestoneKind(component(null)), null);
});

// isEmptyOfContent guards the announce-and-skip categories: every ActiveCode
// ships with an output <pre> that stays empty until the reader runs the
// program, and announcing "Code. Skipping." over it is noise.
const el = (text, media = false) => ({
    textContent: text,
    matches: () => false,
    querySelector: () => (media ? {} : null),
});

test("an element with no text and no media has nothing to announce", () => {
    assert.equal(isEmptyOfContent(el("")), true);
    assert.equal(isEmptyOfContent(el("\n   \n")), true);
});

test("an element with text is never judged empty", () => {
    assert.equal(isEmptyOfContent(el("print('hi')")), false);
});

test("media counts as content even though it carries no text", () => {
    // A figure holding only an image, or a JSXGraph box whose canvas the
    // library has already inserted.
    assert.equal(isEmptyOfContent(el("", true)), false);
    // The media element itself, which contains nothing at all.
    assert.equal(
        isEmptyOfContent({
            textContent: "",
            matches: (sel) => sel.includes("iframe"),
            querySelector: () => null,
        }),
        false
    );
});

// readingOrder decides where a caption is heard.  PreTeXt sets a figure's
// caption below its image, so by ear the alt text would otherwise arrive
// before the listener knows what is being described.
const container = (children, caption = null) => ({
    childNodes: children,
    querySelector: (sel) => (sel === ":scope > figcaption" ? caption : null),
});

test("a figure's caption is heard before the image it captions", () => {
    const caption = "figcaption";
    const image = "image-box";
    const order = readingOrder(container([image, caption], caption));
    assert.deepEqual(order, [caption, image]);
});

test("a caption already on top stays where it is", () => {
    // Tables, listings and named lists caption above the content already.
    const caption = "figcaption";
    const tabular = "tabular";
    assert.deepEqual(
        readingOrder(container([caption, tabular], caption)),
        [caption, tabular]
    );
});

test("a container with no caption of its own is left alone", () => {
    // Including a "sidebyside" whose captions all belong to its panels: the
    // direct-child query finds none, so the panels keep their own order.
    const children = ["panel", "panel", "panel"];
    assert.deepEqual(readingOrder(container(children)), children);
});
