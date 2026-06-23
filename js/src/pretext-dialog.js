// Standard dialog widget for PreTeXt UI
// Builds on native dialog with accessibility enhancements and fallback for
// browsers with limited support

class PTXDialog {
    static hasNativeCommandInvokers() {
        return 'commandForElement' in HTMLButtonElement.prototype;
    }
    // dialogElement: should be a <dialog> element
    // openButton: is an optional element that triggers the dialog to open and will receive focus again when the dialog closes
    //             if provided, will automatically have an event listener added to open the dialog on click
    // options can include:
    // - kind: whether the dialog is "modal" (the default), "light-close" or "non-modal"
    //   - "modal" traps focus and must be dismissed with the close button or escape
    //   - "light-close" are model, but close if the user clicks outside the dialog
    //   - "non-modal" do not trap focus and can be interacted with while open
    // - closeButton: button element that should close the dialog when clicked
    //                If not provided for a modal dialog, one will be added.
    constructor(dialogElement, openButton = null, options = {}) {
        this.dialog = dialogElement;
        this.controlElement = openButton;
        this.kind = options.kind || "modal";
        this.isModal = this.kind === "modal" || this.kind === "light-close";

        // verify we have a dialog and set some basic attributes on the dialog
        if (!this.dialog) {
            console.log("PTXDialog: No dialog element provided.");
            return;
        }
        this.dialog.setAttribute("aria-modal", this.isModal ? "true" : "false");
        if (PTXDialog.hasNativeCommandInvokers()) {
            if (this.isModal) {
                this.dialog.closedBy = (this.kind !== "light-close") ? "closerequest" : "any";
            } else {
                // non-modal dialogs don't have a native closedBy behavior
                // but make explicit
                this.dialog.closedBy = "none";
            }
        }

        // set up the control element if provided
        if (this.controlElement ) {
            this.controlElement.setAttribute('aria-expanded', "false");
            this.controlElement.setAttribute('aria-controls', this.dialog.id);
            if(PTXDialog.hasNativeCommandInvokers()) {
                this.controlElement.commandFor = this.dialog.id;
            }
            if (this.isModal) {
                this.controlElement.addEventListener("click", () => this.open());
            } else {
                this.controlElement.addEventListener("click", () => this.toggle());
            }
        }

        this.closeButton = options.closeButton;
        // add a close button to modals unless the dialog already has one as identified in options
        if (!this.closeButton && this.isModal) {
            const topBar = document.createElement("div");
            topBar.classList.add("ptx-dialog-topbar");
            this.dialog.prepend(topBar);
            this.closeButton = document.createElement("button");
            this.closeButton.classList.add("button", "ptx-dialog-close-button");
            this.closeButton.setAttribute("aria-label", "Close dialog");
            this.closeButton.innerHTML = `<span class="material-symbols-outlined">close</span>`;
            topBar.appendChild(this.closeButton);
        }
        if (this.closeButton) {
            this.closeButton.addEventListener("click", () => this.close());
        }
        if (!this.isModal) {
            // For non-modal dialogs, make a top bar as a grab area for dragging
            const topBar = document.createElement("div");
            topBar.classList.add("ptx-dialog-topbar");
            this.topBar = topBar;
            this.dialog.prepend(topBar);
        }

        if (PTXDialog.hasNativeCommandInvokers()) {
            // If the browser supports command invokers, we can just use the native dialog element and its showModal and close methods.
            this.open = () => {
                if (this.isModal) {
                    this.dialog.showModal();
                } else {
                    this.dialog.show();
                }
                if (this.controlElement) {
                    this.setExpanded(true);
                }
            };
            this.close = () => {
                this.dialog.close();
                if (this.controlElement) {
                    this.controlElement.focus();
                    this.setExpanded(false);
                }
            };
            this.toggle = () => {
                if (this.dialog.open) {
                    this.close();
                } else {
                    this.open();
                }
            };
        } else {
            // Otherwise, we use the fallback functions defined above to manage the dialog state.
            this.open = () => this.openDialogFallback();
            this.close = () => this.closeDialogFallback();
            this.toggle = () => this.toggleDialogFallback();
        }

        if (!PTXDialog.hasNativeCommandInvokers() && this.kind === "light-close") {
            // Add event listener to close the dialog if the user clicks outside of it
            this.dialog.addEventListener("click", (event) => {
                if (event.target === this.dialog) {
                    // need to ask for bounding rext and do manual check
                    // to include border and padding area of the dialog
                    const rect = this.dialog.getBoundingClientRect();
                    const isInDialog = (
                        rect.top <= event.clientY &&
                        event.clientY <= rect.top + rect.height &&
                        rect.left <= event.clientX &&
                        event.clientX <= rect.left + rect.width
                    );
                    if (!isInDialog) {
                        this.close();
                    }
                }
            });
        }

        // Should be handled natively, but Sagecells currently break native esc handling
        if (this.isModal) {
            this.dialog.addEventListener("keydown", (event) => {
                if (event.key === "Escape") {
                    this.close();
                }
            });
        }

        // make non-modal dialogs draggable by their top bar
        if (!this.isModal) {
            const topBar = this.dialog.querySelector(".ptx-dialog-topbar");
            let isDragging = false;
            let offsetX = 0;
            let offsetY = 0;

            topBar.addEventListener("pointerover", (e) => {
                topBar.style.cursor = "move";
            });

            // Trigger when the user presses down on the element
            topBar.addEventListener("pointerdown", (e) => {
                isDragging = true;

                const dialogRect = this.dialog.getBoundingClientRect();

                // Track the pointer offset within the dialog so movement stays smooth.
                offsetX = e.clientX - dialogRect.left;
                offsetY = e.clientY - dialogRect.top;

                // Lock pointer to capture movement even outside the element boundaries
                topBar.setPointerCapture(e.pointerId);
            });

            // Trigger as the user moves the pointer
            topBar.addEventListener("pointermove", (e) => {
                if (!isDragging) return;

                // Calculate new coordinates from the current pointer position.
                const newX = e.clientX - offsetX;
                const newY = e.clientY - offsetY;

                // Apply styles to move the element.
                this.dialog.style.left = `${newX}px`;
                this.dialog.style.top = `${newY}px`;
                this.dialog.style.bottom = "auto"; // Reset bottom to auto to allow top positioning
                this.dialog.style.right = "auto"; // Reset right to auto to allow left positioning
            });

            // Trigger when the user releases the pointer
            topBar.addEventListener("pointerup", (e) => {
                isDragging = false;
                topBar.releasePointerCapture(e.pointerId);
            });

            // Make sure we stay in view during resizes
            window.addEventListener('resize', (event) => {
                this.dialog.style.left = '';
                this.dialog.style.right = '';
                // make sure top is in viewport
                if (this.dialog.getBoundingClientRect().top > window.innerHeight) {
                    this.dialog.style.top = '20px';
                }
            });
        }
    }

    setExpanded(expanded) {
        if (this.controlElement) {
            this.controlElement.setAttribute('aria-expanded', expanded ? 'true' : 'false');
            if (expanded) {
                this.controlElement.classList.add('open');
            } else {
                this.controlElement.classList.remove('open');
            }
        }
    }

    openDialogFallback() {
        if (this.dialog && typeof this.dialog.showModal === "function" && !this.dialog.open) {
            if(this.isModal) {
              this.dialog.showModal();
            } else {
              this.dialog.show();
            }
            this.setExpanded(true);
        }
    }

    closeDialogFallback() {
        if (this.dialog && typeof this.dialog.close === "function" && this.dialog.open) {
            this.dialog.close();
            this.setExpanded(false);
        }
        if (this.controlElement) {
            this.controlElement.focus();
        }
    }

    toggleDialogFallback() {
        if (!this.dialog) {
            return;
        }
        if (this.dialog.open) {
            this.closeDialogFallback();
        } else {
            this.openDialogFallback();
        }
    }
}


// PTXDialog is used by pretext_search.js, which is a separately-loaded script.
// When this file is bundled into pretext-core.js (IIFE format), it is scoped
// to the bundle. Assigning to window makes it reachable globally.
window.PTXDialog = PTXDialog;