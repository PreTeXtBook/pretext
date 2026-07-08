window.addEventListener("load", (event2) => {
  addKnowls(document);
});
function addKnowls(target) {
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
class SlideRevealer {
  static STATE = Object.freeze({
    INACTIVE: 0,
    CLOSING: 1,
    EXPANDING: 2
  });
  // triggerElement is the element clicked to open/close
  // contentElement is the element that will hide/reveal
  // animatedElement is the element that will grow/shrink as contentElement is modified
  //    may be the same as contentElement or a parent of it
  constructor(triggerElement, contentElement, animatedElement) {
    this.triggerElement = triggerElement;
    this.contentElement = contentElement;
    this.animatedElement = animatedElement;
    this.animation = null;
    this.animationState = SlideRevealer.STATE.INACTIVE;
    this.animatedElementInlineStyle = null;
    this.triggerElement.addEventListener("click", (e) => this.onClick(e));
  }
  isBusy() {
    return this.animationState !== SlideRevealer.STATE.INACTIVE || this.animatedElementInlineStyle !== null;
  }
  storeAnimatedElementInlineStyle() {
    if (this.animatedElementInlineStyle !== null) return;
    this.animatedElementInlineStyle = {
      overflow: this.animatedElement.style.overflow,
      height: this.animatedElement.style.height,
      paddingTop: this.animatedElement.style.paddingTop,
      paddingBottom: this.animatedElement.style.paddingBottom
    };
  }
  restoreAnimatedElementInlineStyle() {
    if (this.animatedElementInlineStyle === null) return;
    this.animatedElement.style.overflow = this.animatedElementInlineStyle.overflow;
    this.animatedElement.style.height = this.animatedElementInlineStyle.height;
    this.animatedElement.style.paddingTop = this.animatedElementInlineStyle.paddingTop;
    this.animatedElement.style.paddingBottom = this.animatedElementInlineStyle.paddingBottom;
    this.animatedElementInlineStyle = null;
  }
  onClick(e) {
    if (e) e.preventDefault();
    if (this.isBusy()) return;
    this.storeAnimatedElementInlineStyle();
    this.animatedElement.style.overflow = "hidden";
    if (this.animationState === SlideRevealer.STATE.CLOSING || !this.animatedElement.hasAttribute("open")) {
      this.animatedElement.setAttribute("open", "");
      this.triggerElement.setAttribute("open", "");
      this.contentElement.style.display = "";
      this.contentElement.style.visibility = "hidden";
      let closedHeight = 0;
      if (this.animatedElement.contains(this.triggerElement))
        closedHeight = this.triggerElement.offsetHeight;
      const naturalStyle = window.getComputedStyle(this.animatedElement);
      const naturalPaddingTop = naturalStyle.paddingTop;
      const naturalPaddingBottom = naturalStyle.paddingBottom;
      this.animatedElement.style.height = `${closedHeight}px`;
      this.animatedElement.style.paddingTop = "0px";
      this.animatedElement.style.paddingBottom = "0px";
      const expandingMeasurements = {
        fullHeight: this.contentElement === this.animatedElement ? this.contentElement.scrollHeight : closedHeight + this.contentElement.offsetHeight,
        paddingTop: naturalPaddingTop,
        paddingBottom: naturalPaddingBottom
      };
      this.contentElement.style.visibility = "";
      this.toggle(true, expandingMeasurements);
    } else if (this.animationState === SlideRevealer.STATE.EXPANDING || this.animatedElement.hasAttribute("open")) {
      this.toggle(false);
    }
  }
  toggle(expanding, expandingMeasurements = null) {
    let closedHeight = 0;
    if (this.animatedElement.contains(this.triggerElement))
      closedHeight = this.triggerElement.offsetHeight;
    const computedStyle = window.getComputedStyle(this.animatedElement);
    const fullHeight = expandingMeasurements?.fullHeight ?? closedHeight + this.contentElement.offsetHeight;
    const startHeight = `${expanding ? closedHeight : this.animatedElement.offsetHeight}px`;
    const endHeight = `${expanding ? fullHeight : closedHeight}px`;
    const currentPaddingTop = computedStyle.paddingTop;
    const currentPaddingBottom = computedStyle.paddingBottom;
    const endPaddingTop = expandingMeasurements?.paddingTop ?? currentPaddingTop;
    const endPaddingBottom = expandingMeasurements?.paddingBottom ?? currentPaddingBottom;
    const startPadTop = expanding ? "0px" : currentPaddingTop;
    const endPadTop = expanding ? endPaddingTop : "0px";
    const startPadBottom = expanding ? "0px" : currentPaddingBottom;
    const endPadBottom = expanding ? endPaddingBottom : "0px";
    if (this.animation) {
      this.animation.cancel();
    }
    const animDuration = Math.max(Math.min(Math.abs(closedHeight - fullHeight) / 400 * 1e3, 750), 250);
    this.animationState = expanding ? SlideRevealer.STATE.EXPANDING : SlideRevealer.STATE.CLOSING;
    this.animation = this.animatedElement.animate({
      height: [startHeight, endHeight],
      paddingTop: [startPadTop, endPadTop],
      paddingBottom: [startPadBottom, endPadBottom]
    }, {
      duration: animDuration,
      easing: "ease-out"
    });
    this.animation.onfinish = () => {
      this.onAnimationFinish(expanding);
    };
    this.animation.oncancel = () => {
      this.animationState = SlideRevealer.STATE.INACTIVE;
      this.restoreAnimatedElementInlineStyle();
    };
  }
  onAnimationFinish(isOpen) {
    this.animation = null;
    this.animationState = SlideRevealer.STATE.INACTIVE;
    if (!isOpen) {
      this.animatedElement.removeAttribute("open");
      this.triggerElement.removeAttribute("open");
    }
    this.restoreAnimatedElementInlineStyle();
    if (!isOpen)
      this.contentElement.style.display = "none";
    this.contentElement.style.visibility = "";
    if (isOpen) {
      let hasCallback = this.contentElement.querySelectorAll("[data-knowl-callback]");
      hasCallback.forEach((el) => {
        window[el.getAttribute("data-knowl-callback")](el, open);
      });
    }
  }
}
class LinkKnowl {
  // Used to uniquely identify XrefKnowls
  static xrefCount = 0;
  // Factory to create an XrefKnowl from a knowl link
  // Will avoid duplicate initialization
  // This should be used by outside code to create XrefKnowls
  static initializeXrefKnowl(knowlLinkElement) {
    if (knowlLinkElement.getAttribute("data-knowl-uid") === null) {
      return new LinkKnowl(knowlLinkElement);
    }
  }
  // "Private" constructor - should only be called by initializeXrefKnowl
  constructor(knowlLinkElement) {
    this.linkElement = knowlLinkElement;
    this.outputElement = null;
    this.slideHandler = null;
    this.uid = LinkKnowl.xrefCount++;
    knowlLinkElement.setAttribute("data-knowl-uid", this.uid);
    knowlLinkElement.setAttribute("role", "button");
    knowlLinkElement.setAttribute("data-base-title", knowlLinkElement.getAttribute("title") || this.linkElement.textContent);
    knowlLinkElement.classList.add("knowl__link");
    this.updateLabels(false);
    knowlLinkElement.addEventListener("click", this.handleLinkClick.bind(this));
  }
  // Set aria-label and title based on visibility of knowl
  updateLabels(isVisible) {
    const verb = isVisible ? this.linkElement.getAttribute("data-close-label") || "Close" : this.linkElement.getAttribute("data-reveal-label") || "Reveal";
    const targetDescript = this.linkElement.getAttribute("data-base-title");
    const helpText = verb + " " + targetDescript;
    this.linkElement.setAttribute("aria-label", helpText);
    this.linkElement.setAttribute("title", helpText);
  }
  // Toggle the state of the knowl link and output elements
  // Assumes output is already created
  toggle() {
    this.linkElement.classList.toggle("active");
    const isActive = this.linkElement.classList.contains("active");
    this.updateLabels(isActive);
    if (isActive) {
      const h = this.outputElement.getBoundingClientRect().height;
      if (h > window.innerHeight) {
        this.outputElement.scrollIntoView(true);
      } else {
        if (this.outputElement.getBoundingClientRect().bottom > window.innerHeight)
          this.outputElement.scrollIntoView(false);
      }
    }
  }
  // Returns element the knowl output should be inserted after
  findOutputLocation() {
    const invalidParents = "table, mjx-container, div.tabular-box, .runestone > .parsons";
    let el = this.linkElement.parentElement;
    let problemAncestor = el.closest(invalidParents);
    while (problemAncestor && problemAncestor !== el) {
      el = problemAncestor;
      problemAncestor = el.closest(invalidParents);
    }
    return el;
  }
  // Create the knowl output element
  createOutputElement() {
    const outputId = "knowl-uid-" + this.uid;
    const outputContentsId = "knowl-output-" + this.uid;
    const linkTarget = this.linkElement.getAttribute("data-knowl");
    const placeholderText = `<div class='knowl__content' style='display:none;' id='${outputId}' aria-live='polite' id='${outputContentsId}'>Loading '${linkTarget}'</div>`;
    const temp = document.createElement("template");
    temp.innerHTML = placeholderText;
    this.outputElement = temp.content.children[0];
    const insertLoc = this.findOutputLocation(this.linkElement);
    insertLoc.after(this.outputElement);
  }
  // Get content for knowl as dom element. Returns promise that resolves to knowl content
  async getContent() {
    const contentURL = this.linkElement.getAttribute("data-knowl");
    const knowlContent = await fetch(contentURL).then((response) => response.text()).then((data) => {
      let knowlDoc = new DOMParser().parseFromString(data, "text/html");
      let tempContainer2 = knowlDoc.body;
      let scripts = knowlDoc.querySelectorAll("head script");
      tempContainer2.append(...scripts);
      return tempContainer2;
    }).catch((error) => {
      const destination = this.linkElement.getAttribute("href");
      const text = this.linkElement.textContent;
      const err_message = `<div class='knowl-output__error'><div class='para'>Error fetching content. (<em>${error}</em>)</div><div class='para'><a href='${destination}'>Navigate to ${text}</a> instead.</div><div class='para'>If you are viewing this book from your local filesystem, this is expected behavior. To view the book with all features, you must serve the book from a web server. See the <a href="https://pretextbook.org/doc/guide/html/author-faq.html#how-do-i-view-my-book-locally">PreTeXt FAQ</a> for more information.</div></div>`;
      return err_message;
    });
    return knowlContent;
  }
  // Handle a click on the knowl link
  handleLinkClick(event) {
    event.preventDefault();
    if (this.slideHandler?.isBusy()) {
      return;
    }
    if (this.outputElement !== null) {
      this.toggle();
    } else {
      this.createOutputElement();
      this.slideHandler = new SlideRevealer(this.linkElement, this.outputElement, this.outputElement);
      this.linkElement.addEventListener("click", this.slideHandler);
      let loadingTimeout = setTimeout(() => {
        loadingTimeout = null;
        this.slideHandler.onClick();
        this.toggle();
      }, 500);
      const content = this.getContent();
      content.then((tempContainer) => {
        if (loadingTimeout !== null) {
          clearTimeout(loadingTimeout);
        }
        setTimeout(() => {
          this.slideHandler.onClick();
          this.toggle();
        }, 100);
        const runestoneElements = tempContainer.querySelectorAll(".ptx-runestone-container");
        [...runestoneElements].forEach((e) => {
          const rsId = e.querySelector("[data-component]")?.id;
          const onPage = document.getElementById(rsId);
          if (onPage) {
            e.innerHTML = `<div class="para">The interactive that belongs here is already on the page and cannot appear multiple times. <a href="#${rsId}">Scroll to interactive.</a>`;
          } else {
            window.runestoneComponents.renderOneComponent(e);
          }
        });
        const children = [...tempContainer.children];
        this.outputElement.innerHTML = "";
        this.outputElement.append(...children);
        addKnowls(this.outputElement);
        MathJax.typesetPromise([this.outputElement]);
        Prism.highlightAllUnder(this.outputElement);
        [...this.outputElement.getElementsByTagName("script")].forEach((s) => {
          if (s.getAttribute("type") === null || s.getAttribute("type") === "text/javascript") {
            eval(s.innerHTML);
          }
        });
      }).catch((data) => {
        console.log("Error fetching knowl content: " + data);
      });
    }
  }
}
//# sourceMappingURL=knowl.js.map
