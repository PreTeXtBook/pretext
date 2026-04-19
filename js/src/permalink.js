/**
 * Permalink copy-to-clipboard functionality.
 *
 * Copies permalink URLs to the clipboard using the Clipboard API,
 * with a brief visual confirmation message.
 */

async function copyPermalink(linkNode) {
    if (!navigator.clipboard) {
        console.log("Error: Clipboard API not available");
        return;
    }
    const elem = linkNode.parentElement;
    if (!linkNode) {
        console.log("Error: Something went wrong finding permalink URL");
        return;
    }
    const url = linkNode.href;
    const description = elem.getAttribute("data-description");
    const link = `<a href="${url}">${description}</a>`;
    const msgLink = `<a class="internal" href="${url}">${description}</a>`;
    const textFallback = description + " \r\n" + url;
    let copySuccess = true;

    try {
        // NOTE: this method will only work in Firefox if the user has
        //    dom.events.asyncClipboard.clipboardItem
        // set to true in their about:config.
        await navigator.clipboard.write([
            new ClipboardItem({
                "text/html": new Blob([link], { type: "text/html" }),
                "text/plain": new Blob([textFallback], { type: "text/plain" }),
            }),
        ]);
    } catch (err) {
        console.log(
            "Permalink-to-clipboard using ClipboardItem failed, falling back to clipboard.writeText",
            err
        );
        copySuccess = false;
    }

    if (!copySuccess) {
        try {
            await navigator.clipboard.writeText(textFallback);
        } catch (err) {
            console.log(
                "Permalink-to-clipboard using clipboard.writeText failed",
                err
            );
            console.error("Failed to copy link to clipboard!");
            return;
        }
    }

    console.log(`copied '${url}' to clipboard`);
    const copiedMsg = document.createElement("p");
    copiedMsg.setAttribute("role", "alert");
    copiedMsg.className = "permalink-alert";
    copiedMsg.innerHTML = "Link to " + msgLink + " copied to clipboard";
    elem.parentElement.insertBefore(copiedMsg, elem);
    await new Promise((resolve) => setTimeout(resolve, 1500));
    copiedMsg.remove();
}

export function initPermalinks() {
    const permalinks = document.querySelectorAll(".autopermalink > a");
    permalinks.forEach((link) => {
        link.addEventListener("click", function (event) {
            event.preventDefault();
            copyPermalink(link);
        });
    });
}
