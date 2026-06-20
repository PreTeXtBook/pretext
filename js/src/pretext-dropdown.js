// Standard dropdown widget for PreTeXt UI.
// Uses ordinary DOM state and ARIA attributes; intentionally does not use the
// popover API so it works with existing positioned navbar menus. Potentially
// revisit that once popover support is more widespread and stable.

class PTXDropdown {
    // dropdownElement: menu element to show and hide
    // openButton: element that toggles the dropdown and receives focus on close
    constructor(dropdownElement, openButton = null, options = {}) {
        this.dropdown = dropdownElement;
        this.controlElement = openButton;
        this.closeOnSelect = options.closeOnSelect !== false;

        if (!this.dropdown) {
            console.warn("PTXDropdown: No dropdown element provided.");
            return;
        }

        this.dropdown.hidden = true;

        if (this.controlElement) {
            this.controlElement.setAttribute("aria-expanded", "false");
            this.controlElement.setAttribute("aria-controls", this.dropdown.id);
            this.controlElement.addEventListener("click", (event) => {
                event.preventDefault();
                this.toggle();
            });
            this.controlElement.addEventListener("keydown", (event) => {
                if (event.key === "ArrowDown" || event.key === "Enter" || event.key === " ") {
                    event.preventDefault();
                    this.open({ focusMenu: true });
                }
            });
            // Close on escape even if opened via click and focus is on button
            this.controlElement.addEventListener("keydown", (event) => {
                if (event.key === "Escape" && this.isOpen()) {
                    event.preventDefault();
                    this.close();
                }
            });
        }

        this.dropdown.addEventListener("keydown", (event) => this.handleKeydown(event));
        this.dropdown.addEventListener("click", (event) => {
            if (this.closeOnSelect && event.target.closest('[role="menuitem"], a, button')) {
                this.close({ restoreFocus: false });
            }
        });


        document.addEventListener("click", (event) => {
            if (!this.isOpen()) return;
            if (this.dropdown.contains(event.target) || this.controlElement?.contains(event.target)) {
                return;
            }
            this.close({ restoreFocus: false });
        });
    }

    isOpen() {
        return !this.dropdown.hidden;
    }

    setExpanded(expanded) {
        this.dropdown.hidden = !expanded;
        this.dropdown.classList.toggle("open", expanded);
        if (this.controlElement) {
            this.controlElement.setAttribute("aria-expanded", expanded ? "true" : "false");
            this.controlElement.classList.toggle("open", expanded);
        }
    }

    open(options = {}) {
        // All links should not be tabbable, navigation is via arrow keys
        // Links may have been added post-initialization, so set tabindex here rather than on initialization
        this.dropdown.querySelectorAll("a").forEach((link) => {
            link.setAttribute("tabindex", "-1");
        });

        this.setExpanded(true);
        if (options.focusMenu) {
            this.focusFirstItem();
        }
    }

    close(options = {}) {
        this.setExpanded(false);
        if (options.restoreFocus !== false && this.controlElement) {
            this.controlElement.focus();
        }
    }

    toggle() {
        if (this.isOpen()) {
            this.close();
        } else {
            this.open();
        }
    }

    menuItems() {
        return Array.from(this.dropdown.querySelectorAll('[role="menuitem"], a, button'))
            .filter((item) => !item.hasAttribute("disabled") && item.getAttribute("aria-disabled") !== "true");
    }

    focusFirstItem() {
        this.menuItems()[0]?.focus();
    }

    focusLastItem() {
        const items = this.menuItems();
        items[items.length - 1]?.focus();
    }

    focusNextItem(currentItem, direction) {
        const items = this.menuItems();
        if (!items.length) return;

        const currentIndex = items.indexOf(currentItem);
        const nextIndex = currentIndex === -1
            ? 0
            : (currentIndex + direction + items.length) % items.length;
        items[nextIndex].focus();
    }

    handleKeydown(event) {
        switch (event.key) {
            case "Escape":
                event.preventDefault();
                this.close();
                break;
            case "ArrowDown":
                event.preventDefault();
                this.focusNextItem(document.activeElement, 1);
                break;
            case "ArrowUp":
                event.preventDefault();
                this.focusNextItem(document.activeElement, -1);
                break;
            case "Home":
                event.preventDefault();
                this.focusFirstItem();
                break;
            case "End":
                event.preventDefault();
                this.focusLastItem();
                break;
            case "Tab":
                this.close({ restoreFocus: false });
                break;
        }
    }
}

window.PTXDropdown = PTXDropdown;
