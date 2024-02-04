// Code for link based knowls

// Assumes this file is loaded as part of initial page
window.addEventListener("load", (event) => {
  addLinkKnowls(document);
});

function addLinkKnowls(target) {
  const xrefs = target.querySelectorAll("[data-knowl]");
  for (const xref of xrefs) {
    LinkKnowl.initializeXrefKnowl(xref);
  }
}

// A LinkKnowl managages a single link based knowl
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
    this.updateLabels(this.linkElement.classList.contains("active"));

    this.outputElement.classList.toggle("knowl-output--hide");

    // Scroll to reveal if needed
    if (!this.outputElement.classList.contains("knowl-output--hide")) {
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

    const placeholderText = `<div class='knowl-output knowl-output--hide' id='${outputId}' aria-live='polite'>`
      + `<div class='knowl'>`
      + `<div class='knowl-content' id='${outputContentsId}'>`
      + `Loading '${linkTarget}'`
      + `</div>`
      + `<div class='knowl-footer'>${linkTarget}</div>`
      + `</div></div></div>`;

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

      // Wait up to a half second in hopes of avoiding double content change
      // then render to show loading message
      let loadingTimeout = setTimeout(() => {
        loadingTimeout = null;
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
            this.toggle();
          }, 100);

          // check embeded runestone interactives by loading content into a temp container
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
          const target = document.getElementById("knowl-output-" + this.uid);
          const children = [...tempContainer.children];
          target.innerHTML = "";
          target.append(...children);

          // render any knowls and mathjax in the knowl
          MathJax.typesetPromise([target]);
          addLinkKnowls(target);

          // force any scripts (e.g. sagecell) to execute by evaling them
          [...target.getElementsByTagName("script")].forEach((s) => {
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
