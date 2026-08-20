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
        '.sbspanel > img',
        'figure > img',
        'figure > div > img'
    ].join(', ');

    document.querySelectorAll(magnifiableImageSelector).forEach((image) => {
        if (image.classList.contains('draw_on_me') || initializedImageDialogs.has(image)) {
            return;
        }

        const imageBox = image.closest('.image-box');
        const figure = imageBox?.parentElement?.matches('figure') ? imageBox.parentElement : null;
        const isSVG = image instanceof HTMLImageElement &&
            new URL(image.currentSrc || image.src, document.baseURI).pathname.toLowerCase().endsWith('.svg');
        if (image instanceof HTMLImageElement && !isSVG) {
            if (!image.naturalWidth || !image.naturalHeight) {
                image.addEventListener('load', initializeImageDialogs, { once: true });
                return;
            }
            const renderedSize = image.getBoundingClientRect();
            if (
                renderedSize.width >= image.naturalWidth &&
                renderedSize.height >= image.naturalHeight
            ) {
                return;
            }
        }

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

        const refreshDialogContent = () => {
            let dialogContent = (figure || image).cloneNode(true);
            if (dialogContent.matches('img')) {
                const dialogImageBox = document.createElement('div');
                dialogImageBox.classList.add('image-box');
                dialogImageBox.append(dialogContent);
                dialogContent = dialogImageBox;
            }
            dialogContent.removeAttribute('id');
            dialogContent.querySelectorAll('[id]').forEach((element) => element.removeAttribute('id'));
            dialogContent.querySelectorAll('.ptx-image-expand-button').forEach((button) => button.remove());
            dialogContentContainer.replaceChildren(dialogContent);
            dialogContentRoot = dialogContent;
            dialogImage = dialogContent.matches('img') ? dialogContent : dialogContent.querySelector('img');
            dialogFigure = dialogContent.matches('figure') ? dialogContent : null;
            if (dialogImage instanceof HTMLImageElement) {
                dialogImage.addEventListener('load', fitDialogToFigure);
            }
        };

        const fitDialogToFigure = () => {
            if (!dialog.open || !dialogImage) {
                return;
            }

            const maxWidth = window.innerWidth * 0.9;
            const maxHeight = window.innerHeight * 0.9;
            const naturalWidth = dialogImage.naturalWidth || maxWidth;
            const intrinsicAspectRatio = dialogImage.naturalWidth && dialogImage.naturalHeight
                ? dialogImage.naturalWidth / dialogImage.naturalHeight
                : null;
            let imageWidth = isSVG
                ? Math.min(maxWidth, maxHeight * (intrinsicAspectRatio || 1))
                : Math.min(naturalWidth, maxWidth);

            for (let attempt = 0; attempt < 2; attempt += 1) {
                dialog.style.width = `${imageWidth}px`;
                dialogImage.style.setProperty('width', `${imageWidth}px`, 'important');
                dialogImage.style.setProperty('max-height', `${maxHeight}px`, 'important');

                const imageRect = dialogImage.getBoundingClientRect();
                if (!imageRect.width || !imageRect.height) {
                    return;
                }
                const contentRect = (dialogFigure || dialogContentRoot || dialogImage).getBoundingClientRect();
                const nonImageHeight = Math.max(0, contentRect.height - imageRect.height);
                const availableImageHeight = Math.max(0, maxHeight - nonImageHeight);
                const aspectRatio = intrinsicAspectRatio || (imageRect.width / imageRect.height);
                imageWidth = Math.min(imageWidth, availableImageHeight * aspectRatio);
            }

            dialog.style.width = `${imageWidth}px`;
            dialogImage.style.setProperty('width', `${imageWidth}px`, 'important');
        };

        const trigger = document.createElement('button');
        trigger.type = 'button';
        trigger.classList.add('ptx-image-expand-button');
        const description = image.getAttribute('alt')?.trim();
        trigger.setAttribute('aria-label', description ? `Expand image: ${description}` : 'Expand image');
        trigger.setAttribute('title', trigger.getAttribute('aria-label'));
        trigger.innerHTML = '<span class="material-symbols-outlined">open_in_full</span>';
        const triggerContainer = imageBox || image.parentElement;
        triggerContainer.classList.add('ptx-image-dialog-trigger-container');
        image.after(trigger);

        image.setAttribute('tabindex', '0');
        image.setAttribute('role', 'button');
        image.setAttribute('aria-label', trigger.getAttribute('aria-label'));
        image.addEventListener('click', () => trigger.click());
        image.addEventListener('keydown', (keyEvent) => {
            if (keyEvent.key === 'Enter' || keyEvent.key === ' ') {
                keyEvent.preventDefault();
                image.click();
            }
        });

        trigger.addEventListener('click', () => {
            refreshDialogContent();
            requestAnimationFrame(fitDialogToFigure);
        });
        window.addEventListener('resize', fitDialogToFigure);

        new window.PTXDialog(dialog, trigger, { kind: 'light-close' });
    });
}
