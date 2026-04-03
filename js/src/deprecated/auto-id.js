/**
 * Auto-ID generation for paragraphs without IDs.
 *
 * ⚠️ DEPRECATED / SUSPICIOUS: Generates IDs like "base-id-part2", "base-id-part3"
 * for <p> elements that lack an id, based on the nearest preceding <p> that has one.
 * Produces heavy console.log output. It is unclear whether any downstream code
 * depends on the generated IDs.
 */

export function initAutoId() {
    const noIdParagraphs = document.querySelectorAll(".main p:not([id])");
    for (let n = noIdParagraphs.length - 1; n >= 0; --n) {
        const e = noIdParagraphs[n];
        if (e.hasAttribute("id")) continue;
        if (e.classList.contains("watermark")) continue;

        // Find all preceding sibling <p> elements
        const prevParagraphs = [];
        let sibling = e.previousElementSibling;
        while (sibling) {
            if (sibling.tagName === "P") {
                prevParagraphs.push(sibling);
            }
            sibling = sibling.previousElementSibling;
        }

        if (prevParagraphs.length === 0) continue;

        let partsFound = 1;
        const partsToId = [e];
        for (let i = 0; i < prevParagraphs.length; ++i) {
            const thisPrevious = prevParagraphs[i];
            if (!thisPrevious.hasAttribute("id")) {
                partsToId.unshift(thisPrevious);
            } else {
                const baseId = thisPrevious.id;
                for (let j = 0; j < partsToId.length; ++j) {
                    ++partsFound;
                    const nextId = baseId + "-part" + partsFound.toString();
                    partsToId[j].setAttribute("id", nextId);
                }
                break;
            }
        }
    }
}
