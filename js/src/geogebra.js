/**
 * GeoGebra calculator integration.
 *
 * Manages the floating GeoGebra calculator overlay: toggling visibility,
 * preventing body scroll while hovering the canvas, and injecting the
 * GeoGebra applet script on first open.
 */

import { getScrollbarWidth } from "./deprecated/scrollbar-width.js";

function calculatorOnload() {
    const toggle = document.getElementById("calculator-toggle");
    if (toggle) toggle.focus();
    const inputField = document.querySelector(
        "input.gwt-SuggestBox.TextField"
    );
    if (inputField) inputField.focus();
}

export function initGeoGebra() {
    const scrollWidth = getScrollbarWidth();
    const calcOffsetR = 5;
    const calcOffsetB = 5;

    // Prevent body scroll when hovering the GeoGebra canvas
    document.body.addEventListener("mouseover", function (event) {
        if (!event.target.closest("#geogebra-calculator canvas")) return;
        document.body.style.overflow = "hidden";
        document.documentElement.style.marginRight = "15px";
        const container = document.getElementById("calculator-container");
        if (container) {
            container.style.right = calcOffsetR + scrollWidth + "px";
            container.style.bottom = calcOffsetB + scrollWidth + "px";
        }
    });

    document.body.addEventListener("mouseout", function (event) {
        if (!event.target.closest("#geogebra-calculator canvas")) return;
        document.body.style.overflow = "scroll";
        document.documentElement.style.marginRight = "0";
        const container = document.getElementById("calculator-container");
        if (container) {
            container.style.right = calcOffsetR + "px";
            container.style.bottom = calcOffsetB + "px";
        }
    });

    // Toggle calculator visibility
    document.body.addEventListener("click", function (event) {
        const toggle = event.target.closest("#calculator-toggle");
        if (!toggle) return;

        const container = document.getElementById("calculator-container");
        if (!container) return;

        if (container.style.display === "none" || !container.style.display) {
            container.style.display = "block";
            toggle.classList.add("open");
            toggle.setAttribute("title", "Hide calculator");
            toggle.setAttribute("aria-expanded", "true");

            const existingScript = document.getElementById("create_ggb_calc");
            if (!existingScript) {
                const ggbScript = document.createElement("script");
                ggbScript.id = "create_ggb_calc";
                ggbScript.innerHTML = "ggbApp.inject('geogebra-calculator')";
                document.body.appendChild(ggbScript);
            } else {
                calculatorOnload();
            }
        } else {
            container.style.display = "none";
            toggle.classList.remove("open");
            toggle.setAttribute("title", "Show calculator");
            toggle.setAttribute("aria-expanded", "false");
        }
    });
}
