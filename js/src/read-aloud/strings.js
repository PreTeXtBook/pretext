/*******************************************************************************
 * strings.js — the user-facing words read-aloud speaks or shows
 *******************************************************************************
 * These deliberately do *not* come from xsl/localizations.  That mechanism is
 * reserved for content reaching more than one output format, and read-aloud is
 * HTML-only: nothing here has a LaTeX or EPUB counterpart.  The remaining
 * words — button tooltips, dialog labels — are literal text in the XSL for the
 * same reason.
 *
 * Collecting them in one module keeps the eventual JavaScript-side translation
 * layer to a single swap: replace this object, and every announcement follows.
 *
 * Keys are the ids the rest of the feature already speaks in — announce tokens
 * carry `stringId` (collector.js), and block type names are keyed by the
 * `type` that nodes.js assigns.
 ******************************************************************************/

export const STRINGS = {
    // Toggle-button tooltips, one per state of the player's disclosure.
    "read-aloud-show": "Read aloud",
    "read-aloud-hide": "Hide reading controls",
    "read-aloud-play": "Play",
    "read-aloud-pause": "Pause",

    // Spoken in place of a block that has no useful linear reading.
    "read-aloud-skip-table": "Table. Skipping.",
    "read-aloud-skip-code": "Code. Skipping.",
    "read-aloud-skip-interactive": "Interactive element. Skipping.",

    // Spoken *before* an interactive exercise, whose prose is then read out:
    // the listener needs to know a question is coming and that answering it
    // means looking at the screen.  {kind} is Runestone's own name for the
    // component ("Multiple Choice", "Parsons", "Drag-N-Drop"), read out of
    // the page; the second form covers components that render no name.
    "read-aloud-interactive-kind": "{kind} exercise.",
    "read-aloud-interactive": "Interactive exercise.",

    // Spoken when MathJax reports no speech text for an equation.
    "read-aloud-equation-fallback": "equation",

    // Introduces an image's alt text, which is written to replace a picture
    // rather than to be read as part of the surrounding prose.
    "read-aloud-image-alt": "Image. Alt text is:",

    // Spoken at the end of a page before auto-continue navigates away.  A
    // listener with the page out of view has no other warning that they are
    // about to be somewhere else, and the pause it occupies is also their
    // chance to stop it.
    "read-aloud-continuing": "Continuing to the next page.",

    // Spoken after the name of a hidden block the listener has navigated to,
    // for the first few only: an audio interface shows no keys, so the only
    // way to learn one is to be told.
    "read-aloud-open-hint": "Press space to open.",

    // Type names for the two blocks whose headings carry no visible type: a
    // footnote shows only its number, an image description only an icon.
    // Every other block announces the name PreTeXt already renders.
    footnote: "Footnote",
    description: "Description",
};
