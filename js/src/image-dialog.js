// Accessible image enlargement dialogs.
// Loaded by pretext-core.js after pretext-dialog.js defines window.PTXDialog.

window.addEventListener('load', () => {
    requestAnimationFrame(initializeImageDialogs);
});

const initializedImageDialogs = new WeakSet();
let imageDialogNumber = 0;

function initializeImageDialogs() {
    const magnifiableImageSelector = [
        '.image-box > img',
        '.image-box > pre.mermaid',
        '.image-box > .ChemAccess-element',  // Prefigure interactive diagram
        '.image-box > .asymptote-box',
        '.sbspanel > img',
        'figure > img',
        'figure > div > img'
    ].join(', ');

    document.querySelectorAll(magnifiableImageSelector).forEach((image) => {
        if (initializedImageDialogs.has(image)) {
            return;
        }

        const imageBox = image.closest('.image-box');
        const figure = imageBox?.parentElement?.matches('figure') ? imageBox.parentElement : null;
        const isMermaid = image.matches('pre.mermaid');
        const isDiagcess = image.matches('.ChemAccess-element');
        const asymptoteIframe = image.querySelector?.('iframe.asymptote');
        const asymptoteSVG = asymptoteIframe?.contentDocument?.querySelector('svg');
        const asymptoteCanvas = asymptoteIframe?.contentDocument?.querySelector('canvas');
        if (image.matches('.asymptote-box') && !asymptoteSVG && !asymptoteCanvas) {
            // Wait for an unloaded Asymptote iframe. Once it is available, its
            // SVG or canvas identifies the 2-D or 3-D variant respectively.
            if (asymptoteIframe?.contentDocument?.readyState !== 'complete') {
                asymptoteIframe?.addEventListener('load', initializeImageDialogs, { once: true });
            }
            return;
        }
        const isAsymptote2D = !!asymptoteSVG;
        const isAsymptote3D = !!asymptoteCanvas;
        const isAsymptote = isAsymptote2D || isAsymptote3D;
        initializedImageDialogs.add(image);
        const dialog = document.createElement('dialog');
        dialog.id = `ptx-image-dialog-${++imageDialogNumber}`;
        dialog.classList.add('ptx-image-dialog');
        dialog.setAttribute('aria-label', 'Expanded image');
        const dialogContentContainer = document.createElement('div');
        dialogContentContainer.classList.add('ptx-image-dialog-content');
        dialog.append(dialogContentContainer);
        document.body.append(dialog);

        let dialogImage = null;
        let dialogFigure = null;
        let dialogContentRoot = null;

        const initializeDialogDiagcess = (diagrams) => {
            if (!diagrams.length || !window.diagcess?.Base) {
                return;
            }

            // Diagcess installs its interaction after it has fetched the SVG
            // and annotations. Fit the dialog when that rendered SVG arrives.
            const observer = new MutationObserver(() => {
                if (diagrams.some((diagram) => diagram.querySelector('svg'))) {
                    observer.disconnect();
                    requestAnimationFrame(fitDialogToFigure);
                }
            });
            diagrams.forEach((diagram) => {
                observer.observe(diagram, { childList: true, subtree: true });
            });
            window.diagcess.Base.init();
        };

        const refreshDialogContent = () => {
            // Mermaid renders after the page load event, so clone at
            // activation time to capture its rendered SVG rather than source.
            // A direct-child image-box includes the full figure and caption.
            // Diagcess needs its entire image-box, which can contain more
            // than its interactive SVG.
            let dialogContent = (figure || (isDiagcess ? imageBox : image)).cloneNode(true);
            if (dialogContent.matches('img, .ChemAccess-element')) {
                const dialogImageBox = document.createElement('div');
                dialogImageBox.classList.add('image-box');
                dialogImageBox.append(dialogContent);
                dialogContent = dialogImageBox;
            }
            dialogContent.removeAttribute('id');
            dialogContent.querySelectorAll('[id]').forEach((element) => {
                // Mermaid's generated SVG styles and references rely on IDs.
                if (!element.closest('svg')) {
                    element.removeAttribute('id');
                }
            });
            dialogContent.querySelectorAll('.ptx-image-expand-button').forEach((button) => button.remove());
            const clonedMermaids = [
                ...(dialogContent.matches('pre.mermaid') ? [dialogContent] : []),
                ...dialogContent.querySelectorAll('pre.mermaid')
            ];
            clonedMermaids.forEach((mermaid) => {
                // Do not let Mermaid re-parse its already-rendered SVG.
                mermaid.classList.replace('mermaid', 'ptx-mermaid-dialog');
            });
            if (isAsymptote2D) {
                const clonedAsymptoteBox = dialogContent.matches('.asymptote-box')
                    ? dialogContent
                    : dialogContent.querySelector('.asymptote-box');
                const dialogAsymptoteSVG = asymptoteSVG.cloneNode(true);
                dialogAsymptoteSVG.classList.add('ptx-asymptote-dialog');
                clonedAsymptoteBox.replaceChildren(dialogAsymptoteSVG);
                clonedAsymptoteBox.style.removeProperty('padding-top');
            }
            const clonedDiagcess = [
                ...(dialogContent.matches('.ChemAccess-element') ? [dialogContent] : []),
                ...dialogContent.querySelectorAll('.ChemAccess-element')
            ].map((diagram) => {
                // A clone of an initialized Diagcess diagram lacks its event
                // handlers. Recreate its source placeholder so Diagcess can
                // build an independent, fully interactive diagram here.
                const placeholder = document.createElement('div');
                placeholder.classList.add('ChemAccess-element');
                [...diagram.attributes].forEach((attribute) => {
                    if (attribute.name.startsWith('data-') || attribute.name === 'aria-label') {
                        placeholder.setAttribute(attribute.name, attribute.value);
                    }
                });
                diagram.replaceWith(placeholder);
                return placeholder;
            });
            dialogContentContainer.replaceChildren(dialogContent);
            dialogContentRoot = dialogContent;
            dialogImage = dialogContent.matches('img, pre.ptx-mermaid-dialog, .ChemAccess-element, svg.ptx-asymptote-dialog, iframe.asymptote')
                ? dialogContent
                : dialogContent.querySelector('img, pre.ptx-mermaid-dialog, .ChemAccess-element, svg.ptx-asymptote-dialog, iframe.asymptote');
            dialogFigure = dialogContent.matches('figure') ? dialogContent : null;
            if (dialogImage instanceof HTMLImageElement || dialogImage instanceof HTMLIFrameElement) {
                dialogImage.addEventListener('load', fitDialogToFigure);
            }
            initializeDialogDiagcess(clonedDiagcess);
        };

        const fitDialogToFigure = () => {
            const displayedImage = isDiagcess
                ? dialogContentContainer.querySelector('.ChemAccess-element svg')
                : dialogImage;
            if (!dialog.open || !displayedImage) {
                return;
            }

            const maxWidth = window.innerWidth * 0.9;
            const maxHeight = window.innerHeight * 0.9;
            const dialogStyle = getComputedStyle(dialog);
            const horizontalPadding = parseFloat(dialogStyle.paddingLeft) + parseFloat(dialogStyle.paddingRight);
            const verticalPadding = parseFloat(dialogStyle.paddingTop) + parseFloat(dialogStyle.paddingBottom);
            const maxContentWidth = Math.max(0, maxWidth - horizontalPadding);
            const maxContentHeight = Math.max(0, maxHeight - verticalPadding);
            const renderedSVG = displayedImage instanceof SVGSVGElement
                ? displayedImage
                : displayedImage.querySelector?.('svg');
            const viewBox = renderedSVG?.viewBox?.baseVal;
            const intrinsicAspectRatio = viewBox?.width && viewBox?.height
                ? viewBox.width / viewBox.height
                : (isAsymptote3D && asymptoteCanvas.width && asymptoteCanvas.height
                    ? asymptoteCanvas.width / asymptoteCanvas.height
                : (displayedImage instanceof HTMLImageElement && displayedImage.naturalWidth && displayedImage.naturalHeight
                    ? displayedImage.naturalWidth / displayedImage.naturalHeight
                    : null));
            // Every kind of image fills the same space, so a low-resolution
            // raster enlarges as far as a vector one does rather than stopping
            // at some multiple of its natural size.  It will be soft at that
            // size, which is the honest presentation of a small source image.
            let imageWidth = Math.min(maxContentWidth, maxContentHeight * (intrinsicAspectRatio || 1));

            for (let attempt = 0; attempt < 2; attempt += 1) {
                dialog.style.width = `${imageWidth + horizontalPadding}px`;
                displayedImage.style.setProperty('width', `${imageWidth}px`, 'important');
                displayedImage.style.setProperty('max-height', `${maxContentHeight}px`, 'important');

                const imageRect = displayedImage.getBoundingClientRect();
                if (!imageRect.width || !imageRect.height) {
                    return;
                }
                const contentRect = (dialogFigure || dialogContentRoot || displayedImage).getBoundingClientRect();
                const nonImageHeight = Math.max(0, contentRect.height - imageRect.height);
                const availableImageHeight = Math.max(0, maxContentHeight - nonImageHeight);
                const aspectRatio = intrinsicAspectRatio || (imageRect.width / imageRect.height);
                imageWidth = Math.min(imageWidth, availableImageHeight * aspectRatio);
            }

            dialog.style.width = `${imageWidth + horizontalPadding}px`;
            displayedImage.style.setProperty('width', `${imageWidth}px`, 'important');
        };

        const trigger = document.createElement('button');
        trigger.type = 'button';
        trigger.classList.add('ptx-image-expand-button');
        const description = image.getAttribute('alt')?.trim() || (
            isMermaid ? 'Mermaid diagram' : (isDiagcess ? 'interactive diagram' : (
                isAsymptote ? asymptoteIframe.title?.trim() || 'Asymptote diagram' : ''
            ))
        );
        const contentType = (isMermaid || isDiagcess || isAsymptote) ? 'diagram' : 'image';
        trigger.setAttribute('aria-label', description ? `Expand ${contentType}: ${description}` : `Expand ${contentType}`);
        trigger.setAttribute('title', trigger.getAttribute('aria-label'));
        trigger.innerHTML = '<span class="material-symbols-outlined">open_in_full</span>';
        const triggerContainer = imageBox || image.parentElement;
        triggerContainer.classList.add('ptx-image-dialog-trigger-container');
        image.after(trigger);

        image.setAttribute('tabindex', '0');
        image.setAttribute('role', 'button');
        image.setAttribute('aria-label', trigger.getAttribute('aria-label'));
        if (isDiagcess) {
            // Intercept at capture time, before Diagcess' handlers activate
            // its annotations. The dialog clone is the interactive diagram.
            image.addEventListener('click', (clickEvent) => {
                clickEvent.preventDefault();
                clickEvent.stopImmediatePropagation();
                trigger.click();
            }, true);
            image.addEventListener('keydown', (keyEvent) => {
                keyEvent.stopImmediatePropagation();
                if (keyEvent.key === 'Enter' || keyEvent.key === ' ') {
                    keyEvent.preventDefault();
                    trigger.click();
                }
            }, true);
        } else if (isAsymptote) {
            // Pointer events inside an iframe do not bubble to its parent.
            // Make the embedded diagram a mouse trigger, while keyboard
            // activation stays on the enclosing asymptote box.
            asymptoteIframe.tabIndex = -1;
            asymptoteSVG?.setAttribute('aria-hidden', 'true');
            if (isAsymptote3D) {
                let pointerStart = null;
                const clickMovementThreshold = 5;
                asymptoteIframe.contentDocument.addEventListener('pointerdown', (pointerEvent) => {
                    if (pointerEvent.button === 0) {
                        pointerStart = { x: pointerEvent.clientX, y: pointerEvent.clientY };
                    }
                });
                asymptoteIframe.contentDocument.addEventListener('pointerup', (pointerEvent) => {
                    if (pointerEvent.button === 0 && pointerStart) {
                        const distance = Math.hypot(
                            pointerEvent.clientX - pointerStart.x,
                            pointerEvent.clientY - pointerStart.y
                        );
                        if (distance <= clickMovementThreshold) {
                            trigger.click();
                        }
                    }
                    pointerStart = null;
                });
                asymptoteIframe.contentDocument.addEventListener('pointercancel', () => {
                    pointerStart = null;
                });
            } else {
                asymptoteIframe.contentDocument.addEventListener('click', (clickEvent) => {
                    clickEvent.preventDefault();
                    trigger.click();
                });
            }
            image.addEventListener('click', () => trigger.click());
            image.addEventListener('keydown', (keyEvent) => {
                if (keyEvent.key === 'Enter' || keyEvent.key === ' ') {
                    keyEvent.preventDefault();
                    trigger.click();
                }
            });
        } else {
            image.addEventListener('click', () => trigger.click());
            image.addEventListener('keydown', (keyEvent) => {
                if (keyEvent.key === 'Enter' || keyEvent.key === ' ') {
                    keyEvent.preventDefault();
                    image.click();
                }
            });
        }

        trigger.addEventListener('click', () => {
            refreshDialogContent();
            requestAnimationFrame(fitDialogToFigure);
        });
        window.addEventListener('resize', fitDialogToFigure);

        new window.PTXDialog(dialog, trigger, { kind: 'light-close' });
    });
}
