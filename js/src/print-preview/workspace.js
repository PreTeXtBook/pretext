/**
 * Print-preview workspace height management.
 *
 * Handles setting initial workspace heights from data attributes,
 * adjusting heights to fit pages, highlighting workspace areas,
 * and MathJax re-typesetting on workspace edits.
 */

import { getElementTotalHeight, getElemWorkspaceHeight } from "./geometry.js";

export function setInitialWorkspaceHeights() {
    const workspaces = document.querySelectorAll(".workspace");
    workspaces.forEach((ws) => {
        ws.style.height = ws.getAttribute("data-space") || "0px";
        ws.setAttribute("contenteditable", "true");
    });
}

export function adjustWorkspaceToFitPage({ paperSize, margins }) {
    // Toggle off workspace highlight if it is on
    const highlightCheckbox = document.getElementById(
        "highlight-workspace-checkbox"
    );
    const wasHighlighted = highlightCheckbox && highlightCheckbox.checked;
    if (wasHighlighted) {
        toggleWorkspaceHighlight(false);
    }

    let paperWidth, paperHeight;
    if (paperSize === "a4" || document.body.classList.contains("a4")) {
        paperWidth = 794;
        paperHeight = 1122.5;
    } else {
        paperWidth = 816;
        paperHeight = 1056;
    }
    const paperContentHeight = paperHeight - (margins.top + margins.bottom);

    setInitialWorkspaceHeights();

    const pages = document.querySelectorAll(".onepage");
    pages.forEach((page) => {
        page.style.width = paperWidth + "px";
        const rows = page.children;
        let totalContentHeight = 0;
        let totalWorkspaceHeight = 0;
        for (const row of rows) {
            totalContentHeight += getElementTotalHeight(row);
            totalWorkspaceHeight += getElemWorkspaceHeight(row);
        }
        if (totalWorkspaceHeight === 0) {
            page.style.width = "";
            return;
        }
        const extraHeight = paperContentHeight - totalContentHeight;
        const workspaceAdjustmentFactor =
            (totalWorkspaceHeight + extraHeight) / totalWorkspaceHeight;
        const pageWorkspaces = page.querySelectorAll(".workspace");
        pageWorkspaces.forEach((ws) => {
            const originalHeight = ws.offsetHeight;
            const newHeight = originalHeight * workspaceAdjustmentFactor;
            ws.style.height = newHeight + "px";
        });
        page.style.width = "";
    });

    if (wasHighlighted) {
        toggleWorkspaceHighlight(true);
    }
}

export function toggleWorkspaceHighlight(isChecked) {
    if (isChecked) {
        document.body.classList.add("highlight-workspace");
        if (!document.querySelector(".workspace-container")) {
            document.querySelectorAll(".workspace").forEach((workspace) => {
                const container = document.createElement("div");
                container.classList.add("workspace-container");
                container.style.height =
                    window.getComputedStyle(workspace).height;
                const original = document.createElement("div");
                original.classList.add("original-workspace");
                const originalHeight =
                    workspace.getAttribute("data-space") || "0px";
                original.setAttribute(
                    "title",
                    "Author-specified workspace height (" +
                        originalHeight +
                        ")"
                );
                original.style.height = originalHeight;
                container.appendChild(original);
                if (original.offsetHeight > workspace.offsetHeight) {
                    original.classList.add("warning");
                }
                workspace.parentNode.insertBefore(container, workspace);
                container.appendChild(workspace);
            });
        }
    } else {
        document.body.classList.remove("highlight-workspace");
        document
            .querySelectorAll(".workspace-container")
            .forEach((container) => {
                const workspace = container.querySelector(".workspace");
                container.parentNode.insertBefore(workspace, container);
                container.remove();
            });
    }
}

export function processWorkspace() {
    if (typeof MathJax !== "undefined" && MathJax.typesetPromise) {
        MathJax.typesetPromise();
    }
}
