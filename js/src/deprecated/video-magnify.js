/**
 * Video magnification (resize YouTube iframes to full browser width).
 *
 * ⚠️ DEAD CODE: The selector `body iframeXXXX` intentionally matches no
 * elements.  This module is preserved for reference but has no effect.
 */

export function initVideoMagnify() {
    const allIframes = document.querySelectorAll("body iframeXXXX");
    for (let i = 0; i < allIframes.length; i++) {
        const thisItem = allIframes[i];
        const thisItemSrc = thisItem.src;
        if (!thisItemSrc.includes("youtube")) continue;

        const thisItemId = thisItem.id;
        const thisItemWidth = thisItem.width;
        const thisItemHeight = thisItem.height;
        if (thisItemHeight < 150) continue;

        const emptyDiv = document.createElement("div");
        const videomagContainer = document.createElement("div");
        const parentTag = thisItem.parentElement.tagName;
        if (parentTag === "FIGURE") {
            videomagContainer.setAttribute("class", "videobig");
        } else {
            videomagContainer.setAttribute("class", "videobig nofigure");
        }
        videomagContainer.setAttribute("video-id", thisItemId);
        videomagContainer.setAttribute("data-width", thisItemWidth);
        videomagContainer.setAttribute("data-height", thisItemHeight);
        videomagContainer.innerHTML = "fit width";

        thisItem.insertAdjacentElement("beforebegin", emptyDiv);
        thisItem.insertAdjacentElement("beforebegin", videomagContainer);
        thisItem.insertAdjacentElement("beforebegin", emptyDiv);
    }

    // Toggle handlers
    document.body.addEventListener("click", function (event) {
        const bigBtn = event.target.closest(".videobig");
        if (bigBtn) {
            const videoId = bigBtn.getAttribute("video-id");
            const video = document.getElementById(videoId);
            const originalWidth = parseInt(bigBtn.getAttribute("data-width"));
            const originalHeight = parseInt(bigBtn.getAttribute("data-height"));
            const browserWidth = window.innerWidth;
            const widthRatio = browserWidth / originalWidth;

            video.setAttribute("width", widthRatio * originalWidth);
            video.setAttribute("height", widthRatio * originalHeight);
            video.setAttribute(
                "style",
                "position:relative; left:-260px; z-index:1000"
            );
            bigBtn.setAttribute("class", "videosmall");
            bigBtn.innerHTML = "make small";
            return;
        }

        const smallBtn = event.target.closest(".videosmall");
        if (smallBtn) {
            const videoId = smallBtn.getAttribute("video-id");
            const video = document.getElementById(videoId);
            const originalWidth = smallBtn.getAttribute("data-width");
            const originalHeight = smallBtn.getAttribute("data-height");

            video.removeAttribute("style");
            video.setAttribute("width", originalWidth);
            video.setAttribute("height", originalHeight);
            smallBtn.setAttribute("class", "videobig");
            smallBtn.innerHTML = "fit width";
        }
    });
}
