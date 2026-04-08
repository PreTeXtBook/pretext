/**
 * Dynamic-programming page-break algorithm.
 *
 * Given a list of content blocks with heights and workspace heights,
 * finds page-break positions that minimize leftover whitespace variance
 * across pages.
 */

export function findPageBreaks(rows, pageHeight) {
    let pageBreaks = [];
    let minCost = Array(rows.length + 1).fill(Infinity);
    minCost[rows.length] = 0;
    let nextPageBreak = Array(rows.length).fill(-1);

    for (let i = rows.length - 1; i >= 0; i--) {
        let cumulativeHeight = 0;
        for (let j = i; j < rows.length; j++) {
            cumulativeHeight += rows[j].height;
            if (cumulativeHeight > pageHeight) {
                if (j === i) {
                    // Single row exceeds page height — give it its own page
                    minCost[i] = 0;
                    nextPageBreak[i] = i + 1;
                }
                break;
            }

            const cost =
                (pageHeight - cumulativeHeight) ** 2 + minCost[j + 1];
            if (cost < minCost[i]) {
                minCost[i] = cost;
                nextPageBreak[i] = j + 1;
            }
        }
    }

    // Backtrack: row 0 is always a title sharing the first page with row 1
    let nextPage = 1;
    while (nextPage < rows.length) {
        pageBreaks.push(nextPageBreak[nextPage]);
        nextPage = nextPageBreak[nextPage];
    }
    return pageBreaks;
}
