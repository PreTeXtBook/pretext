/**
 * Embed/share button and embed-mode display.
 *
 * Provides the "embed in LMS" button that copies an <iframe> snippet,
 * and strips chrome when the page is loaded in embed mode (?embed).
 */

import { setDarkMode } from "./theme.js";

export function initShareButton() {
    const shareButton = document.getElementById("embed-button");
    if (!shareButton) return;

    const sharePopup = document.getElementById("embed-popup");
    const embedCode =
        "<iframe src='" +
        window.location.href +
        "?embed' width='100%' height='1000px' frameborder='0'></iframe>";
    const embedTextbox = document.getElementById("embed-code-textbox");
    if (embedTextbox) {
        embedTextbox.value = embedCode;
    }

    shareButton.addEventListener("click", function () {
        sharePopup.classList.toggle("hidden");
    });

    const copyButton = document.getElementById("copy-embed-button");
    if (copyButton) {
        copyButton.addEventListener("click", function () {
            const textbox = document.getElementById("embed-code-textbox");
            if (textbox) {
                navigator.clipboard
                    .writeText(embedCode)
                    .then(() => {
                        console.log("Embed code copied to clipboard!");
                    })
                    .catch((err) => {
                        console.error("Failed to copy embed code: ", err);
                    });
                copyButton.querySelector(".icon").innerText =
                    "library_add_check";
                setTimeout(function () {
                    copyButton.querySelector(".icon").innerText =
                        "content_copy";
                    sharePopup.classList.add("hidden");
                }, 450);
            }
        });
    }
}

export function initEmbedMode() {
    const urlParams = new URLSearchParams(window.location.search);
    if (!urlParams.has("embed")) return;

    // Set dark mode based on value of param
    if (urlParams.get("embed") === "dark") {
        setDarkMode(true);
    } else {
        setDarkMode(false);
    }

    const elemsToHide = [
        "ptx-navbar",
        "ptx-masthead",
        "ptx-page-footer",
        "ptx-sidebar",
        "ptx-content-footer",
    ];
    for (const id of elemsToHide) {
        const elem = document.getElementById(id);
        if (elem) {
            elem.classList.add("hidden");
        }
    }
}
