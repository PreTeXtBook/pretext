/**
 * Print-preview header and footer management.
 *
 * Adds editable header/footer divs to each page, populates them from
 * localStorage or data attributes, and persists edits back to localStorage.
 */

export function addHeadersAndFootersToPrintout() {
    const printout = document.querySelector(
        "section.worksheet, section.handout"
    );
    if (!printout) return;

    const pages = printout.querySelectorAll(".onepage");
    pages.forEach((page, index) => {
        const isFirstPage = index === 0;

        const headerDiv = document.createElement("div");
        headerDiv.classList.add(
            isFirstPage ? "first-page-header" : "running-header",
            "hidden"
        );
        headerDiv.innerHTML = `<div class="header-left" contenteditable="true"></div><div class="header-center" contenteditable="true"></div><div class="header-right" contenteditable="true"></div>`;
        page.insertBefore(headerDiv, page.firstChild);

        const footerDiv = document.createElement("div");
        footerDiv.classList.add(
            isFirstPage ? "first-page-footer" : "running-footer",
            "hidden"
        );
        footerDiv.innerHTML = `<div class="footer-left" contenteditable="true"></div><div class="footer-center" contenteditable="true"></div><div class="footer-right" contenteditable="true"></div>`;
        page.appendChild(footerDiv);
    });

    // Populate from localStorage or data attributes
    const keys = [
        "header-first-left",
        "header-first-center",
        "header-first-right",
        "footer-first-left",
        "footer-first-center",
        "footer-first-right",
        "header-running-left",
        "header-running-center",
        "header-running-right",
        "footer-running-left",
        "footer-running-center",
        "footer-running-right",
    ];

    const content = {};
    keys.forEach((key) => {
        content[key] =
            localStorage.getItem(key) ||
            printout.getAttribute(`data-${key}`) ||
            "";
    });

    // First page
    const firstHeader = document.querySelector(".first-page-header");
    if (firstHeader) {
        firstHeader.querySelector(".header-left").innerHTML =
            content["header-first-left"];
        firstHeader.querySelector(".header-center").innerHTML =
            content["header-first-center"];
        firstHeader.querySelector(".header-right").innerHTML =
            content["header-first-right"];
    }
    const firstFooter = document.querySelector(".first-page-footer");
    if (firstFooter) {
        firstFooter.querySelector(".footer-left").innerHTML =
            content["footer-first-left"];
        firstFooter.querySelector(".footer-center").innerHTML =
            content["footer-first-center"];
        firstFooter.querySelector(".footer-right").innerHTML =
            content["footer-first-right"];
    }

    // Running headers and footers
    document.querySelectorAll(".running-header").forEach((headerDiv) => {
        headerDiv.querySelector(".header-left").innerHTML =
            content["header-running-left"];
        headerDiv.querySelector(".header-center").innerHTML =
            content["header-running-center"];
        headerDiv.querySelector(".header-right").innerHTML =
            content["header-running-right"];
    });
    document.querySelectorAll(".running-footer").forEach((footerDiv) => {
        footerDiv.querySelector(".footer-left").innerHTML =
            content["footer-running-left"];
        footerDiv.querySelector(".footer-center").innerHTML =
            content["footer-running-center"];
        footerDiv.querySelector(".footer-right").innerHTML =
            content["footer-running-right"];
    });

    // Persist edits to localStorage
    const selectorMap = {
        "header-first-left": ".first-page-header .header-left",
        "header-first-center": ".first-page-header .header-center",
        "header-first-right": ".first-page-header .header-right",
        "footer-first-left": ".first-page-footer .footer-left",
        "footer-first-center": ".first-page-footer .footer-center",
        "footer-first-right": ".first-page-footer .footer-right",
        "header-running-left": ".running-header .header-left",
        "header-running-center": ".running-header .header-center",
        "header-running-right": ".running-header .header-right",
        "footer-running-left": ".running-footer .footer-left",
        "footer-running-center": ".running-footer .footer-center",
        "footer-running-right": ".running-footer .footer-right",
    };
    keys.forEach((key) => {
        const elements = document.querySelectorAll(selectorMap[key]);
        elements.forEach((elem) => {
            elem.addEventListener("input", () => {
                localStorage.setItem(key, elem.innerHTML);
            });
        });
    });
}
