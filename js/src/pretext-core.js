/*******************************************************************************
 * pretext-core.js  —  entry point for the core PreTeXt bundle
 *******************************************************************************
 * This file is NOT shipped directly. jsbuilder.mjs reads it as the entry point
 * for esbuild, which bundles these imports into js/dist/pretext-core.js.
 *
 * Load order matters: pretext-dialog.js defines PTXDialog (used by
 * pretext_search.js), and knowl.js hooks into the DOM at "load" time alongside
 * pretext_add_on.js, so they need to share the same event-listener order they
 * had when loaded as separate <script> elements.
 *
 * When adding new always-loaded scripts, import them here rather than adding
 * additional <script> tags to the XSL.
 ******************************************************************************/

import './pretext-dialog.js';
import './pretext-dropdown.js';
import './readability-options.js';
import '../pretext.js';
import '../pretext_add_on.js';
import './pretext-embed.js';
import '../knowl.js';
