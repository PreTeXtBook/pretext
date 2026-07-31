/*******************************************************************************
 * navigation.js — moving around the document tree, statelessly
 *******************************************************************************
 * Every function here answers "where should the reader go next?" purely from
 * *where they are*, never from how they arrived.  That is the whole design:
 * a stack of frames recording how the listener got somewhere would desync the
 * moment they clicked into the middle of a proof (click-to-start) or stepped
 * across a knowl boundary with the arrow keys.  Ancestry is derived from
 * position, so there is nothing to keep in sync and every entry point behaves
 * correctly.
 *
 * No DOM access: blocks are the plain data collector.js produces, so this file
 * unit-tests alongside the segmenter (see test/navigation.test.js).
 *
 * INPUT — blocks, as produced by collector.js:
 *   Block: { el?, tokens, path: Node[], summary: boolean }
 *     path     root-to-leaf ancestry, from nodes.js
 *     summary  true for the always-read title of an aside, false for its body
 *
 * Nodes are compared by identity (their `el`), so tests can use plain objects.
 * Every "find" returns a block index, or -1 when there is nowhere to go.
 ******************************************************************************/

const pathOf = (blocks, index) => (blocks[index] && blocks[index].path) || [];

const pathHas = (path, node) => path.some((n) => n.el === node.el);

/**
 * The innermost node containing this block that satisfies `predicate`.
 * Innermost wins because the listener's "skip this" means the tightest thing
 * they are inside — the proof, not the section containing it.
 */
export function innermost(blocks, index, predicate = () => true) {
    const path = pathOf(blocks, index);
    for (let i = path.length - 1; i >= 0; i--) {
        if (predicate(path[i])) return path[i];
    }
    return null;
}

/** The innermost aside (born-hidden knowl, footnote, description) around a block. */
export function enclosingAside(blocks, index) {
    return innermost(blocks, index, (n) => n.aside);
}

/**
 * The innermost *content* node around a block — a theorem, example, proof —
 * ignoring divisions.  This is what "skip the current block" acts on; without
 * the filter it would skip the whole enclosing section.
 */
export function enclosingBlock(blocks, index) {
    return innermost(blocks, index, (n) => n.family !== "division");
}

/** First block belonging to `node`, or -1. */
export function firstBlockIn(blocks, node) {
    for (let i = 0; i < blocks.length; i++) {
        if (pathHas(blocks[i].path, node)) return i;
    }
    return -1;
}

/** First block of `node`'s body, skipping its always-read title. */
export function firstBodyBlockIn(blocks, node) {
    for (let i = 0; i < blocks.length; i++) {
        if (pathHas(blocks[i].path, node) && !blocks[i].summary) return i;
    }
    return -1;
}

/**
 * First block at or after `index` that is no longer inside `node` — where
 * reading resumes when the listener skips or finishes a subtree.  Returns -1
 * when the node runs to the end of the page, which the caller reads as "stop".
 */
export function nextBlockOutside(blocks, index, node) {
    for (let i = Math.max(0, index); i < blocks.length; i++) {
        if (!pathHas(blocks[i].path, node)) return i;
    }
    return -1;
}

/**
 * The next block that *begins* a node matching `predicate`, after `index`.
 * "Begins" matters: without it, walking forward inside a long theorem would
 * report that same theorem as the next one.
 */
export function nextNodeStart(blocks, index, predicate) {
    const current = pathOf(blocks, index);
    for (let i = index + 1; i < blocks.length; i++) {
        const path = pathOf(blocks, i);
        for (const node of path) {
            if (!predicate(node)) continue;
            // Newly entered: not an ancestor we were already inside.
            if (!pathHas(current, node) && !pathHas(pathOf(blocks, i - 1), node)) {
                return i;
            }
        }
    }
    return -1;
}

/** Next node of a given "-like" family, e.g. jump to the next theorem. */
export function nextOfFamily(blocks, index, family) {
    return nextNodeStart(blocks, index, (n) => n.family === family);
}

/**
 * Where reading should continue when the listener skips the block they are
 * in — the next block outside the innermost theorem/example/proof.
 */
export function skipTarget(blocks, index) {
    const node = enclosingBlock(blocks, index);
    return node ? nextBlockOutside(blocks, index, node) : -1;
}

//------------------------------------------------------------------
// Block-level movement along the page
//
// Distinct from the tree predicates above: these walk the reading order one
// block at a time, which is how the arrow keys behave.  They take the *plan*
// rather than the blocks, since "am I part-way through this block?" is a
// question about utterances.

/** First plan index belonging to the same block as `planIndex`. */
export function blockStart(plan, planIndex) {
    const item = plan[planIndex];
    if (!item) return -1;
    let i = planIndex;
    while (i > 0 && plan[i - 1].blockIndex === item.blockIndex) i--;
    return i;
}

/**
 * Start of the previous block, or of this one when the listener is part-way
 * through it — "up" means "back to where this started" before it means
 * "back one block", which is what makes repeated presses walk backwards.
 */
export function previousBlockStart(plan, planIndex, allowed) {
    const start = blockStart(plan, planIndex);
    if (start === -1) return -1;
    if (start !== planIndex) return start;
    for (let i = start - 1; i >= 0; i--) {
        if (plan[i].blockIndex !== plan[start].blockIndex) {
            const candidate = blockStart(plan, i);
            if (!allowed || allowed(plan[candidate].blockIndex)) return candidate;
            i = candidate;
        }
    }
    return -1;
}

/** Start of the next block in reading order. */
export function nextBlockStart(plan, planIndex, allowed) {
    const item = plan[planIndex];
    if (!item) return -1;
    for (let i = planIndex + 1; i < plan.length; i++) {
        if (plan[i].blockIndex !== item.blockIndex) {
            if (!allowed || allowed(plan[i].blockIndex)) return i;
            // Skip the whole of a disallowed block, not just its first line.
            const skipped = plan[i].blockIndex;
            while (i + 1 < plan.length && plan[i + 1].blockIndex === skipped) i++;
        }
    }
    return -1;
}

/**
 * Traversal filter for the aside listening modes.
 *
 * Titles are always read: a sighted reader sees an aside's heading whether or
 * not they click it, so "skip" must still announce that the aside exists —
 * otherwise it is invisible to the listener and the arrow keys have nothing
 * to land on.  The mode governs only the body.
 *
 * `entered` is the set of aside nodes the listener explicitly opened, which
 * override the mode for that aside alone.
 */
export function shouldSpeak(blocks, index, mode, entered) {
    const block = blocks[index];
    if (!block) return false;
    const asides = block.path.filter((n) => n.aside);

    // A title is always read, so the aside it names does not gate it — but
    // any aside *containing* that one still does.  Without this, skipping a
    // theorem's body would still announce the proof nested inside it, which
    // the listener has no way to reach and did not ask to hear.
    const gating = block.summary ? asides.slice(0, -1) : asides;
    return gating.every(
        (n) => mode === "read" || (entered ? entered.has(n.el) : false)
    );
}

/**
 * The next block to speak at or after `index` under the current mode, or -1
 * at the end of the page.
 */
export function nextSpeakable(blocks, index, mode, entered) {
    for (let i = Math.max(0, index); i < blocks.length; i++) {
        if (shouldSpeak(blocks, i, mode, entered)) return i;
    }
    return -1;
}
