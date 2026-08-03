/*******************************************************************************
 * Unit tests for the read-aloud node vocabulary (CSS classes → tree nodes).
 *
 * Run from the repository root with:
 *     node --test js/src/read-aloud/test/*.test.js
 *
 * nodeDescriptor only reads `classList` and `tagName`, so a plain object
 * stands in for an element and these tests need no DOM.  The class strings
 * below are copied from real PreTeXt output (sample article + demo), because
 * the whole risk this file guards against is a spelling we did not expect.
 ******************************************************************************/

import { test } from "node:test";
import assert from "node:assert/strict";
import { nodeDescriptor } from "../nodes.js";

const el = (className, tagName = "ARTICLE") => {
    const list = className.split(/\s+/);
    list.contains = (c) => list.includes(c);
    return { classList: list, tagName };
};

test("a block carries its PreTeXt name and its family", () => {
    const d = nodeDescriptor(el("lemma theorem-like"));
    assert.equal(d.type, "lemma");
    assert.equal(d.family, "theorem-like");
    assert.equal(d.aside, false);
});

test("born-hidden blocks are asides, keeping their own type", () => {
    const d = nodeDescriptor(el("example example-like born-hidden-knowl", "DETAILS"));
    assert.equal(d.type, "example");
    assert.equal(d.family, "example-like");
    assert.equal(d.aside, true);
});

test("a born-hidden proof is spelled 'hiddenproof', not 'proof'", () => {
    // Missing this spelling made proofs invisible to navigation: skipping a
    // theorem still read the proof inside it, and every block within the
    // proof announced itself as the enclosing theorem.
    const d = nodeDescriptor(el("hiddenproof born-hidden-knowl", "DETAILS"));
    assert.equal(d.type, "hiddenproof");
    assert.equal(d.aside, true);
    // Non-hidden proofs keep the plain spelling.
    assert.equal(nodeDescriptor(el("proof")).type, "proof");
});

test("footnotes and image descriptions are asides with supplied names", () => {
    const fn = nodeDescriptor(el("ptx-footnote", "DETAILS"));
    assert.equal(fn.type, "footnote");
    assert.equal(fn.aside, true);
    const desc = nodeDescriptor(el("image-description", "DETAILS"));
    assert.equal(desc.type, "description");
    assert.equal(desc.aside, true);
});

test("solutions, hints and answers inside a block are asides", () => {
    for (const cls of ["solution solution-like", "hint solution-like", "answer solution-like"]) {
        const d = nodeDescriptor(el(`${cls} born-hidden-knowl`, "DETAILS"));
        assert.equal(d.aside, true, cls);
        assert.equal(d.family, "solution-like", cls);
    }
});

test("a block emitted with only its family name still resolves", () => {
    const d = nodeDescriptor(el("solution-like born-hidden-knowl", "DETAILS"));
    assert.equal(d.type, "solution-like");
    assert.equal(d.aside, true);
});

test("divisions are nodes only on <section>", () => {
    assert.equal(nodeDescriptor(el("subsection", "SECTION")).family, "division");
    // The same word appears on wrappers that are not divisions.
    assert.equal(nodeDescriptor(el("pretext article ignore-math", "DIV")), null);
});

test("page chrome is not a node", () => {
    assert.equal(nodeDescriptor(el("print-options", "DETAILS")), null);
    assert.equal(nodeDescriptor(el("instructions diagcess__instructions", "DETAILS")), null);
    assert.equal(nodeDescriptor(el("para", "DIV")), null);
});

test("an element with no classes is not a node", () => {
    assert.equal(nodeDescriptor({ classList: [], tagName: "DIV" }), null);
});
