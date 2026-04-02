/**
 * PreTeXt Core — main entry point.
 *
 * Bundles all core PreTeXt JavaScript into a single IIFE script.
 * This replaces the old pattern of loading jquery.min.js + pretext.js +
 * pretext_add_on.js + knowl.js + lti_iframe_resizer.js as separate scripts.
 */

// --- Core modules (from pretext.js, knowl.js, lti_iframe_resizer.js) ---
import { initToc, initFocusedToc, initScrollToc } from "./toc.js";
import { initKnowls } from "./knowl.js";
import { initLtiIframeResizer } from "./lti-iframe-resizer.js";

// --- Modules extracted from pretext_add_on.js ---
import { initPermalinks } from "./permalink.js";
import { initImageMagnify } from "./image-magnify.js";
import { initGeoGebra } from "./geogebra.js";
import { initKeyboardNav, initAnchorKnowl } from "./keyboard-nav.js";
import { initPrintPreview } from "./print-preview/index.js";
import { isDarkMode, setDarkMode, initThemeToggle } from "./theme.js";
import { initShareButton, initEmbedMode } from "./embed.js";
import { initCodeCopyButtons, initCodeCopyHandler } from "./code-copy.js";

// --- Deprecated modules (included but flagged for future removal) ---
import { initAutoId } from "./deprecated/auto-id.js";
import { initVideoMagnify } from "./deprecated/video-magnify.js";

// Run dark mode immediately to avoid flash of wrong theme
setDarkMode(isDarkMode());

// --- DOMContentLoaded handlers ---
window.addEventListener("DOMContentLoaded", function () {
    // TOC and sidebar
    initToc();
    initFocusedToc();
    initScrollToc();

    // Permalinks
    initPermalinks();

    // Theme toggle button
    initThemeToggle();

    // Embed/share button and embed mode
    initShareButton();
    initEmbedMode();

    // Code copy buttons
    initCodeCopyButtons();

    // Print preview (conditionally activates based on URL params)
    initPrintPreview();
});

// --- Load handlers (need full page including images/styles) ---
window.addEventListener("load", function () {
    // Knowls
    initKnowls();

    // LTI iframe resizer
    initLtiIframeResizer();

    // Image magnification
    initImageMagnify();

    // GeoGebra calculator
    initGeoGebra();

    // Keyboard navigation (ESC/ENTER)
    initKeyboardNav();

    // Anchor-based knowl opening
    initAnchorKnowl();

    // Deprecated: auto-ID generation
    initAutoId();

    // Deprecated: video magnification (dead code — selector matches nothing)
    initVideoMagnify();
});

// Code copy click handler (uses event delegation, safe to register early)
initCodeCopyHandler();
