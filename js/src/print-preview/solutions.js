/**
 * Solution rewriting for print preview.
 *
 * Converts <details>/<summary> solution elements into plain <div>s
 * with a heading, so they render properly in print layout.
 */

export function rewriteSolutions() {
    const bornHiddenKnowls = document.querySelectorAll(
        ".worksheet details, .handout details"
    );
    bornHiddenKnowls.forEach(function (detail) {
        const summary = detail.querySelector("summary");
        const content = detail.innerHTML.replace(summary.outerHTML, "");
        const div = document.createElement("div");
        div.classList = detail.classList;
        if (summary) {
            const title = document.createElement("h5");
            title.innerHTML = summary.innerHTML;
            div.appendChild(title);
        }
        const body = document.createElement("div");
        body.innerHTML = content;
        div.appendChild(body);
        detail.parentNode.replaceChild(div, detail);
    });
}
