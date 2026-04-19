/**
 * PreTeXt Search — search bundle entry point.
 *
 * Bundles the native search UI. Loaded only when the document
 * has native search enabled ($has-native-search).
 *
 * Expects these globals to be available (from lunr-pretext-search-index.js):
 *   - ptx_lunr_idx
 *   - ptx_lunr_docs
 *   - ptx_lunr_search_style
 * And from the lunr.js library:
 *   - lunr
 */

import { initSearch } from "./search.js";

window.addEventListener("load", function () {
    initSearch();
});
