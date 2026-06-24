// Handle controls for readability dialog / options
// This script needs to be run before initial render as it makes significant
// visual changes

//-----------------------------------------------------------------
// Dark/Light mode switching

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
// Line height controls

function getSavedLineHeight() {
    const savedLineHeight = localStorage.getItem("lineHeight");
    if (isValidLineHeight(savedLineHeight)) {
        return savedLineHeight;
    }
    return null;
}

function isValidLineHeight(value) {
    return value !== null && !isNaN(value) && Number(value) > 0 && Number(value) < 5;
}

function formatLineHeight(value) {
    return Number(value).toFixed(2);
}

function applyLineHeight(lineHeight) {
    if (isValidLineHeight(lineHeight)) {
        document.documentElement.style.setProperty("--ptx-content-line-height", lineHeight);
    }
}

function updateLineHeightOutput(output, lineHeight) {
    if (output) {
        output.value = formatLineHeight(lineHeight);
    }
}

//-----------------------------------------------------------------
// Font size controls

function getSavedFontSize() {
    const savedFontSize = localStorage.getItem("fontSize");
    if (isValidFontSize(savedFontSize)) {
        return savedFontSize;
    }
    return null;
}

function isValidFontSize(value) {
    return value !== null && !isNaN(value) && Number(value) > 0 && Number(value) < 5;
}

function formatFontSize(value) {
    return `${Math.round(Number(value) * 100)}%`;
}

function applyFontSize(fontSize) {
    if (isValidFontSize(fontSize)) {
        document.documentElement.style.setProperty("--ptx-content-font-size", formatFontSize(fontSize));
    }
}

function updateFontSizeOutput(output, fontSize) {
    if (output) {
        output.value = formatFontSize(fontSize);
    }
}

//-----------------------------------------------------------------
// Permalink accessibility controls

function getSavedAccessiblePermalinks() {
    return localStorage.getItem("accessiblePermalinks") === "true";
}

function setSavedAccessiblePermalinks(accessiblePermalinks) {
    if (accessiblePermalinks) {
        localStorage.setItem("accessiblePermalinks", "true");
    } else {
        localStorage.removeItem("accessiblePermalinks");
    }
}

function setAutopermalinksAccessible(accessible) {
    const autopermalinks = document.querySelectorAll('.autopermalink');
    autopermalinks.forEach(permalink => {
        const link = permalink.querySelector('a');
        if (!link) {
            return;
        }
        if (accessible) {
            permalink.removeAttribute('aria-hidden');
            link.setAttribute('tabindex', '0');
        } else {
            permalink.setAttribute('aria-hidden', 'true');
            link.setAttribute('tabindex', '-1');
        }
    });
}

//-----------------------------------------------------------------
// Core functionality

function resetReadabilityOptions(options) {
    localStorage.removeItem("theme");
    localStorage.removeItem("lineHeight");
    localStorage.removeItem("fontSize");
    localStorage.removeItem("accessiblePermalinks");

    const systemThemeInput = document.getElementById("ptx-readability-theme-system");
    if (systemThemeInput) {
        systemThemeInput.checked = true;
    }
    applyThemeChoice("system");

    if (options.lineHeightInput) {
        options.lineHeightInput.value = options.defaultLineHeight;
        updateLineHeightOutput(options.lineHeightOutput, options.defaultLineHeight);
        document.documentElement.style.removeProperty("--ptx-content-line-height");
    }

    if (options.fontSizeInput) {
        options.fontSizeInput.value = options.defaultFontSize;
        updateFontSizeOutput(options.fontSizeOutput, options.defaultFontSize);
        applyFontSize(options.defaultFontSize);
    }

    if (options.accessiblePermalinksInput) {
        options.accessiblePermalinksInput.checked = false;
        setAutopermalinksAccessible(false);
    }
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
    // apply again once DOM is loaded to make sure iframes are in sync
    setDarkMode(isDarkMode());

    const lineHeightInput = document.getElementById("ptx-readability-line-height");
    const lineHeightOutput = document.getElementById("ptx-readability-line-height-value");
    const defaultLineHeight = lineHeightInput ? lineHeightInput.defaultValue : null;
    const savedLineHeight = getSavedLineHeight();

    if (lineHeightInput) {
        if (savedLineHeight) {
            lineHeightInput.value = savedLineHeight;
            applyLineHeight(savedLineHeight);
        }
        updateLineHeightOutput(lineHeightOutput, lineHeightInput.value);

        lineHeightInput.addEventListener("input", function() {
            updateLineHeightOutput(lineHeightOutput, this.value);
            if (!isValidLineHeight(this.value)) {
                return;
            }
            localStorage.setItem("lineHeight", this.value);
            applyLineHeight(this.value);
        });
    }

    const fontSizeInput = document.getElementById("ptx-readability-font-size");
    const fontSizeOutput = document.getElementById("ptx-readability-font-size-value");
    const defaultFontSize = fontSizeInput ? fontSizeInput.defaultValue : null;
    const savedFontSize = getSavedFontSize();

    if (fontSizeInput) {
        if (savedFontSize) {
            fontSizeInput.value = savedFontSize;
            applyFontSize(savedFontSize);
        }
        updateFontSizeOutput(fontSizeOutput, fontSizeInput.value);

        fontSizeInput.addEventListener("input", function() {
            updateFontSizeOutput(fontSizeOutput, this.value);
            if (!isValidFontSize(this.value)) {
                return;
            }
            localStorage.setItem("fontSize", this.value);
            applyFontSize(this.value);
        });
    }

    const accessiblePermalinksInput = document.getElementById("ptx-readability-accessible-permalinks");
    if (accessiblePermalinksInput) {
        accessiblePermalinksInput.checked = getSavedAccessiblePermalinks();
        accessiblePermalinksInput.addEventListener("change", function() {
            setSavedAccessiblePermalinks(this.checked);
            setAutopermalinksAccessible(this.checked);
        });
    }
    setAutopermalinksAccessible(getSavedAccessiblePermalinks());

    const resetButton = document.getElementById("ptx-readability-reset-button");
    if (resetButton) {
        resetButton.addEventListener("click", function() {
            resetReadabilityOptions({
                fontSizeInput: fontSizeInput,
                fontSizeOutput: fontSizeOutput,
                defaultFontSize: defaultFontSize,
                accessiblePermalinksInput: accessiblePermalinksInput,
                defaultLineHeight: defaultLineHeight,
                lineHeightInput: lineHeightInput,
                lineHeightOutput: lineHeightOutput
            });
        });
    }
});


// Run these as soon as possible to avoid flicker - don't wait for DOMContentLoaded
// They may be re-applied on DOMContentLoaded, but this way we minimize the chance
// of a flash of unstyled content for users who have changed defaults from the system settings
setDarkMode(isDarkMode());
applyLineHeight(getSavedLineHeight());
applyFontSize(getSavedFontSize());


// isDarkMode is called from XSL-generated inline <script> blocks (e.g. mermaid).
// expose it globally
window.isDarkMode = isDarkMode;