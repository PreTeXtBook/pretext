/**
 * Printout section loading (print preview).
 *
 * Swaps the current page content with the target printable section
 * and switches to the print-worksheet stylesheet.
 */

export async function loadPrintout(printableSectionID) {
    const themeStylesheetLink = document.querySelector(
        'link[rel="stylesheet"][href*="theme"]'
    );
    const themeStylesheetHref = themeStylesheetLink
        ? themeStylesheetLink.getAttribute("href")
        : null;

    if (themeStylesheetHref) {
        const printStylesheetHref = themeStylesheetHref.replace(
            /theme.*\.css/,
            "print-worksheet.css"
        );
        themeStylesheetLink.setAttribute("href", printStylesheetHref);
        await new Promise((resolve) => {
            themeStylesheetLink.addEventListener("load", resolve, {
                once: true,
            });
        });
    }

    const printableSection = document.getElementById(printableSectionID);
    if (!printableSection) {
        console.error("No section found with ID:", printableSectionID);
        return;
    }

    const ptxContent = document.querySelector(".ptx-content");
    const existingSections = ptxContent.querySelectorAll(":scope > section");
    existingSections.forEach((sec) => ptxContent.removeChild(sec));
    ptxContent.appendChild(printableSection);
}
