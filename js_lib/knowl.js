// Code controlling behavior of xref knowls and born hidden knowls

// Assumes this file is loaded as part of initial page
window.addEventListener("load", (event) => {
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

// Used to animate both types of knowls
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

    // mid animation state tracking
    this.animation = null;
    this.animationState = SlideRevealer.STATE.INACTIVE;

    this.triggerElement.addEventListener('click', (e) => this.onClick(e));
  }

  onClick(e) {
    // Stop default behavior from the browser
    if (e) e.preventDefault();

    // Add an overflow on the <details> to avoid content overflowing
    this.animatedElement.style.overflow = 'hidden';

    // Check if the element is being closed or is already closed
    if (this.animationState === SlideRevealer.STATE.CLOSING || !this.animatedElement.hasAttribute("open")) {
      // Force the [open] attributes - allow for similar targetting of xref and born-hidden knowls
      this.animatedElement.setAttribute("open","");
      this.triggerElement.setAttribute("open","");
      this.contentElement.style.display = '';
      // Wait for the next frame to call the toggle function
      window.requestAnimationFrame(() => this.toggle(true));
    } else if (this.animationState === SlideRevealer.STATE.EXPANDING || this.animatedElement.hasAttribute("open")) {
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

    // Need to animate padding to avoid extra height for xref knowls
    const padding = this.animatedElement.offsetHeight - this.animatedElement.clientHeight;
    const startPad = `${expanding ? 0 : padding}px`;
    const endPad = `${expanding ? padding : 0}px`;

    // Cancel any existing animation
    if (this.animation) {
      this.animation.cancel();
    }

    // Animate ~400 pixels per second with max of 0.75 second and min of 0.25
    const animDuration = Math.max( Math.min( (Math.abs(closedHeight - fullHeight) / 400 * 1000), 750), 250);

    // Start animation
    this.animationState = expanding ? SlideRevealer.STATE.EXPANDING : SlideRevealer.STATE.CLOSING;
    this.animation = this.animatedElement.animate({
      height: [startHeight, endHeight],
      paddingTop: [startPad, endPad],
      paddingBottom: [startPad, endPad]
    }, {
      duration: animDuration,
      easing: 'ease'
    });

    this.animation.onfinish = () => { this.onAnimationFinish(expanding); };
    this.animation.oncancel = () => { this.animationState = SlideRevealer.STATE.INACTIVE; };
  }

  onAnimationFinish(isOpen) {
    // Clear animation state
    this.animation = null;
    this.animationState = SlideRevealer.STATE.INACTIVE;

    // Make sure animated element has open (needed for details)
    if(!isOpen) {
      this.animatedElement.removeAttribute("open");
      this.triggerElement.removeAttribute("open");
    }

    // Clear styles used in animation
    this.animatedElement.style.overflow = '';
    if (!isOpen)
      this.contentElement.style.display = 'none';
  }
}



// A LinkKnowl manages a single link based knowl
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
    this.uid = LinkKnowl.xrefCount++;
    knowlLinkElement.setAttribute("data-knowl-uid", this.uid);

    // Xref's behavior is that of a button
    knowlLinkElement.setAttribute("role", "button");

    // Stash a copy of the original title for use in aria-label
    // If no title, use textContent
    knowlLinkElement.setAttribute("data-base-title", knowlLinkElement.getAttribute("title") || this.linkElement.textContent);

    knowlLinkElement.classList.add("knowl__link");

    this.updateLabels(false);

    // Bind required to force "this" of event handler to be this object
    knowlLinkElement.addEventListener("click", this.handleLinkClick.bind(this));
  }

  // Set aria-label and title based on visibility of knowl
  updateLabels(isVisible) {
    const verb = isVisible
      ? this.linkElement.getAttribute("data-close-label") || "Close"
      : this.linkElement.getAttribute("data-reveal-label") || "Reveal";
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

    // Scroll to reveal if needed
    if (isActive) {
      const h = this.outputElement.getBoundingClientRect().height;
      if (h > window.innerHeight) {
        // knowl is taller than window, scroll to top of knowl
        this.outputElement.scrollIntoView(true);
      } else {
        // reveal full knowl
        if (this.outputElement.getBoundingClientRect().bottom > window.innerHeight)
          this.outputElement.scrollIntoView(false);
      }
    }
  }

  // Returns element the knowl output should be inserted after
  findOutputLocation() {
    const invalidParents = "table, mjx-container, div.tabular-box, .runestone > .parsons";
    // Start with the link's parent, move up as long as there are invalid parents
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

    const placeholderText = `<div class='knowl__content' style='display:none;' id='${outputId}' aria-live='polite' id='${outputContentsId}'>`
      + `Loading '${linkTarget}'`
      + `</div>`;

    const temp = document.createElement("template");
    temp.innerHTML = placeholderText;
    this.outputElement = temp.content.children[0];

    const insertLoc = this.findOutputLocation(this.linkElement);
    insertLoc.after(this.outputElement);
  }

  // Get content for knowl as dom element. Returns promise that resolves to knowl content
  async getContent() {
    const contentURL = this.linkElement.getAttribute("data-knowl");
    const knowlContent = await fetch(contentURL)
      .then((response) => response.text())
      .then((data) => {
        // knowls are full HTML pages, need to just extract body
        let knowlDoc = (new DOMParser()).parseFromString(data, "text/html");
        let tempContainer = knowlDoc.body;
        // grab any scripts from head of knowl doc and add them to the output
        let scripts = knowlDoc.querySelectorAll("head script");
        tempContainer.append(...scripts);
        return tempContainer;
      })
      .catch((error) => {
        const destination = this.linkElement.getAttribute("href");
        const text = this.linkElement.textContent;
        const err_message = `<div class='knowl-output__error'>`
          + `<div class='para'>Error fetching content. (<em>${error}</em>)</div>`
          + `<div class='para'><a href='${destination}'>Navigate to ${text}</a> instead.</div>`
          + `<div class='para'>If you are viewing this book from your local filesystem, this is expected behavior. To view the book with all features, you must serve the book from a web server. See the <a href="https://pretextbook.org/doc/guide/html/author-faq.html#how-do-i-view-my-book-locally">PreTeXt FAQ</a> for more information.</div>`
          + `</div>`;
        return err_message;
      });
    return knowlContent;
  }

  // Handle a click on the knowl link
  handleLinkClick(event) {
    // prevent navigation
    event.preventDefault();

    if (this.outputElement !== null) {
      // output already created, toggle visibility
      this.toggle();
    } else {
      this.createOutputElement();

      const slideHandler = new SlideRevealer(this.linkElement, this.outputElement, this.outputElement);
      //slideHandler is now responsible for handling clicks to this element
      this.linkElement.addEventListener('click', slideHandler);

      // Wait up to a half second in hopes of avoiding double content change
      // then render to show loading message
      let loadingTimeout = setTimeout(() => {
        loadingTimeout = null;
        slideHandler.onClick(); //fake initial click
        this.toggle();
      }, 500);

      const content = this.getContent();

      // Content is a promise at this point, insert when resolved
      content
        .then((tempContainer) => {
          // if timeout still active, cancel it and render
          if (loadingTimeout !== null) {
            clearTimeout(loadingTimeout);
          }
          // Now give code that follows .1 seconds to render before making visible
          setTimeout(() => {
            slideHandler.onClick(); //fake initial click
            this.toggle();
          }, 100);

          // check embedded runestone interactives by loading content into a temp container
          // we want to not render any that already are on page. Dupe IDs probably bad
          const runestoneElements = tempContainer.querySelectorAll(".ptx-runestone-container");
          [...runestoneElements].forEach((e) => {
            const rsId = e.querySelector("[data-component]")?.id;
            const onPage = document.getElementById(rsId);
            if (onPage) {
              e.innerHTML = `<div class="para">The interactive that belongs here is already on the page and cannot appear multiple times. <a href="#${rsId}">Scroll to interactive.</a>`;
            } else {
              // let runestone start rendering it
              window.runestoneComponents.renderOneComponent(e);
            }
          });

          // now move all contents to the real output element
          const children = [...tempContainer.children];
          this.outputElement.innerHTML = "";
          this.outputElement.append(...children);

          // render any knowls and mathjax in the knowl
          MathJax.typesetPromise([this.outputElement]);
          addKnowls(this.outputElement);

          // force any scripts (e.g. sagecell) to execute by evaling them
          [...this.outputElement.getElementsByTagName("script")].forEach((s) => {
            if (
              s.getAttribute("type") === null ||
              s.getAttribute("type") === "text/javascript"
            ) {
              eval(s.innerHTML);
            }
          });
        })
        .catch((data) => {
          console.log("Error fetching knowl content: " + data);
        });
    }
  }
}
