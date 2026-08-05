import {applyThemeChoice } from "./readability-options.js";

// Share button and embed in LMS code
window.addEventListener("DOMContentLoaded", function(event) {
    const shareButton = document.getElementById("ptx-embed-button");
    const sharePopupElement = document.getElementById("ptx-embed-popup");
    if (!shareButton || !sharePopupElement) {
        return;
    }
    const closeBtn = document.getElementById("ptx-embed-close-button");

    const sharePopup = new PTXDialog(
        sharePopupElement,
        shareButton,
        {
            kind: "light-close",
            closeButton: closeBtn
        }
    );

    const embedCode = "<iframe src='" + window.location.href + "?embed' width='100%' height='1000px' frameborder='0'></iframe>";
    const embedTextbox = document.getElementById("ptx-embed-code-textbox");
    if (embedTextbox) {
        embedTextbox.value = embedCode;
    }

    const copyButton = document.getElementById("ptx-embed-copy-button");
    if (copyButton) {
        if (navigator.clipboard) {
            copyButton.addEventListener("click", function() {
                const embedTextbox = document.getElementById("ptx-embed-code-textbox");
                if (embedTextbox) {
                    if (navigator.clipboard) {
                        navigator.clipboard.writeText(embedCode).then(() => {
                            console.log("Embed code copied to clipboard!");
                            copyButton.querySelector('.icon').innerText = "library_add_check";
                            setTimeout(function() {
                                copyButton.querySelector('.icon').innerText = "content_copy";
                                sharePopup.close();
                                shareButton.focus();
                            }, 450);
                        }).catch(err => {
                            console.error("Failed to copy embed code: ", err);
                        });
                    } else {
                        console.warn("Clipboard API not supported, falling back to manual copy.");
                    }
                }
            });
        } else {
            // If clipboard API is not supported, hide the copy button and
            // rely on users to manually copy from the textbox
            copyButton.style.display = "none";
        }
    }
});

// The embed URL carries the instructor's choice: plain "embed" asks for light,
// "embed=dark" for dark, so the frame can be made to match the LMS page around
// it.  We always enforce this theme and remove the choices from the reader.
function applyEmbedTheme(embedValue) {
    const instructorTheme = (embedValue === "dark") ? "dark" : "light";
    applyThemeChoice(instructorTheme);
}

// Strip the page down to its content when the URL has "embed" in it, as an
// instructor's LMS iframe loads it.
window.addEventListener("DOMContentLoaded", function(event) {
    const urlParams = new URLSearchParams(window.location.search);
    if (!urlParams.has("embed")) {
        return;
    }

    // Hands the page to _embed.scss, which restyles the navbar below into a
    // floating cluster in the top-right corner.
    document.body.classList.add("ptx-embedded");

    // "ptx-navbar" is deliberately absent from this list.  Hiding it used to be
    // how the table of contents, search and prev/next buttons were dropped, but
    // it took the reading settings and the read-aloud player down with them --
    // those live in the same bar, and they are the controls an embedded reader
    // most needs.  _embed.scss hides the navigation and keeps the rest.
    const elemsToHide = [
        "ptx-masthead",
        "ptx-page-footer",
        "ptx-sidebar",
        "ptx-content-footer"
    ];
    for (let id of elemsToHide) {
        const elem = document.getElementById(id);
        if (elem) {
            elem.classList.add("hidden");
        }
    }

    applyEmbedTheme(urlParams.get("embed"));
});
