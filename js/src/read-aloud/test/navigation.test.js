/*******************************************************************************
 * Unit tests for read-aloud tree navigation (pure blocks → block index).
 *
 * Run from the repository root with:
 *     node --test js/src/read-aloud/test/*.test.js
 *
 * Nodes are compared by identity of their `el`, so the fixtures below use
 * plain strings in place of elements and never touch a DOM.
 ******************************************************************************/

import { test } from "node:test";
import assert from "node:assert/strict";
import {
    blockStart,
    enclosingAside,
    enclosingBlock,
    firstBlockIn,
    firstBodyBlockIn,
    innermost,
    nextBlockOutside,
    nextOfFamily,
    nextBlockStart,
    nextSpeakable,
    previousBlockStart,
    shouldSpeak,
    skipTarget,
} from "../navigation.js";

//------------------------------------------------------------------
// Fixture: a section holding a born-hidden theorem (with a born-hidden
// proof inside it), then a paragraph, then a born-hidden example.
//
//   0  para                      [S]
//   1  theorem title             [S,T]    summary
//   2  theorem body              [S,T]
//   3  proof title               [S,T,P]  summary
//   4  proof body                [S,T,P]
//   5  para                      [S]
//   6  example title             [S,X]    summary
//   7  example body              [S,X]
//   8  para                      [S]

const S = { el: "S", type: "section", family: "division", aside: false };
const T = { el: "T", type: "theorem", family: "theorem-like", aside: true };
const P = { el: "P", type: "proof", family: null, aside: true };
const X = { el: "X", type: "example", family: "example-like", aside: true };

const b = (path, summary = false) => ({ el: {}, tokens: [], path, summary });

const blocks = [
    b([S]),
    b([S, T], true),
    b([S, T]),
    b([S, T, P], true),
    b([S, T, P]),
    b([S]),
    b([S, X], true),
    b([S, X]),
    b([S]),
];

const NONE = new Set();

//------------------------------------------------------------------
// Ancestry lookups

test("innermost finds the tightest matching ancestor", () => {
    assert.equal(innermost(blocks, 4, (n) => n.aside), P);
    assert.equal(innermost(blocks, 4, (n) => n.family === "division"), S);
    assert.equal(innermost(blocks, 0, (n) => n.aside), null);
});

test("enclosingBlock ignores divisions", () => {
    // A bare paragraph sits in a section only, so there is no block to skip.
    assert.equal(enclosingBlock(blocks, 0), null);
    assert.equal(enclosingBlock(blocks, 2), T);
    assert.equal(enclosingBlock(blocks, 4), P);
});

test("firstBlockIn finds the title, firstBodyBlockIn skips it", () => {
    assert.equal(firstBlockIn(blocks, T), 1);
    assert.equal(firstBodyBlockIn(blocks, T), 2);
    assert.equal(firstBlockIn(blocks, P), 3);
    assert.equal(firstBodyBlockIn(blocks, P), 4);
});

test("nextBlockOutside leaves the whole subtree, not just the node", () => {
    // Leaving the theorem must also leave the proof nested inside it.
    assert.equal(nextBlockOutside(blocks, 2, T), 5);
    assert.equal(nextBlockOutside(blocks, 4, P), 5);
    // A node running to the end of the page reports "nowhere".
    assert.equal(nextBlockOutside(blocks, 0, S), -1);
});

//------------------------------------------------------------------
// Skipping

test("skipTarget skips the innermost block, not the section", () => {
    assert.equal(skipTarget(blocks, 2), 5); // out of the theorem
    assert.equal(skipTarget(blocks, 4), 5); // out of the proof, into prose
    assert.equal(skipTarget(blocks, 7), 8); // out of the example
});

test("skipTarget has nowhere to go from bare prose", () => {
    assert.equal(skipTarget(blocks, 0), -1);
});

//------------------------------------------------------------------
// Family jumps (the "next theorem" style navigation, wired up later)

test("nextOfFamily finds the next node of a family", () => {
    assert.equal(nextOfFamily(blocks, 0, "theorem-like"), 1);
    assert.equal(nextOfFamily(blocks, 0, "example-like"), 6);
});

test("nextOfFamily does not re-report the node already inside", () => {
    // Standing in the theorem body, the next theorem-like is not this one.
    assert.equal(nextOfFamily(blocks, 2, "theorem-like"), -1);
});

//------------------------------------------------------------------
// Block-level movement (the arrow keys)
//
// A plan over the fixture above: block 0 has three sentences, block 2 has
// two, everything else one.  That is what makes "part-way through a block"
// testable.

const plan = [
    { blockIndex: 0 }, { blockIndex: 0 }, { blockIndex: 0 },
    { blockIndex: 1 },
    { blockIndex: 2 }, { blockIndex: 2 },
    { blockIndex: 3 },
    { blockIndex: 4 },
    { blockIndex: 5 },
];

test("blockStart finds the head of the block being read", () => {
    assert.equal(blockStart(plan, 2), 0);
    assert.equal(blockStart(plan, 0), 0);
    assert.equal(blockStart(plan, 5), 4);
});

test("up goes to the head of the current block when part-way through", () => {
    // Reading the third sentence of block 0: back to its first.
    assert.equal(previousBlockStart(plan, 2), 0);
    assert.equal(previousBlockStart(plan, 5), 4);
});

test("up goes to the previous block when already at a head", () => {
    assert.equal(previousBlockStart(plan, 3), 0);
    assert.equal(previousBlockStart(plan, 4), 3);
});

test("up has nowhere to go from the first block", () => {
    assert.equal(previousBlockStart(plan, 0), -1);
});

test("down goes to the head of the next block", () => {
    assert.equal(nextBlockStart(plan, 0), 3);
    assert.equal(nextBlockStart(plan, 2), 3);
    assert.equal(nextBlockStart(plan, 4), 6);
});

test("down has nowhere to go from the last block", () => {
    assert.equal(nextBlockStart(plan, 8), -1);
});

test("movement steps over blocks the mode suppresses", () => {
    // Suppress block 2 entirely: from block 1, down lands on block 3.
    const allowed = (b) => b !== 2;
    assert.equal(nextBlockStart(plan, 3, allowed), 6);
    // And coming back up from block 3 skips it too.
    assert.equal(previousBlockStart(plan, 6, allowed), 3);
});

//------------------------------------------------------------------
// Listening modes

test("titles are always spoken, so an aside is never invisible", () => {
    assert.equal(shouldSpeak(blocks, 1, "skip", NONE), true);
    assert.equal(shouldSpeak(blocks, 6, "skip", NONE), true);
});

test("skip mode suppresses bodies", () => {
    assert.equal(shouldSpeak(blocks, 2, "skip", NONE), false);
    assert.equal(shouldSpeak(blocks, 7, "skip", NONE), false);
});

test("read mode speaks everything", () => {
    for (let i = 0; i < blocks.length; i++) {
        assert.equal(shouldSpeak(blocks, i, "read", NONE), true, `block ${i}`);
    }
});

test("a nested aside's title is suppressed with its parent's body", () => {
    // Skipping the theorem must not announce the proof buried inside it.
    assert.equal(shouldSpeak(blocks, 3, "skip", NONE), false);
});

test("entering an aside reads its body but not nested asides", () => {
    const entered = new Set(["T"]);
    assert.equal(shouldSpeak(blocks, 2, "skip", entered), true);
    assert.equal(shouldSpeak(blocks, 3, "skip", entered), true, "proof announced");
    assert.equal(shouldSpeak(blocks, 4, "skip", entered), false, "proof body");
});

test("nextSpeakable walks past suppressed subtrees", () => {
    // From the theorem body in skip mode: 2,3,4 are all suppressed.
    assert.equal(nextSpeakable(blocks, 2, "skip", NONE), 5);
    assert.equal(nextSpeakable(blocks, 7, "skip", NONE), 8);
    assert.equal(nextSpeakable(blocks, 2, "read", NONE), 2);
});

test("nextSpeakable reports the end of the page", () => {
    assert.equal(nextSpeakable(blocks, 9, "skip", NONE), -1);
});
