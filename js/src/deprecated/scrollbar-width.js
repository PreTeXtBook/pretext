/**
 * Scrollbar width detection utility.
 *
 * ⚠️ DEPRECATED: Only used by the GeoGebra calculator integration.
 * Consider replacing with a CSS-based approach in the future.
 *
 * @see https://stackoverflow.com/questions/13382516/getting-scroll-bar-width-using-javascript
 */

export function getScrollbarWidth() {
    const outer = document.createElement("div");
    outer.style.visibility = "hidden";
    outer.style.width = "100px";
    outer.style.msOverflowStyle = "scrollbar"; // needed for WinJS apps

    document.body.appendChild(outer);

    const widthNoScroll = outer.offsetWidth;
    outer.style.overflow = "scroll";

    const inner = document.createElement("div");
    inner.style.width = "100%";
    outer.appendChild(inner);

    const widthWithScroll = inner.offsetWidth;
    outer.parentNode.removeChild(outer);

    return widthNoScroll - widthWithScroll;
}
