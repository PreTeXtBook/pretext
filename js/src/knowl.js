/**
 * Knowl behavior (from knowl.js).
 *
 * Manages xref knowls and born-hidden knowls: click-to-reveal with
 * slide animation, lazy content fetching, and MathJax re-typesetting.
 */

// Used to animate both types of knowls
class SlideRevealer {
    static STATE = Object.freeze({
        INACTIVE: 0,
        CLOSING: 1,
        EXPANDING: 2,
    });

    constructor(triggerElement, contentElement, animatedElement) {
        this.triggerElement = triggerElement;
        this.contentElement = contentElement;
        this.animatedElement = animatedElement;

        this.animation = null;
        this.animationState = SlideRevealer.STATE.INACTIVE;

        this.triggerElement.addEventListener("click", (e) => this.onClick(e));
    }

    onClick(e) {
        if (e) e.preventDefault();
        this.animatedElement.style.overflow = "hidden";

        if (
            this.animationState === SlideRevealer.STATE.CLOSING ||
            !this.animatedElement.hasAttribute("open")
        ) {
            this.animatedElement.setAttribute("open", "");
            this.triggerElement.setAttribute("open", "");
            this.contentElement.style.display = "";
            MathJax.typesetPromise().then(() =>
                window.requestAnimationFrame(() => this.toggle(true))
            );
        } else if (
            this.animationState === SlideRevealer.STATE.EXPANDING ||
            this.animatedElement.hasAttribute("open")
        ) {
            this.toggle(false);
        }
    }

    toggle(expanding) {
        let closedHeight = 0;
        if (this.animatedElement.contains(this.triggerElement))
            closedHeight = this.triggerElement.offsetHeight;
        const fullHeight = closedHeight + this.contentElement.offsetHeight;

        const startHeight = `${expanding ? closedHeight : fullHeight}px`;
        const endHeight = `${expanding ? fullHeight : closedHeight}px`;

        const padding =
            this.animatedElement.offsetHeight -
            this.animatedElement.clientHeight;
        const startPad = `${expanding ? 0 : padding}px`;
        const endPad = `${expanding ? padding : 0}px`;

        if (this.animation) this.animation.cancel();

        const animDuration = Math.max(
            Math.min(
                (Math.abs(closedHeight - fullHeight) / 400) * 1000,
                750
            ),
            250
        );

        this.animationState = expanding
            ? SlideRevealer.STATE.EXPANDING
            : SlideRevealer.STATE.CLOSING;
        this.animation = this.animatedElement.animate(
            {
                height: [startHeight, endHeight],
                paddingTop: [startPad, endPad],
                paddingBottom: [startPad, endPad],
            },
            { duration: animDuration, easing: "ease" }
        );

        this.animation.onfinish = () => {
            this.onAnimationFinish(expanding);
        };
        this.animation.oncancel = () => {
            this.animationState = SlideRevealer.STATE.INACTIVE;
        };
    }

    onAnimationFinish(isOpen) {
        this.animation = null;
        this.animationState = SlideRevealer.STATE.INACTIVE;

        if (!isOpen) {
            this.animatedElement.removeAttribute("open");
            this.triggerElement.removeAttribute("open");
        }

        this.animatedElement.style.overflow = "";
        if (!isOpen) this.contentElement.style.display = "none";

        if (isOpen) {
            let hasCallback =
                this.contentElement.querySelectorAll(
                    "[data-knowl-callback]"
                );
            hasCallback.forEach((el) => {
                window[el.getAttribute("data-knowl-callback")](el, open);
            });
        }
    }
}

class LinkKnowl {
    static xrefCount = 0;

    static initializeXrefKnowl(knowlLinkElement) {
        if (
            knowlLinkElement.getAttribute("data-knowl-uid") === null
        ) {
            return new LinkKnowl(knowlLinkElement);
        }
    }

    constructor(knowlLinkElement) {
        this.linkElement = knowlLinkElement;
        this.outputElement = null;
        this.uid = LinkKnowl.xrefCount++;
        knowlLinkElement.setAttribute("data-knowl-uid", this.uid);
        knowlLinkElement.setAttribute("role", "button");
        knowlLinkElement.setAttribute(
            "data-base-title",
            knowlLinkElement.getAttribute("title") ||
                this.linkElement.textContent
        );
        knowlLinkElement.classList.add("knowl__link");
        this.updateLabels(false);
        knowlLinkElement.addEventListener(
            "click",
            this.handleLinkClick.bind(this)
        );
    }

    updateLabels(isVisible) {
        const verb = isVisible
            ? this.linkElement.getAttribute("data-close-label") || "Close"
            : this.linkElement.getAttribute("data-reveal-label") ||
              "Reveal";
        const targetDescript =
            this.linkElement.getAttribute("data-base-title");
        const helpText = verb + " " + targetDescript;
        this.linkElement.setAttribute("aria-label", helpText);
        this.linkElement.setAttribute("title", helpText);
    }

    toggle() {
        this.linkElement.classList.toggle("active");
        const isActive = this.linkElement.classList.contains("active");
        this.updateLabels(isActive);

        if (isActive) {
            const h = this.outputElement.getBoundingClientRect().height;
            if (h > window.innerHeight) {
                this.outputElement.scrollIntoView(true);
            } else {
                if (
                    this.outputElement.getBoundingClientRect().bottom >
                    window.innerHeight
                )
                    this.outputElement.scrollIntoView(false);
            }
        }
    }

    findOutputLocation() {
        const invalidParents =
            "table, mjx-container, div.tabular-box, .runestone > .parsons";
        let el = this.linkElement.parentElement;
        let problemAncestor = el.closest(invalidParents);
        while (problemAncestor && problemAncestor !== el) {
            el = problemAncestor;
            problemAncestor = el.closest(invalidParents);
        }
        return el;
    }

    createOutputElement() {
        const outputId = "knowl-uid-" + this.uid;
        const outputContentsId = "knowl-output-" + this.uid;
        const linkTarget =
            this.linkElement.getAttribute("data-knowl");

        const placeholderText =
            `<div class='knowl__content' style='display:none;' id='${outputId}' aria-live='polite' id='${outputContentsId}'>` +
            `Loading '${linkTarget}'` +
            `</div>`;

        const temp = document.createElement("template");
        temp.innerHTML = placeholderText;
        this.outputElement = temp.content.children[0];

        const insertLoc = this.findOutputLocation(this.linkElement);
        insertLoc.after(this.outputElement);
    }

    async getContent() {
        const contentURL =
            this.linkElement.getAttribute("data-knowl");
        const knowlContent = await fetch(contentURL)
            .then((response) => response.text())
            .then((data) => {
                let knowlDoc = new DOMParser().parseFromString(
                    data,
                    "text/html"
                );
                let tempContainer = knowlDoc.body;
                let scripts = knowlDoc.querySelectorAll("head script");
                tempContainer.append(...scripts);
                return tempContainer;
            })
            .catch((error) => {
                const destination =
                    this.linkElement.getAttribute("href");
                const text = this.linkElement.textContent;
                const err_message =
                    `<div class='knowl-output__error'>` +
                    `<div class='para'>Error fetching content. (<em>${error}</em>)</div>` +
                    `<div class='para'><a href='${destination}'>Navigate to ${text}</a> instead.</div>` +
                    `<div class='para'>If you are viewing this book from your local filesystem, this is expected behavior. To view the book with all features, you must serve the book from a web server. See the <a href="https://pretextbook.org/doc/guide/html/author-faq.html#how-do-i-view-my-book-locally">PreTeXt FAQ</a> for more information.</div>` +
                    `</div>`;
                return err_message;
            });
        return knowlContent;
    }

    handleLinkClick(event) {
        event.preventDefault();

        if (this.outputElement !== null) {
            this.toggle();
        } else {
            this.createOutputElement();

            const slideHandler = new SlideRevealer(
                this.linkElement,
                this.outputElement,
                this.outputElement
            );
            this.linkElement.addEventListener("click", slideHandler);

            let loadingTimeout = setTimeout(() => {
                loadingTimeout = null;
                slideHandler.onClick();
                this.toggle();
            }, 500);

            const content = this.getContent();

            content
                .then((tempContainer) => {
                    if (loadingTimeout !== null) {
                        clearTimeout(loadingTimeout);
                    }
                    setTimeout(() => {
                        slideHandler.onClick();
                        this.toggle();
                    }, 100);

                    const runestoneElements =
                        tempContainer.querySelectorAll(
                            ".ptx-runestone-container"
                        );
                    [...runestoneElements].forEach((e) => {
                        const rsId =
                            e.querySelector("[data-component]")?.id;
                        const onPage = document.getElementById(rsId);
                        if (onPage) {
                            e.innerHTML = `<div class="para">The interactive that belongs here is already on the page and cannot appear multiple times. <a href="#${rsId}">Scroll to interactive.</a>`;
                        } else {
                            window.runestoneComponents.renderOneComponent(
                                e
                            );
                        }
                    });

                    const children = [...tempContainer.children];
                    this.outputElement.innerHTML = "";
                    this.outputElement.append(...children);

                    addKnowls(this.outputElement);
                    Prism.highlightAllUnder(this.outputElement);

                    [
                        ...this.outputElement.getElementsByTagName(
                            "script"
                        ),
                    ].forEach((s) => {
                        if (
                            s.getAttribute("type") === null ||
                            s.getAttribute("type") ===
                                "text/javascript"
                        ) {
                            eval(s.innerHTML);
                        }
                    });
                })
                .catch((data) => {
                    console.log(
                        "Error fetching knowl content: " + data
                    );
                });
        }
    }
}

export function addKnowls(target) {
    const xrefs = target.querySelectorAll("[data-knowl]");
    for (const xref of xrefs) {
        LinkKnowl.initializeXrefKnowl(xref);
    }

    const bornHiddens = target.querySelectorAll(".born-hidden-knowl");
    for (const bhk of bornHiddens) {
        const summary = bhk.querySelector(":scope > summary");
        const contents = bhk.querySelector(":scope > summary + *");
        new SlideRevealer(summary, contents, bhk);
    }
}

export function initKnowls() {
    addKnowls(document);
}
