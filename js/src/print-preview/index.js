/**
 * Print-preview initialization and controls.
 *
 * Orchestrates the print-preview workflow: loading the printout section,
 * setting up paper size controls, managing solution visibility, creating
 * or adjusting pages, and wiring up header/footer toggles.
 */

import { toPixels, setPageGeometryCSS } from "./geometry.js";
import {
    adjustWorkspaceToFitPage,
    toggleWorkspaceHighlight,
} from "./workspace.js";
import {
    flattenParagraphsSections,
    waitForImages,
    adjustPrintoutPages,
    createPrintoutPages,
} from "./pages.js";
import { addHeadersAndFootersToPrintout } from "./headers-footers.js";
import { getPaperSize } from "./paper-size.js";
import { loadPrintout } from "./section-swap.js";
import { rewriteSolutions } from "./solutions.js";

export async function initPrintPreview() {
    const urlParams = new URLSearchParams(window.location.search);
    if (!urlParams.has("printpreview")) return;

    const printableSectionID = urlParams.get("printpreview");
    await loadPrintout(printableSectionID);

    // Parse margins
    const marginList = document
        .querySelector("section.worksheet, section.handout")
        .getAttribute("data-margins")
        .split(" ");
    const margins = {
        top: toPixels(marginList[0] || "0.75in"),
        right: toPixels(marginList[1] || "0.75in"),
        bottom: toPixels(marginList[2] || "0.75in"),
        left: toPixels(marginList[3] || "0.75in"),
    };

    rewriteSolutions();

    // Paper size setup
    let paperSize = getPaperSize();
    if (paperSize) {
        const radio = document.querySelector(
            `input[name="papersize"][value="${paperSize}"]`
        );
        if (radio) radio.checked = true;
        document.body.classList.remove("a4", "letter");
        document.body.classList.add(paperSize);
        setPageGeometryCSS({ paperSize, margins });
    }

    // Paper size radio change handlers
    const papersizeRadios = document.querySelectorAll(
        'input[name="papersize"]'
    );
    papersizeRadios.forEach((radio) => {
        radio.addEventListener("change", function () {
            if (this.checked) {
                document.body.classList.remove("a4", "letter");
                document.body.classList.add(this.value);
                localStorage.setItem("papersize", this.value);
                setPageGeometryCSS({ paperSize: this.value, margins });
                adjustWorkspaceToFitPage({
                    paperSize: this.value,
                    margins,
                });
            }
        });
    });

    // Solution visibility checkboxes
    for (const solutionType of ["hint", "answer", "solution"]) {
        const checkbox = document.getElementById(
            `hide-${solutionType}-checkbox`
        );
        if (!checkbox) continue;

        const storageKey = `hide-${solutionType}`;
        if (
            (solutionType === "answer" || solutionType === "solution") &&
            !localStorage.getItem(storageKey)
        ) {
            checkbox.checked = true;
            localStorage.setItem(storageKey, "true");
        }

        checkbox.checked = localStorage.getItem(storageKey) === "true";
        document.querySelectorAll(`div.${solutionType}`).forEach((elem) => {
            if (checkbox.checked) {
                elem.classList.add("hidden");
            } else {
                elem.classList.remove("hidden");
            }
        });

        checkbox.addEventListener("change", function () {
            localStorage.setItem(storageKey, this.checked);
            document
                .querySelectorAll(`div.${solutionType}`)
                .forEach((elem) => {
                    if (checkbox.checked) {
                        elem.classList.add("hidden");
                    } else {
                        elem.classList.remove("hidden");
                    }
                    adjustWorkspaceToFitPage({ paperSize, margins });
                });
        });
    }

    // Build pages
    const printoutSection = document.querySelector(
        "section.worksheet, section.handout"
    );
    if (printoutSection) {
        flattenParagraphsSections(printoutSection);
        await waitForImages(printoutSection);
    }

    if (document.querySelector(".onepage")) {
        adjustPrintoutPages();
    } else {
        createPrintoutPages(margins);
    }

    addHeadersAndFootersToPrintout();

    // Header/footer toggle checkboxes
    for (const hf of [
        "first-page-header",
        "running-header",
        "first-page-footer",
        "running-footer",
    ]) {
        const checkbox = document.getElementById(`print-${hf}-checkbox`);
        if (!checkbox) continue;

        checkbox.checked =
            localStorage.getItem(`print-${hf}`) === "true";
        document.querySelectorAll(`.${hf}`).forEach((elem) => {
            if (checkbox.checked) {
                elem.classList.remove("hidden");
            } else {
                elem.classList.add("hidden");
            }
        });

        checkbox.addEventListener("change", function () {
            localStorage.setItem(`print-${hf}`, this.checked);
            document.querySelectorAll(`.${hf}`).forEach((elem) => {
                if (checkbox.checked) {
                    elem.classList.remove("hidden");
                } else {
                    elem.classList.add("hidden");
                }
                adjustWorkspaceToFitPage({ paperSize, margins });
            });
        });
    }

    // Adjust workspace heights
    adjustWorkspaceToFitPage({ paperSize, margins });

    // Highlight workspace checkbox
    const highlightCheckbox = document.getElementById(
        "highlight-workspace-checkbox"
    );
    if (highlightCheckbox) {
        highlightCheckbox.checked =
            localStorage.getItem("highlightWorkspace") === "true";
        highlightCheckbox.addEventListener("change", function () {
            localStorage.setItem("highlightWorkspace", this.checked);
            toggleWorkspaceHighlight(this.checked);
        });
        toggleWorkspaceHighlight(highlightCheckbox.checked);
    }
}
