/**
 * Dark/light mode switching.
 *
 * Detects user preference via localStorage or `prefers-color-scheme`,
 * toggles the `dark-mode` class on `<html>` and syncs to embedded iframes.
 */

export function isDarkMode() {
    if (document.documentElement.dataset.darkmode === "disabled") return false;

    const currentTheme = localStorage.getItem("theme");
    if (currentTheme === "dark") return true;
    if (currentTheme === "light") return false;

    return (
        window.matchMedia &&
        window.matchMedia("(prefers-color-scheme: dark)").matches
    );
}

export function setDarkMode(isDark) {
    if (document.documentElement.dataset.darkmode === "disabled") return;

    const parentHtml = document.documentElement;
    const iframes = document.querySelectorAll(
        "iframe[data-dark-mode-enabled]"
    );

    if (isDark) {
        parentHtml.classList.add("dark-mode");
    } else {
        parentHtml.classList.remove("dark-mode");
    }

    // Sync each iframe's <html> class with the parent
    for (const iframe of iframes) {
        try {
            const iframeHtml = iframe.contentWindow.document.documentElement;
            if (isDark) {
                iframeHtml.classList.add("dark-mode");
            } else {
                iframeHtml.classList.remove("dark-mode");
            }
        } catch (err) {
            console.warn("Dark mode sync to iframe failed:", err);
        }
    }

    const modeButton = document.getElementById("light-dark-button");
    if (modeButton) {
        modeButton.querySelector(".icon").innerText = isDark
            ? "light_mode"
            : "dark_mode";
        modeButton.querySelector(".name").innerText = isDark
            ? "Light Mode"
            : "Dark Mode";
    }
}

export function initThemeToggle() {
    // Run immediately to avoid flicker
    setDarkMode(isDarkMode());

    // Wire up button after DOM is ready (called from entry point's DOMContentLoaded)
    const isDark = isDarkMode();
    setDarkMode(isDark);

    const modeButton = document.getElementById("light-dark-button");
    if (modeButton) {
        modeButton.addEventListener("click", function () {
            const wasDark = isDarkMode();
            setDarkMode(!wasDark);
            localStorage.setItem("theme", wasDark ? "light" : "dark");
        });
    }
}
