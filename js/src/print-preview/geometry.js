/**
 * Print-preview page geometry helpers.
 *
 * Utilities for converting CSS units to pixels, computing element heights,
 * and injecting dynamic @page / CSS-variable rules.
 */

export function toPixels(value) {
    if (typeof value === "number") return value;
    if (typeof value !== "string") return 0;
    value = value.trim();
    if (value.endsWith("px")) {
        return parseFloat(value);
    } else if (value.endsWith("in")) {
        return Math.floor(parseFloat(value) * 96);
    } else if (value.endsWith("cm")) {
        return Math.floor(parseFloat(value) * 37.8);
    } else if (value.endsWith("mm")) {
        return Math.floor(parseFloat(value) * 3.78);
    } else if (value.endsWith("pt")) {
        return Math.floor(parseFloat(value) * (96 / 72));
    } else {
        return parseFloat(value) || 0;
    }
}

export function getElementTotalHeight(elem) {
    const style = getComputedStyle(elem);
    const marginTop = parseFloat(style.marginTop);
    const marginBottom = parseFloat(style.marginBottom);
    const height = elem.offsetHeight;
    return height + marginTop + marginBottom;
}

export function getElemWorkspaceHeight(elem) {
    if (elem.classList.contains("sidebyside")) {
        const sbspanels = elem.querySelectorAll(".sbspanel");
        let max = 0;
        sbspanels.forEach((panel) => {
            const workspaces = panel.querySelectorAll(".workspace");
            let totalHeight = 0;
            workspaces.forEach((workspace) => {
                const workspaceHeight = workspace.offsetHeight;
                if (workspaceHeight) {
                    totalHeight += workspaceHeight;
                }
            });
            if (totalHeight > max) {
                max = totalHeight;
            }
        });
        return max;
    }

    let columns = 1;
    if (elem.classList.contains("exercisegroup")) {
        for (let i = 2; i <= 6; i++) {
            if (elem.querySelector(`.cols${i}`)) {
                columns = i;
                break;
            }
        }
    }
    const workspaces = elem.querySelectorAll(".workspace");
    let totalHeight = 0;
    workspaces.forEach((ws) => {
        const workspaceHeight = ws.offsetHeight;
        if (workspaceHeight) {
            totalHeight += workspaceHeight;
        }
    });
    return totalHeight / columns;
}

export function setPageGeometryCSS({ paperSize, margins }) {
    const existingStyle = document.getElementById("page-geometry-css");
    if (existingStyle) {
        existingStyle.remove();
    }
    const wsWidth = paperSize === "letter" ? "816px" : "794px";
    const wsHeight = paperSize === "letter" ? "1056px" : "1123px";

    const style = document.createElement("style");
    style.id = "page-geometry-css";
    style.textContent = `
        :root {
            --ws-width: ${wsWidth};
            --ws-height: ${wsHeight};
            --ws-top-margin: ${margins.top}px;
            --ws-right-margin: ${margins.right}px;
            --ws-bottom-margin: ${margins.bottom}px;
            --ws-left-margin: ${margins.left}px;
        }
        @page {
            margin: var(--ws-top-margin, ${margins.top}px) var(--ws-right-margin, ${margins.right}px) var(--ws-bottom-margin, ${margins.bottom}px) var(--ws-left-margin, ${margins.left}px);
        }
    `;
    document.head.appendChild(style);
}
