/*******************************************************************************
 * nodes.js — which DOM elements count as navigable tree nodes
 *******************************************************************************
 * PreTeXt's HTML preserves the authoring tree: every major block is emitted as
 * an element carrying both its PreTeXt element name and its "-like" family
 * (e.g. `<article class="lemma theorem-like">`), and divisions nest as
 * `<section>`s.  That is the tree a listener wants to move around in, so this
 * file is the single place that maps CSS classes to node descriptors — the one
 * spot coupled to PreTeXt's class vocabulary.
 *
 * A descriptor is plain data plus the element:
 *   { el, type, family, aside }
 *     type    the PreTeXt element name  ("lemma", "example", "section")
 *     family  the "-like" grouping      ("theorem-like") or "division"
 *     aside   true for content a sighted reader must click to see
 *
 * Granularity is deliberately coarse: the major blocks an author thinks in,
 * not every list item.  Navigating to "the next theorem-like" is useful;
 * stopping at every `case` or `li` would make navigation unusable.
 ******************************************************************************/

// The "-like" families PreTeXt emits.  Membership here is what makes a block
// a navigable node, so adding a family is how navigation grows later.
const FAMILIES = new Set([
    "theorem-like",
    "definition-like",
    "example-like",
    "project-like",
    "remark-like",
    "computation-like",
    "assemblage-like",
    "goal-like",
    "openproblem-like",
    "exercise-like",
    "solution-like",
    "discussion-like",
    "aside-like",
    "figure-like",
    "table-like",
]);

// Divisions, which nest to form the document's spine.  Only ever read off a
// <section>, since these words also appear as classes on unrelated wrappers
// (e.g. `<div class="pretext article ignore-math">`).
const DIVISIONS = new Set([
    "article",
    "chapter",
    "section",
    "subsection",
    "subsubsection",
    "appendix",
    "exercises",
    "worksheet",
    "introduction",
    "conclusion",
    "paragraphs",
    "reading-questions",
    "references",
    "solutions",
    "glossary",
    "backmatter",
    "frontmatter",
]);

// Blocks with no "-like" family that still deserve to be nodes, because they
// are routinely born hidden and so are things a listener steps into or past.
// A born-hidden proof is emitted as "hiddenproof", not "proof", and missing
// that spelling makes it invisible to navigation: it is not recognized as an
// aside, so skipping its theorem still reads it, and the blocks inside it
// report the enclosing theorem as their type.
const BARE_BLOCKS = new Set(["proof", "hiddenproof"]);

// Content a sighted reader must click to reveal.  Each is a <details>, so the
// content is already in the DOM and needs no fetching (unlike xref knowls).
const ASIDE_CLASSES = {
    "born-hidden-knowl": null, // type comes from its own block classes
    "ptx-footnote": "footnote",
    "image-description": "description",
};

/**
 * Describe `el` as a tree node, or return null if it is not one.
 *
 * Called on every element during collection, so it stays allocation-light:
 * a single pass over classList with no regex.
 */
export function nodeDescriptor(el) {
    const classes = el.classList;
    if (!classes || classes.length === 0) return null;

    let family = null;
    let type = null;
    let aside = false;

    for (const name of classes) {
        if (FAMILIES.has(name)) {
            family = name;
        } else if (name in ASIDE_CLASSES) {
            aside = true;
            if (ASIDE_CLASSES[name]) type = ASIDE_CLASSES[name];
        }
    }

    // The PreTeXt element name is the first class token: "lemma theorem-like"
    // yields "lemma".  A block emitted with only its family (some generated
    // content does this) falls back to the family name.
    if (family && !type) {
        type = classes[0] === family ? family : classes[0];
    }

    if (!type && BARE_BLOCKS.has(classes[0])) {
        type = classes[0];
    }

    if (!type && el.tagName === "SECTION" && DIVISIONS.has(classes[0])) {
        type = classes[0];
        family = "division";
    }

    return type ? { el, type, family, aside } : null;
}

/** True when the node is one the listener chose not to see by default. */
export function isAside(node) {
    return !!node && node.aside;
}
