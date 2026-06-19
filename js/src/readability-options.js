// Handle controls for readability dialog / options
// This script needs to be run before initial render as it makes significant
// visual changes

//-----------------------------------------------------------------
// Dark/Light mode swiching

function getSavedTheme() {
    const savedTheme = localStorage.getItem("theme");
    if (savedTheme === "light" || savedTheme === "dark") {
        return savedTheme;
    }
    return "system";
}

function setSavedTheme(theme) {
    if (theme === "system") {
        localStorage.removeItem("theme");
    } else {
        localStorage.setItem("theme", theme);
    }
}

function applyThemeChoice(theme) {
    if (theme === "system") {
        setDarkMode(isDarkMode());
    } else {
        setDarkMode(theme === "dark");
    }
}

function isDarkMode() {
    if (document.documentElement.dataset.darkmode === 'disabled')
        return false;

    const currentTheme = localStorage.getItem("theme");
    if (currentTheme === "dark")
        return true;
    else if (currentTheme === "light")
        return false;

    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
}

function setDarkMode(isDark) {
    if(document.documentElement.dataset.darkmode === 'disabled')
        return;

    const parentHtml = document.documentElement;
    const iframes = document.querySelectorAll("iframe[data-dark-mode-enabled]");

    // Update the parent document
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
              iframeHtml.classList.add("dark-mode")
            } else {
              iframeHtml.classList.remove("dark-mode")
            }
        } catch (err) {
            console.warn("Dark mode sync to iframe failed:", err);
        }
    }

}


//-----------------------------------------------------------------
// Core functionality

function resetReadabilityOptions(options) {
    localStorage.removeItem("theme");

    const systemThemeInput = document.getElementById("ptx-readability-theme-system");
    if (systemThemeInput) {
        systemThemeInput.checked = true;
    }
    applyThemeChoice("system");
}

window.addEventListener("DOMContentLoaded", function() {
    const readabilityButton = document.getElementById("ptx-readability-options-button");
    const readabilityPopupElement = document.getElementById("ptx-readability-options-popup");
    if (!readabilityButton || !readabilityPopupElement || !window.PTXDialog) {
        return;
    }

    const closeButton = document.getElementById("ptx-readability-options-close-button");
    new window.PTXDialog(
        readabilityPopupElement,
        readabilityButton,
        {
            closeButton: closeButton
        }
    );

    const themeInputs = readabilityPopupElement.querySelectorAll('input[name="ptx-readability-theme"]');
    const savedTheme = getSavedTheme();

    for (const input of themeInputs) {
        input.checked = input.value === savedTheme;
        input.addEventListener("change", function() {
            if (!this.checked) {
                return;
            }
            setSavedTheme(this.value);
            applyThemeChoice(this.value);
        });
    }

    // Listen for system theme changes and update if user has "system" selected
    if (window.matchMedia) {
        window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", function() {
            if (getSavedTheme() === "system") {
                applyThemeChoice("system");
            }
        });
    }
    // apply again once DOM is loadedto make sure iframes are in sync
    setDarkMode(isDarkMode());

    const resetButton = document.getElementById("ptx-readability-reset-button");
    if (resetButton) {
        resetButton.addEventListener("click", function() {
            resetReadabilityOptions({
            });
        });
    }
});


// Run these as soon as possible to avoid flicker - don't wait for DOMContentLoaded
// They may be re-applied on DOMContentLoaded, but this way we minimize the chance
// of a flash of unstyled content for users who have changed defaults from the system settings
setDarkMode(isDarkMode());


// isDarkMode is called from XSL-generated inline <script> blocks (e.g. mermaid).
// expose it globally
window.isDarkMode = isDarkMode;