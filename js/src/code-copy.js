/**
 * Code block copy-to-clipboard button.
 *
 * Wraps `.clipboardable` elements with a container and injects a copy
 * button.  Clicking the button copies the `<pre>` content.
 */

export function initCodeCopyButtons() {
    const elements = document.querySelectorAll(".clipboardable");
    for (const el of elements) {
        const div = document.createElement("div");
        div.classList.add("clipboardable");
        el.classList.remove("clipboardable");
        el.replaceWith(div);
        div.insertAdjacentElement("afterbegin", el);
        div.insertAdjacentHTML(
            "beforeend",
            `
    <button class="code-copy" title="Copy code" role="button" aria-label="Copy code" >
        <span class="copyicon material-symbols-outlined">content_copy</span>
        <span class="checkmark material-symbols-outlined">check</span>
    </button>
            `.trim()
        );
    }
}

export function initCodeCopyHandler() {
    document.addEventListener("click", (ev) => {
        const codeBox = ev.target.closest(".clipboardable");
        if (!navigator.clipboard || !codeBox) return;
        const button = ev.target.closest(".code-copy");
        if (!button) return;
        const preContent = codeBox.querySelector("pre").textContent;
        navigator.clipboard.writeText(preContent);
        button.classList.toggle("copied");
        setTimeout(() => button.classList.toggle("copied"), 1000);
    });
}
